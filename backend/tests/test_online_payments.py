from backend.services.payment_service import PaymentService
from backend.services.credit_service import CreditService

def test_online_upi_razorpay_payment_flow():
    user_id = "test_upi_user_99"
    CreditService.reset_mock_state()

    # Step 1: User creates order for 5 Credits pack (₹49)
    order = PaymentService.create_razorpay_order(user_id=user_id, plan_id="credits_5")
    assert order["success"] is True
    assert order["amount_inr"] == 49
    assert order["credits"] == 5

    # Step 2: Simulate successful UPI payment & verify signature
    payment_id = "pay_rzp_mock_live_001"
    success, msg, new_balance = PaymentService.verify_razorpay_payment(
        user_id=user_id,
        plan_id="credits_5",
        razorpay_order_id=order["order_id"],
        razorpay_payment_id=payment_id,
        razorpay_signature="mock_signature_valid"
    )
    assert success is True
    assert new_balance == 6  # 1 initial free credit + 5 purchased

    # Step 3: Duplicate payment token rejection test
    dup_success, dup_msg, _ = PaymentService.verify_razorpay_payment(
        user_id=user_id,
        plan_id="credits_5",
        razorpay_order_id=order["order_id"],
        razorpay_payment_id=payment_id,
        razorpay_signature="mock_signature_valid"
    )
    assert dup_success is False
    assert "already processed" in dup_msg.lower()
