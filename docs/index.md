# Linear-Bootstrap Documentation

**Welcome to linear-bootstrap** - A deployment orchestration client for the PT Performance platform.

---

## 🚀 Quick Start

**New here? Start with these in order:**

1. [Repository Map](architecture/repo-map.md) - **Read this first** - Where everything lives
2. [Runbooks Index](runbooks/index.md) - How to do common tasks
3. Pick your task runbook:
   - [Deploy Content](runbooks/content.md)
   - [Run Swarms](../.swarms/README.md)
   - [Setup Environment](runbooks/setup.md)

**Then:**
```bash
# Bootstrap your environment
tools/scripts/bootstrap.sh

# Validate setup
tools/scripts/validate.sh all

# You're ready!
```

---

## 📚 Documentation Structure

```
docs/
├── index.md                    # 👈 YOU ARE HERE (navigation hub)
├── architecture/               # How the system works
│   ├── repo-map.md             # ⭐ THE MAP - where everything is
│   ├── overview.md             # System architecture
│   ├── boundaries.md           # Module dependencies & collision map
│   └── decisions/              # Architecture Decision Records (ADRs)
├── runbooks/                   # How to operate the system
│   ├── index.md                # Runbook navigation
│   ├── content.md              # Deploy articles
│   ├── linear-sync.md          # Sync with Linear
│   ├── swarms.md               # Run multi-agent swarms
│   ├── setup.md                # Environment setup
│   └── troubleshooting.md      # Fix common problems
└── help-articles/              # Content library (189 baseball articles)
```

---

## 🎯 Common Tasks

| **I Want To...** | **Read This** | **Then Run This** |
|------------------|---------------|-------------------|
| **Deploy content articles** | [content.md](runbooks/content.md) | `tools/scripts/deploy.sh content` |
| **Run a swarm** | [.swarms/README.md](../.swarms/README.md) | `/swarm-it .swarms/configs/{file}.yaml` |
| **Sync with Linear** | [linear-sync.md](runbooks/linear-sync.md) | `tools/scripts/sync.sh linear` |
| **Validate before deploy** | [validation.md](runbooks/validation.md) | `tools/scripts/validate.sh all` |
| **Fix something broken** | [troubleshooting.md](runbooks/troubleshooting.md) | See guide |
| **Understand the system** | [overview.md](architecture/overview.md) | N/A |

---

## 🏗️ Architecture

### Core Concepts

**Linear-bootstrap is an orchestration layer.**

**It OWNS:**
- Content library (189 baseball articles)
- Deployment scripts
- Linear integration
- Swarm coordination

**It COORDINATES (but doesn't contain):**
- iOS builds (`../../ios-app/`)
- Supabase migrations (`../../supabase/`)
- Quiver platform (`../../clients/quiver/`)

**Read:** [architecture/overview.md](architecture/overview.md) for full system design

### Key Documents

1. **[repo-map.md](architecture/repo-map.md)** ⭐ **START HERE**
   - The canonical map of where everything lives
   - Quick navigation to all common tasks
   - Directory structure explanation

2. **[boundaries.md](architecture/boundaries.md)**
   - Module dependency rules
   - Collision map for 100-agent parallelism
   - Ownership map (who can modify what)

3. **[overview.md](architecture/overview.md)**
   - System architecture diagram
   - How components interact
   - Design principles

---

## 🔧 Operations

### Runbooks (How-To Guides)

**All runbooks:** [runbooks/index.md](runbooks/index.md)

**Essential runbooks:**

1. **[content.md](runbooks/content.md)** - Deploy articles to Supabase
   - Create/edit markdown files
   - Validate frontmatter
   - Upload to database
   - Troubleshoot failures

2. **[swarms.md](../.swarms/README.md)** - Multi-agent coordination
   - Create swarm configs
   - Execute parallel work
   - Monitor sessions
   - Archive completed swarms

3. **[setup.md](runbooks/setup.md)** - Environment setup
   - Install dependencies
   - Configure .env
   - Bootstrap script
   - Verify installation

4. **[troubleshooting.md](runbooks/troubleshooting.md)** - Fix problems
   - Content deployment failures
   - Environment issues
   - Swarm execution problems
   - Common error messages

---

## 🤖 For Agents

**If you're an AI agent joining this codebase:**

### First-Time Orientation (5 minutes)

1. **Read** [architecture/repo-map.md](architecture/repo-map.md)
   - Understand where everything lives
   - Learn the directory structure
   - Find canonical commands

2. **Read** your task-specific runbook:
   - Content work → [runbooks/content.md](runbooks/content.md)
   - Swarm work → [../.swarms/README.md](../.swarms/README.md)
   - Infrastructure → [runbooks/troubleshooting.md](runbooks/troubleshooting.md)

3. **Run** bootstrap if needed:
   ```bash
   tools/scripts/bootstrap.sh
   ```

### Resuming Work (Rehydration)

**If resuming a previous session:**

1. Read `.swarms/handoffs/{session-id}/handoff.md`
2. Check `.swarms/sessions/{session-id}/state.json`
3. Run `.swarms/bin/rehydrate.sh {session-id}`
4. Continue from last checkpoint

### Execution Principles

**Always:**
- ✅ Use `tools/scripts/` for all operations (deploy, test, validate)
- ✅ Read `boundaries.md` before modifying shared files
- ✅ Create outcome reports in `.outcomes/`
- ✅ Update handoff docs when pausing work

**Never:**
- ❌ Guess where files live (read repo-map.md)
- ❌ Invent command syntax (use canonical wrappers)
- ❌ Modify without checking collision map
- ❌ Skip outcome reporting

---

## 📊 Content Library

**189 baseball performance articles across 10 categories**

### Categories

| **Category** | **Count** | **Topics** |
|--------------|-----------|------------|
| Training | 66 | Periodization, strength, conditioning |
| Arm Care | 24 | Throwing mechanics, UCL health |
| Mental | 23 | Focus, visualization, confidence |
| Recovery | 16 | Sleep, cold therapy, rest protocols |
| Hitting | 10 | Bat speed, launch angle, rotational power |
| Injury Prevention | 10 | ACL, hamstrings, concussion |
| Mobility | 10 | Band work, hip/shoulder mobility |
| Nutrition | 10 | Pre-game meals, hydration |
| Speed | 10 | Sprint mechanics, base stealing |
| Warm-up | 10 | Dynamic stretching, activation |

**Read:** [Content Runbook](runbooks/content.md) for deployment guide

**Browse:** [`docs/help-articles/baseball/`](help-articles/baseball/)

---

## 🔄 Integration Points

### External Systems

**Linear-bootstrap coordinates with:**

1. **iOS App** (`../../ios-app/PTPerformance/`)
   - Trigger builds
   - Deploy to TestFlight
   - Via: `tools/scripts/deploy.sh ios`

2. **Supabase** (`../../supabase/`)
   - Deploy content
   - Apply migrations
   - Via: `tools/scripts/deploy.sh content`

3. **Linear** (API integration)
   - Sync issues/epics
   - Update task status
   - Via: `tools/scripts/sync.sh linear`

**Read:** [repo-map.md#dependency-graph](architecture/repo-map.md#dependency-graph)

---

## 🛠️ Tools & Scripts

**All operations use canonical wrappers in `tools/scripts/`:**

### Deployment

```bash
tools/scripts/deploy.sh content      # Deploy articles
tools/scripts/deploy.sh ios          # Trigger iOS build
tools/scripts/deploy.sh migration    # Apply DB migration
tools/scripts/deploy.sh testflight   # Deploy to TestFlight
```

### Validation

```bash
tools/scripts/validate.sh articles   # Validate articles
tools/scripts/validate.sh swarms     # Validate swarm configs
tools/scripts/validate.sh env        # Validate environment
tools/scripts/validate.sh all        # Run all validations
```

### Sync

```bash
tools/scripts/sync.sh linear         # Sync with Linear
tools/scripts/sync.sh manifest       # Update deployment manifest
```

**Read:** [repo-map.md#canonical-execution-commands](architecture/repo-map.md#canonical-execution-commands)

---

## 📈 Metrics & Status

**Current state (2025-12-20):**
- Articles deployed: 189
- Article categories: 10
- Swarm configs: ~30
- Active Linear epics: 15+
- iOS builds: 73+
- Deployment success rate: 95%+

---

## 🆘 Getting Help

### Documentation Hierarchy

```
Lost? → repo-map.md → Specific runbook → Troubleshooting
```

### Common Issues

| **Problem** | **Solution** |
|-------------|--------------|
| Don't know where to start | Read [repo-map.md](architecture/repo-map.md) |
| Command failed | Read [troubleshooting.md](runbooks/troubleshooting.md) |
| Can't find a file | Check [repo-map.md](architecture/repo-map.md) directory structure |
| Deployment failed | Read [content.md](runbooks/content.md) troubleshooting section |
| Swarm won't execute | Read [.swarms/README.md](../.swarms/README.md) troubleshooting |

### Support Channels

- **Documentation:** Start here (`docs/`)
- **Runbooks:** Step-by-step guides (`docs/runbooks/`)
- **Troubleshooting:** Common issues (`docs/runbooks/troubleshooting.md`)

---

## 🔄 Keeping Docs Updated

**When to update documentation:**

- New feature added → Update relevant runbook + repo-map
- Command changed → Update runbook + troubleshooting
- New module created → Update repo-map + boundaries
- Common error pattern → Add to troubleshooting

**How to update:**

1. Edit the specific document
2. Update last-updated date
3. Test the updated procedure
4. Create outcome report documenting change

---

## 📝 Document Templates

### Creating New Runbook

**Template:** See [runbooks/index.md](runbooks/index.md#runbook-template)

**Location:** `docs/runbooks/{name}.md`

**Remember to:**
1. Add entry to runbook index
2. Update repo-map if it adds new commands
3. Follow the template structure

### Creating New ADR

**Template:** Architecture Decision Record format

**Location:** `docs/architecture/decisions/{NNN-title}.md`

**Format:**
```markdown
# ADR NNN: {Title}

**Status:** Proposed | Accepted | Deprecated
**Date:** YYYY-MM-DD
**Context:** What problem are we solving?
**Decision:** What did we decide?
**Consequences:** What are the trade-offs?
```

---

## 🎯 Success Criteria

**You know linear-bootstrap well when you can:**

- [ ] Find any file in < 10 seconds using repo-map.md
- [ ] Deploy content without reading runbooks
- [ ] Run validation checks before every deployment
- [ ] Create swarm configs for parallel work
- [ ] Troubleshoot common errors independently
- [ ] Resume work from handoff docs
- [ ] Explain module boundaries to new contributors

---

## 🚀 Next Steps

### For New Contributors

1. **Read** [repo-map.md](architecture/repo-map.md) (10 minutes)
2. **Run** `tools/scripts/bootstrap.sh` (5 minutes)
3. **Validate** `tools/scripts/validate.sh all` (2 minutes)
4. **Pick** a task from [runbooks/index.md](runbooks/index.md)
5. **Execute** following the runbook
6. **Report** outcome in `.outcomes/`

### For Agents

1. **Orient** via repo-map.md
2. **Understand** via task-specific runbook
3. **Execute** via `tools/scripts/*`
4. **Report** outcome
5. **Create handoff** if pausing

---

## 🏗️ Repo Philosophy

**Design Principles:**

1. **One obvious place** for each kind of knowledge
2. **Shallow discovery** (top-level answers "how to operate")
3. **Deep implementation** (internals can be complex)
4. **Composable modules** with explicit boundaries
5. **Convention over documentation** (but both when helpful)

**Read:** [architecture/overview.md](architecture/overview.md) for full philosophy

---

**Welcome to linear-bootstrap. Now go build something! 🚀**

*Last updated: 2025-12-20*
