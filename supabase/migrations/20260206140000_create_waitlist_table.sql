-- Waitlist table for getmodus.app landing page signups
-- Allows anonymous inserts for collecting emails

CREATE TABLE IF NOT EXISTS waitlist (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL UNIQUE,
    source TEXT DEFAULT 'website',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    converted_at TIMESTAMPTZ,
    notes TEXT
);

-- Index for quick email lookups
CREATE INDEX IF NOT EXISTS idx_waitlist_email ON waitlist(email);
CREATE INDEX IF NOT EXISTS idx_waitlist_created_at ON waitlist(created_at DESC);

-- Enable RLS
ALTER TABLE waitlist ENABLE ROW LEVEL SECURITY;

-- Allow anonymous inserts (for landing page form)
CREATE POLICY "Anyone can join waitlist"
    ON waitlist
    FOR INSERT
    TO anon
    WITH CHECK (true);

-- Only authenticated users (admins) can read/update/delete
CREATE POLICY "Authenticated users can view waitlist"
    ON waitlist
    FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Authenticated users can update waitlist"
    ON waitlist
    FOR UPDATE
    TO authenticated
    USING (true);

CREATE POLICY "Authenticated users can delete from waitlist"
    ON waitlist
    FOR DELETE
    TO authenticated
    USING (true);

-- Grant permissions
GRANT INSERT ON waitlist TO anon;
GRANT ALL ON waitlist TO authenticated;

COMMENT ON TABLE waitlist IS 'Email waitlist signups from getmodus.app landing page';
COMMENT ON COLUMN waitlist.source IS 'Where the signup came from (website, referral, etc)';
COMMENT ON COLUMN waitlist.converted_at IS 'When they became a real user (if applicable)';
