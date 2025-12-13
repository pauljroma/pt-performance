#!/usr/bin/env python3
"""Deploy Auto-Regulation System - Apply all migrations"""
import os
import sys
from pathlib import Path

# Database connection using psycopg2
try:
    import psycopg2
    HAS_PSYCOPG2 = True
except ImportError:
    HAS_PSYCOPG2 = False
    print("⚠️  psycopg2 not available, will use alternative method")

# Connection details from .env
DB_PASSWORD = "rcq!vyd6qtb_HCP5mzt"
PROJECT_REF = "rpbxeaxlaoyoqkohytlw"

# Try direct connection (Transaction mode - port 5432)
DIRECT_URL = f"postgresql://postgres:{DB_PASSWORD}@db.{PROJECT_REF}.supabase.co:5432/postgres"

# Try pooler connection (Session mode - port 6543)
POOLER_URL = f"postgresql://postgres.{PROJECT_REF}:{DB_PASSWORD}@aws-0-us-west-1.pooler.supabase.com:6543/postgres"

MIGRATIONS = [
    "supabase/migrations/20251213000001_seed_nic_roma_patient.sql",
    "supabase/migrations/20251213000003_seed_winter_lift_program.sql",
    "supabase/migrations/20251214000001_add_progression_schema.sql",
    "supabase/migrations/20251215000001_add_readiness_schema.sql",
]

def apply_migration_psycopg2(filepath):
    """Apply migration using psycopg2 direct connection"""
    print(f"\n📝 Applying: {Path(filepath).name}")
    print("=" * 70)

    # Read SQL
    with open(filepath, 'r') as f:
        sql = f.read()

    print(f"   Loaded {len(sql)} characters")

    # Try direct connection first
    for conn_url, conn_type in [(DIRECT_URL, "Direct"), (POOLER_URL, "Pooler")]:
        try:
            print(f"   Trying {conn_type} connection...")
            conn = psycopg2.connect(conn_url)
            conn.autocommit = True
            cursor = conn.cursor()

            # Execute SQL
            cursor.execute(sql)

            cursor.close()
            conn.close()

            print(f"   ✅ Migration applied successfully via {conn_type}")
            return True

        except Exception as e:
            print(f"   ❌ {conn_type} failed: {str(e)[:100]}")
            continue

    return False

def apply_migration_subprocess(filepath):
    """Apply migration using psql subprocess"""
    import subprocess

    print(f"\n📝 Applying: {Path(filepath).name}")
    print("=" * 70)

    with open(filepath, 'r') as f:
        sql = f.read()

    print(f"   Loaded {len(sql)} characters")

    # Try direct connection via psql
    for conn_url, conn_type in [(DIRECT_URL, "Direct"), (POOLER_URL, "Pooler")]:
        try:
            print(f"   Trying {conn_type} connection via psql...")
            result = subprocess.run(
                ['psql', conn_url, '-f', filepath],
                capture_output=True,
                text=True,
                timeout=30
            )

            if result.returncode == 0:
                print(f"   ✅ Migration applied successfully via {conn_type}")
                if result.stdout:
                    print(f"   Output: {result.stdout[:200]}")
                return True
            else:
                print(f"   ❌ {conn_type} failed: {result.stderr[:100]}")

        except subprocess.TimeoutExpired:
            print(f"   ❌ {conn_type} timeout")
        except Exception as e:
            print(f"   ❌ {conn_type} error: {str(e)[:100]}")

    return False

def main():
    print("🚀 AUTO-REGULATION SYSTEM DEPLOYMENT")
    print("=" * 70)
    print()

    # Choose method
    if HAS_PSYCOPG2:
        print("✅ Using psycopg2 for direct database connection")
        apply_func = apply_migration_psycopg2
    else:
        print("✅ Using psql subprocess")
        apply_func = apply_migration_subprocess

    # Apply migrations
    results = {}
    for migration_file in MIGRATIONS:
        if os.path.exists(migration_file):
            success = apply_func(migration_file)
            results[Path(migration_file).name] = success
        else:
            print(f"\n❌ File not found: {migration_file}")
            results[Path(migration_file).name] = False

    # Summary
    print("\n" + "=" * 70)
    print("📊 DEPLOYMENT SUMMARY")
    print("=" * 70)

    for migration, success in results.items():
        status = "✅ APPLIED" if success else "❌ FAILED"
        print(f"{status} - {migration}")

    successful = sum(1 for s in results.values() if s)
    print(f"\nTotal: {successful}/{len(results)} migrations applied")

    if successful == len(results):
        print("\n🎉 All migrations applied successfully!")
        return 0
    else:
        print("\n⚠️  Some migrations failed")
        print("\n💡 Manual application may be required via Supabase SQL Editor:")
        print(f"   https://supabase.com/dashboard/project/{PROJECT_REF}/sql")
        return 1

if __name__ == '__main__':
    sys.exit(main())
