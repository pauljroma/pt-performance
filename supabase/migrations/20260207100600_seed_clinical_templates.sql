-- Clinical Assessments & Documentation Feature
-- Part 7: Seed Data for System Templates
-- Created: 2026-02-07

-- ============================================================================
-- SOAP TEMPLATES - GENERAL
-- ============================================================================

INSERT INTO public.clinical_templates (
    name,
    description,
    template_type,
    body_region,
    template_content,
    default_values,
    is_system_template,
    is_active
) VALUES
-- General SOAP Template
(
    'General SOAP Note',
    'Standard SOAP note template for routine visits',
    'soap',
    'general',
    '{
        "sections": {
            "subjective": {
                "prompts": [
                    "Patient reports current symptoms",
                    "Pain level and location",
                    "Changes since last visit",
                    "Home exercise compliance",
                    "Functional limitations"
                ]
            },
            "objective": {
                "prompts": [
                    "Posture and gait observations",
                    "Range of motion findings",
                    "Strength testing results",
                    "Special tests performed",
                    "Palpation findings"
                ]
            },
            "assessment": {
                "prompts": [
                    "Response to previous treatment",
                    "Progress toward goals",
                    "Current functional status",
                    "Barriers to progress"
                ]
            },
            "plan": {
                "prompts": [
                    "Treatment interventions for today",
                    "Home exercise modifications",
                    "Goals for next visit",
                    "Frequency and duration recommendations"
                ]
            }
        }
    }',
    '{
        "functional_status": "stable",
        "time_spent_minutes": 45
    }',
    true,
    true
),

-- ============================================================================
-- SOAP TEMPLATES - SHOULDER
-- ============================================================================
(
    'Shoulder SOAP Note',
    'SOAP note template for shoulder conditions (rotator cuff, impingement, frozen shoulder)',
    'soap',
    'shoulder',
    '{
        "sections": {
            "subjective": {
                "prompts": [
                    "Current shoulder pain location and radiation pattern",
                    "Pain with overhead activities",
                    "Night pain or difficulty sleeping on affected side",
                    "Functional limitations (dressing, reaching, lifting)",
                    "Changes in symptoms since last visit"
                ],
                "common_complaints": [
                    "Pain with reaching overhead",
                    "Difficulty sleeping on shoulder",
                    "Weakness with lifting",
                    "Clicking or catching sensation"
                ]
            },
            "objective": {
                "measurements": {
                    "rom": ["flexion", "abduction", "external_rotation", "internal_rotation"],
                    "strength": ["supraspinatus", "infraspinatus", "subscapularis", "deltoid"]
                },
                "special_tests": [
                    "Empty can test",
                    "Hawkins-Kennedy",
                    "Neer impingement",
                    "Speeds test",
                    "Cross-arm adduction"
                ],
                "prompts": [
                    "Scapular positioning and winging",
                    "Shoulder girdle posture",
                    "Cervical ROM screening"
                ]
            },
            "assessment": {
                "prompts": [
                    "Stage of healing/rehabilitation",
                    "Progress with ROM and strength",
                    "Functional improvement",
                    "Impairments limiting function"
                ]
            },
            "plan": {
                "interventions": [
                    "Manual therapy techniques",
                    "Therapeutic exercise",
                    "Modalities used",
                    "Patient education"
                ],
                "home_program": [
                    "Pendulum exercises",
                    "Rotator cuff strengthening",
                    "Scapular stabilization",
                    "Stretching program"
                ]
            }
        }
    }',
    '{
        "vitals": {},
        "time_spent_minutes": 45,
        "cpt_codes": ["97110", "97140", "97530"]
    }',
    true,
    true
),

-- ============================================================================
-- SOAP TEMPLATES - KNEE
-- ============================================================================
(
    'Knee SOAP Note',
    'SOAP note template for knee conditions (ACL, meniscus, patellofemoral, OA)',
    'soap',
    'knee',
    '{
        "sections": {
            "subjective": {
                "prompts": [
                    "Location of knee pain (anterior, medial, lateral, posterior)",
                    "Aggravating activities (stairs, squatting, walking)",
                    "Episodes of giving way or instability",
                    "Swelling or locking sensations",
                    "Impact on daily activities and sports"
                ],
                "common_complaints": [
                    "Pain with stairs",
                    "Giving way with pivoting",
                    "Morning stiffness",
                    "Pain with prolonged sitting"
                ]
            },
            "objective": {
                "measurements": {
                    "rom": ["flexion", "extension"],
                    "strength": ["quadriceps", "hamstrings", "hip_abductors"],
                    "girth": ["superior_pole", "joint_line", "inferior_pole"]
                },
                "special_tests": [
                    "Lachman test",
                    "Anterior drawer",
                    "McMurray test",
                    "Patellar grind",
                    "Varus/valgus stress"
                ],
                "functional_tests": [
                    "Single leg squat quality",
                    "Step down test",
                    "Balance assessment"
                ]
            },
            "assessment": {
                "prompts": [
                    "Phase of rehabilitation",
                    "Quad activation and control",
                    "Functional progress",
                    "Return to activity readiness"
                ]
            },
            "plan": {
                "interventions": [
                    "Quad strengthening progression",
                    "Balance and proprioception",
                    "Gait training",
                    "Modalities for swelling/pain"
                ],
                "milestones": [
                    "Full ROM",
                    "Normal gait pattern",
                    "Return to sport criteria"
                ]
            }
        }
    }',
    '{
        "time_spent_minutes": 45,
        "cpt_codes": ["97110", "97530", "97542"]
    }',
    true,
    true
),

-- ============================================================================
-- SOAP TEMPLATES - LUMBAR SPINE
-- ============================================================================
(
    'Lumbar Spine SOAP Note',
    'SOAP note template for low back pain conditions',
    'soap',
    'lumbar_spine',
    '{
        "sections": {
            "subjective": {
                "prompts": [
                    "Location and distribution of pain (central, unilateral, radiating)",
                    "Aggravating positions and activities",
                    "Relieving positions and activities",
                    "Neurological symptoms (numbness, tingling, weakness)",
                    "Impact on work, sleep, and daily activities"
                ],
                "red_flags": [
                    "Saddle anesthesia",
                    "Bowel/bladder changes",
                    "Progressive weakness",
                    "Night pain unrelated to position"
                ]
            },
            "objective": {
                "measurements": {
                    "rom": ["flexion", "extension", "sidebending", "rotation"],
                    "neurological": ["myotomes", "dermatomes", "reflexes"]
                },
                "special_tests": [
                    "SLR/Slump test",
                    "Prone instability test",
                    "FABER/FADIR",
                    "Centralization/peripheralization"
                ],
                "prompts": [
                    "Posture assessment",
                    "Movement patterns",
                    "Core activation ability"
                ]
            },
            "assessment": {
                "prompts": [
                    "Classification (directional preference, motor control)",
                    "Response to mechanical loading",
                    "Functional limitations",
                    "Prognosis indicators"
                ]
            },
            "plan": {
                "interventions": [
                    "Directional exercises",
                    "Manual therapy",
                    "Core stabilization",
                    "Posture/ergonomic education"
                ],
                "home_program": [
                    "Specific directional exercises",
                    "Core activation",
                    "Posture breaks",
                    "Walking program"
                ]
            }
        }
    }',
    '{
        "time_spent_minutes": 45,
        "cpt_codes": ["97110", "97140", "97530"]
    }',
    true,
    true
),

-- ============================================================================
-- SOAP TEMPLATES - CERVICAL SPINE
-- ============================================================================
(
    'Cervical Spine SOAP Note',
    'SOAP note template for neck pain and headache conditions',
    'soap',
    'cervical',
    '{
        "sections": {
            "subjective": {
                "prompts": [
                    "Location of neck pain and any radiation",
                    "Associated headaches (location, frequency, intensity)",
                    "Neurological symptoms in upper extremities",
                    "Aggravating activities and positions",
                    "Impact on work and daily activities"
                ],
                "red_flags": [
                    "Dizziness with neck movement",
                    "Drop attacks",
                    "Bilateral neurological symptoms",
                    "Progressive weakness"
                ]
            },
            "objective": {
                "measurements": {
                    "rom": ["flexion", "extension", "rotation", "sidebending"],
                    "neurological": ["upper_extremity_myotomes", "dermatomes", "reflexes"]
                },
                "special_tests": [
                    "Spurling test",
                    "Upper limb tension tests",
                    "Vertebral artery test",
                    "Cervical flexion-rotation test"
                ],
                "prompts": [
                    "Cervical posture (forward head position)",
                    "Thoracic kyphosis",
                    "Scapular position",
                    "Upper trapezius/levator tension"
                ]
            },
            "assessment": {
                "prompts": [
                    "Cervical mobility status",
                    "Headache classification if applicable",
                    "Functional limitations",
                    "Response to treatment"
                ]
            },
            "plan": {
                "interventions": [
                    "Cervical mobilization/manipulation",
                    "Postural correction",
                    "Deep neck flexor training",
                    "Thoracic mobility"
                ],
                "home_program": [
                    "Chin tucks",
                    "Postural exercises",
                    "Stretching program",
                    "Workstation modifications"
                ]
            }
        }
    }',
    '{
        "time_spent_minutes": 45,
        "cpt_codes": ["97110", "97140", "97530"]
    }',
    true,
    true
),

-- ============================================================================
-- SOAP TEMPLATES - HIP
-- ============================================================================
(
    'Hip SOAP Note',
    'SOAP note template for hip conditions (OA, labral, FAI, bursitis)',
    'soap',
    'hip',
    '{
        "sections": {
            "subjective": {
                "prompts": [
                    "Location of hip pain (groin, lateral, posterior)",
                    "Pain with sitting, walking, or specific activities",
                    "Clicking, catching, or giving way",
                    "Impact on sleep and daily activities",
                    "History of hip problems"
                ]
            },
            "objective": {
                "measurements": {
                    "rom": ["flexion", "extension", "abduction", "adduction", "internal_rotation", "external_rotation"],
                    "strength": ["hip_flexors", "hip_abductors", "hip_extensors"]
                },
                "special_tests": [
                    "FABER test",
                    "FADIR test",
                    "Thomas test",
                    "Trendelenburg test",
                    "Log roll test"
                ],
                "prompts": [
                    "Gait analysis",
                    "Single leg stance",
                    "Lumbar spine screening"
                ]
            },
            "assessment": {
                "prompts": [
                    "Primary impairments",
                    "Functional limitations",
                    "Contributing factors",
                    "Progress status"
                ]
            },
            "plan": {
                "interventions": [
                    "Hip mobilization",
                    "Strengthening program",
                    "Gait training",
                    "Activity modification"
                ]
            }
        }
    }',
    '{
        "time_spent_minutes": 45,
        "cpt_codes": ["97110", "97140", "97530"]
    }',
    true,
    true
),

-- ============================================================================
-- ASSESSMENT TEMPLATES
-- ============================================================================
(
    'Initial Evaluation Template',
    'Comprehensive intake assessment template',
    'intake',
    'general',
    '{
        "sections": {
            "patient_history": {
                "fields": [
                    "chief_complaint",
                    "history_of_present_illness",
                    "mechanism_of_injury",
                    "previous_treatments",
                    "past_medical_history",
                    "medications",
                    "social_history"
                ]
            },
            "systems_review": {
                "fields": [
                    "cardiovascular",
                    "pulmonary",
                    "musculoskeletal",
                    "neuromuscular",
                    "integumentary"
                ]
            },
            "examination": {
                "fields": [
                    "posture",
                    "range_of_motion",
                    "strength",
                    "flexibility",
                    "balance",
                    "gait",
                    "special_tests"
                ]
            },
            "assessment_plan": {
                "fields": [
                    "diagnosis",
                    "prognosis",
                    "treatment_plan",
                    "goals_short_term",
                    "goals_long_term",
                    "frequency_duration"
                ]
            }
        }
    }',
    '{
        "assessment_type": "intake",
        "status": "draft"
    }',
    true,
    true
),
(
    'Progress Note Assessment',
    'Template for periodic progress assessments',
    'assessment',
    'general',
    '{
        "sections": {
            "interval_history": {
                "prompts": [
                    "Changes since last assessment",
                    "Response to treatment",
                    "Home program compliance",
                    "New symptoms or concerns"
                ]
            },
            "objective_measures": {
                "prompts": [
                    "ROM changes",
                    "Strength improvements",
                    "Functional test results",
                    "Pain scale changes"
                ]
            },
            "goal_review": {
                "prompts": [
                    "Short-term goal status",
                    "Long-term goal progress",
                    "Goal modifications needed"
                ]
            },
            "plan_update": {
                "prompts": [
                    "Treatment modifications",
                    "Frequency adjustments",
                    "Discharge planning status"
                ]
            }
        }
    }',
    '{
        "assessment_type": "progress"
    }',
    true,
    true
),
(
    'Discharge Summary Template',
    'Template for patient discharge documentation',
    'discharge',
    'general',
    '{
        "sections": {
            "treatment_summary": {
                "prompts": [
                    "Total visits attended",
                    "Treatment interventions provided",
                    "Modalities utilized",
                    "Patient education completed"
                ]
            },
            "outcomes": {
                "prompts": [
                    "Final ROM measurements",
                    "Final strength assessment",
                    "Functional outcome scores",
                    "Pain level at discharge",
                    "Goal achievement status"
                ]
            },
            "discharge_status": {
                "options": [
                    "Goals met",
                    "Maximum benefit achieved",
                    "Patient request",
                    "Non-compliance",
                    "Referred elsewhere"
                ]
            },
            "recommendations": {
                "prompts": [
                    "Home exercise program",
                    "Activity precautions",
                    "Follow-up recommendations",
                    "Return precautions"
                ]
            }
        }
    }',
    '{
        "assessment_type": "discharge"
    }',
    true,
    true
),

-- ============================================================================
-- SPORTS-SPECIFIC TEMPLATES
-- ============================================================================
(
    'Baseball/Throwing Athlete SOAP',
    'SOAP note for throwing athletes (shoulder and elbow focus)',
    'soap',
    'shoulder',
    '{
        "sections": {
            "subjective": {
                "prompts": [
                    "Current throwing status and volume",
                    "Location and timing of pain (cocking, acceleration, follow-through)",
                    "Velocity and command changes",
                    "Arm care routine compliance",
                    "Sleep and recovery"
                ],
                "throwing_history": [
                    "Pitch count this week",
                    "Days since last outing",
                    "Current phase (off-season, spring training, in-season)"
                ]
            },
            "objective": {
                "measurements": {
                    "shoulder_rom": ["flexion", "abduction", "GIRD", "total_arc_motion"],
                    "elbow_rom": ["flexion", "extension"],
                    "strength": ["external_rotation", "internal_rotation", "scapular"]
                },
                "special_tests": [
                    "Posterior impingement test",
                    "Anterior apprehension",
                    "Sulcus sign",
                    "Moving valgus stress",
                    "Milking maneuver"
                ],
                "functional_tests": [
                    "Scapular dyskinesis assessment",
                    "GIRD measurement",
                    "Total arc comparison"
                ]
            },
            "assessment": {
                "prompts": [
                    "Arm health status",
                    "Risk factors identified",
                    "Throwing program phase",
                    "Return to throw timeline"
                ]
            },
            "plan": {
                "interventions": [
                    "Arm care exercises",
                    "Posterior capsule stretching",
                    "Scapular strengthening",
                    "Rotator cuff program"
                ],
                "throwing_program": [
                    "Current phase",
                    "Next progression",
                    "Volume recommendations"
                ]
            }
        }
    }',
    '{
        "time_spent_minutes": 45,
        "cpt_codes": ["97110", "97530", "97542"]
    }',
    true,
    true
),
(
    'Post-Surgical Rehabilitation SOAP',
    'SOAP note template for post-operative rehabilitation',
    'soap',
    'general',
    '{
        "sections": {
            "subjective": {
                "prompts": [
                    "Weeks post-operative",
                    "Pain level and medication use",
                    "Incision/wound status",
                    "Sleep quality",
                    "Home exercise compliance",
                    "Any new symptoms or concerns"
                ],
                "precautions": [
                    "Weight bearing status",
                    "ROM restrictions",
                    "Activity restrictions"
                ]
            },
            "objective": {
                "measurements": {
                    "incision": ["healing_status", "swelling", "warmth"],
                    "rom": ["active", "passive"],
                    "strength": ["manual_muscle_test"]
                },
                "prompts": [
                    "Girth measurements",
                    "Edema assessment",
                    "Gait/mobility status"
                ]
            },
            "assessment": {
                "prompts": [
                    "Healing status",
                    "Phase of rehabilitation",
                    "Protocol compliance",
                    "Progression readiness"
                ]
            },
            "plan": {
                "prompts": [
                    "Current phase exercises",
                    "Precautions maintained",
                    "Criteria for next phase",
                    "Follow-up with surgeon"
                ]
            }
        }
    }',
    '{
        "time_spent_minutes": 45,
        "cpt_codes": ["97110", "97530", "97542"]
    }',
    true,
    true
);

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    template_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO template_count FROM public.clinical_templates WHERE is_system_template = true;
    RAISE NOTICE 'Seeded % system clinical templates', template_count;
END;
$$;
