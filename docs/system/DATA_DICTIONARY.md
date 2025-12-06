# DATA DICTIONARY – PT PLATFORM

**Purpose:** Define every field so agents & developers avoid misinterpretation.

---

## patients
- **id** (uuid) - Primary key
- **therapist_id** (uuid) - Foreign key to therapists table
- **first_name** (text) - Patient first name
- **last_name** (text) - Patient last name
- **date_of_birth** (date) - DOB for age calculation
- **sport** (text) - e.g., "Baseball", "Football"
- **position** (text) - e.g., "RHP", "SS", "QB"
- **dominant_hand** (text) - "Left", "Right", "Ambidextrous"
- **height_in** (numeric) - Height in inches
- **weight_lb** (numeric) - Weight in pounds
- **medical_history** (jsonb) - Structured: {injuries: [], surgeries: [], chronic_conditions: []}
- **medications** (jsonb) - Structured: {current: [{name, dose, schedule}], allergies: []}
- **goals** (text) - Free-text short-term and long-term goals
- **email** (text) - For auth integration
- **created_at** (timestamptz) - Record creation timestamp

---

## therapists
- **id** (uuid) - Primary key
- **user_id** (uuid) - Maps to Supabase auth.users.id
- **first_name** (text)
- **last_name** (text)
- **email** (text) - Unique, for login
- **created_at** (timestamptz)

---

## programs
- **id** (uuid) - Primary key
- **patient_id** (uuid) - Foreign key to patients
- **name** (text) - e.g., "2025 In-Season Maintenance"
- **description** (text) - Free-text overview
- **start_date** (date)
- **end_date** (date)
- **status** (text) - CHECK: 'planned', 'active', 'completed', 'paused'
- **metadata** (jsonb) - {target_level, role, return_to_throw_target_date}
- **created_at** (timestamptz)

---

## phases
- **id** (uuid) - Primary key
- **program_id** (uuid) - Foreign key to programs
- **name** (text) - e.g., "On-Ramp Week 3"
- **sequence** (int) - Order within program
- **start_date** (date)
- **end_date** (date)
- **duration_weeks** (int) - Expected duration
- **goals** (text) - Phase objectives
- **constraints** (jsonb) - {no_overhead_until_week, max_intensity_pct, restrictions}
- **notes** (text)
- **created_at** (timestamptz)

---

## sessions
- **id** (uuid) - Primary key
- **phase_id** (uuid) - Foreign key to phases
- **name** (text) - e.g., "Day 2 – Lower Body + Plyo"
- **sequence** (int) - Order within phase
- **weekday** (int) - 0=Sunday, 6=Saturday (optional)
- **intensity_rating** (numeric) - 0-10 scale
- **is_throwing_day** (boolean) - True if bullpen/plyo included
- **notes** (text)
- **created_at** (timestamptz)

---

## exercise_templates
- **id** (uuid) - Primary key
- **name** (text) - e.g., "Trap Bar Deadlift"
- **category** (text) - strength, mobility, plyo, bullpen, rehab, stability, cardio
- **body_region** (text) - shoulder, elbow, hip, knee, spine, etc.
- **equipment** (text) - DB, BB, KB, bands, etc.
- **load_type** (text) - weight, bodyweight, distance, time, velocity
- **rm_method** (text) - epley, brzycki, lombardi, none
- **cueing** (text) - Coaching cues
- **primary_muscle_group** (text)
- **is_primary_lift** (boolean)
- **default_rm_method** (text) - For auto-calc
- **movement_pattern** (text) - hinge, squat, push, pull, rotation, carry
- **clinical_tags** (jsonb) - Array of clinical flags
- **throwing_tags** (jsonb) - {pitch_type_supported, ball_weight_oz, drill_category}
- **programming_metadata** (jsonb) - {default_set_rep_scheme, progression_type, tissue_capacity_rating}
- **created_at** (timestamptz)

---

## session_exercises
- **id** (uuid) - Primary key
- **session_id** (uuid) - Foreign key to sessions
- **exercise_template_id** (uuid) - Foreign key to exercise_templates
- **target_sets** (int)
- **target_reps** (int)
- **target_load** (numeric) - In pounds or kg
- **target_rpe** (numeric) - 0-10
- **tempo** (text) - e.g., "3-1-1-0"
- **notes** (text)
- **sequence** (int) - Order in session
- **created_at** (timestamptz)

---

## exercise_logs
- **id** (uuid) - Primary key
- **patient_id** (uuid) - Foreign key to patients
- **session_id** (uuid) - Foreign key to sessions
- **session_exercise_id** (uuid) - Foreign key to session_exercises
- **performed_at** (timestamptz) - When logged
- **set_number** (int) - Which set (1, 2, 3...)
- **actual_reps** (int)
- **actual_load** (numeric)
- **rpe** (numeric) - 0-10
- **pain_score** (numeric) - 0-10 during that exercise
- **rm_estimate** (numeric) - Calculated 1RM
- **is_pr** (boolean) - Personal record flag
- **notes** (text)

---

## pain_logs
- **id** (uuid) - Primary key
- **patient_id** (uuid) - Foreign key to patients
- **session_id** (uuid) - Foreign key to sessions (nullable)
- **logged_at** (timestamptz)
- **pain_rest** (numeric) - 0-10
- **pain_during** (numeric) - 0-10
- **pain_after** (numeric) - 0-10
- **notes** (text)

---

## bullpen_logs
- **id** (uuid) - Primary key
- **patient_id** (uuid) - Foreign key to patients
- **logged_at** (timestamptz)
- **pitch_type** (text) - "4-seam", "slider", "changeup", etc.
- **velocity** (numeric) - mph
- **command_rating** (numeric) - 1-10
- **pitch_count** (int)
- **pain_score** (numeric) - 0-10
- **missed_spot_count** (int)
- **hit_spot_count** (int)
- **hit_spot_pct** (numeric) - Calculated
- **avg_velocity** (numeric) - Per session per pitch type
- **ball_weight_oz** (numeric) - For plyo drills
- **is_plyo** (boolean)
- **drill_name** (text)
- **notes** (text)

---

## plyo_logs
- **id** (uuid) - Primary key
- **patient_id** (uuid) - Foreign key to patients
- **logged_at** (timestamptz)
- **drill_name** (text)
- **ball_weight_oz** (numeric)
- **velocity** (numeric) - mph
- **throw_count** (int)
- **pain_score** (numeric) - 0-10
- **notes** (text)

---

## body_comp_measurements
- **id** (uuid) - Primary key
- **patient_id** (uuid) - Foreign key to patients
- **measured_at** (date)
- **weight_lb** (numeric)
- **body_fat_pct** (numeric)
- **lean_mass_lb** (numeric)
- **notes** (text)

---

## session_notes
- **id** (uuid) - Primary key
- **patient_id** (uuid) - Foreign key to patients
- **session_id** (uuid) - Foreign key to sessions (nullable)
- **author_type** (text) - CHECK: 'therapist', 'patient', 'system'
- **content** (text)
- **created_at** (timestamptz)

---

## session_status
- **id** (uuid) - Primary key
- **patient_id** (uuid) - Foreign key to patients
- **session_id** (uuid) - Foreign key to sessions
- **scheduled_date** (date)
- **status** (text) - CHECK: 'scheduled', 'completed', 'missed', 'skipped'
- **completed_at** (timestamptz)
- **notes** (text)
- **created_at** (timestamptz)
- **UNIQUE** (patient_id, session_id, scheduled_date)

---

## pain_flags
- **id** (uuid) - Primary key
- **patient_id** (uuid) - Foreign key to patients
- **flag_type** (text) - CHECK: 'pain_spike', 'chronic_pain', 'throwing_pain', 'positive_adaptation'
- **severity** (text) - CHECK: 'low', 'medium', 'high'
- **triggered_at** (timestamptz)
- **resolved_at** (timestamptz) - Null if active
- **context** (jsonb) - Related session IDs, metrics
- **notes** (text)

---

## Views

### vw_patient_adherence
Computes adherence % per patient based on scheduled vs completed sessions.

### vw_pain_trend
Aggregates pain over time per patient.

### vw_pain_summary
Recent pain metrics + flags for dashboard.

### vw_throwing_workload
Daily throwing metrics with automatic flags.

### vw_onramp_progress
Week-by-week on-ramp progression.

### vw_therapist_patient_summary
Complete patient overview for therapist dashboard.

### vw_performance_trends
Velocity and strength trends over time.

---

## DoD

- All analytics & agents use dictionary terminology
- Schema changes require dictionary update
- No field misinterpretation in agent prompts
- Complete coverage of all tables and key fields
