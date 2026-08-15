# JewelTry — Database Backup & Disaster Recovery Guide

---

## 💾 1. Database Backup Strategy

### Daily Automatic Point-in-Time Recovery (PITR)
- Supabase automatically maintains WAL (Write-Ahead Logging) archives enabling point-in-time recovery up to 7 days on production tiers.

### Manual Database Dump Command
To take an immediate snapshot dump of your PostgreSQL database:

```bash
pg_dump --clean --if-exists \
  --quote-all-identifiers \
  --exclude-schema 'auth' \
  --exclude-schema 'storage' \
  -h db.your-project.supabase.co \
  -U postgres \
  -d postgres > backup_jeweltry_$(date +%Y%m%d).sql
```

---

## 🔄 2. Disaster Recovery & Restoration

### Restoring Schema & Tables
1. Open Supabase Dashboard -> **SQL Editor**.
2. Run `backend/db/schema.sql` to re-initialize tables, indexes, RLS policies, and atomic credit functions.
3. If restoring from dump:
   ```bash
   psql -h db.your-project.supabase.co -U postgres -d postgres < backup_jeweltry_20260811.sql
   ```

---

## 📁 3. Supabase Storage Backup & Recovery

1. Bucket recovery: Re-create buckets `temporary-uploads` and `generated-results` if deleted.
2. File assets in `generated-results` are served via public URLs referenced in `try_on_generations.result_image_url`.
