# 🚨 BUILD 74 CRITICAL BUGS - PRODUCTION BLOCKERS

**Build:** 74  
**Status:** 🔴 CRITICAL - DO NOT RELEASE TO PRODUCTION  
**Uploaded to TestFlight:** 2025-12-23 21:29 EST  
**Crash Log Received:** 2025-12-23 21:58 EST  

---

## Critical Issues Summary

| Issue | Severity | Impact |
|-------|----------|--------|
| 1. No help articles showing | 🔴 CRITICAL | Users cannot access 189 articles |
| 2. Debugging logger not working | 🟡 HIGH | Cannot diagnose issues |
| 3. Creating program crashes app | 🔴 CRITICAL | Watchdog timeout, app killed |
| 4. Learning modules empty | 🔴 CRITICAL | No content visible |
| 5. Tabata/TRX timer not findable | 🟡 HIGH | New feature invisible to users |

---

## 1. App Crash Analysis (0x8BADF00D Watchdog)

### Crash Details
```
Termination Code: 0x8BADF00D (ate bad food)
Reason: scene-update watchdog transgression
Duration: App hung for 10+ seconds during UI update
Elapsed CPU: 24.820s (user 20.200s, system 4.620s), 25% CPU
```

### Stack Trace
```
Thread 0 Crashed (Main Thread):
ListBatchUpdates.computeRemovesAndInserts
  → UICollectionViewListCoordinator.update
  → UpdateCollectionViewListCoordinator.updateValue
  → GraphHost.flushTransactions
  → ViewGraphRootValueUpdater.updateGraph
```

### Root Cause
When creating a new program, SwiftUI's List is performing a massive batch update operation synchronously on the main thread. This is taking more than 10 seconds, triggering iOS's watchdog timer which kills the app.

### Files Implicated
- `ViewModels/ProgramEditorViewModel.swift` - Program creation logic
- `Views/Therapist/ProgramBuilder/SessionBuilderSheet.swift` - UI that triggers creation
- SwiftUI List performing batch updates on large datasets

---

## 2. Articles Not Loading

### Symptoms
- Help section shows no articles
- Learning modules show no content  
- Article browse view is empty

### Investigation
**Database Status:**
```sql
SELECT COUNT(*) FROM content_items; 
-- Result: 189 rows ✅
```

Articles exist in database, but iOS app cannot see them.

### Possible Causes
1. **RLS Policies Blocking Access**
   - Anon key may not have SELECT permission on `content_items`
   - Need to verify policies allow public read access

2. **ArticlesViewModel Not Being Called**
   - `loadFeaturedArticles()` may not be triggered on view appear
   - SwiftUI view lifecycle issue

3. **RPC Function Issue**
   - `search_content` function may have permission issues
   - Function parameters may not match

### Files to Check
- `ViewModels/ArticlesViewModel.swift:55` (loadFeaturedArticles)
- `Views/Articles/ArticleBrowseView.swift`
- Supabase RLS policies on `content_items` table

---

## 3. Tabata/TRX Timer Not Accessible

### What Was Built
✅ `Services/IntervalTimerEngine.swift` - Timer logic  
✅ `Views/Workout/IntervalTimerView.swift` - TRX-style UI  
✅ `Views/Therapist/IntervalBlockPickerView.swift` - Template picker  
✅ `Models/IntervalBlock.swift` - Data models  
✅ Database migration applied with 6 templates  

### Problem
User cannot find the feature. Where is it supposed to appear?

**Expected Flow:**
1. **Therapist:** Edit Session → "Add Warmup Block" button → Select Tabata template
2. **Patient:** Today's Session → See interval block card → Tap to launch timer

### Investigation Needed
- Is "Add Warmup Block" button visible?
- Are interval blocks being fetched from database?
- Is navigation wired up correctly?

### Files to Verify
- `Views/Therapist/ProgramEditor/EditSessionView.swift:143-183`
- `TodaySessionView.swift` 
- `ViewModels/TodaySessionViewModel.swift`

---

## 4. Debug Logging Not Working

### Impact
Cannot diagnose issues because logging is broken. This makes fixing other bugs much harder.

### Files to Check
- `Services/ErrorLogger.swift`
- `Services/PerformanceMonitor.swift`
- Any `DebugLogger` usage

---

## Immediate Actions Required

### Priority 1 (Today)
1. ✅ **Do NOT promote Build 74 to production**
2. ⏳ **Fix RLS policies** - Allow anon access to content_items
3. ⏳ **Add async loading** to program creation (fix crash)
4. ⏳ **Add debug logging** to ArticlesViewModel

### Priority 2 (This Week)
5. ⏳ **Make interval timer discoverable** 
6. ⏳ **Add performance monitoring**
7. ⏳ **Test all user flows** before next TestFlight upload

---

## Root Cause Analysis

### Why These Issues Weren't Caught

1. **No QA Testing Protocol**
   - Build uploaded without testing core flows
   - Should test: Help, Learn, Program Creation, New Features

2. **Missing Performance Testing**
   - List updates not tested with realistic data volumes
   - No profiling of synchronous operations

3. **Incomplete Integration**  
   - Interval timer feature built but not wired to UI navigation
   - Feature flags or discovery missing

---

## Recommended Fixes

### Fix #1: Content Loading (RLS Policies)
```sql
-- Allow anonymous SELECT on content_items
ALTER POLICY "Allow public read access" ON content_items
USING (true);

-- Verify search function has correct permissions
GRANT EXECUTE ON FUNCTION search_content TO anon;
```

### Fix #2: Program Creation Crash
```swift
// ProgramEditorViewModel.swift
func createProgram() async {
    await MainActor.run {
        isLoading = true
    }
    
    // Move heavy computation off main thread
    let program = await Task.detached {
        // Build program data
    }.value
    
    await MainActor.run {
        // Update UI
        isLoading = false
    }
}
```

### Fix #3: Make Timer Discoverable
Add prominent "Warmup Timer" button to:
- Today's Session view (patient)
- Session editor toolbar (therapist)

---

## Next Build Checklist

Before uploading Build 75:
- [ ] Fix all 5 critical issues
- [ ] Test Help section loads articles
- [ ] Test Learning modules loads content
- [ ] Test creating new program (no crash)
- [ ] Test finding and using interval timer
- [ ] Verify debug logging works
- [ ] Run on device for 5+ minutes without crash

---

**Status:** Awaiting fixes before next TestFlight upload
**ETA:** Fix and test before end of day
