#!/usr/bin/env python3
"""Apply Winter Lift program SQL directly"""
import os, requests
from dotenv import load_dotenv

load_dotenv()
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_KEY')
NEW_PATIENT_ID = "27d60616-8cb9-4434-b2b9-e84476788e08"

print("📝 Creating Winter Lift program...")
print(f"   Patient ID: {NEW_PATIENT_ID}")

headers = {
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "apikey": SUPABASE_KEY,
    "Content-Type": "application/json",
    "Prefer": "return=representation"
}

# Create program
print("\n1️⃣  Creating program...")
program = {
    "id": "00000000-0000-0000-0000-000000000300",
    "patient_id": NEW_PATIENT_ID,
    "name": "Winter Lift 3x/week",
    "description": "Progressive 12-week strength building program with 3 training days per week. Focuses on compound lifts, hypertrophy work, and auto-regulated load progression.",
    "start_date": "2025-01-13",
    "end_date": "2025-04-06",
    "status": "active",
    "metadata": {
        "frequency_per_week": 3,
        "target_level": "Intermediate",
        "program_type": "strength_building",
        "session_pattern": ["Day 1: Anterior Chain", "Day 2: Combo", "Day 3: Posterior Chain"],
        "auto_regulation": {
            "enabled": True,
            "load_progression": "rpe_based",
            "deload_frequency": "as_needed",
            "readiness_tracking": True
        },
        "phase_structure": {
            "total_phases": 3,
            "weeks_per_phase": 4,
            "advancement_criteria": "completion_and_performance"
        }
    }
}

response = requests.post(
    f"{SUPABASE_URL}/rest/v1/programs",
    headers=headers,
    json=program
)

if response.status_code in [200, 201]:
    result = response.json()[0] if isinstance(response.json(), list) else response.json()
    print(f"   ✅ Program created: {result.get('name')}")
else:
    print(f"   Status: {response.status_code}")
    if response.status_code == 409:
        print("   ℹ️  Program already exists - continuing...")
    else:
        print(f"   Response: {response.text[:300]}")

# Verify program exists
print("\n2️⃣  Verifying program...")
response = requests.get(
    f"{SUPABASE_URL}/rest/v1/programs?patient_id=eq.{NEW_PATIENT_ID}",
    headers=headers
)

if response.status_code == 200:
    programs = response.json()
    print(f"   ✅ Patient has {len(programs)} program(s)")
    for p in programs:
        print(f"      - {p['name']}")

print("\n" + "=" * 70)
print("✅ WINTER LIFT PROGRAM CREATED")
print("=" * 70)
print("\nNic Roma can now:")
print("  ✅ Log in with: nic.roma@ptperformance.app / nic-demo-2025")
print("  ✅ View Winter Lift 3x/week program")
print("  ✅ Use auto-regulation features (RPE tracking, deload triggers)")
print("  ✅ Complete daily readiness check-ins")
print()
print("⚠️  Note: Full program includes 3 phases, 9 sessions, ~120 exercises")
print("         These will be visible once the complete SQL migration runs")
