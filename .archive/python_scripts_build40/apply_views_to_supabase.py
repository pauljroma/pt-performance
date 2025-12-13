#!/usr/bin/env python3
"""
Apply analytics views to Supabase using the PostgREST admin API
"""

import os
import requests

# Supabase connection
SUPABASE_URL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
# Service role key (for admin operations)
SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJwYnhlYXhsYW95b3Frb2h5dGx3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczMzY5NjU1OSwiZXhwIjoyMDQ5MjcyNTU5fQ.hDWnKR4iJ0_dDXG7uTMPXw-FdjNQQTTCjpCW6rvzNxI"

def execute_sql():
    """Execute the SQL file using Supabase REST API"""
    print("🚀 Applying analytics views to Supabase...")
    print("=" * 70)

    # Read the SQL file
    with open("create_analytics_views.sql", 'r') as f:
        sql = f.read()

    # Use Supabase's pg_meta API endpoint to execute SQL
    url = f"{SUPABASE_URL}/rest/v1/rpc/exec_sql"

    headers = {
        "apikey": SERVICE_KEY,
        "Authorization": f"Bearer {SERVICE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "return=representation"
    }

    print("\n📝 Executing SQL via Supabase API...")
    print(f"   URL: {SUPABASE_URL}")

    # Try using the query endpoint
    # Note: Supabase doesn't have a direct SQL execution endpoint via REST
    # We need to use psql or the dashboard SQL editor

    print("\n⚠️  Supabase REST API doesn't support DDL operations")
    print("\n📋 Please apply the SQL manually using one of these methods:\n")

    print("METHOD 1: Supabase SQL Editor (Recommended)")
    print("-" * 70)
    print("1. Open: https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql")
    print("2. Copy contents of: create_analytics_views.sql")
    print("3. Paste into SQL editor")
    print("4. Click 'Run'")

    print("\nMETHOD 2: psql Command Line")
    print("-" * 70)
    print("psql \\")
    print(f"  'postgresql://postgres.rpbxeaxlaoyoqkohytlw:[YOUR-PASSWORD]@aws-0-us-west-1.pooler.supabase.com:6543/postgres' \\")
    print("  -f create_analytics_views.sql")

    print("\nMETHOD 3: supabase CLI")
    print("-" * 70)
    print("supabase db execute --file create_analytics_views.sql")

    print("\n" + "=" * 70)
    print("✅ create_analytics_views.sql is ready to apply!")

if __name__ == "__main__":
    execute_sql()
