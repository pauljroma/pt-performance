#!/usr/bin/env python3
"""Apply Auto-Regulation System migrations to Supabase"""
import os
import sys
from supabase import create_client

# Configuration from .env
SUPABASE_URL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJwYnhlYXhsYW95b3Frb2h5dGx3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczMzY5NjU1OSwiZXhwIjoyMDQ5MjcyNTU5fQ.hDWnKR4iJ0_dDXG7uTMPXw-FdjNQQTTCjpCW6rvzNxI"

# Migrations to apply in order
MIGRATIONS = [
    "supabase/migrations/20251213000001_seed_nic_roma_patient.sql",
    "supabase/migrations/20251213000003_seed_winter_lift_program.sql",
    "supabase/migrations/20251214000001_add_progression_schema.sql",
    "supabase/migrations/20251215000001_add_readiness_schema.sql"
]

def apply_migration(client, filepath):
    """Apply a single migration file"""
    print(f"\n📝 Applying: {os.path.basename(filepath)}")
    print("=" * 70)

    try:
        # Read SQL file
        with open(filepath, 'r') as f:
            sql_content = f.read()

        print(f"   Loaded {len(sql_content)} characters")

        # Execute SQL using Supabase client's rpc method
        # Note: This executes raw SQL on the database
        result = client.rpc('exec_sql', {'sql': sql_content}).execute()

        print(f"   ✅ Migration applied successfully")
        return True

    except Exception as e:
        # If exec_sql doesn't exist, try direct execution
        print(f"   ⚠️  RPC method failed, trying direct execution: {e}")

        try:
            # Try using the postgrest API directly with SQL statements
            # Split into individual statements
            statements = []
            current = []
            for line in sql_content.split('\n'):
                if line.strip().startswith('--'):
                    continue
                current.append(line)
                if ';' in line:
                    stmt = '\n'.join(current).strip()
                    if stmt and not stmt.startswith('--'):
                        statements.append(stmt)
                    current = []

            print(f"   Found {len(statements)} SQL statements")

            # For now, just report success if file was read
            # Actual execution would require direct database access or SQL editor API
            print(f"   ⚠️  Migration file validated but not executed")
            print(f"   💡 Manual execution required via Supabase SQL Editor")
            return False

        except Exception as e2:
            print(f"   ❌ Error: {e2}")
            return False

def main():
    print("🚀 Auto-Regulation System Migration Deployment")
    print("=" * 70)
    print()

    # Create Supabase client
    supabase = create_client(SUPABASE_URL, SERVICE_ROLE_KEY)
    print(f"✅ Connected to Supabase: {SUPABASE_URL}")

    # Apply each migration
    results = {}
    for migration_file in MIGRATIONS:
        if os.path.exists(migration_file):
            success = apply_migration(supabase, migration_file)
            results[os.path.basename(migration_file)] = success
        else:
            print(f"\n❌ Migration file not found: {migration_file}")
            results[os.path.basename(migration_file)] = False

    # Summary
    print("\n" + "=" * 70)
    print("📊 MIGRATION SUMMARY")
    print("=" * 70)

    for migration, success in results.items():
        status = "✅ APPLIED" if success else "⚠️  PENDING"
        print(f"{status} - {migration}")

    successful = sum(1 for s in results.values() if s)
    print(f"\nTotal: {successful}/{len(results)} migrations applied")

    if successful < len(results):
        print("\n💡 Some migrations require manual execution via Supabase SQL Editor:")
        print(f"   {SUPABASE_URL}/project/rpbxeaxlaoyoqkohytlw/sql")
        return 1

    return 0

if __name__ == '__main__':
    sys.exit(main())
