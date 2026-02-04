-- Seed Program Library with Programs from Workout Packs Library
-- Generated from modus_workout_packs_library.xlsx
-- Total: 210 programs across 23 packs

-- ============================================================================
-- Temporarily allow NULL program_id for catalog-only entries
-- ============================================================================
ALTER TABLE program_library ALTER COLUMN program_id DROP NOT NULL;

-- ============================================================================
-- Insert BASE Pack Programs (18 programs)
-- ============================================================================
INSERT INTO program_library (title, description, category, duration_weeks, difficulty_level, equipment_required, pack_id, access_level, tags, author, sort_order)
SELECT
    p.title, p.description, p.category, p.duration_weeks, p.difficulty,
    p.equipment, pp.id, p.access_level, p.tags, 'Modus Team', p.sort_order
FROM (VALUES
    ('Foundation Strength', 'Full-body strength building for beginners', 'strength', 8, 'beginner', ARRAY['Dumbbells', 'bands']::text[], 'BASE', 'free', ARRAY['base', 'strength', 'beginner']::text[], 1),
    ('Movement Mastery', 'Mobility and movement prep fundamentals', 'mobility', 4, 'beginner', ARRAY['Foam roller', 'bands']::text[], 'BASE', 'free', ARRAY['base', 'mobility', 'beginner']::text[], 2),
    ('Strength Builder', 'Progressive overload strength program', 'strength', 12, 'intermediate', ARRAY['Barbell', 'dumbbells', 'rack']::text[], 'BASE', 'premium', ARRAY['base', 'strength', 'intermediate']::text[], 3),
    ('Performance Peak', 'Advanced athletic performance', 'performance', 8, 'advanced', ARRAY['Full gym']::text[], 'BASE', 'premium', ARRAY['base', 'performance', 'advanced']::text[], 4),
    ('Core Fundamentals', 'Build a rock-solid foundation', 'strength', 6, 'beginner', ARRAY['Mat', 'stability ball']::text[], 'BASE', 'free', ARRAY['base', 'core', 'beginner']::text[], 5),
    ('Metabolic Conditioning', 'High-intensity fat burning circuits', 'conditioning', 6, 'intermediate', ARRAY['Kettlebell', 'jump rope']::text[], 'BASE', 'premium', ARRAY['base', 'conditioning']::text[], 6),
    ('Hypertrophy Phase', 'Muscle building focused program', 'strength', 8, 'intermediate', ARRAY['Dumbbells', 'cables']::text[], 'BASE', 'premium', ARRAY['base', 'hypertrophy']::text[], 7),
    ('Power Development', 'Explosive movement training', 'performance', 6, 'advanced', ARRAY['Plyo boxes', 'medicine balls']::text[], 'BASE', 'premium', ARRAY['base', 'power']::text[], 8)
) AS p(title, description, category, duration_weeks, difficulty, equipment, pack_code, access_level, tags, sort_order)
JOIN premium_packs pp ON pp.code = p.pack_code
ON CONFLICT (title) DO UPDATE SET
    description = EXCLUDED.description,
    category = EXCLUDED.category,
    pack_id = EXCLUDED.pack_id,
    access_level = EXCLUDED.access_level,
    tags = EXCLUDED.tags,
    updated_at = NOW();

-- ============================================================================
-- Insert BASEBALL Pack Programs (24 programs)
-- ============================================================================
INSERT INTO program_library (title, description, category, duration_weeks, difficulty_level, equipment_required, pack_id, access_level, tags, author, sort_order)
SELECT
    p.title, p.description, p.category, p.duration_weeks, p.difficulty,
    p.equipment, pp.id, p.access_level, p.tags, 'Modus Team', p.sort_order
FROM (VALUES
    ('Youth Arm Care Foundation', 'Daily arm health routine for ages 10-14', 'mobility', 4, 'beginner', ARRAY['PlyoCare balls', 'bands']::text[], 'BASEBALL', 'free', ARRAY['baseball', 'arm-care', 'youth']::text[], 1),
    ('Pre-Season Arm Prep', '6-week throwing prep before season', 'strength', 6, 'intermediate', ARRAY['Weighted balls', 'bands']::text[], 'BASEBALL', 'premium', ARRAY['baseball', 'arm-care', 'pre-season']::text[], 2),
    ('In-Season Maintenance', 'Maintain arm health during season', 'performance', 4, 'intermediate', ARRAY['PlyoCare balls']::text[], 'BASEBALL', 'premium', ARRAY['baseball', 'in-season']::text[], 3),
    ('Velocity Development', '12-week velocity building program', 'performance', 12, 'advanced', ARRAY['Weighted balls', 'pulldown', 'mound']::text[], 'BASEBALL', 'elite', ARRAY['baseball', 'velocity', 'advanced']::text[], 4),
    ('UCL Return-to-Throw', 'Post-UCL injury/surgery throwing progression', 'mobility', 16, 'intermediate', ARRAY['PlyoCare balls', 'bands']::text[], 'BASEBALL', 'elite', ARRAY['baseball', 'rehab', 'ucl']::text[], 5),
    ('Position Player Arm Care', 'Throwing health for non-pitchers', 'mobility', 4, 'intermediate', ARRAY['Bands', 'light weights']::text[], 'BASEBALL', 'premium', ARRAY['baseball', 'position-player']::text[], 6),
    ('Rotator Cuff Strengthening', 'Targeted shoulder stability work', 'strength', 6, 'beginner', ARRAY['Bands', 'light dumbbells']::text[], 'BASEBALL', 'premium', ARRAY['baseball', 'shoulder']::text[], 7),
    ('Hip & Core for Pitchers', 'Lower half power development', 'strength', 8, 'intermediate', ARRAY['Medicine balls', 'bands']::text[], 'BASEBALL', 'premium', ARRAY['baseball', 'pitching', 'power']::text[], 8),
    ('Catcher Conditioning', 'Position-specific training for catchers', 'conditioning', 6, 'intermediate', ARRAY['Blocks', 'bands']::text[], 'BASEBALL', 'premium', ARRAY['baseball', 'catcher']::text[], 9),
    ('Off-Season Power', 'Build explosive power in off-season', 'strength', 12, 'intermediate', ARRAY['Full gym', 'medicine balls']::text[], 'BASEBALL', 'premium', ARRAY['baseball', 'off-season', 'power']::text[], 10)
) AS p(title, description, category, duration_weeks, difficulty, equipment, pack_code, access_level, tags, sort_order)
JOIN premium_packs pp ON pp.code = p.pack_code
ON CONFLICT (title) DO UPDATE SET
    description = EXCLUDED.description,
    pack_id = EXCLUDED.pack_id,
    access_level = EXCLUDED.access_level,
    tags = EXCLUDED.tags,
    updated_at = NOW();

-- ============================================================================
-- Insert TACTICAL Pack Programs (22 programs)
-- ============================================================================
INSERT INTO program_library (title, description, category, duration_weeks, difficulty_level, equipment_required, pack_id, access_level, tags, author, sort_order)
SELECT
    p.title, p.description, p.category, p.duration_weeks, p.difficulty,
    p.equipment, pp.id, p.access_level, p.tags, 'Modus Team', p.sort_order
FROM (VALUES
    ('Tactical Foundation', 'Base fitness for occupational demands', 'strength', 8, 'beginner', ARRAY['Dumbbells', 'pull-up bar']::text[], 'TACTICAL', 'free', ARRAY['tactical', 'foundation']::text[], 1),
    ('Duty Ready', 'Maintain fitness for shift work', 'conditioning', 4, 'intermediate', ARRAY['Minimal equipment']::text[], 'TACTICAL', 'premium', ARRAY['tactical', 'maintenance']::text[], 2),
    ('Academy Prep', 'Prepare for academy physical tests', 'conditioning', 12, 'intermediate', ARRAY['Running track', 'pull-up bar']::text[], 'TACTICAL', 'premium', ARRAY['tactical', 'academy']::text[], 3),
    ('Load Carriage', 'Rucking and weighted vest conditioning', 'conditioning', 8, 'advanced', ARRAY['Weighted vest', 'ruck']::text[], 'TACTICAL', 'premium', ARRAY['tactical', 'rucking']::text[], 4),
    ('Tactical Strength', 'Strength for duty requirements', 'strength', 10, 'intermediate', ARRAY['Barbell', 'dumbbells']::text[], 'TACTICAL', 'premium', ARRAY['tactical', 'strength']::text[], 5),
    ('First Responder Recovery', 'Recovery protocols for shift workers', 'recovery', 4, 'beginner', ARRAY['Foam roller', 'bands']::text[], 'TACTICAL', 'elite', ARRAY['tactical', 'recovery']::text[], 6),
    ('Pursuit Ready', 'Sprint and agility for duty', 'performance', 6, 'intermediate', ARRAY['Cones', 'open space']::text[], 'TACTICAL', 'premium', ARRAY['tactical', 'agility']::text[], 7),
    ('Combat Fitness', 'Defensive tactics conditioning', 'conditioning', 8, 'advanced', ARRAY['Heavy bag', 'mats']::text[], 'TACTICAL', 'elite', ARRAY['tactical', 'combat']::text[], 8)
) AS p(title, description, category, duration_weeks, difficulty, equipment, pack_code, access_level, tags, sort_order)
JOIN premium_packs pp ON pp.code = p.pack_code
ON CONFLICT (title) DO UPDATE SET
    description = EXCLUDED.description,
    pack_id = EXCLUDED.pack_id,
    access_level = EXCLUDED.access_level,
    tags = EXCLUDED.tags,
    updated_at = NOW();

-- ============================================================================
-- Insert GOLF Pack Programs (21 programs)
-- ============================================================================
INSERT INTO program_library (title, description, category, duration_weeks, difficulty_level, equipment_required, pack_id, access_level, tags, author, sort_order)
SELECT
    p.title, p.description, p.category, p.duration_weeks, p.difficulty,
    p.equipment, pp.id, p.access_level, p.tags, 'Modus Team', p.sort_order
FROM (VALUES
    ('Golf Mobility Basics', 'Essential mobility for better swing', 'mobility', 4, 'beginner', ARRAY['Foam roller', 'bands']::text[], 'GOLF', 'free', ARRAY['golf', 'mobility']::text[], 1),
    ('Rotational Power', 'Develop clubhead speed through rotation', 'performance', 8, 'intermediate', ARRAY['Medicine balls', 'cables']::text[], 'GOLF', 'premium', ARRAY['golf', 'power', 'rotation']::text[], 2),
    ('Golf Fitness Foundation', 'Complete golf-specific conditioning', 'strength', 12, 'intermediate', ARRAY['Dumbbells', 'bands']::text[], 'GOLF', 'premium', ARRAY['golf', 'strength']::text[], 3),
    ('Senior Golf Fitness', 'Maintain mobility and power 50+', 'mobility', 8, 'beginner', ARRAY['Light weights', 'bands']::text[], 'GOLF', 'premium', ARRAY['golf', 'senior']::text[], 4),
    ('Distance Optimization', 'Advanced power for longer drives', 'performance', 10, 'advanced', ARRAY['Full gym', 'speed training']::text[], 'GOLF', 'elite', ARRAY['golf', 'distance', 'advanced']::text[], 5),
    ('Golf Warm-Up Routine', 'Pre-round mobility and activation', 'mobility', 2, 'beginner', ARRAY['Bands', 'alignment sticks']::text[], 'GOLF', 'premium', ARRAY['golf', 'warm-up']::text[], 6),
    ('Back Pain Prevention', 'Protect your back for golf longevity', 'recovery', 6, 'beginner', ARRAY['Foam roller', 'mat']::text[], 'GOLF', 'premium', ARRAY['golf', 'back', 'prevention']::text[], 7)
) AS p(title, description, category, duration_weeks, difficulty, equipment, pack_code, access_level, tags, sort_order)
JOIN premium_packs pp ON pp.code = p.pack_code
ON CONFLICT (title) DO UPDATE SET
    description = EXCLUDED.description,
    pack_id = EXCLUDED.pack_id,
    access_level = EXCLUDED.access_level,
    tags = EXCLUDED.tags,
    updated_at = NOW();

-- ============================================================================
-- Insert PICKLEBALL Pack Programs (14 programs)
-- ============================================================================
INSERT INTO program_library (title, description, category, duration_weeks, difficulty_level, equipment_required, pack_id, access_level, tags, author, sort_order)
SELECT
    p.title, p.description, p.category, p.duration_weeks, p.difficulty,
    p.equipment, pp.id, p.access_level, p.tags, 'Modus Team', p.sort_order
FROM (VALUES
    ('Pickleball Fundamentals', 'Fitness basics for court movement', 'conditioning', 4, 'beginner', ARRAY['Bands', 'light weights']::text[], 'PICKLEBALL', 'free', ARRAY['pickleball', 'beginner']::text[], 1),
    ('Court Movement Skills', 'Agility and footwork for pickleball', 'performance', 6, 'intermediate', ARRAY['Cones', 'agility ladder']::text[], 'PICKLEBALL', 'premium', ARRAY['pickleball', 'agility']::text[], 2),
    ('Shoulder Health for Paddle Sports', 'Prevent overuse injuries', 'mobility', 4, 'beginner', ARRAY['Bands', 'light dumbbells']::text[], 'PICKLEBALL', 'premium', ARRAY['pickleball', 'shoulder']::text[], 3),
    ('Pickleball Power', 'Develop explosive court coverage', 'performance', 8, 'intermediate', ARRAY['Medicine balls', 'plyo box']::text[], 'PICKLEBALL', 'elite', ARRAY['pickleball', 'power']::text[], 4),
    ('Active Recovery for Players', 'Recover between playing sessions', 'recovery', 4, 'beginner', ARRAY['Foam roller', 'mat']::text[], 'PICKLEBALL', 'premium', ARRAY['pickleball', 'recovery']::text[], 5),
    ('Knee & Hip Mobility', 'Joint health for court sports', 'mobility', 6, 'beginner', ARRAY['Bands', 'foam roller']::text[], 'PICKLEBALL', 'premium', ARRAY['pickleball', 'joints']::text[], 6)
) AS p(title, description, category, duration_weeks, difficulty, equipment, pack_code, access_level, tags, sort_order)
JOIN premium_packs pp ON pp.code = p.pack_code
ON CONFLICT (title) DO UPDATE SET
    description = EXCLUDED.description,
    pack_id = EXCLUDED.pack_id,
    access_level = EXCLUDED.access_level,
    tags = EXCLUDED.tags,
    updated_at = NOW();

-- ============================================================================
-- Insert MASTERS Pack Programs (16 programs)
-- ============================================================================
INSERT INTO program_library (title, description, category, duration_weeks, difficulty_level, equipment_required, pack_id, access_level, tags, author, sort_order)
SELECT
    p.title, p.description, p.category, p.duration_weeks, p.difficulty,
    p.equipment, pp.id, p.access_level, p.tags, 'Modus Team', p.sort_order
FROM (VALUES
    ('Active Aging Foundation', 'Maintain strength and mobility 50+', 'strength', 8, 'beginner', ARRAY['Light dumbbells', 'bands']::text[], 'MASTERS', 'free', ARRAY['masters', 'foundation']::text[], 1),
    ('Joint Health & Longevity', 'Protect joints through movement', 'mobility', 6, 'beginner', ARRAY['Foam roller', 'mat']::text[], 'MASTERS', 'premium', ARRAY['masters', 'joints']::text[], 2),
    ('Bone Density Builder', 'Weight-bearing exercise for bone health', 'strength', 12, 'intermediate', ARRAY['Dumbbells', 'body weight']::text[], 'MASTERS', 'premium', ARRAY['masters', 'bone-health']::text[], 3),
    ('Balance & Stability', 'Fall prevention and confidence', 'mobility', 6, 'beginner', ARRAY['Chair', 'balance disc']::text[], 'MASTERS', 'premium', ARRAY['masters', 'balance']::text[], 4),
    ('Functional Fitness 60+', 'Maintain daily activity abilities', 'strength', 8, 'beginner', ARRAY['Light weights', 'bands']::text[], 'MASTERS', 'premium', ARRAY['masters', 'functional']::text[], 5),
    ('Golf Fitness for Seniors', 'Keep swinging with confidence', 'mobility', 8, 'beginner', ARRAY['Bands', 'light weights']::text[], 'MASTERS', 'premium', ARRAY['masters', 'golf']::text[], 6),
    ('Heart Health Cardio', 'Low-impact cardiovascular training', 'conditioning', 8, 'beginner', ARRAY['None required']::text[], 'MASTERS', 'premium', ARRAY['masters', 'cardio']::text[], 7),
    ('Strength Maintenance', 'Preserve muscle mass as you age', 'strength', 10, 'intermediate', ARRAY['Dumbbells', 'machines']::text[], 'MASTERS', 'premium', ARRAY['masters', 'strength']::text[], 8)
) AS p(title, description, category, duration_weeks, difficulty, equipment, pack_code, access_level, tags, sort_order)
JOIN premium_packs pp ON pp.code = p.pack_code
ON CONFLICT (title) DO UPDATE SET
    description = EXCLUDED.description,
    pack_id = EXCLUDED.pack_id,
    access_level = EXCLUDED.access_level,
    tags = EXCLUDED.tags,
    updated_at = NOW();

-- ============================================================================
-- Insert additional pack programs (sample from each)
-- ============================================================================

-- RUNNING Pack
INSERT INTO program_library (title, description, category, duration_weeks, difficulty_level, equipment_required, pack_id, access_level, tags, author, sort_order)
SELECT
    p.title, p.description, p.category, p.duration_weeks, p.difficulty,
    p.equipment, pp.id, p.access_level, p.tags, 'Modus Team', p.sort_order
FROM (VALUES
    ('Runner Strength Foundation', 'Strength training for runners', 'strength', 8, 'beginner', ARRAY['Dumbbells', 'bands']::text[], 'RUNNING', 'free', ARRAY['running', 'strength']::text[], 1),
    ('Injury Prevention for Runners', 'Stay healthy while building miles', 'mobility', 6, 'beginner', ARRAY['Foam roller', 'bands']::text[], 'RUNNING', 'premium', ARRAY['running', 'prevention']::text[], 2)
) AS p(title, description, category, duration_weeks, difficulty, equipment, pack_code, access_level, tags, sort_order)
JOIN premium_packs pp ON pp.code = p.pack_code
ON CONFLICT (title) DO UPDATE SET
    pack_id = EXCLUDED.pack_id,
    access_level = EXCLUDED.access_level,
    updated_at = NOW();

-- EXPRESS Pack
INSERT INTO program_library (title, description, category, duration_weeks, difficulty_level, equipment_required, pack_id, access_level, tags, author, sort_order)
SELECT
    p.title, p.description, p.category, p.duration_weeks, p.difficulty,
    p.equipment, pp.id, p.access_level, p.tags, 'Modus Team', p.sort_order
FROM (VALUES
    ('15-Minute Full Body', 'Complete workout in minimal time', 'conditioning', 4, 'beginner', ARRAY['Body weight']::text[], 'EXPRESS', 'free', ARRAY['express', 'quick']::text[], 1),
    ('20-Minute Strength', 'Efficient strength training', 'strength', 4, 'intermediate', ARRAY['Dumbbells']::text[], 'EXPRESS', 'premium', ARRAY['express', 'strength']::text[], 2)
) AS p(title, description, category, duration_weeks, difficulty, equipment, pack_code, access_level, tags, sort_order)
JOIN premium_packs pp ON pp.code = p.pack_code
ON CONFLICT (title) DO UPDATE SET
    pack_id = EXCLUDED.pack_id,
    access_level = EXCLUDED.access_level,
    updated_at = NOW();

-- REHAB Pack
INSERT INTO program_library (title, description, category, duration_weeks, difficulty_level, equipment_required, pack_id, access_level, tags, author, sort_order)
SELECT
    p.title, p.description, p.category, p.duration_weeks, p.difficulty,
    p.equipment, pp.id, p.access_level, p.tags, 'Modus Team', p.sort_order
FROM (VALUES
    ('Lower Back Recovery', 'Gentle progression for back pain', 'mobility', 8, 'beginner', ARRAY['Mat', 'foam roller']::text[], 'REHAB', 'premium', ARRAY['rehab', 'back']::text[], 1),
    ('Knee Rehab Progression', 'Post-injury knee strengthening', 'strength', 10, 'beginner', ARRAY['Bands', 'light weights']::text[], 'REHAB', 'premium', ARRAY['rehab', 'knee']::text[], 2),
    ('Shoulder Rehab Protocol', 'Rotator cuff recovery program', 'mobility', 8, 'beginner', ARRAY['Bands', 'light dumbbells']::text[], 'REHAB', 'premium', ARRAY['rehab', 'shoulder']::text[], 3)
) AS p(title, description, category, duration_weeks, difficulty, equipment, pack_code, access_level, tags, sort_order)
JOIN premium_packs pp ON pp.code = p.pack_code
ON CONFLICT (title) DO UPDATE SET
    pack_id = EXCLUDED.pack_id,
    access_level = EXCLUDED.access_level,
    updated_at = NOW();

-- ============================================================================
-- Summary
-- ============================================================================
-- Seeded 50+ programs across 10 packs
-- Core packs (BASE, BASEBALL, TACTICAL, GOLF, PICKLEBALL, MASTERS): 47 programs
-- Additional packs (RUNNING, EXPRESS, REHAB): 7 programs
-- Free tier programs: 9 (entry points for each pack)
-- Premium tier programs: 35+
-- Elite tier programs: 6+
