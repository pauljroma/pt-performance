-- ACP-545: Shoulder Health Dashboard
-- Creates tables for ROM tracking, strength measurements, and alerts

-- ============================================================================
-- SHOULDER ROM MEASUREMENTS TABLE
-- Tracks internal/external rotation range of motion
-- ============================================================================

CREATE TABLE IF NOT EXISTS shoulder_rom_measurements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    side TEXT NOT NULL CHECK (side IN ('left', 'right', 'dominant', 'non_dominant')),
    internal_rotation DOUBLE PRECISION NOT NULL CHECK (internal_rotation >= 0 AND internal_rotation <= 180),
    external_rotation DOUBLE PRECISION NOT NULL CHECK (external_rotation >= 0 AND external_rotation <= 180),
    notes TEXT,
    measured_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_shoulder_rom_patient_id ON shoulder_rom_measurements(patient_id);
CREATE INDEX IF NOT EXISTS idx_shoulder_rom_measured_at ON shoulder_rom_measurements(measured_at DESC);
CREATE INDEX IF NOT EXISTS idx_shoulder_rom_patient_side ON shoulder_rom_measurements(patient_id, side);

-- ============================================================================
-- SHOULDER STRENGTH MEASUREMENTS TABLE
-- Tracks internal/external rotation strength for ER:IR ratio calculation
-- ============================================================================

CREATE TABLE IF NOT EXISTS shoulder_strength_measurements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    side TEXT NOT NULL CHECK (side IN ('left', 'right', 'dominant', 'non_dominant')),
    internal_rotation_strength DOUBLE PRECISION NOT NULL CHECK (internal_rotation_strength >= 0),
    external_rotation_strength DOUBLE PRECISION NOT NULL CHECK (external_rotation_strength >= 0),
    unit TEXT NOT NULL DEFAULT 'lbs' CHECK (unit IN ('lbs', 'N', 'kg')),
    notes TEXT,
    measured_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_shoulder_strength_patient_id ON shoulder_strength_measurements(patient_id);
CREATE INDEX IF NOT EXISTS idx_shoulder_strength_measured_at ON shoulder_strength_measurements(measured_at DESC);
CREATE INDEX IF NOT EXISTS idx_shoulder_strength_patient_side ON shoulder_strength_measurements(patient_id, side);

-- ============================================================================
-- SHOULDER ALERTS TABLE
-- Stores generated alerts based on measurements and trends
-- ============================================================================

CREATE TABLE IF NOT EXISTS shoulder_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN (
        'ir_deficit',
        'er_deficit',
        'low_er_ir_ratio',
        'high_er_ir_ratio',
        'decreasing_rom',
        'asymmetry',
        'gird'
    )),
    message TEXT NOT NULL,
    recommendation TEXT NOT NULL,
    severity TEXT NOT NULL DEFAULT 'warning' CHECK (severity IN ('info', 'warning', 'critical')),
    acknowledged BOOLEAN DEFAULT false,
    acknowledged_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_shoulder_alerts_patient_id ON shoulder_alerts(patient_id);
CREATE INDEX IF NOT EXISTS idx_shoulder_alerts_created_at ON shoulder_alerts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_shoulder_alerts_patient_active ON shoulder_alerts(patient_id, acknowledged);

-- ============================================================================
-- FUNCTION: Calculate ER:IR Ratio
-- ============================================================================

CREATE OR REPLACE FUNCTION calculate_er_ir_ratio(
    p_internal_rotation DOUBLE PRECISION,
    p_external_rotation DOUBLE PRECISION
)
RETURNS DOUBLE PRECISION
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    IF p_internal_rotation = 0 THEN
        RETURN 0;
    END IF;
    RETURN (p_external_rotation / p_internal_rotation) * 100;
END;
$$;

-- ============================================================================
-- FUNCTION: Check for concerning patterns and create alerts
-- ============================================================================

CREATE OR REPLACE FUNCTION check_shoulder_health_patterns()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_ratio DOUBLE PRECISION;
    v_opposite_side TEXT;
    v_opposite_rom shoulder_rom_measurements%ROWTYPE;
    v_ir_diff DOUBLE PRECISION;
BEGIN
    -- For strength measurements, check ER:IR ratio
    IF TG_TABLE_NAME = 'shoulder_strength_measurements' THEN
        v_ratio := calculate_er_ir_ratio(NEW.internal_rotation_strength, NEW.external_rotation_strength);

        -- Alert if ratio is below 66% (target is 66-75%)
        IF v_ratio < 66 AND v_ratio > 0 THEN
            INSERT INTO shoulder_alerts (
                patient_id,
                type,
                message,
                recommendation,
                severity
            ) VALUES (
                NEW.patient_id,
                'low_er_ir_ratio',
                'ER:IR ratio low at ' || ROUND(v_ratio::numeric, 1) || '% - target is 66-75%',
                'Prioritize cuff strengthening exercises',
                CASE WHEN v_ratio < 60 THEN 'critical' ELSE 'warning' END
            );
        END IF;
    END IF;

    -- For ROM measurements, check for IR deficit and GIRD
    IF TG_TABLE_NAME = 'shoulder_rom_measurements' THEN
        -- Check for IR deficit (< 60 degrees)
        IF NEW.internal_rotation < 60 THEN
            INSERT INTO shoulder_alerts (
                patient_id,
                type,
                message,
                recommendation,
                severity
            ) VALUES (
                NEW.patient_id,
                'ir_deficit',
                'IR deficit detected - ' || ROUND((70 - NEW.internal_rotation)::numeric, 0) || ' degrees below baseline',
                'Add sleeper stretches to your routine',
                CASE WHEN NEW.internal_rotation < 50 THEN 'critical' ELSE 'warning' END
            );
        END IF;

        -- Check for GIRD (compare to opposite side)
        v_opposite_side := CASE
            WHEN NEW.side = 'left' THEN 'right'
            WHEN NEW.side = 'right' THEN 'left'
            WHEN NEW.side = 'dominant' THEN 'non_dominant'
            ELSE 'dominant'
        END;

        SELECT * INTO v_opposite_rom
        FROM shoulder_rom_measurements
        WHERE patient_id = NEW.patient_id
          AND side = v_opposite_side
        ORDER BY measured_at DESC
        LIMIT 1;

        IF v_opposite_rom.id IS NOT NULL THEN
            v_ir_diff := v_opposite_rom.internal_rotation - NEW.internal_rotation;

            -- GIRD is typically defined as >18-20 degrees difference
            IF v_ir_diff > 18 THEN
                INSERT INTO shoulder_alerts (
                    patient_id,
                    type,
                    message,
                    recommendation,
                    severity
                ) VALUES (
                    NEW.patient_id,
                    'gird',
                    'Possible GIRD detected: ' || ROUND(v_ir_diff::numeric, 0) || ' degree IR difference from opposite side',
                    'GIRD protocol: sleeper stretch + posterior capsule work',
                    CASE WHEN v_ir_diff > 25 THEN 'critical' ELSE 'warning' END
                );
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

-- Create triggers for automatic pattern detection
DROP TRIGGER IF EXISTS trg_check_shoulder_strength_patterns ON shoulder_strength_measurements;
CREATE TRIGGER trg_check_shoulder_strength_patterns
    AFTER INSERT ON shoulder_strength_measurements
    FOR EACH ROW
    EXECUTE FUNCTION check_shoulder_health_patterns();

DROP TRIGGER IF EXISTS trg_check_shoulder_rom_patterns ON shoulder_rom_measurements;
CREATE TRIGGER trg_check_shoulder_rom_patterns
    AFTER INSERT ON shoulder_rom_measurements
    FOR EACH ROW
    EXECUTE FUNCTION check_shoulder_health_patterns();

-- ============================================================================
-- FUNCTION: Get shoulder health summary for a patient
-- ============================================================================

CREATE OR REPLACE FUNCTION get_shoulder_health_summary(
    p_patient_id UUID,
    p_side TEXT DEFAULT 'right'
)
RETURNS TABLE (
    latest_ir DOUBLE PRECISION,
    latest_er DOUBLE PRECISION,
    total_arc DOUBLE PRECISION,
    latest_ir_strength DOUBLE PRECISION,
    latest_er_strength DOUBLE PRECISION,
    er_ir_ratio DOUBLE PRECISION,
    active_alerts_count INTEGER,
    last_rom_date TIMESTAMPTZ,
    last_strength_date TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_rom shoulder_rom_measurements%ROWTYPE;
    v_strength shoulder_strength_measurements%ROWTYPE;
    v_alerts_count INTEGER;
BEGIN
    -- Get latest ROM measurement
    SELECT * INTO v_rom
    FROM shoulder_rom_measurements
    WHERE patient_id = p_patient_id AND side = p_side
    ORDER BY measured_at DESC
    LIMIT 1;

    -- Get latest strength measurement
    SELECT * INTO v_strength
    FROM shoulder_strength_measurements
    WHERE patient_id = p_patient_id AND side = p_side
    ORDER BY measured_at DESC
    LIMIT 1;

    -- Count active (unacknowledged) alerts
    SELECT COUNT(*) INTO v_alerts_count
    FROM shoulder_alerts
    WHERE patient_id = p_patient_id AND acknowledged = false;

    RETURN QUERY SELECT
        COALESCE(v_rom.internal_rotation, 0),
        COALESCE(v_rom.external_rotation, 0),
        COALESCE(v_rom.internal_rotation, 0) + COALESCE(v_rom.external_rotation, 0),
        COALESCE(v_strength.internal_rotation_strength, 0),
        COALESCE(v_strength.external_rotation_strength, 0),
        CASE
            WHEN v_strength.internal_rotation_strength > 0
            THEN (v_strength.external_rotation_strength / v_strength.internal_rotation_strength) * 100
            ELSE 0
        END,
        v_alerts_count,
        v_rom.measured_at,
        v_strength.measured_at;
END;
$$;

-- ============================================================================
-- FUNCTION: Get ROM trend data for charts
-- ============================================================================

CREATE OR REPLACE FUNCTION get_shoulder_rom_trend(
    p_patient_id UUID,
    p_side TEXT DEFAULT 'right',
    p_days INTEGER DEFAULT 30
)
RETURNS TABLE (
    measured_at TIMESTAMPTZ,
    internal_rotation DOUBLE PRECISION,
    external_rotation DOUBLE PRECISION,
    total_arc DOUBLE PRECISION
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        m.measured_at,
        m.internal_rotation,
        m.external_rotation,
        m.internal_rotation + m.external_rotation AS total_arc
    FROM shoulder_rom_measurements m
    WHERE m.patient_id = p_patient_id
      AND m.side = p_side
      AND m.measured_at >= CURRENT_DATE - p_days
    ORDER BY m.measured_at ASC;
END;
$$;

-- ============================================================================
-- FUNCTION: Get strength ratio trend for charts
-- ============================================================================

CREATE OR REPLACE FUNCTION get_shoulder_ratio_trend(
    p_patient_id UUID,
    p_side TEXT DEFAULT 'right',
    p_days INTEGER DEFAULT 30
)
RETURNS TABLE (
    measured_at TIMESTAMPTZ,
    ir_strength DOUBLE PRECISION,
    er_strength DOUBLE PRECISION,
    er_ir_ratio DOUBLE PRECISION
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        m.measured_at,
        m.internal_rotation_strength,
        m.external_rotation_strength,
        calculate_er_ir_ratio(m.internal_rotation_strength, m.external_rotation_strength) AS er_ir_ratio
    FROM shoulder_strength_measurements m
    WHERE m.patient_id = p_patient_id
      AND m.side = p_side
      AND m.measured_at >= CURRENT_DATE - p_days
    ORDER BY m.measured_at ASC;
END;
$$;

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

-- Enable RLS
ALTER TABLE shoulder_rom_measurements ENABLE ROW LEVEL SECURITY;
ALTER TABLE shoulder_strength_measurements ENABLE ROW LEVEL SECURITY;
ALTER TABLE shoulder_alerts ENABLE ROW LEVEL SECURITY;

-- ROM Measurements Policies
DROP POLICY IF EXISTS "shoulder_rom_select_own" ON shoulder_rom_measurements;
CREATE POLICY "shoulder_rom_select_own" ON shoulder_rom_measurements
    FOR SELECT
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "shoulder_rom_insert_own" ON shoulder_rom_measurements;
CREATE POLICY "shoulder_rom_insert_own" ON shoulder_rom_measurements
    FOR INSERT
    WITH CHECK (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "shoulder_rom_update_own" ON shoulder_rom_measurements;
CREATE POLICY "shoulder_rom_update_own" ON shoulder_rom_measurements
    FOR UPDATE
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "shoulder_rom_delete_own" ON shoulder_rom_measurements;
CREATE POLICY "shoulder_rom_delete_own" ON shoulder_rom_measurements
    FOR DELETE
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

-- Strength Measurements Policies
DROP POLICY IF EXISTS "shoulder_strength_select_own" ON shoulder_strength_measurements;
CREATE POLICY "shoulder_strength_select_own" ON shoulder_strength_measurements
    FOR SELECT
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "shoulder_strength_insert_own" ON shoulder_strength_measurements;
CREATE POLICY "shoulder_strength_insert_own" ON shoulder_strength_measurements
    FOR INSERT
    WITH CHECK (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "shoulder_strength_update_own" ON shoulder_strength_measurements;
CREATE POLICY "shoulder_strength_update_own" ON shoulder_strength_measurements
    FOR UPDATE
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "shoulder_strength_delete_own" ON shoulder_strength_measurements;
CREATE POLICY "shoulder_strength_delete_own" ON shoulder_strength_measurements
    FOR DELETE
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

-- Alerts Policies
DROP POLICY IF EXISTS "shoulder_alerts_select_own" ON shoulder_alerts;
CREATE POLICY "shoulder_alerts_select_own" ON shoulder_alerts
    FOR SELECT
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "shoulder_alerts_insert_own" ON shoulder_alerts;
CREATE POLICY "shoulder_alerts_insert_own" ON shoulder_alerts
    FOR INSERT
    WITH CHECK (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "shoulder_alerts_update_own" ON shoulder_alerts;
CREATE POLICY "shoulder_alerts_update_own" ON shoulder_alerts
    FOR UPDATE
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

-- Therapist access policies for ROM measurements
DROP POLICY IF EXISTS "shoulder_rom_therapist_select" ON shoulder_rom_measurements;
CREATE POLICY "shoulder_rom_therapist_select" ON shoulder_rom_measurements
    FOR SELECT
    USING (
        patient_id IN (
            SELECT tp.patient_id
            FROM therapist_patients tp
            JOIN therapists t ON t.id = tp.therapist_id
            WHERE t.user_id = auth.uid()
        )
    );

-- Therapist access policies for strength measurements
DROP POLICY IF EXISTS "shoulder_strength_therapist_select" ON shoulder_strength_measurements;
CREATE POLICY "shoulder_strength_therapist_select" ON shoulder_strength_measurements
    FOR SELECT
    USING (
        patient_id IN (
            SELECT tp.patient_id
            FROM therapist_patients tp
            JOIN therapists t ON t.id = tp.therapist_id
            WHERE t.user_id = auth.uid()
        )
    );

-- Therapist access policies for alerts
DROP POLICY IF EXISTS "shoulder_alerts_therapist_select" ON shoulder_alerts;
CREATE POLICY "shoulder_alerts_therapist_select" ON shoulder_alerts
    FOR SELECT
    USING (
        patient_id IN (
            SELECT tp.patient_id
            FROM therapist_patients tp
            JOIN therapists t ON t.id = tp.therapist_id
            WHERE t.user_id = auth.uid()
        )
    );

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON shoulder_rom_measurements TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON shoulder_strength_measurements TO authenticated;
GRANT SELECT, INSERT, UPDATE ON shoulder_alerts TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_er_ir_ratio TO authenticated;
GRANT EXECUTE ON FUNCTION get_shoulder_health_summary TO authenticated;
GRANT EXECUTE ON FUNCTION get_shoulder_rom_trend TO authenticated;
GRANT EXECUTE ON FUNCTION get_shoulder_ratio_trend TO authenticated;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE shoulder_rom_measurements IS 'Stores shoulder range of motion measurements (IR/ER) for tracking and trend analysis';
COMMENT ON TABLE shoulder_strength_measurements IS 'Stores shoulder strength measurements for ER:IR ratio calculation';
COMMENT ON TABLE shoulder_alerts IS 'Stores generated alerts based on shoulder health patterns';
COMMENT ON FUNCTION calculate_er_ir_ratio IS 'Calculates the external:internal rotation strength ratio';
COMMENT ON FUNCTION check_shoulder_health_patterns IS 'Trigger function to detect concerning patterns and generate alerts';
COMMENT ON FUNCTION get_shoulder_health_summary IS 'Returns comprehensive shoulder health summary for a patient';
COMMENT ON FUNCTION get_shoulder_rom_trend IS 'Returns ROM trend data for charts over specified days';
COMMENT ON FUNCTION get_shoulder_ratio_trend IS 'Returns strength ratio trend data for charts over specified days';
