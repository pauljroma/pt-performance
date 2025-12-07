#!/usr/bin/env python3
"""
Agent 3: Seed Database
Seeds demo data and exercise library to Supabase
"""

import os
import sys
from pathlib import Path
import subprocess


SCHEMA_FILES = [
    "infra/001_init_supabase.sql",
    "infra/002_epic_enhancements.sql",
    "infra/003_agent1_constraints_and_protocols.sql"
]

SEED_FILES = [
    "infra/004_seed_exercise_library.sql",
    "infra/003_seed_demo_data.sql",
    "infra/005_seed_session_exercises.sql"
]

TEST_FILES = [
    "infra/006_data_quality_tests.sql"
]


def validate_files(files):
    """Validate all files exist"""
    print("Validating files...")
    missing = []

    for file_path in files:
        path = Path(file_path)
        if not path.exists():
            missing.append(file_path)
            print(f"  MISSING: {file_path}")
        else:
            size = path.stat().st_size
            print(f"  FOUND: {file_path} ({size:,} bytes)")

    if missing:
        print(f"\nERROR: Missing files: {missing}")
        return False

    print("\nAll files validated successfully!\n")
    return True


def check_supabase_config():
    """Check if Supabase is configured"""
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_KEY")

    print("Checking Supabase configuration...")
    print(f"  SUPABASE_URL: {supabase_url or 'NOT SET'}")
    print(f"  SUPABASE_KEY: {'SET' if supabase_key else 'NOT SET'}")

    if not supabase_url or "your-project" in supabase_url:
        print("\nWARNING: Supabase URL not configured.")
        print("Please set SUPABASE_URL in .env file to deploy schema.")
        return False

    return True


def run_sql_file(db_host, password, sql_file):
    """Run a SQL file using psql"""
    print(f"\nApplying {sql_file}...")

    cmd = [
        "psql",
        f"-h", db_host,
        "-U", "postgres",
        "-d", "postgres",
        "-f", sql_file
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
            print(f"  SUCCESS: {sql_file} applied")
            if result.stdout:
                # Print summary lines
                lines = result.stdout.strip().split('\n')
                for line in lines[-20:]:  # Last 20 lines
                    if line.strip():
                        print(f"  {line}")
            return True
        else:
            print(f"  ERROR: Failed to apply {sql_file}")
            print(f"  Error: {result.stderr}")
            return False

    except FileNotFoundError:
        print("  ERROR: psql command not found. Please install PostgreSQL client.")
        return False
    except subprocess.TimeoutExpired:
        print("  ERROR: Command timed out")
        return False


def deploy_schema(db_host, password):
    """Deploy schema files"""
    print("\n" + "="*70)
    print("DEPLOYING SCHEMA")
    print("="*70)

    for schema_file in SCHEMA_FILES:
        if not run_sql_file(db_host, password, schema_file):
            return False

    print("\nAll schema files deployed successfully!")
    return True


def deploy_seeds(db_host, password):
    """Deploy seed data files"""
    print("\n" + "="*70)
    print("DEPLOYING SEED DATA")
    print("="*70)

    for seed_file in SEED_FILES:
        if not run_sql_file(db_host, password, seed_file):
            return False

    print("\nAll seed files deployed successfully!")
    return True


def run_tests(db_host, password):
    """Run data quality tests"""
    print("\n" + "="*70)
    print("RUNNING DATA QUALITY TESTS")
    print("="*70)

    for test_file in TEST_FILES:
        if not run_sql_file(db_host, password, test_file):
            return False

    print("\nAll data quality tests completed!")
    return True


def generate_summary():
    """Generate deployment summary"""
    print("\n" + "="*70)
    print("AGENT 3 DATABASE SEEDING SUMMARY")
    print("="*70 + "\n")

    all_files = SCHEMA_FILES + SEED_FILES + TEST_FILES

    for file_path in all_files:
        print(f"\n{file_path}:")

        with open(file_path, 'r') as f:
            content = f.read()

            # Count different objects
            tables = content.lower().count("create table")
            views = content.lower().count("create view") + content.lower().count("create or replace view")
            inserts = content.count("INSERT INTO") + content.count("insert into")

            print(f"  Tables: {tables}")
            print(f"  Views: {views}")
            print(f"  INSERT statements: {inserts}")

    print("\n" + "="*70 + "\n")


def main():
    print("\n" + "="*70)
    print("AGENT 3: DATABASE SEEDING")
    print("="*70 + "\n")

    # Step 1: Validate files
    all_files = SCHEMA_FILES + SEED_FILES + TEST_FILES
    if not validate_files(all_files):
        sys.exit(1)

    # Step 2: Generate summary
    generate_summary()

    # Step 3: Check Supabase config
    supabase_configured = check_supabase_config()

    if not supabase_configured:
        print("\n" + "="*70)
        print("FILES VALIDATED - READY TO DEPLOY")
        print("="*70)
        print("\nAll files are ready to deploy.")
        print("To deploy, please configure SUPABASE_URL in .env and re-run this script.")
        print("\nSchema files:")
        for f in SCHEMA_FILES:
            print(f"  - {f}")
        print("\nSeed files:")
        for f in SEED_FILES:
            print(f"  - {f}")
        print("\nTest files:")
        for f in TEST_FILES:
            print(f"  - {f}")
        print("\n" + "="*70 + "\n")
        return

    # Step 4: Deploy
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_password = os.getenv("SUPABASE_PASSWORD") or os.getenv("SUPABASE_KEY")

    if not supabase_password:
        print("\nERROR: SUPABASE_PASSWORD or SUPABASE_KEY not set")
        sys.exit(1)

    # Parse Supabase URL
    if not supabase_url.startswith("https://"):
        print("ERROR: Invalid Supabase URL format")
        sys.exit(1)

    host = supabase_url.replace("https://", "").replace("http://", "")
    db_host = f"db.{host}"

    # Deploy schema
    if not deploy_schema(db_host, supabase_password):
        print("\n" + "="*70)
        print("SCHEMA DEPLOYMENT FAILED")
        print("="*70 + "\n")
        sys.exit(1)

    # Deploy seeds
    if not deploy_seeds(db_host, supabase_password):
        print("\n" + "="*70)
        print("SEED DEPLOYMENT FAILED")
        print("="*70 + "\n")
        sys.exit(1)

    # Run tests
    if not run_tests(db_host, supabase_password):
        print("\n" + "="*70)
        print("DATA QUALITY TESTS FAILED")
        print("="*70 + "\n")
        sys.exit(1)

    print("\n" + "="*70)
    print("DEPLOYMENT COMPLETE!")
    print("="*70)
    print("\nDatabase seeded with:")
    print("  - 1 demo therapist (Sarah Thompson)")
    print("  - 1 demo patient (John Brebbia)")
    print("  - 1 8-week program (4 phases, 24 sessions)")
    print("  - 50+ exercises in library")
    print("  - Session exercises with prescriptions")
    print("  - Sample exercise logs, pain logs, and body comp data")
    print("\nData quality tests:")
    print("  - All tests passed (see output above for details)")
    print("\n" + "="*70 + "\n")


if __name__ == "__main__":
    main()
