#!/bin/bash
# ============================================================================
# ci_test_edge_functions.sh
# Integration tests for Supabase Edge Functions (analytics suite).
#
# Usage:
#   ./ci_test_edge_functions.sh --output test-results.json
#
# Required environment variables:
#   SUPABASE_URL       - e.g. http://localhost:54321
#   SUPABASE_ANON_KEY  - local anon JWT (set by setup_test_environment.sh)
#
# Optional:
#   OPENAI_API_KEY     - required only for AI-dependent functions (not tested here)
#
# Output JSON schema:
#   {
#     "summary":  { "total": N, "passed": N, "failed": N, "skipped": N, "pass_rate": N },
#     "test_duration_seconds": N,
#     "by_function": { "<name>": { "actual": N } }
#   }
# ============================================================================

set -uo pipefail

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
OUTPUT_FILE=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1" >&2
            echo "Usage: $0 --output <file>" >&2
            exit 1
            ;;
    esac
done

if [ -z "$OUTPUT_FILE" ]; then
    echo "Error: --output <file> is required." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Resolve environment
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.test_env"

# Source environment from setup script if available
if [ -f "$ENV_FILE" ]; then
    # shellcheck disable=SC1090
    source "$ENV_FILE"
fi

SUPABASE_URL="${SUPABASE_URL:-http://localhost:54321}"

if [ -z "${SUPABASE_ANON_KEY:-}" ]; then
    echo "Error: SUPABASE_ANON_KEY is not set. Run setup_test_environment.sh first." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
FUNCTIONS_BASE="${SUPABASE_URL}/functions/v1"
CURL_TIMEOUT=30   # seconds per request
TEST_PATIENT_ID="aaaaaaaa-bbbb-cccc-dddd-000000000001"

# ---------------------------------------------------------------------------
# Counters and result tracking
# ---------------------------------------------------------------------------
TOTAL=0
PASSED=0
FAILED=0
SKIPPED=0

# Associative arrays for per-function tracking
declare -A FUNC_PASS
declare -A FUNC_TOTAL

START_TIME=$(date +%s)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
info()  { echo "[test] $*"; }
pass()  { echo "[PASS] $*"; }
fail()  { echo "[FAIL] $*"; }
skip()  { echo "[SKIP] $*"; }

# run_test <function_name> <test_label> <http_method> <url> <body> <expected_http_code> [<body_check_pattern>]
#
# Sends a request and checks:
#   1. HTTP status code matches expected
#   2. Optionally, response body matches a grep pattern
run_test() {
    local func_name="$1"
    local label="$2"
    local method="$3"
    local url="$4"
    local body="$5"
    local expected_code="$6"
    local body_pattern="${7:-}"

    TOTAL=$((TOTAL + 1))
    FUNC_TOTAL[$func_name]=$(( ${FUNC_TOTAL[$func_name]:-0} + 1 ))

    local tmpfile
    tmpfile=$(mktemp)

    local http_code
    http_code=$(curl -s -o "$tmpfile" -w "%{http_code}" \
        --max-time "$CURL_TIMEOUT" \
        -X "$method" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
        -H "apikey: ${SUPABASE_ANON_KEY}" \
        -d "$body" \
        "$url" 2>/dev/null || echo "000")

    local response
    response=$(cat "$tmpfile" 2>/dev/null || echo "")
    rm -f "$tmpfile"

    # Check HTTP status code
    if [ "$http_code" != "$expected_code" ]; then
        fail "${func_name} :: ${label} - expected HTTP ${expected_code}, got ${http_code}"
        if [ -n "$response" ]; then
            echo "       Response: ${response:0:300}"
        fi
        FAILED=$((FAILED + 1))
        return 1
    fi

    # Optionally check response body
    if [ -n "$body_pattern" ]; then
        if ! echo "$response" | grep -qE "$body_pattern"; then
            fail "${func_name} :: ${label} - response did not match pattern: ${body_pattern}"
            echo "       Response: ${response:0:300}"
            FAILED=$((FAILED + 1))
            return 1
        fi
    fi

    pass "${func_name} :: ${label} (HTTP ${http_code})"
    PASSED=$((PASSED + 1))
    FUNC_PASS[$func_name]=$(( ${FUNC_PASS[$func_name]:-0} + 1 ))
    return 0
}

# skip_test <function_name> <test_label> <reason>
skip_test() {
    local func_name="$1"
    local label="$2"
    local reason="$3"

    TOTAL=$((TOTAL + 1))
    SKIPPED=$((SKIPPED + 1))
    FUNC_TOTAL[$func_name]=$(( ${FUNC_TOTAL[$func_name]:-0} + 1 ))

    skip "${func_name} :: ${label} - ${reason}"
}

# ============================================================================
# TEST SUITE
# ============================================================================

info "=============================================="
info "Edge Function Integration Tests"
info "=============================================="
info "SUPABASE_URL: ${SUPABASE_URL}"
info "Functions base: ${FUNCTIONS_BASE}"
info ""

# ---------------------------------------------------------------------------
# 1. revenue-analytics
# ---------------------------------------------------------------------------
info "--- revenue-analytics ---"

run_test "revenue-analytics" \
    "POST with period=30" \
    "POST" \
    "${FUNCTIONS_BASE}/revenue-analytics" \
    '{"period": 30}' \
    "200" \
    '"success"' \
    || true

run_test "revenue-analytics" \
    "POST with specific sections" \
    "POST" \
    "${FUNCTIONS_BASE}/revenue-analytics" \
    '{"period": 90, "sections": "metrics,ltv"}' \
    "200" \
    '"sections_included"' \
    || true

run_test "revenue-analytics" \
    "POST with invalid cohort format returns 400" \
    "POST" \
    "${FUNCTIONS_BASE}/revenue-analytics" \
    '{"cohort": "invalid"}' \
    "400" \
    '"error"' \
    || true

echo ""

# ---------------------------------------------------------------------------
# 2. retention-analytics
# ---------------------------------------------------------------------------
info "--- retention-analytics ---"

run_test "retention-analytics" \
    "POST with months=6" \
    "POST" \
    "${FUNCTIONS_BASE}/retention-analytics" \
    '{"months": 6}' \
    "200" \
    '"generated_at"' \
    || true

run_test "retention-analytics" \
    "POST with type=cohorts" \
    "POST" \
    "${FUNCTIONS_BASE}/retention-analytics" \
    '{"months": 3, "type": "cohorts"}' \
    "200" \
    '"cohorts"' \
    || true

run_test "retention-analytics" \
    "POST with invalid months returns 400" \
    "POST" \
    "${FUNCTIONS_BASE}/retention-analytics" \
    '{"months": 999}' \
    "400" \
    '"error"' \
    || true

echo ""

# ---------------------------------------------------------------------------
# 3. engagement-scoring
# ---------------------------------------------------------------------------
info "--- engagement-scoring ---"

run_test "engagement-scoring" \
    "POST with at_risk=true" \
    "POST" \
    "${FUNCTIONS_BASE}/engagement-scoring" \
    '{"at_risk": true}' \
    "200" \
    '"success"' \
    || true

run_test "engagement-scoring" \
    "POST with threshold" \
    "POST" \
    "${FUNCTIONS_BASE}/engagement-scoring" \
    '{"threshold": 30}' \
    "200" \
    '"success"' \
    || true

run_test "engagement-scoring" \
    "POST empty body (batch)" \
    "POST" \
    "${FUNCTIONS_BASE}/engagement-scoring" \
    '{}' \
    "200" \
    '"success"' \
    || true

echo ""

# ---------------------------------------------------------------------------
# 4. training-outcomes
# ---------------------------------------------------------------------------
info "--- training-outcomes ---"

run_test "training-outcomes" \
    "POST with aggregate=true" \
    "POST" \
    "${FUNCTIONS_BASE}/training-outcomes" \
    '{"aggregate": "true"}' \
    "200" \
    '"success"' \
    || true

run_test "training-outcomes" \
    "POST with patient_id and period" \
    "POST" \
    "${FUNCTIONS_BASE}/training-outcomes" \
    "{\"patient_id\": \"${TEST_PATIENT_ID}\", \"period\": 90}" \
    "200" \
    '"success"\|"error"' \
    || true

run_test "training-outcomes" \
    "POST missing patient_id (no aggregate) returns 400" \
    "POST" \
    "${FUNCTIONS_BASE}/training-outcomes" \
    '{}' \
    "400" \
    '"error"' \
    || true

echo ""

# ---------------------------------------------------------------------------
# 5. executive-dashboard
# ---------------------------------------------------------------------------
info "--- executive-dashboard ---"

run_test "executive-dashboard" \
    "POST with empty body (full dashboard)" \
    "POST" \
    "${FUNCTIONS_BASE}/executive-dashboard" \
    '{}' \
    "200" \
    "" \
    || true

run_test "executive-dashboard" \
    "POST with format=digest" \
    "POST" \
    "${FUNCTIONS_BASE}/executive-dashboard" \
    '{"format": "digest"}' \
    "200" \
    "" \
    || true

run_test "executive-dashboard" \
    "POST handles OPTIONS preflight (CORS)" \
    "OPTIONS" \
    "${FUNCTIONS_BASE}/executive-dashboard" \
    '' \
    "200" \
    "" \
    || true

echo ""

# ---------------------------------------------------------------------------
# 6. product-health
# ---------------------------------------------------------------------------
info "--- product-health ---"

run_test "product-health" \
    "POST with period=30" \
    "POST" \
    "${FUNCTIONS_BASE}/product-health" \
    '{"period": 30}' \
    "200" \
    "" \
    || true

run_test "product-health" \
    "POST with period=90" \
    "POST" \
    "${FUNCTIONS_BASE}/product-health" \
    '{"period": 90}' \
    "200" \
    "" \
    || true

run_test "product-health" \
    "POST with invalid period returns 400" \
    "POST" \
    "${FUNCTIONS_BASE}/product-health" \
    '{"period": 999}' \
    "400" \
    '"error"' \
    || true

echo ""

# ---------------------------------------------------------------------------
# 7. analytics-pipeline
# ---------------------------------------------------------------------------
info "--- analytics-pipeline ---"

run_test "analytics-pipeline" \
    "POST with action=health (GET /health)" \
    "GET" \
    "${FUNCTIONS_BASE}/analytics-pipeline/health" \
    '' \
    "200" \
    '"success"' \
    || true

run_test "analytics-pipeline" \
    "GET root returns function info" \
    "GET" \
    "${FUNCTIONS_BASE}/analytics-pipeline" \
    '' \
    "200" \
    '"analytics-pipeline"' \
    || true

run_test "analytics-pipeline" \
    "POST /ingest with empty events returns 400" \
    "POST" \
    "${FUNCTIONS_BASE}/analytics-pipeline/ingest" \
    '{"events": []}' \
    "400" \
    '"error"' \
    || true

echo ""

# ---------------------------------------------------------------------------
# 8. Auth validation tests (no Authorization header)
# ---------------------------------------------------------------------------
info "--- auth-validation (cross-function) ---"

# Test functions that explicitly check for Authorization header
for func in revenue-analytics training-outcomes executive-dashboard product-health; do
    TOTAL=$((TOTAL + 1))
    FUNC_TOTAL[$func]=$(( ${FUNC_TOTAL[$func]:-0} + 1 ))

    tmpfile=$(mktemp)
    http_code=$(curl -s -o "$tmpfile" -w "%{http_code}" \
        --max-time "$CURL_TIMEOUT" \
        -X POST \
        -H "Content-Type: application/json" \
        -d '{}' \
        "${FUNCTIONS_BASE}/${func}" 2>/dev/null || echo "000")
    response=$(cat "$tmpfile" 2>/dev/null || echo "")
    rm -f "$tmpfile"

    if [ "$http_code" = "401" ]; then
        pass "${func} :: rejects unauthenticated request (HTTP 401)"
        PASSED=$((PASSED + 1))
        FUNC_PASS[$func]=$(( ${FUNC_PASS[$func]:-0} + 1 ))
    else
        # Some functions may return 401 via the Supabase relay or 200 if they
        # don't check auth themselves. Either way, track the result.
        fail "${func} :: expected 401 for unauthenticated request, got HTTP ${http_code}"
        echo "       Response: ${response:0:200}"
        FAILED=$((FAILED + 1))
    fi
done

echo ""

# ============================================================================
# Summary
# ============================================================================
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Compute pass rate (avoid division by zero)
if [ "$TOTAL" -gt 0 ]; then
    PASS_RATE=$(( (PASSED * 100) / TOTAL ))
else
    PASS_RATE=0
fi

info "=============================================="
info "Results: ${PASSED}/${TOTAL} passed, ${FAILED} failed, ${SKIPPED} skipped (${DURATION}s)"
info "Pass rate: ${PASS_RATE}%"
info "=============================================="

# ---------------------------------------------------------------------------
# Build per-function JSON
# ---------------------------------------------------------------------------
by_function_json="{"
first=true
for func in revenue-analytics retention-analytics engagement-scoring training-outcomes executive-dashboard product-health analytics-pipeline; do
    actual=${FUNC_PASS[$func]:-0}
    if [ "$first" = true ]; then
        first=false
    else
        by_function_json+=","
    fi
    # Convert hyphens to underscores for JSON keys
    json_key=$(echo "$func" | tr '-' '_')
    by_function_json+="\"${json_key}\": {\"actual\": ${actual}}"
done
by_function_json+="}"

# ---------------------------------------------------------------------------
# Write results JSON
# ---------------------------------------------------------------------------
cat > "$OUTPUT_FILE" <<RESULTS_EOF
{
  "summary": {
    "total": ${TOTAL},
    "passed": ${PASSED},
    "failed": ${FAILED},
    "skipped": ${SKIPPED},
    "pass_rate": ${PASS_RATE}
  },
  "test_duration_seconds": ${DURATION},
  "by_function": ${by_function_json}
}
RESULTS_EOF

info "Results written to ${OUTPUT_FILE}"

# Print the JSON for CI logs
cat "$OUTPUT_FILE"

# Exit with failure if any tests failed
if [ "$FAILED" -gt 0 ]; then
    exit 1
fi

exit 0
