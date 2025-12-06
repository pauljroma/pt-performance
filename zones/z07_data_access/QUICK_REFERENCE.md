# 4-Tier Router - Quick Reference Card

## One-Line Import
```python
from zones.z07_data_access import TierRouter
```

## Basic Usage
```python
router = TierRouter()
tier, overhead = router.route_query({"days_back": 3})
```

## Query Parameters

| Parameter | Type | Routes To | Example |
|-----------|------|-----------|---------|
| `days_back: 0-7` | int | Master | `{"days_back": 3}` |
| `use_embeddings: True` | bool | PGVector | `{"use_embeddings": True}` |
| `similarity_search: True` | bool | PGVector | `{"similarity_search": True}` |
| `days_back: 7-90` | int | MinIO* | `{"days_back": 30}` |
| `days_back: >90` | int | Athena* | `{"days_back": 120}` |

*Wave 2 only (currently fallback to Master)

## Tier Routing

```python
# Master (Tier 1) - Recent data
router.route_query({"days_back": 3})         # → master

# PGVector (Tier 2) - Semantic search
router.route_query({"use_embeddings": True}) # → pgvector

# MinIO (Tier 3) - Historical [Wave 2]
router.route_query({"days_back": 30})        # → master (fallback)

# Athena (Tier 4) - Archive [Wave 2]
router.route_query({"days_back": 120})       # → master (fallback)
```

## Get Metrics
```python
metrics = router.get_routing_metrics()
# {
#   'total_queries': 100,
#   'routing_percentage': 40.0,
#   'avg_overhead_ms': 0.0018,
#   'tier_distribution': {...}
# }
```

## Feature Flags
```bash
# Disable routing
export TIER_ROUTER_ENABLED=false

# Enable Rust mode (Wave 2)
export TIER_ROUTER_USE_RUST=true
```

## Performance
- Overhead: **0.0018ms** avg
- Throughput: **558K queries/sec**
- Routing: **40%** of queries

## Testing
```bash
# Run all tests
pytest tests/test_tier_router_wave1.py -v

# Run demo
python zones/z07_data_access/demo_routing.py
```

## Configuration
Edit `tier_router_config.yaml`:
```yaml
tier_thresholds:
  master_days: 7    # Tier 1 threshold
  minio_days: 90    # Tier 3 threshold
```

## Support
- Tests: `/tests/test_tier_router_wave1.py`
- Demo: `/zones/z07_data_access/demo_routing.py`
- Docs: `/zones/z07_data_access/README.md`
