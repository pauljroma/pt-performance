-- Fix RLS on patients table to allow Edge Functions to query
-- Build 82: Fix "Athlete not found" error in ai-chat-completion

-- The service_role bypasses RLS, but let's ensure the table is properly configured
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Service role can read all patients" ON patients;
DROP POLICY IF EXISTS "Edge functions can read patients" ON patients;

-- Create policy for service role (Edge Functions use service_role key)
CREATE POLICY "Service role can read all patients"
ON patients
FOR SELECT
TO service_role
USING (true);

-- Also create policy for authenticated users to read their own patient record
DROP POLICY IF EXISTS "Users can read own patient record" ON patients;
CREATE POLICY "Users can read own patient record"
ON patients
FOR SELECT
TO authenticated
USING (auth.uid() = user_id OR auth.uid() IN (
  SELECT user_id FROM therapists WHERE id = therapist_id
));

-- Ensure RLS is enabled
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;

-- Grant usage to service_role
GRANT SELECT ON patients TO service_role;
GRANT SELECT ON patients TO authenticated;
