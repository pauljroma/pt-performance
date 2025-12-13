#!/usr/bin/env python3
"""Apply create_analytics_views.sql to Supabase using psycopg2"""
import os

# Read SQL file
with open('create_analytics_views.sql', 'r') as f:
    sql = f.read()

print("🚀 Applying create_analytics_views.sql to Supabase...")
print("=" * 70)

# Since we can't use psycopg2 directly, let's use the supabase-py client
try:
    from supabase import create_client
    
    SUPABASE_URL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
    SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJwYnhlYXhsYW95b3Frb2h5dGx3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczMzY5NjU1OSwiZXhwIjoyMDQ5MjcyNTU5fQ.hDWnKR4iJ0_dDXG7uTMPXw-FdjNQQTTCjpCW6rvzNxI"
    
    supabase = create_client(SUPABASE_URL, SERVICE_KEY)
    
    # Verify tables exist first
    print("\n📊 Verifying base tables exist...")
    tables = ['pain_logs', 'patients', 'programs', 'phases', 'sessions']
    for table in tables:
        try:
            result = supabase.table(table).select('*').limit(1).execute()
            print(f"   ✅ {table}")
        except:
            print(f"   ❌ {table} - NOT FOUND")
    
    print("\n⚠️  Note: Supabase Python client cannot execute DDL (CREATE VIEW)")
    print("Using alternative: Database connection via psql")
    
except ImportError:
    print("⚠️  supabase-py not installed")

# Try using psql with connection string
print("\n📝 Attempting to apply via psql...")
DB_URL = "postgresql://postgres.rpbxeaxlaoyoqkohytlw:Sd11BV_-_@aws-0-us-west-1.pooler.supabase.com:6543/postgres"

import subprocess
result = subprocess.run(
    ['psql', DB_URL, '-f', 'create_analytics_views.sql'],
    capture_output=True,
    text=True
)

if result.returncode == 0:
    print("✅ Migration applied successfully!")
    print(result.stdout)
else:
    print(f"❌ Error: {result.stderr}")
    print("\n💡 Use Supabase SQL Editor instead:")
    print(f"   https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql")
