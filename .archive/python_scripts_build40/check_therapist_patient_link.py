#!/usr/bin/env python3
"""
Check Therapist-Patient Linkage
================================
Verifies that the demo patient is actually linked to the demo therapist.
"""

import requests

SUPABASE_URL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
SUPABASE_SERVICE_KEY = "sb_secret_FYMKefuStzD82VUTplnsuw_GHN_0hb3"

headers = {
    "apikey": SUPABASE_SERVICE_KEY,
    "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
    "Content-Type": "application/json"
}

print("=" * 80)
print("CHECKING THERAPIST-PATIENT LINKAGE")
print("=" * 80)

# 1. Get therapist info
print("\n1. Demo Therapist:")
therapist_url = f"{SUPABASE_URL}/rest/v1/therapists?email=eq.demo-pt@ptperformance.app&select=*"
response = requests.get(therapist_url, headers=headers)
therapists = response.json()

if therapists:
    therapist = therapists[0]
    therapist_id = therapist['id']
    print(f"   ID: {therapist_id}")
    print(f"   Name: {therapist['first_name']} {therapist['last_name']}")
    print(f"   Email: {therapist['email']}")
    print(f"   Auth User ID: {therapist.get('user_id', 'NULL')}")
else:
    print("   ❌ THERAPIST NOT FOUND!")
    therapist_id = None

# 2. Get patient info
print("\n2. Demo Patient:")
patient_url = f"{SUPABASE_URL}/rest/v1/patients?email=eq.demo-athlete@ptperformance.app&select=*"
response = requests.get(patient_url, headers=headers)
patients = response.json()

if patients:
    patient = patients[0]
    patient_id = patient['id']
    patient_therapist_id = patient.get('therapist_id')
    print(f"   ID: {patient_id}")
    print(f"   Name: {patient['first_name']} {patient['last_name']}")
    print(f"   Email: {patient['email']}")
    print(f"   Auth User ID: {patient.get('user_id', 'NULL')}")
    print(f"   Therapist ID: {patient_therapist_id or 'NULL'}")
else:
    print("   ❌ PATIENT NOT FOUND!")
    patient_therapist_id = None

# 3. Check linkage
print("\n3. Linkage Status:")
if therapist_id and patient_therapist_id:
    if therapist_id == patient_therapist_id:
        print(f"   ✅ LINKED: Patient's therapist_id matches therapist's ID")
        print(f"   Matching ID: {therapist_id}")
    else:
        print(f"   ❌ NOT LINKED: IDs don't match!")
        print(f"   Therapist ID: {therapist_id}")
        print(f"   Patient's therapist_id: {patient_therapist_id}")
else:
    print(f"   ❌ MISSING DATA: Cannot verify linkage")

# 4. Test the actual query that the app uses
print("\n4. Testing iOS App Query:")
print(f"   Query: SELECT * FROM patients WHERE therapist_id = '{therapist_id}'")
test_url = f"{SUPABASE_URL}/rest/v1/patients?therapist_id=eq.{therapist_id}&select=*"
response = requests.get(test_url, headers=headers)
patients_for_therapist = response.json()
print(f"   Results: {len(patients_for_therapist)} patient(s) found")

if patients_for_therapist:
    for p in patients_for_therapist:
        print(f"     - {p['first_name']} {p['last_name']} ({p['email']})")
else:
    print(f"     ❌ NO PATIENTS FOUND FOR THIS THERAPIST!")

print("\n" + "=" * 80)
print("DIAGNOSIS:")
print("=" * 80)

if therapist_id and patient_therapist_id and therapist_id == patient_therapist_id:
    if len(patients_for_therapist) > 0:
        print("✅ Everything is correct - patient should appear in therapist dashboard")
        print("   Issue might be with RLS policies or app-side filtering")
    else:
        print("❌ Database linkage exists but query returns no results")
        print("   This suggests an RLS policy is blocking the query!")
elif therapist_id and not patient_therapist_id:
    print("❌ Patient's therapist_id is NULL - needs to be set!")
    print(f"   Run: UPDATE patients SET therapist_id = '{therapist_id}' WHERE email = 'demo-athlete@ptperformance.app'")
elif therapist_id != patient_therapist_id:
    print("❌ Patient is linked to a different therapist!")
    print(f"   Current: {patient_therapist_id}")
    print(f"   Should be: {therapist_id}")
    print(f"   Run: UPDATE patients SET therapist_id = '{therapist_id}' WHERE email = 'demo-athlete@ptperformance.app'")

print("=" * 80)
