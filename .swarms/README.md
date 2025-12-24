# Swarm Coordination System

**Purpose:** Multi-agent coordination for parallel work execution
**Location:** `.swarms/`
**Last Updated:** 2025-12-20

---

## What is This?

The `.swarms/` directory is a **first-class coordination system** for running 10-100 agents in parallel on complex tasks.

**It enables:**
- Parallel content creation (10+ agents creating articles simultaneously)
- Coordinated iOS builds (multiple agents working on different features)
- Infrastructure deployments (agents deploying migrations, content, code in parallel)
- Session persistence (agents can resume from handoffs)

---

## Directory Structure

```
.swarms/
├── README.md                   # 👈 YOU ARE HERE
├── context/                    # Agent rehydration templates
│   ├── COMMANDER.md            # Commander agent context
│   └── WORKER.md               # Worker agent context
├── configs/                    # Swarm YAML configurations
│   ├── content/                # Content creation swarms
│   │   ├── baseball-articles.yaml
│   │   └── video-content.yaml
│   ├── ios/                    # iOS development swarms
│   │   ├── build-deploy.yaml
│   │   └── testflight.yaml
│   └── infrastructure/         # Infrastructure swarms
│       └── migrations.yaml
├── sessions/                   # Active session state
│   └── {session-id}/           # Per-session artifacts
├── handoffs/                   # Session handoff documents
│   └── {session-id}/
└── bin/                        # Automation scripts
    ├── rehydrate.sh            # Restore agent context
    ├── validate.sh             # Validate swarm configs
    └── archive.sh              # Archive completed sessions
```

---

## Quick Start

### Run a Swarm

```bash
# Execute a swarm configuration
/swarm-it .swarms/configs/content/baseball-articles.yaml
```

### Validate a Config

```bash
# Check YAML syntax and structure
.swarms/bin/validate.sh
```

### Resume a Session

```bash
# Restore context from previous session
.swarms/bin/rehydrate.sh {session-id}
```

---

## Swarm Config Format

**Location:** `.swarms/configs/{category}/{name}.yaml`

**Template:**
```yaml
name: Descriptive Swarm Name
description: |
  What this swarm does and why.
  Can be multiple lines.

build_number: CONTENT-001       # Optional build tracking
target_directory: path/to/output/
estimated_duration: 2-4 hours   # Estimate for planning

agents:
  - id: 1
    name: Agent Name
    track: content|ios|infra     # Track identifier
    category: category-name      # For organization
    articles:                    # Or tasks, features, etc.
      - "Task 1 description"
      - "Task 2 description"
      - "Task 3 description"
    deliverables:               # Expected outputs
      - Description of deliverable 1
      - Description of deliverable 2
    research_keywords:          # Optional search terms
      - "keyword 1"
      - "keyword 2"
    estimate_tokens: 500k       # Optional token estimate

  - id: 2
    name: Another Agent
    track: content
    # ... same structure

coordination:                   # How agents should coordinate
  - Use docs/architecture/repo-map.md for orientation
  - Deploy via tools/scripts/deploy.sh
  - Report outcomes to .outcomes/

quality_standards:              # Optional quality gates
  - Minimum 3 citations per article
  - Baseball-specific examples required
  - Grade 9-10 reading level

deliverables:                   # Overall swarm deliverables
  - 100 markdown articles
  - Deployment manifest
  - Test results
```

---

## Agent Types

### Commander Agent

**Role:** Coordinates multiple worker agents

**Responsibilities:**
- Task assignment and load balancing
- Collision detection and prevention
- Progress monitoring
- Outcome aggregation

**Context:** `.swarms/context/COMMANDER.md`

### Worker Agent

**Role:** Executes assigned tasks independently

**Responsibilities:**
- Complete assigned work items
- Report progress to commander
- Handle collisions gracefully
- Create outcomes

**Context:** `.swarms/context/WORKER.md`

---

## Coordination Patterns

### Pattern 1: Zero Collision (Parallel Categories)

**Use case:** Creating articles in different categories

```yaml
agents:
  - id: 1
    category: mental
    articles: [10 articles]

  - id: 2
    category: hitting
    articles: [10 articles]

  - id: 3
    category: recovery
    articles: [10 articles]
```

**Collision risk:** Zero
**Agents can run:** Fully in parallel
**See:** `docs/architecture/boundaries.md#zero-collision-zones`

---

### Pattern 2: Low Collision (Same Category)

**Use case:** Creating many articles in same category

```yaml
agents:
  - id: 1
    category: mental
    articles: [mental/01-*.md, mental/02-*.md]

  - id: 2
    category: mental
    articles: [mental/03-*.md, mental/04-*.md]
```

**Collision risk:** Low (file numbering only)
**Coordination:** Assign sequential number ranges
**See:** `docs/architecture/boundaries.md#low-collision-zones`

---

### Pattern 3: Coordinated Deployment

**Use case:** Build + Test + Deploy pipeline

```yaml
agents:
  - id: 1
    track: build
    deliverables: [Compiled app]

  - id: 2
    track: test
    depends_on: [1]              # Waits for agent 1
    deliverables: [Test results]

  - id: 3
    track: deploy
    depends_on: [1, 2]           # Waits for both
    deliverables: [TestFlight upload]
```

**Collision risk:** Managed via dependencies
**See:** `.swarms/configs/ios/build-deploy.yaml`

---

## Session Management

### Session Lifecycle

```
1. Start swarm      → /swarm-it {config}.yaml
2. Create session   → .swarms/sessions/{id}/
3. Agents execute   → Update session state
4. Create outcomes  → .outcomes/{reports}
5. Archive session  → .swarms/bin/archive.sh {id}
```

### Session Directory

```
.swarms/sessions/{session-id}/
├── config.yaml           # Swarm config snapshot
├── state.json            # Current execution state
├── agent-01.log          # Per-agent logs
├── agent-02.log
└── summary.md            # Session summary
```

### Handoff Documents

**Purpose:** Enable session continuity across time/agents

**Location:** `.swarms/handoffs/{session-id}/handoff.md`

**Contents:**
- What was accomplished
- What remains
- Blockers encountered
- Context for next agent

**When to create:**
- End of day
- Agent handoff
- Context window approaching limit
- Major milestone reached

---

## Best Practices

### Config Organization

✅ **DO:**
- Use descriptive names (`baseball-mental-articles.yaml`)
- Group by category (content/, ios/, infrastructure/)
- Include estimates and deliverables
- Document coordination requirements

❌ **DON'T:**
- Generic names (`swarm1.yaml`, `test.yaml`)
- Mix unrelated tasks in one swarm
- Skip quality standards
- Forget to update after changes

### Agent Assignment

✅ **DO:**
- Assign based on collision map (see `boundaries.md`)
- Give each agent clear deliverables
- Provide rehydration docs (repo-map, runbooks)
- Set realistic token estimates

❌ **DON'T:**
- Assign conflicting paths without coordination
- Create agents without clear outputs
- Assume agents know repo structure
- Underestimate token usage

### Outcome Reporting

✅ **DO:**
- Create outcome reports in `.outcomes/`
- Include session ID in outcome filename
- Document what worked and what didn't
- Link to session artifacts

❌ **DON'T:**
- Skip outcome creation
- Lose session context
- Forget to archive successful patterns
- Leave incomplete sessions without handoffs

---

## Example Swarms

### Example 1: Content Creation (100 Articles)

**Config:** `.swarms/configs/content/baseball-articles.yaml`

**Pattern:** Zero collision (10 agents × 10 categories)

**Execution time:** 2-4 hours

**Deliverable:** 189 articles deployed to Supabase

**Outcome:** `.outcomes/BASEBALL_CONTENT_LIBRARY_COMPLETE.md`

---

### Example 2: iOS Build Pipeline

**Config:** `.swarms/configs/ios/build-deploy.yaml`

**Pattern:** Sequential pipeline (build → test → deploy)

**Execution time:** 30-60 minutes

**Deliverable:** TestFlight upload

**Outcome:** `.outcomes/BUILD_XX_DEPLOYMENT_*.md`

---

### Example 3: Database Migration

**Config:** `.swarms/configs/infrastructure/migrations.yaml`

**Pattern:** Serial execution (one migration at a time)

**Execution time:** 10-20 minutes

**Deliverable:** Applied migrations, schema updated

**Outcome:** `.outcomes/MIGRATION_*.md`

---

## Automation Scripts

### bin/validate.sh

**Purpose:** Validate swarm YAML syntax and structure

**Usage:**
```bash
# Validate all configs
.swarms/bin/validate.sh

# Validate specific config
.swarms/bin/validate.sh configs/content/baseball.yaml
```

**Checks:**
- Valid YAML syntax
- Required fields present
- Referenced paths exist
- No duplicate agent IDs

---

### bin/rehydrate.sh

**Purpose:** Restore agent context from previous session

**Usage:**
```bash
# Resume session by ID
.swarms/bin/rehydrate.sh session-20251220-001

# Resume latest session
.swarms/bin/rehydrate.sh latest
```

**What it does:**
1. Loads session state
2. Reads handoff document
3. Provides context to new agent
4. Updates session tracking

---

### bin/archive.sh

**Purpose:** Archive completed sessions

**Usage:**
```bash
# Archive specific session
.swarms/bin/archive.sh session-20251220-001

# Archive all completed sessions older than 30 days
.swarms/bin/archive.sh --cleanup --days 30
```

**What it does:**
1. Moves session to archive
2. Compresses artifacts
3. Updates index
4. Frees up space

---

## Troubleshooting

### Swarm Won't Start

**Check:**
1. YAML syntax: `.swarms/bin/validate.sh {config}`
2. Paths exist: Referenced files/directories in config
3. Dependencies: Required tools installed

### Agents Colliding

**Check:**
1. `docs/architecture/boundaries.md` for collision zones
2. Swarm config agent assignments
3. File paths for overlap

**Solution:** Reassign to different collision-free zones

### Session Lost Context

**Solution:**
1. Check `.swarms/sessions/{id}/` for artifacts
2. Read latest handoff in `.swarms/handoffs/{id}/`
3. Use `.swarms/bin/rehydrate.sh {id}`

### Agent Can't Find Instructions

**Solution:**
1. Ensure config includes:
   ```yaml
   coordination:
     - Use docs/architecture/repo-map.md for orientation
     - Read docs/runbooks/{relevant}.md
   ```
2. Update context templates in `.swarms/context/`

---

## Metrics

**Current State (2025-12-20):**
- Total swarm configs: ~30
- Successful executions: 15+
- Average agents per swarm: 10
- Largest swarm: 100 agents (content creation)
- Success rate: 95%+

---

## Integration with Linear-Bootstrap

### Swarms Use Linear-Bootstrap Infrastructure

**Deployment:**
```yaml
coordination:
  - Deploy via tools/scripts/deploy.sh content
```

**Validation:**
```yaml
coordination:
  - Validate via tools/scripts/validate.sh articles
```

**Orientation:**
```yaml
coordination:
  - Read docs/architecture/repo-map.md for structure
  - Read docs/runbooks/{task}.md for procedures
```

---

## See Also

- [Repository Map](../docs/architecture/repo-map.md) - Where everything lives
- [Module Boundaries](../docs/architecture/boundaries.md) - Collision map
- [Content Runbook](../docs/runbooks/content.md) - Content deployment
- [Runbooks Index](../docs/runbooks/index.md) - All operational guides

---

**Next Steps:**

1. **Create your first swarm:**
   - Copy existing config from `.swarms/configs/content/`
   - Modify for your task
   - Validate: `.swarms/bin/validate.sh`
   - Execute: `/swarm-it .swarms/configs/your-config.yaml`

2. **Monitor execution:**
   - Check `.swarms/sessions/` for state
   - Read agent logs
   - Track progress

3. **Create outcome:**
   - Document results in `.outcomes/`
   - Link to session ID
   - Archive session when complete

---

**Swarm coordination enables 100-agent parallelism. Use it wisely!**
