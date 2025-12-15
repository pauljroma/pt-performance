# Backlog: Recreate Sapphire Scientist Skill

**Created:** 2025-12-15
**Priority:** MEDIUM
**Effort:** HIGH
**Value:** MEDIUM
**Status:** 🔴 NOT STARTED

---

## Context

The **Sapphire Scientist skill** was completely lost during the Sapphire v3.8 → v3.23 regression recovery. All Python source code is gone, with only compiled bytecode (`__pycache__`) and log files remaining.

### What Was Lost

**Sapphire Scientist** - An optional enhancement providing:
- Enhanced conversational capabilities for scientific queries
- Additional domain-specific intelligence
- Chainlit integration for improved UI/UX
- World-class scientific reasoning capabilities

### Evidence of Loss

```
Location: /Users/expo/Code/expo/clients/quiver/.claude/skills/sapphire_scientist/
Status: Only __pycache__/ directory remains
Source Code: Completely deleted (0 .py files)
Git History: References exist but no source code committed
Backups: Not found in any backups or archives
```

**What Still Exists:**
- Compiled Python files in `__pycache__/`
- Log files: `sapphire_scientist.log`, `sapphire_scientist.error.log`
- Documentation: `SAPPHIRE_DRUG_SCIENTIST_REVIEW_v1.0.md` (in archive)
- Git commit messages: `d9680cd1`, `ea84cfba`, etc.
- Integration code in `app_sapphire_v3.py` (lines 519-536)

---

## Current System Behavior

**Warning Displayed:**
```
⚠️  Sapphire Scientist skill failed to load: No module named 'sapphire_scientist.chainlit_integration'
Continuing with standard Sapphire system prompt...
```

**Impact:**
- ✅ System continues to work normally
- ✅ All 60 tools function correctly
- ✅ 82% test pass rate maintained
- ⚠️ Missing enhanced scientific reasoning
- ⚠️ Missing Chainlit integration features

**Severity:** LOW (Non-critical, graceful fallback)

---

## Requirements

### Functional Requirements

1. **Enhanced System Prompt**
   - Provide world-class scientific reasoning
   - Include domain-specific knowledge
   - Integrate with Sapphire's metagraph
   - Support drug discovery workflows

2. **Chainlit Integration**
   - Module: `sapphire_scientist.chainlit_integration`
   - Function: `load_sapphire_scientist()`
   - Returns: Object with `get_system_prompt()` and `get_context_summary()`

3. **Seamless Integration**
   - Load during Sapphire startup
   - Graceful fallback if unavailable
   - No impact on core tool functionality
   - Logging support

### Technical Requirements

**Module Structure:**
```
sapphire_scientist/
├── __init__.py
├── chainlit_integration.py  # Main integration module
├── prompts.py               # Scientific reasoning prompts
├── knowledge_base.py        # Domain-specific knowledge
└── utils.py                 # Helper functions
```

**API Requirements:**
```python
# Expected interface (from app_sapphire_v3.py)
from sapphire_scientist.chainlit_integration import load_sapphire_scientist

sapphire_scientist = load_sapphire_scientist()
context_summary = sapphire_scientist.get_context_summary()
system_prompt = sapphire_scientist.get_system_prompt()
```

---

## Implementation Plan

### Phase 1: Research & Documentation Review (2-4 hours)

**Tasks:**
1. Extract documentation from archive
   - Find `SAPPHIRE_DRUG_SCIENTIST_REVIEW_v1.0.md`
   - Review any other related docs
   - Document original requirements

2. Analyze integration code
   - Review `app_sapphire_v3.py` lines 519-536
   - Understand expected interface
   - Document integration points

3. Review git history
   - Check commits: `d9680cd1`, `ea84cfba`
   - Extract any remaining context
   - Document timeline of skill development

4. Analyze log files
   - Review `sapphire_scientist.log`
   - Review `sapphire_scientist.error.log`
   - Understand usage patterns

**Deliverables:**
- [ ] Requirements document
- [ ] API specification
- [ ] Original feature list

### Phase 2: Core Module Development (4-6 hours)

**Tasks:**
1. Create module structure
   ```bash
   mkdir -p /Users/expo/Code/expo/clients/quiver/.claude/skills/sapphire_scientist
   ```

2. Implement `chainlit_integration.py`
   - `load_sapphire_scientist()` function
   - SapphireScientist class
   - `get_system_prompt()` method
   - `get_context_summary()` method

3. Develop scientific reasoning prompts
   - Drug discovery workflows
   - Target validation reasoning
   - Mechanism of action analysis
   - Safety prediction logic

4. Integrate with Sapphire's knowledge base
   - PGVector embeddings
   - Neo4j graph data
   - Master tables (drug, gene, pathway)

**Deliverables:**
- [ ] Working Python modules
- [ ] Unit tests
- [ ] Integration tests

### Phase 3: Testing & Validation (2-3 hours)

**Tasks:**
1. Unit testing
   - Test module imports
   - Test API functions
   - Test prompt generation

2. Integration testing
   - Test with Sapphire v3.23
   - Verify startup sequence
   - Validate tool interactions

3. Comparison testing
   - Compare with baseline prompts
   - Validate scientific accuracy
   - Test fallback behavior

**Deliverables:**
- [ ] Test suite
- [ ] Performance benchmarks
- [ ] Validation report

### Phase 4: Documentation & Deployment (1-2 hours)

**Tasks:**
1. Create user documentation
   - Installation guide
   - Configuration options
   - Usage examples

2. Create developer documentation
   - API reference
   - Architecture overview
   - Extension guide

3. Deploy and monitor
   - Install in production
   - Monitor logs
   - Collect feedback

**Deliverables:**
- [ ] User documentation
- [ ] Developer documentation
- [ ] Deployment checklist

---

## Success Criteria

### Must Have ✅
- [ ] Module loads without errors
- [ ] Startup warning disappears
- [ ] `get_system_prompt()` returns enhanced prompt
- [ ] `get_context_summary()` shows skill info
- [ ] Graceful fallback if module fails
- [ ] All existing tests still pass (82%+)

### Nice to Have ⭐
- [ ] Improved scientific reasoning quality
- [ ] Chainlit UI enhancements
- [ ] Knowledge base integration
- [ ] Configurable prompt templates
- [ ] A/B testing capability

---

## Resources Needed

### Documentation
- ✅ `SAPPHIRE_DRUG_SCIENTIST_REVIEW_v1.0.md` (in archive)
- ✅ `app_sapphire_v3.py` integration code
- ✅ Git commit messages
- ✅ Log files

### Code References
- ✅ Sapphire v3.23 codebase
- ✅ Chainlit documentation
- ✅ Similar skills in `.claude/skills/`

### Tools
- ✅ Python 3.11
- ✅ Sapphire development environment
- ✅ Test suite framework

---

## Risks & Mitigation

### Risk 1: Incomplete Documentation
**Risk:** Original requirements not fully documented
**Mitigation:**
- Start with minimal viable implementation
- Iterate based on feedback
- Reference similar skills

### Risk 2: Integration Complexity
**Risk:** Tight coupling with Sapphire internals
**Mitigation:**
- Use loose coupling design
- Test fallback behavior
- Maintain backward compatibility

### Risk 3: Performance Impact
**Risk:** Skill slows down Sapphire startup
**Mitigation:**
- Lazy loading where possible
- Profile and optimize
- Make features optional

---

## Estimated Timeline

**Total Effort:** 9-15 hours

```
Phase 1 (Research):       2-4 hours
Phase 2 (Development):    4-6 hours
Phase 3 (Testing):        2-3 hours
Phase 4 (Documentation):  1-2 hours
```

**Recommended Schedule:**
- Day 1: Phase 1 (Research)
- Day 2: Phase 2 (Development)
- Day 3: Phases 3-4 (Testing & Docs)

---

## Related Backlog Items

**Dependencies:**
- None (independent task)

**Related Items:**
- Manual .env update (HIGH priority)
- Populate missing drug data (HIGH priority)
- Fix query_direct_run schema (MEDIUM priority)

**Would Benefit From:**
- Expanded test coverage
- Better backup strategy for .claude/skills/

---

## Next Actions

**When Starting This Task:**

1. **Preparation:**
   - [ ] Review this backlog document
   - [ ] Extract documentation from archive
   - [ ] Set up development environment

2. **Research Phase:**
   - [ ] Read `SAPPHIRE_DRUG_SCIENTIST_REVIEW_v1.0.md`
   - [ ] Analyze integration code in app_sapphire_v3.py
   - [ ] Review git commit history

3. **Development Phase:**
   - [ ] Create module structure
   - [ ] Implement core functionality
   - [ ] Write tests

4. **Validation:**
   - [ ] Test with Sapphire v3.23
   - [ ] Verify all existing tests pass
   - [ ] Document results

---

## References

**Documentation:**
- Recovery Session: `.outcomes/SAPPHIRE_V323_COMPLETE_RECOVERY_SESSION_2025-12-15.md`
- Handoff Doc: `.outcomes/SAPPHIRE_V323_RECOVERY_HANDOFF_2025-12-15.md`

**Code Locations:**
- Skill Directory: `/Users/expo/Code/expo/clients/quiver/.claude/skills/sapphire_scientist/`
- Integration: `zones/z01_presentation/sapphire/app_sapphire_v3.py:519-536`
- Logs: `/Users/expo/Code/expo/clients/quiver/logs/sapphire_scientist*.log`

**Git Commits:**
- `d9680cd1` - feat(sapphire): Sapphire Scientist v3.24 integration
- `ea84cfba` - feat(sapphire-v3.14): Production deployment
- More references in git log

---

## Priority Justification

**Why MEDIUM Priority:**
- ✅ System works perfectly without it (LOW urgency)
- ⚠️ Enhanced features would improve user experience (MEDIUM value)
- 🔧 Significant effort required to recreate (HIGH effort)

**Priority Calculation:** LOW urgency + MEDIUM value + HIGH effort = **MEDIUM priority**

**When to Prioritize:**
- After HIGH priority items completed (.env, data population)
- When enhanced scientific reasoning is needed
- If user feedback requests it
- During a slow period (low-pressure task)

---

**Status:** 🔴 NOT STARTED
**Last Updated:** 2025-12-15
**Created By:** Claude Sonnet 4.5 (Recovery Session)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
