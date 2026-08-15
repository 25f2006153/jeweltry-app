from abc import ABC, abstractmethod

class BaseAIService(ABC):
    @abstractmethod
    async def generate_try_on(
        self,
        user_image_bytes: bytes,
        jewelry_image_bytes: bytes,
        jewelry_type: str,
        target_anchor: str,
    ) -> bytes:
        """
        Synthesizes a realistic virtual try-on image combining user image and jewelry image.
        Returns generated result image bytes (JPEG/PNG).
        """
        pass
