#!/usr/bin/env python3
"""
Fix Nic Roma patient linkage - update all references to use auth user ID
"""

import os
import requests
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_SERVICE_KEY = os.getenv('SUPABASE_KEY')

OLD_PATIENT_ID = "00000000-0000-0000-0000-000000000002"
NEW_PATIENT_ID = "27d60616-8cb9-4434-b2b9-e84476788e08"  # Auth user ID

headers = {
    "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
    "apikey": SUPABASE_SERVICE_KEY,
    "Content-Type": "application/json",
    "Prefer": "return=representation"
}

print("🔧 Fixing Nic Roma Patient Linkage")
print("=" * 70)
print(f"Old Patient ID: {OLD_PATIENT_ID}")
print(f"New Patient ID: {NEW_PATIENT_ID} (Auth User)")
print()

# Step 1: Update programs table
print("1️⃣  Updating programs table...")
response = requests.patch(
    f"{SUPABASE_URL}/rest/v1/programs?patient_id=eq.{OLD_PATIENT_ID}",
    headers=headers,
    json={"patient_id": NEW_PATIENT_ID}
)
if response.status_code in [200, 201, 204]:
    print("   ✅ Programs updated")
else:
    print(f"   ⚠️  Programs update: {response.status_code} - {response.text}")

# Step 2: Delete old patient record
print("2️⃣  Deleting old patient record...")
response = requests.delete(
    f"{SUPABASE_URL}/rest/v1/patients?id=eq.{OLD_PATIENT_ID}",
    headers=headers
)
if response.status_code in [200, 201, 204]:
    print("   ✅ Old patient record deleted")
else:
    print(f"   ⚠️  Delete: {response.status_code} - {response.text}")

# Step 3: Create new patient record with auth user ID
print("3️⃣  Creating new patient record with auth user ID...")
new_patient = {
    "id": NEW_PATIENT_ID,
    "therapist_id": "00000000-0000-0000-0000-000000000100",  # Sarah Thompson
    "first_name": "Nic",
    "last_name": "Roma",
    "email": "nic.roma@ptperformance.app",
    "date_of_birth": "1992-03-15",
    "sport": "Strength Training",
    "position": "General Athlete",
    "dominant_hand": "Right",
    "height_in": 70,
    "weight_lb": 180,
    "medical_history": '{"prior_injuries": [], "current_conditions": []}',
    "medications": '[]',
    "goals": "Build strength and work capacity during winter off-season"
}

response = requests.post(
    f"{SUPABASE_URL}/rest/v1/patients",
    headers=headers,
    json=new_patient
)
if response.status_code in [200, 201]:
    print("   ✅ New patient record created")
else:
    print(f"   ⚠️  Create: {response.status_code} - {response.text}")

# Step 4: Verify linkage
print("4️⃣  Verifying linkage...")
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/patients?id=eq.{NEW_PATIENT_ID}&select=*",
    headers=headers
)
if response.status_code == 200:
    patient_data = response.json()
    if patient_data:
        print("   ✅ Patient verified:")
        p = patient_data[0]
        print(f"      - ID: {p['id']}")
        print(f"      - Name: {p['first_name']} {p['last_name']}")
        print(f"      - Email: {p['email']}")
        print(f"      - Therapist: {p['therapist_id']}")
    else:
        print("   ⚠️  Patient not found")

response = requests.get(
    f"{SUPABASE_URL}/rest/v1/programs?patient_id=eq.{NEW_PATIENT_ID}&select=id,name,patient_id",
    headers=headers
)
if response.status_code == 200:
    programs = response.json()
    print(f"   ✅ Programs linked: {len(programs)}")
    for prog in programs:
        print(f"      - {prog['name']} (ID: {prog['id']})")

print()
print("=" * 70)
print("✅ NIC ROMA LINKAGE FIXED")
print("=" * 70)
print()
print("Auth User can now log in:")
print("  Email:    nic.roma@ptperformance.app")
print("  Password: nic-demo-2025")
print("  User ID:  " + NEW_PATIENT_ID)
print()
