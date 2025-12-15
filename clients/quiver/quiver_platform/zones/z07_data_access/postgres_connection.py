#!/usr/bin/env python3
"""
PostgreSQL Connection Utilities for Sapphire v3
Provides connection pooling and query execution for 226GB biomedical data warehouse

Databases:
- rescue: Core biomedical data (LINCS, ChEMBL, KEGG, etc.)
- expo: Extended datasets and analytics

Author: claude-code-agent
Date: 2025-11-28
Version: 1.0
"""

import os
from typing import Dict, List, Any, Optional
import asyncio
import asyncpg
from contextlib import asynccontextmanager


class PostgresConnectionPool:
    """Manage PostgreSQL connection pools for rescue and expo databases."""

    def __init__(self):
        self.rescue_pool: Optional[asyncpg.Pool] = None
        self.expo_pool: Optional[asyncpg.Pool] = None
        self._initialized = False

    async def initialize(self):
        """Initialize connection pools."""
        if self._initialized:
            return

        try:
            # Get connection info from environment
            host = os.getenv("POSTGRES_HOST", "localhost")
            port = int(os.getenv("POSTGRES_PORT", "5432"))
            user = os.getenv("POSTGRES_USER", "postgres")
            password = os.getenv("POSTGRES_PASSWORD", "")

            # Initialize rescue database pool
            try:
                self.rescue_pool = await asyncpg.create_pool(
                    host=host,
                    port=port,
                    user=user,
                    password=password,
                    database="rescue",
                    min_size=2,
                    max_size=10,
                    command_timeout=60
                )
                print("✅ PostgreSQL 'rescue' pool initialized")
            except Exception as e:
                print(f"⚠️  Failed to initialize 'rescue' pool: {e}")

            # Initialize sapphire_database pool (PGVector v6.0)
            try:
                self.expo_pool = await asyncpg.create_pool(
                    host=host,
                    port=port,
                    user=user,
                    password=password,
                    database="sapphire_database",
                    min_size=2,
                    max_size=10,
                    command_timeout=60
                )
                print("✅ PostgreSQL 'sapphire_database' pool initialized")
            except Exception as e:
                print(f"⚠️  Failed to initialize 'expo' pool: {e}")

            self._initialized = True

        except Exception as e:
            print(f"❌ PostgreSQL initialization failed: {e}")

    async def close(self):
        """Close all connection pools."""
        if self.rescue_pool:
            await self.rescue_pool.close()
        if self.expo_pool:
            await self.expo_pool.close()
        self._initialized = False

    @asynccontextmanager
    async def get_connection(self, database: str = "rescue"):
        """Get a connection from the appropriate pool."""
        if not self._initialized:
            await self.initialize()

        pool = self.rescue_pool if database == "rescue" else self.expo_pool

        if not pool:
            raise RuntimeError(f"PostgreSQL pool for '{database}' not initialized")

        async with pool.acquire() as connection:
            yield connection

    async def execute_query(
        self,
        query: str,
        params: List[Any] = None,
        database: str = "rescue"
    ) -> List[Dict[str, Any]]:
        """
        Execute a query and return results as list of dicts.

        Args:
            query: SQL query (use $1, $2, etc. for parameters)
            params: Query parameters
            database: Database to query ("rescue" or "expo")

        Returns:
            List of result rows as dictionaries
        """
        async with self.get_connection(database) as conn:
            if params:
                rows = await conn.fetch(query, *params)
            else:
                rows = await conn.fetch(query)

            # Convert Record objects to dicts
            return [dict(row) for row in rows]

    async def execute_single(
        self,
        query: str,
        params: List[Any] = None,
        database: str = "rescue"
    ) -> Optional[Dict[str, Any]]:
        """Execute a query and return first result as dict."""
        results = await self.execute_query(query, params, database)
        return results[0] if results else None

    async def execute_scalar(
        self,
        query: str,
        params: List[Any] = None,
        database: str = "rescue"
    ) -> Any:
        """Execute a query and return first column of first row."""
        async with self.get_connection(database) as conn:
            if params:
                return await conn.fetchval(query, *params)
            else:
                return await conn.fetchval(query)


# Global connection pool instance
_pool: Optional[PostgresConnectionPool] = None


async def get_pool() -> PostgresConnectionPool:
    """Get or create the global connection pool."""
    global _pool
    if _pool is None:
        _pool = PostgresConnectionPool()
        await _pool.initialize()
    return _pool


async def query_postgres(
    query: str,
    params: List[Any] = None,
    database: str = "rescue"
) -> List[Dict[str, Any]]:
    """
    Convenience function to execute a query.

    Args:
        query: SQL query
        params: Query parameters
        database: Database to query ("rescue" or "expo")

    Returns:
        List of result rows as dictionaries
    """
    pool = await get_pool()
    return await pool.execute_query(query, params, database)


# Export for tool imports
__all__ = [
    "PostgresConnectionPool",
    "get_pool",
    "query_postgres"
]
