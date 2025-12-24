# Linear-Bootstrap Architecture Rollout Plan

**Created:** 2025-12-20
**Purpose:** Step-by-step plan to implement agent-optimized repo architecture
**Timeline:** 4 weeks (zero disruption, incremental)
**Goal:** Enable 100-agent parallelism with < 10-second orientation time

---

## Overview

We've created **7 critical files** that transform linear-bootstrap into an agent-optimized orchestration client:

1. `docs/architecture/repo-map.md` - THE MAP (where everything is)
2. `docs/architecture/boundaries.md` - Collision map for parallelism
3. `docs/runbooks/index.md` - Runbook navigation hub
4. `docs/runbooks/content.md` - Content deployment guide
5. `tools/scripts/deploy.sh` - Canonical deployment interface
6. `tools/scripts/validate.sh` - Canonical validation interface
7. `.swarms/README.md` - Swarm coordination guide

**Plus:**
- `docs/index.md` - Main documentation hub

---

## Current Status

✅ **Created (Ready to Review):**
- All 7 critical files exist
- Documented current state accurately
- Defined module boundaries
- Created canonical execution interfaces

❌ **Not Yet Created:**
- Some referenced scripts (bootstrap.sh, sync.sh, etc.)
- Some runbooks (setup.md, linear-sync.md, etc.)
- Orchestration scripts in `scripts/orchestration/`
- Validation Python scripts

---

## 4-Week Rollout Timeline

### Week 1: Documentation Foundation ✅ (IN PROGRESS)

**Goal:** Make repo-map.md the single source of truth

**Tasks:**
- [x] Create `docs/architecture/repo-map.md`
- [x] Create `docs/architecture/boundaries.md`
- [x] Create `docs/runbooks/index.md`
- [x] Create `docs/runbooks/content.md`
- [x] Create `docs/index.md`
- [x] Create `.swarms/README.md`
- [ ] Move existing `.claude/` runbooks to `docs/runbooks/` with redirects
- [ ] Update all swarm configs to reference repo-map.md

**Validation:**
```bash
# Agent should answer these in < 10 seconds:
- "Where do I deploy content?" → repo-map.md → deploy.sh content
- "Where are the articles?" → repo-map.md → docs/help-articles/baseball/
- "How do I run tests?" → repo-map.md → (coming in week 2)
```

**Time:** 5-10 hours

---

### Week 2: Canonical Interfaces

**Goal:** Create `tools/scripts/` as universal entry point

**Tasks:**
- [x] Create `tools/scripts/deploy.sh` (wrapper)
- [x] Create `tools/scripts/validate.sh` (wrapper)
- [ ] Create `tools/scripts/test.sh` (wrapper)
- [ ] Create `tools/scripts/sync.sh` (wrapper)
- [ ] Create `tools/scripts/bootstrap.sh` (setup automation)
- [ ] Move existing `scripts/content/load_articles.py` (already exists, just document)
- [ ] Create `scripts/orchestration/` directory
- [ ] Create `scripts/orchestration/trigger_ios_build.sh`
- [ ] Create `scripts/orchestration/apply_migration.sh`
- [ ] Create `scripts/orchestration/deploy_to_testflight.sh`

**Validation:**
```bash
# All operations use canonical wrappers
tools/scripts/deploy.sh content           # Works
tools/scripts/validate.sh articles        # Works
tools/scripts/test.sh --quick             # Works
tools/scripts/sync.sh linear              # Works
```

**Time:** 8-12 hours

---

### Week 3: Module Boundaries & Organization

**Goal:** Clean boundaries for parallel work

**Tasks:**
- [ ] Create `tools/python/` directory
- [ ] Move validation logic to `tools/python/validate_articles.py`
- [ ] Create `scripts/linear/sync_issues.py`
- [ ] Create `scripts/linear/create_epic.py`
- [ ] Create `scripts/linear/update_status.py`
- [ ] Update `.swarms/` directory structure
  - [ ] Organize configs by category (content/, ios/, infrastructure/)
  - [ ] Create `.swarms/context/COMMANDER.md`
  - [ ] Create `.swarms/context/WORKER.md`
  - [ ] Create `.swarms/bin/rehydrate.sh`
  - [ ] Create `.swarms/bin/validate.sh`
  - [ ] Create `.swarms/bin/archive.sh`
- [ ] Update all swarm configs to use new structure
- [ ] Create `config/` directory
  - [ ] `config/environments/{dev,staging,prod}.env.template`
  - [ ] `config/linear/project-config.json`
  - [ ] `config/content/article-schema.json`

**Validation:**
```bash
# Boundaries clear
cat docs/architecture/boundaries.md   # Shows collision map
ls .swarms/configs/content/            # Organized by category
ls .swarms/configs/ios/                # Organized by category
```

**Time:** 10-15 hours

---

### Week 4: Swarm Optimization & Testing

**Goal:** Enable real 100-agent parallelism

**Tasks:**
- [ ] Test with real swarm execution
  - [ ] Pick `.swarms/configs/CONTENT_100_BASEBALL_ARTICLES.yaml`
  - [ ] Update to reference repo-map.md
  - [ ] Add rehydration docs section
  - [ ] Execute and measure orientation time
- [ ] Create remaining runbooks
  - [ ] `docs/runbooks/setup.md`
  - [ ] `docs/runbooks/linear-sync.md`
  - [ ] `docs/runbooks/swarms.md`
  - [ ] `docs/runbooks/validation.md`
  - [ ] `docs/runbooks/troubleshooting.md`
- [ ] Create Architecture Decision Records (ADRs)
  - [ ] `docs/architecture/decisions/001-canonical-wrappers.md`
  - [ ] `docs/architecture/decisions/002-swarm-coordination.md`
  - [ ] `docs/architecture/decisions/003-content-system-jsonb.md`
- [ ] Update `.outcomes/` organization
  - [ ] Create `.outcomes/README.md`
  - [ ] Organize by date: `.outcomes/2025-12/`
  - [ ] Create outcome templates: `.outcomes/templates/`

**Validation:**
```bash
# 100-agent test
/swarm-it .swarms/configs/content/test-parallelism.yaml

# Measure:
# - Orientation time (target: < 10 seconds)
# - Collision rate (target: < 5%)
# - Success rate (target: > 95%)
```

**Time:** 10-15 hours

---

## Immediate Next Steps (Today)

### Step 1: Review Created Files (30 min)

**Review these files for accuracy:**
1. `docs/architecture/repo-map.md`
2. `docs/architecture/boundaries.md`
3. `docs/runbooks/index.md`
4. `docs/runbooks/content.md`
5. `tools/scripts/deploy.sh`
6. `tools/scripts/validate.sh`
7. `.swarms/README.md`
8. `docs/index.md`

**Check:**
- [ ] Paths are correct for your actual structure
- [ ] Commands match existing scripts
- [ ] Categories match your content library
- [ ] Swarm examples are accurate

### Step 2: Test Canonical Wrappers (15 min)

```bash
# Make scripts executable (if not already)
chmod +x tools/scripts/deploy.sh
chmod +x tools/scripts/validate.sh

# Test deploy wrapper
tools/scripts/deploy.sh content

# Test validate wrapper
tools/scripts/validate.sh env
```

**Expected:**
- deploy.sh should run `scripts/content/load_articles.py`
- validate.sh should check .env exists

### Step 3: Update One Swarm Config (15 min)

**Pick:** `.swarms/CONTENT_100_BASEBALL_ARTICLES.yaml` (or any active config)

**Add rehydration section:**
```yaml
rehydration:
  - Read docs/architecture/repo-map.md for orientation
  - Read docs/runbooks/content.md for deployment process
  - Deploy via tools/scripts/deploy.sh content
  - Validate via tools/scripts/validate.sh articles
```

### Step 4: Test Agent Rehydration (10 min)

**Spawn fresh agent and give ONLY this:**
```
Task: Deploy the mental performance articles to Supabase

Context:
1. Read docs/architecture/repo-map.md
2. Read docs/runbooks/content.md
3. Execute deployment
```

**Measure:**
- How many grep/search steps? (target: < 3)
- How long to find correct command? (target: < 10 seconds)
- Did they use canonical wrapper? (target: yes)

---

## Migration Checklist

### Documentation Migration

- [ ] Move `.claude/CONTENT_UPLOAD_RUNBOOK.md` → `docs/runbooks/content.md` ✅ (already done - new version created)
- [ ] Move `.claude/LINEAR_RUNBOOK.md` → `docs/runbooks/linear-sync.md`
- [ ] Move `.claude/BUILD_RUNBOOK.md` → `docs/runbooks/build.md`
- [ ] Move `.claude/QC_RUNBOOK.md` → `docs/runbooks/validation.md`
- [ ] Create redirects in `.claude/` files pointing to new locations

### Script Migration

- [ ] Keep `scripts/content/load_articles.py` (already in right place)
- [ ] Move standalone deployment scripts to `scripts/orchestration/`
- [ ] Create wrappers in `tools/scripts/` for everything
- [ ] Update all references in docs

### Swarm Config Migration

- [ ] Create `.swarms/configs/content/` directory
- [ ] Move content-related swarms there
- [ ] Create `.swarms/configs/ios/` directory
- [ ] Move iOS-related swarms there
- [ ] Create `.swarms/configs/infrastructure/` directory
- [ ] Update all swarm configs with rehydration docs

---

## Validation Criteria

### Success Metrics

**Orientation Time:**
- Fresh agent can find deployment command in < 10 seconds ✅
- Fresh agent understands module boundaries in < 5 minutes
- Fresh agent knows what's safe to modify in < 3 minutes

**Parallelism:**
- Can assign 10 agents to different categories with zero coordination
- Can assign 100 agents with minimal collision (< 5% conflict rate)
- Commander can generate collision-free assignments automatically

**Execution:**
- All operations use canonical wrappers (100%)
- No invented commands (0% command guessing)
- Outcomes documented (100% task completion → outcome report)

---

## Testing Plan

### Test 1: Fresh Agent Orientation

**Setup:**
- Clear agent context
- Provide only: "Task: Deploy content. Read docs/architecture/repo-map.md"

**Measure:**
- Time to find deployment command
- Number of search/grep operations
- Whether canonical wrapper was used

**Target:**
- < 10 seconds
- < 3 searches
- 100% wrapper usage

---

### Test 2: Parallel Content Creation

**Setup:**
- 10 agents assigned to different article categories
- Monitor for collisions

**Measure:**
- Collision rate (file conflicts)
- Coordination overhead (cross-agent communication)
- Success rate (articles created and deployed)

**Target:**
- 0% collision rate
- 0 coordination messages needed
- 100% success rate

---

### Test 3: Swarm Execution

**Setup:**
- Execute `.swarms/configs/content/baseball-articles.yaml`
- Include rehydration docs

**Measure:**
- Agent confusion rate (stuck/thrashing)
- Command invention rate (non-canonical commands)
- Outcome reporting rate

**Target:**
- 0% confusion
- 0% command invention
- 100% outcome reports

---

## Risks & Mitigations

### Risk 1: Docs Get Out of Sync

**Mitigation:**
- Update repo-map.md when ANY file moves
- Date-stamp all documentation
- Include "last updated" in all runbooks
- Create ADR for major changes

### Risk 2: Scripts Don't Match Docs

**Mitigation:**
- Test all commands in runbooks before publishing
- Use automation to validate script existence
- Create CI check for broken links in docs

### Risk 3: Swarms Reference Old Paths

**Mitigation:**
- Validate all swarm configs: `.swarms/bin/validate.sh`
- Update swarms incrementally (not all at once)
- Keep old paths working temporarily with symlinks

### Risk 4: Agents Still Thrash

**Mitigation:**
- Measure thrash rate (searches per task)
- Identify missing docs and create them
- Update repo-map.md to answer new questions
- A/B test fresh agents weekly

---

## Rollback Plan

**If this doesn't work:**

1. **Old docs still exist** - Keep `.claude/` runbooks as fallback
2. **Scripts backward compatible** - Canonical wrappers call existing scripts
3. **Swarm configs still work** - Update configs incrementally, not all at once
4. **Can revert one week at a time** - Each week is independent

**Rollback command:**
```bash
# Restore old structure (if needed)
git revert <commit-hash>
```

---

## Success Indicators

**You'll know this is working when:**

- ✅ Agents stop grep thrashing (< 3 searches per task)
- ✅ Commander can assign 100 agents without collision calculation
- ✅ New contributors onboard in < 15 minutes
- ✅ Swarm configs execute without agent confusion
- ✅ Outcome reports consistently reference canonical paths
- ✅ No one asks "where is X?" anymore (they check repo-map.md)

---

## Long-Term Maintenance

### Monthly

- [ ] Review repo-map.md for accuracy
- [ ] Update boundaries.md with new modules
- [ ] Archive old .outcomes/ to keep it manageable
- [ ] Validate all swarm configs still work

### Quarterly

- [ ] Measure agent orientation time (should stay < 10s)
- [ ] Review collision map (should enable 100+ agents)
- [ ] Update ADRs for major decisions
- [ ] Collect feedback from agents/humans

### Annually

- [ ] Major architecture review
- [ ] Reorganize if structure no longer serves
- [ ] Update this rollout plan for next iteration

---

## Budget

**Time Investment:**

| **Week** | **Tasks** | **Time** |
|----------|-----------|----------|
| Week 1 | Documentation foundation | 5-10 hours |
| Week 2 | Canonical interfaces | 8-12 hours |
| Week 3 | Module boundaries | 10-15 hours |
| Week 4 | Swarm optimization | 10-15 hours |
| **Total** | **Full implementation** | **33-52 hours** |

**Return on Investment:**

- **Before:** 10-30 minutes per agent to orient
- **After:** < 10 seconds per agent to orient
- **Savings:** ~99% reduction in orientation time
- **Enables:** 100-agent parallelism (10x increase in velocity)

---

## Next Action

**Right now (5 minutes):**

1. Read this rollout plan
2. Review the 8 created files
3. Pick ONE to adjust/improve
4. Test ONE canonical wrapper
5. Update ONE swarm config with rehydration docs

**Then (tomorrow):**

1. Complete Week 1 tasks (move runbooks, update swarms)
2. Test with real agent
3. Measure orientation time
4. Decide: proceed to Week 2 or iterate on Week 1

**Week by week:**

- Execute one week's tasks at a time
- Test before moving to next week
- Iterate if needed
- Document learnings in `.outcomes/`

---

**Let's transform linear-bootstrap into an agent-optimized powerhouse!** 🚀

*Created: 2025-12-20*
*Owner: You*
*Status: Ready to execute*
