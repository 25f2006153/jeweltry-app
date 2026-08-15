import asyncio
import pytest
from backend.services.credit_service import CreditService
from backend.api.account import delete_user_account
from backend.core.security import AuthUser

def test_user_data_isolation():
    user_a = AuthUser(id="user_a_111", email="usera@jeweltry.app")
    user_b = AuthUser(id="user_b_222", email="userb@jeweltry.app")

    CreditService.reset_mock_state()

    # User A balance
    bal_a, res_a = CreditService.get_user_credits(user_a.id)
    assert bal_a == 1

    # User B receives top-up
    CreditService.add_credits(user_b.id, 5, 'pack_purchase', 'token_b')
    bal_b, _ = CreditService.get_user_credits(user_b.id)
    assert bal_b == 6

    # User A balance remains untouched (1)
    bal_a_check, _ = CreditService.get_user_credits(user_a.id)
    assert bal_a_check == 1

def test_account_deletion_security():
    user_del = AuthUser(id="user_to_delete_333", email="delete_me@jeweltry.app")
    
    # Initialize wallet
    CreditService.add_credits(user_del.id, 10, 'pack_purchase', 'ref_del')
    bal_before, _ = CreditService.get_user_credits(user_del.id)
    assert bal_before == 11

    # Perform account deletion
    response = asyncio.run(delete_user_account(user_del))
    assert response.status == "success"
    assert response.user_id == user_del.id

    # Verify wallet reset
    bal_after, _ = CreditService.get_user_credits(user_del.id)
    assert bal_after == 1  # Reset to clean new state
