# JewelTry Production Deployment & Infrastructure Guide

This guide provides step-by-step instructions for deploying the **JewelTry** backend to Render, setting up Supabase (PostgreSQL + Storage + Auth), configuring the Gemini AI Virtual Try-On API, and connecting Google Play Billing.

---

## 1. Environment Secrets & Variables Reference

Save these environment variables in your deployment platform (e.g. Render Dashboard / Docker / Kubernetes secret manager):

```env
# Server Config
APP_NAME="JewelTry Backend"
APP_ENV="production"
DEBUG=false
CORS_ORIGINS=["https://jeweltry.app", "http://localhost"]
ADMIN_SECRET_KEY="your-super-secret-admin-key"

# Supabase Credentials (from Supabase Project Settings -> API)
SUPABASE_URL="https://your-project-id.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOi..."
SUPABASE_SERVICE_ROLE_KEY="eyJhbGciOi..."

# AI Engine Configuration
GEMINI_API_KEY="AIzaSy..."
AI_PROVIDER="gemini"
AI_MODEL="gemini-2.5-flash"
AI_OUTPUT_SIZE="1K"
AI_MAX_RETRIES=1
AI_TIMEOUT_SECONDS=60

# Android Google Play Billing Verification
GOOGLE_PLAY_PACKAGE_NAME="com.jeweltry.app"
GOOGLE_APPLICATION_CREDENTIALS="/etc/secrets/google-service-account.json"

# Limits & Storage
MAX_UPLOAD_MB=10
```

---

## 2. Supabase Database & Storage Setup

### Step A: Execute SQL Migration
1. Go to your **Supabase Dashboard** -> **SQL Editor**.
2. Copy and paste the complete contents of `backend/db/schema.sql`.
3. Click **Run** to create:
   - Tables (`profiles`, `plans`, `subscriptions`, `credit_wallets`, `credit_reservations`, `credit_transactions`, `try_on_generations`, `payment_transactions`, `app_config`).
   - Atomic credit functions (`reserve_credit`, `finalize_credit_reservation`, `release_credit_reservation`).
   - Indexes and Row Level Security (RLS) policies.

### Step B: Create Supabase Storage Buckets
1. Navigate to **Supabase Dashboard** -> **Storage**.
2. Create two public buckets:
   - `temporary-uploads` (Public bucket enabled)
   - `generated-results` (Public bucket enabled)

---

## 3. Render FastAPI Deployment

1. Connect your Git repository to [Render.com](https://render.com).
2. Select **New Web Service**.
3. Set the following fields:
   - **Environment**: `Python 3`
   - **Build Command**: `pip install -r backend/requirements.txt`
   - **Start Command**: `uvicorn backend.app.main:app --host 0.0.0.0 --port $PORT`
4. Add all environment variables from `.env.example` in **Environment Variables**.
5. Upload your Google Play Service Account JSON file under **Secret Files** as `/etc/secrets/google-service-account.json`.

---

## 4. Google Play Console Setup

1. Log into **Google Play Console** -> **In-app products** / **Subscriptions**.
2. Create subscription products matching:
   - `starter_monthly` (₹59 / month)
   - `basic_monthly` (₹99 / month)
   - `pro_monthly` (₹199 / month)
   - `premium_monthly` (₹399 / month)
3. Create one-time in-app products matching:
   - `credits_5` (₹49)
   - `credits_12` (₹99)
   - `credits_28` (₹199)
   - `credits_60` (₹399)
4. Link a **Google Cloud Service Account** under **API access** with `androidpublisher` scope and grant permissions.

---

## 5. Production Checks Checklist

- [x] Run `PYTHONPATH=. pytest backend/tests/` -> Verify concurrency credit locks pass.
- [x] Run `flutter analyze` -> 0 errors & 0 warnings.
- [x] Run `flutter test` -> All Flutter tests pass.
- [ ] Set `GEMINI_API_KEY` on Render FastAPI environment.
- [ ] Update `HttpAIService` base URL in Flutter app to your Render HTTPS endpoint (`https://jeweltry-backend.onrender.com`).
