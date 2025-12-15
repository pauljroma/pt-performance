#!/usr/bin/env python3
"""Apply workload flags schema fix migration"""

import psycopg2
import sys

# Supabase connection string
CONN_STR = "postgresql://postgres.rpbxeaxlaoyoqkohytlw:rcq!vyd6qtb_HCP5mzt@aws-0-us-west-2.pooler.supabase.com:5432/postgres"

# Read migration SQL from file
with open('supabase/migrations/20251214160000_fix_workload_flags_schema.sql', 'r') as f:
    MIGRATION_SQL = f.read()

def apply_migration():
    """Apply the workload flags schema fix migration"""
    try:
        print("🔄 Connecting to Supabase database...")
        conn = psycopg2.connect(CONN_STR)
        print("✅ Connected successfully")

        cursor = conn.cursor()

        print("🔄 Executing migration SQL...")
        cursor.execute(MIGRATION_SQL)
        print("✅ Migration SQL executed successfully")

        # Commit the changes
        conn.commit()
        print("✅ Changes committed")

        # Verify the changes
        print("\n🔍 Verifying changes...")

        verify_sql = """
        SELECT
          column_name,
          data_type,
          is_nullable,
          column_default
        FROM information_schema.columns
        WHERE table_name = 'workload_flags'
        AND column_name IN ('flag_type', 'message', 'value', 'threshold', 'timestamp', 'severity')
        ORDER BY column_name;
        """

        cursor.execute(verify_sql)
        results = cursor.fetchall()

        print("\n✅ Verification Results:")
        for row in results:
            column, dtype, nullable, default = row
            null_str = 'NULL' if nullable == 'YES' else 'NOT NULL'
            default_str = f' DEFAULT {default}' if default else ''
            print(f"  • {column}: {dtype} {null_str}{default_str}")

        # Check data
        print("\n🔍 Checking existing workload flags data...")
        cursor.execute("""
            SELECT id, flag_type, severity, message, value, threshold
            FROM workload_flags
            LIMIT 3;
        """)

        flags = cursor.fetchall()
        print(f"\n✅ Found {len(flags)} workload flags:")
        for flag in flags:
            flag_id, flag_type, severity, message, value, threshold = flag
            print(f"  • {flag_type} ({severity}): {message}")
            print(f"    Value: {value}, Threshold: {threshold}")

        cursor.close()
        conn.close()

        print("\n✅ Workload flags schema fix applied successfully!")
        print("✅ Added iOS-required columns")
        print("✅ Updated severity values to iOS enum format")
        print("✅ Populated data from existing boolean flags")

        return True

    except psycopg2.Error as e:
        print(f"\n❌ Database Error: {e}")
        return False

    except Exception as e:
        print(f"\n❌ Unexpected Error: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = apply_migration()
    sys.exit(0 if success else 1)
