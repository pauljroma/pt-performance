# Zone 7: Rust Data Access Layer

**Location:** `quiver_platform/zones/z07_data_access/rust/`
**Source:** Migrated from `clients/quiver/rust/`
**Language:** Rust (PyO3 Python bindings)
**Purpose:** High-performance similarity search and data access

## Components

### lincs_similarity/
High-performance LINCS similarity engine:
- Parallel cosine similarity computation
- Optimized for large-scale signature comparison
- PyO3 bindings for Python integration

### gene_similarity/
Gene similarity calculations:
- Fast pairwise gene similarity
- Embedding-based similarity search
- Optimized for large gene sets

## Performance

Both engines provide **10-100x speedup** over pure Python implementations through:
- Parallel processing (Rayon)
- Memory-efficient algorithms
- SIMD optimizations
- LTO compilation

## Build

```bash
# Build both engines
cd zones/z07_data_access/rust/lincs_similarity && maturin develop --release
cd zones/z07_data_access/rust/gene_similarity && maturin develop --release
```

## Usage

```python
import lincs_similarity_engine
import gene_similarity_rust

# LINCS similarity
scores = lincs_similarity_engine.compute_similarity(query, database)

# Gene similarity
gene_scores = gene_similarity_rust.compute_gene_similarity(genes)
```

## Migration

Migrated from `clients/quiver/rust/` to zone architecture (2025-11-29).
