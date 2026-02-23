-- MVP Feature Flags
-- Adds flags to control feature visibility for the initial App Store launch.
-- MVP keeps: recovery, supplements, nutrition, daily workouts, 4-5 programs.
-- Everything else is hidden but stays wired -- toggle via Supabase dashboard.

INSERT INTO feature_flags (flag_key, enabled, description) VALUES
  -- Master MVP switch
  ('mvp_mode', true, 'Master MVP mode — simplified 4-tab layout'),

  -- Disabled feature areas
  ('therapist_mode_enabled', false, 'Enable therapist role UI (7-tab clinical dashboard)'),
  ('mode_selection_enabled', false, 'Enable mode selection in onboarding and settings'),
  ('pain_tracking_enabled', false, 'Enable pain tracking tab (rehab mode)'),
  ('rom_exercises_enabled', false, 'Enable ROM exercises tab (rehab mode)'),
  ('pr_tracking_enabled', false, 'Enable PR tracking / BigLifts tab (strength mode)'),
  ('performance_analytics_enabled', false, 'Enable ACWR analytics tab (performance mode)'),
  ('fasting_tracker_enabled', false, 'Enable fasting tracker in Health Hub'),
  ('biomarker_dashboard_enabled', false, 'Enable biomarker dashboard in Health Hub'),
  ('ai_health_coach_enabled', false, 'Enable AI health coach in Health Hub'),
  ('lab_upload_enabled', false, 'Enable lab PDF upload in Health Hub'),
  ('programs_packs_enabled', false, 'Enable premium packs segment in Programs Hub'),
  ('programs_trends_enabled', false, 'Enable trends segment in Programs Hub'),
  ('programs_history_enabled', false, 'Enable history segment in Programs Hub'),
  ('arm_care_enabled', false, 'Enable arm care assessment in Today Hub'),
  ('leaderboards_enabled', false, 'Enable social leaderboards'),
  ('paywall_enabled', false, 'Enable premium paywall gating'),
  ('mode_dashboards_enabled', false, 'Enable mode-specific dashboard sheets in Today Hub'),
  ('body_comp_tools_enabled', false, 'Enable body composition tools in Profile'),
  ('therapist_linking_enabled', false, 'Enable therapist linking in Profile'),

  -- MVP-ON features
  ('weekly_summary_enabled', true, 'Enable weekly summary in Today Hub'),
  ('streak_dashboard_enabled', true, 'Enable streak dashboard in Today Hub')
ON CONFLICT (flag_key) DO NOTHING;
