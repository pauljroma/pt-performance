#!/usr/bin/env python3
from supabase import create_client, Client
import os

# Load from .env
SUPABASE_URL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
SERVICE_KEY = "sb_secret_FYMKefuStzD82VUTplnsuw_GHN_0hb3"

print("🚀 Applying Analytics Views Migration")
print("=" * 70)

# Read SQL
with open('create_analytics_views.sql', 'r') as f:
    sql = f.read()

print(f"📝 Loaded SQL ({len(sql)} chars)\n")

# Create client with service role key
supabase: Client = create_client(SUPABASE_URL, SERVICE_KEY)

# Execute SQL via rpc
print("⚡ Executing SQL via Supabase client...\n")

try:
    # Execute each statement
    statements = [s.strip() for s in sql.split(';') if s.strip() and 'CREATE VIEW' in s]
    
    for i, stmt in enumerate(statements, 1):
        print(f"   [{i}/{len(statements)}] Creating view...")
        # Use SQL function if available
        result = supabase.rpc('exec_sql', {'sql': stmt + ';'}).execute()
        print(f"       ✅ Done")
        
except Exception as e:
    print(f"   ⚠️ RPC method not available: {e}")
    print("\n   Trying alternative: Direct table query method...\n")
    
    # Alternative: Try querying to verify tables exist first
    print("   Verifying base tables...")
    try:
        tables = ['pain_logs', 'patients', 'sessions']
        for table in tables:
            result = supabase.table(table).select('id').limit(1).execute()
            print(f"      ✅ {table} exists")
    except Exception as e2:
        print(f"      ❌ Tables not accessible: {e2}")

# Verify views
print("\n🔍 Verifying views...")
views = ['vw_pain_trend', 'vw_patient_adherence', 'vw_patient_sessions']

for view in views:
    try:
        result = supabase.table(view).select('*').limit(1).execute()
        print(f"   ✅ {view} - OK")
    except Exception as e:
        print(f"   ❌ {view} - Not found")

print("\n" + "=" * 70)
