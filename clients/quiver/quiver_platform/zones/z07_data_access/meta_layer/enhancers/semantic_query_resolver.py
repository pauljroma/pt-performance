"""
SemanticQueryResolver - Vague to Structured Query Conversion
=============================================================

Converts vague natural language questions into structured queries
with proper entity types and relationships.

Capabilities:
- Gene → drug rescue mapping (SCN1A → rescue drugs)
- Drug → mechanism mapping (gabapentin → mechanism of action)
- Disease → biomarker mapping (epilepsy → biomarker genes)
- Query template generation
- Entity relationship detection

Performance: <10ms latency

Author: Meta Layer Swarm - Agent 8
Date: 2025-12-01
Version: 1.0.0
"""

import re
import time
from typing import Dict, List, Optional, Any

from ..base_resolver import BaseResolver


class SemanticQueryResolver(BaseResolver):
    """
    Convert vague questions to structured queries.

    Usage:
        resolver = SemanticQueryResolver()
        result = resolver.resolve(
            "Find rescue drugs for SCN1A",
            entities=[{'entity': 'SCN1A', 'type': 'gene'}]
        )
    """

    def _initialize(self):
        """Initialize with query templates."""
        # Query templates for different intent patterns
        self.templates = {
            # Gene → Drug rescue
            "gene_to_drug_rescue": {
                "pattern": r"rescue|repurpos",
                "entity_from": "gene",
                "entity_to": "drug",
                "relationship": "modulates",
                "query_type": "cross_entity_search",
                "params": {"k": 50, "cross_entity": True}
            },

            # Drug → Mechanism
            "drug_to_mechanism": {
                "pattern": r"mechanism|mode of action|how .* work",
                "entity_from": "drug",
                "entity_to": "pathway",
                "relationship": "affects",
                "query_type": "graph_traversal",
                "params": {"cross_entity": True, "include_graph": True, "max_hops": 2}
            },

            # Disease → Biomarker
            "disease_to_biomarker": {
                "pattern": r"biomarker|genetic marker|gene.* for",
                "entity_from": "disease",
                "entity_to": "gene",
                "relationship": "associated_with",
                "query_type": "discovery",
                "params": {"cross_entity": True, "k": 100, "discovery_mode": True}
            },

            # Drug → Safety/ADME
            "drug_to_safety": {
                "pattern": r"safety|toxic|adverse|adme",
                "entity_from": "drug",
                "entity_to": "adverse_event",
                "relationship": "causes",
                "query_type": "lookup",
                "params": {"k": 20}
            },

            # Gene → Pathway
            "gene_to_pathway": {
                "pattern": r"pathway|biological process",
                "entity_from": "gene",
                "entity_to": "pathway",
                "relationship": "participates_in",
                "query_type": "graph_traversal",
                "params": {"include_graph": True}
            },
        }

        self.logger.info(f"SemanticQueryResolver initialized: "
                        f"{len(self.templates)} query templates")

    def resolve(
        self,
        query: str,
        entities: Optional[List[Dict[str, Any]]] = None,
        intent: Optional[Dict[str, Any]] = None,
        **kwargs
    ) -> Dict[str, Any]:
        """
        Convert vague question to structured query.

        Args:
            query: Natural language question
            entities: Extracted entities (from FuzzyEntityMatcher)
            intent: Intent classification result
            **kwargs: Additional parameters

        Returns:
            {
                'result': {
                    'structured_query': {
                        'query_type': 'cross_entity_search'|'graph_traversal'|etc,
                        'source_entity': {...},
                        'target_entity_type': 'drug'|'gene'|'pathway',
                        'relationship': 'modulates'|'affects'|etc,
                        'params': {...}
                    },
                    'query_template': template_name,
                    'reasoning': explanation
                },
                'confidence': 0.0-1.0,
                'strategy': 'template_match'|'semantic_analysis',
                'metadata': {...}
            }
        """
        start_time = time.time()

        if not self.validate(query):
            return self._error_result(query, "Invalid query")

        query_lower = query.lower()

        # Try to match query to template
        matched_template = None
        for template_name, template in self.templates.items():
            if re.search(template['pattern'], query_lower):
                matched_template = (template_name, template)
                break

        if not matched_template:
            result = self._empty_result(query, "No matching query template")
        else:
            template_name, template = matched_template
            result = self._generate_structured_query(
                query,
                template_name,
                template,
                entities,
                intent
            )

        # Record metrics
        latency_ms = (time.time() - start_time) * 1000
        self._record_query(latency_ms, success=result['confidence'] > 0.0)
        result['latency_ms'] = latency_ms

        return result

    def _generate_structured_query(
        self,
        query: str,
        template_name: str,
        template: Dict[str, Any],
        entities: Optional[List[Dict[str, Any]]],
        intent: Optional[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """Generate structured query from template."""

        # Get source entity (from entities list)
        source_entity = None
        if entities and len(entities) > 0:
            # Take the highest confidence entity
            sorted_entities = sorted(
                entities,
                key=lambda x: x.get('confidence', 0),
                reverse=True
            )
            source_entity = sorted_entities[0]

        # Build structured query
        structured_query = {
            'query_type': template['query_type'],
            'source_entity': source_entity,
            'target_entity_type': template['entity_to'],
            'relationship': template['relationship'],
            'params': template['params'].copy()
        }

        # Generate reasoning
        reasoning = self._generate_reasoning(
            template_name,
            source_entity,
            template
        )

        return {
            'result': {
                'structured_query': structured_query,
                'query_template': template_name,
                'reasoning': reasoning
            },
            'confidence': 0.90,  # Template match is high confidence
            'strategy': 'template_match',
            'metadata': {
                'template_name': template_name,
                'source_entity_type': template['entity_from'],
                'target_entity_type': template['entity_to']
            }
        }

    def _generate_reasoning(
        self,
        template_name: str,
        source_entity: Optional[Dict[str, Any]],
        template: Dict[str, Any]
    ) -> str:
        """Generate human-readable reasoning for query."""
        if not source_entity:
            return f"Query pattern matches {template_name}"

        entity_name = source_entity.get('entity', 'unknown')
        entity_type = source_entity.get('entity_type', 'unknown')

        reasoning_templates = {
            "gene_to_drug_rescue": f"Finding drugs that rescue/modulate {entity_name} ({entity_type})",
            "drug_to_mechanism": f"Finding mechanism of action for {entity_name}",
            "disease_to_biomarker": f"Finding biomarker genes for {entity_name}",
            "drug_to_safety": f"Finding safety/toxicity profile for {entity_name}",
            "gene_to_pathway": f"Finding pathways involving {entity_name}"
        }

        return reasoning_templates.get(
            template_name,
            f"Cross-entity query from {entity_type} to {template['entity_to']}"
        )

    def get_stats(self) -> Dict[str, Any]:
        """Return resolver statistics."""
        return {
            **self.get_base_stats(),
            'total_templates': len(self.templates)
        }


# Singleton instance
_resolver_instance = None


def get_semantic_query_resolver() -> SemanticQueryResolver:
    """
    Get singleton SemanticQueryResolver instance.

    Usage:
        resolver = get_semantic_query_resolver()
        result = resolver.resolve("Find rescue drugs for SCN1A")
    """
    global _resolver_instance
    if _resolver_instance is None:
        _resolver_instance = SemanticQueryResolver()
    return _resolver_instance
