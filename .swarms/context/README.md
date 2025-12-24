# Swarm Context Templates

**Purpose:** Context templates for swarm agents (Commander & Worker roles)

---

## Templates

### COMMANDER.md

**Role:** Swarm Coordinator
**Use:** Main orchestration agent coordinating multi-agent swarms

**Provides:**
- Swarm planning framework
- Agent coordination patterns
- Collision management strategies
- Error handling procedures
- Outcome reporting templates

**When to use:**
- Starting new swarm execution
- Coordinating multiple worker agents
- Managing complex multi-phase projects
- Validating and reporting outcomes

**How to use:**
1. Copy template to session context
2. Fill in `[PLACEHOLDERS]` with actual values
3. Reference during swarm execution
4. Follow checklists for each phase

---

### WORKER.md

**Role:** Task Executor
**Use:** Individual agent executing specific deliverables

**Provides:**
- Task execution framework
- File creation patterns
- Quality standards
- Completion reporting templates
- Common code patterns

**When to use:**
- Agent assigned specific deliverables
- Implementing features/components
- Creating documentation/scripts
- Following established patterns

**How to use:**
1. Copy template to agent context
2. Fill in agent-specific details
3. Follow execution steps
4. Use patterns as reference
5. Report completion when done

---

## Context Files

**Location:** `.swarms/context/`

**Types:**

### Agent Role Templates
- `COMMANDER.md` - Coordinator role
- `WORKER.md` - Executor role

### Session-Specific Context
- `rehydrated_SESSION_ID.md` - Restored context from previous session
- `custom_SWARM_NAME.md` - Custom context for specific swarm

---

## Creating Custom Context

### For New Swarm Type

```bash
# Create custom context
cat > .swarms/context/CUSTOM_TYPE.md << 'EOF'
# [Swarm Type] Context

**Purpose:** [Specific purpose]

## Key Information
- [INFO_1]
- [INFO_2]

## Execution Steps
1. [STEP_1]
2. [STEP_2]
EOF
```

### For Specific Domain

```bash
# Create domain context (e.g., iOS development)
cat > .swarms/context/IOS_DEVELOPMENT.md << 'EOF'
# iOS Development Context

**Xcode Project:** ios-app/PTPerformance
**Target:** PTPerformance (iOS 16+)

## Common Patterns
- SwiftUI views in Views/
- Services in Services/
- Models in Models/

## Testing
- Unit tests: Tests/Unit/
- Integration tests: Tests/Integration/
EOF
```

---

## Rehydrated Context

**Created by:** `.swarms/bin/rehydrate.sh`

**Contains:**
- Session metadata
- Outcomes from session
- Deliverables list
- Next steps

**Usage:**
```bash
# Rehydrate context from session
.swarms/bin/rehydrate.sh SESSION_ID

# Creates: .swarms/context/rehydrated_SESSION_ID.md
```

---

## Context Variables

### Common Placeholders

Replace these when using templates:

**Swarm-Level:**
- `[SWARM_NAME]` - Name of swarm
- `[SWARM_GOAL]` - High-level goal
- `[SESSION_ID]` - Unique session identifier
- `[DURATION]` - Estimated time
- `[COST]` - Estimated cost
- `[CATEGORY]` - Config category (content, ios, infrastructure)
- `[CONFIG_FILE]` - Config filename

**Agent-Level:**
- `[AGENT_ID]` - Agent number
- `[AGENT_NAME]` - Agent descriptive name
- `[TRACK]` - Agent track (documentation, scripts, etc.)
- `[DELIVERABLE_1..N]` - Specific deliverables
- `[CRITERION_1..N]` - Success criteria
- `[DEPENDENCIES]` - Other agents this depends on

**Project-Level:**
- `[DATE]` - Current date (YYYY-MM-DD)
- `[TIMESTAMP]` - Full timestamp
- `[STATUS]` - Current status (pending, in_progress, completed)

---

## Integration with Swarm Execution

### Commander Flow

1. **Load Context**
   ```bash
   # Read commander template
   cat .swarms/context/COMMANDER.md
   ```

2. **Fill Variables**
   - Replace placeholders with actual values
   - Customize for specific swarm

3. **Execute Phases**
   - Follow phase checklist
   - Coordinate worker agents
   - Validate outputs

4. **Report Outcomes**
   - Use outcome template
   - Create session summary
   - Archive session

### Worker Flow

1. **Receive Assignment**
   - Get deliverables from Commander
   - Understand dependencies

2. **Load Context**
   ```bash
   # Read worker template
   cat .swarms/context/WORKER.md
   ```

3. **Execute Tasks**
   - Follow execution steps
   - Use code patterns
   - Validate work

4. **Report Completion**
   - Use completion template
   - List deliverables
   - Note any issues

---

## Best Practices

### Template Usage

**Do:**
- ✅ Copy template before modifying
- ✅ Fill all placeholders
- ✅ Follow checklists
- ✅ Adapt to specific context
- ✅ Keep original templates intact

**Don't:**
- ❌ Edit original templates
- ❌ Skip placeholder replacement
- ❌ Ignore checklists
- ❌ Deviate without reason

### Context Sharing

**Do:**
- ✅ Share relevant context with agents
- ✅ Provide examples when helpful
- ✅ Link to related documentation
- ✅ Keep context up-to-date

**Don't:**
- ❌ Overload with irrelevant info
- ❌ Assume context is known
- ❌ Use outdated templates
- ❌ Skip context entirely

---

## Examples

### Commander Context for Content Swarm

```markdown
# Commander Agent Context

**Swarm Name:** Baseball Articles - Advanced Training
**Config File:** .swarms/configs/content/BASEBALL_ARTICLES.yaml
**Session ID:** 20251223_baseball_advanced
**Estimated Duration:** 3-4 hours
**Estimated Cost:** $25-$35

### Agents Under Command

Agent 1: Long Toss Articles Agent
  - Deliverables: Create 5 long toss articles
  - Dependencies: []

Agent 2: Velocity Development Agent
  - Deliverables: Create 5 velocity articles
  - Dependencies: []

...
```

### Worker Context for Script Creation

```markdown
# Worker Agent Context

**Agent ID:** 7
**Agent Name:** Python Tools Agent
**Track:** scripts

**Deliverables:**
- [ ] Create tools/python/validate_articles.py
- [ ] Create tools/python/build.sh
- [ ] Create tools/python/test.sh
- [ ] Create tools/python/lint.sh
- [ ] Make all scripts executable

**Dependencies:** None

**Success Criteria:**
- [ ] All scripts created
- [ ] Scripts are executable
- [ ] Validation passes
```

---

## See Also

- [Swarm README](../README.md) - Main swarm documentation
- [Swarm Configs](../configs/README.md) - Config organization
- [Swarm Automation](../bin/README.md) - Automation scripts
- [Repo Map](../../docs/architecture/repo-map.md) - Repository structure
