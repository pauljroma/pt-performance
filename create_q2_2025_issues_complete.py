#!/usr/bin/env python3
"""
Create Q2 2025 Linear Issues (Builds 81-90)
Total: 100 issues (ACP-316 to ACP-415)

Maps to strategic roadmap epics:
- ACP-275: AI-Driven Program Intelligence (Build 81)
- ACP-276: Parity - Program Builder & Periodization (Build 77)
- ACP-277: Parity - Athlete Assignment & Delivery (Build 82)
- ACP-278: Intelligent Exercise Library (Build 74)
- ACP-279: Pain Interpretation & Safety (Build 73)
- ACP-280: Analytics & Predictive Intelligence (Build 81)
- ACP-281: Collaboration & Communication Hub (Build 83)
- ACP-282: Return-to-Play Intelligence (Build 75, 80)
- ACP-283: Readiness & Auto-Regulation (Build 72, 76)
- ACP-284: Video Intelligence & Form Analysis (Build 86-87)
"""

import os
import requests
import time

GRAPHQL_URL = "https://api.linear.app/graphql"
API_KEY = os.getenv("LINEAR_API_KEY", "lin_api_fMj4OrC0XqallztdPaS0WAmEvcXDlbKA9jULoZNa")
ACP_TEAM_ID = "5296cff8-9c53-4cb3-9df3-ccb83601805e"
ACP_TODO_STATE_ID = "6806266a-71d7-41d2-8fab-b8b84651ea37"

headers = {
    "Authorization": API_KEY,
    "Content-Type": "application/json"
}

def create_issue(title, description, priority=2, parent_id=None):
    """Create a Linear issue with optional parent linking"""
    mutation = """
    mutation CreateIssue($input: IssueCreateInput!) {
        issueCreate(input: $input) {
            success
            issue {
                id
                identifier
                title
                url
            }
        }
    }
    """

    input_data = {
        "teamId": ACP_TEAM_ID,
        "title": title,
        "description": description,
        "priority": priority,
        "stateId": ACP_TODO_STATE_ID
    }

    if parent_id:
        input_data["parentId"] = parent_id

    response = requests.post(
        GRAPHQL_URL,
        json={
            "query": mutation,
            "variables": {"input": input_data}
        },
        headers=headers
    )

    if response.status_code == 200:
        try:
            data = response.json()
            if data and data.get("data", {}).get("issueCreate", {}).get("success"):
                return data["data"]["issueCreate"]["issue"]
            else:
                print(f"  Error: {data}")
        except Exception as e:
            print(f"  Error: {e}")
    else:
        print(f"  HTTP {response.status_code}")
    return None

print("="*80)
print("Creating Q2 2025 Linear Issues (Builds 81-90)")
print("Total: 100 issues (ACP-316 to ACP-415)")
print("="*80)
print()

# ============================================================================
# Build 81: AI Program Generator (ACP-316 to ACP-330) - 15 issues
# Parent: ACP-275 (EPIC-01: AI-Driven Program Intelligence Layer)
# ============================================================================
build_81_issues = [
    {
        "title": "ACP-316: Design AI Program Generator prompt architecture",
        "description": """**Build 81 Agent 1: AI Foundation**

Design the core prompt architecture for AI-assisted program generation.

**Deliverables:**
1. System prompt template with medical context awareness
2. Injury-specific prompt variations (10 common injuries)
3. Evidence citation formatting
4. Contraindication logic integration
5. PT override and feedback loop design

**Prompt Structure:**
- Patient profile (age, injury, training history)
- Medical constraints (surgery date, ROM limitations, pain level)
- Training goals (return-to-sport timeline, performance targets)
- Equipment availability
- Evidence-based exercise selection criteria

**Parent Epic:** ACP-275 (AI-Driven Program Intelligence)
**Priority:** P0 (Critical)
**Estimated Effort:** 6-8 hours
""",
        "priority": 1
    },
    {
        "title": "ACP-317: Create program_templates table + AI metadata schema",
        "description": """**Build 81 Agent 2: Database Schema**

Database schema for AI-generated programs with evidence tracking.

**Schema:**
```sql
CREATE TABLE ai_program_templates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  template_name TEXT NOT NULL,
  injury_type TEXT,
  phase TEXT CHECK (phase IN ('acute', 'subacute', 'return_to_play', 'performance')),
  ai_model_version TEXT,
  evidence_citations JSONB,
  contraindications JSONB,
  success_rate FLOAT,
  pt_approval_rate FLOAT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE ai_program_generations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  template_id UUID REFERENCES ai_program_templates(id),
  patient_id UUID REFERENCES profiles(id),
  therapist_id UUID REFERENCES profiles(id),
  input_context JSONB,
  generated_program JSONB,
  pt_edits JSONB,
  approval_status TEXT CHECK (approval_status IN ('pending', 'approved', 'rejected', 'modified')),
  deployment_timestamp TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Parent Epic:** ACP-275
**Priority:** P0
**Estimated Effort:** 4-6 hours
""",
        "priority": 1
    },
    {
        "title": "ACP-318: Integrate OpenAI/Anthropic API for program generation",
        "description": """**Build 81 Agent 3: AI Integration**

Build API integration layer for AI program generation.

**Service: AIProgramGeneratorService.swift**
- OpenAI GPT-4 or Anthropic Claude integration
- Rate limiting (max 10 generations/hour per PT)
- Cost tracking ($0.05-0.15 per generation)
- Streaming responses for better UX
- Error handling and fallbacks

**Features:**
- Generate 4-week program from injury diagnosis
- Include exercise progressions
- Add evidence citations for each exercise
- Flag contraindications automatically
- Suggest alternative exercises

**Parent Epic:** ACP-275
**Priority:** P0
**Estimated Effort:** 8-10 hours
""",
        "priority": 1
    },
    {
        "title": "ACP-319: Build PT review and approval workflow UI",
        "description": """**Build 81 Agent 4: Review Workflow**

Create UI for PT to review, edit, and approve AI-generated programs.

**Views:**
1. **AIProgramReviewView.swift** - Main review interface
2. **ProgramDiffView.swift** - Show PT edits vs AI suggestions
3. **EvidenceCitationView.swift** - Display research citations
4. **ContraindicationWarningView.swift** - Highlight safety concerns

**Workflow:**
1. PT enters patient profile + injury details
2. AI generates program (streaming 30-60 seconds)
3. PT reviews program with evidence citations
4. PT edits exercises/progressions as needed
5. PT approves and deploys to patient
6. System learns from edits (feedback loop)

**Parent Epic:** ACP-275
**Priority:** P0
**Estimated Effort:** 10-12 hours
""",
        "priority": 1
    },
    {
        "title": "ACP-320: Implement exercise contraindication logic engine",
        "description": """**Build 81 Agent 5: Safety Logic**

Build medical safety engine that prevents contraindicated exercises.

**Contraindication Rules (10 common injuries):**
1. **ACL reconstruction:** No pivoting until week 12+
2. **Rotator cuff repair:** No overhead until week 8+
3. **Achilles tendinopathy:** No jumping until pain-free
4. **Meniscus repair:** No full squat until week 6+
5. **Hamstring strain:** No sprinting until strength >90%
6. **Patellar tendinopathy:** No high-volume jumping
7. **Labral repair:** No external rotation loads until week 12+
8. **Groin strain:** No lateral lunges until pain-free
9. **Ankle sprain:** No single-leg plyos until stable
10. **Chronic ankle instability:** Mandatory balance training

**Implementation:**
- Rule engine with phase-based permissions
- Real-time validation during program creation
- Visual warnings in PT interface
- Override capability (with documentation requirement)

**Parent Epic:** ACP-275
**Priority:** P0
**Estimated Effort:** 8-10 hours
""",
        "priority": 1
    },
    {
        "title": "ACP-321: Build evidence citation database + API",
        "description": """**Build 81 Agent 6: Evidence Layer**

Create evidence citation system for exercise recommendations.

**Database Schema:**
```sql
CREATE TABLE exercise_evidence (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  exercise_id UUID REFERENCES exercise_templates(id),
  citation TEXT,
  pubmed_id TEXT,
  study_quality TEXT CHECK (study_quality IN ('high', 'medium', 'low')),
  evidence_level TEXT CHECK (evidence_level IN ('1A', '1B', '2A', '2B', '3', '4', '5')),
  summary TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Initial Seed:**
- 50+ high-quality citations for common exercises
- PubMed integration for citation lookup
- Evidence hierarchy visualization

**Parent Epic:** ACP-275
**Priority:** P1 (High)
**Estimated Effort:** 6-8 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-322: Implement AI learning from PT edits (feedback loop)",
        "description": """**Build 81 Agent 7: Learning System**

Build feedback loop that improves AI from PT corrections.

**Learning Mechanism:**
1. Track all PT edits to AI-generated programs
2. Store edit patterns (exercise swaps, load adjustments, phase modifications)
3. Weekly batch analysis of common edits
4. Update AI prompt weights based on patterns
5. Measure improvement in approval rate over time

**Metrics to Track:**
- Initial approval rate (target: 70%+)
- Approval rate after 1 month (target: 80%+)
- Approval rate after 3 months (target: 90%+)
- Most common edit types
- PT satisfaction scores

**Parent Epic:** ACP-275
**Priority:** P1 (High)
**Estimated Effort:** 8-10 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-323: Create one-click program deployment system",
        "description": """**Build 81 Agent 8: Deployment**

Streamline program deployment from approval to patient activation.

**Workflow:**
1. PT approves AI-generated program
2. One-click "Deploy to Patient" button
3. System creates scheduled_sessions records
4. Patient receives push notification
5. Program appears in patient's "Today" view
6. Audit trail created for compliance

**Features:**
- Instant deployment (<2 seconds)
- Automatic scheduling based on phase
- Patient notification with welcome message
- Undo capability (within 5 minutes)

**Parent Epic:** ACP-275
**Priority:** P0
**Estimated Effort:** 6-8 hours
""",
        "priority": 1
    },
    {
        "title": "ACP-324: Build AI cost tracking and optimization dashboard",
        "description": """**Build 81 Agent 9: Cost Management**

Monitor and optimize AI API costs.

**Dashboard Metrics:**
- Daily/weekly/monthly AI generation count
- Average cost per generation
- Total monthly spend
- Cost per PT
- Cost per patient onboarded

**Optimization Strategies:**
- Cache common programs (ACL week 1-4, etc.)
- Use smaller models for simple cases
- Batch generations for efficiency
- Rate limiting per PT

**Target Costs:**
- <$0.10 per program generation
- <$5 per patient lifetime (onboarding + adjustments)

**Parent Epic:** ACP-275
**Priority:** P2 (Medium)
**Estimated Effort:** 4-6 hours
""",
        "priority": 3
    },
    {
        "title": "ACP-325: Design program variation generator (deload, progression)",
        "description": """**Build 81 Agent 10: Progression Logic**

Auto-generate program variations for deload weeks and progressions.

**Features:**
1. **Deload Week Generator:**
   - Reduce volume by 40-50%
   - Reduce intensity by 10-20%
   - Maintain movement patterns
   - Every 4th week recommendation

2. **Progression Generator:**
   - Increase load by 2.5-5%
   - Add 1 set when ready
   - Progress exercise difficulty
   - Based on patient performance data

3. **Phase Transition:**
   - Auto-detect readiness for next phase
   - Suggest phase-up criteria
   - Generate bridge weeks

**Parent Epic:** ACP-275
**Priority:** P1 (High)
**Estimated Effort:** 8-10 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-326: Implement AI program quality scoring algorithm",
        "description": """**Build 81 Agent 11: Quality Assurance**

Score AI-generated programs for quality and safety.

**Quality Dimensions (0-100 scale):**
1. **Evidence Quality (0-25):** Citation quality and relevance
2. **Safety Score (0-25):** Contraindication adherence, progression logic
3. **Completeness (0-25):** All phases covered, progression pathways clear
4. **Personalization (0-25):** Patient-specific adaptations

**Automatic Flags:**
- Score <60: Require mandatory PT review
- Score 60-79: Recommended PT review
- Score 80+: Optional PT review (fast-track approval)

**Parent Epic:** ACP-275
**Priority:** P1 (High)
**Estimated Effort:** 6-8 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-327: Build multi-injury program generator",
        "description": """**Build 81 Agent 12: Complex Cases**

Handle patients with multiple concurrent injuries.

**Features:**
- Support 2-3 concurrent injuries
- Detect exercise conflicts (e.g., shoulder + lower back)
- Find exercises that address multiple regions
- Prioritize primary injury
- Phase alignment across injuries

**Example Cases:**
- ACL + shoulder impingement
- Achilles + lower back pain
- Hamstring + hip flexor strain

**Parent Epic:** ACP-275
**Priority:** P2 (Medium)
**Estimated Effort:** 8-10 hours
""",
        "priority": 3
    },
    {
        "title": "ACP-328: Create equipment-aware program adaptation",
        "description": """**Build 81 Agent 13: Equipment Adaptation**

Auto-adapt programs based on available equipment.

**Equipment Profiles:**
1. **Full gym:** Barbells, dumbbells, cables, machines
2. **Minimal:** Dumbbells + bands only
3. **Bodyweight:** No equipment
4. **Home gym:** Barbells + bench + rack

**Adaptation Logic:**
- Auto-swap exercises based on equipment
- Maintain movement pattern (push/pull/squat/hinge)
- Preserve training stimulus
- Flag when equipment swap reduces effectiveness

**Parent Epic:** ACP-275
**Priority:** P2 (Medium)
**Estimated Effort:** 6-8 hours
""",
        "priority": 3
    },
    {
        "title": "ACP-329: Implement AI generation audit trail + compliance logging",
        "description": """**Build 81 Agent 14: Compliance**

Medical-grade audit trail for AI program generations.

**Audit Data:**
- AI model version used
- Input context (patient profile, injury details)
- Generated output
- PT edits and approval decision
- Deployment timestamp
- All evidence citations
- Contraindication checks performed

**Compliance Features:**
- Immutable audit log
- Export for legal/insurance purposes
- HIPAA-compliant storage
- 7-year retention

**Parent Epic:** ACP-275
**Priority:** P0 (Critical)
**Estimated Effort:** 4-6 hours
""",
        "priority": 1
    },
    {
        "title": "ACP-330: Build 81 Integration Testing + Deployment",
        "description": """**Build 81 Final Agent: Integration & Testing**

Integrate all Build 81 features and deploy.

**Integration Tasks:**
1. Add all new Swift files to Xcode
2. Apply database migrations
3. Test AI generation end-to-end
4. Test PT review workflow
5. Test contraindication engine
6. Test deployment to patient
7. Verify audit trails

**Success Metrics:**
- AI generation accuracy: 80%+
- PT approval rate: 70%+
- Average generation time: <60 seconds
- Cost per generation: <$0.10
- Zero contraindication violations

**Deployment:**
- Increment build to 81
- Deploy to TestFlight
- Update Linear to Done

**Parent Epic:** ACP-275
**Priority:** P0
**Estimated Effort:** 8-10 hours
""",
        "priority": 1
    }
]

# ============================================================================
# Build 82: Team Management (ACP-331 to ACP-338) - 8 issues
# Parent: ACP-277 (EPIC-05: Parity - Athlete Assignment & Delivery)
# ============================================================================
build_82_issues = [
    {
        "title": "ACP-331: Create teams and cohorts database schema",
        "description": """**Build 82 Agent 1: Database Schema**

Schema for team management, cohorts, and bulk assignment.

**Schema:**
```sql
CREATE TABLE teams (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID REFERENCES organizations(id),
  team_name TEXT NOT NULL,
  sport TEXT,
  level TEXT CHECK (level IN ('youth', 'high_school', 'college', 'professional', 'adult_rec')),
  season TEXT,
  roster_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE team_cohorts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  team_id UUID REFERENCES teams(id),
  cohort_name TEXT NOT NULL,
  tags JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE team_athletes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  team_id UUID REFERENCES teams(id),
  cohort_id UUID REFERENCES team_cohorts(id),
  athlete_id UUID REFERENCES profiles(id),
  position TEXT,
  jersey_number INT,
  injury_status TEXT,
  active BOOLEAN DEFAULT TRUE,
  joined_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Parent Epic:** ACP-277 (Team Management)
**Priority:** P0
**Estimated Effort:** 4-6 hours
""",
        "priority": 1
    },
    {
        "title": "ACP-332: Build team roster import (CSV/bulk add)",
        "description": """**Build 82 Agent 2: Roster Import**

Bulk import team rosters from CSV.

**Features:**
- CSV upload (name, email, position, jersey number)
- Auto-create athlete accounts
- Send welcome emails
- Assign to team + cohort
- Validation and error handling

**CSV Format:**
```
first_name,last_name,email,position,jersey_number,cohort
John,Smith,john@example.com,QB,12,Varsity
Jane,Doe,jane@example.com,WR,3,Varsity
```

**Success Criteria:**
- Import 50+ athletes in <5 minutes
- Auto-detect duplicate emails
- Preview before final import

**Parent Epic:** ACP-277
**Priority:** P0
**Estimated Effort:** 6-8 hours
""",
        "priority": 1
    },
    {
        "title": "ACP-333: Create multi-athlete dashboard view",
        "description": """**Build 82 Agent 3: Dashboard UI**

Multi-athlete dashboard for team monitoring.

**View: TeamDashboardView.swift**
- Grid view of all athletes
- Status indicators (active, injured, cleared)
- Compliance metrics (% sessions completed)
- Last activity timestamp
- Quick filters (position, cohort, injury status)
- Search by name

**Columns:**
- Name + photo
- Position
- Injury status
- Last workout
- Compliance (7-day %)
- Readiness (today's band)
- Action menu (view details, message, assign program)

**Parent Epic:** ACP-277
**Priority:** P0
**Estimated Effort:** 8-10 hours
""",
        "priority": 1
    },
    {
        "title": "ACP-334: Implement bulk program assignment workflow",
        "description": """**Build 82 Agent 4: Bulk Assignment**

Assign programs to multiple athletes at once.

**Workflow:**
1. PT selects cohort or custom athlete list
2. PT selects program template
3. System shows preview (X athletes will receive Y program)
4. PT confirms and deploys
5. All athletes receive program + notification

**Features:**
- Filter athletes before assignment
- Preview assignment impact
- Schedule start date for all
- Individual customization option
- Undo capability (within 24 hours)

**Success Metrics:**
- Assign program to 50 athletes in <2 minutes

**Parent Epic:** ACP-277
**Priority:** P0
**Estimated Effort:** 6-8 hours
""",
        "priority": 1
    },
    {
        "title": "ACP-335: Build cohort-based filtering and tagging system",
        "description": """**Build 82 Agent 5: Cohorts & Tags**

Flexible cohort and tagging system for athlete groups.

**Cohort Types:**
- Position-based (QB, WR, RB, etc.)
- Injury-based (ACL recovery, shoulder rehab)
- Phase-based (pre-season, in-season, off-season)
- Custom tags

**Features:**
- Create custom cohorts
- Multi-tag athletes
- Dynamic cohort rules (e.g., "all injured athletes")
- Cohort-based analytics
- Bulk tag editing

**Parent Epic:** ACP-277
**Priority:** P1 (High)
**Estimated Effort:** 6-8 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-336: Create team compliance analytics view",
        "description": """**Build 82 Agent 6: Team Analytics**

Team-level compliance and performance analytics.

**Metrics:**
1. **Compliance Rate:** % athletes completing assigned sessions
2. **Injury Rate:** Current injured / total roster
3. **Readiness Distribution:** Green/Yellow/Orange/Red breakdown
4. **Volume Trends:** Team-wide weekly volume
5. **Adherence Score:** Consistency over time

**Visualizations:**
- Team compliance heatmap
- Injury timeline
- Readiness trend chart
- Position-based breakdowns

**Parent Epic:** ACP-277
**Priority:** P1 (High)
**Estimated Effort:** 6-8 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-337: Implement team-level export and reporting",
        "description": """**Build 82 Agent 7: Export & Reporting**

Export team data for compliance and performance reporting.

**Export Formats:**
- CSV (roster, compliance, workload)
- PDF (team summary report)
- Excel (full analytics workbook)

**Report Types:**
1. **Weekly Team Summary:** Compliance, injuries, readiness
2. **Monthly Performance Report:** Volume trends, progression
3. **Season Review:** Full season analytics
4. **Injury Report:** All injuries, timelines, RTP status

**Parent Epic:** ACP-277
**Priority:** P2 (Medium)
**Estimated Effort:** 4-6 hours
""",
        "priority": 3
    },
    {
        "title": "ACP-338: Build 82 Integration Testing + Deployment",
        "description": """**Build 82 Final Agent: Integration & Testing**

Integrate all Build 82 features and deploy.

**Testing:**
1. Import 100-athlete roster via CSV
2. Create 5 cohorts and assign tags
3. Bulk assign program to 50 athletes
4. Verify team dashboard accuracy
5. Test compliance analytics
6. Export team reports

**Success Metrics:**
- <5 minutes to onboard 50 athletes
- Bulk assignment works for 100+ athletes
- Dashboard loads in <2 seconds
- Export generates correctly

**Deployment:**
- Increment build to 82
- Deploy to TestFlight

**Parent Epic:** ACP-277
**Priority:** P0
**Estimated Effort:** 6-8 hours
""",
        "priority": 1
    }
]

# ============================================================================
# Build 83: Training-Linked Nutrition (ACP-339 to ACP-350) - 12 issues
# Parent: ACP-281 (EPIC-09: Collaboration & Communication Hub)
# ============================================================================
build_83_issues = [
    {
        "title": "ACP-339: Design training-linked nutrition schema (pre/intra/post)",
        "description": """**Build 83 Agent 1: Database Schema**

Nutrition tracking linked to training sessions.

**Schema:**
```sql
CREATE TABLE nutrition_targets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES profiles(id),
  training_phase TEXT CHECK (training_phase IN ('pre_workout', 'intra_workout', 'post_workout', 'recovery_day', 'rest_day')),
  calories_target INT,
  protein_grams INT,
  carbs_grams INT,
  fat_grams INT,
  hydration_ml INT,
  timing_window TEXT,  -- "30-60 min before", "within 2 hours after", etc.
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE nutrition_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES profiles(id),
  session_id UUID REFERENCES scheduled_sessions(id),
  meal_type TEXT CHECK (meal_type IN ('pre_workout', 'intra_workout', 'post_workout', 'breakfast', 'lunch', 'dinner', 'snack')),
  calories INT,
  protein_grams INT,
  carbs_grams INT,
  fat_grams INT,
  meal_photo_url TEXT,
  notes TEXT,
  logged_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Parent Epic:** ACP-281 (Communication Hub)
**Priority:** P1 (High)
**Estimated Effort:** 4-6 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-340: Build pre-workout nutrition timing system",
        "description": """**Build 83 Agent 2: Pre-Workout Nutrition**

Pre-workout nutrition recommendations based on session type.

**Features:**
1. **Session-Specific Targets:**
   - Strength: 20-30g protein, 30-40g carbs (90 min before)
   - Conditioning: 40-60g carbs (60 min before)
   - Recovery: Light snack only

2. **Timing Reminders:**
   - Push notification 90 minutes before session
   - Suggested meals/snacks
   - Quick log options

3. **Quick Log UI:**
   - Pre-built meal options (protein shake, oatmeal, banana)
   - Photo upload
   - Manual macro entry

**Parent Epic:** ACP-281
**Priority:** P1 (High)
**Estimated Effort:** 6-8 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-341: Implement post-workout recovery nutrition protocol",
        "description": """**Build 83 Agent 3: Post-Workout Nutrition**

Post-workout nutrition tracking and recommendations.

**Features:**
1. **Anabolic Window Tracking:**
   - Remind within 30-120 min post-workout
   - Target: 20-40g protein, 40-80g carbs (session-dependent)

2. **Session-Linked Logging:**
   - Auto-link to completed session
   - Show session volume (tonnage) → recommend carbs
   - Protein recommendation based on muscle damage

3. **Quick Log Options:**
   - Common post-workout meals (shake, chicken + rice, burrito)
   - Photo + AI macro estimation
   - Manual entry

**Parent Epic:** ACP-281
**Priority:** P1 (High)
**Estimated Effort:** 6-8 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-342: Create intra-workout hydration + carb tracking",
        "description": """**Build 83 Agent 4: Intra-Workout Nutrition**

Track hydration and intra-workout carbs for long sessions.

**Features:**
1. **Hydration Tracking:**
   - Target: 200-400ml per 15 minutes of training
   - Quick log buttons (250ml, 500ml, 1L)
   - Color-coded hydration status

2. **Intra-Workout Carbs (for sessions >90 min):**
   - Recommend 30-60g carbs/hour
   - Quick log (sports drink, gel, banana)

3. **Real-Time Tracking During Session:**
   - In-session quick log widget
   - No disruption to workout flow

**Parent Epic:** ACP-281
**Priority:** P2 (Medium)
**Estimated Effort:** 4-6 hours
""",
        "priority": 3
    },
    {
        "title": "ACP-343: Build photo-based meal logging with AI macro estimation",
        "description": """**Build 83 Agent 5: AI Meal Logging**

AI-powered meal photo analysis for macro estimation.

**Features:**
1. **Photo Upload:**
   - Take photo or upload from gallery
   - Compress and upload to Supabase Storage

2. **AI Macro Estimation:**
   - OpenAI Vision API or Nutritionix API
   - Estimate calories, protein, carbs, fat
   - Confidence score (low/medium/high)

3. **Manual Override:**
   - PT or athlete can edit AI estimates
   - Save custom foods for future

**Accuracy Target:** 80%+ within ±20% of actual macros

**Parent Epic:** ACP-281
**Priority:** P1 (High)
**Estimated Effort:** 8-10 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-344: Implement daily macro targets (training vs rest days)",
        "description": """**Build 83 Agent 6: Macro Periodization**

Adjust daily macro targets based on training vs rest days.

**Logic:**
1. **Training Day:**
   - Higher carbs (+20-30%)
   - Maintain protein
   - Moderate fat

2. **Rest/Recovery Day:**
   - Lower carbs (-20-30%)
   - Higher fat (+10-20%)
   - Maintain protein

3. **Readiness-Linked Adjustments:**
   - Red readiness → reduce calories by 10%
   - Green readiness → standard targets

**UI:**
- Daily macro ring chart
- Progress toward targets
- Meal-by-meal breakdown

**Parent Epic:** ACP-281
**Priority:** P1 (High)
**Estimated Effort:** 6-8 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-345: Create nutrition compliance tracking and streaks",
        "description": """**Build 83 Agent 7: Compliance Gamification**

Track nutrition adherence with streak system.

**Metrics:**
1. **Daily Compliance Score (0-100):**
   - Hit protein target: +40 points
   - Hit calorie target (±10%): +30 points
   - Pre/post workout timing: +30 points

2. **Streaks:**
   - Consecutive days hitting targets
   - Weekly consistency badges
   - Milestone celebrations (7/30/90 days)

3. **Team Leaderboards:**
   - Team average compliance
   - Position-based breakdowns

**Parent Epic:** ACP-281
**Priority:** P2 (Medium)
**Estimated Effort:** 4-6 hours
""",
        "priority": 3
    },
    {
        "title": "ACP-346: Build nutrition dashboard with meal timing visualization",
        "description": """**Build 83 Agent 8: Nutrition Dashboard**

Visual dashboard for nutrition tracking and analysis.

**Visualizations:**
1. **Daily Timeline:**
   - Meals plotted vs training sessions
   - Pre/post workout timing windows highlighted
   - Hydration curve

2. **Macro Breakdown:**
   - Ring charts (protein, carbs, fat)
   - Daily trends (7-day view)
   - Training day vs rest day comparison

3. **Compliance Heatmap:**
   - Calendar view (green = on-target, red = missed)

**Parent Epic:** ACP-281
**Priority:** P1 (High)
**Estimated Effort:** 8-10 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-347: Implement nutrition-to-performance correlation analytics",
        "description": """**Build 83 Agent 9: Performance Analytics**

Correlate nutrition adherence with training performance.

**Analytics:**
1. **Nutrition → Performance Correlation:**
   - Compare sessions with good pre-workout nutrition vs poor
   - Volume/intensity achieved vs macro intake
   - Recovery rate vs post-workout nutrition

2. **Insights:**
   - "You lift 10% more volume when you hit pre-workout carb targets"
   - "Recovery is 15% faster with consistent post-workout protein"

3. **Recommendations:**
   - Auto-adjust targets based on performance data
   - Suggest nutrition changes for performance gains

**Parent Epic:** ACP-281
**Priority:** P2 (Medium)
**Estimated Effort:** 6-8 hours
""",
        "priority": 3
    },
    {
        "title": "ACP-348: Create custom meal plans and recipes library",
        "description": """**Build 83 Agent 10: Meal Planning**

Pre-built meal plans and recipe library.

**Features:**
1. **Meal Plan Templates:**
   - 2000, 2500, 3000, 3500 calorie plans
   - High protein, balanced, low carb variations
   - Training day vs rest day plans

2. **Recipe Library:**
   - 50+ pre-logged recipes with macros
   - Filter by meal type, macros, prep time
   - Shopping list generator

3. **Quick Log from Recipe:**
   - One-tap logging from recipe library
   - Portion size adjustment

**Parent Epic:** ACP-281
**Priority:** P2 (Medium)
**Estimated Effort:** 6-8 hours
""",
        "priority": 3
    },
    {
        "title": "ACP-349: Build nutritionist collaboration features",
        "description": """**Build 83 Agent 11: Nutritionist Integration**

Multi-role collaboration between PT, nutritionist, and athlete.

**Features:**
1. **Nutritionist Role:**
   - View athlete's training schedule
   - Set macro targets based on training phases
   - Comment on meal logs
   - Send meal plan adjustments

2. **Shared Visibility:**
   - PT sees nutrition compliance in dashboard
   - Nutritionist sees training load
   - Athlete sees both plans integrated

3. **Communication:**
   - In-app messaging (nutrition-specific thread)
   - Nutritionist can flag concerns to PT
   - Coordinated care plans

**Parent Epic:** ACP-281
**Priority:** P2 (Medium)
**Estimated Effort:** 8-10 hours
""",
        "priority": 3
    },
    {
        "title": "ACP-350: Build 83 Integration Testing + Deployment",
        "description": """**Build 83 Final Agent: Integration & Testing**

Integrate all Build 83 features and deploy.

**Testing:**
1. Log pre-workout meal 90 min before session
2. Complete training session
3. Log post-workout meal within 2 hours
4. Track hydration during session
5. Upload meal photo and verify AI estimation
6. Check nutrition dashboard accuracy
7. Test PT and nutritionist collaboration

**Success Metrics:**
- 80%+ athletes log pre/post workout nutrition
- AI macro estimation within ±20%
- Nutrition compliance tracked accurately
- Multi-role collaboration works smoothly

**Deployment:**
- Increment build to 83
- Deploy to TestFlight

**Parent Epic:** ACP-281
**Priority:** P0
**Estimated Effort:** 6-8 hours
""",
        "priority": 1
    }
]

# ============================================================================
# Build 84: Training-Safe Fasting (ACP-351 to ACP-358) - 8 issues
# Parent: ACP-281 (EPIC-09: Collaboration & Communication Hub)
# ============================================================================
build_84_issues = [
    {
        "title": "ACP-351: Design fasting protocol schema (16:8, 5:2, etc.)",
        "description": """**Build 84 Agent 1: Database Schema**

Schema for fasting protocols integrated with training.

**Schema:**
```sql
CREATE TABLE fasting_protocols (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES profiles(id),
  protocol_type TEXT CHECK (protocol_type IN ('16:8', '18:6', '20:4', '5:2', 'alternate_day', 'custom')),
  eating_window_start TIME,
  eating_window_end TIME,
  fasting_days JSONB,  -- For 5:2 or alternate day
  training_adjustments JSONB,
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE fasting_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES profiles(id),
  fast_start TIMESTAMPTZ,
  fast_end TIMESTAMPTZ,
  duration_hours FLOAT,
  session_during_fast UUID REFERENCES scheduled_sessions(id),
  energy_level INT CHECK (energy_level BETWEEN 1 AND 10),
  performance_impact TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Parent Epic:** ACP-281
**Priority:** P2 (Medium)
**Estimated Effort:** 4-6 hours
""",
        "priority": 3
    },
    {
        "title": "ACP-352: Implement fasted training safety logic engine",
        "description": """**Build 84 Agent 2: Safety Logic**

Safety rules for training while fasted.

**Safety Rules:**
1. **Safe Fasted Training:**
   - Low-intensity cardio (HR <140)
   - Mobility and yoga
   - Light skill work

2. **Unsafe Fasted Training (require pre-workout fuel):**
   - Heavy strength (>85% 1RM)
   - High-intensity conditioning (HIIT, sprints)
   - Power/plyometric work
   - Sessions >60 minutes

3. **Auto-Recommendations:**
   - If fasted + heavy session scheduled → recommend 20-30g carbs before
   - If fasted + long session → recommend intra-workout carbs
   - If fasted + Red readiness → recommend breaking fast

**Parent Epic:** ACP-281
**Priority:** P1 (High)
**Estimated Effort:** 6-8 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-353: Build fasting window vs training schedule optimizer",
        "description": """**Build 84 Agent 3: Schedule Optimization**

Optimize fasting windows around training schedule.

**Features:**
1. **Auto-Suggest Optimal Windows:**
   - Analyze weekly training schedule
   - Suggest eating window that minimizes fasted heavy sessions
   - Example: If training at 6am, suggest 12pm-8pm eating window (not 16:8 starting at 10am)

2. **Conflict Detection:**
   - Flag when heavy session falls during fasting window
   - Suggest window adjustment or pre-workout fuel

3. **Visual Timeline:**
   - Show fasting window + training sessions on daily timeline
   - Color-code conflicts (red = unsafe, yellow = suboptimal, green = optimal)

**Parent Epic:** ACP-281
**Priority:** P1 (High)
**Estimated Effort:** 6-8 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-354: Create fasting timer with training session awareness",
        "description": """**Build 84 Agent 4: Fasting Timer**

Live fasting timer that alerts for training conflicts.

**Features:**
1. **Live Timer:**
   - Current fast duration (12:34 of 16:00)
   - Time until eating window opens
   - Visual progress ring

2. **Session-Aware Alerts:**
   - "Heavy session in 2 hours - consider breaking fast"
   - "Light session scheduled - safe to continue fasting"

3. **Quick Actions:**
   - Break fast early (log reason)
   - Extend fast (if no training)
   - Log fasted training performance

**Parent Epic:** ACP-281
**Priority:** P1 (High)
**Estimated Effort:** 6-8 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-355: Implement fasted training performance tracking",
        "description": """**Build 84 Agent 5: Performance Tracking**

Track performance during fasted vs fed training.

**Metrics:**
1. **Performance Comparison:**
   - Volume achieved (fasted vs fed)
   - RPE (fasted vs fed)
   - Energy level (1-10 scale)
   - Post-workout recovery rate

2. **Insights:**
   - "Your fasted training volume is 15% lower than fed"
   - "Energy levels are highest when eating window opens 2-3 hours before training"

3. **Recommendations:**
   - Adjust fasting window based on performance data
   - Suggest fasted-appropriate sessions

**Parent Epic:** ACP-281
**Priority:** P2 (Medium)
**Estimated Effort:** 6-8 hours
""",
        "priority": 3
    },
    {
        "title": "ACP-356: Build fasting protocol templates (16:8, 5:2, warrior)",
        "description": """**Build 84 Agent 6: Protocol Templates**

Pre-built fasting protocol templates.

**Templates:**
1. **16:8 (Beginner):** 12pm-8pm eating window
2. **18:6 (Intermediate):** 2pm-8pm eating window
3. **20:4 (Advanced):** 4pm-8pm eating window
4. **5:2:** Normal eating 5 days, 500-600 cal on 2 days
5. **Alternate Day:** Fast every other day
6. **Warrior Diet:** 20:4 with one large evening meal

**For Each Template:**
- Recommended training adjustments
- Sample meal timing
- Common pitfalls
- Success rate data

**Parent Epic:** ACP-281
**Priority:** P2 (Medium)
**Estimated Effort:** 4-6 hours
""",
        "priority": 3
    },
    {
        "title": "ACP-357: Create fasting compliance tracking and analytics",
        "description": """**Build 84 Agent 7: Compliance Analytics**

Track fasting adherence and effectiveness.

**Metrics:**
1. **Compliance Tracking:**
   - % days hitting fasting window target
   - Average fast duration
   - Streak tracking

2. **Body Composition Trends:**
   - Weight trend during fasting protocol
   - Estimated body fat % (if available)
   - Performance metrics (strength maintained?)

3. **Analytics:**
   - Best fasting window for you (performance + adherence)
   - Training day vs rest day fasting comparison
   - Readiness correlation with fasting

**Parent Epic:** ACP-281
**Priority:** P2 (Medium)
**Estimated Effort:** 6-8 hours
""",
        "priority": 3
    },
    {
        "title": "ACP-358: Build 84 Integration Testing + Deployment",
        "description": """**Build 84 Final Agent: Integration & Testing**

Integrate all Build 84 features and deploy.

**Testing:**
1. Set up 16:8 fasting protocol
2. Schedule heavy training session during fast
3. Verify safety alert triggers
4. Log fasted training performance
5. Compare fasted vs fed session data
6. Test fasting timer and notifications
7. Verify schedule optimization suggestions

**Success Metrics:**
- Zero unsafe fasted heavy training sessions
- 80%+ athletes follow recommended windows
- Performance tracking accurate
- Compliance analytics correct

**Deployment:**
- Increment build to 84
- Deploy to TestFlight

**Parent Epic:** ACP-281
**Priority:** P0
**Estimated Effort:** 6-8 hours
""",
        "priority": 1
    }
]

# ============================================================================
# Build 85: Protocol-Based Supplement Stacks (ACP-359 to ACP-368) - 10 issues
# Parent: ACP-281 (EPIC-09: Collaboration & Communication Hub)
# ============================================================================
build_85_issues = [
    {
        "title": "ACP-359: Design supplement protocol schema (training, recovery, sleep)",
        "description": """**Build 85 Agent 1: Database Schema**

Schema for supplement protocols and tracking.

**Schema:**
```sql
CREATE TABLE supplement_protocols (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  protocol_type TEXT CHECK (protocol_type IN ('performance', 'recovery', 'sleep', 'injury_support', 'general_health')),
  supplements JSONB,  -- [{"name": "Creatine", "dose": "5g", "timing": "post_workout"}]
  evidence_citations JSONB,
  contraindications JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE athlete_supplements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES profiles(id),
  protocol_id UUID REFERENCES supplement_protocols(id),
  supplement_name TEXT NOT NULL,
  dose TEXT,
  timing TEXT,  -- "morning", "pre_workout", "post_workout", "before_bed"
  active BOOLEAN DEFAULT TRUE,
  started_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE supplement_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES profiles(id),
  supplement_id UUID REFERENCES athlete_supplements(id),
  taken_at TIMESTAMPTZ DEFAULT NOW(),
  dose_taken TEXT,
  session_linked UUID REFERENCES scheduled_sessions(id)
);
```

**Parent Epic:** ACP-281
**Priority:** P2 (Medium)
**Estimated Effort:** 4-6 hours
""",
        "priority": 3
    },
    {
        "title": "ACP-360: Create evidence-based supplement protocol library",
        "description": """**Build 85 Agent 2: Protocol Library**

Build library of evidence-based supplement protocols.

**Performance Protocols:**
1. **Strength & Power:**
   - Creatine 5g/day (post-workout)
   - Caffeine 3-6mg/kg (pre-workout)
   - Beta-alanine 3-6g/day (split doses)
   - Citations: ISSN Position Stand

2. **Endurance:**
   - Beetroot juice 500ml (2 hours pre)
   - Sodium bicarbonate 0.3g/kg (for events >60s)
   - Caffeine 3-6mg/kg

3. **Recovery:**
   - Whey protein 20-40g post-workout
   - Tart cherry juice 8oz (2x/day)
   - Omega-3 2-4g/day
   - Magnesium 400mg (before bed)

4. **Sleep Quality:**
   - Magnesium glycinate 400mg
   - Glycine 3g
   - Theanine 200mg
   - Melatonin 0.5-3mg (last resort)

5. **Injury Support:**
   - Collagen peptides 15g/day
   - Vitamin C 500mg
   - Curcumin 500mg (2x/day)

**Parent Epic:** ACP-281
**Priority:** P1 (High)
**Estimated Effort:** 8-10 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-361: Implement supplement timing optimizer (training-linked)",
        "description": """**Build 85 Agent 3: Timing Optimization**

Optimize supplement timing around training schedule.

**Features:**
1. **Auto-Schedule Supplements:**
   - Creatine → post-workout (or any consistent time)
   - Caffeine → 30-60 min pre-workout
   - Protein → within 2 hours post-workout
   - Magnesium → 1 hour before bed
   - Beta-alanine → split into 2 doses

2. **Session-Linked Reminders:**
   - "Training in 45 min - take caffeine now"
   - "Session complete - take creatine + protein"

3. **Conflict Detection:**
   - No caffeine within 6 hours of bedtime
   - Separate iron and calcium by 2+ hours

**Parent Epic:** ACP-281
**Priority:** P1 (High)
**Estimated Effort:** 6-8 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-362: Build supplement reminder and compliance tracking",
        "description": """**Build 85 Agent 4: Reminders & Compliance**

Push notifications and compliance tracking for supplements.

**Features:**
1. **Smart Reminders:**
   - Time-based (e.g., 8am for morning stack)
   - Training-based (e.g., 45 min before session)
   - Bedtime-based (e.g., 1 hour before sleep)

2. **Quick Log:**
   - One-tap "Taken" button from notification
   - Mark as skipped with reason
   - Snooze for 15 minutes

3. **Compliance Tracking:**
   - % days hitting protocol
   - Streak tracking
   - Visual calendar (green = taken, red = missed)

**Parent Epic:** ACP-281
**Priority:** P1 (High)
**Estimated Effort:** 6-8 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-363: Create supplement-to-performance correlation analytics",
        "description": """**Build 85 Agent 5: Performance Analytics**

Correlate supplement adherence with training performance.

**Analytics:**
1. **Performance Comparison:**
   - Sessions with pre-workout caffeine vs without
   - Creatine loading phase vs maintenance
   - Recovery rate with vs without recovery stack

2. **Insights:**
   - "You lift 8% more volume on days with caffeine"
   - "Recovery is 20% faster with magnesium + tart cherry"

3. **Personalized Recommendations:**
   - Adjust doses based on performance data
   - Suggest protocol changes
   - Flag non-responders (e.g., creatine non-responder)

**Parent Epic:** ACP-281
**Priority:** P2 (Medium)
**Estimated Effort:** 6-8 hours
""",
        "priority": 3
    },
    {
        "title": "ACP-364: Implement supplement cost tracking and budgeting",
        "description": """**Build 85 Agent 6: Cost Management**

Track supplement costs and optimize for budget.

**Features:**
1. **Cost Database:**
   - Price per serving for common supplements
   - Brand comparisons
   - Bulk purchase discounts

2. **Monthly Budget Tracking:**
   - Current protocol monthly cost
   - Budget alerts
   - Cost-effective alternatives

3. **ROI Analysis:**
   - Cost per performance improvement
   - Essential vs optional supplements
   - Suggest cost-optimized stacks

**Parent Epic:** ACP-281
**Priority:** P2 (Medium)
**Estimated Effort:** 4-6 hours
""",
        "priority": 3
    },
    {
        "title": "ACP-365: Build supplement interaction checker (safety)",
        "description": """**Build 85 Agent 7: Safety Checker**

Check for dangerous supplement interactions.

**Safety Checks:**
1. **Supplement-Supplement Interactions:**
   - Caffeine + ephedrine = dangerous
   - Iron + calcium = absorption conflict
   - Multiple stimulants = excessive dose

2. **Supplement-Medication Interactions:**
   - Blood thinners + omega-3 = bleeding risk
   - Beta blockers + caffeine = conflict
   - Require medical disclaimer

3. **Contraindications:**
   - Pregnancy warnings
   - Age restrictions (<18 for certain supps)
   - Medical condition conflicts

**Parent Epic:** ACP-281
**Priority:** P0 (Critical)
**Estimated Effort:** 6-8 hours
""",
        "priority": 1
    },
    {
        "title": "ACP-366: Create supplement protocol templates for injury recovery",
        "description": """**Build 85 Agent 8: Injury Protocols**

Injury-specific supplement protocols.

**Protocols:**
1. **Tendon/Ligament Repair:**
   - Collagen peptides 15g/day
   - Vitamin C 500mg
   - Gelatin 10g (pre-rehab)

2. **Bone Healing:**
   - Calcium 1000mg
   - Vitamin D 2000 IU
   - Vitamin K2 100mcg

3. **Muscle Strain Recovery:**
   - Protein 1.6g/kg bodyweight
   - Omega-3 2-4g/day
   - Tart cherry juice

4. **Post-Surgery:**
   - Collagen 15g
   - Vitamin C 500mg
   - Bromelain 500mg (inflammation)

**Parent Epic:** ACP-281
**Priority:** P1 (High)
**Estimated Effort:** 6-8 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-367: Build supplement education library with evidence citations",
        "description": """**Build 85 Agent 9: Education Library**

Evidence-based supplement education.

**Content:**
1. **Supplement Profiles (50+ supplements):**
   - What it does
   - Evidence quality (strong, moderate, weak)
   - Effective dose range
   - Timing recommendations
   - Side effects and safety
   - Citations (PubMed links)

2. **Myth Busting:**
   - BCAAs (probably not useful)
   - Glutamine (overhyped)
   - Testosterone boosters (mostly ineffective)

3. **Tier System:**
   - Tier 1: Strong evidence (creatine, caffeine, protein)
   - Tier 2: Moderate evidence (beta-alanine, beetroot)
   - Tier 3: Weak evidence (most "fat burners")

**Parent Epic:** ACP-281
**Priority:** P2 (Medium)
**Estimated Effort:** 8-10 hours
""",
        "priority": 3
    },
    {
        "title": "ACP-368: Build 85 Integration Testing + Deployment",
        "description": """**Build 85 Final Agent: Integration & Testing**

Integrate all Build 85 features and deploy.

**Testing:**
1. Create supplement protocol (strength stack)
2. Test timing optimizer with training schedule
3. Verify reminders trigger correctly
4. Log supplement compliance for 7 days
5. Test interaction checker (caffeine + stimulant)
6. Review performance analytics
7. Test injury protocol assignment

**Success Metrics:**
- 80%+ supplement compliance
- Zero dangerous interactions approved
- Timing optimization reduces missed doses
- Performance correlation insights accurate

**Deployment:**
- Increment build to 85
- Deploy to TestFlight

**Parent Epic:** ACP-281
**Priority:** P0
**Estimated Effort:** 6-8 hours
""",
        "priority": 1
    }
]

# ============================================================================
# Build 86: Training-Driven Sleep Protocols (ACP-369 to ACP-378) - 10 issues
# Parent: ACP-281 (EPIC-09: Collaboration & Communication Hub)
# ============================================================================
build_86_issues = [
    {
        "title": "ACP-369: Design sleep protocol schema (training-linked)",
        "description": """**Build 86 Agent 1: Database Schema**

Schema for sleep tracking integrated with training load.

**Schema:**
```sql
CREATE TABLE sleep_protocols (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES profiles(id),
  target_sleep_duration INTERVAL,
  target_bedtime TIME,
  target_wake_time TIME,
  training_day_adjustment INTERVAL,  -- Extra sleep on heavy days
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE sleep_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES profiles(id),
  sleep_date DATE,
  bedtime TIMESTAMPTZ,
  wake_time TIMESTAMPTZ,
  total_sleep_duration INTERVAL,
  sleep_quality INT CHECK (sleep_quality BETWEEN 1 AND 10),
  resting_hr INT,
  hrv_score INT,
  sessions_next_day JSONB,  -- Linked training sessions
  recovery_score INT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Parent Epic:** ACP-281
**Priority:** P1 (High)
**Estimated Effort:** 4-6 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-370: Implement training load → sleep recommendation algorithm",
        "description": """**Build 86 Agent 2: Sleep Optimization**

Calculate sleep needs based on training load.

**Algorithm:**
1. **Base Sleep Need:** 7-9 hours (athlete-specific baseline)

2. **Training-Day Adjustments:**
   - High volume day (>10,000 kg tonnage): +30-60 min
   - High intensity day (>85% 1RM work): +30-45 min
   - Long conditioning (>60 min): +30-60 min
   - Competition day: +60-90 min

3. **Recovery Debt Tracking:**
   - If sleep < target for 3+ days → increase target by 60 min
   - If readiness Red 2+ days → mandate 9+ hours

4. **Smart Bedtime Recommendations:**
   - Calculate optimal bedtime based on:
     - Tomorrow's training schedule
     - Tonight's sleep need
     - Athlete's circadian rhythm

**Parent Epic:** ACP-281
**Priority:** P1 (High)
**Estimated Effort:** 6-8 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-371: Build bedtime reminder system (training-aware)",
        "description": """**Build 86 Agent 3: Bedtime Reminders**

Smart bedtime reminders based on tomorrow's training.

**Features:**
1. **Dynamic Bedtime Calculation:**
   - Tomorrow's first session: 6am
   - Sleep need tonight: 8.5 hours (heavy session today)
   - Optimal bedtime: 9:15pm
   - Reminder at 8:45pm ("Bedtime in 30 min")

2. **Wind-Down Routine:**
   - 60 min before bed: Dim lights, no screens
   - 30 min before bed: Pre-sleep supplement (magnesium)
   - Bedtime: Start sleep tracking

3. **Escalating Reminders:**
   - 60 min before: Gentle reminder
   - 30 min before: Stronger reminder + wind-down tips
   - Bedtime: Final reminder

**Parent Epic:** ACP-281
**Priority:** P1 (High)
**Estimated Effort:** 6-8 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-372: Create sleep quality tracking (subjective + objective)",
        "description": """**Build 86 Agent 4: Sleep Tracking**

Track sleep quality with subjective and objective metrics.

**Subjective Metrics (manual log):**
1. Sleep quality (1-10 scale)
2. How rested do you feel? (1-10)
3. Difficulty falling asleep?
4. Woke up during night?
5. Dream recall?

**Objective Metrics (WHOOP/Oura integration):**
1. Total sleep duration
2. Time in bed
3. Sleep efficiency (sleep / time in bed)
4. REM/Deep/Light breakdown
5. Resting heart rate
6. HRV (heart rate variability)

**Quick Log UI:**
- Morning wake-up prompt
- 30-second log (3-4 taps)
- Auto-import WHOOP/Oura data if available

**Parent Epic:** ACP-281
**Priority:** P1 (High)
**Estimated Effort:** 6-8 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-373: Implement sleep debt tracking and recovery planning",
        "description": """**Build 86 Agent 5: Sleep Debt Management**

Track cumulative sleep debt and plan recovery.

**Features:**
1. **Sleep Debt Calculation:**
   - Daily deficit = target - actual
   - Cumulative debt (rolling 7 days)
   - Critical threshold: 5+ hours debt

2. **Recovery Planning:**
   - Suggest extra sleep on rest days
   - Recommend naps after heavy sessions
   - Flag when debt is affecting performance

3. **Alerts:**
   - Yellow: 3-5 hours debt ("Prioritize sleep tonight")
   - Red: 5+ hours debt ("Cancel non-essential training")
   - Auto-adjust readiness band based on sleep debt

**Parent Epic:** ACP-281
**Priority:** P1 (High)
**Estimated Effort:** 6-8 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-374: Build sleep-to-performance correlation analytics",
        "description": """**Build 86 Agent 6: Performance Analytics**

Correlate sleep quality with training performance.

**Analytics:**
1. **Performance Comparison:**
   - Volume achieved: 8+ hours sleep vs <7 hours
   - RPE difference
   - Injury rate correlation

2. **Insights:**
   - "You lift 12% more volume after 8+ hours sleep"
   - "RPE is 1.5 points lower when well-rested"
   - "Injury risk 3x higher with <6 hours sleep"

3. **Optimal Sleep Duration:**
   - Personalized optimal: 7.5, 8, 8.5, or 9 hours
   - Based on performance data

**Parent Epic:** ACP-281
**Priority:** P2 (Medium)
**Estimated Effort:** 6-8 hours
""",
        "priority": 3
    },
    {
        "title": "ACP-375: Create pre-sleep routine builder and tracking",
        "description": """**Build 86 Agent 7: Sleep Routine**

Build and track personalized pre-sleep routines.

**Routine Components:**
1. **Screen Cutoff:** No screens 60 min before bed
2. **Supplement Stack:** Magnesium, glycine, etc.
3. **Environment:** Room temp 65-68°F, blackout curtains
4. **Activities:** Reading, meditation, stretching
5. **Avoid:** Caffeine after 2pm, alcohol, large meals

**Tracking:**
- Checklist for routine components
- Compliance tracking
- Correlate routine adherence with sleep quality

**Parent Epic:** ACP-281
**Priority:** P2 (Medium)
**Estimated Effort:** 4-6 hours
""",
        "priority": 3
    },
    {
        "title": "ACP-376: Implement nap recommendation system (training-based)",
        "description": """**Build 86 Agent 8: Nap Optimization**

Recommend strategic naps based on training load.

**Nap Logic:**
1. **When to Nap:**
   - After very heavy morning session
   - When sleep debt >3 hours
   - Before evening competition
   - During deload week (recovery maximization)

2. **Optimal Nap Duration:**
   - 20-30 min: Power nap (avoid sleep inertia)
   - 90 min: Full sleep cycle (if time permits)

3. **Timing:**
   - Best: 1-3pm (natural circadian dip)
   - Avoid: After 4pm (disrupts night sleep)

**Features:**
- Nap timer (20 or 90 min)
- Smart alarm
- Log nap and track benefit

**Parent Epic:** ACP-281
**Priority:** P2 (Medium)
**Estimated Effort:** 4-6 hours
""",
        "priority": 3
    },
    {
        "title": "ACP-377: Build sleep environment optimization checklist",
        "description": """**Build 86 Agent 9: Sleep Environment**

Optimize sleep environment for recovery.

**Optimization Checklist:**
1. **Temperature:** 65-68°F (cool room)
2. **Light:** Blackout curtains, no LEDs
3. **Sound:** White noise or earplugs
4. **Mattress:** Medium-firm, <10 years old
5. **Pillow:** Neck support, comfortable
6. **Bedding:** Breathable sheets
7. **Air Quality:** Fresh air circulation

**Assessment:**
- One-time environment audit
- Score each dimension (0-10)
- Prioritized improvement recommendations
- Track changes over time

**Parent Epic:** ACP-281
**Priority:** P2 (Medium)
**Estimated Effort:** 4-6 hours
""",
        "priority": 3
    },
    {
        "title": "ACP-378: Build 86 Integration Testing + Deployment",
        "description": """**Build 86 Final Agent: Integration & Testing**

Integrate all Build 86 features and deploy.

**Testing:**
1. Set sleep protocol (8 hours, 10pm-6am)
2. Complete heavy training session
3. Verify sleep recommendation increases
4. Test bedtime reminder (dynamic calculation)
5. Log sleep quality next morning
6. Track sleep debt accumulation
7. Test nap recommendation after heavy session
8. Verify performance analytics

**Success Metrics:**
- Sleep recommendations accurate (±30 min)
- 80%+ athletes hit sleep targets
- Performance correlation insights correct
- Sleep debt tracking accurate

**Deployment:**
- Increment build to 86
- Deploy to TestFlight

**Parent Epic:** ACP-281
**Priority:** P0
**Estimated Effort:** 6-8 hours
""",
        "priority": 1
    }
]

# ============================================================================
# Build 87: Performance-State Modulation (Mental) (ACP-379 to ACP-388) - 10 issues
# Parent: ACP-284 (EPIC-10: Video Intelligence & Form Analysis)
# ============================================================================
build_87_issues = [
    {
        "title": "ACP-379: Design mental performance protocol schema",
        "description": """**Build 87 Agent 1: Database Schema**

Schema for mental performance protocols (arousal, focus, recovery).

**Schema:**
```sql
CREATE TABLE mental_performance_protocols (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES profiles(id),
  protocol_type TEXT CHECK (protocol_type IN ('pre_competition', 'pre_training', 'recovery', 'sleep', 'focus')),
  target_state TEXT CHECK (target_state IN ('high_arousal', 'calm_focus', 'deep_relaxation', 'flow_state')),
  techniques JSONB,  -- Breathing, visualization, music, etc.
  duration_minutes INT,
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE mental_performance_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES profiles(id),
  protocol_id UUID REFERENCES mental_performance_protocols(id),
  session_id UUID REFERENCES scheduled_sessions(id),
  pre_state_rating INT CHECK (pre_state_rating BETWEEN 1 AND 10),
  post_state_rating INT CHECK (post_state_rating BETWEEN 1 AND 10),
  technique_used TEXT,
  duration_minutes INT,
  effectiveness_rating INT CHECK (effectiveness_rating BETWEEN 1 AND 10),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Parent Epic:** ACP-284
**Priority:** P2 (Medium)
**Estimated Effort:** 4-6 hours
""",
        "priority": 3
    },
    {
        "title": "ACP-380: Build arousal optimization system (psych-up vs calm-down)",
        "description": """**Build 87 Agent 2: Arousal Optimization**

Optimize arousal state for different training types.

**Arousal Profiles:**
1. **High Arousal (for max strength, power, competition):**
   - Techniques: Explosive music, visualization, ammonia, slaps
   - Target: 8-10/10 intensity
   - Duration: 5-10 minutes

2. **Calm Focus (for technical work, rehab, mobility):**
   - Techniques: Box breathing, slow music, meditation
   - Target: 4-6/10 intensity
   - Duration: 3-5 minutes

3. **Flow State (for conditioning, skill practice):**
   - Techniques: Rhythmic breathing, tempo music
   - Target: 6-7/10 intensity
   - Duration: 5-10 minutes

**Auto-Recommendations:**
- Heavy squat day → suggest high arousal protocol
- Rehab session → suggest calm focus
- Long run → suggest flow state

**Parent Epic:** ACP-284
**Priority:** P1 (High)
**Estimated Effort:** 6-8 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-381: Implement breathing protocol library (box, 4-7-8, Wim Hof)",
        "description": """**Build 87 Agent 3: Breathing Protocols**

Guided breathing protocols for state modulation.

**Protocols:**
1. **Box Breathing (Calm Focus):**
   - Inhale 4s, Hold 4s, Exhale 4s, Hold 4s
   - Repeat 5-10 minutes
   - Use: Pre-rehab, pre-sleep, anxiety reduction

2. **4-7-8 Breathing (Sleep/Relaxation):**
   - Inhale 4s, Hold 7s, Exhale 8s
   - Repeat 4-8 cycles
   - Use: Before bed, post-competition wind-down

3. **Wim Hof (High Arousal):**
   - 30-40 deep breaths, exhale hold
   - Repeat 3-4 rounds
   - Use: Pre-competition, cold exposure prep

4. **Physiological Sigh (Rapid Calm-Down):**
   - Double inhale, long exhale
   - 1-3 cycles
   - Use: Panic/anxiety reset

**Features:**
- Visual breathing timer
- Audio cues
- Progress tracking
- HRV biofeedback (if available)

**Parent Epic:** ACP-284
**Priority:** P1 (High)
**Estimated Effort:** 6-8 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-382: Create visualization and mental rehearsal system",
        "description": """**Build 87 Agent 4: Mental Rehearsal**

Guided visualization for performance enhancement.

**Visualization Types:**
1. **Pre-Competition:**
   - Visualize perfect execution
   - Rehearse key moments
   - Build confidence
   - Duration: 5-10 minutes

2. **Injury Recovery:**
   - Visualize tissue healing
   - Imagine pain-free movement
   - Positive outcome focus

3. **Skill Acquisition:**
   - Mental practice of technique
   - Motor imagery
   - Combine with video review

**Features:**
- Guided audio scripts
- Customizable scenarios
- Progress tracking
- Combine with breathing

**Parent Epic:** ACP-284
**Priority:** P2 (Medium)
**Estimated Effort:** 6-8 hours
""",
        "priority": 3
    },
    {
        "title": "ACP-383: Build music-based arousal modulation (playlist integration)",
        "description": """**Build 87 Agent 5: Music Integration**

Curated playlists for arousal modulation.

**Playlist Categories:**
1. **Psych-Up (High Arousal):**
   - Heavy metal, rap, EDM
   - 140-180 BPM
   - Aggressive, intense

2. **Focus Flow (Medium Arousal):**
   - Lo-fi hip hop, instrumental
   - 90-120 BPM
   - Steady, rhythmic

3. **Calm/Recovery (Low Arousal):**
   - Classical, ambient, nature sounds
   - 60-80 BPM
   - Soothing, relaxing

**Features:**
- Pre-built playlists (Spotify/Apple Music integration)
- Custom playlist creation
- Auto-suggest based on session type
- Track effectiveness (rate playlist after session)

**Parent Epic:** ACP-284
**Priority:** P2 (Medium)
**Estimated Effort:** 6-8 hours
""",
        "priority": 3
    },
    {
        "title": "ACP-384: Implement pre-competition mental routine builder",
        "description": """**Build 87 Agent 6: Competition Prep**

Build personalized pre-competition mental routines.

**Routine Components:**
1. **Timing (T-60 min to T-0):**
   - T-60: Visualization (10 min)
   - T-45: Calm breathing (5 min)
   - T-30: Music psych-up (15 min)
   - T-15: Physical warm-up + cues
   - T-5: Final psych-up (breathing + visualization)
   - T-0: Competition start

2. **Customization:**
   - Sport-specific routines
   - Individual preferences
   - Arousal level titration

3. **Tracking:**
   - Log routine adherence
   - Correlate with performance
   - Refine over time

**Parent Epic:** ACP-284
**Priority:** P2 (Medium)
**Estimated Effort:** 6-8 hours
""",
        "priority": 3
    },
    {
        "title": "ACP-385: Create post-competition recovery protocol (mental)",
        "description": """**Build 87 Agent 7: Mental Recovery**

Mental recovery protocols after competition or hard training.

**Recovery Techniques:**
1. **Immediate Post (0-30 min):**
   - Calm breathing (5-10 min)
   - Gratitude practice
   - Positive self-talk

2. **Evening (2-4 hours post):**
   - Reflection journaling
   - Performance review (what went well)
   - Let go of mistakes

3. **Sleep Prep:**
   - 4-7-8 breathing
   - Progressive muscle relaxation
   - Avoid rumination

**Features:**
- Guided recovery sequences
- Journaling prompts
- Mood tracking (post-competition)

**Parent Epic:** ACP-284
**Priority:** P2 (Medium)
**Estimated Effort:** 4-6 hours
""",
        "priority": 3
    },
    {
        "title": "ACP-386: Build focus and attention training (pre-technical work)",
        "description": """**Build 87 Agent 8: Focus Training**

Attention training for technical skill work.

**Focus Protocols:**
1. **Pre-Technical Session:**
   - 3-5 min focused breathing
   - Attention anchoring (single point of focus)
   - Intention setting

2. **During Session:**
   - Mindful rest between sets
   - Attention reset cues
   - Quality over quantity mindset

3. **Focus Metrics:**
   - Self-rated focus (1-10)
   - Distractions counted
   - Quality of execution

**Use Cases:**
- Pre-rehab (maximum attention to form)
- Skill practice (baseball mechanics, Olympic lifting)
- Technical strength work

**Parent Epic:** ACP-284
**Priority:** P2 (Medium)
**Estimated Effort:** 4-6 hours
""",
        "priority": 3
    },
    {
        "title": "ACP-387: Implement mental performance analytics and insights",
        "description": """**Build 87 Agent 9: Mental Analytics**

Track and analyze mental performance over time.

**Metrics:**
1. **Protocol Effectiveness:**
   - Pre-state vs post-state rating
   - Performance correlation
   - Athlete satisfaction

2. **Trends:**
   - Best protocols for you (personalized)
   - Optimal arousal levels by session type
   - Mental state → performance outcomes

3. **Insights:**
   - "Box breathing improves focus by 30%"
   - "Music psych-up increases max strength by 5%"
   - "Your optimal arousal for heavy squats is 8/10"

**Parent Epic:** ACP-284
**Priority:** P2 (Medium)
**Estimated Effort:** 6-8 hours
""",
        "priority": 3
    },
    {
        "title": "ACP-388: Build 87 Integration Testing + Deployment",
        "description": """**Build 87 Final Agent: Integration & Testing**

Integrate all Build 87 features and deploy.

**Testing:**
1. Create pre-competition mental routine
2. Test box breathing protocol with timer
3. Log arousal state before/after protocol
4. Test music playlist integration
5. Complete visualization session
6. Track mental performance over 7 days
7. Verify analytics and insights

**Success Metrics:**
- Protocols improve state ratings by 2+ points
- 70%+ athletes use mental protocols
- Performance correlation insights accurate
- User satisfaction >4/5

**Deployment:**
- Increment build to 87
- Deploy to TestFlight

**Parent Epic:** ACP-284
**Priority:** P0
**Estimated Effort:** 6-8 hours
""",
        "priority": 1
    }
]

# ============================================================================
# Build 88: WHOOP Integration (ACP-389 to ACP-395) - 7 issues
# Parent: ACP-283 (EPIC-03: Readiness & Auto-Regulation)
# ============================================================================
build_88_issues = [
    {
        "title": "ACP-389: Design WHOOP API integration architecture",
        "description": """**Build 88 Agent 1: API Architecture**

Integrate with WHOOP API for recovery and strain data.

**WHOOP API Endpoints:**
1. **Recovery Data:**
   - Daily recovery score (0-100%)
   - HRV (heart rate variability)
   - Resting heart rate
   - Sleep performance (hours, quality, debt)

2. **Strain Data:**
   - Daily strain score (0-21)
   - Cardiovascular load
   - Activity breakdown

3. **Sleep Data:**
   - Total sleep duration
   - Sleep stages (REM, deep, light, awake)
   - Sleep efficiency
   - Sleep debt

**Authentication:**
- OAuth 2.0 flow
- Secure token storage
- Auto-refresh tokens

**Parent Epic:** ACP-283 (Readiness & Auto-Regulation)
**Priority:** P0 (Critical)
**Estimated Effort:** 6-8 hours
""",
        "priority": 1
    },
    {
        "title": "ACP-390: Implement WHOOP recovery score → readiness band mapping",
        "description": """**Build 88 Agent 2: Recovery Mapping**

Map WHOOP recovery score to PT Performance readiness bands.

**Mapping Algorithm:**
1. **WHOOP Recovery → Readiness Band:**
   - 67-100% (Green) → Green readiness
   - 34-66% (Yellow) → Yellow readiness
   - 0-33% (Red) → Orange/Red readiness

2. **HRV-Based Adjustments:**
   - HRV >20% above baseline → boost to Green
   - HRV >20% below baseline → downgrade band

3. **Sleep Debt Integration:**
   - Sleep debt >3 hours → downgrade band
   - Perfect sleep → boost band

4. **Override Logic:**
   - PT can override auto-mapping
   - Athlete subjective input considered

**Parent Epic:** ACP-283
**Priority:** P0 (Critical)
**Estimated Effort:** 6-8 hours
""",
        "priority": 1
    },
    {
        "title": "ACP-391: Build WHOOP strain → session volume correlation",
        "description": """**Build 88 Agent 3: Strain Analysis**

Correlate WHOOP strain with training volume.

**Features:**
1. **Strain Tracking:**
   - Daily WHOOP strain score
   - Compare to training volume (tonnage)
   - Identify discrepancies (high strain, low volume = poor recovery)

2. **Target Strain Recommendations:**
   - Light training day: 8-12 strain
   - Moderate: 12-16 strain
   - Heavy: 16-20 strain
   - Very heavy: 20-21 strain

3. **Auto-Adjustment:**
   - If strain consistently higher than expected → reduce volume
   - If strain lower than expected → increase intensity

**Parent Epic:** ACP-283
**Priority:** P1 (High)
**Estimated Effort:** 6-8 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-392: Create WHOOP sleep data auto-import + visualization",
        "description": """**Build 88 Agent 4: Sleep Integration**

Auto-import WHOOP sleep data into PT Performance.

**Features:**
1. **Auto-Import (daily):**
   - Total sleep duration
   - Sleep stages breakdown
   - Sleep efficiency
   - Sleep debt
   - Sync every morning at 8am

2. **Visualization:**
   - Sleep timeline (bedtime to wake)
   - Stage breakdown (REM/Deep/Light/Awake)
   - 7-day sleep trend
   - Compare to training load

3. **Insights:**
   - "You slept 20 min less than recommended"
   - "Deep sleep was 15% below average"
   - "Sleep debt increased by 45 min"

**Parent Epic:** ACP-283
**Priority:** P1 (High)
**Estimated Effort:** 6-8 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-393: Implement WHOOP HRV trend analysis + alerts",
        "description": """**Build 88 Agent 5: HRV Monitoring**

Monitor HRV trends and alert on significant changes.

**Features:**
1. **HRV Baseline Calculation:**
   - Rolling 7-day average
   - Personal normal range (mean ± 1 SD)

2. **Trend Analysis:**
   - HRV increasing → improved fitness or recovery
   - HRV decreasing → overreaching or illness

3. **Alerts:**
   - Yellow: HRV >15% below baseline (monitor closely)
   - Red: HRV >25% below baseline (reduce training)
   - Green: HRV >10% above baseline (can push hard)

4. **Visualization:**
   - HRV trend chart (30 days)
   - Baseline + normal range shaded
   - Training load overlay

**Parent Epic:** ACP-283
**Priority:** P1 (High)
**Estimated Effort:** 6-8 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-394: Build WHOOP-driven auto-adjustment integration",
        "description": """**Build 88 Agent 6: Auto-Adjustment**

Integrate WHOOP recovery into existing auto-adjustment system.

**Integration:**
1. **Replace Manual Check-In:**
   - WHOOP recovery auto-populates readiness
   - Athlete can still override with subjective input

2. **Enhanced Auto-Adjustment:**
   - Use WHOOP strain from yesterday
   - Use HRV trend
   - Use sleep debt
   - More accurate adjustment decisions

3. **Feedback Loop:**
   - Track adjustment effectiveness
   - Refine mapping over time
   - Personalize for each athlete

**Parent Epic:** ACP-283
**Priority:** P0 (Critical)
**Estimated Effort:** 8-10 hours
""",
        "priority": 1
    },
    {
        "title": "ACP-395: Build 88 Integration Testing + Deployment",
        "description": """**Build 88 Final Agent: Integration & Testing**

Integrate all Build 88 features and deploy.

**Testing:**
1. Connect WHOOP account via OAuth
2. Import recovery, strain, sleep data
3. Verify readiness band mapping
4. Test HRV alerts
5. Test auto-adjustment with WHOOP data
6. Verify sleep visualization
7. Test strain correlation analytics

**Success Metrics:**
- WHOOP data syncs within 5 minutes of waking
- Readiness band mapping >90% accurate
- HRV alerts trigger correctly
- Auto-adjustment works seamlessly

**Deployment:**
- Increment build to 88
- Deploy to TestFlight

**Parent Epic:** ACP-283
**Priority:** P0
**Estimated Effort:** 6-8 hours
""",
        "priority": 1
    }
]

# ============================================================================
# Build 89: Oura/Apple Watch Integration (ACP-396 to ACP-402) - 7 issues
# Parent: ACP-283 (EPIC-03: Readiness & Auto-Regulation)
# ============================================================================
build_89_issues = [
    {
        "title": "ACP-396: Design multi-wearable integration architecture (Oura, Apple Watch)",
        "description": """**Build 89 Agent 1: Multi-Wearable Architecture**

Unified integration layer for multiple wearables.

**Wearables Supported:**
1. **Oura Ring:**
   - Recovery score
   - Sleep stages
   - HRV, resting HR
   - Activity tracking

2. **Apple Watch:**
   - Workout tracking (HR, calories, duration)
   - Steps, active energy
   - Sleep tracking (watchOS 10+)
   - HRV (Health app)

3. **WHOOP (existing):**
   - Recovery, strain, sleep

**Unified Data Model:**
```sql
CREATE TABLE wearable_connections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES profiles(id),
  wearable_type TEXT CHECK (wearable_type IN ('whoop', 'oura', 'apple_watch', 'garmin')),
  connected_at TIMESTAMPTZ,
  last_sync TIMESTAMPTZ,
  active BOOLEAN DEFAULT TRUE
);

CREATE TABLE wearable_data (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES profiles(id),
  wearable_type TEXT,
  data_type TEXT CHECK (data_type IN ('recovery', 'sleep', 'hrv', 'activity', 'workout')),
  data_json JSONB,
  recorded_at TIMESTAMPTZ,
  synced_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Parent Epic:** ACP-283
**Priority:** P0 (Critical)
**Estimated Effort:** 6-8 hours
""",
        "priority": 1
    },
    {
        "title": "ACP-397: Implement Oura API integration (recovery, sleep, HRV)",
        "description": """**Build 89 Agent 2: Oura Integration**

Integrate with Oura Cloud API.

**Oura API Endpoints:**
1. **Daily Readiness:**
   - Readiness score (0-100)
   - Contributors (sleep, HRV, temperature, activity)
   - Previous night + previous day breakdown

2. **Sleep Data:**
   - Total sleep
   - Sleep stages (REM, deep, light)
   - Sleep efficiency
   - Timing (bedtime, wake time)
   - Restfulness score

3. **Daily Activity:**
   - Steps
   - Active calories
   - Inactivity alerts
   - Training volume

**OAuth Flow:**
- Same pattern as WHOOP
- Secure token storage
- Auto-refresh

**Parent Epic:** ACP-283
**Priority:** P0 (Critical)
**Estimated Effort:** 6-8 hours
""",
        "priority": 1
    },
    {
        "title": "ACP-398: Build Apple Watch HealthKit integration (workouts, HRV, sleep)",
        "description": """**Build 89 Agent 3: Apple Watch Integration**

Integrate with Apple HealthKit for Apple Watch data.

**HealthKit Data Types:**
1. **Workouts:**
   - Workout type (strength, run, HIIT, etc.)
   - Duration
   - Heart rate (avg, max)
   - Active energy (calories)
   - Distance (if applicable)

2. **HRV:**
   - Daily HRV measurements
   - Time of measurement

3. **Sleep (watchOS 10+):**
   - Sleep stages (if available)
   - Total sleep duration
   - Bedtime, wake time

4. **Resting Heart Rate:**
   - Daily resting HR

**HealthKit Permissions:**
- Request read access for all data types
- Background sync capability
- Privacy-focused (no write access needed)

**Parent Epic:** ACP-283
**Priority:** P0 (Critical)
**Estimated Effort:** 8-10 hours
""",
        "priority": 1
    },
    {
        "title": "ACP-399: Create unified recovery score (multi-wearable fusion)",
        "description": """**Build 89 Agent 4: Data Fusion**

Fuse data from multiple wearables into unified recovery score.

**Fusion Logic:**
1. **Prioritization (if multiple devices):**
   - WHOOP recovery > Oura readiness > Apple Watch HRV
   - Use most comprehensive data source
   - Fall back if primary unavailable

2. **Cross-Validation:**
   - Compare WHOOP vs Oura (should be similar)
   - Flag discrepancies (>20% difference)
   - Average if both available

3. **Unified Recovery Score (0-100):**
   - Primary source: WHOOP or Oura
   - Secondary: Apple Watch HRV-based estimate
   - Tertiary: Manual check-in

**Visualization:**
- Show all sources (WHOOP 85%, Oura 82%, Unified 84%)
- Indicate which source is primary

**Parent Epic:** ACP-283
**Priority:** P1 (High)
**Estimated Effort:** 6-8 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-400: Implement Apple Watch workout auto-import",
        "description": """**Build 89 Agent 5: Workout Import**

Auto-import Apple Watch workouts into PT Performance.

**Features:**
1. **Workout Detection:**
   - Detect completed workouts from HealthKit
   - Match to scheduled PT Performance sessions
   - Auto-link if timing matches (±30 min)

2. **Data Import:**
   - Duration
   - Heart rate (avg, max)
   - Calories burned
   - Training zones (if available)

3. **Unscheduled Workout Handling:**
   - If workout not in schedule → suggest adding
   - Quick-add as "Extra Cardio" or "Unplanned Strength"

**Smart Matching:**
- "Outdoor Run" → Cardio session
- "Traditional Strength Training" → Strength session
- HIIT → Conditioning session

**Parent Epic:** ACP-283
**Priority:** P1 (High)
**Estimated Effort:** 6-8 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-401: Build wearable data preference system (choose primary device)",
        "description": """**Build 89 Agent 6: Device Preferences**

Allow athletes to choose primary wearable for each data type.

**Preference Settings:**
1. **Recovery Score:**
   - Primary: WHOOP, Oura, or Manual
   - Fallback: Next available

2. **Sleep Tracking:**
   - Primary: WHOOP, Oura, Apple Watch, or Manual
   - Preference for most accurate

3. **Workout Tracking:**
   - Primary: PT Performance manual log, Apple Watch, WHOOP
   - Hybrid: Manual + wearable validation

4. **HRV:**
   - Primary: WHOOP, Oura, Apple Watch
   - Most consistent source

**UI:**
- Settings → Wearable Integrations
- Toggle primary/secondary for each data type
- Show last sync status

**Parent Epic:** ACP-283
**Priority:** P2 (Medium)
**Estimated Effort:** 4-6 hours
""",
        "priority": 3
    },
    {
        "title": "ACP-402: Build 89 Integration Testing + Deployment",
        "description": """**Build 89 Final Agent: Integration & Testing**

Integrate all Build 89 features and deploy.

**Testing:**
1. Connect Oura Ring via OAuth
2. Connect Apple Watch via HealthKit
3. Import recovery data from both
4. Test unified recovery score fusion
5. Import Apple Watch workout
6. Test workout auto-matching
7. Set device preferences
8. Verify all data sources display correctly

**Success Metrics:**
- Multi-wearable data syncs correctly
- Unified recovery score within ±5% of primary source
- Apple Watch workouts match >80% of time
- No sync conflicts or errors

**Deployment:**
- Increment build to 89
- Deploy to TestFlight

**Parent Epic:** ACP-283
**Priority:** P0
**Estimated Effort:** 6-8 hours
""",
        "priority": 1
    }
]

# ============================================================================
# Build 90: Mode-Based UX (Performance OS) (ACP-403 to ACP-415) - 13 issues
# Parent: Multiple epics (UX overhaul)
# ============================================================================
build_90_issues = [
    {
        "title": "ACP-403: Design Performance OS mode architecture (3 modes)",
        "description": """**Build 90 Agent 1: Mode Architecture**

Design 3-mode UX system: Rehab, Strength, Performance.

**Mode Definitions:**
1. **Rehab Mode (Injury Recovery):**
   - Focus: Pain tracking, ROM, safety alerts
   - UI: Medical-first, safety warnings prominent
   - Features: Contraindication checks, PT messaging, progress photos
   - Visual: Medical blue, cautious tone

2. **Strength Mode (General Population):**
   - Focus: Volume, tonnage, progressive overload
   - UI: Clean, data-driven, motivational
   - Features: PR tracking, volume trends, habit streaks
   - Visual: Performance black/white, bold

3. **Performance Mode (Elite Athletes):**
   - Focus: Readiness, periodization, peak performance
   - UI: Advanced analytics, multi-role coordination
   - Features: WHOOP/Oura, team management, competition prep
   - Visual: Elite gold/black, sophisticated

**Mode Switching:**
- PT assigns mode based on patient phase
- Auto-suggest mode changes (e.g., cleared for RTP → switch to Strength)
- Patient cannot change mode (PT-controlled)

**Parent Epic:** Multiple (UX overhaul)
**Priority:** P0 (Critical)
**Estimated Effort:** 8-10 hours
""",
        "priority": 1
    },
    {
        "title": "ACP-404: Build Rehab Mode UI (pain-first, safety-focused)",
        "description": """**Build 90 Agent 2: Rehab Mode**

Build Rehab Mode UI for injury recovery patients.

**Home Screen (Rehab Mode):**
1. **Pain Check-In (prominent):**
   - Daily pain rating (0-10)
   - Pain location (body diagram)
   - Quick notes

2. **Today's Rehab Session:**
   - Exercise list with contraindication warnings
   - Video demonstrations
   - ROM targets

3. **Safety Alerts:**
   - Workload flags (volume spike)
   - Pain alerts (>7/10 triggers PT notification)

4. **Progress Tracking:**
   - ROM improvements
   - Pain reduction over time
   - Before/after photos

**Visual Design:**
- Medical blue theme
- Large, readable fonts
- Safety warnings in red
- Calm, reassuring tone

**Parent Epic:** ACP-282 (Return-to-Play)
**Priority:** P0 (Critical)
**Estimated Effort:** 10-12 hours
""",
        "priority": 1
    },
    {
        "title": "ACP-405: Build Strength Mode UI (PR-focused, volume-driven)",
        "description": """**Build 90 Agent 3: Strength Mode**

Build Strength Mode UI for general strength training.

**Home Screen (Strength Mode):**
1. **Today's Workout:**
   - Exercise blocks (strength, accessory, conditioning)
   - PR indicators ("PR possible today!")
   - Volume targets (tonnage goal)

2. **Quick Stats:**
   - Total volume this week
   - PRs this month
   - Consistency streak

3. **Progress Highlights:**
   - Strength trends (squat, bench, deadlift)
   - Volume progression
   - Next milestone ("10 lbs to 315 bench")

4. **Habit Streaks:**
   - Days trained consecutively
   - Weekly consistency
   - Recovery day credit

**Visual Design:**
- Black/white theme
- Bold, motivational
- Data-driven charts
- Achievement-focused

**Parent Epic:** ACP-276 (Program Builder)
**Priority:** P0 (Critical)
**Estimated Effort:** 10-12 hours
""",
        "priority": 1
    },
    {
        "title": "ACP-406: Build Performance Mode UI (readiness-first, elite-focused)",
        "description": """**Build 90 Agent 4: Performance Mode**

Build Performance Mode UI for elite athletes.

**Home Screen (Performance Mode):**
1. **Readiness Dashboard:**
   - Today's readiness band (Green/Yellow/Orange/Red)
   - WHOOP/Oura recovery score
   - HRV trend
   - Sleep quality

2. **Today's Training:**
   - Auto-adjusted based on readiness
   - Periodization phase (Base, Build, Peak, Taper)
   - Competition countdown (if applicable)

3. **Multi-Role Coordination:**
   - PT, coach, nutritionist visibility
   - Team compliance rank
   - Shared care plans

4. **Advanced Analytics:**
   - Fatigue index
   - Injury risk score
   - Performance prediction

**Visual Design:**
- Elite gold/black theme
- Sophisticated, data-rich
- Multi-metric dashboards
- Professional tone

**Parent Epic:** ACP-283 (Readiness & Auto-Regulation)
**Priority:** P0 (Critical)
**Estimated Effort:** 12-14 hours
""",
        "priority": 1
    },
    {
        "title": "ACP-407: Implement mode-specific feature visibility logic",
        "description": """**Build 90 Agent 5: Feature Gating**

Show/hide features based on mode.

**Feature Visibility Matrix:**

**Rehab Mode:**
- ✅ Pain tracking
- ✅ ROM measurement
- ✅ Safety alerts
- ✅ PT messaging
- ✅ Progress photos
- ❌ PR tracking
- ❌ Readiness bands
- ❌ Team management
- ❌ Advanced analytics

**Strength Mode:**
- ✅ PR tracking
- ✅ Volume trends
- ✅ Habit streaks
- ✅ Exercise library
- ❌ Pain tracking (simplified)
- ❌ Readiness bands (optional)
- ❌ Team management
- ❌ Multi-role coordination

**Performance Mode:**
- ✅ All features unlocked
- ✅ Readiness bands
- ✅ WHOOP/Oura
- ✅ Team management
- ✅ Advanced analytics
- ✅ Multi-role coordination
- ❌ None (everything available)

**Implementation:**
- Feature flag system
- Dynamic navigation bar
- Contextual help text

**Parent Epic:** Multiple
**Priority:** P0 (Critical)
**Estimated Effort:** 6-8 hours
""",
        "priority": 1
    },
    {
        "title": "ACP-408: Create mode transition workflows (Rehab → Strength → Performance)",
        "description": """**Build 90 Agent 6: Mode Transitions**

Handle mode transitions as patients progress.

**Transition Triggers:**
1. **Rehab → Strength:**
   - PT clears patient for strength training
   - Pain <3/10 for 7+ days
   - ROM within normal limits
   - Strength tests passed

2. **Strength → Performance:**
   - Athlete joins competitive team
   - PT enables advanced features
   - Wearable connected

3. **Performance → Rehab (injury):**
   - New injury flagged
   - PT downgrades to rehab mode
   - Safety features re-enabled

**Transition UX:**
- Congratulations message
- Feature tour (new capabilities)
- Onboarding for new mode
- Data preserved across modes

**Parent Epic:** ACP-282 (Return-to-Play)
**Priority:** P1 (High)
**Estimated Effort:** 6-8 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-409: Build mode-specific onboarding flows",
        "description": """**Build 90 Agent 7: Onboarding**

Custom onboarding for each mode.

**Rehab Mode Onboarding:**
1. Injury intake (diagnosis, surgery date, ROM)
2. Pain baseline (initial pain rating)
3. PT introduction (assign therapist)
4. Set rehab goals (return-to-play timeline)
5. Explain safety features

**Strength Mode Onboarding:**
1. Training history (experience level)
2. Set baseline PRs (squat, bench, deadlift)
3. Set goals (strength, hypertrophy, endurance)
4. Explain PR tracking and volume trends
5. Habit streak system

**Performance Mode Onboarding:**
1. Connect wearable (WHOOP, Oura, Apple Watch)
2. Set performance goals (competition dates)
3. Enable multi-role team (PT, coach, nutritionist)
4. Explain readiness-based auto-adjustment
5. Advanced analytics tour

**Parent Epic:** Multiple
**Priority:** P1 (High)
**Estimated Effort:** 8-10 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-410: Implement mode-specific analytics dashboards",
        "description": """**Build 90 Agent 8: Mode Analytics**

Custom analytics for each mode.

**Rehab Mode Analytics:**
- Pain trend (30-day chart)
- ROM improvements
- Adherence to rehab protocol
- Time-to-clearance projection

**Strength Mode Analytics:**
- Volume trends (tonnage over time)
- PR timeline (all lifts)
- Consistency metrics
- Strength balance (push/pull/legs)

**Performance Mode Analytics:**
- Readiness trend (30-day)
- HRV baseline + deviations
- Fatigue index
- Injury risk score
- Team compliance rank

**Parent Epic:** ACP-280 (Analytics & Predictive Intelligence)
**Priority:** P1 (High)
**Estimated Effort:** 10-12 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-411: Create mode-specific notification strategies",
        "description": """**Build 90 Agent 9: Notifications**

Custom notification strategies for each mode.

**Rehab Mode Notifications:**
- Daily pain check-in (9am)
- Today's rehab session ready (based on schedule)
- Safety alert (pain >7/10)
- PT message received
- Weekly progress summary

**Strength Mode Notifications:**
- Workout reminder (scheduled session time)
- PR possible today!
- Streak milestone (7 days, 30 days, 90 days)
- Weekly summary (volume, PRs, consistency)

**Performance Mode Notifications:**
- Readiness score available (after WHOOP sync)
- Auto-adjustment applied (workout modified)
- Recovery alert (HRV low, reduce training)
- Sleep reminder (based on tomorrow's training)
- Competition countdown (T-7 days, T-3 days, T-1 day)

**Parent Epic:** Multiple
**Priority:** P2 (Medium)
**Estimated Effort:** 6-8 hours
""",
        "priority": 3
    },
    {
        "title": "ACP-412: Build mode-specific settings and preferences",
        "description": """**Build 90 Agent 10: Mode Settings**

Custom settings for each mode.

**Rehab Mode Settings:**
- Pain tracking frequency (daily, after session, both)
- Photo upload reminders
- PT communication preferences
- Safety alert thresholds

**Strength Mode Settings:**
- PR tracking preferences (which lifts to track)
- Volume tracking (tonnage vs reps)
- Notification preferences
- Habit streak rules (recovery day credit)

**Performance Mode Settings:**
- Primary wearable selection
- Auto-adjustment sensitivity (aggressive, moderate, conservative)
- Multi-role permissions (who can see what)
- Advanced analytics preferences

**Parent Epic:** Multiple
**Priority:** P2 (Medium)
**Estimated Effort:** 4-6 hours
""",
        "priority": 3
    },
    {
        "title": "ACP-413: Implement mode-specific visual themes and branding",
        "description": """**Build 90 Agent 11: Visual Themes**

Custom visual themes for each mode.

**Rehab Mode Theme:**
- Primary: Medical blue (#0077CC)
- Secondary: Calming green (#00AA88)
- Accent: Warning red (for alerts)
- Fonts: Clean, readable (SF Pro, large sizes)
- Icons: Medical-focused (bandage, clipboard, shield)
- Tone: Reassuring, supportive

**Strength Mode Theme:**
- Primary: Black (#000000)
- Secondary: White (#FFFFFF)
- Accent: Motivational orange (#FF6600)
- Fonts: Bold, impactful (SF Pro Rounded, heavy weights)
- Icons: Strength-focused (dumbbell, trophy, fire)
- Tone: Motivational, achievement-driven

**Performance Mode Theme:**
- Primary: Elite gold (#FFD700)
- Secondary: Sophisticated black (#1A1A1A)
- Accent: Performance blue (#0066FF)
- Fonts: Sophisticated (SF Pro, medium weights)
- Icons: Advanced (graph, lightning, crown)
- Tone: Professional, data-driven

**Parent Epic:** Multiple
**Priority:** P1 (High)
**Estimated Effort:** 8-10 hours
""",
        "priority": 2
    },
    {
        "title": "ACP-414: Create mode switching admin panel (PT-controlled)",
        "description": """**Build 90 Agent 12: Admin Panel**

PT admin panel for mode assignment and switching.

**Features:**
1. **Patient Mode Overview:**
   - See all patients and their current modes
   - Filter by mode (Rehab, Strength, Performance)
   - Bulk mode assignment

2. **Mode Change Workflow:**
   - Select patient
   - Choose new mode (Rehab, Strength, Performance)
   - Set transition date (immediate or scheduled)
   - Add transition notes (e.g., "Cleared for RTP")
   - Notify patient of mode change

3. **Mode History:**
   - Track mode transitions over time
   - Audit trail (who changed, when, why)
   - Revert capability (undo mode change)

4. **Mode Analytics:**
   - % patients in each mode
   - Average time in Rehab mode
   - Transition success rates

**Parent Epic:** ACP-277 (Team Management)
**Priority:** P0 (Critical)
**Estimated Effort:** 6-8 hours
""",
        "priority": 1
    },
    {
        "title": "ACP-415: Build 90 Integration Testing + Deployment",
        "description": """**Build 90 Final Agent: Integration & Testing**

Integrate all Build 90 features and deploy.

**Testing:**
1. Create patient in Rehab Mode
2. Verify Rehab UI, features, notifications
3. Transition patient to Strength Mode
4. Verify Strength UI, features, analytics
5. Transition to Performance Mode
6. Verify Performance UI, wearables, advanced features
7. Test PT admin panel (mode switching)
8. Test visual themes for all modes
9. Verify feature gating works correctly

**Success Metrics:**
- All 3 modes render correctly
- Mode transitions smooth (<5 seconds)
- Feature visibility correct per mode
- Visual themes consistent
- PT admin panel intuitive

**Deployment:**
- Increment build to 90
- Deploy to TestFlight
- Q2 2025 COMPLETE! 🎉

**Parent Epic:** Multiple
**Priority:** P0 (Critical)
**Estimated Effort:** 10-12 hours
""",
        "priority": 1
    }
]

# ============================================================================
# EXECUTION: Create all 100 issues with rate limiting
# ============================================================================

all_builds = [
    ("Build 81", build_81_issues),
    ("Build 82", build_82_issues),
    ("Build 83", build_83_issues),
    ("Build 84", build_84_issues),
    ("Build 85", build_85_issues),
    ("Build 86", build_86_issues),
    ("Build 87", build_87_issues),
    ("Build 88", build_88_issues),
    ("Build 89", build_89_issues),
    ("Build 90", build_90_issues)
]

created_issues = []
failed_issues = []

for build_name, issues in all_builds:
    print(f"\n{'='*80}")
    print(f"Creating {build_name} issues ({len(issues)} issues)")
    print('='*80)

    for issue_data in issues:
        print(f"\nCreating: {issue_data['title']}")
        issue = create_issue(
            issue_data["title"],
            issue_data["description"],
            issue_data["priority"]
        )

        if issue:
            print(f"  ✅ Created: {issue['identifier']}")
            print(f"     URL: {issue['url']}")
            created_issues.append(issue)
        else:
            print(f"  ❌ Failed to create issue")
            failed_issues.append(issue_data['title'])

        # Rate limiting: 0.5 second delay between creates
        time.sleep(0.5)

# ============================================================================
# SUMMARY
# ============================================================================
print("\n" + "="*80)
print("Q2 2025 ISSUES CREATION COMPLETE")
print("="*80)
print()

print("Summary by Build:")
print(f"  • Build 81 (AI Program Generator): 15 issues")
print(f"  • Build 82 (Team Management): 8 issues")
print(f"  • Build 83 (Training-Linked Nutrition): 12 issues")
print(f"  • Build 84 (Training-Safe Fasting): 8 issues")
print(f"  • Build 85 (Protocol-Based Supplement Stacks): 10 issues")
print(f"  • Build 86 (Training-Driven Sleep Protocols): 10 issues")
print(f"  • Build 87 (Performance-State Modulation): 10 issues")
print(f"  • Build 88 (WHOOP Integration): 7 issues")
print(f"  • Build 89 (Oura/Apple Watch Integration): 7 issues")
print(f"  • Build 90 (Mode-Based UX): 13 issues")
print()
print(f"Total created: {len(created_issues)}/100")
print(f"Failed: {len(failed_issues)}")
print()

if failed_issues:
    print("Failed Issues:")
    for title in failed_issues:
        print(f"  • {title}")
    print()

print("All issues: https://linear.app/x2machines/team/ACP")
print()
print("Next Steps:")
print("1. Verify all issues created in Linear")
print("2. Link issues to parent epics (ACP-275 through ACP-284)")
print("3. Assign priorities and estimates")
print("4. Begin Build 81 execution!")
print()
