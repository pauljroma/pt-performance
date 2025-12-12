-- 002_epic_enhancements.sql
-- Schema enhancements based on EPIC A-H requirements
-- Run after 001_init_supabase.sql

-- ============================================================================
-- EPIC A: Personal & Clinical Context
-- ============================================================================

-- Add email to patients (for auth integration)
alter table patients add column if not exists email text unique;

-- Add metadata to programs
alter table programs add column if not exists metadata jsonb default '{}'::jsonb;

-- Create clinical history structure
comment on column patients.medical_history is
'JSON structure:
{
  "injuries": [{"year": 2025, "body_region": "shoulder", "diagnosis": "rotator cuff strain", "notes": "..."}],
  "surgeries": [{"year": 2023, "procedure": "Tommy John", "notes": "..."}],
  "chronic_conditions": ["asthma", "hypertension"]
}';

comment on column patients.medications is
'JSON structure:
{
  "current": [{"name": "diclofenac", "dose": "50mg", "schedule": "daily", "seasonality": "in-season"}],
  "allergies": ["penicillin"]
}';

comment on column programs.metadata is
'JSON structure:
{
  "target_level": "MLB",
  "role": "reliever",
  "return_to_throw_target_date": "2025-06-01"
}';

-- ============================================================================
-- EPIC B: Strength & S&C Model
-- ============================================================================

-- Enhance exercise_templates
alter table exercise_templates add column if not exists primary_muscle_group text;
alter table exercise_templates add column if not exists is_primary_lift boolean default false;
alter table exercise_templates add column if not exists default_rm_method text
  check (default_rm_method in ('epley', 'brzycki', 'lombardi', 'none'));
alter table exercise_templates add column if not exists movement_pattern text;
alter table exercise_templates add column if not exists clinical_tags jsonb default '[]'::jsonb;
alter table exercise_templates add column if not exists throwing_tags jsonb default '{}'::jsonb;
alter table exercise_templates add column if not exists programming_metadata jsonb default '{}'::jsonb;

-- Enhance exercise_logs
alter table exercise_logs add column if not exists rm_estimate numeric;
alter table exercise_logs add column if not exists is_pr boolean default false;

comment on column exercise_templates.clinical_tags is
'JSON array of tags: ["contraindicated_post_surgery", "valgus_stress_sensitive", "promotes_internal_rotation"]';

comment on column exercise_templates.throwing_tags is
'JSON structure:
{
  "pitch_type_supported": ["4-seam", "slider", "changeup"],
  "ball_weight_oz": 5,
  "drill_category": "arm care",
  "velocity_tracking_required": true
}';

comment on column exercise_templates.programming_metadata is
'JSON structure:
{
  "default_set_rep_scheme": "3x8",
  "progression_type": "linear load",
  "tissue_capacity_rating": 7
}';

-- ============================================================================
-- EPIC C: Throwing, On-Ramp, and Plyo Model
-- ============================================================================

-- Enhance bullpen_logs
alter table bullpen_logs add column if not exists missed_spot_count int default 0;
alter table bullpen_logs add column if not exists hit_spot_count int default 0;
alter table bullpen_logs add column if not exists hit_spot_pct numeric;
alter table bullpen_logs add column if not exists avg_velocity numeric;
alter table bullpen_logs add column if not exists ball_weight_oz numeric;
alter table bullpen_logs add column if not exists is_plyo boolean default false;
alter table bullpen_logs add column if not exists drill_name text;

-- Create plyo_logs table (alternative approach to using bullpen_logs)
create table if not exists plyo_logs (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references patients(id) on delete cascade,
  logged_at timestamptz default now(),
  drill_name text not null,
  ball_weight_oz numeric not null,
  velocity numeric,
  throw_count int,
  pain_score numeric,
  notes text
);

-- Throwing workload view
create or replace view vw_throwing_workload as
select
  patient_id,
  date(logged_at) as session_date,
  sum(pitch_count) as total_pitches,
  avg(case when pitch_type like '%FB%' then velocity end) as avg_velocity_fastball,
  avg(hit_spot_pct) as avg_hit_spot_pct,
  max(pain_score) as max_pain,
  case
    when sum(pitch_count) > 60 then true
    else false
  end as high_workload_flag,
  case
    when avg(case when pitch_type like '%FB%' then velocity end) <
         lag(avg(case when pitch_type like '%FB%' then velocity end), 3)
         over (partition by patient_id order by date(logged_at)) - 3
    then true
    else false
  end as velocity_drop_flag
from bullpen_logs
where is_plyo = false
group by patient_id, date(logged_at);

-- On-ramp progress view
create or replace view vw_onramp_progress as
select
  pr.patient_id,
  pr.id as program_id,
  pr.name as program_name,
  ph.id as phase_id,
  ph.name as phase_name,
  ph.sequence as week,
  count(distinct s.id) as target_sessions,
  count(distinct el.session_id) as completed_sessions,
  avg(bl.avg_velocity) as avg_velocity,
  max(bl.pain_score) as max_pain
from programs pr
join phases ph on ph.program_id = pr.id
join sessions s on s.phase_id = ph.id
left join exercise_logs el on el.session_id = s.id
left join bullpen_logs bl on bl.patient_id = pr.patient_id
  and date(bl.logged_at) between ph.start_date and ph.end_date
where pr.name ilike '%on-ramp%' or pr.name ilike '%return to throw%'
group by pr.patient_id, pr.id, pr.name, ph.id, ph.name, ph.sequence
order by ph.sequence;

-- ============================================================================
-- EPIC D: Exercise Library Metadata
-- ============================================================================

-- Additional indexes for exercise search
create index if not exists idx_exercise_templates_category on exercise_templates(category);
create index if not exists idx_exercise_templates_body_region on exercise_templates(body_region);
create index if not exists idx_exercise_templates_movement_pattern on exercise_templates(movement_pattern);

-- GIN index for JSONB searches
create index if not exists idx_exercise_templates_clinical_tags on exercise_templates using gin(clinical_tags);
create index if not exists idx_exercise_templates_throwing_tags on exercise_templates using gin(throwing_tags);

-- ============================================================================
-- EPIC E: Program Builder
-- ============================================================================

-- Enhance phases
alter table phases add column if not exists duration_weeks int;
alter table phases add column if not exists goals text;
alter table phases add column if not exists constraints jsonb default '{}'::jsonb;

comment on column phases.constraints is
'JSON structure:
{
  "no_overhead_until_week": 4,
  "max_intensity_pct": 80,
  "restrictions": ["no throwing", "limited ROM"]
}';

-- Enhance sessions
alter table sessions add column if not exists intensity_rating numeric check (intensity_rating between 0 and 10);
alter table sessions add column if not exists is_throwing_day boolean default false;

-- ============================================================================
-- EPIC F: Program Execution Logic
-- ============================================================================

-- Session status tracking
create table if not exists session_status (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references patients(id) on delete cascade,
  session_id uuid not null references sessions(id) on delete cascade,
  scheduled_date date not null,
  status text check (status in ('scheduled', 'completed', 'missed', 'skipped')) default 'scheduled',
  completed_at timestamptz,
  notes text,
  created_at timestamptz default now(),
  unique(patient_id, session_id, scheduled_date)
);

-- ============================================================================
-- EPIC G: Pain Interpretation Model
-- ============================================================================

-- Pain flags table
create table if not exists pain_flags (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references patients(id) on delete cascade,
  flag_type text not null check (flag_type in ('pain_spike', 'chronic_pain', 'throwing_pain', 'positive_adaptation')),
  severity text check (severity in ('low', 'medium', 'high')) default 'medium',
  triggered_at timestamptz default now(),
  resolved_at timestamptz,
  context jsonb,
  notes text
);

-- Pain summary view
create or replace view vw_pain_summary as
select
  p.id as patient_id,
  p.first_name,
  p.last_name,
  avg(pl.pain_during) filter (where pl.logged_at > now() - interval '7 days') as avg_pain_7d,
  avg(pl.pain_during) filter (where pl.logged_at > now() - interval '14 days') as avg_pain_14d,
  max(pl.pain_during) filter (where pl.logged_at > now() - interval '7 days') as max_pain_7d,
  case
    when max(pl.pain_during) filter (where pl.logged_at > now() - interval '7 days') > 5 then 'red'
    when max(pl.pain_during) filter (where pl.logged_at > now() - interval '7 days') > 3 then 'yellow'
    else 'green'
  end as pain_indicator,
  count(*) filter (where pf.resolved_at is null) as active_flags
from patients p
left join pain_logs pl on pl.patient_id = p.id
left join pain_flags pf on pf.patient_id = p.id and pf.resolved_at is null
group by p.id, p.first_name, p.last_name;

-- ============================================================================
-- EPIC H: Therapist Dashboard
-- ============================================================================

-- Comprehensive patient summary view
create or replace view vw_therapist_patient_summary as
select
  p.id as patient_id,
  p.first_name,
  p.last_name,
  p.sport,
  p.position,
  t.first_name as therapist_first_name,
  t.last_name as therapist_last_name,
  pr.id as active_program_id,
  pr.name as active_program_name,
  pr.status as program_status,
  ph.name as current_phase,
  max(el.performed_at) as last_session_date,
  pa.adherence_pct,
  ps.avg_pain_7d,
  ps.pain_indicator,
  ps.active_flags as flag_count
from patients p
left join therapists t on t.id = p.therapist_id
left join programs pr on pr.patient_id = p.id and pr.status = 'active'
left join phases ph on ph.program_id = pr.id
  and current_date between ph.start_date and ph.end_date
left join exercise_logs el on el.patient_id = p.id
left join vw_patient_adherence pa on pa.patient_id = p.id
left join vw_pain_summary ps on ps.patient_id = p.id
group by p.id, p.first_name, p.last_name, p.sport, p.position,
         t.first_name, t.last_name, pr.id, pr.name, pr.status,
         ph.name, pa.adherence_pct, ps.avg_pain_7d, ps.pain_indicator, ps.active_flags;

-- Velocity/strength trend view (for pitcher-specific metrics)
create or replace view vw_performance_trends as
select
  patient_id,
  date(logged_at) as session_date,
  avg(velocity) as avg_velocity,
  avg(hit_spot_pct) as avg_command,
  max(pain_score) as max_pain
from bullpen_logs
where logged_at > now() - interval '30 days'
group by patient_id, date(logged_at)
order by patient_id, session_date;

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

create index if not exists idx_exercise_logs_patient_id on exercise_logs(patient_id);
create index if not exists idx_exercise_logs_session_id on exercise_logs(session_id);
create index if not exists idx_exercise_logs_performed_at on exercise_logs(performed_at desc);

create index if not exists idx_pain_logs_patient_id on pain_logs(patient_id);
create index if not exists idx_pain_logs_logged_at on pain_logs(logged_at desc);

create index if not exists idx_bullpen_logs_patient_id on bullpen_logs(patient_id);
create index if not exists idx_bullpen_logs_logged_at on bullpen_logs(logged_at desc);

create index if not exists idx_programs_patient_id on programs(patient_id);
create index if not exists idx_programs_status on programs(status);

create index if not exists idx_session_status_patient_id on session_status(patient_id);
create index if not exists idx_session_status_scheduled_date on session_status(scheduled_date);

create index if not exists idx_pain_flags_patient_id on pain_flags(patient_id);
create index if not exists idx_pain_flags_resolved_at on pain_flags(resolved_at) where resolved_at is null;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all tables
alter table therapists enable row level security;
alter table patients enable row level security;
alter table programs enable row level security;
alter table phases enable row level security;
alter table sessions enable row level security;
alter table exercise_templates enable row level security;
alter table session_exercises enable row level security;
alter table exercise_logs enable row level security;
alter table pain_logs enable row level security;
alter table body_comp_measurements enable row level security;
alter table bullpen_logs enable row level security;
alter table plyo_logs enable row level security;
alter table session_notes enable row level security;
alter table session_status enable row level security;
alter table pain_flags enable row level security;

-- Therapists can see all their patients
DO $$ BEGIN
  create policy therapists_see_own_patients on patients
    for select using (
      therapist_id in (
        select id from therapists where user_id = auth.uid()
      )
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Patients can see only their own data
DO $$ BEGIN
  create policy patients_see_own_data on patients
    for select using (
      id in (
        select id from patients where user_id = auth.uid()
      )
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Similar policies for other tables (example for programs)
DO $$ BEGIN
  create policy therapists_see_patient_programs on programs
    for select using (
      patient_id in (
        select id from patients where therapist_id in (
          select id from therapists where user_id = auth.uid()
        )
      )
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  create policy patients_see_own_programs on programs
    for select using (
      patient_id in (
        select id from patients where user_id = auth.uid()
      )
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Exercise templates are public (read-only for all authenticated users)
DO $$ BEGIN
  create policy exercise_templates_read_all on exercise_templates
    for select using (auth.role() = 'authenticated');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Only therapists can write to exercise_templates
DO $$ BEGIN
  create policy exercise_templates_write_therapists on exercise_templates
    for all using (
      exists (
        select 1 from therapists where user_id = auth.uid()
      )
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- TODO: Add remaining RLS policies for other tables following same pattern

-- ============================================================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================================================

comment on table pain_flags is 'Auto-generated and manual flags for pain events that require PT attention';
comment on table session_status is 'Tracks scheduled vs completed sessions for adherence calculation';
comment on table plyo_logs is 'Plyometric drill tracking separate from bullpen work';

comment on view vw_throwing_workload is 'Daily throwing workload summary with automatic flags';
comment on view vw_onramp_progress is 'On-ramp program progression tracking by week';
comment on view vw_pain_summary is 'Patient pain summary with 7-day and 14-day trends';
comment on view vw_therapist_patient_summary is 'Complete patient summary for therapist dashboard';
comment on view vw_performance_trends is 'Velocity and command trends for pitchers';
