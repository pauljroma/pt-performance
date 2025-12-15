#!/usr/bin/env python3
"""
ML Data Labeler - Automatic Optimal Tier Labeling for ML Training

Analyzes query patterns and execution metrics to automatically label each query
with its optimal tier based on performance characteristics.

Labeling Rules:
- Tier 1 (Master Tables): <2ms, name resolution, metadata lookup
- Tier 2 (PGVector): 5-50ms, embedding similarity, vector operations
- Tier 3 (Neo4j): 50-500ms, graph traversal, relationship queries
- Tier 4 (Parquet): 100-5000ms, analytics, bulk data access

The labeler considers:
1. Actual execution time
2. Query type and complexity
3. Data sources required
4. Success rate
5. Entity count

Version: 1.0.0
Date: 2025-12-06
Author: Agent 4 - Data Collection Engineer
Zone: z07_data_access/ml
"""

import json
import logging
from pathlib import Path
from typing import Dict, List, Any, Optional
from dataclasses import dataclass
from collections import defaultdict

logger = logging.getLogger(__name__)


@dataclass
class TierCharacteristics:
    """Performance characteristics for each tier"""
    tier: int
    name: str
    latency_range: tuple  # (min_ms, max_ms)
    typical_latency: float  # p50 latency in ms
    query_types: List[str]
    data_sources: List[str]


class MLDataLabeler:
    """
    Automatically labels query patterns with optimal tier.

    Uses performance-based heuristics and query characteristics to determine
    the best tier for each query pattern.

    Usage:
        labeler = MLDataLabeler()

        # Load unlabeled data
        patterns = labeler.load_patterns("training_data.json")

        # Label with optimal tier
        labeled = labeler.label_patterns(patterns)

        # Save labeled data
        labeler.save_labeled_data(labeled, "labeled_training_data.json")

        # Convert to Parquet for ML training
        labeler.save_as_parquet(labeled, "training_sample.parquet")
    """

    def __init__(self):
        """Initialize data labeler with tier characteristics"""
        self.tier_specs = self._define_tier_characteristics()

    def _define_tier_characteristics(self) -> Dict[int, TierCharacteristics]:
        """Define performance characteristics for each tier"""
        return {
            1: TierCharacteristics(
                tier=1,
                name="Master Tables (Rust)",
                latency_range=(0.1, 2.0),
                typical_latency=0.8,
                query_types=["name_resolution", "metadata_lookup", "id_mapping"],
                data_sources=["master_tables"],
            ),
            2: TierCharacteristics(
                tier=2,
                name="PGVector",
                latency_range=(5.0, 50.0),
                typical_latency=20.0,
                query_types=["embedding_similarity", "vector_neighbors"],
                data_sources=["pgvector"],
            ),
            3: TierCharacteristics(
                tier=3,
                name="Neo4j",
                latency_range=(50.0, 500.0),
                typical_latency=150.0,
                query_types=["graph_traversal", "graph_path"],
                data_sources=["neo4j"],
            ),
            4: TierCharacteristics(
                tier=4,
                name="Parquet (Athena/MinIO)",
                latency_range=(100.0, 5000.0),
                typical_latency=500.0,
                query_types=["analytical", "bulk_export"],
                data_sources=["parquet", "athena", "minio"],
            ),
        }

    def load_patterns(self, filename: str) -> List[Dict[str, Any]]:
        """
        Load query patterns from JSON file.

        Args:
            filename: Input filename

        Returns:
            List of query pattern dictionaries
        """
        input_path = Path(__file__).parent / "data" / filename

        if not input_path.exists():
            raise FileNotFoundError(f"Data file not found: {input_path}")

        with open(input_path, "r") as f:
            patterns = json.load(f)

        logger.info(f"Loaded {len(patterns)} patterns from {input_path}")
        return patterns

    def label_patterns(self, patterns: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        Label each pattern with optimal tier.

        Args:
            patterns: List of unlabeled query patterns

        Returns:
            List of labeled query patterns
        """
        labeled_patterns = []

        for pattern in patterns:
            optimal_tier = self._determine_optimal_tier(pattern)
            pattern["optimal_tier"] = optimal_tier

            # Add labeling metadata
            pattern["label_metadata"] = {
                "labeling_method": "automatic",
                "tier_name": self.tier_specs[optimal_tier].name,
                "is_correctly_routed": pattern["actual_tier"] == optimal_tier,
            }

            labeled_patterns.append(pattern)

        # Calculate labeling statistics
        stats = self._calculate_labeling_stats(labeled_patterns)
        logger.info(f"Labeled {len(labeled_patterns)} patterns")
        logger.info(f"Routing accuracy: {stats['routing_accuracy']:.1%}")

        return labeled_patterns

    def _determine_optimal_tier(self, pattern: Dict[str, Any]) -> int:
        """
        Determine optimal tier for a query pattern.

        Uses multi-factor analysis:
        1. Query type match (primary)
        2. Execution time fit (secondary)
        3. Data source requirements (tertiary)
        4. Complexity score (quaternary)

        Args:
            pattern: Query pattern dictionary

        Returns:
            Optimal tier (1-4)
        """
        query_type = pattern.get("query_type", "unknown")
        execution_time = pattern.get("execution_time_ms", 100.0)
        data_sources = pattern.get("data_sources", [])
        complexity = pattern.get("complexity_score", 0.5)
        success = pattern.get("success", True)

        # Score each tier
        tier_scores = {}

        for tier, specs in self.tier_specs.items():
            score = 0.0

            # Factor 1: Query type match (40% weight)
            if query_type in specs.query_types:
                score += 0.4

            # Factor 2: Execution time fit (30% weight)
            min_latency, max_latency = specs.latency_range
            if min_latency <= execution_time <= max_latency:
                # Perfect fit
                score += 0.3
            else:
                # Penalize based on distance from range
                if execution_time < min_latency:
                    # Too fast for this tier
                    distance = (min_latency - execution_time) / min_latency
                    score += max(0.3 - distance * 0.3, 0)
                else:
                    # Too slow for this tier
                    distance = (execution_time - max_latency) / max_latency
                    score += max(0.3 - distance * 0.1, 0)

            # Factor 3: Data source match (20% weight)
            matching_sources = set(data_sources) & set(specs.data_sources)
            if matching_sources:
                score += 0.2 * (len(matching_sources) / len(specs.data_sources))

            # Factor 4: Complexity fit (10% weight)
            # Higher complexity → higher tier
            expected_complexity_for_tier = (tier - 1) / 3  # 0, 0.33, 0.67, 1.0
            complexity_diff = abs(complexity - expected_complexity_for_tier)
            score += max(0.1 - complexity_diff * 0.1, 0)

            tier_scores[tier] = score

        # Select tier with highest score
        optimal_tier = max(tier_scores.items(), key=lambda x: x[1])[0]

        # Special cases: Override based on strong signals

        # If query type is name_resolution, always use Tier 1
        if query_type == "name_resolution":
            return 1

        # If execution time is <2ms and success, likely Tier 1
        if execution_time < 2.0 and success:
            return 1

        # If data_sources only contains master_tables, use Tier 1
        if data_sources == ["master_tables"]:
            return 1

        # If execution time is >1000ms, likely Tier 4
        if execution_time > 1000.0:
            return 4

        # If query type is graph_traversal or graph_path, use Tier 3
        if query_type in ["graph_traversal", "graph_path"]:
            return 3

        # If data_sources contains neo4j, use Tier 3
        if "neo4j" in data_sources:
            return 3

        return optimal_tier

    def _calculate_labeling_stats(self, patterns: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Calculate statistics about labeled data.

        Args:
            patterns: List of labeled patterns

        Returns:
            Statistics dictionary
        """
        total = len(patterns)
        correctly_routed = sum(
            1 for p in patterns
            if p["actual_tier"] == p["optimal_tier"]
        )

        # Distribution by optimal tier
        optimal_tier_dist = defaultdict(int)
        actual_tier_dist = defaultdict(int)
        misrouting_matrix = defaultdict(lambda: defaultdict(int))

        for pattern in patterns:
            optimal_tier_dist[pattern["optimal_tier"]] += 1
            actual_tier_dist[pattern["actual_tier"]] += 1

            # Track misroutings
            if pattern["actual_tier"] != pattern["optimal_tier"]:
                misrouting_matrix[pattern["actual_tier"]][pattern["optimal_tier"]] += 1

        # Calculate average latency by tier
        tier_latencies = defaultdict(list)
        for pattern in patterns:
            tier_latencies[pattern["optimal_tier"]].append(pattern["execution_time_ms"])

        avg_latencies = {
            tier: sum(latencies) / len(latencies)
            for tier, latencies in tier_latencies.items()
        }

        return {
            "total_patterns": total,
            "correctly_routed": correctly_routed,
            "routing_accuracy": correctly_routed / total if total > 0 else 0,
            "optimal_tier_distribution": dict(optimal_tier_dist),
            "actual_tier_distribution": dict(actual_tier_dist),
            "misrouting_matrix": {
                actual: dict(optimal)
                for actual, optimal in misrouting_matrix.items()
            },
            "average_latency_by_optimal_tier": avg_latencies,
        }

    def save_labeled_data(self, patterns: List[Dict[str, Any]], filename: str):
        """
        Save labeled patterns to JSON file.

        Args:
            patterns: List of labeled patterns
            filename: Output filename
        """
        output_path = Path(__file__).parent / "data" / filename
        output_path.parent.mkdir(exist_ok=True)

        with open(output_path, "w") as f:
            json.dump(patterns, f, indent=2)

        logger.info(f"Saved {len(patterns)} labeled patterns to {output_path}")

    def save_as_parquet(self, patterns: List[Dict[str, Any]], filename: str):
        """
        Save labeled patterns as Parquet file for efficient ML training.

        Schema:
        - query_id: string
        - query_type: string
        - entity_type: string
        - entity_count: int
        - complexity_score: float
        - data_sources: string (JSON array)
        - features: string (JSON object)
        - actual_tier: int
        - optimal_tier: int (label)
        - execution_time_ms: float
        - success: bool
        - timestamp: string

        Args:
            patterns: List of labeled patterns
            filename: Output filename (.parquet)
        """
        try:
            import pandas as pd
            import pyarrow as pa
            import pyarrow.parquet as pq
        except ImportError:
            logger.error("pandas and pyarrow are required for Parquet export")
            logger.info("Install with: pip install pandas pyarrow")
            return

        output_path = Path(__file__).parent / "data" / filename
        output_path.parent.mkdir(exist_ok=True)

        # Convert to DataFrame
        df_data = []
        for pattern in patterns:
            row = {
                "query_id": pattern["query_id"],
                "query_type": pattern["query_type"],
                "entity_type": pattern["entity_type"],
                "entity_count": pattern["entity_count"],
                "complexity_score": pattern["complexity_score"],
                "data_sources": json.dumps(pattern["data_sources"]),
                "features": json.dumps(pattern["features"]),
                "actual_tier": pattern["actual_tier"],
                "optimal_tier": pattern["optimal_tier"],
                "execution_time_ms": pattern["execution_time_ms"],
                "success": pattern["success"],
                "timestamp": pattern["timestamp"],
            }
            df_data.append(row)

        df = pd.DataFrame(df_data)

        # Write to Parquet
        table = pa.Table.from_pandas(df)
        pq.write_table(table, output_path)

        logger.info(f"Saved {len(patterns)} patterns to Parquet: {output_path}")
        logger.info(f"File size: {output_path.stat().st_size / 1024:.1f} KB")

    def analyze_misroutings(self, patterns: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Analyze patterns that were misrouted to wrong tier.

        Args:
            patterns: List of labeled patterns

        Returns:
            Misrouting analysis
        """
        misrouted = [
            p for p in patterns
            if p["actual_tier"] != p["optimal_tier"]
        ]

        if not misrouted:
            return {"message": "No misroutings found - perfect routing!"}

        # Analyze common misrouting patterns
        analysis = {
            "total_misrouted": len(misrouted),
            "misrouting_rate": len(misrouted) / len(patterns),
            "common_misroutings": defaultdict(int),
            "impact_analysis": {},
        }

        # Count misrouting patterns
        for pattern in misrouted:
            key = f"Tier {pattern['actual_tier']} → Tier {pattern['optimal_tier']}"
            analysis["common_misroutings"][key] += 1

        # Calculate impact (wasted latency)
        tier_latencies = {
            spec.tier: spec.typical_latency
            for spec in self.tier_specs.values()
        }

        total_wasted_ms = 0
        for pattern in misrouted:
            actual_latency = tier_latencies.get(pattern["actual_tier"], 0)
            optimal_latency = tier_latencies.get(pattern["optimal_tier"], 0)
            wasted_ms = max(actual_latency - optimal_latency, 0)
            total_wasted_ms += wasted_ms

        analysis["impact_analysis"] = {
            "total_wasted_latency_ms": total_wasted_ms,
            "avg_wasted_latency_per_query_ms": total_wasted_ms / len(misrouted),
        }

        return dict(analysis)


# ============================================================================
# CLI Interface
# ============================================================================

if __name__ == "__main__":
    import argparse

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )

    parser = argparse.ArgumentParser(description="ML Data Labeler for Tier Router")
    parser.add_argument(
        "--input",
        type=str,
        default="training_data.json",
        help="Input filename (unlabeled data)"
    )
    parser.add_argument(
        "--output-json",
        type=str,
        default="labeled_training_data.json",
        help="Output filename for labeled JSON data"
    )
    parser.add_argument(
        "--output-parquet",
        type=str,
        default="training_sample.parquet",
        help="Output filename for Parquet data"
    )

    args = parser.parse_args()

    labeler = MLDataLabeler()

    # Load patterns
    patterns = labeler.load_patterns(args.input)

    # Label patterns
    labeled = labeler.label_patterns(patterns)

    # Save labeled data
    labeler.save_labeled_data(labeled, args.output_json)
    labeler.save_as_parquet(labeled, args.output_parquet)

    # Analyze misroutings
    misrouting_analysis = labeler.analyze_misroutings(labeled)

    print("\n" + "=" * 60)
    print("LABELING RESULTS")
    print("=" * 60)

    stats = labeler._calculate_labeling_stats(labeled)
    print(json.dumps(stats, indent=2))

    print("\n" + "=" * 60)
    print("MISROUTING ANALYSIS")
    print("=" * 60)
    print(json.dumps(misrouting_analysis, indent=2))
