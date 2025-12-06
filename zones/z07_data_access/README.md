# 4-Tier Database Router

Zone 7 Data Access Layer - Intelligent query routing across database tiers

## Overview

The 4-tier router automatically routes database queries to the optimal tier based on query characteristics:

- **Tier 1 (Master)**: Recent data (<7 days), high-frequency queries
- **Tier 2 (PGVector)**: Semantic search, embeddings, similarity queries
- **Tier 3 (MinIO)**: Historical data (7-90 days), bulk queries
- **Tier 4 (Athena)**: Archive (>90 days), analytics queries

## Quick Start

```python
from zones.z07_data_access import TierRouter

# Initialize router
router = TierRouter()

# Route a recent query → Master
tier, overhead = router.route_query({"days_back": 3})
print(f"Routed to: {tier.value}")  # Output: master

# Route a semantic search → PGVector
tier, overhead = router.route_query({"use_embeddings": True})
print(f"Routed to: {tier.value}")  # Output: pgvector

# Get metrics
metrics = router.get_routing_metrics()
print(f"Routing percentage: {metrics['routing_percentage']:.1f}%")
```

## Installation

```bash
pip install pyyaml
```

## Configuration

Edit `tier_router_config.yaml` to customize routing behavior:

```yaml
tier_thresholds:
  master_days: 7      # Recent data threshold
  minio_days: 90      # Historical data threshold

routing_rules:
  master:
    enabled: true
  pgvector:
    enabled: true
  minio:
    enabled: false    # Wave 2
  athena:
    enabled: false    # Wave 2
```

## Feature Flags

### TIER_ROUTER_ENABLED
Master kill switch for tier routing.

```bash
# Disable routing (all queries → Master)
export TIER_ROUTER_ENABLED=false
```

### TIER_ROUTER_USE_RUST
Enable Rust primitives for hot path optimization (Wave 2).

```bash
# Enable Rust mode
export TIER_ROUTER_USE_RUST=true
```

## Query Parameters

The router analyzes these query parameters:

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `days_back` | int | How far back to query | `{"days_back": 7}` |
| `use_embeddings` | bool | Use vector embeddings | `{"use_embeddings": True}` |
| `similarity_search` | bool | Similarity search | `{"similarity_search": True}` |

## Routing Logic

```python
# Recent data (< 7 days) → Master
router.route_query({"days_back": 3})  # → Tier 1 (Master)

# Embeddings/Similarity → PGVector
router.route_query({"use_embeddings": True})  # → Tier 2 (PGVector)

# Historical (7-90 days) → MinIO (Wave 2)
router.route_query({"days_back": 30})  # → Tier 3 (MinIO)

# Archive (>90 days) → Athena (Wave 2)
router.route_query({"days_back": 120})  # → Tier 4 (Athena)
```

## Performance

Wave 1 performance characteristics:

- **Routing overhead**: 0.0018ms average (555x better than 1ms requirement)
- **Throughput**: ~558,000 queries/second
- **Memory**: Minimal (stateless routing)

## Testing

Run the comprehensive test suite:

```bash
pytest tests/test_tier_router_wave1.py -v
```

Run the demo:

```bash
python zones/z07_data_access/demo_routing.py
```

## Metrics

Track routing performance:

```python
metrics = router.get_routing_metrics()

print(metrics)
# {
#   'total_queries': 1000,
#   'routing_percentage': 40.0,
#   'avg_overhead_ms': 0.0018,
#   'tier_distribution': {
#     'master': 600,
#     'pgvector': 400,
#     'minio': 0,
#     'athena': 0
#   }
# }
```

## Architecture

```
Query → Analyze → Select Tier → Route
         ↓
    - Embeddings?
    - Days back?
    - Query type?
         ↓
    ┌────┴────┐
    ↓         ↓
  Master   PGVector
```

## Wave 2 Roadmap

- Rust primitives integration (<0.001ms overhead)
- MinIO tier enablement (historical queries)
- Athena tier enablement (analytics queries)
- Advanced query optimization
- Tier health monitoring

## Files

- `tier_router.py` - Main routing engine (183 lines)
- `tier_router_config.yaml` - Configuration (41 lines)
- `demo_routing.py` - Demonstration script
- `README.md` - This file

## Support

For issues or questions:
1. Check test suite: `pytest tests/test_tier_router_wave1.py -v`
2. Run demo: `python zones/z07_data_access/demo_routing.py`
3. Review metrics: `router.get_routing_metrics()`

## License

Internal use - PT Performance Platform
