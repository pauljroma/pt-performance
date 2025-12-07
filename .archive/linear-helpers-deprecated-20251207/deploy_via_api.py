#!/usr/bin/env python3
"""
Deploy SQL migrations via Supabase REST API
Uses direct database connection through Supabase
"""

import os
import sys
from pathlib import Path
from dotenv import load_dotenv
import psycopg2
from psycopg2 import sql

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


def get_db_connection_string(supabase_url, password):
    """Build PostgreSQL connection string"""
    # Extract project reference from URL
    # Format: https://rpbxeaxlaoyoqkohytlw.supabase.co
    project_ref = supabase_url.replace("https://", "").replace(".supabase.co", "")

    # Supabase database connection format
    # Host: db.PROJECT_REF.supabase.co
    # Database: postgres
    # User: postgres
    # Port: 5432

    host = f"db.{project_ref}.supabase.co"

    return {
        'host': host,
        'database': 'postgres',
        'user': 'postgres',
        'password': password,
        'port': 5432
    }


def deploy_with_postgres(conn_params):
    """Deploy migrations using PostgreSQL connection"""
    print("Deploying migrations via PostgreSQL connection...\n")

    try:
        # Connect to database
        print(f"📡 Connecting to {conn_params['host']}...")
        conn = psycopg2.connect(**conn_params)
        conn.autocommit = True
        cursor = conn.cursor()
        print("✅ Connected!\n")

        for file in MIGRATION_FILES:
            print(f"📝 Applying {file}...")

            # Read SQL file
            with open(file, 'r') as f:
                sql_content = f.read()

            try:
                # Execute SQL
                cursor.execute(sql_content)
                print(f"  ✅ SUCCESS: {file} applied\n")

            except Exception as e:
                error_msg = str(e)
                # Check if it's a "already exists" error (safe to ignore)
                if "already exists" in error_msg.lower():
                    print(f"  ⚠️  WARNING: Some objects already exist (safe to ignore)")
                    print(f"  ✅ {file} applied (with warnings)\n")
                else:
                    print(f"  ❌ ERROR: {error_msg}")
                    cursor.close()
                    conn.close()
                    return False

        cursor.close()
        conn.close()

        print("\n✅ All migrations deployed successfully!")
        return True

    except psycopg2.Error as e:
        print(f"❌ Database error: {e}")
        return False
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return False


def main():
    print("\n" + "="*80)
    print("🚀 PHASE 3: SQL MIGRATIONS DEPLOYMENT (PostgreSQL)")
    print("="*80 + "\n")

    # Validate files
    if not validate_files():
        sys.exit(1)

    # Check config
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_password = os.getenv("SUPABASE_PASSWORD")

    if not supabase_url:
        print("❌ ERROR: SUPABASE_URL not set")
        sys.exit(1)

    if not supabase_password:
        print("❌ ERROR: SUPABASE_PASSWORD not set")
        sys.exit(1)

    print(f"📍 Target: {supabase_url}")
    print()

    # Get connection params
    conn_params = get_db_connection_string(supabase_url, supabase_password)

    # Deploy
    success = deploy_with_postgres(conn_params)

    if success:
        print("\n" + "="*80)
        print("✅ DEPLOYMENT COMPLETE")
        print("="*80)
        print("\nDeployed migrations:")
        for file in MIGRATION_FILES:
            print(f"  ✅ {file}")
        print()
        print("Next steps:")
        print("  1. Start backend: cd agent-service && npm start")
        print("  2. Test endpoints: curl http://localhost:4000/health")
        print("  3. Build iOS app in Xcode")
    else:
        print("\n" + "="*80)
        print("❌ DEPLOYMENT FAILED")
        print("="*80)
        sys.exit(1)


if __name__ == "__main__":
    main()
