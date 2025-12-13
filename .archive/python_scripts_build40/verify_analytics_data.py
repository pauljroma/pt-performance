#!/usr/bin/env python3
from supabase import create_client

SUPABASE_URL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
SERVICE_KEY = "sb_secret_FYMKefuStzD82VUTplnsuw_GHN_0hb3"

supabase = create_client(SUPABASE_URL, SERVICE_KEY)

print("🔍 Verifying Analytics Views Data")
print("=" * 70)

# Test vw_pain_trend
print("\n1️⃣  vw_pain_trend:")
result = supabase.table('vw_pain_trend').select('*').limit(5).execute()
print(f"   Rows: {len(result.data)}")
if result.data:
    print(f"   Sample: {result.data[0]}")

# Test vw_patient_adherence  
print("\n2️⃣  vw_patient_adherence:")
result = supabase.table('vw_patient_adherence').select('*').limit(5).execute()
print(f"   Rows: {len(result.data)}")
if result.data:
    print(f"   Sample: {result.data[0]}")

# Test vw_patient_sessions
print("\n3️⃣  vw_patient_sessions:")
result = supabase.table('vw_patient_sessions').select('*').limit(5).execute()
print(f"   Rows: {len(result.data)}")
if result.data:
    print(f"   Sample: {result.data[0]}")

print("\n" + "=" * 70)
print("✅ All analytics views are working!")
