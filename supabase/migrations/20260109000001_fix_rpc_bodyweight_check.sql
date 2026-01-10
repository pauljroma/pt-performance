-- Force update RPC function to handle bodyweight exercises correctly

DROP FUNCTION IF EXISTS get_substitution_candidates(UUID, TEXT[]);

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
    -- OR equipment is 'none' (bodyweight exercises - always available)
    AND (
      p_equipment_available IS NULL
      OR esc.equipment_required = ARRAY['none']::TEXT[]
      OR esc.equipment_required <@ p_equipment_available
    )
  ORDER BY esc.difficulty_delta ASC;
END;
$$;
