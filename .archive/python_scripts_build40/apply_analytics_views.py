#!/usr/bin/env python3
"""
Apply analytics view migrations to Supabase
Creates vw_pain_trend, vw_patient_adherence, and vw_patient_sessions
"""

import os
from supabase import create_client, Client

# Supabase connection (from Config.swift)
SUPABASE_URL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
SUPABASE_KEY = "sb_publishable_bvF02gZep-IdSHFNYVro3g_lNY8hfzr"

def apply_migration(supabase: Client, migration_file: str):
    """Apply a migration file to Supabase"""
    print(f"\n📝 Applying migration: {migration_file}")

    with open(f"supabase/migrations/{migration_file}", 'r') as f:
        sql = f.read()

    try:
        # Execute the SQL using Supabase RPC
        # Note: This requires a function in Supabase that can execute arbitrary SQL
        # For now, we'll extract just the CREATE VIEW statements

        # Extract CREATE VIEW statements
        views = []
        lines = sql.split('\n')
        i = 0
        while i < len(lines):
            line = lines[i].strip()
            if line.startswith('CREATE') and 'VIEW' in line.upper():
                # Collect full CREATE VIEW statement
                view_sql = []
                while i < len(lines):
                    view_sql.append(lines[i])
                    if ';' in lines[i]:
                        break
                    i += 1
                views.append('\n'.join(view_sql))
            i += 1

        print(f"   Found {len(views)} view(s) to create")

        # For Supabase, we need to use postgREST or direct SQL execution
        # Since we can't execute DDL directly via REST API,
        # we'll need to use the SQL editor or connection string

        return views

    except Exception as e:
        print(f"   ❌ Error: {e}")
        return []

def main():
    print("🚀 Applying Analytics View Migrations")
    print("=" * 60)

    # Migrations to apply (in order)
    migrations = [
        "20251211000005_fix_all_schema_mismatches.sql",      # vw_pain_trend, vw_patient_adherence
        "20251211000003_fix_patient_detail_schema.sql",       # vw_patient_sessions
        "20251211000015_fix_security_definer_issues.sql",     # Security fixes
    ]

    # Read and display the SQL for manual application
    print("\n📋 SQL to apply to Supabase SQL Editor:\n")
    print("=" * 60)

    for migration_file in migrations:
        filepath = f"supabase/migrations/{migration_file}"
        if os.path.exists(filepath):
            print(f"\n-- Migration: {migration_file}")
            print("-" * 60)
            with open(filepath, 'r') as f:
                sql = f.read()
                # Extract only CREATE VIEW and ALTER VIEW statements
                for line in sql.split('\n'):
                    if any(keyword in line.upper() for keyword in ['CREATE VIEW', 'ALTER VIEW', 'DROP VIEW', 'GRANT SELECT']):
                        print(line)
        else:
            print(f"⚠️  File not found: {filepath}")

    print("\n" + "=" * 60)
    print("\n✅ Copy the SQL above and run it in Supabase SQL Editor:")
    print("   https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql")
    print("\nOr apply using psql:")
    print("   psql postgres://postgres.[password]@db.rpbxeaxlaoyoqkohytlw.supabase.co:5432/postgres")

if __name__ == "__main__":
    main()
