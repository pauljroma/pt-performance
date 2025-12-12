# Seed Data Requirements for PT Performance Demo

## Executive Summary

**Status**: SEED DATA EXISTS AND IS CONFIGURED CORRECTLY

The database has been successfully seeded with demo data. Build 8's "data could not be read because it doesn't exist" error is **NOT** caused by missing seed data, but likely by:
1. Authentication/session management issues
2. API endpoint configuration
3. Supabase query permissions or RLS (Row Level Security) policies

## Verification Results

### Database Verification (2025-12-09)

```
✅ Demo therapist exists: Sarah Thompson (demo-pt@ptperformance.app)
✅ Demo patient exists: John Brebbia (demo-athlete@ptperformance.app)
✅ Active program created: 4-Week Return to Throw
✅ Phases created: 2 phases (Foundation, Light Throwing)
✅ Sessions created: 6 sessions for Phase 1
✅ Exercise templates: 5 exercises
✅ Today's session: Linked with 10 exercises
```

## Demo Patient Account

### Login Credentials
- **Email**: `demo-athlete@ptperformance.app`
- **Password**: `demo-patient-2025`
- **Patient ID**: `00000000-0000-0000-0000-000000000001`

### Patient Profile
- **Name**: John Brebbia
- **Sport**: Baseball
- **Position**: Pitcher (Right-handed)
- **Birth Date**: 1990-05-27
- **Therapist**: Sarah Thompson

## Seed Data Structure

### 1. Core User Data

#### Therapist (Required for FK relationship)
```sql
INSERT INTO therapists (id, first_name, last_name, email)
VALUES (
  '00000000-0000-0000-0000-000000000100',
  'Sarah',
  'Thompson',
  'demo-pt@ptperformance.app'
);
```

#### Patient
```sql
INSERT INTO patients (
  id,
  therapist_id,
  first_name,
  last_name,
  email,
  date_of_birth,
  sport,
  position
) VALUES (
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000100',
  'John',
  'Brebbia',
  'demo-athlete@ptperformance.app',
  '1990-05-27',
  'Baseball',
  'Pitcher'
);
```

### 2. Program Structure (Required for Session Data)

#### Program
```sql
INSERT INTO programs (
  id,
  patient_id,
  name,
  description,
  start_date,
  end_date,
  status
) VALUES (
  '00000000-0000-0000-0000-000000000200',
  '00000000-0000-0000-0000-000000000001',
  '4-Week Return to Throw',
  'Progressive return-to-throw program for post-tricep strain rehabilitation',
  CURRENT_DATE,
  CURRENT_DATE + INTERVAL '4 weeks',
  'active'
);
```

**Critical**: The program MUST have `status = 'active'` for iOS app to find it.

#### Phases
```sql
-- Phase 1: Foundation (Weeks 1-2)
INSERT INTO phases (
  id,
  program_id,
  name,
  sequence,
  start_date,
  end_date
) VALUES (
  '00000000-0000-0000-0000-000000000301',
  '00000000-0000-0000-0000-000000000200',
  'Foundation',
  1,
  CURRENT_DATE,
  CURRENT_DATE + INTERVAL '2 weeks'
);

-- Phase 2: Light Throwing (Weeks 3-4)
INSERT INTO phases (
  id,
  program_id,
  name,
  sequence,
  start_date,
  end_date
) VALUES (
  '00000000-0000-0000-0000-000000000302',
  '00000000-0000-0000-0000-000000000200',
  'Light Throwing',
  2,
  CURRENT_DATE + INTERVAL '2 weeks' + INTERVAL '1 day',
  CURRENT_DATE + INTERVAL '4 weeks'
);
```

### 3. Sessions (Required for Today's Session View)

The iOS app queries sessions through this relationship chain:
```
sessions -> phases -> programs -> patient
```

**Minimum Required**: At least 1 session in Phase 1 for TODAY

```sql
INSERT INTO sessions (
  id,
  phase_id,
  name,
  sequence,
  weekday
) VALUES (
  '00000000-0000-0000-0000-000000000401',
  '00000000-0000-0000-0000-000000000301',
  'Session 1: Foundation Training',
  1,
  1  -- Monday
);
```

**Currently Seeded**: 6 sessions for Phase 1 (3 sessions/week for 2 weeks)

### 4. Exercise Templates (Exercise Library)

**Minimum Required**: 5 exercise templates

```sql
INSERT INTO exercise_templates (id, name, category, body_region, equipment, load_type) VALUES
('00000000-0000-0000-0000-000000000501', 'Band Pull-Apart', 'Upper Body', 'Shoulder', 'Resistance Band', 'Bodyweight'),
('00000000-0000-0000-0000-000000000502', 'Scapular Wall Slides', 'Upper Body', 'Shoulder', 'None', 'Bodyweight'),
('00000000-0000-0000-0000-000000000503', 'Prone Y Raises', 'Upper Body', 'Shoulder', 'None', 'Bodyweight'),
('00000000-0000-0000-0000-000000000504', 'External Rotation', 'Upper Body', 'Rotator Cuff', 'Dumbbell', 'Weight'),
('00000000-0000-0000-0000-000000000505', 'Plank', 'Core', 'Core', 'None', 'Time');
```

**Full Library Available**: 60+ exercises in `/infra/004_seed_exercise_library.sql`

### 5. Session Exercises (Links Exercises to Sessions)

**Critical**: This is what the iOS app displays in TodaySessionView

```sql
INSERT INTO session_exercises (
  session_id,
  exercise_template_id,
  sequence,
  target_sets,
  target_reps,
  notes
) VALUES
('00000000-0000-0000-0000-000000000401', '00000000-0000-0000-0000-000000000501', 1, 3, 15, 'Focus on squeezing shoulder blades'),
('00000000-0000-0000-0000-000000000401', '00000000-0000-0000-0000-000000000502', 2, 3, 10, 'Maintain wall contact'),
('00000000-0000-0000-0000-000000000401', '00000000-0000-0000-0000-000000000503', 3, 3, 12, 'Keep core engaged'),
('00000000-0000-0000-0000-000000000401', '00000000-0000-0000-0000-000000000504', 4, 3, 10, '5lb dumbbells'),
('00000000-0000-0000-0000-000000000405', '00000000-0000-0000-0000-000000000505', 5, 3, 30, '30 seconds per set');
```

**Currently Seeded**: 10 exercises linked to today's session

## Seed Scripts Available

### 1. Minimal Seed (Python)
**Location**: `/Users/expo/Code/expo/clients/linear-bootstrap/seed_demo_minimal.py`

Creates:
- Demo therapist
- Demo patient

**Run**: `python3 seed_demo_minimal.py`

### 2. Minimal Program (Python)
**Location**: `/Users/expo/Code/expo/clients/linear-bootstrap/seed_minimal_program.py`

Creates:
- 4-week program
- 2 phases
- 6 sessions
- 5 exercise templates
- 5 session exercises for today's session

**Run**: `python3 seed_minimal_program.py`

### 3. Full Demo Data (SQL)
**Location**: `/Users/expo/Code/expo/clients/linear-bootstrap/infra/003_seed_demo_data.sql`

Creates:
- Complete 8-week program
- 4 phases
- 24 sessions
- Pain logs
- Session status tracking
- Therapist notes

**Run via Supabase CLI**: `supabase db run /Users/expo/Code/expo/clients/linear-bootstrap/infra/003_seed_demo_data.sql`

### 4. Exercise Library (SQL)
**Location**: `/Users/expo/Code/expo/clients/linear-bootstrap/infra/004_seed_exercise_library.sql`

Creates:
- 60+ exercise templates
- Comprehensive exercise library covering:
  - Strength training
  - Arm care & rotator cuff
  - Plyometric drills
  - Core exercises
  - Mobility & stretching
  - Throwing-specific exercises

### 5. Session Exercise Prescriptions (SQL)
**Location**: `/Users/expo/Code/expo/clients/linear-bootstrap/infra/005_seed_session_exercises.sql`

Creates:
- Exercise prescriptions for all 24 sessions
- Realistic sets, reps, load, RPE
- Sample exercise logs

## iOS App Query Logic

### TodaySessionViewModel.swift Query

The app fetches today's session using this Supabase query:

```swift
.from("sessions")
.select("""
    *,
    phases!inner(
        id,
        name,
        program_id,
        programs!inner(
            id,
            name,
            patient_id,
            status
        )
    )
""")
.eq("phases.programs.patient_id", value: patientId)
.eq("phases.programs.status", value: "active")
.order("sequence", ascending: true)
.limit(1)
```

**Requirements for Success**:
1. Patient must exist with matching `patient_id`
2. Program must exist with `status = 'active'`
3. Program must have at least 1 phase
4. Phase must have at least 1 session
5. Foreign key relationships must be correct:
   - `sessions.phase_id` -> `phases.id`
   - `phases.program_id` -> `programs.id`
   - `programs.patient_id` -> `patients.id`

### Exercise Query

```swift
.from("session_exercises")
.select("""
    *,
    exercise_templates!inner(
        id,
        name,
        category,
        body_region
    )
""")
.eq("session_id", value: session.id)
.order("sequence", ascending: true)
```

**Requirements**:
1. Session must have linked `session_exercises`
2. Each `session_exercise` must reference a valid `exercise_template`

## Supabase Configuration

### Config.swift Settings

```swift
static let supabaseURL = "https://rpbxeaxlaoyoqkohytlw.supabase.co"
static let supabaseAnonKey = "sb_secret_FYMKefuStzD82VUTplnsuw_GHN_0hb3"

// Demo credentials
static let patientEmail = "demo-athlete@ptperformance.app"
static let patientPassword = "demo-patient-2025"
```

## Troubleshooting Build 8 Error

Since seed data exists and is correctly configured, the "data could not be read because it doesn't exist" error is likely caused by:

### 1. Row Level Security (RLS) Policies
**Issue**: Supabase RLS may be blocking queries even with valid auth

**Check**:
```sql
-- View current RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename;
```

**Solution**: Ensure RLS policies allow authenticated users to read their own data

### 2. Authentication Token Issues
**Issue**: Patient may be logged in but `userId` not properly set in AppState

**Check**: Verify in `PTSupabaseClient.swift` that `userId` is extracted from Supabase session

### 3. API Endpoint Not Responding
**Issue**: Backend `/today-session/:patientId` endpoint may not be deployed

**Check**:
- Is the agent-service running?
- Is the Supabase Edge Function deployed?

### 4. Database Foreign Key Constraints
**Issue**: FK relationships may be broken

**Verify**:
```sql
-- Check patient has active program
SELECT p.id, p.name, p.status
FROM programs p
WHERE p.patient_id = '00000000-0000-0000-0000-000000000001'
AND p.status = 'active';

-- Check program has phases
SELECT ph.id, ph.name, ph.program_id
FROM phases ph
JOIN programs p ON p.id = ph.program_id
WHERE p.patient_id = '00000000-0000-0000-0000-000000000001';

-- Check phases have sessions
SELECT s.id, s.name, s.phase_id
FROM sessions s
JOIN phases ph ON ph.id = s.phase_id
JOIN programs p ON p.id = ph.program_id
WHERE p.patient_id = '00000000-0000-0000-0000-000000000001';
```

## Next Steps for Debugging

1. **Enable Debug Logging**: Check Xcode console for detailed logs from `TodaySessionViewModel`
2. **Test Authentication**: Verify patient can successfully log in and session persists
3. **Test Direct Query**: Use Supabase dashboard to run the exact query the app uses
4. **Check RLS Policies**: Ensure proper read permissions for patients table
5. **Verify Backend**: Test `/today-session/:patientId` endpoint directly

## Conclusion

**Seed data is NOT the issue.** The database has:
- Valid demo patient account
- Active program assigned
- Phases and sessions created
- Exercises linked to sessions

The Build 8 error must be investigated in:
- iOS app authentication flow
- Supabase RLS policies
- API endpoint configuration
- Network connectivity

## Files Reference

| File | Purpose |
|------|---------|
| `seed_demo_minimal.py` | Create therapist + patient |
| `seed_minimal_program.py` | Create program structure |
| `infra/003_seed_demo_data.sql` | Full 8-week demo data |
| `infra/004_seed_exercise_library.sql` | 60+ exercise templates |
| `infra/005_seed_session_exercises.sql` | Link exercises to sessions |
| `verify_migrations.py` | Verify database schema |
| `ios-app/PTPerformance/Config.swift` | Supabase credentials |
| `ios-app/PTPerformance/ViewModels/TodaySessionViewModel.swift` | Session query logic |
