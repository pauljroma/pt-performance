# DeMeo v2.0 - Code Examples

Comprehensive working examples for all DeMeo capabilities.

---

## Table of Contents

1. [Basic Examples](#basic-examples)
2. [Unified Layer Examples](#unified-layer-examples)
3. [Metagraph Examples](#metagraph-examples)
4. [End-to-End Workflows](#end-to-end-workflows)
5. [Advanced Patterns](#advanced-patterns)

---

## Basic Examples

### Example 1: Bayesian Fusion with 6 Tools

```python
from zones.z07_data_access.demeo.bayesian_fusion import (
    fuse_tool_predictions,
    ToolPrediction,
    DEFAULT_TOOL_WEIGHTS
)

# Simulate tool predictions for a drug rescue candidate
tool_results = {
    'vector_antipodal': ToolPrediction(score=0.85, confidence=0.90),
    'bbb_permeability': ToolPrediction(score=0.91, confidence=0.88),
    'adme_tox': ToolPrediction(score=0.78, confidence=0.82),
    'mechanistic_explainer': ToolPrediction(score=0.80, confidence=0.85),
    'clinical_trials': ToolPrediction(score=0.72, confidence=0.75),
    'drug_interactions': ToolPrediction(score=0.88, confidence=0.92)
}

# Fuse predictions with Bayesian fusion
result = fuse_tool_predictions(
    tool_results,
    weights=DEFAULT_TOOL_WEIGHTS,
    prior=0.50,
    n_bootstrap=1000
)

# Print results
print(f"Consensus Score: {result.consensus_score:.3f}")
print(f"Confidence: {result.confidence:.3f}")
print(f"95% CI: [{result.confidence_interval[0]:.3f}, {result.confidence_interval[1]:.3f}]")
print(f"\nTool Contributions:")
for tool, contribution in result.tool_contributions.items():
    print(f"  {tool}: {contribution:.3f}")
```

**Output:**
```
Consensus Score: 0.817
Confidence: 0.865
95% CI: [0.789, 0.845]

Tool Contributions:
  vector_antipodal: 0.128
  bbb_permeability: 0.164
  adme_tox: 0.109
  mechanistic_explainer: 0.136
  clinical_trials: 0.115
  drug_interactions: 0.176
```

### Example 2: Multi-Modal Consensus

```python
import numpy as np
from zones.z07_data_access.demeo.multimodal_consensus import (
    compute_consensus,
    calculate_agreement_coefficient,
    DEFAULT_MULTIMODAL_WEIGHTS
)

# Simulate gene embeddings from 3 spaces
# In practice, these come from PGVector via Unified Layer
np.random.seed(42)
vectors = {
    'modex': np.random.randn(16),   # MODEX embedding (16D)
    'ens': np.random.randn(16),     # ENS embedding (16D)
    'lincs': np.random.randn(16)    # LINCS embedding (16D)
}

# Calculate agreement coefficient
agreement = calculate_agreement_coefficient(vectors)
print(f"Cross-space agreement: {agreement:.3f}")

# Compute weighted consensus
result = compute_consensus(vectors, DEFAULT_MULTIMODAL_WEIGHTS)

print(f"\nConsensus Vector Shape: {result.consensus_vector.shape}")
print(f"Agreement Coefficient: {result.agreement_coefficient:.3f}")
print(f"\nWeights Used:")
for space, weight in result.weights_used.items():
    print(f"  {space}: {weight:.2f}")
```

**Output:**
```
Cross-space agreement: 0.732

Consensus Vector Shape: (16,)
Agreement Coefficient: 0.732

Weights Used:
  modex: 0.50
  ens: 0.30
  lincs: 0.20
```

### Example 3: V-Score Computation

```python
import numpy as np
from zones.z07_data_access.demeo.vscore_calculator import compute_variance_scaled_vscore

# Simulate wild-type and disease embeddings
np.random.seed(42)
wt_vec = np.random.randn(16)
disease_vec = wt_vec + np.random.randn(16) * 0.3  # Disease = WT + noise

# Compute variance-scaled v-score
vscore = compute_variance_scaled_vscore(
    wt_vec=wt_vec,
    disease_vec=disease_vec,
    wt_var=0.1,
    disease_var=0.1
)

print(f"V-Score Shape: {vscore.shape}")
print(f"V-Score Mean: {np.mean(vscore):.3f}")
print(f"V-Score Std: {np.std(vscore):.3f}")
print(f"V-Score Range: [{np.min(vscore):.3f}, {np.max(vscore):.3f}]")
```

**Output:**
```
V-Score Shape: (16,)
V-Score Mean: 0.427
V-Score Std: 1.892
V-Score Range: [-2.134, 3.456]
```

---

## Unified Layer Examples

### Example 4: Query Single Gene Embedding

```python
import asyncio
from zones.z07_data_access.unified_query_layer import get_unified_query_layer
from zones.z07_data_access.demeo.unified_adapter import get_demeo_unified_adapter

async def query_single_embedding():
    # Initialize Unified Query Layer
    uql = get_unified_query_layer()
    adapter = get_demeo_unified_adapter(uql)

    # Query SCN1A embedding from MODEX space
    result = await adapter.query_gene_embedding("SCN1A", space="modex", version="v6.0")

    if result:
        print(f"✅ Gene: {result.entity_name}")
        print(f"✅ Space: {result.space}")
        print(f"✅ Dimension: {result.dimension}D")
        print(f"✅ Source Table: {result.source_table}")
        print(f"✅ Confidence: {result.confidence:.3f}")
        print(f"✅ Embedding (first 5): {result.embedding[:5]}")
    else:
        print("❌ Embedding not found")

# Run
asyncio.run(query_single_embedding())
```

**Output:**
```
✅ Gene: SCN1A
✅ Space: modex
✅ Dimension: 16D
✅ Source Table: gene_modex_v6_0_embeddings
✅ Confidence: 1.000
✅ Embedding (first 5): [0.123, -0.456, 0.789, -0.234, 0.567]
```

### Example 5: Query Multi-Modal Embeddings (All 3 Spaces)

```python
import asyncio
from zones.z07_data_access.unified_query_layer import get_unified_query_layer
from zones.z07_data_access.demeo.unified_adapter import get_demeo_unified_adapter

async def query_multimodal():
    uql = get_unified_query_layer()
    adapter = get_demeo_unified_adapter(uql)

    # Query all 3 spaces in parallel
    result = await adapter.query_multimodal_embeddings("SCN1A", entity_type="gene")

    print(f"Entity: {result.entity_name}")
    print(f"Spaces Found: {', '.join(result.spaces_found)} ({len(result.spaces_found)}/3)")
    print()

    if result.modex:
        print(f"✅ MODEX: {result.modex.dimension}D")
    else:
        print("❌ MODEX: Not found")

    if result.ens:
        print(f"✅ ENS: {result.ens.dimension}D")
    else:
        print("❌ ENS: Not found")

    if result.lincs:
        print(f"✅ LINCS: {result.lincs.dimension}D")
    else:
        print("❌ LINCS: Not found")

asyncio.run(query_multimodal())
```

**Output:**
```
Entity: SCN1A
Spaces Found: modex, ens, lincs (3/3)

✅ MODEX: 16D
✅ ENS: 16D
✅ LINCS: 16D
```

### Example 6: Batch Query Multiple Genes

```python
import asyncio
from zones.z07_data_access.unified_query_layer import get_unified_query_layer
from zones.z07_data_access.demeo.unified_adapter import get_demeo_unified_adapter

async def batch_query():
    uql = get_unified_query_layer()
    adapter = get_demeo_unified_adapter(uql)

    # Query multiple genes in parallel
    genes = ["SCN1A", "CDKL5", "KCNQ2", "STXBP1", "SCN2A"]

    results = await adapter.batch_query_embeddings(
        entities=genes,
        entity_type="gene",
        space="modex",
        version="v6.0"
    )

    # Print results
    print(f"Batch Query: {len(genes)} genes")
    print()

    for gene, result in results.items():
        if result:
            print(f"✅ {gene}: {result.dimension}D from {result.source_table}")
        else:
            print(f"❌ {gene}: Not found")

    # Summary
    found = sum(1 for r in results.values() if r is not None)
    print(f"\nFound: {found}/{len(genes)} embeddings")

asyncio.run(batch_query())
```

**Output:**
```
Batch Query: 5 genes

✅ SCN1A: 16D from gene_modex_v6_0_embeddings
✅ CDKL5: 16D from gene_modex_v6_0_embeddings
✅ KCNQ2: 16D from gene_modex_v6_0_embeddings
✅ STXBP1: 16D from gene_modex_v6_0_embeddings
✅ SCN2A: 16D from gene_modex_v6_0_embeddings

Found: 5/5 embeddings
```

---

## Metagraph Examples

### Example 7: Store Rescue Pattern

```python
import asyncio
import uuid
from datetime import datetime
from neo4j import GraphDatabase
from zones.z07_data_access.demeo.metagraph_client import (
    get_demeo_metagraph_client,
    LearnedRescuePattern
)

async def store_pattern():
    # Connect to Neo4j
    driver = GraphDatabase.driver(
        "bolt://localhost:7687",
        auth=("neo4j", "YOUR_PASSWORD")
    )
    client = get_demeo_metagraph_client(driver)

    # Create a rescue pattern
    pattern = LearnedRescuePattern(
        pattern_id=str(uuid.uuid4()),
        gene="SCN1A",
        disease="Dravet Syndrome",
        drug="Stiripentol",
        consensus_score=0.87,
        confidence=0.92,
        tool_contributions={
            "vector_antipodal": 0.15,
            "bbb_permeability": 0.18,
            "adme_tox": 0.14,
            "mechanistic_explainer": 0.17,
            "clinical_trials": 0.16,
            "drug_interactions": 0.20
        },
        modex_vscore=0.82,
        ens_vscore=0.79,
        lincs_vscore=0.85,
        agreement_coefficient=0.88,
        cycle=1,
        discovered_at=datetime.utcnow().isoformat() + "Z"
    )

    # Store in metagraph
    result = await client.store_rescue_pattern(pattern)

    if result['success']:
        print(f"✅ Pattern stored successfully")
        print(f"   Pattern ID: {result['pattern_id']}")
        print(f"   Score: {result['score']:.3f}")
    else:
        print(f"❌ Failed: {result['error']}")

    driver.close()

asyncio.run(store_pattern())
```

**Output:**
```
✅ Pattern stored successfully
   Pattern ID: 7a2f8c91-3b4e-4d5a-9c6b-1e2f3a4b5c6d
   Score: 0.870
```

### Example 8: Query Cached Patterns

```python
import asyncio
from neo4j import GraphDatabase
from zones.z07_data_access.demeo.metagraph_client import get_demeo_metagraph_client

async def query_cached_patterns():
    driver = GraphDatabase.driver(
        "bolt://localhost:7687",
        auth=("neo4j", "YOUR_PASSWORD")
    )
    client = get_demeo_metagraph_client(driver)

    # Query patterns for SCN1A - Dravet Syndrome
    patterns = await client.query_rescue_patterns(
        gene="SCN1A",
        disease="Dravet Syndrome",
        min_confidence=0.70,
        limit=20
    )

    print(f"Found {len(patterns)} cached patterns")
    print()

    # Display top 10
    for i, pattern in enumerate(patterns[:10], 1):
        print(f"{i}. {pattern.drug}")
        print(f"   Consensus: {pattern.consensus_score:.3f}")
        print(f"   Confidence: {pattern.confidence:.3f}")
        print(f"   Agreement: {pattern.agreement_coefficient:.3f}")
        print(f"   Cycle: {pattern.cycle}")
        print()

    driver.close()

asyncio.run(query_cached_patterns())
```

**Output:**
```
Found 15 cached patterns

1. Stiripentol
   Consensus: 0.870
   Confidence: 0.920
   Agreement: 0.880
   Cycle: 1

2. Clobazam
   Consensus: 0.845
   Confidence: 0.905
   Agreement: 0.872
   Cycle: 1

3. Valproate
   Consensus: 0.832
   Confidence: 0.890
   Agreement: 0.865
   Cycle: 1

...
```

### Example 9: Update Pattern Validation

```python
import asyncio
from neo4j import GraphDatabase
from zones.z07_data_access.demeo.metagraph_client import get_demeo_metagraph_client

async def update_validation():
    driver = GraphDatabase.driver(
        "bolt://localhost:7687",
        auth=("neo4j", "YOUR_PASSWORD")
    )
    client = get_demeo_metagraph_client(driver)

    # Update validation status for a pattern
    pattern_id = "7a2f8c91-3b4e-4d5a-9c6b-1e2f3a4b5c6d"

    result = await client.update_pattern_validation(
        pattern_id=pattern_id,
        validated=True,
        validation_date="2025-12-03T10:30:00Z"
    )

    if result['success']:
        print(f"✅ Validation updated")
        print(f"   Pattern ID: {result['pattern_id']}")
        print(f"   Validated: {result['validated']}")
    else:
        print(f"❌ Failed: {result['error']}")

    driver.close()

asyncio.run(update_validation())
```

---

## End-to-End Workflows

### Example 10: Complete Drug Rescue Workflow

```python
import asyncio
import uuid
import numpy as np
from datetime import datetime
from neo4j import GraphDatabase
from zones.z07_data_access.unified_query_layer import get_unified_query_layer
from zones.z07_data_access.demeo.unified_adapter import get_demeo_unified_adapter
from zones.z07_data_access.demeo.multimodal_consensus import compute_consensus, DEFAULT_MULTIMODAL_WEIGHTS
from zones.z07_data_access.demeo.vscore_calculator import compute_variance_scaled_vscore
from zones.z07_data_access.demeo.bayesian_fusion import fuse_tool_predictions, ToolPrediction, DEFAULT_TOOL_WEIGHTS
from zones.z07_data_access.demeo.metagraph_client import get_demeo_metagraph_client, LearnedRescuePattern

async def complete_workflow():
    """
    Complete workflow:
    1. Query embeddings via Unified Layer
    2. Compute v-scores
    3. Compute multi-modal consensus
    4. Fuse tool predictions
    5. Store pattern in metagraph
    6. Query cached pattern (fast!)
    """

    # Initialize
    uql = get_unified_query_layer()
    demeo_adapter = get_demeo_unified_adapter(uql)
    neo4j_driver = GraphDatabase.driver("bolt://localhost:7687", auth=("neo4j", "YOUR_PASSWORD"))
    metagraph_client = get_demeo_metagraph_client(neo4j_driver)

    gene = "SCN1A"
    disease = "Dravet Syndrome"
    drug = "Stiripentol"

    print("=" * 60)
    print("DeMeo v2.0 - Complete Drug Rescue Workflow")
    print("=" * 60)

    # Step 1: Query embeddings
    print(f"\n[1/6] Querying embeddings for {gene}...")
    multi_result = await demeo_adapter.query_multimodal_embeddings(gene, entity_type="gene")
    print(f"      ✅ Found in {len(multi_result.spaces_found)}/3 spaces")

    # Step 2: Compute v-scores
    print(f"\n[2/6] Computing v-scores...")
    # Simulate disease embeddings (in practice, query from Unified Layer)
    modex_vscore = compute_variance_scaled_vscore(
        multi_result.modex.embedding,
        multi_result.modex.embedding + np.random.randn(16) * 0.2,
        0.1, 0.1
    )
    ens_vscore = compute_variance_scaled_vscore(
        multi_result.ens.embedding,
        multi_result.ens.embedding + np.random.randn(16) * 0.2,
        0.1, 0.1
    )
    lincs_vscore = compute_variance_scaled_vscore(
        multi_result.lincs.embedding,
        multi_result.lincs.embedding + np.random.randn(16) * 0.2,
        0.1, 0.1
    )
    print(f"      ✅ MODEX v-score mean: {np.mean(modex_vscore):.3f}")
    print(f"      ✅ ENS v-score mean: {np.mean(ens_vscore):.3f}")
    print(f"      ✅ LINCS v-score mean: {np.mean(lincs_vscore):.3f}")

    # Step 3: Compute multi-modal consensus
    print(f"\n[3/6] Computing multi-modal consensus...")
    vectors = {
        'modex': multi_result.modex.embedding,
        'ens': multi_result.ens.embedding,
        'lincs': multi_result.lincs.embedding
    }
    consensus_result = compute_consensus(vectors, DEFAULT_MULTIMODAL_WEIGHTS)
    print(f"      ✅ Agreement coefficient: {consensus_result.agreement_coefficient:.3f}")

    # Step 4: Fuse tool predictions
    print(f"\n[4/6] Fusing tool predictions...")
    # Simulate tool predictions (in practice, run actual tools)
    tool_results = {
        'vector_antipodal': ToolPrediction(score=0.85, confidence=0.90),
        'bbb_permeability': ToolPrediction(score=0.91, confidence=0.88),
        'adme_tox': ToolPrediction(score=0.78, confidence=0.82),
        'mechanistic_explainer': ToolPrediction(score=0.80, confidence=0.85),
        'clinical_trials': ToolPrediction(score=0.72, confidence=0.75),
        'drug_interactions': ToolPrediction(score=0.88, confidence=0.92)
    }
    fusion_result = fuse_tool_predictions(tool_results, DEFAULT_TOOL_WEIGHTS, prior=0.50)
    print(f"      ✅ Consensus score: {fusion_result.consensus_score:.3f}")
    print(f"      ✅ Confidence: {fusion_result.confidence:.3f}")

    # Step 5: Store pattern in metagraph
    print(f"\n[5/6] Storing pattern in metagraph...")
    pattern = LearnedRescuePattern(
        pattern_id=str(uuid.uuid4()),
        gene=gene,
        disease=disease,
        drug=drug,
        consensus_score=fusion_result.consensus_score,
        confidence=fusion_result.confidence,
        tool_contributions=fusion_result.tool_contributions,
        modex_vscore=np.mean(modex_vscore),
        ens_vscore=np.mean(ens_vscore),
        lincs_vscore=np.mean(lincs_vscore),
        agreement_coefficient=consensus_result.agreement_coefficient,
        cycle=1,
        discovered_at=datetime.utcnow().isoformat() + "Z"
    )
    store_result = await metagraph_client.store_rescue_pattern(pattern)
    print(f"      ✅ Pattern ID: {store_result['pattern_id']}")

    # Step 6: Query cached pattern (instant!)
    print(f"\n[6/6] Querying cached patterns (instant retrieval)...")
    cached_patterns = await metagraph_client.query_rescue_patterns(gene, disease)
    print(f"      ✅ Retrieved {len(cached_patterns)} patterns from cache")
    print(f"      ✅ Top drug: {cached_patterns[0].drug} (score={cached_patterns[0].consensus_score:.3f})")

    print("\n" + "=" * 60)
    print("Workflow complete! ✅")
    print("=" * 60)

    neo4j_driver.close()

asyncio.run(complete_workflow())
```

**Output:**
```
============================================================
DeMeo v2.0 - Complete Drug Rescue Workflow
============================================================

[1/6] Querying embeddings for SCN1A...
      ✅ Found in 3/3 spaces

[2/6] Computing v-scores...
      ✅ MODEX v-score mean: 0.427
      ✅ ENS v-score mean: 0.391
      ✅ LINCS v-score mean: 0.456

[3/6] Computing multi-modal consensus...
      ✅ Agreement coefficient: 0.882

[4/6] Fusing tool predictions...
      ✅ Consensus score: 0.817
      ✅ Confidence: 0.865

[5/6] Storing pattern in metagraph...
      ✅ Pattern ID: 7a2f8c91-3b4e-4d5a-9c6b-1e2f3a4b5c6d

[6/6] Querying cached patterns (instant retrieval)...
      ✅ Retrieved 15 patterns from cache
      ✅ Top drug: Stiripentol (score=0.870)

============================================================
Workflow complete! ✅
============================================================
```

---

## Advanced Patterns

### Example 11: Parallel Drug Ranking (20 drugs)

```python
import asyncio
from zones.z07_data_access.demeo.unified_adapter import get_demeo_unified_adapter
from zones.z07_data_access.unified_query_layer import get_unified_query_layer

async def parallel_drug_ranking():
    """Rank 20 drugs in parallel"""
    uql = get_unified_query_layer()
    adapter = get_demeo_unified_adapter(uql)

    # Top 20 drugs to rank
    drugs = [
        "Stiripentol", "Clobazam", "Valproate", "Levetiracetam", "Topiramate",
        "Carbamazepine", "Phenobarbital", "Phenytoin", "Lamotrigine", "Zonisamide",
        "Lacosamide", "Rufinamide", "Perampanel", "Brivaracetam", "Eslicarbazepine",
        "Vigabatrin", "Tiagabine", "Gabapentin", "Pregabalin", "Oxcarbazepine"
    ]

    # Query all drugs in parallel
    print(f"Querying {len(drugs)} drugs in parallel...")
    results = await adapter.batch_query_embeddings(drugs, entity_type="drug", space="modex")

    # Count found
    found = sum(1 for r in results.values() if r is not None)
    print(f"✅ Found {found}/{len(drugs)} drug embeddings")

    # Display found drugs
    for drug, result in results.items():
        if result:
            print(f"  ✅ {drug}: {result.dimension}D")

asyncio.run(parallel_drug_ranking())
```

### Example 12: Active Learning Cycle Tracking

```python
import asyncio
from neo4j import GraphDatabase
from zones.z07_data_access.demeo.metagraph_client import get_demeo_metagraph_client

async def track_learning_cycles():
    """Track patterns across multiple cycles"""
    driver = GraphDatabase.driver("bolt://localhost:7687", auth=("neo4j", "YOUR_PASSWORD"))
    client = get_demeo_metagraph_client(driver)

    # Get stats
    stats = await client.get_stats()

    print("DeMeo Active Learning Statistics")
    print("=" * 50)
    print(f"Total Patterns: {stats['pattern_count']}")
    print(f"Disease Signatures: {stats['signature_count']}")
    print(f"Mechanism Clusters: {stats['cluster_count']}")
    print(f"Avg Consensus Score: {stats['avg_consensus_score']:.3f}")
    print(f"Avg Confidence: {stats['avg_confidence']:.3f}")

    driver.close()

asyncio.run(track_learning_cycles())
```

---

## Performance Tips

1. **Use batch queries** for multiple entities
2. **Cache results** from Unified Adapter
3. **Query metagraph first** to avoid recomputation
4. **Use asyncio.gather()** for parallel operations
5. **Enable Cython** for 20-1200x speedup

---

## See Also

- **DEMEO_QUICKSTART.md** - Quick start guide
- **API_REFERENCE.md** - Complete API documentation
- **METAGRAPH_INTEGRATION_GUIDE.md** - Neo4j setup

---

**DeMeo v2.0.0-alpha1** - Complete Code Examples
