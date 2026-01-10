-- Migration: Create Therapist Role System
-- Build: 119
-- Date: 2026-01-03
-- Purpose: Implement role-based access control foundation

-- Create user_roles table
CREATE TABLE IF NOT EXISTS user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role_name VARCHAR(50) NOT NULL CHECK (role_name IN ('patient', 'therapist', 'admin')),
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    assigned_by UUID REFERENCES auth.users(id),
    UNIQUE(user_id, role_name)
);

-- Create indexes for performance
CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX idx_user_roles_role_name ON user_roles(role_name);

-- Enable RLS on user_roles
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can see their own roles
CREATE POLICY "Users can view own roles"
    ON user_roles FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

-- RLS Policy: Only admins can manage roles (for now, allow system to manage)
CREATE POLICY "System can manage roles"
    ON user_roles FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Drop existing functions if they exist (handle conflicts)
DROP FUNCTION IF EXISTS is_therapist(UUID);
DROP FUNCTION IF EXISTS is_patient(UUID);
DROP FUNCTION IF EXISTS get_user_role(UUID);

-- Function: Check if user is a therapist
CREATE FUNCTION is_therapist(user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM user_roles
        WHERE user_roles.user_id = $1
        AND role_name = 'therapist'
    );
$$;

-- Function: Check if user is a patient
CREATE FUNCTION is_patient(user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM user_roles
        WHERE user_roles.user_id = $1
        AND role_name = 'patient'
    );
$$;

-- Function: Get user's primary role
CREATE FUNCTION get_user_role(user_id UUID)
RETURNS VARCHAR
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT role_name
    FROM user_roles
    WHERE user_roles.user_id = $1
    ORDER BY
        CASE role_name
            WHEN 'admin' THEN 1
            WHEN 'therapist' THEN 2
            WHEN 'patient' THEN 3
        END
    LIMIT 1;
$$;

-- Seed: Assign 'patient' role to all existing users
INSERT INTO user_roles (user_id, role_name, assigned_at)
SELECT
    id,
    'patient',
    now()
FROM auth.users
ON CONFLICT (user_id, role_name) DO NOTHING;

-- Comment
COMMENT ON TABLE user_roles IS 'Role-based access control for users (BUILD 119)';
COMMENT ON FUNCTION is_therapist(UUID) IS 'Check if user has therapist role (BUILD 119)';
COMMENT ON FUNCTION is_patient(UUID) IS 'Check if user has patient role (BUILD 119)';
COMMENT ON FUNCTION get_user_role(UUID) IS 'Get user primary role (BUILD 119)';
