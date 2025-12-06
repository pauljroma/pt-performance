# Wave 2 Tier Enablement - Operational Runbook

**Version:** 1.0
**Last Updated:** 2025-12-06
**Owner:** Agent 10 - Tier Integration Engineer

## Quick Reference

### System Status Check

```python
from zones.z07_data_access.tier_router import TierRouter
from zones.z07_data_access.tier_health_monitor import TierHealthMonitor

# Initialize and check
router = TierRouter()
metrics = router.get_routing_metrics()

print(f"Routing: {metrics['routing_percentage']:.1f}%")
print(f"Tiers: {metrics['tier_distribution']}")
print(f"Overhead: {metrics['avg_overhead_ms']:.4f}ms")
```

### Expected Metrics

- **Routing Percentage:** ≥50% (target), ~60% (typical)
- **Routing Overhead:** <1ms (requirement), ~0.002ms (typical)
- **Tier Distribution:** Master 40%, PGVector 20%, MinIO 20%, Athena 20%

## Component Overview

### File Locations

```
/clients/linear-bootstrap/zones/z07_data_access/
├── tier_router.py                    # Main router (enhanced Wave 2)
├── tier_router_config.yaml           # Configuration (4 tiers enabled)
├── tier3_minio_integration.py        # MinIO integration
├── tier4_athena_integration.py       # Athena integration
└── tier_health_monitor.py            # Health monitoring

/clients/linear-bootstrap/tests/
├── test_tier_router_wave1.py         # Wave 1 tests (19 tests)
└── test_tier_enablement_wave2.py     # Wave 2 tests (29 tests)
```

### Dependencies

```bash
# Core dependencies
pip install pyyaml              # Configuration parsing

# Optional (for production)
pip install minio               # MinIO client
pip install boto3               # AWS Athena client
```

## Common Operations

### 1. Start System with All Tiers

```python
#!/usr/bin/env python3
from zones.z07_data_access.tier_router import TierRouter
from zones.z07_data_access.tier3_minio_integration import MinIOTier
from zones.z07_data_access.tier4_athena_integration import AthenaTier
from zones.z07_data_access.tier_health_monitor import TierHealthMonitor

# Initialize tier clients
minio = MinIOTier(
    endpoint="minio.example.com:9000",
    bucket="pt-historical"
)
athena = AthenaTier(
    region="us-east-1",
    database="pt_analytics"
)

# Initialize health monitor
monitor = TierHealthMonitor(check_interval_seconds=30)
monitor.register_tier("minio", minio)
monitor.register_tier("athena", athena)

# Start background monitoring
monitor.start_monitoring()

# Initialize router
router = TierRouter(health_monitor=monitor)

print("✅ System started - all 4 tiers active")
print(f"Health: {monitor.get_health_summary()}")
```

### 2. Route Queries

```python
# Recent query → Master
tier, overhead = router.route_query({"days_back": 3})
print(f"Recent: {tier.value}")  # master

# Semantic search → PGVector
tier, overhead = router.route_query({"use_embeddings": True})
print(f"Semantic: {tier.value}")  # pgvector

# Historical → MinIO
tier, overhead = router.route_query({"days_back": 30})
print(f"Historical: {tier.value}")  # minio

# Analytics → Athena
tier, overhead = router.route_query({"days_back": 120})
print(f"Analytics: {tier.value}")  # athena
```

### 3. Monitor Performance

```python
# Get routing metrics
metrics = router.get_routing_metrics()

print(f"Total queries: {metrics['total_queries']}")
print(f"Routing %: {metrics['routing_percentage']:.1f}%")
print(f"Avg overhead: {metrics['avg_overhead_ms']:.4f}ms")
print(f"Failovers: {metrics['failover_count']}")

# Tier distribution
for tier, count in metrics['tier_distribution'].items():
    pct = metrics['tier_distribution_pct'][tier]
    print(f"  {tier}: {count} queries ({pct:.1f}%)")
```

### 4. Check Health Status

```python
# Overall health
health = monitor.get_health_summary()
print(f"Status: {health['overall_status']}")
print(f"Available: {health['available_count']}/{health['total_tiers']}")

# Per-tier health
for tier, status in health['tier_health'].items():
    print(f"{tier}: {status['status']} ({status['latency_ms']:.2f}ms)")

# Get uptime stats
stats = monitor.get_stats()
print(f"Uptime: {stats['uptime_percentage']}")
```

### 5. Query Historical Data (MinIO)

```python
from zones.z07_data_access.tier3_minio_integration import MinIOTier

minio = MinIOTier()

# Query historical sessions
result = minio.query(
    filter_criteria={"table": "sessions"},
    days_back=30,
    limit=100
)

print(f"Rows: {result.row_count}")
print(f"Query time: {result.query_time_ms:.2f}ms")
print(f"Cached: {result.cached}")

# Get stats
stats = minio.get_stats()
print(f"Cache hit rate: {stats['cache_hit_rate_pct']:.1f}%")
print(f"Avg query time: {stats['avg_query_time_ms']:.2f}ms")
```

### 6. Execute Analytics (Athena)

```python
from zones.z07_data_access.tier4_athena_integration import AthenaTier

athena = AthenaTier()

# Execute analytics query
result = athena.execute_analytics_query(
    sql="SELECT COUNT(*) as total FROM sessions WHERE created_at > '2024-01-01'"
)

print(f"Rows: {result.row_count}")
print(f"Query ID: {result.query_id}")
print(f"Data scanned: {result.data_scanned_bytes / 1024**2:.2f} MB")

# Get stats
stats = athena.get_stats()
print(f"Total queries: {stats['total_queries']}")
print(f"Success rate: {stats['success_rate_pct']:.1f}%")
print(f"Estimated cost: ${stats['estimated_cost_usd']:.4f}")
```

## Troubleshooting

### Issue: Routing percentage below 50%

**Symptoms:**
- `metrics['routing_percentage'] < 50%`
- Most queries going to Master

**Diagnosis:**
```python
# Check tier enablement
router = TierRouter()
config = router.config['routing_rules']

for tier, rules in config.items():
    print(f"{tier}: enabled={rules['enabled']}")
```

**Resolution:**
1. Verify `tier_router_config.yaml` has all tiers enabled
2. Check feature flags: `ENABLE_TIER3=true`, `ENABLE_TIER4=true`
3. Restart application to reload configuration

### Issue: Tier unavailable / failing health checks

**Symptoms:**
- Health check shows tier as "unavailable"
- Failover count increasing
- Queries routing to fallback tiers

**Diagnosis:**
```python
# Check specific tier health
monitor = TierHealthMonitor()
# ... register tiers ...
snapshot = monitor.check_all_tiers()

for tier_name, health in snapshot.tiers.items():
    if not health.available:
        print(f"{tier_name} UNAVAILABLE:")
        print(f"  Error: {health.error}")
        print(f"  Consecutive failures: {health.consecutive_failures}")
        print(f"  Latency: {health.latency_ms}ms")
```

**Resolution:**

For MinIO:
1. Check MinIO service is running: `curl http://minio.example.com:9000`
2. Verify credentials: `MINIO_ENDPOINT`, `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`
3. Check bucket exists: `mc ls myminio/pt-historical`

For Athena:
1. Check AWS credentials: `aws sts get-caller-identity`
2. Verify Athena permissions: `aws athena list-work-groups`
3. Check S3 output bucket: `aws s3 ls s3://pt-athena-results/`

### Issue: High routing overhead (>1ms)

**Symptoms:**
- `metrics['avg_overhead_ms'] > 1.0`
- Slow query routing

**Diagnosis:**
```python
# Measure routing overhead
import time

router = TierRouter()
overheads = []

for _ in range(100):
    start = time.perf_counter()
    router.route_query({"days_back": 3})
    overhead = (time.perf_counter() - start) * 1000
    overheads.append(overhead)

print(f"Min: {min(overheads):.4f}ms")
print(f"Max: {max(overheads):.4f}ms")
print(f"Avg: {sum(overheads)/len(overheads):.4f}ms")
```

**Resolution:**
1. Disable health monitoring if not needed: `router = TierRouter(health_monitor=None)`
2. Use background health checks instead of inline: `monitor.start_monitoring()`
3. Increase health check interval: `TierHealthMonitor(check_interval_seconds=60)`
4. Profile for bottlenecks: Check I/O, network calls in health checks

### Issue: Failover not working

**Symptoms:**
- Tier is down but queries still trying to route there
- Errors instead of automatic failover

**Diagnosis:**
```python
# Verify health monitor is attached
router = TierRouter()
print(f"Health monitor: {router.health_monitor}")

# Check if tier is marked as unavailable
if router.health_monitor:
    is_available = router.health_monitor.is_tier_available("minio")
    print(f"MinIO available: {is_available}")
```

**Resolution:**
1. Ensure health monitor is passed to router: `TierRouter(health_monitor=monitor)`
2. Register all tier clients with monitor: `monitor.register_tier(name, client)`
3. Check tier has `health_check()` method implemented
4. Verify failover chains in `_find_healthy_fallback()`

### Issue: Tests failing

**Symptoms:**
- `pytest` shows failures
- New code breaks existing tests

**Diagnosis:**
```bash
# Run specific test file
python3 -m pytest tests/test_tier_enablement_wave2.py -v

# Run specific test
python3 -m pytest tests/test_tier_enablement_wave2.py::TestMinIOIntegration::test_minio_initialization -v

# Show full output
python3 -m pytest tests/test_tier_enablement_wave2.py -v -s
```

**Resolution:**
1. Check imports: Ensure modules are in PYTHONPATH
2. Verify configuration: `tier_router_config.yaml` must have tiers enabled
3. Check dependencies: `pip install -r requirements.txt`
4. Clear cache: `rm -rf .pytest_cache __pycache__`

## Configuration Reference

### Environment Variables

```bash
# Router control
export TIER_ROUTER_ENABLED=true          # Enable/disable routing
export TIER_ROUTER_USE_RUST=false        # Rust mode (future)

# Tier enablement
export ENABLE_TIER3=true                 # MinIO tier
export ENABLE_TIER4=true                 # Athena tier

# MinIO configuration
export MINIO_ENDPOINT=localhost:9000
export MINIO_ACCESS_KEY=minioadmin
export MINIO_SECRET_KEY=minioadmin

# AWS Athena configuration
export AWS_REGION=us-east-1
export ATHENA_OUTPUT_LOCATION=s3://pt-athena-results/
```

### Configuration File (tier_router_config.yaml)

```yaml
tier_thresholds:
  master_days: 7        # Recent → Master
  minio_days: 90        # Historical → MinIO, Archive → Athena

routing_rules:
  master:
    enabled: true       # Required
    target_percentage: 35

  pgvector:
    enabled: true       # Required
    target_percentage: 25

  minio:
    enabled: true       # Wave 2 enabled
    target_percentage: 20

  athena:
    enabled: true       # Wave 2 enabled
    target_percentage: 20

health_checks:
  enabled: true
  interval_seconds: 30
  latency_threshold_healthy_ms: 100
  latency_threshold_degraded_ms: 500
  max_consecutive_failures: 3

performance:
  max_routing_overhead_ms: 1.0
  target_routing_percentage: 50.0
```

## Testing

### Run All Tests

```bash
# Wave 1 tests (19 tests)
python3 -m pytest tests/test_tier_router_wave1.py -v

# Wave 2 tests (29 tests)
python3 -m pytest tests/test_tier_enablement_wave2.py -v

# All tests together (48 tests)
python3 -m pytest tests/test_tier_router_wave1.py tests/test_tier_enablement_wave2.py -v

# With coverage
python3 -m pytest tests/ --cov=zones.z07_data_access --cov-report=html
```

### Performance Benchmark

```bash
# Run Wave 2 benchmark
python3 -m pytest tests/test_tier_enablement_wave2.py::test_wave2_routing_performance_benchmark -v -s

# Expected output:
# Total queries: 1000
# Average per query: ~0.002ms
# Routing percentage: ~60%
# All 4 tiers active
```

## Monitoring & Alerts

### Key Metrics to Monitor

1. **Routing Percentage** - Should be ≥50%
2. **Routing Overhead** - Should be <1ms
3. **Tier Health Status** - All tiers should be "healthy"
4. **Failover Count** - Low count is normal, high count indicates issues
5. **Cache Hit Rate** (MinIO) - Higher is better (>50% ideal)
6. **Query Success Rate** (Athena) - Should be >95%

### Recommended Alerts

```yaml
# Routing percentage low
- name: routing_percentage_low
  condition: routing_percentage < 50
  severity: warning
  action: Check tier health, verify configuration

# High routing overhead
- name: high_routing_overhead
  condition: avg_overhead_ms > 1.0
  severity: warning
  action: Check health monitoring overhead, profile routing

# Tier unavailable
- name: tier_unavailable
  condition: tier_health.status == "unavailable"
  severity: critical
  action: Check tier service, verify credentials, review logs

# High failover rate
- name: high_failover_rate
  condition: failover_count > 100 per hour
  severity: warning
  action: Investigate tier stability, check health thresholds
```

## Maintenance

### Regular Tasks

**Daily:**
- Review routing metrics
- Check tier health status
- Monitor failover counts

**Weekly:**
- Analyze tier distribution
- Review cache hit rates (MinIO)
- Check Athena query costs

**Monthly:**
- Review and adjust tier thresholds
- Optimize health check intervals
- Update configuration based on workload patterns

### Backup Configuration

```bash
# Backup current config
cp zones/z07_data_access/tier_router_config.yaml \
   zones/z07_data_access/tier_router_config.yaml.bak.$(date +%Y%m%d)
```

### Rollback Procedure

If Wave 2 causes issues, rollback to Wave 1:

```yaml
# In tier_router_config.yaml
routing_rules:
  minio:
    enabled: false  # Disable Wave 2 tier
  athena:
    enabled: false  # Disable Wave 2 tier
```

Or use feature flags:
```bash
export ENABLE_TIER3=false
export ENABLE_TIER4=false
```

## Support & Escalation

### Getting Help

1. Check this runbook
2. Review test suite output
3. Check logs for errors
4. Consult completion report: `.outcomes/WAVE2_TIER_ENABLEMENT.md`

### Contact

- **Implementation:** Agent 10 - Tier Integration Engineer
- **Wave 1 Baseline:** Agent 2/5 - Database Routing
- **Documentation:** `.outcomes/WAVE2_TIER_ENABLEMENT.md`

---

**Document Version:** 1.0
**Last Validated:** 2025-12-06
**Test Status:** ✅ 48/48 tests passing
