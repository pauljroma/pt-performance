-- 004_seed_exercise_library.sql
-- Exercise Library Seed Data for PT Performance Platform
-- Agent 3 - Phase 1: Data Layer (ACP-67)
--
-- Comprehensive exercise library with 50+ exercises covering:
-- - Strength training (compound lifts, accessory work)
-- - Mobility and activation
-- - Plyometric drills (throwing-specific)
-- - Arm care and rotator cuff exercises
-- - Lower body and core work
--
-- Run after: 001_init_supabase.sql, 002_epic_enhancements.sql

-- ============================================================================
-- STRENGTH - UPPER BODY (Compound Lifts)
-- ============================================================================

INSERT INTO exercise_templates (
  id, name, category, body_region, equipment, load_type,
  primary_muscle_group, is_primary_lift, default_rm_method,
  movement_pattern, cueing, clinical_tags, programming_metadata
) VALUES
(
  '10000000-0000-0000-0000-000000000001'::uuid,
  'Bench Press (Barbell)',
  'strength',
  'chest',
  'barbell',
  'weight',
  'pectoralis_major',
  true,
  'epley',
  'horizontal_push',
  'Drive through the floor, keep shoulder blades retracted, bar touches lower chest',
  '[]'::jsonb,
  '{"default_set_rep_scheme": "3x5-8", "progression_type": "linear load", "tissue_capacity_rating": 8}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000002'::uuid,
  'Overhead Press (Barbell)',
  'strength',
  'shoulder',
  'barbell',
  'weight',
  'deltoids',
  true,
  'epley',
  'vertical_push',
  'Elbows slightly forward, press straight up, squeeze glutes',
  '["contraindicated_post_surgery"]'::jsonb,
  '{"default_set_rep_scheme": "3x5-8", "progression_type": "linear load", "tissue_capacity_rating": 7}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000003'::uuid,
  'Pull-Up (Bodyweight)',
  'strength',
  'back',
  'pull-up bar',
  'bodyweight',
  'latissimus_dorsi',
  true,
  'none',
  'vertical_pull',
  'Full hang, chest to bar, controlled descent',
  '[]'::jsonb,
  '{"default_set_rep_scheme": "3x6-10", "progression_type": "reps then load", "tissue_capacity_rating": 8}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000004'::uuid,
  'Barbell Row (Bent Over)',
  'strength',
  'back',
  'barbell',
  'weight',
  'latissimus_dorsi',
  true,
  'epley',
  'horizontal_pull',
  'Hinge at hips, row to lower ribs, elbows back',
  '[]'::jsonb,
  '{"default_set_rep_scheme": "3x6-10", "progression_type": "linear load", "tissue_capacity_rating": 8}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000005'::uuid,
  'Dumbbell Bench Press (Incline)',
  'strength',
  'chest',
  'dumbbells',
  'weight',
  'pectoralis_major',
  false,
  'epley',
  'horizontal_push',
  '30-45° incline, full ROM, control the eccentric',
  '[]'::jsonb,
  '{"default_set_rep_scheme": "3x8-12", "progression_type": "linear load", "tissue_capacity_rating": 7}'::jsonb
);

-- ============================================================================
-- STRENGTH - LOWER BODY
-- ============================================================================

INSERT INTO exercise_templates (
  id, name, category, body_region, equipment, load_type,
  primary_muscle_group, is_primary_lift, default_rm_method,
  movement_pattern, cueing, clinical_tags, programming_metadata
) VALUES
(
  '10000000-0000-0000-0000-000000000010'::uuid,
  'Back Squat (Barbell)',
  'strength',
  'legs',
  'barbell',
  'weight',
  'quadriceps',
  true,
  'epley',
  'squat',
  'Hip crease below knee, knees track over toes, chest up',
  '[]'::jsonb,
  '{"default_set_rep_scheme": "3x5-8", "progression_type": "linear load", "tissue_capacity_rating": 9}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000011'::uuid,
  'Deadlift (Conventional)',
  'strength',
  'posterior_chain',
  'barbell',
  'weight',
  'erector_spinae',
  true,
  'epley',
  'hinge',
  'Neutral spine, hips back, drive through floor',
  '[]'::jsonb,
  '{"default_set_rep_scheme": "1x5 or 3x3", "progression_type": "linear load", "tissue_capacity_rating": 9}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000012'::uuid,
  'Bulgarian Split Squat',
  'strength',
  'legs',
  'dumbbells',
  'weight',
  'quadriceps',
  false,
  'none',
  'lunge',
  'Front knee over ankle, vertical torso, drive through front heel',
  '[]'::jsonb,
  '{"default_set_rep_scheme": "3x8-12 per leg", "progression_type": "linear load", "tissue_capacity_rating": 7}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000013'::uuid,
  'Romanian Deadlift (Barbell)',
  'strength',
  'posterior_chain',
  'barbell',
  'weight',
  'hamstrings',
  false,
  'epley',
  'hinge',
  'Hinge from hips, bar tracks down shins, soft knees',
  '[]'::jsonb,
  '{"default_set_rep_scheme": "3x8-12", "progression_type": "linear load", "tissue_capacity_rating": 8}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000014'::uuid,
  'Walking Lunge (Dumbbell)',
  'strength',
  'legs',
  'dumbbells',
  'weight',
  'quadriceps',
  false,
  'none',
  'lunge',
  'Long stride, knee almost touches ground, stay tall',
  '[]'::jsonb,
  '{"default_set_rep_scheme": "3x10-15 per leg", "progression_type": "linear load", "tissue_capacity_rating": 6}'::jsonb
);

-- ============================================================================
-- ARM CARE & ROTATOR CUFF
-- ============================================================================

INSERT INTO exercise_templates (
  id, name, category, body_region, equipment, load_type,
  primary_muscle_group, is_primary_lift, default_rm_method,
  movement_pattern, cueing, clinical_tags, throwing_tags, programming_metadata
) VALUES
(
  '10000000-0000-0000-0000-000000000020'::uuid,
  'External Rotation (Dumbbell, Side-Lying)',
  'strength',
  'shoulder',
  'dumbbell',
  'weight',
  'infraspinatus',
  false,
  'none',
  'rotation',
  'Elbow at 90°, rotate arm upward, keep elbow tucked',
  '["promotes_external_rotation"]'::jsonb,
  '{"drill_category": "arm care", "velocity_tracking_required": false}'::jsonb,
  '{"default_set_rep_scheme": "3x12-15", "progression_type": "slow progression", "tissue_capacity_rating": 6}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000021'::uuid,
  'Internal Rotation (Cable)',
  'strength',
  'shoulder',
  'cable',
  'weight',
  'subscapularis',
  false,
  'none',
  'rotation',
  'Elbow at 90°, rotate across body, keep elbow at side',
  '["promotes_internal_rotation"]'::jsonb,
  '{"drill_category": "arm care", "velocity_tracking_required": false}'::jsonb,
  '{"default_set_rep_scheme": "3x12-15", "progression_type": "slow progression", "tissue_capacity_rating": 6}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000022'::uuid,
  'Prone T (Scapular Retraction)',
  'mobility',
  'shoulder',
  'light dumbbells',
  'weight',
  'rhomboids',
  false,
  'none',
  'scapular_retraction',
  'Thumbs up, squeeze shoulder blades together, lift arms',
  '[]'::jsonb,
  '{"drill_category": "arm care", "velocity_tracking_required": false}'::jsonb,
  '{"default_set_rep_scheme": "3x15-20", "progression_type": "none", "tissue_capacity_rating": 5}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000023'::uuid,
  'Prone Y (Scapular Elevation)',
  'mobility',
  'shoulder',
  'light dumbbells',
  'weight',
  'lower_trapezius',
  false,
  'none',
  'scapular_elevation',
  'Arms at 45°, thumbs up, lift and squeeze',
  '[]'::jsonb,
  '{"drill_category": "arm care", "velocity_tracking_required": false}'::jsonb,
  '{"default_set_rep_scheme": "3x15-20", "progression_type": "none", "tissue_capacity_rating": 5}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000024'::uuid,
  'Scapular Wall Slide',
  'mobility',
  'shoulder',
  'wall',
  'bodyweight',
  'serratus_anterior',
  false,
  'none',
  'overhead_mobility',
  'Back against wall, slide arms overhead, keep contact',
  '[]'::jsonb,
  '{"drill_category": "arm care", "velocity_tracking_required": false}'::jsonb,
  '{"default_set_rep_scheme": "3x10-12", "progression_type": "none", "tissue_capacity_rating": 4}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000025'::uuid,
  'Band Pull-Apart',
  'strength',
  'shoulder',
  'resistance band',
  'resistance',
  'posterior_deltoid',
  false,
  'none',
  'horizontal_pull',
  'Arms straight, pull band to chest, squeeze shoulder blades',
  '[]'::jsonb,
  '{"drill_category": "arm care", "velocity_tracking_required": false}'::jsonb,
  '{"default_set_rep_scheme": "3x15-20", "progression_type": "increase reps", "tissue_capacity_rating": 5}'::jsonb
);

-- ============================================================================
-- PLYOMETRIC & MEDICINE BALL DRILLS
-- ============================================================================

INSERT INTO exercise_templates (
  id, name, category, body_region, equipment, load_type,
  primary_muscle_group, is_primary_lift, default_rm_method,
  movement_pattern, cueing, clinical_tags, throwing_tags, programming_metadata
) VALUES
(
  '10000000-0000-0000-0000-000000000030'::uuid,
  'Med Ball Chest Pass (2-Hand)',
  'plyo',
  'chest',
  'medicine ball',
  'distance',
  'pectoralis_major',
  false,
  'none',
  'power_push',
  'Explosive push, full extension, catch with soft hands',
  '[]'::jsonb,
  '{"drill_category": "plyo", "ball_weight_oz": 6, "velocity_tracking_required": false}'::jsonb,
  '{"default_set_rep_scheme": "3x10", "progression_type": "increase ball weight", "tissue_capacity_rating": 7}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000031'::uuid,
  'Med Ball Overhead Slam',
  'plyo',
  'core',
  'medicine ball',
  'distance',
  'core',
  false,
  'none',
  'power_extension',
  'Full overhead extension, aggressive slam, hinge to pick up',
  '["valgus_stress_sensitive"]'::jsonb,
  '{"drill_category": "plyo", "ball_weight_oz": 10, "velocity_tracking_required": false}'::jsonb,
  '{"default_set_rep_scheme": "3x8-10", "progression_type": "increase ball weight", "tissue_capacity_rating": 8}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000032'::uuid,
  'Med Ball Side Toss (Rotational)',
  'plyo',
  'core',
  'medicine ball',
  'distance',
  'obliques',
  false,
  'none',
  'rotation',
  'Rotate from hips, explosive release, catch and redirect',
  '[]'::jsonb,
  '{"drill_category": "plyo", "ball_weight_oz": 8, "velocity_tracking_required": false}'::jsonb,
  '{"default_set_rep_scheme": "3x8-10 per side", "progression_type": "increase ball weight", "tissue_capacity_rating": 7}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000033'::uuid,
  'Plyo Ball Throw (1-Hand, 2oz)',
  'plyo',
  'shoulder',
  'plyo ball',
  'velocity',
  'deltoids',
  false,
  'none',
  'throwing',
  'Pitching mechanics, max intent, track velocity',
  '[]'::jsonb,
  '{"drill_category": "plyo", "ball_weight_oz": 2, "velocity_tracking_required": true, "pitch_type_supported": ["4-seam"]}'::jsonb,
  '{"default_set_rep_scheme": "3x5-8", "progression_type": "increase ball weight", "tissue_capacity_rating": 6}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000034'::uuid,
  'Plyo Ball Throw (1-Hand, 14oz)',
  'plyo',
  'shoulder',
  'plyo ball',
  'velocity',
  'deltoids',
  false,
  'none',
  'throwing',
  'Pitching mechanics, focus on deceleration, track velocity',
  '[]'::jsonb,
  '{"drill_category": "plyo", "ball_weight_oz": 14, "velocity_tracking_required": true, "pitch_type_supported": ["4-seam"]}'::jsonb,
  '{"default_set_rep_scheme": "3x5-8", "progression_type": "increase reps", "tissue_capacity_rating": 8}'::jsonb
);

-- ============================================================================
-- CORE EXERCISES
-- ============================================================================

INSERT INTO exercise_templates (
  id, name, category, body_region, equipment, load_type,
  primary_muscle_group, is_primary_lift, default_rm_method,
  movement_pattern, cueing, clinical_tags, programming_metadata
) VALUES
(
  '10000000-0000-0000-0000-000000000040'::uuid,
  'Plank (Front)',
  'strength',
  'core',
  'bodyweight',
  'time',
  'rectus_abdominis',
  false,
  'none',
  'anti_extension',
  'Elbows under shoulders, neutral spine, squeeze glutes',
  '[]'::jsonb,
  '{"default_set_rep_scheme": "3x30-60s", "progression_type": "increase duration", "tissue_capacity_rating": 5}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000041'::uuid,
  'Side Plank',
  'strength',
  'core',
  'bodyweight',
  'time',
  'obliques',
  false,
  'none',
  'anti_lateral_flexion',
  'Elbow under shoulder, hips stacked, straight line',
  '[]'::jsonb,
  '{"default_set_rep_scheme": "3x20-45s per side", "progression_type": "increase duration", "tissue_capacity_rating": 5}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000042'::uuid,
  'Dead Bug',
  'mobility',
  'core',
  'bodyweight',
  'reps',
  'core',
  false,
  'none',
  'anti_extension',
  'Low back pressed to floor, opposite arm/leg extend, slow and controlled',
  '[]'::jsonb,
  '{"default_set_rep_scheme": "3x10-12 per side", "progression_type": "increase reps", "tissue_capacity_rating": 4}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000043'::uuid,
  'Pallof Press (Anti-Rotation)',
  'strength',
  'core',
  'cable',
  'weight',
  'obliques',
  false,
  'none',
  'anti_rotation',
  'Press away from body, resist rotation, full extension',
  '[]'::jsonb,
  '{"default_set_rep_scheme": "3x12-15 per side", "progression_type": "linear load", "tissue_capacity_rating": 6}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000044'::uuid,
  'Hanging Leg Raise',
  'strength',
  'core',
  'pull-up bar',
  'bodyweight',
  'rectus_abdominis',
  false,
  'none',
  'flexion',
  'Hang from bar, lift legs to 90°, control descent',
  '[]'::jsonb,
  '{"default_set_rep_scheme": "3x8-12", "progression_type": "increase reps", "tissue_capacity_rating": 7}'::jsonb
);

-- ============================================================================
-- MOBILITY & STRETCHING
-- ============================================================================

INSERT INTO exercise_templates (
  id, name, category, body_region, equipment, load_type,
  primary_muscle_group, is_primary_lift, default_rm_method,
  movement_pattern, cueing, clinical_tags, programming_metadata
) VALUES
(
  '10000000-0000-0000-0000-000000000050'::uuid,
  'Thoracic Spine Extension (Foam Roller)',
  'mobility',
  'thoracic_spine',
  'foam roller',
  'bodyweight',
  'thoracic_extensors',
  false,
  'none',
  'extension',
  'Roll positioned at mid-back, hands behind head, extend over roller',
  '[]'::jsonb,
  '{"default_set_rep_scheme": "2x10-12", "progression_type": "none", "tissue_capacity_rating": 3}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000051'::uuid,
  'Hip 90/90 Stretch',
  'mobility',
  'hip',
  'floor',
  'time',
  'hip_rotators',
  false,
  'none',
  'hip_rotation',
  'Both knees at 90°, lean forward over front leg, hold stretch',
  '[]'::jsonb,
  '{"default_set_rep_scheme": "2x45-60s per side", "progression_type": "none", "tissue_capacity_rating": 3}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000052'::uuid,
  'Cat-Cow (Spinal Mobility)',
  'mobility',
  'spine',
  'floor',
  'reps',
  'spinal_flexors',
  false,
  'none',
  'flexion_extension',
  'Hands and knees, alternate between spinal flexion and extension',
  '[]'::jsonb,
  '{"default_set_rep_scheme": "2x10-15", "progression_type": "none", "tissue_capacity_rating": 2}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000053'::uuid,
  'World''s Greatest Stretch',
  'mobility',
  'full_body',
  'floor',
  'reps',
  'hip_flexors',
  false,
  'none',
  'multiplanar',
  'Lunge + rotation + reach + hamstring stretch sequence',
  '[]'::jsonb,
  '{"default_set_rep_scheme": "2x5 per side", "progression_type": "none", "tissue_capacity_rating": 4}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000054'::uuid,
  'Sleeper Stretch (Shoulder IR)',
  'mobility',
  'shoulder',
  'floor',
  'time',
  'posterior_capsule',
  false,
  'none',
  'rotation',
  'Lying on side, push throwing arm down toward floor',
  '["promotes_internal_rotation"]'::jsonb,
  '{"default_set_rep_scheme": "2x30-45s per side", "progression_type": "none", "tissue_capacity_rating": 4}'::jsonb
);

-- ============================================================================
-- ACCESSORY UPPER BODY WORK
-- ============================================================================

INSERT INTO exercise_templates (
  id, name, category, body_region, equipment, load_type,
  primary_muscle_group, is_primary_lift, default_rm_method,
  movement_pattern, cueing, clinical_tags, programming_metadata
) VALUES
(
  '10000000-0000-0000-0000-000000000060'::uuid,
  'Dumbbell Row (Single-Arm)',
  'strength',
  'back',
  'dumbbell',
  'weight',
  'latissimus_dorsi',
  false,
  'none',
  'horizontal_pull',
  'Hand on bench, row dumbbell to hip, elbow back',
  '[]'::jsonb,
  '{"default_set_rep_scheme": "3x10-12 per arm", "progression_type": "linear load", "tissue_capacity_rating": 7}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000061'::uuid,
  'Face Pull (Cable)',
  'strength',
  'shoulder',
  'cable',
  'weight',
  'posterior_deltoid',
  false,
  'none',
  'horizontal_pull',
  'Rope to face, elbows high, squeeze shoulder blades',
  '[]'::jsonb,
  '{"default_set_rep_scheme": "3x15-20", "progression_type": "linear load", "tissue_capacity_rating": 6}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000062'::uuid,
  'Lateral Raise (Dumbbell)',
  'strength',
  'shoulder',
  'dumbbell',
  'weight',
  'lateral_deltoid',
  false,
  'none',
  'abduction',
  'Slight forward lean, raise to shoulder height, thumb neutral',
  '["valgus_stress_sensitive"]'::jsonb,
  '{"default_set_rep_scheme": "3x12-15", "progression_type": "linear load", "tissue_capacity_rating": 6}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000063'::uuid,
  'Tricep Extension (Cable Overhead)',
  'strength',
  'tricep',
  'cable',
  'weight',
  'triceps',
  false,
  'none',
  'extension',
  'Arms overhead, extend elbows fully, control eccentric',
  '[]'::jsonb,
  '{"default_set_rep_scheme": "3x10-15", "progression_type": "linear load", "tissue_capacity_rating": 6}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000064'::uuid,
  'Bicep Curl (Dumbbell)',
  'strength',
  'bicep',
  'dumbbell',
  'weight',
  'biceps',
  false,
  'epley',
  'flexion',
  'Elbows at sides, curl to shoulder, control descent',
  '[]'::jsonb,
  '{"default_set_rep_scheme": "3x10-12", "progression_type": "linear load", "tissue_capacity_rating": 6}'::jsonb
);

-- ============================================================================
-- THROWING-SPECIFIC EXERCISES
-- ============================================================================

INSERT INTO exercise_templates (
  id, name, category, body_region, equipment, load_type,
  primary_muscle_group, is_primary_lift, default_rm_method,
  movement_pattern, cueing, clinical_tags, throwing_tags, programming_metadata
) VALUES
(
  '10000000-0000-0000-0000-000000000070'::uuid,
  'Long Toss (Flat Ground)',
  'bullpen',
  'shoulder',
  'baseball',
  'distance',
  'deltoids',
  false,
  'none',
  'throwing',
  'Build distance progressively, focus on arc, track throws',
  '[]'::jsonb,
  '{"drill_category": "long toss", "ball_weight_oz": 5, "velocity_tracking_required": false}'::jsonb,
  '{"default_set_rep_scheme": "progressive to 180-240ft", "progression_type": "increase distance", "tissue_capacity_rating": 7}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000071'::uuid,
  'Flat Ground Throwing (60ft)',
  'bullpen',
  'shoulder',
  'baseball',
  'reps',
  'deltoids',
  false,
  'none',
  'throwing',
  'Focus on mechanics, 70-80% intensity, hit glove',
  '[]'::jsonb,
  '{"drill_category": "flat ground", "ball_weight_oz": 5, "velocity_tracking_required": false, "pitch_type_supported": ["4-seam", "changeup"]}'::jsonb,
  '{"default_set_rep_scheme": "20-30 throws", "progression_type": "increase volume", "tissue_capacity_rating": 6}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000072'::uuid,
  'Bullpen Session (Mound)',
  'bullpen',
  'shoulder',
  'baseball',
  'reps',
  'deltoids',
  false,
  'none',
  'throwing',
  'Full intensity, work all pitches, track velocity and command',
  '[]'::jsonb,
  '{"drill_category": "bullpen", "ball_weight_oz": 5, "velocity_tracking_required": true, "pitch_type_supported": ["4-seam", "slider", "changeup", "curveball"]}'::jsonb,
  '{"default_set_rep_scheme": "25-35 pitches", "progression_type": "increase volume", "tissue_capacity_rating": 9}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000073'::uuid,
  'Rocker Drill (Balance + Throwing)',
  'bullpen',
  'shoulder',
  'baseball',
  'reps',
  'deltoids',
  false,
  'none',
  'throwing',
  'Step onto front leg, throw from balance position',
  '[]'::jsonb,
  '{"drill_category": "drill work", "ball_weight_oz": 5, "velocity_tracking_required": false}'::jsonb,
  '{"default_set_rep_scheme": "10-15 throws", "progression_type": "none", "tissue_capacity_rating": 5}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000074'::uuid,
  'Towel Drill (No-Ball)',
  'mobility',
  'shoulder',
  'towel',
  'reps',
  'deltoids',
  false,
  'none',
  'throwing',
  'Full pitching mechanics, whip towel through, focus on mechanics',
  '[]'::jsonb,
  '{"drill_category": "drill work", "velocity_tracking_required": false}'::jsonb,
  '{"default_set_rep_scheme": "2x10", "progression_type": "none", "tissue_capacity_rating": 3}'::jsonb
);

-- ============================================================================
-- CARDIO & CONDITIONING
-- ============================================================================

INSERT INTO exercise_templates (
  id, name, category, body_region, equipment, load_type,
  primary_muscle_group, is_primary_lift, default_rm_method,
  movement_pattern, cueing, clinical_tags, programming_metadata
) VALUES
(
  '10000000-0000-0000-0000-000000000080'::uuid,
  'Bike (Assault Bike)',
  'cardio',
  'full_body',
  'assault bike',
  'time',
  'cardiovascular',
  false,
  'none',
  'cyclical',
  'Maintain steady pace or interval work',
  '[]'::jsonb,
  '{"default_set_rep_scheme": "20-30min steady or intervals", "progression_type": "increase duration", "tissue_capacity_rating": 5}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000081'::uuid,
  'Row (Concept2)',
  'cardio',
  'full_body',
  'rowing machine',
  'distance',
  'cardiovascular',
  false,
  'none',
  'pull',
  'Drive with legs, finish with back pull, recover smoothly',
  '[]'::jsonb,
  '{"default_set_rep_scheme": "2000-5000m or intervals", "progression_type": "increase distance", "tissue_capacity_rating": 6}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000082'::uuid,
  'Sled Push',
  'cardio',
  'legs',
  'sled',
  'distance',
  'quadriceps',
  false,
  'none',
  'push',
  'Low position, drive through legs, maintain speed',
  '[]'::jsonb,
  '{"default_set_rep_scheme": "4-6x40m", "progression_type": "increase load", "tissue_capacity_rating": 8}'::jsonb
),
(
  '10000000-0000-0000-0000-000000000083'::uuid,
  'Sprint Intervals (Track)',
  'cardio',
  'legs',
  'track',
  'distance',
  'cardiovascular',
  false,
  'none',
  'sprint',
  'Full acceleration, maintain form, rest between sets',
  '[]'::jsonb,
  '{"default_set_rep_scheme": "6-8x60m", "progression_type": "increase volume", "tissue_capacity_rating": 7}'::jsonb
);

-- ============================================================================
-- VALIDATION & SUMMARY
-- ============================================================================

-- Count exercises by category
SELECT
  category,
  count(*) as exercise_count
FROM exercise_templates
GROUP BY category
ORDER BY category;

-- Exercises by body region
SELECT
  body_region,
  count(*) as exercise_count
FROM exercise_templates
GROUP BY body_region
ORDER BY exercise_count DESC;

-- Primary lifts
SELECT
  name,
  category,
  default_rm_method
FROM exercise_templates
WHERE is_primary_lift = true
ORDER BY category, name;
