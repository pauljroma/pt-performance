#!/bin/bash
# Wave 1 Monitoring - Deployment Validation Script
# Agent 7 - Wave 1 Monitoring Engineer

echo "================================================================================"
echo "Wave 1 Monitoring Infrastructure - Deployment Validation"
echo "================================================================================"
echo ""

VALIDATION_PASSED=0
VALIDATION_FAILED=0

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((VALIDATION_PASSED++))
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    ((VALIDATION_FAILED++))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

echo "=== 1. File Existence Checks ==="
echo ""

# Check dashboard file
if [ -f "zones/z13_monitoring/dashboards/wave1_foundation.json" ]; then
    check_pass "Dashboard configuration file exists"
else
    check_fail "Dashboard configuration file missing"
fi

# Check alert rules file
if [ -f "zones/z13_monitoring/alerts/wave1_alert_rules.yaml" ]; then
    check_pass "Alert rules file exists"
else
    check_fail "Alert rules file missing"
fi

# Check incident runbook
if [ -f "zones/z13_monitoring/runbooks/INCIDENT_RESPONSE_RUNBOOK.md" ]; then
    check_pass "Incident response runbook exists"
else
    check_fail "Incident response runbook missing"
fi

# Check monitoring setup guide
if [ -f ".outcomes/WAVE1_MONITORING_SETUP.md" ]; then
    check_pass "Monitoring setup documentation exists"
else
    check_fail "Monitoring setup documentation missing"
fi

# Check completion report
if [ -f "AGENT7_WAVE1_MONITORING_COMPLETION_REPORT.md" ]; then
    check_pass "Completion report exists"
else
    check_fail "Completion report missing"
fi

echo ""
echo "=== 2. File Syntax Validation ==="
echo ""

# Validate JSON syntax
if command -v python3 &> /dev/null; then
    if python3 -m json.tool zones/z13_monitoring/dashboards/wave1_foundation.json > /dev/null 2>&1; then
        check_pass "Dashboard JSON syntax valid"
    else
        check_fail "Dashboard JSON syntax invalid"
    fi
else
    check_warn "Python3 not found - skipping JSON validation"
fi

# Validate YAML syntax
if command -v python3 &> /dev/null; then
    if python3 -c "import yaml; yaml.safe_load(open('zones/z13_monitoring/alerts/wave1_alert_rules.yaml'))" > /dev/null 2>&1; then
        check_pass "Alert rules YAML syntax valid"
    else
        check_fail "Alert rules YAML syntax invalid"
    fi
else
    check_warn "Python3 not found - skipping YAML validation"
fi

echo ""
echo "=== 3. Dashboard Configuration Checks ==="
echo ""

# Count panels in dashboard
PANEL_COUNT=$(grep -o '"id":' zones/z13_monitoring/dashboards/wave1_foundation.json | wc -l | tr -d ' ')
if [ "$PANEL_COUNT" -ge 16 ]; then
    check_pass "Dashboard has $PANEL_COUNT panels (expected: 16+)"
else
    check_fail "Dashboard has only $PANEL_COUNT panels (expected: 16+)"
fi

# Check for templating variables
if grep -q '"templating"' zones/z13_monitoring/dashboards/wave1_foundation.json; then
    check_pass "Dashboard templating configured"
else
    check_fail "Dashboard templating missing"
fi

# Check for annotations
if grep -q '"annotations"' zones/z13_monitoring/dashboards/wave1_foundation.json; then
    check_pass "Dashboard annotations configured"
else
    check_fail "Dashboard annotations missing"
fi

echo ""
echo "=== 4. Alert Rules Checks ==="
echo ""

# Count alert rules
ALERT_COUNT=$(grep -c '^      - alert:' zones/z13_monitoring/alerts/wave1_alert_rules.yaml 2>/dev/null || echo "0")
if [ "$ALERT_COUNT" -ge 20 ]; then
    check_pass "Alert rules defined: $ALERT_COUNT (expected: 20+)"
else
    check_fail "Alert rules defined: $ALERT_COUNT (expected: 20+)"
fi

# Check for severity labels
if grep -q 'severity: critical' zones/z13_monitoring/alerts/wave1_alert_rules.yaml; then
    check_pass "Critical severity alerts defined"
else
    check_fail "Critical severity alerts missing"
fi

if grep -q 'severity: warning' zones/z13_monitoring/alerts/wave1_alert_rules.yaml; then
    check_pass "Warning severity alerts defined"
else
    check_fail "Warning severity alerts missing"
fi

# Check for runbook annotations
if grep -q 'runbook:' zones/z13_monitoring/alerts/wave1_alert_rules.yaml; then
    check_pass "Runbook links included in alerts"
else
    check_fail "Runbook links missing from alerts"
fi

echo ""
echo "=== 5. Documentation Completeness Checks ==="
echo ""

# Check monitoring setup guide sections
SETUP_SECTIONS=("Dashboard Overview" "Metric Definitions" "Alert Thresholds" "Dashboard Setup Guide" "Runbook")
for section in "${SETUP_SECTIONS[@]}"; do
    if grep -q "$section" .outcomes/WAVE1_MONITORING_SETUP.md; then
        check_pass "Setup guide includes: $section"
    else
        check_fail "Setup guide missing: $section"
    fi
done

# Check incident runbook sections
RUNBOOK_SECTIONS=("Quick Reference" "SEV-1" "SEV-2" "SEV-3" "Emergency Rollback" "Postmortem")
for section in "${RUNBOOK_SECTIONS[@]}"; do
    if grep -q "$section" zones/z13_monitoring/runbooks/INCIDENT_RESPONSE_RUNBOOK.md; then
        check_pass "Incident runbook includes: $section"
    else
        check_fail "Incident runbook missing: $section"
    fi
done

echo ""
echo "=== 6. Metric Coverage Checks ==="
echo ""

# Check for Rust primitives metrics
RUST_METRICS=("rust_primitives_latency" "rust_primitives_fallback" "rust_primitives_cache")
for metric in "${RUST_METRICS[@]}"; do
    if grep -q "$metric" zones/z13_monitoring/dashboards/wave1_foundation.json; then
        check_pass "Rust metric tracked: $metric"
    else
        check_fail "Rust metric missing: $metric"
    fi
done

# Check for tier router metrics
ROUTER_METRICS=("tier_router_overhead" "tier_router_queries_by_tier" "tier_router_classification")
for metric in "${ROUTER_METRICS[@]}"; do
    if grep -q "$metric" zones/z13_monitoring/dashboards/wave1_foundation.json; then
        check_pass "Router metric tracked: $metric"
    else
        check_fail "Router metric missing: $metric"
    fi
done

# Check for system metrics
SYSTEM_METRICS=("wave1_end_to_end_latency" "wave1_queries_total" "wave1_errors_total")
for metric in "${SYSTEM_METRICS[@]}"; do
    if grep -q "$metric" zones/z13_monitoring/dashboards/wave1_foundation.json; then
        check_pass "System metric tracked: $metric"
    else
        check_fail "System metric missing: $metric"
    fi
done

echo ""
echo "=== 7. File Size Validation ==="
echo ""

# Check file sizes (should be substantial)
DASHBOARD_SIZE=$(wc -l < zones/z13_monitoring/dashboards/wave1_foundation.json | tr -d ' ')
if [ "$DASHBOARD_SIZE" -gt 500 ]; then
    check_pass "Dashboard size: $DASHBOARD_SIZE lines (substantial)"
else
    check_warn "Dashboard size: $DASHBOARD_SIZE lines (seems small)"
fi

ALERT_SIZE=$(wc -l < zones/z13_monitoring/alerts/wave1_alert_rules.yaml | tr -d ' ')
if [ "$ALERT_SIZE" -gt 300 ]; then
    check_pass "Alert rules size: $ALERT_SIZE lines (substantial)"
else
    check_warn "Alert rules size: $ALERT_SIZE lines (seems small)"
fi

RUNBOOK_SIZE=$(wc -l < zones/z13_monitoring/runbooks/INCIDENT_RESPONSE_RUNBOOK.md | tr -d ' ')
if [ "$RUNBOOK_SIZE" -gt 500 ]; then
    check_pass "Runbook size: $RUNBOOK_SIZE lines (comprehensive)"
else
    check_warn "Runbook size: $RUNBOOK_SIZE lines (seems small)"
fi

SETUP_SIZE=$(wc -l < .outcomes/WAVE1_MONITORING_SETUP.md | tr -d ' ')
if [ "$SETUP_SIZE" -gt 1000 ]; then
    check_pass "Setup guide size: $SETUP_SIZE lines (comprehensive)"
else
    check_warn "Setup guide size: $SETUP_SIZE lines (seems small)"
fi

echo ""
echo "=== 8. Agent 6 Baseline Integration ==="
echo ""

# Check for Agent 6 baselines in documentation
BASELINES=("0.082ms" "0.55ms" "42%" "72%" "8x" "850 qps")
for baseline in "${BASELINES[@]}"; do
    if grep -q "$baseline" .outcomes/WAVE1_MONITORING_SETUP.md; then
        check_pass "Baseline referenced: $baseline"
    else
        check_warn "Baseline not found: $baseline"
    fi
done

echo ""
echo "================================================================================"
echo "Validation Summary"
echo "================================================================================"
echo ""
echo -e "${GREEN}Passed: $VALIDATION_PASSED${NC}"
echo -e "${RED}Failed: $VALIDATION_FAILED${NC}"
echo ""

if [ $VALIDATION_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All validations passed! Monitoring infrastructure ready for deployment.${NC}"
    exit 0
else
    echo -e "${RED}✗ Some validations failed. Please review and fix issues before deployment.${NC}"
    exit 1
fi
