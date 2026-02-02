# Database Snapshot

Create point-in-time backup of Supabase database and upload to S3.

## Trigger

```
/db-snapshot [label]
```

**Examples:**
- `/db-snapshot` - Create snapshot with timestamp label
- `/db-snapshot pre-migration` - Create labeled snapshot
- `/db-snapshot --list` - List existing snapshots

## Prerequisites

1. Supabase project access
2. AWS S3 bucket configured (optional, for remote backup)
3. `pg_dump` available locally

## Execution Steps

### Phase 1: Create Local Backup

```bash
# Get database connection string
# From Supabase Dashboard > Settings > Database

# Create backup using pg_dump
pg_dump "$DATABASE_URL" \
  --format=custom \
  --file="backup-$(date +%Y%m%d-%H%M%S).dump" \
  --no-owner \
  --no-privileges

# Or for plain SQL format
pg_dump "$DATABASE_URL" \
  --format=plain \
  --file="backup-$(date +%Y%m%d-%H%M%S).sql" \
  --no-owner
```

### Phase 2: Upload to S3 (Optional)

```bash
# Upload to S3
aws s3 cp "backup-*.dump" \
  "s3://pt-performance-backups/$(date +%Y/%m)/" \
  --storage-class STANDARD_IA
```

### Phase 3: Record Metadata

```sql
-- Log backup in audit table
INSERT INTO backup_logs (
  filename,
  size_bytes,
  created_at,
  label,
  s3_url
) VALUES (
  'backup-20250130-143022.dump',
  15234567,
  NOW(),
  'pre-migration',
  's3://pt-performance-backups/2025/01/backup-20250130-143022.dump'
);
```

## Output

```
Database Snapshot Complete

Label: pre-migration
Filename: backup-20250130-143022.dump
Size: 14.5 MB
Tables: 45
Rows: ~125,000

Local: ./backups/backup-20250130-143022.dump
S3: s3://pt-performance-backups/2025/01/...

Restore command:
pg_restore -d $DATABASE_URL backup-20250130-143022.dump
```

## Restore from Snapshot

```bash
# Restore from local backup
pg_restore \
  --dbname="$DATABASE_URL" \
  --clean \
  --if-exists \
  backup-20250130-143022.dump

# Restore from S3
aws s3 cp s3://pt-performance-backups/2025/01/backup.dump ./
pg_restore -d $DATABASE_URL backup.dump
```

## Reference

- Supabase Dashboard: https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw
- Database Settings: Settings > Database
