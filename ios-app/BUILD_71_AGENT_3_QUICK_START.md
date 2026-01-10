# Build 71 Agent 3 - Quick Start Guide

## What Was Implemented

Drag-to-reschedule functionality for scheduled workout sessions in iOS app.

## To Complete the Integration

### 1. Add SessionQuickLogView to Xcode (REQUIRED)

The file `/Users/expo/Code/expo/ios-app/PTPerformance/Views/Scheduling/SessionQuickLogView.swift` exists but needs to be added to the Xcode project.

**Option A: Using Xcode GUI**
1. Open `PTPerformance.xcodeproj` in Xcode
2. Right-click on `Views/Scheduling` folder
3. Select "Add Files to PTPerformance..."
4. Navigate to and select `SessionQuickLogView.swift`
5. Ensure "Copy items if needed" is unchecked
6. Click "Add"

**Option B: Using Ruby Script**
```bash
cd /Users/expo/Code/expo/ios-app
ruby << 'EOF'
require 'xcodeproj'
project = Xcodeproj::Project.open('PTPerformance/PTPerformance.xcodeproj')
target = project.targets.first
group = project.main_group.find_subpath('PTPerformance/Views/Scheduling', true)
file_ref = group.new_reference('SessionQuickLogView.swift')
target.add_file_references([file_ref])
project.save
EOF
```

### 2. Build and Test

```bash
cd /Users/expo/Code/expo/ios-app/PTPerformance
xcodebuild -scheme PTPerformance -sdk iphonesimulator build CODE_SIGNING_ALLOWED=NO
```

### 3. Manual Testing Checklist

- [ ] Long-press on a scheduled session (hold for 0.5s)
- [ ] Verify card scales down and becomes semi-transparent
- [ ] Drag finger over calendar dates
- [ ] Verify green highlight appears on hovered dates
- [ ] Verify past dates are grayed out
- [ ] Drop on a future date
- [ ] Verify confirmation dialog appears with correct date
- [ ] Confirm the reschedule
- [ ] Verify loading spinner appears
- [ ] Verify session moves to new date
- [ ] Test error case (disconnect network, try rescheduling)
- [ ] Verify error alert appears
- [ ] Test cancellation (press "Cancel" in dialog)
- [ ] Test on physical device for haptic feedback

### 4. Backend Verification

Ensure Supabase function exists:
```sql
-- Should exist in migrations
CREATE OR REPLACE FUNCTION reschedule_session(
    p_scheduled_session_id UUID,
    p_new_date DATE,
    p_new_time TIME
) RETURNS scheduled_sessions
```

## Key Files Modified

1. `/Users/expo/Code/expo/ios-app/PTPerformance/Views/Scheduling/ScheduledSessionsView.swift`
   - Added drag-to-reschedule logic (lines 21-500+)

2. `/Users/expo/Code/expo/ios-app/PTPerformance/Views/Scheduling/SessionQuickLogView.swift`
   - Created (placeholder, not part of drag-to-reschedule feature)

## How It Works

1. **Long Press** → Enters drag mode, card becomes semi-transparent
2. **Drag** → Calendar dates highlight when hovered (green border)
3. **Drop** → Shows confirmation: "Reschedule workout to [date]?"
4. **Confirm** → Calls API, shows loading spinner
5. **Success** → Haptic feedback, session moves to new date
6. **Error** → Error alert, session stays on original date

## Troubleshooting

### Build Error: "Cannot find 'SessionQuickLogView' in scope"
- **Solution**: Add SessionQuickLogView.swift to Xcode project (see step 1 above)

### No Haptic Feedback
- **Reason**: Simulators don't support haptics
- **Solution**: Test on physical iPhone/iPad

### Drag Not Working
- **Check**: Ensure session status is "scheduled" (not completed/cancelled)
- **Check**: Ensure long press duration is at least 0.5 seconds

### Calendar Not Highlighting
- **Check**: Verify `isDragging` state is true
- **Check**: Verify `hoveredDate` is being updated

## API Integration

The implementation calls:
```swift
await SchedulingService.shared.rescheduleSession(
    scheduledSessionId: session.id,
    newDate: targetDate,
    newTime: session.scheduledTime  // Keeps original time
)
```

## State Management

All drag state is local to the view:
- `draggedSession`: Currently dragged session
- `isDragging`: Boolean flag for drag mode
- `hoveredDate`: Date under finger during drag
- `showRescheduleConfirmation`: Shows confirm dialog
- `targetRescheduleDate`: New date for reschedule
- `isRescheduling`: Shows loading spinner
- `rescheduleError`: Error message if API fails

## Animation Specs

- **Card Transform**: Spring (0.3s response)
- **Calendar Hover**: Ease-in-out (0.15s)
- **Shadow**: Radius 3→10, Opacity 0.05→0.2
- **Opacity**: 1.0→0.7 during drag
- **Scale**: 1.0→0.95 during drag

## Haptic Feedback

- **Long Press Start**: Medium impact
- **Successful Reschedule**: Selection changed
- **Failed Reschedule**: Error notification

## Linear Issue

**ACP-199**: Drag-to-Reschedule for Scheduled Sessions

Update status to "In Review" once testing is complete.

## Questions?

Refer to detailed documentation:
`/Users/expo/Code/expo/ios-app/BUILD_71_AGENT_3_DRAG_TO_RESCHEDULE_COMPLETE.md`
