# DeMeo v2.0 → World-Class Roadmap
**Goal**: Transform DeMeo from prototype to production-grade world-class drug rescue system

**Current Status**: ✅ Foundation Complete | ⚠️ Integration Pending | 🎯 4 Critical Gaps

---

## Executive Summary

DeMeo v2.0 has **exceptional architecture** but currently uses **mock data** for critical components. The path to world-class requires connecting 4 existing systems that are already built:

1. **Real Tool Integration** - Connect 6 Sapphire tools (BBB, ADME, Clinical Trials, etc.)
2. **Drug Database Connection** - Use ChEMBL/DrugBank (14,246 FDA drugs available)
3. **Embedding Space Fixes** - Load 5 missing spaces (MODEX, PLATINUM, Transcript, ENS, DFP)
4. **Metagraph Activation** - Apply Neo4j migrations for 100-1000x caching

**Impact**: Transform from demo to production-grade explainable drug discovery system trusted by researchers.

---

## Current State Analysis

### ✅ What's World-Class Already

| Component | Status | Performance | Grade |
|-----------|--------|-------------|-------|
| **Cython Optimization** | ✅ Complete | 20-1200x speedup | A+ |
| **Bayesian Fusion Math** | ✅ Complete | Explainable predictions | A+ |
| **Multi-Modal Consensus** | ✅ Complete | 3-space fusion (MODEX/ENS/LINCS) | A+ |
| **V-Score Calculator** | ✅ Complete | EP methodology | A |
| **Unified Layer Adapter** | ✅ Complete | PGVector abstraction | A |
| **Metagraph Client** | ✅ Complete | Neo4j pattern storage | A |
| **Tool Architecture** | ✅ Complete | Claude-accessible via Sapphire | A+ |

**Foundation Grade**: **A (95/100)** - Architecture is world-class, needs data connections.

### ⚠️ What's Mock/Incomplete

| Component | Current State | Issue | Impact |
|-----------|---------------|-------|--------|
| **Drug Data** | Mock (`Drug_1`, `Drug_2`) | No real drug names | ❌ Cannot use in production |
| **Tool Predictions** | Hardcoded scores | No real BBB/ADME/Clinical data | ❌ Predictions meaningless |
| **V-Scores** | Random values | No real embedding calculations | ⚠️ Rankings unreliable |
| **Embedding Spaces** | 5/11 unloadable | Missing MODEX_Gene, PLATINUM, etc. | ⚠️ Degraded multi-modal |
| **Neo4j Metagraph** | Schema ready, not applied | No caching available | ⏸️ Slower queries |

**Production Readiness**: **C (60/100)** - Works as demo, not production-ready.

---

## The 4 Critical Gaps (Ranked by Impact)

### Gap 1: Real Tool Integration (HIGHEST IMPACT)
**Status**: 🔴 Blocking Production Use
**Effort**: 2-3 days
**Impact**: ⭐⭐⭐⭐⭐ Transforms from demo to real predictions

**Current Code** (demeo_drug_rescue.py:233-243):
```python
# TODO: Connect real tools (BBB, ADME, etc.) in future version
tool_results = {
    "vector_antipodal": ToolPrediction(score=0.85, confidence=0.90),  # MOCK
    "bbb_permeability": ToolPrediction(score=0.78, confidence=0.85),  # MOCK
    "adme_tox": ToolPrediction(score=0.82, confidence=0.88),          # MOCK
    "mechanistic_explainer": ToolPrediction(score=0.76, confidence=0.80),  # MOCK
    "clinical_trials": ToolPrediction(score=0.88, confidence=0.92),   # MOCK
    "drug_interactions": ToolPrediction(score=0.80, confidence=0.86)  # MOCK
}
```

**World-Class Solution** - Tools ALREADY EXIST in Sapphire!
```python
# Import existing Sapphire tools
from zones.z07_data_access.tools.bbb_permeability import execute as bbb_execute
from zones.z07_data_access.tools.adme_tox_predictor import execute as adme_execute
from zones.z07_data_access.tools.clinical_trial_intelligence import execute as clinical_execute
from zones.z07_data_access.tools.drug_interactions import execute as interactions_execute
from zones.z07_data_access.tools.mechanistic_explainer import execute as mech_execute
from zones.z07_data_access.tools.vector_antipodal import execute as antipodal_execute

# Real predictions
async def get_real_tool_predictions(gene: str, drug: str) -> Dict[str, ToolPrediction]:
    """Execute real tools and convert to ToolPrediction format."""

    # 1. BBB Permeability
    bbb_result = await bbb_execute({"drug": drug})
    bbb_score = bbb_result.get("bbb_probability", 0.5) if bbb_result.get("success") else 0.5

    # 2. ADME/Tox
    adme_result = await adme_execute({"drug": drug})
    adme_score = adme_result.get("safety_score", 0.5) if adme_result.get("success") else 0.5

    # 3. Clinical Trials
    clinical_result = await clinical_execute({"gene": gene, "drug": drug})
    clinical_score = clinical_result.get("evidence_score", 0.5) if clinical_result.get("success") else 0.5

    # 4. Drug Interactions
    interactions_result = await interactions_execute({"drug": drug})
    interaction_score = 1.0 - interactions_result.get("risk_score", 0.5) if interactions_result.get("success") else 0.5

    # 5. Mechanistic Explainer
    mech_result = await mech_execute({"gene": gene, "drug": drug})
    mech_score = mech_result.get("mechanism_score", 0.5) if mech_result.get("success") else 0.5

    # 6. Vector Antipodal
    antipodal_result = await antipodal_execute({"gene": gene, "drug": drug})
    antipodal_score = antipodal_result.get("antipodal_score", 0.5) if antipodal_result.get("success") else 0.5

    return {
        "vector_antipodal": ToolPrediction(score=antipodal_score, confidence=0.90),
        "bbb_permeability": ToolPrediction(score=bbb_score, confidence=0.85),
        "adme_tox": ToolPrediction(score=adme_score, confidence=0.88),
        "mechanistic_explainer": ToolPrediction(score=mech_score, confidence=0.80),
        "clinical_trials": ToolPrediction(score=clinical_score, confidence=0.92),
        "drug_interactions": ToolPrediction(score=interaction_score, confidence=0.86)
    }
```

**Testing Plan**:
1. Test each tool individually with known gene/drug pairs
2. Verify score ranges (0-1) and confidence intervals
3. Benchmark latency (should be <500ms per tool, <2s parallel)
4. Compare Bayesian fusion with real vs mock data

**Acceptance Criteria**:
- ✅ All 6 tools return real predictions (not mock)
- ✅ Predictions vary based on actual gene/drug input
- ✅ Bayesian fusion produces explainable rankings
- ✅ Tool contributions are interpretable

---

### Gap 2: Drug Database Connection (HIGH IMPACT)
**Status**: 🟡 Demo Only
**Effort**: 1-2 days
**Impact**: ⭐⭐⭐⭐ Real drug names and metadata

**Current Code** (demeo_drug_rescue.py:247-252):
```python
# Generate drug results (using mock data for now)
drugs = []
for i in range(min(top_k, 20)):
    drug_name = f"Drug_{i+1}"  # Placeholder - will connect to real drug database
    score = base_score * (1 - i * 0.02)
```

**World-Class Solution** - Query PostgreSQL drug database:
```python
async def get_candidate_drugs_for_gene(gene: str, top_k: int = 100) -> List[Dict[str, Any]]:
    """
    Query PostgreSQL for drugs with evidence for rescuing the gene.

    Data sources:
    - ChEMBL: 14,246 FDA drugs
    - DrugBank: Targets, mechanisms, clinical data
    - LINCS: Perturbation signatures
    """
    from zones.z07_data_access.postgres_connection import get_connection

    async with get_connection() as conn:
        # Query drugs with evidence for gene rescue
        query = """
        SELECT DISTINCT
            d.drugbank_id,
            d.drug_name,
            d.canonical_smiles,
            d.mechanism_of_action,
            d.approval_status,
            t.target_gene,
            AVG(e.similarity_score) as avg_similarity
        FROM drugs d
        JOIN drug_targets t ON d.drugbank_id = t.drugbank_id
        LEFT JOIN embedding_similarities e ON d.drugbank_id = e.drug_id
        WHERE t.target_gene = $1
           OR d.drugbank_id IN (
               SELECT drug_id FROM lincs_perturbations
               WHERE gene_symbol = $1 AND abs(z_score) > 2.0
           )
        GROUP BY d.drugbank_id, d.drug_name, d.canonical_smiles,
                 d.mechanism_of_action, d.approval_status, t.target_gene
        ORDER BY avg_similarity DESC NULLS LAST
        LIMIT $2
        """

        results = await conn.fetch(query, gene, top_k)

        return [
            {
                "drugbank_id": r["drugbank_id"],
                "drug_name": r["drug_name"],
                "smiles": r["canonical_smiles"],
                "mechanism": r["mechanism_of_action"],
                "approval_status": r["approval_status"],
                "prior_evidence_score": float(r["avg_similarity"]) if r["avg_similarity"] else 0.0
            }
            for r in results
        ]
```

**Database Schema Required**:
```sql
-- Drugs table (14,246 FDA drugs)
CREATE TABLE drugs (
    drugbank_id VARCHAR(20) PRIMARY KEY,
    drug_name VARCHAR(255) NOT NULL,
    canonical_smiles TEXT,
    mechanism_of_action TEXT,
    approval_status VARCHAR(50),
    indication TEXT
);

-- Drug-Target relationships
CREATE TABLE drug_targets (
    drugbank_id VARCHAR(20) REFERENCES drugs(drugbank_id),
    target_gene VARCHAR(50),
    target_protein VARCHAR(100),
    interaction_type VARCHAR(50)
);

-- LINCS perturbation signatures
CREATE TABLE lincs_perturbations (
    id SERIAL PRIMARY KEY,
    drug_id VARCHAR(20) REFERENCES drugs(drugbank_id),
    gene_symbol VARCHAR(50),
    z_score FLOAT,
    cell_line VARCHAR(50),
    dose_um FLOAT
);
```

**Testing Plan**:
1. Verify 14,246 drugs are loaded in PostgreSQL
2. Test gene query returns relevant drugs (e.g., "SCN1A" → stiripentol, clobazam)
3. Benchmark query latency (<100ms)
4. Validate drug metadata completeness

**Acceptance Criteria**:
- ✅ Real drug names (e.g., "Stiripentol", "Clobazam" not "Drug_1")
- ✅ DrugBank IDs and SMILES strings included
- ✅ Mechanism of action and approval status available
- ✅ Query returns biologically relevant drugs

---

### Gap 3: Embedding Space Fixes (MEDIUM IMPACT)
**Status**: 🟡 Degraded Performance
**Effort**: 1 day
**Impact**: ⭐⭐⭐ Better multi-modal consensus

**Current Issue** (from startup logs):
```
⚠️  Unloadable: MODEX_Gene_16D_v2_0, PLATINUM_Similarity_v1_0,
                Transcript_v1_Drug, ENS_v3_1_Drug, DFP_PhaseII_16D_v1_0
```

**Root Cause Analysis**:
1. Check if parquet files exist but have schema issues
2. Check if file paths are incorrect in registry
3. Check if embedding dimensions mismatch expected values
4. Check if files are corrupted

**World-Class Solution**:
```bash
# 1. Audit missing spaces
cd zones/z07_data_access/embeddings
python -c "
from unified_query_layer import get_unified_query_layer
uql = get_unified_query_layer()

for space in ['MODEX_Gene_16D_v2_0', 'PLATINUM_Similarity_v1_0',
              'Transcript_v1_Drug', 'ENS_v3_1_Drug', 'DFP_PhaseII_16D_v1_0']:
    try:
        result = uql.test_space_load(space)
        print(f'✅ {space}: {result}')
    except Exception as e:
        print(f'❌ {space}: {e}')
"

# 2. Fix schema issues
# - Regenerate parquet files if corrupted
# - Update registry with correct paths
# - Verify dimensions match expected values

# 3. Verify all 11 spaces load
python -c "
from unified_query_layer import get_unified_query_layer
uql = get_unified_query_layer()
spaces = uql.list_available_spaces()
print(f'Loadable spaces: {len(spaces)}/11')
assert len(spaces) == 11, 'Some spaces still unloadable'
"
```

**Testing Plan**:
1. Test each embedding space loads without errors
2. Verify dimensions match expected values
3. Test query performance (should be <50ms per space)
4. Validate multi-modal consensus uses all 3 spaces (MODEX/ENS/LINCS)

**Acceptance Criteria**:
- ✅ All 11 embedding spaces loadable
- ✅ MODEX, ENS, LINCS all available for consensus
- ✅ No startup warnings about unloadable spaces
- ✅ Multi-modal agreement coefficient > 0.80

---

### Gap 4: Neo4j Metagraph Activation (MEDIUM IMPACT)
**Status**: ⏸️ Ready to Apply
**Effort**: 2 hours
**Impact**: ⭐⭐⭐ 100-1000x caching speedup

**Current State**:
- Schema ready: `zones/z08_persist/neo4j/migrations/demeo_schema_v1.cypher`
- Indexes ready: `zones/z08_persist/neo4j/migrations/demeo_indexes_v1.cypher`
- Edges ready: `zones/z08_persist/neo4j/migrations/demeo_edges_v1.cypher`
- Client code ready: `zones/z07_data_access/demeo/metagraph_client.py`

**World-Class Solution**:
```bash
# 1. Apply Neo4j migrations
cd zones/z08_persist/neo4j/migrations

# Apply schema (creates LearnedRescuePattern node type)
docker exec sand-expo-neo4j cypher-shell -u neo4j -p ${NEO4J_PASSWORD} < demeo_schema_v1.cypher

# Apply indexes (optimizes cache queries)
docker exec sand-expo-neo4j cypher-shell -u neo4j -p ${NEO4J_PASSWORD} < demeo_indexes_v1.cypher

# Apply edges (connects patterns to genes/drugs/diseases)
docker exec sand-expo-neo4j cypher-shell -u neo4j -p ${NEO4J_PASSWORD} < demeo_edges_v1.cypher

# 2. Verify schema
docker exec -it sand-expo-neo4j cypher-shell -u neo4j -p ${NEO4J_PASSWORD}
# In Neo4j Browser:
SHOW CONSTRAINTS;  # Expected: 6 constraints
SHOW INDEXES;      # Expected: 12 indexes

# 3. Test metagraph caching
python -c "
from zones.z07_data_access.demeo.metagraph_client import get_demeo_metagraph_client
from neo4j import GraphDatabase
import asyncio

driver = GraphDatabase.driver('bolt://localhost:7687', auth=('neo4j', 'password'))
client = get_demeo_metagraph_client(driver)

# Test pattern storage and retrieval
async def test_cache():
    # Store pattern
    pattern = LearnedRescuePattern(
        pattern_id='test_001',
        gene='SCN1A',
        disease='Dravet Syndrome',
        drug='Stiripentol',
        consensus_score=0.92,
        confidence=0.88,
        tool_contributions={'bbb': 0.15, 'clinical': 0.18},
        modex_vscore=0.89,
        ens_vscore=0.86,
        lincs_vscore=0.91,
        agreement_coefficient=0.87,
        cycle=1,
        discovered_at='2025-12-03T14:00:00Z'
    )
    await client.store_rescue_pattern(pattern)

    # Query pattern
    results = await client.query_rescue_patterns(
        gene='SCN1A',
        disease='Dravet Syndrome',
        min_confidence=0.70,
        limit=20
    )

    print(f'Cache test: {len(results)} patterns retrieved')
    assert len(results) > 0, 'Cache not working'

asyncio.run(test_cache())
print('✅ Metagraph caching operational')
"
```

**Performance Impact**:
- **Without cache**: 500-1000ms per query (fresh computation)
- **With cache hit**: 10-50ms per query (100-1000x speedup)
- **Cache hit rate**: Expected 60-80% for repeated queries

**Testing Plan**:
1. Store 100 patterns in metagraph
2. Benchmark cache hit latency (<50ms)
3. Benchmark cache miss latency (<1000ms)
4. Verify patterns persist across restarts

**Acceptance Criteria**:
- ✅ Neo4j schema applied (6 constraints, 12 indexes)
- ✅ Patterns can be stored and retrieved
- ✅ Cache hit latency <50ms (10-50ms typical)
- ✅ Graceful degradation if Neo4j unavailable

---

## Implementation Roadmap (2-Week Sprint)

### Week 1: Core Integration (Gaps 1 & 2)

#### Day 1-2: Real Tool Integration (Gap 1)
**Owner**: Integration Engineer
**Output**: `demeo_tool_integration.py` module

- [ ] Create tool adapter functions for all 6 Sapphire tools
- [ ] Test each tool individually with known gene/drug pairs
- [ ] Implement parallel tool execution (async)
- [ ] Add error handling and graceful degradation
- [ ] Update `demeo_drug_rescue.py` to use real tools
- [ ] Run integration tests (9/9 tests should still pass)

**Deliverable**: Real Bayesian fusion with actual tool predictions

#### Day 3-4: Drug Database Connection (Gap 2)
**Owner**: Data Engineer
**Output**: Drug query service + PostgreSQL schema

- [ ] Verify ChEMBL/DrugBank data loaded (14,246 drugs)
- [ ] Create `drug_candidate_service.py` module
- [ ] Implement gene→drug query with evidence scoring
- [ ] Add drug metadata enrichment (SMILES, MoA, approval status)
- [ ] Update `demeo_drug_rescue.py` to use real drugs
- [ ] Test with known gene queries (SCN1A, TSC2, KCNQ2)

**Deliverable**: Real drug rankings with biological validity

#### Day 5: Integration Testing & QA
**Owner**: QA Engineer
**Output**: Test suite + validation report

- [ ] End-to-end test: Gene → Tools → Bayesian → Drugs
- [ ] Validate predictions against known drug-gene relationships
- [ ] Benchmark latency (target: <2s for top-20 drugs)
- [ ] Compare rankings with literature evidence
- [ ] Document any discrepancies or edge cases

**Deliverable**: Production-ready DeMeo v2.1 with real data

---

### Week 2: Performance & Scale (Gaps 3 & 4)

#### Day 6-7: Embedding Space Fixes (Gap 3)
**Owner**: ML Engineer
**Output**: All 11 spaces loadable

- [ ] Audit each unloadable space (5 total)
- [ ] Fix schema/path/dimension issues
- [ ] Regenerate corrupted parquet files if needed
- [ ] Verify multi-modal consensus uses MODEX/ENS/LINCS
- [ ] Test agreement coefficient improvements

**Deliverable**: Full multi-modal consensus (no degraded spaces)

#### Day 8: Neo4j Metagraph Activation (Gap 4)
**Owner**: DevOps + Data Engineer
**Output**: Metagraph caching operational

- [ ] Apply Neo4j migrations (schema, indexes, edges)
- [ ] Verify constraints and indexes created
- [ ] Test pattern storage and retrieval
- [ ] Benchmark cache hit/miss latency
- [ ] Configure auto-caching in `demeo_drug_rescue.py`

**Deliverable**: 100-1000x speedup on repeated queries

#### Day 9-10: Production Hardening
**Owner**: Platform Team
**Output**: Production-ready DeMeo v3.0

- [ ] Add monitoring/instrumentation (Prometheus metrics)
- [ ] Configure alerts (latency >2s, error rate >5%)
- [ ] Add rate limiting and quotas
- [ ] Document operational runbook
- [ ] Create user guide with example queries

**Deliverable**: DeMeo v3.0 World-Class Release

---

## Success Metrics (Before/After)

| Metric | Current (v2.0) | Target (v3.0) | Method |
|--------|----------------|---------------|--------|
| **Prediction Validity** | 0% (mock data) | 95% (real tools) | Validate against literature |
| **Drug Relevance** | 0% (Drug_1, Drug_2) | 90% (real ChEMBL drugs) | Expert review of top-20 |
| **Multi-Modal Coverage** | 6/11 spaces (55%) | 11/11 spaces (100%) | Embedding load test |
| **Cache Hit Latency** | N/A (no cache) | <50ms (100-1000x speedup) | Benchmark repeated queries |
| **End-to-End Latency** | 500-1000ms (no tools) | <2000ms (with tools) | Load test 100 queries |
| **Explainability** | Mock contributions | Real per-tool scores | User study |
| **Biological Validity** | Unknown (no validation) | 85% match literature | Expert curation |

---

## Risk Analysis

### Risk 1: Tool Integration Complexity
**Probability**: Medium
**Impact**: High
**Mitigation**:
- Each tool has different output schema → Create unified adapter
- Some tools may fail → Implement graceful degradation (use prior if tool fails)
- Latency may exceed 2s → Execute tools in parallel with asyncio

### Risk 2: Drug Database Quality
**Probability**: Medium
**Impact**: Medium
**Mitigation**:
- ChEMBL/DrugBank may have incomplete data → Fall back to multiple sources
- Gene-drug mappings may be sparse → Use embedding similarity as fallback
- Approval status may be outdated → Add data freshness checks

### Risk 3: Embedding Space Corruption
**Probability**: Low
**Impact**: Medium
**Mitigation**:
- Parquet files may be corrupted → Keep backups, regenerate if needed
- Dimensions may mismatch → Validate on load, fail gracefully
- Performance may degrade → Monitor query latency, alert on slowdown

### Risk 4: Neo4j Migration Issues
**Probability**: Low
**Impact**: Low
**Mitigation**:
- Migrations may fail → Test in staging first, rollback plan ready
- Cache may fill up → Configure TTL and eviction policies
- Driver may timeout → Add retry logic with exponential backoff

---

## Post-Launch Roadmap (v3.1+)

### Phase 1: Active Learning (v3.1)
**Timeline**: Q1 2026
**Goal**: Learn from user feedback to improve rankings

- Capture user selections (which drugs were chosen)
- Update metagraph with positive/negative signals
- Retrain Bayesian priors based on actual outcomes
- A/B test ranking improvements

### Phase 2: Real-Time Updates (v3.2)
**Timeline**: Q2 2026
**Goal**: Incorporate latest research automatically

- Connect to PubMed API for latest papers
- Update clinical trials data daily
- Refresh drug approval statuses monthly
- Auto-update metagraph patterns

### Phase 3: Hypothesis Generation (v3.3)
**Timeline**: Q3 2026
**Goal**: Proactively suggest novel rescue strategies

- Identify unexplored gene-drug combinations
- Generate mechanistic hypotheses
- Suggest experiments to validate predictions
- Integrate with lab automation systems

### Phase 4: Multi-Disease Expansion (v3.4)
**Timeline**: Q4 2026
**Goal**: Expand beyond epilepsy to all CNS disorders

- Train disease-specific models (Alzheimer's, Parkinson's, ALS)
- Cross-disease transfer learning
- Unified rescue pattern library
- Comparative disease analysis

---

## Conclusion

**DeMeo v2.0 → v3.0 Path to World-Class**:

✅ **Foundation**: World-class architecture (A+ grade)
🔄 **Integration**: 4 critical gaps (2-week sprint)
🚀 **Impact**: Transform from demo to production-grade trusted system

**Key Insight**: DeMeo doesn't need new algorithms or architecture. It needs **data connections** to the excellent tools and databases that already exist in the platform.

**Timeline**: 2 weeks to world-class v3.0 release.

**Next Step**: Approve roadmap → Assign team → Execute Week 1 (Tool Integration + Drug Database)

---

**Document Version**: 1.0
**Created**: 2025-12-03
**Owner**: DeMeo Product Team
**Status**: Awaiting Approval
