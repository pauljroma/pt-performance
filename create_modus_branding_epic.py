#!/usr/bin/env python3
"""
Create Modus Branding Implementation Epic in Linear
"""

import asyncio
import sys
sys.path.insert(0, '/Users/expo/Code/expo/scripts/linear')

from linear_client import LinearClient

LINEAR_API_KEY = "lin_api_fMj4OrC0XqallztdPaS0WAmEvcXDlbKA9jULoZNa"
TEAM_NAME = "Agent-Control-Plane"
PROJECT_NAME = "MVP 1 — PT App & Agent Pilot"

# Priority mapping: 1=urgent, 2=high, 3=medium, 4=low
PRIORITY_URGENT = 1
PRIORITY_HIGH = 2
PRIORITY_MEDIUM = 3
PRIORITY_LOW = 4

EPIC_TITLE = "Epic 19: Modus Branding Implementation"
EPIC_DESCRIPTION = """# Modus Branding Implementation

This epic covers the complete rebranding of the PT Performance app to Modus branding.

## Scope
- App icons and visual assets
- Color palette updates
- App name and bundle identifier changes
- Launch screen redesign
- UI element styling
- Onboarding flow updates
- Marketing assets
- Email templates
- Push notification icons
- Typography audit

## Brand Colors
- Deep Teal: #0D4F4F
- Cyan: #0891B2
- Teal Accent: #14B8A6
- Light Teal: #F0FDFA

## Tagline
"Stop Guessing. Start Recovering."
"""

ISSUES = [
    {
        "title": "ACP-1901: Replace App Icons with Modus Icons",
        "priority": PRIORITY_URGENT,
        "description": """## Zone: iOS

Replace all app icons in Xcode asset catalog with new Modus icons. Update AppIcon.appiconset with all required sizes.

### Tasks
- [ ] Obtain Modus icon assets in all required sizes
- [ ] Replace AppIcon.appiconset contents
- [ ] Verify icon renders correctly on all device sizes
- [ ] Test on both light and dark mode backgrounds
"""
    },
    {
        "title": "ACP-1902: Update App Color Palette to Teal",
        "priority": PRIORITY_HIGH,
        "description": """## Zone: iOS

Replace current color scheme with Modus teal palette.

### Modus Colors
- **Deep Teal:** #0D4F4F
- **Cyan:** #0891B2
- **Teal Accent:** #14B8A6
- **Light Teal:** #F0FDFA

### Tasks
- [ ] Update Color.xcassets with new color definitions
- [ ] Search and replace hardcoded color values
- [ ] Update any programmatic color definitions
- [ ] Test color contrast for accessibility (WCAG 2.1)
- [ ] Verify dark mode variants
"""
    },
    {
        "title": "ACP-1903: Update App Name to Modus",
        "priority": PRIORITY_URGENT,
        "description": """## Zone: iOS

Change app display name from "PT Performance" to "Modus".

### Tasks
- [ ] Update CFBundleDisplayName in Info.plist
- [ ] Update CFBundleName in Info.plist
- [ ] Review and update bundle identifier references
- [ ] Update all UI strings referencing app name
- [ ] Update App Store Connect display name
- [ ] Verify name displays correctly under icon
"""
    },
    {
        "title": "ACP-1904: Update Launch Screen",
        "priority": PRIORITY_HIGH,
        "description": """## Zone: iOS

Replace launch screen with Modus branding.

### Design Specifications
- **Background:** Gradient from #0D4F4F (top) to #14B8A6 (bottom)
- **Logo:** White Modus mark centered
- **Animation:** None (static launch screen)

### Tasks
- [ ] Create LaunchScreen.storyboard updates
- [ ] Add Modus mark asset (white variant)
- [ ] Configure gradient background
- [ ] Test on all device sizes (iPhone SE through Pro Max)
- [ ] Verify launch screen timing
"""
    },
    {
        "title": "ACP-1905: Update Navigation Bar & Tab Bar Styling",
        "priority": PRIORITY_HIGH,
        "description": """## Zone: iOS

Apply Modus colors to navigation bars, tab bars, and system UI elements.

### Specifications
- **Tint Color:** Cyan #0891B2
- **Navigation Bar Background:** System default with teal tint
- **Tab Bar Selected:** Cyan #0891B2
- **Tab Bar Unselected:** Gray (system default)

### Tasks
- [ ] Update UINavigationBar appearance
- [ ] Update UITabBar appearance
- [ ] Configure tint color globally
- [ ] Update any custom navigation components
- [ ] Test with scroll views and content behind bars
"""
    },
    {
        "title": "ACP-1906: Update Onboarding Screens",
        "priority": PRIORITY_MEDIUM,
        "description": """## Zone: iOS

Update onboarding flow with Modus branding, colors, and messaging.

### Requirements
- **Tagline:** "Stop Guessing. Start Recovering."
- **Colors:** Use Modus teal palette
- **Logo:** Display Modus mark on welcome screen

### Tasks
- [ ] Update welcome screen with Modus logo
- [ ] Apply teal color palette to all screens
- [ ] Update copy with new tagline
- [ ] Review and update onboarding illustrations
- [ ] Test complete onboarding flow
"""
    },
    {
        "title": "ACP-1907: Update Marketing Assets",
        "priority": PRIORITY_MEDIUM,
        "description": """## Zone: iOS

Create new App Store screenshots and marketing materials with Modus branding.

### Deliverables
- [ ] iPhone 6.7" screenshots (required)
- [ ] iPhone 6.5" screenshots (required)
- [ ] iPhone 5.5" screenshots (required)
- [ ] iPad Pro screenshots (if applicable)
- [ ] Preview video update (if exists)
- [ ] App Store feature graphic

### Tasks
- [ ] Design screenshot templates with Modus branding
- [ ] Capture new in-app screenshots
- [ ] Add device frames and marketing copy
- [ ] Update App Store Connect with new assets
"""
    },
    {
        "title": "ACP-1908: Update Email Templates",
        "priority": PRIORITY_MEDIUM,
        "description": """## Zone: Edge Functions

Update transactional email templates with Modus branding.

### Email Types to Update
- Welcome email
- Password reset
- Workout completion summaries
- Weekly progress reports

### Tasks
- [ ] Update email header with Modus logo
- [ ] Apply Modus color palette to email templates
- [ ] Update footer with new branding
- [ ] Test email rendering across clients (Gmail, Apple Mail, Outlook)
- [ ] Update Supabase edge functions if applicable
"""
    },
    {
        "title": "ACP-1909: Update Push Notification Icon",
        "priority": PRIORITY_MEDIUM,
        "description": """## Zone: iOS

Update push notification icon to Modus mark for lock screen notifications.

### Requirements
- Icon should be recognizable at small sizes
- Must work on light and dark lock screens
- Follow Apple HIG for notification icons

### Tasks
- [ ] Create notification icon asset (Modus mark silhouette)
- [ ] Add to asset catalog
- [ ] Configure in push notification payload
- [ ] Test notifications on device
"""
    },
    {
        "title": "ACP-1910: Typography Audit",
        "priority": PRIORITY_LOW,
        "description": """## Zone: iOS

Audit all typography to ensure SF Pro Display is used consistently per brand guidelines.

### Brand Typography
- **Primary Font:** SF Pro Display
- **Headings:** SF Pro Display Bold/Semibold
- **Body:** SF Pro Display Regular
- **Captions:** SF Pro Display Light

### Tasks
- [ ] Audit all text styles in app
- [ ] Verify SF Pro Display usage throughout
- [ ] Check font weights and sizes per guidelines
- [ ] Update any non-compliant typography
- [ ] Document typography system for consistency
"""
    }
]


async def get_labels(client, team_id):
    """Get all labels for the team."""
    query = """
    query TeamLabels($teamId: String!) {
        team(id: $teamId) {
            labels {
                nodes {
                    id
                    name
                }
            }
        }
    }
    """
    data = await client.query(query, {"teamId": team_id})
    return data.get("team", {}).get("labels", {}).get("nodes", [])


async def main():
    print("Creating Modus Branding Implementation Epic in Linear...")
    print(f"Team: {TEAM_NAME}")
    print(f"Project: {PROJECT_NAME}")
    print()

    async with LinearClient(LINEAR_API_KEY) as client:
        # Get team
        team = await client.get_team_by_name(TEAM_NAME)
        if not team:
            print(f"Error: Team '{TEAM_NAME}' not found")
            return
        print(f"Found team: {team['name']} ({team['key']})")

        # Get project
        project = await client.get_project_by_name(team["id"], PROJECT_NAME)
        if not project:
            print(f"Error: Project '{PROJECT_NAME}' not found")
            return
        print(f"Found project: {project['name']}")
        print()

        # Get labels to find iOS and Edge Functions labels
        labels = await get_labels(client, team["id"])
        ios_label_id = None
        edge_functions_label_id = None
        for label in labels:
            if label["name"].lower() == "ios":
                ios_label_id = label["id"]
            elif "edge" in label["name"].lower() and "function" in label["name"].lower():
                edge_functions_label_id = label["id"]

        print(f"Labels found - iOS: {ios_label_id}, Edge Functions: {edge_functions_label_id}")
        print()

        # Create the epic (parent issue)
        print(f"Creating Epic: {EPIC_TITLE}")
        epic = await client.create_issue(
            team_id=team["id"],
            title=EPIC_TITLE,
            description=EPIC_DESCRIPTION,
            priority=PRIORITY_HIGH,
            project_id=project["id"]
        )
        print(f"  Created: {epic['identifier']} - {epic['title']}")
        print(f"  URL: {epic['url']}")
        print()

        # Create child issues under the epic
        print("Creating child issues...")
        created_issues = []

        for issue_data in ISSUES:
            # Determine label based on Zone
            label_ids = []
            if "Zone: iOS" in issue_data["description"]:
                if ios_label_id:
                    label_ids.append(ios_label_id)
            elif "Zone: Edge Functions" in issue_data["description"]:
                if edge_functions_label_id:
                    label_ids.append(edge_functions_label_id)

            issue = await client.create_issue(
                team_id=team["id"],
                title=issue_data["title"],
                description=issue_data["description"],
                priority=issue_data["priority"],
                project_id=project["id"],
                parent_id=epic["id"],
                labels=label_ids if label_ids else None
            )
            created_issues.append(issue)
            priority_name = {1: "Urgent", 2: "High", 3: "Medium", 4: "Low"}.get(issue_data["priority"], "None")
            print(f"  Created: {issue['identifier']} - {issue['title']} (Priority: {priority_name})")

        print()
        print("=" * 60)
        print("SUMMARY")
        print("=" * 60)
        print()
        print(f"Epic: {epic['identifier']} - {epic['title']}")
        print(f"URL: {epic['url']}")
        print()
        print("Child Issues:")
        for issue in created_issues:
            print(f"  - {issue['identifier']}: {issue['title']}")
        print()
        print(f"Total: 1 epic + {len(created_issues)} issues created")


if __name__ == "__main__":
    asyncio.run(main())
