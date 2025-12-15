"""
Meta Layer - Modular Query Resolution Architecture
===================================================

The meta layer provides composable, pattern-based resolvers and enhancers
for intelligent query processing in the unified query layer.

Architecture:
- resolvers/   - Entity and name normalization
- classifiers/ - Intent and type detection
- enhancers/   - Query optimization and enrichment

All components inherit from BaseResolver for consistency.

Usage:
    from meta_layer import MetaLayerPipeline

    pipeline = MetaLayerPipeline()
    result = pipeline.process("Find rescue drugs for SCN1A")

Author: Meta Layer Swarm
Date: 2025-12-01
Version: 1.0.0
"""

from .base_resolver import BaseResolver
from .pipeline import MetaLayerPipeline

# Import all resolvers
from .resolvers.fuzzy_entity_matcher import FuzzyEntityMatcher, get_fuzzy_entity_matcher
from .resolvers.drug_name_resolver import DrugNameResolver, get_drug_name_resolver
from .resolvers.target_resolver import TargetResolver, get_target_resolver
from .resolvers.gene_name_resolver import GeneNameResolver, get_gene_name_resolver
from .resolvers.chemical_resolver import ChemicalResolver, get_chemical_resolver
from .resolvers.protein_resolver import ProteinResolver, get_protein_resolver
from .resolvers.pathway_resolver import PathwayResolver, get_pathway_resolver
from .resolvers.disease_resolver import DiseaseResolver, get_disease_resolver
from .resolvers.cellline_resolver import CellLineResolver, get_cellline_resolver
from .resolvers.tissue_resolver import TissueResolver, get_tissue_resolver

# Import all classifiers
from .classifiers.intent_classifier import IntentClassifier, get_intent_classifier

# Import all enhancers
from .enhancers.semantic_query_resolver import SemanticQueryResolver, get_semantic_query_resolver

__version__ = "1.0.0"

__all__ = [
    "BaseResolver",
    "MetaLayerPipeline",
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
    "IntentClassifier",
    "get_intent_classifier",
    "SemanticQueryResolver",
    "get_semantic_query_resolver",
]
