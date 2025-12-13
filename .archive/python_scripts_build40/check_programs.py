#!/usr/bin/env python3
import os, requests
from dotenv import load_dotenv

load_dotenv()
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_KEY')

headers = {
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "apikey": SUPABASE_KEY
}

response = requests.get(
    f"{SUPABASE_URL}/rest/v1/programs?select=*",
    headers=headers
)

programs = response.json()
print(f"Total programs: {len(programs)}")
for p in programs:
    print(f"  - {p['name']} (Patient: {p['patient_id']}, ID: {p['id']})")
