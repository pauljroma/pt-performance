# Swarm Configurations

This directory contains swarm configuration files for coordinated multi-agent development and testing workflows.

## Active Swarms

### BUILD 143 Verification & BUILD 144 Planning
**File:** `build_143_verification_and_144_planning.yaml`
**Status:** Ready to execute
**Created:** 2026-01-10

**Purpose:** Verify SQL migration fixes, test production functionality, plan next improvements

**Quick Start:**
```bash
# 1. Review the swarm configuration
cat .swarms/build_143_verification_and_144_planning.yaml

# 2. Execute using /swarm-it skill
/swarm-it build_143_verification_and_144_planning.yaml
```

**Prerequisites:**
- ✅ BUILD 143 deployed to TestFlight
- ✅ Error logging enabled (shake device works)
- ⏳ SQL migration created (needs application)
- ⏳ Verification script ready

**Phases:**
1. **Migration Verification** (15 min) - Verify SQL fixes applied
2. **Timer Testing** (20 min) - Test timer creation and execution
3. **Exercise Testing** (20 min) - Test exercise logging
4. **Error Analysis** (15 min) - Analyze remaining errors
5. **BUILD 144 Planning** (30 min) - Plan next improvements

**Expected Duration:** 2 hours

**Deliverables:**
- Migration verification report
- Timer testing results
- Exercise testing results
- Error analysis report
- BUILD 144 plan document

## Swarm Workflow Overview

### Phase 1: Migration Verification
**Objective:** Confirm SQL migration applied successfully

**Steps:**
1. User pastes `verify_migration.sql` into Supabase SQL editor
2. Validate RLS policies count = 4
3. Validate functions count = 2
4. Test function calculations
5. Document results

**Success Criteria:**
- ✅ 4 RLS policies on workout_timers
- ✅ 2 calculate_rm_estimate functions
- ✅ Function test: calculate_rm_estimate(100, 10) = 133.33
- ✅ Function test: calculate_rm_estimate(100, ARRAY[10,8,6]) = 120.00

### Phase 2: Timer Testing
**Objective:** Verify timers work without RLS errors

**Steps:**
1. Open BUILD 143 on TestFlight device
2. Navigate to Timers tab
3. Select '5 Minute AMRAP' preset
4. Start timer
5. Check debug logs (shake device)
6. Verify database record created

**Success Criteria:**
- ✅ Timer starts successfully
- ✅ No [TIMER_START] errors in debug logs
- ✅ workout_timers record exists in database

### Phase 3: Exercise Testing
**Objective:** Verify exercise saves work without function errors

**Steps:**
1. Navigate to Exercise Log
2. Select exercise (e.g., Bench Press)
3. Log 3 sets: 100 lbs x 10, 8, 6 reps
4. Save exercise
5. Check debug logs (shake device)
6. Verify database record with RM estimate

**Success Criteria:**
- ✅ Exercise saves successfully
- ✅ No calculate_rm_estimate errors in debug logs
- ✅ exercise_logs record exists with rm_estimate = 120.00

### Phase 4: Error Analysis
**Objective:** Analyze any remaining errors

**Steps:**
1. Collect full debug log output
2. Categorize errors by type
3. Calculate frequencies
4. Identify root causes
5. Document findings

**Success Criteria:**
- ✅ Zero timer-related errors
- ✅ Zero exercise save errors
- ✅ All new errors categorized and explained

### Phase 5: BUILD 144 Planning
**Objective:** Plan improvements for next build

**Steps:**
1. Review BUILD 143 lessons learned
2. Design user-friendly error messages
3. Plan retry logic
4. Evaluate error reporting services (Sentry, etc.)
5. Create prioritized BUILD 144 plan

**Deliverables:**
- `.outcomes/BUILD_144_PLAN.md`
- User-friendly error message designs
- Retry logic specifications
- Error monitoring service recommendation

## Swarm Execution Commands

### Using /swarm-it Skill
```bash
# Execute the swarm with full coordination
/swarm-it build_143_verification_and_144_planning.yaml

# The skill will:
# - Parse the YAML configuration
# - Initialize all agents
# - Execute phases in sequence
# - Coordinate agent communication
# - Generate deliverables
# - Report final status
```

### Manual Phase Execution
If you prefer to execute phases manually:

```bash
# Phase 1: Migration Verification
cat verify_migration.sql
# User: Paste into Supabase SQL editor and run

# Phase 2: Timer Testing
# User: Open TestFlight, test timers, shake device for logs

# Phase 3: Exercise Testing
# User: Log exercise, shake device for logs

# Phase 4: Error Analysis
# User: Share debug log output

# Phase 5: BUILD 144 Planning
# Agent: Creates BUILD_144_PLAN.md
```

## Exit Conditions

### ✅ Can Proceed to BUILD 144
- All SQL migration checks pass
- Timers work without errors
- Exercise saves work without errors
- BUILD 144 plan approved

### ❌ Needs BUILD 143 Hotfix
- Critical errors still occurring
- SQL migration failed
- User cannot use core features

### ⚠️ Needs More Investigation
- Intermittent errors
- Edge cases discovered
- Performance issues

## Success Metrics

**Error Visibility:**
- Debug logs visible: ✅ YES (shake device works)
- Timer errors captured: ✅ YES (RLS error logged)
- Exercise errors captured: ✅ YES (Function error logged)

**Error Resolution:**
- Timer RLS fixed: ⏳ Pending verification
- Exercise function fixed: ⏳ Pending verification
- Verification passed: ⏳ Pending execution

## Related Documentation

- `.outcomes/BUILD_143_ERROR_LOGGING_FIX_COMPLETE.md` - Current status
- `supabase/migrations/20260109000001_fix_timers_and_exercise_errors.sql` - SQL fixes
- `verify_migration.sql` - Verification script

## Notes

- BUILD 143 already deployed - no new deployment needed
- SQL migration must be applied manually in Supabase
- All testing done on actual TestFlight build
- User has full error visibility (shake device)
- Focus is VERIFICATION, not new development
- BUILD 144 planning is secondary objective

## Support

**Repository:** git@github.com:pauljroma/pt-performance.git
**Directory:** /Users/expo/pt-performance
**Owner:** expo
**Assistant:** Claude Sonnet 4.5
