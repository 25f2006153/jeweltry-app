import uuid
import logging
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, status, BackgroundTasks
from pydantic import BaseModel

from ..core.config import settings
from ..core.security import get_current_user, AuthUser
from ..services.credit_service import CreditService
from ..services.storage_service import StorageService
from ..services.gemini_service import get_ai_service
from ..db.database import get_supabase_client

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/try-on", tags=["Try-On"])

# In-memory status store for polling GET /api/try-on/{request_id}
_generations_store = {}

class TryOnResponse(BaseModel):
    request_id: str
    status: str  # pending, processing, completed, failed
    result_image_url: Optional[str] = None
    credits_remaining: int
    error_message: Optional[str] = None

ALLOWED_MIMES = ["image/jpeg", "image/png", "image/webp"]

async def process_ai_try_on_task(
    request_id: str,
    user_id: str,
    user_bytes: bytes,
    jewelry_bytes: bytes,
    jewelry_type: str,
    user_filename: str,
    jewelry_filename: str,
):
    ai_service = get_ai_service()
    target_anchor = "ears" if "earring" in jewelry_type.lower() else ("neck" if "necklace" in jewelry_type.lower() else "body")
    
    _generations_store[request_id]['status'] = 'processing'

    try:
        # Run AI virtual try-on engine
        result_bytes = await ai_service.generate_try_on(
            user_image_bytes=user_bytes,
            jewelry_image_bytes=jewelry_bytes,
            jewelry_type=jewelry_type,
            target_anchor=target_anchor,
        )

        # Upload result image to PRIVATE Supabase Storage bucket under user_id/request_id.jpg
        result_path = StorageService.upload_generated_result(
            user_id=user_id,
            generation_id=request_id,
            file_bytes=result_bytes
        )

        # Finalize credit reservation (deduct 1 credit)
        new_balance = CreditService.finalize_reservation(request_id)

        # Generate short-lived signed URL for user
        signed_url = StorageService.create_signed_result_url(
            user_id=user_id,
            request_user_id=user_id,
            generation_id_or_path=result_path,
            expires_in=settings.SIGNED_URL_EXPIRATION_SECONDS
        )

        # Update in-memory & DB record
        _generations_store[request_id].update({
            'status': 'completed',
            'result_image_url': signed_url,
            'result_path': result_path,
            'credits_remaining': new_balance,
        })

        # Autoclean temporary user input files
        StorageService.delete_temporary_request_folder(user_id, request_id)

        client = get_supabase_client()
        if client is not None:
            try:
                client.table('try_on_generations').update({
                    'status': 'completed',
                    'result_image_url': result_path,
                }).eq('id', request_id).execute()
            except Exception as e:
                logger.error(f"Failed to update try_on_generations record: {e}")

    except Exception as e:
        logger.error(f"AI Try-On processing error for request {request_id}: {e}")
        # Release credit reservation (0 credits deducted!)
        new_balance = CreditService.release_reservation(request_id)

        _generations_store[request_id].update({
            'status': 'failed',
            'error_message': 'AI generation failed. Please try again.',
            'credits_remaining': new_balance,
        })
        StorageService.delete_temporary_request_folder(user_id, request_id)

@router.post("", response_model=TryOnResponse)
async def initiate_try_on(
    background_tasks: BackgroundTasks,
    user_image: UploadFile = File(...),
    jewelry_image: UploadFile = File(...),
    jewelry_type: str = Form(...),
    request_id: Optional[str] = Form(None),
    user: AuthUser = Depends(get_current_user),
):
    # ZERO-CREDIT SHIELD: Verify available credits BEFORE reading files or invoking Gemini!
    balance, reserved = CreditService.get_user_credits(user.id)
    available_credits = balance - reserved

    if available_credits < 1:
        logger.warning(f"🛡️ Zero-Credit Shield Triggered: User {user.id} blocked with 0 credits available.")
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail=f"Insufficient credits. Balance: {balance}, Available: {available_credits}. Gemini API call blocked.",
        )

    # Validate MIME types
    if user_image.content_type not in ALLOWED_MIMES or jewelry_image.content_type not in ALLOWED_MIMES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid image format. Supported formats: JPG, PNG, WEBP",
        )

    # Read image files and check MAX_UPLOAD_MB
    user_bytes = await user_image.read()
    jewelry_bytes = await jewelry_image.read()

    max_bytes = settings.MAX_UPLOAD_MB * 1024 * 1024
    if len(user_bytes) > max_bytes or len(jewelry_bytes) > max_bytes:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Image size exceeds maximum upload limit of {settings.MAX_UPLOAD_MB}MB",
        )

    req_id = request_id or str(uuid.uuid4())

    # Prevent duplicate request processing
    if req_id in _generations_store and _generations_store[req_id]['status'] in ['processing', 'completed']:
        return TryOnResponse(
            request_id=req_id,
            status=_generations_store[req_id]['status'],
            result_image_url=_generations_store[req_id].get('result_image_url'),
            credits_remaining=_generations_store[req_id].get('credits_remaining', 0),
        )

    # Atomic credit reservation
    reserved_ok = CreditService.reserve_credit(user.id, req_id)
    if not reserved_ok:
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail="Insufficient credits available to reserve.",
        )

    # Upload temporary inputs to user-isolated storage path
    StorageService.upload_temporary_image(user.id, req_id, user_bytes, "user.jpg", user_image.content_type or "image/jpeg")
    StorageService.upload_temporary_image(user.id, req_id, jewelry_bytes, "jewelry.jpg", jewelry_image.content_type or "image/jpeg")

    _generations_store[req_id] = {
        'request_id': req_id,
        'user_id': user.id,
        'status': 'pending',
        'result_image_url': None,
        'credits_remaining': balance,
        'error_message': None,
    }

    # Queue AI processing in background task
    background_tasks.add_task(
        process_ai_try_on_task,
        request_id=req_id,
        user_id=user.id,
        user_bytes=user_bytes,
        jewelry_bytes=jewelry_bytes,
        jewelry_type=jewelry_type,
        user_filename=user_image.filename or "user.jpg",
        jewelry_filename=jewelry_image.filename or "jewelry.jpg",
    )

    return TryOnResponse(
        request_id=req_id,
        status="processing",
        result_image_url=None,
        credits_remaining=balance,
    )

@router.get("/{request_id}", response_model=TryOnResponse)
async def get_try_on_status(
    request_id: str,
    user: AuthUser = Depends(get_current_user),
):
    if request_id in _generations_store:
        record = _generations_store[request_id]
        
        # User isolation authorization check!
        if record.get('user_id') != user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied: You do not own this generation record.",
            )

        # Generate short-lived signed URL if completed
        signed_url = record.get('result_image_url')
        if record.get('status') == 'completed' and record.get('result_path'):
            signed_url = StorageService.create_signed_result_url(
                user_id=record['user_id'],
                request_user_id=user.id,
                generation_id_or_path=record['result_path'],
                expires_in=settings.SIGNED_URL_EXPIRATION_SECONDS
            )

        return TryOnResponse(
            request_id=request_id,
            status=record['status'],
            result_image_url=signed_url,
            credits_remaining=record.get('credits_remaining', 0),
            error_message=record.get('error_message'),
        )

    # Database query fallback
    client = get_supabase_client()
    if client is not None:
        try:
            res = client.table('try_on_generations').select('*').eq('id', request_id).execute()
            if res.data and len(res.data) > 0:
                row = res.data[0]
                if row['user_id'] != user.id:
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail="Access denied: You do not own this generation record.",
                    )

                signed_url = StorageService.create_signed_result_url(
                    user_id=row['user_id'],
                    request_user_id=user.id,
                    generation_id_or_path=row.get('result_image_url') or request_id,
                    expires_in=settings.SIGNED_URL_EXPIRATION_SECONDS
                )
                balance, _ = CreditService.get_user_credits(user.id)
                return TryOnResponse(
                    request_id=request_id,
                    status=row['status'],
                    result_image_url=signed_url,
                    credits_remaining=balance,
                    error_message=row.get('error_message'),
                )
        except Exception:
            pass

    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail="Try-On request ID not found",
    )
