# Swarm Automation Scripts

**Purpose:** Automation tools for swarm session management

---

## Scripts

### rehydrate.sh

**Purpose:** Restore agent context from completed swarm sessions

**Usage:**
```bash
# Rehydrate specific session
.swarms/bin/rehydrate.sh 20251223_architecture_rollout

# Rehydrate latest session
.swarms/bin/rehydrate.sh latest
```

**What it does:**
1. Loads session metadata from `.swarms/sessions/SESSION_ID/`
2. Extracts outcomes and deliverables
3. Generates context summary file
4. Creates handoff document for continuation

**Outputs:**
- `.swarms/context/rehydrated_SESSION_ID.md` - Full context summary
- `.swarms/handoffs/handoff_SESSION_ID_TIMESTAMP.md` - Handoff document

**Use when:**
- Continuing work after session ends
- Resuming interrupted swarm
- Agent needs prior context
- Creating continuation plan

---

### validate.sh

**Purpose:** Validate swarm configs and sessions

**Usage:**
```bash
# Validate single config
.swarms/bin/validate.sh .swarms/configs/infrastructure/ARCHITECTURE_ROLLOUT.yaml

# Validate all configs and sessions
.swarms/bin/validate.sh all
```

**What it does:**
1. Validates YAML syntax
2. Checks required fields (name, agents, deliverables)
3. Verifies config structure
4. Validates session JSON files

**Validates:**
- YAML syntax correctness
- Required field presence
- Agent structure
- Session metadata

**Use when:**
- Before executing swarm
- After editing config
- Troubleshooting errors
- CI/CD validation

---

### archive.sh

**Purpose:** Archive completed swarm sessions

**Usage:**
```bash
# Archive specific session
.swarms/bin/archive.sh 20251223_architecture_rollout

# Archive all completed sessions
.swarms/bin/archive.sh all

# Archive sessions older than 30 days
.swarms/bin/archive.sh --older-than 30

# List archived sessions
.swarms/bin/archive.sh --list
```

**What it does:**
1. Moves completed sessions from `.swarms/sessions/` to `.swarms/archive/YYYY-MM/`
2. Creates archive metadata
3. Preserves all session files
4. Organizes by month

**Archive structure:**
```
.swarms/archive/
├── 2025-12/
│   ├── 20251223_architecture_rollout/
│   └── 20251220_baseball_content/
└── 2026-01/
    └── 20260115_features/
```

**Use when:**
- Session completed successfully
- Cleaning up active sessions
- Monthly maintenance
- Before major changes

---

## Typical Workflows

### After Swarm Completes

```bash
# 1. Validate session outputs
.swarms/bin/validate.sh all

# 2. Rehydrate context for review
.swarms/bin/rehydrate.sh latest

# 3. Review handoff document
cat .swarms/handoffs/handoff_*.md

# 4. Archive session
.swarms/bin/archive.sh SESSION_ID
```

### Before Starting New Swarm

```bash
# 1. Validate config
.swarms/bin/validate.sh .swarms/configs/category/NEW_SWARM.yaml

# 2. Check for similar past sessions
.swarms/bin/archive.sh --list

# 3. Rehydrate relevant context if continuing work
.swarms/bin/rehydrate.sh RELATED_SESSION_ID
```

### Monthly Maintenance

```bash
# Archive old sessions
.swarms/bin/archive.sh --older-than 30

# Validate all configs
.swarms/bin/validate.sh all

# List archived sessions
.swarms/bin/archive.sh --list
```

---

## Integration with Canonical Wrappers

These scripts are called by canonical wrappers:

```bash
# tools/scripts/validate.sh swarms
# → calls .swarms/bin/validate.sh all

# Future integrations:
# - Automatic rehydration after swarm completion
# - Scheduled archiving via cron
# - Pre-execution validation
```

See: [`docs/architecture/repo-map.md`](../../docs/architecture/repo-map.md)

---

## File Locations

### Generated Files

**Context Files:**
- Location: `.swarms/context/rehydrated_SESSION_ID.md`
- Purpose: Full context summary for continuation
- Format: Markdown with embedded outcomes

**Handoff Documents:**
- Location: `.swarms/handoffs/handoff_SESSION_ID_TIMESTAMP.md`
- Purpose: Next steps and continuation plan
- Format: Markdown with structured sections

**Archive:**
- Location: `.swarms/archive/YYYY-MM/SESSION_ID/`
- Purpose: Long-term storage of completed sessions
- Structure: Organized by month

---

## Advanced Usage

### Custom Rehydration

Modify `rehydrate.sh` to customize context generation:

```bash
# Add custom sections to context file
cat >> "$CONTEXT_FILE" << EOF
### Custom Section
...
EOF
```

### Automated Archiving

Set up monthly archiving via cron:

```bash
# Add to crontab
0 0 1 * * /path/to/.swarms/bin/archive.sh --older-than 30
```

### Pre-Execution Hooks

Validate before every swarm execution:

```bash
# Add to swarm execution script
if ! .swarms/bin/validate.sh "$CONFIG_FILE"; then
    echo "Config validation failed"
    exit 1
fi
```

---

## Troubleshooting

### "Session not found"

```bash
# List available sessions
ls -1 .swarms/sessions/

# Check spelling
.swarms/bin/rehydrate.sh CORRECT_SESSION_ID
```

### "YAML syntax error"

```bash
# Install Python YAML library
pip install pyyaml

# Manually validate
python3 -c "import yaml; yaml.safe_load(open('CONFIG.yaml'))"
```

### "No jq command"

```bash
# Install jq for JSON validation
brew install jq  # macOS
apt-get install jq  # Linux
```

### "Permission denied"

```bash
# Make scripts executable
chmod +x .swarms/bin/*.sh
```

---

## See Also

- [Swarm README](../README.md) - Main swarm documentation
- [Swarm Configs README](../configs/README.md) - Config organization
- [Repo Map](../../docs/architecture/repo-map.md) - Repository structure
