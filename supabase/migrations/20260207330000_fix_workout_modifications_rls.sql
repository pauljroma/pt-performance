-- Fix workout_modifications RLS policy
-- Allow patients to insert their own workout modifications

-- Check existing policies
DO $$
BEGIN
    RAISE NOTICE 'Checking workout_modifications RLS policies...';
END $$;

-- Enable RLS if not already enabled
ALTER TABLE public.workout_modifications ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to recreate them properly
DROP POLICY IF EXISTS "Users can view own workout modifications" ON public.workout_modifications;
DROP POLICY IF EXISTS "Users can insert own workout modifications" ON public.workout_modifications;
DROP POLICY IF EXISTS "Users can update own workout modifications" ON public.workout_modifications;
DROP POLICY IF EXISTS "Therapists can manage patient workout modifications" ON public.workout_modifications;

-- Create comprehensive policies
CREATE POLICY "Users can view own workout modifications"
ON public.workout_modifications FOR SELECT
USING (
    patient_id IN (
        SELECT id FROM public.patients WHERE user_id = auth.uid()
    )
    OR
    patient_id::text = auth.uid()::text
    OR
    patient_id = auth.uid()
);

CREATE POLICY "Users can insert own workout modifications"
ON public.workout_modifications FOR INSERT
WITH CHECK (
    patient_id IN (
        SELECT id FROM public.patients WHERE user_id = auth.uid()
    )
    OR
    patient_id::text = auth.uid()::text
    OR
    patient_id = auth.uid()
);

CREATE POLICY "Users can update own workout modifications"
ON public.workout_modifications FOR UPDATE
USING (
    patient_id IN (
        SELECT id FROM public.patients WHERE user_id = auth.uid()
    )
    OR
    patient_id::text = auth.uid()::text
    OR
    patient_id = auth.uid()
);

-- Therapists can manage their patients' modifications
CREATE POLICY "Therapists can manage patient workout modifications"
ON public.workout_modifications FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM public.patients p
        JOIN public.therapists t ON p.therapist_id = t.id
        WHERE p.id = workout_modifications.patient_id
        AND t.user_id = auth.uid()
    )
);

-- Grant table permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.workout_modifications TO authenticated;
GRANT SELECT ON public.workout_modifications TO anon;

NOTIFY pgrst, 'reload schema';
