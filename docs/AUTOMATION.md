# PT Performance Automation Guide

Comprehensive documentation for Claude Code skills and Make.com automation scenarios.

## Overview

This automation system reduces manual work for PT Performance by:
- **Claude Code Skills**: One-command workflows for development tasks
- **Make.com Scenarios**: Automated patient lifecycle and engagement workflows

**Estimated Monthly Cost**: ~$16 (Make.com Core + OpenAI API)

### Current Status

| Component | Status |
|-----------|--------|
| Claude Code Skills (10) | Done |
| Webhook Handlers | Done |
| Email Templates | Done |
| Scenario Blueprints | Done |
| Make.com Setup | Pending |
| SendGrid Integration | Pending |
| Production Testing | Pending |

---

## Table of Contents

1. [Claude Code Skills](#claude-code-skills)
   - [High-Priority Skills](#high-priority-skills)
   - [Medium-Priority Skills](#medium-priority-skills)
2. [Make.com Automation](#makecom-automation)
   - [Scenario Overview](#scenario-overview)
   - [Setup Instructions](#setup-instructions)
3. [Integration Architecture](#integration-architecture)
4. [Implementation Roadmap](#implementation-roadmap)
5. [Troubleshooting](#troubleshooting)

---

## Claude Code Skills

Skills are located in `.claude/skills/` and provide one-command workflows.

### High-Priority Skills

#### `/deploy` - One-Command Deployment

Deploy iOS build to TestFlight + push Supabase migrations in one command.

```bash
/deploy        # Auto-increment build number
/deploy 89     # Deploy as build 89
```

**Actions:**
1. Run iOS tests
2. Increment build number (Config.swift + Xcode)
3. Build & archive iOS app
4. Upload to TestFlight
5. Push pending Supabase migrations
6. Tag git release
7. Post to Slack (optional)

**File**: `.claude/skills/deploy.md`

---

#### `/generate-videos` - Batch Video Generation

Generate exercise demonstration videos from a list.

```bash
/generate-videos squat,deadlift,lunge
/generate-videos all-missing
```

**Actions:**
1. Parse exercise list (or query missing videos)
2. Render each via Lottie/Remotion/Runway
3. Upload to Supabase storage
4. Update `exercise_templates` with URLs

**File**: `.claude/skills/generate-videos.md`

---

#### `/patient-report` - Generate Patient Summary

Create therapist-ready patient progress report.

```bash
/patient-report abc123
/patient-report abc123 --email therapist@clinic.com
/patient-report abc123 --format pdf
```

**Actions:**
1. Query patient sessions, readiness, pain logs
2. Calculate adherence, trends, metrics
3. Generate markdown summary
4. Export as PDF (optional)
5. Email to therapist (optional)

**File**: `.claude/skills/patient-report.md`

---

#### `/sync-content` - Sync Exercise Library

Import exercises from external sources.

```bash
/sync-content exercises.csv
/sync-content new-exercises.json
/sync-content --dry-run exercises.csv
```

**Actions:**
1. Parse CSV/JSON input
2. Validate against schema
3. Upsert to `exercise_templates`
4. Generate videos for new exercises
5. Report changes

**File**: `.claude/skills/sync-content.md`

---

#### `/linear-sync` - Sync Linear Issues

Keep Linear issues updated with implementation status.

```bash
/linear-sync
/linear-sync ACP-123
/linear-sync --status
```

**Actions:**
1. Scan recent commits for issue references
2. Update Linear issue status
3. Add implementation notes
4. Link PRs

**File**: `.claude/skills/linear-sync.md`

---

### Medium-Priority Skills

| Skill | Purpose | File |
|-------|---------|------|
| `/db-snapshot` | Create point-in-time backup + upload to S3 | `db-snapshot.md` |
| `/test-rls [table]` | Verify RLS policies work correctly | `test-rls.md` |
| `/analyze-logs` | Summarize recent Supabase/Sentry errors | `analyze-logs.md` |
| `/generate-program [sport]` | Create training program from template | `generate-program.md` |
| `/audit-schema` | Compare local migrations vs remote DB | `audit-schema.md` |

---

## Make.com Automation

### Scenario Overview

| # | Scenario | Trigger | Purpose | Est. Cost |
|---|----------|---------|---------|-----------|
| 1 | Patient Onboarding | New patient row | Welcome email sequence | ~$2/mo |
| 2 | Weekly Dashboard | Monday 8am | Therapist stats report | ~$1/mo |
| 3 | Inactive Re-engagement | Daily 9am | Win-back 7+ day inactive | ~$3/mo |
| 4 | Program Auto-Advance | Program completed | Enroll in next program | ~$2/mo |
| 5 | Readiness Adjustment | Low readiness logged | Modify workout | ~$5/mo |
| 6 | Video Generation | Sunday 2am | Batch video creation | ~$1/mo |

**Total**: ~$14/month in Make.com operations

---

### Scenario 1: Patient Onboarding Sequence

**Trigger**: New row in `patients` table (Supabase webhook)

```
Flow:
1. [Supabase] Watch new patients
2. [Delay] Wait 5 minutes
3. [SendGrid] Send welcome email with app download link
4. [Supabase] Create first scheduled session
5. [Supabase Edge Function] Send push notification
6. [Slack] Notify therapist of new patient
7. [Delay] 24 hours
8. [SendGrid] Send "Complete your profile" reminder (if needed)
```

**Files**:
- `scripts/make-webhooks/scenarios/patient-onboarding.json`
- `scripts/make-webhooks/templates/welcome.html`
- `scripts/make-webhooks/handlers/patient-onboarding.ts`

---

### Scenario 2: Weekly Therapist Dashboard

**Trigger**: Schedule (Every Monday 8am)

```
Flow:
1. [Schedule] Monday 8am
2. [Supabase] Query weekly stats:
   - Active patients count
   - Sessions completed
   - Average adherence rate
   - Patients with pain flags
   - Readiness score distribution
3. [OpenAI] Generate summary paragraph
4. [Google Sheets] Append to tracking sheet
5. [SendGrid] Email therapist with report
6. [Slack] Post to #pt-metrics channel
```

**Files**:
- `scripts/make-webhooks/handlers/generate-report.ts`

---

### Scenario 3: Inactive User Re-engagement

**Trigger**: Schedule (Daily 9am)

```
Flow:
1. [Schedule] Daily 9am
2. [Supabase] Query patients with no session in 7+ days
3. [Iterator] For each inactive patient:
   a. [Supabase Edge Function] ai-workout-recommendation
   b. [SendGrid] Send personalized "We miss you" email
   c. [Supabase Edge Function] send-push-notification
4. [Supabase] Log outreach in patient_communications
5. [Slack] Summary of re-engagement attempts
```

**Files**:
- `scripts/make-webhooks/scenarios/inactive-reengagement.json`
- `scripts/make-webhooks/templates/reengagement.html`

---

### Scenario 4: Program Completion → Auto-Advance

**Trigger**: Supabase webhook on `program_enrollments` update (status = 'completed')

```
Flow:
1. [Supabase] Watch program_enrollments
2. [Supabase] Get patient's current program level
3. [Supabase] Find next program in sequence
4. [Branch] If next program exists:
   a. [Supabase] Create new enrollment
   b. [Supabase Edge Function] generate-scheduled-sessions
   c. [SendGrid] Congratulations email
   d. [Supabase Edge Function] send-push-notification
5. [Branch] If no next program:
   a. [Slack] Alert therapist to assign manually
```

---

### Scenario 5: Daily Readiness → Workout Adjustment

**Trigger**: Supabase webhook on `daily_readiness` insert

```
Flow:
1. [Supabase] Watch new daily_readiness entries
2. [Branch] If readiness_score < 50:
   a. [Supabase Edge Function] trigger-readiness-adjustment
   b. [Supabase Edge Function] send-push-notification
      "Today's workout adjusted based on your readiness"
3. [Branch] If readiness_score < 30:
   a. [Supabase] Mark today's session as "rest day"
   b. [SendGrid] Send recovery tips email
4. [Supabase] Log adjustment in audit_logs
```

---

### Setup Instructions

#### 1. Create Make.com Account

1. Sign up at [make.com](https://www.make.com)
2. Choose Core plan ($10.59/month, 10,000 operations)
3. Connect to your Supabase project

#### 2. Configure Supabase Webhooks

In Supabase Dashboard > Database > Webhooks:

```sql
-- Example: Patient onboarding trigger
CREATE OR REPLACE FUNCTION notify_make_new_patient()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM net.http_post(
    url := 'https://hook.us1.make.com/YOUR_WEBHOOK_ID',
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := json_build_object(
      'type', TG_OP,
      'table', TG_TABLE_NAME,
      'record', row_to_json(NEW)
    )::text
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_patient_created
AFTER INSERT ON patients
FOR EACH ROW EXECUTE FUNCTION notify_make_new_patient();
```

#### 3. Configure External Services

**SendGrid**:
1. Create account at [sendgrid.com](https://sendgrid.com)
2. Create dynamic templates for each email type
3. Get API key and add to Make.com

**Slack**:
1. Create Slack App at [api.slack.com](https://api.slack.com)
2. Add Incoming Webhook
3. Get webhook URL and add to Make.com

**OpenAI** (for AI summaries):
1. Get API key from [platform.openai.com](https://platform.openai.com)
2. Add to Make.com scenario

#### 4. Environment Variables

Set these in Make.com scenario settings:

```
SUPABASE_URL=https://rpbxeaxlaoyoqkohytlw.supabase.co
SUPABASE_ANON_KEY=sb_publishable_...
SUPABASE_SERVICE_KEY=sb_service_...
SENDGRID_API_KEY=SG.xxx
SLACK_WEBHOOK_URL=https://hooks.slack.com/...
OPENAI_API_KEY=sk-...
```

---

## Integration Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     TRIGGERS                                 │
├─────────────────────────────────────────────────────────────┤
│  Supabase Webhooks    │  Scheduled (Cron)  │  Manual/API    │
│  - New patient        │  - Daily 9am       │  - Claude /cmd │
│  - Session complete   │  - Weekly Monday   │  - Admin panel │
│  - Readiness logged   │  - Monthly 1st     │  - Slack slash │
└──────────┬────────────┴────────┬───────────┴───────┬────────┘
           │                     │                   │
           ▼                     ▼                   ▼
┌─────────────────────────────────────────────────────────────┐
│                      MAKE.COM                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ Onboarding  │  │  Reports    │  │ Re-engage   │         │
│  │ Sequence    │  │  Generator  │  │ Inactive    │         │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘         │
└─────────┼────────────────┼────────────────┼─────────────────┘
          │                │                │
          ▼                ▼                ▼
┌─────────────────────────────────────────────────────────────┐
│                  SUPABASE EDGE FUNCTIONS                     │
│  - send-push-notification    - ai-workout-recommendation    │
│  - generate-scheduled-sessions  - trigger-readiness-adjustment │
│  - sync-whoop-recovery       - ai-nutrition-recommendation   │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    EXTERNAL SERVICES                         │
│  SendGrid │ Slack │ Linear │ Stripe │ WHOOP │ OpenAI       │
└─────────────────────────────────────────────────────────────┘
```

---

## Implementation Roadmap

### Phase 0: Foundation (Completed)

- [x] Create all Claude Code skills (10 skills in `.claude/skills/`)
- [x] Create Make.com webhook handlers (`scripts/make-webhooks/handlers/`)
- [x] Create email templates (welcome, reengagement)
- [x] Create scenario blueprints (patient-onboarding, inactive-reengagement)
- [x] Write AUTOMATION.md documentation

### Week 1: Patient Onboarding (Scenario 1)

- [ ] Set up Make.com account
- [ ] Connect Supabase webhook for `patients` table
- [ ] Configure SendGrid for transactional emails
- [ ] Upload welcome email template to SendGrid
- [ ] Create "complete your profile" reminder template
- [ ] Connect Slack notifications for new patients
- [ ] Test end-to-end with test patient

### Week 2: Re-engagement & Auto-Advance (Scenarios 3 & 4)

- [ ] Build inactive user detection query (7+ days)
- [ ] Upload re-engagement email template to SendGrid
- [ ] Connect to `send-push-notification` Edge Function
- [ ] Build program completion webhook trigger
- [ ] Implement auto-enrollment in next program
- [ ] Test re-engagement flow with test patient

### Week 3: Readiness Integration (Scenario 5)

- [ ] Build `daily_readiness` webhook trigger
- [ ] Connect to `trigger-readiness-adjustment` Edge Function
- [ ] Create low-readiness notification flow
- [ ] Add audit logging for adjustments

### Week 4: Polish & Monitoring

- [ ] Build Weekly Dashboard (Scenario 2)
- [ ] Set up error alerting in Make.com
- [ ] Create runbook for common issues
- [ ] Monitor first week of production usage

---

## Cost Estimate

| Service | Monthly Cost |
|---------|-------------|
| Make.com (Core plan) | $10.59 |
| SendGrid (Free tier, up to 100/day) | $0 |
| Slack (Free tier) | $0 |
| OpenAI API (for summaries) | ~$5 |
| **Total** | **~$16/month** |

---

## Troubleshooting

### Make.com Issues

**Scenario not triggering:**
1. Check Supabase webhook is active
2. Verify Make.com webhook URL is correct
3. Check Make.com execution history for errors
4. Test with manual webhook trigger

**SendGrid emails not delivered:**
1. Check SendGrid API key is valid
2. Verify sender email is authenticated
3. Check spam folder
4. Review SendGrid Activity Feed

### Supabase Issues

**Webhook not firing:**
```sql
-- Check if trigger exists
SELECT * FROM pg_trigger WHERE tgname LIKE '%make%';

-- Check if function exists
SELECT * FROM pg_proc WHERE proname LIKE '%notify_make%';

-- Check net extension is enabled
SELECT * FROM pg_extension WHERE extname = 'pg_net';
```

**Edge function timeout:**
1. Increase timeout in function config
2. Add caching for repeated calls
3. Optimize database queries

### Claude Skill Issues

**Skill not recognized:**
1. Verify file is in `.claude/skills/`
2. Check markdown formatting
3. Restart Claude Code session

---

## Files Reference

```
.claude/skills/
├── deploy.md              # /deploy skill
├── generate-videos.md     # /generate-videos skill
├── patient-report.md      # /patient-report skill
├── sync-content.md        # /sync-content skill
├── linear-sync.md         # /linear-sync skill
├── db-snapshot.md         # /db-snapshot skill
├── test-rls.md            # /test-rls skill
├── analyze-logs.md        # /analyze-logs skill
├── generate-program.md    # /generate-program skill
└── audit-schema.md        # /audit-schema skill

scripts/make-webhooks/
├── README.md              # Webhook handlers overview
├── handlers/
│   ├── patient-onboarding.ts
│   └── generate-report.ts
├── templates/
│   ├── welcome.html
│   └── reengagement.html
└── scenarios/
    ├── patient-onboarding.json
    └── inactive-reengagement.json

docs/
└── AUTOMATION.md          # This file
```

---

## Verification Checklist

### Completed
- [x] Claude Code skills created and documented (10 skills)
- [x] Make.com webhook handlers written
- [x] Email templates created (HTML)
- [x] Scenario blueprints defined (JSON)

### Pending (requires Make.com account)
- [ ] Import scenarios into Make.com
- [ ] Test each Make.com scenario with test data
- [ ] Verify Supabase webhooks fire correctly
- [ ] Check email deliverability (SendGrid)
- [ ] Monitor Make.com execution logs for errors
- [ ] Set up Slack alerts for failures
