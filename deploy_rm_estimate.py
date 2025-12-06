#!/usr/bin/env python3
"""Deploy rm_estimate migration directly via psycopg2"""

import os
from dotenv import load_dotenv
import psycopg2

load_dotenv()

# Read SQL file
with open('infra/005_add_rm_estimate.sql', 'r') as f:
    sql = f.read()

# Connect to Supabase
supabase_url = os.getenv("SUPABASE_URL")
supabase_password = os.getenv("SUPABASE_PASSWORD")

if not supabase_url or not supabase_password:
    print("❌ Missing credentials")
    exit(1)

# Extract project ref
project_ref = supabase_url.replace("https://", "").replace(".supabase.co", "")
host = f"db.{project_ref}.supabase.co"

print("Connecting to Supabase...")
print(f"Host: {host}")

try:
    conn = psycopg2.connect(
        host=host,
        database="postgres",
        user="postgres",
        password=supabase_password,
        port=6543,  # Supabase uses port 6543 for connection pooler
        connect_timeout=10
    )
    conn.autocommit = True
    cursor = conn.cursor()

    print("✅ Connected!")
    print("\n📝 Executing rm_estimate migration...")

    cursor.execute(sql)

    print("✅ Migration deployed successfully!")

    cursor.close()
    conn.close()

except Exception as e:
    print(f"❌ Error: {e}")
    print("\nTrying port 5432...")

    try:
        conn = psycopg2.connect(
            host=host,
            database="postgres",
            user="postgres",
            password=supabase_password,
            port=5432,
            connect_timeout=10
        )
        conn.autocommit = True
        cursor = conn.cursor()

        print("✅ Connected on port 5432!")
        print("\n📝 Executing rm_estimate migration...")

        cursor.execute(sql)

        print("✅ Migration deployed successfully!")

        cursor.close()
        conn.close()

    except Exception as e2:
        print(f"❌ Error: {e2}")
        exit(1)
