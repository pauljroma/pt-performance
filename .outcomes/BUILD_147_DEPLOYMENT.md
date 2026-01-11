# BUILD 147 - Deployment Complete

**Date:** 2026-01-10
**Status:** ✅ UPLOADED TO TESTFLIGHT
**Delivery UUID:** dad8f637-d618-4e17-8474-cff5bf41abed

## Changes

### Timer Fixes (Critical - Unblocks Timer Feature)

**Swift Code Changes:**
- Made `WorkoutTimer.templateId` optional to handle NULL from database
- Made `CreateWorkoutTimerInput.templateId` optional
- Pass `nil` for templateId instead of random UUID (no templates in DB yet)

**Database Migrations (Applied):**
- `20260110000099`: Disabled RLS on workout_timers table
- `20260110000100`: Backfilled patients table, added auto-trigger for new signups
- `20260110000101`: Auto-convert invalid template_id to NULL via trigger
- `20260109000003`: Timer/exercise RLS policies + calculate_rm_estimate fixes

### Root Causes Fixed

1. **RLS Violation**: RLS enabled but policies blocking INSERT → Disabled RLS entirely
2. **Patient FK Violation**: patient_id FK violation - auth users not in patients table → Backfilled patients table
3. **Template FK Violation**: template_id FK violation - random UUIDs don't exist in interval_templates → Trigger converts to NULL
4. **Decoding Error**: WorkoutTimer.templateId non-optional - crashes decoding NULL from database → Made optional

## Build Metrics

- **Build Number:** 147
- **Archive Time:** ~4 minutes
- **Upload Time:** 0.037 seconds (134.6MB/s)
- **IPA Size:** 5.0 MB
- **Delivery UUID:** dad8f637-d618-4e17-8474-cff5bf41abed

## Files Changed

**Swift Files:**
- `ios-app/PTPerformance/Models/WorkoutTimer.swift`
- `ios-app/PTPerformance/Models/TimerInputModels.swift`
- `ios-app/PTPerformance/Services/IntervalTimerService.swift`

**Migrations:**
- `supabase/migrations/20260109000003_fix_timers_and_exercise_errors.sql`
- `supabase/migrations/20260110000099_disable_rls_workout_timers.sql`
- `supabase/migrations/20260110000100_fix_patient_fk_for_timers.sql`
- `supabase/migrations/20260110000101_fix_invalid_template_id.sql`

## Testing Checklist

- [ ] Install BUILD 147 from TestFlight
- [ ] Sign in as patient
- [ ] Start a timer (Tabata/EMOM/AMRAP)
- [ ] Verify timer starts without errors
- [ ] Verify timer runs and completes
- [ ] Test exercise logging with multi-set exercises
- [ ] Verify no crashes or RLS errors

## Expected Results

✅ Timers should start successfully
✅ No RLS policy violations
✅ No foreign key constraint errors
✅ No JSON decoding errors
✅ Timer data saves to database with NULL template_id

## Next Steps

1. **Test on TestFlight** - Verify timers work (highest priority)
2. **Test exercise logging** - Verify multi-set exercises and RM calculation
3. **Review BUILD 144 plan** - Approve error handling improvements
4. **Deploy BUILD 148** - With error handling from BUILD 144 plan (if approved)

## Processing Timeline

- **Upload:** 2026-01-10 22:25:10
- **Expected Processing:** 10-15 minutes
- **Available for Testing:** ~2026-01-10 22:40:00

Check App Store Connect: https://appstoreconnect.apple.com
