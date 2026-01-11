# BUILD 143 - Timer Testing Instructions

## Phase 2: Timer Functionality Testing

**Objective:** Verify timers create and start without RLS policy violations

### Test Case 1: Preset Timer (5 Minute AMRAP)

1. **Open BUILD 143** on TestFlight device
2. **Navigate to Timers tab**
3. **Select "5 Minute AMRAP"** preset
4. **Tap "Start Timer"**
5. **Expected Result:** Timer starts counting without errors
6. **Let run for 10-15 seconds**, then stop
7. **Shake device** to open debug log viewer
8. **Check for errors:** Should see NO `[TIMER_START]` errors
9. **Check Supabase dashboard** → workout_timers table → Verify new record exists

### Test Case 2: Custom Timer

1. **Navigate to Custom Timer Builder**
2. **Create a simple timer:**
   - Name: "Test Timer"
   - Intervals: 1 work interval, 30 seconds
3. **Tap "Create"**
4. **Expected Result:** Timer created successfully
5. **Start the timer**
6. **Expected Result:** Timer starts without errors
7. **Shake device** → Check debug logs
8. **Expected:** No `[CUSTOM_TIMER]` errors

### Success Criteria

**✅ PASS if:**
- Timers start successfully
- No `[TIMER_START]` errors in debug logs
- No "new row violates row-level security policy" errors
- workout_timers table contains new records

**❌ FAIL if:**
- Timers fail to start
- RLS policy violation errors appear
- No database records created

### Report Format

After testing, provide:

```
Test Case 1: Preset Timer
- Result: [PASS/FAIL]
- Errors seen: [None / List errors]
- Database record: [Yes / No]

Test Case 2: Custom Timer
- Result: [PASS/FAIL]
- Errors seen: [None / List errors]
- Database record: [Yes / No]

Debug Log Output:
[Paste relevant log entries]
```

---

**Ready to test?** Follow the steps above and report results.
