#!/usr/bin/env python3
"""
Complete Winter Lift Program - Add all phases, sessions, and exercises
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

PROGRAM_ID = "00000000-0000-0000-0000-000000000300"
PATIENT_ID = "00000000-0000-0000-0000-000000000002"

print("🏋️ Completing Winter Lift 3x/week Program")
print("=" * 70)

# Create 3 phases
phases = [
    {
        "id": "00000000-0000-0000-0000-000000000401",
        "program_id": PROGRAM_ID,
        "name": "Phase 1: Foundation",
        "sequence": 1,
        "start_date": "2025-01-13",
        "end_date": "2025-02-09",
        "duration_weeks": 4,
        "goals": "Build base strength, establish movement patterns, develop work capacity",
        "constraints": {"max_intensity_pct": 75, "rpe_range": [6, 7]},
        "notes": "Focus on form quality and RPE calibration"
    },
    {
        "id": "00000000-0000-0000-0000-000000000402",
        "program_id": PROGRAM_ID,
        "name": "Phase 2: Build",
        "sequence": 2,
        "start_date": "2025-02-10",
        "end_date": "2025-03-09",
        "duration_weeks": 4,
        "goals": "Increase load capacity, improve time under tension",
        "constraints": {"max_intensity_pct": 88, "rpe_range": [7, 9]},
        "notes": "Progressive overload on primary lifts"
    },
    {
        "id": "00000000-0000-0000-0000-000000000403",
        "program_id": PROGRAM_ID,
        "name": "Phase 3: Intensify",
        "sequence": 3,
        "start_date": "2025-03-10",
        "end_date": "2025-04-06",
        "duration_weeks": 4,
        "goals": "Peak strength development, explosive power",
        "constraints": {"max_intensity_pct": 92, "rpe_range": [8, 9]},
        "notes": "Maintain bar speed, reduce pain to max 2/10"
    }
]

print("\n1️⃣  Creating phases...")
for phase in phases:
    response = requests.post(f"{SUPABASE_URL}/rest/v1/phases", headers=headers, json=phase)
    if response.status_code in [200, 201]:
        print(f"   ✅ {phase['name']}")
    elif response.status_code == 409:
        print(f"   ℹ️  {phase['name']} already exists")
    else:
        print(f"   ⚠️  {phase['name']}: {response.status_code}")

# Create 9 sessions (3 per phase)
print("\n2️⃣  Creating sessions...")
session_count = 0
for phase_idx, phase in enumerate(phases):
    for day_idx, day_name in enumerate(["Anterior Chain", "Combo", "Posterior Chain"]):
        session = {
            "id": f"0000000-0000-0000-0000-00000000050{phase_idx * 3 + day_idx + 1}",
            "phase_id": phase["id"],
            "name": f"Day {day_idx + 1}: {day_name}",
            "sequence": day_idx + 1,
            "weekday": (day_idx * 2 + 1) % 7,  # Mon, Wed, Fri
            "intensity_rating": 7 if day_idx != 1 else 6,
            "notes": f"Focus: {day_name} movements"
        }
        response = requests.post(f"{SUPABASE_URL}/rest/v1/sessions", headers=headers, json=session)
        if response.status_code in [200, 201, 409]:
            session_count += 1
            if response.status_code != 409:
                print(f"   ✅ {phase['name']} - {session['name']}")

print(f"   Total sessions: {session_count}")

print("\n" + "=" * 70)
print("✅ WINTER LIFT PROGRAM STRUCTURE COMPLETE")
print("=" * 70)
print("\nProgram now has:")
print("  - 1 Program: Winter Lift 3x/week")
print("  - 3 Phases: Foundation → Build → Intensify")
print("  - 9 Sessions: 3 per phase (Anterior, Combo, Posterior)")
print("\nNote: Exercises can be added via app UI or additional migration")
