# Agent 3 Phase 2 - Quick Start Guide

## What Was Built

Agent 3 implemented testing infrastructure, observability, and validation layers for the PT Performance Platform backend.

## New Endpoints

### 1. Manual Plan Change Request
```bash
POST /pt-assistant/plan-change-proposal/:patientId

# Example:
curl -X POST http://localhost:4000/pt-assistant/plan-change-proposal/00000000-0000-0000-0000-000000000001 \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "High pain levels detected (7/10) for 2 consecutive sessions",
    "suggested_changes": "Reduce throwing volume by 20%, add extra rest day",
    "severity": "HIGH"
  }'
```

### 2. Protocol Validation
```bash
POST /protocol/validate

# Example:
curl -X POST http://localhost:4000/protocol/validate \
  -H "Content-Type: application/json" \
  -d '{
    "patientId": "00000000-0000-0000-0000-000000000001",
    "recommendation": {
      "type": "increase_velocity",
      "value": 95,
      "context": {
        "currentPain": 2,
        "currentVelocity": 82
      }
    }
  }'
```

### 3. Protocol Summary
```bash
GET /protocol/summary/:patientId

# Example:
curl http://localhost:4000/protocol/summary/00000000-0000-0000-0000-000000000001
```

## Setup

### 1. Install Dependencies
```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap/agent-service
npm install
```

### 2. Deploy Schema
```bash
# Deploy agent_logs table to Supabase
psql $SUPABASE_URL -f ../infra/007_agent_logs_table.sql
```

### 3. Update Server
```bash
# Replace server.js with server-updated.js
mv src/server.js src/server-original.js
mv src/server-updated.js src/server.js
```

### 4. Run Tests
```bash
npm test
```

Expected output:
```
Test Suites: 1 passed, 1 total
Tests:       23 passed, 23 total
```

### 5. Start Service
```bash
npm run dev
```

## File Structure

```
agent-service/
├── src/
│   ├── server.js                        # Main server (updated)
│   ├── routes/
│   │   └── pcr.js                       # Plan Change Request endpoint
│   ├── services/
│   │   └── protocol-validator.js       # Protocol validation logic
│   └── middleware/
│       └── logging.js                   # Logging middleware
├── tests/
│   ├── assistant.test.js                # Test suite (23 tests)
│   └── fixtures/
│       └── demo-patient-data.json       # Test data
└── package.json                         # Updated with Jest

infra/
└── 007_agent_logs_table.sql            # Logging table schema
```

## Key Features

### Logging Middleware
- Automatically logs ALL endpoint requests
- Writes to `agent_logs` table
- Captures: endpoint, method, patient_id, response_time, status_code, errors
- Sanitizes sensitive data (passwords, tokens)

### Protocol Validator
- Queries `protocol_constraints` table
- Validates suggestions against clinical safety rules
- Blocks unsafe recommendations (critical/error violations)
- Returns detailed violation information

### Test Suite
- 23 test scenarios covering:
  - Pain detection (>5, trends, thresholds)
  - Velocity drops (>3 mph, >5 mph)
  - Adherence tracking (<60%)
  - Summary safety (no harmful recommendations)
  - Protocol validation (blocks unsafe, allows safe)
  - Flag computation and prioritization

### PCR Endpoint
- Creates Linear issues for plan changes
- Automatic zone-4b labeling
- Sets state to "In Review"
- Returns issue ID and URL

## Integration with Other Agents

### For Agent 1 (Core Backend)
```javascript
// In your server.js, add:
import { loggingMiddleware } from "./middleware/logging.js";
app.use(loggingMiddleware);
```

### For Agent 2 (Flags)
```javascript
// Before creating auto-PCRs, validate:
import { validateRecommendation } from "./services/protocol-validator.js";

const validation = await validateRecommendation(patientId, recommendation);
if (!validation.isSafe) {
  // Block or warn
}
```

## Testing

### Run All Tests
```bash
npm test
```

### Run with Coverage
```bash
npm run test:coverage
```

### Run in Watch Mode
```bash
npm run test:watch
```

## Monitoring

### Check Agent Logs
```sql
-- Recent endpoint activity
SELECT * FROM agent_logs
ORDER BY created_at DESC
LIMIT 20;

-- Error summary
SELECT * FROM vw_agent_error_summary
WHERE error_date > CURRENT_DATE - 7;

-- Endpoint performance
SELECT * FROM vw_agent_endpoint_performance
ORDER BY request_count DESC;
```

### Get Patient Logs (via API)
```javascript
import { getPatientLogs } from "./middleware/logging.js";
const logs = await getPatientLogs(patientId, 50);
```

### Get Error Summary (via API)
```javascript
import { getErrorSummary } from "./middleware/logging.js";
const summary = await getErrorSummary(24); // last 24 hours
```

## Linear Issues

All Agent 3 Phase 2 issues are now DONE:

- ✅ ACP-90: Implement /plan-change-proposal endpoint
- ✅ ACP-72: Add PT assistant behavior tests
- ✅ ACP-81: Add protocol validation
- ✅ ACP-74: Add logging to endpoints

## Next Steps

1. **Agent 1**: Apply logging middleware to your endpoints
2. **Agent 2**: Integrate protocol validator before auto-PCR creation
3. **All Agents**: Run test suite to ensure compatibility
4. **Phase 3**: Frontend integration and demo preparation

## Troubleshooting

### Tests Failing
```bash
# Make sure you're in the right directory
cd agent-service

# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install
npm test
```

### Logging Not Working
- Check Supabase connection (SUPABASE_URL, SUPABASE_SERVICE_KEY)
- Verify agent_logs table exists: `\dt agent_logs` in psql
- Check logs will still work locally even if Supabase is down (graceful degradation)

### Protocol Validation Errors
- Verify protocol_constraints table has data
- Check patient has an active program with protocol template
- If no protocol assigned, validator returns safe default (allows action)

## Demo Patient

**John Brebbia**
- ID: `00000000-0000-0000-0000-000000000001`
- Program: 8-Week On-Ramp (post-tricep strain)
- Protocol: Tommy John inspired constraints

Test with realistic scenarios from `tests/fixtures/demo-patient-data.json`

## Success Metrics

- ✅ 23/23 tests passing
- ✅ >80% test coverage
- ✅ All endpoints logged to agent_logs
- ✅ Protocol validator blocks unsafe recommendations
- ✅ PCR endpoint creates Linear issues
- ✅ All Linear issues marked Done

---

**Built by:** Agent 3 (Testing & Observability)
**Phase:** Phase 2 - Backend Intelligence
**Date:** 2025-12-06
