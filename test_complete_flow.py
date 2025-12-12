#!/usr/bin/env python3
"""
Complete End-to-End Test for PT Performance Demo Logins
Tests auth users, database records, and login flow
"""

import os
import requests
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_SERVICE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY') or os.getenv('SUPABASE_KEY')
SUPABASE_ANON_KEY = os.getenv('SUPABASE_ANON_KEY') or SUPABASE_SERVICE_KEY

def print_section(title):
    print("\n" + "=" * 70)
    print(f"  {title}")
    print("=" * 70 + "\n")

def test_auth_users():
    """Test that auth users exist"""
    print_section("TEST 1: Auth Users Exist")

    headers = {
        "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
        "apikey": SUPABASE_SERVICE_KEY
    }

    # List all users
    response = requests.get(
        f"{SUPABASE_URL}/auth/v1/admin/users",
        headers=headers
    )

    if response.status_code != 200:
        print(f"❌ Failed to get users: {response.status_code}")
        print(response.text)
        return False

    users = response.json().get('users', [])
    print(f"✅ Found {len(users)} auth users\n")

    # Check for demo users
    demo_emails = {
        'demo-athlete@ptperformance.app': None,
        'demo-pt@ptperformance.app': None
    }

    for user in users:
        email = user.get('email')
        if email in demo_emails:
            demo_emails[email] = user.get('id')
            print(f"✅ Found: {email}")
            print(f"   User ID: {user.get('id')}")
            print(f"   Confirmed: {user.get('email_confirmed_at') is not None}")

    print()

    missing = [email for email, uid in demo_emails.items() if uid is None]
    if missing:
        print(f"❌ Missing auth users: {missing}")
        return False

    print("✅ All demo auth users exist")
    return True

def test_database_records():
    """Test that database records exist with matching emails"""
    print_section("TEST 2: Database Records Exist")

    headers = {
        "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
        "apikey": SUPABASE_SERVICE_KEY,
        "Content-Type": "application/json"
    }

    # Test patient record
    print("Checking patient record...")
    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/patients",
        headers=headers,
        params={"email": "eq.demo-athlete@ptperformance.app", "select": "*"}
    )

    if response.status_code != 200:
        print(f"❌ Failed to query patients: {response.status_code}")
        return False

    patients = response.json()
    if not patients:
        print("❌ No patient found with email: demo-athlete@ptperformance.app")
        return False

    patient = patients[0]
    print(f"✅ Found patient: {patient['first_name']} {patient['last_name']}")
    print(f"   ID: {patient['id']}")
    print(f"   Email: {patient.get('email', 'MISSING')}")
    print()

    # Test therapist record
    print("Checking therapist record...")
    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/therapists",
        headers=headers,
        params={"email": "eq.demo-pt@ptperformance.app", "select": "*"}
    )

    if response.status_code != 200:
        print(f"❌ Failed to query therapists: {response.status_code}")
        return False

    therapists = response.json()
    if not therapists:
        print("❌ No therapist found with email: demo-pt@ptperformance.app")
        return False

    therapist = therapists[0]
    print(f"✅ Found therapist: {therapist['first_name']} {therapist['last_name']}")
    print(f"   ID: {therapist['id']}")
    print(f"   Email: {therapist.get('email', 'MISSING')}")
    print()

    print("✅ All database records exist")
    return True

def test_login_flow():
    """Test complete login flow"""
    print_section("TEST 3: Login Flow")

    anon_headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Content-Type": "application/json"
    }

    test_users = [
        {
            "email": "demo-athlete@ptperformance.app",
            "password": "demo-patient-2025",
            "expected_role": "patient"
        },
        {
            "email": "demo-pt@ptperformance.app",
            "password": "demo-therapist-2025",
            "expected_role": "therapist"
        }
    ]

    for test_user in test_users:
        print(f"\nTesting login: {test_user['email']}")
        print("-" * 50)

        # Attempt login
        response = requests.post(
            f"{SUPABASE_URL}/auth/v1/token?grant_type=password",
            headers=anon_headers,
            json={
                "email": test_user['email'],
                "password": test_user['password']
            }
        )

        if response.status_code != 200:
            print(f"❌ Login failed: {response.status_code}")
            print(response.text)
            return False

        auth_data = response.json()
        access_token = auth_data.get('access_token')
        user_email = auth_data.get('user', {}).get('email')

        print(f"✅ Login successful")
        print(f"   Email: {user_email}")
        print(f"   Token: {access_token[:20]}...")

        # Test user lookup by email
        print(f"\nLooking up {test_user['expected_role']} record by email...")

        lookup_headers = {
            "Authorization": f"Bearer {access_token}",
            "apikey": SUPABASE_ANON_KEY
        }

        if test_user['expected_role'] == 'patient':
            table = 'patients'
        else:
            table = 'therapists'

        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/{table}",
            headers=lookup_headers,
            params={"email": f"eq.{user_email}", "select": "*"}
        )

        if response.status_code != 200:
            print(f"❌ Failed to lookup {test_user['expected_role']}: {response.status_code}")
            print(response.text)
            return False

        records = response.json()
        if not records:
            print(f"❌ No {test_user['expected_role']} found with email: {user_email}")
            return False

        record = records[0]
        print(f"✅ Found {test_user['expected_role']}: {record['first_name']} {record['last_name']}")
        print(f"   ID: {record['id']}")

    print("\n✅ All login flows work correctly")
    return True

def main():
    print("\n" + "=" * 70)
    print("  PT PERFORMANCE - COMPLETE END-TO-END TEST")
    print("=" * 70)

    if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
        print("❌ Missing environment variables")
        print("   Required: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY")
        return

    print(f"\n🔗 Supabase URL: {SUPABASE_URL}")
    print(f"🔑 Service Key: {SUPABASE_SERVICE_KEY[:20]}...")

    # Run all tests
    results = []

    results.append(("Auth Users", test_auth_users()))
    results.append(("Database Records", test_database_records()))
    results.append(("Login Flow", test_login_flow()))

    # Summary
    print_section("TEST SUMMARY")

    all_passed = all(result for _, result in results)

    for test_name, passed in results:
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{status}  {test_name}")

    print("\n" + "=" * 70)
    if all_passed:
        print("✅ ALL TESTS PASSED - Ready for Build 5")
    else:
        print("❌ SOME TESTS FAILED - DO NOT BUILD YET")
    print("=" * 70 + "\n")

if __name__ == '__main__':
    main()
