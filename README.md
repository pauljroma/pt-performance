# Linear-Bootstrap

**Agent-Optimized Content & Integration Hub**

[![Status](https://img.shields.io/badge/status-active-success.svg)]()
[![Architecture](https://img.shields.io/badge/architecture-agent--optimized-blue.svg)]()

---

## Quick Start

**New to this repo?** Read [`docs/architecture/repo-map.md`](docs/architecture/repo-map.md) first (< 10 second orientation)

### First-Time Setup

```bash
# 1. Bootstrap environment
tools/scripts/bootstrap.sh

# 2. Configure .env
# Edit .env with your Supabase credentials

# 3. Validate setup
tools/scripts/validate.sh env

# 4. You're ready!
```

**Detailed setup:** [`docs/runbooks/setup.md`](docs/runbooks/setup.md)

---

## What is Linear-Bootstrap?

Linear-Bootstrap is an **agent-optimized integration hub** for:
- **Content Management**: Baseball training articles, help content, video metadata
- **Linear Integration**: Project management sync with Linear API
- **Deployment Orchestration**: Content deployment to Supabase, iOS build coordination
- **Swarm Coordination**: Multi-agent task execution with collision avoidance

**Design Philosophy**: Enable < 10 second agent orientation, support 100-agent parallelism

---

## Quick Navigation

| **I Want To...** | **Go Here** | **Command** |
|------------------|-------------|-------------|
| Deploy content | `docs/help-articles/` | `tools/scripts/deploy.sh content` |
| Validate articles | `docs/help-articles/` | `tools/scripts/validate.sh articles` |
| Sync with Linear | `scripts/linear/` | `tools/scripts/sync.sh linear` |
| Run a swarm | `.swarms/` | `/swarm-it .swarms/configs/{config}.yaml` |
| Understand architecture | `docs/architecture/` | Read `repo-map.md` |
| Troubleshoot issues | `docs/runbooks/` | Read `troubleshooting.md` |

**Complete navigation:** [`docs/architecture/repo-map.md`](docs/architecture/repo-map.md)

---

## Canonical Commands

All operations use **canonical wrapper scripts** at `tools/scripts/`:

### Deploy
```bash
tools/scripts/deploy.sh content      # Deploy articles to Supabase
tools/scripts/deploy.sh ios          # Coordinate iOS build
tools/scripts/deploy.sh migration    # Apply database migration
tools/scripts/deploy.sh testflight   # Deploy to TestFlight
```

### Validate
```bash
tools/scripts/validate.sh articles   # Validate article structure
tools/scripts/validate.sh swarms     # Validate swarm configs
tools/scripts/validate.sh env        # Check environment setup
tools/scripts/validate.sh all        # Run all validations
```

### Test
```bash
tools/scripts/test.sh --quick        # Fast tests (< 30s)
tools/scripts/test.sh --full         # Full test suite
tools/scripts/test.sh --module NAME  # Test specific module
```

### Sync
```bash
tools/scripts/sync.sh linear         # Sync with Linear API
tools/scripts/sync.sh manifest       # Update deployment manifest
```

**Why canonical wrappers?** See [ADR 001](docs/architecture/decisions/001-canonical-wrappers.md)

---

## Repository Structure

```
linear-bootstrap/
├── docs/                    # All documentation (single source of truth)
│   ├── architecture/        # System design, repo-map, boundaries, ADRs
│   ├── runbooks/           # Step-by-step operational guides
│   └── help-articles/      # Content library (baseball, etc.)
│
├── tools/                   # Canonical execution layer
│   ├── scripts/            # Wrapper scripts (deploy.sh, validate.sh, etc.)
│   └── python/             # Python helper utilities
│
├── scripts/                 # Implementation layer
│   ├── content/            # Content deployment (load_articles.py)
│   ├── orchestration/      # Multi-system coordination
│   └── linear/             # Linear API integration
│
├── .swarms/                 # Swarm coordination (multi-agent orchestration)
│   ├── configs/            # Swarm YAML configs (by category)
│   ├── bin/                # Swarm automation scripts
│   ├── context/            # Context templates for agents
│   └── sessions/           # Active swarm sessions
│
├── config/                  # Configuration files
│   ├── environments/       # Environment-specific configs
│   ├── linear/             # Linear API configuration
│   └── content/            # Content deployment configs
│
└── tests/                   # Test suites
    ├── unit/               # Unit tests
    ├── integration/        # Integration tests
    └── fixtures/           # Test data
```

**Detailed structure:** [`docs/architecture/repo-map.md`](docs/architecture/repo-map.md)

---

## Documentation

### Start Here
- **[Repo Map](docs/architecture/repo-map.md)** - Where everything lives (THE MAP)
- **[Setup Guide](docs/runbooks/setup.md)** - First-time environment setup
- **[Troubleshooting](docs/runbooks/troubleshooting.md)** - Common errors & solutions

### Architecture
- **[Overview](docs/architecture/overview.md)** - System architecture & design principles
- **[Boundaries](docs/architecture/boundaries.md)** - Collision map for parallel work
- **[Decisions](docs/architecture/decisions/)** - Architecture Decision Records (ADRs)

### Runbooks
- **[Content Deployment](docs/runbooks/content.md)** - Deploy articles to Supabase
- **[Linear Sync](docs/runbooks/linear-sync.md)** - Sync with Linear API
- **[Swarm Coordination](docs/runbooks/swarms.md)** - Multi-agent orchestration

### Reference
- **[Documentation Index](docs/index.md)** - Complete documentation catalog
- **[Swarm Guide](.swarms/README.md)** - Swarm system documentation

---

## Common Tasks

### Deploy Content Articles

```bash
# 1. Add/edit articles in docs/help-articles/
# 2. Validate structure
tools/scripts/validate.sh articles

# 3. Deploy to Supabase
tools/scripts/deploy.sh content

# Detailed guide: docs/runbooks/content.md
```

### Sync with Linear

```bash
# Sync issues from Linear API
tools/scripts/sync.sh linear

# Detailed guide: docs/runbooks/linear-sync.md
```

### Run a Swarm

```bash
# Execute multi-agent swarm
/swarm-it .swarms/configs/content/BASEBALL_ARTICLES.yaml

# Detailed guide: .swarms/README.md
```

### Run Tests

```bash
# Quick validation (< 30s)
tools/scripts/test.sh --quick

# Full test suite
tools/scripts/test.sh --full
```

---

## Design Principles

**1. Agent-Optimized Architecture**
- < 10 second orientation time (down from 10-30 minutes)
- Single source of truth for navigation (repo-map.md)
- Canonical wrapper interfaces (no command invention)

**2. 100-Agent Parallelism**
- Collision map defines safe parallel zones
- Module boundaries prevent conflicts
- Organized by collision zones (zero/low/medium/high)

**3. Predictable Structure**
- docs/ - All documentation
- tools/scripts/ - All canonical commands
- scripts/ - All implementation
- .swarms/ - All swarm coordination

**4. Self-Documenting**
- Every module has README
- Every operation has runbook
- Every decision has ADR

**Detailed principles:** [`docs/architecture/overview.md`](docs/architecture/overview.md)

---

## Environment Variables

Required in `.env`:

```bash
# Supabase (required)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Linear (optional - for Linear sync)
LINEAR_API_KEY=your-linear-api-key
LINEAR_TEAM_ID=your-team-id

# Environment
ENVIRONMENT=dev  # dev, staging, production
```

**Setup guide:** [`docs/runbooks/setup.md`](docs/runbooks/setup.md)

---

## Support

### Getting Help

1. **Check documentation first:**
   - Start with [Repo Map](docs/architecture/repo-map.md)
   - Check [Troubleshooting](docs/runbooks/troubleshooting.md)
   - Review relevant [Runbook](docs/runbooks/)

2. **Run validation:**
   ```bash
   tools/scripts/validate.sh all
   ```

3. **Check logs:**
   - Content deployment: `scripts/content/logs/`
   - Swarm sessions: `.swarms/sessions/`
   - Outcomes: `.outcomes/`

### Common Issues

**"Supabase connection failed"**
```bash
# Validate environment
tools/scripts/validate.sh env

# Check .env credentials
cat .env | grep SUPABASE
```

**"Article validation failed"**
```bash
# Check article structure
tools/scripts/validate.sh articles

# See: docs/runbooks/troubleshooting.md
```

**Complete troubleshooting:** [`docs/runbooks/troubleshooting.md`](docs/runbooks/troubleshooting.md)

---

## Contributing

### Architecture Changes

1. Read [Repo Map](docs/architecture/repo-map.md) and [Boundaries](docs/architecture/boundaries.md)
2. Propose change (create ADR in `docs/architecture/decisions/`)
3. Implement change
4. Update documentation
5. Create outcome report in `.outcomes/`

### Adding Content

1. Follow article template in [`docs/runbooks/content.md`](docs/runbooks/content.md)
2. Validate: `tools/scripts/validate.sh articles`
3. Deploy: `tools/scripts/deploy.sh content`

### Adding Features

1. Check [Component Registry](../quiver/COMPONENT_REGISTRY.md) for existing solutions
2. Create swarm config in `.swarms/configs/`
3. Execute: `/swarm-it .swarms/configs/{your-config}.yaml`
4. Document outcome in `.outcomes/`

---

## Architecture Decision Records

Major architectural decisions are documented in `docs/architecture/decisions/`:

- [ADR 001: Canonical Wrapper Scripts](docs/architecture/decisions/001-canonical-wrappers.md)

**Why ADRs?** Track architectural evolution, explain rationale, document alternatives.

---

## Project Status

**Current Version:** Agent-Optimized Architecture v1.0
**Last Updated:** 2025-12-23
**Status:** Active Development

### Recent Changes

See [CHANGELOG.md](CHANGELOG.md)

### Metrics

- **Agent Orientation Time:** < 10 seconds (down from 10-30 minutes)
- **Supported Parallelism:** 100 agents (via collision map)
- **Content Articles:** 189 baseball articles deployed
- **Canonical Commands:** 4 wrapper scripts (deploy, validate, test, sync)

---

## Related Projects

- **[ios-app/PTPerformance](../../../ios-app/PTPerformance/)** - iOS app consuming this content
- **[clients/quiver](../../quiver/)** - Scientific knowledge graph platform (reusable components)
- **[supabase/](../../../supabase/)** - Backend database & migrations

---

## License

Proprietary - Expo's Internal Tooling

---

**Questions?** Start with [`docs/architecture/repo-map.md`](docs/architecture/repo-map.md) - it has all the answers.
