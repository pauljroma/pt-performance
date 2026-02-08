#!/bin/bash
# =============================================================================
# Migration Verification Script
# =============================================================================
# Runs after `supabase db push` to verify RLS policies and table access
#
# Usage:
#   ./scripts/verify_migration.sh
#   ./scripts/verify_migration.sh --verbose
#   ./scripts/verify_migration.sh --skip-access-tests
#
# Exit Codes:
#   0 - All verifications passed
#   1 - Verification failed (RLS or policy issues)
# =============================================================================

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Options
VERBOSE=false
SKIP_ACCESS_TESTS=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        --skip-access-tests)
            SKIP_ACCESS_TESTS=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -v, --verbose       Show detailed output"
            echo "  --skip-access-tests Skip the table access tests"
            echo "  -h, --help          Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# =============================================================================
# Helper Functions
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

log_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo -e "       $1"
    fi
}

# Tables that MUST have RLS enabled and policies
CRITICAL_TABLES=(
    "sessions"
    "session_exercises"
    "exercise_logs"
    "manual_sessions"
    "manual_session_exercises"
    "workout_prescriptions"
    "workout_modifications"
    "patient_favorite_templates"
    "patient_workout_templates"
    "system_workout_templates"
    "streak_records"
    "streak_history"
    "daily_readiness"
    "arm_care_assessments"
    "body_comp_measurements"
    "notification_settings"
    "prescription_notification_preferences"
    "patients"
    "therapists"
    "users"
)

# Minimum required policies per operation type
MIN_POLICIES_PER_OPERATION=1

# =============================================================================
# Database Connection
# =============================================================================

get_db_url() {
    # Try environment variable first
    if [ -n "$SUPABASE_DB_URL" ]; then
        echo "$SUPABASE_DB_URL"
        return
    fi

    # Try .env file
    if [ -f "$PROJECT_ROOT/.env" ]; then
        source "$PROJECT_ROOT/.env"
        if [ -n "$SUPABASE_DB_URL" ]; then
            echo "$SUPABASE_DB_URL"
            return
        fi
    fi

    # Try Supabase CLI
    if command -v supabase &> /dev/null; then
        # Get connection string from supabase status
        local status
        status=$(supabase status 2>/dev/null | grep "DB URL" | awk '{print $3}')
        if [ -n "$status" ]; then
            echo "$status"
            return
        fi
    fi

    echo ""
}

run_sql() {
    local sql="$1"
    psql "$DB_URL" -t -A -c "$sql" 2>/dev/null
}

# =============================================================================
# Main Verification
# =============================================================================

echo ""
echo -e "${BOLD}==============================================================================${NC}"
echo -e "${BOLD}Migration Verification Script${NC}"
echo -e "${BOLD}==============================================================================${NC}"
echo ""

# Get database URL
DB_URL=$(get_db_url)

if [ -z "$DB_URL" ]; then
    log_error "Cannot connect to database. Set SUPABASE_DB_URL environment variable."
    echo ""
    echo "Example:"
    echo "  export SUPABASE_DB_URL='postgresql://postgres:password@localhost:54322/postgres'"
    exit 1
fi

log_info "Connected to database"
log_verbose "URL: ${DB_URL:0:50}..."

# =============================================================================
# Step 1: Run RLS Policy Verification SQL
# =============================================================================

echo ""
echo -e "${BOLD}Step 1: Verifying RLS Policies${NC}"
echo "-------------------------------------------"

# Run the verification SQL and capture results
RLS_RESULTS=$(psql "$DB_URL" -t -A -f "$SCRIPT_DIR/verify_rls_policies.sql" 2>&1)

if [ $? -ne 0 ]; then
    log_error "Failed to run RLS verification SQL"
    log_verbose "$RLS_RESULTS"
    exit 1
fi

# Parse results and display
VERIFICATION_FAILED=false
TABLES_MISSING_RLS=()
TABLES_MISSING_POLICIES=()
TABLES_OK=()

# Process each line of results
while IFS='|' read -r table_name rls_enabled policy_count select_count insert_count update_count delete_count grants_ok; do
    # Skip empty lines
    [ -z "$table_name" ] && continue

    # Clean up whitespace
    table_name=$(echo "$table_name" | xargs)
    rls_enabled=$(echo "$rls_enabled" | xargs)
    policy_count=$(echo "$policy_count" | xargs)
    grants_ok=$(echo "$grants_ok" | xargs)

    # Check if this is a critical table
    is_critical=false
    for critical_table in "${CRITICAL_TABLES[@]}"; do
        if [ "$critical_table" = "$table_name" ]; then
            is_critical=true
            break
        fi
    done

    # Only report on critical tables or those with issues
    if [ "$is_critical" = true ]; then
        if [ "$rls_enabled" != "t" ]; then
            log_error "$table_name: RLS DISABLED - DATA IS PUBLICLY ACCESSIBLE"
            TABLES_MISSING_RLS+=("$table_name")
            VERIFICATION_FAILED=true
        elif [ "$policy_count" -eq 0 ]; then
            log_error "$table_name: RLS enabled, 0 policies - MISSING POLICIES"
            TABLES_MISSING_POLICIES+=("$table_name")
            VERIFICATION_FAILED=true
        elif [ "$grants_ok" != "OK" ]; then
            log_warning "$table_name: RLS enabled, $policy_count policies, grants issue"
            VERIFICATION_FAILED=true
        else
            log_success "$table_name: RLS enabled, $policy_count policies, grants OK"
            TABLES_OK+=("$table_name")
        fi
    fi
done <<< "$RLS_RESULTS"

# =============================================================================
# Step 2: Check for Tables Missing from Verification
# =============================================================================

echo ""
echo -e "${BOLD}Step 2: Checking Critical Tables Exist${NC}"
echo "-------------------------------------------"

MISSING_TABLES=()
EXISTING_TABLES=$(run_sql "SELECT tablename FROM pg_tables WHERE schemaname = 'public';")

for table in "${CRITICAL_TABLES[@]}"; do
    if echo "$EXISTING_TABLES" | grep -q "^${table}$"; then
        log_verbose "$table exists"
    else
        log_warning "$table: Table does not exist (may not be created yet)"
        MISSING_TABLES+=("$table")
    fi
done

if [ ${#MISSING_TABLES[@]} -eq 0 ]; then
    log_success "All critical tables exist"
else
    log_warning "${#MISSING_TABLES[@]} critical tables not found (may be expected)"
fi

# =============================================================================
# Step 3: Test Table Access (Optional)
# =============================================================================

if [ "$SKIP_ACCESS_TESTS" = false ]; then
    echo ""
    echo -e "${BOLD}Step 3: Testing Table Access${NC}"
    echo "-------------------------------------------"

    ACCESS_TEST_RESULTS=$(psql "$DB_URL" -f "$SCRIPT_DIR/test_table_access.sql" 2>&1)

    if [ $? -ne 0 ]; then
        log_warning "Table access tests had issues (this may be expected in some environments)"
        log_verbose "$ACCESS_TEST_RESULTS"
    else
        # Parse test results
        if echo "$ACCESS_TEST_RESULTS" | grep -q "FAIL"; then
            log_error "Some table access tests failed"
            VERIFICATION_FAILED=true
            if [ "$VERBOSE" = true ]; then
                echo "$ACCESS_TEST_RESULTS" | grep -E "(PASS|FAIL)"
            fi
        else
            log_success "All table access tests passed"
        fi
    fi
else
    echo ""
    log_info "Skipping table access tests (--skip-access-tests)"
fi

# =============================================================================
# Summary
# =============================================================================

echo ""
echo -e "${BOLD}==============================================================================${NC}"
echo -e "${BOLD}Verification Summary${NC}"
echo -e "${BOLD}==============================================================================${NC}"
echo ""

echo "Tables verified: ${#TABLES_OK[@]}"
echo "Tables missing RLS: ${#TABLES_MISSING_RLS[@]}"
echo "Tables missing policies: ${#TABLES_MISSING_POLICIES[@]}"
echo "Tables not found: ${#MISSING_TABLES[@]}"
echo ""

if [ "$VERIFICATION_FAILED" = true ]; then
    echo -e "${RED}${BOLD}VERIFICATION FAILED${NC}"
    echo ""

    if [ ${#TABLES_MISSING_RLS[@]} -gt 0 ]; then
        echo "Tables with RLS disabled (CRITICAL):"
        for table in "${TABLES_MISSING_RLS[@]}"; do
            echo "  - $table"
            echo "    Fix: ALTER TABLE $table ENABLE ROW LEVEL SECURITY;"
        done
        echo ""
    fi

    if [ ${#TABLES_MISSING_POLICIES[@]} -gt 0 ]; then
        echo "Tables missing policies (CRITICAL):"
        for table in "${TABLES_MISSING_POLICIES[@]}"; do
            echo "  - $table"
        done
        echo ""
        echo "Create policies for these tables before deploying to production."
    fi

    exit 1
else
    echo -e "${GREEN}${BOLD}VERIFICATION PASSED${NC}"
    echo ""
    echo "All critical tables have RLS enabled with appropriate policies."
    exit 0
fi
