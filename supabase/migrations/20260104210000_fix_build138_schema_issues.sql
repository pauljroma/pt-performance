-- BUILD 138 - Fix Schema Issues for Edge Functions
-- Date: 2026-01-04
-- Purpose: Add missing columns required by BUILD 138 Edge Functions

-- Fix 1: Add equipment_required column to exercise_templates
ALTER TABLE exercise_templates
ADD COLUMN IF NOT EXISTS equipment_required TEXT[];

-- Fix 2: Add logged_at column to nutrition_logs
ALTER TABLE nutrition_logs
ADD COLUMN IF NOT EXISTS logged_at TIMESTAMPTZ DEFAULT NOW();

-- Fix 3: Ensure patients table has whoop_credentials column
ALTER TABLE patients
ADD COLUMN IF NOT EXISTS whoop_credentials JSONB;

-- Fix 4: Add recommended_at to nutrition_logs for AI recommendations
ALTER TABLE nutrition_logs
ADD COLUMN IF NOT EXISTS ai_recommended BOOLEAN DEFAULT false;

NOTIFY pgrst, 'reload schema';
