# DeMeo Drug Rescue - PGVector Quick Reference

**Status:** ✅ 100% PGVector (v6.0 tables)
**Last Verified:** 2025-12-03

---

## TL;DR

`demeo_drug_rescue.py` uses **ONLY PostgreSQL pgvector embeddings**. Zero file I/O.

---

## PGVector Tables Used

### Gene Embeddings (via UnifiedQueryLayer)
- **ens_gene_64d_v6_0** - ENS gene embeddings (64D)
- **gene_modex_v6_0** - MODEX gene embeddings
- **gene_lincs_v6_0** - LINCS gene embeddings

### Drug Embeddings (via UnifiedQueryLayer)
- **drug_chemical_v6_0_256d** - Chemical drug embeddings (256D)

### Fusion Tables (Direct SQL)
1. **g_aux_cto_topk_v6_0** - Cell type ontology (15% weight)
2. **g_aux_dgp_topk_v6_0** - Disease-gene-phenotype (20% weight)
3. **g_aux_ep_drug_topk_v6_0** - Expression profile (35% weight, CNS-critical)
4. **g_aux_mop_topk_v6_0** - Mechanism of pathology (25% weight)
5. **g_aux_syn_topk_v6_0** - Synonym similarity (5% weight)
6. **d_g_chem_ens_topk_v6_0** - Drug-gene cross-modal fusion

---

## Query Flow

```
User → execute(gene="SCN1A")
  ↓
DeMeoUnifiedAdapter.query_multimodal_embeddings()
  ↓
PostgreSQL pgvector:
  - ens_gene_64d_v6_0 (gene embedding)
  - 5 gene auxiliary fusion tables (similar genes)
  - d_g_chem_ens_topk_v6_0 (drugs for similar genes)
  ↓
Bayesian Fusion + Ranking
  ↓
Top-K drugs returned
```

---

## Verification Commands

```bash
# Static code analysis (AST-based)
python3 zones/z07_data_access/tools/test_demeo_pgvector_only.py

# Integration test
python3 zones/z07_data_access/tools/test_demeo_integration.py

# Expected output:
# ✅ VERIFICATION PASSED - All checks successful!
# ✅ ALL TESTS PASSED
```

---

## Key Code Locations

| Feature | Line(s) | Description |
|---------|---------|-------------|
| Multi-modal query | 207-211 | `query_multimodal_embeddings(version="v6.0")` |
| Fusion tables | 252-257 | List of 5 gene auxiliary tables |
| Fusion weights | 261-267 | CNS-critical EP gets 35% weight |
| SQL queries | 276-306 | Direct PostgreSQL queries (no file I/O) |
| Cross-modal fusion | 322-330 | Drug-gene similarity via `d_g_chem_ens_topk_v6_0` |

---

## What Was Removed

✅ **REMOVED:**
- No `embedding_service` imports
- No `load_gene_space()` calls
- No `load_drug_space()` calls
- No `.parquet`, `.npy`, `.pkl` file references
- No file I/O operations

✅ **REPLACED WITH:**
- UnifiedQueryLayer integration
- Direct PostgreSQL queries
- v6.0 fusion tables
- 100% pgvector embeddings

---

## Environment Variables

```bash
# PostgreSQL connection (defaults: localhost:5435)
PGVECTOR_HOST=localhost
PGVECTOR_PORT=5435
PGVECTOR_DATABASE=sapphire_database
PGVECTOR_USER=postgres
PGVECTOR_PASSWORD=<password>
```

---

## Performance Profile

| Operation | Latency | Source |
|-----------|---------|--------|
| Cache HIT | 10-50ms | Neo4j metagraph |
| Cache MISS | 500-1000ms | PostgreSQL v6.0 |
| Gene multi-modal query | ~100ms | 3 parallel pgvector queries |
| Fusion consensus | ~200ms | 5 parallel SQL queries |
| Drug-gene lookup | ~100ms | 1 SQL query per gene |

---

## Testing

### Quick Smoke Test

```python
import asyncio
from zones.z07_data_access.tools import demeo_drug_rescue

result = asyncio.run(demeo_drug_rescue.execute({
    "gene": "SCN1A",
    "disease": "Dravet Syndrome",
    "top_k": 5,
    "use_cache": False
}))

print(f"Success: {result['success']}")
print(f"Drugs: {result['count']}")
print(f"Spaces: {result['multi_modal']['spaces_found']}")
```

### Expected Output

```json
{
  "success": true,
  "method": "demeo_v2.0_computed",
  "query_time_ms": "650.3",
  "gene": "SCN1A",
  "disease": "Dravet Syndrome",
  "drugs": [...],
  "count": 5,
  "multi_modal": {
    "agreement_coefficient": 0.847,
    "spaces_found": ["modex", "ens", "lincs"]
  }
}
```

---

## Compliance Checklist

- [x] No file-based embedding imports
- [x] No embedding_service references
- [x] All embeddings from PostgreSQL v6.0
- [x] Gene embeddings via `ens_gene_64d_v6_0`
- [x] Drug embeddings via `drug_chemical_v6_0_256d`
- [x] 5 gene auxiliary fusion tables used
- [x] 1 drug-gene cross-modal fusion table used
- [x] UnifiedQueryLayer integration
- [x] Explicit `version='v6.0'` parameter
- [x] Zero file I/O operations

---

## Troubleshooting

### Issue: "No embeddings found for gene X"
**Cause:** Gene not in `ens_gene_64d_v6_0` table
**Fix:** Check gene symbol, try alias (e.g., CDKL5 vs. STK9)

### Issue: "No drug candidates found"
**Cause:** No similar genes in fusion tables
**Fix:** Reduce similarity threshold, check gene expression data

### Issue: "DeMeo modules not available"
**Cause:** Import path issue
**Fix:** Ensure platform root in `sys.path`

---

## References

- **Main File:** `zones/z07_data_access/tools/demeo_drug_rescue.py`
- **Adapter:** `zones/z07_data_access/demeo/unified_adapter.py`
- **Verification:** `zones/z07_data_access/tools/test_demeo_pgvector_only.py`
- **Integration Test:** `zones/z07_data_access/tools/test_demeo_integration.py`
- **Full Report:** `zones/z07_data_access/tools/DEMEO_PGVECTOR_VERIFICATION_REPORT.md`

---

**Last Updated:** 2025-12-03
**Status:** ✅ Production Ready
