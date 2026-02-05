# Migration Applied - workout_modifications

**Date:** 2026-02-04
**Migration File:** `20260204300000_create_workout_modifications.sql`
**Applied By:** supabase-migrations skill via `supabase db push`

## Migration Content Summary

### Enum Types Created
- `modification_status`: pending, accepted, declined, modified, expired
- `modification_type`: load_adjustment, volume_reduction, exercise_swap, workout_delay, insert_recovery_day, trigger_deload, intensity_zone_change, skip_workout
- `modification_trigger`: low_readiness, high_readiness, consecutive_low_days, high_acwr, low_hrv, poor_sleep, pain_reported, high_fatigue, manual_request, ai_coach_suggestion

### Table Created: `workout_modifications`
- `id` UUID PRIMARY KEY
- `patient_id` UUID (FK to patients)
- `scheduled_session_id` UUID (FK to scheduled_sessions)
- `session_name` TEXT
- `scheduled_date` DATE
- `modification_type` TEXT with check constraint
- `trigger` TEXT with check constraint
- `status` TEXT (default: 'pending')
- `readiness_score`, `fatigue_score` NUMERIC
- `load_adjustment_percentage` NUMERIC
- `volume_reduction_sets` INTEGER
- `delay_days`, `deload_duration_days` INTEGER
- `exercise_modifications` JSONB
- `reason`, `detailed_explanation` TEXT
- `created_at`, `resolved_at` TIMESTAMPTZ
- `athlete_feedback` TEXT

### Indexes Created
- `idx_workout_modifications_patient_id`
- `idx_workout_modifications_status`
- `idx_workout_modifications_scheduled_date`
- `idx_workout_modifications_patient_pending` (partial index)
- `idx_workout_modifications_created_at`

### RLS Policies Created
- `patients_view_own_modifications` - SELECT for patients
- `patients_update_own_modifications` - UPDATE for patients
- `system_insert_modifications` - INSERT for authenticated
- `therapists_view_patient_modifications` - SELECT for therapists

### Functions Created
1. `get_pending_modifications(p_patient_id UUID)` - Fetch pending modifications
2. `resolve_modification(p_modification_id UUID, p_status TEXT, p_feedback TEXT)` - Accept/decline
3. `expire_old_modifications()` - Expire old pending modifications
4. `create_workout_modification(...)` - Create new modification from iOS app

## Application Method

CLI: `supabase db push --include-all`

## Issues Resolved During Application

1. **Timestamp conflict**: Renamed from `20260204000000` to `20260204300000`
2. **Duplicate tracking entry**: Used `supabase migration repair --status applied 20260204200000`
3. **Table reference fix**: Changed `patient_scheduled_sessions` to `scheduled_sessions`

## Verification

- CLI reported: "Finished supabase db push"
- No errors during application

## iOS App Integration

The following iOS files are now ready to use this table:
- `Services/AdaptiveTrainingService.swift` - Fetches/creates modifications
- `ViewModels/AdaptiveWorkoutViewModel.swift` - Manages UI state
- `Views/Components/WorkoutModificationCard.swift` - Displays suggestions
- `Models/WorkoutModification.swift` - Data model

## Next Steps

- [ ] Test fetching modifications from iOS app
- [ ] Test creating modifications after readiness check-in
- [ ] Test accept/decline flow
- [ ] Verify RLS policies work correctly
