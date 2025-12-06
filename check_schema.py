#!/usr/bin/env python3
"""Check what tables exist in Supabase"""

import os
from dotenv import load_dotenv
from supabase import create_client

load_dotenv()

supabase_url = os.getenv("SUPABASE_URL")
supabase_key = os.getenv("SUPABASE_KEY")

if not supabase_url or not supabase_key:
    print("❌ Missing SUPABASE_URL or SUPABASE_KEY")
    exit(1)

supabase = create_client(supabase_url, supabase_key)

print("\n" + "="*80)
print("🔍 CHECKING SUPABASE SCHEMA")
print("="*80 + "\n")

# Check for key tables
tables_to_check = [
    'patients',
    'therapists',
    'programs',
    'exercise_logs',
    'session_exercises',
    'exercise_templates',
    'agent_logs'
]

for table in tables_to_check:
    try:
        result = supabase.table(table).select('*').limit(1).execute()
        print(f"✅ {table} exists")
    except Exception as e:
        error = str(e).lower()
        if "does not exist" in error or "relation" in error:
            print(f"❌ {table} does NOT exist")
        else:
            print(f"⚠️  {table} - Could not check: {e}")

print("\n" + "="*80)
print("Schema check complete")
print("="*80)
