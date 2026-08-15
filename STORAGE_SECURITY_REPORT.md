# JewelTry — Supabase Storage Security & Signed URL Audit Report

**Date**: August 11, 2026  
**Bucket Configuration**: `generated-results` (**PRIVATE Bucket**)  
**Signed URL Expiration**: `3,600 Seconds (1 Hour)`

---

## 🔒 Storage Security Audit Findings

### 1. Private Bucket Enforcement
- **Bucket Type**: Changed `generated-results` to **PRIVATE**.
- **User-Isolated Storage Paths**:
  - `generated-results/{user_id}/{generation_id}.jpg`
  - `temporary-uploads/{user_id}/{request_id}/...`

### 2. Authorization & Signed Short-Lived URLs (`backend/services/storage_service.py`)
- **Flow**: `Flutter` → `FastAPI` → `authenticate user` → `verify generation ownership` → `generate short-lived signed URL` → `Flutter displays result`.
- **User Isolation Verification (`test_private_storage_signed_urls_user_isolation`)**:
  - User A fetching User A's generated result: **ALLOWED** (signed URL generated).
  - User B attempting to fetch User A's generated result: **ACCESS DENIED** (Returns `None` / HTTP 403).

### 3. Automatic Temporary File Cleanup
- Temporary source input images stored in `temporary-uploads/{user_id}/{request_id}/` are automatically deleted after generation completes or fails (`StorageService.delete_temporary_request_folder`).
