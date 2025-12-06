#!/usr/bin/env python3
"""
Deploy SQL migrations via Supabase REST API
Uses Supabase query endpoint to execute SQL
"""

import os
import sys
from pathlib import Path
from dotenv import load_dotenv
import requests

# Load environment variables
load_dotenv()

MIGRATION_FILES = [
    "infra/005_add_rm_estimate.sql",
    "infra/007_agent_logs_table.sql"
]


def validate_files():
    """Validate migration files exist"""
    print("Validating migration files...")
    missing = []

    for file in MIGRATION_FILES:
        path = Path(file)
        if not path.exists():
            missing.append(file)
            print(f"  ❌ MISSING: {file}")
        else:
            size = path.stat().st_size
            print(f"  ✅ FOUND: {file} ({size:,} bytes)")

    if missing:
        print(f"\n❌ ERROR: Missing files: {missing}")
        return False

    print("\n✅ All migration files validated!\n")
    return True


def execute_sql_via_rest(supabase_url, service_key, sql_content):
    """Execute SQL via Supabase REST API using rpc"""
    # Try using the query endpoint
    # Supabase doesn't expose direct SQL execution through REST API for security reasons

    # Instead, we'll need to use the database's REST API to create tables/columns
    # This is limited and won't work for complex migrations

    print("  ⚠️  Note: Supabase REST API doesn't support arbitrary SQL execution")
    return False


def print_manual_instructions(files):
    """Print manual deployment instructions"""
    print("\n" + "="*80)
    print("📋 MANUAL DEPLOYMENT REQUIRED")
    print("="*80)
    print("\n⚠️  Supabase requires SQL migrations to be deployed via:")
    print("   • Supabase Dashboard SQL Editor (recommended)")
    print("   • Supabase CLI")
    print("   • Direct PostgreSQL connection (requires IP whitelisting)")
    print()
    print("🔗 Quick Link:")
    print("   https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql")
    print()
    print("📝 Steps:")
    print("   1. Click the link above to open SQL Editor")
    print("   2. Click 'New Query'")
    print("   3. Copy/paste the SQL from each file below:")
    print()

    for i, file in enumerate(files, 1):
        print(f"   Migration {i}: {file}")
        print(f"   ---")
        with open(file, 'r') as f:
            content = f.read()
            lines = content.split('\n')
            print(f"   First few lines:")
            for line in lines[:5]:
                if line.strip():
                    print(f"   {line[:70]}{'...' if len(line) > 70 else ''}")
        print(f"   ... ({Path(file).stat().st_size:,} bytes total)")
        print()

    print("   4. Click 'Run' for each migration")
    print("   5. Verify success (no errors)")
    print()
    print("✅ After deployment, run:")
    print("   python3 verify_migrations.py")
    print()


def create_verification_script():
    """Create a script to verify migrations were deployed"""
    script = """#!/usr/bin/env python3
'''
Verify Phase 3 migrations were deployed successfully
'''

import os
from dotenv import load_dotenv
from supabase import create_client

load_dotenv()

supabase_url = os.getenv("SUPABASE_URL")
supabase_key = os.getenv("SUPABASE_KEY")

if not supabase_url or not supabase_key:
    print("❌ Missing SUPABASE_URL or SUPABASE_KEY")
    exit(1)

supabase = create_client(supabase_url, supabase_key)

print("\\n" + "="*80)
print("🔍 VERIFYING PHASE 3 MIGRATIONS")
print("="*80 + "\\n")

# Check 1: rm_estimate column
print("1️⃣ Checking rm_estimate column...")
try:
    # Try to query exercise_logs with rm_estimate
    result = supabase.table('exercise_logs').select('rm_estimate').limit(1).execute()
    print("   ✅ rm_estimate column exists")
except Exception as e:
    if "column" in str(e).lower() and "does not exist" in str(e).lower():
        print("   ❌ rm_estimate column NOT found")
        print(f"   Error: {e}")
    else:
        print(f"   ⚠️  Could not verify: {e}")

# Check 2: agent_logs table
print("\\n2️⃣ Checking agent_logs table...")
try:
    result = supabase.table('agent_logs').select('*').limit(1).execute()
    print("   ✅ agent_logs table exists")
except Exception as e:
    if "does not exist" in str(e).lower():
        print("   ❌ agent_logs table NOT found")
        print(f"   Error: {e}")
    else:
        print(f"   ⚠️  Could not verify: {e}")

print("\\n" + "="*80)
print("✅ VERIFICATION COMPLETE")
print("="*80)
print("\\nIf any checks failed, deploy the corresponding migration.")
"""

    with open("verify_migrations.py", "w") as f:
        f.write(script)

    os.chmod("verify_migrations.py", 0o755)
    print("✅ Created verify_migrations.py")


def main():
    print("\n" + "="*80)
    print("🚀 PHASE 3: SQL MIGRATIONS DEPLOYMENT")
    print("="*80 + "\n")

    # Validate files
    if not validate_files():
        sys.exit(1)

    # Check config
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_KEY") or os.getenv("SUPABASE_SERVICE_ROLE_KEY")

    if not supabase_url:
        print("❌ ERROR: SUPABASE_URL not set")
        sys.exit(1)

    if not supabase_key:
        print("❌ ERROR: SUPABASE_KEY not set")
        sys.exit(1)

    print(f"📍 Target: {supabase_url}")
    print()

    # Print manual instructions
    print_manual_instructions(MIGRATION_FILES)

    # Create verification script
    create_verification_script()


if __name__ == "__main__":
    main()
