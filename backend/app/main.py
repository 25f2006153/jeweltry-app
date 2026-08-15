from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from ..core.config import settings
from ..api import try_on, credits, subscriptions, history, payments, admin, account
from ..services.gemini_service import validate_ai_model_compatibility

app = FastAPI(
    title=settings.APP_NAME,
    description="JewelTry AI Virtual Jewelry Try-On Production Backend API",
    version="1.0.0",
)

@app.on_event("startup")
async def startup_event():
    # Validate configured AI_MODEL supports image generation operations
    validate_ai_model_compatibility(settings.AI_MODEL)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API Routers
app.include_router(try_on.router)
app.include_router(credits.router)
app.include_router(subscriptions.router)
app.include_router(history.router)
app.include_router(payments.router)
app.include_router(admin.router)
app.include_router(account.router)

@app.get("/")
async def root():
    return {
        "app": settings.APP_NAME,
        "status": "online",
        "env": settings.APP_ENV,
        "ai_provider": settings.AI_PROVIDER,
        "ai_model": settings.AI_MODEL,
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
