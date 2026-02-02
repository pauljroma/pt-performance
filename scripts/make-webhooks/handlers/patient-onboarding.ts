/**
 * Patient Onboarding Webhook Handler
 *
 * Triggered when a new patient is created in Supabase.
 * Handles the welcome email sequence and notifications.
 *
 * Make.com Scenario: Patient Onboarding Sequence
 */

interface PatientWebhookPayload {
  type: 'INSERT';
  table: 'patients';
  record: {
    id: string;
    full_name: string;
    email: string;
    phone?: string;
    therapist_id?: string;
    created_at: string;
  };
}

interface OnboardingConfig {
  sendgridApiKey: string;
  slackWebhookUrl: string;
  supabaseUrl: string;
  supabaseAnonKey: string;
  appDownloadUrl: string;
}

/**
 * Main handler for patient onboarding webhook
 */
export async function handlePatientOnboarding(
  payload: PatientWebhookPayload,
  config: OnboardingConfig
): Promise<{ success: boolean; actions: string[] }> {
  const actions: string[] = [];
  const patient = payload.record;

  try {
    // Step 1: Send welcome email
    await sendWelcomeEmail(patient, config);
    actions.push(`Welcome email sent to ${patient.email}`);

    // Step 2: Create first scheduled session
    await createInitialSession(patient.id, config);
    actions.push('Initial session created');

    // Step 3: Send push notification (if device registered)
    await sendWelcomePush(patient.id, config);
    actions.push('Welcome push notification queued');

    // Step 4: Notify therapist via Slack
    if (patient.therapist_id) {
      await notifyTherapist(patient, config);
      actions.push('Therapist notified via Slack');
    }

    return { success: true, actions };
  } catch (error) {
    console.error('Onboarding failed:', error);
    return { success: false, actions };
  }
}

/**
 * Send welcome email via SendGrid
 */
async function sendWelcomeEmail(
  patient: PatientWebhookPayload['record'],
  config: OnboardingConfig
): Promise<void> {
  const emailData = {
    personalizations: [
      {
        to: [{ email: patient.email, name: patient.full_name }],
        dynamic_template_data: {
          first_name: patient.full_name.split(' ')[0],
          app_download_url: config.appDownloadUrl,
        },
      },
    ],
    from: {
      email: 'hello@ptperformance.app',
      name: 'PT Performance',
    },
    template_id: 'd-welcome-template-id', // SendGrid template ID
  };

  await fetch('https://api.sendgrid.com/v3/mail/send', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${config.sendgridApiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(emailData),
  });
}

/**
 * Create initial session via Supabase Edge Function
 */
async function createInitialSession(
  patientId: string,
  config: OnboardingConfig
): Promise<void> {
  await fetch(
    `${config.supabaseUrl}/functions/v1/generate-scheduled-sessions`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${config.supabaseAnonKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        patient_id: patientId,
        weeks: 1,
        include_onboarding: true,
      }),
    }
  );
}

/**
 * Send welcome push notification
 */
async function sendWelcomePush(
  patientId: string,
  config: OnboardingConfig
): Promise<void> {
  await fetch(
    `${config.supabaseUrl}/functions/v1/send-push-notification`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${config.supabaseAnonKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        patient_id: patientId,
        title: 'Welcome to PT Performance!',
        body: 'Your first session is ready. Tap to get started.',
        data: { screen: 'today' },
      }),
    }
  );
}

/**
 * Notify therapist via Slack
 */
async function notifyTherapist(
  patient: PatientWebhookPayload['record'],
  config: OnboardingConfig
): Promise<void> {
  const message = {
    blocks: [
      {
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: `*New Patient Registered* :wave:\n\n*Name:* ${patient.full_name}\n*Email:* ${patient.email}\n*Time:* ${new Date(patient.created_at).toLocaleString()}`,
        },
      },
      {
        type: 'actions',
        elements: [
          {
            type: 'button',
            text: { type: 'plain_text', text: 'View in Dashboard' },
            url: `https://app.ptperformance.app/patients/${patient.id}`,
          },
        ],
      },
    ],
  };

  await fetch(config.slackWebhookUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(message),
  });
}

/**
 * Schedule follow-up reminder (called by Make.com delay)
 */
export async function scheduleProfileReminder(
  patientId: string,
  config: OnboardingConfig
): Promise<void> {
  // Check if profile is complete
  const response = await fetch(
    `${config.supabaseUrl}/rest/v1/patients?id=eq.${patientId}&select=profile_completed`,
    {
      headers: {
        Authorization: `Bearer ${config.supabaseAnonKey}`,
        apikey: config.supabaseAnonKey,
      },
    }
  );

  const [patient] = await response.json();

  if (!patient?.profile_completed) {
    // Send reminder email
    await fetch('https://api.sendgrid.com/v3/mail/send', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${config.sendgridApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        personalizations: [{ to: [{ email: patient.email }] }],
        from: { email: 'hello@ptperformance.app', name: 'PT Performance' },
        template_id: 'd-complete-profile-template-id',
      }),
    });
  }
}
