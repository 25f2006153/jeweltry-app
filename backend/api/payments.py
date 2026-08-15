from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from ..core.security import get_current_user, AuthUser
from ..services.payment_service import PaymentService

router = APIRouter(prefix="/api/payments", tags=["Payments"])

class GooglePlayVerifyRequest(BaseModel):
    plan_id: str
    purchase_token: str
    order_id: str

class PaymentVerifyResponse(BaseModel):
    success: bool
    message: str
    credits_remaining: int

@router.post("/verify-google-play", response_model=PaymentVerifyResponse)
async def verify_google_play_payment(
    body: GooglePlayVerifyRequest,
    user: AuthUser = Depends(get_current_user),
):
    success, message, new_balance = PaymentService.verify_google_play_purchase(
        user_id=user.id,
        plan_id=body.plan_id,
        purchase_token=body.purchase_token,
        order_id=body.order_id,
    )

    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=message,
        )

    return PaymentVerifyResponse(
        success=True,
        message=message,
        credits_remaining=new_balance,
    )

class RazorpayOrderRequest(BaseModel):
    plan_id: str

class RazorpayVerifyRequest(BaseModel):
    plan_id: str
    razorpay_order_id: str
    razorpay_payment_id: str
    razorpay_signature: str

@router.post("/create-order")
async def create_online_payment_order(
    body: RazorpayOrderRequest,
    user: AuthUser = Depends(get_current_user),
):
    result = PaymentService.create_razorpay_order(
        user_id=user.id,
        plan_id=body.plan_id,
    )
    if not result.get("success"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=result.get("message", "Could not create payment order"),
        )
    return result

@router.post("/verify-razorpay", response_model=PaymentVerifyResponse)
async def verify_razorpay_payment_endpoint(
    body: RazorpayVerifyRequest,
    user: AuthUser = Depends(get_current_user),
):
    success, message, new_balance = PaymentService.verify_razorpay_payment(
        user_id=user.id,
        plan_id=body.plan_id,
        razorpay_order_id=body.razorpay_order_id,
        razorpay_payment_id=body.razorpay_payment_id,
        razorpay_signature=body.razorpay_signature,
    )
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=message,
        )
    return PaymentVerifyResponse(
        success=True,
        message=message,
        credits_remaining=new_balance,
    )

