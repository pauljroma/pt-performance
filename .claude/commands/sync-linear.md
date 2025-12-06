# Sync Linear Plan

Fetch the latest project plan from Linear and load it into context.

## What this does:

1. Connects to Linear API
2. Fetches the current project: **MVP 1 — PT App & Agent Pilot**
3. Gets all issues with their current status
4. Displays the plan in readable markdown format

## Instructions:

Use the `linear_get_plan` MCP tool to fetch the latest plan:

```
Call linear_get_plan with parameters:
- team_name: "Agent-Control-Plane"
- project_name: "MVP 1 — PT App & Agent Pilot"
- format: "markdown"
```

After fetching, analyze the plan and:
1. Identify which issues are in progress vs backlog
2. Check for any blockers or dependencies
3. Suggest the next issue to work on based on priority and labels

**Important:** Always check Linear at the start of a new session to get the latest status.
