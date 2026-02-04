-- Migration: Create nutrition profiles for Modus nutrition system
-- Date: 2026-02-04
-- Description: Nutrition profiles with BMR/TDEE calculations and athlete-specific settings
-- Based on Modus Nutrition Guidelines (Mifflin-St Jeor formula)

BEGIN;

-- =====================================================
-- NUTRITION PROFILES TABLE
-- =====================================================
-- Stores user nutrition profiles with stats for BMR/TDEE calculations

CREATE TABLE IF NOT EXISTS nutrition_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Athlete type (matches pack code: BASE, BASEBALL, RUNNING, etc.)
    athlete_type TEXT NOT NULL DEFAULT 'BASE',

    -- Personal stats for BMR calculation (Mifflin-St Jeor)
    age INTEGER NOT NULL CHECK (age >= 12 AND age <= 120),
    weight_lbs DECIMAL(6,2) NOT NULL CHECK (weight_lbs >= 50 AND weight_lbs <= 500),
    height_inches DECIMAL(5,2) NOT NULL CHECK (height_inches >= 36 AND height_inches <= 96),
    gender TEXT NOT NULL CHECK (gender IN ('male', 'female')),

    -- Activity level for TDEE calculation
    -- sedentary=1.2, light=1.375, moderate=1.55, active=1.725, very_active=1.9, athlete=2.0
    activity_level TEXT NOT NULL DEFAULT 'moderate'
        CHECK (activity_level IN ('sedentary', 'light', 'moderate', 'active', 'very_active', 'athlete')),

    -- Primary nutrition goal
    -- maintain=1.0, fat_loss=0.8, muscle_gain=1.1, performance=1.15 (calorie multipliers)
    goal TEXT NOT NULL DEFAULT 'maintain'
        CHECK (goal IN ('maintain', 'fat_loss', 'muscle_gain', 'performance')),

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Each user can only have one nutrition profile
    CONSTRAINT unique_user_nutrition_profile UNIQUE (user_id)
);

-- Create indexes
CREATE INDEX idx_nutrition_profiles_user ON nutrition_profiles(user_id);
CREATE INDEX idx_nutrition_profiles_athlete_type ON nutrition_profiles(athlete_type);

-- =====================================================
-- NUTRITION LOGS TABLE ENHANCEMENT
-- =====================================================
-- Add profile reference to nutrition logs for tracking against calculated targets

-- Add column if it doesn't exist (safe migration)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'nutrition_logs' AND column_name = 'profile_id'
    ) THEN
        ALTER TABLE nutrition_logs ADD COLUMN profile_id UUID REFERENCES nutrition_profiles(id);
    END IF;
END $$;

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE nutrition_profiles ENABLE ROW LEVEL SECURITY;

-- Users can view their own profile
CREATE POLICY "Users view own nutrition profile"
    ON nutrition_profiles FOR SELECT
    USING (user_id = auth.uid());

-- Users can create their own profile
CREATE POLICY "Users create own nutrition profile"
    ON nutrition_profiles FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- Users can update their own profile
CREATE POLICY "Users update own nutrition profile"
    ON nutrition_profiles FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Users can delete their own profile
CREATE POLICY "Users delete own nutrition profile"
    ON nutrition_profiles FOR DELETE
    USING (user_id = auth.uid());

-- Therapists can view profiles of their patients
CREATE POLICY "Therapists view patient nutrition profiles"
    ON nutrition_profiles FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.id = nutrition_profiles.user_id
            AND patients.therapist_id = auth.uid()
        )
    );

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_nutrition_profiles_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS nutrition_profiles_updated_at ON nutrition_profiles;
CREATE TRIGGER nutrition_profiles_updated_at
    BEFORE UPDATE ON nutrition_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_nutrition_profiles_updated_at();

-- =====================================================
-- COMPUTED VALUES VIEW
-- =====================================================
-- View that calculates BMR, TDEE, and macro targets

CREATE OR REPLACE VIEW vw_nutrition_profile_targets AS
SELECT
    np.id,
    np.user_id,
    np.athlete_type,
    np.age,
    np.weight_lbs,
    np.height_inches,
    np.gender,
    np.activity_level,
    np.goal,

    -- Weight in kg for BMR calculation
    ROUND(np.weight_lbs / 2.205, 2) as weight_kg,

    -- Height in cm for BMR calculation
    ROUND(np.height_inches * 2.54, 2) as height_cm,

    -- BMR using Mifflin-St Jeor formula
    -- Male: 10*weight(kg) + 6.25*height(cm) - 5*age + 5
    -- Female: 10*weight(kg) + 6.25*height(cm) - 5*age - 161
    ROUND(
        CASE
            WHEN np.gender = 'male' THEN
                10 * (np.weight_lbs / 2.205) + 6.25 * (np.height_inches * 2.54) - 5 * np.age + 5
            ELSE
                10 * (np.weight_lbs / 2.205) + 6.25 * (np.height_inches * 2.54) - 5 * np.age - 161
        END
    , 0) as bmr,

    -- Activity multiplier
    CASE np.activity_level
        WHEN 'sedentary' THEN 1.2
        WHEN 'light' THEN 1.375
        WHEN 'moderate' THEN 1.55
        WHEN 'active' THEN 1.725
        WHEN 'very_active' THEN 1.9
        WHEN 'athlete' THEN 2.0
        ELSE 1.55
    END as activity_multiplier,

    -- Goal multiplier
    CASE np.goal
        WHEN 'maintain' THEN 1.0
        WHEN 'fat_loss' THEN 0.8
        WHEN 'muscle_gain' THEN 1.1
        WHEN 'performance' THEN 1.15
        ELSE 1.0
    END as goal_multiplier,

    -- TDEE (maintenance calories)
    ROUND(
        (
            CASE
                WHEN np.gender = 'male' THEN
                    10 * (np.weight_lbs / 2.205) + 6.25 * (np.height_inches * 2.54) - 5 * np.age + 5
                ELSE
                    10 * (np.weight_lbs / 2.205) + 6.25 * (np.height_inches * 2.54) - 5 * np.age - 161
            END
        ) *
        CASE np.activity_level
            WHEN 'sedentary' THEN 1.2
            WHEN 'light' THEN 1.375
            WHEN 'moderate' THEN 1.55
            WHEN 'active' THEN 1.725
            WHEN 'very_active' THEN 1.9
            WHEN 'athlete' THEN 2.0
            ELSE 1.55
        END
    , 0) as tdee,

    -- Target calories (TDEE * goal multiplier)
    ROUND(
        (
            CASE
                WHEN np.gender = 'male' THEN
                    10 * (np.weight_lbs / 2.205) + 6.25 * (np.height_inches * 2.54) - 5 * np.age + 5
                ELSE
                    10 * (np.weight_lbs / 2.205) + 6.25 * (np.height_inches * 2.54) - 5 * np.age - 161
            END
        ) *
        CASE np.activity_level
            WHEN 'sedentary' THEN 1.2
            WHEN 'light' THEN 1.375
            WHEN 'moderate' THEN 1.55
            WHEN 'active' THEN 1.725
            WHEN 'very_active' THEN 1.9
            WHEN 'athlete' THEN 2.0
            ELSE 1.55
        END *
        CASE np.goal
            WHEN 'maintain' THEN 1.0
            WHEN 'fat_loss' THEN 0.8
            WHEN 'muscle_gain' THEN 1.1
            WHEN 'performance' THEN 1.15
            ELSE 1.0
        END
    , 0) as target_calories,

    -- Protein target (0.9 g/lb as default)
    ROUND(np.weight_lbs * 0.9, 0) as target_protein_g,

    np.created_at,
    np.updated_at

FROM nutrition_profiles np;

-- Grant access to the view
GRANT SELECT ON vw_nutrition_profile_targets TO authenticated;

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Function to get user's nutrition targets
CREATE OR REPLACE FUNCTION get_nutrition_targets(p_user_id UUID)
RETURNS TABLE (
    bmr INTEGER,
    tdee INTEGER,
    target_calories INTEGER,
    target_protein_g INTEGER,
    activity_level TEXT,
    goal TEXT,
    athlete_type TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        vw.bmr::INTEGER,
        vw.tdee::INTEGER,
        vw.target_calories::INTEGER,
        vw.target_protein_g::INTEGER,
        vw.activity_level,
        vw.goal,
        vw.athlete_type
    FROM vw_nutrition_profile_targets vw
    WHERE vw.user_id = p_user_id
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_nutrition_targets(UUID) TO authenticated;

COMMIT;
