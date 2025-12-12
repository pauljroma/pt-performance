#!/usr/bin/env python3
"""Test exercise query structure"""
import requests

SUPABASE_URL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
SUPABASE_ANON_KEY = "sb_publishable_bvF02gZep-IdSHFNYVro3g_lNY8hfzr"

# Login as therapist
auth_response = requests.post(
    f"{SUPABASE_URL}/auth/v1/token?grant_type=password",
    headers={"apikey": SUPABASE_ANON_KEY, "Content-Type": "application/json"},
    json={"email": "demo-pt@ptperformance.app", "password": "demo-therapist-2025"}
)

access_token = auth_response.json()["access_token"]

headers = {
    "apikey": SUPABASE_ANON_KEY,
    "Authorization": f"Bearer {access_token}"
}

# Get a session ID
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/sessions?select=id&limit=1",
    headers=headers
)
session_id = response.json()[0]["id"]
print(f"Testing with session_id: {session_id}\n")

# Test current iOS query
print("=" * 60)
print("CURRENT iOS QUERY (what Build 9 uses):")
print("=" * 60)

query = """id,session_id,exercise_templates!inner(exercise_name),prescribed_sets,prescribed_reps,prescribed_load,load_unit,rest_period_seconds,order_index"""

response = requests.get(
    f"{SUPABASE_URL}/rest/v1/session_exercises?session_id=eq.{session_id}&select={query}&order=order_index.asc",
    headers=headers
)

print(f"Status: {response.status_code}")
if response.status_code == 200:
    import json
    data = response.json()
    print(f"✅ Query succeeded - {len(data)} exercises")
    if data:
        print("\nFirst exercise structure:")
        print(json.dumps(data[0], indent=2))
else:
    print(f"❌ Failed: {response.text}")

# Test alternative query with flat exercise_template_id
print("\n" + "=" * 60)
print("ALTERNATIVE: Get exercise_template_id and join manually")
print("=" * 60)

query2 = """id,session_id,exercise_template_id,prescribed_sets,prescribed_reps,prescribed_load,load_unit,rest_period_seconds,order_index"""

response = requests.get(
    f"{SUPABASE_URL}/rest/v1/session_exercises?session_id=eq.{session_id}&select={query2}&order=order_index.asc",
    headers=headers
)

print(f"Status: {response.status_code}")
if response.status_code == 200:
    data = response.json()
    print(f"✅ Query succeeded - {len(data)} exercises")
    if data:
        exercise_template_id = data[0].get("exercise_template_id")
        print(f"\nFirst exercise has exercise_template_id: {exercise_template_id}")

        # Now get the exercise name
        response2 = requests.get(
            f"{SUPABASE_URL}/rest/v1/exercise_templates?id=eq.{exercise_template_id}&select=exercise_name",
            headers=headers
        )
        if response2.status_code == 200:
            template = response2.json()[0]
            print(f"Exercise name: {template.get('exercise_name')}")
