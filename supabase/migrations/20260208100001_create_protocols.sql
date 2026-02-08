-- Migration: Create Protocol Templates and Athlete Plans
-- Purpose: Support X2Index PT workflow for assigning recovery/performance plans
-- Target: Apply/edit protocol templates and assign personalized tasks in <60s

-- ============================================================================
-- Protocol Templates Table
-- Stores reusable protocol templates with embedded tasks
-- ============================================================================

CREATE TABLE protocol_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('recovery', 'returnToPlay', 'performance', 'injury', 'maintenance')),
    description TEXT,
    default_duration_days INT DEFAULT 7,
    tasks JSONB NOT NULL DEFAULT '[]',
    is_active BOOLEAN DEFAULT true,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add comment for documentation
COMMENT ON TABLE protocol_templates IS 'Reusable protocol templates for athlete recovery and performance plans';
COMMENT ON COLUMN protocol_templates.tasks IS 'JSON array of ProtocolTask objects with task definitions';
COMMENT ON COLUMN protocol_templates.category IS 'Protocol category: recovery, returnToPlay, performance, injury, maintenance';

-- ============================================================================
-- Athlete Plans Table
-- Stores assigned plans for individual athletes
-- ============================================================================

CREATE TABLE athlete_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    athlete_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    protocol_id UUID REFERENCES protocol_templates(id),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    assigned_by UUID NOT NULL REFERENCES auth.users(id),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'paused', 'cancelled')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Ensure end_date is after start_date
    CONSTRAINT valid_date_range CHECK (end_date >= start_date)
);

-- Add comments
COMMENT ON TABLE athlete_plans IS 'Individual athlete protocol plans assigned by PT staff';
COMMENT ON COLUMN athlete_plans.status IS 'Plan status: active, completed, paused, cancelled';

-- ============================================================================
-- Assigned Tasks Table
-- Individual tasks within an athlete's plan
-- ============================================================================

CREATE TABLE assigned_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID NOT NULL REFERENCES athlete_plans(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    task_type TEXT NOT NULL CHECK (task_type IN ('exercise', 'stretch', 'ice', 'heat', 'rest', 'medication', 'checkIn', 'appointment')),
    due_date DATE NOT NULL,
    due_time TIME,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'skipped', 'overdue')),
    completed_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add comments
COMMENT ON TABLE assigned_tasks IS 'Individual tasks assigned to athletes within their protocol plan';
COMMENT ON COLUMN assigned_tasks.task_type IS 'Task type: exercise, stretch, ice, heat, rest, medication, checkIn, appointment';
COMMENT ON COLUMN assigned_tasks.status IS 'Task status: pending, completed, skipped, overdue';

-- ============================================================================
-- Indexes for Performance
-- ============================================================================

-- Protocol templates indexes
CREATE INDEX idx_protocol_templates_category ON protocol_templates(category) WHERE is_active = true;
CREATE INDEX idx_protocol_templates_active ON protocol_templates(is_active);

-- Athlete plans indexes
CREATE INDEX idx_athlete_plans_athlete ON athlete_plans(athlete_id);
CREATE INDEX idx_athlete_plans_status ON athlete_plans(status);
CREATE INDEX idx_athlete_plans_athlete_status ON athlete_plans(athlete_id, status);
CREATE INDEX idx_athlete_plans_assigned_by ON athlete_plans(assigned_by);
CREATE INDEX idx_athlete_plans_dates ON athlete_plans(start_date, end_date);

-- Assigned tasks indexes
CREATE INDEX idx_assigned_tasks_plan ON assigned_tasks(plan_id);
CREATE INDEX idx_assigned_tasks_due ON assigned_tasks(due_date, status);
CREATE INDEX idx_assigned_tasks_status ON assigned_tasks(status);
CREATE INDEX idx_assigned_tasks_plan_date ON assigned_tasks(plan_id, due_date);

-- ============================================================================
-- Triggers for Updated Timestamps
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for each table
CREATE TRIGGER update_protocol_templates_updated_at
    BEFORE UPDATE ON protocol_templates
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_athlete_plans_updated_at
    BEFORE UPDATE ON athlete_plans
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_assigned_tasks_updated_at
    BEFORE UPDATE ON assigned_tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- Function to Mark Overdue Tasks
-- ============================================================================

CREATE OR REPLACE FUNCTION mark_overdue_tasks()
RETURNS INTEGER AS $$
DECLARE
    updated_count INTEGER;
BEGIN
    UPDATE assigned_tasks
    SET status = 'overdue'
    WHERE status = 'pending'
      AND due_date < CURRENT_DATE
      AND (
          due_time IS NULL
          OR (due_date = CURRENT_DATE - INTERVAL '1 day' AND due_time < CURRENT_TIME)
      );

    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RETURN updated_count;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION mark_overdue_tasks IS 'Marks pending tasks as overdue if past their due date/time';

-- ============================================================================
-- Row Level Security (RLS)
-- ============================================================================

ALTER TABLE protocol_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE athlete_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE assigned_tasks ENABLE ROW LEVEL SECURITY;

-- Protocol templates: Readable by all authenticated users, writable by staff
CREATE POLICY "Protocol templates are readable by authenticated users"
    ON protocol_templates
    FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Protocol templates are insertable by staff"
    ON protocol_templates
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_id = auth.uid()
            AND role IN ('admin', 'pt', 'coach')
        )
    );

CREATE POLICY "Protocol templates are updatable by staff"
    ON protocol_templates
    FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_id = auth.uid()
            AND role IN ('admin', 'pt', 'coach')
        )
    );

-- Athlete plans: Readable by assigned staff and athlete, writable by staff
CREATE POLICY "Athlete plans are readable by relevant users"
    ON athlete_plans
    FOR SELECT
    TO authenticated
    USING (
        assigned_by = auth.uid()
        OR athlete_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_id = auth.uid()
            AND role IN ('admin', 'pt', 'coach')
        )
    );

CREATE POLICY "Athlete plans are insertable by staff"
    ON athlete_plans
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_id = auth.uid()
            AND role IN ('admin', 'pt', 'coach')
        )
    );

CREATE POLICY "Athlete plans are updatable by staff"
    ON athlete_plans
    FOR UPDATE
    TO authenticated
    USING (
        assigned_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_id = auth.uid()
            AND role IN ('admin', 'pt', 'coach')
        )
    );

-- Assigned tasks: Accessible based on plan access
CREATE POLICY "Assigned tasks follow plan access"
    ON assigned_tasks
    FOR ALL
    TO authenticated
    USING (
        plan_id IN (
            SELECT id FROM athlete_plans
            WHERE assigned_by = auth.uid()
               OR athlete_id IN (SELECT id FROM patients WHERE user_id = auth.uid())
               OR EXISTS (
                   SELECT 1 FROM user_roles
                   WHERE user_id = auth.uid()
                   AND role IN ('admin', 'pt', 'coach')
               )
        )
    );

-- ============================================================================
-- Seed Data: 5 Protocol Templates
-- ============================================================================

INSERT INTO protocol_templates (id, name, category, description, default_duration_days, tasks, is_active) VALUES

-- 1. Post-Workout Recovery
(
    '11111111-1111-1111-1111-111111111111',
    'Post-Workout Recovery',
    'recovery',
    'Comprehensive recovery routine for post-workout muscle recovery and soreness prevention',
    3,
    '[
        {
            "id": "a1111111-1111-1111-1111-111111111111",
            "title": "Static Stretching Routine",
            "description": "Full body static stretch sequence",
            "task_type": "stretch",
            "frequency": "daily",
            "default_time": "18:00",
            "duration_minutes": 15,
            "instructions": "Hold each stretch for 30 seconds. Focus on major muscle groups worked during training."
        },
        {
            "id": "a2222222-2222-2222-2222-222222222222",
            "title": "Foam Rolling Session",
            "description": "Self-myofascial release",
            "task_type": "exercise",
            "frequency": "daily",
            "default_time": "19:00",
            "duration_minutes": 10,
            "instructions": "Roll slowly over each muscle group. Pause on tender spots for 30 seconds."
        },
        {
            "id": "a3333333-3333-3333-3333-333333333333",
            "title": "Ice Bath / Cold Therapy",
            "description": "Cold water immersion for recovery",
            "task_type": "ice",
            "frequency": "daily",
            "default_time": "19:30",
            "duration_minutes": 10,
            "instructions": "10 minutes in cold water (50-59F). Focus on lower body immersion."
        },
        {
            "id": "a4444444-4444-4444-4444-444444444444",
            "title": "Recovery Check-In",
            "description": "Rate soreness and recovery status",
            "task_type": "checkIn",
            "frequency": "daily",
            "default_time": "08:00",
            "duration_minutes": 2,
            "instructions": "Rate muscle soreness 1-10 and note any areas of concern."
        }
    ]'::jsonb,
    true
),

-- 2. Return to Training (Mild Strain)
(
    '22222222-2222-2222-2222-222222222222',
    'Return to Training (Mild Strain)',
    'returnToPlay',
    'Progressive return protocol following mild muscle strain with gradual load increase',
    14,
    '[
        {
            "id": "b1111111-1111-1111-1111-111111111111",
            "title": "Gentle Mobility Work",
            "description": "Pain-free range of motion exercises",
            "task_type": "stretch",
            "frequency": "twiceDaily",
            "default_time": "07:00",
            "duration_minutes": 10,
            "instructions": "Move through pain-free range only. Stop if pain exceeds 3/10."
        },
        {
            "id": "b2222222-2222-2222-2222-222222222222",
            "title": "Ice Application",
            "description": "Apply ice to affected area",
            "task_type": "ice",
            "frequency": "daily",
            "default_time": "20:00",
            "duration_minutes": 15,
            "instructions": "Apply ice pack wrapped in cloth for 15 minutes. Do not apply directly to skin."
        },
        {
            "id": "b3333333-3333-3333-3333-333333333333",
            "title": "Progressive Loading Exercise",
            "description": "Gradual strength rebuilding",
            "task_type": "exercise",
            "frequency": "everyOtherDay",
            "default_time": "10:00",
            "duration_minutes": 20,
            "instructions": "Start with bodyweight, progress to light resistance as tolerated."
        },
        {
            "id": "b4444444-4444-4444-4444-444444444444",
            "title": "Pain & Function Check-In",
            "description": "Daily symptom monitoring",
            "task_type": "checkIn",
            "frequency": "daily",
            "default_time": "21:00",
            "duration_minutes": 3,
            "instructions": "Rate pain at rest and with movement. Note any improvements or setbacks."
        },
        {
            "id": "b5555555-5555-5555-5555-555555555555",
            "title": "PT Follow-Up Appointment",
            "description": "Progress evaluation with PT",
            "task_type": "appointment",
            "frequency": "weekly",
            "default_time": "14:00",
            "duration_minutes": 45,
            "instructions": "Bring completed check-in logs. Be prepared to demonstrate movement quality."
        }
    ]'::jsonb,
    true
),

-- 3. Performance Optimization
(
    '33333333-3333-3333-3333-333333333333',
    'Performance Optimization',
    'performance',
    'Peak performance protocol combining activation, recovery, and readiness optimization',
    7,
    '[
        {
            "id": "c1111111-1111-1111-1111-111111111111",
            "title": "Morning Activation Routine",
            "description": "Dynamic warm-up and neural activation",
            "task_type": "exercise",
            "frequency": "daily",
            "default_time": "06:30",
            "duration_minutes": 15,
            "instructions": "Dynamic stretches, activation drills, light plyometrics."
        },
        {
            "id": "c2222222-2222-2222-2222-222222222222",
            "title": "Pre-Training Prep",
            "description": "Sport-specific warm-up",
            "task_type": "exercise",
            "frequency": "daily",
            "default_time": "15:00",
            "duration_minutes": 20,
            "instructions": "Movement preparation specific to training focus."
        },
        {
            "id": "c3333333-3333-3333-3333-333333333333",
            "title": "Post-Training Flush",
            "description": "Active recovery work",
            "task_type": "stretch",
            "frequency": "daily",
            "default_time": "18:00",
            "duration_minutes": 10,
            "instructions": "Light cardio followed by stretching and mobility."
        },
        {
            "id": "c4444444-4444-4444-4444-444444444444",
            "title": "Readiness Assessment",
            "description": "Daily performance readiness check",
            "task_type": "checkIn",
            "frequency": "daily",
            "default_time": "07:00",
            "duration_minutes": 5,
            "instructions": "Rate sleep quality, energy, motivation, and physical readiness."
        },
        {
            "id": "c5555555-5555-5555-5555-555555555555",
            "title": "Contrast Therapy",
            "description": "Hot/cold alternating therapy",
            "task_type": "heat",
            "frequency": "everyOtherDay",
            "default_time": "19:00",
            "duration_minutes": 20,
            "instructions": "3 min hot, 1 min cold. Repeat 4 times. End on cold."
        }
    ]'::jsonb,
    true
),

-- 4. Sleep Improvement Protocol
(
    '44444444-4444-4444-4444-444444444444',
    'Sleep Improvement Protocol',
    'maintenance',
    'Evidence-based sleep hygiene and recovery optimization program',
    21,
    '[
        {
            "id": "d1111111-1111-1111-1111-111111111111",
            "title": "Evening Wind-Down Routine",
            "description": "Relaxation and sleep preparation",
            "task_type": "rest",
            "frequency": "daily",
            "default_time": "21:00",
            "duration_minutes": 30,
            "instructions": "Dim lights, no screens, gentle stretching or breathing exercises."
        },
        {
            "id": "d2222222-2222-2222-2222-222222222222",
            "title": "Sleep Environment Check",
            "description": "Optimize bedroom conditions",
            "task_type": "checkIn",
            "frequency": "weekly",
            "default_time": "20:00",
            "duration_minutes": 10,
            "instructions": "Check room temp (65-68F), darkness, noise levels. Make adjustments as needed."
        },
        {
            "id": "d3333333-3333-3333-3333-333333333333",
            "title": "Morning Light Exposure",
            "description": "Natural light for circadian rhythm",
            "task_type": "exercise",
            "frequency": "daily",
            "default_time": "07:00",
            "duration_minutes": 15,
            "instructions": "Get outside within 30 min of waking. 10-15 min of natural light exposure."
        },
        {
            "id": "d4444444-4444-4444-4444-444444444444",
            "title": "Sleep Quality Log",
            "description": "Track sleep metrics",
            "task_type": "checkIn",
            "frequency": "daily",
            "default_time": "08:00",
            "duration_minutes": 2,
            "instructions": "Record: bedtime, wake time, perceived quality (1-10), interruptions."
        },
        {
            "id": "d5555555-5555-5555-5555-555555555555",
            "title": "Gentle Evening Stretch",
            "description": "Relaxation stretching routine",
            "task_type": "stretch",
            "frequency": "daily",
            "default_time": "21:30",
            "duration_minutes": 10,
            "instructions": "Slow, relaxing stretches. Focus on breathing. Avoid stimulating movements."
        }
    ]'::jsonb,
    true
),

-- 5. Stress Management
(
    '55555555-5555-5555-5555-555555555555',
    'Stress Management',
    'maintenance',
    'Holistic stress reduction protocol combining movement, breathing, and mindfulness',
    14,
    '[
        {
            "id": "e1111111-1111-1111-1111-111111111111",
            "title": "Morning Breathwork",
            "description": "Box breathing or 4-7-8 technique",
            "task_type": "rest",
            "frequency": "daily",
            "default_time": "06:30",
            "duration_minutes": 10,
            "instructions": "Box breathing: 4 sec inhale, 4 sec hold, 4 sec exhale, 4 sec hold. Repeat 10 cycles."
        },
        {
            "id": "e2222222-2222-2222-2222-222222222222",
            "title": "Midday Movement Break",
            "description": "Active stress relief",
            "task_type": "exercise",
            "frequency": "daily",
            "default_time": "12:00",
            "duration_minutes": 15,
            "instructions": "Walk, stretch, or light movement. Get away from desk/work area."
        },
        {
            "id": "e3333333-3333-3333-3333-333333333333",
            "title": "Evening Decompression",
            "description": "End-of-day stress release",
            "task_type": "stretch",
            "frequency": "daily",
            "default_time": "18:00",
            "duration_minutes": 20,
            "instructions": "Yoga-inspired flow or gentle stretching. Focus on hip openers and shoulder release."
        },
        {
            "id": "e4444444-4444-4444-4444-444444444444",
            "title": "Stress Level Check-In",
            "description": "Monitor stress patterns",
            "task_type": "checkIn",
            "frequency": "twiceDaily",
            "default_time": "09:00",
            "duration_minutes": 2,
            "instructions": "Rate stress 1-10. Note triggers. Identify one positive moment."
        },
        {
            "id": "e5555555-5555-5555-5555-555555555555",
            "title": "Progressive Muscle Relaxation",
            "description": "Tension release technique",
            "task_type": "rest",
            "frequency": "daily",
            "default_time": "21:00",
            "duration_minutes": 15,
            "instructions": "Systematically tense and release each muscle group. Start from feet, work to head."
        }
    ]'::jsonb,
    true
);

-- ============================================================================
-- Analytics View for KPI Tracking
-- ============================================================================

CREATE OR REPLACE VIEW protocol_assignment_stats AS
SELECT
    pt.id as template_id,
    pt.name as template_name,
    pt.category,
    COUNT(ap.id) as total_assignments,
    COUNT(CASE WHEN ap.status = 'completed' THEN 1 END) as completed_plans,
    COUNT(CASE WHEN ap.status = 'active' THEN 1 END) as active_plans,
    AVG(ap.end_date - ap.start_date) as avg_duration_days,
    (
        SELECT COUNT(*)
        FROM assigned_tasks at2
        JOIN athlete_plans ap2 ON at2.plan_id = ap2.id
        WHERE ap2.protocol_id = pt.id AND at2.status = 'completed'
    )::float / NULLIF(
        (
            SELECT COUNT(*)
            FROM assigned_tasks at3
            JOIN athlete_plans ap3 ON at3.plan_id = ap3.id
            WHERE ap3.protocol_id = pt.id
        ), 0
    ) * 100 as task_completion_rate
FROM protocol_templates pt
LEFT JOIN athlete_plans ap ON pt.id = ap.protocol_id
GROUP BY pt.id, pt.name, pt.category;

COMMENT ON VIEW protocol_assignment_stats IS 'Analytics view for tracking protocol template usage and effectiveness';
