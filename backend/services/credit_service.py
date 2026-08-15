import logging
import threading
from typing import Dict, Tuple
from ..db.database import get_supabase_client

logger = logging.getLogger(__name__)

# In-memory mock wallet storage for local development & Pytest concurrency verification
_mock_lock = threading.Lock()
_mock_wallets: Dict[str, Dict[str, int]] = {}  # user_id -> {'balance': 1, 'reserved': 0}
_mock_reservations: Dict[str, Dict[str, str]] = {}  # request_id -> {'user_id': ..., 'status': 'reserved'}

class CreditService:
    @staticmethod
    def reserve_credit(user_id: str, request_id: str) -> bool:
        """
        Atomically reserve 1 credit for generation request_id.
        Returns True if reservation succeeds, False if insufficient credits.
        """
        client = get_supabase_client()
        if client is not None:
            try:
                res = client.rpc('reserve_credit', {
                    'p_user_id': user_id,
                    'p_request_id': request_id
                }).execute()
                return bool(res.data)
            except Exception as e:
                logger.error(f"RPC reserve_credit error: {e}. Falling back to atomic in-memory lock.")

        # Thread-safe in-memory atomic reservation lock
        with _mock_lock:
            wallet = _mock_wallets.setdefault(user_id, {'balance': 1, 'reserved': 0})
            available = wallet['balance'] - wallet['reserved']
            if available >= 1:
                wallet['reserved'] += 1
                _mock_reservations[request_id] = {
                    'user_id': user_id,
                    'status': 'reserved',
                    'amount': 1
                }
                return True
            else:
                return False

    @staticmethod
    def finalize_reservation(request_id: str) -> int:
        """
        Finalize reservation: deduct 1 credit from balance upon successful AI generation.
        Returns updated balance.
        """
        client = get_supabase_client()
        if client is not None:
            try:
                res = client.rpc('finalize_credit_reservation', {
                    'p_request_id': request_id
                }).execute()
                return int(res.data) if res.data is not None else 0
            except Exception as e:
                logger.error(f"RPC finalize_credit_reservation error: {e}")

        with _mock_lock:
            res_info = _mock_reservations.get(request_id)
            if res_info and res_info['status'] == 'reserved':
                user_id = res_info['user_id']
                wallet = _mock_wallets.get(user_id, {'balance': 1, 'reserved': 1})
                wallet['balance'] = max(0, wallet['balance'] - 1)
                wallet['reserved'] = max(0, wallet['reserved'] - 1)
                res_info['status'] = 'finalized'
                return wallet['balance']
            return 0

    @staticmethod
    def release_reservation(request_id: str) -> int:
        """
        Release reservation: refund/cancel reservation on AI failure (0 credits deducted).
        Returns current balance.
        """
        client = get_supabase_client()
        if client is not None:
            try:
                res = client.rpc('release_credit_reservation', {
                    'p_request_id': request_id
                }).execute()
                return int(res.data) if res.data is not None else 0
            except Exception as e:
                logger.error(f"RPC release_credit_reservation error: {e}")

        with _mock_lock:
            res_info = _mock_reservations.get(request_id)
            if res_info and res_info['status'] == 'reserved':
                user_id = res_info['user_id']
                wallet = _mock_wallets.get(user_id, {'balance': 1, 'reserved': 1})
                wallet['reserved'] = max(0, wallet['reserved'] - 1)
                res_info['status'] = 'released'
                return wallet['balance']
            return 0

    @staticmethod
    def get_user_credits(user_id: str) -> Tuple[int, int]:
        """
        Returns (balance, reserved).
        """
        client = get_supabase_client()
        if client is not None:
            try:
                res = client.table('credit_wallets').select('balance, reserved').eq('user_id', user_id).execute()
                if res.data and len(res.data) > 0:
                    row = res.data[0]
                    return row['balance'], row['reserved']
            except Exception as e:
                logger.error(f"Get credits error: {e}")

        with _mock_lock:
            wallet = _mock_wallets.setdefault(user_id, {'balance': 1, 'reserved': 0})
            return wallet['balance'], wallet['reserved']

    @staticmethod
    def add_credits(user_id: str, amount: int, transaction_type: str, reference_id: str) -> int:
        """
        Grants credits to user wallet.
        """
        client = get_supabase_client()
        if client is not None:
            try:
                # Update wallet balance
                client.rpc('add_user_credits', {'p_user_id': user_id, 'p_amount': amount}).execute()
            except Exception:
                pass

        with _mock_lock:
            wallet = _mock_wallets.setdefault(user_id, {'balance': 1, 'reserved': 0})
            wallet['balance'] += amount
            return wallet['balance']

    @staticmethod
    def reset_mock_state():
        """Helper for Pytest concurrency testing."""
        with _mock_lock:
            _mock_wallets.clear()
            _mock_reservations.clear()
