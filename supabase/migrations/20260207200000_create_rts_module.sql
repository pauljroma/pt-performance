-- RTS (Return to Sport) Module Database Migration
-- Created: 2026-02-07
-- Purpose: Complete schema for managing athlete return-to-sport protocols,
--          including phase-based progression, milestone criteria, clearance documents,
--          and risk assessment with traffic light system

-- ============================================================================
-- TABLE 1: RTS_SPORTS
-- Sport definitions with default phase templates
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.rts_sports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Sport identification
    name TEXT NOT NULL UNIQUE,               -- e.g., "Baseball - Throwing"
    category TEXT NOT NULL,                  -- throwing, running, cutting

    -- Default phase templates for this sport (JSONB array)
    -- Structure: [{ phase_number, phase_name, activity_level, description, target_duration_days }]
    default_phases JSONB NOT NULL DEFAULT '[]'::jsonb,

    -- Audit columns
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for rts_sports
CREATE INDEX IF NOT EXISTS idx_rts_sports_category
    ON public.rts_sports(category);

CREATE INDEX IF NOT EXISTS idx_rts_sports_name
    ON public.rts_sports(name);

-- ============================================================================
-- TABLE 2: RTS_PROTOCOLS
-- Patient RTS journey - the main tracking entity
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.rts_protocols (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Foreign keys
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    therapist_id UUID NOT NULL REFERENCES public.therapists(id),
    sport_id UUID NOT NULL REFERENCES public.rts_sports(id),

    -- Injury information
    injury_type TEXT NOT NULL,               -- e.g., "UCL Reconstruction", "ACL Tear"
    surgery_date DATE,                       -- nullable for non-surgical cases
    injury_date DATE NOT NULL,

    -- Target dates
    target_return_date DATE NOT NULL,
    actual_return_date DATE,                 -- set when protocol completes successfully

    -- Protocol status
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'completed', 'discontinued')),

    -- Current phase tracking (nullable during draft)
    current_phase_id UUID,                   -- FK added after rts_phases table

    -- Notes
    notes TEXT,

    -- Audit columns
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for rts_protocols
CREATE INDEX IF NOT EXISTS idx_rts_protocols_patient_id
    ON public.rts_protocols(patient_id);

CREATE INDEX IF NOT EXISTS idx_rts_protocols_therapist_id
    ON public.rts_protocols(therapist_id);

CREATE INDEX IF NOT EXISTS idx_rts_protocols_sport_id
    ON public.rts_protocols(sport_id);

CREATE INDEX IF NOT EXISTS idx_rts_protocols_status
    ON public.rts_protocols(status);

CREATE INDEX IF NOT EXISTS idx_rts_protocols_patient_status
    ON public.rts_protocols(patient_id, status);

CREATE INDEX IF NOT EXISTS idx_rts_protocols_therapist_status
    ON public.rts_protocols(therapist_id, status);

CREATE INDEX IF NOT EXISTS idx_rts_protocols_injury_date
    ON public.rts_protocols(injury_date DESC);

-- ============================================================================
-- TABLE 3: RTS_PHASES
-- Phases within a protocol (e.g., Protected, Controlled Activity, etc.)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.rts_phases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Parent protocol
    protocol_id UUID NOT NULL REFERENCES public.rts_protocols(id) ON DELETE CASCADE,

    -- Phase definition
    phase_number INTEGER NOT NULL,
    phase_name TEXT NOT NULL,                -- e.g., "Protected", "Controlled Activity"
    activity_level TEXT NOT NULL CHECK (activity_level IN ('green', 'yellow', 'red')),
    description TEXT NOT NULL,

    -- Entry/Exit criteria (JSONB arrays)
    -- Structure: [{ category, name, description, target_value, target_unit, comparison_operator }]
    entry_criteria JSONB NOT NULL DEFAULT '[]'::jsonb,
    exit_criteria JSONB NOT NULL DEFAULT '[]'::jsonb,

    -- Timing
    started_at TIMESTAMPTZ,                  -- when phase was entered
    completed_at TIMESTAMPTZ,                -- when phase was exited
    target_duration_days INTEGER,            -- expected duration

    -- Audit columns
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Ensure unique phase numbers per protocol
    CONSTRAINT rts_phases_protocol_phase_unique UNIQUE (protocol_id, phase_number)
);

-- Add FK from rts_protocols to rts_phases (now that table exists)
ALTER TABLE public.rts_protocols
    ADD CONSTRAINT fk_rts_protocols_current_phase
    FOREIGN KEY (current_phase_id) REFERENCES public.rts_phases(id)
    ON DELETE SET NULL;

-- Indexes for rts_phases
CREATE INDEX IF NOT EXISTS idx_rts_phases_protocol_id
    ON public.rts_phases(protocol_id);

CREATE INDEX IF NOT EXISTS idx_rts_phases_protocol_number
    ON public.rts_phases(protocol_id, phase_number);

CREATE INDEX IF NOT EXISTS idx_rts_phases_activity_level
    ON public.rts_phases(activity_level);

CREATE INDEX IF NOT EXISTS idx_rts_phases_started_at
    ON public.rts_phases(started_at DESC) WHERE started_at IS NOT NULL;

-- ============================================================================
-- TABLE 4: RTS_MILESTONE_CRITERIA
-- Criteria definitions per phase (functional tests, strength tests, etc.)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.rts_milestone_criteria (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Parent phase
    phase_id UUID NOT NULL REFERENCES public.rts_phases(id) ON DELETE CASCADE,

    -- Criterion definition
    category TEXT NOT NULL CHECK (category IN ('functional', 'strength', 'rom', 'pain', 'psychological')),
    name TEXT NOT NULL,                      -- e.g., "Single Leg Hop Test"
    description TEXT NOT NULL,

    -- Target values
    target_value NUMERIC,                    -- nullable for subjective criteria
    target_unit TEXT,                        -- e.g., "% LSI", "degrees", "score"
    comparison_operator TEXT NOT NULL DEFAULT '>=' CHECK (comparison_operator IN ('>=', '<=', '==', 'between')),

    -- Flags
    is_required BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order INTEGER NOT NULL DEFAULT 0,

    -- Audit columns
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for rts_milestone_criteria
CREATE INDEX IF NOT EXISTS idx_rts_milestone_criteria_phase_id
    ON public.rts_milestone_criteria(phase_id);

CREATE INDEX IF NOT EXISTS idx_rts_milestone_criteria_category
    ON public.rts_milestone_criteria(category);

CREATE INDEX IF NOT EXISTS idx_rts_milestone_criteria_phase_order
    ON public.rts_milestone_criteria(phase_id, sort_order);

CREATE INDEX IF NOT EXISTS idx_rts_milestone_criteria_required
    ON public.rts_milestone_criteria(phase_id, is_required) WHERE is_required = true;

-- ============================================================================
-- TABLE 5: RTS_TEST_RESULTS
-- Actual test measurements recorded during the protocol
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.rts_test_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Foreign keys
    criterion_id UUID NOT NULL REFERENCES public.rts_milestone_criteria(id) ON DELETE CASCADE,
    protocol_id UUID NOT NULL REFERENCES public.rts_protocols(id) ON DELETE CASCADE,
    recorded_by UUID NOT NULL REFERENCES public.therapists(id),

    -- Result data
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    value NUMERIC NOT NULL,
    unit TEXT NOT NULL,
    passed BOOLEAN NOT NULL,

    -- Notes
    notes TEXT,

    -- Audit column (no updated_at - results are immutable)
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for rts_test_results
CREATE INDEX IF NOT EXISTS idx_rts_test_results_criterion_id
    ON public.rts_test_results(criterion_id);

CREATE INDEX IF NOT EXISTS idx_rts_test_results_protocol_id
    ON public.rts_test_results(protocol_id);

CREATE INDEX IF NOT EXISTS idx_rts_test_results_recorded_by
    ON public.rts_test_results(recorded_by);

CREATE INDEX IF NOT EXISTS idx_rts_test_results_recorded_at
    ON public.rts_test_results(recorded_at DESC);

CREATE INDEX IF NOT EXISTS idx_rts_test_results_protocol_date
    ON public.rts_test_results(protocol_id, recorded_at DESC);

CREATE INDEX IF NOT EXISTS idx_rts_test_results_passed
    ON public.rts_test_results(protocol_id, passed);

-- ============================================================================
-- TABLE 6: RTS_PHASE_ADVANCEMENTS
-- Decision log for phase transitions (audit trail)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.rts_phase_advancements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Foreign keys
    protocol_id UUID NOT NULL REFERENCES public.rts_protocols(id) ON DELETE CASCADE,
    from_phase_id UUID REFERENCES public.rts_phases(id) ON DELETE SET NULL,  -- nullable for initial phase
    to_phase_id UUID NOT NULL REFERENCES public.rts_phases(id) ON DELETE CASCADE,

    -- Decision details
    decision TEXT NOT NULL CHECK (decision IN ('advance', 'extend', 'hold', 'manual_override')),
    decision_reason TEXT NOT NULL,

    -- Snapshot of criteria status at time of decision
    -- Structure: { criteria: [{ id, name, value, target, passed }], summary: { passed, failed, total } }
    criteria_summary JSONB NOT NULL DEFAULT '{}'::jsonb,

    -- Who made the decision
    decided_by UUID NOT NULL REFERENCES public.therapists(id),
    decided_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Audit column (no updated_at - decisions are immutable)
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for rts_phase_advancements
CREATE INDEX IF NOT EXISTS idx_rts_phase_advancements_protocol_id
    ON public.rts_phase_advancements(protocol_id);

CREATE INDEX IF NOT EXISTS idx_rts_phase_advancements_from_phase
    ON public.rts_phase_advancements(from_phase_id);

CREATE INDEX IF NOT EXISTS idx_rts_phase_advancements_to_phase
    ON public.rts_phase_advancements(to_phase_id);

CREATE INDEX IF NOT EXISTS idx_rts_phase_advancements_decided_by
    ON public.rts_phase_advancements(decided_by);

CREATE INDEX IF NOT EXISTS idx_rts_phase_advancements_decided_at
    ON public.rts_phase_advancements(decided_at DESC);

CREATE INDEX IF NOT EXISTS idx_rts_phase_advancements_decision
    ON public.rts_phase_advancements(decision);

-- ============================================================================
-- TABLE 7: RTS_CLEARANCES
-- Formal clearance documents (phase and final clearances)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.rts_clearances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Parent protocol
    protocol_id UUID NOT NULL REFERENCES public.rts_protocols(id) ON DELETE CASCADE,

    -- Clearance type and level
    clearance_type TEXT NOT NULL CHECK (clearance_type IN ('phase_clearance', 'final_clearance', 'conditional_clearance')),
    clearance_level TEXT NOT NULL CHECK (clearance_level IN ('green', 'yellow', 'red')),

    -- Document status (signing workflow)
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'complete', 'signed', 'co_signed')),

    -- Content
    assessment_summary TEXT NOT NULL,
    recommendations TEXT NOT NULL,
    restrictions TEXT,                       -- nullable - only for conditional clearances

    -- Signature workflow
    requires_physician_signature BOOLEAN NOT NULL DEFAULT FALSE,
    signed_by UUID REFERENCES public.therapists(id),
    signed_at TIMESTAMPTZ,
    co_signed_by UUID,                       -- physician UUID (may not be in therapists table)
    co_signed_at TIMESTAMPTZ,

    -- Audit columns
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for rts_clearances
CREATE INDEX IF NOT EXISTS idx_rts_clearances_protocol_id
    ON public.rts_clearances(protocol_id);

CREATE INDEX IF NOT EXISTS idx_rts_clearances_type
    ON public.rts_clearances(clearance_type);

CREATE INDEX IF NOT EXISTS idx_rts_clearances_level
    ON public.rts_clearances(clearance_level);

CREATE INDEX IF NOT EXISTS idx_rts_clearances_status
    ON public.rts_clearances(status);

CREATE INDEX IF NOT EXISTS idx_rts_clearances_signed_by
    ON public.rts_clearances(signed_by) WHERE signed_by IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_rts_clearances_pending_signature
    ON public.rts_clearances(status, requires_physician_signature)
    WHERE status = 'signed' AND requires_physician_signature = true;

-- ============================================================================
-- TABLE 8: RTS_READINESS_SCORES
-- Risk assessment scores with traffic light system
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.rts_readiness_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Foreign keys
    protocol_id UUID NOT NULL REFERENCES public.rts_protocols(id) ON DELETE CASCADE,
    phase_id UUID NOT NULL REFERENCES public.rts_phases(id) ON DELETE CASCADE,
    recorded_by UUID NOT NULL REFERENCES public.therapists(id),

    -- Timing
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Scores (0-100 scale)
    physical_score NUMERIC NOT NULL CHECK (physical_score >= 0 AND physical_score <= 100),
    functional_score NUMERIC NOT NULL CHECK (functional_score >= 0 AND functional_score <= 100),
    psychological_score NUMERIC NOT NULL CHECK (psychological_score >= 0 AND psychological_score <= 100),
    overall_score NUMERIC NOT NULL CHECK (overall_score >= 0 AND overall_score <= 100),

    -- Traffic light (computed: green 80+, yellow 60-79, red <60)
    traffic_light TEXT NOT NULL CHECK (traffic_light IN ('green', 'yellow', 'red')),

    -- Risk factors identified
    -- Structure: [{ category, factor, severity, recommendation }]
    risk_factors JSONB NOT NULL DEFAULT '[]'::jsonb,

    -- Notes
    notes TEXT,

    -- Audit column (no updated_at - scores are immutable)
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for rts_readiness_scores
CREATE INDEX IF NOT EXISTS idx_rts_readiness_scores_protocol_id
    ON public.rts_readiness_scores(protocol_id);

CREATE INDEX IF NOT EXISTS idx_rts_readiness_scores_phase_id
    ON public.rts_readiness_scores(phase_id);

CREATE INDEX IF NOT EXISTS idx_rts_readiness_scores_recorded_by
    ON public.rts_readiness_scores(recorded_by);

CREATE INDEX IF NOT EXISTS idx_rts_readiness_scores_recorded_at
    ON public.rts_readiness_scores(recorded_at DESC);

CREATE INDEX IF NOT EXISTS idx_rts_readiness_scores_traffic_light
    ON public.rts_readiness_scores(traffic_light);

CREATE INDEX IF NOT EXISTS idx_rts_readiness_scores_protocol_date
    ON public.rts_readiness_scores(protocol_id, recorded_at DESC);

CREATE INDEX IF NOT EXISTS idx_rts_readiness_scores_overall
    ON public.rts_readiness_scores(overall_score);

-- ============================================================================
-- TRIGGERS: Update timestamps
-- ============================================================================

-- Generic updated_at trigger function (reuse if exists)
CREATE OR REPLACE FUNCTION update_rts_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$;

-- Apply to tables with updated_at
DROP TRIGGER IF EXISTS trigger_rts_sports_updated ON public.rts_sports;
CREATE TRIGGER trigger_rts_sports_updated
    BEFORE UPDATE ON public.rts_sports
    FOR EACH ROW
    EXECUTE FUNCTION update_rts_updated_at();

DROP TRIGGER IF EXISTS trigger_rts_protocols_updated ON public.rts_protocols;
CREATE TRIGGER trigger_rts_protocols_updated
    BEFORE UPDATE ON public.rts_protocols
    FOR EACH ROW
    EXECUTE FUNCTION update_rts_updated_at();

DROP TRIGGER IF EXISTS trigger_rts_phases_updated ON public.rts_phases;
CREATE TRIGGER trigger_rts_phases_updated
    BEFORE UPDATE ON public.rts_phases
    FOR EACH ROW
    EXECUTE FUNCTION update_rts_updated_at();

DROP TRIGGER IF EXISTS trigger_rts_milestone_criteria_updated ON public.rts_milestone_criteria;
CREATE TRIGGER trigger_rts_milestone_criteria_updated
    BEFORE UPDATE ON public.rts_milestone_criteria
    FOR EACH ROW
    EXECUTE FUNCTION update_rts_updated_at();

DROP TRIGGER IF EXISTS trigger_rts_clearances_updated ON public.rts_clearances;
CREATE TRIGGER trigger_rts_clearances_updated
    BEFORE UPDATE ON public.rts_clearances
    FOR EACH ROW
    EXECUTE FUNCTION update_rts_updated_at();

-- ============================================================================
-- TRIGGER: Calculate traffic light for readiness scores
-- ============================================================================

CREATE OR REPLACE FUNCTION calculate_rts_readiness_traffic_light()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Traffic light based on overall score
    -- Green (80+): Full activity approved
    -- Yellow (60-79): Modified activity with caution
    -- Red (<60): Hold or regress
    IF NEW.overall_score >= 80 THEN
        NEW.traffic_light := 'green';
    ELSIF NEW.overall_score >= 60 THEN
        NEW.traffic_light := 'yellow';
    ELSE
        NEW.traffic_light := 'red';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_rts_readiness_traffic_light ON public.rts_readiness_scores;
CREATE TRIGGER trigger_rts_readiness_traffic_light
    BEFORE INSERT OR UPDATE ON public.rts_readiness_scores
    FOR EACH ROW
    EXECUTE FUNCTION calculate_rts_readiness_traffic_light();

-- ============================================================================
-- RLS POLICIES: rts_sports (read-only for all authenticated users)
-- ============================================================================

ALTER TABLE public.rts_sports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view sports"
    ON public.rts_sports
    FOR SELECT
    TO authenticated
    USING (true);

-- Only allow insert/update/delete through migrations or admin
-- No policies for INSERT/UPDATE/DELETE = only service role can modify

-- ============================================================================
-- RLS POLICIES: rts_protocols
-- ============================================================================

ALTER TABLE public.rts_protocols ENABLE ROW LEVEL SECURITY;

-- Patients can view their own protocols (read-only)
CREATE POLICY "Patients can view own protocols"
    ON public.rts_protocols
    FOR SELECT
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM public.patients
            WHERE user_id = auth.uid()
        )
    );

-- Therapists can view protocols for their patients
CREATE POLICY "Therapists can view patient protocols"
    ON public.rts_protocols
    FOR SELECT
    TO authenticated
    USING (
        therapist_id IN (
            SELECT id FROM public.therapists
            WHERE user_id = auth.uid()
        )
        OR
        patient_id IN (
            SELECT tp.patient_id
            FROM public.therapist_patients tp
            JOIN public.therapists t ON t.id = tp.therapist_id
            WHERE t.user_id = auth.uid() AND tp.active = true
        )
    );

-- Therapists can create protocols
CREATE POLICY "Therapists can create protocols"
    ON public.rts_protocols
    FOR INSERT
    TO authenticated
    WITH CHECK (
        therapist_id IN (
            SELECT id FROM public.therapists
            WHERE user_id = auth.uid()
        )
    );

-- Therapists can update their own protocols
CREATE POLICY "Therapists can update own protocols"
    ON public.rts_protocols
    FOR UPDATE
    TO authenticated
    USING (
        therapist_id IN (
            SELECT id FROM public.therapists
            WHERE user_id = auth.uid()
        )
    )
    WITH CHECK (
        therapist_id IN (
            SELECT id FROM public.therapists
            WHERE user_id = auth.uid()
        )
    );

-- Therapists can delete their own draft protocols only
CREATE POLICY "Therapists can delete own draft protocols"
    ON public.rts_protocols
    FOR DELETE
    TO authenticated
    USING (
        status = 'draft'
        AND therapist_id IN (
            SELECT id FROM public.therapists
            WHERE user_id = auth.uid()
        )
    );

-- ============================================================================
-- RLS POLICIES: rts_phases
-- ============================================================================

ALTER TABLE public.rts_phases ENABLE ROW LEVEL SECURITY;

-- Patients can view phases for their own protocols
CREATE POLICY "Patients can view own protocol phases"
    ON public.rts_phases
    FOR SELECT
    TO authenticated
    USING (
        protocol_id IN (
            SELECT rp.id FROM public.rts_protocols rp
            JOIN public.patients p ON p.id = rp.patient_id
            WHERE p.user_id = auth.uid()
        )
    );

-- Therapists can view phases for their patients' protocols
CREATE POLICY "Therapists can view patient protocol phases"
    ON public.rts_phases
    FOR SELECT
    TO authenticated
    USING (
        protocol_id IN (
            SELECT id FROM public.rts_protocols
            WHERE therapist_id IN (
                SELECT id FROM public.therapists
                WHERE user_id = auth.uid()
            )
        )
    );

-- Therapists can manage phases for their protocols
CREATE POLICY "Therapists can insert phases"
    ON public.rts_phases
    FOR INSERT
    TO authenticated
    WITH CHECK (
        protocol_id IN (
            SELECT id FROM public.rts_protocols
            WHERE therapist_id IN (
                SELECT id FROM public.therapists
                WHERE user_id = auth.uid()
            )
        )
    );

CREATE POLICY "Therapists can update phases"
    ON public.rts_phases
    FOR UPDATE
    TO authenticated
    USING (
        protocol_id IN (
            SELECT id FROM public.rts_protocols
            WHERE therapist_id IN (
                SELECT id FROM public.therapists
                WHERE user_id = auth.uid()
            )
        )
    )
    WITH CHECK (
        protocol_id IN (
            SELECT id FROM public.rts_protocols
            WHERE therapist_id IN (
                SELECT id FROM public.therapists
                WHERE user_id = auth.uid()
            )
        )
    );

CREATE POLICY "Therapists can delete phases"
    ON public.rts_phases
    FOR DELETE
    TO authenticated
    USING (
        protocol_id IN (
            SELECT id FROM public.rts_protocols
            WHERE therapist_id IN (
                SELECT id FROM public.therapists
                WHERE user_id = auth.uid()
            )
            AND status = 'draft'
        )
    );

-- ============================================================================
-- RLS POLICIES: rts_milestone_criteria
-- ============================================================================

ALTER TABLE public.rts_milestone_criteria ENABLE ROW LEVEL SECURITY;

-- Patients can view criteria for their protocols
CREATE POLICY "Patients can view own criteria"
    ON public.rts_milestone_criteria
    FOR SELECT
    TO authenticated
    USING (
        phase_id IN (
            SELECT ph.id FROM public.rts_phases ph
            JOIN public.rts_protocols rp ON rp.id = ph.protocol_id
            JOIN public.patients p ON p.id = rp.patient_id
            WHERE p.user_id = auth.uid()
        )
    );

-- Therapists can view criteria for their patients
CREATE POLICY "Therapists can view patient criteria"
    ON public.rts_milestone_criteria
    FOR SELECT
    TO authenticated
    USING (
        phase_id IN (
            SELECT ph.id FROM public.rts_phases ph
            JOIN public.rts_protocols rp ON rp.id = ph.protocol_id
            WHERE rp.therapist_id IN (
                SELECT id FROM public.therapists
                WHERE user_id = auth.uid()
            )
        )
    );

-- Therapists can manage criteria
CREATE POLICY "Therapists can insert criteria"
    ON public.rts_milestone_criteria
    FOR INSERT
    TO authenticated
    WITH CHECK (
        phase_id IN (
            SELECT ph.id FROM public.rts_phases ph
            JOIN public.rts_protocols rp ON rp.id = ph.protocol_id
            WHERE rp.therapist_id IN (
                SELECT id FROM public.therapists
                WHERE user_id = auth.uid()
            )
        )
    );

CREATE POLICY "Therapists can update criteria"
    ON public.rts_milestone_criteria
    FOR UPDATE
    TO authenticated
    USING (
        phase_id IN (
            SELECT ph.id FROM public.rts_phases ph
            JOIN public.rts_protocols rp ON rp.id = ph.protocol_id
            WHERE rp.therapist_id IN (
                SELECT id FROM public.therapists
                WHERE user_id = auth.uid()
            )
        )
    );

CREATE POLICY "Therapists can delete criteria"
    ON public.rts_milestone_criteria
    FOR DELETE
    TO authenticated
    USING (
        phase_id IN (
            SELECT ph.id FROM public.rts_phases ph
            JOIN public.rts_protocols rp ON rp.id = ph.protocol_id
            WHERE rp.therapist_id IN (
                SELECT id FROM public.therapists
                WHERE user_id = auth.uid()
            )
            AND rp.status = 'draft'
        )
    );

-- ============================================================================
-- RLS POLICIES: rts_test_results
-- ============================================================================

ALTER TABLE public.rts_test_results ENABLE ROW LEVEL SECURITY;

-- Patients can view their own test results
CREATE POLICY "Patients can view own test results"
    ON public.rts_test_results
    FOR SELECT
    TO authenticated
    USING (
        protocol_id IN (
            SELECT rp.id FROM public.rts_protocols rp
            JOIN public.patients p ON p.id = rp.patient_id
            WHERE p.user_id = auth.uid()
        )
    );

-- Therapists can view test results for their patients
CREATE POLICY "Therapists can view patient test results"
    ON public.rts_test_results
    FOR SELECT
    TO authenticated
    USING (
        protocol_id IN (
            SELECT id FROM public.rts_protocols
            WHERE therapist_id IN (
                SELECT id FROM public.therapists
                WHERE user_id = auth.uid()
            )
        )
    );

-- Therapists can record test results
CREATE POLICY "Therapists can insert test results"
    ON public.rts_test_results
    FOR INSERT
    TO authenticated
    WITH CHECK (
        recorded_by IN (
            SELECT id FROM public.therapists
            WHERE user_id = auth.uid()
        )
        AND protocol_id IN (
            SELECT id FROM public.rts_protocols
            WHERE therapist_id IN (
                SELECT id FROM public.therapists
                WHERE user_id = auth.uid()
            )
        )
    );

-- Test results are immutable - no UPDATE or DELETE policies

-- ============================================================================
-- RLS POLICIES: rts_phase_advancements
-- ============================================================================

ALTER TABLE public.rts_phase_advancements ENABLE ROW LEVEL SECURITY;

-- Patients can view advancement history for their protocols
CREATE POLICY "Patients can view own advancement history"
    ON public.rts_phase_advancements
    FOR SELECT
    TO authenticated
    USING (
        protocol_id IN (
            SELECT rp.id FROM public.rts_protocols rp
            JOIN public.patients p ON p.id = rp.patient_id
            WHERE p.user_id = auth.uid()
        )
    );

-- Therapists can view advancement history
CREATE POLICY "Therapists can view patient advancement history"
    ON public.rts_phase_advancements
    FOR SELECT
    TO authenticated
    USING (
        protocol_id IN (
            SELECT id FROM public.rts_protocols
            WHERE therapist_id IN (
                SELECT id FROM public.therapists
                WHERE user_id = auth.uid()
            )
        )
    );

-- Therapists can record phase advancements
CREATE POLICY "Therapists can insert phase advancements"
    ON public.rts_phase_advancements
    FOR INSERT
    TO authenticated
    WITH CHECK (
        decided_by IN (
            SELECT id FROM public.therapists
            WHERE user_id = auth.uid()
        )
        AND protocol_id IN (
            SELECT id FROM public.rts_protocols
            WHERE therapist_id IN (
                SELECT id FROM public.therapists
                WHERE user_id = auth.uid()
            )
        )
    );

-- Phase advancements are immutable - no UPDATE or DELETE policies

-- ============================================================================
-- RLS POLICIES: rts_clearances
-- ============================================================================

ALTER TABLE public.rts_clearances ENABLE ROW LEVEL SECURITY;

-- Patients can view their own clearances
CREATE POLICY "Patients can view own clearances"
    ON public.rts_clearances
    FOR SELECT
    TO authenticated
    USING (
        protocol_id IN (
            SELECT rp.id FROM public.rts_protocols rp
            JOIN public.patients p ON p.id = rp.patient_id
            WHERE p.user_id = auth.uid()
        )
    );

-- Therapists can view clearances for their patients
CREATE POLICY "Therapists can view patient clearances"
    ON public.rts_clearances
    FOR SELECT
    TO authenticated
    USING (
        protocol_id IN (
            SELECT id FROM public.rts_protocols
            WHERE therapist_id IN (
                SELECT id FROM public.therapists
                WHERE user_id = auth.uid()
            )
        )
    );

-- Therapists can create clearances
CREATE POLICY "Therapists can insert clearances"
    ON public.rts_clearances
    FOR INSERT
    TO authenticated
    WITH CHECK (
        protocol_id IN (
            SELECT id FROM public.rts_protocols
            WHERE therapist_id IN (
                SELECT id FROM public.therapists
                WHERE user_id = auth.uid()
            )
        )
    );

-- Therapists can update their own clearances (except co-signed)
CREATE POLICY "Therapists can update own clearances"
    ON public.rts_clearances
    FOR UPDATE
    TO authenticated
    USING (
        status NOT IN ('co_signed')
        AND protocol_id IN (
            SELECT id FROM public.rts_protocols
            WHERE therapist_id IN (
                SELECT id FROM public.therapists
                WHERE user_id = auth.uid()
            )
        )
    )
    WITH CHECK (
        protocol_id IN (
            SELECT id FROM public.rts_protocols
            WHERE therapist_id IN (
                SELECT id FROM public.therapists
                WHERE user_id = auth.uid()
            )
        )
    );

-- Therapists can delete their own draft clearances
CREATE POLICY "Therapists can delete own draft clearances"
    ON public.rts_clearances
    FOR DELETE
    TO authenticated
    USING (
        status = 'draft'
        AND protocol_id IN (
            SELECT id FROM public.rts_protocols
            WHERE therapist_id IN (
                SELECT id FROM public.therapists
                WHERE user_id = auth.uid()
            )
        )
    );

-- ============================================================================
-- RLS POLICIES: rts_readiness_scores
-- ============================================================================

ALTER TABLE public.rts_readiness_scores ENABLE ROW LEVEL SECURITY;

-- Patients can view their own readiness scores
CREATE POLICY "Patients can view own readiness scores"
    ON public.rts_readiness_scores
    FOR SELECT
    TO authenticated
    USING (
        protocol_id IN (
            SELECT rp.id FROM public.rts_protocols rp
            JOIN public.patients p ON p.id = rp.patient_id
            WHERE p.user_id = auth.uid()
        )
    );

-- Therapists can view readiness scores for their patients
CREATE POLICY "Therapists can view patient readiness scores"
    ON public.rts_readiness_scores
    FOR SELECT
    TO authenticated
    USING (
        protocol_id IN (
            SELECT id FROM public.rts_protocols
            WHERE therapist_id IN (
                SELECT id FROM public.therapists
                WHERE user_id = auth.uid()
            )
        )
    );

-- Therapists can record readiness scores
CREATE POLICY "Therapists can insert readiness scores"
    ON public.rts_readiness_scores
    FOR INSERT
    TO authenticated
    WITH CHECK (
        recorded_by IN (
            SELECT id FROM public.therapists
            WHERE user_id = auth.uid()
        )
        AND protocol_id IN (
            SELECT id FROM public.rts_protocols
            WHERE therapist_id IN (
                SELECT id FROM public.therapists
                WHERE user_id = auth.uid()
            )
        )
    );

-- Readiness scores are immutable - no UPDATE or DELETE policies

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT SELECT ON public.rts_sports TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.rts_protocols TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.rts_phases TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.rts_milestone_criteria TO authenticated;
GRANT SELECT, INSERT ON public.rts_test_results TO authenticated;
GRANT SELECT, INSERT ON public.rts_phase_advancements TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.rts_clearances TO authenticated;
GRANT SELECT, INSERT ON public.rts_readiness_scores TO authenticated;

-- ============================================================================
-- SEED DATA: Sports with Default Phases
-- ============================================================================

INSERT INTO public.rts_sports (name, category, default_phases) VALUES
-- Baseball - Throwing
('Baseball - Throwing', 'throwing', '[
    {
        "phase_number": 1,
        "phase_name": "Protected",
        "activity_level": "red",
        "description": "Initial healing phase. No throwing allowed. Focus on pain management, ROM restoration, and protected strengthening.",
        "target_duration_days": 42
    },
    {
        "phase_number": 2,
        "phase_name": "Controlled Activity",
        "activity_level": "red",
        "description": "Progressive loading begins. Light tossing under 45 feet. Focus on rebuilding throwing mechanics.",
        "target_duration_days": 42
    },
    {
        "phase_number": 3,
        "phase_name": "Advanced Strengthening",
        "activity_level": "yellow",
        "description": "Increased throwing distances (45-90 feet). Emphasis on arm strength and endurance.",
        "target_duration_days": 28
    },
    {
        "phase_number": 4,
        "phase_name": "Interval Throwing",
        "activity_level": "yellow",
        "description": "Long toss up to 120+ feet. Progressive throwing program with monitored volume and intensity.",
        "target_duration_days": 28
    },
    {
        "phase_number": 5,
        "phase_name": "Return to Mound",
        "activity_level": "yellow",
        "description": "Bullpen sessions begin. Progressive pitch counts and pitch type introduction.",
        "target_duration_days": 28
    },
    {
        "phase_number": 6,
        "phase_name": "Full Competition",
        "activity_level": "green",
        "description": "Live game simulation and return to competitive play. Full pitch repertoire at game intensity.",
        "target_duration_days": null
    }
]'::jsonb),

-- Running - Distance
('Running - Distance', 'running', '[
    {
        "phase_number": 1,
        "phase_name": "Walking",
        "activity_level": "red",
        "description": "Pain-free walking only. Focus on gait mechanics and low-impact cross-training.",
        "target_duration_days": 14
    },
    {
        "phase_number": 2,
        "phase_name": "Walk/Jog",
        "activity_level": "red",
        "description": "Alternating walk/jog intervals. Progressive increase in jog duration. Monitor symptoms closely.",
        "target_duration_days": 14
    },
    {
        "phase_number": 3,
        "phase_name": "Progressive Running",
        "activity_level": "yellow",
        "description": "Continuous easy running. Gradual increase in duration and frequency. Build aerobic base.",
        "target_duration_days": 28
    },
    {
        "phase_number": 4,
        "phase_name": "Sport-Specific",
        "activity_level": "yellow",
        "description": "Introduction of tempo runs, intervals, and sport-specific training. Progressive volume increase.",
        "target_duration_days": 28
    },
    {
        "phase_number": 5,
        "phase_name": "Full Return",
        "activity_level": "green",
        "description": "Return to full training and competition. Normal training loads with monitoring for any setbacks.",
        "target_duration_days": null
    }
]'::jsonb),

-- Soccer/Football
('Soccer/Football', 'cutting', '[
    {
        "phase_number": 1,
        "phase_name": "Protected",
        "activity_level": "red",
        "description": "Initial healing phase. No weight-bearing sports activities. Focus on ROM and early strengthening.",
        "target_duration_days": 28
    },
    {
        "phase_number": 2,
        "phase_name": "Linear Activity",
        "activity_level": "red",
        "description": "Straight-line running and jumping. No cutting or pivoting. Progressive plyometric introduction.",
        "target_duration_days": 28
    },
    {
        "phase_number": 3,
        "phase_name": "Agility",
        "activity_level": "yellow",
        "description": "Controlled cutting and direction changes. Ladder drills, cone work, and progressive agility patterns.",
        "target_duration_days": 28
    },
    {
        "phase_number": 4,
        "phase_name": "Sport Drills",
        "activity_level": "yellow",
        "description": "Soccer-specific drills without contact. Ball work, passing, shooting. Reactive agility training.",
        "target_duration_days": 28
    },
    {
        "phase_number": 5,
        "phase_name": "Practice",
        "activity_level": "yellow",
        "description": "Return to team practice with controlled contact. Full participation in non-contact drills.",
        "target_duration_days": 28
    },
    {
        "phase_number": 6,
        "phase_name": "Full Competition",
        "activity_level": "green",
        "description": "Full contact practice and return to competitive matches. Monitor closely for first few games.",
        "target_duration_days": null
    }
]'::jsonb),

-- Basketball
('Basketball', 'cutting', '[
    {
        "phase_number": 1,
        "phase_name": "Protected",
        "activity_level": "red",
        "description": "Initial healing phase. No basketball activities. Focus on ROM, swelling management, and early strengthening.",
        "target_duration_days": 28
    },
    {
        "phase_number": 2,
        "phase_name": "Linear/Jumping",
        "activity_level": "red",
        "description": "Straight-line running and controlled jumping. Box jumps, bilateral landing. No cutting or pivoting.",
        "target_duration_days": 28
    },
    {
        "phase_number": 3,
        "phase_name": "Cutting/Pivoting",
        "activity_level": "yellow",
        "description": "Progressive cutting and pivoting drills. Single-leg landing progressions. Court movement patterns.",
        "target_duration_days": 28
    },
    {
        "phase_number": 4,
        "phase_name": "Basketball Drills",
        "activity_level": "yellow",
        "description": "Basketball-specific skills without contact. Shooting, dribbling, passing. Reactive drills and scrimmage prep.",
        "target_duration_days": 28
    },
    {
        "phase_number": 5,
        "phase_name": "Practice",
        "activity_level": "yellow",
        "description": "Return to team practice with progressive contact. Full participation in non-contact portions.",
        "target_duration_days": 28
    },
    {
        "phase_number": 6,
        "phase_name": "Full Competition",
        "activity_level": "green",
        "description": "Full contact practice and return to competitive games. Progressive minutes in initial games.",
        "target_duration_days": null
    }
]'::jsonb)

ON CONFLICT (name) DO UPDATE SET
    category = EXCLUDED.category,
    default_phases = EXCLUDED.default_phases,
    updated_at = NOW();

-- ============================================================================
-- COMMENTS
-- ============================================================================

-- Table comments
COMMENT ON TABLE public.rts_sports IS 'Sport definitions with default phase templates for return-to-sport protocols';
COMMENT ON TABLE public.rts_protocols IS 'Patient return-to-sport journey tracking - main protocol entity';
COMMENT ON TABLE public.rts_phases IS 'Phases within an RTS protocol (e.g., Protected, Controlled Activity)';
COMMENT ON TABLE public.rts_milestone_criteria IS 'Criteria definitions for advancing between phases';
COMMENT ON TABLE public.rts_test_results IS 'Recorded test measurements for milestone criteria';
COMMENT ON TABLE public.rts_phase_advancements IS 'Audit log of phase transition decisions';
COMMENT ON TABLE public.rts_clearances IS 'Formal clearance documents with signing workflow';
COMMENT ON TABLE public.rts_readiness_scores IS 'Risk assessment scores with traffic light system';

-- Column comments for rts_sports
COMMENT ON COLUMN public.rts_sports.name IS 'Unique sport name, e.g., "Baseball - Throwing"';
COMMENT ON COLUMN public.rts_sports.category IS 'Sport category: throwing, running, or cutting';
COMMENT ON COLUMN public.rts_sports.default_phases IS 'JSONB array of default phase templates for this sport';

-- Column comments for rts_protocols
COMMENT ON COLUMN public.rts_protocols.injury_type IS 'Type of injury, e.g., "UCL Reconstruction", "ACL Tear"';
COMMENT ON COLUMN public.rts_protocols.surgery_date IS 'Date of surgery (nullable for non-surgical cases)';
COMMENT ON COLUMN public.rts_protocols.status IS 'Protocol status: draft, active, completed, or discontinued';
COMMENT ON COLUMN public.rts_protocols.current_phase_id IS 'Reference to current active phase';

-- Column comments for rts_phases
COMMENT ON COLUMN public.rts_phases.activity_level IS 'Traffic light status: green (full), yellow (modified), red (restricted)';
COMMENT ON COLUMN public.rts_phases.entry_criteria IS 'JSONB array of criteria required to enter this phase';
COMMENT ON COLUMN public.rts_phases.exit_criteria IS 'JSONB array of criteria required to exit/advance from this phase';

-- Column comments for rts_milestone_criteria
COMMENT ON COLUMN public.rts_milestone_criteria.category IS 'Criterion category: functional, strength, rom, pain, or psychological';
COMMENT ON COLUMN public.rts_milestone_criteria.comparison_operator IS 'How to compare value: >=, <=, ==, or between';
COMMENT ON COLUMN public.rts_milestone_criteria.is_required IS 'Whether this criterion is required to advance';

-- Column comments for rts_test_results
COMMENT ON COLUMN public.rts_test_results.passed IS 'Whether the test result met the criterion target';

-- Column comments for rts_phase_advancements
COMMENT ON COLUMN public.rts_phase_advancements.decision IS 'Decision type: advance, extend, hold, or manual_override';
COMMENT ON COLUMN public.rts_phase_advancements.criteria_summary IS 'Snapshot of all criteria status at time of decision';

-- Column comments for rts_clearances
COMMENT ON COLUMN public.rts_clearances.clearance_type IS 'Type: phase_clearance, final_clearance, or conditional_clearance';
COMMENT ON COLUMN public.rts_clearances.clearance_level IS 'Traffic light level: green, yellow, or red';
COMMENT ON COLUMN public.rts_clearances.status IS 'Document status: draft, complete, signed, or co_signed';
COMMENT ON COLUMN public.rts_clearances.requires_physician_signature IS 'Whether physician co-signature is required';

-- Column comments for rts_readiness_scores
COMMENT ON COLUMN public.rts_readiness_scores.physical_score IS 'Physical readiness score (0-100)';
COMMENT ON COLUMN public.rts_readiness_scores.functional_score IS 'Functional readiness score (0-100)';
COMMENT ON COLUMN public.rts_readiness_scores.psychological_score IS 'Psychological readiness score (0-100)';
COMMENT ON COLUMN public.rts_readiness_scores.overall_score IS 'Weighted overall readiness score (0-100)';
COMMENT ON COLUMN public.rts_readiness_scores.traffic_light IS 'Computed status: green (80+), yellow (60-79), red (<60)';
COMMENT ON COLUMN public.rts_readiness_scores.risk_factors IS 'JSONB array of identified risk factors';

-- ============================================================================
-- ROLLBACK (if needed)
-- ============================================================================

/*
-- To rollback this migration, run:
DROP TABLE IF EXISTS public.rts_readiness_scores CASCADE;
DROP TABLE IF EXISTS public.rts_clearances CASCADE;
DROP TABLE IF EXISTS public.rts_phase_advancements CASCADE;
DROP TABLE IF EXISTS public.rts_test_results CASCADE;
DROP TABLE IF EXISTS public.rts_milestone_criteria CASCADE;
DROP TABLE IF EXISTS public.rts_phases CASCADE;
DROP TABLE IF EXISTS public.rts_protocols CASCADE;
DROP TABLE IF EXISTS public.rts_sports CASCADE;
DROP FUNCTION IF EXISTS update_rts_updated_at CASCADE;
DROP FUNCTION IF EXISTS calculate_rts_readiness_traffic_light CASCADE;
*/
