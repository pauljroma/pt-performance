-- ============================================================================
-- DELOAD RECOMMENDATIONS COMPLETE SCHEMA - BUILD 352
-- ============================================================================
-- Comprehensive deload recommendation system with:
-- 1. deload_recommendations table (enhanced with status tracking)
-- 2. active_deload_periods table
-- 3. is_in_deload_period() function
-- 4. activate_deload() function
-- 5. RLS policies and indexes
--
-- Date: 2026-02-01
-- Agent: 2
-- Sprint: Smart Recovery
-- ============================================================================

-- =====================================================
-- 1. DELOAD RECOMMENDATIONS TABLE (Enhanced)
-- =====================================================

-- Drop existing table if it exists (to recreate with full schema)
DROP TABLE IF EXISTS active_deload_periods CASCADE;
DROP TABLE IF EXISTS deload_recommendations CASCADE;

CREATE TABLE deload_recommendations (
    -- Primary key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Patient relationship
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,

    -- When recommendation was generated
    recommended_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Urgency level
    urgency TEXT NOT NULL DEFAULT 'suggested'
        CHECK (urgency IN ('suggested', 'recommended', 'required')),

    -- AI-generated explanation
    reasoning TEXT NOT NULL,

    -- Fatigue metrics at time of recommendation
    fatigue_score NUMERIC(4,1) CHECK (fatigue_score >= 0 AND fatigue_score <= 100),
    fatigue_band TEXT CHECK (fatigue_band IN ('low', 'moderate', 'high', 'critical')),
    avg_readiness_7d NUMERIC(5,2),
    acute_chronic_ratio NUMERIC(5,3),

    -- Contributing factors (JSONB array of factor strings)
    contributing_factors JSONB NOT NULL DEFAULT '[]'::jsonb,
    -- Example: ["sleep_deficit", "high_training_load", "elevated_soreness", "accumulated_fatigue"]

    -- Deload prescription parameters
    duration_days INTEGER NOT NULL DEFAULT 7 CHECK (duration_days >= 3 AND duration_days <= 14),
    load_reduction_pct INTEGER NOT NULL DEFAULT 50 CHECK (load_reduction_pct >= 20 AND load_reduction_pct <= 80),
    volume_reduction_pct INTEGER NOT NULL DEFAULT 40 CHECK (volume_reduction_pct >= 20 AND volume_reduction_pct <= 70),
    focus TEXT NOT NULL DEFAULT 'active_recovery'
        CHECK (focus IN ('technique', 'mobility', 'active_recovery', 'complete_rest')),
    suggested_start_date DATE NOT NULL DEFAULT CURRENT_DATE,

    -- Status tracking
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'activated', 'dismissed', 'completed', 'expired')),

    -- Status transition timestamps
    activated_at TIMESTAMPTZ,
    dismissed_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,

    -- Optional dismissal reason
    dismissed_reason TEXT,

    -- Recommendation expiration
    expires_at TIMESTAMPTZ DEFAULT (now() + INTERVAL '48 hours'),

    -- Standard timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Constraints
    CONSTRAINT valid_activated_at CHECK (activated_at IS NULL OR status IN ('activated', 'completed')),
    CONSTRAINT valid_dismissed_at CHECK (dismissed_at IS NULL OR status = 'dismissed'),
    CONSTRAINT valid_completed_at CHECK (completed_at IS NULL OR status = 'completed')
);

-- =====================================================
-- 2. ACTIVE DELOAD PERIODS TABLE
-- =====================================================

CREATE TABLE active_deload_periods (
    -- Primary key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Patient relationship
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,

    -- Link to the recommendation that triggered this deload
    recommendation_id UUID REFERENCES deload_recommendations(id) ON DELETE SET NULL,

    -- Deload period dates
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,

    -- Deload parameters (copied from recommendation)
    load_reduction_pct INTEGER NOT NULL CHECK (load_reduction_pct >= 20 AND load_reduction_pct <= 80),
    volume_reduction_pct INTEGER NOT NULL CHECK (volume_reduction_pct >= 20 AND volume_reduction_pct <= 70),
    focus TEXT NOT NULL CHECK (focus IN ('technique', 'mobility', 'active_recovery', 'complete_rest')),

    -- Active status
    is_active BOOLEAN NOT NULL DEFAULT true,

    -- Completion tracking
    completed_at TIMESTAMPTZ,
    early_termination BOOLEAN DEFAULT false,
    termination_reason TEXT,

    -- Standard timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Constraints
    CONSTRAINT valid_date_range CHECK (end_date >= start_date),
    CONSTRAINT valid_completed_at CHECK (completed_at IS NULL OR NOT is_active)
);

-- =====================================================
-- 3. INDEXES FOR PERFORMANCE
-- =====================================================

-- deload_recommendations indexes
CREATE INDEX idx_deload_rec_patient ON deload_recommendations(patient_id);
CREATE INDEX idx_deload_rec_patient_created ON deload_recommendations(patient_id, created_at DESC);
CREATE INDEX idx_deload_rec_status ON deload_recommendations(status);
CREATE INDEX idx_deload_rec_urgency ON deload_recommendations(urgency) WHERE urgency IN ('recommended', 'required');
CREATE INDEX idx_deload_rec_pending ON deload_recommendations(patient_id, expires_at)
    WHERE status = 'pending';
CREATE INDEX idx_deload_rec_patient_status ON deload_recommendations(patient_id, status);

-- active_deload_periods indexes
CREATE INDEX idx_active_deload_patient ON active_deload_periods(patient_id);
CREATE INDEX idx_active_deload_active ON active_deload_periods(patient_id, is_active)
    WHERE is_active = true;
CREATE INDEX idx_active_deload_dates ON active_deload_periods(start_date, end_date);
CREATE INDEX idx_active_deload_recommendation ON active_deload_periods(recommendation_id);

-- =====================================================
-- 4. AUTO-UPDATE TIMESTAMP TRIGGERS
-- =====================================================

-- Trigger for deload_recommendations
CREATE OR REPLACE FUNCTION update_deload_recommendations_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_deload_recommendations_updated_at ON deload_recommendations;
CREATE TRIGGER trg_deload_recommendations_updated_at
    BEFORE UPDATE ON deload_recommendations
    FOR EACH ROW
    EXECUTE FUNCTION update_deload_recommendations_timestamp();

-- Trigger for active_deload_periods
CREATE OR REPLACE FUNCTION update_active_deload_periods_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_active_deload_periods_updated_at ON active_deload_periods;
CREATE TRIGGER trg_active_deload_periods_updated_at
    BEFORE UPDATE ON active_deload_periods
    FOR EACH ROW
    EXECUTE FUNCTION update_active_deload_periods_timestamp();

-- =====================================================
-- 5. IS_IN_DELOAD_PERIOD FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION is_in_deload_period(p_patient_id UUID)
RETURNS TABLE (
    in_deload BOOLEAN,
    deload_period_id UUID,
    start_date DATE,
    end_date DATE,
    days_remaining INTEGER,
    load_reduction_pct INTEGER,
    volume_reduction_pct INTEGER,
    focus TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_deload_period active_deload_periods%ROWTYPE;
BEGIN
    -- Find active deload period for this patient
    SELECT *
    INTO v_deload_period
    FROM active_deload_periods adp
    WHERE adp.patient_id = p_patient_id
      AND adp.is_active = true
      AND CURRENT_DATE BETWEEN adp.start_date AND adp.end_date
    ORDER BY adp.start_date DESC
    LIMIT 1;

    IF FOUND THEN
        -- Patient is in a deload period
        RETURN QUERY SELECT
            true::BOOLEAN,
            v_deload_period.id,
            v_deload_period.start_date,
            v_deload_period.end_date,
            (v_deload_period.end_date - CURRENT_DATE)::INTEGER,
            v_deload_period.load_reduction_pct,
            v_deload_period.volume_reduction_pct,
            v_deload_period.focus;
    ELSE
        -- Patient is not in a deload period
        RETURN QUERY SELECT
            false::BOOLEAN,
            NULL::UUID,
            NULL::DATE,
            NULL::DATE,
            NULL::INTEGER,
            NULL::INTEGER,
            NULL::INTEGER,
            NULL::TEXT;
    END IF;
END;
$$;

COMMENT ON FUNCTION is_in_deload_period(UUID) IS
'Check if a patient is currently in an active deload period.
Returns deload status along with period details if active.
Used by workout recommendation systems to adjust training intensity.';

-- =====================================================
-- 6. ACTIVATE_DELOAD FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION activate_deload(
    p_recommendation_id UUID,
    p_start_date DATE DEFAULT NULL,
    p_custom_duration_days INTEGER DEFAULT NULL
)
RETURNS active_deload_periods
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_recommendation deload_recommendations%ROWTYPE;
    v_start_date DATE;
    v_end_date DATE;
    v_duration_days INTEGER;
    v_result active_deload_periods;
    v_existing_active INTEGER;
BEGIN
    -- Get the recommendation
    SELECT * INTO v_recommendation
    FROM deload_recommendations
    WHERE id = p_recommendation_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Recommendation not found: %', p_recommendation_id;
    END IF;

    -- Check recommendation is in pending status
    IF v_recommendation.status != 'pending' THEN
        RAISE EXCEPTION 'Recommendation is not pending. Current status: %', v_recommendation.status;
    END IF;

    -- Check for existing active deload period
    SELECT COUNT(*) INTO v_existing_active
    FROM active_deload_periods
    WHERE patient_id = v_recommendation.patient_id
      AND is_active = true
      AND CURRENT_DATE BETWEEN start_date AND end_date;

    IF v_existing_active > 0 THEN
        RAISE EXCEPTION 'Patient already has an active deload period';
    END IF;

    -- Determine start date (use provided or default to recommendation's suggested date or today)
    v_start_date := COALESCE(p_start_date, v_recommendation.suggested_start_date, CURRENT_DATE);

    -- Cannot start in the past
    IF v_start_date < CURRENT_DATE THEN
        v_start_date := CURRENT_DATE;
    END IF;

    -- Determine duration
    v_duration_days := COALESCE(p_custom_duration_days, v_recommendation.duration_days);

    -- Validate duration (3-14 days)
    IF v_duration_days < 3 OR v_duration_days > 14 THEN
        RAISE EXCEPTION 'Duration must be between 3 and 14 days. Got: %', v_duration_days;
    END IF;

    -- Calculate end date
    v_end_date := v_start_date + (v_duration_days - 1);

    -- Create the active deload period
    INSERT INTO active_deload_periods (
        patient_id,
        recommendation_id,
        start_date,
        end_date,
        load_reduction_pct,
        volume_reduction_pct,
        focus,
        is_active
    )
    VALUES (
        v_recommendation.patient_id,
        p_recommendation_id,
        v_start_date,
        v_end_date,
        v_recommendation.load_reduction_pct,
        v_recommendation.volume_reduction_pct,
        v_recommendation.focus,
        true
    )
    RETURNING * INTO v_result;

    -- Update the recommendation status
    UPDATE deload_recommendations
    SET status = 'activated',
        activated_at = now()
    WHERE id = p_recommendation_id;

    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION activate_deload(UUID, DATE, INTEGER) IS
'Activate a deload recommendation, creating an active deload period.
Parameters:
- p_recommendation_id: UUID of the pending recommendation to activate
- p_start_date: Optional custom start date (defaults to recommendation suggestion or today)
- p_custom_duration_days: Optional override for duration (defaults to recommendation duration)
Returns the created active_deload_periods record.';

-- =====================================================
-- 7. DISMISS_DELOAD FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION dismiss_deload(
    p_recommendation_id UUID,
    p_reason TEXT DEFAULT NULL
)
RETURNS deload_recommendations
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_result deload_recommendations;
BEGIN
    UPDATE deload_recommendations
    SET status = 'dismissed',
        dismissed_at = now(),
        dismissed_reason = p_reason
    WHERE id = p_recommendation_id
      AND status = 'pending'
    RETURNING * INTO v_result;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Recommendation not found or not pending: %', p_recommendation_id;
    END IF;

    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION dismiss_deload(UUID, TEXT) IS
'Dismiss a pending deload recommendation with optional reason.';

-- =====================================================
-- 8. COMPLETE_DELOAD_PERIOD FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION complete_deload_period(
    p_deload_period_id UUID,
    p_early_termination BOOLEAN DEFAULT false,
    p_termination_reason TEXT DEFAULT NULL
)
RETURNS active_deload_periods
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_result active_deload_periods;
    v_recommendation_id UUID;
BEGIN
    -- Complete the deload period
    UPDATE active_deload_periods
    SET is_active = false,
        completed_at = now(),
        early_termination = p_early_termination,
        termination_reason = p_termination_reason
    WHERE id = p_deload_period_id
      AND is_active = true
    RETURNING * INTO v_result;

    v_recommendation_id := v_result.recommendation_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Active deload period not found: %', p_deload_period_id;
    END IF;

    -- Update the linked recommendation if exists
    IF v_recommendation_id IS NOT NULL THEN
        UPDATE deload_recommendations
        SET status = 'completed',
            completed_at = now()
        WHERE id = v_recommendation_id
          AND status = 'activated';
    END IF;

    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION complete_deload_period(UUID, BOOLEAN, TEXT) IS
'Complete an active deload period. Can be called for normal completion or early termination.';

-- =====================================================
-- 9. AUTO-EXPIRE DELOAD PERIODS (Scheduled Job Helper)
-- =====================================================

CREATE OR REPLACE FUNCTION auto_complete_expired_deload_periods()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_count INTEGER;
BEGIN
    -- Complete deload periods that have passed their end date
    WITH completed AS (
        UPDATE active_deload_periods
        SET is_active = false,
            completed_at = now()
        WHERE is_active = true
          AND end_date < CURRENT_DATE
        RETURNING id, recommendation_id
    )
    SELECT COUNT(*) INTO v_count FROM completed;

    -- Update linked recommendations
    UPDATE deload_recommendations dr
    SET status = 'completed',
        completed_at = now()
    FROM active_deload_periods adp
    WHERE adp.recommendation_id = dr.id
      AND adp.is_active = false
      AND adp.completed_at IS NOT NULL
      AND dr.status = 'activated';

    -- Expire pending recommendations that passed their expiration
    UPDATE deload_recommendations
    SET status = 'expired'
    WHERE status = 'pending'
      AND expires_at < now();

    RETURN v_count;
END;
$$;

COMMENT ON FUNCTION auto_complete_expired_deload_periods() IS
'Automatically complete deload periods that have passed their end date.
Designed to be called by a scheduled job (pg_cron).
Returns count of completed periods.';

-- =====================================================
-- 10. ROW-LEVEL SECURITY (RLS)
-- =====================================================

-- Enable RLS on both tables
ALTER TABLE deload_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE active_deload_periods ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------
-- DELOAD_RECOMMENDATIONS POLICIES
-- ----------------------------------------

-- Patients can view their own recommendations
CREATE POLICY "deload_rec_patients_select_own"
    ON deload_recommendations FOR SELECT
    TO authenticated
    USING (
        patient_id IN (
            SELECT p.id FROM patients p
            WHERE p.email = (auth.jwt() ->> 'email')
        )
    );

-- Patients can update their own recommendations (for dismissing)
CREATE POLICY "deload_rec_patients_update_own"
    ON deload_recommendations FOR UPDATE
    TO authenticated
    USING (
        patient_id IN (
            SELECT p.id FROM patients p
            WHERE p.email = (auth.jwt() ->> 'email')
        )
    )
    WITH CHECK (
        patient_id IN (
            SELECT p.id FROM patients p
            WHERE p.email = (auth.jwt() ->> 'email')
        )
    );

-- Therapists can view all recommendations
CREATE POLICY "deload_rec_therapists_select_all"
    ON deload_recommendations FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM auth.users u
            WHERE u.id = auth.uid()
              AND u.raw_user_meta_data->>'role' = 'therapist'
        )
    );

-- Service role has full access
CREATE POLICY "deload_rec_service_role_all"
    ON deload_recommendations FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ----------------------------------------
-- ACTIVE_DELOAD_PERIODS POLICIES
-- ----------------------------------------

-- Patients can view their own deload periods
CREATE POLICY "active_deload_patients_select_own"
    ON active_deload_periods FOR SELECT
    TO authenticated
    USING (
        patient_id IN (
            SELECT p.id FROM patients p
            WHERE p.email = (auth.jwt() ->> 'email')
        )
    );

-- Patients can update their own deload periods (for early termination)
CREATE POLICY "active_deload_patients_update_own"
    ON active_deload_periods FOR UPDATE
    TO authenticated
    USING (
        patient_id IN (
            SELECT p.id FROM patients p
            WHERE p.email = (auth.jwt() ->> 'email')
        )
    )
    WITH CHECK (
        patient_id IN (
            SELECT p.id FROM patients p
            WHERE p.email = (auth.jwt() ->> 'email')
        )
    );

-- Therapists can view all deload periods
CREATE POLICY "active_deload_therapists_select_all"
    ON active_deload_periods FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM auth.users u
            WHERE u.id = auth.uid()
              AND u.raw_user_meta_data->>'role' = 'therapist'
        )
    );

-- Therapists can update deload periods
CREATE POLICY "active_deload_therapists_update_all"
    ON active_deload_periods FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM auth.users u
            WHERE u.id = auth.uid()
              AND u.raw_user_meta_data->>'role' = 'therapist'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM auth.users u
            WHERE u.id = auth.uid()
              AND u.raw_user_meta_data->>'role' = 'therapist'
        )
    );

-- Service role has full access
CREATE POLICY "active_deload_service_role_all"
    ON active_deload_periods FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- =====================================================
-- 11. GRANT PERMISSIONS
-- =====================================================

-- deload_recommendations
GRANT SELECT, UPDATE ON deload_recommendations TO authenticated;
GRANT ALL ON deload_recommendations TO service_role;

-- active_deload_periods
GRANT SELECT, UPDATE ON active_deload_periods TO authenticated;
GRANT ALL ON active_deload_periods TO service_role;

-- Functions
GRANT EXECUTE ON FUNCTION is_in_deload_period(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION activate_deload(UUID, DATE, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION dismiss_deload(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION complete_deload_period(UUID, BOOLEAN, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION auto_complete_expired_deload_periods() TO service_role;

-- =====================================================
-- 12. TABLE AND COLUMN COMMENTS
-- =====================================================

COMMENT ON TABLE deload_recommendations IS
'AI-generated deload recommendations based on fatigue analysis.
Status flow: pending -> activated/dismissed -> completed/expired';

COMMENT ON COLUMN deload_recommendations.urgency IS 'suggested=mild, recommended=significant, required=critical';
COMMENT ON COLUMN deload_recommendations.contributing_factors IS 'JSONB array of factor strings like ["sleep_deficit", "high_training_load"]';
COMMENT ON COLUMN deload_recommendations.focus IS 'technique=skill work, mobility=flexibility, active_recovery=light activity, complete_rest=no training';
COMMENT ON COLUMN deload_recommendations.status IS 'pending=awaiting action, activated=deload started, dismissed=ignored, completed=deload finished, expired=no action taken';

COMMENT ON TABLE active_deload_periods IS
'Tracks active and historical deload periods for patients.
Created when a deload_recommendation is activated.';

COMMENT ON COLUMN active_deload_periods.is_active IS 'True if deload is currently in effect';
COMMENT ON COLUMN active_deload_periods.early_termination IS 'True if deload was ended before scheduled end_date';

-- =====================================================
-- 13. VERIFICATION
-- =====================================================

DO $$
DECLARE
    v_rec_table_exists BOOLEAN;
    v_periods_table_exists BOOLEAN;
    v_is_in_deload_exists BOOLEAN;
    v_activate_deload_exists BOOLEAN;
    v_rec_policy_count INTEGER;
    v_periods_policy_count INTEGER;
BEGIN
    -- Check tables exist
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'deload_recommendations'
    ) INTO v_rec_table_exists;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'active_deload_periods'
    ) INTO v_periods_table_exists;

    -- Check functions exist
    SELECT EXISTS (
        SELECT 1 FROM information_schema.routines
        WHERE routine_schema = 'public' AND routine_name = 'is_in_deload_period'
    ) INTO v_is_in_deload_exists;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.routines
        WHERE routine_schema = 'public' AND routine_name = 'activate_deload'
    ) INTO v_activate_deload_exists;

    -- Count policies
    SELECT COUNT(*) INTO v_rec_policy_count
    FROM pg_policies WHERE tablename = 'deload_recommendations';

    SELECT COUNT(*) INTO v_periods_policy_count
    FROM pg_policies WHERE tablename = 'active_deload_periods';

    -- Validate
    IF NOT v_rec_table_exists THEN
        RAISE EXCEPTION 'FAILED: deload_recommendations table not created';
    END IF;

    IF NOT v_periods_table_exists THEN
        RAISE EXCEPTION 'FAILED: active_deload_periods table not created';
    END IF;

    IF NOT v_is_in_deload_exists THEN
        RAISE EXCEPTION 'FAILED: is_in_deload_period function not created';
    END IF;

    IF NOT v_activate_deload_exists THEN
        RAISE EXCEPTION 'FAILED: activate_deload function not created';
    END IF;

    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'DELOAD RECOMMENDATIONS SCHEMA - SMART RECOVERY SPRINT';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Tables Created:';
    RAISE NOTICE '  - deload_recommendations (% RLS policies)', v_rec_policy_count;
    RAISE NOTICE '  - active_deload_periods (% RLS policies)', v_periods_policy_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Functions Created:';
    RAISE NOTICE '  - is_in_deload_period(patient_id UUID)';
    RAISE NOTICE '  - activate_deload(recommendation_id UUID, start_date DATE, custom_duration INTEGER)';
    RAISE NOTICE '  - dismiss_deload(recommendation_id UUID, reason TEXT)';
    RAISE NOTICE '  - complete_deload_period(deload_period_id UUID, early_termination BOOLEAN, reason TEXT)';
    RAISE NOTICE '  - auto_complete_expired_deload_periods()';
    RAISE NOTICE '';
    RAISE NOTICE 'Status Flow:';
    RAISE NOTICE '  pending -> activated -> completed';
    RAISE NOTICE '         \-> dismissed';
    RAISE NOTICE '         \-> expired (after 48h)';
    RAISE NOTICE '';
    RAISE NOTICE 'Urgency Levels:';
    RAISE NOTICE '  suggested | recommended | required';
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'MIGRATION COMPLETE - Agent 2 Smart Recovery Sprint';
    RAISE NOTICE '============================================================================';
END $$;
