#!/usr/bin/env python3
"""
Restore original patient setup AND add Nic Roma as additional patient
"""
import os, requests
from dotenv import load_dotenv

load_dotenv()
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_KEY')

headers = {
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "apikey": SUPABASE_KEY,
    "Content-Type": "application/json",
    "Prefer": "return=representation"
}

print("🔧 Restoring Original Patient + Keeping Nic Roma")
print("=" * 70)

# 1. Recreate original patient with static UUID (for testing/seeding)
print("\n1️⃣  Recreating original patient with static UUID...")
original_patient = {
    "id": "00000000-0000-0000-0000-000000000002",
    "therapist_id": "00000000-0000-0000-0000-000000000100",
    "first_name": "Nic",
    "last_name": "Roma",
    "email": "nic.roma.seed@ptperformance.app",  # Different email
    "date_of_birth": "1992-03-15",
    "sport": "Strength Training",
    "position": "General Athlete",
    "dominant_hand": "Right",
    "height_in": 70,
    "weight_lb": 180,
    "medical_history": '{"prior_injuries": [], "current_conditions": []}',
    "medications": '[]',
    "goals": "Build strength and work capacity during winter off-season (SEED DATA)"
}

response = requests.post(
    f"{SUPABASE_URL}/rest/v1/patients",
    headers=headers,
    json=original_patient
)

if response.status_code in [200, 201]:
    print("   ✅ Original patient recreated (static UUID for migrations)")
elif response.status_code == 409:
    print("   ℹ️  Original patient already exists")
else:
    print(f"   ⚠️  {response.status_code}: {response.text[:200]}")

# 2. Move Winter Lift program back to original patient
print("\n2️⃣  Moving Winter Lift program to original patient...")
response = requests.patch(
    f"{SUPABASE_URL}/rest/v1/programs?id=eq.00000000-0000-0000-0000-000000000300",
    headers=headers,
    json={"patient_id": "00000000-0000-0000-0000-000000000002"}
)

if response.status_code in [200, 201, 204]:
    print("   ✅ Program moved to original patient")
else:
    print(f"   ⚠️  {response.status_code}: {response.text[:200]}")

# 3. Verify both patients exist
print("\n3️⃣  Verifying both patients...")
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/patients?select=id,first_name,last_name,email&order=email",
    headers=headers
)

if response.status_code == 200:
    patients = response.json()
    nic_patients = [p for p in patients if 'nic' in p['email'].lower() and 'roma' in p['email'].lower()]
    print(f"   ✅ Found {len(nic_patients)} Nic Roma patient(s):")
    for p in nic_patients:
        print(f"      - {p['first_name']} {p['last_name']} ({p['email']})")
        print(f"        ID: {p['id']}")

# 4. Verify programs
print("\n4️⃣  Verifying programs...")
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/programs?select=id,name,patient_id",
    headers=headers
)

if response.status_code == 200:
    programs = response.json()
    print(f"   ✅ Total programs: {len(programs)}")
    for prog in programs:
        print(f"      - {prog['name']} (Patient: {prog['patient_id'][:8]}...)")

print("\n" + "=" * 70)
print("✅ PATIENT SETUP RESTORED")
print("=" * 70)
print("\nTwo Nic Roma patients now exist:")
print("  1. SEED DATA (static UUID): nic.roma.seed@ptperformance.app")
print("     - Has Winter Lift program")
print("     - Used for migrations/testing")
print("  2. AUTH USER: nic.roma@ptperformance.app / nic-demo-2025")
print("     - Can log in to app")
print("     - No program yet (can assign one)")
print()
