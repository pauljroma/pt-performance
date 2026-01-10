-- BUILD 138: Nutrition Tracking - Storage and AI Recommendations
-- Create storage bucket for meal photos and nutrition_recommendations table

-- ============================================================================
-- 1. Supabase Storage Bucket for Meal Photos
-- ============================================================================

-- Create meal_photos bucket (private, patient-owned)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'meal_photos',
    'meal_photos',
    false, -- Private bucket
    5242880, -- 5MB max file size
    ARRAY[
        'image/jpeg',
        'image/jpg',
        'image/png',
        'image/heic',
        'image/heif',
        'image/webp'
    ]
)
ON CONFLICT (id) DO UPDATE
SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- ============================================================================
-- 2. Storage RLS Policies for meal_photos
-- ============================================================================

-- Patients can upload their own meal photos
CREATE POLICY "Patients can upload own meal photos"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'meal_photos'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Patients can view their own meal photos
CREATE POLICY "Patients can view own meal photos"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'meal_photos'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Patients can delete their own meal photos
CREATE POLICY "Patients can delete own meal photos"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'meal_photos'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Therapists can view their patients' meal photos
CREATE POLICY "Therapists can view patient meal photos"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'meal_photos'
        AND EXISTS (
            SELECT 1 FROM patients
            WHERE patients.id::text = (storage.foldername(name))[1]
            AND patients.therapist_id = auth.uid()
        )
    );

-- ============================================================================
-- 3. Nutrition Recommendations Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS nutrition_recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    recommendation_text TEXT NOT NULL,
    target_macros JSONB NOT NULL, -- {protein: 30, carbs: 40, fats: 10, calories: 400}
    reasoning TEXT NOT NULL,
    context JSONB, -- {time_of_day: '2:00 PM', next_workout_time: '4:00 PM', workout_type: 'strength', ...}
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast lookups by patient
CREATE INDEX IF NOT EXISTS idx_nutrition_recommendations_patient
    ON nutrition_recommendations(patient_id, created_at DESC);

COMMENT ON TABLE nutrition_recommendations IS 'AI-generated nutrition recommendations with context awareness';
COMMENT ON COLUMN nutrition_recommendations.target_macros IS 'JSONB containing target protein, carbs, fats, and calories for the meal';
COMMENT ON COLUMN nutrition_recommendations.reasoning IS 'AI explanation for why this meal is recommended';
COMMENT ON COLUMN nutrition_recommendations.context IS 'JSONB containing contextual data like time of day, next workout, recovery status, etc.';

-- ============================================================================
-- 4. Row Level Security for nutrition_recommendations
-- ============================================================================

ALTER TABLE nutrition_recommendations ENABLE ROW LEVEL SECURITY;

-- Patients can view their own recommendations
CREATE POLICY "Patients can view own nutrition recommendations"
    ON nutrition_recommendations FOR SELECT
    USING (patient_id = auth.uid());

-- Patients can insert their own recommendations
CREATE POLICY "Patients can insert own nutrition recommendations"
    ON nutrition_recommendations FOR INSERT
    WITH CHECK (patient_id = auth.uid());

-- Therapists can view their patients' recommendations
CREATE POLICY "Therapists can view patient nutrition recommendations"
    ON nutrition_recommendations FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.id = nutrition_recommendations.patient_id
            AND patients.therapist_id = auth.uid()
        )
    );

-- ============================================================================
-- 5. Update nutrition_logs table to support photo URLs
-- ============================================================================

-- Add photo_url column to existing nutrition_logs table
ALTER TABLE nutrition_logs
    ADD COLUMN IF NOT EXISTS photo_url TEXT;

ALTER TABLE nutrition_logs
    ADD COLUMN IF NOT EXISTS ai_generated BOOLEAN DEFAULT false;

COMMENT ON COLUMN nutrition_logs.photo_url IS 'URL to meal photo in Supabase Storage (meal_photos bucket)';
COMMENT ON COLUMN nutrition_logs.ai_generated IS 'True if macros were estimated by AI, false if manually entered';

-- ============================================================================
-- 6. Helper Functions
-- ============================================================================

-- Function to get today's nutrition summary
CREATE OR REPLACE FUNCTION get_daily_nutrition_summary(
    p_patient_id UUID,
    p_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    total_calories INT,
    total_protein NUMERIC,
    total_carbs NUMERIC,
    total_fats NUMERIC,
    goal_calories INT,
    goal_protein NUMERIC,
    goal_carbs NUMERIC,
    goal_fats NUMERIC,
    calories_remaining INT,
    protein_remaining NUMERIC,
    carbs_remaining NUMERIC,
    fats_remaining NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(SUM(nl.calories), 0)::INT AS total_calories,
        COALESCE(SUM(nl.protein), 0) AS total_protein,
        COALESCE(SUM(nl.carbs), 0) AS total_carbs,
        COALESCE(SUM(nl.fats), 0) AS total_fats,
        COALESCE(ng.target_calories, 2000) AS goal_calories,
        COALESCE(ng.target_protein, 150) AS goal_protein,
        COALESCE(ng.target_carbs, 200) AS goal_carbs,
        COALESCE(ng.target_fats, 65) AS goal_fats,
        (COALESCE(ng.target_calories, 2000) - COALESCE(SUM(nl.calories), 0))::INT AS calories_remaining,
        (COALESCE(ng.target_protein, 150) - COALESCE(SUM(nl.protein), 0)) AS protein_remaining,
        (COALESCE(ng.target_carbs, 200) - COALESCE(SUM(nl.carbs), 0)) AS carbs_remaining,
        (COALESCE(ng.target_fats, 65) - COALESCE(SUM(nl.fats), 0)) AS fats_remaining
    FROM patients p
    LEFT JOIN nutrition_logs nl ON nl.patient_id = p.id AND nl.logged_at::date = p_date
    LEFT JOIN nutrition_goals ng ON ng.patient_id = p.id
    WHERE p.id = p_patient_id
    GROUP BY p.id, ng.target_calories, ng.target_protein, ng.target_carbs, ng.target_fats;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_daily_nutrition_summary IS 'Returns daily nutrition totals vs goals with remaining macros';
