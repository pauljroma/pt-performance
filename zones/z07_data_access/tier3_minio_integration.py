"""
MinIO Tier 3 Integration - Historical Data Storage (7-90 days)
Object storage tier for bulk historical queries

Features:
- MinIO object storage client
- SQL to object storage query translation
- Historical data retrieval (7-90 days)
- Result caching layer for performance
- Batch operations support

Architecture:
- Data partitioned by date (YYYY-MM-DD)
- Parquet format for efficient storage
- Local caching with TTL
"""

import json
import os
import time
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, Any, List, Optional
from dataclasses import dataclass
from enum import Enum

try:
    from minio import Minio
    from minio.error import S3Error
    MINIO_AVAILABLE = True
except ImportError:
    MINIO_AVAILABLE = False
    print("Warning: MinIO library not installed. Run: pip install minio")


class HealthStatus(Enum):
    """Health status enumeration"""
    HEALTHY = "healthy"
    DEGRADED = "degraded"
    UNAVAILABLE = "unavailable"


@dataclass
class MinIOHealthCheck:
    """MinIO health check result"""
    available: bool
    latency_ms: float
    status: HealthStatus
    timestamp: datetime
    error: Optional[str] = None


@dataclass
class QueryResult:
    """MinIO query result"""
    data: List[Dict[str, Any]]
    row_count: int
    query_time_ms: float
    cached: bool
    bucket: str
    object_path: str


class MinIOTier:
    """
    Tier 3: MinIO Object Storage for Historical Data

    Handles queries for data aged 7-90 days with object storage backend
    """

    def __init__(
        self,
        endpoint: Optional[str] = None,
        access_key: Optional[str] = None,
        secret_key: Optional[str] = None,
        bucket: str = "pt-historical",
        secure: bool = True,
        cache_enabled: bool = True,
        cache_ttl_seconds: int = 300
    ):
        """
        Initialize MinIO tier

        Args:
            endpoint: MinIO endpoint (default: from MINIO_ENDPOINT env)
            access_key: Access key (default: from MINIO_ACCESS_KEY env)
            secret_key: Secret key (default: from MINIO_SECRET_KEY env)
            bucket: S3 bucket name
            secure: Use HTTPS
            cache_enabled: Enable result caching
            cache_ttl_seconds: Cache TTL in seconds
        """
        self.endpoint = endpoint or os.getenv("MINIO_ENDPOINT", "localhost:9000")
        self.access_key = access_key or os.getenv("MINIO_ACCESS_KEY", "minioadmin")
        self.secret_key = secret_key or os.getenv("MINIO_SECRET_KEY", "minioadmin")
        self.bucket = bucket
        self.secure = secure

        # Cache configuration
        self.cache_enabled = cache_enabled
        self.cache_ttl_seconds = cache_ttl_seconds
        self._cache: Dict[str, tuple] = {}  # key -> (result, timestamp)

        # Client initialization
        self.client = None
        self._initialize_client()

        # Stats tracking
        self.stats = {
            "total_queries": 0,
            "cache_hits": 0,
            "cache_misses": 0,
            "total_query_time_ms": 0.0,
            "total_rows_returned": 0
        }

    def _initialize_client(self) -> bool:
        """Initialize MinIO client"""
        if not MINIO_AVAILABLE:
            return False

        try:
            self.client = Minio(
                self.endpoint,
                access_key=self.access_key,
                secret_key=self.secret_key,
                secure=self.secure
            )

            # Ensure bucket exists
            if not self.client.bucket_exists(self.bucket):
                self.client.make_bucket(self.bucket)

            return True
        except Exception as e:
            print(f"Failed to initialize MinIO client: {e}")
            return False

    def health_check(self) -> MinIOHealthCheck:
        """
        Check MinIO availability and latency

        Returns:
            MinIOHealthCheck with status and metrics
        """
        start = time.perf_counter()

        if not MINIO_AVAILABLE or self.client is None:
            return MinIOHealthCheck(
                available=False,
                latency_ms=0.0,
                status=HealthStatus.UNAVAILABLE,
                timestamp=datetime.now(),
                error="MinIO client not initialized"
            )

        try:
            # Check bucket access
            self.client.bucket_exists(self.bucket)

            latency_ms = (time.perf_counter() - start) * 1000

            # Determine health status based on latency
            if latency_ms < 100:
                status = HealthStatus.HEALTHY
            elif latency_ms < 500:
                status = HealthStatus.DEGRADED
            else:
                status = HealthStatus.UNAVAILABLE

            return MinIOHealthCheck(
                available=True,
                latency_ms=latency_ms,
                status=status,
                timestamp=datetime.now()
            )

        except Exception as e:
            latency_ms = (time.perf_counter() - start) * 1000
            return MinIOHealthCheck(
                available=False,
                latency_ms=latency_ms,
                status=HealthStatus.UNAVAILABLE,
                timestamp=datetime.now(),
                error=str(e)
            )

    def query(
        self,
        filter_criteria: Dict[str, Any],
        days_back: int = 30,
        limit: int = 1000
    ) -> QueryResult:
        """
        Query historical data from MinIO

        Args:
            filter_criteria: Filter conditions (table, columns, where clauses)
            days_back: How many days back to query
            limit: Maximum rows to return

        Returns:
            QueryResult with data and metadata
        """
        start = time.perf_counter()
        self.stats["total_queries"] += 1

        # Generate cache key
        cache_key = self._generate_cache_key(filter_criteria, days_back, limit)

        # Check cache
        if self.cache_enabled:
            cached_result = self._get_from_cache(cache_key)
            if cached_result:
                self.stats["cache_hits"] += 1
                return cached_result

        self.stats["cache_misses"] += 1

        # Execute query
        data = self._execute_query(filter_criteria, days_back, limit)

        query_time_ms = (time.perf_counter() - start) * 1000
        self.stats["total_query_time_ms"] += query_time_ms
        self.stats["total_rows_returned"] += len(data)

        # Build result
        object_path = self._build_object_path(filter_criteria, days_back)
        result = QueryResult(
            data=data,
            row_count=len(data),
            query_time_ms=query_time_ms,
            cached=False,
            bucket=self.bucket,
            object_path=object_path
        )

        # Cache result
        if self.cache_enabled:
            self._add_to_cache(cache_key, result)

        return result

    def _execute_query(
        self,
        filter_criteria: Dict[str, Any],
        days_back: int,
        limit: int
    ) -> List[Dict[str, Any]]:
        """
        Execute query against MinIO

        This is a mock implementation that returns synthetic data.
        In production, this would:
        1. List objects matching the date range
        2. Download and parse Parquet files
        3. Apply filters and aggregations
        4. Return results
        """
        if not MINIO_AVAILABLE or self.client is None:
            # Return empty result if client not available
            return []

        # For demo: return synthetic historical data
        table = filter_criteria.get("table", "sessions")
        results = []

        # Generate sample historical data
        base_date = datetime.now() - timedelta(days=days_back)
        for i in range(min(limit, 10)):
            results.append({
                "id": f"hist_{i}",
                "table": table,
                "created_at": (base_date + timedelta(days=i)).isoformat(),
                "data": f"Historical record {i}",
                "tier": "minio",
                "days_back": days_back
            })

        return results

    def _build_object_path(
        self,
        filter_criteria: Dict[str, Any],
        days_back: int
    ) -> str:
        """Build S3 object path for query"""
        table = filter_criteria.get("table", "unknown")
        date = (datetime.now() - timedelta(days=days_back)).strftime("%Y-%m-%d")
        return f"{table}/{date}/*.parquet"

    def _generate_cache_key(
        self,
        filter_criteria: Dict[str, Any],
        days_back: int,
        limit: int
    ) -> str:
        """Generate cache key from query parameters"""
        key_parts = [
            str(filter_criteria.get("table", "")),
            str(days_back),
            str(limit),
            json.dumps(filter_criteria, sort_keys=True)
        ]
        return ":".join(key_parts)

    def _get_from_cache(self, cache_key: str) -> Optional[QueryResult]:
        """Get result from cache if valid"""
        if cache_key not in self._cache:
            return None

        result, timestamp = self._cache[cache_key]
        age_seconds = (time.time() - timestamp)

        if age_seconds > self.cache_ttl_seconds:
            # Cache expired
            del self._cache[cache_key]
            return None

        # Return cached result with updated flag
        cached_result = QueryResult(
            data=result.data,
            row_count=result.row_count,
            query_time_ms=0.0,  # Cached results have zero query time
            cached=True,
            bucket=result.bucket,
            object_path=result.object_path
        )
        return cached_result

    def _add_to_cache(self, cache_key: str, result: QueryResult):
        """Add result to cache"""
        self._cache[cache_key] = (result, time.time())

        # Simple cache eviction: keep only last 100 entries
        if len(self._cache) > 100:
            # Remove oldest entry
            oldest_key = min(self._cache.keys(), key=lambda k: self._cache[k][1])
            del self._cache[oldest_key]

    def clear_cache(self):
        """Clear all cached results"""
        self._cache.clear()

    def get_stats(self) -> Dict[str, Any]:
        """Get MinIO tier statistics"""
        total_queries = self.stats["total_queries"]
        if total_queries == 0:
            cache_hit_rate = 0.0
            avg_query_time = 0.0
        else:
            cache_hit_rate = (self.stats["cache_hits"] / total_queries) * 100
            avg_query_time = self.stats["total_query_time_ms"] / total_queries

        return {
            "total_queries": total_queries,
            "cache_hits": self.stats["cache_hits"],
            "cache_misses": self.stats["cache_misses"],
            "cache_hit_rate_pct": cache_hit_rate,
            "avg_query_time_ms": avg_query_time,
            "total_rows_returned": self.stats["total_rows_returned"],
            "cache_size": len(self._cache)
        }
