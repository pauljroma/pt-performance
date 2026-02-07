-- Fix exercise_logs RLS policy
-- Allow patients to insert their own exercise logs

-- Enable RLS if not already enabled
ALTER TABLE public.exercise_logs ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to recreate them properly
DROP POLICY IF EXISTS "Users can view own exercise logs" ON public.exercise_logs;
DROP POLICY IF EXISTS "Users can insert own exercise logs" ON public.exercise_logs;
DROP POLICY IF EXISTS "Users can update own exercise logs" ON public.exercise_logs;
DROP POLICY IF EXISTS "Therapists can manage patient exercise logs" ON public.exercise_logs;

-- Create comprehensive policies
CREATE POLICY "Users can view own exercise logs"
ON public.exercise_logs FOR SELECT
USING (
    patient_id IN (
        SELECT id FROM public.patients WHERE user_id = auth.uid()
    )
    OR
    patient_id::text = auth.uid()::text
    OR
    patient_id = auth.uid()
);

CREATE POLICY "Users can insert own exercise logs"
ON public.exercise_logs FOR INSERT
WITH CHECK (
    patient_id IN (
        SELECT id FROM public.patients WHERE user_id = auth.uid()
    )
    OR
    patient_id::text = auth.uid()::text
    OR
    patient_id = auth.uid()
);

CREATE POLICY "Users can update own exercise logs"
ON public.exercise_logs FOR UPDATE
USING (
    patient_id IN (
        SELECT id FROM public.patients WHERE user_id = auth.uid()
    )
    OR
    patient_id::text = auth.uid()::text
    OR
    patient_id = auth.uid()
);

-- Therapists can manage their patients' exercise logs
CREATE POLICY "Therapists can manage patient exercise logs"
ON public.exercise_logs FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM public.patients p
        JOIN public.therapists t ON p.therapist_id = t.id
        WHERE p.id = exercise_logs.patient_id
        AND t.user_id = auth.uid()
    )
);

-- Grant table permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.exercise_logs TO authenticated;
GRANT SELECT ON public.exercise_logs TO anon;

NOTIFY pgrst, 'reload schema';
