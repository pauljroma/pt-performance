# Wave 1 Foundation Monitoring Setup

**Date:** 2025-12-06
**Agent:** Agent 7 - Wave 1 Monitoring Engineer
**Status:** ✅ COMPLETE

---

## Executive Summary

Comprehensive monitoring infrastructure deployed for Wave 1 foundation components (Rust Primitives + Tier Router). Includes Grafana dashboards, Prometheus alert rules, incident response runbooks, and operational procedures based on Agent 6 performance benchmarks.

### Key Deliverables

- ✅ Grafana dashboard with 16 panels covering all Wave 1 metrics
- ✅ 20 alert rules with warning and critical thresholds
- ✅ Incident response runbooks for all alert scenarios
- ✅ Performance baseline tracking and comparison
- ✅ Rollback procedures and emergency protocols

---

## Dashboard Overview

### Location
`/Users/expo/Code/expo/clients/linear-bootstrap/zones/z13_monitoring/dashboards/wave1_foundation.json`

### Dashboard Panels (16 Total)

#### 1. System Health Overview
- **Type:** Stat panel with color-coded health status
- **Metrics:** Overall system health (Healthy/Degraded/Critical)
- **Update Frequency:** 10s
- **Purpose:** At-a-glance system status

#### 2. Rust Primitives - Latency
- **Type:** Time series graph
- **Metrics:** P50, P95, P99 latency
- **Target:** P95 < 0.1ms (baseline: 0.082ms)
- **Alert:** Warning at >0.1ms
- **Purpose:** Track Rust query performance

#### 3. Rust Primitives - Fallback Rate
- **Type:** Time series graph with thresholds
- **Metrics:** Rust → Python fallback percentage
- **Target:** <1% (baseline: <0.1%)
- **Alerts:**
  - Warning: >0.5%
  - Critical: >1%
- **Purpose:** Monitor Rust service availability

#### 4. Rust Primitives - Cache Performance
- **Type:** Dual-axis time series
- **Metrics:**
  - Cache hit rate % (target: 72%)
  - Cache size (entries)
- **Alerts:**
  - Warning: <60% hit rate
  - Critical: <50% hit rate
- **Purpose:** Optimize cache efficiency

#### 5. Rust Primitives - Throughput & Errors
- **Type:** Time series with error overlay
- **Metrics:**
  - Requests per minute
  - Errors per minute
- **Alert:** Any errors trigger critical alert
- **Purpose:** Track request volume and failures

#### 6. Tier Router - Routing Overhead
- **Type:** Time series graph
- **Metrics:** P50, P95, P99 overhead
- **Target:** P95 < 1ms (baseline: 0.55ms)
- **Alerts:**
  - Warning: >0.6ms
  - Critical: >1ms
- **Purpose:** Monitor routing performance impact

#### 7. Tier Router - Tier Distribution
- **Type:** Donut chart
- **Metrics:** Query distribution across 4 tiers
  - Master Tables (target: 58%)
  - PGVector (target: 25%)
  - MinIO (target: 12%)
  - Athena (target: 5%)
- **Purpose:** Visualize routing effectiveness

#### 8. Tier Router - Routing Percentage
- **Type:** Stat panel
- **Metrics:** % queries routed to non-master tiers
- **Target:** 42% (minimum: 30%)
- **Alert:** Warning if <30%
- **Purpose:** Track routing efficiency

#### 9. Tier Router - Fallback Rate
- **Type:** Stat panel with color coding
- **Metrics:** Router fallback percentage
- **Target:** <1%
- **Alerts:**
  - Warning: >0.5%
  - Critical: >1%
- **Purpose:** Monitor routing reliability

#### 10. Tier Router - Classification Speed
- **Type:** Stat panel
- **Metrics:** P95 query classification time
- **Target:** <0.23ms (baseline: 0.23ms)
- **Alert:** Warning at >0.25ms
- **Purpose:** Track classification performance

#### 11. End-to-End Performance - Latency
- **Type:** Time series graph
- **Metrics:** P50, P95, P99 end-to-end latency
- **Target:** P95 < 2ms (baseline: 0.85ms)
- **Alerts:**
  - Warning: >2ms
  - Critical: >5ms
- **Purpose:** Monitor overall system performance

#### 12. System Performance - Throughput
- **Type:** Time series with moving average
- **Metrics:**
  - Queries per minute (1m avg)
  - Queries per minute (5m avg)
- **Baseline:** 51,000 qpm (850 qps)
- **Alert:** Warning if <30,000 qpm
- **Purpose:** Track system capacity

#### 13. System Performance - Memory Usage
- **Type:** Time series with multiple metrics
- **Metrics:**
  - Total process memory
  - Cache memory usage
- **Baseline:** 45MB per 10K queries
- **Alerts:**
  - Warning: >300MB
  - Critical: >500MB
- **Purpose:** Monitor memory efficiency

#### 14. System Performance - Error Rate
- **Type:** Time series with error breakdown
- **Metrics:**
  - Overall error rate %
  - Critical errors per minute
- **Target:** 0% (baseline: 0%)
- **Alerts:**
  - Warning: >0.1%
  - Critical: >1%
- **Purpose:** Track reliability

#### 15. Alert Status Summary
- **Type:** Table
- **Metrics:** All active alerts with state
- **States:** Firing, Pending, OK
- **Purpose:** Centralized alert monitoring

#### 16. Performance Baseline Comparison
- **Type:** Table with color-coded status
- **Metrics:** All key metrics vs. baselines
- **Columns:** Metric, Target, Achieved, Status, Margin
- **Purpose:** Track performance vs. benchmarks

---

## Metric Definitions

### Rust Primitives Metrics

| Metric Name | Type | Description | Unit | Source |
|-------------|------|-------------|------|--------|
| `rust_primitives_latency_bucket` | Histogram | Query latency distribution | ms | Rust service |
| `rust_primitives_requests_total` | Counter | Total requests processed | count | Rust service |
| `rust_primitives_fallback_total` | Counter | Fallback to Python count | count | Rust service |
| `rust_primitives_errors_total` | Counter | Total errors encountered | count | Rust service |
| `rust_primitives_cache_hits` | Counter | Cache hit count | count | Rust service |
| `rust_primitives_cache_misses` | Counter | Cache miss count | count | Rust service |
| `rust_primitives_cache_size` | Gauge | Current cache entries | count | Rust service |
| `rust_primitives_cache_memory_bytes` | Gauge | Cache memory usage | bytes | Rust service |
| `rust_primitives_connection_pool_active` | Gauge | Active DB connections | count | Rust service |
| `rust_primitives_connection_pool_max` | Gauge | Max pool size | count | Rust service |

### Tier Router Metrics

| Metric Name | Type | Description | Unit | Source |
|-------------|------|-------------|------|--------|
| `tier_router_overhead_bucket` | Histogram | Routing overhead distribution | ms | Router service |
| `tier_router_queries_by_tier` | Counter | Queries per tier (labeled) | count | Router service |
| `tier_router_requests_total` | Counter | Total routing requests | count | Router service |
| `tier_router_fallback_total` | Counter | Routing fallback count | count | Router service |
| `tier_router_classification_duration_bucket` | Histogram | Classification time | ms | Router service |
| `tier_router_errors_total` | Counter | Router errors | count | Router service |

### System Performance Metrics

| Metric Name | Type | Description | Unit | Source |
|-------------|------|-------------|------|--------|
| `wave1_end_to_end_latency_bucket` | Histogram | Full request latency | ms | Application |
| `wave1_queries_total` | Counter | Total queries processed | count | Application |
| `wave1_errors_total` | Counter | Total errors (labeled by severity) | count | Application |
| `wave1_system_health` | Gauge | System health score (0-1) | score | Application |
| `wave1_performance_baseline` | Info | Performance baseline metadata | - | Configuration |
| `process_resident_memory_bytes` | Gauge | Process memory usage | bytes | System |
| `process_cpu_seconds_total` | Counter | CPU usage | seconds | System |
| `up` | Gauge | Service availability | 0/1 | Prometheus |

---

## Alert Thresholds

### Alert Severity Levels

- **CRITICAL:** Immediate action required, potential user impact
- **WARNING:** Investigate soon, potential degradation
- **INFO:** Informational, no action required

### Threshold Summary Table

| Alert Name | Warning | Critical | For Duration | Action Required |
|------------|---------|----------|--------------|-----------------|
| Rust High Latency | - | >0.1ms P95 | 2m | Check Rust service health |
| Rust Fallback Storm | >0.5% | >1% | 3m | Investigate Rust availability |
| Rust Errors | - | >0 errors/sec | 2m | Check logs and connectivity |
| Rust Cache Hit Rate Low | <60% | <50% | 5m | Review cache config |
| Router High Overhead | >0.6ms | >1ms P95 | 3m | Review routing logic |
| Router Fallback Rate | - | >1% | 3m | Check routing configuration |
| Router Low Routing % | <30% | - | 10m | Investigate tier selection |
| End-to-End High Latency | >2ms | >5ms P95 | 3m | Check all components |
| High Error Rate | >0.1% | >1% | 2m | Investigate error logs |
| Low Throughput | <30K qpm | - | 5m | Check for traffic drop |
| High Memory Usage | >300MB | >500MB | 10m | Investigate memory leak |
| Component Down | - | Service down | 1m | Restart service |

### Alert Threshold Justifications

#### Rust Primitives

**Latency (P95 > 0.1ms):**
- Baseline: 0.082ms
- Target: <0.1ms
- Justification: 0.1ms was the original performance target; exceeding this indicates degradation from baseline performance

**Fallback Rate (>1%):**
- Baseline: <0.1%
- Warning: 0.5%
- Critical: 1%
- Justification: >1% indicates Rust service instability; graceful degradation to Python works but loses 8x speedup benefit

**Cache Hit Rate (<50%):**
- Baseline: 72%
- Warning: 60% (17% below baseline)
- Critical: 50% (minimum target)
- Justification: Cache performance directly impacts latency; <50% significantly degrades performance

#### Tier Router

**Overhead (P95 > 1ms):**
- Baseline: 0.55ms
- Warning: 0.6ms (9% over baseline)
- Critical: 1ms (target threshold)
- Justification: 1ms was the design target; exceeding it erodes Rust speedup benefits

**Routing Percentage (<30%):**
- Baseline: 42%
- Target: 30%+
- Warning: <30%
- Justification: <30% indicates router not effectively distributing load across tiers

#### End-to-End System

**Latency (P95 > 2ms):**
- Baseline: 0.85ms
- Warning: 2ms (2.35x baseline)
- Critical: 5ms (5.88x baseline)
- Justification: 2ms target allows headroom for production variability; 5ms indicates severe degradation

**Error Rate (>1%):**
- Baseline: 0%
- Warning: 0.1%
- Critical: 1%
- Justification: Any errors indicate issues; >1% suggests systemic problems

**Memory (>500MB):**
- Baseline: 45MB per 10K queries
- Peak load: ~300MB
- Warning: 300MB
- Critical: 500MB
- Justification: 500MB suggests memory leak or cache bloat; well above expected usage

---

## Dashboard Setup Guide

### Prerequisites

1. **Prometheus:** Running and scraping Wave 1 metrics
2. **Grafana:** Version 9.0+ installed
3. **Access:** Admin access to Grafana instance
4. **Data Source:** Prometheus data source configured

### Installation Steps

#### Step 1: Import Dashboard

```bash
# Option 1: Via Grafana UI
1. Navigate to Grafana → Dashboards → Import
2. Upload file: zones/z13_monitoring/dashboards/wave1_foundation.json
3. Select Prometheus data source
4. Click "Import"

# Option 2: Via API
curl -X POST http://grafana:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
  -d @zones/z13_monitoring/dashboards/wave1_foundation.json
```

#### Step 2: Configure Alert Rules

```bash
# Copy alert rules to Prometheus
cp zones/z13_monitoring/alerts/wave1_alert_rules.yaml \
   /etc/prometheus/rules/wave1_alert_rules.yaml

# Reload Prometheus configuration
curl -X POST http://prometheus:9090/-/reload

# Verify rules loaded
curl http://prometheus:9090/api/v1/rules | jq '.data.groups[] | select(.name | startswith("wave1"))'
```

#### Step 3: Configure Alert Manager

```yaml
# /etc/alertmanager/alertmanager.yml
route:
  group_by: ['wave', 'component', 'severity']
  group_wait: 10s
  group_interval: 5m
  repeat_interval: 3h
  receiver: 'wave1-alerts'

  routes:
    - match:
        wave: wave1
        severity: critical
      receiver: 'wave1-critical'
      repeat_interval: 30m

    - match:
        wave: wave1
        severity: warning
      receiver: 'wave1-warning'
      repeat_interval: 1h

receivers:
  - name: 'wave1-critical'
    pagerduty_configs:
      - service_key: ${PAGERDUTY_SERVICE_KEY}
        description: '{{ .GroupLabels.alertname }}: {{ .Annotations.summary }}'
    slack_configs:
      - api_url: ${SLACK_WEBHOOK_URL}
        channel: '#wave1-alerts-critical'
        title: 'Wave 1 Critical Alert'
        text: '{{ .Annotations.description }}'

  - name: 'wave1-warning'
    slack_configs:
      - api_url: ${SLACK_WEBHOOK_URL}
        channel: '#wave1-alerts-warning'
        title: 'Wave 1 Warning'
        text: '{{ .Annotations.description }}'

  - name: 'wave1-alerts'
    slack_configs:
      - api_url: ${SLACK_WEBHOOK_URL}
        channel: '#wave1-monitoring'
```

#### Step 4: Verify Setup

```bash
# Check Prometheus targets
curl http://prometheus:9090/api/v1/targets | jq '.data.activeTargets[] | select(.job == "wave1")'

# Check alert rules
curl http://prometheus:9090/api/v1/rules | jq '.data.groups[] | select(.name | startswith("wave1")) | .rules[] | .name'

# Check Grafana dashboard
curl -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
  http://grafana:3000/api/search?query=Wave%201 | jq .

# Test alert
curl -X POST http://prometheus:9090/api/v1/admin/tsdb/delete_series \
  -d 'match[]=rust_primitives_latency_bucket{quantile="0.95"}' \
  -d 'start=2025-01-01T00:00:00Z' \
  -d 'end=2025-12-31T23:59:59Z'
```

### Customization Options

#### Dashboard Variables

The dashboard supports templating for different environments:

```json
{
  "templating": {
    "list": [
      {
        "name": "environment",
        "options": ["prod", "staging", "dev"],
        "current": "prod"
      },
      {
        "name": "component",
        "options": ["rust_primitives", "tier_router", "end_to_end"],
        "multi": true,
        "includeAll": true
      }
    ]
  }
}
```

**Usage:**
- Select environment from dropdown (Production/Staging/Development)
- Filter by component (Rust Primitives, Tier Router, End-to-End)

#### Alert Rule Tuning

To adjust thresholds based on your environment:

```yaml
# Edit: zones/z13_monitoring/alerts/wave1_alert_rules.yaml

# Example: Increase latency threshold for high-latency environments
- alert: RustPrimitivesHighLatency
  expr: histogram_quantile(0.95, rate(rust_primitives_latency_bucket[5m])) > 0.2  # Changed from 0.1
  for: 5m  # Changed from 2m
```

---

## Metric Collection Setup

### Instrumenting Rust Primitives

```rust
// src/rust_primitives/metrics.rs
use prometheus::{Histogram, Counter, Gauge, Registry};

lazy_static! {
    pub static ref RUST_LATENCY: Histogram = Histogram::with_opts(
        histogram_opts!("rust_primitives_latency", "Query latency in seconds")
            .buckets(vec![0.00005, 0.0001, 0.0002, 0.0005, 0.001, 0.002, 0.005])
    ).unwrap();

    pub static ref RUST_REQUESTS: Counter = Counter::new(
        "rust_primitives_requests_total",
        "Total requests"
    ).unwrap();

    pub static ref RUST_FALLBACK: Counter = Counter::new(
        "rust_primitives_fallback_total",
        "Fallback to Python count"
    ).unwrap();

    pub static ref RUST_CACHE_HITS: Counter = Counter::new(
        "rust_primitives_cache_hits",
        "Cache hit count"
    ).unwrap();

    pub static ref RUST_CACHE_SIZE: Gauge = Gauge::new(
        "rust_primitives_cache_size",
        "Current cache size"
    ).unwrap();
}

// Usage in query function
pub fn query_drug_name(drug_id: i32) -> Result<String> {
    let timer = RUST_LATENCY.start_timer();
    RUST_REQUESTS.inc();

    let result = match execute_query(drug_id) {
        Ok(name) => {
            RUST_CACHE_HITS.inc();
            Ok(name)
        }
        Err(e) => {
            RUST_FALLBACK.inc();
            fallback_to_python(drug_id)
        }
    };

    timer.observe_duration();
    result
}
```

### Instrumenting Tier Router

```python
# src/tier_router/metrics.py
from prometheus_client import Histogram, Counter, Gauge

ROUTER_OVERHEAD = Histogram(
    'tier_router_overhead',
    'Routing overhead in seconds',
    buckets=[0.0002, 0.0004, 0.0006, 0.001, 0.002, 0.005]
)

ROUTER_QUERIES_BY_TIER = Counter(
    'tier_router_queries_by_tier',
    'Queries routed to each tier',
    ['tier']
)

ROUTER_CLASSIFICATION_DURATION = Histogram(
    'tier_router_classification_duration',
    'Query classification time',
    buckets=[0.0001, 0.0002, 0.0003, 0.0005, 0.001]
)

# Usage in router
def route_query(query_type, query_params):
    with ROUTER_OVERHEAD.time():
        with ROUTER_CLASSIFICATION_DURATION.time():
            tier = classify_query(query_type)

        ROUTER_QUERIES_BY_TIER.labels(tier=tier).inc()
        return execute_on_tier(tier, query_params)
```

### Prometheus Scrape Configuration

```yaml
# /etc/prometheus/prometheus.yml
scrape_configs:
  - job_name: 'wave1'
    scrape_interval: 10s
    scrape_timeout: 5s
    metrics_path: '/metrics'
    static_configs:
      - targets:
          - 'rust-primitives:9090'
          - 'tier-router:9091'
          - 'application:9092'
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
      - source_labels: []
        target_label: wave
        replacement: 'wave1'
```

---

## Runbook: Common Issues

### Issue 1: Rust Primitives High Latency

**Alert:** `RustPrimitivesHighLatency`
**Severity:** CRITICAL
**Threshold:** P95 > 0.1ms for 2 minutes

#### Symptoms
- Grafana dashboard shows latency spike
- Alert firing in Alert Manager
- User reports of slow queries

#### Investigation Steps

1. **Check Rust service health:**
   ```bash
   curl http://rust-primitives:9090/health
   # Expected: {"status": "healthy", "latency_p95_ms": 0.082}
   ```

2. **Check database performance:**
   ```bash
   # PostgreSQL slow query log
   psql -c "SELECT query, mean_exec_time, calls FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 10;"
   ```

3. **Check connection pool:**
   ```bash
   curl http://rust-primitives:9090/metrics | grep connection_pool
   # Look for: rust_primitives_connection_pool_active near pool_max
   ```

4. **Check cache hit rate:**
   ```bash
   curl http://rust-primitives:9090/metrics | grep cache
   # Calculate: cache_hits / (cache_hits + cache_misses)
   ```

#### Resolution Actions

**Action 1: Database Slowness**
```sql
-- Identify blocking queries
SELECT pid, query, wait_event, state FROM pg_stat_activity WHERE wait_event IS NOT NULL;

-- Kill long-running queries
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state = 'active' AND query_start < NOW() - INTERVAL '5 minutes';
```

**Action 2: Connection Pool Exhaustion**
```bash
# Increase pool size (temporary)
curl -X POST http://rust-primitives:9090/config \
  -d '{"connection_pool_size": 50}'  # From 20 to 50

# Restart service with new config
systemctl restart rust-primitives
```

**Action 3: Cache Invalidation**
```bash
# Clear cache to force rebuild
curl -X POST http://rust-primitives:9090/cache/clear

# Warm up cache
curl -X POST http://rust-primitives:9090/cache/warmup
```

#### Escalation
- **After 5 minutes:** Page on-call engineer
- **After 10 minutes:** Consider rollback to Python baseline
- **After 15 minutes:** Execute rollback procedure

---

### Issue 2: Rust Fallback Storm

**Alert:** `RustPrimitivesFallbackStorm`
**Severity:** CRITICAL
**Threshold:** Fallback rate >1% for 3 minutes

#### Symptoms
- Rust service unavailable or timing out
- All queries falling back to Python
- Performance degraded to baseline (8x slower)

#### Investigation Steps

1. **Check Rust service status:**
   ```bash
   systemctl status rust-primitives
   curl http://rust-primitives:9090/health
   ```

2. **Check logs for errors:**
   ```bash
   journalctl -u rust-primitives -n 100 --no-pager | grep -i error
   ```

3. **Check database connectivity:**
   ```bash
   # From Rust service container
   psql -h ${DB_HOST} -U ${DB_USER} -d ${DB_NAME} -c "SELECT 1;"
   ```

4. **Check network connectivity:**
   ```bash
   ping -c 5 ${DB_HOST}
   telnet ${DB_HOST} 5432
   ```

#### Resolution Actions

**Action 1: Rust Service Down**
```bash
# Restart service
systemctl restart rust-primitives

# Check startup logs
journalctl -u rust-primitives -f

# Verify health
curl http://rust-primitives:9090/health
```

**Action 2: Database Connection Issues**
```bash
# Check database connections
psql -c "SELECT count(*) FROM pg_stat_activity WHERE application_name = 'rust_primitives';"

# Kill idle connections
psql -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE application_name = 'rust_primitives' AND state = 'idle';"

# Restart Rust service to re-establish connections
systemctl restart rust-primitives
```

**Action 3: Accept Degraded Performance**
```bash
# If Rust cannot be restored quickly, accept Python fallback
# Monitor Python performance
curl http://application:9092/metrics | grep python_baseline_latency

# Set expectations: 8x slower but functional
# Continue debugging Rust service offline
```

#### Escalation
- **After 3 minutes:** Page database team
- **After 10 minutes:** Consider disabling Rust primitives
- **After 20 minutes:** Execute full rollback

---

### Issue 3: Tier Router High Overhead

**Alert:** `TierRouterHighOverhead`
**Severity:** CRITICAL
**Threshold:** P95 overhead >1ms for 3 minutes

#### Symptoms
- Routing taking longer than expected
- End-to-end latency increased
- Query classification slow

#### Investigation Steps

1. **Check router metrics:**
   ```bash
   curl http://tier-router:9091/metrics | grep tier_router_overhead
   curl http://tier-router:9091/metrics | grep tier_router_classification_duration
   ```

2. **Check tier availability:**
   ```bash
   # Master tables
   psql -h ${MASTER_HOST} -c "SELECT 1;"

   # PGVector
   curl http://pgvector:5433/health

   # MinIO
   mc admin info minio

   # Athena
   aws athena get-query-execution --query-execution-id test
   ```

3. **Check routing logic complexity:**
   ```bash
   # Review recent config changes
   git log --since="1 hour ago" -- tier_router/config.yaml
   ```

#### Resolution Actions

**Action 1: Simplify Routing Logic**
```python
# Temporarily disable complex classification rules
# tier_router/config.yaml
routing_rules:
  query_classification:
    use_ml_classification: false  # Disable ML, use simple rules
    use_regex_patterns: false     # Disable regex, use exact matches
```

**Action 2: Increase Routing Timeout**
```yaml
# tier_router/config.yaml
timeouts:
  classification_timeout_ms: 500  # Increase from 250ms
  tier_selection_timeout_ms: 1000  # Increase from 500ms
```

**Action 3: Fallback to Master Only**
```bash
# Disable tier routing temporarily
export TIER_ROUTER_ENABLED=false
systemctl restart application

# All queries go to master (slower but reliable)
```

#### Escalation
- **After 5 minutes:** Notify routing team
- **After 10 minutes:** Consider disabling tier router
- **After 15 minutes:** Fallback to master-only mode

---

### Issue 4: High Error Rate

**Alert:** `Wave1HighErrorRate`
**Severity:** CRITICAL
**Threshold:** Error rate >1% for 2 minutes

#### Symptoms
- Queries failing with errors
- Users experiencing failures
- Error logs growing rapidly

#### Investigation Steps

1. **Identify error types:**
   ```bash
   # Check error logs
   journalctl -u application -n 1000 --no-pager | grep -i error | sort | uniq -c | sort -nr

   # Check Prometheus metrics
   curl http://application:9092/metrics | grep wave1_errors_total
   ```

2. **Check common error causes:**
   ```bash
   # Database errors
   psql -c "SELECT * FROM pg_stat_database WHERE datname = '${DB_NAME}';"

   # Connection errors
   netstat -an | grep ${DB_PORT} | grep ESTABLISHED | wc -l

   # Timeout errors
   grep -i timeout /var/log/application/error.log | tail -20
   ```

3. **Check resource exhaustion:**
   ```bash
   # Memory
   free -h

   # CPU
   top -b -n 1 | head -20

   # Disk
   df -h

   # File descriptors
   lsof -p $(pgrep application) | wc -l
   ```

#### Resolution Actions

**Action 1: Database Connection Issues**
```bash
# Increase connection pool
export DB_POOL_SIZE=100  # From 20
systemctl restart application

# Add connection retry logic
export DB_CONNECTION_RETRY_COUNT=5
export DB_CONNECTION_RETRY_DELAY_MS=1000
systemctl restart application
```

**Action 2: Timeout Issues**
```bash
# Increase query timeouts
export QUERY_TIMEOUT_MS=5000  # From 1000
export CONNECTION_TIMEOUT_MS=10000  # From 5000
systemctl restart application
```

**Action 3: Resource Exhaustion**
```bash
# Restart service to clear resources
systemctl restart application

# Monitor for immediate recurrence
watch -n 1 'curl http://application:9092/metrics | grep error'

# If errors persist, scale horizontally
kubectl scale deployment application --replicas=5  # From 3
```

#### Escalation
- **After 2 minutes:** Page on-call engineer
- **After 5 minutes:** Engage database team
- **After 10 minutes:** Consider full rollback

---

### Issue 5: Low Cache Hit Rate

**Alert:** `RustCacheHitRateLow`
**Severity:** WARNING
**Threshold:** Hit rate <50% for 5 minutes

#### Symptoms
- Cache hit rate declining
- Latency increasing
- Database load increasing

#### Investigation Steps

1. **Check cache metrics:**
   ```bash
   curl http://rust-primitives:9090/metrics | grep cache
   # Look at: cache_hits, cache_misses, cache_size, cache_evictions
   ```

2. **Check cache configuration:**
   ```bash
   curl http://rust-primitives:9090/config | jq .cache
   # Expected: {"max_size": 20000, "ttl_seconds": 3600}
   ```

3. **Analyze query patterns:**
   ```bash
   # Check for high cardinality queries (many unique keys)
   psql -c "SELECT COUNT(DISTINCT drug_id) FROM recent_queries;"
   ```

#### Resolution Actions

**Action 1: Increase Cache Size**
```bash
# Increase cache from 20K to 50K entries
curl -X POST http://rust-primitives:9090/config \
  -d '{"cache_max_size": 50000}'

# Monitor memory impact
watch -n 5 'curl http://rust-primitives:9090/metrics | grep cache_memory_bytes'
```

**Action 2: Adjust TTL**
```bash
# Increase TTL from 1 hour to 4 hours for stable data
curl -X POST http://rust-primitives:9090/config \
  -d '{"cache_ttl_seconds": 14400}'
```

**Action 3: Warm Up Cache**
```bash
# Pre-populate cache with common queries
curl -X POST http://rust-primitives:9090/cache/warmup \
  -d '{"top_n_queries": 10000}'
```

#### Escalation
- **After 15 minutes:** Notify performance team
- **After 30 minutes:** Consider cache architecture review

---

## Rollback Procedures

### Emergency Rollback: Full Wave 1 Disable

**When to Execute:**
- Multiple critical alerts firing
- User impact severe and widespread
- Unable to resolve issues within 15 minutes
- Performance degraded beyond acceptable levels

**Rollback Steps:**

#### Step 1: Disable Rust Primitives (30 seconds)

```bash
# Set environment variable to disable Rust
export RUST_PRIMITIVES_ENABLED=false

# Verify fallback to Python baseline active
curl http://application:9092/config | jq .rust_primitives.enabled
# Expected: false

# Restart application
systemctl restart application

# Verify Python fallback working
curl http://application:9092/health
# Expected: {"status": "healthy", "rust_enabled": false, "fallback": "python"}
```

**Impact:** Queries will run on Python baseline (8x slower but functional)

#### Step 2: Disable Tier Router (30 seconds)

```bash
# Set environment variable to disable routing
export TIER_ROUTER_ENABLED=false

# Verify routing disabled
curl http://application:9092/config | jq .tier_router.enabled
# Expected: false

# Restart application
systemctl restart application

# Verify master-only mode
curl http://application:9092/health
# Expected: {"status": "healthy", "tier_router_enabled": false, "mode": "master_only"}
```

**Impact:** All queries route to master database (higher load but reliable)

#### Step 3: Verify Rollback Success (1 minute)

```bash
# Check application health
curl http://application:9092/health
# Expected: {"status": "healthy", "wave1_enabled": false}

# Check error rate
curl http://application:9092/metrics | grep wave1_errors_total
# Expected: Errors declining

# Check latency
curl http://application:9092/metrics | grep wave1_end_to_end_latency
# Expected: Latency stabilized (higher but stable)

# Monitor dashboards
# - Error rate should decrease
# - Latency should stabilize
# - Throughput may decrease but should be stable
```

#### Step 4: Notify Stakeholders (2 minutes)

```bash
# Send notification to Slack
curl -X POST ${SLACK_WEBHOOK_URL} \
  -H 'Content-Type: application/json' \
  -d '{
    "channel": "#wave1-alerts",
    "text": "Wave 1 emergency rollback executed",
    "attachments": [{
      "color": "danger",
      "fields": [
        {"title": "Status", "value": "Rolled back to baseline", "short": true},
        {"title": "Time", "value": "'$(date)' ", "short": true},
        {"title": "Impact", "value": "Rust disabled (8x slower), Tier router disabled (master-only)", "short": false}
      ]
    }]
  }'

# Update status page
curl -X POST ${STATUS_PAGE_API} \
  -d '{"status": "degraded", "message": "Wave 1 features temporarily disabled"}'
```

#### Step 5: Post-Rollback Verification (5 minutes)

```bash
# Monitor for 5 minutes
for i in {1..30}; do
  echo "=== Check $i/30 ==="
  curl -s http://application:9092/metrics | grep -E "error|latency"
  sleep 10
done

# Expected: Stable metrics, no errors, latency predictable
```

**Total Rollback Time:** ~5 minutes (< 5 minute SLA)

### Gradual Re-Enable After Rollback

Once issues are resolved, re-enable Wave 1 gradually:

#### Phase 1: Enable Rust Primitives (5% traffic)

```bash
# Enable Rust with 5% traffic
export RUST_PRIMITIVES_ENABLED=true
export RUST_PRIMITIVES_TRAFFIC_PERCENTAGE=5
systemctl restart application

# Monitor for 15 minutes
# Check: latency, fallback rate, errors
```

#### Phase 2: Increase Rust Traffic (25% → 50% → 100%)

```bash
# Every 15 minutes, increase traffic
export RUST_PRIMITIVES_TRAFFIC_PERCENTAGE=25
systemctl restart application

# Monitor and repeat at 50%, then 100%
```

#### Phase 3: Enable Tier Router (similar gradual approach)

```bash
export TIER_ROUTER_ENABLED=true
export TIER_ROUTER_TRAFFIC_PERCENTAGE=5
# Repeat gradual ramp
```

---

## Monitoring Best Practices

### 1. Alert Fatigue Prevention

**Problem:** Too many alerts reduce response effectiveness

**Solutions:**
- Use appropriate severity levels (Critical vs Warning)
- Set "for" duration to avoid transient spikes
- Group related alerts together
- Implement alert inhibition for cascading failures

**Example:**
```yaml
# Inhibit Rust latency alert if Rust is in fallback storm
inhibit_rules:
  - source_match:
      alertname: 'RustPrimitivesFallbackStorm'
    target_match:
      alertname: 'RustPrimitivesHighLatency'
    equal: ['component']
```

### 2. Dashboard Organization

**Structure:**
1. **Overview Panel** (top): System health at a glance
2. **Component Panels** (middle): Detailed metrics per component
3. **System Panels** (bottom): Cross-component metrics
4. **Alert Panel** (last): Current alert status

**Color Coding:**
- Green: Exceeds targets
- Blue: Meets targets
- Yellow: Warning threshold
- Red: Critical threshold

### 3. Baseline Tracking

**Maintain historical baselines:**
```bash
# Export current metrics as baseline
curl http://application:9092/metrics > baseline-$(date +%Y%m%d).txt

# Compare to baseline weekly
./scripts/compare_to_baseline.sh baseline-20251206.txt
```

### 4. Regular Review Cadence

**Daily:** Check dashboard for anomalies
**Weekly:** Review alert trends and tune thresholds
**Monthly:** Update baselines based on traffic growth
**Quarterly:** Review and update runbooks

---

## Troubleshooting Guide

### Dashboard Not Loading

**Symptoms:** Grafana dashboard empty or errors

**Checks:**
1. Verify Grafana running: `systemctl status grafana-server`
2. Check data source connected: Grafana → Configuration → Data Sources
3. Verify Prometheus scraping: `curl http://prometheus:9090/api/v1/targets`
4. Check time range selected (default: last 1 hour)

### Metrics Not Appearing

**Symptoms:** Panels show "No data"

**Checks:**
1. Verify metric names: `curl http://prometheus:9090/api/v1/label/__name__/values | grep wave1`
2. Check Prometheus scrape config
3. Verify application exporting metrics: `curl http://application:9092/metrics`
4. Check firewall rules allowing Prometheus scraping

### Alerts Not Firing

**Symptoms:** Expected alerts not triggering

**Checks:**
1. Verify alert rules loaded: `curl http://prometheus:9090/api/v1/rules`
2. Check alert expression manually: `curl 'http://prometheus:9090/api/v1/query?query=...'`
3. Verify AlertManager configured: `curl http://alertmanager:9093/api/v1/status`
4. Check "for" duration hasn't been met yet

### Wrong Baseline Values

**Symptoms:** Dashboard shows incorrect targets

**Resolution:**
1. Edit dashboard JSON: zones/z13_monitoring/dashboards/wave1_foundation.json
2. Update baseline values in panel descriptions
3. Update alert thresholds if needed
4. Re-import dashboard to Grafana

---

## Performance Baselines Reference

### Quick Reference Table

| Component | Metric | Baseline | Target | Warning | Critical |
|-----------|--------|----------|--------|---------|----------|
| **Rust Primitives** |
| | P50 Latency | 0.062ms | <0.1ms | - | >0.1ms |
| | P95 Latency | 0.082ms | <0.1ms | - | >0.1ms |
| | P99 Latency | 0.089ms | <0.15ms | - | >0.15ms |
| | Fallback Rate | <0.1% | <1% | >0.5% | >1% |
| | Cache Hit Rate | 72% | >50% | <60% | <50% |
| | Speedup vs Python | 8x | 8x+ | <6x | <4x |
| **Tier Router** |
| | P50 Overhead | 0.40ms | <1ms | - | >0.6ms |
| | P95 Overhead | 0.55ms | <1ms | >0.6ms | >1ms |
| | P99 Overhead | 0.60ms | <1.5ms | >1ms | >1.5ms |
| | Routing % | 42% | >30% | <30% | <20% |
| | Classification P95 | 0.23ms | <0.25ms | >0.25ms | >0.5ms |
| | Fallback Rate | <0.1% | <1% | >0.5% | >1% |
| **End-to-End** |
| | P50 Latency | 0.605ms | <2ms | - | >2ms |
| | P95 Latency | 0.850ms | <2ms | >2ms | >5ms |
| | P99 Latency | 0.920ms | <3ms | >3ms | >10ms |
| | Throughput | 51K qpm | >30K qpm | <30K qpm | <10K qpm |
| | Error Rate | 0% | <0.1% | >0.1% | >1% |
| | Memory (10K queries) | 45MB | <100MB | >300MB | >500MB |

**Source:** Agent 6 - Wave 1 Performance Benchmarking (AGENT6_WAVE1_PERFORMANCE_COMPLETION_REPORT.md)

---

## Appendix: Metric Calculation Examples

### Cache Hit Rate
```promql
(
  rate(rust_primitives_cache_hits[5m]) /
  (rate(rust_primitives_cache_hits[5m]) + rate(rust_primitives_cache_misses[5m]))
) * 100
```

### Fallback Rate
```promql
(
  rate(rust_primitives_fallback_total[5m]) /
  rate(rust_primitives_requests_total[5m])
) * 100
```

### Non-Master Routing Percentage
```promql
(
  sum(rate(tier_router_queries_by_tier{tier!="master_tables"}[5m])) /
  sum(rate(tier_router_queries_by_tier[5m]))
) * 100
```

### Error Rate
```promql
(
  rate(wave1_errors_total[5m]) /
  rate(wave1_queries_total[5m])
) * 100
```

### Throughput (Queries Per Minute)
```promql
rate(wave1_queries_total[1m]) * 60
```

---

## Contact & Support

**On-Call Engineer:** Check PagerDuty rotation
**Slack Channels:**
- #wave1-alerts-critical (Critical alerts)
- #wave1-alerts-warning (Warning alerts)
- #wave1-monitoring (General monitoring discussion)

**Documentation:**
- Performance Report: `.outcomes/WAVE1_PERFORMANCE_REPORT.md`
- Agent 6 Benchmarks: `AGENT6_WAVE1_PERFORMANCE_COMPLETION_REPORT.md`
- Dashboard Config: `zones/z13_monitoring/dashboards/wave1_foundation.json`
- Alert Rules: `zones/z13_monitoring/alerts/wave1_alert_rules.yaml`

**Runbook Updates:**
Submit PRs to update this runbook based on incident learnings.

---

**Document Version:** 1.0
**Last Updated:** 2025-12-06
**Next Review:** 2025-12-20
