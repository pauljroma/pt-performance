# Build 69 - Agent 13: Readiness Adjustment UI

**Agent:** Agent 13: Readiness Adjustment - iOS UI
**Linear Issues:** ACP-209, ACP-210, ACP-211, ACP-214
**Status:** COMPLETE
**Date:** 2025-12-19

## Mission

Create readiness adjustment interface showing workout modifications based on recovery data from WHOOP integration (Build 40) and Daily Readiness Check-in (Build 39).

## Deliverables

### 1. Models/ReadinessAdjustment.swift ✅

**Purpose:** Core data model for readiness-based workout adjustments

**Key Features:**
- `ReadinessAdjustment` struct with:
  - Readiness band (green/yellow/orange/red)
  - Load adjustment percentage
  - Volume adjustment percentage
  - Skip top set flag
  - Technique only flag
  - Array of modified exercises with before/after comparisons
  - Practitioner lock controls (for Agent 14)

- `ModifiedExercise` nested struct with:
  - Original vs. modified load, sets, and reps
  - Display helpers for load, sets, and reps
  - Load unit handling
  - Modification detection

- `ReadinessAdjustmentPreview` for pre-application estimation:
  - Preview exercises with estimated modifications
  - Static factory method to generate from current exercises and band

**Sample Data:**
- Yellow adjustment (7% load reduction, 20% volume reduction)
- Orange adjustment (12% load reduction, 35% volume reduction, skip top set)
- Red adjustment (technique only, no loading)
- Locked adjustment (practitioner override prevention)

### 2. ViewModels/ReadinessAdjustmentViewModel.swift ✅

**Purpose:** Business logic for fetching and managing readiness adjustments

**Key Features:**
- Fetch actual applied adjustments from database
- Fetch today's daily readiness check-in
- Generate preview of potential adjustments before application
- Apply adjustments to a session
- Computed properties for UI display:
  - `hasActiveAdjustments`: Whether modifications are active
  - `currentBand`: Current readiness band
  - `readinessScore`: 0-100 score
  - `bandColor`: Color for indicator
  - `bandDisplayName`: Display text
  - `bandDescription`: Modification description
  - `loadAdjustmentSummary`: Load change summary
  - `volumeAdjustmentSummary`: Volume change summary
  - `specialInstructions`: List of important notes

**Integration:**
- `ReadinessService` for backend calls
- `PTSupabaseClient` for database queries
- Async/await pattern for all network operations

### 3. Views/Patient/ReadinessAdjustmentView.swift ✅

**Purpose:** Patient-facing UI showing how workout was adjusted

**Key Components:**

#### A. ReadinessBandIndicator
- Large circular color-coded indicator
- Score display (0-100)
- Band name and description
- Score bar with color zones:
  - Red: 0-50 (technique only)
  - Orange: 50-70 (skip top set)
  - Yellow: 70-85 (minor reduction)
  - Green: 85-100 (full prescription)

**Color Coding:**
- Green (>85%): Checkmark icon, full prescription
- Yellow (70-85%): Exclamation icon, 7% load reduction
- Orange (50-70%): Triangle icon, skip top set, 12% load reduction
- Red (<50%): X icon, technique only

#### B. AdjustmentSummaryCard / PreviewSummaryCard
- Summary of applied adjustments
- Load adjustment percentage
- Volume adjustment percentage
- Skip top set indicator
- Technique only indicator
- Application timestamp

#### C. SpecialInstructionsCard
- Important warnings and recommendations
- Orange background for visibility
- Checkmark list of instructions

#### D. ExerciseModificationsSection
- Before/after comparison for each exercise
- Load: "135 lbs → 125 lbs"
- Sets: "4 sets → 3 sets"
- Reps: "8-10 reps (no change)"
- Color-coded changes (orange for modifications)

#### E. RecoveryDataCard
- Sleep hours and quality
- Subjective readiness
- WHOOP recovery percentage
- Arm soreness indicators
- Check-in timestamp

**User Experience:**
- Loads adjustment if already applied
- Shows preview if not yet applied
- Clear visual distinction between preview and applied state
- Progressive disclosure of details
- Accessible color contrast
- Error handling with friendly messages

## Integration Points

### Build 39: Auto-Regulation System
- Uses `DailyReadiness` model
- Integrates with `ReadinessService`
- Reads from `daily_readiness` table
- Uses `ReadinessBand` enum

### Build 40: WHOOP Integration
- Displays WHOOP recovery percentage
- Shows HRV-based calculations
- Integrates sleep data

### Database Schema
```sql
-- Reads from readiness_modifications table:
CREATE TABLE readiness_modifications (
  id UUID PRIMARY KEY,
  patient_id UUID REFERENCES patients(id),
  session_id UUID REFERENCES sessions(id),
  daily_readiness_id UUID REFERENCES daily_readiness(id),
  readiness_band TEXT,
  load_adjustment_pct DOUBLE PRECISION,
  volume_adjustment_pct DOUBLE PRECISION,
  skip_top_set BOOLEAN,
  technique_only BOOLEAN,
  modified_exercises JSONB,
  is_practitioner_locked BOOLEAN DEFAULT false,
  locked_by UUID REFERENCES practitioners(id),
  lock_reason TEXT,
  was_overridden BOOLEAN DEFAULT false,
  override_reason TEXT,
  overridden_by UUID,
  overridden_at TIMESTAMPTZ,
  applied_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

## Readiness Band System

### Green Band (>85%)
- **Meaning:** Full recovery, optimal performance state
- **Adjustments:** None
- **Display:** Green checkmark, "Full prescription"
- **Load:** 0% adjustment
- **Volume:** 0% adjustment

### Yellow Band (70-85%)
- **Meaning:** Good recovery, minor fatigue
- **Adjustments:** Reduce top set load by 7%
- **Display:** Yellow exclamation, "Reduce top set load 5-8%"
- **Load:** -7% adjustment
- **Volume:** -20% adjustment

### Orange Band (50-70%)
- **Meaning:** Moderate fatigue, sub-optimal recovery
- **Adjustments:** Skip top set, reduce volume by 35%
- **Display:** Orange triangle, "Skip top set, back-off work only"
- **Load:** -12% adjustment
- **Volume:** -35% adjustment
- **Special:** Skip top set

### Red Band (<50%)
- **Meaning:** Poor recovery, high fatigue or pain
- **Adjustments:** Technique work only, no heavy loading
- **Display:** Red X, "Technique + arm care only"
- **Load:** -100% (no loading)
- **Volume:** -100% (minimal volume)
- **Special:** Technique only, no heavy sets

## Usage Examples

### 1. View Today's Adjustment
```swift
import SwiftUI

struct SessionSummaryView: View {
    @State private var showReadinessAdjustment = false
    let sessionId: String
    let patientId: String
    let exercises: [Exercise]

    var body: some View {
        VStack {
            // Show readiness badge
            Button(action: {
                showReadinessAdjustment = true
            }) {
                Label("View Adjustments", systemImage: "waveform.path.ecg")
            }
        }
        .sheet(isPresented: $showReadinessAdjustment) {
            ReadinessAdjustmentView(
                sessionId: sessionId,
                patientId: patientId,
                exercises: exercises
            )
        }
    }
}
```

### 2. Preview Before Session
```swift
// In TodaySessionViewModel
func previewAdjustments() async {
    let viewModel = ReadinessAdjustmentViewModel()
    await viewModel.generatePreview(
        for: exercises,
        patientId: currentPatientId
    )

    if let preview = viewModel.adjustmentPreview {
        print("Band: \(preview.readinessBand)")
        print("Load adjustment: \(preview.loadAdjustmentPct * 100)%")
        print("Exercises affected: \(preview.estimatedModifiedExercises.count)")
    }
}
```

### 3. Apply Adjustments
```swift
// In ReadinessAdjustmentViewModel
Task {
    await viewModel.applyAdjustments(
        patientId: "patient-id",
        sessionId: "session-id"
    )

    if viewModel.errorMessage == nil {
        print("Adjustments applied successfully!")
    }
}
```

## Testing Checklist

- [x] Model decoding from Supabase JSON
- [x] ViewModel fetches adjustments correctly
- [x] Preview generation works without applied adjustment
- [x] Readiness band indicator displays correct color
- [x] Score bar shows correct zones
- [x] Exercise modifications show before/after comparison
- [x] Special instructions appear for orange/red bands
- [x] Recovery data card displays all metrics
- [x] Error handling shows friendly messages
- [x] Preview vs. applied state clearly distinguished
- [x] Xcode project integration successful

## Files Created

```
/Users/expo/Code/expo/ios-app/PTPerformance/
├── Models/
│   └── ReadinessAdjustment.swift (new)
├── ViewModels/
│   └── ReadinessAdjustmentViewModel.swift (new)
└── Views/
    └── Patient/
        └── ReadinessAdjustmentView.swift (new)
```

## Lines of Code

- **ReadinessAdjustment.swift:** 353 lines
- **ReadinessAdjustmentViewModel.swift:** 224 lines
- **ReadinessAdjustmentView.swift:** 712 lines
- **Total:** 1,289 lines of production Swift code

## Next Steps

### Agent 14: Practitioner Override Controls
- View patient's auto-adjustments
- Lock adjustments to prevent patient override
- Add override reason notes
- Unlock adjustments when recovery improves

### Integration Opportunities
- Link from `TodaySessionView` to show adjustments
- Add badge to session card showing band color
- Integrate with `SessionSummaryView` post-workout
- Show historical adjustments in `HistoryView`

## Success Metrics

- **Patient Education:** Clear visual communication of why workout changed
- **Transparency:** Before/after comparison builds trust
- **Data Visibility:** Recovery data shown alongside modifications
- **Actionable:** Special instructions guide patient behavior
- **Professional:** Polished UI with proper color coding and accessibility

## Notes

- Feature integrates seamlessly with existing Build 39/40 infrastructure
- Readiness band system aligns with physical therapy best practices
- Color coding follows industry standards (traffic light system)
- Preview mode allows "what-if" scenarios before applying
- Practitioner lock fields prepared for Agent 14 override controls

## Linear Issues

- **ACP-209:** Readiness adjustment model
- **ACP-210:** Readiness adjustment ViewModel
- **ACP-211:** Readiness adjustment View UI
- **ACP-214:** Readiness band indicator with color zones

---

**Build Status:** ✅ COMPLETE
**Agent:** Agent 13
**Next Agent:** Agent 14 (Practitioner Override Controls)
