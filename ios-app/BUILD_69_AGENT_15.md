# Build 69 - Agent 15: Readiness Adjustment Backend

**Linear Issues:** ACP-215, ACP-216, ACP-217, ACP-218, ACP-219
**Status:** Complete
**Completion Date:** 2025-12-19

---

## Overview

Implemented a comprehensive readiness-based workout adjustment system that automatically modifies training volume and intensity based on recovery metrics from wearables (WHOOP, Apple Watch, Oura) and manual inputs. The system includes practitioner override capabilities with full audit trails.

---

## Deliverables

### 1. Database Schema (ACP-215, ACP-216)

**Migration:** `/supabase/migrations/20251219120002_create_readiness_adjustments.sql`

#### Tables Created

##### `readiness_metrics`
Stores raw readiness data from wearables and manual inputs.

**Key Columns:**
- `patient_id` - Patient reference
- `metric_date` - Date of metrics
- `recovery_score` - Primary metric (0-100)
- `hrv_score` - Heart rate variability (0-100)
- `sleep_score` - Sleep quality (0-100)
- `resting_heart_rate` - RHR in BPM
- `total_sleep_duration_minutes` - Total sleep time
- `deep_sleep_duration_minutes` - Deep sleep duration
- `rem_sleep_duration_minutes` - REM sleep duration
- `hrv_rmssd` - HRV RMSSD in milliseconds
- `strain_score` - Accumulated strain
- `source` - Data source (whoop, apple_watch, oura, manual, system)
- `source_metadata` - Additional source-specific data (JSONB)

**Indexes:**
- `idx_readiness_metrics_patient_id`
- `idx_readiness_metrics_metric_date`
- `idx_readiness_metrics_patient_date`
- `idx_readiness_metrics_source`

##### `readiness_adjustments`
Stores calculated adjustments with practitioner override support.

**Key Columns:**
- `patient_id` - Patient reference
- `adjustment_date` - Date of adjustment
- `session_id` - Optional session reference
- `recovery_score` - Input recovery score
- `hrv_score` - Input HRV score
- `sleep_score` - Input sleep score
- `strain_score` - Input strain score
- `volume_multiplier` - Calculated volume adjustment (0.7-1.3x)
- `intensity_multiplier` - Calculated intensity adjustment (0.7-1.3x)
- `readiness_category` - Category (optimal, good, moderate, low, critical)
- `is_overridden` - Override flag
- `override_reason` - Practitioner override reason
- `overridden_by` - Practitioner who overrode
- `overridden_at` - Override timestamp
- `original_volume_multiplier` - Pre-override volume
- `original_intensity_multiplier` - Pre-override intensity
- `status` - Status (calculated, applied, overridden, expired)
- `recommendations` - Array of recommendations
- `warnings` - Array of warnings
- `algorithm_version` - Algorithm version (v1.0)
- `calculation_metadata` - Algorithm details (JSONB)

**Indexes:**
- `idx_readiness_adjustments_patient_id`
- `idx_readiness_adjustments_date`
- `idx_readiness_adjustments_session_id`
- `idx_readiness_adjustments_patient_date`
- `idx_readiness_adjustments_category`
- `idx_readiness_adjustments_status`
- `idx_readiness_adjustments_overridden` (partial index)

---

### 2. Adjustment Algorithm (ACP-217)

**Function:** `calculate_adjustment_multipliers()`

#### Algorithm Details

**Composite Score Calculation:**
```
Composite = (Recovery × 0.5) + (HRV × 0.25) + (Sleep × 0.20)
```

If metrics missing, recovery score is used as fallback.

**Strain Adjustment:**
- High strain (>15) reduces composite score
- Reduction capped at 10 points
- Formula: `score - min((strain - 15) / 2, 10)`

#### Readiness Categories

| Category | Score Range | Volume Mult | Intensity Mult | Description |
|----------|-------------|-------------|----------------|-------------|
| **Optimal** | 90-100 | 1.1-1.3x | 1.0-1.15x | Excellent recovery - consider progressive overload |
| **Good** | 75-89 | 1.0-1.1x | 0.95-1.0x | Good recovery - proceed with planned training |
| **Moderate** | 60-74 | 0.85-1.0x | 0.85-0.95x | Moderate recovery - reduce volume/intensity slightly |
| **Low** | 40-59 | 0.7-0.85x | 0.7-0.85x | Low recovery - significant reduction recommended |
| **Critical** | 0-39 | 0.5-0.7x | 0.5-0.7x | Critical state - rest day strongly recommended |

#### Recommendations by Category

**Optimal (90-100):**
- Excellent recovery - consider progressive overload
- Optimal conditions for skill work and technique refinement
- Good day for testing maximal efforts or PRs

**Good (75-89):**
- Good recovery - proceed with planned training
- Monitor RPE and adjust within session if needed
- Consider adding optional accessory work

**Moderate (60-74):**
- Moderate recovery - reduce volume and intensity slightly
- Focus on movement quality over load
- Consider eliminating optional exercises
- Monitor for pain or excessive fatigue

**Low (40-59):**
- Low recovery - significant reduction recommended
- Focus on movement practice and technique
- Consider active recovery or mobility work instead
- Prioritize primary movements only

**Critical (<40):**
- Critical recovery state - strongly consider rest day
- If training, use very light loads (technique only)
- Prioritize recovery: sleep, nutrition, stress management
- Monitor for illness or overtraining symptoms

#### Warnings

- High accumulated strain detected → Conservative adjustment
- Low HRV (<40) → Autonomic stress detected
- Poor sleep (<50) → Increased injury risk
- Critical readiness → Consult with practitioner before proceeding

---

### 3. Edge Function (ACP-217)

**Function:** `calculate-readiness-adjustment`
**Path:** `/supabase/functions/calculate-readiness-adjustment/index.ts`

#### Request Format

```typescript
POST /functions/v1/calculate-readiness-adjustment
Authorization: Bearer <token>
Content-Type: application/json

{
  "patient_id": "uuid",
  "adjustment_date": "2025-12-19", // Optional, defaults to today
  "session_id": "uuid", // Optional
  "metrics": { // Optional - if provided, will be inserted first
    "recovery_score": 85,
    "hrv_score": 72,
    "sleep_score": 80,
    "strain_score": 12,
    "source": "whoop",
    "source_metadata": {}
  },
  "force_recalculate": false // Optional - forces recalculation even if exists
}
```

#### Response Format

```typescript
{
  "success": true,
  "adjustment": {
    "adjustment_id": "uuid",
    "patient_id": "uuid",
    "adjustment_date": "2025-12-19",
    "readiness_category": "good",
    "volume_multiplier": 1.05,
    "intensity_multiplier": 0.98,
    "recovery_score": 85,
    "recommendations": [
      "Good recovery - proceed with planned training",
      "Monitor RPE and adjust within session if needed",
      "Consider adding optional accessory work"
    ],
    "warnings": [],
    "status": "calculated"
  },
  "message": "Adjustment calculated successfully"
}
```

#### Error Handling

- **401 Unauthorized** - Missing or invalid auth token
- **401 Access Denied** - User is not patient or their therapist
- **400 Bad Request** - Missing required parameters
- **400 No Metrics** - No readiness metrics found for date

#### Security

- Validates user authentication via Supabase Auth
- Verifies user is either the patient or their assigned therapist
- Uses service role key for database operations
- Full audit trail via `log_audit_event()`

---

### 4. Audit Logging (ACP-218)

All adjustment operations are automatically logged to `audit_logs` table.

#### Logged Events

**Adjustment Creation:**
```
action_type: 'CREATE'
resource_type: 'readiness_adjustment'
operation: 'calculate_adjustment'
description: 'Readiness adjustment calculated: good (volume: 1.05x, intensity: 0.98x)'
```

**Adjustment Override:**
```
action_type: 'UPDATE'
resource_type: 'readiness_adjustment'
operation: 'override_adjustment'
description: 'Practitioner override: volume 1.05→0.90, intensity 0.98→0.85. Reason: Patient reported fatigue'
old_values: {"volume_multiplier": 1.05, "intensity_multiplier": 0.98}
new_values: {"volume_multiplier": 0.90, "intensity_multiplier": 0.85}
```

---

### 5. Row Level Security (ACP-219)

#### `readiness_metrics` Policies

**Patients:**
- ✅ SELECT their own metrics
- ✅ INSERT their own metrics

**Therapists:**
- ✅ SELECT metrics for their patients
- ❌ INSERT (patients and system only)

**System/Admin:**
- ✅ INSERT metrics (for automated imports)

#### `readiness_adjustments` Policies

**Patients:**
- ✅ SELECT their own adjustments
- ❌ UPDATE (therapists only)

**Therapists:**
- ✅ SELECT adjustments for their patients
- ✅ UPDATE adjustments for their patients (override capability)

**System:**
- ✅ INSERT adjustments via functions

---

### 6. Database Functions

#### `calculate_adjustment_multipliers()`
**Purpose:** Calculates volume/intensity multipliers from readiness metrics
**Input:** recovery_score, hrv_score, sleep_score, strain_score
**Output:** volume_multiplier, intensity_multiplier, category, recommendations, warnings
**Security:** Accessible to all authenticated users

#### `create_readiness_adjustment()`
**Purpose:** Creates or updates adjustment record for a patient
**Input:** patient_id, adjustment_date, session_id (optional)
**Output:** adjustment_id
**Security:** SECURITY DEFINER - executes with elevated privileges
**Features:**
- Fetches most recent metrics for date
- Calculates multipliers via `calculate_adjustment_multipliers()`
- Creates/updates adjustment record (if not overridden)
- Logs audit event
- Returns adjustment ID

#### `override_readiness_adjustment()`
**Purpose:** Allows practitioners to override calculated adjustments
**Input:** adjustment_id, volume_multiplier, intensity_multiplier, override_reason
**Output:** success boolean
**Security:** SECURITY DEFINER
**Validations:**
- Multipliers must be between 0.5 and 1.5
- Stores original values before override
- Logs audit event with before/after values
- Updates status to 'overridden'

---

### 7. Helper Views

#### `vw_recent_adjustments`
Shows recent adjustments with patient info.

**Columns:**
- adjustment_id, patient_id, patient_name
- adjustment_date, readiness_category
- recovery_score, volume_multiplier, intensity_multiplier
- is_overridden, status
- recommendations, warnings
- created_at

#### `vw_adjustment_trends`
Shows 7-day rolling averages for trend analysis.

**Columns:**
- patient_id, adjustment_date
- recovery_score, volume_multiplier, intensity_multiplier
- readiness_category
- recovery_score_7d_avg
- volume_multiplier_7d_avg

---

## Integration Guide

### iOS Integration

#### 1. Sync WHOOP/Apple Watch Data

```swift
// HealthKit or WHOOP API integration
struct ReadinessData {
    let recoveryScore: Double
    let hrvScore: Double
    let sleepScore: Double
    let date: Date
}

func syncReadinessMetrics(_ data: ReadinessData) async throws {
    let response = try await supabase.functions.invoke(
        "calculate-readiness-adjustment",
        options: FunctionInvokeOptions(
            body: [
                "patient_id": currentPatientId,
                "metrics": [
                    "recovery_score": data.recoveryScore,
                    "hrv_score": data.hrvScore,
                    "sleep_score": data.sleepScore,
                    "source": "apple_watch",
                    "metric_date": ISO8601DateFormatter().string(from: data.date)
                ]
            ]
        )
    )

    let adjustment = try response.decode(to: AdjustmentResponse.self)
    // Use adjustment.volume_multiplier and adjustment.intensity_multiplier
}
```

#### 2. Apply Adjustments to Workouts

```swift
func applyReadinessAdjustment(to session: Session) async throws {
    // Fetch today's adjustment
    let adjustment = try await supabase
        .from("readiness_adjustments")
        .select()
        .eq("patient_id", currentPatientId)
        .eq("adjustment_date", today)
        .single()
        .execute()

    // Apply multipliers to session
    for exercise in session.exercises {
        exercise.adjustedSets = Int(Double(exercise.targetSets) * adjustment.volumeMultiplier)
        exercise.adjustedLoad = exercise.targetLoad * adjustment.intensityMultiplier
    }

    // Show warnings/recommendations to user
    if !adjustment.warnings.isEmpty {
        showReadinessWarnings(adjustment.warnings)
    }
}
```

#### 3. Practitioner Override

```swift
func overrideAdjustment(
    adjustmentId: UUID,
    volumeMultiplier: Double,
    intensityMultiplier: Double,
    reason: String
) async throws {
    try await supabase.rpc(
        "override_readiness_adjustment",
        params: [
            "p_adjustment_id": adjustmentId.uuidString,
            "p_volume_multiplier": volumeMultiplier,
            "p_intensity_multiplier": intensityMultiplier,
            "p_override_reason": reason
        ]
    ).execute()
}
```

---

## Testing

### Test Scenarios

#### 1. Optimal Readiness
```sql
INSERT INTO readiness_metrics (patient_id, metric_date, recovery_score, hrv_score, sleep_score, source)
VALUES ('patient-uuid', '2025-12-19', 95, 90, 92, 'test');

SELECT * FROM create_readiness_adjustment('patient-uuid', '2025-12-19', NULL);
-- Expected: volume ~1.15-1.20x, intensity ~1.10-1.15x, category 'optimal'
```

#### 2. Low Readiness
```sql
INSERT INTO readiness_metrics (patient_id, metric_date, recovery_score, hrv_score, sleep_score, source)
VALUES ('patient-uuid', '2025-12-19', 45, 38, 42, 'test');

SELECT * FROM create_readiness_adjustment('patient-uuid', '2025-12-19', NULL);
-- Expected: volume ~0.70-0.75x, intensity ~0.70-0.75x, category 'low'
```

#### 3. Practitioner Override
```sql
-- Get adjustment ID
SELECT id FROM readiness_adjustments WHERE patient_id = 'patient-uuid' AND adjustment_date = '2025-12-19';

-- Override it
SELECT override_readiness_adjustment(
    'adjustment-uuid',
    0.90,
    0.85,
    'Patient reported feeling fatigued despite good metrics'
);

-- Verify override
SELECT is_overridden, override_reason, original_volume_multiplier, volume_multiplier
FROM readiness_adjustments WHERE id = 'adjustment-uuid';
```

#### 4. Edge Function Test
```bash
curl -X POST https://your-project.supabase.co/functions/v1/calculate-readiness-adjustment \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "patient_id": "patient-uuid",
    "metrics": {
      "recovery_score": 85,
      "hrv_score": 78,
      "sleep_score": 82,
      "source": "whoop"
    }
  }'
```

---

## Production Considerations

### 1. Automated Metric Imports

Set up scheduled jobs to import metrics from wearable APIs:

```typescript
// Deno cron job (runs daily at 6 AM)
Deno.cron("Import WHOOP metrics", "0 6 * * *", async () => {
  const patients = await getActivePatients();

  for (const patient of patients) {
    if (patient.whoopAccessToken) {
      const metrics = await fetchWHOOPMetrics(patient.whoopAccessToken);
      await insertReadinessMetrics(patient.id, metrics);
      await createReadinessAdjustment(patient.id);
    }
  }
});
```

### 2. Notification System

Alert patients when adjustments are significant:

```typescript
if (adjustment.readiness_category === 'critical' || adjustment.warnings.length > 0) {
  await sendPushNotification(patient.id, {
    title: "Readiness Alert",
    body: `Your recovery is ${adjustment.readiness_category}. Consider modifying today's workout.`,
    data: { adjustment_id: adjustment.id }
  });
}
```

### 3. Historical Trend Analysis

Use `vw_adjustment_trends` for long-term pattern detection:

```sql
-- Detect chronic low readiness
SELECT
  patient_id,
  COUNT(*) as low_days,
  AVG(recovery_score) as avg_recovery
FROM readiness_adjustments
WHERE adjustment_date >= CURRENT_DATE - INTERVAL '30 days'
  AND readiness_category IN ('low', 'critical')
GROUP BY patient_id
HAVING COUNT(*) > 10;
```

---

## Migration Instructions

### Apply Migration
```bash
cd /Users/expo/Code/expo/supabase
supabase db push
```

### Deploy Edge Function
```bash
cd /Users/expo/Code/expo/supabase
supabase functions deploy calculate-readiness-adjustment
```

### Verify Deployment
```sql
-- Check tables exist
\dt readiness_*

-- Check functions exist
\df calculate_adjustment_multipliers
\df create_readiness_adjustment
\df override_readiness_adjustment

-- Check views exist
\dv vw_*adjustment*

-- Test function
SELECT * FROM calculate_adjustment_multipliers(85, 78, 82, 12);
```

---

## Linear Issue Updates

### ACP-215: Create readiness_adjustments table
**Status:** ✅ Complete
- Created `readiness_metrics` table
- Created `readiness_adjustments` table
- Added indexes and constraints
- Enabled RLS with appropriate policies

### ACP-216: Implement adjustment algorithm
**Status:** ✅ Complete
- Implemented `calculate_adjustment_multipliers()` function
- Composite scoring: Recovery (50%), HRV (25%), Sleep (20%)
- 5 readiness categories with distinct multiplier ranges
- Context-aware recommendations and warnings
- Strain adjustment logic

### ACP-217: Create adjustment Edge Function
**Status:** ✅ Complete
- Implemented `calculate-readiness-adjustment` Edge Function
- Supports metric insertion and adjustment calculation
- Authentication and authorization checks
- Error handling and response formatting

### ACP-218: Add adjustment audit logging
**Status:** ✅ Complete
- Integration with `log_audit_event()` function
- Logs adjustment creation with category and multipliers
- Logs practitioner overrides with before/after values
- Full compliance with HIPAA audit requirements

### ACP-219: Implement practitioner override RLS policies
**Status:** ✅ Complete
- RLS policies for `readiness_metrics` (patient view/insert, therapist view)
- RLS policies for `readiness_adjustments` (patient view, therapist view/update)
- `override_readiness_adjustment()` function with validation
- Audit trail for all overrides

---

## Files Created

1. `/supabase/migrations/20251219120002_create_readiness_adjustments.sql` - Database schema
2. `/supabase/functions/calculate-readiness-adjustment/index.ts` - Edge Function
3. `/ios-app/BUILD_69_AGENT_15.md` - This documentation

---

## Next Steps

1. **iOS Integration:** Implement HealthKit/WHOOP data sync
2. **UI Components:** Build readiness dashboard and adjustment views
3. **Automated Imports:** Set up cron jobs for wearable data import
4. **Notifications:** Alert patients of significant adjustments
5. **Analytics:** Build practitioner dashboard for readiness trends
6. **Testing:** Comprehensive integration tests with real patient data

---

## Support

For questions or issues, contact the development team or reference:
- Migration: `20251219120002_create_readiness_adjustments.sql`
- Edge Function: `calculate-readiness-adjustment`
- Linear Issues: ACP-215 through ACP-219
