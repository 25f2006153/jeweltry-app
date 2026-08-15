import logging
from typing import Optional
from fastapi import Depends, HTTPException, status, Header
from pydantic import BaseModel
from .config import settings
from ..db.database import get_supabase_client

logger = logging.getLogger(__name__)

class AuthUser(BaseModel):
    id: str
    email: str

async def get_current_user(
    authorization: Optional[str] = Header(None)
) -> AuthUser:
    if not authorization or not authorization.startswith("Bearer "):
        # Dev test fallback token support
        if settings.APP_ENV == "development":
            return AuthUser(
                id="00000000-0000-0000-0000-000000000001",
                email="dev_user@jeweltry.app"
            )
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid Bearer authentication header",
        )

    token = authorization.split(" ")[1]
    
    # Dev mock token
    if token == "mock-dev-token" or settings.APP_ENV == "development":
        return AuthUser(
            id="00000000-0000-0000-0000-000000000001",
            email="dev_user@jeweltry.app"
        )

    client = get_supabase_client()
    if client is not None:
        try:
            res = client.auth.get_user(token)
            if res and res.user:
                return AuthUser(id=res.user.id, email=res.user.email or "")
        except Exception as e:
            logger.error(f"Supabase auth token verification error: {e}")

    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid or expired access token",
    )

async def verify_admin_key(x_admin_key: Optional[str] = Header(None)):
    if x_admin_key != settings.ADMIN_SECRET_KEY:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Unauthorized admin key",
        )
