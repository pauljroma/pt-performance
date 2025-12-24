# Linear-Driven Swarms - Quick Start Guide

**Purpose:** How to trigger swarms that pull work from Linear and coordinate across multiple repos
**Last Updated:** 2025-12-23

---

## 🚀 Quick Start - 3 Options

### Option 1: Sync Linear Issues (Fastest)

```bash
# Pull all current Linear issues
tools/scripts/sync.sh linear

# This runs: scripts/linear/sync_issues.py
# Downloads: Issues, states, assignees, labels
# Output: JSON to stdout or .swarms/sessions/latest/linear_issues.json
```

**Use when:** You just want to see current Linear state

---

### Option 2: Create Linear Issues from Specs

```bash
# Create epic/issues from JSON spec
python3 scripts/linear/create_epic.py \
    --title "Q1 2025 Features" \
    --description "Feature set for Q1" \
    --team-id "TEAM_ID"

# Or from JSON file
python3 scripts/linear/create_epic.py --spec epic_spec.json
```

**Use when:** You want to populate Linear with new work

---

### Option 3: Run Full Linear-Driven Swarm (Multi-Repo)

```bash
# Execute the Linear coordination swarm
/swarm-it .swarms/configs/infrastructure/LINEAR_COORDINATION.yaml
```

**What this does:**
1. **Discovery** - Syncs all Linear issues
2. **Distribution** - Groups work by repo (linear-bootstrap, ios-app, quiver)
3. **Execution** - Runs agents in parallel per repo
4. **Integration** - Tests cross-repo changes
5. **Reporting** - Updates Linear statuses, creates outcome report

**Use when:** You want automated multi-repo coordination from Linear

---

## 📊 Multi-Repo Coordination

### Repository Roles

**linear-bootstrap** (this repo)
- **Role:** Orchestration & content deployment hub
- **Owns:** Content library, deployment scripts, swarm coordination
- **Coordinates:** iOS builds, Supabase migrations, content uploads

**ios-app** (`../../../ios-app/PTPerformance`)
- **Role:** Mobile application
- **Coordination:** Via `scripts/orchestration/trigger_ios_build.sh`
- **Linear Labels:** `ios`, `mobile`, `build-XX`

**quiver** (`../../../expo/clients/quiver/quiver_platform`)
- **Role:** Backend intelligence platform (Sapphire)
- **Coordination:** Direct agent coordination
- **Linear Labels:** `backend`, `quiver`, `sapphire`
- **Key Zones:** z07_data_access, z03a_cognitive, z01_presentation/sapphire

### How Linear-Bootstrap Coordinates Other Repos

**For iOS:**
```bash
# Trigger iOS build from linear-bootstrap
scripts/orchestration/trigger_ios_build.sh

# This:
# 1. Navigates to ../../../ios-app/PTPerformance
# 2. Runs fastlane or Xcode build
# 3. Returns build status
# 4. Updates Linear issue
```

**For Supabase:**
```bash
# Apply migration from linear-bootstrap
scripts/orchestration/apply_migration.sh MIGRATION_FILE.sql

# This:
# 1. Reads migration from ../../../supabase/migrations/
# 2. Applies via Supabase CLI, psql, or REST API
# 3. Verifies schema changes
# 4. Updates Linear issue
```

**For Quiver:**
- Direct agent coordination (same parent directory)
- Share Supabase backend
- Coordinate via Linear issues

---

## 🎯 Workflow Examples

### Example 1: Deploy Content from Linear Issue

**Linear Issue:** ACP-123 "Deploy baseball arm care articles"

```bash
# 1. Sync Linear to get issue details
tools/scripts/sync.sh linear

# 2. Deploy content
tools/scripts/deploy.sh content

# 3. Update Linear status
python3 scripts/linear/update_status.py \
    --issue-id "ACP-123" \
    --state "Done" \
    --comment "Deployed 24 arm care articles to Supabase"
```

---

### Example 2: Coordinate iOS Build from Linear

**Linear Issue:** ACP-124 "Build 73 - Safety Alerts Feature"

```bash
# 1. Sync Linear
tools/scripts/sync.sh linear

# 2. Trigger iOS build
scripts/orchestration/trigger_ios_build.sh

# 3. If build succeeds, deploy to TestFlight
scripts/orchestration/deploy_to_testflight.sh

# 4. Update Linear
python3 scripts/linear/update_status.py \
    --issue-id "ACP-124" \
    --state "Done" \
    --comment "Build 73 deployed to TestFlight (build number: 73)"
```

---

### Example 3: Multi-Repo Swarm from Linear

**Scenario:** Linear has 10 issues across 3 repos

```bash
# Run the coordination swarm
/swarm-it .swarms/configs/infrastructure/LINEAR_COORDINATION.yaml
```

**What happens:**

**Phase 1: Discovery**
- Agent 1: Syncs all Linear issues → `linear_issues.json`
- Agent 2: Groups by repo, identifies dependencies

**Phase 2: Parallel Execution**
- Agent 3: Works on linear-bootstrap issues (content deployment)
- Agent 4: Works on ios-app issues (build features) [PARALLEL]
- Agent 5: Works on quiver issues (backend changes) [PARALLEL]

**Phase 3: Integration**
- Agent 6: Tests cross-repo integration
- Agent 7: Updates all Linear issues to "Done"

**Output:** `.outcomes/2025-12/LINEAR_COORDINATION_2025-12-23.md`

---

## 🛠️ Configuration

### Environment Variables

```bash
# Required for Linear API
export LINEAR_API_KEY="lin_api_..."

# Optional - auto-detects if not set
export LINEAR_TEAM_ID="..."

# Required for Supabase
export SUPABASE_URL="https://..."
export SUPABASE_KEY="..."
```

**Check configuration:**
```bash
tools/scripts/validate.sh env
```

---

### Linear API Credentials

**Get your API key:**
1. Go to https://linear.app/settings/api
2. Create new Personal API Key
3. Copy to `.env` file in linear-bootstrap root:
   ```bash
   LINEAR_API_KEY=lin_api_YOUR_KEY_HERE
   ```

**Get your Team ID:**
```bash
# Auto-detect (recommended)
python3 scripts/linear/sync_issues.py

# Or manually from Linear URL
# https://linear.app/your-team/team/TEAM_ID/...
```

---

## 📋 Linear Issue Labels for Multi-Repo Work

**Use these labels to route work:**

- `linear-bootstrap` - Content deployment, orchestration
- `ios` - iOS app features, builds
- `quiver` - Backend intelligence, Sapphire
- `supabase` - Database migrations, schema changes
- `cross-repo` - Requires coordination across repos

**The LINEAR_COORDINATION swarm automatically:**
1. Reads these labels
2. Routes issues to appropriate repo agents
3. Coordinates dependencies
4. Updates statuses when complete

---

## 🚨 Troubleshooting

### "Linear API Key not found"

```bash
# Check .env file
cat .env | grep LINEAR_API_KEY

# If missing, create it
echo "LINEAR_API_KEY=lin_api_YOUR_KEY" >> .env
```

---

### "Can't find ios-app directory"

```bash
# Verify path (from linear-bootstrap root)
ls -la ../../../ios-app/PTPerformance

# If different path, update in:
# - .swarms/configs/infrastructure/LINEAR_COORDINATION.yaml
# - scripts/orchestration/trigger_ios_build.sh
```

---

### "Swarm fails during execution"

```bash
# Check swarm logs
tail -f .swarms/sessions/latest/*.log

# Validate config
.swarms/bin/validate.sh .swarms/configs/infrastructure/LINEAR_COORDINATION.yaml

# Check enforcement (if using /swarm-it)
cat .workspace/swarm_status.json
```

---

## 📖 Additional Resources

**Runbooks:**
- `docs/runbooks/linear-sync.md` - Detailed Linear API integration
- `docs/runbooks/content.md` - Content deployment workflow
- `docs/runbooks/troubleshooting.md` - Common errors

**Architecture:**
- `docs/architecture/repo-map.md` - Repository structure
- `docs/architecture/boundaries.md` - Collision zones for parallel work
- `.swarms/README.md` - Swarm system overview

**Context Templates:**
- `.swarms/context/COMMANDER.md` - Multi-agent coordinator
- `.swarms/context/WORKER.md` - Task executor

---

## ✅ Next Steps

**To start using Linear-driven swarms:**

1. **Verify environment**
   ```bash
   tools/scripts/validate.sh env
   ```

2. **Sync Linear issues**
   ```bash
   tools/scripts/sync.sh linear
   ```

3. **Run coordination swarm**
   ```bash
   /swarm-it .swarms/configs/infrastructure/LINEAR_COORDINATION.yaml
   ```

**The swarm will:**
- ✅ Pull work from Linear
- ✅ Distribute across repos
- ✅ Execute in parallel where safe
- ✅ Update Linear statuses
- ✅ Create comprehensive outcome report

---

**You're ready to go! 🚀**
