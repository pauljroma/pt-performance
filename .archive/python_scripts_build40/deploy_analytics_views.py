#!/usr/bin/env python3
"""Deploy analytics views to Supabase using direct PostgreSQL connection"""
import psycopg2

# Supabase connection details
PROJECT_REF = "rpbxeaxlaoyoqkohytlw"
DB_PASSWORD = "Sd11BV_-_"  # From connection string

conn_params = {
    'host': f'db.{PROJECT_REF}.supabase.co',
    'database': 'postgres',
    'user': 'postgres',
    'password': DB_PASSWORD,
    'port': 5432
}

print("🚀 Deploying Analytics Views to Supabase")
print("=" * 70)

try:
    # Connect
    print(f"\n📡 Connecting to {conn_params['host']}...")
    conn = psycopg2.connect(**conn_params)
    conn.autocommit = True
    cursor = cursor()
    print("✅ Connected!\n")

    # Read SQL file
    print("📝 Reading create_analytics_views.sql...")
    with open('create_analytics_views.sql', 'r') as f:
        sql_content = f.read()
    print(f"✅ Loaded {len(sql_content)} characters\n")

    # Execute SQL
    print("⚡ Executing SQL migration...")
    cursor.execute(sql_content)
    print("✅ Migration executed successfully!\n")

    # Verify views
    print("🔍 Verifying views created...")
    views = ['vw_pain_trend', 'vw_patient_adherence', 'vw_patient_sessions']

    for view_name in views:
        cursor.execute(f"SELECT COUNT(*) FROM {view_name}")
        count = cursor.fetchone()[0]
        print(f"   ✅ {view_name} - {count} rows")

    cursor.close()
    conn.close()

    print("\n" + "=" * 70)
    print("🎉 Analytics views deployed successfully!")
    print("\nNext step: Test History tab in iOS app")

except Exception as e:
    print(f"\n❌ Error: {e}")
    print("\nTroubleshooting:")
    print("1. Check database password")
    print("2. Verify network connection")
    print("3. Use Supabase SQL Editor: https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql")

