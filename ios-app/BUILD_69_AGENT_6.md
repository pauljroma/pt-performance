# Build 69 - Agent 6: Safety & Audit - iOS Lead

**Date:** December 19, 2025
**Agent:** Agent 6 - Safety & Audit iOS Lead
**Linear Issues:** ACP-182, ACP-183, ACP-184, ACP-185

## Mission

Implement workload flags UI for therapist safety monitoring with comprehensive flag dashboard, resolution workflow, and patient list integration.

## Deliverables

### 1. WorkloadFlagsViewModel.swift
**Location:** `/Users/expo/Code/expo/ios-app/PTPerformance/ViewModels/WorkloadFlagsViewModel.swift`

**Features:**
- **Flag Loading:** Fetch workload flags from Supabase with therapist filtering
- **Security:** HIPAA-compliant filtering by therapist_id through patient relationship
- **Filtering:** Multiple filter options (severity, flag type, search)
- **Sorting:** Priority-based, date-based, severity-based sorting
- **Resolution Actions:** Acknowledge, dismiss, and bulk resolution
- **Real-time Updates:** Automatic flag removal on resolution

**Key Methods:**
```swift
func loadFlags(therapistId: String?)
func resolveFlag(_ flag: WorkloadFlag)
func dismissFlag(_ flag: WorkloadFlag)
func acknowledgeFlag(_ flag: WorkloadFlag, notes: String?)
func resolveAllForPatient(patientId: UUID)
```

**Filter Types:**
- All / Unresolved
- Spike Detection
- High ACR (Acute:Chronic Ratio)
- Monotony
- Pain Increase
- Velocity Drop
- Command Loss

### 2. WorkloadFlagsView.swift
**Location:** `/Users/expo/Code/expo/ios-app/PTPerformance/Views/Therapist/WorkloadFlagsView.swift`

**Features:**
- **Dashboard Summary:** Quick stats for critical/warning flags, patient count
- **Segmented Lists:** Critical alerts and warnings in separate sections
- **Swipe Actions:** Quick resolve or dismiss with swipe gestures
- **Detail Sheet:** Full flag resolution workflow with optional notes
- **Search & Filter:** Real-time search and multi-criteria filtering
- **Empty States:** Graceful handling when no flags exist

**UI Components:**
- `FlagRow` - Individual flag display with metrics
- `SummaryCard` - Dashboard statistics cards
- `MetricPill` - Current value vs threshold display
- `FlagFilterSheet` - Filter and sort controls
- `FlagResolutionSheet` - Full-screen resolution workflow

### 3. PatientListView.swift Updates
**Location:** `/Users/expo/Code/expo/ios-app/PTPerformance/Views/Therapist/PatientListView.swift`

**Enhancements:**
- **Avatar Badges:** Visual flag indicators on patient avatars
  - Red badge with exclamation for critical flags
  - Orange badge with count for warning flags
- **Flag Count Pills:** Colored pills showing alert count
- **Enhanced Visibility:** High-severity flags prominently displayed

### 4. TherapistTabView.swift Integration
**Location:** `/Users/expo/Code/expo/ios-app/PTPerformance/TherapistTabView.swift`

**Changes:**
- Added "Safety" tab with shield icon
- Integrated WorkloadFlagsView for therapist workload monitoring
- Security check for therapist authentication

## Architecture

### Data Flow
```
Supabase workload_flags table
    ↓
WorkloadFlagsViewModel (HIPAA filtering)
    ↓
WorkloadFlagsView (UI)
    ↓
User Actions (Resolve/Dismiss)
    ↓
Supabase updates (resolved = true)
```

### Security
- **HIPAA Compliance:** All queries filtered by therapist_id
- **Row-Level Security:** Enforced through Supabase RLS policies
- **Authorization:** User must be authenticated therapist

### Database Schema
```sql
workload_flags (
    id UUID PRIMARY KEY,
    patient_id UUID REFERENCES patients(id),
    flag_type TEXT,
    severity TEXT CHECK (severity IN ('yellow', 'red')),
    message TEXT,
    value NUMERIC,
    threshold NUMERIC,
    timestamp TIMESTAMPTZ,
    resolved BOOLEAN DEFAULT false,
    resolved_at TIMESTAMPTZ,
    resolution_notes TEXT
)
```

## Flag Types

1. **High Workload** - Exceeding recommended workload thresholds
2. **Velocity Drop** - Significant decrease in performance metrics
3. **Command Loss** - Decline in control/accuracy metrics
4. **Consecutive Days** - Monotony from insufficient rest
5. **Pain Increase** - Elevated pain scores

## Resolution Workflow

### User Flow
1. Therapist opens Safety tab
2. Views dashboard with critical/warning counts
3. Taps flag to see details
4. Options:
   - **Acknowledge & Resolve:** Mark as addressed (with optional notes)
   - **Dismiss:** Mark as false positive or non-actionable
   - **Swipe to Resolve:** Quick action from list

### Resolution Actions
- **Acknowledge:** Updates `resolved = true`, `resolved_at = NOW()`, optional notes
- **Dismiss:** Same as acknowledge but with "Dismissed by therapist" note
- **Bulk Resolve:** Resolve all flags for a specific patient

## Testing

### Manual Testing Checklist
- [ ] Load flags for therapist (only their patients)
- [ ] Filter by severity (critical/warning)
- [ ] Filter by flag type
- [ ] Search for specific flags
- [ ] Swipe to dismiss flag
- [ ] Swipe to resolve flag
- [ ] Open flag detail sheet
- [ ] Add resolution notes
- [ ] Acknowledge and resolve
- [ ] Verify flag removed from list
- [ ] Check flag badges on PatientListView
- [ ] Verify Security tab appears in TherapistTabView

### Edge Cases
- [ ] Empty state when no flags
- [ ] Loading state
- [ ] Error state (network failure)
- [ ] Non-therapist user access
- [ ] Invalid therapist ID

## Performance Considerations

- **Pagination:** Flags ordered by severity and date (newest first)
- **Caching:** Local flag state prevents redundant queries
- **Optimistic Updates:** UI updates immediately on resolution
- **Lazy Loading:** Patient names loaded on-demand

## Future Enhancements

1. **Push Notifications:** Alert therapists of new critical flags
2. **Analytics:** Flag resolution time tracking
3. **Bulk Actions:** Resolve multiple flags at once
4. **Export:** Generate safety reports
5. **Trends:** Historical flag analysis
6. **Auto-Resolution:** Intelligent flag dismissal based on patterns

## Linear Issues Status

### ACP-182: WorkloadFlagsViewModel
- **Status:** ✅ Complete
- **Deliverable:** Full ViewModel with filtering, sorting, resolution logic

### ACP-183: WorkloadFlagsView Dashboard
- **Status:** ✅ Complete
- **Deliverable:** Complete dashboard UI with summary cards, lists, filters

### ACP-184: Flag Resolution Workflow
- **Status:** ✅ Complete
- **Deliverable:** Swipe actions, detail sheets, acknowledge/dismiss flows

### ACP-185: PatientListView Flag Badges
- **Status:** ✅ Complete
- **Deliverable:** Avatar badges, flag count pills, enhanced visibility

## Files Created

1. `/Users/expo/Code/expo/ios-app/PTPerformance/ViewModels/WorkloadFlagsViewModel.swift`
2. `/Users/expo/Code/expo/ios-app/PTPerformance/Views/Therapist/WorkloadFlagsView.swift`

## Files Modified

1. `/Users/expo/Code/expo/ios-app/PTPerformance/Views/Therapist/PatientListView.swift`
2. `/Users/expo/Code/expo/ios-app/PTPerformance/TherapistTabView.swift`

## Build Status

- [x] ViewModel implementation complete
- [x] View implementation complete
- [x] PatientListView badges added
- [x] TherapistTabView integration
- [x] Files added to Xcode project
- [ ] Compile verification (pending)
- [ ] Linear issues updated (pending)

## Notes

- The existing `WorkloadFlag` model and `WorkloadFlagBanner` components were already in place and functional
- Database schema was previously migrated (20251214160000_fix_workload_flags_schema.sql)
- Integration leverages existing `PatientListViewModel` for patient data
- Security follows HIPAA compliance patterns established in Build 60-65

## Next Steps

1. Verify build compiles successfully
2. Update Linear issues ACP-182 through ACP-185
3. Create test data for demo
4. User acceptance testing with therapists
5. Deploy to TestFlight for validation
