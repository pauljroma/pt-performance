-- Add demo user bypass for RLS policies
-- Demo mode bypasses Supabase auth, so auth.uid() is NULL
-- These policies allow the demo patient to write data

-- Demo patient ID
-- 00000000-0000-0000-0000-000000000001

-- exercise_logs: Add demo bypass policy
CREATE POLICY "Demo user can insert exercise logs"
ON public.exercise_logs FOR INSERT
WITH CHECK (
    patient_id = '00000000-0000-0000-0000-000000000001'::uuid
);

CREATE POLICY "Demo user can update exercise logs"
ON public.exercise_logs FOR UPDATE
USING (
    patient_id = '00000000-0000-0000-0000-000000000001'::uuid
);

CREATE POLICY "Demo user can delete exercise logs"
ON public.exercise_logs FOR DELETE
USING (
    patient_id = '00000000-0000-0000-0000-000000000001'::uuid
);

-- workout_modifications: Add demo bypass policy
CREATE POLICY "Demo user can insert workout modifications"
ON public.workout_modifications FOR INSERT
WITH CHECK (
    patient_id = '00000000-0000-0000-0000-000000000001'::uuid
);

CREATE POLICY "Demo user can update workout modifications"
ON public.workout_modifications FOR UPDATE
USING (
    patient_id = '00000000-0000-0000-0000-000000000001'::uuid
);

-- manual_sessions: Add demo bypass (for manual workout logging)
ALTER TABLE public.manual_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Demo user can manage manual sessions" ON public.manual_sessions;
CREATE POLICY "Demo user can manage manual sessions"
ON public.manual_sessions FOR ALL
USING (
    patient_id = '00000000-0000-0000-0000-000000000001'::uuid
);

-- manual_session_exercises: Add demo bypass via manual_session_id
ALTER TABLE public.manual_session_exercises ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Demo user can manage manual session exercises" ON public.manual_session_exercises;
CREATE POLICY "Demo user can manage manual session exercises"
ON public.manual_session_exercises FOR ALL
USING (
    manual_session_id IN (
        SELECT id FROM public.manual_sessions
        WHERE patient_id = '00000000-0000-0000-0000-000000000001'::uuid
    )
);

-- scheduled_sessions: Allow demo user to update status
ALTER TABLE public.scheduled_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Demo user can update scheduled sessions" ON public.scheduled_sessions;
CREATE POLICY "Demo user can update scheduled sessions"
ON public.scheduled_sessions FOR UPDATE
USING (
    enrollment_id IN (
        SELECT id FROM public.program_enrollments
        WHERE patient_id = '00000000-0000-0000-0000-000000000001'::uuid
    )
);

-- daily_readiness: Allow demo user to manage readiness
ALTER TABLE public.daily_readiness ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Demo user can manage daily readiness" ON public.daily_readiness;
CREATE POLICY "Demo user can manage daily readiness"
ON public.daily_readiness FOR ALL
USING (
    patient_id = '00000000-0000-0000-0000-000000000001'::uuid
);

-- streak_records: Allow demo user to manage streaks
ALTER TABLE public.streak_records ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Demo user can manage streak records" ON public.streak_records;
CREATE POLICY "Demo user can manage streak records"
ON public.streak_records FOR ALL
USING (
    patient_id = '00000000-0000-0000-0000-000000000001'::uuid
);

-- arm_care_assessments: Allow demo user to manage assessments
ALTER TABLE public.arm_care_assessments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Demo user can manage arm care assessments" ON public.arm_care_assessments;
CREATE POLICY "Demo user can manage arm care assessments"
ON public.arm_care_assessments FOR ALL
USING (
    patient_id = '00000000-0000-0000-0000-000000000001'::uuid
);

NOTIFY pgrst, 'reload schema';
