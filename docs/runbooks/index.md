# Runbooks Index

**Last Updated:** 2025-12-20
**Purpose:** Navigation hub for all operational runbooks

---

## Quick Reference

| **I Need To...** | **Read This Runbook** | **Command** |
|------------------|----------------------|-------------|
| Deploy content articles | [content.md](content.md) | `tools/scripts/deploy.sh content` |
| Sync with Linear | [linear-sync.md](linear-sync.md) | `tools/scripts/sync.sh linear` |
| Run a swarm | [swarms.md](swarms.md) | `/swarm-it .swarms/configs/{path}` |
| Validate content/config | [validation.md](validation.md) | `tools/scripts/validate.sh {target}` |
| Set up environment | [setup.md](setup.md) | `tools/scripts/bootstrap.sh` |
| Fix common issues | [troubleshooting.md](troubleshooting.md) | N/A |

---

## Runbook Catalog

### 1. [Setup & Bootstrap](setup.md)

**When to use:** First-time setup, new agent onboarding

**Covers:**
- Installing dependencies
- Configuring environment variables
- Running bootstrap script
- Verifying installation

**Time:** 10-15 minutes

---

### 2. [Content Deployment](content.md)

**When to use:** Deploying baseball articles to Supabase

**Covers:**
- Creating new articles
- Validating frontmatter
- Uploading to Supabase
- Verifying deployment
- Troubleshooting upload failures

**Time:** 2-5 minutes per deployment

---

### 3. [Linear Sync](linear-sync.md)

**When to use:** Syncing issues, epics, and tasks with Linear

**Covers:**
- Fetching Linear issues
- Creating epics
- Updating task status
- Mapping Linear to local structure

**Time:** 5-10 minutes

---

### 4. [Swarm Execution](swarms.md)

**When to use:** Running multi-agent parallel work

**Covers:**
- Creating swarm configs
- Validating swarm YAML
- Executing swarms
- Monitoring sessions
- Archiving completed swarms

**Time:** Variable (swarm-dependent)

---

### 5. [Validation & Quality Control](validation.md)

**When to use:** Before deploying, during PR review

**Covers:**
- Validating article frontmatter
- Checking YAML syntax
- Verifying environment config
- Running pre-flight checks

**Time:** 1-2 minutes

---

### 6. [Troubleshooting](troubleshooting.md)

**When to use:** When something breaks

**Covers:**
- Content deployment failures
- Linear API errors
- Environment issues
- Swarm execution problems
- Common error messages

**Time:** 5-30 minutes (issue-dependent)

---

## How to Use Runbooks

### For Humans

1. **Find your task** in the Quick Reference table above
2. **Click the runbook link**
3. **Follow step-by-step instructions**
4. **Run the suggested command**

### For Agents

1. **Read repo-map.md first** for orientation
2. **Identify your task type** (content, linear, swarm, etc.)
3. **Read the relevant runbook** in full
4. **Execute via `tools/scripts/` only**
5. **Report outcome to `.outcomes/`**

---

## Runbook Template

When creating new runbooks, follow this structure:

```markdown
# {Runbook Title}

**Purpose:** One sentence describing when to use this
**Time:** Estimated time to complete
**Prerequisites:** What needs to be set up first

---

## Quick Reference

{One-command summary}

---

## Step-by-Step

### Step 1: {Action}

{Detailed instructions}

```bash
{command}
```

**Expected output:**
```
{example output}
```

### Step 2: {Next Action}

...

---

## Verification

How to confirm it worked:
- {Check 1}
- {Check 2}

---

## Troubleshooting

**Problem:** {Common issue}
**Solution:** {How to fix}

---

## See Also

- [{Related runbook}]({file}.md)
```

---

## Runbook Maintenance

**When to update:**
- Command changes
- New features added
- Common troubleshooting pattern emerges
- Agent reports confusion

**How to update:**
1. Edit the specific runbook
2. Update this index if adding/removing runbooks
3. Update last-updated date
4. Test the updated procedure

---

## Contributing

**Adding a new runbook:**

1. Create `docs/runbooks/{name}.md`
2. Follow the template above
3. Add entry to this index
4. Update repo-map.md if it adds new commands

---

## See Also

- [Repository Map](../architecture/repo-map.md) - Where everything lives
- [Architecture Overview](../architecture/overview.md) - System design
- [Module Boundaries](../architecture/boundaries.md) - What can import what

---

**If you're lost, start here:**
1. Read [repo-map.md](../architecture/repo-map.md) first
2. Come back to this index
3. Pick the runbook for your task
