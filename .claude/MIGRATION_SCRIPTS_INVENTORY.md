# Migration Scripts Inventory

## Purpose

This file catalogs ALL existing migration scripts and tools to prevent Claude from recreating them every build.

**Rule:** Before creating ANY migration-related script → **CHECK THIS FILE FIRST** → Reuse existing script.

---

## ✅ Scripts That Already Exist - REUSE THESE

### Verification Scripts

| Script | Location | Purpose | Usage | Created |
|--------|----------|---------|-------|---------|
| `apply_migration_direct.py` | Root | Check if table exists via REST API | `python3 apply_migration_direct.py` | Build 32 |
| `refresh_schema_cache.py` | Root | Test schema cache + trigger refresh attempts | `python3 refresh_schema_cache.py` | Build 32 |
| `verify_table_schema.py` | Root | Validate table schema via RPC query | `python3 verify_table_schema.py` | Build 31 |
| `verify_exercise_logs_schema.py` | Root | Build 32 specific - validates exercise_logs table | `python3 verify_exercise_logs_schema.py` | Build 32 |

**Common Pattern:**
All verification scripts use Supabase REST API with these credentials:
- URL: `https://rpbxeaxlaoyoqkohytlw.supabase.co`
- Anon Key: `sb_publishable_bvF02gZep-IdSHFNYVro3g_lNY8hfzr`

### Automation Tools

| Tool | Location | Purpose | Usage | Created |
|------|----------|---------|-------|---------|
| `complete_migration.html` | Root | Browser-based migration assistant with auto-test | `open complete_migration.html` | Build 32 |
| `refresh_schema.sql` | Root | SQL to manually refresh PostgREST cache | Paste in SQL Editor | Build 32 |

**complete_migration.html Features:**
- Auto-tests table existence
- Attempts schema cache refresh
- One-click SQL copy to clipboard
- One-click SQL Editor launch
- Visual status indicators

### Migration SQL Files

| File | Purpose | Status |
|------|---------|--------|
| `supabase/migrations/20251212000001_create_exercise_logs_table.sql.applied` | Create exercise_logs table | ✅ Applied |
| (See `supabase/migrations/` for full list of 23 migrations) | Various schema changes | Mixed |

### Documentation

| File | Purpose | When to Read |
|------|---------|--------------|
| `.claude/MIGRATION_RUNBOOK.md` | **PRIMARY** - Step-by-step execution guide | ALWAYS read FIRST when migration mentioned |
| `.claude/HOW_TO_APPLY_MIGRATIONS.md` | Detailed manual instructions | Reference only |
| `.claude/AUTOMATED_MIGRATIONS.md` | Why automation doesn't work (31 builds history) | Reference only |

---

## 🚨 STOP RECREATING THESE

### Scripts Claude Has Been Recreating Every Build

❌ **DO NOT CREATE:**
- `apply_migration.py` → **USE:** `apply_migration_direct.py`
- `verify_*.py` (generic) → **USE:** `verify_table_schema.py` or `refresh_schema_cache.py`
- `check_*.py` → **USE:** `apply_migration_direct.py`
- HTML automation tools → **USE:** `complete_migration.html`
- Schema verification scripts → **USE:** `refresh_schema_cache.py`
- Table existence checkers → **USE:** `apply_migration_direct.py`

### Pattern to Stop

**OLD (30+ builds):**
```
User: "Apply migration"
→ Create apply_migration.py
→ Create verify_schema.py
→ Create check_table.html
→ Discover same blockers
→ Document why automation failed
→ Apply manually
```

**NEW:**
```
User: "Apply migration"
→ Read MIGRATION_RUNBOOK.md
→ Run apply_migration_direct.py (exists)
→ Open complete_migration.html (exists)
→ Run refresh_schema_cache.py (exists)
→ Done
```

---

## When to CREATE New Scripts

### Only Create If:

1. **New migration SQL** (not a verification script)
   - Use `.claude/migration_template.sql` as starting point
   - Save to `supabase/migrations/YYYYMMDDHHMMSS_description.sql`

2. **Genuinely novel functionality**
   - Example: New table type with special validation requirements
   - Must be clearly different from existing scripts
   - Add to this inventory after creating

3. **User explicitly requests custom automation**
   - Even then, check if existing script can be modified
   - Prefer extending existing scripts over creating new ones

### Before Creating:

1. ✅ Check this inventory
2. ✅ Read existing scripts to see if they can be reused
3. ✅ Ask: "Can I modify an existing script instead?"
4. ✅ If yes to create → Update this inventory after

---

## Script Details & Code Patterns

### apply_migration_direct.py

**What it does:**
```python
# 1. Checks if table exists via GET request
# 2. If exists → Reports success
# 3. If not → Shows manual instructions
```

**When to use:** Step 1 of every migration (pre-flight check)

**Output Examples:**
- `✅ Table already exists!` → Migration done
- `❌ Table does not exist (status: 404)` → Need to apply

### refresh_schema_cache.py

**What it does:**
```python
# 1. Sends OPTIONS request to trigger cache refresh
# 2. Attempts test INSERT to validate schema cache
# 3. Reports if cache is refreshed or still pending
```

**When to use:** Step 4 of every migration (verification)

**Output Examples:**
- `✅ Schema cache refreshed! Table is ready!` → Success
- `❌ Schema cache still not refreshed` → Wait 30-60 seconds

### complete_migration.html

**What it does:**
```javascript
// 1. Auto-runs table existence check on page load
// 2. Provides buttons to refresh & test
// 3. Shows status with visual indicators
// 4. Offers one-click SQL copy + editor launch
```

**When to use:** Step 2 of every migration (automated application)

**Features:**
- Green = Success
- Yellow = Pending
- Red = Error
- Auto-executes on page load

---

## Known Blockers (Don't Try to Solve)

### These Methods Don't Work (31 Builds Confirmed)

| Method | Tool | Error | Why It Fails |
|--------|------|-------|--------------|
| Supabase CLI | `supabase db push` | "Access token not provided" | Requires interactive OAuth login |
| Direct PostgreSQL | `psql` with pooler | "Tenant or user not found" | Auth format incompatible |
| Python psycopg2 | Direct connection | "No route to host" | IPv6 routing blocked |
| REST API | Service role key | "Endpoint not found" | Supabase doesn't expose SQL execution via REST |
| Management API | POST to migrations endpoint | "Not found" | No SQL migration endpoint available |

**Working Method:** Supabase Dashboard SQL Editor (100% success rate, 1 minute)

**Don't waste time trying:**
- New connection string formats
- Different auth methods
- Alternative Supabase APIs
- Network workarounds

---

## Maintenance

### When to Update This Inventory

1. **New script created** (rare, only if genuinely needed)
   - Add to appropriate table above
   - Document purpose, usage, creation date

2. **Script deprecated** (mark as archived)
   - Move entry to "Deprecated" section
   - Note replacement script

3. **Build number references** (update periodically)
   - Keep "Created in Build X" accurate
   - Helps track script age/relevance

### Quarterly Review

Every ~10 builds, review this inventory:
- Are all scripts still relevant?
- Can any be consolidated?
- Are naming conventions consistent?
- Update "Created" dates if needed

---

## Quick Reference Card

**When migration is mentioned:**

1. Read `.claude/MIGRATION_RUNBOOK.md` FIRST
2. Check this inventory for existing scripts
3. Reuse, don't recreate
4. Execute mechanically

**Scripts to memorize:**
- `apply_migration_direct.py` = Pre-flight check
- `complete_migration.html` = Automated application
- `refresh_schema_cache.py` = Verification

**Time saved per migration:** ~5-8 minutes (vs recreating scripts)

---

**Last Updated:** Build 32 (2025-12-12)
**Total Scripts Cataloged:** 9 (4 Python, 2 HTML/SQL, 3 Docs)
**Scripts Prevented from Recreation:** ~20+ over past builds
