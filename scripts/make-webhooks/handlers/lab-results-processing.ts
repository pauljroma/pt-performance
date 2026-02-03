/**
 * Lab Results Processing Webhook Handler
 *
 * Supabase Edge Function to handle lab PDF uploads and processing.
 * Called by Make.com when a lab PDF is uploaded.
 *
 * Make.com Scenario: Lab Results Processing
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

interface LabUploadWebhookPayload {
  type: 'INSERT';
  table: 'lab_uploads';
  record: {
    id: string;
    patient_id: string;
    file_path: string;
    file_name: string;
    lab_type: LabType;
    lab_date: string;
    created_at: string;
  };
}

type LabType =
  | 'comprehensive_metabolic_panel'
  | 'complete_blood_count'
  | 'lipid_panel'
  | 'thyroid_panel'
  | 'hormone_panel'
  | 'vitamin_panel'
  | 'inflammatory_markers'
  | 'general';

interface Biomarker {
  name: string;
  value: number;
  unit: string;
  reference_range_low: number;
  reference_range_high: number;
  status: 'normal' | 'low' | 'high' | 'critical_low' | 'critical_high';
  category: string;
}

interface ParsedLabResults {
  biomarkers: Biomarker[];
  lab_name: string;
  collection_date: string;
  report_date: string;
  patient_name: string;
  ordering_physician?: string;
}

interface LabProcessingConfig {
  supabaseUrl: string;
  supabaseServiceKey: string;
  openaiApiKey: string;
  sendgridApiKey: string;
  slackWebhookUrl: string;
  slackUrgentWebhookUrl: string;
}

/**
 * Main handler for lab results processing
 */
export async function handleLabResultsProcessing(
  payload: LabUploadWebhookPayload,
  config: LabProcessingConfig
): Promise<{
  success: boolean;
  lab_result_id?: string;
  biomarkers_count?: number;
  has_critical?: boolean;
  error?: string;
}> {
  const supabase = createClient(config.supabaseUrl, config.supabaseServiceKey);
  const upload = payload.record;

  try {
    // Step 1: Get patient info
    const { data: patient, error: patientError } = await supabase
      .from('patients')
      .select('id, full_name, email, phone, therapist_id, date_of_birth, sex')
      .eq('id', upload.patient_id)
      .single();

    if (patientError) throw new Error(`Failed to fetch patient: ${patientError.message}`);

    // Step 2: Get therapist info
    const { data: therapist } = await supabase
      .from('therapists')
      .select('id, full_name, email, slack_user_id')
      .eq('id', patient.therapist_id)
      .single();

    // Step 3: Download PDF from storage
    const { data: pdfData, error: downloadError } = await supabase.storage
      .from('lab-results')
      .download(upload.file_path);

    if (downloadError) throw new Error(`Failed to download PDF: ${downloadError.message}`);

    // Step 4: Convert PDF to base64 for AI processing
    const pdfBase64 = await blobToBase64(pdfData);

    // Step 5: Parse lab results with AI
    const parsedResults = await parseLabResultsWithAI(
      pdfBase64,
      upload.lab_type,
      patient,
      config.openaiApiKey
    );

    // Step 6: Determine if there are critical values
    const hasCritical = parsedResults.biomarkers.some(
      b => b.status === 'critical_low' || b.status === 'critical_high'
    );
    const abnormalCount = parsedResults.biomarkers.filter(
      b => b.status !== 'normal'
    ).length;

    // Step 7: Store lab results in database
    const { data: labResult, error: labError } = await supabase
      .from('lab_results')
      .insert({
        patient_id: upload.patient_id,
        upload_id: upload.id,
        lab_type: upload.lab_type,
        lab_name: parsedResults.lab_name,
        collection_date: parsedResults.collection_date,
        report_date: parsedResults.report_date,
        ordering_physician: parsedResults.ordering_physician,
        total_biomarkers: parsedResults.biomarkers.length,
        abnormal_count: abnormalCount,
        has_critical_values: hasCritical,
        processed_at: new Date().toISOString(),
        status: 'processed',
      })
      .select()
      .single();

    if (labError) throw new Error(`Failed to store lab results: ${labError.message}`);

    // Step 8: Store individual biomarkers
    const biomarkerRecords = parsedResults.biomarkers.map(b => ({
      patient_id: upload.patient_id,
      lab_result_id: labResult.id,
      name: b.name,
      value: b.value,
      unit: b.unit,
      reference_range_low: b.reference_range_low,
      reference_range_high: b.reference_range_high,
      status: b.status,
      category: b.category,
      collection_date: parsedResults.collection_date,
    }));

    await supabase.from('biomarkers').insert(biomarkerRecords);

    // Step 9: Trigger AI analysis
    const analysis = await triggerAIAnalysis(
      upload.patient_id,
      labResult.id,
      parsedResults.biomarkers,
      patient,
      config
    );

    // Step 10: Update lab result with AI analysis
    await supabase
      .from('lab_results')
      .update({
        ai_summary: analysis.summary,
        ai_recommendations: analysis.recommendations,
        ai_concerns: analysis.concerns,
        health_score: analysis.health_score,
        analysis_completed_at: new Date().toISOString(),
      })
      .eq('id', labResult.id);

    // Step 11: Handle notifications based on critical values
    if (hasCritical) {
      await handleCriticalValues(
        patient,
        therapist,
        labResult.id,
        parsedResults,
        analysis,
        config
      );
    } else {
      await sendNormalResultsNotifications(
        patient,
        therapist,
        labResult.id,
        parsedResults,
        analysis,
        config
      );
    }

    // Step 12: Update upload status
    await supabase
      .from('lab_uploads')
      .update({
        status: 'processed',
        lab_result_id: labResult.id,
        processed_at: new Date().toISOString(),
        biomarkers_extracted: parsedResults.biomarkers.length,
      })
      .eq('id', upload.id);

    // Step 13: Log processing
    await supabase.from('audit_logs').insert({
      action: 'lab_results_processed',
      entity_type: 'lab_result',
      entity_id: labResult.id,
      patient_id: upload.patient_id,
      metadata: {
        upload_id: upload.id,
        lab_type: upload.lab_type,
        biomarkers_count: parsedResults.biomarkers.length,
        abnormal_count: abnormalCount,
        has_critical: hasCritical,
        health_score: analysis.health_score,
      },
    });

    return {
      success: true,
      lab_result_id: labResult.id,
      biomarkers_count: parsedResults.biomarkers.length,
      has_critical: hasCritical,
    };
  } catch (error) {
    console.error('Lab processing failed:', error);

    // Mark upload as failed
    await supabase
      .from('lab_uploads')
      .update({
        status: 'failed',
        error_message: error.message,
        failed_at: new Date().toISOString(),
      })
      .eq('id', upload.id);

    return {
      success: false,
      error: error.message,
    };
  }
}

/**
 * Parse lab results using GPT-4 Vision
 */
async function parseLabResultsWithAI(
  pdfBase64: string,
  labType: LabType,
  patient: { full_name: string; date_of_birth: string; sex: string },
  openaiApiKey: string
): Promise<ParsedLabResults> {
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${openaiApiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-4-vision-preview',
      messages: [
        {
          role: 'system',
          content: `You are a medical lab results parser. Extract all biomarkers from the lab report PDF. For each biomarker, provide:
1. name (standard medical name)
2. value (numeric value)
3. unit (measurement unit)
4. reference_range_low (lower bound of normal range)
5. reference_range_high (upper bound of normal range)
6. status (normal, low, high, critical_low, critical_high)
7. category (e.g., lipid_panel, metabolic_panel, cbc, hormone, vitamin, inflammatory)

Return a JSON object with:
- biomarkers: array of biomarker objects
- lab_name: name of the laboratory
- collection_date: date of sample collection (YYYY-MM-DD format)
- report_date: date of report (YYYY-MM-DD format)
- patient_name: name on the report (for verification)
- ordering_physician: name of ordering physician if present

Be precise with values and units. Mark any values outside reference ranges appropriately.
Values significantly outside normal (>2x deviation) should be marked as critical.`,
        },
        {
          role: 'user',
          content: [
            {
              type: 'text',
              text: `Parse this ${labType} lab report. Patient: ${patient.full_name}, DOB: ${patient.date_of_birth}, Sex: ${patient.sex}`,
            },
            {
              type: 'image_url',
              image_url: {
                url: `data:application/pdf;base64,${pdfBase64}`,
              },
            },
          ],
        },
      ],
      temperature: 0,
      max_tokens: 4000,
      response_format: { type: 'json_object' },
    }),
  });

  const data = await response.json();
  return JSON.parse(data.choices[0].message.content);
}

/**
 * Trigger AI analysis edge function
 */
async function triggerAIAnalysis(
  patientId: string,
  labResultId: string,
  biomarkers: Biomarker[],
  patient: { date_of_birth: string; sex: string },
  config: LabProcessingConfig
): Promise<{
  summary: string;
  recommendations: string[];
  concerns: string[];
  health_score: number;
  highlights: string[];
}> {
  const response = await fetch(
    `${config.supabaseUrl}/functions/v1/ai-lab-analysis`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${config.supabaseServiceKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        patient_id: patientId,
        lab_result_id: labResultId,
        biomarkers,
        patient_context: {
          age: calculateAge(patient.date_of_birth),
          sex: patient.sex,
        },
        include_recommendations: true,
        include_trends: true,
      }),
    }
  );

  return response.json();
}

/**
 * Handle critical values - urgent notifications
 */
async function handleCriticalValues(
  patient: { id: string; full_name: string; email: string; phone: string; therapist_id: string },
  therapist: { id: string; full_name: string; email: string; slack_user_id: string } | null,
  labResultId: string,
  results: ParsedLabResults,
  analysis: { concerns: string[] },
  config: LabProcessingConfig
): Promise<void> {
  const criticalBiomarkers = results.biomarkers.filter(
    b => b.status === 'critical_low' || b.status === 'critical_high'
  );

  // Send urgent Slack notification
  const criticalList = criticalBiomarkers
    .map(b => `- *${b.name}*: ${b.value} ${b.unit} (Range: ${b.reference_range_low}-${b.reference_range_high}) - ${b.status}`)
    .join('\n');

  await fetch(config.slackUrgentWebhookUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      blocks: [
        {
          type: 'header',
          text: { type: 'plain_text', text: 'CRITICAL LAB VALUES DETECTED' },
        },
        {
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: `*Patient:* ${patient.full_name}\n*Lab Date:* ${results.collection_date}\n\n*Critical Values:*\n${criticalList}`,
          },
        },
        {
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: `*AI Concerns:*\n${analysis.concerns.join('\n')}`,
          },
        },
        {
          type: 'actions',
          elements: [
            {
              type: 'button',
              text: { type: 'plain_text', text: 'View Results' },
              style: 'danger',
              url: `https://app.ptperformance.app/patients/${patient.id}/labs/${labResultId}`,
            },
            {
              type: 'button',
              text: { type: 'plain_text', text: 'Call Patient' },
              url: `tel:${patient.phone}`,
            },
          ],
        },
      ],
    }),
  });

  // Send email to therapist
  if (therapist) {
    await sendEmail(
      config.sendgridApiKey,
      therapist.email,
      'd-critical-lab-values-template-id',
      {
        therapist_name: therapist.full_name.split(' ')[0],
        patient_name: patient.full_name,
        collection_date: results.collection_date,
        critical_biomarkers: criticalBiomarkers,
        ai_concerns: analysis.concerns,
        view_results_url: `https://app.ptperformance.app/patients/${patient.id}/labs/${labResultId}`,
      }
    );
  }

  // Send patient notification (advising to contact provider)
  await sendEmail(
    config.sendgridApiKey,
    patient.email,
    'd-lab-results-critical-patient-template-id',
    {
      first_name: patient.full_name.split(' ')[0],
      collection_date: formatDate(results.collection_date),
      therapist_name: therapist?.full_name || 'Your care team',
      message: 'Some of your lab results require attention. Your care team has been notified.',
    }
  );
}

/**
 * Send normal results notifications
 */
async function sendNormalResultsNotifications(
  patient: { id: string; full_name: string; email: string },
  therapist: { full_name: string } | null,
  labResultId: string,
  results: ParsedLabResults,
  analysis: { summary: string; recommendations: string[]; health_score: number; highlights: string[] },
  config: LabProcessingConfig
): Promise<void> {
  // Send patient summary email
  await sendEmail(
    config.sendgridApiKey,
    patient.email,
    'd-lab-results-summary-template-id',
    {
      first_name: patient.full_name.split(' ')[0],
      lab_name: results.lab_name,
      collection_date: formatDate(results.collection_date),
      total_biomarkers: results.biomarkers.length,
      normal_count: results.biomarkers.filter(b => b.status === 'normal').length,
      abnormal_count: results.biomarkers.filter(b => b.status !== 'normal').length,
      health_score: analysis.health_score,
      ai_summary: analysis.summary,
      ai_recommendations: analysis.recommendations,
      key_highlights: analysis.highlights,
      view_full_results_url: `https://app.ptperformance.app/labs/${labResultId}`,
    }
  );

  // Notify therapist via Slack
  await fetch(config.slackWebhookUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      blocks: [
        {
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: `*Lab Results Processed*\n\n*Patient:* ${patient.full_name}\n*Date:* ${results.collection_date}\n*Biomarkers:* ${results.biomarkers.length} total\n*Health Score:* ${analysis.health_score}/100`,
          },
        },
        {
          type: 'actions',
          elements: [
            {
              type: 'button',
              text: { type: 'plain_text', text: 'View Results' },
              url: `https://app.ptperformance.app/patients/${patient.id}/labs/${labResultId}`,
            },
          ],
        },
      ],
    }),
  });
}

// Utility functions
async function blobToBase64(blob: Blob): Promise<string> {
  const arrayBuffer = await blob.arrayBuffer();
  const uint8Array = new Uint8Array(arrayBuffer);
  let binary = '';
  uint8Array.forEach(byte => {
    binary += String.fromCharCode(byte);
  });
  return btoa(binary);
}

function calculateAge(dateOfBirth: string): number {
  const today = new Date();
  const birthDate = new Date(dateOfBirth);
  let age = today.getFullYear() - birthDate.getFullYear();
  const monthDiff = today.getMonth() - birthDate.getMonth();
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
    age--;
  }
  return age;
}

function formatDate(dateStr: string): string {
  const date = new Date(dateStr);
  return date.toLocaleDateString('en-US', {
    month: 'long',
    day: 'numeric',
    year: 'numeric',
  });
}

async function sendEmail(
  apiKey: string,
  to: string,
  templateId: string,
  data: Record<string, unknown>
): Promise<void> {
  await fetch('https://api.sendgrid.com/v3/mail/send', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      personalizations: [
        {
          to: [{ email: to }],
          dynamic_template_data: data,
        },
      ],
      from: { email: 'health@ptperformance.app', name: 'PT Performance' },
      template_id: templateId,
    }),
  });
}

// Edge function handler
serve(async (req) => {
  try {
    const payload = await req.json();

    const config: LabProcessingConfig = {
      supabaseUrl: Deno.env.get('SUPABASE_URL') || '',
      supabaseServiceKey: Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '',
      openaiApiKey: Deno.env.get('OPENAI_API_KEY') || '',
      sendgridApiKey: Deno.env.get('SENDGRID_API_KEY') || '',
      slackWebhookUrl: Deno.env.get('SLACK_WEBHOOK_URL') || '',
      slackUrgentWebhookUrl: Deno.env.get('SLACK_URGENT_WEBHOOK_URL') || '',
    };

    const result = await handleLabResultsProcessing(payload, config);

    return new Response(JSON.stringify(result), {
      headers: { 'Content-Type': 'application/json' },
      status: result.success ? 200 : 500,
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500,
    });
  }
});
