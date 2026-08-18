import base64
import logging
from typing import Optional
from ..core.config import settings
from ..db.database import get_supabase_client

logger = logging.getLogger(__name__)

TEMP_BUCKET = "temporary-uploads"
RESULTS_BUCKET = "generated-results"  # PRIVATE Bucket

class StorageService:
    @staticmethod
    def upload_temporary_image(
        user_id: str,
        request_id: str,
        file_bytes: bytes,
        filename: str,
        mime_type: str = "image/jpeg"
    ) -> str:
        """
        Uploads temporary input photo to user-isolated path:
        temporary-uploads/{user_id}/{request_id}/{filename}
        """
        client = get_supabase_client()
        path = f"{user_id}/{request_id}/{filename}"

        if client is not None:
            try:
                client.storage.from_(TEMP_BUCKET).upload(
                    path=path,
                    file=file_bytes,
                    file_options={"content-type": mime_type, "upsert": "true"}
                )
                return path
            except Exception as e:
                logger.error(f"Supabase storage temporary upload error: {e}")

        # Fallback data URI / mock path for local dev
        b64 = base64.b64encode(file_bytes).decode('utf-8')
        return f"data:{mime_type};base64,{b64[:30]}..."

    @staticmethod
    def upload_generated_result(
        user_id: str,
        generation_id: str,
        file_bytes: bytes,
        mime_type: str = "image/jpeg"
    ) -> str:
        """
        Uploads generated try-on output to PRIVATE user-isolated path:
        generated-results/{user_id}/{generation_id}.jpg
        """
        client = get_supabase_client()
        path = f"{user_id}/{generation_id}.jpg"

        if client is not None:
            try:
                client.storage.from_(RESULTS_BUCKET).upload(
                    path=path,
                    file=file_bytes,
                    file_options={"content-type": mime_type, "upsert": "true"}
                )
                return path
            except Exception as e:
                logger.error(f"Supabase storage result upload error: {e}")

        b64 = base64.b64encode(file_bytes).decode('utf-8')
        return f"data:image/jpeg;base64,{b64}"

    @staticmethod
    def create_signed_result_url(
        user_id: str,
        request_user_id: str,
        generation_id_or_path: str,
        expires_in: int = 3600
    ) -> Optional[str]:
        """
        Security Enforcement:
        Generates short-lived signed URL ONLY if request_user_id matches file owner user_id.
        User A attempting to fetch User B's result receives None (Access Denied).
        """
        # User isolation check
        if user_id != request_user_id:
            logger.warning(f"🔒 Access Denied: User {request_user_id} attempted to access User {user_id}'s result image.")
            return None

        clean_path = generation_id_or_path
        if not clean_path.startswith(f"{user_id}/") and not clean_path.startswith("data:"):
            clean_path = f"{user_id}/{generation_id_or_path}.jpg"

        if clean_path.startswith("data:"):
            return clean_path

        client = get_supabase_client()
        if client is not None:
            try:
                res = client.storage.from_(RESULTS_BUCKET).create_signed_url(
                    path=clean_path,
                    expires_in=expires_in
                )
                if isinstance(res, dict):
                    url = res.get('signedURL') or res.get('signedUrl') or res.get('signed_url')
                    if url:
                        return url
                elif hasattr(res, 'signed_url') and res.signed_url:
                    return res.signed_url
            except Exception as e:
                logger.warning(f"Signed URL creation warning for {clean_path}: {e}")

        # If generation_id_or_path is already base64 or if file exists
        return generation_id_or_path

    @staticmethod
    def delete_temporary_request_folder(user_id: str, request_id: str):
        """Deletes user's temporary input photos after generation."""
        client = get_supabase_client()
        if client is not None:
            try:
                folder_path = f"{user_id}/{request_id}"
                files = client.storage.from_(TEMP_BUCKET).list(folder_path)
                if files:
                    file_paths = [f"{folder_path}/{f['name']}" for f in files]
                    client.storage.from_(TEMP_BUCKET).remove(file_paths)
            except Exception as e:
                logger.warning(f"Error deleting temp folder: {e}")
