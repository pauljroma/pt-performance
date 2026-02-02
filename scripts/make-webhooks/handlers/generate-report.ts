/**
 * Weekly Dashboard Report Generator
 *
 * Called by Make.com on Monday 8am to generate therapist dashboard.
 * Queries Supabase for weekly stats and sends summary email.
 *
 * Make.com Scenario: Weekly Therapist Dashboard
 */

interface ReportConfig {
  supabaseUrl: string;
  supabaseServiceKey: string;
  sendgridApiKey: string;
  openaiApiKey: string;
  googleSheetsId?: string;
  slackWebhookUrl?: string;
}

interface WeeklyStats {
  activePatientsCount: number;
  sessionsCompleted: number;
  averageAdherence: number;
  patientsWithPainFlags: number;
  averageReadiness: number;
  readinessDistribution: { low: number; medium: number; high: number };
  topExercises: { name: string; count: number }[];
}

/**
 * Main handler for weekly report generation
 */
export async function generateWeeklyReport(
  therapistId: string,
  config: ReportConfig
): Promise<{ success: boolean; reportUrl?: string }> {
  try {
    // Step 1: Query weekly stats from Supabase
    const stats = await fetchWeeklyStats(therapistId, config);

    // Step 2: Generate AI summary
    const summary = await generateAISummary(stats, config);

    // Step 3: Format report
    const report = formatReport(stats, summary);

    // Step 4: Append to Google Sheets (optional)
    if (config.googleSheetsId) {
      await appendToSheets(stats, config);
    }

    // Step 5: Send email to therapist
    await sendReportEmail(therapistId, report, config);

    // Step 6: Post to Slack (optional)
    if (config.slackWebhookUrl) {
      await postToSlack(stats, summary, config);
    }

    return { success: true };
  } catch (error) {
    console.error('Report generation failed:', error);
    return { success: false };
  }
}

/**
 * Fetch weekly stats from Supabase
 */
async function fetchWeeklyStats(
  therapistId: string,
  config: ReportConfig
): Promise<WeeklyStats> {
  const headers = {
    Authorization: `Bearer ${config.supabaseServiceKey}`,
    apikey: config.supabaseServiceKey,
    'Content-Type': 'application/json',
  };

  // Active patients count
  const patientsResponse = await fetch(
    `${config.supabaseUrl}/rest/v1/rpc/get_active_patients_count`,
    {
      method: 'POST',
      headers,
      body: JSON.stringify({ therapist_id: therapistId }),
    }
  );
  const activePatientsCount = await patientsResponse.json();

  // Sessions completed this week
  const sessionsResponse = await fetch(
    `${config.supabaseUrl}/rest/v1/rpc/get_weekly_sessions_count`,
    {
      method: 'POST',
      headers,
      body: JSON.stringify({ therapist_id: therapistId }),
    }
  );
  const sessionsCompleted = await sessionsResponse.json();

  // Average adherence rate
  const adherenceResponse = await fetch(
    `${config.supabaseUrl}/rest/v1/rpc/get_average_adherence`,
    {
      method: 'POST',
      headers,
      body: JSON.stringify({ therapist_id: therapistId }),
    }
  );
  const averageAdherence = await adherenceResponse.json();

  // Patients with pain flags
  const painResponse = await fetch(
    `${config.supabaseUrl}/rest/v1/rpc/get_pain_flag_count`,
    {
      method: 'POST',
      headers,
      body: JSON.stringify({ therapist_id: therapistId }),
    }
  );
  const patientsWithPainFlags = await painResponse.json();

  // Readiness stats
  const readinessResponse = await fetch(
    `${config.supabaseUrl}/rest/v1/rpc/get_readiness_stats`,
    {
      method: 'POST',
      headers,
      body: JSON.stringify({ therapist_id: therapistId }),
    }
  );
  const readinessStats = await readinessResponse.json();

  // Top exercises
  const exercisesResponse = await fetch(
    `${config.supabaseUrl}/rest/v1/rpc/get_top_exercises`,
    {
      method: 'POST',
      headers,
      body: JSON.stringify({ therapist_id: therapistId, limit: 5 }),
    }
  );
  const topExercises = await exercisesResponse.json();

  return {
    activePatientsCount,
    sessionsCompleted,
    averageAdherence,
    patientsWithPainFlags,
    averageReadiness: readinessStats.average,
    readinessDistribution: readinessStats.distribution,
    topExercises,
  };
}

/**
 * Generate AI summary using OpenAI
 */
async function generateAISummary(
  stats: WeeklyStats,
  config: ReportConfig
): Promise<string> {
  const prompt = `Generate a brief (2-3 sentences) summary paragraph for a physical therapist's weekly dashboard:

Stats:
- Active patients: ${stats.activePatientsCount}
- Sessions completed: ${stats.sessionsCompleted}
- Average adherence: ${stats.averageAdherence}%
- Patients with pain flags: ${stats.patientsWithPainFlags}
- Average readiness score: ${stats.averageReadiness}/100

Focus on:
1. Overall patient progress
2. Any concerns (low adherence, pain flags)
3. One actionable insight

Keep it professional, concise, and encouraging.`;

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${config.openaiApiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-4-turbo-preview',
      messages: [{ role: 'user', content: prompt }],
      max_tokens: 200,
      temperature: 0.7,
    }),
  });

  const data = await response.json();
  return data.choices[0].message.content;
}

/**
 * Format the report as HTML
 */
function formatReport(stats: WeeklyStats, summary: string): string {
  const weekStart = getWeekStart();
  const weekEnd = getWeekEnd();

  return `
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: #4F46E5; color: white; padding: 20px; border-radius: 8px 8px 0 0; }
    .content { background: #f9fafb; padding: 20px; border-radius: 0 0 8px 8px; }
    .stat-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 16px; margin: 20px 0; }
    .stat-card { background: white; padding: 16px; border-radius: 8px; text-align: center; }
    .stat-value { font-size: 32px; font-weight: bold; color: #4F46E5; }
    .stat-label { color: #6b7280; font-size: 14px; }
    .summary { background: white; padding: 16px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #4F46E5; }
    .alert { background: #fef2f2; border-left: 4px solid #ef4444; padding: 12px; border-radius: 4px; }
  </style>
</head>
<body>
  <div class="header">
    <h1>Weekly Dashboard</h1>
    <p>${weekStart} - ${weekEnd}</p>
  </div>

  <div class="content">
    <div class="summary">
      <h3>AI Summary</h3>
      <p>${summary}</p>
    </div>

    <div class="stat-grid">
      <div class="stat-card">
        <div class="stat-value">${stats.activePatientsCount}</div>
        <div class="stat-label">Active Patients</div>
      </div>
      <div class="stat-card">
        <div class="stat-value">${stats.sessionsCompleted}</div>
        <div class="stat-label">Sessions Completed</div>
      </div>
      <div class="stat-card">
        <div class="stat-value">${stats.averageAdherence}%</div>
        <div class="stat-label">Avg Adherence</div>
      </div>
      <div class="stat-card">
        <div class="stat-value">${stats.averageReadiness}</div>
        <div class="stat-label">Avg Readiness</div>
      </div>
    </div>

    ${stats.patientsWithPainFlags > 0 ? `
    <div class="alert">
      <strong>Attention:</strong> ${stats.patientsWithPainFlags} patient(s) reported pain this week.
      <a href="https://app.ptperformance.app/patients?filter=pain">View details</a>
    </div>
    ` : ''}

    <h3>Top Exercises This Week</h3>
    <ol>
      ${stats.topExercises.map(ex => `<li>${ex.name} (${ex.count} sets)</li>`).join('')}
    </ol>
  </div>
</body>
</html>
  `;
}

/**
 * Append stats to Google Sheets for tracking
 */
async function appendToSheets(
  stats: WeeklyStats,
  config: ReportConfig
): Promise<void> {
  // Google Sheets API call would go here
  // This is typically handled directly in Make.com
  console.log('Appending to Google Sheets:', stats);
}

/**
 * Send report email via SendGrid
 */
async function sendReportEmail(
  therapistId: string,
  reportHtml: string,
  config: ReportConfig
): Promise<void> {
  // First, get therapist email from Supabase
  const therapistResponse = await fetch(
    `${config.supabaseUrl}/rest/v1/therapists?id=eq.${therapistId}&select=email,full_name`,
    {
      headers: {
        Authorization: `Bearer ${config.supabaseServiceKey}`,
        apikey: config.supabaseServiceKey,
      },
    }
  );
  const [therapist] = await therapistResponse.json();

  const emailData = {
    personalizations: [
      {
        to: [{ email: therapist.email, name: therapist.full_name }],
      },
    ],
    from: {
      email: 'reports@ptperformance.app',
      name: 'PT Performance',
    },
    subject: `Weekly Dashboard - ${getWeekStart()}`,
    content: [
      {
        type: 'text/html',
        value: reportHtml,
      },
    ],
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
 * Post summary to Slack
 */
async function postToSlack(
  stats: WeeklyStats,
  summary: string,
  config: ReportConfig
): Promise<void> {
  const message = {
    blocks: [
      {
        type: 'header',
        text: { type: 'plain_text', text: 'Weekly Dashboard' },
      },
      {
        type: 'section',
        text: { type: 'mrkdwn', text: summary },
      },
      {
        type: 'section',
        fields: [
          { type: 'mrkdwn', text: `*Active Patients:* ${stats.activePatientsCount}` },
          { type: 'mrkdwn', text: `*Sessions:* ${stats.sessionsCompleted}` },
          { type: 'mrkdwn', text: `*Adherence:* ${stats.averageAdherence}%` },
          { type: 'mrkdwn', text: `*Readiness:* ${stats.averageReadiness}` },
        ],
      },
    ],
  };

  await fetch(config.slackWebhookUrl!, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(message),
  });
}

// Helper functions
function getWeekStart(): string {
  const now = new Date();
  const day = now.getDay();
  const diff = now.getDate() - day + (day === 0 ? -6 : 1);
  return new Date(now.setDate(diff)).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
  });
}

function getWeekEnd(): string {
  const now = new Date();
  const day = now.getDay();
  const diff = now.getDate() - day + (day === 0 ? 0 : 7);
  return new Date(now.setDate(diff)).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
  });
}
