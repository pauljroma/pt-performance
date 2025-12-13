#!/usr/bin/env python3
"""
create_nic_roma_user.py
Create Supabase auth user for Nic Roma patient
ACP-121: Auth User Creation for Winter Lift Program

Usage:
    python3 create_nic_roma_user.py

Prerequisites:
    pip install supabase

Environment variables (optional):
    SUPABASE_URL - Supabase project URL
    SUPABASE_SERVICE_KEY - Service role key (admin access)

If not provided, uses default values for local development.
"""

import os
import sys
from supabase import create_client

# Configuration
SUPABASE_URL = os.getenv("SUPABASE_URL", "https://rpbxeaxlaoyoqkohytlw.supabase.co")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

# Patient details
PATIENT_EMAIL = "nic.roma@ptperformance.app"
PATIENT_PASSWORD = "nic-demo-2025"
PATIENT_UUID = "00000000-0000-0000-0000-000000000002"


def main():
    """Create auth user for Nic Roma and update patients table."""

    if not SUPABASE_SERVICE_KEY:
        print("Error: SUPABASE_SERVICE_KEY environment variable not set")
        print("\nUsage:")
        print("  export SUPABASE_SERVICE_KEY='your-service-role-key'")
        print("  python3 create_nic_roma_user.py")
        print("\nOr provide inline:")
        print("  SUPABASE_SERVICE_KEY='your-key' python3 create_nic_roma_user.py")
        sys.exit(1)

    print(f"Connecting to Supabase: {SUPABASE_URL}")
    supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

    try:
        # Step 1: Check if patient exists in database
        print(f"\n[1/3] Checking if patient exists in database...")
        patient_check = supabase.table('patients').select('*').eq('email', PATIENT_EMAIL).execute()

        if not patient_check.data:
            print(f"   ❌ Patient not found in database. Run migration first:")
            print(f"   supabase migration apply 20251213000001_seed_nic_roma_patient.sql")
            sys.exit(1)

        print(f"   ✅ Patient found: {patient_check.data[0]['first_name']} {patient_check.data[0]['last_name']}")
        patient_db_id = patient_check.data[0]['id']

        # Step 2: Check if auth user already exists
        print(f"\n[2/3] Checking if auth user already exists...")
        try:
            # Try to get existing user
            existing_user = supabase.auth.admin.get_user_by_email(PATIENT_EMAIL)
            if existing_user:
                print(f"   ℹ️  Auth user already exists: {existing_user.user.email}")
                auth_user_id = existing_user.user.id
                print(f"   User ID: {auth_user_id}")
        except Exception:
            # User doesn't exist, create new one
            print(f"   Creating new auth user...")

            auth_response = supabase.auth.admin.create_user({
                "email": PATIENT_EMAIL,
                "password": PATIENT_PASSWORD,
                "email_confirm": True,
                "user_metadata": {
                    "full_name": "Nic Roma",
                    "role": "patient",
                    "patient_id": PATIENT_UUID
                }
            })

            auth_user_id = auth_response.user.id
            print(f"   ✅ Created auth user: {PATIENT_EMAIL}")
            print(f"   User ID: {auth_user_id}")
            print(f"   Password: {PATIENT_PASSWORD}")

        # Step 3: Update patients table with auth user ID
        print(f"\n[3/3] Linking auth user to patient record...")

        # Check if user_id column exists
        patient_record = patient_check.data[0]
        if 'user_id' not in patient_record:
            print(f"   ⚠️  Warning: patients table does not have user_id column")
            print(f"   Patient record will not be linked to auth user")
        else:
            # Update patient record with user_id
            update_response = supabase.table('patients').update({
                'user_id': auth_user_id
            }).eq('email', PATIENT_EMAIL).execute()

            print(f"   ✅ Linked patient record to auth user")
            print(f"   Patient DB ID: {patient_db_id}")
            print(f"   Auth User ID: {auth_user_id}")

        print("\n" + "=" * 60)
        print("SUCCESS: Nic Roma auth user created and linked")
        print("=" * 60)
        print(f"\nLogin credentials:")
        print(f"  Email:    {PATIENT_EMAIL}")
        print(f"  Password: {PATIENT_PASSWORD}")
        print(f"\nPatient details:")
        print(f"  Name:     Nic Roma")
        print(f"  UUID:     {PATIENT_UUID}")
        print(f"  Auth ID:  {auth_user_id}")
        print(f"  Role:     Patient")
        print(f"  Therapist: Sarah Thompson")

    except Exception as e:
        print(f"\n❌ Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
