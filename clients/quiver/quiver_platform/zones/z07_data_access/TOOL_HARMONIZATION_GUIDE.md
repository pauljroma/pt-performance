# Tool Harmonization Guide - Sapphire v4.0 Stream 1

## Overview

All 27 Sapphire tools are being enhanced with identifier harmonization and validation to accept multiple ID formats. This allows users to query with any identifier type (drug name, ChEMBL ID, RxNorm ID, LINCS ID, gene symbol, Entrez ID, etc.) and the tools automatically convert to the correct format.

**Date:** 2025-11-29
**Stream:** 1 (Foundation & Infrastructure)
**Status:** In Progress

---

## Harmonization Pattern

### 1. Import Utilities (Top of Tool File)

```python
# Import harmonization utilities (Stream 1: Foundation)
try:
    from tool_utils import harmonize_gene_id, harmonize_drug_id, validate_input, normalize_gene_symbol
    HARMONIZATION_AVAILABLE = True
except ImportError:
    HARMONIZATION_AVAILABLE = False
```

### 2. Update Tool Description

For tools accepting gene identifiers:
```python
"gene": {
    "type": "string",
    "description": "Gene identifier in any format: HGNC symbol (TP53), Entrez ID (7157), or UniProt ID (P04637). Case-insensitive for symbols."
}
```

For tools accepting drug identifiers:
```python
"drug": {
    "type": "string",
    "description": "Drug identifier in any format: ChEMBL ID (CHEMBL1234), RxNorm ID (1234567), LINCS ID (BRD-K12345678), or drug name (Aspirin)."
}
```

### 3. Add Harmonization in Execute Function

#### For Gene Tools:

```python
async def execute(tool_input: Dict[str, Any]) -> Dict[str, Any]:
    gene = tool_input.get("gene", "").strip()

    # STREAM 1: Identifier harmonization
    if HARMONIZATION_AVAILABLE:
        harmonized = harmonize_gene_id(gene)
        if harmonized["success"] and harmonized["hgnc_symbol"]:
            gene_normalized = harmonized["hgnc_symbol"]
            harmonization_note = f"Harmonized {harmonized['id_type_detected']} → HGNC"
        else:
            gene_normalized = normalize_gene_symbol(gene)
            harmonization_note = None
    else:
        gene_normalized = gene.upper().strip()
        harmonization_note = None

    # Use gene_normalized for queries...
```

#### For Drug Tools:

```python
async def execute(tool_input: Dict[str, Any]) -> Dict[str, Any]:
    drug = tool_input.get("drug", "").strip()

    # STREAM 1: Identifier harmonization
    if HARMONIZATION_AVAILABLE:
        harmonized = harmonize_drug_id(drug)
        if harmonized["success"]:
            # Use the appropriate ID for your tool's backend
            drug_chembl_id = harmonized.get("chembl_id")
            drug_rxnorm_id = harmonized.get("rxnorm_id")
            drug_lincs_ids = harmonized.get("lincs_pert_ids", [])
            harmonization_note = f"Harmonized {harmonized['id_type_detected']}"
        else:
            harmonization_note = None
    else:
        harmonization_note = None

    # Use harmonized IDs for queries...
```

### 4. Return Harmonization Info

```python
result_dict = {
    "success": True,
    # ... other fields ...
}

# Add harmonization note if applicable
if harmonization_note:
    result_dict["harmonization"] = harmonization_note

return result_dict
```

---

## Tool Classification

### Tools Requiring Gene Harmonization (9 tools)

1. ✅ **vector_antipodal** - COMPLETED (reference implementation)
   - Accepts: HGNC symbol, Entrez ID, UniProt ID
   - Backend: Neo4j (uses HGNC symbols)

2. **vector_neighbors**
   - Accepts: HGNC symbol, Entrez ID
   - Backend: Neo4j (uses HGNC symbols)

3. **graph_neighbors**
   - Accepts: HGNC symbol, Entrez ID
   - Backend: Neo4j (uses HGNC symbols)

4. **graph_path**
   - Accepts: source/target genes (HGNC, Entrez, UniProt)
   - Backend: Neo4j (uses HGNC symbols)

5. **graph_subgraph**
   - Accepts: gene_list (HGNC, Entrez IDs)
   - Backend: Neo4j (uses HGNC symbols)

6. **transcriptomic_rescue**
   - Accepts: HGNC symbol, Entrez ID
   - Backend: Neo4j + PostgreSQL

7. **provenance_discovery**
   - Accepts: entity names (genes/drugs)
   - Backend: Neo4j

8. **entity_metadata**
   - Accepts: entity_id (gene/drug)
   - Backend: Neo4j

9. **lincs_expression_detail**
   - Accepts: gene_symbol
   - Backend: PostgreSQL

### Tools Requiring Drug Harmonization (8 tools)

10. **drug_interactions**
    - Accepts: drug_name, ChEMBL ID, RxNorm ID
    - Backend: Neo4j

11. **drug_lookalikes**
    - Accepts: drug_name, ChEMBL ID
    - Backend: Neo4j

12. **drug_combinations_synergy**
    - Accepts: drug1, drug2 (ChEMBL IDs, RxNorm IDs, names)
    - Backend: Neo4j

13. **rescue_combinations**
    - Accepts: gene, drug lists
    - Backend: Neo4j

14. **drug_properties_detail**
    - Accepts: drug_name, ChEMBL ID
    - Backend: PostgreSQL (ChEMBL database)

15. **vector_similarity** (drug-drug similarity)
    - Accepts: drug1, drug2
    - Backend: Neo4j

16. **semantic_search** (can search drugs)
    - Accepts: query (flexible)
    - Backend: Neo4j + ChromaDB

17. **lincs_expression_detail** (also accepts drug)
    - Accepts: pert_id (LINCS ID)
    - Backend: PostgreSQL

### Tools Not Requiring Harmonization (10 tools)

18. **vector_dimensions** - Returns metadata only
19. **semantic_collections** - Collection listing
20. **count_entities** - Count queries
21. **execute_cypher** - Raw Cypher (user responsibility)
22. **graph_properties** - Property metadata
23. **read_parquet_filter** - File reading utility
24. **session_analytics** - Session data
25. **available_spaces** - Metadata listing
26. **literature_search_agent** - Service integration (text queries)
27. **biomarker_discovery** - Service integration (text queries)
28. **literature_evidence** - Service integration (text queries)

---

## Implementation Priority

### Phase 1: Critical Gene Tools (2 days)
- ✅ vector_antipodal (DONE - reference)
- vector_neighbors
- transcriptomic_rescue
- graph_neighbors

### Phase 2: Critical Drug Tools (2 days)
- drug_properties_detail
- drug_interactions
- drug_lookalikes
- rescue_combinations

### Phase 3: Advanced Graph Tools (1 day)
- graph_path
- graph_subgraph
- drug_combinations_synergy

### Phase 4: Utility & Detail Tools (1 day)
- entity_metadata
- provenance_discovery
- lincs_expression_detail
- vector_similarity
- semantic_search

---

## Validation Standards

### Required Validation for All Tools

1. **Input Validation**
   - Non-empty strings
   - Valid ID formats (using validation.py)
   - Numeric ranges where applicable

2. **Error Messages**
   - Clear, actionable error messages
   - Suggest correct formats
   - Provide examples

3. **Response Format**
   - Always include "success": bool
   - Include "harmonization" field when ID conversion occurred
   - Include "error" field with details on failure

---

## Testing Protocol

### Unit Tests per Tool

```python
# Test 1: HGNC symbol input
result = await execute({"gene": "TP53"})
assert result["success"] == True
assert result["gene"] == "TP53"

# Test 2: Entrez ID input (with harmonization)
result = await execute({"gene": "7157"})  # TP53 Entrez ID
assert result["success"] == True
assert result["gene"] == "TP53"
assert "harmonization" in result
assert "entrez" in result["harmonization"].lower()

# Test 3: Invalid input
result = await execute({"gene": "INVALID_GENE_99999"})
assert result["success"] == False
assert "error" in result
```

### Integration Tests

- Test with multiple ID formats per tool
- Verify harmonization note appears in response
- Verify backend queries use correct ID format
- Verify error handling for invalid IDs

---

## Performance Considerations

1. **LRU Caching**: DrugHarmonizer and GeneHarmonizer use `@lru_cache` for 10,000 entries
2. **Singleton Pattern**: Harmonizers initialized once, reused across all tools
3. **Lazy Initialization**: Harmonization only occurs if needed (fallback to original input)
4. **API Fallback**: Local CSV caches used first, REST APIs as fallback

---

## Dependencies

### Required Files
- `zones/z07_data_access/tool_utils.py` ← NEW (harmonization utilities)
- `zones/z10c_utility/identifiers/drug_harmonizer.py` ← EXISTS
- `zones/z10c_utility/identifiers/gene_harmonizer.py` ← EXISTS
- `zones/z10c_utility/utils/validation.py` ← EXISTS

### Required Data Files
- `data/mappings/chembl_lincs_map.csv` - ChEMBL↔LINCS mappings
- `data/mappings/hgnc_cache.csv` - HGNC↔Entrez↔UniProt mappings
- `data/mappings/string_gene_map.csv` - STRING↔HGNC mappings

### Required Services
- PostgreSQL (quiver_platform_db) - RxNorm↔ChEMBL mappings via OMOP
- Neo4j - Graph queries with standardized IDs
- Internet connectivity - Fallback APIs (HGNC, MyGene.info, UniProt)

---

## Completion Criteria

### Stream 1.1: Identifier Harmonization ✅

- ✅ tool_utils.py created with harmonization functions
- ✅ Reference implementation (vector_antipodal) complete
- ⏳ 16 additional tools updated (17 total requiring harmonization)
- ⏳ All tools tested with multiple ID formats
- ⏳ Documentation complete
- ⏳ Integration tests passing

### Stream 1.2: Validation Framework

- Add input validation to all 27 tools
- Standard error message format
- Validation test coverage

---

## Next Steps

1. **Immediate**: Update vector_neighbors (next gene tool)
2. **Day 1**: Complete Phase 1 (4 critical gene tools)
3. **Day 2**: Complete Phase 2 (4 critical drug tools)
4. **Day 3-4**: Complete Phases 3-4 (remaining 9 tools)
5. **Day 5**: Integration testing and validation

---

## Example: Complete Harmonization in vector_antipodal

See: `zones/z07_data_access/tools/vector_antipodal.py:183-198`

This reference implementation shows:
- Graceful fallback (if harmonization unavailable)
- Multiple ID format support (HGNC, Entrez, UniProt)
- Harmonization note in response
- Backward compatibility (works with or without tool_utils)

---

## Support

For questions or issues with harmonization:
1. Check tool_utils.py for available functions
2. Review vector_antipodal.py as reference
3. Test with validation.py functions first
4. Check harmonizer logs for mapping issues
