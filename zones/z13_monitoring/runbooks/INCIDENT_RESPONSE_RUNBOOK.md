# Wave 1 Foundation - Incident Response Runbook

**Version:** 1.0
**Last Updated:** 2025-12-06
**Maintainer:** Platform Team

---

## Quick Reference

### Emergency Contacts

| Role | Contact | Escalation Time |
|------|---------|-----------------|
| On-Call Engineer | PagerDuty | Immediate |
| Database Team | #db-team | 5 minutes |
| Platform Lead | #platform-leads | 10 minutes |
| VP Engineering | Phone | 30 minutes |

### Emergency Rollback Command

```bash
# ONE-LINE ROLLBACK (copy-paste ready)
export RUST_PRIMITIVES_ENABLED=false TIER_ROUTER_ENABLED=false && systemctl restart application && curl http://application:9092/health
```

**Rollback Time:** <5 minutes
**Impact:** Returns to Python baseline (8x slower but stable)

---

## Incident Classification

### Severity Levels

| Severity | Definition | Response Time | Examples |
|----------|------------|---------------|----------|
| **SEV-1** | Service down, major user impact | Immediate | >50% error rate, service unreachable |
| **SEV-2** | Degraded performance, partial impact | 5 minutes | >10% latency increase, >1% errors |
| **SEV-3** | Minor degradation, limited impact | 15 minutes | Cache hit rate low, elevated latency |
| **SEV-4** | No user impact, monitoring only | 1 hour | Single metric warning |

### Decision Tree

```
Is service responding?
├── NO → SEV-1: Execute emergency rollback
└── YES
    ├── Error rate >10%? → SEV-1: Execute emergency rollback
    ├── Error rate >1%? → SEV-2: Investigate and mitigate
    ├── Latency >2x baseline? → SEV-2: Investigate and mitigate
    └── Single metric warning? → SEV-3/4: Monitor and investigate
```

---

## SEV-1: Service Down / Critical

### Immediate Actions (First 5 Minutes)

#### Step 1: Verify Incident (30 seconds)

```bash
# Quick health check
curl http://application:9092/health

# Check key metrics
curl http://application:9092/metrics | grep -E "error_rate|latency_p95|up"

# Check recent alerts
curl http://prometheus:9090/api/v1/alerts | jq '.data.alerts[] | select(.state == "firing")'
```

**Decision Point:**
- If service down or >50% errors → Execute emergency rollback immediately
- If service degraded but functional → Proceed to Step 2

#### Step 2: Execute Emergency Rollback (2 minutes)

```bash
#!/bin/bash
# emergency_rollback.sh

echo "=== STARTING EMERGENCY ROLLBACK ==="
echo "Time: $(date)"

# Disable Wave 1 components
export RUST_PRIMITIVES_ENABLED=false
export TIER_ROUTER_ENABLED=false

# Restart service
echo "Restarting application..."
systemctl restart application

# Wait for service to start
sleep 10

# Verify health
echo "Verifying health..."
HEALTH=$(curl -s http://application:9092/health | jq -r .status)

if [ "$HEALTH" == "healthy" ]; then
  echo "✓ Rollback successful"
  echo "✓ Service healthy"
  echo "✓ Wave 1 disabled (Python baseline active)"
else
  echo "✗ Rollback failed - service still unhealthy"
  echo "ESCALATE IMMEDIATELY"
  exit 1
fi

# Verify metrics stabilizing
echo "Monitoring metrics for 60 seconds..."
for i in {1..6}; do
  ERROR_RATE=$(curl -s http://application:9092/metrics | grep wave1_errors_total | awk '{sum+=$2} END {print sum}')
  echo "[$i/6] Error count: $ERROR_RATE"
  sleep 10
done

echo "=== ROLLBACK COMPLETE ==="
echo "Time: $(date)"
```

**Expected Output:**
```
=== STARTING EMERGENCY ROLLBACK ===
Time: 2025-12-06 10:15:30
Restarting application...
Verifying health...
✓ Rollback successful
✓ Service healthy
✓ Wave 1 disabled (Python baseline active)
Monitoring metrics for 60 seconds...
[1/6] Error count: 0
[2/6] Error count: 0
[3/6] Error count: 0
[4/6] Error count: 0
[5/6] Error count: 0
[6/6] Error count: 0
=== ROLLBACK COMPLETE ===
Time: 2025-12-06 10:17:45
```

#### Step 3: Notify Stakeholders (1 minute)

```bash
#!/bin/bash
# notify_incident.sh

INCIDENT_TIME=$(date)
INCIDENT_SEVERITY="SEV-1"
INCIDENT_STATUS="Rollback executed"

# Slack notification
curl -X POST ${SLACK_WEBHOOK_URL} \
  -H 'Content-Type: application/json' \
  -d '{
    "channel": "#incidents",
    "username": "Incident Bot",
    "icon_emoji": ":rotating_light:",
    "attachments": [{
      "color": "danger",
      "title": "SEV-1 Incident: Wave 1 Rollback",
      "fields": [
        {"title": "Time", "value": "'"${INCIDENT_TIME}"'", "short": true},
        {"title": "Severity", "value": "SEV-1", "short": true},
        {"title": "Status", "value": "'"${INCIDENT_STATUS}"'", "short": false},
        {"title": "Action", "value": "Emergency rollback executed. Wave 1 disabled.", "short": false},
        {"title": "Impact", "value": "Service stable on Python baseline (8x slower)", "short": false}
      ],
      "actions": [
        {"type": "button", "text": "View Dashboard", "url": "https://grafana/d/wave1"},
        {"type": "button", "text": "View Runbook", "url": "https://docs/runbooks/wave1"}
      ]
    }]
  }'

# PagerDuty incident
curl -X POST https://api.pagerduty.com/incidents \
  -H "Authorization: Token token=${PAGERDUTY_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "incident": {
      "type": "incident",
      "title": "SEV-1: Wave 1 Emergency Rollback",
      "service": {"id": "'"${PAGERDUTY_SERVICE_ID}"'", "type": "service_reference"},
      "urgency": "high",
      "body": {
        "type": "incident_body",
        "details": "Wave 1 components disabled due to critical issues. Service running on Python baseline."
      }
    }
  }'

# Status page update
curl -X POST ${STATUS_PAGE_API}/incidents \
  -d '{
    "name": "Performance Degradation",
    "status": "investigating",
    "message": "We are experiencing performance issues and have temporarily disabled optimization features. Service is operational but may be slower than usual.",
    "component_ids": ["wave1"]
  }'
```

#### Step 4: Post-Rollback Verification (5 minutes)

```bash
#!/bin/bash
# verify_rollback.sh

echo "=== POST-ROLLBACK VERIFICATION ==="

# 1. Check service health
echo "[1/5] Checking service health..."
HEALTH=$(curl -s http://application:9092/health)
echo "$HEALTH" | jq .

# 2. Check error rate
echo "[2/5] Checking error rate..."
ERROR_RATE=$(curl -s http://prometheus:9090/api/v1/query?query='rate(wave1_errors_total[5m])' | jq -r '.data.result[0].value[1]')
echo "Error rate: $ERROR_RATE errors/sec"

# 3. Check latency
echo "[3/5] Checking latency..."
P95_LATENCY=$(curl -s http://prometheus:9090/api/v1/query?query='histogram_quantile(0.95, rate(wave1_end_to_end_latency_bucket[5m]))' | jq -r '.data.result[0].value[1]')
echo "P95 latency: $P95_LATENCY ms"

# 4. Check Wave 1 components disabled
echo "[4/5] Verifying Wave 1 disabled..."
RUST_ENABLED=$(curl -s http://application:9092/config | jq -r .rust_primitives.enabled)
ROUTER_ENABLED=$(curl -s http://application:9092/config | jq -r .tier_router.enabled)
echo "Rust enabled: $RUST_ENABLED (expected: false)"
echo "Router enabled: $ROUTER_ENABLED (expected: false)"

# 5. Check active alerts
echo "[5/5] Checking active alerts..."
FIRING_ALERTS=$(curl -s http://prometheus:9090/api/v1/alerts | jq -r '.data.alerts[] | select(.state == "firing") | .labels.alertname')
if [ -z "$FIRING_ALERTS" ]; then
  echo "No firing alerts ✓"
else
  echo "WARNING: Still firing alerts:"
  echo "$FIRING_ALERTS"
fi

echo "=== VERIFICATION COMPLETE ==="
```

**Success Criteria:**
- ✅ Service health: "healthy"
- ✅ Error rate: <0.1%
- ✅ P95 latency: Stable (higher than Wave 1 but predictable)
- ✅ Wave 1 components: Disabled
- ✅ No firing alerts

### Investigation Phase (Next 30 Minutes)

#### 1. Collect Logs

```bash
# Application logs (last 1 hour)
journalctl -u application --since "1 hour ago" > /tmp/incident-app-logs.txt

# Rust service logs
journalctl -u rust-primitives --since "1 hour ago" > /tmp/incident-rust-logs.txt

# Tier router logs
journalctl -u tier-router --since "1 hour ago" > /tmp/incident-router-logs.txt

# Database logs
psql -c "COPY (SELECT * FROM pg_log WHERE log_time > NOW() - INTERVAL '1 hour') TO '/tmp/incident-db-logs.csv' CSV HEADER;"

# Compress and archive
tar -czf incident-$(date +%Y%m%d-%H%M%S).tar.gz /tmp/incident-*.txt /tmp/incident-*.csv
```

#### 2. Analyze Root Cause

**Common Root Causes:**

| Symptom | Likely Root Cause | Investigation |
|---------|-------------------|---------------|
| Service won't start | Configuration error | Check config files, environment variables |
| Immediate crashes | Code bug, resource exhaustion | Check error logs, core dumps |
| Gradual degradation | Memory leak, connection pool exhaustion | Check memory, connections over time |
| Sudden spike | Traffic surge, DDoS | Check request rates, sources |
| Database errors | Schema change, locks, connection limits | Check database logs, active queries |

**Investigation Script:**

```bash
#!/bin/bash
# investigate_root_cause.sh

echo "=== ROOT CAUSE INVESTIGATION ==="

# Check recent deploys
echo "[1/8] Recent deployments:"
git log --since="24 hours ago" --oneline

# Check configuration changes
echo "[2/8] Recent config changes:"
git log --since="24 hours ago" -- config/ zones/z13_monitoring/

# Check error patterns
echo "[3/8] Top error messages:"
grep -i error /tmp/incident-app-logs.txt | sort | uniq -c | sort -nr | head -10

# Check resource usage at time of incident
echo "[4/8] Resource usage:"
free -h
df -h
uptime

# Check database health
echo "[5/8] Database health:"
psql -c "SELECT * FROM pg_stat_activity WHERE state != 'idle' LIMIT 20;"
psql -c "SELECT * FROM pg_stat_database WHERE datname = 'sapphire';"

# Check network connectivity
echo "[6/8] Network connectivity:"
ping -c 5 ${DB_HOST}
netstat -an | grep ${DB_PORT} | wc -l

# Check Rust service health
echo "[7/8] Rust service health:"
curl http://rust-primitives:9090/health || echo "Rust service unreachable"

# Check recent alerts
echo "[8/8] Recent alerts (last 2 hours):"
curl -s http://prometheus:9090/api/v1/query?query='ALERTS{wave="wave1",alertstate="firing"}[2h]' | jq .

echo "=== INVESTIGATION COMPLETE ==="
```

#### 3. Create Incident Timeline

```markdown
# Incident Timeline Template

## Incident ID: INC-20251206-001
## Severity: SEV-1
## Status: Resolved (Rolled Back)

### Timeline

**10:00 AM** - Normal operations, all metrics green
**10:05 AM** - First warning alert: Rust latency elevated
**10:07 AM** - Critical alert: Rust fallback storm (>5%)
**10:08 AM** - Critical alert: High error rate (>10%)
**10:10 AM** - On-call engineer paged
**10:12 AM** - Investigation started
**10:15 AM** - Decision made to rollback
**10:15 AM** - Emergency rollback executed
**10:17 AM** - Service stable on Python baseline
**10:18 AM** - Stakeholders notified
**10:20 AM** - Verification complete
**10:25 AM** - Root cause investigation started

### Root Cause

[To be filled after investigation]

### Impact

- Duration: 17 minutes (10:00 AM - 10:17 AM)
- Affected users: ~X% (estimate)
- Error rate peak: X%
- Services impacted: Wave 1 components only
- Data loss: None
- Rollback: Successful, stable on Python baseline

### Action Items

- [ ] Fix root cause issue
- [ ] Add monitoring to prevent recurrence
- [ ] Update runbook with learnings
- [ ] Schedule postmortem
- [ ] Plan re-enable strategy
```

---

## SEV-2: Degraded Performance

### Response Actions (First 10 Minutes)

#### Step 1: Assess Severity (2 minutes)

```bash
# Check key metrics
curl -s http://prometheus:9090/api/v1/query?query='rate(wave1_errors_total[5m])' | jq -r '.data.result[0].value[1]'
# Error rate threshold: >1% = SEV-2, >10% = escalate to SEV-1

curl -s http://prometheus:9090/api/v1/query?query='histogram_quantile(0.95, rate(wave1_end_to_end_latency_bucket[5m]))' | jq -r '.data.result[0].value[1]'
# Latency threshold: >2ms = SEV-2, >5ms = escalate to SEV-1

# Check alert state
curl -s http://prometheus:9090/api/v1/alerts | jq '.data.alerts[] | select(.state == "firing") | {alert: .labels.alertname, severity: .labels.severity}'
```

**Decision Points:**
- Error rate >10% OR Latency >5ms → **Escalate to SEV-1**
- Multiple critical alerts → **Escalate to SEV-1**
- Single component degraded → **Continue SEV-2 response**

#### Step 2: Identify Component (3 minutes)

```bash
#!/bin/bash
# identify_degraded_component.sh

echo "=== COMPONENT HEALTH CHECK ==="

# Rust Primitives
echo "[1/3] Rust Primitives:"
RUST_LATENCY=$(curl -s http://prometheus:9090/api/v1/query?query='histogram_quantile(0.95, rate(rust_primitives_latency_bucket[5m]))' | jq -r '.data.result[0].value[1]')
RUST_FALLBACK=$(curl -s http://prometheus:9090/api/v1/query?query='rate(rust_primitives_fallback_total[5m]) / rate(rust_primitives_requests_total[5m]) * 100' | jq -r '.data.result[0].value[1]')
echo "  Latency P95: ${RUST_LATENCY}ms (baseline: 0.082ms, target: <0.1ms)"
echo "  Fallback rate: ${RUST_FALLBACK}% (baseline: <0.1%, target: <1%)"

# Tier Router
echo "[2/3] Tier Router:"
ROUTER_OVERHEAD=$(curl -s http://prometheus:9090/api/v1/query?query='histogram_quantile(0.95, rate(tier_router_overhead_bucket[5m]))' | jq -r '.data.result[0].value[1]')
ROUTER_ROUTING=$(curl -s http://prometheus:9090/api/v1/query?query='sum(rate(tier_router_queries_by_tier{tier!="master_tables"}[5m])) / sum(rate(tier_router_queries_by_tier[5m])) * 100' | jq -r '.data.result[0].value[1]')
echo "  Overhead P95: ${ROUTER_OVERHEAD}ms (baseline: 0.55ms, target: <1ms)"
echo "  Routing %: ${ROUTER_ROUTING}% (baseline: 42%, target: >30%)"

# System
echo "[3/3] System:"
SYSTEM_LATENCY=$(curl -s http://prometheus:9090/api/v1/query?query='histogram_quantile(0.95, rate(wave1_end_to_end_latency_bucket[5m]))' | jq -r '.data.result[0].value[1]')
SYSTEM_ERRORS=$(curl -s http://prometheus:9090/api/v1/query?query='rate(wave1_errors_total[5m]) / rate(wave1_queries_total[5m]) * 100' | jq -r '.data.result[0].value[1]')
echo "  Latency P95: ${SYSTEM_LATENCY}ms (baseline: 0.85ms, target: <2ms)"
echo "  Error rate: ${SYSTEM_ERRORS}% (baseline: 0%, target: <0.1%)"

echo "=== COMPONENT IDENTIFICATION COMPLETE ==="
```

#### Step 3: Apply Targeted Mitigation (5 minutes)

**Mitigation Options by Component:**

##### Rust Primitives Degraded

```bash
# Option 1: Clear and warm up cache
curl -X POST http://rust-primitives:9090/cache/clear
curl -X POST http://rust-primitives:9090/cache/warmup

# Option 2: Increase connection pool
curl -X POST http://rust-primitives:9090/config \
  -d '{"connection_pool_size": 50}'  # From 20
systemctl restart rust-primitives

# Option 3: Disable Rust only (keep router)
export RUST_PRIMITIVES_ENABLED=false
systemctl restart application
# Monitor for improvement
```

##### Tier Router Degraded

```bash
# Option 1: Simplify routing rules
curl -X POST http://tier-router:9091/config \
  -d '{"use_ml_classification": false}'  # Use simple rules only
systemctl restart tier-router

# Option 2: Increase routing timeouts
curl -X POST http://tier-router:9091/config \
  -d '{"classification_timeout_ms": 500, "tier_selection_timeout_ms": 1000}'
systemctl restart tier-router

# Option 3: Disable router only (keep Rust)
export TIER_ROUTER_ENABLED=false
systemctl restart application
# Monitor for improvement
```

##### Database Issues

```bash
# Option 1: Kill long-running queries
psql -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state = 'active' AND query_start < NOW() - INTERVAL '5 minutes';"

# Option 2: Clear database locks
psql -c "SELECT pg_cancel_backend(pid) FROM pg_stat_activity WHERE wait_event_type = 'Lock';"

# Option 3: Increase connection limit temporarily
psql -c "ALTER SYSTEM SET max_connections = 200;"  # From 100
psql -c "SELECT pg_reload_conf();"
```

### Recovery Verification (5 minutes)

```bash
#!/bin/bash
# verify_recovery.sh

echo "=== RECOVERY VERIFICATION ==="
BASELINE_ERROR_RATE=0.1  # Warning threshold
BASELINE_LATENCY=2.0     # Warning threshold

# Monitor for 5 minutes
for i in {1..30}; do
  ERROR_RATE=$(curl -s http://prometheus:9090/api/v1/query?query='rate(wave1_errors_total[1m]) / rate(wave1_queries_total[1m]) * 100' | jq -r '.data.result[0].value[1]')
  LATENCY=$(curl -s http://prometheus:9090/api/v1/query?query='histogram_quantile(0.95, rate(wave1_end_to_end_latency_bucket[1m]))' | jq -r '.data.result[0].value[1]')

  ERROR_OK=$(echo "$ERROR_RATE < $BASELINE_ERROR_RATE" | bc -l)
  LATENCY_OK=$(echo "$LATENCY < $BASELINE_LATENCY" | bc -l)

  STATUS="✗ DEGRADED"
  if [ "$ERROR_OK" -eq 1 ] && [ "$LATENCY_OK" -eq 1 ]; then
    STATUS="✓ HEALTHY"
  fi

  echo "[$i/30] Error: ${ERROR_RATE}% | Latency: ${LATENCY}ms | $STATUS"
  sleep 10
done

echo "=== VERIFICATION COMPLETE ==="
```

**Recovery Criteria:**
- ✅ Error rate <0.1% for 5 minutes
- ✅ Latency P95 <2ms for 5 minutes
- ✅ No new critical alerts
- ✅ Metrics stable and trending toward baseline

---

## SEV-3: Minor Degradation

### Response Actions (First 15 Minutes)

#### Step 1: Acknowledge and Monitor (5 minutes)

```bash
# Acknowledge alert in AlertManager
curl -X POST http://alertmanager:9093/api/v1/alerts \
  -d '[{"labels": {"alertname": "RustCacheHitRateLow"}, "status": "acknowledged"}]'

# Start monitoring session
watch -n 10 'curl -s http://prometheus:9090/api/v1/query?query=rust_primitives_cache_hit_rate | jq .'
```

#### Step 2: Investigate (10 minutes)

**Common SEV-3 Scenarios:**

##### Low Cache Hit Rate

```bash
# Check cache configuration
curl http://rust-primitives:9090/config | jq .cache

# Check cache metrics
curl http://rust-primitives:9090/metrics | grep cache

# Analyze query patterns
psql -c "SELECT COUNT(DISTINCT drug_id) FROM recent_queries WHERE timestamp > NOW() - INTERVAL '1 hour';"
```

**Actions:**
- High cardinality → Increase cache size
- Low TTL → Increase TTL
- Cache evictions high → Review eviction policy

##### Elevated Latency (Not Critical)

```bash
# Check database performance
psql -c "SELECT query, mean_exec_time, calls FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 10;"

# Check connection pool usage
curl http://rust-primitives:9090/metrics | grep connection_pool
```

**Actions:**
- Slow queries → Optimize queries, add indexes
- Pool saturation → Increase pool size
- Database load → Scale database

#### Step 3: Document Findings

```markdown
# SEV-3 Investigation Report

**Alert:** [Alert Name]
**Time:** [Time]
**Duration:** [Duration]
**Status:** Investigating / Resolved

## Findings

- Current value: [X]
- Baseline: [Y]
- Deviation: [Z%]
- Trend: Increasing / Decreasing / Stable

## Root Cause

[Description]

## Actions Taken

1. [Action 1]
2. [Action 2]

## Outcome

[Resolution or plan]

## Follow-Up

- [ ] Monitor for 24 hours
- [ ] Tune thresholds if needed
- [ ] Update documentation
```

---

## Postmortem Template

### Incident Postmortem

**Incident ID:** INC-YYYYMMDD-NNN
**Date:** YYYY-MM-DD
**Duration:** X hours Y minutes
**Severity:** SEV-X
**Status:** Resolved

---

#### Summary

[One paragraph summary of what happened]

---

#### Impact

- **Users Affected:** X users (Y% of total)
- **Duration:** X minutes
- **Services Impacted:** [List]
- **Data Loss:** None / [Details]
- **Financial Impact:** $X (estimated)

---

#### Timeline

| Time | Event |
|------|-------|
| HH:MM | [Event description] |
| HH:MM | [Event description] |

---

#### Root Cause

**Primary Cause:**
[Description of root cause]

**Contributing Factors:**
1. [Factor 1]
2. [Factor 2]

---

#### Resolution

**Immediate Actions:**
1. [Action taken to resolve]
2. [Action taken to resolve]

**Long-Term Actions:**
1. [Preventive measure]
2. [Preventive measure]

---

#### What Went Well

- [Thing that went well]
- [Thing that went well]

---

#### What Could Be Improved

- [Area for improvement]
- [Area for improvement]

---

#### Action Items

| Action | Owner | Due Date | Status |
|--------|-------|----------|--------|
| [Action description] | [Name] | YYYY-MM-DD | Open / In Progress / Done |

---

#### Lessons Learned

1. [Lesson 1]
2. [Lesson 2]

---

**Reviewed By:** [Names]
**Date:** YYYY-MM-DD

---

## Appendix: Quick Commands

### Health Checks

```bash
# Overall system health
curl http://application:9092/health | jq .

# Rust health
curl http://rust-primitives:9090/health | jq .

# Router health
curl http://tier-router:9091/health | jq .

# Database health
psql -c "SELECT 1;" && echo "Database OK" || echo "Database ERROR"
```

### Metrics Queries

```bash
# Error rate (last 5 min)
curl -s 'http://prometheus:9090/api/v1/query?query=rate(wave1_errors_total[5m]) / rate(wave1_queries_total[5m]) * 100' | jq -r '.data.result[0].value[1]'

# Latency P95 (last 5 min)
curl -s 'http://prometheus:9090/api/v1/query?query=histogram_quantile(0.95, rate(wave1_end_to_end_latency_bucket[5m]))' | jq -r '.data.result[0].value[1]'

# Throughput (queries per minute)
curl -s 'http://prometheus:9090/api/v1/query?query=rate(wave1_queries_total[1m]) * 60' | jq -r '.data.result[0].value[1]'

# Cache hit rate
curl -s 'http://prometheus:9090/api/v1/query?query=rate(rust_primitives_cache_hits[5m]) / (rate(rust_primitives_cache_hits[5m]) + rate(rust_primitives_cache_misses[5m])) * 100' | jq -r '.data.result[0].value[1]'
```

### Service Control

```bash
# Restart application
systemctl restart application

# Restart Rust service
systemctl restart rust-primitives

# Restart tier router
systemctl restart tier-router

# Check service status
systemctl status application rust-primitives tier-router
```

### Emergency Procedures

```bash
# Full rollback (Wave 1 disable)
export RUST_PRIMITIVES_ENABLED=false TIER_ROUTER_ENABLED=false && systemctl restart application

# Disable Rust only
export RUST_PRIMITIVES_ENABLED=false && systemctl restart application

# Disable router only
export TIER_ROUTER_ENABLED=false && systemctl restart application

# Re-enable (gradual)
export RUST_PRIMITIVES_ENABLED=true RUST_PRIMITIVES_TRAFFIC_PERCENTAGE=5 && systemctl restart application
```

---

## Training Exercises

### Exercise 1: Simulated Incident Response

**Scenario:** Rust service becomes unresponsive

```bash
# Simulate failure
systemctl stop rust-primitives

# Your task:
# 1. Detect the issue (check metrics/alerts)
# 2. Determine severity (SEV-1/2/3)
# 3. Execute appropriate response
# 4. Verify recovery
# 5. Document timeline

# Expected time: <10 minutes
```

### Exercise 2: Alert Interpretation

**Scenario:** Multiple alerts firing simultaneously

**Your task:**
1. Identify primary vs. cascading alerts
2. Determine root cause alert
3. Prioritize investigation order
4. Execute mitigation plan

### Exercise 3: Rollback Drill

**Practice executing full rollback:**

```bash
# 1. Execute rollback command
# 2. Verify service health
# 3. Check metrics stabilized
# 4. Notify stakeholders (test channel)
# 5. Document timeline

# Target completion: <5 minutes
```

---

## Runbook Maintenance

### Review Schedule

- **Weekly:** Review recent incidents, update common issues
- **Monthly:** Review all procedures, test emergency commands
- **Quarterly:** Full runbook review, update baselines

### Update Process

1. Create PR with changes
2. Get review from on-call engineer
3. Test updated procedures
4. Merge and deploy
5. Notify team of changes

### Feedback

Submit feedback or improvements:
- Slack: #wave1-monitoring
- GitHub: Create issue with label `runbook`
- During postmortems: Note runbook gaps

---

**Version:** 1.0
**Last Updated:** 2025-12-06
**Next Review:** 2025-12-20
**Maintainer:** Platform Team
