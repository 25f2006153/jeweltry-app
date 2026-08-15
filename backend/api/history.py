from typing import List, Optional
from fastapi import APIRouter, Depends, Query, HTTPException, status
from pydantic import BaseModel
from ..core.config import settings
from ..core.security import get_current_user, AuthUser
from ..services.storage_service import StorageService
from ..db.database import get_supabase_client
from .try_on import _generations_store

router = APIRouter(prefix="/api/history", tags=["History"])

class HistoryItem(BaseModel):
    id: str
    jewelry_type: str
    target_anchor: str
    status: str
    result_image_url: Optional[str] = None
    created_at: str

class HistoryResponse(BaseModel):
    items: List[HistoryItem]
    page: int
    limit: int
    total: int

@router.get("", response_model=HistoryResponse)
async def get_user_history(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    user: AuthUser = Depends(get_current_user),
):
    items = []
    client = get_supabase_client()
    if client is not None:
        try:
            offset = (page - 1) * limit
            res = client.table('try_on_generations')\
                .select('*', count='exact')\
                .eq('user_id', user.id)\
                .order('created_at', desc=True)\
                .range(offset, offset + limit - 1)\
                .execute()

            if res.data is not None:
                for row in res.data:
                    # Generate user-isolated signed URL
                    signed_url = StorageService.create_signed_result_url(
                        user_id=row['user_id'],
                        request_user_id=user.id,
                        generation_id_or_path=row.get('result_image_url') or row['id'],
                        expires_in=settings.SIGNED_URL_EXPIRATION_SECONDS
                    )
                    items.append(HistoryItem(
                        id=row['id'],
                        jewelry_type=row['jewelry_type'],
                        target_anchor=row['target_anchor'],
                        status=row['status'],
                        result_image_url=signed_url,
                        created_at=row.get('created_at', ''),
                    ))
                return HistoryResponse(
                    items=items,
                    page=page,
                    limit=limit,
                    total=res.count or len(items),
                )
        except Exception:
            pass

    # In-memory store fallback with signed URLs
    user_items = []
    for k, v in _generations_store.items():
        if v.get('user_id') == user.id:
            signed_url = StorageService.create_signed_result_url(
                user_id=user.id,
                request_user_id=user.id,
                generation_id_or_path=v.get('result_path') or k,
                expires_in=settings.SIGNED_URL_EXPIRATION_SECONDS
            )
            user_items.append(HistoryItem(
                id=k,
                jewelry_type="earrings",
                target_anchor="ears",
                status=v.get('status', 'completed'),
                result_image_url=signed_url,
                created_at="2026-08-11T12:00:00Z"
            ))

    return HistoryResponse(
        items=user_items,
        page=page,
        limit=limit,
        total=len(user_items),
    )

@router.delete("/{id}")
async def delete_history_item(
    id: str,
    user: AuthUser = Depends(get_current_user),
):
    if id in _generations_store:
        record = _generations_store[id]
        if record.get('user_id') != user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied: You do not own this generation record.",
            )
        del _generations_store[id]
        return {"status": "deleted", "id": id}

    client = get_supabase_client()
    if client is not None:
        try:
            # Verify ownership before deleting
            res = client.table('try_on_generations').select('user_id').eq('id', id).execute()
            if res.data:
                if res.data[0]['user_id'] != user.id:
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail="Access denied: You do not own this generation record.",
                    )
            client.table('try_on_generations').delete().eq('id', id).eq('user_id', user.id).execute()
            return {"status": "deleted", "id": id}
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

    return {"status": "deleted", "id": id}
