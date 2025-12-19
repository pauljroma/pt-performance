# Schema Validation Guide

**Purpose:** Prevent iOS-database schema mismatches that cause runtime decoding errors.

**Context:** Build 44 had 5 schema mismatches (missing columns, nullability mismatches, enum value differences) that were only discovered in production. This system catches those issues before deployment.

---

## Quick Start

### Run Locally

```bash
# From project root
python3 scripts/validate_ios_schema.py --verbose
```

### Expected Output (Success)

```
================================================================================
Schema Validation Report
================================================================================

Models checked: 12
Tables checked: 12
Errors: 0
Warnings: 0

✅ All schemas match!

================================================================================
```

### Expected Output (Failure)

```
================================================================================
Schema Validation Report
================================================================================

Models checked: 12
Tables checked: 12
Errors: 2
Warnings: 1

❌ ERRORS (Blocking):

1. [MISSING_COLUMN] WorkloadFlag -> workload_flags
   Column 'flag_type' expected by Swift property 'flagType' not found in table
   Fix: Add column 'flag_type' to table 'workload_flags' or update CodingKeys mapping

2. [NULLABILITY_MISMATCH] Program -> programs
   Column 'target_level' is nullable in DB but non-optional in Swift (targetLevel: String)
   Fix: Either make Swift property optional ('targetLevel?') or add NOT NULL constraint to database column

⚠️  WARNINGS (Non-blocking):

1. [EXTRA_COLUMN] Patient -> patients
   Column 'legacy_id' exists in database but not in Swift model
   Suggestion: Add property to Swift model or remove column from database (if unused)

================================================================================
```

---

## How It Works

### 1. Parse Swift Models

The script scans `ios-app/PTPerformance/Models/*.swift` and extracts:
- Struct names
- Property names and types
- Optional vs required properties
- `CodingKeys` enum mappings

**Example:**
```swift
struct Patient: Codable {
    let id: String
    let therapistId: String
    let firstName: String
    let sport: String?  // ← Optional

    enum CodingKeys: String, CodingKey {
        case id
        case therapistId = "therapist_id"  // ← Maps to database column
        case firstName = "first_name"
        case sport
    }
}
```

### 2. Query Database Schema

Queries Supabase `information_schema.columns` to get:
- Table names
- Column names and types
- Nullable vs NOT NULL constraints
- Primary keys

### 3. Compare and Report

For each Swift model:
1. Find corresponding database table (via `model_to_table_map`)
2. For each `CodingKeys` entry, verify database column exists
3. Check nullability matches (optional in Swift ↔ nullable in DB)
4. Report mismatches with severity and remediation steps

---

## Configuration

### Database Connection

The script needs access to your Supabase database. Set the connection string:

```bash
export SUPABASE_DB_URL="postgresql://user:pass@host:port/database"
```

Or create `.env` file in project root:

```env
SUPABASE_DB_URL=postgresql://postgres.xxx:password@aws-0-us-west-2.pooler.supabase.com:5432/postgres
```

### Model-to-Table Mapping

If a Swift model name doesn't match the database table name, update the mapping in `validate_ios_schema.py`:

```python
self.model_to_table_map = {
    "Patient": "patients",       # Patient.swift → patients table
    "WorkloadFlag": "workload_flags",  # WorkloadFlag.swift → workload_flags table
    # Add new mappings here...
}
```

---

## CI/CD Integration

### GitHub Actions

Schema validation runs automatically on:
- Every pull request that touches models or migrations
- Every push to `main` branch

**Workflow:** `.github/workflows/schema-validation.yml`

**Secrets Required:**
- `SUPABASE_DB_URL` - Database connection string

**How to Add Secret:**
```bash
# Go to GitHub repo → Settings → Secrets and variables → Actions
# Click "New repository secret"
# Name: SUPABASE_DB_URL
# Value: postgresql://...
```

### Pre-Commit Hook

For even faster feedback, run validation before every commit:

```bash
# Install pre-commit hook
cp scripts/pre-commit-schema-validation.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

Now schema validation runs automatically before each commit. Skip with:

```bash
git commit --no-verify  # Skip validation
```

---

## Common Issues

### Issue 1: Missing Column

**Error:**
```
[MISSING_COLUMN] WorkloadFlag -> workload_flags
Column 'flag_type' expected by Swift property 'flagType' not found in table
```

**Causes:**
1. Database migration not applied
2. Wrong column name in CodingKeys
3. Model references wrong table

**Fixes:**
- Apply missing migration: `supabase migration up`
- Update CodingKeys: `case flagType = "correct_column_name"`
- Update model_to_table_map if model references wrong table

---

### Issue 2: Nullability Mismatch

**Error:**
```
[NULLABILITY_MISMATCH] Program -> programs
Column 'target_level' is nullable in DB but non-optional in Swift
```

**Causes:**
1. Database allows NULL but Swift expects value
2. Default value not set in database

**Fixes:**

**Option A:** Make Swift property optional (safer if data can be null)
```swift
let targetLevel: String?  // Add ?
```

**Option B:** Add NOT NULL constraint in database
```sql
ALTER TABLE programs
ALTER COLUMN target_level SET NOT NULL,
ALTER COLUMN target_level SET DEFAULT 'Intermediate';

UPDATE programs SET target_level = 'Intermediate' WHERE target_level IS NULL;
```

---

### Issue 3: Enum Value Mismatch

**Error:**
```
Database has severity values: 'low', 'medium', 'high'
Swift expects: 'yellow', 'red'
```

**Causes:**
1. Enum values changed in Swift but not in database
2. Database seeded with old enum values

**Fixes:**

**Update database to match Swift:**
```sql
UPDATE workload_flags
SET severity = CASE
    WHEN severity = 'high' THEN 'red'
    WHEN severity IN ('medium', 'low') THEN 'yellow'
END;

ALTER TABLE workload_flags DROP CONSTRAINT severity_check;
ALTER TABLE workload_flags ADD CONSTRAINT severity_check
    CHECK (severity IN ('yellow', 'red'));
```

---

### Issue 4: Extra Column Warning

**Warning:**
```
[EXTRA_COLUMN] Patient -> patients
Column 'legacy_id' exists in database but not in Swift model
```

**Causes:**
1. Database has columns not used by iOS app
2. Deprecated columns not removed

**Fixes:**

**Option A:** Add to Swift model (if needed)
```swift
let legacyId: String?

enum CodingKeys: String, CodingKey {
    // ...
    case legacyId = "legacy_id"
}
```

**Option B:** Remove from database (if truly unused)
```sql
ALTER TABLE patients DROP COLUMN legacy_id;
```

**Note:** Extra columns are **warnings**, not errors. They don't block deployment.

---

## Adding New Models

When creating a new Swift model:

1. **Create the model file:** `ios-app/PTPerformance/Models/NewModel.swift`

2. **Add CodingKeys enum:**
```swift
struct NewModel: Codable {
    let id: String
    let someProp: String
    let optionalProp: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case someProp = "some_prop"  // ← Map to database column
        case optionalProp = "optional_prop"
    }
}
```

3. **Add table mapping** (if table name differs from model name):
```python
# In validate_ios_schema.py
self.model_to_table_map = {
    # ...
    "NewModel": "new_models",  # Add this line
}
```

4. **Run validation:**
```bash
python3 scripts/validate_ios_schema.py --verbose
```

5. **Fix any mismatches** before committing

---

## Testing

### Test Against Local Database

```bash
# Point to local Supabase
export SUPABASE_DB_URL="postgresql://postgres:postgres@localhost:54322/postgres"

python3 scripts/validate_ios_schema.py
```

### Test Against Staging

```bash
# Point to staging database
export SUPABASE_DB_URL="postgresql://user:pass@staging-host:5432/postgres"

python3 scripts/validate_ios_schema.py
```

### Test Script Changes

```bash
# Add print statements for debugging
python3 scripts/validate_ios_schema.py --verbose
```

---

## Troubleshooting

### Script Can't Find Models Directory

**Error:** `Error: Cannot find Models directory`

**Fix:**
```bash
# Run from project root
cd /path/to/project
python3 scripts/validate_ios_schema.py
```

### psql Command Not Found

**Error:** `Error: psql command not found`

**Fix:**
```bash
# macOS
brew install postgresql

# Ubuntu/Debian
sudo apt-get install postgresql-client

# Or use Python library (psycopg2) - requires code change
```

### Database Connection Timeout

**Error:** `Error querying database: connection timeout`

**Fix:**
- Check database URL is correct
- Check firewall allows connection
- Check database is running
- Try with `psql` directly: `psql "$SUPABASE_DB_URL" -c "SELECT 1"`

---

## Best Practices

### 1. Run Before Every Migration

```bash
# Before applying migration
python3 scripts/validate_ios_schema.py

# Apply migration
supabase migration up

# Validate again
python3 scripts/validate_ios_schema.py
```

### 2. Run Before Every Model Change

```bash
# After modifying Swift model
python3 scripts/validate_ios_schema.py

# If errors, fix model or database
# Then validate again
```

### 3. Check CI Before Merging

Always wait for schema validation to pass in GitHub Actions before merging PR.

### 4. Don't Skip Validation

Even if you're "sure" the schema matches, run validation. Build 44 taught us that manual checks miss things.

---

## Future Enhancements

Potential improvements:

1. **Auto-fix mode:** Automatically generate migration SQL to fix mismatches
2. **Type checking:** Verify Swift types match PostgreSQL types (String ↔ text/varchar)
3. **Reverse validation:** Check all database columns have corresponding Swift properties
4. **Performance:** Cache database schema to speed up repeated runs
5. **Web UI:** Visual diff of schemas with one-click fixes

---

## Exit Codes

- `0` - All schemas match perfectly
- `1` - Errors detected (blocks deployment)
- `2` - Warnings only (doesn't block deployment)

Use in scripts:

```bash
if python3 scripts/validate_ios_schema.py; then
    echo "Safe to deploy"
else
    echo "Fix schema issues first"
    exit 1
fi
```

---

## Related Documentation

- [Migration Testing Guide](./MIGRATION_TESTING.md)
- [RLS Policies](./RLS_POLICIES.md)
- [Build 44 Schema Fixes](./.outcomes/BUILD_44_ALL_SCHEMA_FIXES_COMPLETE.md)

---

## Support

**Issues:** Create issue in Linear with label `schema-validation`

**Questions:** Check existing Linear issues or ask in team chat

**Urgent:** If schema validation is blocking deployment, can be temporarily disabled with `--no-verify` git flag or by removing GitHub Actions workflow. **Not recommended!**

---

**Last Updated:** 2025-12-15 (Build 45)
**Owner:** Build 45 Swarm Agent 1
