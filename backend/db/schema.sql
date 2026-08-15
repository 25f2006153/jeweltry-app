-- JewelTry Production Supabase PostgreSQL Schema & Security Policies

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Profiles Table
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Plans & Credit Packs Configuration Table
CREATE TABLE IF NOT EXISTS public.plans (
    id TEXT PRIMARY KEY, -- e.g. 'free', 'starter_monthly', 'basic_monthly', 'pro_monthly', 'premium_monthly', 'credits_5', 'credits_12'
    title TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('subscription', 'one_time_pack')),
    price_inr NUMERIC(10, 2) NOT NULL,
    credits INT NOT NULL,
    google_play_product_id TEXT UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Subscriptions Table
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    plan_id TEXT NOT NULL REFERENCES public.plans(id),
    status TEXT NOT NULL CHECK (status IN ('active', 'canceled', 'expired', 'past_due')),
    purchase_token TEXT UNIQUE,
    current_period_start TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    current_period_end TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Credit Wallets Table
CREATE TABLE IF NOT EXISTS public.credit_wallets (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    balance INT NOT NULL DEFAULT 1 CHECK (balance >= 0),
    reserved INT NOT NULL DEFAULT 0 CHECK (reserved >= 0),
    lifetime_earned INT NOT NULL DEFAULT 1,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Credit Reservations Table (For Atomic Concurrency Lock)
CREATE TABLE IF NOT EXISTS public.credit_reservations (
    request_id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    amount INT NOT NULL DEFAULT 1,
    status TEXT NOT NULL CHECK (status IN ('reserved', 'finalized', 'released')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Credit Transactions Audit Table
CREATE TABLE IF NOT EXISTS public.credit_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    amount INT NOT NULL, -- positive for grants, negative for spend
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('signup_bonus', 'subscription_grant', 'pack_purchase', 'generation_spend', 'refund')),
    reference_id TEXT, -- generation_id or purchase_token
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Try-On Generations History Table
CREATE TABLE IF NOT EXISTS public.try_on_generations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    jewelry_type TEXT NOT NULL,
    target_anchor TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    user_image_url TEXT,
    jewelry_image_url TEXT,
    result_image_url TEXT,
    error_message TEXT,
    processing_time_ms INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. Payment Transactions Table
CREATE TABLE IF NOT EXISTS public.payment_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    plan_id TEXT NOT NULL REFERENCES public.plans(id),
    amount_inr NUMERIC(10, 2) NOT NULL,
    purchase_token TEXT UNIQUE NOT NULL, -- Enforces duplicate purchase token protection!
    order_id TEXT,
    purchase_state TEXT NOT NULL,
    verified_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. App Remote Configuration Table
CREATE TABLE IF NOT EXISTS public.app_config (
    key TEXT PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =========================================================
-- INDEXES FOR 10K-20K USER SCALABILITY
-- =========================================================
CREATE INDEX IF NOT EXISTS idx_try_on_generations_user_id ON public.try_on_generations(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON public.subscriptions(user_id, status);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_token ON public.payment_transactions(purchase_token);
CREATE INDEX IF NOT EXISTS idx_credit_reservations_user ON public.credit_reservations(user_id, status);

-- =========================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =========================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.credit_wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.credit_reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.credit_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.try_on_generations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;

-- Read policies for clients
CREATE POLICY "Users can read own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Anyone can read active plans" ON public.plans FOR SELECT USING (is_active = true);
CREATE POLICY "Users can read own subscriptions" ON public.subscriptions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can read own credit wallet" ON public.credit_wallets FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can read own credit history" ON public.credit_transactions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can read/delete own generations" ON public.try_on_generations FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own generations" ON public.try_on_generations FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "Anyone can read app config" ON public.app_config FOR SELECT USING (true);

-- NO direct client INSERT/UPDATE/DELETE on credit_wallets, subscriptions, payment_transactions!
-- Only Service Role (FastAPI Backend) can modify wallets and billing records.

-- =========================================================
-- ATOMIC CONCURRENCY CREDIT RESERVATION FUNCTIONS
-- =========================================================

-- Function 1: Reserve 1 Credit (Atomic Lock)
CREATE OR REPLACE FUNCTION public.reserve_credit(
    p_user_id UUID,
    p_request_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
    v_balance INT;
    v_reserved INT;
BEGIN
    -- Lock wallet row for update
    SELECT balance, reserved INTO v_balance, v_reserved
    FROM public.credit_wallets
    WHERE user_id = p_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        -- Initialize wallet with 1 free credit if not existing
        INSERT INTO public.credit_wallets (user_id, balance, reserved, lifetime_earned)
        VALUES (p_user_id, 1, 0, 1);
        v_balance := 1;
        v_reserved := 0;
    END IF;

    -- Check if available balance (balance - reserved) >= 1
    IF (v_balance - v_reserved) >= 1 THEN
        -- Reserve 1 credit
        UPDATE public.credit_wallets
        SET reserved = reserved + 1,
            updated_at = NOW()
        WHERE user_id = p_user_id;

        -- Record active reservation
        INSERT INTO public.credit_reservations (request_id, user_id, amount, status)
        VALUES (p_request_id, p_user_id, 1, 'reserved');

        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function 2: Finalize Credit Reservation (Deduct 1 credit on Success)
CREATE OR REPLACE FUNCTION public.finalize_credit_reservation(
    p_request_id UUID
) RETURNS INT AS $$
DECLARE
    v_user_id UUID;
    v_amount INT;
    v_status TEXT;
    v_new_balance INT;
BEGIN
    SELECT user_id, amount, status INTO v_user_id, v_amount, v_status
    FROM public.credit_reservations
    WHERE request_id = p_request_id
    FOR UPDATE;

    IF v_status = 'reserved' THEN
        -- Update reservation state
        UPDATE public.credit_reservations
        SET status = 'finalized', updated_at = NOW()
        WHERE request_id = p_request_id;

        -- Deduct from balance and release reservation lock
        UPDATE public.credit_wallets
        SET balance = balance - v_amount,
            reserved = reserved - v_amount,
            updated_at = NOW()
        RETURNING balance INTO v_new_balance;

        -- Log transaction
        INSERT INTO public.credit_transactions (user_id, amount, transaction_type, reference_id, description)
        VALUES (v_user_id, -v_amount, 'generation_spend', p_request_id::text, 'AI Try-On Generation');

        RETURN v_new_balance;
    ELSE
        SELECT balance INTO v_new_balance FROM public.credit_wallets WHERE user_id = v_user_id;
        RETURN v_new_balance;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function 3: Release Credit Reservation (0 deduction on Failure)
CREATE OR REPLACE FUNCTION public.release_credit_reservation(
    p_request_id UUID
) RETURNS INT AS $$
DECLARE
    v_user_id UUID;
    v_amount INT;
    v_status TEXT;
    v_balance INT;
BEGIN
    SELECT user_id, amount, status INTO v_user_id, v_amount, v_status
    FROM public.credit_reservations
    WHERE request_id = p_request_id
    FOR UPDATE;

    IF v_status = 'reserved' THEN
        UPDATE public.credit_reservations
        SET status = 'released', updated_at = NOW()
        WHERE request_id = p_request_id;

        UPDATE public.credit_wallets
        SET reserved = reserved - v_amount,
            updated_at = NOW()
        RETURNING balance INTO v_balance;

        RETURN v_balance;
    ELSE
        SELECT balance INTO v_balance FROM public.credit_wallets WHERE user_id = v_user_id;
        RETURN v_balance;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =========================================================
-- SEED INITIAL REMOTE APP CONFIG & PLANS
-- =========================================================
INSERT INTO public.plans (id, title, type, price_inr, credits, google_play_product_id) VALUES
('free', 'Free Trial', 'subscription', 0.00, 1, 'free_plan'),
('starter_monthly', 'Starter Monthly', 'subscription', 59.00, 8, 'starter_monthly'),
('basic_monthly', 'Basic Monthly', 'subscription', 99.00, 20, 'basic_monthly'),
('pro_monthly', 'Pro Monthly', 'subscription', 199.00, 40, 'pro_monthly'),
('premium_monthly', 'Premium Monthly', 'subscription', 399.00, 90, 'premium_monthly'),
('credits_5', '5 Credit Top-up', 'one_time_pack', 49.00, 5, 'credits_5'),
('credits_12', '12 Credit Top-up', 'one_time_pack', 99.00, 12, 'credits_12'),
('credits_28', '28 Credit Top-up', 'one_time_pack', 199.00, 28, 'credits_28'),
('credits_60', '60 Credit Top-up', 'one_time_pack', 399.00, 60, 'credits_60')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.app_config (key, value, description) VALUES
('ai_settings', '{"provider": "gemini", "model": "gemini-2.5-flash", "output_size": "1K", "timeout_seconds": 60}'::jsonb, 'Remote AI model configuration'),
('upload_settings', '{"max_upload_mb": 10, "allowed_mimes": ["image/jpeg", "image/png", "image/webp"]}'::jsonb, 'Upload file limits'),
('business_metrics_estimates', '{"gemini_cost_per_image_inr": 2.50, "hosting_cost_monthly_inr": 1500.00, "storage_cost_per_gb_inr": 15.00, "payment_gateway_fee_percent": 1.5}'::jsonb, 'Configurable admin metrics estimation factors')
ON CONFLICT (key) DO NOTHING;
