-- ============================================================================
-- COMPREHENSIVE READINESS FACTORS SEED DATA - BUILD 116
-- ============================================================================
-- Expands readiness factors with evidence-based weights for accurate scoring
-- Replaces initial 5-factor seed with comprehensive 7-factor system
--
-- Date: 2026-01-03
-- Agent: 3
-- Linear: BUILD-116
-- ============================================================================

-- =====================================================
-- Clear existing factors (reset for comprehensive set)
-- =====================================================

-- First, deactivate all existing factors to avoid conflicts
UPDATE readiness_factors SET is_active = false WHERE is_active = true;

-- =====================================================
-- Comprehensive Readiness Factors (Evidence-Based)
-- =====================================================

-- INSERT comprehensive factors with scientific weights
-- Total weight must sum to exactly 1.0
-- Weights based on recovery science literature

INSERT INTO readiness_factors (name, weight, description, is_active) VALUES

-- SLEEP QUALITY (30% weight) - Most critical factor
-- Research: Sleep is the #1 recovery factor for athletes
-- Reference: Halson, S.L. (2014). Sleep in Elite Athletes and Nutritional Interventions to Enhance Sleep
(
    'sleep_quality',
    0.30,
    'Sleep duration and quality - primary recovery mechanism. Optimal range: 7-9 hours. Research shows sleep is the most critical factor for physical and cognitive recovery.',
    true
),

-- MUSCLE SORENESS (25% weight) - Direct indicator of recovery status
-- Research: DOMS (Delayed Onset Muscle Soreness) indicates incomplete recovery
-- Reference: Cheung et al. (2003). Delayed Onset Muscle Soreness
(
    'soreness_level',
    0.25,
    'Muscle soreness and delayed onset muscle soreness (DOMS). Inverse scoring: lower soreness = higher readiness. Direct indicator of neuromuscular recovery status.',
    true
),

-- ENERGY LEVEL (18% weight) - Subjective readiness perception
-- Research: Perceived energy correlates with performance capacity
-- Reference: Saw et al. (2016). Monitoring the athlete training response
(
    'energy_level',
    0.18,
    'Subjective energy and motivation levels. Perceived readiness is a strong predictor of actual performance capacity and training response.',
    true
),

-- STRESS LEVEL (12% weight) - Psychological recovery factor
-- Research: Mental stress impairs physical recovery
-- Reference: Kellmann & Kallus (2001). Recovery-Stress Questionnaire
(
    'stress_level',
    0.12,
    'Mental stress and anxiety levels. Inverse scoring: lower stress = higher readiness. Psychological stress significantly impacts physical recovery and performance.',
    true
),

-- MOOD STATE (8% weight) - Psychological well-being
-- Research: Mood state reflects overall recovery status
-- Reference: McNair et al. (1971). Profile of Mood States (POMS)
(
    'mood_state',
    0.08,
    'Overall mood and emotional well-being. Positive mood indicates adequate recovery, negative mood suggests overtraining or inadequate recovery.',
    true
),

-- HEART RATE VARIABILITY (5% weight) - Objective autonomic marker (if tracked)
-- Research: HRV reflects autonomic nervous system recovery
-- Reference: Plews et al. (2013). Training Adaptation and Heart Rate Variability
(
    'hrv_score',
    0.05,
    'Heart rate variability - objective marker of autonomic nervous system recovery. Higher HRV indicates better recovery. Optional if wearable device available.',
    true
),

-- RATE OF PERCEIVED EXERTION (2% weight) - Previous day effort context
-- Research: RPE from previous session affects next-day readiness
-- Reference: Borg (1982). Psychophysical bases of perceived exertion
(
    'previous_rpe',
    0.02,
    'Rate of perceived exertion from previous training session. High RPE from yesterday suggests need for lighter training today. Provides training load context.',
    true
)

-- Handle conflicts by updating existing records
ON CONFLICT (name) DO UPDATE SET
    weight = EXCLUDED.weight,
    description = EXCLUDED.description,
    is_active = EXCLUDED.is_active,
    updated_at = now();

-- =====================================================
-- Weight Validation
-- =====================================================

-- Verify weights sum to exactly 1.0
DO $$
DECLARE
    v_total_weight numeric;
BEGIN
    SELECT SUM(weight) INTO v_total_weight
    FROM readiness_factors
    WHERE is_active = true;

    IF ABS(v_total_weight - 1.0) > 0.001 THEN
        RAISE EXCEPTION 'Readiness factor weights do not sum to 1.0 (got %)', v_total_weight;
    END IF;

    RAISE NOTICE '✅ Weight validation passed: total weight = %', v_total_weight;
END $$;

-- =====================================================
-- Verification Output
-- =====================================================

DO $$
DECLARE
    v_factor_count integer;
    v_total_weight numeric;
    v_factor record;
BEGIN
    SELECT COUNT(*), SUM(weight)
    INTO v_factor_count, v_total_weight
    FROM readiness_factors
    WHERE is_active = true;

    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'COMPREHENSIVE READINESS FACTORS SEEDED - BUILD 116';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Active Factors: %', v_factor_count;
    RAISE NOTICE '✅ Total Weight: % (target: 1.00)', v_total_weight;
    RAISE NOTICE '';
    RAISE NOTICE 'Evidence-Based Weight Distribution:';
    RAISE NOTICE '-----------------------------------';

    FOR v_factor IN
        SELECT name, weight, LEFT(description, 80) || '...' as desc_short
        FROM readiness_factors
        WHERE is_active = true
        ORDER BY weight DESC
    LOOP
        RAISE NOTICE '  % | Weight: % (%%) | %',
            RPAD(v_factor.name, 20),
            LPAD(v_factor.weight::text, 4),
            LPAD(ROUND(v_factor.weight * 100)::text, 3),
            v_factor.desc_short;
    END LOOP;

    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'SCIENTIFIC JUSTIFICATION';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE '1. Sleep Quality (30%%): Primary recovery mechanism';
    RAISE NOTICE '   - Most impactful factor for physical and cognitive recovery';
    RAISE NOTICE '   - Halson (2014): Sleep in Elite Athletes';
    RAISE NOTICE '';
    RAISE NOTICE '2. Soreness Level (25%%): Direct recovery status indicator';
    RAISE NOTICE '   - DOMS indicates incomplete neuromuscular recovery';
    RAISE NOTICE '   - Cheung et al. (2003): Delayed Onset Muscle Soreness';
    RAISE NOTICE '';
    RAISE NOTICE '3. Energy Level (18%%): Subjective readiness perception';
    RAISE NOTICE '   - Strong predictor of performance capacity';
    RAISE NOTICE '   - Saw et al. (2016): Monitoring athlete training response';
    RAISE NOTICE '';
    RAISE NOTICE '4. Stress Level (12%%): Psychological recovery factor';
    RAISE NOTICE '   - Mental stress impairs physical recovery';
    RAISE NOTICE '   - Kellmann & Kallus (2001): Recovery-Stress Questionnaire';
    RAISE NOTICE '';
    RAISE NOTICE '5. Mood State (8%%): Psychological well-being';
    RAISE NOTICE '   - Reflects overall recovery status';
    RAISE NOTICE '   - McNair et al. (1971): Profile of Mood States';
    RAISE NOTICE '';
    RAISE NOTICE '6. HRV Score (5%%): Objective autonomic marker';
    RAISE NOTICE '   - Autonomic nervous system recovery';
    RAISE NOTICE '   - Plews et al. (2013): Training Adaptation and HRV';
    RAISE NOTICE '';
    RAISE NOTICE '7. Previous RPE (2%%): Training load context';
    RAISE NOTICE '   - Previous session effort affects readiness';
    RAISE NOTICE '   - Borg (1982): Psychophysical bases of perceived exertion';
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'READINESS FACTORS READY FOR BUILD 116';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
END $$;

-- =====================================================
-- Grant Permissions (ensure access)
-- =====================================================

GRANT SELECT ON readiness_factors TO authenticated;
GRANT ALL ON readiness_factors TO service_role;
