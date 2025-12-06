# PT Performance App – Complete Project

This repository contains a complete PT/performance app with Linear-driven agent workflow.

## Project Structure

```
clients/linear-bootstrap/
├── docs/                          # Complete project documentation
│   ├── PT_APP_VISION.md          # Vision & scope
│   ├── PT_APP_ARCHITECTURE.md    # System architecture
│   ├── PT_APP_PLAN.md            # Linear task breakdown
│   ├── PT_APP_DATA_MODEL_FROM_XLS.md  # Database model
│   ├── PT_APP_USER_STORIES.md    # User stories
│   ├── PT_APP_SYSTEM_GUIDE.md    # Agent system guide
│   ├── AGENT_GOVERNANCE.md       # Agent rules of engagement
│   └── SLACK_APPROVAL_FLOW.md    # Approval workflow
│
├── infra/                         # Infrastructure & database
│   └── 001_init_supabase.sql     # Complete Supabase schema
│
├── ios-app/PTPerformance/         # SwiftUI mobile app
│   ├── PTPerformanceApp.swift    # App entry point
│   ├── RootView.swift            # Root navigation
│   ├── AuthView.swift            # Authentication
│   ├── PatientTabView.swift      # Patient navigation
│   ├── TodaySessionView.swift    # Today's workout
│   ├── PatientHistoryView.swift  # Patient history
│   ├── TherapistTabView.swift    # Therapist navigation
│   ├── TherapistDashboardView.swift  # Patient dashboard
│   └── TherapistProgramsView.swift   # Program management
│
├── agent-service/                 # PT Agent Backend
│   ├── src/
│   │   └── server.js             # Express server with Linear integration
│   ├── package.json              # Node dependencies
│   └── .env.example              # Environment template
│
└── Linear Integration/            # Existing Linear tools
    ├── linear_client.py          # CLI for Linear operations
    ├── mcp_server.py            # MCP server
    └── .claude/                  # Claude Code integration
        ├── commands/sync-linear.md
        ├── hooks/on-start.sh
        └── preload.md
```

## Quick Start

### 1. Read the Documentation

All agents must start by reading the `/docs` folder:

```bash
# Read these in order:
1. docs/PT_APP_VISION.md
2. docs/PT_APP_ARCHITECTURE.md
3. docs/PT_APP_PLAN.md
4. docs/AGENT_GOVERNANCE.md
5. docs/PT_APP_SYSTEM_GUIDE.md
```

### 2. Sync Linear Plan

```bash
# Using the existing Linear client
python3 linear_client.py export-md

# Or in Claude Code
/sync-linear
```

### 3. Create Linear Issues from Plan

Tell Claude:

> "Read all docs in /docs and translate PT_APP_PLAN.md into Linear issues under the project 'MVP 1 — PT App & Agent Pilot' in the Agent-Control-Plane team, using zone labels and priorities as specified."

### 4. Start Building

Agents should:
1. Pick tasks from their zones (zone-7, zone-8, zone-12, zone-3c, etc.)
2. Follow AGENT_GOVERNANCE.md rules
3. Update Linear with progress
4. Create Plan Change Requests (zone-4b) when needed

## Database Setup

```bash
# 1. Create Supabase project at supabase.com

# 2. Apply schema
psql -h db.your-project.supabase.co \
  -U postgres \
  -d postgres \
  -f infra/001_init_supabase.sql

# Or use Supabase dashboard SQL editor
```

## iOS App Setup

```bash
# 1. Open Xcode
# 2. Create new SwiftUI project named "PTPerformance"
# 3. Copy files from ios-app/PTPerformance/ into project
# 4. Add Supabase Swift SDK via SPM
# 5. Configure Supabase credentials
```

## Agent Service Setup

```bash
cd agent-service

# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env with your Supabase and Linear credentials

# Run server
npm run dev

# Test health endpoint
curl http://localhost:4000/health
```

## Agent Workflow

### Daily Flow

1. **Session Start**
   ```bash
   /sync-linear  # Auto-syncs via hook
   ```

2. **Pick Task**
   - Agent reads Linear plan
   - Filters by zone labels
   - Picks highest priority task in assigned zone

3. **Work**
   - Create feature branch
   - Implement changes
   - Follow definitions of done

4. **Update Linear**
   ```bash
   # Add progress comment
   python3 linear_client.py add-comment \
     --issue-id <id> \
     --comment "Implemented X, Y, Z"

   # Update status
   python3 linear_client.py update-status \
     --issue-id <id> \
     --state-id <done-state-id>
   ```

5. **Commit**
   ```bash
   git commit -m "ACP-XX: Task description"
   ```

### Plan Changes (zone-4b)

When agent needs to change patient program:

1. Create Plan Change Request issue in Linear
2. Set zone-4b label
3. Move to "In Review"
4. Notify Slack (when implemented)
5. Wait for PT approval
6. Apply changes only after approval

## Key Principles

### Linear as Source of Truth
- ALL tasks live in Linear
- Agents MUST sync before starting work
- Agents MUST update Linear with progress
- NO work happens outside Linear tracking

### Zone-Based Routing
- **zone-7/8**: Database & Supabase
- **zone-12**: iOS app
- **zone-3c**: Agent backend
- **zone-4a**: Control plane
- **zone-4b**: Approval flow
- **zone-10b**: Quality/testing
- **zone-13**: Monitoring

### Clinical Safety
- Never override PT decisions
- Never give medical advice
- Always propose changes via zone-4b
- Never auto-increase intensity if pain rising
- Follow pain thresholds strictly

## Testing the System

### Test Linear Integration

```bash
# Export plan
python3 linear_client.py export-md

# List issues
python3 linear_client.py list-issues

# Get workflow states
python3 linear_client.py export-json | jq '.workflow_states'
```

### Test Database

```bash
# Connect to Supabase
psql -h db.your-project.supabase.co -U postgres -d postgres

# Check tables
\dt

# Check views
SELECT * FROM vw_patient_adherence;
SELECT * FROM vw_pain_trend;
```

### Test Agent Service

```bash
# Start service
cd agent-service && npm run dev

# Test endpoints
curl http://localhost:4000/health
curl http://localhost:4000/patient-summary/test-id
```

## Next Steps

1. ✅ **Complete Linear Setup**
   - Create issues from PT_APP_PLAN.md
   - Assign zones and priorities
   - Set up approval workflow

2. ✅ **Apply Database Schema**
   - Run 001_init_supabase.sql
   - Seed demo data
   - Test views

3. ✅ **Build iOS App**
   - Create Xcode project
   - Wire Supabase auth
   - Implement patient flow

4. ✅ **Deploy Agent Service**
   - Configure environment
   - Test Linear integration
   - Implement Slack approval

## Resources

- **Linear Project**: https://linear.app/bb-pt/project/mvp-1-pt-app-and-agent-pilot-d86e35fb091b
- **Supabase Docs**: https://supabase.com/docs
- **Linear API**: https://developers.linear.app/docs
- **SwiftUI Docs**: https://developer.apple.com/documentation/swiftui

## Support

For questions about:
- **Linear integration**: See INTEGRATION_GUIDE.md
- **Agent governance**: See docs/AGENT_GOVERNANCE.md
- **Data model**: See docs/PT_APP_DATA_MODEL_FROM_XLS.md
- **Workflows**: See docs/PT_APP_SYSTEM_GUIDE.md
