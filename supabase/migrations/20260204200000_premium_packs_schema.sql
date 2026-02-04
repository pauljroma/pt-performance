-- Premium Packs Schema Enhancement
-- Adds pack-based organization, access levels, and pricing to program library

-- ============================================================================
-- 1. Premium Packs Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS premium_packs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT NOT NULL UNIQUE, -- 'BASE', 'BASEBALL', 'TACTICAL', 'GOLF', 'PICKLEBALL', 'MASTERS'
    name TEXT NOT NULL,
    description TEXT,
    icon_name TEXT, -- SF Symbol name for iOS
    cover_image_url TEXT,
    base_price_monthly DECIMAL(10,2), -- Monthly subscription price
    bundle_price_monthly DECIMAL(10,2), -- Discounted price when bundled
    is_addon BOOLEAN DEFAULT false, -- true = requires BASE pack
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_premium_packs_code ON premium_packs(code);
CREATE INDEX IF NOT EXISTS idx_premium_packs_active ON premium_packs(is_active) WHERE is_active = true;

COMMENT ON TABLE premium_packs IS 'Premium content packs for grouping programs (BASE, BASEBALL, TACTICAL, etc.)';
COMMENT ON COLUMN premium_packs.code IS 'Unique identifier code for pack (BASE, BASEBALL, etc.)';
COMMENT ON COLUMN premium_packs.is_addon IS 'If true, requires BASE pack subscription';

-- ============================================================================
-- 2. Enhance Program Library with Pack and Access Level
-- ============================================================================

-- Add pack reference and access level to program_library
ALTER TABLE program_library
    ADD COLUMN IF NOT EXISTS pack_id UUID REFERENCES premium_packs(id),
    ADD COLUMN IF NOT EXISTS access_level TEXT DEFAULT 'free'
        CHECK (access_level IN ('free', 'premium', 'elite')),
    ADD COLUMN IF NOT EXISTS sort_order INT DEFAULT 0,
    ADD COLUMN IF NOT EXISTS preview_video_url TEXT,
    ADD COLUMN IF NOT EXISTS requires_equipment BOOLEAN DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_program_library_pack ON program_library(pack_id);
CREATE INDEX IF NOT EXISTS idx_program_library_access ON program_library(access_level);

COMMENT ON COLUMN program_library.pack_id IS 'Reference to premium pack this program belongs to';
COMMENT ON COLUMN program_library.access_level IS 'Content access tier: free (all users), premium (BASE subscribers), elite (specific pack)';

-- ============================================================================
-- 3. User Pack Subscriptions Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_pack_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL, -- References auth.users
    pack_id UUID NOT NULL REFERENCES premium_packs(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'expired', 'trial')),
    started_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    stripe_subscription_id TEXT, -- For payment integration
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, pack_id)
);

CREATE INDEX IF NOT EXISTS idx_user_pack_subscriptions_user ON user_pack_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_pack_subscriptions_status ON user_pack_subscriptions(status) WHERE status = 'active';

COMMENT ON TABLE user_pack_subscriptions IS 'Track user subscriptions to premium packs';

-- ============================================================================
-- 4. Row Level Security for New Tables
-- ============================================================================

ALTER TABLE premium_packs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_pack_subscriptions ENABLE ROW LEVEL SECURITY;

-- Premium packs: Public read access
CREATE POLICY "Anyone can view premium packs"
    ON premium_packs FOR SELECT
    USING (true);

-- User subscriptions: Users can view/manage their own
CREATE POLICY "Users can view own subscriptions"
    ON user_pack_subscriptions FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can insert own subscriptions"
    ON user_pack_subscriptions FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own subscriptions"
    ON user_pack_subscriptions FOR UPDATE
    USING (user_id = auth.uid());

-- ============================================================================
-- 5. Seed Premium Packs (All 23 packs from workout library)
-- ============================================================================

INSERT INTO premium_packs (code, name, description, icon_name, base_price_monthly, bundle_price_monthly, is_addon, sort_order) VALUES
    -- Core Packs (1-6)
    ('BASE', 'Modus Base', 'Complete strength and conditioning foundation with periodized programs, mobility work, and recovery protocols.', 'figure.strengthtraining.traditional', 29.00, NULL, false, 1),
    ('BASEBALL', 'Baseball Performance', 'Position-specific training for pitchers, catchers, and position players. Velocity development, arm care, and in-season maintenance.', 'baseball.fill', 10.00, 35.00, true, 2),
    ('TACTICAL', 'Tactical Athlete', 'Military, law enforcement, and first responder specific conditioning. Rucking, occupational fitness, and mission-ready protocols.', 'shield.fill', 15.00, 40.00, true, 3),
    ('GOLF', 'Golf Performance', 'Rotational power, flexibility, and golf-specific conditioning. Improve swing mechanics through better movement patterns.', 'figure.golf', 10.00, 35.00, true, 4),
    ('PICKLEBALL', 'Pickleball Performance', 'Court movement, quick reaction training, and injury prevention for pickleball athletes of all ages.', 'sportscourt.fill', 10.00, 35.00, true, 5),
    ('MASTERS', 'Masters Performance', 'Age-optimized training for athletes 50+. Joint health, strength maintenance, and longevity-focused programming.', 'heart.fill', 15.00, 40.00, true, 6),
    -- Sport Packs (10-18)
    ('BASKETBALL', 'Basketball Performance', 'Court-specific conditioning for basketball athletes.', 'basketball.fill', 10.00, 35.00, true, 10),
    ('CROSSFIT', 'CrossFit Supplemental', 'Supplemental programming for CrossFit athletes.', 'figure.cross.training', 10.00, 35.00, true, 11),
    ('RUNNING', 'Running Performance', 'Strength and conditioning for runners.', 'figure.run', 10.00, 35.00, true, 15),
    ('TENNIS', 'Tennis Performance', 'Court movement and power for tennis players.', 'figure.tennis', 10.00, 35.00, true, 16),
    ('SOCCER', 'Soccer Performance', 'Field conditioning for soccer athletes.', 'soccerball', 10.00, 35.00, true, 17),
    ('SWIMMING', 'Swimming Performance', 'Dryland training for swimmers.', 'figure.pool.swim', 10.00, 35.00, true, 18),
    -- Lifestyle Packs (12-14, 25-27)
    ('DESK', 'Desk Athlete', 'Combat the effects of desk work with targeted mobility.', 'desktopcomputer', 5.00, 30.00, true, 12),
    ('EXPRESS', 'Express Workouts', 'Efficient 15-20 minute workouts for busy schedules.', 'timer', 5.00, 30.00, true, 13),
    ('GOALS', 'Goal-Specific', 'Programs designed for specific fitness goals.', 'target', 10.00, 35.00, true, 14),
    ('PARENT', 'Parent Fitness', 'Fitness for busy parents.', 'figure.2.and.child.holdinghands', 5.00, 30.00, true, 25),
    ('TRAVEL', 'Travel Workouts', 'Equipment-free workouts for travelers.', 'airplane', 5.00, 30.00, true, 26),
    ('SHIFT', 'Shift Worker', 'Programs optimized for irregular schedules.', 'moon.fill', 5.00, 30.00, true, 27),
    -- Specialty Packs (20-24)
    ('REHAB', 'Rehab Programs', 'Injury recovery and prevention protocols.', 'bandage.fill', 15.00, 40.00, true, 20),
    ('PRENATAL', 'Prenatal Fitness', 'Safe, effective workouts during pregnancy.', 'figure.and.child.holdinghands', 15.00, 40.00, true, 21),
    ('POSTPARTUM', 'Postpartum Recovery', 'Recovery and rebuilding after childbirth.', 'figure.walk', 15.00, 40.00, true, 22),
    ('YOUTH12', 'Youth Athletes (8-12)', 'Age-appropriate training for young athletes.', 'figure.strengthtraining.traditional', 10.00, 35.00, true, 23),
    ('YOUTH16', 'Youth Athletes (13-16)', 'Development training for teenage athletes.', 'figure.strengthtraining.traditional', 10.00, 35.00, true, 24)
ON CONFLICT (code) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    icon_name = EXCLUDED.icon_name,
    base_price_monthly = EXCLUDED.base_price_monthly,
    bundle_price_monthly = EXCLUDED.bundle_price_monthly,
    is_addon = EXCLUDED.is_addon,
    sort_order = EXCLUDED.sort_order,
    updated_at = NOW();

-- ============================================================================
-- 6. Enhanced Search Function with Access Level
-- ============================================================================

CREATE OR REPLACE FUNCTION search_program_library_v2(
    p_query TEXT DEFAULT NULL,
    p_category TEXT DEFAULT NULL,
    p_difficulty TEXT DEFAULT NULL,
    p_tags TEXT[] DEFAULT NULL,
    p_pack_code TEXT DEFAULT NULL,
    p_access_level TEXT DEFAULT NULL,
    p_user_id UUID DEFAULT NULL,
    p_limit INT DEFAULT 20
)
RETURNS TABLE (
    id UUID,
    title TEXT,
    description TEXT,
    category TEXT,
    duration_weeks INT,
    difficulty_level TEXT,
    equipment_required TEXT[],
    cover_image_url TEXT,
    is_featured BOOLEAN,
    tags TEXT[],
    pack_code TEXT,
    pack_name TEXT,
    access_level TEXT,
    is_accessible BOOLEAN,
    enrollment_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        pl.id,
        pl.title,
        pl.description,
        pl.category,
        pl.duration_weeks,
        pl.difficulty_level,
        pl.equipment_required,
        pl.cover_image_url,
        pl.is_featured,
        pl.tags,
        pp.code AS pack_code,
        pp.name AS pack_name,
        pl.access_level,
        -- Check if user has access based on subscription
        CASE
            WHEN pl.access_level = 'free' THEN true
            WHEN p_user_id IS NULL THEN false
            WHEN pl.access_level = 'premium' THEN EXISTS (
                SELECT 1 FROM user_pack_subscriptions ups
                WHERE ups.user_id = p_user_id
                AND ups.pack_id = (SELECT id FROM premium_packs WHERE code = 'BASE')
                AND ups.status = 'active'
            )
            WHEN pl.access_level = 'elite' THEN EXISTS (
                SELECT 1 FROM user_pack_subscriptions ups
                WHERE ups.user_id = p_user_id
                AND ups.pack_id = pl.pack_id
                AND ups.status = 'active'
            )
            ELSE false
        END AS is_accessible,
        COUNT(pe.id) AS enrollment_count
    FROM program_library pl
    LEFT JOIN premium_packs pp ON pp.id = pl.pack_id
    LEFT JOIN program_enrollments pe ON pe.program_library_id = pl.id
    WHERE
        (p_query IS NULL OR pl.title ILIKE '%' || p_query || '%' OR pl.description ILIKE '%' || p_query || '%')
        AND (p_category IS NULL OR pl.category = p_category)
        AND (p_difficulty IS NULL OR pl.difficulty_level = p_difficulty)
        AND (p_tags IS NULL OR pl.tags && p_tags)
        AND (p_pack_code IS NULL OR pp.code = p_pack_code)
        AND (p_access_level IS NULL OR pl.access_level = p_access_level)
    GROUP BY pl.id, pp.code, pp.name
    ORDER BY pl.is_featured DESC, enrollment_count DESC, pl.sort_order, pl.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION search_program_library_v2 IS 'Enhanced search with pack filtering and access level checking';

-- ============================================================================
-- 7. Function to Check User Pack Access
-- ============================================================================

CREATE OR REPLACE FUNCTION check_user_pack_access(
    p_user_id UUID,
    p_pack_code TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM user_pack_subscriptions ups
        JOIN premium_packs pp ON pp.id = ups.pack_id
        WHERE ups.user_id = p_user_id
        AND pp.code = p_pack_code
        AND ups.status = 'active'
        AND (ups.expires_at IS NULL OR ups.expires_at > NOW())
    );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

COMMENT ON FUNCTION check_user_pack_access IS 'Check if user has active subscription to a specific pack';

-- ============================================================================
-- 8. Function to Get User Accessible Programs
-- ============================================================================

CREATE OR REPLACE FUNCTION get_user_accessible_programs(
    p_user_id UUID
)
RETURNS TABLE (
    program_id UUID,
    title TEXT,
    category TEXT,
    access_level TEXT,
    pack_code TEXT,
    is_enrolled BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        pl.id AS program_id,
        pl.title,
        pl.category,
        pl.access_level,
        pp.code AS pack_code,
        EXISTS (
            SELECT 1 FROM program_enrollments pe
            WHERE pe.program_library_id = pl.id
            AND pe.patient_id = p_user_id
            AND pe.status = 'active'
        ) AS is_enrolled
    FROM program_library pl
    LEFT JOIN premium_packs pp ON pp.id = pl.pack_id
    WHERE
        pl.access_level = 'free'
        OR (pl.access_level = 'premium' AND check_user_pack_access(p_user_id, 'BASE'))
        OR (pl.access_level = 'elite' AND pp.code IS NOT NULL AND check_user_pack_access(p_user_id, pp.code))
    ORDER BY pp.sort_order NULLS FIRST, pl.sort_order, pl.title;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

COMMENT ON FUNCTION get_user_accessible_programs IS 'Get all programs user has access to based on subscriptions';

-- ============================================================================
-- 9. Trigger for updated_at
-- ============================================================================

CREATE OR REPLACE FUNCTION update_premium_packs_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER premium_packs_updated_at
    BEFORE UPDATE ON premium_packs
    FOR EACH ROW
    EXECUTE FUNCTION update_premium_packs_updated_at();

CREATE OR REPLACE FUNCTION update_user_pack_subscriptions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER user_pack_subscriptions_updated_at
    BEFORE UPDATE ON user_pack_subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_user_pack_subscriptions_updated_at();

-- ============================================================================
-- 10. Grant Permissions
-- ============================================================================

GRANT SELECT ON premium_packs TO authenticated;
GRANT SELECT, INSERT, UPDATE ON user_pack_subscriptions TO authenticated;
GRANT EXECUTE ON FUNCTION search_program_library_v2 TO authenticated;
GRANT EXECUTE ON FUNCTION check_user_pack_access TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_accessible_programs TO authenticated;
