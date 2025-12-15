# PGVector Service v6.0 - Single Source of Truth for Embeddings

**Version:** 2.0.0
**Date:** 2025-12-03
**Purpose:** Replace ALL legacy file-based embedding loading with unified PostgreSQL pgvector access

---

## Overview

The `PGVectorService` provides a unified interface to all v6.0 embeddings stored in PostgreSQL with the pgvector extension.

### Key Features

- **Connection Pooling**: 1-10 concurrent connections with lazy initialization
- **Gene Embeddings**: `ens_gene_64d_v6_0` (18,368 genes, 64D)
- **Drug Embeddings**: `drug_chemical_v6_0_256d` (14,246 drugs, 256D)
- **Precomputed Similarities**: g_aux_* and d_aux_* topk tables (100× speedup)
- **Health Monitoring**: Connection, table counts, and coverage statistics

---

## Quick Start

### 1. Environment Setup

```bash
export POSTGRES_HOST=localhost
export POSTGRES_PORT=5432
export POSTGRES_DB=expo
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=your_password_here
```

### 2. Basic Usage

```python
from zones.z07_data_access.pgvector_service import PGVectorService

# Initialize service (uses connection pooling)
service = PGVectorService()

# Get gene embedding
result = service.get_gene_embedding("SCN1A")
print(f"Dimensions: {result.dimensions}D")  # 64D
print(f"Embedding: {result.embedding}")

# Find similar genes (precomputed)
similar = service.find_similar_genes("SCN1A", top_k=10, fusion_type="ep_gene")
for sim in similar:
    print(f"{sim.entity_id}: {sim.similarity_score:.3f}")

# Get drug embedding
drug_result = service.get_drug_embedding("QS00000001")
print(f"Dimensions: {drug_result.dimensions}D")  # 256D

# Find similar drugs
similar_drugs = service.find_similar_drugs("QS00000001", top_k=10, fusion_type="adr")

# Get embedding statistics
stats = service.get_embedding_stats("ens_gene_64d_v6_0")
print(f"Coverage: {stats.coverage_percent:.1f}%")
print(f"Total entities: {stats.total_entities:,}")

# Always close when done
service.close()
```

### 3. Context Manager Pattern (Recommended)

```python
with PGVectorService() as service:
    result = service.get_gene_embedding("TSC2")
    print(result.embedding.shape)
# Connection automatically closed
```

---

## Available Methods

### Embedding Retrieval

#### `get_gene_embedding(gene_id, table='ens_gene_64d_v6_0')`
Get gene embedding vector.

**Args:**
- `gene_id`: Gene symbol (e.g., "SCN1A")
- `table`: Table name (default: "ens_gene_64d_v6_0")

**Returns:** `EmbeddingResult` with entity_id, embedding, dimensions, source_table

#### `get_drug_embedding(drug_id, table='drug_chemical_v6_0_256d')`
Get drug embedding vector.

**Args:**
- `drug_id`: QS code (e.g., "QS00000001")
- `table`: Table name (default: "drug_chemical_v6_0_256d")

**Returns:** `EmbeddingResult` with entity_id, embedding, dimensions, source_table

### Similarity Search (Precomputed)

#### `find_similar_genes(gene_id, top_k=10, fusion_type='cto')`
Find similar genes using precomputed topk tables.

**Fusion Types:**
- `cto`: Cell Type Ontology (tissue specificity)
- `adr`: Adverse Drug Reactions (safety signals)
- `dgp`: Disease-Gene-Protein (mechanistic links)
- `ep_gene`: Electrophysiology (ion channels, neuronal)
- `mop`: Mechanism of Phenotype (functional effects)
- `syn`: Symptoms/Phenotypes (clinical presentation)

**Returns:** List of `SimilarityResult` objects

#### `find_similar_drugs(drug_id, top_k=10, fusion_type='adr')`
Find similar drugs using precomputed topk tables.

**Fusion Types:**
- `cto`: Cell Type Ontology (tissue targeting)
- `adr`: Adverse Drug Reactions (safety profile)
- `dgp`: Disease-Gene-Protein (mechanism of action)
- `ep_drug`: Electrophysiology (ion channel effects)
- `mop`: Mechanism of Phenotype (functional effects)

**Returns:** List of `SimilarityResult` objects

### Monitoring

#### `get_embedding_stats(table_name)`
Get statistics for an embedding table.

**Returns:** `EmbeddingStats` with total_entities, dimensions, coverage_percent, samples

#### `health_check()`
Check service health and database connectivity.

**Returns:** Dict with status, database info, table counts, connection pool stats

---

## Table Schema

### Gene Embeddings

| Table | Dimensions | Entity Column | Embedding Column | Description |
|-------|-----------|--------------|-----------------|-------------|
| ens_gene_64d_v6_0 | 64 | symbol | embedding | ENS v6.0 Gene Embeddings (18,368 genes) |
| gene_modex_v6_0_embeddings | 16 | symbol | embedding | MODEX v6.0 Gene Embeddings |

### Drug Embeddings

| Table | Dimensions | Entity Column | Embedding Column | Description |
|-------|-----------|--------------|-----------------|-------------|
| drug_chemical_v6_0_256d | 256 | qs_code | embedding | Chemical v6.0 Drug Embeddings (14,246 drugs) |

### Precomputed Similarity Tables

**Gene Auxiliary Tables:** `g_aux_{fusion_type}_topk_v6_0`
- `g_aux_cto_topk_v6_0`
- `g_aux_adr_topk_v6_0`
- `g_aux_dgp_topk_v6_0`
- `g_aux_ep_gene_topk_v6_0`
- `g_aux_mop_topk_v6_0`
- `g_aux_syn_topk_v6_0`

**Drug Auxiliary Tables:** `d_aux_{fusion_type}_topk_v6_0`
- `d_aux_cto_topk_v6_0`
- `d_aux_adr_topk_v6_0`
- `d_aux_dgp_topk_v6_0`
- `d_aux_ep_drug_topk_v6_0`
- `d_aux_mop_topk_v6_0`

**Cross-Modal Tables:**
- `d_g_chem_ens_topk_v6_0` (Drug-Gene fusion)
- `d_d_chem_lincs_topk_v6_0` (Drug-Drug fusion)

---

## Testing

### Command Line Tests

```bash
# Health check
python3.11 zones/z07_data_access/pgvector_service.py --health

# Test gene embedding
python3.11 zones/z07_data_access/pgvector_service.py --gene SCN1A

# Test drug embedding
python3.11 zones/z07_data_access/pgvector_service.py --drug QS00000001

# Show statistics
python3.11 zones/z07_data_access/pgvector_service.py --stats
```

### Python Tests

```python
# Test embedding retrieval
service = PGVectorService()

# Gene embedding
result = service.get_gene_embedding("SCN1A")
assert result is not None
assert result.dimensions == 64
assert result.embedding.shape == (64,)

# Drug embedding
drug_result = service.get_drug_embedding("QS00000001")
assert drug_result is not None
assert drug_result.dimensions == 256

# Similarity search
similar = service.find_similar_genes("SCN1A", top_k=5, fusion_type="ep_gene")
assert len(similar) <= 5
for sim in similar:
    assert 0 <= sim.similarity_score <= 1
    assert sim.rank >= 1

service.close()
```

---

## Prerequisites

### PostgreSQL with pgvector Extension

```sql
-- Install pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Verify installation
SELECT * FROM pg_extension WHERE extname = 'vector';
```

### Python Dependencies

```bash
pip install psycopg2-binary numpy
```

---

## Migration from Legacy Systems

### Before (File-Based)

```python
# OLD: Loading from parquet files
import pandas as pd
gene_df = pd.read_parquet("data/embeddings/MODEX_gene_v1.0_PRODUCTION.parquet")
gene_emb = gene_df[gene_df['entity_name'] == 'SCN1A']['MODEX_00':'MODEX_31'].values[0]
```

### After (PGVector)

```python
# NEW: Loading from PostgreSQL
from zones.z07_data_access.pgvector_service import get_pgvector_service
service = get_pgvector_service()
result = service.get_gene_embedding("SCN1A")
gene_emb = result.embedding  # Direct numpy array
```

**Benefits:**
- **100× faster** (database indexes vs file scans)
- **No memory overhead** (lazy loading vs loading entire files)
- **Consistent state** (single source of truth vs scattered files)
- **Connection pooling** (reuse connections vs reconnect every time)

---

## Error Handling

```python
from zones.z07_data_access.pgvector_service import PGVectorService

try:
    service = PGVectorService()
    result = service.get_gene_embedding("INVALID_GENE")

    if result is None:
        print("Gene not found in database")

except ValueError as e:
    print(f"Configuration error: {e}")

except ConnectionError as e:
    print(f"Database connection failed: {e}")

finally:
    service.close()
```

---

## Performance Tips

1. **Use Connection Pooling**: Reuse service instance instead of creating new ones
2. **Use Precomputed Tables**: `find_similar_genes()` is 100× faster than live queries
3. **Batch Queries**: Fetch multiple embeddings in same connection session
4. **Close Connections**: Always call `service.close()` or use context manager

---

## Troubleshooting

### "POSTGRES_PASSWORD not set in environment"

```bash
export POSTGRES_PASSWORD=your_password_here
```

### "Connection pool exhausted"

Increase max connections:

```python
service = PGVectorService(maxconn=20)
```

### "Table does not exist"

Check that v6.0 tables are loaded:

```bash
python3.11 zones/z07_data_access/pgvector_service.py --health
```

### "pgvector extension not installed"

```sql
CREATE EXTENSION vector;
```

---

## Architecture

```
┌─────────────────────────────────────────────┐
│         PGVectorService (Singleton)         │
│  Single Source of Truth for Embeddings     │
└─────────────────────────────────────────────┘
                    │
                    ├─── Connection Pool (1-10 connections)
                    │
    ┌───────────────┴───────────────┐
    │                               │
    ▼                               ▼
┌────────────────┐          ┌────────────────┐
│ Gene Tables    │          │ Drug Tables    │
├────────────────┤          ├────────────────┤
│ ens_gene_64d   │          │ drug_chem_256d │
│ gene_modex_16d │          └────────────────┘
└────────────────┘
    │
    ├─── Precomputed Similarity Tables
    │
    ▼
┌────────────────────────────────────────────┐
│  g_aux_*_topk_v6_0 (6 fusion types)       │
│  d_aux_*_topk_v6_0 (5 fusion types)       │
│  Cross-modal: d_g_chem_ens_topk_v6_0      │
└────────────────────────────────────────────┘
```

---

## Changelog

### v2.0.0 (2025-12-03)
- **NEW**: v6.0 schema support (ens_gene_64d_v6_0, drug_chemical_v6_0_256d)
- **NEW**: Precomputed similarity tables (g_aux_*, d_aux_*)
- **NEW**: Connection pooling with lazy initialization
- **NEW**: Health check and statistics methods
- **IMPROVED**: Clear error messages with fallback guidance
- **BREAKING**: Renamed `PgVectorService` → `PGVectorService` (alias provided)

### v1.0.0 (2025-11-29)
- Initial release with legacy table support

---

## Support

For issues or questions:
- Check health status: `python3.11 zones/z07_data_access/pgvector_service.py --health`
- Review logs: Service uses Python logging module
- File ticket: Include health check output and error messages
