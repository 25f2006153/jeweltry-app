import asyncio
import pytest
from backend.services.credit_service import CreditService
from backend.services.payment_service import PaymentService
from backend.services.gemini_service import GeminiService, validate_ai_model_compatibility

@pytest.fixture(autouse=True)
def reset_state():
    CreditService.reset_mock_state()

def test_atomic_credit_concurrency():
    user_id = "test_user_concurrency_01"
    req_1 = "request_id_111"
    req_2 = "request_id_222"

    balance, reserved = CreditService.get_user_credits(user_id)
    assert balance == 1
    assert reserved == 0

    result_1 = CreditService.reserve_credit(user_id, req_1)
    result_2 = CreditService.reserve_credit(user_id, req_2)

    # Exactly ONE request succeeds
    assert (result_1 is True and result_2 is False) or (result_1 is False and result_2 is True)

    bal, res = CreditService.get_user_credits(user_id)
    assert res == 1

def test_credit_finalization_and_release():
    user_id = "test_user_credit_flow_02"
    req_success = "req_success_001"
    req_fail = "req_fail_002"

    # Successful generation consumes 1 credit
    assert CreditService.reserve_credit(user_id, req_success) is True
    new_bal = CreditService.finalize_reservation(req_success)
    assert new_bal == 0

    # Reservation when balance = 0 fails
    assert CreditService.reserve_credit(user_id, req_fail) is False

    # Failure releases reservation (0 credits deducted)
    CreditService.add_credits(user_id, 1, 'subscription_grant', 'ref_grant')
    bal, _ = CreditService.get_user_credits(user_id)
    assert bal == 1

    assert CreditService.reserve_credit(user_id, req_fail) is True
    restored_bal = CreditService.release_reservation(req_fail)
    assert restored_bal == 1

def test_duplicate_purchase_token_rejection():
    user_id = "test_user_payments_03"
    token = "unique_purchase_token_xyz999"
    plan_id = "credits_5"
    order_id = "GPA.1234-5678-9012"

    success1, msg1, bal1 = PaymentService.verify_google_play_purchase(user_id, plan_id, token, order_id)
    assert success1 is True
    assert bal1 == 6

    success2, msg2, bal2 = PaymentService.verify_google_play_purchase(user_id, plan_id, token, order_id)
    assert success2 is False
    assert "already processed" in msg2

def test_gemini_image_model_validation():
    # Verify image generation capable models pass validation
    assert validate_ai_model_compatibility("imagen-3.0-generate-002") is True
    assert validate_ai_model_compatibility("gemini-2.5-flash-image") is True
    assert validate_ai_model_compatibility("nano-banana-2") is True

def test_gemini_service_returns_image_bytes():
    service = GeminiService()
    user_dummy_bytes = b"GIF89a\x01\x00\x01\x00\x80\x00\x00\xff\xff\xff\x00\x00\x00!\xf9\x04\x01\x00\x00\x00\x00,\x00\x00\x00\x00\x01\x00\x01\x00\x00\x02\x02D\x01\x00;"
    jewelry_dummy_bytes = user_dummy_bytes

    result_bytes = asyncio.run(service.generate_try_on(
        user_image_bytes=user_dummy_bytes,
        jewelry_image_bytes=jewelry_dummy_bytes,
        jewelry_type="earrings",
        target_anchor="ears"
    ))

    assert result_bytes is not None
    assert len(result_bytes) > 20
