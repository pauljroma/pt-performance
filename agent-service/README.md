# PT Agent Backend Service

Backend service for the PT Performance Platform providing intelligent patient summaries, analytics, and plan change proposals.

## Features

- ✅ Health check endpoint
- ✅ Patient summary with adherence, pain trends, and metrics
- ✅ Today's session lookup
- ✅ PT Assistant text summaries
- ✅ Supabase integration
- 🔜 Plan Change Request generation
- 🔜 Linear integration
- 🔜 Slack notifications

## Quick Start

### Prerequisites

- Node.js 18+
- Supabase project
- Linear API key (optional)

### Installation

```bash
cd agent-service
npm install
```

### Configuration

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

Edit `.env`:
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
LINEAR_API_KEY=your-linear-api-key
```

### Run

```bash
# Development mode (auto-restart)
npm run dev

# Production mode
npm start
```

Server will start on http://localhost:4000

## API Endpoints

### Health Check
```bash
GET /health
```

Returns server status and configuration.

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2025-01-15T10:30:00Z",
  "uptime": 123.45,
  "environment": "development",
  "services": {
    "supabase": "configured",
    "linear": "configured"
  }
}
```

### Patient Summary
```bash
GET /api/patient-summary/:patientId
```

Returns comprehensive patient data including profile, program, logs, pain trends, and adherence.

**Response:**
```json
{
  "patient": {
    "id": "uuid",
    "name": "John Brebbia",
    "sport": "Baseball",
    "position": "Pitcher",
    "dominant_hand": "Right"
  },
  "program": { ... },
  "recent_sessions": [ ... ],
  "pain_trend": [ ... ],
  "adherence_pct": 85.5,
  "bullpen_metrics": [ ... ]
}
```

### Today's Session
```bash
GET /api/today-session/:patientId
```

Returns the current session for a patient.

**Response:**
```json
{
  "program": { "id": "uuid", "name": "8-Week On-Ramp" },
  "phase": { "id": "uuid", "name": "Phase 1", "sequence": 1 },
  "session": {
    "id": "uuid",
    "name": "Day 1 - Foundation",
    "session_exercises": [ ... ]
  }
}
```

### PT Assistant Summary
```bash
GET /api/pt-assistant/summary/:patientId
```

Returns a text summary of patient status for PT review.

**Response:**
```json
{
  "patient_id": "uuid",
  "summary": "**Patient:** John Brebbia (Baseball, Pitcher)\n\n**Adherence:** ✅ 85.0%\n...",
  "generated_at": "2025-01-15T10:30:00Z"
}
```

## Testing

```bash
# Run tests
npm test

# Watch mode
npm run test:watch
```

## Architecture

```
agent-service/
├── src/
│   ├── server.js          # Main Express server
│   ├── routes/            # API routes (future)
│   ├── services/          # Business logic (future)
│   └── utils/             # Helpers (future)
├── tests/                 # Test files
├── config/                # Configuration
├── package.json
├── .env
└── README.md
```

## Zones

This service operates in:
- **zone-3c**: Agent intelligence and PT Assistant
- **zone-8**: Data access (Supabase integration)
- **zone-4b**: Plan Change Requests (future)

## Next Steps

1. ✅ Health endpoint working
2. ✅ Supabase integration
3. ✅ Patient summary endpoint
4. ✅ Today session endpoint
5. ✅ PT Assistant summary
6. 🔜 Plan Change Request creation
7. 🔜 Linear integration for PCRs
8. 🔜 Slack notifications
9. 🔜 Flag computation engine
10. 🔜 Agent action logging

## Related Documentation

- [EPIC_J_PT_ASSISTANT_AGENT_SPEC.md](../docs/epics/EPIC_J_PT_ASSISTANT_AGENT_SPEC.md)
- [RUNBOOK_AGENT_BACKEND.md](../docs/runbooks/RUNBOOK_AGENT_BACKEND.md)
- [LINEAR_MAPPING_GUIDE.md](../docs/LINEAR_MAPPING_GUIDE.md)
