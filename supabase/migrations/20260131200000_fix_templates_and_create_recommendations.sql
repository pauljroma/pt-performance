-- BUILD 353: Fix templates RLS and create workout_recommendations table

-- 1. Fix system_workout_templates RLS to allow all authenticated users
DROP POLICY IF EXISTS "system_workout_templates_public_read" ON system_workout_templates;
CREATE POLICY "system_workout_templates_public_read"
ON system_workout_templates FOR SELECT
TO authenticated
USING (true);

-- 2. Create workout_recommendations table for AI Quick Pick
CREATE TABLE IF NOT EXISTS workout_recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    recommendations JSONB NOT NULL,
    reasoning TEXT,
    context JSONB,
    was_selected BOOLEAN DEFAULT FALSE,
    selected_template_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_workout_recommendations_patient_created
ON workout_recommendations(patient_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_workout_recommendations_selected
ON workout_recommendations(was_selected, selected_template_id)
WHERE was_selected = TRUE;

-- RLS
ALTER TABLE workout_recommendations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Patients can view own recommendations" ON workout_recommendations;
CREATE POLICY "Patients can view own recommendations"
ON workout_recommendations FOR SELECT
USING (auth.uid() = patient_id);

DROP POLICY IF EXISTS "Service role can insert recommendations" ON workout_recommendations;
CREATE POLICY "Service role can insert recommendations"
ON workout_recommendations FOR INSERT
WITH CHECK (true);

DROP POLICY IF EXISTS "Patients can update own recommendations" ON workout_recommendations;
CREATE POLICY "Patients can update own recommendations"
ON workout_recommendations FOR UPDATE
USING (auth.uid() = patient_id);

-- Verify
SELECT 'Templates: ' || COUNT(*)::text as status FROM system_workout_templates
UNION ALL
SELECT 'workout_recommendations table created' as status;
