# Resolver Architecture Proposal for MOA Expansion
**Zone:** z07_data_access
**Date:** 2025-12-01
**Purpose:** Unified resolver services for multi-modal drug prediction expansion

---

## Overview

Resolvers provide fast, cached, bidirectional identifier mapping across biological entities. Critical for MOA expansion where we need to bridge multiple identifier spaces (drug names, CHEMBL IDs, gene symbols, pathways, etc.).

### Architectural Principles

1. **Zone Compliance**: All resolvers in z07_data_access (data access layer)
2. **Backward Compatibility**: Never break existing APIs
3. **Bidirectional**: Both forward (ID → name) and reverse (name → ID) lookups
4. **Performance**: <10ms with LRU caching (20K entries)
5. **Signal Preservation**: Always return original ID if no match found
6. **Multi-Source**: Cascade through data sources by quality/confidence

---

## ✅ IMPLEMENTED: DrugNameResolverV21

### What It Does
- **Forward**: QS code / BRD code / Drug name → Commercial name + CHEMBL ID
- **Reverse**: CHEMBL ID → Drug name, Drug name → CHEMBL ID
- **Sources**: Priority drugs (2K), Metadata (14K), PLATINUM index (2.3K), LINCS (51K), Neo4j fallback

### New Features (v2.1)
```python
resolver = get_drug_name_resolver_v21()

# v2.0 methods (preserved)
info = resolver.resolve("QS0318588")  # → {"commercial_name": "Rapamycin", ...}

# v2.1 methods (new for MOA expansion)
drug_name = resolver.resolve_by_chembl("CHEMBL113")     # → "Caffeine"
chembl_id = resolver.resolve_by_drug_name("Caffeine")  # → "CHEMBL113"
```

### Use Case: BBB Prediction with MOA Expansion
1. K-NN returns drug name: "Pilocarpine"
2. Resolve to CHEMBL: `resolve_by_drug_name("Pilocarpine")` → "CHEMBL550"
3. Query Neo4j for targets of CHEMBL550
4. Find MOA-similar drugs with shared targets
5. Resolve back to drug names for display

---

## 🎯 PRIORITY 1: GeneNameResolver

### Purpose
Resolve gene identifiers across naming systems (HGNC, Entrez, Ensembl, UniProt)

### Critical for MOA Expansion
- Neo4j Drug-Gene TARGETS relationships use various gene identifier types
- Need to normalize gene symbols for cross-database queries
- Enable gene-centric MOA similarity (shared targets)

### API Design
```python
resolver = GeneNameResolver()

# Forward lookups
gene_info = resolver.resolve("TP53")
# Returns: {
#     "hgnc_symbol": "TP53",
#     "entrez_id": "7157",
#     "ensembl_id": "ENSG00000141510",
#     "uniprot_id": "P04637",
#     "gene_name": "Tumor protein p53",
#     "aliases": ["P53", "TRP53"],
#     "confidence": "high",
#     "source": "hgnc_cache"
# }

# Reverse lookups
hgnc_symbol = resolver.resolve_by_entrez("7157")       # → "TP53"
hgnc_symbol = resolver.resolve_by_ensembl("ENSG00000141510")  # → "TP53"
hgnc_symbol = resolver.resolve_by_uniprot("P04637")    # → "TP53"

# Bulk resolve
gene_map = resolver.bulk_resolve(["TP53", "EGFR", "BRCA1"])
```

### Data Sources (4-tier cascade)
1. **HGNC cache** (9,886 genes, 98.3% with UniProt) - `/data/mappings/hgnc_cache.csv`
2. **STRING gene map** (19,275 proteins) - `/data/mappings/string_gene_map.csv`
3. **MyGene.info API** (real-time fallback, rate-limited)
4. **Neo4j Gene nodes** (live database)

### Implementation Priority
**HIGH** - Required for Phase 5A MOA expansion. Without this, we can't normalize gene targets across CHEMBL, STRING, Neo4j.

---

## 🎯 PRIORITY 2: PathwayResolver

### Purpose
Resolve pathway identifiers and get member genes

### Critical for MOA Expansion
- Find drugs targeting same pathways (higher-level MOA similarity)
- Expand drug similarity beyond direct target overlap
- Enable pathway-centric predictions

### API Design
```python
resolver = PathwayResolver()

# Forward lookups
pathway_info = resolver.resolve("R-HSA-109581")  # Reactome ID
# Returns: {
#     "pathway_id": "R-HSA-109581",
#     "pathway_name": "Apoptosis",
#     "database": "Reactome",
#     "member_genes": ["TP53", "CASP3", "CASP8", ...],
#     "gene_count": 163,
#     "confidence": "high"
# }

# Reverse lookups
pathways = resolver.pathways_for_gene("TP53")
# Returns: [
#     {"pathway_id": "R-HSA-109581", "pathway_name": "Apoptosis", "database": "Reactome"},
#     {"pathway_id": "hsa04115", "pathway_name": "p53 signaling pathway", "database": "KEGG"},
#     ...
# ]

# Find drugs targeting pathway
drugs_in_pathway = resolver.drugs_targeting_pathway("R-HSA-109581")
# Returns: [{"drug_name": "Doxorubicin", "chembl_id": "CHEMBL53463"}, ...]
```

### Data Sources (3-tier cascade)
1. **Reactome** (2,712 pathways, 11,186 genes)
2. **KEGG pathways** (via REST API)
3. **Neo4j Pathway nodes** (live database with Drug-Pathway edges)

### Implementation Priority
**MEDIUM-HIGH** - Nice-to-have for Phase 5A, essential for Phase 5B. Adds 10-15% more MOA matches.

---

## 🎯 PRIORITY 3: ProteinResolver

### Purpose
Resolve protein identifiers (UniProt, STRING, PDB)

### Critical for MOA Expansion
- Bridge between gene targets and protein structures
- Enable protein-protein interaction (PPI) network similarity
- Link drugs via shared protein targets

### API Design
```python
resolver = ProteinResolver()

# Forward lookups
protein_info = resolver.resolve("P04637")  # UniProt ID
# Returns: {
#     "uniprot_id": "P04637",
#     "protein_name": "Cellular tumor antigen p53",
#     "gene_symbol": "TP53",
#     "string_id": "9606.ENSP00000269305",
#     "pdb_ids": ["1TUP", "2OCJ", "3KMD", ...],
#     "confidence": "high"
# }

# Reverse lookups
uniprot_id = resolver.resolve_by_string("9606.ENSP00000269305")  # → "P04637"
uniprot_ids = resolver.resolve_by_gene_symbol("TP53")  # → ["P04637", "P04637-2"]

# Interaction partners
partners = resolver.get_interaction_partners("P04637", min_score=0.7)
# Returns: [
#     {"partner_uniprot": "Q00987", "partner_gene": "MDM2", "interaction_score": 0.999},
#     ...
# ]
```

### Data Sources (3-tier cascade)
1. **STRING gene map** (19,275 proteins) - `/data/mappings/string_gene_map.csv`
2. **UniProt REST API** (real-time, comprehensive)
3. **Neo4j Protein nodes** (with STRING_INTERACTS relationships)

### Implementation Priority
**MEDIUM** - Useful for Phase 5C advanced MOA. Adds protein network context.

---

## 🎯 PRIORITY 4: DiseaseResolver

### Purpose
Resolve disease identifiers and find associated genes/drugs

### Critical for Therapeutic Area Filtering
- Filter MOA expansions by disease relevance
- Find drugs approved for similar indications
- Enable indication-aware predictions

### API Design
```python
resolver = DiseaseResolver()

# Forward lookups
disease_info = resolver.resolve("DOID:1936")  # Disease Ontology ID
# Returns: {
#     "disease_id": "DOID:1936",
#     "disease_name": "Atherosclerosis",
#     "mesh_id": "D050197",
#     "icd10_codes": ["I70", "I70.0", "I70.1"],
#     "associated_genes": ["APOE", "LDLR", "APOA1", ...],
#     "approved_drugs": [{"drug_name": "Atorvastatin", "chembl_id": "CHEMBL1487"}, ...],
#     "confidence": "high"
# }

# Reverse lookups
diseases = resolver.diseases_for_gene("APOE")
diseases = resolver.diseases_for_drug("CHEMBL1487")  # Atorvastatin

# Find drugs for indication
drugs = resolver.drugs_for_disease("DOID:1936")  # Atherosclerosis drugs
```

### Data Sources (3-tier cascade)
1. **Disease Ontology** (local cache)
2. **Neo4j Disease nodes** (with Drug-Disease edges)
3. **OpenTargets API** (real-time, comprehensive gene-disease associations)

### Implementation Priority
**LOW-MEDIUM** - Nice-to-have for Phase 5C. Adds clinical context.

---

## Implementation Roadmap

### Phase 5A (Week 1) - MOA Expansion Foundation
**Goal:** Enable basic MOA expansion for BBB predictions

✅ **DrugNameResolverV21** (DONE)
- Bidirectional drug name ↔ CHEMBL ID mappings
- PLATINUM index integration (2,327 EP drugs)
- File: `drug_name_resolver_v2_1.py`

🎯 **GeneNameResolver** (PRIORITY 1)
- Implement HGNC/Entrez/Ensembl/UniProt resolution
- Use existing HGNC cache (9,886 genes)
- File: `gene_name_resolver.py`

**Expected Impact:**
- Drug resolver: Enables CHEMBL ↔ drug name bridging for BBB dataset
- Gene resolver: Enables target normalization for MOA queries
- Combined: 40-50% coverage improvement (5% → 45-50%)

---

### Phase 5B (Week 2) - Pathway Expansion
**Goal:** Add pathway-level MOA similarity

🎯 **PathwayResolver** (PRIORITY 2)
- Implement Reactome/KEGG pathway resolution
- Build pathway → gene member mapping
- File: `pathway_resolver.py`

**Expected Impact:**
- Additional 10-15% coverage (45-50% → 60-65%)
- Find drugs via shared pathways (not just direct targets)

---

### Phase 5C (Week 3) - Advanced Context
**Goal:** Add protein network and disease context

🎯 **ProteinResolver** (PRIORITY 3)
- Implement UniProt/STRING protein resolution
- Add PPI network queries
- File: `protein_resolver.py`

🎯 **DiseaseResolver** (PRIORITY 4)
- Implement disease ontology resolution
- Add indication-aware filtering
- File: `disease_resolver.py`

**Expected Impact:**
- Additional 10-15% coverage (60-65% → 75-80%)
- Clinical context for predictions

---

## Resolver Factory Pattern

For consistency, all resolvers should follow this pattern:

```python
# File: z07_data_access/resolver_factory.py

from typing import Literal

ResolverType = Literal['drug', 'gene', 'pathway', 'protein', 'disease']

def get_resolver(resolver_type: ResolverType, enable_neo4j: bool = False):
    """
    Factory function to get any resolver by type.

    Args:
        resolver_type: Type of resolver ('drug', 'gene', 'pathway', etc.)
        enable_neo4j: Enable Neo4j fallback for live lookups

    Returns:
        Resolver instance (singleton)

    Example:
        drug_resolver = get_resolver('drug')
        gene_resolver = get_resolver('gene', enable_neo4j=True)
    """
    if resolver_type == 'drug':
        from drug_name_resolver_v2_1 import get_drug_name_resolver_v21
        return get_drug_name_resolver_v21(enable_neo4j_fallback=enable_neo4j)
    elif resolver_type == 'gene':
        from gene_name_resolver import get_gene_name_resolver
        return get_gene_name_resolver(enable_neo4j_fallback=enable_neo4j)
    elif resolver_type == 'pathway':
        from pathway_resolver import get_pathway_resolver
        return get_pathway_resolver(enable_neo4j_fallback=enable_neo4j)
    elif resolver_type == 'protein':
        from protein_resolver import get_protein_resolver
        return get_protein_resolver(enable_neo4j_fallback=enable_neo4j)
    elif resolver_type == 'disease':
        from disease_resolver import get_disease_resolver
        return get_disease_resolver(enable_neo4j_fallback=enable_neo4j)
    else:
        raise ValueError(f"Unknown resolver type: {resolver_type}")
```

---

## Testing Strategy

Each resolver should have:
1. **Unit tests**: Test all forward/reverse lookups with known entities
2. **Integration tests**: Test Neo4j fallback, cache behavior
3. **Performance tests**: Verify <10ms latency, cache hit rates >90%
4. **Coverage tests**: Measure % of entities successfully resolved

Example test file: `test_gene_name_resolver.py`
```python
def test_gene_resolver_forward():
    resolver = GeneNameResolver()
    info = resolver.resolve("TP53")
    assert info['entrez_id'] == "7157"
    assert info['uniprot_id'] == "P04637"

def test_gene_resolver_reverse():
    resolver = GeneNameResolver()
    assert resolver.resolve_by_entrez("7157") == "TP53"
    assert resolver.resolve_by_uniprot("P04637") == "TP53"

def test_gene_resolver_performance():
    resolver = GeneNameResolver()
    import time
    start = time.time()
    resolver.resolve("TP53")  # First call (cache miss)
    resolver.resolve("TP53")  # Second call (cache hit)
    end = time.time()
    assert (end - start) < 0.01  # <10ms total for 2 calls
```

---

## Benefits of This Architecture

1. **Consistency**: All resolvers follow same API pattern
2. **Performance**: Cached, optimized for <10ms latency
3. **Maintainability**: Each resolver is independent, zone-compliant
4. **Extensibility**: Easy to add new resolvers (e.g., CellLineResolver, TissueResolver)
5. **Quality**: Multi-source cascade with confidence scoring
6. **Backward Compatibility**: Never breaks existing code

---

## Next Steps

**Immediate (Today):**
1. ✅ DrugNameResolverV21 implemented
2. Review this proposal with team
3. Prioritize: Do we need GeneNameResolver immediately or can it wait?

**This Week:**
1. Implement GeneNameResolver (if approved)
2. Test integration with MOA expansion service
3. Measure coverage improvement (should hit 40-50%)

**Next Week:**
1. Implement PathwayResolver (if Phase 5A successful)
2. Target 60-65% coverage
3. Generate validation report

---

**Status:** PROPOSAL READY FOR REVIEW
**Recommended Action:** Approve GeneNameResolver for immediate implementation (Phase 5A)
