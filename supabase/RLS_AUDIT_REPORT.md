# RLS Audit Report -- Modus PT Performance Database

**Date:** 2026-02-22
**Auditor:** Claude Code (automated audit)
**Migration:** `20260222120000_rls_audit_fixes.sql`
**Scope:** All tables in `public` schema across 100+ migration files

---

## Executive Summary

The Modus database contains approximately **120+ tables** across the PT Performance app, LIMS system, and supporting infrastructure. This audit found:

| Severity | Count | Description |
|----------|-------|-------------|
| CRITICAL | 4 | Patient health data tables with NO RLS at all |
| HIGH | 3 | User/program data tables with NO RLS |
| MEDIUM | 18 | Tables with overly permissive `USING(true)` policies |
| LOW | 24+ | System/config/LIMS tables without RLS |
| OK | 70+ | Tables with proper RLS policies |

**Key Finding:** The original 12 tables from `20241205000000_init_schema.sql` were created WITHOUT any RLS. While later migrations added RLS to `patients`, `sessions`, `session_exercises`, `exercise_logs`, `body_comp_measurements`, and `scheduled_sessions`, **6 tables from the original schema never received RLS protection:**

1. `therapists` -- therapist PII (names, emails, credentials)
2. `programs` -- patient program assignments
3. `phases` -- program phase data
4. `pain_logs` -- patient pain scores (HIPAA-sensitive)
5. `bullpen_logs` -- athlete throwing data with pain scores
6. `session_notes` -- clinical documentation (HIPAA-sensitive)
7. `exercise_templates` -- shared content (lower risk)

Additionally, **many tables that originally had proper `auth.uid()` scoping were later relaxed to `USING(true)` in migrations 20260207410000 and 20260207430000** to work around demo mode authentication issues.

---

## Detailed Findings

### CRITICAL: Tables with NO RLS and Patient Health Data

#### 1. `therapists`
- **Created:** `20241205000000_init_schema.sql`
- **RLS Status:** NEVER ENABLED
- **Columns at risk:** `first_name`, `last_name`, `email`, `credentials`, `specialty`
- **Impact:** Any anonymous user could read all therapist personal data
- **Fix:** Enabled RLS. Therapists can see own record + colleagues. Patients can see their assigned therapist.

#### 2. `pain_logs`
- **Created:** `20241205000000_init_schema.sql`
- **RLS Status:** NEVER ENABLED
- **Columns at risk:** `pain_during`, `pain_before`, `pain_after`, `body_region`, `pain_location`, `notes`
- **Impact:** All patient pain scores exposed to any user -- HIPAA violation risk
- **Fix:** Enabled RLS. Patient-scoped via `patient_id`. Therapist access via relationship.

#### 3. `bullpen_logs`
- **Created:** `20241205000000_init_schema.sql`
- **RLS Status:** NEVER ENABLED
- **Columns at risk:** `pitch_count`, `velocity`, `pain_score`, `notes`
- **Impact:** Athlete throwing workload and pain data exposed
- **Fix:** Enabled RLS. Patient-scoped via `patient_id`. Therapist access via relationship.

#### 4. `session_notes`
- **Created:** `20241205000000_init_schema.sql`
- **RLS Status:** NEVER ENABLED
- **Columns at risk:** `note_text`, `content`, `created_by` -- clinical documentation
- **Impact:** Clinical notes (potentially containing diagnoses, treatment plans) fully exposed -- HIPAA violation
- **Fix:** Enabled RLS. Patients can view own notes. Therapists can manage notes for their patients.

### HIGH: Tables with NO RLS and User-Identifiable Data

#### 5. `programs`
- **Created:** `20241205000000_init_schema.sql`
- **RLS Status:** NEVER ENABLED
- **Columns at risk:** `patient_id`, `name`, `target_level`, `status`, `program_type`
- **Impact:** Anyone could enumerate all patients' rehab programs
- **Fix:** Enabled RLS. Patient-scoped. Therapist access via relationship.

#### 6. `phases`
- **Created:** `20241205000000_init_schema.sql`
- **RLS Status:** NEVER ENABLED
- **Impact:** Program phase data (dates, names) exposed -- reveals treatment timelines
- **Fix:** Enabled RLS. Scoped via program -> patient ownership chain.

#### 7. `exercise_templates`
- **Created:** `20241205000000_init_schema.sql`
- **RLS Status:** NEVER ENABLED
- **Note:** This is shared content (exercise library), so read access for all authenticated users is acceptable
- **Fix:** Enabled RLS. Open read for authenticated + anon. Write restricted to therapists.

### MEDIUM: Tables with Overly Permissive `USING(true)` Policies

These tables have RLS enabled but with policies that effectively bypass it by allowing all operations for all roles. This was introduced in migrations `20260207410000_fix_all_remaining_rls.sql` and `20260207430000_fix_remaining_rls_comprehensive.sql` to fix demo mode issues.

**Root Cause:** Demo mode uses the `anon` key, and `auth.uid()` returns `NULL` for anonymous users. Rather than implementing proper demo authentication (e.g., signing the demo user into Supabase Auth), the fix was to open all policies to `USING(true)`.

| # | Table | Has `patient_id`? | Contains Sensitive Data? | Risk |
|---|-------|-------------------|--------------------------|------|
| 1 | `streak_records` | Yes | Engagement metrics | Medium |
| 2 | `streak_history` | Yes | Daily activity history | Medium |
| 3 | `daily_readiness` | Yes | Health readiness scores | Medium |
| 4 | `arm_care_assessments` | Yes | Clinical assessments | High |
| 5 | `body_comp_measurements` | Yes | Body weight, fat %, BMI | High |
| 6 | `manual_sessions` | Yes | Workout sessions | Medium |
| 7 | `patient_goals` | Yes | Treatment goals | Medium |
| 8 | `notification_settings` | Yes | User preferences | Low |
| 9 | `prescription_notification_preferences` | Yes | Notification prefs | Low |
| 10 | `workout_modifications` | Yes | Workout changes | Medium |
| 11 | `manual_session_exercises` | No (via session) | Exercise data | Medium |
| 12 | `patient_favorite_templates` | Yes | User preferences | Low |
| 13 | `workout_prescriptions` | Yes | Clinical prescriptions | High |
| 14 | `sessions` | No (via phase) | Workout data | Medium |
| 15 | `session_exercises` | No (via session) | Exercise data | Medium |
| 16 | `exercise_logs` | Yes | Exercise completion data | Medium |
| 17 | `patient_workout_templates` | Yes | User templates | Low |
| 18 | `system_workout_templates` | No | Shared templates | Low |

**Recommended Fix (not applied in this migration to avoid breaking demo):**

```sql
-- Pattern for patient_id-scoped tables:
CREATE POLICY "table_patient_select" ON table_name
    FOR SELECT TO authenticated
    USING (
        is_own_patient(patient_id)
        OR is_therapist_of_patient(patient_id)
    );

CREATE POLICY "table_anon_select" ON table_name
    FOR SELECT TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

-- Pattern for session-chain tables (no direct patient_id):
CREATE POLICY "sessions_select" ON sessions
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM phases ph
            JOIN programs pr ON ph.program_id = pr.id
            WHERE ph.id = sessions.phase_id
            AND (is_own_patient(pr.patient_id) OR is_therapist_of_patient(pr.patient_id))
        )
    );
```

### LOW: System/Infrastructure Tables Without RLS

These tables contain system metadata, not patient data. RLS is less critical but still best practice.

| Table | Purpose | Fix Applied |
|-------|---------|-------------|
| `slow_query_log` | DB performance monitoring | Service-role only |
| `query_performance_log` | Query timing data | Service-role only |
| `cache_config` | Cache settings | Read for authenticated, write for service-role |
| `workload_flags_job_log` | Cron job logs | Service-role only |

### INFO: LIMS Tables (17+ tables) Without RLS

The LIMS (Laboratory Information Management System) schema was created in migration `20260107000000_lims_schema.sql` with **zero RLS policies**. This is a separate system for laboratory operations.

| Table | Contains |
|-------|----------|
| `lims_materials` | Compound/reagent catalog |
| `lims_batches` | Material lots with QC status |
| `lims_aliquots` | Sample portions with barcodes |
| `lims_containers` | Plates, tubes, racks |
| `lims_wells` | Container well positions |
| `lims_samples` | Patient/research samples |
| `lims_protocols` | Lab protocols |
| `lims_runs` | Experiment runs |
| `lims_run_containers` | Run-container assignments |
| `lims_instruments` | Lab instruments |
| `lims_instrument_maintenance` | Calibration/maintenance logs |
| `lims_observations` | Measurement data |
| `lims_feature_definitions` | Feature schemas |
| `lims_features` | Extracted features |
| `lims_compute_recipes` | Analysis pipelines |
| `lims_compute_runs` | Pipeline executions |
| `lims_datasets` | Data collections |
| `lims_dataset_lineage` | Data provenance |
| `lims_custody_log` | Chain of custody |
| `lims_schema_version` | Schema version tracking |

**Fix Applied:** RLS enabled with service-role full access + therapist read access.

### OK: Tables with Proper RLS

The following tables have proper RLS with `auth.uid()` scoping:

- `patients` -- user_id scoped + therapist access + demo bypass
- `user_roles` -- user_id scoped
- `therapist_patients` -- scoped to therapist_id/patient_id
- `ai_conversations`, `ai_messages` -- user_id scoped
- `ai_chat_sessions`, `ai_chat_messages` -- user_id scoped
- `ai_coach_conversations`, `ai_coach_messages` -- patient_id scoped
- `scheduled_sessions` -- patient_id scoped
- `nutrition_logs`, `nutrition_goals` -- patient_id scoped
- `meal_plans`, `meal_plan_items` -- patient_id scoped
- `help_articles` -- public read
- `data_export_requests` -- user_id scoped
- `audit_logs` -- admin scoped
- `therapist_access_logs` -- therapist scoped
- `push_notification_tokens`, `notification_logs` -- user_id scoped
- `workout_templates`, `template_phases`, `template_sessions` -- public read
- `message_threads`, `messages` -- participant scoped
- `readiness_adjustments`, `readiness_metrics` -- patient scoped
- `interval_block_templates`, `session_interval_blocks` -- scoped
- `video_views` -- user scoped
- `program_library` -- public read
- `program_enrollments` -- patient scoped
- `patient_favorite_exercises` -- patient scoped
- `interval_templates`, `workout_timers`, `timer_presets` -- various
- `fatigue_accumulation` -- patient + therapist scoped
- `deload_recommendations`, `active_deload_periods` -- patient + therapist scoped
- `health_kit_data`, `hrv_baselines` -- patient + therapist scoped
- `supplement_*` tables -- patient scoped
- `fasting_*` tables -- patient scoped
- `lab_results`, `biomarker_values`, `biomarker_reference_ranges` -- scoped
- `recovery_sessions`, `recovery_protocols` -- scoped
- All `rts_*` tables (8 tables) -- proper patient/therapist scoping
- `clinical_assessments`, `outcome_measures`, `soap_notes` -- therapist scoped
- `clinical_templates`, `visit_summaries` -- therapist scoped
- `safety_rules`, `patient_alerts` -- therapist scoped
- `weekly_reports`, `report_schedules` -- therapist scoped
- `safety_incidents`, `kpi_events` -- therapist/admin scoped
- `data_conflicts`, `conflict_audit_log` -- patient + service_role scoped
- `protocol_templates`, `athlete_plans`, `assigned_tasks` -- role-based
- `user_subscriptions` -- user_id scoped
- `approval_requests` -- patient + therapist scoped
- `exercise_embeddings` -- authenticated read, service_role write
- `engagement_scores` -- patient scoped + service_role
- `analytics_events`, `analytics_pipeline_status` -- service_role
- `app_feedback` -- user scoped
- `wearable_connections` -- user scoped
- `daily_checkins` -- patient scoped
- `load_progression_history`, `deload_triggers`, `deload_history` -- scoped
- `recovery_impact_analyses` -- patient scoped
- `waitlist` -- anon insert, authenticated manage
- `premium_packs` -- public read
- `user_pack_subscriptions` -- user scoped
- `linking_codes` -- patient scoped
- `automation_webhooks`, `automation_logs` -- therapist scoped
- `deferred_deep_links` -- public insert, authenticated claim
- `user_notification_preferences` -- user scoped
- `weekly_summary_preferences`, `weekly_summary_history` -- patient scoped
- `data_consents`, `consent_audit_log` -- patient scoped
- `patient_achievements` -- patient scoped
- `soap_note_templates` -- therapist scoped
- `failed_login_attempts` -- user scoped
- `evidence_citations` -- public read

---

## DISABLE RLS History (Red Flags)

The following migrations explicitly disabled RLS. Each represents a point where security was relaxed:

| Migration | Table | Reason |
|-----------|-------|--------|
| `20260105000015_disable_rls_temporarily.sql` | `daily_readiness` | Debugging |
| `20260201000006_daily_readiness_no_rls.sql` | `daily_readiness` | Debugging |
| `20260201000011_daily_readiness_disable_rls.sql` | `daily_readiness` | Debugging |
| `20260202180000_daily_readiness_disable_rls.sql` | `daily_readiness` | Debugging |
| `20260210030004_patients_disable_rls_debug.sql` | `patients` | Debugging |
| `20260110000099_disable_rls_workout_timers.sql` | `workout_timers` | Debugging |
| `20251228000002_simple_rls_fix.sql` | `exercise_logs`, `session_exercises`, `scheduled_sessions`, `ai_chat_sessions`, `ai_chat_messages` | Quick fix |
| `20260207410000_fix_all_remaining_rls.sql` | 9 tables | Demo mode fix |
| `20260207430000_fix_remaining_rls_comprehensive.sql` | 9 tables | Demo mode fix |
| `20260207370000_fix_sessions_rls.sql` | `sessions`, `session_exercises`, `scheduled_sessions` | Demo mode fix |
| `20260207360000_debug_and_fix_exercise_logs.sql` | `exercise_logs` | Demo mode fix |

**Pattern:** RLS was repeatedly disabled/opened on `daily_readiness` (11+ migrations!) and other tables due to demo mode conflicts. The root cause is that demo mode uses anonymous access where `auth.uid()` is NULL.

---

## Recommendations

### Immediate (This Migration -- Applied)

1. Enable RLS on `therapists`, `pain_logs`, `bullpen_logs`, `session_notes`, `programs`, `phases`, `exercise_templates`
2. Enable RLS on LIMS tables with service-role access
3. Enable RLS on system tables (`slow_query_log`, etc.)
4. Add helper functions (`is_own_patient`, `is_therapist_of_patient`) for consistent policy patterns

### Short-Term (Next Sprint)

1. **Fix demo mode authentication:** Sign the demo user into Supabase Auth with a real JWT token scoped to the demo patient. This eliminates the need for `USING(true)` policies.
2. **Tighten the 18 overly permissive tables** once demo auth is fixed. Use the `is_own_patient()` and `is_therapist_of_patient()` helper functions.
3. **Add DELETE policies** where missing (several tables only have SELECT/INSERT/UPDATE).

### Medium-Term

1. Add RLS tests to CI pipeline -- verify that user A cannot read user B's data.
2. Create a `check_rls_coverage.sql` script that queries `pg_class` and `pg_policies` to detect tables without RLS.
3. Consider column-level security for highly sensitive fields (e.g., `pain_logs.notes`).
4. Audit GRANT statements -- several tables grant ALL to `anon` which is overly broad.

### Long-Term

1. Replace hardcoded demo patient UUID checks with a proper demo mode flag in JWT claims.
2. Implement role-based access control (RBAC) using `user_roles` table consistently across all policies.
3. Add audit logging for RLS policy changes.

---

## Migration Safety

The fix migration (`20260222120000_rls_audit_fixes.sql`) is safe to apply because:

- All `ALTER TABLE ... ENABLE ROW LEVEL SECURITY` statements are no-ops if already enabled
- All policies use `DROP POLICY IF EXISTS` before `CREATE POLICY`
- Helper functions use `CREATE OR REPLACE`
- Table existence is checked before modifying (via `DO $$ ... IF EXISTS` blocks)
- The migration is wrapped in a `BEGIN ... COMMIT` transaction
- Overly permissive tables are documented but NOT changed to avoid breaking demo mode
- LIMS tables get read access for therapists (existing usage pattern)
