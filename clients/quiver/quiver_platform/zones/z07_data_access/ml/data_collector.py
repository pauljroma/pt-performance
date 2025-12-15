#!/usr/bin/env python3
"""
ML Data Collector - Production Query Pattern Collection for ML Router Training

Collects query execution traces from distributed tracing to build training dataset
for ML-based tier routing optimization.

Architecture:
- Reads trace data from zones/z13_monitoring/distributed_tracing_config.py
- Extracts query patterns: type, complexity, entity count, data sources
- Captures execution metrics: tier used, latency, success/failure
- Outputs labeled training data for ML model

Integration:
- Hooks into distributed tracing spans
- Simulates realistic query patterns from tool definitions
- No direct database access - uses Zone 7 API patterns

Features:
- Real-time trace data collection
- Batch simulation for initial training data
- Feature extraction from query attributes
- Automatic labeling based on performance

Version: 1.0.0
Date: 2025-12-06
Author: Agent 4 - Data Collection Engineer
Zone: z07_data_access/ml
"""

import json
import logging
import uuid
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Any, Optional
from dataclasses import dataclass, asdict
from collections import defaultdict
import random

# Import distributed tracing (optional - use when available)
# SAP-60 FIX (2025-12-08): Disabled zone violation - z07_data_access cannot import from z13_monitoring
TRACING_AVAILABLE = False
tracer = None
# try:
#     import sys
#     sys.path.append(str(Path(__file__).parent.parent.parent.parent))
#     from zones.z13_monitoring.distributed_tracing_config import tracer
#     TRACING_AVAILABLE = True
# except ImportError:
#     TRACING_AVAILABLE = False
#     tracer = None

logger = logging.getLogger(__name__)


@dataclass
class QueryPattern:
    """Represents a query pattern for ML training"""
    query_id: str
    query_type: str
    entity_type: str  # drug, gene, pathway, etc.
    entity_count: int
    complexity_score: float
    data_sources: List[str]  # master_tables, pgvector, neo4j, parquet
    actual_tier: int  # 1-4
    execution_time_ms: float
    success: bool
    timestamp: str
    features: Dict[str, Any]
    optimal_tier: Optional[int] = None  # Filled by labeler


class MLDataCollector:
    """
    Collects query execution data for ML model training.

    Modes:
    1. Real-time: Reads from distributed tracing logs
    2. Simulation: Generates realistic patterns from tool definitions

    Usage:
        collector = MLDataCollector()

        # Collect from real traces
        real_data = collector.collect_from_traces(days=1)

        # Or simulate training data
        simulated_data = collector.simulate_query_patterns(count=10000)

        # Save to storage
        collector.save_dataset(data, "training_data.json")
    """

    def __init__(self, trace_dir: Optional[Path] = None):
        """
        Initialize data collector.

        Args:
            trace_dir: Directory containing trace files (default: ./traces)
        """
        self.trace_dir = trace_dir or Path("./traces")
        self.trace_dir.mkdir(exist_ok=True)

        # Tool categorization for simulation
        self.tool_tiers = self._define_tool_tiers()
        self.query_types = self._define_query_types()

    def _define_tool_tiers(self) -> Dict[str, int]:
        """Define tier mapping for known tools"""
        return {
            # Tier 1: Master Tables (name resolution, metadata)
            "drug_name_resolver": 1,
            "gene_name_resolver": 1,
            "pathway_resolver": 1,
            "entity_metadata": 1,
            "count_entities": 1,

            # Tier 2: PGVector (embeddings, similarity)
            "vector_neighbors": 2,
            "vector_similarity": 2,
            "vector_antipodal": 2,
            "demeo_drug_rescue": 2,
            "transcriptomic_rescue": 2,
            "drug_lookalikes": 2,
            "query_drug_drug_similarity": 2,
            "query_gene_gene_similarity": 2,
            "fusion_discovery_drug": 2,
            "fusion_discovery_gene": 2,

            # Tier 3: Neo4j (graph traversal)
            "graph_neighbors": 3,
            "graph_path": 3,
            "graph_subgraph": 3,
            "graph_properties": 3,
            "execute_cypher": 3,
            "mechanistic_explainer": 3,
            "causal_inference": 3,

            # Tier 4: Parquet (analytics, bulk)
            "read_parquet_filter": 4,
            "session_analytics": 4,
            "scientist_reports": 4,
            "clinical_trial_intelligence": 4,
            "biomarker_discovery": 4,
        }

    def _define_query_types(self) -> Dict[str, str]:
        """Define query type categorization"""
        return {
            # Name resolution
            "drug_name_resolver": "name_resolution",
            "gene_name_resolver": "name_resolution",
            "pathway_resolver": "name_resolution",

            # Metadata lookup
            "entity_metadata": "metadata_lookup",
            "drug_properties_detail": "metadata_lookup",
            "count_entities": "metadata_lookup",

            # Embedding similarity
            "vector_neighbors": "embedding_similarity",
            "vector_similarity": "embedding_similarity",
            "demeo_drug_rescue": "embedding_similarity",
            "transcriptomic_rescue": "embedding_similarity",
            "drug_lookalikes": "embedding_similarity",

            # Graph traversal
            "graph_neighbors": "graph_traversal",
            "graph_path": "graph_path",
            "graph_subgraph": "graph_traversal",
            "mechanistic_explainer": "graph_traversal",

            # Analytical
            "session_analytics": "analytical",
            "biomarker_discovery": "analytical",
            "clinical_trial_intelligence": "analytical",
        }

    def collect_from_traces(self, days: int = 1) -> List[QueryPattern]:
        """
        Collect query patterns from distributed tracing logs.

        Args:
            days: Number of days of traces to analyze

        Returns:
            List of query patterns extracted from traces
        """
        patterns = []

        # Read trace files
        for i in range(days):
            date_str = (datetime.now()).strftime("%Y%m%d")
            trace_file = self.trace_dir / f"trace_{date_str}.jsonl"

            if not trace_file.exists():
                logger.warning(f"Trace file not found: {trace_file}")
                continue

            # Parse trace file
            with open(trace_file, "r") as f:
                for line in f:
                    try:
                        span = json.loads(line)
                        pattern = self._extract_pattern_from_span(span)
                        if pattern:
                            patterns.append(pattern)
                    except json.JSONDecodeError:
                        logger.warning(f"Failed to parse trace line: {line[:50]}")
                        continue

        logger.info(f"Collected {len(patterns)} patterns from traces")
        return patterns

    def _extract_pattern_from_span(self, span: Dict[str, Any]) -> Optional[QueryPattern]:
        """
        Extract query pattern from a trace span.

        Args:
            span: Trace span data

        Returns:
            QueryPattern if span contains relevant data, None otherwise
        """
        # Only process tool spans
        if span.get("span_type") != "tool":
            return None

        attributes = span.get("attributes", {})
        tool_name = attributes.get("tool_name", "unknown")

        # Extract features
        entity_count = self._estimate_entity_count(attributes)
        data_sources = self._infer_data_sources(tool_name, attributes)
        actual_tier = attributes.get("tier") or self._infer_tier(tool_name)

        # Calculate complexity score
        complexity = self._calculate_complexity(
            tool_name=tool_name,
            entity_count=entity_count,
            data_sources=data_sources,
        )

        # Build features dictionary
        features = {
            "tool_name": tool_name,
            "param_count": attributes.get("param_count", 0),
            "result_size": attributes.get("result_size", 0),
            "has_embedding": "vector" in tool_name or "similarity" in tool_name,
            "has_graph": "graph" in tool_name or "neo4j" in tool_name.lower(),
            "is_bulk": "parquet" in tool_name or "analytics" in tool_name,
            "category": attributes.get("category", "general"),
        }

        return QueryPattern(
            query_id=span.get("span_id", str(uuid.uuid4())),
            query_type=self.query_types.get(tool_name, "unknown"),
            entity_type=self._infer_entity_type(tool_name),
            entity_count=entity_count,
            complexity_score=complexity,
            data_sources=data_sources,
            actual_tier=int(actual_tier) if actual_tier else 2,
            execution_time_ms=span.get("duration_ms", 0),
            success=span.get("status") == "ok",
            timestamp=span.get("timestamp", datetime.now().isoformat()),
            features=features,
        )

    def _estimate_entity_count(self, attributes: Dict[str, Any]) -> int:
        """Estimate entity count from attributes"""
        result_size = attributes.get("result_size", 0)
        param_count = attributes.get("param_count", 0)

        # Heuristic: result_size is often the entity count
        if result_size > 0:
            return min(result_size, 1000)  # Cap at 1000

        # Otherwise use param count as proxy
        return max(param_count, 1)

    def _infer_data_sources(self, tool_name: str, attributes: Dict[str, Any]) -> List[str]:
        """Infer data sources used by tool"""
        sources = []

        # Master tables
        if any(x in tool_name for x in ["resolver", "metadata", "count"]):
            sources.append("master_tables")

        # PGVector
        if any(x in tool_name for x in ["vector", "similarity", "rescue", "lookalike", "fusion"]):
            sources.append("pgvector")

        # Neo4j
        if any(x in tool_name for x in ["graph", "cypher", "mechanistic", "causal"]):
            sources.append("neo4j")

        # Parquet
        if any(x in tool_name for x in ["parquet", "analytics", "report", "biomarker", "clinical"]):
            sources.append("parquet")

        return sources if sources else ["unknown"]

    def _infer_tier(self, tool_name: str) -> int:
        """Infer tier from tool name"""
        return self.tool_tiers.get(tool_name, 2)  # Default to Tier 2

    def _infer_entity_type(self, tool_name: str) -> str:
        """Infer entity type from tool name"""
        if "drug" in tool_name:
            return "drug"
        elif "gene" in tool_name:
            return "gene"
        elif "pathway" in tool_name:
            return "pathway"
        else:
            return "general"

    def _calculate_complexity(
        self,
        tool_name: str,
        entity_count: int,
        data_sources: List[str],
    ) -> float:
        """
        Calculate query complexity score (0.0-1.0).

        Factors:
        - Entity count: More entities = more complex
        - Data sources: More sources = more complex
        - Tool type: Graph/analytical queries more complex

        Returns:
            Complexity score between 0.0 and 1.0
        """
        score = 0.0

        # Entity count factor (0.0-0.3)
        if entity_count <= 1:
            score += 0.0
        elif entity_count <= 10:
            score += 0.1
        elif entity_count <= 50:
            score += 0.2
        else:
            score += 0.3

        # Data source factor (0.0-0.3)
        score += len(data_sources) * 0.1

        # Tool type factor (0.0-0.4)
        if "graph" in tool_name or "cypher" in tool_name:
            score += 0.4  # Graph queries are complex
        elif "analytics" in tool_name or "report" in tool_name:
            score += 0.3  # Analytical queries moderately complex
        elif "vector" in tool_name or "similarity" in tool_name:
            score += 0.2  # Embedding queries somewhat complex
        else:
            score += 0.1  # Simple lookups

        return min(score, 1.0)

    def simulate_query_patterns(self, count: int = 10000) -> List[QueryPattern]:
        """
        Simulate realistic query patterns for training data.

        Generates query patterns based on tool definitions and realistic
        performance characteristics.

        Args:
            count: Number of patterns to generate

        Returns:
            List of simulated query patterns
        """
        patterns = []

        # Distribution of query types (based on typical workload)
        tier_distribution = {
            1: 0.40,  # 40% name resolution (Tier 1)
            2: 0.35,  # 35% embeddings (Tier 2)
            3: 0.15,  # 15% graph (Tier 3)
            4: 0.10,  # 10% analytics (Tier 4)
        }

        for i in range(count):
            # Select tier based on distribution
            tier = random.choices(
                population=list(tier_distribution.keys()),
                weights=list(tier_distribution.values()),
            )[0]

            # Generate pattern for selected tier
            pattern = self._simulate_pattern_for_tier(tier)
            patterns.append(pattern)

            if (i + 1) % 1000 == 0:
                logger.info(f"Generated {i + 1}/{count} patterns")

        logger.info(f"Simulated {len(patterns)} query patterns")
        return patterns

    def _simulate_pattern_for_tier(self, tier: int) -> QueryPattern:
        """Simulate a query pattern for a specific tier"""

        # Select tool for tier
        tier_tools = [tool for tool, t in self.tool_tiers.items() if t == tier]
        tool_name = random.choice(tier_tools) if tier_tools else f"tier_{tier}_tool"

        # Determine entity type
        if "drug" in tool_name:
            entity_type = "drug"
        elif "gene" in tool_name:
            entity_type = "gene"
        elif "pathway" in tool_name:
            entity_type = "pathway"
        else:
            entity_type = random.choice(["drug", "gene", "pathway"])

        # Generate realistic entity count
        if tier == 1:
            entity_count = random.randint(1, 5)  # Simple lookups
        elif tier == 2:
            entity_count = random.randint(5, 50)  # Similarity searches
        elif tier == 3:
            entity_count = random.randint(10, 100)  # Graph traversal
        else:
            entity_count = random.randint(50, 500)  # Bulk analytics

        # Determine data sources
        data_sources = self._infer_data_sources(tool_name, {})

        # Calculate complexity
        complexity = self._calculate_complexity(tool_name, entity_count, data_sources)

        # Generate realistic execution time based on tier
        execution_time = self._simulate_execution_time(tier, entity_count, complexity)

        # Success rate varies by tier (higher tier = slightly lower success)
        success_rate = {1: 0.99, 2: 0.98, 3: 0.95, 4: 0.92}
        success = random.random() < success_rate.get(tier, 0.95)

        # Build features
        features = {
            "tool_name": tool_name,
            "param_count": random.randint(1, 5),
            "result_size": entity_count,
            "has_embedding": tier == 2,
            "has_graph": tier == 3,
            "is_bulk": tier == 4,
            "category": self._infer_category(tier),
        }

        return QueryPattern(
            query_id=str(uuid.uuid4()),
            query_type=self.query_types.get(tool_name, "unknown"),
            entity_type=entity_type,
            entity_count=entity_count,
            complexity_score=complexity,
            data_sources=data_sources,
            actual_tier=tier,
            execution_time_ms=execution_time,
            success=success,
            timestamp=datetime.now().isoformat(),
            features=features,
        )

    def _simulate_execution_time(self, tier: int, entity_count: int, complexity: float) -> float:
        """
        Simulate realistic execution time based on tier and complexity.

        Tier 1 (Master Tables): <2ms
        Tier 2 (PGVector): 5-50ms
        Tier 3 (Neo4j): 50-500ms
        Tier 4 (Parquet): 100-5000ms
        """
        base_times = {
            1: (0.5, 2.0),      # Tier 1: 0.5-2ms
            2: (5.0, 50.0),     # Tier 2: 5-50ms
            3: (50.0, 500.0),   # Tier 3: 50-500ms
            4: (100.0, 5000.0), # Tier 4: 100-5000ms
        }

        min_time, max_time = base_times.get(tier, (10.0, 100.0))

        # Add variance based on entity count and complexity
        variance_factor = 1 + (entity_count / 100) * complexity
        base_time = random.uniform(min_time, max_time)

        return round(base_time * variance_factor, 3)

    def _infer_category(self, tier: int) -> str:
        """Infer category from tier"""
        categories = {
            1: "lookup",
            2: "vector",
            3: "graph",
            4: "analytics",
        }
        return categories.get(tier, "general")

    def save_dataset(self, patterns: List[QueryPattern], filename: str):
        """
        Save query patterns to JSON file.

        Args:
            patterns: List of query patterns
            filename: Output filename
        """
        output_path = Path(__file__).parent / "data" / filename
        output_path.parent.mkdir(exist_ok=True)

        # Convert to dictionaries
        data = [asdict(pattern) for pattern in patterns]

        with open(output_path, "w") as f:
            json.dump(data, f, indent=2)

        logger.info(f"Saved {len(patterns)} patterns to {output_path}")

    def get_collection_stats(self, patterns: List[QueryPattern]) -> Dict[str, Any]:
        """
        Get statistics about collected patterns.

        Args:
            patterns: List of query patterns

        Returns:
            Statistics dictionary
        """
        if not patterns:
            return {"error": "No patterns to analyze"}

        # Count by tier
        tier_counts = defaultdict(int)
        tier_latencies = defaultdict(list)
        query_type_counts = defaultdict(int)
        entity_type_counts = defaultdict(int)

        for pattern in patterns:
            tier_counts[pattern.actual_tier] += 1
            tier_latencies[pattern.actual_tier].append(pattern.execution_time_ms)
            query_type_counts[pattern.query_type] += 1
            entity_type_counts[pattern.entity_type] += 1

        # Calculate average latencies
        avg_latencies = {
            tier: sum(latencies) / len(latencies)
            for tier, latencies in tier_latencies.items()
        }

        return {
            "total_patterns": len(patterns),
            "tier_distribution": dict(tier_counts),
            "query_type_distribution": dict(query_type_counts),
            "entity_type_distribution": dict(entity_type_counts),
            "average_latency_by_tier": avg_latencies,
            "success_rate": sum(1 for p in patterns if p.success) / len(patterns),
        }


# ============================================================================
# CLI Interface
# ============================================================================

if __name__ == "__main__":
    import argparse

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )

    parser = argparse.ArgumentParser(description="ML Data Collector for Tier Router")
    parser.add_argument(
        "--mode",
        choices=["collect", "simulate"],
        default="simulate",
        help="Collection mode: collect from traces or simulate patterns"
    )
    parser.add_argument(
        "--count",
        type=int,
        default=1000,
        help="Number of patterns to generate (simulate mode)"
    )
    parser.add_argument(
        "--output",
        type=str,
        default="training_data.json",
        help="Output filename"
    )

    args = parser.parse_args()

    collector = MLDataCollector()

    if args.mode == "collect":
        patterns = collector.collect_from_traces(days=1)
    else:
        patterns = collector.simulate_query_patterns(count=args.count)

    # Save dataset
    collector.save_dataset(patterns, args.output)

    # Print statistics
    stats = collector.get_collection_stats(patterns)
    print("\n" + "=" * 60)
    print("DATA COLLECTION STATISTICS")
    print("=" * 60)
    print(json.dumps(stats, indent=2))
