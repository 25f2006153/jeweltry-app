import logging
from typing import Optional
try:
    from supabase import create_client, Client
    HAS_SUPABASE = True
except ImportError:
    HAS_SUPABASE = False
    Client = None

logger = logging.getLogger(__name__)

_supabase_client: Optional[Client] = None

def get_supabase_client() -> Optional[Client]:
    global _supabase_client
    if not HAS_SUPABASE:
        return None
    if _supabase_client is None:
        try:
            _supabase_client = create_client(
                settings.SUPABASE_URL,
                settings.SUPABASE_SERVICE_ROLE_KEY
            )
        except Exception as e:
            logger.warning(f"Failed to initialize remote Supabase client: {e}. Falling back to mock client.")
            _supabase_client = None
    return _supabase_client
