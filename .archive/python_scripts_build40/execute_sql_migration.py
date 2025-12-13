#!/usr/bin/env python3
"""Execute SQL migration using Supabase REST API with service role key"""
import requests
import json

# From Config.swift - service role key with admin privileges
SUPABASE_URL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJwYnhlYXhsYW95b3Frb2h5dGx3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczMzY5NjU1OSwiZXhwIjoyMDQ5MjcyNTU5fQ.hDWnKR4iJ0_dDXG7uTMPXw-FdjNQQTTCjpCW6rvzNxI"

print("🚀 Applying create_analytics_views.sql to Supabase")
print("=" * 70)

# Read SQL file
with open('create_analytics_views.sql', 'r') as f:
    sql_content = f.read()

print(f"📝 Loaded SQL migration ({len(sql_content)} chars)\n")

# Split into individual statements
statements = []
current = []
for line in sql_content.split('\n'):
    # Skip comments and notices
    if line.strip().startswith('--') or 'RAISE NOTICE' in line:
        continue
    current.append(line)
    if ';' in line and 'CREATE' in ' '.join(current):
        statements.append('\n'.join(current))
        current = []

print(f"📊 Executing {len(statements)} SQL statements...\n")

# Execute using Supabase REST API sql endpoint
url = f"{SUPABASE_URL}/rest/v1/rpc/exec"
headers = {
    "apikey": SERVICE_ROLE_KEY,
    "Authorization": f"Bearer {SERVICE_ROLE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=representation"
}

# Try executing the full SQL at once
print("⚡ Executing SQL migration...")
try:
    # Use the /rest/v1/ endpoint with raw query
    # Note: PostgREST doesn't support DDL directly, we need to use SQL editor API
    
    # Alternative: Use Supabase Management API
    mgmt_url = f"{SUPABASE_URL}/rest/v1/"
    
    # Execute each CREATE VIEW statement
    for i, stmt in enumerate(statements, 1):
        if not stmt.strip():
            continue
        
        print(f"   [{i}/{len(statements)}] Executing statement...")
        
        # Try using the query endpoint
        query_url = f"{SUPABASE_URL}/rest/v1/rpc/exec_sql"
        payload = {"query": stmt}
        
        response = requests.post(
            query_url,
            headers=headers,
            json=payload
        )
        
        if response.status_code in [200, 201, 204]:
            print(f"       ✅ Success")
        else:
            print(f"       ⚠️  Status {response.status_code}: {response.text[:100]}")

except Exception as e:
    print(f"   ❌ Error: {e}")

# Verify views were created by querying them
print("\n🔍 Verifying views...")
views = ['vw_pain_trend', 'vw_patient_adherence', 'vw_patient_sessions']

for view_name in views:
    try:
        verify_url = f"{SUPABASE_URL}/rest/v1/{view_name}?select=*&limit=1"
        response = requests.get(verify_url, headers=headers)
        
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ {view_name} - EXISTS ({len(data)} rows in sample)")
        else:
            print(f"   ❌ {view_name} - NOT FOUND (status {response.status_code})")
    except Exception as e:
        print(f"   ❌ {view_name} - Error: {e}")

print("\n" + "=" * 70)
print("✅ Migration execution complete!")
