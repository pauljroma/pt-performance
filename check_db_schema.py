#!/usr/bin/env python3
"""Check if database schema exists"""

import psycopg2
import urllib.parse as urlparse

DB_URL = "postgresql://postgres:rcq!vyd6qtb_HCP5mzt@db.rpbxeaxlaoyoqkohytlw.supabase.co:5432/postgres"

url = urlparse.urlparse(DB_URL)
conn = psycopg2.connect(
    database=url.path[1:],
    user=url.username,
    password=url.password,
    host=url.hostname,
    port=url.port
)

cursor = conn.cursor()

# Check what tables exist
cursor.execute("""
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
    ORDER BY table_name;
""")

tables = cursor.fetchall()
print(f"Found {len(tables)} tables:")
for table in tables:
    print(f"  • {table[0]}")

# Check if patients table exists
cursor.execute("""
    SELECT EXISTS (
        SELECT FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = 'patients'
    );
""")

exists = cursor.fetchone()[0]
print(f"\npatients table exists: {exists}")

if exists:
    # Check columns
    cursor.execute("""
        SELECT column_name, data_type
        FROM information_schema.columns
        WHERE table_name = 'patients'
        ORDER BY ordinal_position;
    """)
    columns = cursor.fetchall()
    print(f"\npatients table has {len(columns)} columns:")
    for col in columns:
        print(f"  • {col[0]} ({col[1]})")

cursor.close()
conn.close()
