# ML Router Training Data Collection Pipeline

Production-ready data collection pipeline for training an ML-based tier routing model. Collects query execution patterns from distributed tracing and generates labeled training datasets.

**Version:** 1.0.0
**Date:** 2025-12-06
**Author:** Agent 4 - Data Collection Engineer
**Zone:** z07_data_access/ml

---

## Overview

This pipeline collects and labels query execution data to train an ML model that predicts the optimal database tier (1-4) for routing queries. The goal is to optimize query performance by routing queries to the most appropriate tier based on query characteristics.

### Tier Routing System

- **Tier 1 (Master Tables):** <2ms - Name resolution, metadata lookup
- **Tier 2 (PGVector):** 5-50ms - Embedding similarity, vector operations
- **Tier 3 (Neo4j):** 50-500ms - Graph traversal, relationship queries
- **Tier 4 (Parquet):** 100-5000ms - Analytics, bulk data access

---

## Quick Start

### 1. Generate Training Data

```bash
# Generate 10,000 simulated query patterns
python3 data_collector.py --mode simulate --count 10000 --output training_data.json

# Or collect from distributed tracing
python3 data_collector.py --mode collect --output real_data.json
```

### 2. Label Data with Optimal Tiers

```bash
python3 data_labeler.py \
  --input training_data.json \
  --output-json labeled_training_data.json \
  --output-parquet training_sample.parquet
```

### 3. Validate Pipeline

```bash
python3 test_pipeline.py
```

---

## Files

### Core Modules

- **`data_collector.py`** - Collects query patterns from traces or simulates them
- **`data_labeler.py`** - Automatically labels patterns with optimal tiers
- **`test_pipeline.py`** - Validates the entire pipeline
- **`schema.md`** - Complete data schema documentation

### Data Files (in `data/`)

- **`training_data.json`** - Raw query patterns (unlabeled)
- **`labeled_training_data.json`** - Labeled patterns (includes optimal_tier)
- **`training_sample.parquet`** - Efficient Parquet format for ML training

---

## Data Collection

### Mode 1: Simulation (Default)

Generates realistic query patterns based on tool definitions and performance characteristics.

```python
from data_collector import MLDataCollector

collector = MLDataCollector()
patterns = collector.simulate_query_patterns(count=10000)
collector.save_dataset(patterns, "training_data.json")
```

**Advantages:**
- Fast generation (1000 patterns/second)
- Realistic distributions
- No production dependency

**Distribution:**
- Tier 1: 40% (name resolution)
- Tier 2: 35% (embeddings)
- Tier 3: 15% (graph queries)
- Tier 4: 10% (analytics)

### Mode 2: Real Traces

Collects from distributed tracing logs (`./traces/trace_YYYYMMDD.jsonl`).

```python
collector = MLDataCollector()
patterns = collector.collect_from_traces(days=7)  # Last 7 days
collector.save_dataset(patterns, "real_data.json")
```

**Advantages:**
- Real production data
- Actual performance metrics
- True query distributions

---

## Data Labeling

### Automatic Labeling

Multi-factor scoring algorithm determines optimal tier:

1. **Query Type Match (40% weight)** - Direct match to tier's query types
2. **Execution Time Fit (30% weight)** - How well time fits tier's latency range
3. **Data Source Match (20% weight)** - Matching required data sources
4. **Complexity Fit (10% weight)** - Alignment with tier expectations

```python
from data_labeler import MLDataLabeler

labeler = MLDataLabeler()
patterns = labeler.load_patterns("training_data.json")
labeled = labeler.label_patterns(patterns)

# Save as JSON
labeler.save_labeled_data(labeled, "labeled_training_data.json")

# Save as Parquet for ML training
labeler.save_as_parquet(labeled, "training_sample.parquet")
```

### Override Rules

Strong signals that override scoring:

- Query type = "name_resolution" → **Always Tier 1**
- Execution time < 2ms + success → **Tier 1**
- Data sources = ["master_tables"] only → **Tier 1**
- Query type = "graph_traversal" or "graph_path" → **Tier 3**
- Execution time > 1000ms → **Tier 4**

---

## Data Schema

### Core Fields

| Field | Type | Description |
|-------|------|-------------|
| `query_id` | string | Unique identifier |
| `query_type` | string | Query operation type |
| `entity_type` | string | Entity type (drug/gene/pathway) |
| `entity_count` | int | Number of entities |
| `complexity_score` | float | Query complexity (0.0-1.0) |
| `data_sources` | array | Required data sources |
| `actual_tier` | int | Tier used (1-4) |
| `execution_time_ms` | float | Execution time |
| `success` | bool | Query success |
| `features` | object | Additional features (JSON) |
| `optimal_tier` | int | **LABEL**: Optimal tier |

See `schema.md` for complete documentation.

---

## Usage Examples

### Training an ML Model

```python
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
import json

# Load Parquet data
df = pd.read_parquet("data/training_sample.parquet")

# Parse features
df["features_parsed"] = df["features"].apply(json.loads)

# Create feature matrix
X = df[["entity_count", "complexity_score", "execution_time_ms"]].copy()
X["has_embedding"] = df["features_parsed"].apply(lambda x: x["has_embedding"])
X["has_graph"] = df["features_parsed"].apply(lambda x: x["has_graph"])

# Labels
y = df["optimal_tier"]

# Split and train
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)
model = RandomForestClassifier(n_estimators=100)
model.fit(X_train, y_train)

# Evaluate
accuracy = model.score(X_test, y_test)
print(f"Accuracy: {accuracy:.1%}")
```

### Analyzing Misroutings

```python
from data_labeler import MLDataLabeler

labeler = MLDataLabeler()
patterns = labeler.load_patterns("labeled_training_data.json")

# Analyze misroutings
analysis = labeler.analyze_misroutings(patterns)
print(json.dumps(analysis, indent=2))
```

---

## Current Dataset Statistics

### training_sample.parquet (1,200 patterns)

**Tier Distribution:**
- Tier 1: 471 patterns (39.3%)
- Tier 2: 441 patterns (36.8%)
- Tier 3: 167 patterns (13.9%)
- Tier 4: 121 patterns (10.1%)

**Average Latency by Tier:**
- Tier 1: 1.25ms
- Tier 2: 32.12ms
- Tier 3: 393.84ms
- Tier 4: 6,583.13ms

**Success Rate:** 96.8%

**Routing Accuracy:** 100.0%

---

## Integration Points

### Distributed Tracing

Automatically collects data from:
```python
from zones.z13_monitoring.distributed_tracing_config import tracer
```

Trace files: `./traces/trace_YYYYMMDD.jsonl`

### Tier Router

Integrates with:
```python
from zones.z07_data_access.tier_router import TierRouter
```

### Zone 7 API

All data collection uses Zone 7 patterns:
- No direct database access
- Uses resolver APIs
- Respects zone boundaries

---

## Testing

### Run All Tests

```bash
python3 test_pipeline.py
```

### Test Results

```
✓ Data Collector - Simulation: PASS
✓ Data Collector - Statistics: PASS
✓ Data Labeler - Loading: PASS
✓ Data Labeler - Labeling Logic: PASS
✓ Data Labeler - Tier Determination: PASS
✓ Parquet Generation: PASS
✓ Data Quality - Schema: PASS
✓ Data Quality - Values: PASS
✓ Data Quality - Distribution: PASS
✓ Integration - End to End: PASS

Total: 10 tests
Passed: 10
Failed: 0
Success Rate: 100.0%
```

---

## Architecture

### Data Flow

```
1. Query Execution
   ↓
2. Distributed Tracing (spans)
   ↓
3. Data Collector (extract patterns)
   ↓
4. Data Labeler (assign optimal tiers)
   ↓
5. Parquet Export (ML training format)
   ↓
6. ML Model Training
   ↓
7. Production Tier Router
```

### Simulation Flow

```
1. Tool Definitions → Collector
   ↓
2. Realistic Pattern Generation
   ↓
3. Performance Simulation (per tier)
   ↓
4. Labeling (optimal tier assignment)
   ↓
5. Training Dataset
```

---

## Zone Compliance

### Zone 7 Boundaries ✓

- **No direct database access** - Uses Zone 7 API patterns
- **No cross-zone imports** - Self-contained ML pipeline
- **Distributed tracing integration** - Zone 13 monitoring
- **Tool definitions** - Reads from Zone 7 tools/

### Data Sources Used

- Master Tables (Tier 1) - via resolvers
- PGVector (Tier 2) - via PGVectorService
- Neo4j (Tier 3) - via graph tools
- Parquet (Tier 4) - via analytics tools

---

## Production Deployment

### Step 1: Enable Real Trace Collection

```python
# In zones/z13_monitoring/distributed_tracing_config.py
TRACING_ENABLED = True  # Enable tracing
```

### Step 2: Schedule Data Collection

```bash
# Cron job to collect data daily
0 2 * * * cd /path/to/ml && python3 data_collector.py --mode collect --output daily_data.json
```

### Step 3: Periodic Labeling

```bash
# Weekly labeling job
0 3 * * 0 cd /path/to/ml && python3 data_labeler.py --input daily_data.json --output-parquet weekly_training.parquet
```

### Step 4: Model Retraining

```bash
# Monthly model retraining
0 4 1 * * cd /path/to/ml && python3 train_model.py --input weekly_training.parquet
```

---

## Future Enhancements

### Data Collection
- [ ] Multi-day time series collection
- [ ] User session context features
- [ ] Database load metrics
- [ ] Result quality scoring

### Labeling
- [ ] Semi-supervised labeling
- [ ] Confidence scores
- [ ] Multi-label support (tier + fallback)
- [ ] Active learning for uncertain patterns

### Features
- [ ] Historical query performance
- [ ] Time-of-day patterns
- [ ] Query result caching effectiveness
- [ ] Cross-tier comparison metrics

---

## Dependencies

### Required
- Python 3.8+
- pandas
- pyarrow

### Optional
- numpy (for advanced analytics)
- scikit-learn (for model training)
- matplotlib (for visualization)

### Install

```bash
pip install pandas pyarrow numpy scikit-learn matplotlib
```

---

## References

- **Tier Router:** `/zones/z07_data_access/tier_router.py`
- **Distributed Tracing:** `/zones/z13_monitoring/distributed_tracing_config.py`
- **Tool Definitions:** `/zones/z07_data_access/tools/*.py`
- **Schema Documentation:** `schema.md`

---

## Support

**Agent:** Agent 4 - Data Collection Engineer
**Zone:** z07_data_access
**Phase:** 2 - ML Router Training Pipeline
**Date:** 2025-12-06

For issues or questions, refer to the task specification:
`.workspace/swarm_tasks/agent-4_task.md`
