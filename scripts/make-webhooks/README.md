# Make.com Webhook Handlers

Webhook endpoints and utilities for Make.com automation integration.

## Overview

These handlers support the Make.com automation scenarios for PT Performance:

| Scenario | Trigger | Purpose |
|----------|---------|---------|
| Patient Onboarding | New patient row | Welcome sequence |
| Weekly Dashboard | Monday 8am | Therapist report |
| Inactive Re-engagement | Daily 9am | Win-back emails |
| Program Auto-Advance | Program completion | Next program enrollment |
| Readiness Adjustment | Low readiness | Workout modification |
| Video Generation | Sunday 2am | Batch video creation |

## Setup

### 1. Configure Supabase Webhooks

In Supabase Dashboard > Database > Webhooks:

```sql
-- Patient onboarding trigger
CREATE TRIGGER on_patient_created
AFTER INSERT ON patients
FOR EACH ROW
EXECUTE FUNCTION supabase_functions.http_request(
  'https://hook.us1.make.com/[YOUR_WEBHOOK_ID]',
  'POST',
  '{"Content-Type":"application/json"}',
  '{}',
  '5000'
);
```

### 2. Configure Make.com Scenarios

Import the scenario templates from `scenarios/` directory.

### 3. Set Environment Variables

In Make.com scenario settings:

```
SUPABASE_URL=https://rpbxeaxlaoyoqkohytlw.supabase.co
SUPABASE_ANON_KEY=sb_publishable_...
SENDGRID_API_KEY=SG.xxx
SLACK_WEBHOOK_URL=https://hooks.slack.com/...
```

## Files

```
make-webhooks/
├── README.md                    # This file
├── scenarios/                   # Make.com scenario exports
│   ├── patient-onboarding.json
│   ├── weekly-dashboard.json
│   ├── inactive-reengagement.json
│   ├── program-auto-advance.json
│   ├── readiness-adjustment.json
│   └── video-generation.json
├── templates/                   # Email templates
│   ├── welcome.html
│   ├── complete-profile.html
│   ├── weekly-report.html
│   └── reengagement.html
└── handlers/                    # Custom webhook handlers
    ├── patient-onboarding.ts
    └── generate-report.ts
```

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
    "created_at": "2025-01-30T12:00:00Z"
  }
}
```

### Program Completed

```json
{
  "type": "UPDATE",
  "table": "program_enrollments",
  "record": {
    "id": "uuid",
    "patient_id": "uuid",
    "program_id": "uuid",
    "status": "completed",
    "completed_at": "2025-01-30T12:00:00Z"
  },
  "old_record": {
    "status": "active"
  }
}
```

### Readiness Logged

```json
{
  "type": "INSERT",
  "table": "daily_readiness",
  "record": {
    "id": "uuid",
    "patient_id": "uuid",
    "readiness_score": 45,
    "date": "2025-01-30"
  }
}
```

## Testing

### Local Testing

```bash
# Test webhook payload
curl -X POST "http://localhost:3000/webhook/patient-onboarding" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "INSERT",
    "table": "patients",
    "record": {
      "id": "test-123",
      "full_name": "Test Patient",
      "email": "test@example.com"
    }
  }'
```

### Make.com Testing

1. Open scenario in Make.com
2. Click "Run once"
3. Trigger the webhook (create patient, etc.)
4. Check execution history

## Cost Estimation

| Scenario | Frequency | Operations/Month | Cost |
|----------|-----------|-----------------|------|
| Patient Onboarding | ~20/month | 200 | ~$2 |
| Weekly Dashboard | 4/month | 50 | ~$1 |
| Inactive Re-engagement | Daily | 300 | ~$3 |
| Program Auto-Advance | ~30/month | 150 | ~$2 |
| Readiness Adjustment | Daily | 500 | ~$5 |
| Video Generation | Weekly | 20 | ~$1 |
| **Total** | | ~1,200 | **~$14** |

Based on Make.com Core plan ($10.59/month, 10,000 operations).

## Monitoring

### Make.com Dashboard

- Check scenario run history
- Set up error notifications
- Monitor operation usage

### Slack Alerts

Configure error channel in Make.com:

```json
{
  "channel": "#pt-alerts",
  "username": "Make.com Bot",
  "icon_emoji": ":robot_face:"
}
```

## Reference

- [Make.com Documentation](https://www.make.com/en/help)
- [Supabase Webhooks](https://supabase.com/docs/guides/database/webhooks)
- [SendGrid API](https://docs.sendgrid.com/api-reference)
