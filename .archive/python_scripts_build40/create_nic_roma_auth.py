#!/usr/bin/env python3
"""
Create Nic Roma auth user in Supabase
"""

import os
import requests
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_SERVICE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY') or os.getenv('SUPABASE_KEY')

if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
    print("❌ Missing SUPABASE_URL or SUPABASE_KEY in .env")
    exit(1)

print(f"🔑 Using Supabase URL: {SUPABASE_URL}")
print()

# Nic Roma user
nic_roma = {
    "email": "nic.roma@ptperformance.app",
    "password": "nic-demo-2025",
    "email_confirm": True,
    "user_metadata": {
        "first_name": "Nic",
        "last_name": "Roma",
        "role": "patient"
    }
}

headers = {
    "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
    "apikey": SUPABASE_SERVICE_KEY,
    "Content-Type": "application/json"
}

print("=" * 60)
print("Creating Nic Roma Auth User")
print("=" * 60)
print()

print(f"📧 Creating user: {nic_roma['email']}")
print(f"   Password: {nic_roma['password']}")
print(f"   Role: {nic_roma['user_metadata']['role']}")

response = requests.post(
    f"{SUPABASE_URL}/auth/v1/admin/users",
    headers=headers,
    json=nic_roma
)

if response.status_code in [200, 201]:
    result = response.json()
    user_id = result.get('id')
    print(f"   ✅ Created! User ID: {user_id}")
    print()
    
    # Now update the patients table with this auth user ID
    print(f"📝 Updating patients table to link auth user...")
    
    # Use Supabase REST API to update the patient record
    patient_update_headers = {
        "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
        "apikey": SUPABASE_SERVICE_KEY,
        "Content-Type": "application/json",
        "Prefer": "return=representation"
    }
    
    update_response = requests.patch(
        f"{SUPABASE_URL}/rest/v1/patients?email=eq.nic.roma@ptperformance.app",
        headers=patient_update_headers,
        json={"id": user_id}
    )
    
    if update_response.status_code in [200, 201, 204]:
        print(f"   ✅ Patient record updated with auth user ID")
    else:
        print(f"   ⚠️  Could not update patient record: {update_response.status_code}")
        print(f"   {update_response.text}")
        print(f"   💡 You may need to manually link the patient record to user ID: {user_id}")
        
elif response.status_code == 422:
    print(f"   ℹ️  User already exists (this is fine)")
else:
    print(f"   ❌ Error: {response.status_code}")
    print(f"   {response.text}")

print()
print("=" * 60)
print("✅ Nic Roma Auth User Setup Complete")
print("=" * 60)
print()
print("Login Credentials:")
print("-" * 60)
print("Email:    nic.roma@ptperformance.app")
print("Password: nic-demo-2025")
print()
