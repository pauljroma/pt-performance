#!/usr/bin/env python3
"""
Agent 1: Deploy Supabase Schema
Applies all schema files to Supabase in correct order
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


def validate_schema_files():
    """Validate all schema files exist"""
    print("Validating schema files...")
    missing = []

    for schema_file in SCHEMA_FILES:
        path = Path(schema_file)
        if not path.exists():
            missing.append(schema_file)
            print(f"  MISSING: {schema_file}")
        else:
            size = path.stat().st_size
            print(f"  FOUND: {schema_file} ({size:,} bytes)")

    if missing:
        print(f"\nERROR: Missing schema files: {missing}")
        return False

    print("\nAll schema files validated successfully!\n")
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


def deploy_with_psql(supabase_url, password):
    """Deploy schema using psql"""
    print("\nDeploying schema with psql...")

    # Parse Supabase URL
    # Format: https://your-project.supabase.co
    if not supabase_url.startswith("https://"):
        print("ERROR: Invalid Supabase URL format")
        return False

    # Extract host
    host = supabase_url.replace("https://", "").replace("http://", "")
    db_host = f"db.{host}"

    for schema_file in SCHEMA_FILES:
        print(f"\nApplying {schema_file}...")

        # Use psql to apply schema
        cmd = [
            "psql",
            f"-h", db_host,
            "-U", "postgres",
            "-d", "postgres",
            "-f", schema_file
        ]

        env = os.environ.copy()
        env["PGPASSWORD"] = password

        try:
            result = subprocess.run(
                cmd,
                env=env,
                capture_output=True,
                text=True,
                timeout=60
            )

            if result.returncode == 0:
                print(f"  SUCCESS: {schema_file} applied")
                if result.stdout:
                    print(f"  Output: {result.stdout[:200]}")
            else:
                print(f"  ERROR: Failed to apply {schema_file}")
                print(f"  Error: {result.stderr}")
                return False

        except FileNotFoundError:
            print("  ERROR: psql command not found. Please install PostgreSQL client.")
            return False
        except subprocess.TimeoutExpired:
            print("  ERROR: Command timed out")
            return False

    print("\nAll schema files deployed successfully!")
    return True


def generate_deployment_summary():
    """Generate summary of what will be deployed"""
    print("\n" + "="*70)
    print("AGENT 1 SCHEMA DEPLOYMENT SUMMARY")
    print("="*70 + "\n")

    total_tables = 0
    total_views = 0
    total_constraints = 0

    for schema_file in SCHEMA_FILES:
        print(f"\n{schema_file}:")

        with open(schema_file, 'r') as f:
            content = f.read()

            # Count tables
            tables = content.count("CREATE TABLE")
            tables += content.count("create table")

            # Count views
            views = content.count("CREATE VIEW")
            views += content.count("create view")
            views += content.count("CREATE OR REPLACE VIEW")
            views += content.count("create or replace view")

            # Count constraints
            constraints = content.count("CHECK (")
            constraints += content.count("check (")

            print(f"  Tables: {tables}")
            print(f"  Views: {views}")
            print(f"  CHECK Constraints: {constraints}")

            total_tables += tables
            total_views += views
            total_constraints += constraints

    print("\n" + "-"*70)
    print(f"TOTALS:")
    print(f"  Total Tables: {total_tables}")
    print(f"  Total Views: {total_views}")
    print(f"  Total CHECK Constraints: {total_constraints}")
    print("="*70 + "\n")

    return {
        "tables": total_tables,
        "views": total_views,
        "constraints": total_constraints
    }


def main():
    print("\n" + "="*70)
    print("AGENT 1: SUPABASE SCHEMA DEPLOYMENT")
    print("="*70 + "\n")

    # Step 1: Validate schema files
    if not validate_schema_files():
        sys.exit(1)

    # Step 2: Generate summary
    summary = generate_deployment_summary()

    # Step 3: Check Supabase config
    supabase_configured = check_supabase_config()

    if not supabase_configured:
        print("\n" + "="*70)
        print("SCHEMA VALIDATION COMPLETE")
        print("="*70)
        print("\nAll schema files are ready to deploy.")
        print("To deploy, please configure SUPABASE_URL in .env and re-run this script.")
        print("\nSchema includes:")
        print(f"  - {summary['tables']} tables")
        print(f"  - {summary['views']} views")
        print(f"  - {summary['constraints']} CHECK constraints")
        print("\nFiles ready:")
        for f in SCHEMA_FILES:
            print(f"  - {f}")
        print("\n" + "="*70 + "\n")
        return

    # Step 4: Deploy
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_password = os.getenv("SUPABASE_PASSWORD") or os.getenv("SUPABASE_KEY")

    if not supabase_password:
        print("\nERROR: SUPABASE_PASSWORD or SUPABASE_KEY not set")
        sys.exit(1)

    success = deploy_with_psql(supabase_url, supabase_password)

    if success:
        print("\n" + "="*70)
        print("DEPLOYMENT COMPLETE")
        print("="*70 + "\n")
    else:
        print("\n" + "="*70)
        print("DEPLOYMENT FAILED")
        print("="*70 + "\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
