# Sapphire v3.8 Service Integration Guide

**Version:** 3.8.0
**Date:** 2025-11-29
**Status:** Production Ready

## Overview

Sapphire v3.8 introduces 3 new service integration tools that connect to specialized microservices for advanced literature analysis and biomarker discovery. These tools extend Sapphire's capabilities beyond the existing 24 tools.

## New Tools (3)

### 1. literature_search_agent

**Purpose:** Deep citation network analysis with multi-hop traversal

**Service:** Literature Search Agent v1.0 (port 8101)

**Use Cases:**
- Find foundational papers via citation chains
- Trace research lineage and evolution of ideas
- Deep citation network traversal (1-3 hops)
- Hybrid search (semantic + keyword matching)

**Example Usage:**
```python
{
    "query": "KCNQ2 channel modulators",
    "search_type": "hybrid",  # or "semantic", "keyword"
    "citation_depth": 2,      # 1-3 hops
    "top_k": 20               # number of results
}
```

**When to use vs semantic_search:**
- Use `literature_search_agent` for: Citation chains, foundational papers, research lineage
- Use `semantic_search` for: Quick lookups, broad topic searches

### 2. biomarker_discovery

**Purpose:** AI-powered biomarker identification from literature

**Service:** Biomarker Discovery Agent v1.0 (port 8100)

**Use Cases:**
- Diagnostic biomarker discovery
- Prognostic marker identification
- Predictive biomarker analysis
- Tissue-specific biomarker discovery

**Biomarker Types:**
- `diagnostic`: Disease detection/diagnosis
- `prognostic`: Disease progression prediction
- `predictive`: Treatment response prediction
- `monitoring`: Disease monitoring

**Example Usage:**
```python
{
    "disease": "tuberous sclerosis",
    "biomarker_type": "diagnostic",  # or prognostic, predictive, monitoring
    "tissue": "brain",               # optional: brain, blood, csf, etc.
    "top_k": 20
}
```

**Output Includes:**
- Biomarker name and type
- Disease association
- Tissue specificity
- Evidence strength from literature
- Supporting papers (PMIDs)
- Clinical validation status

### 3. literature_evidence

**Purpose:** Multi-query aggregation and evidence chain reasoning

**Service:** Literature API v1.0 (port 8765)

**Two Modes:**

#### Mode 1: Multi-Query Aggregation
Combine multiple queries to build comprehensive evidence.

**Aggregation Types:**
- `union`: Combine all unique results (broader coverage)
- `intersection`: Only papers matching all queries (higher precision)

**Example:**
```python
{
    "mode": "aggregate",
    "queries": [
        "SCN1A mutations",
        "epilepsy treatments",
        "sodium channel blockers"
    ],
    "aggregation": "intersection",  # or "union"
    "limit": 50
}
```

**Use Case:** "Find papers about SCN1A that discuss both epilepsy AND drug treatments"

#### Mode 2: Evidence Chain Reasoning
Multi-hop reasoning to verify or discover causal chains.

**Example:**
```python
{
    "mode": "evidence_chain",
    "claim": "Aspirin modulates SCN1A expression",
    "max_hops": 3,                  # 1-5 hops
    "confidence_threshold": 0.6     # 0-1
}
```

**Use Case:** Verify if there's evidence that drug X affects gene Y through intermediate steps (e.g., Aspirin→COX-2→Inflammation→SCN1A)

**Output Includes:**
- Evidence chain (hop by hop)
- Confidence score per hop
- Overall chain confidence
- Supporting papers with excerpts
- Whether chain successfully links to claim

## Architecture

### Service Topology

```
Sapphire v3.8 (port 8081)
    ├── Literature Search Agent (port 8101)
    │   └── ChromaDB + Citation Graph
    ├── Biomarker Discovery Agent (port 8100)
    │   └── ChromaDB + NLP
    └── Literature API (port 8765)
        └── ChromaDB (29,863 papers)
```

### Data Sources

All services use the same literature corpus:
- **29,863 CNS drug discovery papers**
- ChromaDB for semantic search
- Full-text abstracts + metadata

### Performance

| Tool | Typical Latency | Max Latency |
|------|----------------|-------------|
| literature_search_agent | 1-5s | 30s (timeout) |
| biomarker_discovery | 2-8s | 30s (timeout) |
| literature_evidence (aggregate) | 1-3s | 30s (timeout) |
| literature_evidence (chain) | 2-8s | 30s (timeout) |

## Service Configuration

### Environment Variables

```bash
# Optional - defaults to localhost
export LITERATURE_SEARCH_AGENT_URL="http://localhost:8101"
export BIOMARKER_DISCOVERY_AGENT_URL="http://localhost:8100"
export LITERATURE_API_URL="http://localhost:8765"
```

### Health Checks

All services expose `/health` endpoints:

```bash
curl http://localhost:8101/health  # Literature Search Agent
curl http://localhost:8100/health  # Biomarker Discovery Agent
curl http://localhost:8765/health  # Literature API
```

## Integration Testing

### Quick Test

```python
import asyncio
from clients.quiver.quiver_platform.zones.z07_data_access.tools.literature_search_agent import execute as lit_search
from clients.quiver.quiver_platform.zones.z07_data_access.tools.biomarker_discovery import execute as biomarker
from clients.quiver.quiver_platform.zones.z07_data_access.tools.literature_evidence import execute as evidence

# Test 1: Literature Search Agent
result1 = asyncio.run(lit_search({
    'query': 'KCNQ2 epilepsy',
    'citation_depth': 2,
    'top_k': 10
}))
print(f"Literature Search: {result1.get('count')} results")

# Test 2: Biomarker Discovery
result2 = asyncio.run(biomarker({
    'disease': 'epilepsy',
    'biomarker_type': 'diagnostic',
    'top_k': 5
}))
print(f"Biomarkers Found: {result2.get('count')}")

# Test 3: Literature Evidence (Aggregate)
result3 = asyncio.run(evidence({
    'mode': 'aggregate',
    'queries': ['SCN1A', 'epilepsy'],
    'aggregation': 'intersection',
    'limit': 20
}))
print(f"Aggregate Results: {result3.get('total')}")

# Test 4: Literature Evidence (Chain)
result4 = asyncio.run(evidence({
    'mode': 'evidence_chain',
    'claim': 'valproic acid affects SCN1A',
    'max_hops': 3
}))
print(f"Evidence Chain: {len(result4.get('evidence_chain', []))} hops")
print(f"Chain Complete: {result4.get('chain_complete')}")
```

## Error Handling

All tools return consistent error responses:

```python
{
    "success": False,
    "error": "Error description",
    "tool_name": "literature_search_agent"  # optional
}
```

### Common Errors

1. **Service Unavailable**
   ```
   "Cannot connect to Literature Search Agent at http://localhost:8101. Is the service running?"
   ```
   **Solution:** Check Docker containers are running (`docker ps`)

2. **Timeout**
   ```
   "Literature API timeout (>30s) in aggregate mode. Try reducing complexity."
   ```
   **Solution:** Reduce `top_k`, `citation_depth`, or `max_hops`

3. **Validation Error**
   ```
   "queries must be a list with 1-10 queries"
   ```
   **Solution:** Check parameter format and limits

## Tool Comparison Matrix

| Feature | semantic_search | literature_search_agent | literature_evidence |
|---------|----------------|------------------------|-------------------|
| Speed | Fast (<200ms) | Medium (1-5s) | Medium (1-8s) |
| Citation depth | No | Yes (1-3 hops) | Yes (evidence chains) |
| Multi-query | No | No | Yes (union/intersection) |
| Causal reasoning | No | No | Yes (evidence chains) |
| Best for | Quick lookups | Deep research | Evidence synthesis |

## Version History

### v3.8 (2025-11-29)
- Added 3 service integration tools
- Total tools: 27 (up from 24)
- New capabilities: Citation analysis, biomarker discovery, evidence chains

### Migration from v3.7

No breaking changes. Existing tools continue to work.

**New capabilities available:**
1. Deep citation analysis via `literature_search_agent`
2. Biomarker discovery via `biomarker_discovery`
3. Multi-query aggregation via `literature_evidence` (mode='aggregate')
4. Evidence chain reasoning via `literature_evidence` (mode='evidence_chain')

## Best Practices

1. **Choose the right tool:**
   - Quick literature search → `semantic_search`
   - Deep citation analysis → `literature_search_agent`
   - Biomarker discovery → `biomarker_discovery`
   - Evidence synthesis → `literature_evidence`

2. **Optimize performance:**
   - Start with small `top_k` values
   - Use `citation_depth: 1` first, increase if needed
   - For evidence chains, use `confidence_threshold: 0.6` as default

3. **Combine tools:**
   - Use `semantic_search` first for broad overview
   - Follow up with `literature_search_agent` for deep dive
   - Validate findings with `literature_evidence` chains

## Support

**Documentation Location:**
- Tool definitions: `clients/quiver/quiver_platform/zones/z07_data_access/tools/`
- This guide: `clients/quiver/quiver_platform/zones/z07_data_access/tools/SERVICE_INTEGRATION_GUIDE.md`

**Service Health:**
```bash
# Check all services
docker ps | grep -E "literature|biomarker"

# View service logs
docker logs sand-expo-literature-search-agent
docker logs sand-expo-biomarker-discovery-agent
docker logs sand-expo-literature-api
```

**Sapphire Logs:**
```bash
tail -f /tmp/sapphire_v3.log
```
