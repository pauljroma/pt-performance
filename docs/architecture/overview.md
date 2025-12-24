# Linear-Bootstrap Architecture Overview

**Last Updated:** 2025-12-20
**Purpose:** High-level system architecture and design principles

---

## What is Linear-Bootstrap?

**Linear-bootstrap is a deployment orchestration client** that coordinates:
- Content deployment (baseball articles → Supabase)
- Build orchestration (iOS builds, migrations)
- Linear project management sync
- Multi-agent swarm coordination

**It is NOT:**
- An iOS application
- A database system
- A data platform

**It IS:**
- A coordination layer
- A deployment orchestrator
- An agent-optimized execution environment

---

## System Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    linear-bootstrap                          │
│              (Deployment Orchestration)                      │
│                                                              │
│  ┌────────────┐  ┌──────────┐  ┌─────────┐  ┌───────────┐ │
│  │   docs/    │  │  tools/  │  │.swarms/ │  │ scripts/  │ │
│  │            │  │          │  │         │  │           │ │
│  │ Architecture│  │ Canonical│  │ Swarm   │  │Deployment │ │
│  │   & Guides  │  │ Wrappers │  │ Configs │  │  Logic    │ │
│  └────────────┘  └──────────┘  └─────────┘  └───────────┘ │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │           content/                                    │  │
│  │     189 Baseball Articles                            │  │
│  │  (10 categories, markdown)                           │  │
│  └──────────────────────────────────────────────────────┘  │
└───────────────────┬──────────────────┬──────────────────────┘
                    │                  │
        ┌───────────▼──────┐  ┌────────▼─────────┐
        │   Coordinates    │  │   Coordinates    │
        │   (doesn't own)  │  │   (doesn't own)  │
        └──────────────────┘  └──────────────────┘
                    │                  │
        ┌───────────▼──────┐  ┌────────▼─────────┐
        │ ../../ios-app/   │  │ ../../supabase/  │
        │  PTPerformance   │  │   Migrations     │
        │  (Swift/iOS)     │  │   (PostgreSQL)   │
        └──────────────────┘  └──────────────────┘
                    │
        ┌───────────▼──────┐
        │ ../../clients/   │
        │     quiver/      │
        │ (Python Platform)│
        └──────────────────┘
```

---

## Design Principles

### 1. One Obvious Place

**Problem:** Agents thrash when there are 6 plausible locations

**Solution:** One canonical location for each kind of knowledge

```
Where do I deploy?       → tools/scripts/deploy.sh
Where are runbooks?      → docs/runbooks/
Where is the map?        → docs/architecture/repo-map.md
Where are swarm configs? → .swarms/configs/
```

### 2. Shallow Discovery, Deep Implementation

**Top-level answers "how to operate"**

```
docs/
  index.md              ← Start here (navigation)
  architecture/
    repo-map.md         ← Find everything (< 10 seconds)
  runbooks/
    content.md          ← Deploy content (step-by-step)
```

**Implementation can be deep:**

```
scripts/content/load_articles.py  ← Complex logic hidden
```

### 3. Composable Modules with Explicit Boundaries

**Enable 100-agent parallelism:**

```
docs/help-articles/
  baseball/
    mental/      ← Agent 1 (zero collision)
    hitting/     ← Agent 2 (zero collision)
    recovery/    ← Agent 3 (zero collision)
```

**See:** `boundaries.md` for collision map

### 4. Convention > Documentation

**Conventions prevent ambiguity:**

```
tools/scripts/*.sh       ← All wrappers here
docs/runbooks/*.md       ← All runbooks here
.swarms/configs/*.yaml   ← All swarm configs here
```

**Agents don't guess locations**

---

## Directory Architecture

### Canonical Interface Layer (`tools/`)

**Purpose:** Universal entry point for all operations

```
tools/
  scripts/
    deploy.sh          ← ONE way to deploy
    validate.sh        ← ONE way to validate
    test.sh            ← ONE way to test
    sync.sh            ← ONE way to sync
```

**Why:** Prevents command invention, enables predictable execution

### Documentation Layer (`docs/`)

**Purpose:** Single source of truth for knowledge

```
docs/
  index.md                    ← Navigation hub
  architecture/
    repo-map.md               ← THE MAP (where everything is)
    boundaries.md             ← Collision map (parallel work)
    overview.md               ← This file (system design)
    decisions/                ← ADRs (why we made choices)
  runbooks/
    index.md                  ← Runbook navigation
    content.md                ← Deploy content
    linear-sync.md            ← Sync with Linear
    setup.md                  ← Environment setup
    troubleshooting.md        ← Fix common issues
```

**Why:** Agents orient in < 10 seconds

### Content Layer (`docs/help-articles/`)

**Purpose:** Data artifacts (not code)

```
docs/help-articles/baseball/
  mental/           ← 23 articles
  training/         ← 66 articles
  arm-care/         ← 24 articles
  [7 more categories]
```

**Why:** Clean separation of data and logic

### Coordination Layer (`.swarms/`)

**Purpose:** Multi-agent orchestration

```
.swarms/
  README.md              ← How to use swarms
  configs/
    content/             ← Content creation swarms
    ios/                 ← iOS build swarms
    infrastructure/      ← Infrastructure swarms
  context/
    COMMANDER.md         ← Commander agent template
    WORKER.md            ← Worker agent template
  bin/
    rehydrate.sh         ← Restore context
    validate.sh          ← Validate configs
```

**Why:** Enables 100-agent parallelism with coordination

### Execution Layer (`scripts/`)

**Purpose:** Implementation logic

```
scripts/
  content/
    load_articles.py   ← Article upload implementation
  linear/
    sync_issues.py     ← Linear API integration
  orchestration/
    trigger_ios_build.sh    ← Coordinate with ios-app
    apply_migration.sh      ← Coordinate with supabase
```

**Why:** Implementation hidden behind canonical wrappers

---

## Data Flow

### Content Deployment Flow

```
1. Human/Agent creates article
   ↓
   docs/help-articles/baseball/{category}/{article}.md

2. Validate frontmatter
   ↓
   tools/scripts/validate.sh articles

3. Deploy via canonical wrapper
   ↓
   tools/scripts/deploy.sh content
   ↓
   scripts/content/load_articles.py
   ↓
   Supabase content_items table

4. Update manifest
   ↓
   deployment_manifest.json
```

### Swarm Execution Flow

```
1. Create swarm config
   ↓
   .swarms/configs/{category}/{name}.yaml

2. Validate config
   ↓
   .swarms/bin/validate.sh

3. Execute swarm
   ↓
   /swarm-it .swarms/configs/{path}
   ↓
   Commander assigns agents
   ↓
   Agents execute in parallel (using boundaries.md)
   ↓
   Outcomes written to .outcomes/

4. Archive session
   ↓
   .swarms/bin/archive.sh {session-id}
```

---

## Module Boundaries

### What Can Import What

```
tools/scripts/           → Can call anything (wrapper layer)
    ↓
scripts/                 → Can import config/
    ↓
config/                  → Pure data (no imports)
```

```
.swarms/                 → Can reference any path (coordination)
    ↙     ↓     ↘
scripts/  docs/  tools/
```

**See:** `boundaries.md` for complete dependency rules

---

## Agent Optimization

### How This Architecture Enables Fast Orientation

**Before:**
```
Agent spawns
→ Greps for "deploy" (30+ results)
→ Greps for "content" (100+ results)
→ Reads 5-6 files trying to understand
→ Invents command syntax
→ Fails, searches more
→ 10-30 minutes wasted
```

**After:**
```
Agent spawns
→ Reads repo-map.md (< 10 seconds)
→ Sees: "Deploy content: tools/scripts/deploy.sh content"
→ Executes canonical wrapper
→ Success
→ < 1 minute total
```

### How This Enables 100-Agent Parallelism

**Collision map in boundaries.md:**

```
Zero Collision:
  docs/help-articles/baseball/mental/    ← Agent 1
  docs/help-articles/baseball/hitting/   ← Agent 2
  docs/help-articles/baseball/recovery/  ← Agent 3
  ... (10 agents in parallel, zero conflicts)
```

**Commander uses collision map to assign safely**

---

## Key Architectural Decisions

**See `docs/architecture/decisions/` for detailed ADRs**

### ADR-001: Canonical Wrappers

**Decision:** All operations use `tools/scripts/` wrappers

**Why:** Prevents command invention, enables predictable execution

**Trade-off:** Extra indirection, but massive reduction in agent confusion

### ADR-002: Swarm Coordination

**Decision:** First-class `.swarms/` directory for multi-agent work

**Why:** Enables 100-agent parallelism with explicit coordination

**Trade-off:** Added complexity, but unlocks parallel velocity

### ADR-003: JSONB Content System

**Decision:** Use JSONB for flexible content storage in Supabase

**Why:** Zero schema changes for new content types

**Trade-off:** Less strict typing, but massive flexibility gains

---

## Technology Stack

**Language:** Mixed (Python, Bash, Swift coordination)

**Content:** Markdown with YAML frontmatter

**Database:** Supabase (PostgreSQL)

**Project Management:** Linear

**Orchestration:** Swarm YAML + custom coordination

---

## Scaling Considerations

### Current Capacity

- Content: 189 articles (can scale to 1000s)
- Agents: Tested to 100 parallel (can scale higher)
- Swarms: 30+ configs (can add unlimited)

### Bottlenecks

1. **Supabase upload speed:** Network limited (~100 articles/minute)
2. **Agent coordination:** Commander CPU bound at ~200 agents
3. **File I/O:** Collision detection limited by filesystem

### Future Improvements

1. Batch inserts for content (10x upload speed)
2. Distributed commander (multi-core assignment)
3. Database-backed collision detection

---

## Security Considerations

### Secrets Management

**❌ Never commit:**
- `.env` files
- API keys
- Supabase service role keys

**✅ Safe to commit:**
- `.env.template` files
- Public Supabase URLs
- Configuration schemas

### Access Control

**Supabase RLS (Row-Level Security):**
- Content: Public read, authenticated write
- User data: User-scoped access only

**Linear API:**
- Personal API keys (user-scoped)
- Rate limited

---

## Monitoring & Observability

### Outcome Tracking

**Every swarm creates outcome report:**
```
.outcomes/
  2025-12/
    ARCHITECTURE_ROLLOUT_COMPLETE.md
```

### Deployment Tracking

**Manifest updated on each deployment:**
```
deployment_manifest.json
{
  "total_articles": 189,
  "last_deployment": "2025-12-20T...",
  "categories": {...}
}
```

---

## Testing Strategy

**Unit tests:** (Future) `tests/unit/`

**Integration tests:** (Future) `tests/integration/`

**Validation:** `tools/scripts/validate.sh all`

**E2E testing:** Manual via runbooks

---

## Success Metrics

**Orientation time:** < 10 seconds (from spawn to command execution)

**Parallelism:** 100 agents with < 5% collision rate

**Command accuracy:** 100% canonical wrapper usage

**Deployment speed:** < 2 minutes for 100 articles

---

## See Also

- [Repository Map](repo-map.md) - Where everything lives
- [Module Boundaries](boundaries.md) - Collision map
- [Runbooks Index](../runbooks/index.md) - How to operate
- [Architecture Decisions](decisions/) - Why we made choices

---

**This architecture optimizes for agent orientation speed and parallel execution capability.**
