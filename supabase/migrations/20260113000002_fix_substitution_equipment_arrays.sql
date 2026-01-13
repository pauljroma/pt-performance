-- BUILD 174 FIX: Fix equipment_required arrays for substitution candidates
-- The RPC function checks for ARRAY['none'] for bodyweight, but we used empty arrays
-- Also add true bodyweight alternatives that require NO equipment

-- First, create bodyweight row alternative (Superman/Back Extension)
INSERT INTO exercise_templates (id, name, category, body_region, equipment_required, difficulty_level)
VALUES ('00000000-0000-0000-0000-000000000b01', 'Prone Y Raise', 'pull', 'upper', ARRAY[]::TEXT[], 'beginner')
ON CONFLICT (id) DO UPDATE SET equipment_required = ARRAY[]::TEXT[];

-- Add bodyweight substitute for Barbell Row
INSERT INTO exercise_substitution_candidates (original_exercise_id, substitute_exercise_id, equipment_required, difficulty_delta, notes)
SELECT
  '00000000-0000-0000-0000-0000000000f2',  -- Barbell Row
  '00000000-0000-0000-0000-000000000b01',  -- Prone Y Raise
  ARRAY[]::TEXT[],
  -0.4,
  'Bodyweight back exercise - no equipment needed'
WHERE NOT EXISTS (
  SELECT 1 FROM exercise_substitution_candidates
  WHERE original_exercise_id = '00000000-0000-0000-0000-0000000000f2'
    AND substitute_exercise_id = '00000000-0000-0000-0000-000000000b01'
);

-- Update substitution candidates with empty arrays to use 'none'
UPDATE exercise_substitution_candidates
SET equipment_required = ARRAY['none']::TEXT[]
WHERE equipment_required = ARRAY[]::TEXT[]
   OR equipment_required IS NULL;

-- Also update any candidates using '{none}' string format
UPDATE exercise_substitution_candidates
SET equipment_required = ARRAY['none']::TEXT[]
WHERE equipment_required::TEXT = '{none}';

-- Fix the RPC to also accept empty arrays as "no equipment needed"
CREATE OR REPLACE FUNCTION get_substitution_candidates(
  p_original_exercise_id UUID,
  p_equipment_available TEXT[]
)
RETURNS TABLE (
  substitute_id UUID,
  substitute_name TEXT,
  equipment_required TEXT[],
  difficulty_delta FLOAT,
  notes TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    et.id AS substitute_id,
    et.name AS substitute_name,
    esc.equipment_required,
    esc.difficulty_delta,
    esc.notes
  FROM exercise_substitution_candidates esc
  INNER JOIN exercise_templates et ON et.id = esc.substitute_exercise_id
  WHERE esc.original_exercise_id = p_original_exercise_id
    -- Only return candidates where all required equipment is available
    -- OR equipment is 'none'/empty (bodyweight exercises - always available)
    AND (
      p_equipment_available IS NULL
      OR esc.equipment_required = ARRAY['none']::TEXT[]
      OR esc.equipment_required = ARRAY[]::TEXT[]
      OR array_length(esc.equipment_required, 1) IS NULL
      OR esc.equipment_required <@ p_equipment_available
    )
  ORDER BY esc.difficulty_delta ASC;
END;
$$;

-- Verify fix
DO $$
DECLARE
  candidate_count INT;
BEGIN
  -- Test getting candidates for Barbell Row with no equipment
  SELECT COUNT(*) INTO candidate_count
  FROM get_substitution_candidates(
    '00000000-0000-0000-0000-0000000000f2'::UUID,  -- Barbell Row
    ARRAY[]::TEXT[]  -- No equipment
  );

  RAISE NOTICE 'Barbell Row candidates with no equipment: %', candidate_count;
END $$;
