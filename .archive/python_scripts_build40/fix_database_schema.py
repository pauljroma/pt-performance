#!/usr/bin/env python3
"""Fix database schema - add missing email column to patients"""

import os
import requests
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_SERVICE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY') or os.getenv('SUPABASE_KEY')

print("=" * 70)
print("  FIXING DATABASE SCHEMA")
print("=" * 70)
print()

# SQL to add email column to patients table
sql = """
-- Add email column to patients table
ALTER TABLE patients ADD COLUMN IF NOT EXISTS email TEXT UNIQUE;

-- Update existing patient record with email
UPDATE patients
SET email = 'demo-athlete@ptperformance.app'
WHERE first_name = 'John' AND last_name = 'Brebbia' AND email IS NULL;
"""

print("Running migration:")
print(sql)
print()

# Execute via Supabase API
headers = {
    "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
    "apikey": SUPABASE_SERVICE_KEY,
    "Content-Type": "application/json"
}

# Use PostgREST rpc or direct SQL execution
# Note: This requires the SQL to be wrapped in a function or use supabase CLI

print("✅ SQL ready to execute")
print()
print("Please run this SQL in Supabase Dashboard:")
print("1. Go to: https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/editor")
print("2. Click 'SQL Editor'")
print("3. Paste and run the SQL above")
print()
print("Or use supabase CLI:")
print(f"  cd {os.path.dirname(__file__)}")
print("  supabase db push")
