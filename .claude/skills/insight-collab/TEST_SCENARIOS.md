# insight-collab Test Scenarios

Test scenarios to verify Claude + OpenAI o1 collaboration works correctly.

---

## Test 1: Proactive Activation (Architecture Decision)

### Scenario
User asks a complex architecture question that should trigger insight-collab automatically.

### Input
```
User: "We need to design a microservices architecture for a real-time
analytics platform that processes 50K events/second across 3 geographic
regions with 99.9% uptime. We have a team of 6 developers and 4 months
to deploy. Should we use Kafka or RabbitMQ for the message queue?
Should we use PostgreSQL or Cassandra for storage? What's the optimal
deployment strategy?"
```

### Expected Behavior
1. Claude analyzes request
2. Claude calculates complexity: 9/10
   - Architecture decision: ✓
   - Multiple tradeoffs: ✓
   - High stakes (uptime SLA): ✓
   - Multiple technology choices: ✓
3. Claude detects complexity ≥ 7 → **auto-triggers insight-collab**
4. Claude calls `consult_o1` tool via openai-reasoning MCP
5. o1 thinks for 30-60 seconds
6. o1 provides detailed reasoning:
   - Kafka vs RabbitMQ analysis
   - PostgreSQL vs Cassandra analysis
   - Recommended architecture
   - Deployment strategy
   - Risk assessment
7. Claude receives o1's response
8. Claude implements recommendations (creates specs, configs, etc.)
9. Claude reports to user with attribution: "Based on o1's analysis..."

### Acceptance Criteria
- ✅ Claude automatically detects high complexity
- ✅ Claude proactively uses insight-collab (no user prompt needed)
- ✅ o1 provides deep reasoning with tradeoffs
- ✅ Claude successfully implements o1's recommendations
- ✅ Cost tracked and reported
- ✅ Total time < 3 minutes (o1 reasoning + Claude execution)

---

## Test 2: Manual Activation (Explicit Request)

### Scenario
User explicitly requests o1 consultation.

### Input
```
User: "Use insight-collab to help me decide between using Redis vs
Memcached for our caching layer. We expect 100K reads/sec and
10K writes/sec."
```

### Expected Behavior
1. Claude recognizes explicit request: "Use insight-collab"
2. Claude calls `consult_o1` tool
3. o1 analyzes Redis vs Memcached:
   - Pros/cons of each
   - Performance comparison
   - Feature differences (persistence, data structures, etc.)
   - Recommended choice with reasoning
4. Claude reports o1's analysis to user

### Acceptance Criteria
- ✅ Claude honors explicit request
- ✅ o1 provides comparison with reasoning
- ✅ Claude presents results clearly

---

## Test 3: Algorithm Optimization

### Scenario
User needs to optimize a slow algorithm.

### Input
```
User: "I have a function that finds all pairs of items with similar
attributes in a dataset of 100K items. Current implementation is O(n²)
and takes 2 hours. How can I optimize this?"
```

### Expected Behavior
1. Claude analyzes: algorithm optimization + performance-critical
2. Complexity: 7/10 → triggers insight-collab
3. Claude calls `consult_o1` with problem details
4. o1 provides:
   - Analysis of current algorithm
   - Multiple optimization approaches (LSH, KD-trees, approximation)
   - Recommended approach with Big-O analysis
   - Implementation pseudocode
5. Claude implements o1's recommendation
6. Claude provides optimized code

### Acceptance Criteria
- ✅ o1 identifies optimal algorithm (not just incremental improvements)
- ✅ o1 provides complexity analysis
- ✅ Claude successfully implements o1's algorithm
- ✅ Significant performance improvement (10x+)

---

## Test 4: Swarm with Reasoning Agent

### Scenario
Run a swarm that uses reasoning-agent type.

### Input
```bash
claude swarm run .swarms/example_reasoning_swarm_v1.yaml
```

### Expected Behavior
1. Swarm starts
2. Phase 1 agent (reasoning-agent) triggers
3. Claude calls `consult_o1` with swarm consultation params
4. o1 provides architecture plan
5. Plan saved to `.swarms/example_reasoning_swarm/architecture_plan_from_o1.md`
6. Phases 2-5 execute using Claude with o1's plan as input
7. All deliverables created
8. Swarm completes with outcome report

### Acceptance Criteria
- ✅ reasoning-agent type works in swarms
- ✅ o1's plan is properly passed to subsequent phases
- ✅ All deliverables created based on o1's recommendations
- ✅ Swarm self-grades with o1 value assessment

---

## Test 5: Budget Controls

### Scenario
Verify budget controls prevent overspending.

### Input
```
# Set low budget
export OPENAI_DAILY_BUDGET=0.50

User: [Ask 3 complex questions that would trigger insight-collab]
```

### Expected Behavior
1. First consultation: ✅ Succeeds (cost ~$0.40)
2. Second consultation: ❌ Blocked "Daily budget of $0.50 exceeded"
3. Claude reports budget status to user
4. Claude falls back to handling request without o1

### Acceptance Criteria
- ✅ Budget check happens before API call
- ✅ Clear error message when budget exceeded
- ✅ Claude gracefully handles budget limit
- ✅ User informed about budget status

---

## Test 6: Complexity Threshold (Don't Use o1 for Simple Tasks)

### Scenario
Verify Claude does NOT use o1 for simple tasks.

### Input
```
User: "Read the README.md file and summarize it."
```

### Expected Behavior
1. Claude analyzes: file reading + summarization
2. Complexity: 2/10 → below threshold (7)
3. Claude does NOT trigger insight-collab
4. Claude handles request directly (fast)

### Acceptance Criteria
- ✅ Claude does not waste money on simple tasks
- ✅ Response is fast (<5 seconds)
- ✅ No o1 API call made

---

## Test 7: Cost Tracking

### Scenario
Verify cost tracking and reporting works.

### Input
```
# After running several consultations
User: "Get o1 usage metrics"
```

### Expected Behavior
1. Claude calls `get_reasoning_metrics` tool
2. Response includes:
   - Total consultations
   - Total cost (USD)
   - Input/output tokens
   - Average reasoning time
   - Budget remaining

### Acceptance Criteria
- ✅ Metrics are accurate
- ✅ Cost calculation matches actual o1 pricing
- ✅ Budget tracking works correctly

---

## Test 8: Strategic Planning

### Scenario
User requests long-term roadmap planning.

### Input
```
User: "Create a 12-month roadmap for migrating our monolithic app to
microservices. We have 10 developers, can tolerate 2% downtime during
migration, and need to maintain feature velocity."
```

### Expected Behavior
1. Claude analyzes: strategic planning + long-term + complex
2. Complexity: 8/10 → triggers insight-collab
3. Claude calls `plan_strategy` tool
4. o1 provides:
   - Phased migration approach
   - Risk assessment per phase
   - Resource allocation recommendations
   - Dependencies and critical path
   - Rollback strategies
5. Claude creates detailed roadmap based on o1's plan

### Acceptance Criteria
- ✅ o1 provides multi-phase plan
- ✅ o1 identifies risks and mitigations
- ✅ Claude creates actionable roadmap
- ✅ Plan includes rollback procedures

---

## Test 9: Error Handling (No API Key)

### Scenario
Verify graceful error handling when API key missing.

### Input
```
# Remove API key
unset OPENAI_API_KEY

User: [Ask complex question that would trigger insight-collab]
```

### Expected Behavior
1. Claude tries to use insight-collab
2. MCP server returns error: "OpenAI API key not configured"
3. Claude reports to user: "o1 consultation unavailable (API key not set)"
4. Claude falls back to handling request without o1

### Acceptance Criteria
- ✅ Clear error message
- ✅ Graceful fallback
- ✅ User informed how to fix (set OPENAI_API_KEY)

---

## Test 10: Deep Analysis (Architecture Tradeoffs)

### Scenario
User needs deep analysis of architecture options.

### Input
```
User: "Use deep_analysis to help me choose between:
1. Serverless (AWS Lambda + API Gateway)
2. Kubernetes (EKS)
3. Traditional VMs (EC2)

Context:
- Traffic: 1K req/sec avg, 5K peak
- Team: 4 developers (limited ops experience)
- Budget: $5K/month
- Timeline: Deploy in 6 weeks"
```

### Expected Behavior
1. Claude calls `deep_analysis` tool
2. o1 analyzes each option:
   - Pros/cons
   - Cost analysis
   - Operational complexity
   - Team skill requirements
   - Risk assessment
3. o1 provides recommendation with reasoning
4. Claude reports analysis to user

### Acceptance Criteria
- ✅ o1 considers all constraints (budget, team, timeline)
- ✅ o1 provides realistic cost estimates
- ✅ o1 assesses team capability gap
- ✅ Recommendation is actionable

---

## Running All Tests

### Prerequisites
```bash
# Set API key
export OPENAI_API_KEY=sk-proj-...

# Set reasonable budget
export OPENAI_DAILY_BUDGET=10.00

# Verify MCP server
claude mcp list | grep openai-reasoning
# Should show: ✓ Connected
```

### Test Execution
```bash
# Run tests 1-10 in order
# Each test should pass acceptance criteria

# After all tests, check metrics
> Get o1 usage metrics

# Expected:
# - Total consultations: 7-8 (tests 1,2,3,4,7,8,10)
# - Total cost: ~$5-8
# - All consultations successful
# - Budget not exceeded
```

---

## Expected Results Summary

| Test | Should Use o1? | Expected Cost | Expected Time |
|------|----------------|---------------|---------------|
| 1. Architecture Decision | ✅ Yes | $0.80 | 60s |
| 2. Manual Activation | ✅ Yes | $0.50 | 45s |
| 3. Algorithm Optimization | ✅ Yes | $0.60 | 50s |
| 4. Swarm Reasoning Agent | ✅ Yes | $1.20 | 90s |
| 5. Budget Controls | ⚠️ Partial | $0.40 | 45s |
| 6. Complexity Threshold | ❌ No | $0.00 | 3s |
| 7. Cost Tracking | N/A | $0.00 | 2s |
| 8. Strategic Planning | ✅ Yes | $1.00 | 70s |
| 9. Error Handling | ❌ No (error) | $0.00 | 5s |
| 10. Deep Analysis | ✅ Yes | $0.70 | 55s |

**Total Expected Cost**: ~$5.20
**Total Expected Time**: ~7 minutes (with o1 reasoning)

---

## Success Criteria (Overall)

### Must Pass:
- ✅ insight-collab automatically triggers when complexity ≥7
- ✅ insight-collab does NOT trigger when complexity <7
- ✅ o1 provides higher quality reasoning than Claude alone
- ✅ Budget controls prevent overspending
- ✅ Cost tracking is accurate
- ✅ Error handling is graceful
- ✅ Swarm integration works

### Quality Metrics:
- o1 value rating: "high" (o1's reasoning prevented mistakes)
- Cost efficiency: "good" (spending justified by quality)
- Time efficiency: "acceptable" (o1 slowness offset by quality)
- User satisfaction: "excellent" (better decisions made)

---

**Status**: ✅ TEST SCENARIOS READY
**Next**: Run tests with actual OPENAI_API_KEY to verify
