-- Build 538: Fix audit_logs action_type constraint and failed_login_attempts schema
--
-- 1. The iOS app sends action_type values like 'data_access', 'authentication', etc.
--    but the CHECK constraint only allows 'CREATE', 'READ', 'UPDATE', 'DELETE', 'EXPORT',
--    'LOGIN', 'LOGOUT', 'ADMIN'. Expand to include iOS values.
--
-- 2. The SecurityMonitor inserts user_email into failed_login_attempts but the column
--    doesn't exist. Add it.

BEGIN;

-- ============================================================================
-- 1. Expand audit_logs action_type CHECK constraint
-- ============================================================================

ALTER TABLE audit_logs DROP CONSTRAINT IF EXISTS audit_logs_action_type_check;

ALTER TABLE audit_logs ADD CONSTRAINT audit_logs_action_type_check CHECK (
    action_type IN (
        -- Original values
        'CREATE', 'READ', 'UPDATE', 'DELETE', 'EXPORT', 'LOGIN', 'LOGOUT', 'ADMIN',
        -- iOS AuditLogger values
        'data_access', 'data_modification', 'authentication', 'authorization',
        'export', 'deletion', 'settings_change', 'security_event'
    )
);

-- ============================================================================
-- 2. Add user_email column to failed_login_attempts
-- ============================================================================

ALTER TABLE failed_login_attempts
    ADD COLUMN IF NOT EXISTS user_email TEXT;

-- ============================================================================
-- 3. Force schema cache reload
-- ============================================================================

NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';

COMMIT;
