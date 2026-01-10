// Build 69: Generate Workload Flags Edge Function (ACP-192)
// Agent 8: Safety & Audit - Backend
//
// Automated workload flag generation using sports science algorithms:
// - Spike Detection: >20% workload increase week-over-week
// - ACWR: Acute:Chronic Workload Ratio (7-day:28-day)
// - Monotony: Low variability in training loads
// - Strain: High cumulative weekly workload
// - Auto-deload triggers based on multiple conditions
//
// Triggered by:
// 1. Daily cron job (scheduled)
// 2. Manual invocation via API
// 3. Post-session completion webhook

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

// ============================================================================
// CONFIGURATION
// ============================================================================

const ENABLE_DETAILED_LOGGING = Deno.env.get('WORKLOAD_FLAGS_DEBUG') === 'true';

interface WorkloadFlagResult {
  patient_id: string;
  status: string;
  acwr: number | null;
  deload: boolean | null;
  error?: string;
}

interface GenerationStats {
  total_patients: number;
  successful: number;
  errors: number;
  high_risk_count: number;
  deload_triggered_count: number;
  execution_time_ms: number;
}

// ============================================================================
// MAIN HANDLER
// ============================================================================

serve(async (req) => {
  const startTime = Date.now();

  try {
    // Get Supabase client with service role (bypasses RLS)
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error('Missing required environment variables');
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Parse request
    const requestData = await req.json().catch(() => ({}));
    const { patient_id, trigger_type = 'manual' } = requestData;

    console.log('Workload flag generation triggered:', {
      trigger_type,
      patient_id: patient_id || 'all',
      timestamp: new Date().toISOString()
    });

    // If specific patient_id provided, generate flags for that patient only
    if (patient_id) {
      const result = await generateFlagsForPatient(supabase, patient_id);

      return new Response(
        JSON.stringify({
          success: result.status === 'success',
          patient_id: result.patient_id,
          acwr: result.acwr,
          deload_triggered: result.deload,
          error: result.error,
          execution_time_ms: Date.now() - startTime
        }),
        {
          headers: { 'Content-Type': 'application/json' },
          status: result.status === 'success' ? 200 : 500
        }
      );
    }

    // Otherwise, generate flags for all active patients
    const results = await generateFlagsForAllPatients(supabase);

    const stats: GenerationStats = {
      total_patients: results.length,
      successful: results.filter(r => r.status === 'success').length,
      errors: results.filter(r => r.status === 'error').length,
      high_risk_count: results.filter(r => r.acwr && r.acwr > 1.5).length,
      deload_triggered_count: results.filter(r => r.deload === true).length,
      execution_time_ms: Date.now() - startTime
    };

    console.log('Workload flag generation complete:', stats);

    // Send alerts for high-risk patients (ACWR > 1.5 or deload triggered)
    const highRiskPatients = results.filter(r =>
      (r.acwr && r.acwr > 1.5) || r.deload === true
    );

    if (highRiskPatients.length > 0) {
      await sendHighRiskAlerts(supabase, highRiskPatients);
    }

    return new Response(
      JSON.stringify({
        success: true,
        stats,
        high_risk_patients: highRiskPatients.map(p => ({
          patient_id: p.patient_id,
          acwr: p.acwr,
          deload_triggered: p.deload
        })),
        trigger_type
      }),
      {
        headers: { 'Content-Type': 'application/json' },
        status: 200
      }
    );

  } catch (error) {
    console.error('Error in workload flag generation:', error);

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
        stack: ENABLE_DETAILED_LOGGING ? error.stack : undefined,
        execution_time_ms: Date.now() - startTime
      }),
      {
        headers: { 'Content-Type': 'application/json' },
        status: 500
      }
    );
  }
});

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Generate workload flags for a single patient
 */
async function generateFlagsForPatient(
  supabase: any,
  patientId: string
): Promise<WorkloadFlagResult> {
  try {
    // Call the database function to generate flags
    const { error: generateError } = await supabase.rpc(
      'generate_workload_flags_for_patient',
      { patient_id_param: patientId }
    );

    if (generateError) {
      throw generateError;
    }

    // Fetch the generated flags
    const { data: flagData, error: fetchError } = await supabase
      .from('workload_flags')
      .select('acwr, deload_triggered')
      .eq('patient_id', patientId)
      .single();

    if (fetchError) {
      throw fetchError;
    }

    return {
      patient_id: patientId,
      status: 'success',
      acwr: flagData?.acwr || null,
      deload: flagData?.deload_triggered || null
    };

  } catch (error) {
    console.error(`Error generating flags for patient ${patientId}:`, error);

    return {
      patient_id: patientId,
      status: 'error',
      acwr: null,
      deload: null,
      error: error.message
    };
  }
}

/**
 * Generate workload flags for all active patients
 */
async function generateFlagsForAllPatients(
  supabase: any
): Promise<WorkloadFlagResult[]> {
  try {
    // Call the database function that processes all patients
    const { data, error } = await supabase.rpc(
      'generate_workload_flags_all_patients'
    );

    if (error) {
      throw error;
    }

    // Transform the results
    const results: WorkloadFlagResult[] = data.map((row: any) => ({
      patient_id: row.patient_id,
      status: row.status,
      acwr: row.acwr,
      deload: row.deload
    }));

    if (ENABLE_DETAILED_LOGGING) {
      console.log('Detailed results:', JSON.stringify(results, null, 2));
    }

    return results;

  } catch (error) {
    console.error('Error generating flags for all patients:', error);
    throw error;
  }
}

/**
 * Send alerts for high-risk patients
 * Options:
 * 1. Create notification in database
 * 2. Send email to therapist
 * 3. Send push notification
 * 4. Log to audit trail
 */
async function sendHighRiskAlerts(
  supabase: any,
  highRiskPatients: WorkloadFlagResult[]
): Promise<void> {
  console.log(`Sending alerts for ${highRiskPatients.length} high-risk patients`);

  for (const patient of highRiskPatients) {
    try {
      // Get patient details
      const { data: patientData, error: patientError } = await supabase
        .from('patients')
        .select('id, first_name, last_name, therapist_id')
        .eq('id', patient.patient_id)
        .single();

      if (patientError) {
        console.error(`Error fetching patient ${patient.patient_id}:`, patientError);
        continue;
      }

      // Create audit log entry
      await supabase.from('audit_logs').insert({
        table_name: 'workload_flags',
        record_id: patient.patient_id,
        action: 'high_risk_detected',
        user_id: null, // System action
        changes: {
          acwr: patient.acwr,
          deload_triggered: patient.deload,
          severity: patient.acwr && patient.acwr > 1.5 ? 'red' : 'yellow'
        },
        timestamp: new Date().toISOString()
      });

      // TODO: Send notification to therapist
      // This could be implemented as:
      // 1. In-app notification via notifications table
      // 2. Email via SendGrid/Postmark
      // 3. SMS via Twilio (for critical alerts)
      // 4. Push notification via FCM/APNs

      console.log(`Alert logged for patient ${patientData.first_name} ${patientData.last_name} (ACWR: ${patient.acwr})`);

    } catch (error) {
      console.error(`Error sending alert for patient ${patient.patient_id}:`, error);
    }
  }
}

/* ============================================================================
   DEPLOYMENT INSTRUCTIONS
   ============================================================================

   1. Deploy this Edge Function:
      ```bash
      supabase functions deploy generate-workload-flags
      ```

   2. Set environment variables (optional):
      ```bash
      supabase secrets set WORKLOAD_FLAGS_DEBUG=false
      ```

   3. Create cron job for daily execution:
      ```sql
      -- Using pg_cron extension
      SELECT cron.schedule(
        'generate-workload-flags-daily',
        '0 2 * * *', -- Run at 2 AM daily
        $$
        SELECT net.http_post(
          url := 'https://your-project.supabase.co/functions/v1/generate-workload-flags',
          headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || current_setting('app.service_role_key')
          ),
          body := jsonb_build_object('trigger_type', 'cron')
        );
        $$
      );
      ```

   4. Alternative: Use Supabase Cron Jobs (recommended)
      - Go to Database > Cron Jobs in Supabase Dashboard
      - Create new job:
        - Name: generate-workload-flags-daily
        - Schedule: 0 2 * * * (2 AM daily)
        - SQL: Call the function URL above

   ============================================================================
   MANUAL TESTING
   ============================================================================

   Test the function locally:
   ```bash
   supabase functions serve generate-workload-flags
   ```

   Test all patients:
   ```bash
   curl -X POST http://localhost:54321/functions/v1/generate-workload-flags \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer YOUR_ANON_KEY" \
     -d '{"trigger_type": "manual"}'
   ```

   Test specific patient:
   ```bash
   curl -X POST http://localhost:54321/functions/v1/generate-workload-flags \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer YOUR_ANON_KEY" \
     -d '{
       "patient_id": "uuid-here",
       "trigger_type": "manual"
     }'
   ```

   ============================================================================
   WEBHOOK TRIGGER (Post-Session Completion)
   ============================================================================

   To trigger workload flag generation after session completion:

   ```sql
   CREATE OR REPLACE FUNCTION trigger_workload_flag_generation()
   RETURNS TRIGGER AS $$
   DECLARE
     function_url TEXT := 'https://your-project.supabase.co/functions/v1/generate-workload-flags';
   BEGIN
     -- Only trigger if session was just completed
     IF NEW.completed = true AND (OLD.completed = false OR OLD.completed IS NULL) THEN
       -- Get patient_id from session
       PERFORM net.http_post(
         url := function_url,
         headers := jsonb_build_object(
           'Content-Type', 'application/json',
           'Authorization', 'Bearer ' || current_setting('app.service_role_key')
         ),
         body := jsonb_build_object(
           'patient_id', (
             SELECT pr.patient_id
             FROM phases ph
             JOIN programs pr ON pr.id = ph.program_id
             WHERE ph.id = NEW.phase_id
           ),
           'trigger_type', 'session_complete'
         )
       );
     END IF;

     RETURN NEW;
   END;
   $$ LANGUAGE plpgsql;

   CREATE TRIGGER after_session_completed
   AFTER UPDATE ON sessions
   FOR EACH ROW
   EXECUTE FUNCTION trigger_workload_flag_generation();
   ```

   ============================================================================
   MONITORING & ALERTS
   ============================================================================

   Monitor function execution:
   ```sql
   -- Check recent workload flag updates
   SELECT
     patient_id,
     acwr,
     high_acwr,
     low_acwr,
     deload_triggered,
     deload_reason,
     calculated_at
   FROM workload_flags
   ORDER BY calculated_at DESC
   LIMIT 20;

   -- Count high-risk patients
   SELECT
     COUNT(*) FILTER (WHERE high_acwr = true) as high_acwr_count,
     COUNT(*) FILTER (WHERE deload_triggered = true) as deload_count,
     COUNT(*) FILTER (WHERE acwr > 1.5) as critical_acwr_count
   FROM workload_flags
   WHERE calculated_at >= now() - interval '7 days';
   ```

   Set up alerts:
   - Email notifications for ACWR > 1.5
   - Dashboard alerts for deload triggers
   - Weekly summary reports for therapists

   ============================================================================
   SPORTS SCIENCE REFERENCES
   ============================================================================

   1. Gabbett TJ (2016): "The training-injury prevention paradox: should
      athletes be training smarter AND harder?"
      - Optimal ACWR: 0.8 - 1.3 (sweet spot zone)
      - High risk: ACWR > 1.5 (2-4x injury risk)

   2. Hulin BT et al. (2016): "Spikes in acute workload are associated with
      increased injury risk in elite cricket fast bowlers"
      - Spikes >20% increase injury risk significantly

   3. Foster C et al. (1998): "Effects of specific versus cross-training on
      running performance"
      - Monotony = Average Load / StdDev Load
      - High monotony (>2.0) + high strain = illness/injury risk

   4. Blanch P & Gabbett TJ (2016): "Has the athlete trained enough to return
      to play safely? The acute:chronic workload ratio permits clinicians to
      quantify a player's risk of subsequent injury"
      - ACWR is the gold standard for readiness assessment

   ============================================================================
*/
