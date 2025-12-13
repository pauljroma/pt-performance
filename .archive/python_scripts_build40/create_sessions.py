#!/usr/bin/env python3
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

# Create sessions for each phase
sessions = [
    # Phase 1 sessions
    {"id": "00000000-0000-0000-0000-000000000501", "phase_id": "00000000-0000-0000-0000-000000000401", "name": "Day 1: Anterior Chain", "sequence": 1, "weekday": 1},
    {"id": "00000000-0000-0000-0000-000000000502", "phase_id": "00000000-0000-0000-0000-000000000401", "name": "Day 2: Combo", "sequence": 2, "weekday": 3},
    {"id": "00000000-0000-0000-0000-000000000503", "phase_id": "00000000-0000-0000-0000-000000000401", "name": "Day 3: Posterior Chain", "sequence": 3, "weekday": 5},
    # Phase 2 sessions
    {"id": "00000000-0000-0000-0000-000000000504", "phase_id": "00000000-0000-0000-0000-000000000402", "name": "Day 1: Anterior Chain", "sequence": 1, "weekday": 1},
    {"id": "00000000-0000-0000-0000-000000000505", "phase_id": "00000000-0000-0000-0000-000000000402", "name": "Day 2: Combo", "sequence": 2, "weekday": 3},
    {"id": "00000000-0000-0000-0000-000000000506", "phase_id": "00000000-0000-0000-0000-000000000402", "name": "Day 3: Posterior Chain", "sequence": 3, "weekday": 5},
    # Phase 3 sessions
    {"id": "00000000-0000-0000-0000-000000000507", "phase_id": "00000000-0000-0000-0000-000000000403", "name": "Day 1: Anterior Chain", "sequence": 1, "weekday": 1},
    {"id": "00000000-0000-0000-0000-000000000508", "phase_id": "00000000-0000-0000-0000-000000000403", "name": "Day 2: Combo", "sequence": 2, "weekday": 3},
    {"id": "00000000-0000-0000-0000-000000000509", "phase_id": "00000000-0000-0000-0000-000000000403", "name": "Day 3: Posterior Chain", "sequence": 3, "weekday": 5},
]

print("Creating sessions...")
success = 0
for session in sessions:
    response = requests.post(f"{SUPABASE_URL}/rest/v1/sessions", headers=headers, json=session)
    if response.status_code in [200, 201]:
        print(f"✅ {session['name']}")
        success += 1
    elif response.status_code == 409:
        print(f"ℹ️  {session['name']} exists")
        success += 1
    else:
        print(f"⚠️  {session['name']}: {response.status_code} - {response.text[:100]}")

print(f"\n✅ Created/verified {success}/9 sessions")
