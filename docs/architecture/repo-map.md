# Linear-Bootstrap - Repository Map

**Last Updated:** 2025-12-20
**Purpose:** The canonical map of where everything lives in linear-bootstrap

---

## What is Linear-Bootstrap?

**Linear-Bootstrap is a deployment orchestration client** for the PT Performance platform.

It coordinates:
- **Content deployment** (baseball performance articles to Supabase)
- **Build orchestration** (triggering iOS builds, migrations)
- **Linear sync** (syncing issues, epics, tasks with Linear project management)
- **Multi-agent coordination** (swarm execution for parallel work)

**It does NOT contain:**
- iOS app code (lives in `../../ios-app/`)
- Quiver platform (lives in `../../clients/quiver/`)
- Supabase migrations (lives in `../../supabase/`)

**It DOES coordinate:**
- Deployment pipelines to those systems
- Content uploads to Supabase
- Multi-agent swarms for parallel execution

---

## Quick Navigation

### I Want To...

| **Task** | **Go Here** | **Run This** |
|----------|-------------|--------------|
| Deploy content articles | `docs/help-articles/` | `tools/scripts/deploy.sh content` |
| Create new articles | `docs/help-articles/baseball/{category}/` | Follow `docs/runbooks/content.md` |
| Sync with Linear | `scripts/linear/` | `tools/scripts/sync.sh linear` |
| Run a swarm | `.swarms/` | `/swarm-it .swarms/{config}.yaml` |
| View runbooks | `docs/runbooks/` | Read `docs/runbooks/index.md` |
| Check architecture | `docs/architecture/` | Read `docs/architecture/overview.md` |
| Bootstrap environment | Root | `tools/scripts/bootstrap.sh` |

---

## Directory Structure

```
linear-bootstrap/                       # ROOT OF THIS CLIENT
│
├── docs/                               # 📚 DOCUMENTATION HUB
│   ├── index.md                        # Navigation starting point
│   ├── architecture/                   # System architecture
│   │   ├── repo-map.md                 # 👈 YOU ARE HERE
│   │   ├── overview.md                 # What linear-bootstrap does
│   │   ├── boundaries.md               # What we own vs coordinate
│   │   └── decisions/                  # Architecture Decision Records
│   ├── runbooks/                       # 🔧 OPERATIONAL RUNBOOKS
│   │   ├── index.md                    # Runbook index
│   │   ├── content.md                  # Content deployment
│   │   ├── linear-sync.md              # Linear integration
│   │   ├── swarms.md                   # Swarm execution
│   │   └── troubleshooting.md          # Common issues
│   └── help-articles/                  # 📖 CONTENT LIBRARY
│       ├── README.md                   # Content overview
│       └── baseball/                   # Baseball performance content
│           ├── mental/                 # Mental performance (23 articles)
│           ├── training/               # Training & periodization (66 articles)
│           ├── arm-care/               # Arm care (24 articles)
│           ├── hitting/                # Hitting (10 articles)
│           ├── recovery/               # Recovery (16 articles)
│           ├── speed/                  # Speed & agility (10 articles)
│           ├── nutrition/              # Nutrition (10 articles)
│           ├── mobility/               # Mobility (10 articles)
│           ├── injury-prevention/      # Injury prevention (10 articles)
│           └── warmup/                 # Warm-up protocols (10 articles)
│
├── tools/                              # 🛠️ CANONICAL EXECUTION INTERFACE
│   ├── scripts/                        # Universal wrappers
│   │   ├── bootstrap.sh                # First-time setup
│   │   ├── deploy.sh                   # 👈 DEPLOY EVERYTHING HERE
│   │   ├── test.sh                     # 👈 TEST EVERYTHING HERE
│   │   ├── sync.sh                     # 👈 SYNC LINEAR HERE
│   │   └── validate.sh                 # Validate configs/content
│   └── python/                         # Python-specific helpers
│       ├── deploy_content.py           # Content deployment
│       ├── sync_linear.py              # Linear API integration
│       └── validate_articles.py        # Article validation
│
├── .swarms/                            # 🤖 MULTI-AGENT COORDINATION
│   ├── README.md                       # 👈 HOW TO USE SWARMS
│   ├── context/                        # Agent rehydration context
│   │   ├── COMMANDER.md                # Commander agent template
│   │   └── WORKER.md                   # Worker agent template
│   ├── configs/                        # Swarm YAML configurations
│   │   ├── content/                    # Content creation swarms
│   │   │   ├── baseball-articles.yaml
│   │   │   └── video-content.yaml
│   │   ├── ios/                        # iOS orchestration swarms
│   │   │   ├── build-deploy.yaml
│   │   │   └── testflight.yaml
│   │   └── infrastructure/             # Infrastructure swarms
│   ├── sessions/                       # Active session state
│   │   └── .gitkeep
│   ├── handoffs/                       # Session handoff artifacts
│   │   └── .gitkeep
│   └── bin/                            # Swarm automation
│       ├── rehydrate.sh                # Restore agent context
│       ├── validate.sh                 # Validate swarm configs
│       └── archive.sh                  # Archive completed sessions
│
├── .outcomes/                          # 📊 AGENT WORK PRODUCTS
│   ├── README.md                       # What are outcomes
│   ├── 2025-12/                        # Date-organized outcomes
│   │   └── BASEBALL_CONTENT_LIBRARY_COMPLETE.md
│   └── templates/                      # Outcome templates
│       ├── deployment-report.md
│       └── swarm-summary.md
│
├── scripts/                            # 📜 DEPLOYMENT SCRIPTS
│   ├── linear/                         # Linear API integration
│   │   ├── sync_issues.py
│   │   ├── create_epic.py
│   │   └── update_status.py
│   ├── content/                        # Content management
│   │   ├── load_articles.py            # 👈 MAIN ARTICLE UPLOADER
│   │   ├── validate_frontmatter.py
│   │   └── generate_manifest.py
│   └── orchestration/                  # External system coordination
│       ├── trigger_ios_build.sh
│       ├── apply_migration.sh
│       └── deploy_to_testflight.sh
│
├── config/                             # ⚙️ CONFIGURATION
│   ├── environments/                   # Environment configs
│   │   ├── dev.env.template
│   │   ├── staging.env.template
│   │   └── prod.env.template
│   ├── linear/                         # Linear configuration
│   │   └── project-config.json
│   └── content/                        # Content system config
│       └── article-schema.json
│
├── tests/                              # 🧪 TESTS
│   ├── unit/                           # Unit tests
│   │   ├── test_article_loader.py
│   │   └── test_linear_sync.py
│   ├── integration/                    # Integration tests
│   │   ├── test_content_deployment.py
│   │   └── test_linear_integration.py
│   └── fixtures/                       # Test fixtures
│
├── .env.template                       # Environment template
├── .env                                # Environment variables (gitignored)
├── deployment_manifest.json            # Deployment tracking
├── pyproject.toml                      # Python dependencies
├── README.md                           # Getting started
└── CHANGELOG.md                        # Version history
```

---

## Module Responsibilities

| **Module** | **Owns** | **Key Files** |
|------------|----------|---------------|
| **docs/help-articles/** | Content library (baseball articles) | `*.md` files, frontmatter |
| **scripts/content/** | Content deployment logic | `load_articles.py`, validators |
| **scripts/linear/** | Linear API integration | Sync scripts, issue creation |
| **scripts/orchestration/** | External system coordination | Build triggers, migration runners |
| **.swarms/** | Multi-agent coordination | YAML configs, session state |
| **tools/scripts/** | Canonical execution interface | Wrapper scripts |
| **config/** | Configuration management | Environment templates, schemas |

---

## What Linear-Bootstrap Owns vs Coordinates

### Owns (Lives in This Repo)

✅ **Content Library**
- 189 baseball articles (markdown files)
- Article metadata and frontmatter
- Content validation logic
- Article upload scripts

✅ **Linear Integration**
- Linear API client code
- Issue sync logic
- Epic/task creation scripts

✅ **Swarm Coordination**
- Swarm YAML configurations
- Agent context templates
- Session management

✅ **Deployment Orchestration**
- Deployment wrapper scripts
- Environment configuration
- Manifest generation

### Coordinates (Lives Elsewhere)

❌ **iOS App** (`../../ios-app/`)
- We trigger builds via `scripts/orchestration/trigger_ios_build.sh`
- We don't contain the Swift code

❌ **Supabase Database** (`../../supabase/`)
- We deploy content TO Supabase
- We trigger migrations via `scripts/orchestration/apply_migration.sh`
- We don't contain the SQL migrations

❌ **Quiver Platform** (`../../clients/quiver/`)
- We may coordinate Quiver deployments
- We don't contain the Python platform code

---

## Dependency Rules

### What Can Import What

```
tools/scripts/          # Can call anything (wrapper layer)
    ↓
scripts/                # Can use config/, can't use docs/
    ↓
config/                 # Pure data, no imports
```

```
.swarms/                # Can reference anything (coordination layer)
    ↙     ↓     ↘
scripts/  docs/  tools/
```

**Key Rules:**
- ✅ `tools/scripts/` can call `scripts/*`
- ✅ `scripts/` can import `config/`
- ✅ `.swarms/` can reference any path (it's coordination)
- ❌ `docs/` should never be imported (it's documentation)
- ❌ `config/` should never import anything (it's pure data)

---

## Content System Architecture

### Article Structure

```
docs/help-articles/baseball/{category}/{NN-slug}.md
```

**Example:**
```
docs/help-articles/baseball/mental/01-pre-pitch-routine.md
```

**Frontmatter Format:**
```yaml
---
id: pre-pitch-routine
title: "Pre-pitch Routine: Consistency Under Pressure"
category: "mental"
subcategory: "performance"
tags: ["pitcher", "mental-performance", "routine"]
author: "PT Performance Medical Team"
reviewed_by: "Sports Medicine Specialist"
last_updated: "2025-12-20"
reading_time: "5 min"
difficulty: "intermediate"
---
```

### Content Deployment Flow

```
1. Create/edit article markdown → docs/help-articles/baseball/{category}/
2. Validate frontmatter        → tools/scripts/validate.sh articles
3. Upload to Supabase           → tools/scripts/deploy.sh content
4. Verify deployment            → Check deployment_manifest.json
```

**Upload Script:**
```bash
# Main upload script
python3 scripts/content/load_articles.py

# Or via wrapper
tools/scripts/deploy.sh content
```

---

## Linear Integration Architecture

### Linear Sync Flow

```
1. Fetch Linear issues     → scripts/linear/sync_issues.py
2. Map to local structure  → Create/update local tracking
3. Create epics/tasks      → scripts/linear/create_epic.py
4. Update status           → scripts/linear/update_status.py
```

**Sync Command:**
```bash
# Via wrapper
tools/scripts/sync.sh linear

# Or directly
python3 scripts/linear/sync_issues.py
```

---

## Swarm Coordination System

### Swarm Execution Flow

```
1. Define swarm config        → .swarms/configs/{category}/{name}.yaml
2. Validate config            → .swarms/bin/validate.sh
3. Execute swarm              → /swarm-it .swarms/configs/{path}
4. Monitor session            → .swarms/sessions/{session-id}/
5. Archive on completion      → .swarms/bin/archive.sh {session-id}
```

### Swarm Config Structure

**Location:** `.swarms/configs/{category}/{name}.yaml`

**Example:** `.swarms/configs/content/baseball-articles.yaml`

```yaml
name: Baseball Content Creation
description: Create 100 baseball articles in parallel

agents:
  - id: 1
    name: Mental Performance Agent
    track: content
    articles: [...]
    deliverables: [...]

  - id: 2
    name: Training Agent
    track: content
    articles: [...]
    deliverables: [...]

coordination:
  - Use docs/architecture/repo-map.md for orientation
  - Deploy via tools/scripts/deploy.sh content
  - Report outcomes to .outcomes/
```

---

## Canonical Execution Commands

**All external-facing commands route through `tools/scripts/`**

### Deployment Commands

```bash
# Deploy content articles to Supabase
tools/scripts/deploy.sh content

# Trigger iOS build (coordinates with ../../ios-app/)
tools/scripts/deploy.sh ios

# Apply Supabase migration (coordinates with ../../supabase/)
tools/scripts/deploy.sh migration
```

### Sync Commands

```bash
# Sync with Linear
tools/scripts/sync.sh linear

# Sync content manifest
tools/scripts/sync.sh manifest
```

### Validation Commands

```bash
# Validate article frontmatter
tools/scripts/validate.sh articles

# Validate swarm configs
tools/scripts/validate.sh swarms

# Validate environment config
tools/scripts/validate.sh env
```

### Test Commands

```bash
# Quick tests (< 30s)
tools/scripts/test.sh --quick

# Full test suite
tools/scripts/test.sh --full

# Specific test category
tools/scripts/test.sh content
tools/scripts/test.sh linear
```

---

## Configuration Management

### Environment Variables

**Template:** `.env.template`
**Active:** `.env` (gitignored)

**Required Variables:**
```bash
# Supabase
SUPABASE_URL=https://{project}.supabase.co
SUPABASE_KEY={anon-key}
SUPABASE_SERVICE_ROLE_KEY={service-role-key}

# Linear
LINEAR_API_KEY={your-api-key}
LINEAR_TEAM_ID={team-id}

# Optional
ENVIRONMENT=dev|staging|prod
```

### Config Files

| **File** | **Purpose** | **Format** |
|----------|-------------|------------|
| `.env` | Environment variables | KEY=value |
| `config/linear/project-config.json` | Linear project mapping | JSON |
| `config/content/article-schema.json` | Article validation schema | JSON Schema |
| `deployment_manifest.json` | Deployment tracking | JSON |

---

## Module Boundaries (Collision Map)

### For 100-Agent Parallelism

**Zero Collision (fully parallel):**
- Different article categories
  - Agent 1: `docs/help-articles/baseball/mental/`
  - Agent 2: `docs/help-articles/baseball/hitting/`
  - Agent 3: `docs/help-articles/baseball/recovery/`
  - **Can run 10+ agents in parallel** (one per category)

**Low Collision (coordinate timestamps):**
- Same category, different articles
  - Agent 1: `mental/01-pre-pitch-routine.md`
  - Agent 2: `mental/02-visualization.md`
  - **Can run 20+ agents per category**

**Medium Collision (coordinate edits):**
- Swarm configs (use unique names)
- Scripts (different files)
- Config files (use separate env files)

**High Collision (serialize):**
- `deployment_manifest.json` (coordinate updates)
- `.env` (use env-specific files)
- `README.md` (coordinate major edits)

### Ownership Map

| **Path** | **Owner** | **Can Modify Without Asking** |
|----------|-----------|-------------------------------|
| `docs/help-articles/baseball/*/` | Content team | Markdown files (create/edit) |
| `scripts/content/` | Backend team | Deployment logic |
| `scripts/linear/` | Integration team | Linear API calls |
| `.swarms/configs/` | Orchestration team | Swarm definitions |
| `tools/scripts/` | DevOps team | Wrapper scripts |

---

## Getting Started (New Agent Rehydration)

### For Agents Joining Mid-Session

**Read in this order:**

1. **This file** (`docs/architecture/repo-map.md`) ← You are here
2. `docs/architecture/overview.md` - What linear-bootstrap does
3. `docs/runbooks/index.md` - Runbook navigation
4. Task-specific runbook:
   - Content work → `docs/runbooks/content.md`
   - Linear sync → `docs/runbooks/linear-sync.md`
   - Swarms → `docs/runbooks/swarms.md`

**Then:**
```bash
# Verify environment
tools/scripts/bootstrap.sh

# Validate setup
tools/scripts/validate.sh env
```

### For Fresh Starts

```bash
# 1. Clone repository (if needed)
cd /Users/expo/Code/expo/clients/linear-bootstrap

# 2. Copy environment template
cp .env.template .env

# 3. Edit .env with your credentials
vim .env

# 4. Bootstrap environment
tools/scripts/bootstrap.sh

# 5. Validate
tools/scripts/validate.sh env

# 6. Run quick tests
tools/scripts/test.sh --quick
```

---

## Common Tasks

### Deploy New Articles

```bash
# 1. Create markdown files in appropriate category
vim docs/help-articles/baseball/mental/24-new-article.md

# 2. Validate frontmatter
tools/scripts/validate.sh articles

# 3. Deploy to Supabase
tools/scripts/deploy.sh content

# 4. Verify
cat deployment_manifest.json
```

### Create Linear Epic

```bash
# 1. Define epic details
python3 scripts/linear/create_epic.py \
  --title "Build 74 - New Feature" \
  --description "Feature description"

# 2. Sync to get ID
tools/scripts/sync.sh linear

# 3. Verify in Linear web app
```

### Run Content Creation Swarm

```bash
# 1. Create or update swarm config
vim .swarms/configs/content/my-swarm.yaml

# 2. Validate
.swarms/bin/validate.sh my-swarm.yaml

# 3. Execute
/swarm-it .swarms/configs/content/my-swarm.yaml

# 4. Monitor session
ls -la .swarms/sessions/

# 5. Archive when complete
.swarms/bin/archive.sh {session-id}
```

---

## Troubleshooting

### "Content deployment failed"

**Check:**
1. `.env` has correct `SUPABASE_URL` and `SUPABASE_KEY`
2. Articles have valid frontmatter (run `tools/scripts/validate.sh articles`)
3. Network access to Supabase

**See:** `docs/runbooks/troubleshooting.md#content-deployment`

### "Linear sync not working"

**Check:**
1. `.env` has `LINEAR_API_KEY` and `LINEAR_TEAM_ID`
2. API key has correct permissions
3. Network access to Linear API

**See:** `docs/runbooks/troubleshooting.md#linear-sync`

### "Swarm config validation fails"

**Check:**
1. YAML syntax is valid
2. All referenced paths exist
3. Agent IDs are unique

**Run:**
```bash
.swarms/bin/validate.sh {config-path}
```

---

## Metrics

**Current State (2025-12-20):**
- Articles deployed: 189
- Article categories: 10
- Swarm configs: ~30
- Active Linear epics: 15+
- Average deployment time: < 2 minutes

---

## Next Steps

### For New Contributors

1. Read this repo-map
2. Run `tools/scripts/bootstrap.sh`
3. Read `docs/runbooks/index.md`
4. Pick a task from ownership map
5. Follow task-specific runbook

### For Agents

1. **Orient:** Read this file
2. **Understand:** Read task-specific runbook
3. **Execute:** Use `tools/scripts/` only
4. **Report:** Create outcome in `.outcomes/`

---

**End of Repository Map**

*This is the single source of truth for linear-bootstrap. Keep it updated.*
