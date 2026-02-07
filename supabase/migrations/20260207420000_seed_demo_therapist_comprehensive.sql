-- Comprehensive Demo Therapist Seed Data for E2E Testing
-- Therapist ID: 00000000-0000-0000-0000-000000000100 (Sarah Thompson)
-- Patient ID: 00000000-0000-0000-0000-000000000001 (John Brebbia)

-- ============================================================================
-- 1. CLINICAL ASSESSMENTS (Intake + Progress)
-- ============================================================================

INSERT INTO clinical_assessments (
    id, patient_id, therapist_id, assessment_type, assessment_date,
    rom_measurements, functional_tests,
    pain_at_rest, pain_with_activity, pain_worst,
    pain_locations, chief_complaint, history_of_present_illness,
    functional_goals, objective_findings, assessment_summary, treatment_plan,
    status, signed_at, created_at
)
VALUES
    -- Initial Intake Assessment (60 days ago)
    (
        'a0000000-0000-0000-0001-000000000001'::uuid,
        '00000000-0000-0000-0000-000000000001'::uuid,
        '00000000-0000-0000-0000-000000000100'::uuid,
        'intake',
        CURRENT_DATE - INTERVAL '60 days',
        '{
            "shoulder": {
                "flexion": {"left": 175, "right": 170, "normal": 180},
                "abduction": {"left": 175, "right": 165, "normal": 180},
                "external_rotation": {"left": 90, "right": 85, "normal": 90},
                "internal_rotation": {"left": 70, "right": 65, "normal": 70}
            },
            "elbow": {
                "flexion": {"left": 145, "right": 140, "normal": 145},
                "extension": {"left": 0, "right": -5, "normal": 0}
            }
        }'::jsonb,
        '{
            "single_leg_squat": {"left": "good", "right": "fair", "notes": "Slight valgus collapse on right"},
            "shoulder_stability": {"empty_can": "4/5", "resisted_er": "4/5"},
            "grip_strength": {"left_kg": 45, "right_kg": 42}
        }'::jsonb,
        2, 4, 6,
        '[{"location": "medial elbow", "description": "Dull ache along UCL", "intensity": 4}]'::jsonb,
        'Right elbow pain with throwing, onset 3 weeks ago during spring training',
        'Patient is a professional baseball pitcher who developed gradual onset right medial elbow pain. Pain increases with throwing, especially on breaking balls. No numbness or tingling. Sleep disrupted when lying on right side.',
        '[
            {"goal": "Return to full throwing program", "timeframe": "8 weeks", "status": "in_progress"},
            {"goal": "Pain-free daily activities", "timeframe": "2 weeks", "status": "achieved"},
            {"goal": "Full ROM restoration", "timeframe": "4 weeks", "status": "in_progress"}
        ]'::jsonb,
        'ROM deficits in right shoulder ER and elbow extension. Mild UCL laxity on valgus stress test. Grip strength deficit 7% on throwing side. Posterior shoulder tightness noted.',
        'Grade 1 UCL sprain with secondary shoulder mobility deficits. Good healing potential with conservative management. Recommend structured rehab program.',
        '8-week progressive throwing program. Focus on posterior shoulder mobility, forearm strengthening, and scapular stability. Manual therapy 2x/week initially, progressing to 1x/week.',
        'signed',
        NOW() - INTERVAL '60 days',
        NOW() - INTERVAL '60 days'
    ),
    -- Progress Assessment (30 days ago)
    (
        'a0000000-0000-0000-0001-000000000002'::uuid,
        '00000000-0000-0000-0000-000000000001'::uuid,
        '00000000-0000-0000-0000-000000000100'::uuid,
        'progress',
        CURRENT_DATE - INTERVAL '30 days',
        '{
            "shoulder": {
                "flexion": {"left": 178, "right": 175, "normal": 180},
                "abduction": {"left": 178, "right": 175, "normal": 180},
                "external_rotation": {"left": 90, "right": 90, "normal": 90},
                "internal_rotation": {"left": 70, "right": 68, "normal": 70}
            },
            "elbow": {
                "flexion": {"left": 145, "right": 145, "normal": 145},
                "extension": {"left": 0, "right": 0, "normal": 0}
            }
        }'::jsonb,
        '{
            "single_leg_squat": {"left": "good", "right": "good", "notes": "Improved mechanics"},
            "shoulder_stability": {"empty_can": "5/5", "resisted_er": "5/5"},
            "grip_strength": {"left_kg": 46, "right_kg": 45}
        }'::jsonb,
        0, 2, 3,
        '[{"location": "medial elbow", "description": "Occasional tightness", "intensity": 2}]'::jsonb,
        'Follow-up for UCL rehab progress',
        'Patient progressing well through throwing program. Currently at 90ft flat-ground throws. Minimal discomfort with throwing. Arm care routine compliance excellent.',
        '[
            {"goal": "Return to full throwing program", "timeframe": "4 more weeks", "status": "in_progress"},
            {"goal": "Pain-free daily activities", "timeframe": "achieved", "status": "achieved"},
            {"goal": "Full ROM restoration", "timeframe": "achieved", "status": "achieved"}
        ]'::jsonb,
        'ROM normalized. Strength improved. Valgus stress test now negative. Ready to progress to mound work.',
        'Excellent progress. UCL healing well. Continue progression per protocol. Target return to mound in 2-3 weeks.',
        'Progress to long-toss program. Initiate mound work at 60% intensity. Continue arm care and strength work. Weekly check-ins.',
        'signed',
        NOW() - INTERVAL '30 days',
        NOW() - INTERVAL '30 days'
    ),
    -- Recent Progress Assessment (7 days ago, draft)
    (
        'a0000000-0000-0000-0001-000000000003'::uuid,
        '00000000-0000-0000-0000-000000000001'::uuid,
        '00000000-0000-0000-0000-000000000100'::uuid,
        'progress',
        CURRENT_DATE - INTERVAL '7 days',
        '{
            "shoulder": {
                "flexion": {"left": 180, "right": 180, "normal": 180},
                "abduction": {"left": 180, "right": 178, "normal": 180},
                "external_rotation": {"left": 92, "right": 95, "normal": 90},
                "internal_rotation": {"left": 70, "right": 72, "normal": 70}
            },
            "elbow": {
                "flexion": {"left": 145, "right": 145, "normal": 145},
                "extension": {"left": 0, "right": 0, "normal": 0}
            }
        }'::jsonb,
        '{
            "single_leg_squat": {"left": "excellent", "right": "excellent"},
            "shoulder_stability": {"empty_can": "5/5", "resisted_er": "5/5"},
            "grip_strength": {"left_kg": 48, "right_kg": 48}
        }'::jsonb,
        0, 1, 2,
        '[]'::jsonb,
        'Pre-return to mound clearance evaluation',
        'Patient completed full long-toss program. Ready for return to mound evaluation.',
        '[
            {"goal": "Return to full throwing program", "timeframe": "1-2 weeks", "status": "in_progress"},
            {"goal": "Pain-free daily activities", "timeframe": "achieved", "status": "achieved"},
            {"goal": "Full ROM restoration", "timeframe": "achieved", "status": "achieved"}
        ]'::jsonb,
        'Full ROM achieved bilaterally. Strength symmetry restored. No pain on valgus stress. Throwing mechanics sound.',
        'Ready for return to mound. Recommend progressive bullpen sessions starting at 50% intensity.',
        'Begin bullpen protocol. 20-pitch sessions at 50-60%, progress weekly. Monitor arm care scores. Final clearance pending 2 successful bullpen sessions.',
        'draft',
        NULL,
        NOW() - INTERVAL '7 days'
    )
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 2. OUTCOME MEASURES (DASH scores showing progress)
-- ============================================================================

INSERT INTO outcome_measures (
    id, patient_id, therapist_id, clinical_assessment_id,
    measure_type, assessment_date, responses,
    raw_score, normalized_score, interpretation,
    previous_score, change_from_previous, meets_mcid,
    notes, created_at
)
VALUES
    -- Initial DASH (60 days ago)
    (
        '00000001-0000-0000-0000-000000000001'::uuid,
        '00000000-0000-0000-0000-000000000001'::uuid,
        '00000000-0000-0000-0000-000000000100'::uuid,
        'a0000000-0000-0000-0001-000000000001'::uuid,
        'DASH',
        CURRENT_DATE - INTERVAL '60 days',
        '{"q1": 2, "q2": 2, "q3": 3, "q4": 2, "q5": 3, "q6": 2, "q7": 3, "q8": 2, "q9": 2, "q10": 2, "q11": 3, "q12": 2, "q13": 2, "q14": 2, "q15": 3, "q16": 2, "q17": 2, "q18": 2, "q19": 3, "q20": 2, "q21": 2, "q22": 2, "q23": 2, "q24": 3, "q25": 2, "q26": 2, "q27": 2, "q28": 2, "q29": 3, "q30": 2}'::jsonb,
        68, 43.33, 'moderate disability',
        NULL, NULL, NULL,
        'Baseline DASH prior to starting throwing program',
        NOW() - INTERVAL '60 days'
    ),
    -- Progress DASH (30 days ago)
    (
        '00000001-0000-0000-0000-000000000002'::uuid,
        '00000000-0000-0000-0000-000000000001'::uuid,
        '00000000-0000-0000-0000-000000000100'::uuid,
        'a0000000-0000-0000-0001-000000000002'::uuid,
        'DASH',
        CURRENT_DATE - INTERVAL '30 days',
        '{"q1": 1, "q2": 1, "q3": 2, "q4": 1, "q5": 1, "q6": 1, "q7": 2, "q8": 1, "q9": 1, "q10": 1, "q11": 2, "q12": 1, "q13": 1, "q14": 1, "q15": 1, "q16": 1, "q17": 1, "q18": 1, "q19": 2, "q20": 1, "q21": 1, "q22": 1, "q23": 1, "q24": 1, "q25": 1, "q26": 1, "q27": 1, "q28": 1, "q29": 1, "q30": 1}'::jsonb,
        36, 15.00, 'mild disability',
        43.33, -28.33, true,
        'Significant improvement. MCID achieved (>10 point change).',
        NOW() - INTERVAL '30 days'
    ),
    -- Recent DASH (7 days ago)
    (
        '00000001-0000-0000-0000-000000000003'::uuid,
        '00000000-0000-0000-0000-000000000001'::uuid,
        '00000000-0000-0000-0000-000000000100'::uuid,
        'a0000000-0000-0000-0001-000000000003'::uuid,
        'DASH',
        CURRENT_DATE - INTERVAL '7 days',
        '{"q1": 0, "q2": 0, "q3": 1, "q4": 0, "q5": 0, "q6": 0, "q7": 1, "q8": 0, "q9": 0, "q10": 0, "q11": 1, "q12": 0, "q13": 0, "q14": 0, "q15": 0, "q16": 0, "q17": 0, "q18": 0, "q19": 1, "q20": 0, "q21": 0, "q22": 0, "q23": 0, "q24": 0, "q25": 0, "q26": 0, "q27": 0, "q28": 0, "q29": 0, "q30": 0}'::jsonb,
        4, 3.33, 'minimal disability',
        15.00, -11.67, true,
        'Near full recovery. Ready for return to sport clearance.',
        NOW() - INTERVAL '7 days'
    ),
    -- VAS Pain scores
    (
        '00000001-0000-0000-0000-000000000004'::uuid,
        '00000000-0000-0000-0000-000000000001'::uuid,
        '00000000-0000-0000-0000-000000000100'::uuid,
        NULL,
        'VAS',
        CURRENT_DATE - INTERVAL '60 days',
        '{"at_rest": 2, "with_activity": 6, "worst": 8}'::jsonb,
        16, 53.33, 'moderate pain',
        NULL, NULL, NULL,
        'Baseline pain assessment',
        NOW() - INTERVAL '60 days'
    ),
    (
        '00000001-0000-0000-0000-000000000005'::uuid,
        '00000000-0000-0000-0000-000000000001'::uuid,
        '00000000-0000-0000-0000-000000000100'::uuid,
        NULL,
        'VAS',
        CURRENT_DATE - INTERVAL '7 days',
        '{"at_rest": 0, "with_activity": 1, "worst": 2}'::jsonb,
        3, 10.00, 'minimal pain',
        53.33, -43.33, true,
        'Excellent pain reduction',
        NOW() - INTERVAL '7 days'
    )
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 3. SOAP NOTES (Visit documentation)
-- ============================================================================

INSERT INTO soap_notes (
    id, patient_id, therapist_id, note_date,
    subjective, objective, assessment, plan,
    vitals, pain_level, functional_status,
    time_spent_minutes, cpt_codes,
    status, signed_at, created_at
)
VALUES
    -- Visit 1: Initial Evaluation (60 days ago)
    (
        '50000000-0000-0000-0001-000000000001'::uuid,
        '00000000-0000-0000-0000-000000000001'::uuid,
        '00000000-0000-0000-0000-000000000100'::uuid,
        CURRENT_DATE - INTERVAL '60 days',
        'Patient reports gradual onset R medial elbow pain x3 weeks. Pain 4/10 at rest, increases to 6/10 with throwing. Describes as "dull ache" along inside of elbow. Sleep somewhat disrupted. Unable to throw breaking balls. Frustrated with timing during spring training.',
        'ROM: R shoulder ER 85° (L 90°), R elbow ext -5° (L 0°). Valgus stress test mildly positive R. Grip strength 42kg R vs 45kg L. Posterior capsule tightness R shoulder. Moving Valgus Stress Test positive. No instability noted.',
        'Grade 1 UCL sprain with contributing posterior shoulder tightness. Good prognosis for conservative management. Patient motivated and compliant.',
        'Begin 8-week progressive throwing program. Week 1-2: No throwing, focus on tissue healing and ROM restoration. Manual therapy 2x/week. HEP for posterior shoulder stretching and forearm strengthening. Ice post-activity. Follow up in 1 week.',
        '{"heart_rate": 62, "blood_pressure": "118/76"}'::jsonb,
        4, 'stable',
        60,
        '["97110", "97140", "97530"]'::jsonb,
        'signed',
        NOW() - INTERVAL '60 days',
        NOW() - INTERVAL '60 days'
    ),
    -- Visit 5: Progress (45 days ago)
    (
        '50000000-0000-0000-0001-000000000002'::uuid,
        '00000000-0000-0000-0000-000000000001'::uuid,
        '00000000-0000-0000-0000-000000000100'::uuid,
        CURRENT_DATE - INTERVAL '45 days',
        'Patient reports significant improvement. Pain now 1-2/10 with activities. Sleeping well. Started catch play at 60ft, no symptoms. Feeling positive about progress.',
        'ROM: Full and symmetric bilaterally. Valgus stress test negative. Grip strength 44kg R vs 45kg L. Posterior capsule mobility normalized. Good scapular control during throwing simulation.',
        'Progressing well. Tissue healing appropriately. Ready to advance throwing distance.',
        'Progress to 90ft throws. Continue HEP. Advance strengthening with resistance bands. See in 1 week for long-toss progression.',
        '{"heart_rate": 58, "blood_pressure": "116/72"}'::jsonb,
        2, 'improving',
        45,
        '["97110", "97530"]'::jsonb,
        'signed',
        NOW() - INTERVAL '45 days',
        NOW() - INTERVAL '45 days'
    ),
    -- Visit 10: Near discharge (14 days ago)
    (
        '50000000-0000-0000-0001-000000000003'::uuid,
        '00000000-0000-0000-0000-000000000001'::uuid,
        '00000000-0000-0000-0000-000000000100'::uuid,
        CURRENT_DATE - INTERVAL '14 days',
        'Patient completing long-toss program at 180ft. No pain. Arm feels strong and loose. Ready to get back on mound. Arm care routine taking 25 mins daily - very compliant.',
        'ROM: Excellent - R shoulder ER actually exceeds L by 5° (normal throwing adaptation). All strength tests 5/5 bilaterally. Throwing mechanics reviewed - efficient and no compensation patterns.',
        'Near full recovery. Ready to initiate mound work. Excellent compliance with arm care program has contributed to positive outcome.',
        'Begin bullpen protocol next week. Start at 50% intensity, 20 pitches fastballs only. Progress per protocol. Final clearance pending 2 successful bullpen sessions. Discharge planning initiated.',
        '{"heart_rate": 56, "blood_pressure": "114/70"}'::jsonb,
        1, 'improving',
        30,
        '["97530"]'::jsonb,
        'signed',
        NOW() - INTERVAL '14 days',
        NOW() - INTERVAL '14 days'
    ),
    -- Recent visit (3 days ago, draft)
    (
        '50000000-0000-0000-0001-000000000004'::uuid,
        '00000000-0000-0000-0000-000000000001'::uuid,
        '00000000-0000-0000-0000-000000000100'::uuid,
        CURRENT_DATE - INTERVAL '3 days',
        'First bullpen session completed yesterday. 25 pitches, all fastballs at 60% intensity. Reports feeling "great" - no pain during or after. Arm recovered well overnight. Eager to progress.',
        'Post-throwing assessment: No increased pain or swelling. ROM maintained. No tenderness on palpation of UCL. Arm care assessment green light.',
        'Excellent tolerance of initial bullpen work. On track for clearance if next session goes well.',
        'Second bullpen session in 3 days. Progress to 30 pitches, 70% intensity. If tolerates, may add breaking balls at 50%. Final clearance evaluation after next session.',
        '{"heart_rate": 60, "blood_pressure": "118/74"}'::jsonb,
        0, 'improving',
        25,
        '["97530"]'::jsonb,
        'draft',
        NULL,
        NOW() - INTERVAL '3 days'
    )
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 4. WORKOUT PRESCRIPTIONS
-- ============================================================================

-- Note: workout_prescriptions references auth.users for therapist_id, not therapists table
-- We need to get the auth user ID for the demo therapist
DO $$
DECLARE
    therapist_auth_id UUID;
BEGIN
    -- Get the auth user ID for demo therapist
    SELECT user_id INTO therapist_auth_id FROM therapists WHERE id = '00000000-0000-0000-0000-000000000100'::uuid;

    IF therapist_auth_id IS NOT NULL THEN
        INSERT INTO workout_prescriptions (
            id, patient_id, therapist_id, template_type, name, instructions, due_date, priority, status, prescribed_at, viewed_at, started_at, completed_at
        )
        VALUES
            -- Completed prescription (7 days ago)
            (
                '000000f0-0000-0000-0001-000000000001'::uuid,
                '00000000-0000-0000-0000-000000000001'::uuid,
                therapist_auth_id,
                'system',
                'Morning Arm Care Protocol',
                'Complete the arm care routine before any throwing activity. Focus on sleeper stretch and posterior capsule work.',
                CURRENT_DATE - INTERVAL '7 days',
                'high',
                'completed',
                NOW() - INTERVAL '8 days',
                NOW() - INTERVAL '8 days',
                NOW() - INTERVAL '7 days',
                NOW() - INTERVAL '7 days'
            ),
            -- Completed prescription (5 days ago)
            (
                '000000f0-0000-0000-0001-000000000002'::uuid,
                '00000000-0000-0000-0000-000000000001'::uuid,
                therapist_auth_id,
                'system',
                'Scapular Stability Circuit',
                'Focus on controlled movements. If any pain, stop and note in app.',
                CURRENT_DATE - INTERVAL '5 days',
                'medium',
                'completed',
                NOW() - INTERVAL '6 days',
                NOW() - INTERVAL '6 days',
                NOW() - INTERVAL '5 days',
                NOW() - INTERVAL '5 days'
            ),
            -- Started prescription (2 days ago)
            (
                '000000f0-0000-0000-0001-000000000003'::uuid,
                '00000000-0000-0000-0000-000000000001'::uuid,
                therapist_auth_id,
                'system',
                'Pre-Bullpen Warmup',
                'Complete 20 minutes before your bullpen session. Emphasize dynamic stretching and band work.',
                CURRENT_DATE,
                'high',
                'started',
                NOW() - INTERVAL '2 days',
                NOW() - INTERVAL '2 days',
                NOW() - INTERVAL '1 day',
                NULL
            ),
            -- Pending prescription (due tomorrow)
            (
                '000000f0-0000-0000-0001-000000000004'::uuid,
                '00000000-0000-0000-0000-000000000001'::uuid,
                therapist_auth_id,
                'system',
                'Recovery Day Protocol',
                'Light mobility work only. No throwing today. Focus on recovery strategies.',
                CURRENT_DATE + INTERVAL '1 day',
                'medium',
                'pending',
                NOW(),
                NULL,
                NULL,
                NULL
            )
        ON CONFLICT DO NOTHING;
    END IF;
END $$;

-- ============================================================================
-- 5. PATIENT ALERTS (Active coaching alerts)
-- ============================================================================

-- First ensure we have some safety rules
INSERT INTO safety_rules (id, rule_name, rule_type, condition, severity, message_template, is_active)
VALUES
    ('e0000000-0000-0000-0001-000000000001'::uuid, 'High Pain Alert', 'pain_threshold', '{"threshold": 7, "operator": ">="}', 'critical', 'Pain level of {{value}} reported - immediate attention required', true),
    ('e0000000-0000-0000-0001-000000000002'::uuid, 'Adherence Drop', 'adherence_drop', '{"threshold": 50, "window_days": 7}', 'high', 'Workout adherence dropped to {{value}}% over past week', true),
    ('e0000000-0000-0000-0001-000000000003'::uuid, 'Missed Sessions', 'missed_sessions', '{"threshold": 3, "window_days": 7}', 'medium', '{{value}} sessions missed in the past week', true),
    ('e0000000-0000-0000-0001-000000000004'::uuid, 'RPE Spike', 'rpe_spike', '{"threshold": 2, "operator": ">="}', 'high', 'RPE increased by {{value}} points from baseline', true)
ON CONFLICT DO NOTHING;

-- Now add some demo alerts (some resolved, some active)
INSERT INTO patient_alerts (
    id, patient_id, therapist_id, rule_id,
    alert_type, severity, title, description, trigger_data,
    status, acknowledged_at, resolved_at, resolution_notes, created_at
)
VALUES
    -- Resolved alert from 30 days ago
    (
        '10000000-0000-0000-0001-000000000001'::uuid,
        '00000000-0000-0000-0000-000000000001'::uuid,
        '00000000-0000-0000-0000-000000000100'::uuid,
        'e0000000-0000-0000-0001-000000000001'::uuid,
        'pain_alert',
        'high',
        'Elevated Pain Reported',
        'Patient reported pain level of 6/10 during throwing session',
        '{"pain_level": 6, "activity": "throwing", "session_date": "2026-01-08"}'::jsonb,
        'resolved',
        NOW() - INTERVAL '30 days',
        NOW() - INTERVAL '29 days',
        'Contacted patient. Reduced intensity per protocol. Pain resolved within 24 hours.',
        NOW() - INTERVAL '30 days'
    ),
    -- Acknowledged alert from 7 days ago
    (
        '10000000-0000-0000-0001-000000000002'::uuid,
        '00000000-0000-0000-0000-000000000001'::uuid,
        '00000000-0000-0000-0000-000000000100'::uuid,
        'e0000000-0000-0000-0001-000000000003'::uuid,
        'exception',
        'low',
        'Arm Care Session Skipped',
        'Patient missed scheduled arm care session',
        '{"missed_date": "2026-02-01", "session_type": "arm_care"}'::jsonb,
        'resolved',
        NOW() - INTERVAL '6 days',
        NOW() - INTERVAL '5 days',
        'Patient traveling. Made up session upon return.',
        NOW() - INTERVAL '7 days'
    ),
    -- Active alert (needs attention)
    (
        '10000000-0000-0000-0001-000000000003'::uuid,
        '00000000-0000-0000-0000-000000000001'::uuid,
        '00000000-0000-0000-0000-000000000100'::uuid,
        NULL,
        'safety_check',
        'medium',
        'Pre-Return Clearance Pending',
        'Patient has completed bullpen protocol - final clearance evaluation needed',
        '{"bullpen_sessions_completed": 1, "target": 2, "last_session_date": "2026-02-04"}'::jsonb,
        'active',
        NULL,
        NULL,
        NULL,
        NOW() - INTERVAL '1 day'
    )
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 6. FIX RLS FOR THERAPIST TABLES (Demo mode)
-- ============================================================================

-- Clinical Assessments
DO $$
DECLARE pol record;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'clinical_assessments'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.clinical_assessments', pol.policyname);
    END LOOP;
END $$;

ALTER TABLE public.clinical_assessments DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.clinical_assessments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "clinical_assessments_select" ON public.clinical_assessments FOR SELECT USING (true);
CREATE POLICY "clinical_assessments_insert" ON public.clinical_assessments FOR INSERT WITH CHECK (true);
CREATE POLICY "clinical_assessments_update" ON public.clinical_assessments FOR UPDATE USING (true);
CREATE POLICY "clinical_assessments_delete" ON public.clinical_assessments FOR DELETE USING (true);

GRANT ALL ON public.clinical_assessments TO authenticated;
GRANT ALL ON public.clinical_assessments TO anon;

-- Outcome Measures
DO $$
DECLARE pol record;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'outcome_measures'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.outcome_measures', pol.policyname);
    END LOOP;
END $$;

ALTER TABLE public.outcome_measures DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.outcome_measures ENABLE ROW LEVEL SECURITY;

CREATE POLICY "outcome_measures_select" ON public.outcome_measures FOR SELECT USING (true);
CREATE POLICY "outcome_measures_insert" ON public.outcome_measures FOR INSERT WITH CHECK (true);
CREATE POLICY "outcome_measures_update" ON public.outcome_measures FOR UPDATE USING (true);
CREATE POLICY "outcome_measures_delete" ON public.outcome_measures FOR DELETE USING (true);

GRANT ALL ON public.outcome_measures TO authenticated;
GRANT ALL ON public.outcome_measures TO anon;

-- SOAP Notes
DO $$
DECLARE pol record;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'soap_notes'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.soap_notes', pol.policyname);
    END LOOP;
END $$;

ALTER TABLE public.soap_notes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.soap_notes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "soap_notes_select" ON public.soap_notes FOR SELECT USING (true);
CREATE POLICY "soap_notes_insert" ON public.soap_notes FOR INSERT WITH CHECK (true);
CREATE POLICY "soap_notes_update" ON public.soap_notes FOR UPDATE USING (true);
CREATE POLICY "soap_notes_delete" ON public.soap_notes FOR DELETE USING (true);

GRANT ALL ON public.soap_notes TO authenticated;
GRANT ALL ON public.soap_notes TO anon;

-- Patient Alerts
DO $$
DECLARE pol record;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'patient_alerts'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.patient_alerts', pol.policyname);
    END LOOP;
END $$;

ALTER TABLE public.patient_alerts DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_alerts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "patient_alerts_select" ON public.patient_alerts FOR SELECT USING (true);
CREATE POLICY "patient_alerts_insert" ON public.patient_alerts FOR INSERT WITH CHECK (true);
CREATE POLICY "patient_alerts_update" ON public.patient_alerts FOR UPDATE USING (true);
CREATE POLICY "patient_alerts_delete" ON public.patient_alerts FOR DELETE USING (true);

GRANT ALL ON public.patient_alerts TO authenticated;
GRANT ALL ON public.patient_alerts TO anon;

-- Safety Rules
DO $$
DECLARE pol record;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'safety_rules'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.safety_rules', pol.policyname);
    END LOOP;
END $$;

ALTER TABLE public.safety_rules DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.safety_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "safety_rules_select" ON public.safety_rules FOR SELECT USING (true);
CREATE POLICY "safety_rules_insert" ON public.safety_rules FOR INSERT WITH CHECK (true);
CREATE POLICY "safety_rules_update" ON public.safety_rules FOR UPDATE USING (true);
CREATE POLICY "safety_rules_delete" ON public.safety_rules FOR DELETE USING (true);

GRANT ALL ON public.safety_rules TO authenticated;
GRANT ALL ON public.safety_rules TO anon;

-- Workout Prescriptions
DO $$
DECLARE pol record;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'workout_prescriptions'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.workout_prescriptions', pol.policyname);
    END LOOP;
END $$;

ALTER TABLE public.workout_prescriptions DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_prescriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "workout_prescriptions_select" ON public.workout_prescriptions FOR SELECT USING (true);
CREATE POLICY "workout_prescriptions_insert" ON public.workout_prescriptions FOR INSERT WITH CHECK (true);
CREATE POLICY "workout_prescriptions_update" ON public.workout_prescriptions FOR UPDATE USING (true);
CREATE POLICY "workout_prescriptions_delete" ON public.workout_prescriptions FOR DELETE USING (true);

GRANT ALL ON public.workout_prescriptions TO authenticated;
GRANT ALL ON public.workout_prescriptions TO anon;

-- ============================================================================
-- 7. Force schema reload
-- ============================================================================

NOTIFY pgrst, 'reload schema';
