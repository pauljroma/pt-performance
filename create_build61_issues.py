#!/usr/bin/env python3
"""Create Build 61 Linear issues for Onboarding & User Experience"""

import os
import requests

GRAPHQL_URL = "https://api.linear.app/graphql"
API_KEY = os.getenv("LINEAR_API_KEY", "lin_api_fMj4OrC0XqallztdPaS0WAmEvcXDlbKA9jULoZNa")
ACP_TEAM_ID = "5296cff8-9c53-4cb3-9df3-ccb83601805e"
ACP_TODO_STATE_ID = "6806266a-71d7-41d2-8fab-b8b84651ea37"  # "Todo" state

headers = {
    "Authorization": API_KEY,
    "Content-Type": "application/json"
}

def create_issue(title, description, priority=2):
    """Create a Linear issue"""
    mutation = """
    mutation CreateIssue($input: IssueCreateInput!) {
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

    response = requests.post(
        GRAPHQL_URL,
        json={
            "query": mutation,
            "variables": {
                "input": {
                    "teamId": ACP_TEAM_ID,
                    "title": title,
                    "description": description,
                    "priority": priority,
                    "stateId": ACP_TODO_STATE_ID
                }
            }
        },
        headers=headers
    )

    if response.status_code == 200:
        try:
            data = response.json()
            if data and data.get("data", {}).get("issueCreate", {}).get("success"):
                issue = data["data"]["issueCreate"]["issue"]
                return issue
            else:
                print(f"  Error: {data}")
        except Exception as e:
            print(f"  Error parsing response: {e}")
            print(f"  Response: {response.text}")
    else:
        print(f"  HTTP {response.status_code}: {response.text}")
    return None

print("="*80)
print("Build 61 - Creating Linear Issues")
print("="*80)
print()

issues_to_create = [
    {
        "title": "Build 61 Agent 1: Onboarding Flow",
        "description": """Create first-time user onboarding experience

**Deliverables:**
- OnboardingView.swift (new) - Main onboarding container
- OnboardingPage.swift (new) - Reusable page component
- OnboardingCoordinator.swift (new) - State management
- PTPerformanceApp.swift (updated) - First launch detection
- RootView.swift (updated) - Onboarding presentation
- TherapistTabView.swift (updated) - Tutorial replay
- PatientTabView.swift (updated) - Tutorial replay

**Acceptance Criteria:**
- Onboarding shows on first app launch
- Can skip onboarding at any point
- Can replay tutorial from settings
- Role-specific content displays correctly
- Onboarding status persists (UserDefaults)
- Smooth page transitions with animations

**Estimated Effort:** 4-6 hours
**Priority:** P0 (Critical)
""",
        "priority": 1  # Urgent
    },
    {
        "title": "Build 61 Agent 2: In-App Help System",
        "description": """Build searchable in-app help system

**Deliverables:**
- HelpView.swift (new) - Main help interface with search
- HelpCategoryView.swift (new) - Browse by category
- HelpArticleView.swift (new) - Article display
- HelpArticle.swift (new) - Model with markdown support
- ContextualHelpButton.swift (new) - Reusable help button
- HelpContent.json (new) - 12-15 help articles
- TherapistProgramsView.swift (updated) - Contextual help
- ProgramBuilderView.swift (updated) - Contextual help
- TodaySessionView.swift (updated) - Contextual help
- ProgressChartsView.swift (updated) - Contextual help

**Acceptance Criteria:**
- Help accessible from navigation bar
- Search works across all articles
- Categories organize content logically
- Markdown renders with formatting
- Deep links work to specific articles
- Contextual help opens relevant article

**Estimated Effort:** 3-4 hours
**Priority:** P1 (High)
""",
        "priority": 2  # High
    },
    {
        "title": "Build 61 Agent 3: Exercise Technique Guides",
        "description": """Add exercise technique guides with video

**Deliverables:**
- ExerciseTechniqueView.swift (new) - Full-screen technique guide
- VideoPlayerView.swift (new) - Custom video player with slow-motion
- ExerciseCuesCard.swift (new) - Setup/execution/breathing cues
- 20251217_add_exercise_technique_fields.sql (new) - Database migration
- Exercise.swift (updated) - Add technique fields
- ExerciseLogView.swift (updated) - Technique button
- ExercisePickerView.swift (updated) - Info button

**Database Changes:**
- Add video_url (TEXT)
- Add technique_cues (JSONB)
- Add common_mistakes (TEXT)
- Add safety_notes (TEXT)

**Acceptance Criteria:**
- Technique view opens from exercise log
- Video plays smoothly (if URL provided)
- Slow-motion playback works
- Cues display clearly organized
- Common mistakes highlighted
- Safety notes prominent
- Falls back gracefully if no video

**Estimated Effort:** 4-5 hours
**Priority:** P1 (High)
""",
        "priority": 2  # High
    },
    {
        "title": "Build 61 Agent 4: Form Validation & Accessibility",
        "description": """Improve form validation and accessibility

**Deliverables:**
- ValidationHelpers.swift (new) - Reusable validation functions
- AccessibleFormField.swift (new) - Form field with VoiceOver
- FormValidationIndicator.swift (new) - Real-time validation feedback
- ProgramBuilderView.swift (updated) - Validation
- ExerciseLogView.swift (updated) - Validation
- AuthView.swift (updated) - Validation
- All form views (accessibility labels)

**Validation Rules:**
- Program name: 3-100 characters
- Exercise reps: 1-999, integers only
- Exercise weight: 0-9999, decimals allowed
- Email: Valid email format
- Password: 8+ chars, 1 uppercase, 1 number

**Acceptance Criteria:**
- All text fields validate on input
- Error messages clear and actionable
- VoiceOver reads all elements correctly
- Keyboard navigation works
- Dynamic type scales properly
- High contrast mode supported

**Estimated Effort:** 3-4 hours
**Priority:** P2 (Medium)
""",
        "priority": 3  # Normal
    },
    {
        "title": "Build 61 Agent 5: Coordination & Deployment",
        "description": """Integration, build, and TestFlight deployment

**Tasks:**
- Monitor progress of Agents 1-4
- Resolve integration conflicts
- Add files to Xcode project (12-15 new files)
- Run integration tests
- Update build number (60 → 61)
- Apply database migration
- Archive and upload to TestFlight
- Create deployment documentation
- Update Linear issues to Done

**Deliverables:**
- Build 61 uploaded to TestFlight
- BUILD61_DEPLOYMENT.md
- All Linear issues updated
- Git commit with all changes
- Database migration applied

**Acceptance Criteria:**
- Build 61 on TestFlight
- All deliverables integrated
- No regressions from Build 60
- Documentation complete

**Estimated Effort:** 2-3 hours
**Priority:** P0 (Critical)
**Dependencies:** ACP-154, ACP-155, ACP-156, ACP-157
""",
        "priority": 1  # Urgent
    }
]

created_issues = []

for issue_data in issues_to_create:
    print(f"Creating: {issue_data['title']}")
    issue = create_issue(
        issue_data["title"],
        issue_data["description"],
        issue_data["priority"]
    )

    if issue:
        print(f"  ✅ Created: {issue['identifier']}")
        print(f"     URL: {issue['url']}")
        created_issues.append(issue)
    else:
        print(f"  ❌ Failed to create issue")
    print()

print("="*80)
print("Build 61 Linear Issues Created")
print("="*80)
print()
print("Summary:")
for issue in created_issues:
    print(f"  • {issue['identifier']}: {issue['title']}")
print()
print(f"Total issues created: {len(created_issues)}/5")
print()
