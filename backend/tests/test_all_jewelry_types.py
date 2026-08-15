import asyncio
import pytest
from backend.services.gemini_service import GeminiService

JEWELRY_TYPES = [
    ("earrings", "ears"),
    ("necklace", "neck"),
    ("ring", "finger"),
    ("bangle", "wrist"),
    ("bracelet", "wrist"),
    ("nose_pin", "nose"),
    ("chain", "neck/body"),
]

def test_virtual_try_on_all_jewelry_types():
    service = GeminiService()

    with open("assets/images/user_sample.png", "rb") as f:
        user_bytes = f.read()
    with open("assets/images/jewelry_earrings.png", "rb") as f:
        jewelry_bytes = f.read()

    results = {}
    for jewelry_type, target_anchor in JEWELRY_TYPES:
        out_bytes = asyncio.run(service.generate_try_on(
            user_image_bytes=user_bytes,
            jewelry_image_bytes=jewelry_bytes,
            jewelry_type=jewelry_type,
            target_anchor=target_anchor,
        ))
        
        assert out_bytes is not None, f"Failed for {jewelry_type}"
        assert len(out_bytes) > 500, f"Generated output too small for {jewelry_type}"
        results[jewelry_type] = len(out_bytes)

    assert len(results) == 7
