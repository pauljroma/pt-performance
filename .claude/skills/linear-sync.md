# Sync Linear Issues

Keep Linear issues updated with implementation status from commits and PRs.

## Trigger

```
/linear-sync
```

**Examples:**
- `/linear-sync` - Sync all recent activity
- `/linear-sync ACP-123` - Sync specific issue
- `/linear-sync --status` - Show sync status only

## Prerequisites

1. Linear MCP tools configured (see `.claude/preload.md`)
2. Git repository with Linear issue references in commits
3. Valid Linear API access

## Commit Reference Format

Linear issues should be referenced in commits:

```
feat(sessions): add session completion flow [ACP-107]

- Added Complete Session button
- Created SessionSummaryView
- Implemented metrics calculation

Closes ACP-107
```

## Execution Steps

### Phase 1: Scan Recent Commits

```bash
# Get commits from last 7 days with Linear references
git log --since="7 days ago" --oneline | grep -E 'ACP-[0-9]+'

# Extract issue IDs
git log --since="7 days ago" --oneline | \
  grep -oE 'ACP-[0-9]+' | \
  sort -u
```

### Phase 2: Fetch Current Issue Status

For each referenced issue, use Linear MCP tools:

```
Call linear_get_issue with parameters:
- issue_id: "ACP-107"
```

Capture:
- Current status
- Assignee
- Labels
- Description

### Phase 3: Analyze Implementation Status

For each issue, check codebase:

```bash
# Find related files
git log --name-only --grep="ACP-107" --since="7 days ago" | \
  grep -v "^$" | \
  grep -v "^commit" | \
  sort -u

# Check if tests exist
find . -name "*test*" -o -name "*spec*" | \
  xargs grep -l "session completion" 2>/dev/null

# Check build status
grep -r "ACP-107" . --include="*.md" | head -5
```

### Phase 4: Update Linear Issue

Use Linear MCP tools to update:

```
Call linear_update_issue with parameters:
- issue_id: "ACP-107"
- status: "In Review" (if PR exists) or "Done" (if merged)
- comment: "Implementation complete in build 88"
```

Add implementation notes as comment:

```
Call linear_add_comment with parameters:
- issue_id: "ACP-107"
- body: |
    ## Implementation Summary

    **Build:** 88
    **Status:** Merged to main

    ### Files Changed
    - Views/SessionSummaryView.swift
    - ViewModels/SessionViewModel.swift
    - Services/SessionService.swift

    ### Commits
    - feat(sessions): add session completion flow
    - fix(sessions): correct volume calculation

    ### Testing
    - Unit tests: 12 added
    - Manual testing: Verified on TestFlight
```

### Phase 5: Link PRs (if applicable)

If PR exists for the issue:

```
Call linear_attach_link with parameters:
- issue_id: "ACP-107"
- url: "https://github.com/org/repo/pull/45"
- title: "PR #45: Session Completion Feature"
```

### Phase 6: Generate Sync Report

```markdown
# Linear Sync Report

**Date:** 2025-01-30
**Commits Scanned:** 23
**Issues Updated:** 5

## Updated Issues

| Issue | Previous Status | New Status | Action |
|-------|-----------------|------------|--------|
| ACP-107 | In Progress | Done | Marked complete |
| ACP-108 | Todo | In Progress | Added implementation notes |
| ACP-109 | In Progress | In Review | PR linked |
| ACP-110 | In Progress | In Progress | Added comment |
| ACP-111 | Todo | In Progress | Assigned |

## Issues Missing References

The following commits don't reference Linear issues:
- "fix typo in readme"
- "update dependencies"

Consider adding Linear references for traceability.

## Recommendations

1. ACP-112 has stale "In Progress" status (no commits in 14 days)
2. ACP-115 is blocked - requires design review
```

## Output

```
Linear Sync Complete

Scanned: 23 commits (last 7 days)
Issues Found: 8 unique

Updates Applied:
- ACP-107: In Progress → Done
- ACP-108: Added implementation comment
- ACP-109: Linked PR #45

No Updates Needed:
- ACP-110: Already up to date
- ACP-111: No related commits

Warnings:
- ACP-112: Stale (no activity 14 days)

Next: Review stale issues in Linear
```

## Automated Sync (Future)

For continuous sync, add to git hooks:

```bash
# .git/hooks/post-commit

#!/bin/bash

# Extract Linear issue from commit message
ISSUE=$(git log -1 --pretty=%B | grep -oE 'ACP-[0-9]+' | head -1)

if [ -n "$ISSUE" ]; then
    echo "Syncing $ISSUE to Linear..."
    # Call linear-sync for specific issue
fi
```

Or use GitHub Actions:

```yaml
# .github/workflows/linear-sync.yml

name: Linear Sync
on:
  push:
    branches: [main]

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Sync Linear
        env:
          LINEAR_API_KEY: ${{ secrets.LINEAR_API_KEY }}
        run: |
          # Extract issues from commit
          # Update Linear via API
```

## Reference

See also:
- `.claude/commands/sync-linear.md` - Fetch plan from Linear
- `.claude/preload.md` - Linear MCP configuration
- Linear API docs: https://developers.linear.app/docs
