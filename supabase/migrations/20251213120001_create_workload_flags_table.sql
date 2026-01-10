-- 20251213120001_create_workload_flags_table.sql
-- Create workload_flags table for auto-regulation system
-- Zone-7 (Data Access)
--
-- Tracks workload metrics and auto-regulation flags for patients
-- Used by ReadinessService to determine training modifications
--
-- Run after: 20251213120000_create_nic_roma_demo_user.sql

-- ============================================================================
-- CREATE WORKLOAD_FLAGS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.workload_flags (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES patients(id) ON DELETE CASCADE,

  -- Workload Metrics
  acute_workload numeric,           -- 7-day average workload
  chronic_workload numeric,          -- 28-day average workload
  acwr numeric,                      -- Acute:Chronic Workload Ratio

  -- Auto-Regulation Flags
  high_acwr boolean DEFAULT false,   -- ACWR > 1.5 (injury risk)
  low_acwr boolean DEFAULT false,    -- ACWR < 0.8 (detraining risk)
  missed_reps boolean DEFAULT false, -- Failed to complete target reps
  rpe_overshoot boolean DEFAULT false, -- RPE exceeded target by 2+
  joint_pain boolean DEFAULT false,  -- Pain reported > 5/10
  readiness_low boolean DEFAULT false, -- Readiness score < 5

  -- Deload Status
  deload_triggered boolean DEFAULT false,
  deload_reason text,
  deload_start_date date,

  -- Timestamps
  calculated_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),

  -- Constraints
  CONSTRAINT valid_acwr CHECK (acwr IS NULL OR acwr >= 0)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_workload_flags_patient_id ON public.workload_flags(patient_id);
CREATE INDEX IF NOT EXISTS idx_workload_flags_calculated_at ON public.workload_flags(calculated_at DESC);
CREATE INDEX IF NOT EXISTS idx_workload_flags_deload ON public.workload_flags(patient_id, deload_triggered) WHERE deload_triggered = true;

-- Comments
COMMENT ON TABLE public.workload_flags IS 'Auto-regulation workload flags for training modifications (Build 40+)';
COMMENT ON COLUMN public.workload_flags.acute_workload IS '7-day rolling average workload';
COMMENT ON COLUMN public.workload_flags.chronic_workload IS '28-day rolling average workload';
COMMENT ON COLUMN public.workload_flags.acwr IS 'Acute:Chronic Workload Ratio (optimal: 0.8-1.3)';
COMMENT ON COLUMN public.workload_flags.high_acwr IS 'ACWR > 1.5 indicates injury risk';
COMMENT ON COLUMN public.workload_flags.deload_triggered IS 'Auto-deload triggered based on flags';

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE public.workload_flags ENABLE ROW LEVEL SECURITY;

-- Patients can view their own workload flags
CREATE POLICY "Patients can view own workload flags"
  ON public.workload_flags
  FOR SELECT
  USING (
    patient_id IN (
      SELECT id FROM patients WHERE user_id = auth.uid()
    )
  );

-- Therapists can view workload flags for their patients
CREATE POLICY "Therapists can view patient workload flags"
  ON public.workload_flags
  FOR SELECT
  USING (
    patient_id IN (
      SELECT p.id FROM patients p
      JOIN therapists t ON t.id = p.therapist_id
      WHERE t.user_id = auth.uid()
    )
  );

-- System/service can insert and update workload flags
CREATE POLICY "Service can manage workload flags"
  ON public.workload_flags
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- ============================================================================
-- SEED INITIAL WORKLOAD FLAGS FOR DEMO USERS
-- ============================================================================

-- John Brebbia - Normal training (no flags)
INSERT INTO public.workload_flags (
  patient_id,
  acute_workload,
  chronic_workload,
  acwr,
  high_acwr,
  low_acwr,
  deload_triggered,
  calculated_at
)
SELECT
  id,
  100.0,  -- Acute workload
  95.0,   -- Chronic workload
  1.05,   -- ACWR (optimal range)
  false,
  false,
  false,
  now()
FROM patients
WHERE email = 'demo-athlete@ptperformance.app'
ON CONFLICT DO NOTHING;

-- Nic Roma - Fresh start (low ACWR from ramping up)
INSERT INTO public.workload_flags (
  patient_id,
  acute_workload,
  chronic_workload,
  acwr,
  high_acwr,
  low_acwr,
  deload_triggered,
  calculated_at
)
SELECT
  id,
  60.0,   -- Acute workload (building up)
  80.0,   -- Chronic workload
  0.75,   -- ACWR (slightly low - ramping up)
  false,
  true,   -- Low ACWR flag (expected for new program)
  false,
  now()
FROM patients
WHERE email = 'nic-demo@ptperformance.app'
ON CONFLICT DO NOTHING;

-- ============================================================================
-- VALIDATION
-- ============================================================================

DO $$
DECLARE
  john_flags_exist boolean;
  nic_flags_exist boolean;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM public.workload_flags wf
    JOIN patients p ON p.id = wf.patient_id
    WHERE p.email = 'demo-athlete@ptperformance.app'
  ) INTO john_flags_exist;

  SELECT EXISTS(
    SELECT 1 FROM public.workload_flags wf
    JOIN patients p ON p.id = wf.patient_id
    WHERE p.email = 'nic-demo@ptperformance.app'
  ) INTO nic_flags_exist;

  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'WORKLOAD FLAGS VALIDATION';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'John Brebbia flags: %', CASE WHEN john_flags_exist THEN '✅ EXISTS' ELSE '❌ MISSING' END;
  RAISE NOTICE 'Nic Roma flags: %', CASE WHEN nic_flags_exist THEN '✅ EXISTS' ELSE '❌ MISSING' END;
  RAISE NOTICE '============================================';
END $$;
