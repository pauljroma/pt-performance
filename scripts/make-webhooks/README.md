# Make.com Webhook Handlers

Webhook endpoints and automation scenarios for PT Performance Make.com integration.

## Overview

This directory contains Make.com scenario blueprints and Supabase Edge Function handlers for automating patient lifecycle, engagement, and health tracking workflows.

## Scenarios

| # | Scenario | Trigger | Purpose | Est. Cost |
|---|----------|---------|---------|-----------|
| 1 | [Patient Onboarding Flow](#1-patient-onboarding-flow) | New patient row | Welcome sequence, Linear issue, profile reminders | ~$3/mo |
| 2 | [Weekly Health Dashboard](#2-weekly-health-dashboard) | Sunday 8am | Per-patient health stats, AI insights, email tracking | ~$5/mo |
| 3 | [Inactive Re-engagement](#3-inactive-re-engagement) | Daily 9am | 3-tier win-back sequence (Day 7, 14, 21) | ~$4/mo |
| 4 | [Lab Results Processing](#4-lab-results-processing) | Lab PDF upload | AI parsing, biomarker storage, alerts | ~$3/mo |
| 5 | [Recovery Reminders](#5-recovery-reminders) | Hourly | Streak tracking, personalized reminders | ~$2/mo |
| 6 | [Program Auto-Advance](#6-program-auto-advance) | Program completion | Next program enrollment | ~$2/mo |
| 7 | [Readiness Adjustment](#7-readiness-adjustment) | Low readiness logged | Workout modification | ~$3/mo |
| 8 | [Video Generation](#8-video-generation) | Sunday 2am | Batch video creation | ~$1/mo |

**Total Estimated**: ~$23/month in Make.com operations

---

## Scenario Details

### 1. Patient Onboarding Flow

**File**: `scenarios/patient-onboarding.json`

**Trigger**: New row in `patients` table (Supabase webhook)

**Flow**:
1. Receive new patient webhook from Supabase
2. Wait 5 minutes for data sync
3. Fetch therapist info
4. Send welcome email with app download links (iOS/Android)
5. Add to SendGrid "New Patients" list segment
6. Create initial scheduled sessions
7. Send welcome push notification
8. Notify therapist via Slack
9. Create Linear issue for onboarding follow-up
10. Store Linear issue reference in patient record
11. Schedule 3-day profile completion reminder
12. After 3 days, check profile completion
13. If incomplete: send reminder email + push
14. If complete: mark onboarding done, close Linear issue

**Handler**: `handlers/patient-onboarding.ts`

---

### 2. Weekly Health Dashboard

**File**: `scenarios/weekly-dashboard.json`

**Trigger**: Schedule (Sunday 8am ET)

**Flow**:
1. Query all active patients with dashboard enabled
2. For each patient:
   - Fetch weekly workout stats (completion, sets, reps, PRs)
   - Fetch recovery session stats
   - Fetch intermittent fasting stats
   - Fetch supplement adherence
   - Fetch sleep & readiness data
   - Fetch pain & progress notes
   - Generate AI personalized summary
   - Calculate weekly health score (0-100)
   - Compare to previous week
   - Send personalized dashboard email
   - Store report for historical tracking
   - Track email engagement (opens, clicks)
3. Get platform-wide aggregate stats
4. Post summary to Slack #pt-metrics
5. Log batch completion

**Handler**: `handlers/generate-report.ts`

**Email Engagement Tracking**: SendGrid webhook captures opens/clicks and stores in `email_tracking` table.

---

### 3. Inactive Re-engagement

**File**: `scenarios/inactive-reengagement.json`

**Trigger**: Schedule (Daily 9am ET)

**Three-Tier Sequence**:

**Day 7 - "We Miss You"**:
- Find patients inactive for exactly 7 days
- Fetch recent app features
- Send email highlighting new features
- Send push notification
- Log outreach

**Day 14 - "Your Progress is Waiting"**:
- Find patients inactive for ~14 days
- Fetch patient's historical progress stats
- Send email with personalized progress data
- Send push with stats
- Log outreach

**Day 21 - "Special Offer" or Therapist Outreach**:
- Find patients inactive for ~21 days
- Check special offer eligibility
- If eligible: Send offer email + push, create redemption record
- If not eligible: Alert therapist via Slack, create follow-up task, send gentle reminder email
- Log outreach

**Summary**: Daily Slack post with tier breakdown

---

### 4. Lab Results Processing

**File**: `scenarios/lab-results-processing.json`

**Trigger**: Webhook when lab PDF uploaded to `lab_uploads` table

**Flow**:
1. Receive upload webhook
2. Get patient and therapist info
3. Download PDF from Supabase storage
4. Convert PDF to base64
5. Parse with GPT-4 Vision to extract biomarkers
6. Store lab results in `lab_results` table
7. Store individual biomarkers in `biomarkers` table
8. Trigger AI analysis edge function
9. Store AI summary, recommendations, health score
10. **If critical values detected**:
    - Urgent Slack notification
    - Email therapist
    - Push notification to therapist
    - Create urgent follow-up task
    - Send patient notification (contact provider)
11. **If no critical values**:
    - Send patient friendly summary email
    - Send patient push notification
    - Notify therapist via Slack
12. Update upload status to processed
13. Log processing

**Handler**: `handlers/lab-results-processing.ts`

**Supported Lab Types**:
- Comprehensive Metabolic Panel
- Complete Blood Count
- Lipid Panel
- Thyroid Panel
- Hormone Panel
- Vitamin Panel
- Inflammatory Markers
- General

---

### 5. Recovery Reminders

**File**: `scenarios/recovery-reminders.json`

**Trigger**: Schedule (Hourly)

**Flow**:
1. Get current hour, date, day of week
2. Query patients due for reminder at this hour (based on preferences)
3. For each patient:
   - Check if recovery already logged today
   - **If logged**: Update streak, check for milestones
   - **If not logged**:
     - Get current recovery streak
     - Get AI-recommended recovery activity
     - Generate motivational message based on streak
     - Send push notification
     - If second reminder of day: also send email
     - Log reminder sent
4. Award achievement badges for milestones (7, 14, 30, 60, 90, 180, 365 days)
5. Log hourly batch results

**Handler**: `handlers/recovery-reminders.ts`

**Streak Milestones**:
- 7 days: "Week Warrior"
- 14 days: "Fortnight Champion"
- 30 days: "Monthly Master"
- 60 days: "Recovery Rockstar"
- 90 days: "Quarter King/Queen"
- 180 days: "Half-Year Hero"
- 365 days: "Recovery Legend"

---

### 6. Program Auto-Advance

**File**: `scenarios/program-auto-advance.json`

**Trigger**: Supabase webhook on `program_enrollments` update (status = 'completed')

See existing documentation in `docs/AUTOMATION.md`.

---

### 7. Readiness Adjustment

**File**: `scenarios/readiness-adjustment.json`

**Trigger**: Supabase webhook on `daily_readiness` insert

See existing documentation in `docs/AUTOMATION.md`.

---

### 8. Video Generation

**File**: `scenarios/video-generation.json`

**Trigger**: Schedule (Sunday 2am ET)

See existing documentation in `docs/AUTOMATION.md`.

---

## File Structure

```
make-webhooks/
├── README.md                           # This file
├── scenarios/                          # Make.com scenario JSON blueprints
│   ├── patient-onboarding.json         # Patient onboarding flow
│   ├── weekly-dashboard.json           # Weekly health dashboard
│   ├── inactive-reengagement.json      # 3-tier re-engagement sequence
│   ├── lab-results-processing.json     # Lab PDF parsing & analysis
│   ├── recovery-reminders.json         # Recovery streak reminders
│   ├── program-auto-advance.json       # Program completion flow
│   ├── readiness-adjustment.json       # Workout adjustment flow
│   └── video-generation.json           # Exercise video generation
├── handlers/                           # Supabase Edge Functions
│   ├── patient-onboarding.ts           # Onboarding webhook handler
│   ├── generate-report.ts              # Report generation handler
│   ├── lab-results-processing.ts       # Lab processing handler
│   └── recovery-reminders.ts           # Recovery reminder handler
└── templates/                          # Email templates (HTML)
    ├── welcome.html                    # New patient welcome
    ├── complete-profile.html           # Profile completion reminder
    ├── reengagement.html               # Inactive user win-back
    ├── weekly-report.html              # Therapist weekly dashboard
    ├── congratulations.html            # Program completion
    └── recovery-tips.html              # Low readiness day
```

---

## Setup Instructions

### 1. Import Scenarios into Make.com

1. Log into [Make.com](https://www.make.com)
2. Create new scenario
3. Click "..." menu > Import Blueprint
4. Upload the JSON file from `scenarios/`
5. Configure environment variables in scenario settings

### 2. Configure Supabase Webhooks

Enable the `pg_net` extension and create webhook triggers:

```sql
-- Enable pg_net extension
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Patient onboarding trigger
CREATE TRIGGER on_patient_created
AFTER INSERT ON patients
FOR EACH ROW
EXECUTE FUNCTION notify_make_webhook('patient_created');

-- Lab upload trigger
CREATE TRIGGER on_lab_uploaded
AFTER INSERT ON lab_uploads
FOR EACH ROW
EXECUTE FUNCTION notify_make_webhook('lab_uploaded');

-- Program completion trigger
CREATE TRIGGER on_program_completed
AFTER UPDATE ON program_enrollments
FOR EACH ROW
WHEN (NEW.status = 'completed' AND OLD.status != 'completed')
EXECUTE FUNCTION notify_make_webhook('program_completed');

-- Readiness logged trigger
CREATE TRIGGER on_readiness_logged
AFTER INSERT ON daily_readiness
FOR EACH ROW
EXECUTE FUNCTION notify_make_webhook('readiness_logged');
```

### 3. Deploy Edge Functions

```bash
# Deploy all handlers
supabase functions deploy patient-onboarding
supabase functions deploy generate-report
supabase functions deploy lab-results-processing
supabase functions deploy recovery-reminders
supabase functions deploy ai-lab-analysis
supabase functions deploy ai-recovery-recommendation
```

### 4. Environment Variables

Set these in Make.com scenario settings and Supabase:

```
# Supabase
SUPABASE_URL=https://rpbxeaxlaoyoqkohytlw.supabase.co
SUPABASE_ANON_KEY=sb_publishable_...
SUPABASE_SERVICE_KEY=sb_service_...

# SendGrid
SENDGRID_API_KEY=SG.xxx
SENDGRID_NEW_PATIENTS_LIST_ID=...

# Slack
SLACK_WEBHOOK_URL=https://hooks.slack.com/...
SLACK_METRICS_WEBHOOK_URL=https://hooks.slack.com/...
SLACK_URGENT_WEBHOOK_URL=https://hooks.slack.com/...
SLACK_ALERT_WEBHOOK=https://hooks.slack.com/...

# OpenAI
OPENAI_API_KEY=sk-...

# Linear
LINEAR_API_KEY=lin_api_...
LINEAR_ONBOARDING_LABEL_ID=...
LINEAR_COMPLETED_STATE_ID=...

# Make.com Webhooks
PROFILE_REMINDER_WEBHOOK_ID=...
SENDGRID_ENGAGEMENT_WEBHOOK_ID=...
VIDEO_CALLBACK_WEBHOOK_ID=...
```

---

## Webhook Payloads

### Patient Created

```json
{
  "type": "INSERT",
  "table": "patients",
  "record": {
    "id": "uuid",
    "full_name": "John Smith",
    "email": "john@example.com",
    "phone": "+1234567890",
    "therapist_id": "uuid",
    "sport": "basketball",
    "injury_type": "ACL recovery",
    "created_at": "2026-02-02T12:00:00Z"
  }
}
```

### Lab Uploaded

```json
{
  "type": "INSERT",
  "table": "lab_uploads",
  "record": {
    "id": "uuid",
    "patient_id": "uuid",
    "file_path": "patient-uuid/labs/2026-02-02-blood-panel.pdf",
    "file_name": "blood-panel.pdf",
    "lab_type": "comprehensive_metabolic_panel",
    "lab_date": "2026-02-01",
    "created_at": "2026-02-02T12:00:00Z"
  }
}
```

---

## Testing

### Local Testing

```bash
# Test webhook payload
curl -X POST "http://localhost:54321/functions/v1/lab-results-processing" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "INSERT",
    "table": "lab_uploads",
    "record": {
      "id": "test-123",
      "patient_id": "patient-456",
      "file_path": "test/lab.pdf",
      "lab_type": "lipid_panel"
    }
  }'
```

### Make.com Testing

1. Open scenario in Make.com
2. Click "Run once"
3. Trigger the webhook (create patient, upload lab, etc.)
4. Check execution history
5. Verify data in Supabase
6. Check Slack notifications
7. Verify emails in SendGrid Activity

---

## Monitoring

### Make.com Dashboard

- Check scenario run history
- Set up error notifications
- Monitor operation usage
- Review execution logs

### Slack Alerts

Configure alert channels in Make.com:
- `#pt-alerts` - Error notifications
- `#pt-metrics` - Weekly stats
- `#pt-urgent` - Critical lab values

### Supabase Logs

```sql
-- Check recent automation events
SELECT * FROM audit_logs
WHERE action LIKE '%_batch_%'
ORDER BY created_at DESC
LIMIT 20;

-- Check patient communications
SELECT * FROM patient_communications
WHERE created_at > NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC;
```

---

## Cost Estimation

| Scenario | Frequency | Ops/Month | Cost |
|----------|-----------|-----------|------|
| Patient Onboarding | ~20/month | 400 | ~$3 |
| Weekly Dashboard | 4/month | 500 | ~$5 |
| Inactive Re-engagement | Daily | 400 | ~$4 |
| Lab Results Processing | ~30/month | 300 | ~$3 |
| Recovery Reminders | Hourly | 200 | ~$2 |
| Program Auto-Advance | ~30/month | 200 | ~$2 |
| Readiness Adjustment | Daily | 400 | ~$3 |
| Video Generation | Weekly | 100 | ~$1 |
| **Total** | | ~2,500 | **~$23** |

Based on Make.com Core plan ($10.59/month, 10,000 operations).

---

## Troubleshooting

### Scenario Not Triggering

1. Check Supabase webhook is active
2. Verify Make.com webhook URL is correct
3. Check Make.com execution history for errors
4. Test with manual webhook trigger
5. Verify `pg_net` extension is enabled

### Emails Not Delivered

1. Check SendGrid API key is valid
2. Verify sender email is authenticated
3. Check spam folder
4. Review SendGrid Activity Feed
5. Verify template IDs are correct

### AI Parsing Failed

1. Check OpenAI API key is valid
2. Verify PDF is readable (not password protected)
3. Check file size limits
4. Review AI response in logs
5. Fallback: Manual biomarker entry

### Push Notifications Not Sent

1. Verify patient has device registered
2. Check APNs/FCM credentials
3. Review `send-push-notification` function logs
4. Verify notification permissions

---

## Reference

- [Make.com Documentation](https://www.make.com/en/help)
- [Supabase Webhooks](https://supabase.com/docs/guides/database/webhooks)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
- [SendGrid API](https://docs.sendgrid.com/api-reference)
- [Linear API](https://developers.linear.app/docs)
- [OpenAI API](https://platform.openai.com/docs/api-reference)
