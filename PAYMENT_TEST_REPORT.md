# JewelTry — Google Play Billing & Verification Audit Report

**Date**: August 11, 2026  
**API Specification**: Android Publisher `purchases.subscriptionsv2` API & Products API  
**Verification Router**: `POST /api/payments/verify-google-play`

---

## 🛒 Purchase & Verification Flow

```
Flutter (In-App Purchase)
       │ (Sends purchase_token + plan_id + order_id)
       ▼
FastAPI (PaymentService.verify_google_play_purchase)
       │ (1. Checks UNIQUE(purchase_token) DB constraint)
       │ (2. Calls Google Play subscriptionsv2 API)
       ▼
Supabase Database
       │ (Grants credits atomically & records transaction)
       ▼
Flutter UI (Credits Updated)
```

---

## 🛡️ Deduplication & Security Verification

1. **Idempotency & Replay Protection**:
   - `test_subscriptionsv2_purchase_verification` verified that repeating the exact same `purchase_token` returns `purchase_token already processed` and grants **0 additional credits**.
2. **Distinct Verification**:
   - Subscriptions (`starter_monthly` - `premium_monthly`) use `purchases.subscriptionsv2` API.
   - Credit Packs (`credits_5` - `credits_60`) use `purchases.products` API.
