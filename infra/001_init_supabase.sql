-- 001_init_supabase.sql
-- Initial schema for PT / performance app

-- Therapists
create table if not exists therapists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique, -- maps to supabase auth.users.id
  first_name text not null,
  last_name text not null,
  email text unique not null,
  created_at timestamptz default now()
);

-- Patients
create table if not exists patients (
  id uuid primary key default gen_random_uuid(),
  therapist_id uuid references therapists(id) on delete set null,
  first_name text not null,
  last_name text not null,
  date_of_birth date,
  sport text,
  position text,
  dominant_hand text,
  height_in numeric,
  weight_lb numeric,
  medical_history jsonb, -- surgeries, conditions
  medications jsonb,
  goals text,
  created_at timestamptz default now()
);

-- Programs (rehab/performance plans)
create table if not exists programs (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references patients(id) on delete cascade,
  name text not null,
  description text,
  start_date date,
  end_date date,
  status text check (status in ('planned','active','completed','paused')) default 'planned',
  created_at timestamptz default now()
);

-- Phases inside a program (e.g. On-Ramp, Strength, Return-to-Throw)
create table if not exists phases (
  id uuid primary key default gen_random_uuid(),
  program_id uuid not null references programs(id) on delete cascade,
  name text not null,
  sequence int not null,
  start_date date,
  end_date date,
  notes text,
  created_at timestamptz default now()
);

-- Sessions (per-day plans)
create table if not exists sessions (
  id uuid primary key default gen_random_uuid(),
  phase_id uuid not null references phases(id) on delete cascade,
  name text not null,
  sequence int not null,
  weekday int, -- 0=Sunday ... 6=Saturday, optional
  notes text,
  created_at timestamptz default now()
);

-- Master exercise library
create table if not exists exercise_templates (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text,          -- strength, mobility, plyo, bullpen, cardio
  body_region text,       -- shoulder, elbow, hip, etc.
  equipment text,
  load_type text,         -- weight, bodyweight, distance, time
  rm_method text,         -- epley, brzycki, lombardi, none
  cueing text,
  created_at timestamptz default now()
);

-- Prescription of an exercise within a session
create table if not exists session_exercises (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references sessions(id) on delete cascade,
  exercise_template_id uuid not null references exercise_templates(id),
  target_sets int,
  target_reps int,
  target_load numeric,
  target_rpe numeric,
  tempo text,
  notes text,
  sequence int not null,
  created_at timestamptz default now()
);

-- Logged exercise results
create table if not exists exercise_logs (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references patients(id) on delete cascade,
  session_id uuid not null references sessions(id) on delete cascade,
  session_exercise_id uuid not null references session_exercises(id) on delete cascade,
  performed_at timestamptz default now(),
  set_number int,
  actual_reps int,
  actual_load numeric,
  rpe numeric,
  pain_score numeric, -- 0–10 during that exercise
  notes text
);

-- Pain per session
create table if not exists pain_logs (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references patients(id) on delete cascade,
  session_id uuid references sessions(id) on delete set null,
  logged_at timestamptz default now(),
  pain_rest numeric,
  pain_during numeric,
  pain_after numeric,
  notes text
);

-- Body composition
create table if not exists body_comp_measurements (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references patients(id) on delete cascade,
  measured_at date not null,
  weight_lb numeric,
  body_fat_pct numeric,
  lean_mass_lb numeric,
  notes text
);

-- Bullpen / pitching logs
create table if not exists bullpen_logs (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references patients(id) on delete cascade,
  logged_at timestamptz default now(),
  pitch_type text,          -- fastball, slider, etc.
  velocity numeric,
  command_rating numeric,   -- 1–10
  pitch_count int,
  pain_score numeric,       -- 0–10
  notes text
);

-- Therapist notes & assessments
create table if not exists session_notes (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references patients(id) on delete cascade,
  session_id uuid references sessions(id) on delete set null,
  author_type text check (author_type in ('therapist','patient','system')) default 'therapist',
  content text not null,
  created_at timestamptz default now()
);

-- Views for analytics (v1 skeletons)
create view vw_patient_adherence as
select
  p.id as patient_id,
  p.first_name,
  p.last_name,
  count(distinct s.id) as scheduled_sessions,
  count(distinct el.session_id) as completed_sessions,
  case
    when count(distinct s.id) = 0 then 0
    else round(100.0 * count(distinct el.session_id) / count(distinct s.id), 1)
  end as adherence_pct
from patients p
left join programs pr on pr.patient_id = p.id and pr.status in ('active','planned')
left join phases ph on ph.program_id = pr.id
left join sessions s on s.phase_id = ph.id
left join exercise_logs el on el.patient_id = p.id and el.session_id = s.id
group by p.id;

create view vw_pain_trend as
select
  patient_id,
  date(logged_at) as day,
  avg(pain_during) as avg_pain_during
from pain_logs
group by patient_id, date(logged_at);
