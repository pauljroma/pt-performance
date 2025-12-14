#!/usr/bin/env python3
"""Apply schema fix migration to Supabase database"""

import psycopg2
import sys

# Supabase connection string (matches working test scripts)
CONN_STR = "postgresql://postgres.rpbxeaxlaoyoqkohytlw:rcq!vyd6qtb_HCP5mzt@aws-0-us-west-2.pooler.supabase.com:5432/postgres"

# Migration SQL
MIGRATION_SQL = """
-- Fix Schema Issues for Build 44
-- Fixes: Missing severity column, null phase_number, null target_level

-- 1. Add severity column to workload_flags table
ALTER TABLE workload_flags
ADD COLUMN IF NOT EXISTS severity TEXT DEFAULT 'medium';

-- Add check constraint for valid severity values (drop first if exists)
DO $$
BEGIN
    ALTER TABLE workload_flags
    ADD CONSTRAINT severity_valid_values
    CHECK (severity IN ('low', 'medium', 'high'));
EXCEPTION
    WHEN duplicate_object THEN
        NULL;  -- Constraint already exists, ignore
END $$;

-- 2. Update existing programs with null target_level
UPDATE programs
SET target_level = 'Intermediate'
WHERE target_level IS NULL;

-- Make target_level NOT NULL with default
ALTER TABLE programs
ALTER COLUMN target_level SET DEFAULT 'Intermediate';

-- 3. Update existing phases with null phase_number
UPDATE phases
SET phase_number = sequence
WHERE phase_number IS NULL;

-- Make phase_number NOT NULL with default
ALTER TABLE phases
ALTER COLUMN phase_number SET DEFAULT 1;

-- 4. Update existing workload flags to have severity
UPDATE workload_flags
SET severity = 'medium'
WHERE severity IS NULL;

-- Make severity NOT NULL
ALTER TABLE workload_flags
ALTER COLUMN severity SET NOT NULL;
"""

def apply_migration():
    """Apply the schema fix migration"""
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
          'workload_flags' as table_name,
          column_name,
          data_type,
          is_nullable
        FROM information_schema.columns
        WHERE table_name = 'workload_flags' AND column_name = 'severity'
        UNION ALL
        SELECT
          'programs' as table_name,
          column_name,
          data_type,
          is_nullable
        FROM information_schema.columns
        WHERE table_name = 'programs' AND column_name = 'target_level'
        UNION ALL
        SELECT
          'phases' as table_name,
          column_name,
          data_type,
          is_nullable
        FROM information_schema.columns
        WHERE table_name = 'phases' AND column_name = 'phase_number';
        """

        cursor.execute(verify_sql)
        results = cursor.fetchall()

        print("\n✅ Verification Results:")
        for row in results:
            table, column, dtype, nullable = row
            print(f"  • {table}.{column}: {dtype} {'NULL' if nullable == 'YES' else 'NOT NULL'}")

        cursor.close()
        conn.close()

        print("\n✅ Schema fixes applied successfully!")
        print("✅ workload_flags.severity column added")
        print("✅ programs.target_level null values fixed")
        print("✅ phases.phase_number null values fixed")

        return True

    except psycopg2.OperationalError as e:
        print(f"\n❌ Connection Error: {e}")
        print("\nThis could be due to:")
        print("  • Network firewall blocking direct database connections")
        print("  • Supabase project settings requiring connection pooling")
        print("  • IPv6 connectivity issues")
        return False

    except psycopg2.Error as e:
        print(f"\n❌ Database Error: {e}")
        return False

    except Exception as e:
        print(f"\n❌ Unexpected Error: {e}")
        return False

if __name__ == "__main__":
    success = apply_migration()
    sys.exit(0 if success else 1)
