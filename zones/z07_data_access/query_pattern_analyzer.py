"""
Query Pattern Analyzer - Wave 2 Agent 11
Analyzes historical query patterns for ML training and optimization

Features:
- Query pattern extraction and classification
- Historical query database with SQLite backend
- Pattern clustering and temporal analysis
- Feature extraction for ML training
- Performance tracking and optimization suggestions
"""

import os
import json
import sqlite3
import hashlib
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, Any, List, Optional, Tuple
from dataclasses import dataclass, asdict
from collections import defaultdict
from enum import Enum

import numpy as np


class QueryPattern(Enum):
    """Common query pattern types"""
    RECENT_LOOKUP = "recent_lookup"  # Recent data, simple filters
    SEMANTIC_SEARCH = "semantic_search"  # Vector similarity
    HISTORICAL_SCAN = "historical_scan"  # Historical data range scan
    ANALYTICS_AGGREGATION = "analytics_aggregation"  # Complex aggregations
    TIME_SERIES = "time_series"  # Time-based analysis
    BULK_EXPORT = "bulk_export"  # Large data export


@dataclass
class QueryRecord:
    """Historical query record for pattern analysis"""
    query_id: str
    timestamp: datetime
    query_params: Dict[str, Any]
    selected_tier: str
    actual_latency_ms: float
    result_size: int
    pattern_type: str
    was_optimal: bool  # Whether tier selection was optimal
    metadata: Dict[str, Any]

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for serialization"""
        return {
            'query_id': self.query_id,
            'timestamp': self.timestamp.isoformat(),
            'query_params': self.query_params,
            'selected_tier': self.selected_tier,
            'actual_latency_ms': self.actual_latency_ms,
            'result_size': self.result_size,
            'pattern_type': self.pattern_type,
            'was_optimal': self.was_optimal,
            'metadata': self.metadata
        }

    @staticmethod
    def from_dict(data: Dict[str, Any]) -> 'QueryRecord':
        """Create from dictionary"""
        return QueryRecord(
            query_id=data['query_id'],
            timestamp=datetime.fromisoformat(data['timestamp']),
            query_params=data['query_params'],
            selected_tier=data['selected_tier'],
            actual_latency_ms=data['actual_latency_ms'],
            result_size=data['result_size'],
            pattern_type=data['pattern_type'],
            was_optimal=data['was_optimal'],
            metadata=data.get('metadata', {})
        )


@dataclass
class PatternCluster:
    """Cluster of similar query patterns"""
    cluster_id: int
    pattern_type: str
    query_count: int
    avg_latency_ms: float
    optimal_tier: str
    tier_distribution: Dict[str, int]
    temporal_pattern: Dict[str, int]  # Hour of day distribution
    feature_centroid: Dict[str, float]


@dataclass
class PatternAnalysis:
    """Analysis results for query patterns"""
    total_queries: int
    unique_patterns: int
    pattern_distribution: Dict[str, int]
    temporal_patterns: Dict[str, List[int]]  # Hour-of-day patterns per type
    tier_accuracy: Dict[str, float]  # % of optimal tier selections per pattern
    clusters: List[PatternCluster]
    recommendations: List[str]


class QueryPatternAnalyzer:
    """
    Analyzes historical query patterns to improve ML model training

    Maintains a SQLite database of historical queries and extracts
    patterns for model training and optimization.
    """

    def __init__(self, db_path: Optional[str] = None):
        """
        Initialize query pattern analyzer

        Args:
            db_path: Path to SQLite database (default: in-memory)
        """
        if db_path is None:
            # Use persistent file in same directory
            db_path = str(Path(__file__).parent / "query_patterns.db")

        self.db_path = db_path
        self.conn = None
        self._init_database()

    def _init_database(self):
        """Initialize SQLite database for query history"""
        self.conn = sqlite3.connect(self.db_path)
        cursor = self.conn.cursor()

        # Create queries table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS query_history (
                query_id TEXT PRIMARY KEY,
                timestamp TEXT NOT NULL,
                query_params TEXT NOT NULL,
                selected_tier TEXT NOT NULL,
                actual_latency_ms REAL NOT NULL,
                result_size INTEGER NOT NULL,
                pattern_type TEXT NOT NULL,
                was_optimal INTEGER NOT NULL,
                metadata TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # Create indexes for faster queries
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_timestamp
            ON query_history(timestamp)
        """)

        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_pattern_type
            ON query_history(pattern_type)
        """)

        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_selected_tier
            ON query_history(selected_tier)
        """)

        self.conn.commit()

    def record_query(
        self,
        query_params: Dict[str, Any],
        selected_tier: str,
        actual_latency_ms: float,
        result_size: int,
        was_optimal: bool = True,
        metadata: Optional[Dict[str, Any]] = None
    ) -> str:
        """
        Record a query execution for pattern analysis

        Args:
            query_params: Query parameters
            selected_tier: Tier that executed the query
            actual_latency_ms: Actual execution time
            result_size: Number of rows returned
            was_optimal: Whether tier selection was optimal
            metadata: Additional metadata

        Returns:
            Query ID
        """
        # Generate unique query ID
        query_id = self._generate_query_id(query_params)

        # Classify pattern type
        pattern_type = self._classify_pattern(query_params, result_size)

        # Create record
        record = QueryRecord(
            query_id=query_id,
            timestamp=datetime.now(),
            query_params=query_params,
            selected_tier=selected_tier,
            actual_latency_ms=actual_latency_ms,
            result_size=result_size,
            pattern_type=pattern_type,
            was_optimal=was_optimal,
            metadata=metadata or {}
        )

        # Insert into database
        cursor = self.conn.cursor()
        cursor.execute("""
            INSERT OR REPLACE INTO query_history
            (query_id, timestamp, query_params, selected_tier, actual_latency_ms,
             result_size, pattern_type, was_optimal, metadata)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            record.query_id,
            record.timestamp.isoformat(),
            json.dumps(record.query_params),
            record.selected_tier,
            record.actual_latency_ms,
            record.result_size,
            record.pattern_type,
            int(record.was_optimal),
            json.dumps(record.metadata)
        ))

        self.conn.commit()
        return query_id

    def _generate_query_id(self, query_params: Dict[str, Any]) -> str:
        """Generate unique ID for query based on parameters"""
        # Create deterministic hash of query parameters
        param_str = json.dumps(query_params, sort_keys=True)
        timestamp_str = datetime.now().isoformat()
        combined = f"{param_str}:{timestamp_str}"
        return hashlib.sha256(combined.encode()).hexdigest()[:16]

    def _classify_pattern(self, query_params: Dict[str, Any], result_size: int) -> str:
        """
        Classify query into pattern type

        Args:
            query_params: Query parameters
            result_size: Result set size

        Returns:
            Pattern type string
        """
        # Semantic search
        if query_params.get('use_embeddings') or query_params.get('similarity_search'):
            return QueryPattern.SEMANTIC_SEARCH.value

        # Analytics aggregation
        if query_params.get('has_aggregation') or result_size < 100:
            days_back = query_params.get('days_back', 0)
            if days_back > 90:
                return QueryPattern.ANALYTICS_AGGREGATION.value

        # Bulk export
        if result_size > 10000:
            return QueryPattern.BULK_EXPORT.value

        # Time series
        if query_params.get('time_series') or query_params.get('group_by_time'):
            return QueryPattern.TIME_SERIES.value

        # Historical scan
        days_back = query_params.get('days_back', 0)
        if days_back > 7:
            return QueryPattern.HISTORICAL_SCAN.value

        # Default: recent lookup
        return QueryPattern.RECENT_LOOKUP.value

    def get_query_history(
        self,
        days_back: int = 7,
        pattern_type: Optional[str] = None,
        tier: Optional[str] = None,
        limit: int = 1000
    ) -> List[QueryRecord]:
        """
        Retrieve query history with filters

        Args:
            days_back: Number of days to look back
            pattern_type: Filter by pattern type
            tier: Filter by tier
            limit: Maximum records to return

        Returns:
            List of QueryRecord objects
        """
        cursor = self.conn.cursor()

        # Build query
        query = "SELECT * FROM query_history WHERE timestamp >= ?"
        params = [
            (datetime.now() - timedelta(days=days_back)).isoformat()
        ]

        if pattern_type:
            query += " AND pattern_type = ?"
            params.append(pattern_type)

        if tier:
            query += " AND selected_tier = ?"
            params.append(tier)

        query += " ORDER BY timestamp DESC LIMIT ?"
        params.append(limit)

        cursor.execute(query, params)

        # Convert to QueryRecord objects
        records = []
        for row in cursor.fetchall():
            record = QueryRecord(
                query_id=row[0],
                timestamp=datetime.fromisoformat(row[1]),
                query_params=json.loads(row[2]),
                selected_tier=row[3],
                actual_latency_ms=row[4],
                result_size=row[5],
                pattern_type=row[6],
                was_optimal=bool(row[7]),
                metadata=json.loads(row[8]) if row[8] else {}
            )
            records.append(record)

        return records

    def analyze_patterns(self, days_back: int = 30) -> PatternAnalysis:
        """
        Analyze query patterns over time period

        Args:
            days_back: Number of days to analyze

        Returns:
            PatternAnalysis with insights
        """
        records = self.get_query_history(days_back=days_back, limit=10000)

        if not records:
            return PatternAnalysis(
                total_queries=0,
                unique_patterns=0,
                pattern_distribution={},
                temporal_patterns={},
                tier_accuracy={},
                clusters=[],
                recommendations=[]
            )

        # Calculate pattern distribution
        pattern_counts = defaultdict(int)
        for record in records:
            pattern_counts[record.pattern_type] += 1

        # Temporal patterns (hour of day distribution)
        temporal_patterns = defaultdict(lambda: [0] * 24)
        for record in records:
            hour = record.timestamp.hour
            temporal_patterns[record.pattern_type][hour] += 1

        # Tier accuracy by pattern
        tier_accuracy = {}
        for pattern_type in pattern_counts.keys():
            pattern_records = [r for r in records if r.pattern_type == pattern_type]
            optimal_count = sum(1 for r in pattern_records if r.was_optimal)
            tier_accuracy[pattern_type] = (optimal_count / len(pattern_records)) * 100

        # Cluster similar queries
        clusters = self._cluster_patterns(records)

        # Generate recommendations
        recommendations = self._generate_recommendations(records, tier_accuracy)

        return PatternAnalysis(
            total_queries=len(records),
            unique_patterns=len(pattern_counts),
            pattern_distribution=dict(pattern_counts),
            temporal_patterns=dict(temporal_patterns),
            tier_accuracy=tier_accuracy,
            clusters=clusters,
            recommendations=recommendations
        )

    def _cluster_patterns(self, records: List[QueryRecord], max_clusters: int = 5) -> List[PatternCluster]:
        """Cluster similar query patterns"""
        if not records:
            return []

        # Group by pattern type
        pattern_groups = defaultdict(list)
        for record in records:
            pattern_groups[record.pattern_type].append(record)

        clusters = []
        cluster_id = 0

        for pattern_type, group_records in pattern_groups.items():
            # Calculate statistics for this pattern type
            latencies = [r.actual_latency_ms for r in group_records]
            tier_dist = defaultdict(int)
            hour_dist = defaultdict(int)

            for record in group_records:
                tier_dist[record.selected_tier] += 1
                hour_dist[record.timestamp.hour] += 1

            # Find most common tier (optimal tier for this pattern)
            optimal_tier = max(tier_dist.items(), key=lambda x: x[1])[0]

            # Create cluster
            cluster = PatternCluster(
                cluster_id=cluster_id,
                pattern_type=pattern_type,
                query_count=len(group_records),
                avg_latency_ms=np.mean(latencies),
                optimal_tier=optimal_tier,
                tier_distribution=dict(tier_dist),
                temporal_pattern=dict(hour_dist),
                feature_centroid=self._calculate_centroid(group_records)
            )

            clusters.append(cluster)
            cluster_id += 1

        return clusters[:max_clusters]

    def _calculate_centroid(self, records: List[QueryRecord]) -> Dict[str, float]:
        """Calculate feature centroid for a group of queries"""
        # Extract numeric features
        days_back_values = []
        result_sizes = []
        latencies = []

        for record in records:
            days_back_values.append(record.query_params.get('days_back', 0))
            result_sizes.append(record.result_size)
            latencies.append(record.actual_latency_ms)

        return {
            'avg_days_back': float(np.mean(days_back_values)),
            'avg_result_size': float(np.mean(result_sizes)),
            'avg_latency_ms': float(np.mean(latencies)),
            'std_latency_ms': float(np.std(latencies))
        }

    def _generate_recommendations(
        self,
        records: List[QueryRecord],
        tier_accuracy: Dict[str, float]
    ) -> List[str]:
        """Generate optimization recommendations based on patterns"""
        recommendations = []

        # Check for low accuracy patterns
        for pattern_type, accuracy in tier_accuracy.items():
            if accuracy < 70:
                recommendations.append(
                    f"Low routing accuracy ({accuracy:.1f}%) for {pattern_type} queries. "
                    f"Consider retraining ML model with more {pattern_type} examples."
                )

        # Check for temporal patterns
        temporal_patterns = defaultdict(lambda: [0] * 24)
        for record in records:
            hour = record.timestamp.hour
            temporal_patterns[record.pattern_type][hour] += 1

        for pattern_type, hourly_counts in temporal_patterns.items():
            peak_hour = hourly_counts.index(max(hourly_counts))
            if max(hourly_counts) > sum(hourly_counts) * 0.3:  # >30% in one hour
                recommendations.append(
                    f"{pattern_type} queries peak at hour {peak_hour}. "
                    f"Consider time-based tier scaling."
                )

        # Check for high latency patterns
        for pattern_type in set(r.pattern_type for r in records):
            pattern_records = [r for r in records if r.pattern_type == pattern_type]
            avg_latency = np.mean([r.actual_latency_ms for r in pattern_records])
            if avg_latency > 500:
                recommendations.append(
                    f"High average latency ({avg_latency:.0f}ms) for {pattern_type}. "
                    f"Review tier assignment strategy."
                )

        return recommendations

    def export_training_data(
        self,
        days_back: int = 30,
        min_samples_per_tier: int = 50
    ) -> List[Tuple[Dict[str, Any], str]]:
        """
        Export query history as ML training data

        Args:
            days_back: Days of history to export
            min_samples_per_tier: Minimum samples required per tier

        Returns:
            List of (query_params, optimal_tier) tuples for ML training
        """
        records = self.get_query_history(days_back=days_back, limit=10000)

        # Filter to only optimal queries
        optimal_records = [r for r in records if r.was_optimal]

        # Check we have enough samples per tier
        tier_counts = defaultdict(int)
        for record in optimal_records:
            tier_counts[record.selected_tier] += 1

        for tier, count in tier_counts.items():
            if count < min_samples_per_tier:
                print(f"Warning: Only {count} samples for tier {tier}, need {min_samples_per_tier}")

        # Convert to training data format
        training_data = [
            (record.query_params, record.selected_tier)
            for record in optimal_records
        ]

        return training_data

    def get_stats(self) -> Dict[str, Any]:
        """Get analyzer statistics"""
        cursor = self.conn.cursor()

        # Total queries
        cursor.execute("SELECT COUNT(*) FROM query_history")
        total_queries = cursor.fetchone()[0]

        # Queries by tier
        cursor.execute("""
            SELECT selected_tier, COUNT(*)
            FROM query_history
            GROUP BY selected_tier
        """)
        tier_counts = dict(cursor.fetchall())

        # Recent queries (last 24 hours)
        cursor.execute("""
            SELECT COUNT(*) FROM query_history
            WHERE timestamp >= ?
        """, [(datetime.now() - timedelta(hours=24)).isoformat()])
        recent_count = cursor.fetchone()[0]

        # Average latency by tier
        cursor.execute("""
            SELECT selected_tier, AVG(actual_latency_ms)
            FROM query_history
            GROUP BY selected_tier
        """)
        avg_latencies = {tier: latency for tier, latency in cursor.fetchall()}

        # Optimal routing rate
        cursor.execute("SELECT AVG(was_optimal) FROM query_history")
        optimal_rate = cursor.fetchone()[0] or 0.0

        return {
            'total_queries': total_queries,
            'queries_last_24h': recent_count,
            'tier_distribution': tier_counts,
            'avg_latency_by_tier_ms': avg_latencies,
            'optimal_routing_rate_pct': optimal_rate * 100,
            'database_path': self.db_path
        }

    def close(self):
        """Close database connection"""
        if self.conn:
            self.conn.close()
