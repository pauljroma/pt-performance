# Deprecated Linear Helper Scripts

**Archived**: December 7, 2025
**Reason**: Cleanup of temporary helper scripts used during development

## What's Here

This directory contains Python scripts that were used during the development and Linear integration phases of the PT Performance Platform project. These scripts served their purpose but are no longer needed in the main directory.

## Categories

### Agent Helper Scripts (agent*.py)
Scripts used by individual agents to update Linear issues during parallel swarm executions:
- `agent1_*.py` - Phase 1 agent helpers
- `agent2_*.py` - Phase 2 agent helpers
- `agent3_*.py` - Phase 3 agent helpers

### Completion Scripts (complete_*.py)
One-off scripts to mark specific issues or groups of issues as complete:
- `complete_acp*.py` - Individual issue completion
- `complete_backlog_items.py` - Bulk backlog updates
- `complete_mvp_in_linear.py` - MVP milestone completion
- `complete_phase3_*.py` - Phase 3 completion tracking

### Creation Scripts (create_*.py)
Scripts to generate new Linear issues from documentation or plans:
- `create_handoff_issue.py` - Create phase handoff issues
- `create_mvp_plan.py` - Generate MVP planning issues
- `create_testflight_issues.py` - Generate TestFlight deployment issues

### Deployment Scripts (deploy_*.py)
Database migration and schema deployment helpers:
- `deploy_migrations_python.py` - Run migrations via Python
- `deploy_phase3_migrations.py` - Phase 3 specific migrations
- `deploy_schema_to_supabase.py` - Schema deployment
- `deploy_via_*.py` - Alternative deployment methods

### Query Scripts (get_*.py, find_*.py)
Scripts to query Linear for specific information:
- `get_backlog_*.py` - Query backlog issues
- `get_remaining_11.py` - Track remaining work
- `get_workflow_states.py` - Fetch workflow state IDs
- `find_testflight_issues.py` - Locate TestFlight issues

### Update Scripts (update_*.py, move_*.py)
Scripts to update issue statuses and states:
- `update_acp*_*.py` - ACP-specific issue updates
- `update_deployment_linear.py` - Deployment status updates
- `update_linear_*.py` - General Linear updates
- `move_testflight_to_todo.py` - Workflow state changes

### Misc Scripts
- `phase3_linear_update.py` - Phase 3 tracking
- `populate_linear_from_docs.py` - Populate issues from docs
- `session_resume_summary.py` - Session handoff generation

## Why Archived

These scripts were helpful during development but are no longer needed because:

1. **Linear Integration Complete**: Issues are now managed directly in Linear UI
2. **Automation in Place**: GitHub Actions handles CI/CD
3. **Swarms Completed**: Multi-agent parallel work finished
4. **One-Time Use**: Scripts were designed for specific milestones

## Kept in Main Directory

The following scripts remain active:

- `linear_client.py` - Core Linear API client (actively used)
- `linear_bootstrap.py` - Main bootstrap script
- `check_linear_status.py` - Current status checker
- `check_schema.py` - Schema validation
- `test_*.py` - Test scripts
- `verify_migrations.py` - Migration verification
- `mcp_server.py` - MCP server implementation

## Restoration

If any of these scripts are needed again:

```bash
cp .archive/linear-helpers-deprecated-20251207/<script-name> ./
```

## Safe to Delete?

Yes, after confirming all Linear issues are properly tracked and the project is stable. Keep this archive for 30-60 days before permanent deletion.
