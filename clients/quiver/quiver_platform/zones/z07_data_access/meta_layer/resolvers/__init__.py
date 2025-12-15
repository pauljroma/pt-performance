"""
Resolvers - Entity and Name Normalization
==========================================

Resolvers normalize entity names across different databases and naming conventions.

Available Resolvers:
- FuzzyEntityMatcher   - Fuzzy matching with typos, synonyms, categories
- DrugNameResolver     - Drug ID normalization (QS, CHEMBL, BRD)
- TargetResolver       - Gene/protein name normalization (basic)
- GeneNameResolver     - Comprehensive gene normalization (HGNC, Entrez, UniProt) [NEW]
- ChemicalResolver     - SMILES/InChI chemical structure resolution [NEW]
- ProteinResolver      - UniProt/STRING protein resolution [NEW]
- PathwayResolver      - Reactome/KEGG pathway resolution [NEW]
- DiseaseResolver      - Disease ontology resolution [NEW]
- CellLineResolver     - Cell line identifier resolution [NEW]
- TissueResolver       - Tissue/organ identifier resolution [NEW]
"""

from .fuzzy_entity_matcher import FuzzyEntityMatcher, get_fuzzy_entity_matcher
from .drug_name_resolver import DrugNameResolver, get_drug_name_resolver
from .target_resolver import TargetResolver, get_target_resolver

# MIGRATION TO V3.0: Use gene_name_resolver_v3 for 60x performance improvement
# The v3 resolver queries master tables instead of loading CSVs into memory
from zones.z07_data_access.gene_name_resolver_v3 import (
    GeneNameResolverV3 as GeneNameResolver,
    get_gene_name_resolver_v3 as get_gene_name_resolver
)

from .chemical_resolver import ChemicalResolver, get_chemical_resolver
from .protein_resolver import ProteinResolver, get_protein_resolver
from .pathway_resolver import PathwayResolver, get_pathway_resolver
from .disease_resolver import DiseaseResolver, get_disease_resolver
from .cellline_resolver import CellLineResolver, get_cellline_resolver
from .tissue_resolver import TissueResolver, get_tissue_resolver

__all__ = [
    "FuzzyEntityMatcher",
    "get_fuzzy_entity_matcher",
    "DrugNameResolver",
    "get_drug_name_resolver",
    "TargetResolver",
    "get_target_resolver",
    "GeneNameResolver",
    "get_gene_name_resolver",
    "ChemicalResolver",
    "get_chemical_resolver",
    "ProteinResolver",
    "get_protein_resolver",
    "PathwayResolver",
    "get_pathway_resolver",
    "DiseaseResolver",
    "get_disease_resolver",
    "CellLineResolver",
    "get_cellline_resolver",
    "TissueResolver",
    "get_tissue_resolver",
]
