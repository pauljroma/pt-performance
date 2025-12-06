# Database Schema Structure Summary

**Generated:** 2025-12-06
**Agent:** Agent 1
**Status:** Phase 1 Data Layer Complete

---

## Schema Overview

### Database Statistics
- **Total Tables:** 19
- **Total Views:** 7
- **Total CHECK Constraints:** 23
- **RLS Policies:** 30+
- **Indexes:** 20+

---

## Entity Relationship Diagram (Text)

```
therapists (1) ──────> (N) patients
    │
    │
    └──────> (N) protocol_templates

patients (1) ──────> (N) programs
    │
    ├──────> (N) exercise_logs
    ├──────> (N) pain_logs
    ├──────> (N) pain_flags
    ├──────> (N) bullpen_logs
    ├──────> (N) plyo_logs
    ├──────> (N) body_comp_measurements
    └──────> (N) session_notes

programs (1) ──────> (N) phases
    │
    └──────> (1) program_protocol_links

phases (1) ──────> (N) sessions

sessions (1) ──────> (N) session_exercises
    │
    └──────> (N) session_status

exercise_templates (1) ──────> (N) session_exercises

session_exercises (1) ──────> (N) exercise_logs

protocol_templates (1) ──────> (N) protocol_phases

protocol_phases (1) ──────> (N) protocol_constraints
```

---

## Tables by Layer

### Layer 1: User Management
```
therapists
├── id (uuid, PK)
├── user_id (uuid, FK to auth.users)
├── first_name (text)
├── last_name (text)
├── email (text)
└── created_at (timestamptz)
```

### Layer 2: Patient Management
```
patients
├── id (uuid, PK)
├── therapist_id (uuid, FK to therapists)
├── user_id (uuid, FK to auth.users)
├── first_name, last_name (text)
├── date_of_birth (date)
├── sport, position (text)
├── dominant_hand (text)
├── height_in, weight_lb (numeric)
├── medical_history (jsonb)
├── medications (jsonb)
├── goals (text)
├── email (text)
└── created_at (timestamptz)
```

### Layer 3: Program Structure
```
programs
├── id (uuid, PK)
├── patient_id (uuid, FK to patients)
├── name, description (text)
├── start_date, end_date (date)
├── status (text) CHECK: planned/active/completed/paused
├── metadata (jsonb)
└── created_at (timestamptz)

phases
├── id (uuid, PK)
├── program_id (uuid, FK to programs)
├── name (text)
├── sequence (int)
├── start_date, end_date (date)
├── duration_weeks (int)
├── goals (text)
├── constraints (jsonb)
├── notes (text)
└── created_at (timestamptz)

sessions
├── id (uuid, PK)
├── phase_id (uuid, FK to phases)
├── name (text)
├── sequence (int)
├── weekday (int) -- 0=Sunday, 6=Saturday
├── intensity_rating (numeric) CHECK: 0-10
├── is_throwing_day (boolean)
├── notes (text)
└── created_at (timestamptz)
```

### Layer 4: Exercise System
```
exercise_templates
├── id (uuid, PK)
├── name (text)
├── category (text) -- strength, mobility, plyo, bullpen, cardio
├── body_region (text)
├── equipment (text)
├── load_type (text)
├── rm_method (text)
├── primary_muscle_group (text)
├── is_primary_lift (boolean)
├── default_rm_method (text)
├── movement_pattern (text)
├── clinical_tags (jsonb)
├── throwing_tags (jsonb)
├── programming_metadata (jsonb)
├── cueing (text)
└── created_at (timestamptz)

session_exercises
├── id (uuid, PK)
├── session_id (uuid, FK to sessions)
├── exercise_template_id (uuid, FK to exercise_templates)
├── target_sets, target_reps (int)
├── target_load (numeric)
├── target_rpe (numeric) CHECK: 0-10
├── tempo (text)
├── sequence (int)
├── notes (text)
└── created_at (timestamptz)
```

### Layer 5: Performance Tracking
```
exercise_logs
├── id (uuid, PK)
├── patient_id (uuid, FK to patients)
├── session_id (uuid, FK to sessions)
├── session_exercise_id (uuid, FK to session_exercises)
├── performed_at (timestamptz)
├── set_number (int)
├── actual_reps (int)
├── actual_load (numeric)
├── rpe (numeric) CHECK: 0-10
├── pain_score (numeric) CHECK: 0-10
├── rm_estimate (numeric)
├── is_pr (boolean)
└── notes (text)

bullpen_logs
├── id (uuid, PK)
├── patient_id (uuid, FK to patients)
├── logged_at (timestamptz)
├── pitch_type (text)
├── velocity (numeric) CHECK: 40-110
├── command_rating (numeric) CHECK: 1-10
├── pitch_count (int)
├── pain_score (numeric) CHECK: 0-10
├── missed_spot_count, hit_spot_count (int)
├── hit_spot_pct (numeric)
├── avg_velocity (numeric)
├── ball_weight_oz (numeric)
├── is_plyo (boolean)
├── drill_name (text)
└── notes (text)

plyo_logs
├── id (uuid, PK)
├── patient_id (uuid, FK to patients)
├── logged_at (timestamptz)
├── drill_name (text)
├── ball_weight_oz (numeric)
├── velocity (numeric) CHECK: 40-110
├── throw_count (int)
├── pain_score (numeric) CHECK: 0-10
└── notes (text)

pain_logs
├── id (uuid, PK)
├── patient_id (uuid, FK to patients)
├── session_id (uuid, FK to sessions)
├── logged_at (timestamptz)
├── pain_rest (numeric) CHECK: 0-10
├── pain_during (numeric) CHECK: 0-10
├── pain_after (numeric) CHECK: 0-10
└── notes (text)

body_comp_measurements
├── id (uuid, PK)
├── patient_id (uuid, FK to patients)
├── measured_at (date)
├── weight_lb (numeric)
├── body_fat_pct (numeric)
├── lean_mass_lb (numeric)
└── notes (text)
```

### Layer 6: Clinical Monitoring
```
pain_flags
├── id (uuid, PK)
├── patient_id (uuid, FK to patients)
├── flag_type (text) CHECK: pain_spike/chronic_pain/throwing_pain/positive_adaptation
├── severity (text) CHECK: low/medium/high
├── triggered_at (timestamptz)
├── resolved_at (timestamptz)
├── context (jsonb)
└── notes (text)

session_status
├── id (uuid, PK)
├── patient_id (uuid, FK to patients)
├── session_id (uuid, FK to sessions)
├── scheduled_date (date)
├── status (text) CHECK: scheduled/completed/missed/skipped
├── completed_at (timestamptz)
├── notes (text)
└── created_at (timestamptz)

session_notes
├── id (uuid, PK)
├── patient_id (uuid, FK to patients)
├── session_id (uuid, FK to sessions)
├── author_type (text) CHECK: therapist/patient/system
├── content (text)
└── created_at (timestamptz)
```

### Layer 7: Protocol System
```
protocol_templates
├── id (uuid, PK)
├── name (text)
├── protocol_type (text) -- rehab/performance/return_to_play
├── indication (text)
├── sport, position (text)
├── evidence_level (text) CHECK: expert_consensus/case_series/rct/meta_analysis
├── source_reference (text)
├── author_therapist_id (uuid, FK to therapists)
├── total_duration_weeks (int)
├── phases_count (int)
├── typical_frequency_per_week (int)
├── contraindications (jsonb)
├── precautions (jsonb)
├── success_criteria (jsonb)
├── is_active, is_public (boolean)
├── version (int)
├── description, notes (text)
├── created_at, updated_at (timestamptz)
└── UNIQUE(name, version)

protocol_phases
├── id (uuid, PK)
├── protocol_template_id (uuid, FK to protocol_templates)
├── name (text)
├── sequence (int)
├── duration_weeks (int)
├── goals (text)
├── criteria_to_advance (text)
├── frequency_per_week (int)
├── intensity_range_min (int) CHECK: 0-10
├── intensity_range_max (int) CHECK: 0-10
├── exercise_categories (jsonb)
├── contraindicated_exercises (jsonb)
├── notes (text)
├── created_at (timestamptz)
└── UNIQUE(protocol_template_id, sequence)

protocol_constraints
├── id (uuid, PK)
├── protocol_phase_id (uuid, FK to protocol_phases)
├── constraint_type (text) CHECK: 12 types
├── constraint_value (numeric)
├── constraint_value_text (text)
├── rationale (text)
├── violation_severity (text) CHECK: warning/error/critical
├── applies_from_week, applies_until_week (int)
├── is_active (boolean)
└── created_at (timestamptz)

program_protocol_links
├── id (uuid, PK)
├── program_id (uuid, FK to programs)
├── protocol_template_id (uuid, FK to protocol_templates)
├── instantiated_at (timestamptz)
├── instantiated_by_therapist_id (uuid, FK to therapists)
├── customizations (jsonb)
├── is_modified (boolean)
├── notes (text)
└── UNIQUE(program_id)
```

---

## Analytics Views

### 1. vw_patient_adherence
**Purpose:** Track patient adherence to scheduled sessions

**Columns:**
- patient_id
- first_name, last_name
- scheduled_sessions (count)
- completed_sessions (count)
- adherence_pct (calculated)

### 2. vw_pain_trend
**Purpose:** Track pain levels over time

**Columns:**
- patient_id
- day (date)
- avg_pain_during (numeric)

### 3. vw_throwing_workload
**Purpose:** Daily throwing workload summary with flags

**Columns:**
- patient_id
- session_date
- total_pitches
- avg_velocity_fastball
- avg_hit_spot_pct
- max_pain
- high_workload_flag (boolean)
- velocity_drop_flag (boolean)

### 4. vw_onramp_progress
**Purpose:** On-ramp program progression tracking

**Columns:**
- patient_id, program_id, phase_id
- program_name, phase_name
- week
- target_sessions, completed_sessions
- avg_velocity, max_pain

### 5. vw_pain_summary
**Purpose:** Patient pain summary with trend indicators

**Columns:**
- patient_id, first_name, last_name
- avg_pain_7d, avg_pain_14d
- max_pain_7d
- pain_indicator (red/yellow/green)
- active_flags (count)

### 6. vw_therapist_patient_summary
**Purpose:** Comprehensive patient summary for therapist dashboard

**Columns:**
- patient_id, first_name, last_name
- sport, position
- therapist_first_name, therapist_last_name
- active_program_id, active_program_name
- program_status, current_phase
- last_session_date
- adherence_pct
- avg_pain_7d, pain_indicator
- flag_count

### 7. vw_performance_trends
**Purpose:** Velocity and command trends for pitchers

**Columns:**
- patient_id
- session_date
- avg_velocity
- avg_command
- max_pain

---

## CHECK Constraints Summary

### Pain Scores (0-10 scale)
1. `exercise_logs.pain_score`
2. `pain_logs.pain_rest`
3. `pain_logs.pain_during`
4. `pain_logs.pain_after`
5. `bullpen_logs.pain_score`
6. `plyo_logs.pain_score`

### RPE - Rate of Perceived Exertion (0-10)
7. `exercise_logs.rpe`
8. `session_exercises.target_rpe`

### Velocity (40-110 mph)
9. `bullpen_logs.velocity`
10. `plyo_logs.velocity`

### Command & Intensity (0-10 or 1-10)
11. `bullpen_logs.command_rating` (1-10)
12. `sessions.intensity_rating` (0-10)
13. `protocol_phases.intensity_range_min` (0-10)
14. `protocol_phases.intensity_range_max` (0-10)

### Status Enums
15. `programs.status` (planned/active/completed/paused)
16. `session_status.status` (scheduled/completed/missed/skipped)
17. `session_notes.author_type` (therapist/patient/system)
18. `pain_flags.flag_type` (4 types)
19. `pain_flags.severity` (low/medium/high)
20. `protocol_templates.evidence_level` (4 levels)
21. `protocol_constraints.constraint_type` (12 types)
22. `protocol_constraints.violation_severity` (warning/error/critical)
23. `exercise_templates.default_rm_method` (4 methods)

---

## Indexes Summary

### Primary Keys
- All 19 tables have UUID primary keys

### Foreign Key Indexes
- All foreign key columns indexed
- Improves join performance

### Query Optimization Indexes
```sql
-- Exercise search
idx_exercise_templates_category
idx_exercise_templates_body_region
idx_exercise_templates_movement_pattern

-- JSONB search (GIN indexes)
idx_exercise_templates_clinical_tags
idx_exercise_templates_throwing_tags

-- Performance tracking
idx_exercise_logs_patient_id
idx_exercise_logs_session_id
idx_exercise_logs_performed_at

idx_pain_logs_patient_id
idx_pain_logs_logged_at

idx_bullpen_logs_patient_id
idx_bullpen_logs_logged_at

-- Program management
idx_programs_patient_id
idx_programs_status

idx_session_status_patient_id
idx_session_status_scheduled_date

idx_pain_flags_patient_id
idx_pain_flags_resolved_at (partial: WHERE resolved_at IS NULL)

-- Protocol system
idx_protocol_templates_protocol_type
idx_protocol_templates_sport
idx_protocol_templates_is_active (partial: WHERE is_active = TRUE)
idx_protocol_templates_is_public (partial: WHERE is_public = TRUE)

idx_protocol_phases_template_id
idx_protocol_phases_sequence

idx_protocol_constraints_phase_id
idx_protocol_constraints_type

idx_program_protocol_links_program_id
idx_program_protocol_links_template_id
```

---

## Row Level Security (RLS)

### Enabled Tables
All 19 tables have RLS enabled

### Policy Categories

**Therapist Policies:**
- Therapists can see all their patients' data
- Therapists can see all public protocols
- Therapists can create/edit their own protocols
- Therapists can see all exercise templates

**Patient Policies:**
- Patients can see only their own data
- Patients cannot see other patients' data
- Patients can read public protocols
- Patients can read exercise templates

**Protocol Policies:**
- Public protocols visible to all authenticated users
- Private protocols visible only to author
- Protocol phases/constraints inherit template permissions

**Exercise Template Policies:**
- All authenticated users can read
- Only therapists can write

---

## Sample Data Included

### Protocol Templates (3)
1. Tommy John - Post-Op 12 Week Return to Throw
2. Rotator Cuff Repair - 16 Week Progressive Strengthening
3. ACL Reconstruction - 24 Week Return to Sport

### Protocol Phases (14 total)
- Tommy John: 4 phases
- Rotator Cuff: 4 phases
- ACL: 6 phases

### Protocol Constraints (10+)
- Velocity limits
- Pain thresholds
- Pitch count limits
- Load restrictions
- Exercise contraindications
- Rest requirements

---

## File Sizes

| File | Size (bytes) | Tables | Views | Constraints |
|------|--------------|--------|-------|-------------|
| 001_init_supabase.sql | 5,739 | 12 | 2 | 2 |
| 002_epic_enhancements.sql | 15,913 | 3 | 5 | 5 |
| 003_agent1_constraints_and_protocols.sql | 30,795 | 4 | 0 | 16 |
| **TOTAL** | **52,447** | **19** | **7** | **23** |

---

## Deployment Readiness

### Status: READY TO DEPLOY

### Requirements
- [x] Schema files validated
- [x] Foreign keys checked
- [x] Constraints tested
- [x] RLS policies defined
- [x] Indexes created
- [x] Sample data included
- [ ] SUPABASE_URL configured (pending)

### Deployment Command
```bash
python3 deploy_schema_to_supabase.py
```

---

**Schema Structure Summary Complete**
**Agent 1 - Phase 1 Data Layer**
**2025-12-06**
