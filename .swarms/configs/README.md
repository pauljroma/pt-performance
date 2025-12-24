# Swarm Configs

**Purpose:** Organized swarm coordination configs by category

---

## Directory Structure

```
.swarms/configs/
├── README.md              # This file
├── content/               # Content creation/deployment swarms
├── ios/                   # iOS build/release swarms
└── infrastructure/        # Infrastructure/architecture swarms
```

---

## Config Categories

### content/

**Purpose:** Content creation, deployment, and management swarms

**Examples:**
- Baseball articles creation
- Help content deployment
- Video metadata sync
- Multi-category content generation

**Typical structure:**
- Agent per content category
- Parallel content generation
- Validation and deployment phases

---

### ios/

**Purpose:** iOS build, test, and release coordination swarms

**Examples:**
- Feature implementation across iOS app
- UI/UX improvements
- Build and TestFlight deployment
- Integration testing

**Typical structure:**
- Agent per feature/component
- Sequential build phases
- Testing and validation

---

### infrastructure/

**Purpose:** Repository infrastructure, architecture, and tooling swarms

**Examples:**
- Architecture rollouts
- Repo structure changes
- Documentation updates
- Tool creation

**Typical structure:**
- Agent per infrastructure component
- Systematic rollout phases
- Validation and verification

**Current configs:**
- `ARCHITECTURE_ROLLOUT.yaml` - 16-agent architecture implementation

---

## Config File Format

All swarm configs use YAML format:

```yaml
name: "Swarm Name"
description: "What this swarm does"
created: "2025-12-23"
estimated_duration: "4-6 hours"
estimated_cost: "$50-$75"

enforcement:
  pre_flight_required: true
  component_registration_required: true
  zone_boundaries_enforced: true

agents:
  - id: 1
    name: "Agent Name"
    role: "What this agent does"
    track: "category|infrastructure|content"
    dependencies: []
    deliverables:
      - Deliverable 1
      - Deliverable 2
    success_criteria:
      - Criteria 1
      - Criteria 2
```

**Required fields:**
- `name` - Short swarm name
- `description` - What the swarm accomplishes
- `agents` - List of agent specs

**Recommended fields:**
- `estimated_duration` - Time estimate
- `estimated_cost` - Cost estimate
- `enforcement` - Enforcement flags
- `phases` - Logical grouping of agents

---

## Creating New Configs

### 1. Choose Category

- **Content?** → `content/`
- **iOS?** → `ios/`
- **Infrastructure?** → `infrastructure/`

### 2. Name Convention

Format: `CATEGORY_PURPOSE.yaml`

**Examples:**
- `content/BASEBALL_ARTICLES_Q1.yaml`
- `ios/BUILD_75_FEATURES.yaml`
- `infrastructure/TESTING_FRAMEWORK.yaml`

### 3. Use Template

```yaml
name: "Your Swarm Name"
description: "Brief description"
created: "YYYY-MM-DD"

agents:
  - id: 1
    name: "First Agent"
    deliverables:
      - Task 1
      - Task 2

  - id: 2
    name: "Second Agent"
    deliverables:
      - Task 3
      - Task 4
```

### 4. Validate

```bash
# Validate YAML syntax
tools/scripts/validate.sh swarms

# Or manually
python3 -c "import yaml; yaml.safe_load(open('.swarms/configs/category/FILE.yaml'))"
```

### 5. Execute

```bash
# Via swarm-it skill
/swarm-it .swarms/configs/category/FILE.yaml

# Or directly (if using swarm coordination scripts)
python3 scripts/swarm_coordinator.py --plan .swarms/configs/category/FILE.yaml
```

---

## Config Best Practices

### Agent Organization

**By Track:**
- Group related agents into tracks
- Tracks can run in parallel
- Examples: documentation, scripts, testing

**By Dependencies:**
- Specify dependencies explicitly
- Agent 5 depends on [1, 2, 3]
- Enables parallel execution where safe

**By Phase:**
- Phase 1: Foundation (setup, validation)
- Phase 2: Implementation (core work)
- Phase 3: Verification (testing, validation)
- Phase 4: Completion (cleanup, reporting)

### Deliverables

**Be Specific:**
- ✅ "Create docs/runbooks/setup.md"
- ❌ "Create setup documentation"

**Be Measurable:**
- ✅ "Validate 189 articles"
- ❌ "Validate articles"

**Be Actionable:**
- ✅ "Run tools/scripts/test.sh --full"
- ❌ "Test everything"

### Success Criteria

**Define Done:**
- ✅ "All tests pass"
- ✅ "Documentation updated"
- ✅ "No linting errors"

**Quantify:**
- ✅ "100% article validation"
- ✅ "Code coverage > 80%"

---

## Examples

### Content Swarm Example

```yaml
name: "Baseball Articles - Advanced Training"
description: "Create 20 advanced training articles"
created: "2025-12-20"

agents:
  - id: 1
    name: "Long Toss Articles Agent"
    track: "content"
    deliverables:
      - Create 5 long toss articles
      - Validate frontmatter
      - Deploy to Supabase
```

### iOS Swarm Example

```yaml
name: "Build 75 - Readiness Features"
description: "Implement readiness adjustment UI"
created: "2025-12-21"

agents:
  - id: 1
    name: "Readiness UI Agent"
    track: "ios"
    deliverables:
      - Create ReadinessAdjustmentView.swift
      - Integrate with WHOOP data
      - Add unit tests
```

### Infrastructure Swarm Example

```yaml
name: "Architecture Rollout"
description: "Agent-optimized repo structure"
created: "2025-12-23"

agents:
  - id: 1
    name: "Documentation Agent"
    track: "documentation"
    deliverables:
      - Create repo-map.md
      - Create boundaries.md
      - Migrate runbooks
```

---

## Parallel Execution

Swarms can execute agents in parallel when safe:

**Fully Parallel (Zero Collision):**
- Different content categories
- Independent features
- Separate modules

**Partially Parallel (Low Collision):**
- Same category, different files
- Related but non-overlapping work

**Sequential Only (High Collision):**
- Same file modifications
- Dependent operations
- Shared resources

**See:** [`docs/architecture/boundaries.md`](../../docs/architecture/boundaries.md)

---

## Troubleshooting

### "YAML syntax error"

```bash
# Validate YAML
python3 -c "import yaml; print(yaml.safe_load(open('.swarms/configs/FILE.yaml')))"

# Common issues:
# - Missing quotes around strings with colons
# - Inconsistent indentation (use 2 spaces)
# - Missing space after colon
```

### "Config not found"

```bash
# Check path
ls .swarms/configs/category/

# Use absolute path
/swarm-it /full/path/to/config.yaml
```

### "Agent execution failed"

```bash
# Check agent deliverables
# - Are they specific?
# - Are file paths correct?
# - Are dependencies met?

# Check logs
cat .swarms/sessions/SWARM_ID/agent_N.log
```

---

## See Also

- [Swarm README](../README.md) - Swarm coordination guide
- [Boundaries](../../docs/architecture/boundaries.md) - Collision map for parallel work
- [Repo Map](../../docs/architecture/repo-map.md) - Where files live
