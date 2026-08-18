import os
from typing import List, Optional
try:
    from pydantic_settings import BaseSettings
except ImportError:
    from pydantic import BaseModel as BaseSettings

class Settings(BaseSettings):
    # App Environment
    APP_NAME: str = "JewelTry Backend"
    APP_ENV: str = "production"
    DEBUG: bool = False
    CORS_ORIGINS: List[str] = ["*", "https://jeweltry-app.vercel.app", "https://jeweltry.app", "http://localhost:8080"]
    
    # Supabase Configuration
    SUPABASE_URL: str = "http://localhost:54321"
    SUPABASE_ANON_KEY: str = "mock-anon-key"
    SUPABASE_SERVICE_ROLE_KEY: str = "mock-service-role-key"
    
    # AI Engine Configuration (Gemini 3.1 Flash Image)
    GEMINI_API_KEY: Optional[str] = None
    AI_PROVIDER: str = "gemini"
    AI_MODEL: str = "gemini-3.1-flash-image"
    AI_OUTPUT_SIZE: str = "1K"
    AI_MAX_RETRIES: int = 1
    AI_TIMEOUT_SECONDS: int = 60
    
    # Pricing & Currency
    EXCHANGE_RATE_USD_INR: float = 86.50
    SIGNED_URL_EXPIRATION_SECONDS: int = 3600
    
    # Android Google Play Billing Verification (subscriptionsv2 API)
    GOOGLE_PLAY_PACKAGE_NAME: str = "com.jeweltry.app"
    GOOGLE_APPLICATION_CREDENTIALS: Optional[str] = None
    GOOGLE_PLAY_SERVICE_ACCOUNT_JSON: Optional[str] = None
    
    # Online Payment Gateway (Razorpay / UPI for Web & Instant In-App)
    RAZORPAY_KEY_ID: Optional[str] = "rzp_test_jeweltry"
    RAZORPAY_KEY_SECRET: Optional[str] = "secret_jeweltry_demo"
    
    # Upload & Security Limits
    MAX_UPLOAD_MB: int = 10
    ADMIN_SECRET_KEY: str = "jeweltry-admin-secret-2026"
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        extra = "ignore"

settings = Settings()
