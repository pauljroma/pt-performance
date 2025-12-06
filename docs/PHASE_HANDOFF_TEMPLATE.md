# Phase X Handoff Template

> Use this template when completing each phase to document completion and prep for next phase.

## Phase X: [Phase Name]

**Date Completed:** YYYY-MM-DD
**Estimated Tokens Used:** ~XXX,000
**Linear Issues:** ACP-XX through ACP-XX

---

## ✅ Completed Tasks

List all completed issues from this phase:

- [ ] ACP-XX: Task name
- [ ] ACP-XX: Task name
- [ ] ACP-XX: Task name

---

## 📊 Deliverables

### What Was Built

- **Component 1**
  - Description of what was implemented
  - Key files created/modified
  - Testing performed

- **Component 2**
  - Description
  - Files
  - Testing

### Key Decisions Made

Document any architectural or implementation decisions:

1. **Decision:** Why SwiftUI instead of UIKit
   - **Rationale:** Modern, declarative, better iPad support
   - **Impact:** Faster development, cleaner code

2. **Decision:** [Next decision]
   - **Rationale:**
   - **Impact:**

---

## 🔍 Testing Summary

### Tests Performed

- [ ] Unit tests: XX passing
- [ ] Integration tests: XX passing
- [ ] Manual testing: All flows tested
- [ ] Performance: Acceptable (<XXs response time)

### Known Issues

List any issues discovered but not yet fixed:

1. **Issue:** Description
   - **Severity:** P1/P2/P3
   - **Workaround:** If any
   - **Linear Issue:** ACP-XX

---

## 📚 Documentation Created

- [ ] Code comments added
- [ ] README updated
- [ ] API documentation (if applicable)
- [ ] User-facing docs (if applicable)

**Files:**
- `docs/COMPONENT_NAME.md`
- `README.md` (section X)

---

## 🔗 Dependencies for Next Phase

### Required Before Starting Phase X+1

1. **Supabase Project**
   - URL: https://PROJECT.supabase.co
   - Credentials: Stored in `.env`
   - Tables: List of tables needed

2. **Environment Variables**
   ```bash
   SUPABASE_URL=...
   SUPABASE_ANON_KEY=...
   LINEAR_API_KEY=...
   ```

3. **Demo Data**
   - Demo therapist ID: `xxx-xxx-xxx`
   - Demo patient ID: `xxx-xxx-xxx`
   - Demo program ID: `xxx-xxx-xxx`

### Phase X+1 Prerequisites Checklist

- [ ] All Phase X issues marked "Done" in Linear
- [ ] Database schema applied and tested
- [ ] Environment configured for next phase
- [ ] Demo data seeded and verified
- [ ] No blocking P1 issues remaining

---

## 🚀 Next Phase Preview

**Phase X+1: [Name]**

**Goal:** Brief description of what Phase X+1 will accomplish

**Estimated Issues:** XX tasks

**Key Focus Areas:**
- Area 1
- Area 2
- Area 3

**First Task:** ACP-XX - [Task name]

---

## 📝 Session Notes

### What Went Well

- Item 1
- Item 2

### Challenges Encountered

- Challenge 1
  - How it was resolved

- Challenge 2
  - How it was resolved

### Lessons Learned

- Lesson 1
- Lesson 2

---

## 🔄 Context for Next Session

**To resume work in Phase X+1:**

1. Sync Linear plan:
   ```bash
   /sync-linear
   # or
   python3 linear_client.py export-md
   ```

2. Filter for Phase X+1 issues:
   - In Linear: Apply filter `phase-X+1`
   - Sort by priority (High first)

3. Read relevant docs:
   - `docs/PT_APP_ARCHITECTURE.md`
   - `docs/[COMPONENT]_GUIDE.md`

4. Pick first High priority issue from Phase X+1

5. Create feature branch:
   ```bash
   git checkout -b feature/acp-XX-task-name
   ```

6. Update Linear issue to "In Progress"

---

## 📊 Token Usage Estimate

**Phase X Token Breakdown:**
- Planning & setup: ~10K tokens
- Implementation: ~100K tokens
- Testing & debugging: ~30K tokens
- Documentation: ~10K tokens

**Total: ~150K tokens**

---

## ✨ Sign-off

**Phase X Complete:** ✅

**Ready for Phase X+1:** ✅ / ❌

**Blocker if not ready:** [Description if any]

**Reviewed by:** [Name/Agent]

**Date:** YYYY-MM-DD

---

**Next:** Begin Phase X+1 by reading `.outcomes/PHASE_X+1_HANDOFF.md` (create when Phase X+1 completes)
