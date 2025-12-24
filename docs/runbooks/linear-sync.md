# Linear Sync Runbook

**Purpose:** Sync issues, epics, and tasks with Linear project management
**Time:** 5-10 minutes
**Prerequisites:** `.env` configured with `LINEAR_API_KEY` and `LINEAR_TEAM_ID`

---

## Quick Reference

```bash
# Sync with Linear
tools/scripts/sync.sh linear

# Or directly
python3 scripts/linear/sync_issues.py
```

---

## Overview

Linear is the project management system for the PT Performance platform. This runbook covers syncing Linear issues, creating epics, and updating task status from linear-bootstrap.

**Linear Workspace:** Agent-Control-Plane
**Project:** MVP 1 — PT App & Agent Pilot
**Integration Point:** `scripts/linear/` directory

---

## Complete Workflow

### Step 1: Configure Linear API Access

**Edit `.env` file:**
```bash
# Linear configuration
LINEAR_API_KEY=lin_api_xxxxxxxxxxxx
LINEAR_TEAM_ID=team-id-here
```

**Get API Key:**
1. Go to https://linear.app/settings/api
2. Create new API key
3. Copy to `.env`

**Get Team ID:**
1. Go to your Linear workspace
2. Check URL: `https://linear.app/{team-id}/`
3. Copy team ID to `.env`

**Validate configuration:**
```bash
tools/scripts/validate.sh env
```

---

### Step 2: Sync Issues from Linear

**Fetch all issues for current project:**

```bash
python3 scripts/linear/sync_issues.py
```

**What this does:**
- Fetches all issues from Linear API
- Maps to local tracking structure
- Creates local cache in `.workspace/linear/`
- Updates issue status locally

**Expected output:**
```
✅ Connected to Linear API
📥 Fetching issues from project: MVP 1
✅ Found 65 issues
📊 Breakdown:
   Backlog: 15
   Todo: 20
   In Progress: 25
   Done: 5
✅ Sync complete
```

---

### Step 3: Update Issue Status

**After completing a task:**

```bash
python3 scripts/linear/update_status.py \
  --issue ACP-123 \
  --status "Done" \
  --comment "Completed in Build 74"
```

**Valid statuses:**
- `Backlog` - Not started
- `Todo` - Planned for current sprint
- `In Progress` - Actively working
- `Done` - Completed
- `Canceled` - Won't do

**When to use:**
- ✅ After successful build deployment
- ✅ After completing a feature
- ✅ After fixing a bug
- ✅ After applying migrations
- ✅ After content deployment

---

### Step 4: Create New Epic or Issue

**Create an epic:**

```bash
python3 scripts/linear/create_epic.py \
  --title "Build 75 - Advanced Features" \
  --description "Implement advanced training features" \
  --project "MVP 1"
```

**Create an issue:**

```bash
python3 scripts/linear/create_issue.py \
  --title "Add new article category" \
  --description "Create biomechanics article category" \
  --status "Todo" \
  --epic "BUILD-75"
```

**When to create epics:**
- New build cycle starts
- Major feature set being planned
- New phase of development

**When to create issues:**
- Bug discovered during QA
- Sub-task for large feature
- Testing task after deployment

---

### Step 5: Verify Sync

**Check Linear web app:**
1. Go to https://linear.app/agent-control-plane
2. Navigate to project
3. Verify issue status updated
4. Check comments were added

**Check local cache:**
```bash
cat .workspace/linear/issues.json | jq '.[] | select(.identifier == "ACP-123")'
```

---

## Common Tasks

### After Build Deployment

```bash
# Update issue status
python3 scripts/linear/update_status.py \
  --issue ACP-{BUILD} \
  --status "Done" \
  --comment "Build {N} deployed to TestFlight"

# Create testing issue
python3 scripts/linear/create_issue.py \
  --title "Test Build {N} on TestFlight" \
  --description "QA checklist for build {N}" \
  --status "Todo"
```

### After Content Deployment

```bash
# Update content deployment issue
python3 scripts/linear/update_status.py \
  --issue ACP-CONTENT \
  --status "Done" \
  --comment "Deployed {N} articles to Supabase"
```

### Planning Next Sprint

```bash
# Sync to get latest backlog
python3 scripts/linear/sync_issues.py

# Create epic for new sprint
python3 scripts/linear/create_epic.py \
  --title "Build {N} Sprint" \
  --description "Features and fixes for build {N}"

# Move issues to epic
# (Done via Linear UI or API if needed)
```

---

## Configuration

### Linear Project Structure

```
Agent-Control-Plane (Workspace)
└── MVP 1 — PT App & Agent Pilot (Project)
    ├── Phase 1: Core Infrastructure
    ├── Phase 2: Content System
    ├── Phase 3: AI Integration
    ├── Phase 4: Mobile Features
    └── Phase 5: Production Launch
```

### Issue Naming Convention

```
ACP-{NUMBER}: {Title}

Examples:
- ACP-123: Build 74 Deployment
- ACP-124: Add Biomechanics Articles
- ACP-125: Fix Video Playback Bug
```

### Epic Naming Convention

```
BUILD-{NUMBER}: {Feature Set}

Examples:
- BUILD-74: Advanced Training Features
- BUILD-75: Mobile Optimization
- BUILD-76: AI Assistant Improvements
```

---

## Troubleshooting

### Error: "Linear API authentication failed"

**Problem:** Invalid or missing `LINEAR_API_KEY`

**Solution:**
```bash
# Check .env file
cat .env | grep LINEAR_API_KEY

# Regenerate API key if needed
# Go to https://linear.app/settings/api
# Create new key
# Update .env

# Validate
tools/scripts/validate.sh env
```

---

### Error: "Issue not found: ACP-XXX"

**Problem:** Issue doesn't exist in Linear

**Solution:**
```bash
# Sync to refresh local cache
python3 scripts/linear/sync_issues.py

# Verify issue exists in Linear web app
# Check issue identifier spelling
```

---

### Error: "Rate limit exceeded"

**Problem:** Too many API calls in short time

**Solution:**
```bash
# Wait 60 seconds
sleep 60

# Retry operation
python3 scripts/linear/sync_issues.py

# If frequent, implement rate limiting in scripts
```

---

### Warning: "Local cache outdated"

**Problem:** Local issue cache is stale

**Solution:**
```bash
# Force refresh from Linear
python3 scripts/linear/sync_issues.py --force

# This re-downloads all issues
```

---

## Advanced Usage

### Bulk Update Issues

**Mark all Build 74 issues as Done:**

```bash
# Get all Build 74 issues
python3 scripts/linear/sync_issues.py | \
  jq '.[] | select(.title | contains("Build 74"))' | \
  while read issue; do
    id=$(echo $issue | jq -r '.identifier')
    python3 scripts/linear/update_status.py \
      --issue "$id" \
      --status "Done"
  done
```

### Generate Sprint Report

**Create summary of completed work:**

```bash
python3 scripts/linear/sync_issues.py
python3 << 'EOF'
import json
with open('.workspace/linear/issues.json') as f:
    issues = json.load(f)
    done = [i for i in issues if i['state']['name'] == 'Done']
    print(f"Completed: {len(done)} issues")
    for issue in done:
        print(f"  {issue['identifier']}: {issue['title']}")
EOF
```

---

## Integration with Other Systems

### With Content Deployment

```bash
# After deploying content
tools/scripts/deploy.sh content

# Update Linear issue
python3 scripts/linear/update_status.py \
  --issue ACP-CONTENT \
  --status "Done" \
  --comment "Deployed $(cat deployment_manifest.json | jq '.total_articles') articles"
```

### With iOS Builds

```bash
# After iOS build
cd ../../ios-app/PTPerformance
fastlane build

# Update Linear issue
python3 ../../clients/linear-bootstrap/scripts/linear/update_status.py \
  --issue ACP-BUILD-74 \
  --status "Done" \
  --comment "Build 74 archived and ready for TestFlight"
```

---

## Best Practices

✅ **DO:**
- Sync issues daily to keep cache fresh
- Add comments when updating status (provides context)
- Use consistent issue naming
- Create testing issues after deployments
- Update issues immediately after completing work

❌ **DON'T:**
- Skip sync before bulk operations
- Update issues without comments
- Create duplicate issues (check first)
- Forget to validate .env before syncing
- Batch update too many issues at once (rate limits)

---

## Automation Opportunities

### Automatic Status Updates

**When deploying content:**
```bash
# In tools/scripts/deploy.sh, add:
if [[ "$TARGET" == "content" ]]; then
    # Deploy content
    python3 scripts/content/load_articles.py

    # Auto-update Linear
    python3 scripts/linear/update_status.py \
      --issue "${LINEAR_ISSUE:-ACP-CONTENT}" \
      --status "Done" \
      --comment "Auto-deployed from tools/scripts/deploy.sh"
fi
```

### CI/CD Integration

**In GitHub Actions:**
```yaml
- name: Update Linear on deploy
  run: |
    python3 scripts/linear/update_status.py \
      --issue ${{ github.event.issue.number }} \
      --status "Done" \
      --comment "Deployed via GitHub Actions"
  env:
    LINEAR_API_KEY: ${{ secrets.LINEAR_API_KEY }}
```

---

## See Also

- [Content Deployment](content.md) - Deploy articles (creates Linear issues)
- [Validation](validation.md) - Validate before deployment
- [Troubleshooting](troubleshooting.md) - Common error solutions
- [Repo Map](../architecture/repo-map.md) - Where Linear scripts live

---

## Checklist

**Before syncing:**
- [ ] `.env` has `LINEAR_API_KEY` and `LINEAR_TEAM_ID`
- [ ] Validated environment with `tools/scripts/validate.sh env`
- [ ] Network access to Linear API available

**After updating issues:**
- [ ] Verified status changed in Linear web app
- [ ] Added meaningful comment explaining change
- [ ] Local cache updated

**Regular maintenance:**
- [ ] Sync issues daily
- [ ] Clean up old local cache weekly
- [ ] Review Linear project structure monthly

---

**Total time:** 5-10 minutes per sync operation
