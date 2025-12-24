-- Migration: Create WHOOP integration tables
-- Build: 76
-- Date: 2025-12-24
-- Description: Add WHOOP recovery and credentials tables for Build 76

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- Table: whoop_credentials
-- Purpose: Store WHOOP OAuth tokens for athletes
-- ============================================================

CREATE TABLE IF NOT EXISTS whoop_credentials (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    athlete_id UUID NOT NULL REFERENCES athletes(id) ON DELETE CASCADE,
    access_token TEXT NOT NULL,
    refresh_token TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Ensure one WHOOP account per athlete
    CONSTRAINT whoop_credentials_athlete_unique UNIQUE (athlete_id)
);

-- Index for fast athlete lookup
CREATE INDEX IF NOT EXISTS idx_whoop_credentials_athlete
    ON whoop_credentials(athlete_id);

-- Index for token expiration checks
CREATE INDEX IF NOT EXISTS idx_whoop_credentials_expires
    ON whoop_credentials(expires_at)
    WHERE expires_at > NOW();

-- ============================================================
-- Table: whoop_recovery
-- Purpose: Store daily WHOOP recovery data
-- ============================================================

CREATE TABLE IF NOT EXISTS whoop_recovery (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    athlete_id UUID NOT NULL REFERENCES athletes(id) ON DELETE CASCADE,
    date DATE NOT NULL,

    -- Recovery metrics
    recovery_score DECIMAL(5,2) NOT NULL CHECK (recovery_score >= 0 AND recovery_score <= 100),
    hrv_rmssd DECIMAL(6,2),  -- Heart rate variability in milliseconds
    resting_hr INTEGER CHECK (resting_hr > 0 AND resting_hr < 200),
    hrv_baseline DECIMAL(6,2),  -- Athlete's HRV baseline for comparison
    sleep_performance DECIMAL(5,2) CHECK (sleep_performance >= 0 AND sleep_performance <= 100),

    -- Calculated readiness band
    readiness_band TEXT NOT NULL CHECK (readiness_band IN ('green', 'yellow', 'red')),

    -- Metadata
    synced_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Ensure one recovery record per athlete per day
    CONSTRAINT whoop_recovery_athlete_date_unique UNIQUE (athlete_id, date)
);

-- Index for fast athlete + date queries
CREATE INDEX IF NOT EXISTS idx_whoop_recovery_athlete_date
    ON whoop_recovery(athlete_id, date DESC);

-- Index for readiness band filtering
CREATE INDEX IF NOT EXISTS idx_whoop_recovery_readiness
    ON whoop_recovery(readiness_band)
    WHERE readiness_band IN ('yellow', 'red');

-- ============================================================
-- Table: whoop_strain (optional - for future use)
-- Purpose: Store daily WHOOP strain data
-- ============================================================

CREATE TABLE IF NOT EXISTS whoop_strain (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    athlete_id UUID NOT NULL REFERENCES athletes(id) ON DELETE CASCADE,
    date DATE NOT NULL,

    -- Strain metrics (WHOOP scale 0-21)
    day_strain DECIMAL(4,2) CHECK (day_strain >= 0 AND day_strain <= 21),
    workout_strain DECIMAL(4,2) CHECK (workout_strain >= 0 AND workout_strain <= 21),

    -- Activity metrics
    calories INTEGER,
    avg_hr INTEGER CHECK (avg_hr > 0 AND avg_hr < 250),
    max_hr INTEGER CHECK (max_hr > 0 AND max_hr < 250),

    -- Metadata
    synced_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT whoop_strain_athlete_date_unique UNIQUE (athlete_id, date)
);

CREATE INDEX IF NOT EXISTS idx_whoop_strain_athlete_date
    ON whoop_strain(athlete_id, date DESC);

-- ============================================================
-- Table: whoop_sleep (optional - for future use)
-- Purpose: Store WHOOP sleep data
-- ============================================================

CREATE TABLE IF NOT EXISTS whoop_sleep (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    athlete_id UUID NOT NULL REFERENCES athletes(id) ON DELETE CASCADE,
    date DATE NOT NULL,  -- Date of sleep (morning wake-up date)

    -- Sleep duration
    total_sleep_hours DECIMAL(4,2) CHECK (total_sleep_hours >= 0 AND total_sleep_hours <= 24),
    time_in_bed_hours DECIMAL(4,2) CHECK (time_in_bed_hours >= 0 AND time_in_bed_hours <= 24),

    -- Sleep quality
    sleep_efficiency DECIMAL(5,2) CHECK (sleep_efficiency >= 0 AND sleep_efficiency <= 100),

    -- Sleep stages (minutes)
    slow_wave_sleep_minutes INTEGER CHECK (slow_wave_sleep_minutes >= 0),
    rem_sleep_minutes INTEGER CHECK (rem_sleep_minutes >= 0),
    light_sleep_minutes INTEGER CHECK (light_sleep_minutes >= 0),
    awake_minutes INTEGER CHECK (awake_minutes >= 0),

    -- Metadata
    synced_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT whoop_sleep_athlete_date_unique UNIQUE (athlete_id, date)
);

CREATE INDEX IF NOT EXISTS idx_whoop_sleep_athlete_date
    ON whoop_sleep(athlete_id, date DESC);

-- ============================================================
-- Row Level Security (RLS) Policies
-- ============================================================

-- Enable RLS on all WHOOP tables
ALTER TABLE whoop_credentials ENABLE ROW LEVEL SECURITY;
ALTER TABLE whoop_recovery ENABLE ROW LEVEL SECURITY;
ALTER TABLE whoop_strain ENABLE ROW LEVEL SECURITY;
ALTER TABLE whoop_sleep ENABLE ROW LEVEL SECURITY;

-- whoop_credentials policies
CREATE POLICY "Athletes can view their own WHOOP credentials"
    ON whoop_credentials FOR SELECT
    USING (athlete_id = auth.uid());

CREATE POLICY "Athletes can insert their own WHOOP credentials"
    ON whoop_credentials FOR INSERT
    WITH CHECK (athlete_id = auth.uid());

CREATE POLICY "Athletes can update their own WHOOP credentials"
    ON whoop_credentials FOR UPDATE
    USING (athlete_id = auth.uid());

CREATE POLICY "Athletes can delete their own WHOOP credentials"
    ON whoop_credentials FOR DELETE
    USING (athlete_id = auth.uid());

-- whoop_recovery policies
CREATE POLICY "Athletes can view their own WHOOP recovery"
    ON whoop_recovery FOR SELECT
    USING (athlete_id = auth.uid());

CREATE POLICY "System can insert WHOOP recovery data"
    ON whoop_recovery FOR INSERT
    WITH CHECK (true);  -- Edge Functions will insert

CREATE POLICY "System can update WHOOP recovery data"
    ON whoop_recovery FOR UPDATE
    USING (true);

-- whoop_strain policies
CREATE POLICY "Athletes can view their own WHOOP strain"
    ON whoop_strain FOR SELECT
    USING (athlete_id = auth.uid());

CREATE POLICY "System can insert WHOOP strain data"
    ON whoop_strain FOR INSERT
    WITH CHECK (true);

-- whoop_sleep policies
CREATE POLICY "Athletes can view their own WHOOP sleep"
    ON whoop_sleep FOR SELECT
    USING (athlete_id = auth.uid());

CREATE POLICY "System can insert WHOOP sleep data"
    ON whoop_sleep FOR INSERT
    WITH CHECK (true);

-- ============================================================
-- Triggers for updated_at timestamps
-- ============================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for whoop_credentials
CREATE TRIGGER update_whoop_credentials_updated_at
    BEFORE UPDATE ON whoop_credentials
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for whoop_recovery
CREATE TRIGGER update_whoop_recovery_updated_at
    BEFORE UPDATE ON whoop_recovery
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- Comments
-- ============================================================

COMMENT ON TABLE whoop_credentials IS 'OAuth credentials for WHOOP API access per athlete';
COMMENT ON TABLE whoop_recovery IS 'Daily WHOOP recovery scores and readiness bands';
COMMENT ON TABLE whoop_strain IS 'Daily WHOOP strain metrics (optional, future use)';
COMMENT ON TABLE whoop_sleep IS 'WHOOP sleep data (optional, future use)';

COMMENT ON COLUMN whoop_recovery.recovery_score IS 'WHOOP recovery percentage (0-100)';
COMMENT ON COLUMN whoop_recovery.hrv_rmssd IS 'Heart rate variability in milliseconds';
COMMENT ON COLUMN whoop_recovery.readiness_band IS 'PT Performance readiness band: green (67-100%), yellow (34-66%), red (0-33%)';
