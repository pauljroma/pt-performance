#!/usr/bin/env python3
"""
Validate ALL Database Schemas Against iOS Models
=================================================
Comprehensively check every table/view the app uses.
"""

import requests

SUPABASE_URL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
SUPABASE_SERVICE_KEY = "sb_secret_FYMKefuStzD82VUTplnsuw_GHN_0hb3"

headers = {
    "apikey": SUPABASE_SERVICE_KEY,
    "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
}

# iOS Models with required columns (from CodingKeys)
MODELS = {
    "vw_pain_trend → PainDataPoint": {
        "table": "vw_pain_trend",
        "required": ["id", "logged_date", "avg_pain", "session_number"]
    },
    "vw_patient_adherence → AdherenceData": {
        "table": "vw_patient_adherence",
        "required": ["adherence_pct", "completed_sessions", "total_sessions"]
    },
    "session_notes → SessionNote": {
        "table": "session_notes",
        "required": ["id", "patient_id", "session_id", "note_type", "note_text", "created_by", "created_at"]
    },
    "programs → Program": {
        "table": "programs",
        "required": ["id", "patient_id", "name", "target_level", "duration_weeks", "created_at"]
    },
    "phases → Phase": {
        "table": "phases",
        "required": ["id", "program_id", "phase_number", "name", "duration_weeks", "goals"]
    }
}

print("=" * 80)
print("VALIDATING ALL SCHEMAS AGAINST iOS MODELS")
print("=" * 80)

failures = []

for model_name, config in MODELS.items():
    table = config["table"]
    required = config["required"]

    print(f"\n{model_name}")
    print(f"   Querying {table}...")

    # Get one row to see actual columns
    url = f"{SUPABASE_URL}/rest/v1/{table}?limit=1&select=*"
    response = requests.get(url, headers=headers)

    if response.status_code != 200:
        print(f"   ❌ Table/view doesn't exist or error: {response.status_code}")
        failures.append((model_name, f"Table query failed: {response.text[:100]}"))
        continue

    data = response.json()
    if not data:
        # Empty table - try to infer columns from header or try a different approach
        print(f"   ⚠️ Table is empty, trying column check via select...")
        # Try selecting specific columns
        select_cols = ",".join(required)
        url2 = f"{SUPABASE_URL}/rest/v1/{table}?limit=0&select={select_cols}"
        response2 = requests.get(url2, headers=headers)
        if response2.status_code == 200:
            print(f"   ✅ All required columns exist (table empty but columns accessible)")
        else:
            error_msg = response2.text
            print(f"   ❌ Column check failed: {error_msg[:200]}")
            failures.append((model_name, error_msg))
    else:
        # Check actual columns
        actual = list(data[0].keys())
        missing = [col for col in required if col not in actual]

        if missing:
            print(f"   ❌ MISSING COLUMNS: {missing}")
            print(f"   Available: {actual}")
            failures.append((model_name, f"Missing: {missing}"))
        else:
            print(f"   ✅ All required columns present")
            print(f"   Columns: {actual}")

# Summary
print("\n" + "=" * 80)
print("SUMMARY")
print("=" * 80)

if failures:
    print(f"\n❌ {len(failures)} SCHEMA MISMATCHES FOUND:\n")
    for model, error in failures:
        print(f"{model}")
        print(f"   Error: {error}\n")

    print("\nTHESE ARE THE EXACT ERRORS THE APP IS HITTING!")
    print("Each mismatch causes JSON decoding to fail → 'Unable to load' error")
else:
    print("\n✅ ALL SCHEMAS VALID!")

print("=" * 80)
