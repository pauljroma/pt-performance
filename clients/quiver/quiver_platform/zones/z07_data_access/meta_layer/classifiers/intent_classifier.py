"""
Intent Classifier Service
Classifies query intent and routes to correct tool/space combinations.

Capabilities:
1. Intent detection from question patterns
2. Tool/space selection based on intent
3. Query parameter generation
4. Multi-hop query decomposition

Performance: <5ms latency with pattern matching
"""

import re
from typing import Dict, List, Optional, Tuple, Any
from functools import lru_cache
import logging

logger = logging.getLogger(__name__)


class IntentClassifier:
    """
    Classify query intent and route to appropriate tool/space.

    Usage:
        classifier = IntentClassifier()
        intent = classifier.classify("Find rescue candidates for SCN1A")
        # Returns: {'intent': 'gene_to_drug_rescue', 'tool': 'rescue_combinations', ...}
    """

    def __init__(self):
        """Initialize classifier with intent patterns."""

        # Intent patterns (regex → intent)
        self.intent_patterns = [
            # Rescue/repurposing intents
            (r"rescue\s+(?:candidates|drugs|compounds)", "gene_to_drug_rescue"),
            (r"find\s+(?:rescue|repurposing)", "gene_to_drug_rescue"),
            (r"drugs?\s+(?:for|targeting)\s+gene", "gene_to_drug_rescue"),

            # Mechanism intents
            (r"mechanism\s+of\s+action", "mechanism_lookup"),
            (r"how\s+does\s+\w+\s+work", "mechanism_lookup"),
            (r"mode\s+of\s+action", "mechanism_lookup"),
            (r"(?:what\s+)?pathway(?:s)?\s+(?:are\s+)?(?:affected|modulated)", "pathway_analysis"),
            (r"(?:what\s+)?pathway(?:s)?\s+(?:by|for)", "pathway_analysis"),

            # Biomarker intents
            (r"biomarker(?:s)?", "disease_to_biomarker_discovery"),
            (r"find\s+(?:genes|proteins)\s+(?:for|associated)", "disease_to_biomarker_discovery"),
            (r"genetic\s+markers", "disease_to_biomarker_discovery"),

            # Similarity intents (order matters!)
            (r"(?:find\s+)?genes?\s+similar", "gene_similarity"),  # Gene similarity
            (r"drugs?\s+(?:structurally\s+)?similar", "drug_similarity"),  # Drug similarity
            (r"(?:find|search)\s+(?:cns\s+)?drugs?\s+similar", "drug_similarity"),  # Find drugs similar
            (r"similar\s+drugs?", "drug_similarity"),  # similar drugs
            (r"lookalikes?", "drug_similarity"),
            (r"analogs?", "drug_similarity"),

            # Safety/ADME intents
            (r"(?:bbb|blood.brain.barrier)", "bbb_permeability"),
            (r"permeability", "bbb_permeability"),
            (r"(?:adme|toxicity|safety)", "adme_tox"),
            (r"hepatotoxicity", "adme_tox"),
            (r"cardiotoxicity", "adme_tox"),
            (r"adverse\s+(?:events|effects)", "adme_tox"),

            # Interaction intents
            (r"interaction(?:s)?", "drug_interactions"),
            (r"combine\s+with", "drug_combinations"),
            (r"synerg(?:y|istic)", "combination_synergy"),

            # Graph traversal intents
            (r"(?:what|which)\s+genes?\s+does\s+\w+\s+target", "drug_to_gene_targets"),
            (r"target(?:s|ed)?\s+(?:by|genes)", "drug_to_gene_targets"),
            (r"pathway\s+(?:analysis|relationships)", "pathway_traversal"),

            # Semantic search intents
            (r"search\s+for", "semantic_search"),
            (r"find\s+all", "semantic_search"),

            # Property lookup intents
            (r"properties\s+(?:of|for)", "property_lookup"),
            (r"details?\s+(?:of|for|about)", "property_lookup"),
            (r"information\s+(?:on|about)", "property_lookup"),
        ]

        # Intent → tool/space mappings
        self.intent_mappings = {
            # Rescue intents (gene → drug)
            "gene_to_drug_rescue": {
                "tool": "rescue_combinations",
                "primary_space": "lincs_drug_32d_v5_0",
                "fallback_spaces": ["modex_ep_unified_16d_v6_0"],
                "entity_transform": "gene_to_drug",  # Transform gene to drugs
                "query_type": "cross_entity"
            },

            # Mechanism intents (drug → pathways)
            "mechanism_lookup": {
                "tool": "mechanistic_explainer",
                "primary_space": "mop_emb_15d_v5_0",
                "fallback_spaces": ["cto_emb_9d_v5_0"],
                "entity_transform": "drug_to_mechanism",
                "query_type": "lookup"
            },

            # Pathway analysis (drug → pathways)
            "pathway_analysis": {
                "tool": "mechanistic_explainer",
                "primary_space": "mop_emb_15d_v5_0",
                "fallback_spaces": ["cto_emb_9d_v5_0"],
                "entity_transform": "drug_to_pathway",
                "query_type": "traversal"
            },

            # Biomarker discovery (disease → genes)
            "disease_to_biomarker_discovery": {
                "tool": "biomarker_discovery",
                "primary_space": "ens_gene_64d_v6_0",
                "fallback_spaces": ["dgp_emb_12d_v5_0"],
                "entity_transform": "disease_to_genes",
                "query_type": "discovery"
            },

            # Drug similarity
            "drug_similarity": {
                "tool": "vector_neighbors",
                "primary_space": "lincs_drug_32d_v5_0",
                "fallback_spaces": ["modex_ep_unified_16d_v6_0"],
                "entity_transform": None,
                "query_type": "similarity"
            },

            # Gene similarity
            "gene_similarity": {
                "tool": "vector_neighbors",
                "primary_space": "ens_gene_64d_v6_0",
                "fallback_spaces": [],
                "entity_transform": None,
                "query_type": "similarity"
            },

            # BBB permeability
            "bbb_permeability": {
                "tool": "bbb_permeability",
                "primary_space": "modex_ep_unified_16d_v6_0",
                "fallback_spaces": ["lincs_drug_32d_v5_0"],
                "entity_transform": None,
                "query_type": "lookup"
            },

            # ADME/Tox
            "adme_tox": {
                "tool": "adme_tox_predictor",
                "primary_space": "adr_emb_8d_v5_0",
                "fallback_spaces": ["D_D_D_1__EP__MODEX_LINCS__ADR"],
                "entity_transform": None,
                "query_type": "lookup"
            },

            # Drug interactions
            "drug_interactions": {
                "tool": "drug_interactions",
                "primary_space": "modex_ep_unified_16d_v6_0",
                "fallback_spaces": ["adr_emb_8d_v5_0"],
                "entity_transform": None,
                "query_type": "interaction"
            },

            # Combination synergy
            "combination_synergy": {
                "tool": "drug_combinations_synergy",
                "primary_space": "modex_ep_unified_16d_v6_0",
                "fallback_spaces": ["lincs_drug_32d_v5_0"],
                "entity_transform": None,
                "query_type": "synergy"
            },

            # Drug → gene targets
            "drug_to_gene_targets": {
                "tool": "graph_neighbors",
                "primary_space": "neo4j",
                "fallback_spaces": [],
                "entity_transform": "drug_to_genes",
                "query_type": "traversal"
            },

            # Pathway traversal
            "pathway_traversal": {
                "tool": "graph_path",
                "primary_space": "neo4j",
                "fallback_spaces": [],
                "entity_transform": None,
                "query_type": "traversal"
            },

            # Semantic search
            "semantic_search": {
                "tool": "semantic_search",
                "primary_space": "modex_ep_unified_16d_v6_0",
                "fallback_spaces": ["lincs_drug_32d_v5_0"],
                "entity_transform": None,
                "query_type": "search"
            },

            # Property lookup
            "property_lookup": {
                "tool": "drug_properties_detail",
                "primary_space": "modex_ep_unified_16d_v6_0",
                "fallback_spaces": [],
                "entity_transform": None,
                "query_type": "lookup"
            },
        }

        logger.info(f"IntentClassifier initialized: {len(self.intent_patterns)} patterns, "
                   f"{len(self.intent_mappings)} intent mappings")

    @lru_cache(maxsize=1000)
    def classify(self, question: str, category: Optional[str] = None) -> Dict[str, Any]:
        """
        Classify query intent and return routing information.

        Args:
            question: Natural language question
            category: Optional category hint from test suite

        Returns:
            {
                'intent': detected intent name,
                'tool': recommended tool name,
                'primary_space': primary embedding space,
                'fallback_spaces': list of fallback spaces,
                'entity_transform': transformation type (if needed),
                'query_type': type of query,
                'confidence': 0.0-1.0,
                'matched_pattern': regex pattern that matched
            }
        """
        if not question or not isinstance(question, str):
            return self._default_classification()

        question_lower = question.strip().lower()

        # Try pattern matching
        for pattern, intent_name in self.intent_patterns:
            if re.search(pattern, question_lower):
                mapping = self.intent_mappings.get(intent_name)

                if mapping:
                    return {
                        'intent': intent_name,
                        'tool': mapping['tool'],
                        'primary_space': mapping['primary_space'],
                        'fallback_spaces': mapping['fallback_spaces'],
                        'entity_transform': mapping.get('entity_transform'),
                        'query_type': mapping['query_type'],
                        'confidence': 0.90,
                        'matched_pattern': pattern,
                        'category': category
                    }

        # Fallback: Use category hint if provided
        if category:
            return self._classify_by_category(category)

        # Default fallback
        return self._default_classification()

    def _classify_by_category(self, category: str) -> Dict[str, Any]:
        """Classify based on category hint."""

        category_mappings = {
            "bbb_permeability": "bbb_permeability",
            "adme_tox": "adme_tox",
            "drug_similarity": "drug_similarity",
            "gene_similarity": "gene_similarity",
            "rescue": "gene_to_drug_rescue",
            "mechanism": "mechanism_lookup",
            "biomarker": "disease_to_biomarker_discovery",
            "drug_interactions": "drug_interactions",
            "pathway_analysis": "pathway_analysis",
            "combination_synergy": "combination_synergy",
        }

        intent_name = category_mappings.get(category)

        if intent_name and intent_name in self.intent_mappings:
            mapping = self.intent_mappings[intent_name]

            return {
                'intent': intent_name,
                'tool': mapping['tool'],
                'primary_space': mapping['primary_space'],
                'fallback_spaces': mapping['fallback_spaces'],
                'entity_transform': mapping.get('entity_transform'),
                'query_type': mapping['query_type'],
                'confidence': 0.75,
                'matched_pattern': f"category:{category}",
                'category': category
            }

        return self._default_classification()

    def _default_classification(self) -> Dict[str, Any]:
        """Return default classification for unknown intents."""
        return {
            'intent': 'unknown',
            'tool': 'vector_neighbors',
            'primary_space': 'modex_ep_unified_16d_v6_0',
            'fallback_spaces': ['lincs_drug_32d_v5_0'],
            'entity_transform': None,
            'query_type': 'similarity',
            'confidence': 0.50,
            'matched_pattern': None,
            'category': None
        }

    def suggest_query_params(self,
                            intent_result: Dict[str, Any],
                            entity: str,
                            entity_type: str) -> Dict[str, Any]:
        """
        Suggest query parameters based on intent and entity.

        Args:
            intent_result: Result from classify()
            entity: Entity name
            entity_type: Entity type

        Returns:
            Query parameters optimized for the intent
        """
        base_params = {
            "entity_name": entity,
            "entity_type": entity_type,
            "k": 20
        }

        # Adjust parameters based on query type
        query_type = intent_result.get('query_type', 'similarity')

        if query_type == 'cross_entity':
            # Gene → drug rescue
            base_params["cross_entity_search"] = True
            base_params["k"] = 50  # More results for rescue

        elif query_type == 'discovery':
            # Disease → biomarker discovery
            base_params["discovery_mode"] = True
            base_params["k"] = 100  # Many biomarkers

        elif query_type == 'traversal':
            # Graph traversal
            base_params["include_graph"] = True
            base_params["max_hops"] = 2

        elif query_type == 'interaction':
            # Drug-drug interactions
            base_params["interaction_check"] = True

        elif query_type == 'synergy':
            # Combination synergy
            base_params["synergy_score"] = True

        return base_params

    def get_stats(self) -> Dict[str, int]:
        """Return statistics about classifier."""
        return {
            'intent_patterns': len(self.intent_patterns),
            'intent_mappings': len(self.intent_mappings),
            'cache_size': self.classify.cache_info().currsize,
            'cache_hits': self.classify.cache_info().hits,
            'cache_misses': self.classify.cache_info().misses
        }


# Singleton instance for global use
_classifier_instance = None


def get_intent_classifier() -> IntentClassifier:
    """
    Get singleton IntentClassifier instance.

    Usage:
        classifier = get_intent_classifier()
        intent = classifier.classify("Find rescue drugs for SCN1A")
    """
    global _classifier_instance
    if _classifier_instance is None:
        _classifier_instance = IntentClassifier()
    return _classifier_instance
