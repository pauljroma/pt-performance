CREATE TABLE IF NOT EXISTS feature_flags (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  flag_key text UNIQUE NOT NULL,
  enabled boolean DEFAULT false NOT NULL,
  description text,
  rollout_percentage integer DEFAULT 100 CHECK (rollout_percentage BETWEEN 0 AND 100),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- RLS: anyone authenticated can read flags (they're not sensitive)
ALTER TABLE feature_flags ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated users can read flags" ON feature_flags
  FOR SELECT TO authenticated USING (true);

-- Seed current flags (matching Config.swift AIConfig)
INSERT INTO feature_flags (flag_key, enabled, description) VALUES
  ('ai_chat_enabled', true, 'Enable AI chat feature'),
  ('ai_substitution_enabled', true, 'Enable AI exercise substitution'),
  ('ai_safety_enabled', true, 'Enable AI safety checks'),
  ('ai_progressive_overload_enabled', true, 'Enable AI progressive overload'),
  ('ai_soap_suggestions_enabled', true, 'Enable AI SOAP note suggestions'),
  ('ai_nutrition_enabled', true, 'Enable AI nutrition recommendations'),
  ('whoop_integration_enabled', false, 'Enable WHOOP wearable integration'),
  ('baseball_pack_enabled', true, 'Enable baseball training pack'),
  ('elite_tier_enabled', true, 'Enable elite subscription tier')
ON CONFLICT (flag_key) DO NOTHING;
