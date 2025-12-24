# BUILD_72A LoggingService Integration Guide

## Quick Start for Other Agents

This guide helps other agents in the BUILD_72A swarm integrate with the LoggingService.

## Import and Access

```swift
import Foundation

// Access the singleton instance
let loggingService = LoggingService.shared
```

## Common Integration Patterns

### 1. Block Completion (Agent 9 - Workout Flow)

When a user completes a block in their workout:

```swift
class WorkoutFlowViewModel: ObservableObject {
    private let loggingService = LoggingService.shared

    func onBlockCompleted(
        patientId: UUID,
        sessionId: UUID,
        blockNumber: Int,
        exerciseId: UUID
    ) async {
        // Log the block completion
        await loggingService.emitBlockCompletion(
            patientId: patientId,
            sessionId: sessionId,
            blockNumber: blockNumber,
            exerciseId: exerciseId,
            metadata: [
                "completed_at": ISO8601DateFormatter().string(from: Date()),
                "device": "iOS"
            ]
        )

        // Continue with your business logic...
        // Update UI, navigate to next block, etc.
    }
}
```

### 2. Pain Reporting (Agent 10 - Pain Tracking)

When a user reports pain during or after exercise:

```swift
class PainTrackingViewModel: ObservableObject {
    private let loggingService = LoggingService.shared

    func submitPainReport(
        patientId: UUID,
        sessionId: UUID?,
        painLevel: Int,
        location: String,
        notes: String?
    ) async {
        // Log the pain report
        var metadata: [String: String] = [
            "reported_at": ISO8601DateFormatter().string(from: Date())
        ]
        if let notes = notes {
            metadata["notes"] = notes
        }

        await loggingService.emitPainReport(
            patientId: patientId,
            sessionId: sessionId,
            painLevel: painLevel,
            location: location,
            metadata: metadata
        )

        // Save to local database, show confirmation, etc.
    }
}
```

### 3. Readiness Check-In (Agent 11 - Daily Readiness)

When a user completes their daily readiness check-in:

```swift
class ReadinessViewModel: ObservableObject {
    private let loggingService = LoggingService.shared

    func submitReadinessCheckIn(
        patientId: UUID,
        readinessScore: Double,
        whoopData: WHOOPData?
    ) async {
        var hrv: Double?
        var sleepHours: Double?
        var metadata: [String: String] = [:]

        // Extract WHOOP data if available
        if let whoop = whoopData {
            hrv = whoop.hrv
            sleepHours = whoop.sleep.duration / 3600 // Convert to hours
            metadata["recovery_score"] = String(whoop.recovery)
            metadata["strain"] = String(format: "%.1f", whoop.strain)
            metadata["data_source"] = "whoop"
        } else {
            metadata["data_source"] = "manual"
        }

        // Log the readiness check-in
        await loggingService.emitReadinessCheckIn(
            patientId: patientId,
            readinessScore: readinessScore,
            hrv: hrv,
            sleepHours: sleepHours,
            metadata: metadata
        )

        // Update local state, navigate to next screen, etc.
    }
}
```

### 4. Session Events (Agent 12 - Session Management)

Track session start and completion:

```swift
class SessionManagementViewModel: ObservableObject {
    private let loggingService = LoggingService.shared

    func startSession(session: ScheduledSession) async {
        let event = LogEvent(
            eventType: .sessionStarted,
            patientId: session.patientId,
            sessionId: session.id,
            metadata: [
                "scheduled_at": ISO8601DateFormatter().string(from: session.scheduledFor),
                "started_at": ISO8601DateFormatter().string(from: Date())
            ]
        )

        await loggingService.emit(event)
    }

    func completeSession(session: ScheduledSession, duration: TimeInterval) async {
        let event = LogEvent(
            eventType: .sessionCompleted,
            patientId: session.patientId,
            sessionId: session.id,
            metadata: [
                "duration_seconds": String(Int(duration)),
                "completed_at": ISO8601DateFormatter().string(from: Date())
            ]
        )

        await loggingService.emit(event)
    }
}
```

### 5. Workload Flagging (Agent 13 - Safety Monitoring)

When workload thresholds are exceeded:

```swift
class SafetyMonitoringService: ObservableObject {
    private let loggingService = LoggingService.shared

    func flagExcessiveWorkload(
        patientId: UUID,
        sessionId: UUID,
        metric: String,
        threshold: Double,
        actual: Double
    ) async {
        let event = LogEvent(
            eventType: .workloadFlagged,
            patientId: patientId,
            sessionId: sessionId,
            metadata: [
                "metric": metric,
                "threshold": String(format: "%.2f", threshold),
                "actual": String(format: "%.2f", actual),
                "flagged_at": ISO8601DateFormatter().string(from: Date())
            ]
        )

        await loggingService.emit(event)

        // Show alert, adjust program, etc.
    }
}
```

## Advanced Usage

### Custom Events

If you need to track events not covered by the factory methods:

```swift
// Create custom event
let customEvent = LogEvent(
    eventType: .exerciseStarted, // Or any event type
    patientId: patientId,
    sessionId: sessionId,
    exerciseId: exerciseId,
    metadata: [
        "custom_field_1": "value1",
        "custom_field_2": "value2"
    ]
)

// Emit custom event
await loggingService.emit(customEvent)
```

### Monitoring Queue Status

Display queue status in admin/debug views:

```swift
struct DebugLoggingView: View {
    @StateObject private var loggingService = LoggingService.shared

    var body: some View {
        VStack(alignment: .leading) {
            Text("Logging Service Status")
                .font(.headline)

            HStack {
                Text("Network:")
                Text(loggingService.isOnline ? "Online" : "Offline")
                    .foregroundColor(loggingService.isOnline ? .green : .red)
            }

            HStack {
                Text("Queued Events:")
                Text("\(loggingService.queuedEventCount)")
            }

            if loggingService.queuedEventCount > 0 {
                Button("Sync Now") {
                    Task {
                        await loggingService.syncQueuedEvents()
                    }
                }
                .disabled(loggingService.isSyncing)
            }

            // Performance metrics
            let metrics = loggingService.getPerformanceMetrics()
            Text(metrics.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
```

### Error Handling

The service handles errors internally and logs to console. For critical flows, check the return value:

```swift
let success = await loggingService.emit(event)

if !success {
    // Event was queued for later sync
    print("Event queued. Will sync when online.")
} else {
    // Event was successfully sent to Supabase
    print("Event sent immediately.")
}
```

## Testing Your Integration

### Unit Tests

```swift
class YourViewModelTests: XCTestCase {
    var viewModel: YourViewModel!
    var loggingService: LoggingService!

    override func setUp() {
        loggingService = LoggingService.shared
        loggingService.clearQueue()
        viewModel = YourViewModel()
    }

    func testEventEmission() async {
        // Simulate offline to test queueing
        loggingService.setOfflineMode(true)

        // Trigger action that should emit event
        await viewModel.performAction()

        // Verify event was queued
        XCTAssertEqual(loggingService.queuedEventCount, 1)
    }
}
```

### Debug Console

Watch for logging output:

```
[LoggingService] Emitting event: Block 3 completed
[LoggingService] Successfully sent event: 12345678-...
```

Or when offline:

```
[LoggingService] Event queued: Pain reported (level: 6). Queue size: 3
[LoggingService] Connection restored. Auto-syncing queued events...
[LoggingService] Starting sync of 3 queued events
```

## Performance Considerations

### When to Emit Events

✅ **DO** emit events for:
- User actions (block completion, pain reports)
- State changes (session start/end)
- System events (workload flags)

❌ **DON'T** emit events for:
- UI interactions (button taps, scrolling)
- Frequent polling (every second)
- Debug/development logging

### Batching

The service automatically batches events when syncing. No need to batch manually.

### Metadata Size

Keep metadata reasonably sized (< 1KB per event). Use references instead of full objects:

```swift
// ✅ Good - use IDs
metadata = [
    "exercise_id": exercise.id.uuidString,
    "program_id": program.id.uuidString
]

// ❌ Bad - don't serialize full objects
metadata = [
    "exercise": try? JSONEncoder().encode(exercise).base64EncodedString()
]
```

## Troubleshooting

### Events Not Syncing

1. Check network status: `loggingService.isOnline`
2. Check queue size: `loggingService.queuedEventCount`
3. Manually trigger sync: `await loggingService.syncQueuedEvents()`
4. Check console logs for errors

### Duplicate Events

The service prevents duplicates automatically. If you're seeing duplicates:

1. Ensure you're not creating new event objects with different IDs
2. Check that validation logic isn't bypassed
3. Use the same event instance for retries

### Queue Growing Large

If the queue exceeds 100 events:

1. Check Supabase connection configuration
2. Verify network connectivity
3. Check console for sync errors
4. Consider manual sync

## Database Schema

Ensure your Supabase `workout_events` table matches:

```sql
CREATE TABLE workout_events (
    id UUID PRIMARY KEY,
    event_type TEXT NOT NULL,
    patient_id UUID NOT NULL REFERENCES patients(id),
    session_id UUID REFERENCES scheduled_sessions(id),
    exercise_id UUID REFERENCES exercises(id),
    block_number INTEGER,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for common queries
CREATE INDEX idx_workout_events_patient_id ON workout_events(patient_id);
CREATE INDEX idx_workout_events_session_id ON workout_events(session_id);
CREATE INDEX idx_workout_events_event_type ON workout_events(event_type);
CREATE INDEX idx_workout_events_timestamp ON workout_events(timestamp DESC);
```

## Event Type Reference

| Event Type | When to Use | Required Fields |
|-----------|-------------|----------------|
| `blockCompleted` | User finishes a block | `sessionId`, `blockNumber` |
| `painReported` | User reports pain | `metadata.pain_level` |
| `readinessCheckIn` | Daily readiness check | `metadata.readiness_score` |
| `sessionStarted` | Session begins | `sessionId` |
| `sessionCompleted` | Session ends | `sessionId` |
| `exerciseStarted` | Exercise begins | `exerciseId` |
| `exerciseCompleted` | Exercise ends | `exerciseId` |
| `workloadFlagged` | Safety threshold exceeded | `sessionId`, metadata with details |

## Support

For questions or issues:

1. Check console logs with `[LoggingService]` prefix
2. Review this guide and the main documentation
3. Check the unit tests for examples
4. Contact Agent 8 (LoggingService author)

## Files Reference

- **Model**: `/ios-app/PTPerformance/Models/LogEvent.swift`
- **Service**: `/ios-app/PTPerformance/Services/LoggingService.swift`
- **Tests**: `/ios-app/PTPerformance/Tests/Unit/LoggingServiceTests.swift`
- **Documentation**: `/ios-app/PTPerformance/BUILD_72A_AGENT_8_COMPLETE.md`
