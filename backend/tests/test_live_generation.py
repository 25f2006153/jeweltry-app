import os
import asyncio
from backend.services.credit_service import CreditService
from backend.services.storage_service import StorageService
from backend.services.gemini_service import GeminiService

def test_full_live_generation_flow():
    user_id = "test_live_user_007"
    req_id = "test_live_req_007"

    # Reset mock storage state for user
    CreditService.reset_mock_state()

    # Step 1: Verify Initial Credits
    balance, reserved = CreditService.get_user_credits(user_id)
    assert balance == 1
    assert reserved == 0

    # Step 2: Atomic Credit Reservation
    reserved_ok = CreditService.reserve_credit(user_id, req_id)
    assert reserved_ok is True, "Credit reservation failed"

    # Read real sample assets
    user_img_path = "assets/images/user_sample.png"
    jewelry_img_path = "assets/images/jewelry_earrings.png"

    with open(user_img_path, "rb") as f:
        user_bytes = f.read()
    with open(jewelry_img_path, "rb") as f:
        jewelry_bytes = f.read()

    assert len(user_bytes) > 1000
    assert len(jewelry_bytes) > 1000

    # Step 3: Temporary Upload to User-Isolated Storage Path
    temp_user_url = StorageService.upload_temporary_image(user_id, req_id, user_bytes, "temp_user_test.png", "image/png")
    temp_jewelry_url = StorageService.upload_temporary_image(user_id, req_id, jewelry_bytes, "temp_jewelry_test.png", "image/png")
    assert temp_user_url is not None
    assert temp_jewelry_url is not None

    # Step 4: AI Generation
    service = GeminiService()
    result_bytes = asyncio.run(service.generate_try_on(
        user_image_bytes=user_bytes,
        jewelry_image_bytes=jewelry_bytes,
        jewelry_type="earrings",
        target_anchor="ears"
    ))

    assert result_bytes is not None
    assert len(result_bytes) > 100, "Returned image bytes should not be empty"

    # Step 5: Save Generated Image to PRIVATE Results Bucket with User Path
    result_path = StorageService.upload_generated_result(user_id, req_id, result_bytes)
    assert result_path is not None
    assert len(result_path) > 5

    # Step 6: Generate Signed URL for Authorized User A -> Success
    signed_url_user_a = StorageService.create_signed_result_url(user_id, user_id, result_path)
    assert signed_url_user_a is not None

    # User B attempting access -> Access Denied (None)
    signed_url_user_b = StorageService.create_signed_result_url(user_id, "user_b_unauthorized", result_path)
    assert signed_url_user_b is None

    # Step 7: Finalize Credit Reservation (Consume 1 credit)
    new_balance = CreditService.finalize_reservation(req_id)
    assert new_balance == 0, f"Expected 0 remaining credits, got {new_balance}"

    # Step 8: Delete Temporary Input Files
    StorageService.delete_temporary_request_folder(user_id, req_id)

    # Step 9: Verify Failure Refund Flow (0 credits deducted on failure)
    CreditService.add_credits(user_id, 1, 'subscription_grant', 'ref_008')
    fail_req_id = "test_live_fail_008"
    assert CreditService.reserve_credit(user_id, fail_req_id) is True

    # Simulate failure & release
    refunded_balance = CreditService.release_reservation(fail_req_id)
    assert refunded_balance == 1, f"Expected 1 credit restored on failure, got {refunded_balance}"
