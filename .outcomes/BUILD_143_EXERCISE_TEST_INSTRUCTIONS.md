# BUILD 143 - Exercise Logging Testing Instructions

## Phase 3: Exercise Logging Functionality Testing

**Objective:** Verify exercise logs save without `calculate_rm_estimate` function errors

### Test Case 1: Single Exercise with Multiple Sets

1. **Open BUILD 143** on TestFlight device
2. **Navigate to Exercise Log section**
3. **Select an exercise** (e.g., "Bench Press")
4. **Log 3 sets with following reps:**
   - Set 1: 100 lbs × 10 reps
   - Set 2: 100 lbs × 8 reps
   - Set 3: 100 lbs × 6 reps
5. **Add RPE:** 8/10
6. **Add Pain Score:** 0/10
7. **Tap "Save"**
8. **Expected Result:** Exercise saves successfully
9. **Shake device** → Check debug logs
10. **Expected:** No `[EXERCISE_SAVE]` errors
11. **Check Supabase dashboard** → exercise_logs table → Verify:
    - New record exists
    - `rm_estimate` = 120.00 (calculated from min reps = 6)

### Test Case 2: Single Set Exercise

1. **Log another exercise**
2. **Single set:** 150 lbs × 5 reps
3. **Save**
4. **Expected Result:** Saves successfully
5. **Check rm_estimate:** Should be ~175.00 (Epley formula: 150 × (1 + 5/30))

### Success Criteria

**✅ PASS if:**
- Exercises save successfully
- No `[EXERCISE_SAVE]` errors in debug logs
- No "function calculate_rm_estimate... does not exist" errors
- RM estimates calculated correctly in database

**❌ FAIL if:**
- Exercise saves fail
- Function not found errors
- RM estimates are NULL or incorrect

### Report Format

```
Test Case 1: Multi-Set Exercise
- Result: [PASS/FAIL]
- Errors seen: [None / List errors]
- Database record: [Yes / No]
- RM Estimate: [Value from database]
- Expected: 120.00

Test Case 2: Single Set Exercise
- Result: [PASS/FAIL]
- Errors seen: [None / List errors]
- RM Estimate: [Value from database]
- Expected: ~175.00

Debug Log Output:
[Paste relevant log entries]
```

---

**Ready to test?** Complete Phase 2 (Timer Testing) first, then proceed with this phase.
