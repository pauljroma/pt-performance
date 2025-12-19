#!/usr/bin/env python3
"""
Resilient Component Registry - Graceful Degradation

Primary: PostgreSQL (fast, structured)
Fallback 1: JSON export cache (if PostgreSQL down)
Fallback 2: Direct code search (if all else fails)

Author: claude-code-agent
Date: 2025-12-02
Version: 1.0
"""

import asyncio
import asyncpg
import json
import os
import subprocess
from pathlib import Path
from typing import Dict, List, Any, Optional
from datetime import datetime
from enum import Enum


class RegistryMode(Enum):
    """Registry access mode."""
    POSTGRESQL = "postgresql"
    JSON_CACHE = "json_cache"
    CODE_SEARCH = "code_search"


class ResilientComponentRegistry:
    """Component registry with graceful degradation.

    Tries PostgreSQL first, falls back to JSON cache, then code search.
    """

    def __init__(self):
        self.repo_root = Path(__file__).parent.parent.parent
        self.json_cache = self.repo_root / ".outcomes" / "component_registry_cache.json"
        self.pool: Optional[asyncpg.Pool] = None
        self.mode: Optional[RegistryMode] = None

        # PostgreSQL config
        self.host = os.getenv("POSTGRES_HOST", "localhost")
        self.port = int(os.getenv("POSTGRES_PORT", "5435"))
        self.user = os.getenv("POSTGRES_USER", "postgres")
        self.password = os.getenv("POSTGRES_PASSWORD", "temppass123")
        self.database = "sapphire_database"

    async def initialize(self):
        """Initialize registry with automatic fallback."""
        # Try PostgreSQL first
        try:
            self.pool = await asyncpg.create_pool(
                host=self.host,
                port=self.port,
                user=self.user,
                password=self.password,
                database=self.database,
                min_size=1,
                max_size=3,
                command_timeout=5  # Fast timeout
            )
            # Test connection
            async with self.pool.acquire() as conn:
                await conn.fetchval("SELECT 1")

            self.mode = RegistryMode.POSTGRESQL
            print(f"✅ Registry mode: PostgreSQL (expo database)")
            return
        except Exception as e:
            print(f"⚠️  PostgreSQL unavailable: {e}")

        # Fallback to JSON cache
        if self.json_cache.exists():
            self.mode = RegistryMode.JSON_CACHE
            print(f"⚠️  Registry mode: JSON cache (degraded)")
            return

        # Final fallback to code search
        self.mode = RegistryMode.CODE_SEARCH
        print(f"⚠️  Registry mode: Code search (limited functionality)")

    async def close(self):
        """Close connections."""
        if self.pool:
            await self.pool.close()

    async def search(
        self,
        query: Optional[str] = None,
        component_type: Optional[str] = None,
        zone: Optional[str] = None,
        **kwargs
    ) -> List[Dict[str, Any]]:
        """Search components with automatic fallback."""

        if self.mode == RegistryMode.POSTGRESQL:
            return await self._search_postgresql(query, component_type, zone)

        elif self.mode == RegistryMode.JSON_CACHE:
            return self._search_json_cache(query, component_type, zone)

        else:  # CODE_SEARCH
            return self._search_code(query)

    async def _search_postgresql(
        self,
        query: Optional[str],
        component_type: Optional[str],
        zone: Optional[str]
    ) -> List[Dict[str, Any]]:
        """Search PostgreSQL (fast, structured)."""
        async with self.pool.acquire() as conn:
            # Build WHERE clause
            conditions = []
            params = []
            param_count = 1

            if query:
                conditions.append(f"(component_id ILIKE ${param_count} OR component_name ILIKE ${param_count})")
                params.append(f"%{query}%")
                param_count += 1

            if component_type:
                conditions.append(f"component_type = ${param_count}")
                params.append(component_type)
                param_count += 1

            if zone:
                conditions.append(f"zone = ${param_count}")
                params.append(zone)
                param_count += 1

            where_clause = " AND ".join(conditions) if conditions else "TRUE"

            rows = await conn.fetch(f"""
                SELECT
                    component_id,
                    component_name,
                    component_type,
                    version,
                    zone,
                    file_path,
                    module_path,
                    deployment_status
                FROM components
                WHERE {where_clause}
                ORDER BY component_id
                LIMIT 50
            """, *params)

            return [dict(row) for row in rows]

    def _search_json_cache(
        self,
        query: Optional[str],
        component_type: Optional[str],
        zone: Optional[str]
    ) -> List[Dict[str, Any]]:
        """Search JSON cache (slower, but works offline)."""
        with open(self.json_cache) as f:
            data = json.load(f)

        components = data.get("components", [])
        results = []

        for comp in components:
            # Filter by query
            if query:
                query_lower = query.lower()
                if not (query_lower in comp.get("component_id", "").lower() or
                       query_lower in comp.get("component_name", "").lower()):
                    continue

            # Filter by type
            if component_type and comp.get("component_type") != component_type:
                continue

            # Filter by zone
            if zone and comp.get("zone") != zone:
                continue

            results.append(comp)

        return results[:50]  # Limit results

    def _search_code(self, query: Optional[str]) -> List[Dict[str, Any]]:
        """Search code directly (last resort)."""
        if not query:
            return []

        results = []

        # Search for class definitions
        try:
            output = subprocess.check_output(
                ["grep", "-r", "--include=*.py", f"class.*{query}",
                 str(self.repo_root / "quiver_platform" / "zones")],
                stderr=subprocess.DEVNULL,
                text=True,
                timeout=5
            )

            for line in output.strip().split('\n')[:20]:  # Limit results
                if ':' in line:
                    file_path, code = line.split(':', 1)
                    results.append({
                        "component_id": f"found-{len(results)}",
                        "component_name": query,
                        "component_type": "unknown",
                        "file_path": file_path,
                        "source": "code_search"
                    })
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
            pass

        return results

    async def get_statistics(self) -> Dict[str, Any]:
        """Get registry statistics."""
        if self.mode == RegistryMode.POSTGRESQL:
            return await self._get_stats_postgresql()
        elif self.mode == RegistryMode.JSON_CACHE:
            return self._get_stats_json_cache()
        else:
            return {"mode": "code_search", "note": "Limited statistics in code search mode"}

    async def _get_stats_postgresql(self) -> Dict[str, Any]:
        """Get stats from PostgreSQL."""
        async with self.pool.acquire() as conn:
            count = await conn.fetchval("SELECT COUNT(*) FROM components")
            return {
                "mode": "postgresql",
                "total_components": count,
                "status": "healthy"
            }

    def _get_stats_json_cache(self) -> Dict[str, Any]:
        """Get stats from JSON cache."""
        with open(self.json_cache) as f:
            data = json.load(f)
        return {
            "mode": "json_cache",
            "total_components": len(data.get("components", [])),
            "status": "degraded",
            "note": "Using cached data - may be stale"
        }

    async def refresh_cache(self):
        """Refresh JSON cache from PostgreSQL."""
        if self.mode != RegistryMode.POSTGRESQL:
            print("❌ Cannot refresh cache - PostgreSQL not available")
            return

        print("🔄 Refreshing JSON cache from PostgreSQL...")

        async with self.pool.acquire() as conn:
            rows = await conn.fetch("""
                SELECT
                    component_id,
                    component_name,
                    component_type,
                    version,
                    zone,
                    file_path,
                    module_path,
                    deployment_status,
                    test_coverage,
                    type_safety
                FROM components
                ORDER BY component_id
            """)

            components = [dict(row) for row in rows]

            cache_data = {
                "version": "1.0-cache",
                "total_components": len(components),
                "last_updated": datetime.utcnow().isoformat(),
                "source": "postgresql",
                "components": components
            }

            with open(self.json_cache, 'w') as f:
                json.dump(cache_data, f, indent=2, default=str)

            print(f"✅ Cache refreshed: {len(components)} components")
            print(f"📁 Cache location: {self.json_cache}")


async def main():
    """CLI for resilient registry."""
    import sys

    registry = ResilientComponentRegistry()
    await registry.initialize()

    try:
        if len(sys.argv) < 2:
            print("Usage: python component_registry_resilient.py <command> [options]")
            print("\nCommands:")
            print("  stats                  - Get registry statistics")
            print("  search --query <term>  - Search components")
            print("  search --zone <zone>   - Search by zone")
            print("  refresh-cache          - Update JSON cache from PostgreSQL")
            return

        command = sys.argv[1]

        if command == "stats":
            stats = await registry.get_statistics()
            print(json.dumps(stats, indent=2, default=str))

        elif command == "search":
            # Parse arguments
            query = None
            zone = None
            component_type = None

            i = 2
            while i < len(sys.argv):
                if sys.argv[i] == "--query" and i + 1 < len(sys.argv):
                    query = sys.argv[i + 1]
                    i += 2
                elif sys.argv[i] == "--zone" and i + 1 < len(sys.argv):
                    zone = sys.argv[i + 1]
                    i += 2
                elif sys.argv[i] == "--type" and i + 1 < len(sys.argv):
                    component_type = sys.argv[i + 1]
                    i += 2
                else:
                    i += 1

            results = await registry.search(query=query, zone=zone, component_type=component_type)
            print(f"\nFound {len(results)} component(s):")
            for comp in results:
                print(f"  - {comp.get('component_id')} ({comp.get('component_type')})")

        elif command == "refresh-cache":
            await registry.refresh_cache()

        else:
            print(f"Unknown command: {command}")

    finally:
        await registry.close()


if __name__ == "__main__":
    asyncio.run(main())
