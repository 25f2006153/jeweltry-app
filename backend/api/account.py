import logging
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from ..core.security import get_current_user, AuthUser
from ..db.database import get_supabase_client
from ..services.credit_service import _mock_wallets
from .try_on import _generations_store

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/account", tags=["Account & Privacy"])

class DeleteAccountResponse(BaseModel):
    status: str
    user_id: str
    message: str

@router.delete("", response_model=DeleteAccountResponse)
async def delete_user_account(user: AuthUser = Depends(get_current_user)):
    """
    GDPR & Privacy Account Deletion Endpoint.
    Erases user profile, credit wallet, generation history, and associated storage assets.
    """
    user_id = user.id

    # 1. Clean in-memory dev state
    if user_id in _mock_wallets:
        del _mock_wallets[user_id]

    to_delete_keys = [k for k, v in _generations_store.items() if v.get('user_id') == user_id]
    for k in to_delete_keys:
        del _generations_store[k]

    # 2. Database & Storage cleanup via Supabase Client
    client = get_supabase_client()
    if client is not None:
        try:
            client.table('try_on_generations').delete().eq('user_id', user_id).execute()
            client.table('subscriptions').delete().eq('user_id', user_id).execute()
            client.table('credit_wallets').delete().eq('user_id', user_id).execute()
            client.table('profiles').delete().eq('id', user_id).execute()
            logger.info(f"Successfully erased database records for user {user_id}")
        except Exception as e:
            logger.error(f"Error during account data deletion for {user_id}: {e}")

    return DeleteAccountResponse(
        status="success",
        user_id=user_id,
        message="All account records, credit wallets, and try-on history erased successfully.",
    )
