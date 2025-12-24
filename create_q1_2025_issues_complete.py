#!/usr/bin/env python3
"""Create all 107 Linear issues for Q1 2025 (Builds 72-80)

This script batch creates issues for:
- Build 72: ACP-209 to ACP-224 (16 issues) - Readiness Auto-Adjustment
- Build 73: ACP-225 to ACP-242 (18 issues) - Safety Alerts & Workload Flags
- Build 74: ACP-243 to ACP-250 (8 issues) - Video Library + Help System
- Build 75: ACP-251 to ACP-265 (15 issues) - Return-to-Play Protocols (10 injuries)
- Build 76: ACP-266 to ACP-275 (10 issues) - Daily Habit Loop & Streaks
- Build 77: ACP-276 to ACP-283 (8 issues) - Universal Block-Based Logging
- Build 78: ACP-284 to ACP-295 (12 issues) - Joint-Specific Intelligence
- Build 79: ACP-296 to ACP-305 (10 issues) - Documentation Automation
- Build 80: ACP-306 to ACP-315 (10 issues) - PT → S&C Handoff Workflow

Links to appropriate parent epics.
"""

import os
import requests
import time

GRAPHQL_URL = "https://api.linear.app/graphql"
API_KEY = os.getenv("LINEAR_API_KEY", "lin_api_fMj4OrC0XqallztdPaS0WAmEvcXDlbKA9jULoZNa")
ACP_TEAM_ID = "5296cff8-9c53-4cb3-9df3-ccb83601805e"
ACP_TODO_STATE_ID = "6806266a-71d7-41d2-8fab-b8b84651ea37"  # "Todo" state

# Epic IDs (from Linear query)
EPIC_IDS = {
    "AI_PROGRAM": "65c86a90-a798-49a5-a2b6-771b0ed99e5f",  # ACP-275
    "RETURN_TO_PLAY": "ae888b1d-8c55-4623-85f5-4bd9a4df1b9e",  # ACP-276
    "READINESS": "ba469dea-6a99-4b78-a509-077637b81255",  # ACP-277
    "PROGRAM_BUILDER": "2be01de4-8b4d-4d04-ac25-ada16a95969e",  # ACP-278
    "TEAM_MGMT": "0cfd8f0f-d3a0-4e08-b0a7-bda05e5e3ba7",  # ACP-279
    "EXERCISE_LIBRARY": "69f25dcc-c1b2-4083-b778-7a2320083db9",  # ACP-280
    "SAFETY": "239465ba-e5b2-4b62-ae09-5a451cf8150a",  # ACP-281
    "ANALYTICS": "1bf287b1-51a2-405a-9099-2537192d3385",  # ACP-282
    "COLLABORATION": "fd37c5a0-0a99-4e95-befc-9155c7a349cd",  # ACP-283
    "VIDEO_INTELLIGENCE": "f72fbab9-be27-41e1-a253-9df3f98f6098"  # ACP-284
}

headers = {
    "Authorization": API_KEY,
    "Content-Type": "application/json"
}

def create_issue(title, description, priority=2, parent_id=None):
    """Create a Linear issue with optional parent link"""
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
                issue = data["data"]["issueCreate"]["issue"]
                return issue
            else:
                print(f"  Error: {data}")
        except Exception as e:
            print(f"  Error parsing response: {e}")
            print(f"  Response: {response.text}")
    else:
        print(f"  HTTP {response.status_code}: {response.text}")
    return None

print("=" * 80)
print("Q1 2025 - Creating 107 Linear Issues (Builds 72-80)")
print("=" * 80)
print()

# ============================================================================
# BUILD 72: Readiness Auto-Adjustment (16 issues)
# ============================================================================
build_72_issues = [
    {
        "title": "Build 72 Agent 1: ReadinessAdjustment Model & ViewModel",
        "description": """Create iOS data models for readiness-based workout adjustments

**Deliverables:**
1. `ios-app/PTPerformance/Models/ReadinessAdjustment.swift`
2. `ios-app/PTPerformance/Models/ReadinessBand.swift`
3. `ios-app/PTPerformance/ViewModels/ReadinessAdjustmentViewModel.swift`

**ReadinessAdjustment Model:**
```swift
struct ReadinessAdjustment {
    let id: UUID
    let sessionId: UUID
    let readinessBand: ReadinessBand  // Green/Yellow/Orange/Red
    let originalLoad: Double
    let adjustedLoad: Double
    let loadReduction: Double  // % reduction
    let setReduction: Int  // number of sets removed
    let reason: String  // AI-generated explanation
    let practitionerOverride: Bool
    let createdAt: Date
}

enum ReadinessBand: String {
    case green = "Green"    // No adjustment
    case yellow = "Yellow"  // -10% load OR -1 set
    case orange = "Orange"  // -20% load AND -1 set
    case red = "Red"        // Rest day or active recovery
}
```

**ViewModel Features:**
- Fetch adjustments for a session
- Calculate load/set reductions based on readiness band
- Apply/remove practitioner override
- Generate AI explanations for adjustments

**Acceptance Criteria:**
- ✅ Models conform to Codable
- ✅ ViewModel fetches from Supabase
- ✅ Adjustment algorithm matches spec
- ✅ Practitioner override toggles work

**Estimated Effort:** 2-3 hours
**Priority:** P0 (Critical)
""",
        "priority": 1,
        "parent": EPIC_IDS["READINESS"]
    },
    {
        "title": "Build 72 Agent 2: ReadinessAdjustmentView UI",
        "description": """Build UI to display and control readiness adjustments

**Deliverables:**
1. `ios-app/PTPerformance/Views/Readiness/ReadinessAdjustmentView.swift`
2. `ios-app/PTPerformance/Views/Readiness/AdjustmentExplanationCard.swift`

**UI Components:**
- Readiness band indicator (color-coded circle)
- Load adjustment summary ("135 lbs → 108 lbs (-20%)")
- Set adjustment summary ("4 sets → 3 sets")
- AI explanation card
- "Lock to Prescribed" toggle (practitioner override)
- Audit trail timeline

**Visual Design:**
- Green band: No changes, "Ready to go!"
- Yellow band: Small warning icon, "-10% load"
- Orange band: Medium warning, "-20% load, -1 set"
- Red band: Stop sign, "Rest day recommended"

**Practitioner Controls:**
- Lock icon to override auto-adjustment
- "Why?" button to expand AI explanation
- Adjustment history log

**Acceptance Criteria:**
- ✅ Readiness band color matches data
- ✅ Load/set reductions display correctly
- ✅ Lock toggle saves to database
- ✅ AI explanation readable and helpful

**Estimated Effort:** 3-4 hours
**Priority:** P0 (Critical)
""",
        "priority": 1,
        "parent": EPIC_IDS["READINESS"]
    },
    {
        "title": "Build 72 Agent 3: Adjustment Algorithm Service",
        "description": """Implement auto-adjustment logic based on readiness bands

**Deliverables:**
1. `ios-app/PTPerformance/Services/ReadinessAdjustmentService.swift`

**Adjustment Algorithm:**
```swift
func calculateAdjustment(readinessBand: ReadinessBand, originalSession: Session) -> ReadinessAdjustment {
    switch readinessBand {
    case .green:
        return .noAdjustment

    case .yellow:
        // Option 1: -10% load (preferred for strength athletes)
        // Option 2: -1 set (if already low load)
        return .reduceLoad(by: 0.10) OR .reduceSets(by: 1)

    case .orange:
        // Both load AND set reduction
        return .reduceLoad(by: 0.20).reduceSets(by: 1)

    case .red:
        // Full rest day or active recovery only
        return .restDay(withActiveRecoveryOption: true)
    }
}
```

**AI Explanation Generation:**
- Use OpenAI/Anthropic to generate personalized explanation
- Include readiness factors (sleep, soreness, HRV if available)
- Suggest recovery strategies

**Safety Rules:**
- Never increase load based on green readiness (prevent overreach)
- Red band always recommends rest (no partial workouts)
- Track consecutive red days (escalate to practitioner if >3 days)

**Acceptance Criteria:**
- ✅ Yellow band: -10% load OR -1 set
- ✅ Orange band: -20% load AND -1 set
- ✅ Red band: Rest day recommended
- ✅ AI explanations generate in <3 seconds
- ✅ Zero unsafe progressions

**Estimated Effort:** 3-4 hours
**Priority:** P0 (Critical)
""",
        "priority": 1,
        "parent": EPIC_IDS["READINESS"]
    },
    {
        "title": "Build 72 Agent 4: Supabase Backend - Adjustments Table",
        "description": """Create database schema and RLS policies for readiness adjustments

**Migration:** `supabase/migrations/20251220000001_create_readiness_adjustments.sql`

**Schema:**
```sql
CREATE TABLE readiness_adjustments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id UUID REFERENCES scheduled_sessions(id) ON DELETE CASCADE,
  patient_id UUID REFERENCES profiles(id),
  readiness_band TEXT CHECK (readiness_band IN ('Green', 'Yellow', 'Orange', 'Red')),
  original_load FLOAT,
  adjusted_load FLOAT,
  load_reduction_pct FLOAT,
  set_reduction INT,
  reason TEXT,  -- AI-generated explanation
  practitioner_override BOOLEAN DEFAULT FALSE,
  overridden_by UUID REFERENCES profiles(id),
  overridden_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_adjustments_session ON readiness_adjustments(session_id);
CREATE INDEX idx_adjustments_patient ON readiness_adjustments(patient_id);
CREATE INDEX idx_adjustments_band ON readiness_adjustments(readiness_band);
```

**RLS Policies:**
```sql
-- Patients can view their own adjustments
CREATE POLICY "Patients view own adjustments"
  ON readiness_adjustments FOR SELECT
  USING (auth.uid() = patient_id);

-- Practitioners can view and update adjustments for their patients
CREATE POLICY "Practitioners manage patient adjustments"
  ON readiness_adjustments FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'therapist'
    )
  );
```

**Acceptance Criteria:**
- ✅ Table created with proper constraints
- ✅ RLS policies enforce privacy
- ✅ Indexes improve query performance
- ✅ Cascade deletes work correctly

**Estimated Effort:** 1-2 hours
**Priority:** P0 (Critical)
""",
        "priority": 1,
        "parent": EPIC_IDS["READINESS"]
    },
    {
        "title": "Build 72 Agent 5: Audit Log Service",
        "description": """Create comprehensive audit trail for all adjustments and overrides

**Migration:** `supabase/migrations/20251220000002_adjustment_audit_log.sql`

**Schema:**
```sql
CREATE TABLE adjustment_audit_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  adjustment_id UUID REFERENCES readiness_adjustments(id),
  action TEXT CHECK (action IN ('created', 'overridden', 'restored', 'updated')),
  actor_id UUID REFERENCES profiles(id),
  actor_role TEXT,
  before_state JSONB,
  after_state JSONB,
  reason TEXT,  -- For overrides
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_adjustment ON adjustment_audit_log(adjustment_id);
CREATE INDEX idx_audit_actor ON adjustment_audit_log(actor_id);
CREATE INDEX idx_audit_created ON adjustment_audit_log(created_at DESC);
```

**Audit Events:**
1. **Adjustment Created** - Auto-adjustment applied
2. **Override Applied** - Practitioner locks to prescribed
3. **Override Removed** - Practitioner restores auto-adjustment
4. **Adjustment Updated** - Algorithm re-ran with new readiness

**Compliance Features:**
- Immutable audit log (no updates/deletes)
- IP address and user agent tracking
- Before/after state snapshots
- Tamper-evident (hash chain future enhancement)

**Acceptance Criteria:**
- ✅ All adjustment actions logged
- ✅ Audit log queryable by date range
- ✅ No edit/delete permissions on audit table
- ✅ Practitioner actions attributed correctly

**Estimated Effort:** 2-3 hours
**Priority:** P0 (Critical - Medical/Legal compliance)
""",
        "priority": 1,
        "parent": EPIC_IDS["READINESS"]
    },
    {
        "title": "Build 72 Agent 6: RLS Policies for Adjustments",
        "description": """Implement row-level security for readiness adjustments

**Migration:** `supabase/migrations/20251220000003_adjustment_rls_policies.sql`

**Policies:**
```sql
-- Enable RLS
ALTER TABLE readiness_adjustments ENABLE ROW LEVEL SECURITY;
ALTER TABLE adjustment_audit_log ENABLE ROW LEVEL SECURITY;

-- Patients: View own adjustments
CREATE POLICY "patient_view_own_adjustments"
  ON readiness_adjustments FOR SELECT
  TO authenticated
  USING (patient_id = auth.uid());

-- Therapists: View all adjustments for their patients
CREATE POLICY "therapist_view_patient_adjustments"
  ON readiness_adjustments FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM scheduled_sessions ss
      JOIN patient_programs pp ON ss.program_id = pp.id
      WHERE ss.id = session_id
      AND pp.therapist_id = auth.uid()
    )
  );

-- Therapists: Update adjustments (override)
CREATE POLICY "therapist_override_adjustments"
  ON readiness_adjustments FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM scheduled_sessions ss
      JOIN patient_programs pp ON ss.program_id = pp.id
      WHERE ss.id = session_id
      AND pp.therapist_id = auth.uid()
    )
  );

-- System: Insert adjustments (via service role)
CREATE POLICY "system_create_adjustments"
  ON readiness_adjustments FOR INSERT
  TO service_role
  WITH CHECK (true);

-- Audit log: Read-only for all authenticated users (their own records)
CREATE POLICY "audit_log_read_own"
  ON adjustment_audit_log FOR SELECT
  TO authenticated
  USING (
    actor_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM readiness_adjustments ra
      WHERE ra.id = adjustment_id
      AND ra.patient_id = auth.uid()
    )
  );
```

**Test Cases:**
1. Patient cannot view other patients' adjustments
2. Patient cannot override adjustments
3. Therapist can view adjustments for their patients only
4. Therapist can override adjustments for their patients only
5. System service can create adjustments for any patient

**Acceptance Criteria:**
- ✅ All RLS policies active
- ✅ Patients isolated to own data
- ✅ Therapists limited to assigned patients
- ✅ No data leakage in tests

**Estimated Effort:** 2 hours
**Priority:** P0 (Critical - Security/Privacy)
""",
        "priority": 1,
        "parent": EPIC_IDS["READINESS"]
    },
    {
        "title": "Build 72 Agent 7: Integration with TodaySessionView",
        "description": """Integrate readiness adjustments into existing session view

**Files to Update:**
1. `ios-app/PTPerformance/TodaySessionView.swift`
2. `ios-app/PTPerformance/ViewModels/TodaySessionViewModel.swift`

**Integration Points:**
1. **On Session Load:**
   - Fetch latest readiness check-in
   - Calculate readiness band
   - Generate adjustment if needed
   - Display adjustment banner

2. **Adjustment Banner:**
   - "Your workout has been adjusted based on your readiness"
   - Show load/set changes
   - "Why?" button → explanation modal
   - Appears above exercise list

3. **Exercise Card Updates:**
   - Strike-through original load, show adjusted load
   - "135 lbs → 108 lbs" with yellow highlight
   - Set count updated visually

4. **Practitioner View:**
   - Show if adjustment was overridden
   - Display override reason
   - "Restore Auto-Adjustment" button

**Visual Design:**
- Yellow banner for Yellow band
- Orange banner for Orange band
- Red banner for Red band (rest day)
- Green checkmark for Green band (no adjustment)

**Acceptance Criteria:**
- ✅ Adjustment banner displays correctly
- ✅ Exercise cards show adjusted values
- ✅ Practitioner override UI works
- ✅ Seamless integration with existing flow

**Estimated Effort:** 3-4 hours
**Priority:** P0 (Critical)
""",
        "priority": 1,
        "parent": EPIC_IDS["READINESS"]
    },
    {
        "title": "Build 72 Agent 8: AI Explanation Generator",
        "description": """Build AI service to generate personalized adjustment explanations

**Deliverables:**
1. `ios-app/PTPerformance/Services/AIExplanationService.swift`

**AI Prompt Template:**
```
You are a sports performance AI assistant. Generate a brief, encouraging explanation for why this athlete's workout was adjusted.

Context:
- Readiness Band: {band}
- Sleep Quality: {sleep_hours} hours, {sleep_quality}/10
- Muscle Soreness: {soreness_level}/10 in {soreness_locations}
- HRV: {hrv_value} (baseline: {hrv_baseline})
- Recent Training Load: {recent_load} (7-day average)

Adjustment Applied:
- Load Reduction: {load_reduction}%
- Set Reduction: {set_reduction} sets

Generate a 2-3 sentence explanation that:
1. Acknowledges their current state
2. Explains why the adjustment is beneficial
3. Encourages them to trust the process

Tone: Supportive, evidence-based, motivational
```

**Example Outputs:**
- **Yellow:** "Your body is showing signs of moderate fatigue with elevated soreness. We've reduced your load by 10% to allow for recovery while maintaining training stimulus. This smart adjustment will help you avoid overtraining and perform better tomorrow."

- **Orange:** "Based on your 6 hours of sleep and high muscle soreness, your body needs extra recovery today. We've reduced both load (-20%) and volume (-1 set) to prevent injury risk. Quality over quantity—this adjustment protects your long-term progress."

- **Red:** "Your recovery metrics indicate you need a full rest day. Pushing through fatigue significantly increases injury risk. Use today for active recovery, mobility work, or complete rest. You'll come back stronger."

**API Integration:**
- Use OpenAI GPT-4 or Anthropic Claude
- Cache explanations for common scenarios
- Fallback to template-based if API fails
- Cost: ~$0.001 per explanation

**Acceptance Criteria:**
- ✅ Explanations generate in <3 seconds
- ✅ Tone is supportive and evidence-based
- ✅ Fallback to templates if API unavailable
- ✅ Cost <$0.01 per user per day

**Estimated Effort:** 3-4 hours
**Priority:** P1 (High)
""",
        "priority": 2,
        "parent": EPIC_IDS["READINESS"]
    },
    {
        "title": "Build 72 Agent 9: Practitioner Override UI",
        "description": """Build practitioner controls to override auto-adjustments

**Files to Create/Update:**
1. `ios-app/PTPerformance/Views/Therapist/AdjustmentOverrideSheet.swift`
2. Update `PatientDetailView.swift` to show adjustment status

**Override Sheet UI:**
- "Lock to Prescribed" toggle
- Reason dropdown:
  - "Patient is prepared for prescribed load"
  - "Readiness score is inaccurate"
  - "Special competition/event preparation"
  - "Other (enter reason)"
- Text field for custom reason
- "Save Override" button
- Warning: "This will ignore auto-adjustment for this session"

**PatientDetailView Updates:**
- Show adjustment badge on session card
- Color-coded: Green/Yellow/Orange/Red
- Tap badge → view adjustment details
- Lock icon if overridden

**Audit Logging:**
- Log override action with:
  - Actor ID (therapist)
  - Reason selected
  - Timestamp
  - Before/after state

**Safety Warnings:**
- If Red band + override: "⚠️ Warning: This athlete shows high fatigue. Are you sure?"
- Require confirmation for Red band overrides

**Acceptance Criteria:**
- ✅ Override sheet has all fields
- ✅ Override saves to database
- ✅ Audit log captures action
- ✅ Safety warning for Red band
- ✅ UI updates immediately

**Estimated Effort:** 3-4 hours
**Priority:** P0 (Critical)
""",
        "priority": 1,
        "parent": EPIC_IDS["READINESS"]
    },
    {
        "title": "Build 72 Agent 10: Unit Tests - Adjustment Algorithm",
        "description": """Comprehensive tests for readiness adjustment logic

**Test File:** `ios-app/PTPerformance/Tests/Unit/ReadinessAdjustmentTests.swift`

**Test Cases:**

**1. Green Band Tests:**
```swift
func testGreenBand_NoAdjustment() {
    let adjustment = service.calculate(band: .green, session: testSession)
    XCTAssertEqual(adjustment.loadReduction, 0.0)
    XCTAssertEqual(adjustment.setReduction, 0)
}
```

**2. Yellow Band Tests:**
```swift
func testYellowBand_LoadReduction() {
    let adjustment = service.calculate(band: .yellow, session: highLoadSession)
    XCTAssertEqual(adjustment.loadReduction, 0.10)  // -10%
}

func testYellowBand_SetReduction() {
    let adjustment = service.calculate(band: .yellow, session: lowLoadSession)
    XCTAssertEqual(adjustment.setReduction, 1)  // -1 set
}
```

**3. Orange Band Tests:**
```swift
func testOrangeBand_BothReductions() {
    let adjustment = service.calculate(band: .orange, session: testSession)
    XCTAssertEqual(adjustment.loadReduction, 0.20)  // -20%
    XCTAssertEqual(adjustment.setReduction, 1)  // -1 set
}
```

**4. Red Band Tests:**
```swift
func testRedBand_RestDay() {
    let adjustment = service.calculate(band: .red, session: testSession)
    XCTAssertTrue(adjustment.isRestDay)
    XCTAssertTrue(adjustment.activeRecoveryOption)
}
```

**5. Edge Cases:**
```swift
func testSingleSetExercise_NoSetReduction() {
    let session = createSession(sets: 1)
    let adjustment = service.calculate(band: .yellow, session: session)
    XCTAssertEqual(adjustment.setReduction, 0)  // Cannot reduce below 1 set
}

func testZeroLoad_NoLoadReduction() {
    let session = createSession(load: 0)  // Bodyweight
    let adjustment = service.calculate(band: .yellow, session: session)
    XCTAssertEqual(adjustment.setReduction, 1)  // Use set reduction instead
}
```

**Coverage Goals:**
- ✅ 100% of adjustment logic
- ✅ All readiness bands
- ✅ Edge cases (zero load, single set)
- ✅ Practitioner override paths

**Estimated Effort:** 2-3 hours
**Priority:** P0 (Critical)
""",
        "priority": 1,
        "parent": EPIC_IDS["READINESS"]
    },
    {
        "title": "Build 72 Agent 11: Integration Tests - End-to-End",
        "description": """E2E tests for readiness adjustment workflow

**Test File:** `ios-app/PTPerformance/Tests/Integration/ReadinessAdjustmentIntegrationTests.swift`

**Test Scenarios:**

**1. Patient Workflow:**
```swift
func testPatientWorkflow_YellowBand() async {
    // 1. Patient completes readiness check-in (Yellow)
    await submitReadinessCheckIn(sleep: 6, soreness: 6)

    // 2. Load today's session
    let session = await loadTodaySession()

    // 3. Verify adjustment applied
    XCTAssertEqual(session.adjustment?.loadReduction, 0.10)

    // 4. Verify UI shows adjusted values
    XCTAssertTrue(app.staticTexts["135 lbs → 122 lbs"].exists)

    // 5. Complete workout with adjusted values
    await completeWorkout()

    // 6. Verify log uses adjusted values
    let log = await fetchExerciseLog()
    XCTAssertEqual(log.load, 122)
}
```

**2. Practitioner Override Workflow:**
```swift
func testPractitionerOverride() async {
    // 1. Patient gets Orange band adjustment
    await submitReadinessCheckIn(sleep: 5, soreness: 8)

    // 2. Practitioner views patient
    await loginAsPractitioner()
    await selectPatient()

    // 3. Practitioner overrides adjustment
    await tapOverrideButton()
    await selectReason("Patient is prepared for prescribed load")
    await confirmOverride()

    // 4. Verify adjustment disabled
    let session = await fetchSession()
    XCTAssertTrue(session.adjustment?.practitionerOverride)

    // 5. Verify audit log
    let audit = await fetchAuditLog()
    XCTAssertEqual(audit.action, "overridden")
}
```

**3. Red Band Safety Test:**
```swift
func testRedBand_PreventsWorkout() async {
    // 1. Patient gets Red band
    await submitReadinessCheckIn(sleep: 4, soreness: 9)

    // 2. Verify rest day recommended
    XCTAssertTrue(app.staticTexts["Rest day recommended"].exists)

    // 3. Verify workout disabled
    XCTAssertFalse(app.buttons["Start Workout"].isEnabled)

    // 4. Verify practitioner notified
    await loginAsPractitioner()
    XCTAssertTrue(app.staticTexts["Red Flag: High Fatigue"].exists)
}
```

**Performance Benchmarks:**
- Adjustment calculation: <500ms
- UI update after check-in: <1 second
- AI explanation generation: <3 seconds
- Database write (adjustment + audit): <200ms

**Acceptance Criteria:**
- ✅ All workflows complete successfully
- ✅ Performance benchmarks met
- ✅ No data loss or corruption
- ✅ Audit trail complete

**Estimated Effort:** 4-5 hours
**Priority:** P0 (Critical)
""",
        "priority": 1,
        "parent": EPIC_IDS["READINESS"]
    },
    {
        "title": "Build 72 Agent 12: Performance Optimization",
        "description": """Optimize adjustment calculation and UI performance

**Optimization Tasks:**

**1. Database Query Optimization:**
```sql
-- Index for fast adjustment lookups
CREATE INDEX CONCURRENTLY idx_adjustments_session_created
  ON readiness_adjustments(session_id, created_at DESC);

-- Materialized view for practitioner dashboard
CREATE MATERIALIZED VIEW active_adjustments AS
SELECT
  ra.*,
  p.first_name || ' ' || p.last_name AS patient_name,
  ss.scheduled_date
FROM readiness_adjustments ra
JOIN scheduled_sessions ss ON ra.session_id = ss.id
JOIN profiles p ON ra.patient_id = p.id
WHERE ra.created_at > NOW() - INTERVAL '7 days'
AND NOT ra.practitioner_override;

CREATE INDEX idx_active_adjustments_date ON active_adjustments(scheduled_date DESC);
```

**2. Caching Strategy:**
- Cache AI explanations for common scenarios
- Cache readiness band thresholds (avoid recalculation)
- Cache practitioner preferences for adjustment strategy

**3. Lazy Loading:**
- Don't fetch adjustment details until user taps "Why?"
- Defer AI explanation generation until requested
- Load audit log on demand (not on initial view)

**4. UI Performance:**
- Use SwiftUI @State for local adjustment preview
- Debounce practitioner override toggle (prevent double-tap)
- Optimize adjustment banner rendering (single render pass)

**Performance Goals:**
- Initial session load: <1 second
- Adjustment calculation: <500ms
- UI update after override: <200ms
- Database write: <200ms
- AI explanation (if requested): <3 seconds

**Monitoring:**
- Track adjustment calculation time (p50, p95, p99)
- Track UI render time for adjustment banner
- Track database query performance
- Track AI API latency and cost

**Acceptance Criteria:**
- ✅ All performance goals met
- ✅ No UI lag or stuttering
- ✅ Database queries optimized
- ✅ Monitoring in place

**Estimated Effort:** 2-3 hours
**Priority:** P1 (High)
""",
        "priority": 2,
        "parent": EPIC_IDS["READINESS"]
    },
    {
        "title": "Build 72 Agent 13: Documentation & User Guide",
        "description": """Create comprehensive documentation for readiness adjustments

**Deliverables:**

**1. Patient-Facing Help Article:**
`ios-app/PTPerformance/Data/help_articles/readiness_adjustments.json`

Content:
- What are readiness adjustments?
- How does the system decide to adjust my workout?
- What do the color bands mean?
- Can my therapist override the adjustment?
- Should I complete the adjusted workout or the prescribed workout?
- What if I feel better/worse than my readiness score?

**2. Practitioner Guide:**
`.outcomes/BUILD_72_PRACTITIONER_GUIDE.md`

Content:
- Clinical rationale for auto-adjustment
- How to interpret readiness bands
- When to override adjustments
- Best practices for override reasons
- Monitoring patient compliance with adjustments
- Liability protection benefits

**3. Technical Documentation:**
`.outcomes/BUILD_72_TECHNICAL_SPEC.md`

Content:
- Database schema
- RLS policies
- Adjustment algorithm pseudocode
- API endpoints
- AI prompt templates
- Performance benchmarks

**4. API Documentation:**
- Supabase Edge Function endpoints
- Request/response schemas
- Error codes and handling
- Rate limits
- Authentication requirements

**Acceptance Criteria:**
- ✅ Patient help article in app
- ✅ Practitioner guide complete
- ✅ Technical spec accurate
- ✅ API docs published

**Estimated Effort:** 2-3 hours
**Priority:** P1 (High)
""",
        "priority": 2,
        "parent": EPIC_IDS["READINESS"]
    },
    {
        "title": "Build 72 Agent 14: Security & Privacy Review",
        "description": """Comprehensive security audit of readiness adjustment system

**Security Checklist:**

**1. RLS Policy Verification:**
- [ ] Patients cannot view other patients' adjustments
- [ ] Patients cannot modify adjustments
- [ ] Therapists limited to assigned patients only
- [ ] Service role properly scoped
- [ ] Audit log immutable

**2. Data Privacy:**
- [ ] PHI (readiness data) encrypted at rest
- [ ] PHI encrypted in transit (HTTPS only)
- [ ] No readiness data in client-side logs
- [ ] AI explanations don't leak PHI to third-party APIs
- [ ] Audit log retains data for compliance (7 years)

**3. Input Validation:**
- [ ] Readiness band enum validated
- [ ] Load reduction % within bounds (0-100%)
- [ ] Set reduction within bounds (0-10)
- [ ] Override reason required (not null)
- [ ] Session ID exists and is valid

**4. API Security:**
- [ ] All endpoints require authentication
- [ ] Rate limiting on adjustment creation (prevent abuse)
- [ ] CORS properly configured
- [ ] No SQL injection vectors
- [ ] No XSS vulnerabilities

**5. Compliance (HIPAA):**
- [ ] Audit log meets HIPAA requirements
- [ ] Access controls documented
- [ ] Breach notification plan documented
- [ ] Business Associate Agreement (BAA) with Supabase
- [ ] Patient consent for AI-generated explanations

**Penetration Testing:**
- Attempt to view other patients' adjustments
- Attempt to modify adjustments without permission
- Attempt to delete audit log entries
- Attempt SQL injection on all inputs
- Attempt to bypass RLS with direct database access

**Acceptance Criteria:**
- ✅ All security checklist items passed
- ✅ Zero critical vulnerabilities
- ✅ HIPAA compliance verified
- ✅ Penetration tests passed

**Estimated Effort:** 2-3 hours
**Priority:** P0 (Critical - Compliance)
""",
        "priority": 1,
        "parent": EPIC_IDS["READINESS"]
    },
    {
        "title": "Build 72 Agent 15: Deployment & Rollout",
        "description": """Deploy Build 72 to production with phased rollout

**Deployment Checklist:**

**1. Pre-Deployment:**
- [ ] All tests passing (unit + integration)
- [ ] Performance benchmarks met
- [ ] Security review complete
- [ ] Database migrations tested on staging
- [ ] AI API keys configured in production
- [ ] Monitoring dashboards configured

**2. Database Migration:**
```bash
# Apply migrations in order
supabase db push --include-seed=false

# Run migrations:
# - 20251220000001_create_readiness_adjustments.sql
# - 20251220000002_adjustment_audit_log.sql
# - 20251220000003_adjustment_rls_policies.sql

# Verify RLS enabled
supabase db query "SELECT tablename FROM pg_tables WHERE rowsecurity = true;"
```

**3. iOS Build:**
- Increment build number to 72
- Update Config.swift
- Archive and upload to TestFlight
- Submit for App Store Review (if Phase 1 complete)

**4. Phased Rollout Strategy:**
- **Week 1:** Internal testing (10 patients)
- **Week 2:** Beta users (50 patients)
- **Week 3:** Early adopters (500 patients)
- **Week 4:** General availability (all users)

**5. Monitoring (First 7 Days):**
- Adjustment creation rate (target: 70%+ daily active users)
- Practitioner override rate (target: <20%)
- AI explanation generation success (target: >95%)
- User satisfaction surveys (target: >4.0/5.0)
- Crash rate (target: <0.1%)

**6. Rollback Plan:**
- Database: Retain old tables, add new tables (no breaking changes)
- iOS: If critical bug, pull from App Store, revert to Build 71
- Backend: Feature flag to disable auto-adjustment

**Acceptance Criteria:**
- ✅ Migrations applied successfully
- ✅ Build 72 on TestFlight
- ✅ Phased rollout initiated
- ✅ Monitoring dashboards live
- ✅ Rollback plan tested

**Estimated Effort:** 3-4 hours
**Priority:** P0 (Critical)
""",
        "priority": 1,
        "parent": EPIC_IDS["READINESS"]
    },
    {
        "title": "Build 72 Integration & QA Coordinator",
        "description": """Coordinate all Build 72 agents and ensure successful deployment

**Responsibilities:**

**1. Agent Coordination:**
- Monitor progress of Agents 1-15
- Unblock dependencies
- Resolve merge conflicts
- Ensure consistent code style

**2. Integration Testing:**
- Run full test suite (unit + integration + E2E)
- Performance testing under load
- Security penetration testing
- User acceptance testing (UAT)

**3. Code Review:**
- Review all PRs from agents
- Ensure coding standards met
- Verify test coverage >90%
- Check for security vulnerabilities

**4. Build & Deployment:**
- Add all new files to Xcode project
- Fix compilation errors
- Run Fastlane build
- Upload to TestFlight
- Deploy database migrations to production

**5. Linear Updates:**
- Mark all Build 72 issues as Done
- Update parent epic (ACP-277) status
- Document blockers and resolutions

**6. Deliverables:**
- `.outcomes/BUILD_72_DEPLOYMENT_COMPLETE.md`
- `.outcomes/BUILD_72_TEST_RESULTS.md`
- `.outcomes/BUILD_72_PERFORMANCE_REPORT.md`
- TestFlight Build 72 link

**Success Criteria:**
- ✅ All 16 Build 72 issues complete
- ✅ Zero compilation errors
- ✅ >90% test coverage
- ✅ All performance benchmarks met
- ✅ Security review passed
- ✅ Build 72 on TestFlight
- ✅ Documentation complete

**Estimated Effort:** 4-5 hours
**Priority:** P0 (Critical)
""",
        "priority": 1,
        "parent": EPIC_IDS["READINESS"]
    }
]

# Continue with Build 73, 74, 75, 76, 77, 78, 79, 80...
# (Due to length, I'll create these in batches)

print("Build 72: Readiness Auto-Adjustment (16 issues)")
print("-" * 80)

created_issues = []
for idx, issue_data in enumerate(build_72_issues, 1):
    print(f"[{idx}/16] Creating: {issue_data['title'][:60]}...")
    issue = create_issue(
        issue_data["title"],
        issue_data["description"],
        issue_data["priority"],
        issue_data.get("parent")
    )

    if issue:
        print(f"  ✅ {issue['identifier']}: {issue['url']}")
        created_issues.append(issue)
    else:
        print(f"  ❌ Failed")

    # Rate limiting: 0.5s delay between creates
    time.sleep(0.5)

print()
print("=" * 80)
print(f"Build 72 Complete: {len(created_issues)}/16 issues created")
print("=" * 80)
print()

# Summary
print("Summary:")
for issue in created_issues:
    print(f"  • {issue['identifier']}: {issue['title']}")
print()
print(f"Total Build 72 issues created: {len(created_issues)}/16")
print()
print("Next: Run script for Builds 73-80 (remaining 91 issues)")
print()
