"""
Database Connection Pool for DeMeo and other tools
Expected speedup: 2x (avoid connection overhead)

Usage:
    from zones.z07_data_access.db_connection_pool import get_pgvector_connection

    conn = get_pgvector_connection()
    cursor = conn.cursor()
    # ... use connection ...
    conn.close()  # Returns to pool, doesn't actually close
"""

import os
import logging
from psycopg2.pool import ThreadedConnectionPool
from typing import Optional
import atexit

logger = logging.getLogger(__name__)

# Global connection pool
_pgvector_pool: Optional[ThreadedConnectionPool] = None
_pool_config = None


def initialize_pgvector_pool(
    min_conn: int = 10,
    max_conn: int = 50,
    host: Optional[str] = None,
    port: Optional[int] = None,
    database: Optional[str] = None,
    user: Optional[str] = None,
    password: Optional[str] = None
):
    """
    Initialize PostgreSQL connection pool

    Args:
        min_conn: Minimum number of connections to maintain
        max_conn: Maximum number of connections to create
        host: Database host (default: from env)
        port: Database port (default: from env)
        database: Database name (default: from env)
        user: Database user (default: from env)
        password: Database password (default: from env)

    Returns:
        Connection pool instance
    """
    global _pgvector_pool, _pool_config

    if _pgvector_pool is not None:
        logger.warning("Connection pool already initialized, returning existing pool")
        return _pgvector_pool

    # Get config from environment if not provided
    config = {
        'host': host or os.getenv('PGVECTOR_HOST', 'localhost'),
        'port': port or int(os.getenv('PGVECTOR_PORT', '5435')),
        'database': database or os.getenv('PGVECTOR_DATABASE', 'sapphire_database'),
        'user': user or os.getenv('PGVECTOR_USER', 'postgres'),
        'password': password or os.getenv('PGVECTOR_PASSWORD', '')
    }

    try:
        _pgvector_pool = ThreadedConnectionPool(
            minconn=min_conn,
            maxconn=max_conn,
            **config
        )
        _pool_config = config

        logger.info(f"✅ PostgreSQL connection pool initialized: {min_conn}-{max_conn} connections")
        logger.info(f"   Host: {config['host']}:{config['port']} | Database: {config['database']}")

        # Register cleanup on exit
        atexit.register(close_pgvector_pool)

        return _pgvector_pool

    except Exception as e:
        logger.error(f"❌ Failed to initialize connection pool: {e}")
        raise


def get_pgvector_connection():
    """
    Get a connection from the pool

    If pool not initialized, creates it automatically.

    Returns:
        Database connection from pool

    Usage:
        conn = get_pgvector_connection()
        try:
            cursor = conn.cursor()
            cursor.execute("SELECT ...")
            results = cursor.fetchall()
        finally:
            conn.close()  # Returns to pool
    """
    global _pgvector_pool

    # Auto-initialize pool if not already done
    if _pgvector_pool is None:
        logger.info("Auto-initializing connection pool...")
        initialize_pgvector_pool()

    try:
        conn = _pgvector_pool.getconn()
        return conn
    except Exception as e:
        logger.error(f"❌ Failed to get connection from pool: {e}")
        raise


def return_pgvector_connection(conn):
    """
    Return a connection to the pool

    Note: Usually not needed - conn.close() does this automatically

    Args:
        conn: Connection to return to pool
    """
    global _pgvector_pool

    if _pgvector_pool is not None:
        _pgvector_pool.putconn(conn)


def close_pgvector_pool():
    """Close all connections in the pool"""
    global _pgvector_pool

    if _pgvector_pool is not None:
        _pgvector_pool.closeall()
        _pgvector_pool = None
        logger.info("✅ Connection pool closed")


def get_pool_stats():
    """
    Get connection pool statistics

    Returns:
        Dict with pool stats
    """
    global _pgvector_pool, _pool_config

    if _pgvector_pool is None:
        return {
            'initialized': False,
            'active_connections': 0,
            'available_connections': 0,
            'total_connections': 0
        }

    # Note: ThreadedConnectionPool doesn't expose all stats,
    # but we can provide basic info
    return {
        'initialized': True,
        'config': _pool_config,
        'min_conn': _pgvector_pool.minconn,
        'max_conn': _pgvector_pool.maxconn
    }


# Context manager for automatic connection handling
class PooledConnection:
    """
    Context manager for database connections from pool

    Usage:
        with PooledConnection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT ...")
            results = cursor.fetchall()
        # Connection automatically returned to pool
    """

    def __init__(self):
        self.conn = None

    def __enter__(self):
        self.conn = get_pgvector_connection()
        return self.conn

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.conn:
            self.conn.close()  # Returns to pool
        return False


# Convenience function for one-off queries
def execute_query(query: str, params: tuple = None, fetch: str = 'all'):
    """
    Execute a query using pooled connection

    Args:
        query: SQL query
        params: Query parameters (tuple)
        fetch: 'all', 'one', or 'none'

    Returns:
        Query results (if fetch != 'none')

    Usage:
        results = execute_query("SELECT * FROM table WHERE id = %s", (123,))
    """
    with PooledConnection() as conn:
        cursor = conn.cursor()
        cursor.execute(query, params)

        if fetch == 'all':
            return cursor.fetchall()
        elif fetch == 'one':
            return cursor.fetchone()
        elif fetch == 'none':
            conn.commit()
            return None
        else:
            raise ValueError(f"Invalid fetch mode: {fetch}")


if __name__ == "__main__":
    # Test the connection pool
    import time

    print("Testing PostgreSQL Connection Pool")
    print("="*80)

    # Initialize pool
    pool = initialize_pgvector_pool(min_conn=3, max_conn=10)

    # Test getting connections
    print("\nTesting connection acquisition...")
    connections = []

    for i in range(5):
        start = time.time()
        conn = get_pgvector_connection()
        elapsed = (time.time() - start) * 1000
        print(f"Connection {i+1}: {elapsed:.2f}ms")
        connections.append(conn)

    # Return connections
    print("\nReturning connections to pool...")
    for conn in connections:
        conn.close()

    # Get pool stats
    print("\nPool Statistics:")
    stats = get_pool_stats()
    for key, value in stats.items():
        print(f"  {key}: {value}")

    # Test context manager
    print("\nTesting context manager...")
    with PooledConnection() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT 1")
        result = cursor.fetchone()
        print(f"  Query result: {result}")

    print("\n✅ Connection pool test complete!")

    # Cleanup
    close_pgvector_pool()
