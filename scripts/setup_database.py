#!/usr/bin/env python3.11
"""
Setup database for Quiver v0.6.0 - Zone 8 (Persist)

Creates all tables and sets up pgvector extension.

Usage:
    python scripts/setup_database.py
"""

import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from quiver_platform.zones.z08_persist.config import load_config_from_env
from quiver_platform.zones.z08_persist.session import get_session_manager


def setup_database():
    """Set up database with tables and extensions."""
    print("🔧 Setting up Quiver database...")

    # Load configuration
    config = load_config_from_env()
    print(f"📍 Database: {config.database} @ {config.host}:{config.port}")

    # Get session manager
    manager = get_session_manager(config)

    try:
        # Test connection
        with manager.session_scope() as session:
            result = session.execute("SELECT version();")
            version = result.fetchone()[0]
            print(f"✅ Connected to PostgreSQL: {version[:50]}...")

        # Check for pgvector extension
        if config.enable_pgvector:
            with manager.session_scope() as session:
                try:
                    session.execute("CREATE EXTENSION IF NOT EXISTS vector;")
                    print("✅ pgvector extension enabled")
                except Exception as e:
                    print(f"⚠️  Warning: Could not enable pgvector: {e}")
                    print("   Install pgvector: https://github.com/pgvector/pgvector")

        # Create all tables
        print("📋 Creating tables...")
        manager.create_all_tables()
        print("✅ Tables created successfully")

        # List created tables
        with manager.session_scope() as session:
            result = session.execute(
                """
                SELECT table_name
                FROM information_schema.tables
                WHERE table_schema = 'public'
                ORDER BY table_name;
            """
            )
            tables = [row[0] for row in result.fetchall()]

            if tables:
                print(f"\n📊 Created {len(tables)} table(s):")
                for table in tables:
                    print(f"   - {table}")
            else:
                print("⚠️  No tables found")

        print("\n✅ Database setup complete!")
        print("\n📝 Next steps:")
        print("   1. Load sample data: python scripts/load_sample_drugs.py")
        print("   2. Generate embeddings: python scripts/generate_embeddings.py")

    except Exception as e:
        print(f"\n❌ Error setting up database: {e}")
        print("\n💡 Troubleshooting:")
        print("   1. Ensure PostgreSQL is running:")
        print("      brew services start postgresql@15")
        print("   2. Create database if it doesn't exist:")
        print(f"      createdb {config.database}")
        print("   3. Check environment variables:")
        print("      QUIVER_DB_HOST, QUIVER_DB_PORT, QUIVER_DB_NAME, QUIVER_DB_USER")
        sys.exit(1)


if __name__ == "__main__":
    setup_database()
