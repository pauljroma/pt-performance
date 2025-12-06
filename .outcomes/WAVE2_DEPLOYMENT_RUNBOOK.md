# Wave 2 Production Deployment Runbook

**Version:** 1.0
**Date:** 2025-12-06
**Owner:** Agent 12 - Production Deployment Engineer
**Status:** Production Ready

---

## Executive Summary

This runbook provides comprehensive step-by-step procedures for deploying Wave 2 performance optimizations to production using a gradual rollout strategy (5% → 25% → 50% → 100%). The deployment leverages:

- **Rust optimizations:** 10x speedup (0.520ms → 0.052ms latency)
- **4-tier routing:** 60% optimal tier routing with 0.0018ms overhead
- **Gradual rollout:** 4-week phased approach with validation gates
- **Emergency rollback:** <5 minute rollback capability at any phase

---

## Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Deployment Phases](#deployment-phases)
3. [Health Check Procedures](#health-check-procedures)
4. [Rollback Procedures](#rollback-procedures)
5. [Communication Templates](#communication-templates)
6. [Troubleshooting Guide](#troubleshooting-guide)

---

## Pre-Deployment Checklist

### Infrastructure Requirements

#### Wave 2 Rust Components
- [ ] Rust primitives compiled in release mode
- [ ] Prepared statement cache configured (100 entries)
- [ ] Async query engine validated (1,700+ qps)
- [ ] Dynamic connection pool tested (10-100 connections)
- [ ] All 87 tests passing (67 Wave 1 + 20 Wave 2)

#### Wave 2 Tier Router Components
- [ ] MinIO (Tier 3) deployed and accessible
- [ ] Athena (Tier 4) configured with S3 output bucket
- [ ] Health monitoring system active
- [ ] All 48 tier routing tests passing (19 Wave 1 + 29 Wave 2)

#### Environment Configuration
```bash
# Rust configuration
export RUST_PRIMITIVES_ENABLED=true
export RUST_PRIMITIVES_USE_V2=true
export RUST_POOL_SIZE_MIN=10
export RUST_POOL_SIZE_MAX=100
export RUST_TARGET_UTILIZATION=0.8
export RUST_PREPARED_STMT_CACHE_SIZE=100

# Tier routing configuration
export TIER_ROUTER_ENABLED=true
export ENABLE_TIER3=true  # MinIO
export ENABLE_TIER4=true  # Athena

# MinIO credentials
export MINIO_ENDPOINT=minio.production.example.com:9000
export MINIO_ACCESS_KEY=<from_secrets>
export MINIO_SECRET_KEY=<from_secrets>
export MINIO_BUCKET=pt-historical

# AWS Athena credentials
export AWS_REGION=us-east-1
export ATHENA_DATABASE=pt_analytics
export ATHENA_OUTPUT_LOCATION=s3://pt-athena-results/
export ATHENA_WORKGROUP=primary
```

#### Monitoring & Alerting
- [ ] Prometheus metrics collection active
- [ ] Grafana dashboards deployed:
  - Wave 2 Performance Dashboard
  - Tier Routing Dashboard
  - Rust Optimization Metrics
- [ ] PagerDuty integration configured
- [ ] Alert thresholds configured (see monitoring section)

#### Baseline Metrics Captured
- [ ] Wave 1 performance baseline documented
  - Latency P95: 0.082ms
  - Throughput: 850 qps
  - Routing percentage: 42%
- [ ] Current production traffic patterns analyzed
- [ ] Resource utilization baseline captured (CPU, memory, connections)

#### Rollback Preparation
- [ ] Wave 1 deployment artifacts preserved
- [ ] Rollback scripts tested in staging
- [ ] Feature flags configured for instant disable
- [ ] Emergency contact list updated

---

## Deployment Phases

### Phase 1: Canary (5% Traffic, Week 1)

**Duration:** 7 days
**Traffic:** 5% of production load
**Goal:** Validate basic functionality in production environment

#### Step 1.1: Deploy to Canary Servers

```bash
# 1. Deploy Rust binaries
cd /path/to/rust_primitives
cargo build --release
cp target/release/librust_primitives.so /production/canary/lib/

# 2. Deploy tier router updates
cd /path/to/linear-bootstrap
rsync -av zones/z07_data_access/ canary-servers:/production/zones/z07_data_access/

# 3. Update configuration (5% traffic routing)
cat > /production/canary/config/traffic_split.yaml <<EOF
wave2_enabled: true
traffic_percentage: 5
features:
  rust_v2: true
  tier_router_4tier: true
EOF

# 4. Restart canary services
ssh canary-servers "systemctl restart pt-app-canary"
```

#### Step 1.2: Enable Feature Flags (5% Gradual)

```python
# Via feature flag service
from config.feature_flags import FeatureFlags

flags = FeatureFlags()
flags.set_percentage("wave2_rust_optimizations", 5.0)
flags.set_percentage("wave2_tier_routing", 5.0)
flags.commit()
```

#### Step 1.3: Monitor Canary Metrics (First 24 Hours)

**Critical Metrics to Watch:**
```yaml
rust_performance:
  latency_p95_ms:
    target: "< 0.060"  # Allow 15% margin
    alert_threshold: "> 0.070"

  throughput_qps:
    target: "> 85"  # 5% of 1,700
    alert_threshold: "< 75"

  error_rate:
    target: "< 0.1%"
    alert_threshold: "> 0.5%"

tier_routing:
  routing_percentage:
    target: "> 50%"
    alert_threshold: "< 45%"

  routing_overhead_ms:
    target: "< 0.005"  # Allow margin
    alert_threshold: "> 0.010"

  tier_health:
    target: "all_healthy"
    alert_threshold: "any_unavailable"
```

**Monitoring Commands:**
```bash
# Check Rust performance
curl http://canary-servers/metrics | grep rust_latency_p95
curl http://canary-servers/metrics | grep rust_throughput_qps

# Check tier routing
curl http://canary-servers/metrics | grep tier_routing_percentage
curl http://canary-servers/metrics | grep tier_distribution

# Check errors
tail -f /production/logs/canary/errors.log | grep -i "wave2\|rust\|tier"
```

#### Step 1.4: Success Criteria (Day 7)

**All must pass to proceed to Phase 2:**
- ✅ Zero SEV-1 or SEV-2 incidents
- ✅ Latency P95 ≤ 0.060ms (within 15% of baseline)
- ✅ Throughput ≥ 85 qps (5% of target)
- ✅ Error rate < 0.1%
- ✅ Routing percentage ≥ 50%
- ✅ All 4 tiers healthy
- ✅ No user-reported issues
- ✅ Rollback tested and validated

**Go/No-Go Decision:**
```bash
# Run automated validation
python3 scripts/validate_phase1.py --canary

# Output example:
# ✅ Latency P95: 0.053ms (target: < 0.060ms)
# ✅ Throughput: 92 qps (target: > 85 qps)
# ✅ Error rate: 0.03% (target: < 0.1%)
# ✅ Routing: 58% (target: > 50%)
# ✅ Tier health: 4/4 healthy
#
# PHASE 1 COMPLETE - APPROVED FOR PHASE 2
```

---

### Phase 2: Ramp to 25% (Week 2)

**Duration:** 7 days
**Traffic:** 5% → 25% progressive ramp
**Goal:** Validate under moderate production load

#### Step 2.1: Ramp Traffic (Day 1-3)

```bash
# Day 1: 5% → 10%
flags.set_percentage("wave2_rust_optimizations", 10.0)
# Wait 24 hours, monitor

# Day 2: 10% → 15%
flags.set_percentage("wave2_rust_optimizations", 15.0)
# Wait 24 hours, monitor

# Day 3: 15% → 25%
flags.set_percentage("wave2_rust_optimizations", 25.0)
# Stabilize for 4 days
```

#### Step 2.2: Monitor Moderate Load Metrics

**Enhanced Monitoring (25% Traffic):**
```yaml
rust_performance:
  latency_p95_ms:
    target: "< 0.055"
    p99: "< 0.060"
    alert_threshold: "> 0.065"

  throughput_qps:
    target: "> 425"  # 25% of 1,700
    alert_threshold: "< 375"

  cpu_usage_pct:
    target: "< 60%"
    alert_threshold: "> 70%"

  memory_usage_pct:
    target: "< 70%"
    alert_threshold: "> 80%"

tier_routing:
  routing_percentage:
    target: "> 55%"  # Expect slight improvement
    alert_threshold: "< 50%"

  tier_distribution:
    master: "35-45%"
    pgvector: "15-25%"
    minio: "15-25%"
    athena: "15-25%"
```

**Resource Monitoring:**
```bash
# CPU and memory
kubectl top pods -l app=pt-app --sort-by=cpu
kubectl top pods -l app=pt-app --sort-by=memory

# Connection pool scaling
curl http://metrics/rust_connection_pool_size
curl http://metrics/rust_connection_pool_utilization

# Tier health
curl http://metrics/tier_health_status
```

#### Step 2.3: Load Testing (Day 5)

**Validate burst handling:**
```bash
# Run load test at 50% above current traffic
python3 scripts/load_test.py \
  --target-qps 637 \
  --duration 3600 \
  --spike-multiplier 1.5 \
  --spike-duration 300

# Expected results:
# - Latency P95 < 0.060ms during burst
# - Connection pool scales to ~30-40 connections
# - No tier failures
# - Error rate < 0.2%
```

#### Step 2.4: Success Criteria (Day 7)

- ✅ Latency P95 ≤ 0.055ms
- ✅ Throughput ≥ 425 qps
- ✅ CPU usage < 60%, memory < 70%
- ✅ Connection pool auto-scaling working (10-50 range)
- ✅ Routing percentage ≥ 55%
- ✅ All 4 tiers healthy
- ✅ Successful burst handling
- ✅ Zero SEV-1 incidents

---

### Phase 3: Ramp to 50% (Week 3)

**Duration:** 7 days
**Traffic:** 25% → 50% progressive ramp
**Goal:** Validate under heavy production load

#### Step 3.1: Ramp Traffic (Day 1-3)

```bash
# Day 1: 25% → 35%
flags.set_percentage("wave2_rust_optimizations", 35.0)

# Day 2: 35% → 45%
flags.set_percentage("wave2_rust_optimizations", 45.0)

# Day 3: 45% → 50%
flags.set_percentage("wave2_rust_optimizations", 50.0)
```

#### Step 3.2: Monitor Heavy Load Metrics

```yaml
rust_performance:
  latency_p95_ms:
    target: "< 0.060"
    p99: "< 0.065"
    alert_threshold: "> 0.070"

  throughput_qps:
    target: "> 850"  # 50% of 1,700
    sustained: "> 800"
    alert_threshold: "< 750"

connection_pool:
  active_connections:
    expected_range: "30-60"
    max_allowed: 100

  pool_utilization:
    target: "70-85%"
    alert_threshold: "> 90%"

tier_health:
  all_tiers_healthy: true
  minio_latency_ms: "< 100"
  athena_latency_ms: "< 200"
```

#### Step 3.3: Database Tier Health Validation

**Verify all tiers handling load:**
```bash
# Tier-specific health checks
python3 scripts/check_tier_health.py --detailed

# Expected output:
# Tier 1 (Master):
#   Status: healthy
#   Latency P95: 8ms
#   Query rate: 340 qps (40% of 850)
#
# Tier 2 (PGVector):
#   Status: healthy
#   Latency P95: 15ms
#   Query rate: 170 qps (20% of 850)
#
# Tier 3 (MinIO):
#   Status: healthy
#   Latency P95: 85ms
#   Query rate: 170 qps (20% of 850)
#   Cache hit rate: 75%
#
# Tier 4 (Athena):
#   Status: healthy
#   Latency P95: 180ms
#   Query rate: 170 qps (20% of 850)
#   Avg cost: $0.002 per query
```

#### Step 3.4: Capacity Testing (Day 5)

**Test 2x sustained load:**
```bash
# 2x load test (1,700 qps total, 850 qps on Wave 2)
python3 scripts/capacity_test.py \
  --target-qps 850 \
  --duration 7200 \
  --ramp-up-seconds 300

# Validate auto-scaling
# - Connection pool should scale to 60-80 connections
# - All tiers remain healthy
# - Latency stays within bounds
# - No error rate increase
```

#### Step 3.5: Success Criteria (Day 7)

- ✅ Latency P95 ≤ 0.060ms (sustained)
- ✅ Throughput ≥ 850 qps (sustained)
- ✅ Connection pool scaling validated (30-60 connections)
- ✅ All 4 tiers healthy under load
- ✅ Routing percentage ≥ 58%
- ✅ 2x capacity test passed
- ✅ Zero SEV-1 incidents

---

### Phase 4: Full Rollout (100%, Week 4)

**Duration:** 7 days minimum
**Traffic:** 50% → 100% progressive ramp
**Goal:** Full production deployment

#### Step 4.1: Ramp to 100% (Day 1-3)

```bash
# Day 1: 50% → 70%
flags.set_percentage("wave2_rust_optimizations", 70.0)

# Day 2: 70% → 85%
flags.set_percentage("wave2_rust_optimizations", 85.0)

# Day 3: 85% → 100%
flags.set_percentage("wave2_rust_optimizations", 100.0)
```

#### Step 4.2: Monitor Full Production Load

```yaml
rust_performance:
  latency_p95_ms:
    target: "< 0.052"  # Full Wave 2 baseline
    p99: "< 0.055"
    p99_9: "< 0.058"

  throughput_qps:
    target: "> 1700"
    sustained: "> 1650"

  speedup_vs_python:
    target: "> 10x"

tier_routing:
  routing_percentage:
    target: "> 60%"  # Full Wave 2 target

  tier_distribution:
    master: "40%"
    pgvector: "20%"
    minio: "20%"
    athena: "20%"

resources:
  cpu_usage_pct: "< 75%"
  memory_usage_pct: "< 80%"
  connection_pool_size: "60-100"
  connection_pool_utilization: "75-85%"
```

#### Step 4.3: Full Performance Validation (Day 4-7)

**Comprehensive benchmark suite:**
```bash
# 1. Latency benchmarks
python3 scripts/benchmark_latency.py --production --duration 3600

# 2. Throughput benchmarks
python3 scripts/benchmark_throughput.py --production --duration 3600

# 3. Tier routing validation
python3 scripts/validate_tier_routing.py --production

# 4. Comparison to baselines
python3 scripts/compare_to_baselines.py \
  --wave1-baseline .outcomes/wave1_benchmark_results.json \
  --wave2-baseline .outcomes/wave2_benchmark_results.json \
  --production-current

# Expected results:
# Wave 1 → Wave 2 Improvements:
# - Latency: 0.082ms → 0.052ms (37% faster) ✅
# - Throughput: 850 qps → 1,700 qps (2x) ✅
# - Routing: 42% → 60% (+43%) ✅
```

#### Step 4.4: Stability Validation (Day 7)

**7-day stability check:**
- ✅ Zero SEV-1 incidents over 7 days
- ✅ Error rate < 0.1% consistently
- ✅ Performance within 5% of targets
- ✅ No resource exhaustion events
- ✅ All tier health checks passing
- ✅ No user-reported performance issues

#### Step 4.5: Make Default (Day 8+)

```bash
# Remove feature flags - make Wave 2 the default
cat > /production/config/default.yaml <<EOF
rust_primitives:
  enabled: true
  use_v2: true  # Wave 2 is now default

tier_router:
  enabled: true
  tier3_enabled: true  # MinIO
  tier4_enabled: true  # Athena
EOF

# Remove feature flag dependencies
git commit -m "feat: Make Wave 2 optimizations default"
```

---

## Health Check Procedures

### Automated Health Checks

#### Rust Performance Health Check

```python
#!/usr/bin/env python3
"""
Automated health check for Rust Wave 2 performance.
Run every 5 minutes via cron or monitoring system.
"""

import requests
import sys

def check_rust_health():
    """Check Rust Wave 2 performance metrics."""

    metrics = requests.get("http://localhost:9090/metrics").text

    # Parse metrics
    latency_p95 = float(extract_metric(metrics, "rust_latency_p95_ms"))
    throughput = float(extract_metric(metrics, "rust_throughput_qps"))
    error_rate = float(extract_metric(metrics, "rust_error_rate"))
    pool_size = int(extract_metric(metrics, "rust_connection_pool_size"))

    # Validate thresholds
    issues = []

    if latency_p95 > 0.065:
        issues.append(f"HIGH_LATENCY: {latency_p95}ms (threshold: 0.065ms)")

    if throughput < 1600:
        issues.append(f"LOW_THROUGHPUT: {throughput} qps (threshold: 1600 qps)")

    if error_rate > 0.001:
        issues.append(f"HIGH_ERROR_RATE: {error_rate*100}% (threshold: 0.1%)")

    if pool_size > 95:
        issues.append(f"POOL_EXHAUSTION: {pool_size}/100 connections")

    if issues:
        print(f"UNHEALTHY: {', '.join(issues)}")
        return 1
    else:
        print(f"HEALTHY: latency={latency_p95}ms, throughput={throughput}qps")
        return 0

if __name__ == "__main__":
    sys.exit(check_rust_health())
```

#### Tier Routing Health Check

```python
#!/usr/bin/env python3
"""
Automated health check for tier routing system.
Run every 1 minute via cron or monitoring system.
"""

import sys
from zones.z07_data_access.tier_health_monitor import TierHealthMonitor

def check_tier_health():
    """Check all tier health status."""

    monitor = TierHealthMonitor()
    health = monitor.get_health_summary()

    # Check overall status
    if health['overall_status'] != 'healthy':
        print(f"UNHEALTHY: {health['unavailable_count']} tiers down")
        for tier, status in health['tier_health'].items():
            if not status['available']:
                print(f"  - {tier}: {status['status']} ({status.get('error', 'N/A')})")
        return 1

    # Check routing percentage
    router_metrics = get_router_metrics()
    if router_metrics['routing_percentage'] < 50:
        print(f"LOW_ROUTING: {router_metrics['routing_percentage']}% (threshold: 50%)")
        return 1

    print(f"HEALTHY: {health['available_count']}/{health['total_tiers']} tiers available, "
          f"{router_metrics['routing_percentage']}% routing")
    return 0

if __name__ == "__main__":
    sys.exit(check_tier_health())
```

### Manual Health Check Procedures

#### Quick Status Check (2 minutes)

```bash
#!/bin/bash
# Quick health status check

echo "=== Wave 2 Quick Health Check ==="

# 1. Rust performance
echo -e "\n[Rust Performance]"
curl -s http://localhost:9090/metrics | grep -E "rust_(latency|throughput|error)"

# 2. Tier routing
echo -e "\n[Tier Routing]"
curl -s http://localhost:9090/metrics | grep -E "tier_(routing|distribution|health)"

# 3. Resource usage
echo -e "\n[Resource Usage]"
kubectl top pods -l app=pt-app | head -5

# 4. Recent errors
echo -e "\n[Recent Errors (last 5 min)]"
tail -n 100 /var/log/pt-app/errors.log | grep -i "wave2\|rust\|tier" | tail -10
```

#### Detailed Health Check (10 minutes)

```bash
#!/bin/bash
# Comprehensive health validation

echo "=== Wave 2 Comprehensive Health Check ==="

# 1. Run automated tests
echo -e "\n[Running Test Suite]"
python3 -m pytest tests/test_wave2_health.py -v

# 2. Performance benchmarks
echo -e "\n[Performance Benchmarks]"
python3 scripts/quick_benchmark.py --duration 60

# 3. Tier-by-tier health
echo -e "\n[Tier Health Details]"
python3 scripts/check_tier_health.py --detailed

# 4. Compare to baselines
echo -e "\n[Baseline Comparison]"
python3 scripts/compare_to_baselines.py --quick

# 5. Check for anomalies
echo -e "\n[Anomaly Detection]"
python3 scripts/detect_anomalies.py --lookback 3600
```

---

## Rollback Procedures

### Emergency Rollback (<5 Minutes)

**CRITICAL: Use for SEV-1 incidents only**

#### Option 1: Feature Flag Disable (Fastest - 30 seconds)

```bash
# Instant disable via feature flags
python3 <<EOF
from config.feature_flags import FeatureFlags
flags = FeatureFlags()
flags.set_percentage("wave2_rust_optimizations", 0.0)
flags.set_percentage("wave2_tier_routing", 0.0)
flags.commit()
print("✅ Wave 2 disabled via feature flags")
EOF

# Verify rollback
curl http://localhost:9090/metrics | grep wave2_enabled
# Should show: wave2_enabled 0
```

#### Option 2: Environment Variable Disable (2 minutes)

```bash
# Disable via environment variables
kubectl set env deployment/pt-app \
  RUST_PRIMITIVES_USE_V2=false \
  ENABLE_TIER3=false \
  ENABLE_TIER4=false

# Rolling restart
kubectl rollout restart deployment/pt-app
kubectl rollout status deployment/pt-app --timeout=120s

# Verify Wave 1 is active
curl http://localhost:9090/metrics | grep rust_version
# Should show: rust_version{version="v1"} 1
```

#### Option 3: Code Revert (5 minutes)

```bash
# Revert to Wave 1 deployment
git revert <wave2-commit-hash> --no-edit
git push origin main

# Trigger deployment
kubectl set image deployment/pt-app \
  pt-app=<wave1-image-tag>

# Wait for rollout
kubectl rollout status deployment/pt-app --timeout=300s

# Verify
kubectl exec -it deploy/pt-app -- python3 -c \
  "from rust_primitives import __version__; print(__version__)"
# Should show: 1.0.0 (Wave 1)
```

### Rollback Validation

**After any rollback, validate:**

```bash
# 1. Performance returned to Wave 1 baseline
python3 scripts/validate_wave1_baseline.py

# Expected output:
# ✅ Latency P95: 0.082ms (Wave 1 baseline)
# ✅ Throughput: 850 qps (Wave 1 baseline)
# ✅ Routing: 42% (Wave 1 baseline)
# ✅ Error rate: <0.1%

# 2. No data loss
python3 scripts/verify_data_integrity.py --last-hour

# 3. All services healthy
kubectl get pods -l app=pt-app
# All pods should be Running
```

### Partial Rollback Scenarios

#### Rollback Rust Only (Keep Tier Routing)

```bash
# Disable Rust Wave 2, keep tier routing Wave 2
export RUST_PRIMITIVES_USE_V2=false
export ENABLE_TIER3=true  # Keep MinIO
export ENABLE_TIER4=true  # Keep Athena

kubectl rollout restart deployment/pt-app
```

#### Rollback Tier Routing Only (Keep Rust Wave 2)

```bash
# Keep Rust Wave 2, disable tier routing Wave 2
export RUST_PRIMITIVES_USE_V2=true
export ENABLE_TIER3=false  # Disable MinIO
export ENABLE_TIER4=false  # Disable Athena

kubectl rollout restart deployment/pt-app
```

---

## Communication Templates

### Phase Start Announcement

**Subject:** Wave 2 Deployment - Phase X Starting

```
Team,

We are beginning Phase X of the Wave 2 performance optimization rollout.

Phase Details:
- Start Date: YYYY-MM-DD HH:MM UTC
- Duration: 7 days
- Traffic: X% → Y%
- Expected Impact: [Performance improvements]

Monitoring:
- Dashboard: https://grafana.example.com/wave2
- Alerts: #wave2-deployment Slack channel
- On-call: [Engineer name]

Success Criteria:
- [List key metrics]

Rollback Plan:
- Instant rollback via feature flags: <30 seconds
- Contact: [Engineer] or #wave2-deployment

Questions? Reply to this thread or ask in #wave2-deployment.

Thanks,
[Agent 12 - Production Deployment Engineer]
```

### Daily Status Update

**Subject:** Wave 2 Deployment - Phase X Day Y Status

```
Wave 2 Phase X - Day Y Status Report

Traffic: [Current %]

Performance Metrics (Last 24h):
✅ Latency P95: X.XXXms (target: < X.XXXms)
✅ Throughput: XXXX qps (target: > XXXX qps)
✅ Error Rate: X.XX% (target: < 0.1%)
✅ Routing: XX% (target: > XX%)

Tier Health:
✅ Master: Healthy
✅ PGVector: Healthy
✅ MinIO: Healthy
✅ Athena: Healthy

Incidents: [None | List any]

Next Steps:
- [What happens next]

On-call: [Engineer]
```

### Rollback Notification

**Subject:** URGENT: Wave 2 Rollback Initiated

```
URGENT: Wave 2 Rollback in Progress

Reason: [Brief description of issue]
Severity: SEV-[1|2]
Started: YYYY-MM-DD HH:MM UTC
Method: [Feature flag | Environment variable | Code revert]

Current Status:
- Rollback initiated: HH:MM UTC
- Expected completion: HH:MM UTC (within 5 minutes)
- Traffic on Wave 1: [Percentage increasing]

Impact:
- User impact: [None expected | Describe]
- Data impact: None (verified)

Actions:
- [Engineer] executing rollback
- [Engineer] monitoring restoration
- [Engineer] investigating root cause

Updates will be posted every 5 minutes until resolved.

War room: #wave2-incident
```

### Phase Completion Announcement

**Subject:** Wave 2 Deployment - Phase X Complete ✅

```
Team,

Phase X of Wave 2 deployment is complete!

Results:
✅ All success criteria met
✅ Zero SEV-1 incidents
✅ Performance exceeds targets
  - Latency: X.XXXms (XX% better than baseline)
  - Throughput: XXXX qps (XX% better than baseline)
  - Routing: XX% to optimal tiers

Traffic:
- Started: X%
- Ended: X%
- Stable for: 7 days

Next Steps:
- Phase [X+1] starts: YYYY-MM-DD
- Preparation period: [Duration]
- Go/no-go meeting: YYYY-MM-DD HH:MM UTC

Kudos to the team for a smooth rollout!

[Agent 12]
```

---

## Troubleshooting Guide

### Issue: High Latency Spike

**Symptoms:**
- Latency P95 > 0.070ms
- User complaints about slow queries
- Alerts firing

**Diagnosis:**
```bash
# 1. Check current latency distribution
curl http://localhost:9090/metrics | grep rust_latency_p

# 2. Check connection pool utilization
curl http://localhost:9090/metrics | grep rust_connection_pool

# 3. Check database tier health
python3 scripts/check_tier_health.py --detailed

# 4. Check for slow queries
psql -c "SELECT pid, query, state, wait_event
         FROM pg_stat_activity
         WHERE state = 'active' AND query_start < NOW() - INTERVAL '1 second';"
```

**Resolution:**
```bash
# If connection pool exhausted:
# Increase max pool size temporarily
kubectl set env deployment/pt-app RUST_POOL_SIZE_MAX=150

# If tier is degraded:
# Health monitor will auto-failover, but can manually disable:
export ENABLE_TIER3=false  # If MinIO is slow

# If widespread issue:
# Rollback (see Rollback Procedures)
python3 scripts/emergency_rollback.py --reason "high_latency"
```

### Issue: Throughput Below Target

**Symptoms:**
- Throughput < 1,600 qps
- Requests queuing
- Timeout errors

**Diagnosis:**
```bash
# 1. Check request queue depth
curl http://localhost:9090/metrics | grep request_queue_depth

# 2. Check CPU/memory utilization
kubectl top pods -l app=pt-app

# 3. Check async engine concurrency
curl http://localhost:9090/metrics | grep rust_concurrent_queries

# 4. Check for bottlenecks
python3 scripts/profile_bottlenecks.py --duration 60
```

**Resolution:**
```bash
# Increase async concurrency:
kubectl set env deployment/pt-app RUST_MAX_CONCURRENT_QUERIES=150

# Scale horizontally:
kubectl scale deployment/pt-app --replicas=10

# If at capacity limits:
# Consider early scale-up or rollback
```

### Issue: Tier Routing Below 50%

**Symptoms:**
- `routing_percentage < 50%`
- Most queries going to Master
- Tier 3/4 not being used

**Diagnosis:**
```bash
# 1. Check tier enablement
cat /production/config/tier_router_config.yaml | grep enabled

# 2. Check tier health
python3 -c "
from zones.z07_data_access.tier_health_monitor import TierHealthMonitor
monitor = TierHealthMonitor()
print(monitor.get_health_summary())
"

# 3. Check feature flags
curl http://localhost:9090/metrics | grep tier_enabled
```

**Resolution:**
```bash
# Ensure tiers are enabled:
export ENABLE_TIER3=true
export ENABLE_TIER4=true

# Check tier connectivity:
python3 scripts/test_tier_connectivity.py

# Restart health monitor:
python3 scripts/restart_health_monitor.py
```

### Issue: Memory Leak Suspected

**Symptoms:**
- Memory usage climbing over time
- OOMKilled pods
- Performance degrading

**Diagnosis:**
```bash
# 1. Check memory trend
kubectl top pods -l app=pt-app --sort-by=memory

# 2. Profile memory usage
python3 scripts/profile_memory.py --duration 300

# 3. Check for leaked connections
psql -c "SELECT count(*) FROM pg_stat_activity WHERE application_name LIKE 'rust%';"

# 4. Check cache sizes
curl http://localhost:9090/metrics | grep cache_size
```

**Resolution:**
```bash
# Reduce cache sizes if needed:
kubectl set env deployment/pt-app \
  RUST_PREPARED_STMT_CACHE_SIZE=50 \
  MINIO_CACHE_MAX_ENTRIES=50

# Restart pods with memory leak:
kubectl delete pods -l app=pt-app --grace-period=30

# If persistent:
# Rollback and investigate
python3 scripts/emergency_rollback.py --reason "memory_leak"
```

---

## Appendix

### Critical Metrics Summary

| Metric | Wave 1 | Wave 2 Target | Alert Threshold |
|--------|--------|---------------|-----------------|
| Latency P95 | 0.082ms | < 0.052ms | > 0.065ms |
| Latency P99 | 0.089ms | < 0.055ms | > 0.070ms |
| Throughput | 850 qps | > 1,700 qps | < 1,600 qps |
| Error Rate | < 0.1% | < 0.1% | > 0.5% |
| Routing % | 42% | > 60% | < 50% |
| Routing Overhead | 0.42ms | < 0.0018ms | > 0.005ms |

### Emergency Contacts

```yaml
primary_oncall:
  role: "Production Deployment Engineer"
  contact: "Agent 12"
  slack: "@agent12"

backup_oncall:
  role: "Rust Performance Engineer"
  contact: "Agent 9"
  slack: "@agent9"

escalation:
  role: "Tier Integration Engineer"
  contact: "Agent 10"
  slack: "@agent10"

incident_channel: "#wave2-deployment"
war_room_channel: "#wave2-incident"
```

### Useful Commands Reference

```bash
# Quick status
curl http://localhost:9090/metrics | grep -E "wave2|rust|tier"

# Feature flag disable
python3 -c "from config.feature_flags import FeatureFlags; \
  FeatureFlags().set_percentage('wave2_rust_optimizations', 0.0)"

# Environment variable disable
kubectl set env deployment/pt-app RUST_PRIMITIVES_USE_V2=false

# Check rollout status
kubectl rollout status deployment/pt-app

# View logs
kubectl logs -l app=pt-app --tail=100 -f | grep -i "wave2\|error"

# Run health check
python3 scripts/wave2_health_check.py

# Emergency rollback
python3 scripts/emergency_rollback.py --confirm
```

---

**Document Version:** 1.0
**Last Updated:** 2025-12-06
**Next Review:** After Phase 4 completion
**Owner:** Agent 12 - Production Deployment Engineer
