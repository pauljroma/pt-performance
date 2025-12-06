#!/usr/bin/env python3
"""
Deploy Phase 3 SQL Migrations to Supabase
Deploys 005_add_rm_estimate.sql and 007_agent_logs_table.sql
"""

import os
import sys
from pathlib import Path
import subprocess
from dotenv import load_dotenv

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


def deploy_with_psql(supabase_url, password):
    """Deploy migrations using psql"""
    print("Deploying migrations with psql...")

    # Parse Supabase URL
    if not supabase_url.startswith("https://"):
        print("❌ ERROR: Invalid Supabase URL format")
        return False

    # Extract host
    host = supabase_url.replace("https://", "").replace("http://", "")
    db_host = f"db.{host}"

    for file in MIGRATION_FILES:
        print(f"\n📝 Applying {file}...")

        cmd = [
            "psql",
            f"-h", db_host,
            "-U", "postgres",
            "-d", "postgres",
            "-f", file
        ]

        env = os.environ.copy()
        env["PGPASSWORD"] = password

        try:
            result = subprocess.run(
                cmd,
                env=env,
                capture_output=True,
                text=True,
                timeout=120
            )

            if result.returncode == 0:
                print(f"  ✅ SUCCESS: {file} applied")
                # Show notices/output
                if result.stdout:
                    for line in result.stdout.split('\n'):
                        if line.strip():
                            print(f"     {line}")
            else:
                print(f"  ❌ ERROR: Failed to apply {file}")
                print(f"  Error: {result.stderr}")
                return False

        except FileNotFoundError:
            print("  ❌ ERROR: psql not found. Install PostgreSQL client.")
            return False
        except subprocess.TimeoutExpired:
            print("  ❌ ERROR: Command timed out")
            return False

    print("\n✅ All migrations deployed successfully!")
    return True


def main():
    print("\n" + "="*80)
    print("🚀 PHASE 3: SQL MIGRATIONS DEPLOYMENT")
    print("="*80 + "\n")

    # Validate files
    if not validate_files():
        sys.exit(1)

    # Check config
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_password = os.getenv("SUPABASE_PASSWORD") or os.getenv("SUPABASE_SERVICE_KEY")

    if not supabase_url:
        print("❌ ERROR: SUPABASE_URL not set")
        sys.exit(1)

    if not supabase_password:
        print("❌ ERROR: SUPABASE_PASSWORD or SUPABASE_SERVICE_KEY not set")
        sys.exit(1)

    print(f"📍 Target: {supabase_url}")
    print()

    # Deploy
    success = deploy_with_psql(supabase_url, supabase_password)

    if success:
        print("\n" + "="*80)
        print("✅ DEPLOYMENT COMPLETE")
        print("="*80)
        print("\nDeployed migrations:")
        for file in MIGRATION_FILES:
            print(f"  ✅ {file}")
        print()
    else:
        print("\n" + "="*80)
        print("❌ DEPLOYMENT FAILED")
        print("="*80)
        sys.exit(1)


if __name__ == "__main__":
    main()
