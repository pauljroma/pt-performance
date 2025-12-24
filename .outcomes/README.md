# Outcomes Directory

**Purpose:** Agent work products and session artifacts
**Last Updated:** 2025-12-20

---

## What Are Outcomes?

Outcomes are **deliverable artifacts** created by agents/swarms documenting:
- What was accomplished
- What was learned
- What remains to be done
- Decisions made
- Issues encountered

---

## Organization

```
.outcomes/
├── README.md                    # This file
├── templates/                   # Outcome templates
│   ├── deployment-report.md
│   └── swarm-summary.md
└── 2025-12/                     # Date-organized
    ├── ARCHITECTURE_ROLLOUT_COMPLETE.md
    ├── BUILD_74_DEPLOYMENT.md
    └── BASEBALL_CONTENT_LIBRARY_COMPLETE.md
```

**Date folders:** `YYYY-MM/`

---

## When to Create Outcomes

**Always create outcome when:**
- Swarm completes
- Major deployment finishes
- Architecture change implemented
- Bug investigation concludes
- Sprint/build cycle ends

---

## Outcome Template

**File naming:** `{TOPIC}_{DATE}.md` or just `{TOPIC}.md`

**Structure:**
```markdown
# {Outcome Title}

**Date:** YYYY-MM-DD
**Status:** Complete/In Progress/Blocked
**Agent/Swarm:** {identifier}

---

## Summary

One-paragraph summary of what was accomplished.

## Deliverables

- ✅ Deliverable 1
- ✅ Deliverable 2
- ⏳ Deliverable 3 (in progress)

## Outcomes

What was created/changed:
- Files created: X
- Files modified: Y
- Tests added: Z

## Lessons Learned

- What worked well
- What didn't work
- What to do differently

## Next Steps

1. High priority action
2. Medium priority action
3. Low priority action

---

**End of Outcome**
```

---

## See Also

- [Swarm README](../.swarms/README.md) - Swarm coordination
- [Repo Map](../docs/architecture/repo-map.md) - Where files live
