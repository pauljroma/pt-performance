# Module Boundaries & Dependency Rules

**Last Updated:** 2025-12-20
**Purpose:** Define what can import what, and where collisions happen for parallel agent work

---

## Dependency Graph

```
┌─────────────────────────────────────────┐
│         tools/scripts/                  │
│      (Wrapper Layer - Can call all)     │
└────────────────┬────────────────────────┘
                 │
        ┌────────┼────────┐
        ▼        ▼        ▼
┌──────────┐ ┌──────────┐ ┌──────────┐
│scripts/  │ │.swarms/  │ │  docs/   │
│content/  │ │ configs/ │ │help-art/ │
│linear/   │ │          │ │          │
│orch/     │ │          │ │          │
└────┬─────┘ └──────────┘ └──────────┘
     │
     ▼
┌──────────┐
│ config/  │
│(Pure data│
└──────────┘
```

---

## Allowed Dependencies

### ✅ Legal Imports

```
tools/scripts/          → Can call anything (wrapper/orchestration layer)
scripts/content/        → Can import config/
scripts/linear/         → Can import config/
scripts/orchestration/  → Can call tools/, scripts/, config/
.swarms/configs/        → Can reference any path (YAML references)
tests/                  → Can import scripts/, config/
```

### ❌ Forbidden Imports

```
config/                 → NEVER imports anything (pure data)
docs/                   → NEVER imported as code (documentation only)
.outcomes/              → NEVER imported (output artifacts only)
docs/help-articles/     → NEVER imported (content data only)
```

---

## Module Responsibilities

### Core Principle

**Each module has ONE responsibility and a clear API surface**

| **Module** | **Responsibility** | **Public API** | **Internal Only** |
|------------|-------------------|----------------|-------------------|
| **tools/scripts/** | Canonical execution interface | `deploy.sh`, `test.sh`, `validate.sh`, `sync.sh` | N/A (thin wrappers) |
| **scripts/content/** | Content deployment | `load_articles.py` | Validation, parsing logic |
| **scripts/linear/** | Linear API integration | `sync_issues.py`, `create_epic.py` | API client internals |
| **scripts/orchestration/** | External system coordination | `trigger_ios_build.sh`, `apply_migration.sh` | Coordination logic |
| **.swarms/** | Multi-agent coordination | Configs, bin scripts | Session state management |
| **config/** | Configuration data | JSON/ENV files | N/A (pure data) |
| **docs/help-articles/** | Content library | Markdown files | N/A (pure content) |

---

## Collision Map (For 100-Agent Parallelism)

### How to Read This Map

- **Zero Collision:** Can assign unlimited agents in parallel
- **Low Collision:** Can assign many agents (10-50) with minimal coordination
- **Medium Collision:** Coordinate assignment (require communication)
- **High Collision:** Serialize work (one agent at a time)

---

### Zero Collision Zones

**Different article categories** ⭐️ **BEST FOR PARALLELISM**

```
Agent 1  → docs/help-articles/baseball/mental/
Agent 2  → docs/help-articles/baseball/hitting/
Agent 3  → docs/help-articles/baseball/recovery/
Agent 4  → docs/help-articles/baseball/training/
Agent 5  → docs/help-articles/baseball/arm-care/
...
Agent 10 → docs/help-articles/baseball/warmup/
```

**Parallelism capacity:** 10 agents (one per category) **with zero coordination**

**Different swarm configs**

```
Agent 1  → .swarms/configs/content/baseball-articles.yaml
Agent 2  → .swarms/configs/ios/build-deploy.yaml
Agent 3  → .swarms/configs/infrastructure/migrations.yaml
```

**Parallelism capacity:** Unlimited (different files)

**Different outcome reports**

```
Agent 1  → .outcomes/2025-12/build-74-deployment.md
Agent 2  → .outcomes/2025-12/content-upload-summary.md
Agent 3  → .outcomes/2025-12/linear-sync-report.md
```

**Parallelism capacity:** Unlimited (different files)

---

### Low Collision Zones

**Same category, different articles**

```
Agent 1  → docs/help-articles/baseball/mental/01-pre-pitch-routine.md
Agent 2  → docs/help-articles/baseball/mental/02-visualization.md
Agent 3  → docs/help-articles/baseball/mental/03-managing-slumps.md
...
Agent 23 → docs/help-articles/baseball/mental/23-mental-recovery.md
```

**Parallelism capacity:** 20-30 agents per category
**Coordination needed:** File naming only (use sequential numbers)

**Different scripts in same directory**

```
Agent 1  → scripts/content/load_articles.py
Agent 2  → scripts/content/validate_frontmatter.py
Agent 3  → scripts/linear/sync_issues.py
```

**Parallelism capacity:** 10-20 agents
**Coordination needed:** Function names, imports

---

### Medium Collision Zones

**Same script, different functions**

```
Agent 1  → scripts/content/load_articles.py::parse_frontmatter()
Agent 2  → scripts/content/load_articles.py::extract_references()
Agent 3  → scripts/content/load_articles.py::upload_to_supabase()
```

**Parallelism capacity:** 3-5 agents per file
**Coordination needed:** Function signatures, shared variables

**Same config directory**

```
Agent 1  → config/environments/dev.env.template
Agent 2  → config/environments/staging.env.template
Agent 3  → config/linear/project-config.json
```

**Parallelism capacity:** 5-10 agents
**Coordination needed:** Cross-file dependencies

**Swarm sessions**

```
Agent 1  → .swarms/sessions/session-001/
Agent 2  → .swarms/sessions/session-002/
```

**Parallelism capacity:** 10+ concurrent swarms
**Coordination needed:** Session ID allocation (use timestamps)

---

### High Collision Zones

**These files MUST be edited serially (one agent at a time)**

❌ **deployment_manifest.json**
- **Why:** Single source of truth for deployed content
- **Solution:** Coordinate updates, regenerate after each deployment

❌ **.env**
- **Why:** Shared configuration
- **Solution:** Use environment-specific files (`dev.env`, `staging.env`)

❌ **README.md**
- **Why:** Documentation hub
- **Solution:** Coordinate major edits, use separate docs for details

❌ **pyproject.toml**
- **Why:** Python dependency lock
- **Solution:** Coordinate dependency additions

---

## Ownership Map

**Who can modify what without asking**

| **Path** | **Team** | **Can Modify Without Coordination** | **Must Coordinate** |
|----------|----------|-------------------------------------|---------------------|
| **docs/help-articles/baseball/*** | Content team | Create/edit markdown files | Category reorganization |
| **scripts/content/** | Backend team | Implementation logic | Public API changes |
| **scripts/linear/** | Integration team | Linear client internals | API contract changes |
| **scripts/orchestration/** | DevOps team | Orchestration scripts | External dependencies |
| **.swarms/configs/** | Everyone | New configs (unique names) | Shared templates |
| **tools/scripts/** | DevOps team | Implementation | Public command interface |
| **config/** | Platform team | Environment-specific | Schema changes |
| **tests/** | QA team | Test cases | Test infrastructure |

---

## Safe Parallel Assignment Rules

### Rule 1: Different Categories = Zero Coordination

```yaml
# Swarm config can assign these in parallel
agents:
  - id: 1
    path: docs/help-articles/baseball/mental/
  - id: 2
    path: docs/help-articles/baseball/hitting/
  - id: 3
    path: docs/help-articles/baseball/recovery/
```

**No communication needed between agents**

### Rule 2: Same Category = Low Coordination

```yaml
# Agents need to coordinate file numbering
agents:
  - id: 1
    files: [mental/01-topic-a.md, mental/02-topic-b.md]
  - id: 2
    files: [mental/03-topic-c.md, mental/04-topic-d.md]
```

**Communication needed:** File number allocation

### Rule 3: Same File = Medium Coordination

```yaml
# Agents need to coordinate function boundaries
agents:
  - id: 1
    function: parse_frontmatter()
    file: scripts/content/load_articles.py
  - id: 2
    function: extract_references()
    file: scripts/content/load_articles.py
```

**Communication needed:** Function signatures, shared imports

### Rule 4: Shared State = High Coordination (Avoid)

```yaml
# AVOID: These agents will conflict
agents:
  - id: 1
    action: update deployment_manifest.json
  - id: 2
    action: update deployment_manifest.json
```

**Solution:** Serialize, or use append-only logs + regenerate

---

## Commander Agent Assignment Strategy

### For 100-Agent Parallelism

**Scenario:** Upload 100 new articles

**Strategy 1: Category-based (Zero collision)**
```
10 agents x 10 articles each = 100 articles
- Agent 1: mental/ (10 articles)
- Agent 2: hitting/ (10 articles)
- Agent 3: recovery/ (10 articles)
...
- Agent 10: warmup/ (10 articles)
```

**Coordination overhead:** Zero
**Time to complete:** Parallel (limited by slowest agent)

**Strategy 2: Article-based (Low collision)**
```
100 agents x 1 article each = 100 articles
- Agent 1: mental/01-*.md
- Agent 2: mental/02-*.md
...
- Agent 100: warmup/10-*.md
```

**Coordination overhead:** File numbering only
**Time to complete:** Fully parallel

---

## Cross-Module Boundaries

### Linear-Bootstrap → External Systems

**Linear-bootstrap coordinates these systems but doesn't contain them:**

| **External System** | **Location** | **How We Interact** | **Boundary** |
|---------------------|--------------|---------------------|--------------|
| **iOS App** | `../../ios-app/` | Trigger builds via `scripts/orchestration/trigger_ios_build.sh` | Read-only file checks, write via scripts |
| **Supabase** | `../../supabase/` | Deploy content, trigger migrations | Deploy content rows, coordinate migrations |
| **Quiver** | `../../clients/quiver/` | (Future) Coordinate deployments | Read-only integration |

**Key Principle:** We orchestrate, we don't own.

---

## Violation Detection

### How to Know You've Violated a Boundary

❌ **Bad:** `config/` imports `scripts/`
```python
# In config/schema.py
from scripts.content.load_articles import parse_frontmatter  # WRONG!
```

❌ **Bad:** `docs/` used as code
```python
# In scripts/deploy.py
import docs.help_articles.baseball.mental.01_routine as routine  # WRONG!
```

❌ **Bad:** Circular dependency
```python
# In scripts/content/load_articles.py
from scripts.linear.sync_issues import get_epic_id  # Maybe...

# In scripts/linear/sync_issues.py
from scripts.content.load_articles import get_article_count  # CIRCULAR!
```

✅ **Good:** Use shared `config/` or break into separate modules

---

## Refactoring Guide

### When Boundaries Get Messy

**Symptom:** Agent thrashes trying to figure out where to put code

**Diagnosis:**
1. Check if module has multiple responsibilities
2. Look for imports that violate the rules
3. Check collision map - is this a high-collision zone?

**Treatment:**
1. **Extract shared code to config/** if it's pure data
2. **Create new script in scripts/** if it's new functionality
3. **Update boundaries.md** to document new module
4. **Update repo-map.md** to show new location

---

## Examples

### Example 1: Adding New Article (Zero Collision)

```bash
# Agent 1
vim docs/help-articles/baseball/mental/24-new-topic.md

# Agent 2 (simultaneous)
vim docs/help-articles/baseball/hitting/11-new-drill.md
```

**Collision risk:** Zero
**Coordination needed:** None

### Example 2: Modifying Upload Script (Medium Collision)

```bash
# Agent 1: Modify validation
vim scripts/content/load_articles.py  # Change validate_frontmatter()

# Agent 2: Modify upload
vim scripts/content/load_articles.py  # Change upload_to_supabase()
```

**Collision risk:** Medium
**Coordination needed:**
- Share function signatures
- Agree on shared variable names
- Merge carefully

### Example 3: Updating Manifest (High Collision)

```bash
# Agent 1
python3 scripts/content/load_articles.py  # Updates manifest

# Agent 2 (should wait!)
python3 scripts/content/load_articles.py  # Updates manifest again
```

**Collision risk:** High
**Solution:** Serialize, or make manifest append-only

---

## Summary Rules

### The 3 Laws of Parallel Agents

1. **Different data = Zero coordination**
   - Different article categories
   - Different config files
   - Different outcome reports

2. **Same data, different files = Low coordination**
   - Same category, different articles
   - Same directory, different scripts

3. **Same file = Medium to High coordination**
   - Coordinate function boundaries
   - Serialize shared state updates

### The Golden Rule

**If you can't answer "can these 2 agents work in parallel?" in 5 seconds, the boundaries need clarification.**

---

**Use this document when:**
- Assigning agents to parallel work
- Designing new modules
- Resolving merge conflicts
- Wondering "can I change this without breaking X?"

**Keep it updated** as modules evolve.
