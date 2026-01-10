# Build 71 - Scheduled Sessions Quick Reference

## Agent 2 Complete: ScheduledSession Model & ViewModel

### Usage Examples

#### 1. Fetch Sessions for a Specific Month
```swift
let viewModel = ScheduledSessionsViewModel()
let sessions = try await viewModel.fetchScheduledSessions(
    for: patientId,
    month: 12,  // December
    year: 2025
)
print("Found \(sessions.count) sessions in December 2025")
```

#### 2. Reschedule a Session
```swift
let viewModel = ScheduledSessionsViewModel()
let newDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

try await viewModel.rescheduleSession(
    id: sessionId,
    newDate: newDate
)
// Session rescheduled to tomorrow (keeps same time)
```

#### 3. Complete a Session
```swift
let viewModel = ScheduledSessionsViewModel()

try await viewModel.completeSession(id: sessionId)
// Session marked as completed with timestamp
```

#### 4. Check Session Status
```swift
let session: ScheduledSession = ...

if session.isCompleted {
    print("Session completed!")
} else if session.isMissed {
    print("Session was missed")
} else if session.isUpcoming {
    print("Session coming up: \(session.relativeTimeString)")
}
```

#### 5. Display Session Information
```swift
let session: ScheduledSession = ...

Text(session.formattedDate)           // "Dec 25, 2025"
Text(session.formattedTime)           // "2:00 PM"
Text(session.relativeTimeString)     // "Tomorrow at 2:00 PM"
```

## Model Properties

### ScheduledSession
```swift
struct ScheduledSession {
    // Database fields
    let id: String
    let patientId: String
    let sessionId: String
    let scheduledDate: Date
    let scheduledTime: Date
    let status: ScheduleStatus      // .scheduled, .completed, .cancelled, .rescheduled
    let completedAt: Date?
    let notes: String?

    // Computed properties
    var isCompleted: Bool           // Status is completed
    var isMissed: Bool              // Past due and not completed
    var isUpcoming: Bool            // Future and scheduled
    var isPastDue: Bool             // Past and still scheduled
    var formattedDate: String       // "Dec 25, 2025"
    var formattedTime: String       // "2:00 PM"
    var relativeTimeString: String  // "Tomorrow at 2:00 PM"
}
```

## ViewModel Methods

### ScheduledSessionsViewModel
```swift
class ScheduledSessionsViewModel: ObservableObject {
    // Published properties
    @Published var scheduledSessions: [ScheduledSession]
    @Published var isLoading: Bool
    @Published var errorMessage: String?
    @Published var selectedDate: Date

    // Core methods (Build 71 requirements)
    func fetchScheduledSessions(for patientId: String, month: Int, year: Int) async throws -> [ScheduledSession]
    func rescheduleSession(id: String, newDate: Date) async throws
    func completeSession(id: String) async throws

    // Additional helper methods
    func loadScheduledSessions() async
    func refresh(for patientId: String) async
    func sessionsForDate(_ date: Date) -> [ScheduledSession]
    func hasSessionsOnDate(_ date: Date) -> Bool
}
```

## Error Handling

All async throwing methods use `SchedulingError`:
```swift
do {
    try await viewModel.rescheduleSession(id: sessionId, newDate: newDate)
} catch SchedulingError.sessionNotFound {
    print("Session not found")
} catch SchedulingError.rescheduleFailed(let error) {
    print("Reschedule failed: \(error.localizedDescription)")
} catch {
    print("Unexpected error: \(error)")
}
```

## Backend Integration

### Supabase Table: `scheduled_sessions`
- RLS policies enforce patient can only see their own sessions
- Therapists can see sessions for their patients
- All dates use ISO8601 format

### Required Migrations
- `20251215120000_create_scheduled_sessions.sql` - Creates table
- `20251219000005_add_scheduled_sessions_rls_policies.sql` - RLS policies

## Testing Checklist

- [ ] Fetch sessions for current month
- [ ] Fetch sessions for future month
- [ ] Reschedule session to tomorrow
- [ ] Complete session
- [ ] Check isCompleted property
- [ ] Check isMissed property
- [ ] Check isUpcoming property
- [ ] Verify RLS policies (patient can't see other's sessions)
- [ ] Error handling for invalid dates
- [ ] Error handling for missing session

## Files Modified
1. `/ios-app/PTPerformance/Models/ScheduledSession.swift`
2. `/ios-app/PTPerformance/ViewModels/ScheduledSessionsViewModel.swift`

## Linear Issue
- **ACP-198**: Build 71 - Scheduled Sessions iOS
- **Agent 2 Status**: Complete

## Next Agent
Agent 3 will create the ScheduledSessionsView UI using these models and view models.
