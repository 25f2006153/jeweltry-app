from typing import List, Optional
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from ..core.security import get_current_user, AuthUser
from ..db.database import get_supabase_client

router = APIRouter(tags=["Subscriptions"])

class PlanItem(BaseModel):
    id: str
    title: str
    type: str  # subscription, one_time_pack
    price_inr: float
    credits: int
    google_play_product_id: str

class SubscriptionStatusResponse(BaseModel):
    plan_id: str
    title: str
    status: str
    current_period_end: Optional[str] = None

PLANS_FALLBACK = [
    PlanItem(id="free", title="Free Trial", type="subscription", price_inr=0.0, credits=1, google_play_product_id="free_plan"),
    PlanItem(id="starter_monthly", title="Starter Monthly", type="subscription", price_inr=59.0, credits=8, google_play_product_id="starter_monthly"),
    PlanItem(id="basic_monthly", title="Basic Monthly", type="subscription", price_inr=99.0, credits=20, google_play_product_id="basic_monthly"),
    PlanItem(id="pro_monthly", title="Pro Monthly", type="subscription", price_inr=199.0, credits=40, google_play_product_id="pro_monthly"),
    PlanItem(id="premium_monthly", title="Premium Monthly", type="subscription", price_inr=399.0, credits=90, google_play_product_id="premium_monthly"),
    PlanItem(id="credits_5", title="5 Credit Top-up", type="one_time_pack", price_inr=49.0, credits=5, google_play_product_id="credits_5"),
    PlanItem(id="credits_12", title="12 Credit Top-up", type="one_time_pack", price_inr=99.0, credits=12, google_play_product_id="credits_12"),
    PlanItem(id="credits_28", title="28 Credit Top-up", type="one_time_pack", price_inr=199.0, credits=28, google_play_product_id="credits_28"),
    PlanItem(id="credits_60", title="60 Credit Top-up", type="one_time_pack", price_inr=399.0, credits=60, google_play_product_id="credits_60"),
]

@router.get("/api/plans", response_model=List[PlanItem])
async def get_available_plans():
    client = get_supabase_client()
    if client is not None:
        try:
            res = client.table('plans').select('*').eq('is_active', True).execute()
            if res.data and len(res.data) > 0:
                return [PlanItem(**row) for row in res.data]
        except Exception:
            pass

    return PLANS_FALLBACK

@router.get("/api/subscription", response_model=SubscriptionStatusResponse)
async def get_user_subscription(user: AuthUser = Depends(get_current_user)):
    client = get_supabase_client()
    if client is not None:
        try:
            res = client.table('subscriptions').select('*').eq('user_id', user.id).eq('status', 'active').execute()
            if res.data and len(res.data) > 0:
                row = res.data[0]
                return SubscriptionStatusResponse(
                    plan_id=row['plan_id'],
                    title=row.get('title', 'Active Subscription'),
                    status=row['status'],
                    current_period_end=row.get('current_period_end'),
                )
        except Exception:
            pass

    return SubscriptionStatusResponse(
        plan_id="free",
        title="Free Plan",
        status="active",
        current_period_end=None,
    )
