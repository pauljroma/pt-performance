## Linear Integration Scripts

**Purpose:** Linear API integration for issue sync, epic creation, and status updates

---

## Scripts

### sync_issues.py

**Purpose:** Sync issues from Linear API to local tracking

**Usage:**
```bash
# Sync all issues
python3 scripts/linear/sync_issues.py

# Filter by team
python3 scripts/linear/sync_issues.py --team TEAM_ID

# Filter by state
python3 scripts/linear/sync_issues.py --state "In Progress"

# Filter by project
python3 scripts/linear/sync_issues.py --project "Q1 Features"

# Export to CSV
python3 scripts/linear/sync_issues.py --format csv --output issues.csv

# List available teams
python3 scripts/linear/sync_issues.py --list-teams
```

**Features:**
- Fetch issues from Linear GraphQL API
- Filter by team, state, project
- Export to JSON or CSV
- Issue summary by state/team/project
- Pagination support (--limit)

**Output:**
- `linear_issues.json` (default) - All issue data
- `linear_issues.csv` (with --format csv) - Flattened for spreadsheets

---

### create_epic.py

**Purpose:** Create epics (projects) in Linear from specifications

**Usage:**
```bash
# Create from spec file
python3 scripts/linear/create_epic.py epic_spec.json

# Interactive creation
python3 scripts/linear/create_epic.py --interactive

# Dry-run validation
python3 scripts/linear/create_epic.py epic_spec.json --dry-run
```

**Epic Specification Format:**
```json
{
  "name": "Q1 2025 Feature Rollout",
  "description": "Major features for Q1 release",
  "team_ids": ["TEAM_ID_1", "TEAM_ID_2"],
  "target_date": "2025-03-31",
  "state": "planned",
  "issues": [
    {
      "title": "Implement feature X",
      "description": "Details...",
      "priority": 1,
      "estimate": 5
    },
    {
      "title": "Test feature X",
      "description": "Testing plan...",
      "priority": 2,
      "estimate": 3
    }
  ]
}
```

**Features:**
- Create projects (epics) with metadata
- Automatically create child issues
- Interactive mode for quick epics
- Dry-run validation
- Team selection

---

### update_status.py

**Purpose:** Update issue status in Linear

**Usage:**
```bash
# Update issue status
python3 scripts/linear/update_status.py PT-123 "Done"

# Update with comment
python3 scripts/linear/update_status.py PT-123 "In Progress" --comment "Started work"

# List available states
python3 scripts/linear/update_status.py --list-states
```

**Features:**
- Update issue by identifier (e.g., PT-123)
- Add status update comment
- List available workflow states
- Validates state names
- Confirmation before update

**Common States:**
- Backlog
- Todo
- In Progress
- In Review
- Done
- Canceled

---

## Setup

### Prerequisites

```bash
# Install dependencies
pip install requests

# Or use requirements file (if exists)
pip install -r requirements.txt
```

### Configuration

Add to `.env`:

```bash
# Linear API
LINEAR_API_KEY=lin_api_XXXXXXXXXXXXXXXXXXXX
LINEAR_TEAM_ID=TEAM_ID_HERE  # Optional
```

**Get Linear API Key:**
1. Go to https://linear.app/settings/api
2. Create new Personal API Key
3. Copy key (starts with `lin_api_`)
4. Add to `.env`

**Get Team ID:**
```bash
# List all teams and their IDs
python3 scripts/linear/sync_issues.py --list-teams
```

---

## Integration with Canonical Wrappers

These scripts are called by canonical wrappers:

```bash
# tools/scripts/sync.sh linear
# → calls sync_issues.py

# Future: tools/scripts/deploy.sh epic
# → will call create_epic.py
```

See: [`docs/architecture/repo-map.md`](../../docs/architecture/repo-map.md)

---

## Common Workflows

### Weekly Issue Sync

```bash
# Sync all in-progress issues
python3 scripts/linear/sync_issues.py --state "In Progress"

# Export to CSV for reporting
python3 scripts/linear/sync_issues.py --format csv --output weekly_report.csv
```

### Create Epic from Planning Session

```bash
# 1. Create epic spec
cat > q1_features.json << 'EOF'
{
  "name": "Q1 2025 Features",
  "description": "Feature rollout for Q1",
  "team_ids": ["YOUR_TEAM_ID"],
  "target_date": "2025-03-31",
  "issues": [
    {"title": "Feature A", "priority": 1, "estimate": 5},
    {"title": "Feature B", "priority": 2, "estimate": 3}
  ]
}
EOF

# 2. Validate spec
python3 scripts/linear/create_epic.py q1_features.json --dry-run

# 3. Create epic
python3 scripts/linear/create_epic.py q1_features.json
```

### Bulk Status Updates

```bash
# Update issue after deployment
python3 scripts/linear/update_status.py PT-123 "Done" \
    --comment "Deployed to production in build 74"
```

---

## API Rate Limits

Linear API has rate limits:
- **50 requests per minute** for personal API keys
- **100 requests per minute** for organization API keys

Scripts automatically handle rate limiting via `requests` library timeout.

**Best practices:**
- Use `--limit` to fetch fewer issues
- Batch operations where possible
- Cache results locally (JSON files)

---

## Troubleshooting

### "LINEAR_API_KEY environment variable required"

```bash
# Check if .env exists
cat .env | grep LINEAR_API_KEY

# If missing, add to .env
echo "LINEAR_API_KEY=lin_api_XXXXXXXXXXXXXXXXXXXX" >> .env

# Source .env (if running manually)
source .env
```

### "Issue not found"

```bash
# Verify issue identifier
python3 scripts/linear/sync_issues.py | grep PT-123

# Check team
python3 scripts/linear/sync_issues.py --list-teams
```

### "State not found"

```bash
# List available states
python3 scripts/linear/update_status.py --list-states

# Use exact state name (case-insensitive)
python3 scripts/linear/update_status.py PT-123 "In Progress"
```

### "GraphQL errors"

```bash
# Check API key validity
curl -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ viewer { name } }"}'

# Should return your name, not errors
```

---

## Advanced Usage

### Custom Filters

```python
# Modify sync_issues.py to add custom filters
# Example: Filter by labels

filter_parts.append(f'labels: {{ name: {{ eq: "bug" }} }}')
```

### Pagination

```python
# Fetch all issues (not just 50)
# Modify sync_issues.py:

def get_all_issues(client, team_id=None):
    all_issues = []
    cursor = None

    while True:
        issues, cursor = client.get_issues(
            team_id=team_id,
            cursor=cursor,
            limit=50
        )
        all_issues.extend(issues)

        if not cursor:
            break

    return all_issues
```

### Webhooks

Linear supports webhooks for real-time updates. For webhook integration:

1. Create webhook in Linear settings
2. Point to your endpoint
3. Handle incoming issue updates
4. Update local tracking automatically

---

## Examples

### Example 1: Generate Build Report

```bash
# Get all issues completed this week
python3 scripts/linear/sync_issues.py \
    --state "Done" \
    --format csv \
    --output build_74_completed.csv

# Use for build release notes
```

### Example 2: Create Q1 Epic with Issues

```bash
# Create epic spec
cat > q1_epic.json << 'EOF'
{
  "name": "Q1 2025 Goals",
  "description": "Strategic initiatives for Q1",
  "team_ids": ["TEAM_ID"],
  "target_date": "2025-03-31",
  "issues": [
    {
      "title": "Implement readiness adjustment",
      "description": "Allow coaches to adjust workload based on WHOOP data",
      "priority": 1,
      "estimate": 8
    },
    {
      "title": "Add video library",
      "description": "Browse and play exercise videos",
      "priority": 1,
      "estimate": 5
    }
  ]
}
EOF

# Create
python3 scripts/linear/create_epic.py q1_epic.json
```

### Example 3: Update Issue After Deployment

```bash
# After deploying build 74
python3 scripts/linear/update_status.py PT-123 "Done" \
    --comment "✅ Deployed in build 74 to TestFlight

Testing checklist:
- [ ] Verify readiness adjustment UI
- [ ] Test WHOOP data sync
- [ ] Validate load calculation

Build: 74
Date: 2025-01-15
Tester: @john"
```

---

## See Also

- [Linear API Documentation](https://developers.linear.app/docs/graphql/working-with-the-graphql-api)
- [Linear Runbook](../../docs/runbooks/linear-sync.md)
- [Canonical Wrappers](../../tools/scripts/)
- [Repo Map](../../docs/architecture/repo-map.md)
