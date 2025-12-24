#!/usr/bin/env python3
"""Create Linear issues for Build 74 critical bugs"""
import os
import requests
from datetime import datetime

LINEAR_API_KEY = os.getenv('LINEAR_API_KEY')
TEAM_ID = "PT"  # PT Performance team

def create_issue(title, description, priority=1, labels=None):
    """Create a Linear issue"""
    headers = {
        'Authorization': LINEAR_API_KEY,
        'Content-Type': 'application/json'
    }
    
    query = """
    mutation IssueCreate($input: IssueCreateInput!) {
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
    
    variables = {
        "input": {
            "teamId": TEAM_ID,
            "title": title,
            "description": description,
            "priority": priority,
            "labelIds": labels or []
        }
    }
    
    response = requests.post(
        'https://api.linear.app/graphql',
        headers=headers,
        json={'query': query, 'variables': variables}
    )
    
    if response.status_code == 200:
        data = response.json()
        if data.get('data', {}).get('issueCreate', {}).get('success'):
            issue = data['data']['issueCreate']['issue']
            print(f"✅ Created: {issue['identifier']} - {issue['title']}")
            print(f"   URL: {issue['url']}")
            return issue
    
    print(f"❌ Failed to create issue: {title}")
    print(f"   Response: {response.text}")
    return None

def main():
    print("🚨 Creating Build 74 Critical Bug Issues\n")
    
    # Parent issue
    parent = create_issue(
        title="[CRITICAL] Build 74 - Multiple Production Blockers",
        description=f"""# Build 74 Critical Issues - TestFlight

**Build:** 74
**Status:** 🔴 CRITICAL - Multiple production blockers
**Uploaded:** 2025-12-23
**Crash Log:** Watchdog timeout (0x8BADF00D) - 10 second UI hang

## Critical Issues Found:

1. ❌ **No help articles showing**
2. ❌ **Debugging logger not working**
3. ❌ **Creating new program crashes app** (Watchdog timeout)
4. ❌ **Learning modules finds no articles/content**
5. ❌ **Cannot find Tabata/TRX timer UI**

## Crash Analysis:

```
Termination: scene-update watchdog transgression
Elapsed total CPU time: 24.820s (user 20.200s, system 4.620s), 25% CPU
Crash Location: ListBatchUpdates.computeRemovesAndInserts
```

The app hung for 10+ seconds during a UICollectionView batch update when creating a program.

## Root Causes (Suspected):

### 1. Content Not Loading
- Articles exist in Supabase (189 rows verified)
- iOS app not fetching or displaying them
- Possible migration mismatch or RLS policy issue

### 2. Interval Timer Not Visible
- Code integrated but UI not appearing
- May need navigation fix or feature flag

### 3. Performance Crash
- List update taking >10 seconds
- Likely fetching too much data synchronously
- Need to add pagination or async loading

## Next Steps:

1. Roll back to Build 73 for production users
2. Fix content loading (RLS policies, migration sync)
3. Add async loading for program creation
4. Make interval timer accessible from UI
5. Add performance monitoring

## Files Affected:
- ViewModels/ArticlesViewModel.swift
- Views/Articles/ArticleBrowseView.swift
- ViewModels/ProgramEditorViewModel.swift
- Views/Therapist/IntervalBlockPickerView.swift
""",
        priority=1  # Urgent
    )
    
    if not parent:
        return
    
    parent_id = parent['id']
    
    # Child issues
    issues = [
        {
            "title": "Fix: Articles not loading in Help/Learn sections",
            "description": """## Problem
No articles showing in:
- Help section
- Learning modules
- Article browse view

## Verified
- 189 articles exist in Supabase `content_items` table
- Migration applied successfully
- Data is there, but iOS app not fetching it

## Investigation Needed
1. Check RLS policies on `content_items` table
2. Verify ArticlesViewModel.swift is being called
3. Check if search_content RPC function works
4. Look for SwiftUI view lifecycle issues

## Files to Check
- ViewModels/ArticlesViewModel.swift:55 (loadFeaturedArticles)
- Views/Articles/ArticleBrowseView.swift
- Services/SupabaseManager.swift

## Fix Strategy
1. Add debug logging to ArticlesViewModel
2. Test RPC call directly in Supabase dashboard
3. Check if anon key has SELECT permission
4. Verify view is calling loadFeaturedArticles on appear
""",
            "priority": 1
        },
        {
            "title": "Fix: Program creation crashes app (Watchdog timeout)",
            "description": """## Crash Details
```
Termination Code: 0x8BADF00D (Watchdog)
Reason: scene-update watchdog transgression
Time: 10+ seconds UI hang
Location: ListBatchUpdates.computeRemovesAndInserts
```

## Root Cause
When creating a new program, the app is doing a large UICollectionView batch update synchronously on the main thread, causing a 10 second hang.

## Stack Trace
```
ListBatchUpdates.computeRemovesAndInserts
UICollectionViewListCoordinator.update
UpdateCollectionViewListCoordinator.updateValue
GraphHost.flushTransactions
```

## Fix Strategy
1. Add async/await to program creation
2. Use pagination for exercise lists
3. Add loading indicators
4. Defer heavy computations off main thread

## Files Affected
- ViewModels/ProgramEditorViewModel.swift
- Views/Therapist/ProgramBuilder/SessionBuilderSheet.swift
- Views/Therapist/ProgramEditorView.swift

## Priority
CRITICAL - App crashes on core functionality
""",
            "priority": 1
        },
        {
            "title": "Fix: Tabata/EMOM timer not accessible from UI",
            "description": """## Problem
User cannot find the Tabata/TRX interval timer that was added in Build 74.

## Code Status
✅ IntervalTimerEngine.swift - integrated
✅ IntervalTimerView.swift - integrated
✅ IntervalBlockPickerView.swift - integrated
✅ Database migration - applied
✅ Templates seeded - 6 templates in DB

## Investigation
Where should users access this feature?
1. Therapist: Edit Session → "Add Warmup Block" button?
2. Patient: Today's Session → Interval block card?

## Files to Check
- Views/Therapist/ProgramEditor/EditSessionView.swift:143-183
- TodaySessionView.swift
- ViewModels/TodaySessionViewModel.swift

## Fix Strategy
1. Verify "Add Warmup Block" button is visible
2. Check if intervalBlocks are being fetched
3. Add navigation from patient view to timer
4. Add onboarding/discovery for new feature

## Acceptance Criteria
- Therapist can add interval blocks to sessions
- Patient can see and launch interval timers
- Timer UI works as designed (TRX-style)
""",
            "priority": 2
        },
        {
            "title": "Fix: Debug logging not working in Build 74",
            "description": """## Problem
DebugLogger or logging service not working, making it hard to diagnose issues.

## Impact
Cannot see diagnostic logs for:
- Article loading failures
- Database query errors
- Navigation issues
- Timer initialization

## Files to Check
- Services/ErrorLogger.swift
- Services/PerformanceMonitor.swift
- Any DebugLogger usage

## Fix Strategy
1. Verify logger is initialized
2. Check if logs are being written
3. Add Sentry integration for remote logging
4. Add console logging fallback

## Priority
High - Needed to debug other issues
""",
            "priority": 2
        }
    ]
    
    print(f"\nCreating {len(issues)} sub-issues...\n")
    
    for issue_data in issues:
        create_issue(
            title=issue_data["title"],
            description=issue_data["description"],
            priority=issue_data["priority"]
        )
        print()

if __name__ == '__main__':
    main()
