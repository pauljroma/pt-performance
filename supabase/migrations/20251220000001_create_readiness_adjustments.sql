-- Build 72 - Readiness Adjustment Backend
-- Create simplified readiness_adjustments table matching iOS ReadinessAdjustment model
-- ACP-215, ACP-216, ACP-217
-- Agent 3: Backend Lead - Adjustment Algorithm

BEGIN;

-- ============================================================================
-- 1. READINESS_ADJUSTMENTS TABLE
-- ============================================================================
-- Stores calculated workout adjustments based on readiness band
-- Matches ios-app/PTPerformance/Models/ReadinessAdjustment.swift

-- Drop Build 69 version if it exists (incompatible schema)
DROP TABLE IF EXISTS public.readiness_adjustments CASCADE;
DROP FUNCTION IF EXISTS public.calculate_readiness_adjustment CASCADE;
DROP FUNCTION IF EXISTS public.override_readiness_adjustment CASCADE;
DROP FUNCTION IF EXISTS public.lock_readiness_adjustment CASCADE;

CREATE TABLE public.readiness_adjustments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    session_id UUID REFERENCES public.sessions(id) ON DELETE SET NULL,
    daily_readiness_id UUID, -- References daily_readiness when that table is created

    -- Readiness band that triggered the adjustment
    readiness_band TEXT NOT NULL CHECK (readiness_band IN ('green', 'yellow', 'orange', 'red')),

    -- Overall adjustments applied
    load_adjustment_pct NUMERIC NOT NULL DEFAULT 0, -- -0.10 for yellow, -0.20 for orange, -1.0 for red
    volume_adjustment_pct NUMERIC NOT NULL DEFAULT 0, -- Volume reduction percentage
    skip_top_set BOOLEAN NOT NULL DEFAULT FALSE, -- Orange/Red: skip heaviest set
    technique_only BOOLEAN NOT NULL DEFAULT FALSE, -- Red: technique work only

    -- Practitioner controls (Build 69 - Agent 14 feature)
    is_practitioner_locked BOOLEAN NOT NULL DEFAULT FALSE, -- If true, patient cannot override
    locked_by UUID REFERENCES auth.users(id), -- Practitioner who locked
    lock_reason TEXT, -- Why override is locked
    was_overridden BOOLEAN NOT NULL DEFAULT FALSE, -- Patient chose to override
    override_reason TEXT, -- Why patient overrode
    overridden_by UUID REFERENCES auth.users(id), -- Who performed override
    overridden_at TIMESTAMPTZ,

    -- Metadata
    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Adjustment details (JSONB for flexibility)
    modified_exercises JSONB DEFAULT '[]'::jsonb, -- Array of exercise modifications

    -- Constraints
    UNIQUE(patient_id, session_id) -- One adjustment per patient per session
);

-- Indexes for performance
CREATE INDEX idx_readiness_adjustments_patient_id ON public.readiness_adjustments(patient_id);
CREATE INDEX idx_readiness_adjustments_session_id ON public.readiness_adjustments(session_id);
CREATE INDEX idx_readiness_adjustments_band ON public.readiness_adjustments(readiness_band);
CREATE INDEX idx_readiness_adjustments_applied_at ON public.readiness_adjustments(applied_at DESC);
CREATE INDEX idx_readiness_adjustments_overridden ON public.readiness_adjustments(was_overridden) WHERE was_overridden = TRUE;

-- Comments
COMMENT ON TABLE public.readiness_adjustments IS 'Workout adjustments based on daily readiness bands (Green/Yellow/Orange/Red)';
COMMENT ON COLUMN public.readiness_adjustments.readiness_band IS 'Green: no adjustment, Yellow: -10%, Orange: -20% + skip top set, Red: rest day';
COMMENT ON COLUMN public.readiness_adjustments.load_adjustment_pct IS 'Load reduction: 0 (green), -0.10 (yellow), -0.20 (orange), -1.0 (red)';
COMMENT ON COLUMN public.readiness_adjustments.modified_exercises IS 'Array of {exercise_name, original_load, modified_load, original_sets, modified_sets}';
COMMENT ON COLUMN public.readiness_adjustments.is_practitioner_locked IS 'If true, patient cannot override this adjustment';

-- ============================================================================
-- 2. ADJUSTMENT CALCULATION FUNCTION
-- ============================================================================
-- Simplified algorithm matching Build 72 spec:
-- Green: No adjustment
-- Yellow: -10% load OR -1 set (whichever is less disruptive)
-- Orange: -20% load AND -1 set
-- Red: Suggest rest day (technique only)

CREATE OR REPLACE FUNCTION public.calculate_readiness_adjustment(
    p_patient_id UUID,
    p_session_id UUID,
    p_readiness_band TEXT,
    p_daily_readiness_id UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_adjustment_id UUID;
    v_load_adj NUMERIC;
    v_volume_adj NUMERIC;
    v_skip_top BOOLEAN;
    v_technique_only BOOLEAN;
    v_auto_adjustment_enabled BOOLEAN;
BEGIN
    -- Check if patient has auto-adjustment enabled
    SELECT auto_adjustment_enabled
    INTO v_auto_adjustment_enabled
    FROM public.patients
    WHERE id = p_patient_id;

    -- If auto-adjustment is disabled, return NULL (no adjustment)
    IF v_auto_adjustment_enabled IS FALSE THEN
        RAISE NOTICE 'Auto-adjustment disabled for patient %', p_patient_id;
        RETURN NULL;
    END IF;

    -- Calculate adjustments based on readiness band
    CASE p_readiness_band
        WHEN 'green' THEN
            -- Green: No adjustment needed
            v_load_adj := 0;
            v_volume_adj := 0;
            v_skip_top := FALSE;
            v_technique_only := FALSE;

        WHEN 'yellow' THEN
            -- Yellow: -10% load OR -1 set (choosing -10% as default)
            v_load_adj := -0.10;
            v_volume_adj := 0; -- Could also do -1 set = -0.25 for 4 sets
            v_skip_top := FALSE;
            v_technique_only := FALSE;

        WHEN 'orange' THEN
            -- Orange: -20% load AND -1 set (skip top set)
            v_load_adj := -0.20;
            v_volume_adj := -0.25; -- ~1 set reduction
            v_skip_top := TRUE;
            v_technique_only := FALSE;

        WHEN 'red' THEN
            -- Red: Suggest rest day (technique only, no loading)
            v_load_adj := -1.0; -- No loading
            v_volume_adj := -1.0; -- No volume
            v_skip_top := TRUE;
            v_technique_only := TRUE;

        ELSE
            RAISE EXCEPTION 'Invalid readiness band: %', p_readiness_band;
    END CASE;

    -- Insert adjustment record
    INSERT INTO public.readiness_adjustments (
        patient_id,
        session_id,
        daily_readiness_id,
        readiness_band,
        load_adjustment_pct,
        volume_adjustment_pct,
        skip_top_set,
        technique_only,
        is_practitioner_locked,
        was_overridden
    ) VALUES (
        p_patient_id,
        p_session_id,
        p_daily_readiness_id,
        p_readiness_band,
        v_load_adj,
        v_volume_adj,
        v_skip_top,
        v_technique_only,
        FALSE, -- Not locked by default
        FALSE  -- Not overridden
    )
    ON CONFLICT (patient_id, session_id)
    DO UPDATE SET
        daily_readiness_id = EXCLUDED.daily_readiness_id,
        readiness_band = EXCLUDED.readiness_band,
        load_adjustment_pct = EXCLUDED.load_adjustment_pct,
        volume_adjustment_pct = EXCLUDED.volume_adjustment_pct,
        skip_top_set = EXCLUDED.skip_top_set,
        technique_only = EXCLUDED.technique_only,
        updated_at = NOW()
    WHERE public.readiness_adjustments.was_overridden = FALSE
    RETURNING id INTO v_adjustment_id;

    -- Log audit event
    PERFORM public.log_audit_event(
        'CREATE',
        'readiness_adjustment',
        v_adjustment_id,
        'calculate_adjustment',
        format('Readiness adjustment calculated: %s band (load: %s%%, volume: %s%%)',
               p_readiness_band,
               (v_load_adj * 100)::INT,
               (v_volume_adj * 100)::INT),
        p_patient_id,
        NULL,
        jsonb_build_object(
            'adjustment_id', v_adjustment_id,
            'readiness_band', p_readiness_band,
            'session_id', p_session_id
        ),
        FALSE,
        'DATA_MODIFICATION'
    );

    RETURN v_adjustment_id;
END;
$$;

COMMENT ON FUNCTION public.calculate_readiness_adjustment IS 'Creates workout adjustment based on readiness band (Green/Yellow/Orange/Red)';

-- ============================================================================
-- 3. OVERRIDE ADJUSTMENT FUNCTION
-- ============================================================================
-- Allows patients to override adjustments (if not locked by practitioner)

CREATE OR REPLACE FUNCTION public.override_readiness_adjustment(
    p_adjustment_id UUID,
    p_override_reason TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_is_locked BOOLEAN;
    v_patient_id UUID;
BEGIN
    -- Check if adjustment is practitioner-locked
    SELECT is_practitioner_locked, patient_id
    INTO v_is_locked, v_patient_id
    FROM public.readiness_adjustments
    WHERE id = p_adjustment_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Adjustment not found: %', p_adjustment_id;
    END IF;

    IF v_is_locked THEN
        RAISE EXCEPTION 'This adjustment is locked by your practitioner and cannot be overridden';
    END IF;

    -- Mark as overridden
    UPDATE public.readiness_adjustments
    SET
        was_overridden = TRUE,
        override_reason = p_override_reason,
        overridden_by = auth.uid(),
        overridden_at = NOW(),
        updated_at = NOW()
    WHERE id = p_adjustment_id;

    -- Log audit event
    PERFORM public.log_audit_event(
        'UPDATE',
        'readiness_adjustment',
        p_adjustment_id,
        'override_adjustment',
        format('Patient overrode adjustment. Reason: %s', p_override_reason),
        v_patient_id,
        NULL,
        jsonb_build_object('override_reason', p_override_reason),
        FALSE,
        'DATA_MODIFICATION'
    );

    RETURN TRUE;
END;
$$;

COMMENT ON FUNCTION public.override_readiness_adjustment IS 'Allows patients to override adjustments (if not locked)';

-- ============================================================================
-- 4. PRACTITIONER LOCK FUNCTION
-- ============================================================================
-- Allows practitioners to lock adjustments to prevent patient overrides

CREATE OR REPLACE FUNCTION public.lock_readiness_adjustment(
    p_adjustment_id UUID,
    p_lock_reason TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_patient_id UUID;
BEGIN
    -- Get patient_id
    SELECT patient_id
    INTO v_patient_id
    FROM public.readiness_adjustments
    WHERE id = p_adjustment_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Adjustment not found: %', p_adjustment_id;
    END IF;

    -- Lock the adjustment
    UPDATE public.readiness_adjustments
    SET
        is_practitioner_locked = TRUE,
        locked_by = auth.uid(),
        lock_reason = p_lock_reason,
        updated_at = NOW()
    WHERE id = p_adjustment_id;

    -- Log audit event
    PERFORM public.log_audit_event(
        'UPDATE',
        'readiness_adjustment',
        p_adjustment_id,
        'lock_adjustment',
        format('Practitioner locked adjustment. Reason: %s', p_lock_reason),
        v_patient_id,
        NULL,
        jsonb_build_object('lock_reason', p_lock_reason),
        FALSE,
        'DATA_MODIFICATION'
    );

    RETURN TRUE;
END;
$$;

COMMENT ON FUNCTION public.lock_readiness_adjustment IS 'Allows practitioners to lock adjustments to prevent patient overrides';

-- ============================================================================
-- 5. ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE public.readiness_adjustments ENABLE ROW LEVEL SECURITY;

-- Patients can view their own adjustments
CREATE POLICY "Patients can view their own readiness adjustments"
ON public.readiness_adjustments
FOR SELECT
TO authenticated
USING (
    patient_id IN (
        SELECT id FROM public.patients WHERE user_id = auth.uid()
    )
);

-- Patients can insert their own adjustments (via calculate function)
CREATE POLICY "System can create readiness adjustments"
ON public.readiness_adjustments
FOR INSERT
TO authenticated
WITH CHECK (true); -- Controlled by function security

-- Patients can update their own adjustments (for overrides)
CREATE POLICY "Patients can override their adjustments"
ON public.readiness_adjustments
FOR UPDATE
TO authenticated
USING (
    patient_id IN (
        SELECT id FROM public.patients WHERE user_id = auth.uid()
    )
    AND is_practitioner_locked = FALSE
)
WITH CHECK (
    patient_id IN (
        SELECT id FROM public.patients WHERE user_id = auth.uid()
    )
);

-- Therapists can view patient adjustments
CREATE POLICY "Therapists can view patient readiness adjustments"
ON public.readiness_adjustments
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.therapists t
        JOIN public.patients p ON p.therapist_id = t.id
        WHERE t.user_id = auth.uid()
        AND p.id = patient_id
    )
);

-- Therapists can lock/modify adjustments for their patients
CREATE POLICY "Therapists can lock patient adjustments"
ON public.readiness_adjustments
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.therapists t
        JOIN public.patients p ON p.therapist_id = t.id
        WHERE t.user_id = auth.uid()
        AND p.id = patient_id
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.therapists t
        JOIN public.patients p ON p.therapist_id = t.id
        WHERE t.user_id = auth.uid()
        AND p.id = patient_id
    )
);

-- ============================================================================
-- 6. TRIGGERS FOR UPDATED_AT
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_readiness_adjustments_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER update_readiness_adjustments_updated_at
BEFORE UPDATE ON public.readiness_adjustments
FOR EACH ROW
EXECUTE FUNCTION public.update_readiness_adjustments_updated_at();

-- ============================================================================
-- 7. HELPER VIEWS
-- ============================================================================

-- Recent adjustments with patient names
CREATE OR REPLACE VIEW public.vw_recent_readiness_adjustments AS
SELECT
    ra.id,
    ra.patient_id,
    p.first_name || ' ' || p.last_name as patient_name,
    ra.session_id,
    s.name as session_name,
    ra.readiness_band,
    ra.load_adjustment_pct,
    ra.volume_adjustment_pct,
    ra.skip_top_set,
    ra.technique_only,
    ra.is_practitioner_locked,
    ra.was_overridden,
    ra.override_reason,
    ra.applied_at,
    ra.created_at
FROM public.readiness_adjustments ra
JOIN public.patients p ON p.id = ra.patient_id
LEFT JOIN public.sessions s ON s.id = ra.session_id
ORDER BY ra.applied_at DESC;

-- ============================================================================
-- 8. GRANT PERMISSIONS
-- ============================================================================

GRANT SELECT, INSERT, UPDATE ON public.readiness_adjustments TO authenticated;
GRANT SELECT ON public.vw_recent_readiness_adjustments TO authenticated;
GRANT EXECUTE ON FUNCTION public.calculate_readiness_adjustment TO authenticated;
GRANT EXECUTE ON FUNCTION public.override_readiness_adjustment TO authenticated;
GRANT EXECUTE ON FUNCTION public.lock_readiness_adjustment TO authenticated;

COMMIT;
