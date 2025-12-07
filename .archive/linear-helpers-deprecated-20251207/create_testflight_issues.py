#!/usr/bin/env python3
"""
Create Linear issues for TestFlight deployment pipeline
"""

import asyncio
import os
from linear_client import LinearClient


ISSUES = [
    {
        "title": "[ROOT CAUSE] Automatic code signing incompatible with GitHub Actions CI/CD",
        "description": """## Problem Statement
After 130+ failed build attempts over 14+ hours, the core issue is:
- GitHub Actions cannot use Xcode's "Automatic Code Signing"
- Automatic signing requires an Apple ID logged into Xcode
- CI/CD runners cannot login to Apple ID accounts
- Error: "No Accounts: Add a new account in Accounts settings"

## Root Causes Identified
1. ❌ **Wrong approach**: Using automatic code signing in Xcode project
2. ❌ **Missing infrastructure**: No certificate/provisioning profile management
3. ❌ **Configuration mismatch**: Bundle ID changed multiple times
4. ✅ **GitHub Actions billing**: Fixed (was blocking for 13 hours)
5. ✅ **API credentials**: Configured correctly

## Solution
Use fastlane match for certificate management (industry standard)""",
        "priority": 0,  # Urgent
        "status": "Done"
    },
    {
        "title": "Set up fastlane match for automated iOS code signing",
        "description": """## Acceptance Criteria
- [ ] Match initialized: `bundle exec fastlane match appstore`
- [ ] Certificates created in Apple Developer Portal for com.ptperformance.app
- [ ] Provisioning profile stored in https://github.com/pauljroma/apple-certificates.git
- [ ] MATCH_PASSWORD saved to GitHub secrets
- [ ] Matchfile configured with correct Bundle ID

## Steps
1. Install bundler: `gem install bundler:2.7.2`
2. Run match: `bundle exec fastlane match appstore --readonly false`
3. Save encryption password to 1Password
4. Verify in Apple Developer Portal
5. Add MATCH_PASSWORD to GitHub secrets

## Blocker
Bundler version mismatch - need to install 2.7.2""",
        "priority": 0,  # Urgent
        "status": "In Progress"
    },
    {
        "title": "Update Xcode project to use manual code signing",
        "description": """## Current Status
- ✅ CODE_SIGN_STYLE = Manual
- ✅ PRODUCT_BUNDLE_IDENTIFIER = com.ptperformance.app
- ⏳ DEVELOPMENT_TEAM = 5NNLBL74XR (needs to be set)
- ⏳ PROVISIONING_PROFILE_SPECIFIER = "match AppStore com.ptperformance.app"

## Command
```bash
cd ios-app/PTPerformance
# Set DEVELOPMENT_TEAM in project.pbxproj
```

## Depends On
Must complete after match setup (previous issue)""",
        "priority": 0,  # Urgent
        "status": "Todo"
    },
    {
        "title": "Verify local iOS build works with fastlane match",
        "description": """## Test Command
```bash
cd ios-app/PTPerformance
export APP_STORE_CONNECT_API_KEY_ID="NKWNDTD3DJ"
export APP_STORE_CONNECT_API_ISSUER_ID="69a6de9d-2840-47e3-e053-5b8c7c11a4d1"
export APP_STORE_CONNECT_API_KEY_CONTENT="<base64>"
export MATCH_PASSWORD="<from-previous-issue>"
bundle exec fastlane beta
```

## Success Criteria
- [ ] Match downloads certificates
- [ ] Build succeeds
- [ ] Upload to TestFlight works
- [ ] Build appears in App Store Connect""",
        "priority": 0,  # Urgent
        "status": "Todo"
    },
    {
        "title": "Configure GitHub Actions for automated iOS deployment",
        "description": """## Missing Configuration
- ⏳ MATCH_PASSWORD (needs to be added to GitHub secrets)

## Success Logs
```
[fastlane] 🔓 Successfully decrypted certificates
[fastlane] 📦 Installing provisioning profile
[fastlane] ▸ ** ARCHIVE SUCCEEDED **
[fastlane] 📤 Uploading to TestFlight...
[fastlane] ✅ Successfully uploaded package
```

## Workflow File
`.github/workflows/ios-testflight.yml` already configured""",
        "priority": 0,  # Urgent
        "status": "Todo"
    },
    {
        "title": "Document iOS TestFlight deployment runbook",
        "description": """## Deliverables
- [ ] RUNBOOK.md with deployment process
- [ ] Troubleshooting guide
- [ ] Certificate rotation procedure
- [ ] Emergency rollback steps

**Estimated time**: 30 minutes""",
        "priority": 2,  # High
        "status": "Todo"
    },
    {
        "title": "Archive deprecated Linear helper scripts and organize workspace",
        "description": """## Problem
Multiple duplicate .env files and 15+ deprecated Python scripts scattered throughout linear-bootstrap folder

## Tasks
- [ ] Create `.archive/linear-helpers-deprecated/` folder
- [ ] Move all deprecated `*_linear_*.py` scripts to archive
- [ ] Keep only: `linear_client.py`, `linear_bootstrap.py`, `create_testflight_issues.py`
- [ ] Consolidate .env files (keep root .env only)
- [ ] Update .gitignore to prevent future .env duplication

## Files to Archive
agent1_linear_updates.py, agent2_linear_update.py, agent2_update_linear.py, agent3_linear_helper.py, check_linear_status.py, complete_mvp_in_linear.py, phase3_linear_update.py, update_deployment_linear.py, and others""",
        "priority": 2,  # High
        "status": "Todo"
    }
]


async def main():
    # Load from .env file if not in environment
    api_key = os.getenv("LINEAR_API_KEY")
    if not api_key:
        env_file = os.path.join(os.path.dirname(__file__), ".env")
        if os.path.exists(env_file):
            with open(env_file) as f:
                for line in f:
                    if line.startswith("LINEAR_API_KEY="):
                        api_key = line.split("=", 1)[1].strip()
                        break

    if not api_key:
        print("❌ LINEAR_API_KEY not set in environment or .env file")
        return

    async with LinearClient(api_key) as client:
        # Get team by name
        team = await client.get_team_by_name("Agent-Control-Plane")
        if not team:
            print("❌ Team 'Agent-Control-Plane' not found")
            return

        team_id = team["id"]
        print(f"✅ Using team: {team['name']} (ID: {team_id})")
        print(f"\n📋 Creating {len(ISSUES)} TestFlight deployment issues...")

        # Create issues without project (simpler approach)
        issue_mutation = """
        mutation CreateIssue($input: IssueCreateInput!) {
            issueCreate(input: $input) {
                issue {
                    id
                    identifier
                    title
                    url
                }
            }
        }
        """

        created_issues = []
        for i, issue in enumerate(ISSUES, 1):
            print(f"  {i}/{len(ISSUES)}: {issue['title'][:60]}...")

            try:
                result = await client.query(issue_mutation, {
                    "input": {
                        "title": f"[TESTFLIGHT] {issue['title']}",
                        "description": issue["description"],
                        "teamId": team_id,
                        "priority": issue["priority"]
                    }
                })

                issue_data = result["issueCreate"]["issue"]
                created_issues.append(issue_data)
                print(f"    ✅ {issue_data['identifier']}: {issue_data['url']}")
            except Exception as e:
                print(f"    ❌ Failed: {e}")

        print(f"\n✅ Created {len(created_issues)} issues")
        print(f"\n🔗 View in Linear: https://linear.app/team/project/{project_id}")


if __name__ == "__main__":
    asyncio.run(main())
