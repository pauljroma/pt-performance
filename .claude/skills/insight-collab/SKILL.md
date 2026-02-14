# insight-collab Skill

**Type**: Collaborative Reasoning
**Models**: Claude (Sonnet 4.5) + OpenAI o1 (latest)
**Purpose**: Claude consults OpenAI o1 for complex reasoning tasks

---

## When to Use This Skill

Claude should **proactively** use this skill when encountering:

### ✅ Use insight-collab When:
1. **Complex Swarm Planning** (>10 phases, multiple dependencies)
2. **Architecture Decisions** (multiple tradeoffs, long-term implications)
3. **Algorithm Optimization** (performance-critical code)
4. **Scientific/Mathematical Problems** (complex equations, proofs)
5. **Strategic Planning** (multi-month roadmaps, system design)
6. **Ambiguous Requirements** (need deep analysis to clarify)
7. **Novel Problems** (no clear precedent, need creative reasoning)

### ❌ Don't Use insight-collab When:
1. Simple CRUD operations
2. File reading/writing
3. Direct tool usage
4. Well-established patterns
5. Time-sensitive operations (o1 is slower)

---

## How It Works

### Step 1: Claude Identifies Complexity
```
User request → Claude analyzes → Complexity score (1-10)
If score ≥ 7 → Use insight-collab
```

### Step 2: Claude Consults o1
```python
# Claude calls OpenAI o1 API
response = await openai_o1_consult(
    problem="Complex swarm with 15 phases and cross-dependencies",
    context="Current system architecture, constraints, goals",
    requested_output="Detailed plan with reasoning, tradeoffs, recommendations"
)
```

### Step 3: o1 Provides Deep Reasoning
```
o1 thinks for 30-60 seconds (extended reasoning)
o1 returns:
- Detailed analysis
- Reasoning steps
- Tradeoffs identified
- Recommended approach
- Implementation plan
```

### Step 4: Claude Executes
```
Claude takes o1's recommendations
Claude uses MCP tools to implement
Claude reports results to user
```

---

## Configuration

### Environment Variables
```bash
# Required in .env
OPENAI_API_KEY=sk-proj-...

# Optional (defaults)
OPENAI_O1_MODEL=o1-preview  # or o1-mini for cheaper
OPENAI_O1_MAX_TOKENS=16000  # o1 max output
OPENAI_O1_TIMEOUT=120       # 2 minutes for reasoning
```

### Cost Controls
```python
# Automatic cost optimization
if estimated_cost > $1.00:
    ask_user_approval()

if problem_complexity < 7:
    use_claude_only()  # Don't waste money on o1
```

---

## Usage Examples

### Example 1: Complex Swarm Planning

**User Request**: "Create a swarm to integrate 5 data sources into Neo4j with validation"

**Claude's Analysis**:
```
Complexity: 8/10
- Multiple data sources (5)
- Graph database integration
- Validation requirements
- Cross-dependencies likely
→ Use insight-collab
```

**Claude → o1 Consultation**:
```
Claude: "I need to plan a swarm for integrating 5 heterogeneous data sources
(ChEMBL, DrugBank, Reactome, LINCS, ClinicalTrials) into Neo4j with validation.
What's the optimal approach?"

o1 (reasoning for 45 seconds):
"After analyzing the problem, here's my recommended approach:

1. Data Source Analysis Phase (3 agents)
   - Agent 1: Schema mapping (ChEMBL, DrugBank)
   - Agent 2: Schema mapping (Reactome, LINCS)
   - Agent 3: Schema mapping (ClinicalTrials)
   Rationale: Parallel analysis of schemas to identify conflicts early

2. Conflict Resolution Phase (1 agent)
   - Agent 4: Merge schemas, resolve ID conflicts
   Rationale: Centralized conflict resolution prevents downstream issues

3. ETL Phase (5 agents in parallel)
   - Agents 5-9: One per data source
   Rationale: Parallel extraction maximizes throughput

4. Validation Phase (2 agents)
   - Agent 10: Data quality validation
   - Agent 11: Relationship validation
   Rationale: Separate structural vs semantic validation

5. Neo4j Load Phase (1 agent)
   - Agent 12: Batch loading with constraints
   Rationale: Single loader prevents transaction conflicts

Key Tradeoffs:
- Parallel ETL increases speed but complexity
- Single loader is bottleneck but ensures consistency
- Early conflict resolution adds time but prevents rework

Recommendation: Use this 5-phase approach with 12 agents"

Claude: "Thank you! I'll implement this plan."
```

**Claude Executes**: Creates swarm YAML with o1's plan

---

### Example 2: Architecture Decision

**User Request**: "Should we use microservices or monolith for the new feature?"

**Claude → o1**:
```
Claude: "Architecture decision needed. Context:
- Current system: Monolithic Python app
- New feature: Real-time data streaming (10K events/sec)
- Team size: 3 developers
- Timeline: 3 months
Should we extract microservices or extend monolith?"

o1: "Analysis:

Monolith Approach:
+ Faster development (no distributed complexity)
+ Easier debugging (single deployment)
+ Lower operational overhead
- Tight coupling risks
- Harder to scale independently
- May bottleneck existing features

Microservices Approach:
+ Independent scaling (streaming service)
+ Clear boundaries
+ Better fault isolation
- 3-month overhead for setup
- 3 developers may struggle with ops
- Increased complexity

Recommendation: Extend monolith with:
1. Create isolated module for streaming
2. Use async processing (separate thread pool)
3. Plan for future extraction (clean interfaces)

Rationale:
- 3 developers + 3 months insufficient for microservices
- Monolith extension is 70% faster
- Can extract later if needed

Migration Path (if needed later):
- Module already isolated
- Clean interfaces enable easy extraction
- Defer microservices until team grows"

Claude: "Recommendation: Extend monolith. I'll create an implementation plan."
```

---

### Example 3: Algorithm Optimization

**User Request**: "Optimize this slow graph traversal algorithm"

**Claude → o1**:
```
Claude: "Need to optimize graph traversal. Current: O(n²) for finding connected
components. Graph has 1M nodes. Taking 30 minutes. Code: [shows code]"

o1: "Analysis:

Current Algorithm: Naive DFS
- Time: O(V + E) per component, O(V²) worst case
- Space: O(V)
- Issue: Repeated work on visited nodes

Optimized Approaches:

1. Union-Find (Disjoint Set)
   - Time: O(E α(V)) ≈ O(E) amortized
   - Space: O(V)
   - Speedup: ~100x on dense graphs
   - Complexity: Low (easy to implement)

2. Parallel BFS
   - Time: O((V+E)/P) on P cores
   - Space: O(V)
   - Speedup: ~8x on 8 cores
   - Complexity: Medium

3. Graph Coloring + Union-Find
   - Time: O(E + V log V)
   - Space: O(V)
   - Speedup: ~200x on dense graphs
   - Complexity: High

Recommendation: Union-Find
- Best speed/complexity tradeoff
- 30 min → <20 seconds (90x speedup)
- Easy to implement and test
- Well-established algorithm

Implementation: [provides pseudocode]"

Claude: "I'll implement the Union-Find algorithm. [implements code]"
```

---

## Integration with Swarms

### Swarm Agent Type: reasoning-agent

```yaml
agents:
  - id: "architect-agent-1"
    type: "reasoning-agent"  # Uses o1
    task: "Design optimal database schema"
    consultation:
      model: "o1-preview"
      prompt: "Design schema for 5 data sources with minimal duplication"
      timeout: 120
    deliverables:
      - ".swarms/schema_design_v1.yaml"
```

### Automatic Consultation

```yaml
swarm_config:
  complexity_threshold: 7
  auto_consult_o1: true  # Automatically use o1 if complexity ≥ 7
  o1_budget_usd: 5.00    # Max spend on o1 for this swarm
```

---

## Cost Tracking

### Per-Consultation Metrics
```json
{
  "consultation_id": "consult-20251203-001",
  "problem": "Complex swarm planning",
  "model": "o1-preview",
  "input_tokens": 2000,
  "output_tokens": 8000,
  "cost_usd": 0.51,
  "reasoning_time_sec": 45,
  "value_rating": "high"
}
```

### Running Total
```
Today's o1 Usage:
- Consultations: 5
- Total cost: $2.35
- Average value: high
- Budget remaining: $7.65 / $10.00
```

---

## Skill Activation

### Proactive Activation
Claude automatically uses this skill when:
1. Swarm complexity score ≥ 7
2. User asks "what's the best approach?"
3. Architecture decision words detected ("microservices", "architecture", "design")
4. Algorithm optimization requested
5. Scientific/mathematical problem detected

### Manual Activation
User explicitly requests:
```
> Use insight-collab to plan this swarm
> Consult o1 for architecture advice
> Ask o1 to optimize this algorithm
```

---

## Implementation

See:
- `openai_reasoning_mcp.py` - MCP server for o1 access
- `insight_collab_skill.py` - Skill implementation
- `swarm_o1_integration.py` - Swarm integration

---

**Status**: 🔄 READY TO IMPLEMENT
**Next**: Create OpenAI reasoning MCP server →
