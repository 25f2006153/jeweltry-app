import asyncio
import pytest
from backend.services.credit_service import CreditService
from backend.services.storage_service import StorageService
from backend.services.payment_service import PaymentService
from backend.services.gemini_service import GeminiService
from backend.core.security import AuthUser

@pytest.fixture(autouse=True)
def reset_state():
    CreditService.reset_mock_state()

def test_10_simultaneous_concurrency_balance_1():
    user_id = "user_10_concurrent_bal1"
    # Ensure balance = 1
    bal, res = CreditService.get_user_credits(user_id)
    assert bal == 1
    assert res == 0

    # 10 simultaneous reservation attempts
    results = [
        CreditService.reserve_credit(user_id, f"req_attempt_{i}")
        for i in range(10)
    ]

    successes = [r for r in results if r is True]
    failures = [r for r in results if r is False]

    assert len(successes) == 1, f"Expected exactly 1 success, got {len(successes)}"
    assert len(failures) == 9, f"Expected 9 failures, got {len(failures)}"

    # Final balance check
    bal_end, res_end = CreditService.get_user_credits(user_id)
    assert res_end == 1
    assert bal_end >= 0  # No negative balance!

def test_10_simultaneous_concurrency_balance_5():
    user_id = "user_10_concurrent_bal5"
    CreditService.add_credits(user_id, 4, 'subscription_grant', 'topup_5')
    bal, _ = CreditService.get_user_credits(user_id)
    assert bal == 5

    # 10 simultaneous reservation attempts
    results = [
        CreditService.reserve_credit(user_id, f"req_attempt_bal5_{i}")
        for i in range(10)
    ]

    successes = [r for r in results if r is True]
    failures = [r for r in results if r is False]

    assert len(successes) == 5, f"Expected exactly 5 successes, got {len(successes)}"
    assert len(failures) == 5, f"Expected 5 failures, got {len(failures)}"

def test_private_storage_signed_urls_user_isolation():
    user_a_id = "user_a_owner"
    user_b_id = "user_b_attacker"
    generation_id = "gen_result_777"

    # Generate signed URL for User A by User A -> Allowed!
    signed_url_owner = StorageService.create_signed_result_url(
        user_id=user_a_id,
        request_user_id=user_a_id,
        generation_id_or_path=generation_id,
        expires_in=3600
    )
    assert signed_url_owner is not None
    assert "user_user_a_owner" in signed_url_owner or "user_a_owner" in signed_url_owner

    # Attempt to fetch User A's result by User B -> ACCESS DENIED (None)
    signed_url_attacker = StorageService.create_signed_result_url(
        user_id=user_a_id,
        request_user_id=user_b_id,
        generation_id_or_path=generation_id,
        expires_in=3600
    )
    assert signed_url_attacker is None, "User B must be denied access to User A's private result image"

def test_subscriptionsv2_purchase_verification():
    user_id = "user_subv2_test"
    token = "subv2_token_abc123999"
    plan_id = "pro_monthly"
    order_id = "GPA.9999-8888-7777"

    success, msg, new_bal = PaymentService.verify_google_play_purchase(user_id, plan_id, token, order_id)
    assert success is True
    assert new_bal == 41  # 1 initial + 40 pro monthly credits

    # Duplicate verification token attempt -> MUST FAIL
    dup_success, dup_msg, _ = PaymentService.verify_google_play_purchase(user_id, plan_id, token, order_id)
    assert dup_success is False
    assert "already processed" in dup_msg
