#!/usr/bin/env python3
"""
Create demo auth users in Supabase
This creates the actual authentication users that can log in to the app
"""

import os
import requests
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_SERVICE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY') or os.getenv('SUPABASE_KEY')

if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
    print("❌ Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env")
    exit(1)

print(f"🔑 Using Supabase URL: {SUPABASE_URL}")
print()

# Demo users to create
demo_users = [
    {
        "email": "demo-athlete@ptperformance.app",
        "password": "demo-patient-2025",
        "email_confirm": True,
        "user_metadata": {
            "first_name": "John",
            "last_name": "Brebbia",
            "role": "patient"
        }
    },
    {
        "email": "demo-pt@ptperformance.app",
        "password": "demo-therapist-2025",
        "email_confirm": True,
        "user_metadata": {
            "first_name": "Sarah",
            "last_name": "Thompson",
            "role": "therapist"
        }
    }
]

headers = {
    "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
    "apikey": SUPABASE_SERVICE_KEY,
    "Content-Type": "application/json"
}

print("=" * 60)
print("Creating Demo Auth Users")
print("=" * 60)
print()

for user in demo_users:
    print(f"📧 Creating user: {user['email']}")
    print(f"   Password: {user['password']}")
    print(f"   Role: {user['user_metadata']['role']}")

    response = requests.post(
        f"{SUPABASE_URL}/auth/v1/admin/users",
        headers=headers,
        json=user
    )

    if response.status_code in [200, 201]:
        result = response.json()
        print(f"   ✅ Created! User ID: {result.get('id')}")
    elif response.status_code == 422:
        print(f"   ℹ️  User already exists (this is fine)")
    else:
        print(f"   ❌ Error: {response.status_code}")
        print(f"   {response.text}")
    print()

print("=" * 60)
print("✅ Demo Users Setup Complete")
print("=" * 60)
print()
print("Demo Credentials:")
print("-" * 60)
print("Patient Login:")
print("  Email:    demo-athlete@ptperformance.app")
print("  Password: demo-patient-2025")
print()
print("Therapist Login:")
print("  Email:    demo-pt@ptperformance.app")
print("  Password: demo-therapist-2025")
print()
