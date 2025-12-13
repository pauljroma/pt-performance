#!/usr/bin/env python3
'''
Verify Phase 3 migrations were deployed successfully
'''

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
print("🔍 VERIFYING PHASE 3 MIGRATIONS")
print("="*80 + "\n")

# Check 1: rm_estimate column
print("1️⃣ Checking rm_estimate column...")
try:
    # Try to query exercise_logs with rm_estimate
    result = supabase.table('exercise_logs').select('rm_estimate').limit(1).execute()
    print("   ✅ rm_estimate column exists")
except Exception as e:
    if "column" in str(e).lower() and "does not exist" in str(e).lower():
        print("   ❌ rm_estimate column NOT found")
        print(f"   Error: {e}")
    else:
        print(f"   ⚠️  Could not verify: {e}")

# Check 2: agent_logs table
print("\n2️⃣ Checking agent_logs table...")
try:
    result = supabase.table('agent_logs').select('*').limit(1).execute()
    print("   ✅ agent_logs table exists")
except Exception as e:
    if "does not exist" in str(e).lower():
        print("   ❌ agent_logs table NOT found")
        print(f"   Error: {e}")
    else:
        print(f"   ⚠️  Could not verify: {e}")

print("\n" + "="*80)
print("✅ VERIFICATION COMPLETE")
print("="*80)
print("\nIf any checks failed, deploy the corresponding migration.")
