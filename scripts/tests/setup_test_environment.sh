#!/bin/bash
# ============================================================================
# setup_test_environment.sh
# Prepares the local Supabase environment for edge function integration tests.
#
# What it does:
#   1. Waits for the Supabase REST API to become responsive
#   2. Extracts the local anon key from `supabase status`
#   3. Runs pending migrations / seeds if needed
#   4. Exports SUPABASE_ANON_KEY and SUPABASE_URL for downstream scripts
#
# Expected environment:
#   - Supabase CLI installed and on PATH
#   - `supabase start` already executed (by CI or locally)
#   - Working directory: scripts/tests (or REPO_ROOT set)
# ============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Resolve repo root
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${REPO_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
SUPABASE_URL="${SUPABASE_URL:-http://localhost:54321}"
MAX_RETRIES=30
RETRY_INTERVAL=2   # seconds

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
info()  { echo "[setup] $*"; }
warn()  { echo "[setup] WARNING: $*"; }
error() { echo "[setup] ERROR: $*" >&2; }

# ---------------------------------------------------------------------------
# 1. Wait for Supabase REST API to be ready
# ---------------------------------------------------------------------------
info "Waiting for Supabase REST API at ${SUPABASE_URL} ..."

attempt=0
while true; do
    attempt=$((attempt + 1))

    # Check if the REST endpoint responds (any 2xx/4xx is fine; we just need TCP + HTTP up)
    http_code=$(curl -s -o /dev/null -w "%{http_code}" "${SUPABASE_URL}/rest/v1/" 2>/dev/null || echo "000")

    if [[ "$http_code" =~ ^[2-4][0-9][0-9]$ ]]; then
        info "Supabase REST API is ready (HTTP ${http_code}) after ${attempt} attempt(s)."
        break
    fi

    if [ "$attempt" -ge "$MAX_RETRIES" ]; then
        error "Supabase REST API did not become ready after ${MAX_RETRIES} attempts."
        exit 1
    fi

    info "  Attempt ${attempt}/${MAX_RETRIES} - HTTP ${http_code}, retrying in ${RETRY_INTERVAL}s ..."
    sleep "$RETRY_INTERVAL"
done

# ---------------------------------------------------------------------------
# 2. Extract the local anon key
# ---------------------------------------------------------------------------
info "Extracting local anon key from supabase status ..."

# Try JSON output first (requires supabase CLI >= 1.50)
if SUPABASE_ANON_KEY=$(cd "$REPO_ROOT" && supabase status --output json 2>/dev/null | grep -o '"anon_key":"[^"]*"' | head -1 | cut -d'"' -f4) && [ -n "$SUPABASE_ANON_KEY" ]; then
    info "Anon key extracted via JSON output."
else
    # Fallback: parse plain-text output
    SUPABASE_ANON_KEY=$(cd "$REPO_ROOT" && supabase status 2>/dev/null | grep -i 'anon key' | awk '{print $NF}')
    if [ -z "$SUPABASE_ANON_KEY" ]; then
        error "Could not extract anon key from supabase status."
        error "Make sure Supabase is running (supabase start)."
        exit 1
    fi
    info "Anon key extracted via text output."
fi

# Sanity-check the key looks like a JWT (starts with "ey")
if [[ ! "$SUPABASE_ANON_KEY" =~ ^ey ]]; then
    warn "Anon key does not look like a JWT (expected to start with 'ey'). Proceeding anyway."
fi

# ---------------------------------------------------------------------------
# 3. Run pending migrations if needed
# ---------------------------------------------------------------------------
info "Checking for pending migrations ..."

if cd "$REPO_ROOT" && supabase db push --dry-run 2>/dev/null | grep -q "Would apply"; then
    info "Applying pending migrations ..."
    cd "$REPO_ROOT" && supabase db push 2>&1 || warn "db push returned non-zero (migrations may already be applied)."
else
    info "No pending migrations detected."
fi

# ---------------------------------------------------------------------------
# 4. Verify the edge functions endpoint is responsive
# ---------------------------------------------------------------------------
info "Checking Edge Functions endpoint ..."

ef_attempt=0
EF_MAX_RETRIES=15
while true; do
    ef_attempt=$((ef_attempt + 1))

    ef_code=$(curl -s -o /dev/null -w "%{http_code}" "${SUPABASE_URL}/functions/v1/" 2>/dev/null || echo "000")

    # Any HTTP response (even 404) means the functions server is up
    if [[ "$ef_code" != "000" ]]; then
        info "Edge Functions endpoint is responsive (HTTP ${ef_code})."
        break
    fi

    if [ "$ef_attempt" -ge "$EF_MAX_RETRIES" ]; then
        warn "Edge Functions endpoint not responding after ${EF_MAX_RETRIES} attempts."
        warn "Tests that call edge functions may fail."
        break
    fi

    info "  Attempt ${ef_attempt}/${EF_MAX_RETRIES} - no response, retrying in ${RETRY_INTERVAL}s ..."
    sleep "$RETRY_INTERVAL"
done

# ---------------------------------------------------------------------------
# 5. Export variables for downstream scripts
# ---------------------------------------------------------------------------
# Write to a file that CI steps can source, and also export for the current shell.
ENV_FILE="${SCRIPT_DIR}/.test_env"

cat > "$ENV_FILE" <<EOF
export SUPABASE_URL="${SUPABASE_URL}"
export SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}"
EOF

export SUPABASE_URL
export SUPABASE_ANON_KEY

info "Environment written to ${ENV_FILE}"
info "  SUPABASE_URL=${SUPABASE_URL}"
info "  SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY:0:20}..."

# If running in GitHub Actions, also set outputs
if [ -n "${GITHUB_ENV:-}" ]; then
    echo "SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}" >> "$GITHUB_ENV"
    echo "SUPABASE_URL=${SUPABASE_URL}" >> "$GITHUB_ENV"
    info "Variables exported to GITHUB_ENV."
fi

info "Setup complete. Ready to run edge function tests."
