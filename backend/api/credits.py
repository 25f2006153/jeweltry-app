from fastapi import APIRouter, Depends
from pydantic import BaseModel
from ..core.security import get_current_user, AuthUser
from ..services.credit_service import CreditService

router = APIRouter(prefix="/api/credits", tags=["Credits"])

class CreditsResponse(BaseModel):
    balance: int
    reserved: int
    available: int

class TopupRequest(BaseModel):
    amount: int = 12

@router.get("", response_model=CreditsResponse)
async def get_user_credits(user: AuthUser = Depends(get_current_user)):
    balance, reserved = CreditService.get_user_credits(user.id)
    return CreditsResponse(
        balance=balance,
        reserved=reserved,
        available=max(0, balance - reserved),
    )

@router.post("/topup", response_model=CreditsResponse)
async def topup_user_credits(body: TopupRequest, user: AuthUser = Depends(get_current_user)):
    CreditService.add_credits(user.id, body.amount, "web_topup", f"topup_{user.id}")
    balance, reserved = CreditService.get_user_credits(user.id)
    return CreditsResponse(
        balance=balance,
        reserved=reserved,
        available=max(0, balance - reserved),
    )

