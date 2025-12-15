# Zone 7: Embedding Operations

**Location:** `quiver_platform/zones/z07_data_access/embeddings/`
**Source:** Migrated from `quiver_common` (archived)
**Version:** 0.1.0

## Components

### EPLoader
Load and manage EP embeddings (ENS/ACT/LAT):
- ENS v4.11, ACT v4.1.4.2, LAT v4.2 embeddings
- Unified interface for all embedding types
- Lazy loading for memory efficiency

### vector_ops
Vector operations and similarity:
- Cosine similarity calculations
- Vector projections
- Batch operations

## Usage

```python
from quiver_platform.zones.z07_data_access.embeddings import EPLoader, vector_ops

# Load embeddings
ep_loader = EPLoader()
ens_embeddings = ep_loader.load_ens()

# Vector operations
similarity = vector_ops.cosine_similarity(vec1, vec2)
```

## Migration Notes

Migrated from `quiver_common` package to zone architecture (2025-11-29).
Original location archived at `.archive/quiver_common/`.
