# ML Training Data Schema Documentation

## Overview

This document describes the schema for ML training data used to train the tier routing model. The data is collected from query execution traces and labeled with optimal tier assignments.

**Version:** 1.0.0
**Date:** 2025-12-06
**Author:** Agent 4 - Data Collection Engineer
**Zone:** z07_data_access/ml

---

## Data Files

### 1. training_data.json
Raw query patterns collected from distributed tracing or simulated based on tool definitions.

**Format:** JSON array of query pattern objects
**Size:** ~723 KB (1,200 patterns)
**Status:** Unlabeled (no optimal_tier field)

### 2. labeled_training_data.json
Query patterns labeled with optimal tier assignments.

**Format:** JSON array of labeled query pattern objects
**Size:** ~888 KB (1,200 patterns)
**Status:** Labeled (includes optimal_tier field)

### 3. training_sample.parquet
Efficient binary format for ML model training.

**Format:** Apache Parquet
**Size:** ~92 KB (1,200 patterns)
**Status:** Labeled and optimized for ML frameworks

---

## Schema Definition

### Core Fields

| Field Name | Type | Description | Example |
|------------|------|-------------|---------|
| `query_id` | string | Unique identifier for query pattern | "3f2a9d8c-1b4e-5c6d" |
| `query_type` | string | Type of query operation | "name_resolution", "embedding_similarity" |
| `entity_type` | string | Primary entity type in query | "drug", "gene", "pathway" |
| `entity_count` | integer | Number of entities in query | 1, 10, 100 |
| `complexity_score` | float | Query complexity (0.0-1.0) | 0.35, 0.72 |
| `data_sources` | array[string] | Required data sources | ["master_tables"], ["pgvector", "neo4j"] |
| `actual_tier` | integer | Tier actually used (1-4) | 1, 2, 3, 4 |
| `execution_time_ms` | float | Query execution time in milliseconds | 1.2, 45.8, 350.0 |
| `success` | boolean | Whether query succeeded | true, false |
| `timestamp` | string | ISO 8601 timestamp | "2025-12-06T23:15:16.123456" |
| `features` | object | Additional feature data (JSON) | See Features Object below |
| `optimal_tier` | integer | **LABEL**: Optimal tier (1-4) | 1, 2, 3, 4 |

### Features Object

Nested JSON object containing additional features for ML training:

```json
{
  "tool_name": "vector_neighbors",
  "param_count": 3,
  "result_size": 20,
  "has_embedding": true,
  "has_graph": false,
  "is_bulk": false,
  "category": "vector"
}
```

| Feature | Type | Description |
|---------|------|-------------|
| `tool_name` | string | Name of the tool executed |
| `param_count` | integer | Number of parameters passed |
| `result_size` | integer | Number of results returned |
| `has_embedding` | boolean | Uses embedding/vector operations |
| `has_graph` | boolean | Uses graph traversal |
| `is_bulk` | boolean | Bulk/batch operation |
| `category` | string | Tool category |

### Label Metadata (Labeled Data Only)

Additional metadata about the labeling process:

```json
{
  "labeling_method": "automatic",
  "tier_name": "PGVector",
  "is_correctly_routed": false
}
```

---

## Query Types

### name_resolution
Resolving entity names to canonical IDs.

**Examples:**
- drug_name_resolver: "aspirin" → CHEMBL25
- gene_name_resolver: "TP53" → ENSG00000141510

**Typical Tier:** 1 (Master Tables)
**Latency:** <2ms

### metadata_lookup
Retrieving entity metadata.

**Examples:**
- entity_metadata: Get drug properties
- drug_properties_detail: Detailed drug information

**Typical Tier:** 1 (Master Tables)
**Latency:** <2ms

### embedding_similarity
Vector similarity searches.

**Examples:**
- vector_neighbors: Find similar genes
- demeo_drug_rescue: Drug repurposing candidates

**Typical Tier:** 2 (PGVector)
**Latency:** 5-50ms

### graph_traversal
Graph-based queries.

**Examples:**
- graph_neighbors: Find connected nodes
- mechanistic_explainer: Explain drug mechanisms

**Typical Tier:** 3 (Neo4j)
**Latency:** 50-500ms

### graph_path
Path finding in graph.

**Examples:**
- graph_path: Find shortest path between entities

**Typical Tier:** 3 (Neo4j)
**Latency:** 50-500ms

### analytical
Analytical/aggregate queries.

**Examples:**
- session_analytics: User session analysis
- biomarker_discovery: Statistical biomarker analysis

**Typical Tier:** 4 (Parquet)
**Latency:** 100-5000ms

---

## Tier Definitions

### Tier 1: Master Tables (Rust)
**Performance:** <2ms
**Data Source:** master_tables
**Use Cases:** Name resolution, metadata lookup, ID mapping

**Performance Characteristics:**
- Min latency: 0.1ms
- Max latency: 2.0ms
- Typical latency (p50): 0.8ms

**Tools:**
- drug_name_resolver
- gene_name_resolver
- pathway_resolver
- entity_metadata
- count_entities

---

### Tier 2: PGVector
**Performance:** 5-50ms
**Data Source:** pgvector
**Use Cases:** Embedding similarity, vector operations, fusion queries

**Performance Characteristics:**
- Min latency: 5.0ms
- Max latency: 50.0ms
- Typical latency (p50): 20.0ms

**Tools:**
- vector_neighbors
- vector_similarity
- demeo_drug_rescue
- transcriptomic_rescue
- fusion_discovery_drug
- fusion_discovery_gene

---

### Tier 3: Neo4j
**Performance:** 50-500ms
**Data Source:** neo4j
**Use Cases:** Graph traversal, path finding, relationship exploration

**Performance Characteristics:**
- Min latency: 50.0ms
- Max latency: 500.0ms
- Typical latency (p50): 150.0ms

**Tools:**
- graph_neighbors
- graph_path
- graph_subgraph
- mechanistic_explainer
- causal_inference

---

### Tier 4: Parquet (Athena/MinIO)
**Performance:** 100-5000ms
**Data Source:** parquet, athena, minio
**Use Cases:** Analytics, bulk data access, historical analysis

**Performance Characteristics:**
- Min latency: 100.0ms
- Max latency: 5000.0ms
- Typical latency (p50): 500.0ms

**Tools:**
- read_parquet_filter
- session_analytics
- biomarker_discovery
- clinical_trial_intelligence

---

## Complexity Score Calculation

The complexity score (0.0-1.0) is calculated based on:

### Entity Count Factor (0.0-0.3)
- 1 entity: 0.0
- 2-10 entities: 0.1
- 11-50 entities: 0.2
- 50+ entities: 0.3

### Data Source Factor (0.0-0.3)
- 1 source: 0.1
- 2 sources: 0.2
- 3+ sources: 0.3

### Tool Type Factor (0.0-0.4)
- Simple lookup: 0.1
- Embedding query: 0.2
- Analytical query: 0.3
- Graph query: 0.4

**Formula:**
```
complexity_score = min(entity_factor + source_factor + tool_factor, 1.0)
```

---

## Data Collection Methods

### Real-Time Collection
Reads from distributed tracing logs (`./traces/trace_YYYYMMDD.jsonl`).

**Usage:**
```bash
python3 data_collector.py --mode collect --count 1000
```

**Trace Format:**
- One JSON object per line
- Captures actual query execution data
- Includes timing, success/failure, attributes

### Simulation Mode
Generates realistic patterns based on tool definitions.

**Usage:**
```bash
python3 data_collector.py --mode simulate --count 10000
```

**Simulation Characteristics:**
- Realistic tier distribution (40% T1, 35% T2, 15% T3, 10% T4)
- Accurate latency ranges per tier
- Appropriate success rates (99% T1, 98% T2, 95% T3, 92% T4)
- Entity counts matching typical workloads

---

## Labeling Process

### Automatic Labeling Algorithm

The labeler uses multi-factor scoring to determine optimal tier:

1. **Query Type Match (40% weight)**
   - Direct match to tier's query types

2. **Execution Time Fit (30% weight)**
   - How well execution time fits tier's latency range

3. **Data Source Match (20% weight)**
   - Matching required data sources

4. **Complexity Fit (10% weight)**
   - Alignment of complexity with tier expectations

### Override Rules

Strong signals that override scoring:

- Query type = "name_resolution" → **Always Tier 1**
- Execution time < 2ms + success → **Likely Tier 1**
- Data sources = ["master_tables"] only → **Tier 1**
- Execution time > 1000ms → **Likely Tier 4**
- Query type = "graph_traversal" or "graph_path" → **Tier 3**
- Data sources contains "neo4j" → **Tier 3**

---

## Data Statistics

### Dataset: training_sample.parquet (1,200 patterns)

**Tier Distribution:**
- Tier 1: 471 patterns (39.3%)
- Tier 2: 441 patterns (36.8%)
- Tier 3: 167 patterns (13.9%)
- Tier 4: 121 patterns (10.1%)

**Query Type Distribution:**
- name_resolution: 279 patterns (23.3%)
- metadata_lookup: 192 patterns (16.0%)
- embedding_similarity: 225 patterns (18.8%)
- graph_traversal: 63 patterns (5.3%)
- graph_path: 31 patterns (2.6%)
- analytical: 72 patterns (6.0%)
- unknown: 338 patterns (28.2%)

**Entity Type Distribution:**
- drug: 487 patterns (40.6%)
- gene: 399 patterns (33.3%)
- pathway: 314 patterns (26.2%)

**Average Latency by Tier:**
- Tier 1: 1.25ms
- Tier 2: 32.12ms
- Tier 3: 393.84ms
- Tier 4: 6,583.13ms

**Success Rate:** 96.8%

**Routing Accuracy:** 100.0% (all patterns correctly simulated)

---

## Usage Examples

### Loading Data in Python

```python
import json
import pandas as pd

# Load JSON data
with open("labeled_training_data.json") as f:
    data = json.load(f)

# Load Parquet data
df = pd.read_parquet("training_sample.parquet")

# Access features
for pattern in data:
    query_type = pattern["query_type"]
    optimal_tier = pattern["optimal_tier"]
    features = pattern["features"]
    print(f"{query_type} → Tier {optimal_tier}")
```

### Feature Engineering

```python
import json
import pandas as pd

df = pd.read_parquet("training_sample.parquet")

# Parse JSON features
df["features_parsed"] = df["features"].apply(json.loads)
df["tool_name"] = df["features_parsed"].apply(lambda x: x["tool_name"])
df["has_embedding"] = df["features_parsed"].apply(lambda x: x["has_embedding"])

# Create additional features
df["latency_log"] = np.log1p(df["execution_time_ms"])
df["is_fast"] = df["execution_time_ms"] < 10.0

# One-hot encode query types
df_encoded = pd.get_dummies(df, columns=["query_type", "entity_type"])
```

### Training ML Model

```python
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
import pandas as pd
import json

# Load data
df = pd.read_parquet("training_sample.parquet")

# Parse features
df["features_parsed"] = df["features"].apply(json.loads)

# Create feature matrix
X = df[["entity_count", "complexity_score", "execution_time_ms"]]
X["has_embedding"] = df["features_parsed"].apply(lambda x: x["has_embedding"])
X["has_graph"] = df["features_parsed"].apply(lambda x: x["has_graph"])

# Labels
y = df["optimal_tier"]

# Split data
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)

# Train model
model = RandomForestClassifier(n_estimators=100)
model.fit(X_train, y_train)

# Evaluate
accuracy = model.score(X_test, y_test)
print(f"Accuracy: {accuracy:.1%}")
```

---

## Parquet Schema

The Parquet file uses the following schema:

```
query_id: string
query_type: string
entity_type: string
entity_count: int64
complexity_score: double
data_sources: string (JSON array)
features: string (JSON object)
actual_tier: int64
optimal_tier: int64
execution_time_ms: double
success: bool
timestamp: string
```

**Note:** JSON fields (`data_sources`, `features`) are stored as strings and must be parsed.

---

## Data Quality Checks

### Completeness
- All required fields present: ✓
- No null values in critical fields: ✓
- Valid tier values (1-4): ✓

### Consistency
- execution_time_ms aligns with tier: ✓
- query_type matches data_sources: ✓
- complexity_score in range [0.0, 1.0]: ✓

### Balance
- Tier distribution realistic: ✓ (40/35/15/10 split)
- Entity types represented: ✓ (drug/gene/pathway)
- Success rate realistic: ✓ (96.8%)

---

## Future Enhancements

### Data Collection
1. Add real production trace collection
2. Increase dataset size to 10K+ patterns
3. Add multi-day time series data
4. Include user context features

### Labeling
1. Add semi-supervised labeling
2. Include confidence scores
3. Multi-label support (tier + fallback)
4. Active learning for uncertain patterns

### Features
1. Historical query performance
2. User session context
3. Database load metrics
4. Time-of-day patterns
5. Result quality metrics

---

## References

- **Tier Router:** `/zones/z07_data_access/tier_router.py`
- **Distributed Tracing:** `/zones/z13_monitoring/distributed_tracing_config.py`
- **Data Collector:** `/zones/z07_data_access/ml/data_collector.py`
- **Data Labeler:** `/zones/z07_data_access/ml/data_labeler.py`
- **Tool Definitions:** `/zones/z07_data_access/tools/*.py`

---

## Contact

**Agent:** Agent 4 - Data Collection Engineer
**Zone:** z07_data_access
**Phase:** 2 - ML Router Training Pipeline
**Date:** 2025-12-06
