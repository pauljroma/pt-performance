# insight-collab Quick Start

**Purpose**: Enable Claude to consult OpenAI o1 for complex reasoning tasks

**Status**: ✅ READY TO USE (MCP server registered, skill configured)

---

## Prerequisites

### 1. OpenAI API Key (Required)

```bash
# Add to your .env file
export OPENAI_API_KEY=sk-proj-...

# Optional configuration
export OPENAI_O1_MODEL=o1-preview  # or o1-mini for cheaper
export OPENAI_O1_MAX_TOKENS=16000
export OPENAI_DAILY_BUDGET=10.00   # USD
export OPENAI_PER_CALL_MAX=2.00    # USD per consultation
```

### 2. Verify MCP Server

```bash
claude mcp list
# Should show: openai-reasoning: ✓ Connected
```

---

## How It Works

```
User Request → Claude Analyzes Complexity
                    ↓
            Complexity ≥ 7?
                    ↓
               Yes → Use insight-collab
                    ↓
           Claude → consult_o1 tool
                    ↓
           o1 thinks (30-60s)
                    ↓
           o1 returns reasoning
                    ↓
           Claude implements recommendations
                    ↓
           Claude reports to user
```

---

## Usage Examples

### Example 1: Proactive Activation (Automatic)

```
User: "Design a microservices architecture for our event processing system
that handles 100K events/second with 99.99% uptime across 3 regions."

Claude:
[Analyzes request]
Complexity: 9/10 (architecture decision, multiple tradeoffs, high stakes)
→ Automatically uses insight-collab

"I'll consult OpenAI o1 for this complex architecture decision..."

[Calls consult_o1]

o1: [Thinks for 45 seconds]
"After analyzing the requirements, here's my recommended approach:

1. Event Processing Service (Separate microservice)
   - Use Kafka for message queue (proven at scale)
   - Horizontal scaling with consumer groups
   - Rationale: Decouples event processing from main app

2. API Gateway Layer
   - Use Kong or AWS API Gateway
   - Rate limiting, authentication
   - Rationale: Prevents overwhelming backend services

3. Database Strategy
   - Keep PostgreSQL for transactional data
   - Add Cassandra for event logs (time-series)
   - Rationale: PostgreSQL doesn't scale well for 100K writes/sec

4. Deployment Strategy
   - Kubernetes across 3 regions
   - Active-active with region affinity
   - Rationale: Meets 99.99% uptime requirement

Key Tradeoffs:
- Complexity vs Performance: Higher complexity justified by 100K/sec requirement
- Cost vs Reliability: Multi-region adds $30K/month but meets uptime SLA
- Migration Risk: Phased approach reduces risk but takes 4 months

Recommended: Hybrid approach - extract event processing first (2 months),
then add API gateway (1 month), then migrate to multi-region (1 month)."

Claude: "Based on o1's analysis, I'll create the implementation plan..."
[Creates detailed specs, configs, migration runbook]
```

### Example 2: Manual Activation (Explicit)

```
User: "Use insight-collab to analyze whether we should use GraphQL or REST
for our new API."

Claude: "I'll consult o1 for this architecture decision..."

[Calls deep_analysis tool]

o1: [Provides detailed pros/cons, tradeoffs, recommendation]

Claude: "Recommendation: REST for now, plan for GraphQL later.
Here's why..."
```

### Example 3: Swarm Integration

```yaml
# In your swarm YAML
phases:
  - phase: 1
    name: "Architecture Planning"
    agent_type: "reasoning-agent"  # Uses o1

    consultation:
      model: "o1-preview"
      problem: "Your complex problem here"
      requested_output: "Detailed analysis with recommendations"

    agents:
      - id: "architect-agent"
        type: "reasoning-agent"
        task: "Consult o1 for architecture design"
        deliverables:
          - ".swarms/your_swarm/plan.md"
```

---

## When Claude Uses insight-collab (Automatically)

### ✅ Triggers (Complexity ≥ 7):

1. **Complex Swarm Planning**
   - >10 phases
   - Multiple dependencies
   - Cross-system integration

2. **Architecture Decisions**
   - Keywords: "microservices", "architecture", "design pattern"
   - Multiple options with tradeoffs
   - Long-term implications

3. **Algorithm Optimization**
   - Performance-critical code
   - Big-O complexity concerns
   - Keywords: "optimize", "performance", "faster"

4. **Scientific/Mathematical Problems**
   - Complex equations
   - Statistical analysis
   - Research-level questions

5. **Strategic Planning**
   - >6 month timeline
   - Keywords: "roadmap", "strategy", "long-term"

### ❌ Won't Trigger (Complexity <7):

1. Simple CRUD operations
2. File reading/writing
3. Direct tool usage
4. Well-established patterns
5. Time-sensitive operations (o1 is slow)

---

## Cost Management

### Pricing (Dec 2024)

**o1-preview** (complex reasoning):
- Input: $15 / 1M tokens
- Output: $60 / 1M tokens
- Typical cost: $0.50 - $2.00 per consultation

**o1-mini** (simpler reasoning):
- Input: $3 / 1M tokens
- Output: $12 / 1M tokens
- Typical cost: $0.10 - $0.40 per consultation

### Budget Controls (Automatic)

```json
{
  "daily_budget_usd": 10.00,
  "per_consultation_max_usd": 2.00,
  "require_user_approval_above_usd": 1.00
}
```

- Daily budget: $10
- Per-call max: $2
- User approval if >$1

### Check Usage

```
User: "Get o1 usage metrics"

Claude: [Calls get_reasoning_metrics]

Response:
Total Consultations: 5
Total Cost: $2.35
Daily Budget: $10.00
Budget Used: 23.5%

Avg Reasoning Time: 42s
```

---

## Testing

### Test 1: Simple Consultation

```bash
# In Claude Code CLI
> Consult o1: What's the best algorithm for finding connected components
  in a graph with 1M nodes?

[Claude calls consult_o1]
[o1 reasons and recommends Union-Find]
[Claude responds with implementation]
```

### Test 2: Swarm with Reasoning Agent

```bash
claude swarm run .swarms/example_reasoning_swarm_v1.yaml
```

---

## Troubleshooting

### Error: "OpenAI API key not configured"

**Fix**:
```bash
export OPENAI_API_KEY=sk-proj-...
# Restart Claude Code session
```

### Error: "Budget exceeded"

**Fix**:
```bash
# Increase daily budget
export OPENAI_DAILY_BUDGET=20.00

# Or check current usage
> Get o1 usage metrics
```

### o1 Taking Too Long

**Cause**: o1 thinks for 30-60 seconds (normal)

**Fix**: Use o1-mini for simpler problems:
```bash
export OPENAI_O1_MODEL=o1-mini
```

### Cost Too High

**Fix**: Claude automatically uses o1 only when complexity ≥7
- Review triggers in config.json
- Increase complexity_threshold to 8 or 9
- Use o1-mini instead of o1-preview

---

## Best Practices

### ✅ Do:

1. **Let Claude decide** - Trust the complexity threshold (7)
2. **Use for planning** - o1 excels at upfront design
3. **Cache o1 responses** - Store in .swarms/ for reuse
4. **Track value** - Note when o1 prevented costly mistakes

### ❌ Don't:

1. **Don't use for simple tasks** - Wastes money and time
2. **Don't bypass budget controls** - They protect you
3. **Don't expect instant results** - o1 takes 30-60s to think
4. **Don't use for urgent tasks** - o1 is slow

---

## Integration with Existing Workflow

### Before insight-collab:
```
User request → Claude plans → Claude executes → Done
```

### After insight-collab:
```
User request → Claude analyzes complexity
                     ↓
             Complexity < 7 → Claude handles alone (fast)
                     ↓
             Complexity ≥ 7 → Claude consults o1 (deep reasoning)
                     ↓
                o1 provides plan
                     ↓
             Claude executes plan
                     ↓
                   Done
```

**Result**: Best of both worlds
- Fast execution for simple tasks (Claude alone)
- Deep reasoning for complex tasks (Claude + o1)

---

## Next Steps

1. ✅ Set OPENAI_API_KEY environment variable
2. ✅ Verify MCP server connected: `claude mcp list`
3. ✅ Try a complex question and see Claude automatically use insight-collab
4. ✅ Run example swarm: `claude swarm run .swarms/example_reasoning_swarm_v1.yaml`
5. ✅ Monitor usage: Ask Claude "Get o1 usage metrics"

---

**Questions?**

- See full documentation: `.claude/skills/insight-collab/SKILL.md`
- See MCP server code: `mcp_servers/openai_reasoning_mcp.py`
- See example swarms: `.swarms/example_reasoning_swarm_v1.yaml`

**Status**: ✅ PRODUCTION READY
