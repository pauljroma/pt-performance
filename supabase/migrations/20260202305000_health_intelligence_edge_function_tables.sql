-- ============================================================================
-- HEALTH INTELLIGENCE EDGE FUNCTION TABLES
-- ============================================================================
-- Creates tables for storing AI analysis results and coaching logs
-- Supporting the new edge functions:
-- - ai-lab-analysis
-- - ai-supplement-recommendation
-- - unified-ai-coach
--
-- Date: 2026-02-02
-- Ticket: ACP-1201
-- ============================================================================

BEGIN;

-- ============================================================================
-- LAB ANALYSES TABLE
-- ============================================================================
-- Stores AI-generated lab result analyses

CREATE TABLE IF NOT EXISTS lab_analyses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lab_result_id UUID NOT NULL REFERENCES lab_results(id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    analysis_text TEXT NOT NULL,
    recommendations JSONB NOT NULL DEFAULT '[]'::jsonb,
    biomarker_analyses JSONB NOT NULL DEFAULT '[]'::jsonb,
    training_correlations JSONB NOT NULL DEFAULT '[]'::jsonb,
    sleep_correlations JSONB NOT NULL DEFAULT '[]'::jsonb,
    overall_health_score INTEGER CHECK (overall_health_score >= 0 AND overall_health_score <= 100),
    priority_actions JSONB NOT NULL DEFAULT '[]'::jsonb,
    medical_disclaimer TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE lab_analyses IS 'AI-generated analyses of lab results with recommendations';
COMMENT ON COLUMN lab_analyses.lab_result_id IS 'Reference to the analyzed lab result';
COMMENT ON COLUMN lab_analyses.analysis_text IS 'Main AI-generated analysis text';
COMMENT ON COLUMN lab_analyses.recommendations IS 'JSONB array of specific recommendations';
COMMENT ON COLUMN lab_analyses.biomarker_analyses IS 'JSONB array of individual biomarker analyses';
COMMENT ON COLUMN lab_analyses.training_correlations IS 'JSONB array of training-related correlations';
COMMENT ON COLUMN lab_analyses.sleep_correlations IS 'JSONB array of sleep-related correlations';
COMMENT ON COLUMN lab_analyses.overall_health_score IS 'Calculated health score 0-100';
COMMENT ON COLUMN lab_analyses.priority_actions IS 'JSONB array of prioritized action items';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_lab_analyses_lab_result_id ON lab_analyses(lab_result_id);
CREATE INDEX IF NOT EXISTS idx_lab_analyses_patient_id ON lab_analyses(patient_id);
CREATE INDEX IF NOT EXISTS idx_lab_analyses_created_at ON lab_analyses(created_at DESC);

-- ============================================================================
-- SUPPLEMENT RECOMMENDATIONS TABLE
-- ============================================================================
-- Stores AI-generated supplement stack recommendations

CREATE TABLE IF NOT EXISTS supplement_recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    recommendations JSONB NOT NULL DEFAULT '[]'::jsonb,
    stack_summary TEXT NOT NULL,
    total_daily_cost_estimate TEXT,
    goal_coverage JSONB NOT NULL DEFAULT '{}'::jsonb,
    interaction_warnings JSONB NOT NULL DEFAULT '[]'::jsonb,
    timing_schedule JSONB NOT NULL DEFAULT '{}'::jsonb,
    disclaimer TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE supplement_recommendations IS 'AI-generated personalized supplement stack recommendations';
COMMENT ON COLUMN supplement_recommendations.recommendations IS 'JSONB array of individual supplement recommendations';
COMMENT ON COLUMN supplement_recommendations.stack_summary IS 'Summary of the recommended supplement stack';
COMMENT ON COLUMN supplement_recommendations.total_daily_cost_estimate IS 'Estimated daily cost of the stack';
COMMENT ON COLUMN supplement_recommendations.goal_coverage IS 'JSONB mapping goals to supporting supplements';
COMMENT ON COLUMN supplement_recommendations.interaction_warnings IS 'JSONB array of interaction warnings';
COMMENT ON COLUMN supplement_recommendations.timing_schedule IS 'JSONB object with timing schedule for supplements';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_supplement_recommendations_patient_id ON supplement_recommendations(patient_id);
CREATE INDEX IF NOT EXISTS idx_supplement_recommendations_created_at ON supplement_recommendations(created_at DESC);

-- ============================================================================
-- AI COACHING LOGS TABLE
-- ============================================================================
-- Stores logs of AI coaching interactions for learning and improvement

CREATE TABLE IF NOT EXISTS ai_coaching_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    question TEXT,
    response_summary TEXT,
    insights_count INTEGER NOT NULL DEFAULT 0,
    context_snapshot JSONB NOT NULL DEFAULT '{}'::jsonb,
    feedback_rating INTEGER CHECK (feedback_rating >= 1 AND feedback_rating <= 5),
    feedback_text TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE ai_coaching_logs IS 'Logs of unified AI coach interactions';
COMMENT ON COLUMN ai_coaching_logs.question IS 'User question if provided';
COMMENT ON COLUMN ai_coaching_logs.response_summary IS 'Summary of the AI response';
COMMENT ON COLUMN ai_coaching_logs.insights_count IS 'Number of insights generated';
COMMENT ON COLUMN ai_coaching_logs.context_snapshot IS 'Snapshot of patient context at time of coaching';
COMMENT ON COLUMN ai_coaching_logs.feedback_rating IS 'User rating of the coaching (1-5)';
COMMENT ON COLUMN ai_coaching_logs.feedback_text IS 'Optional feedback text from user';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_ai_coaching_logs_patient_id ON ai_coaching_logs(patient_id);
CREATE INDEX IF NOT EXISTS idx_ai_coaching_logs_created_at ON ai_coaching_logs(created_at DESC);

-- ============================================================================
-- UPDATED_AT TRIGGERS
-- ============================================================================

DROP TRIGGER IF EXISTS update_lab_analyses_timestamp ON lab_analyses;
CREATE TRIGGER update_lab_analyses_timestamp
    BEFORE UPDATE ON lab_analyses
    FOR EACH ROW
    EXECUTE FUNCTION update_health_intelligence_timestamp();

DROP TRIGGER IF EXISTS update_supplement_recommendations_timestamp ON supplement_recommendations;
CREATE TRIGGER update_supplement_recommendations_timestamp
    BEFORE UPDATE ON supplement_recommendations
    FOR EACH ROW
    EXECUTE FUNCTION update_health_intelligence_timestamp();

-- ============================================================================
-- ROW-LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS
ALTER TABLE lab_analyses ENABLE ROW LEVEL SECURITY;
ALTER TABLE supplement_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_coaching_logs ENABLE ROW LEVEL SECURITY;

-- Lab Analyses RLS
CREATE POLICY "Patients view own lab analyses"
    ON lab_analyses FOR SELECT
    USING (patient_id = auth.uid());

CREATE POLICY "Service role can manage lab analyses"
    ON lab_analyses FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Therapists view patient lab analyses"
    ON lab_analyses FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM therapist_patients tp
            WHERE tp.patient_id = lab_analyses.patient_id
            AND tp.therapist_id = auth.uid()
            AND tp.active = true
        )
    );

-- Supplement Recommendations RLS
CREATE POLICY "Patients view own supplement recommendations"
    ON supplement_recommendations FOR SELECT
    USING (patient_id = auth.uid());

CREATE POLICY "Service role can manage supplement recommendations"
    ON supplement_recommendations FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Therapists view patient supplement recommendations"
    ON supplement_recommendations FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM therapist_patients tp
            WHERE tp.patient_id = supplement_recommendations.patient_id
            AND tp.therapist_id = auth.uid()
            AND tp.active = true
        )
    );

-- AI Coaching Logs RLS
CREATE POLICY "Patients view own coaching logs"
    ON ai_coaching_logs FOR SELECT
    USING (patient_id = auth.uid());

CREATE POLICY "Patients can provide feedback"
    ON ai_coaching_logs FOR UPDATE
    USING (patient_id = auth.uid())
    WITH CHECK (patient_id = auth.uid());

CREATE POLICY "Service role can manage coaching logs"
    ON ai_coaching_logs FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT SELECT ON lab_analyses TO authenticated;
GRANT SELECT ON supplement_recommendations TO authenticated;
GRANT SELECT, UPDATE ON ai_coaching_logs TO authenticated;

GRANT ALL ON lab_analyses TO service_role;
GRANT ALL ON supplement_recommendations TO service_role;
GRANT ALL ON ai_coaching_logs TO service_role;

COMMIT;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'HEALTH INTELLIGENCE EDGE FUNCTION TABLES MIGRATION COMPLETE';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Tables Created:';
    RAISE NOTICE '  - lab_analyses (AI lab result analyses)';
    RAISE NOTICE '  - supplement_recommendations (AI supplement stacks)';
    RAISE NOTICE '  - ai_coaching_logs (Unified coach interaction logs)';
    RAISE NOTICE '';
    RAISE NOTICE 'Supporting Edge Functions:';
    RAISE NOTICE '  - ai-lab-analysis';
    RAISE NOTICE '  - ai-supplement-recommendation';
    RAISE NOTICE '  - fasting-workout-optimizer (no persistence needed)';
    RAISE NOTICE '  - unified-ai-coach';
    RAISE NOTICE '';
    RAISE NOTICE 'RLS: Patients see own data, therapists see their patients';
    RAISE NOTICE '============================================================================';
END $$;
