# Linear Integration Context

This project uses **Linear** as the single source of truth for planning and task tracking.

## Quick Reference

**Team:** Agent-Control-Plane (ACP)
**Project:** MVP 1 — PT App & Agent Pilot
**Linear URL:** https://linear.app/bb-pt

## Available Tools

### CLI Tools
```bash
# Export plan as markdown
python3 linear_client.py export-md

# Export plan as JSON
python3 linear_client.py export-json --output plan.json

# List all issues
python3 linear_client.py list-issues

# Update issue status
python3 linear_client.py update-status --issue-id <id> --state-id <state>

# Add comment to issue
python3 linear_client.py add-comment --issue-id <id> --comment "Progress update"
```

### MCP Tools (available in Claude Code)
- `linear_get_plan` - Fetch current project plan
- `linear_list_issues` - List all issues
- `linear_get_issue` - Get issue details
- `linear_update_status` - Update issue status
- `linear_add_comment` - Add comment to issue
- `linear_get_workflow_states` - Get available workflow states

### Slash Command
- `/sync-linear` - Fetch and display latest Linear plan

## Workflow

1. **Session Start**: Plan auto-syncs from Linear → `/tmp/linear_plan_latest.md`
2. **Check Status**: Use `/sync-linear` or `linear_get_plan` to see current state
3. **Pick Task**: Choose an issue from backlog based on labels/priority
4. **Work**: Create feature branch, implement changes
5. **Update Linear**: Use `linear_add_comment` to log progress
6. **Complete**: Use `linear_update_status` to move to "Done"

## Multi-Agent Coordination

All agents should:
- ✅ Check Linear plan at session start
- ✅ Pick issues based on zone labels (zone-3a, zone-7, etc.)
- ✅ Update Linear with progress comments
- ✅ Move issues to appropriate status when complete
- ✅ Reference issue ID in commit messages (e.g., "ACP-5: Implement schema")

## Why Linear?

Linear provides:
- **Persistent state** across sessions
- **Single source of truth** for all agents
- **Human approval** workflow
- **Progress tracking** and audit trail
- **No context loss** from conversation resets
