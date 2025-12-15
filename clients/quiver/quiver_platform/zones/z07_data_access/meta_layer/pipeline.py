"""
MetaLayerPipeline - Orchestrator for Resolver Chain
====================================================

Chains resolvers → classifiers → enhancers for intelligent query processing.

Pipeline Flow:
    1. FuzzyEntityMatcher    - Extract and normalize entities
    2. IntentClassifier      - Detect query intent
    3. DrugNameResolver      - Normalize drug names (if needed)
    4. TargetResolver        - Normalize gene names (if needed)
    5. SemanticQueryResolver - Structure vague queries (if needed)
    6. ContextEnricher       - Add domain context (if needed)

Usage:
    pipeline = MetaLayerPipeline()
    result = pipeline.process("Find rescue drugs for SCN1A")

    # Returns complete resolution:
    {
        'entities': [...],
        'intent': {...},
        'structured_query': {...},
        'query_params': {...},
        'confidence': 0.95
    }

Author: Meta Layer Swarm - Agent 1
Date: 2025-12-01
Version: 1.0.0
"""

from typing import Dict, Any, List, Optional
import logging
import time

logger = logging.getLogger(__name__)


class MetaLayerPipeline:
    """
    Orchestrates resolver chain for complete query processing.

    The pipeline processes queries through multiple stages:
    - Entity extraction and normalization
    - Intent classification
    - Query structuring and enhancement
    """

    def __init__(self):
        """Initialize pipeline with lazy-loaded resolvers."""
        self._fuzzy_matcher = None
        self._intent_classifier = None
        self._drug_resolver = None
        self._target_resolver = None
        self._semantic_resolver = None

        logger.info("MetaLayerPipeline initialized (lazy loading)")

    def _get_fuzzy_matcher(self):
        """Lazy load FuzzyEntityMatcher."""
        if self._fuzzy_matcher is None:
            from .resolvers.fuzzy_entity_matcher import get_fuzzy_entity_matcher
            self._fuzzy_matcher = get_fuzzy_entity_matcher()
        return self._fuzzy_matcher

    def _get_intent_classifier(self):
        """Lazy load IntentClassifier."""
        if self._intent_classifier is None:
            from .classifiers.intent_classifier import get_intent_classifier
            self._intent_classifier = get_intent_classifier()
        return self._intent_classifier

    def _get_drug_resolver(self):
        """Lazy load DrugNameResolver."""
        if self._drug_resolver is None:
            from .resolvers.drug_name_resolver import get_drug_name_resolver
            self._drug_resolver = get_drug_name_resolver()
        return self._drug_resolver

    def _get_target_resolver(self):
        """Lazy load TargetResolver (if available)."""
        if self._target_resolver is None:
            try:
                from .resolvers.target_resolver import get_target_resolver
                self._target_resolver = get_target_resolver()
            except ImportError:
                logger.warning("TargetResolver not available yet")
                self._target_resolver = None
        return self._target_resolver

    def _get_semantic_resolver(self):
        """Lazy load SemanticQueryResolver (if available)."""
        if self._semantic_resolver is None:
            try:
                from .enhancers.semantic_query_resolver import get_semantic_query_resolver
                self._semantic_resolver = get_semantic_query_resolver()
            except ImportError:
                logger.warning("SemanticQueryResolver not available yet")
                self._semantic_resolver = None
        return self._semantic_resolver

    def process(
        self,
        question: str,
        category: Optional[str] = None,
        **kwargs
    ) -> Dict[str, Any]:
        """
        Process query through complete pipeline.

        Args:
            question: Natural language question
            category: Optional category hint
            **kwargs: Additional parameters

        Returns:
            {
                'entities': [
                    {'entity': str, 'type': str, 'confidence': float, ...}
                ],
                'intent': {
                    'intent': str,
                    'tool': str,
                    'primary_space': str,
                    'confidence': float,
                    ...
                },
                'normalized_entities': {
                    'drugs': [...],
                    'genes': [...],
                    'diseases': [...]
                },
                'query_params': {
                    'entity_name': str,
                    'entity_type': str,
                    'preferred_space': str,
                    'k': int,
                    ...
                },
                'pipeline_metadata': {
                    'stages_executed': [...],
                    'total_latency_ms': float,
                    'confidence': float
                }
            }
        """
        start_time = time.time()
        stages_executed = []

        result = {
            'entities': [],
            'intent': {},
            'normalized_entities': {},
            'query_params': {},
            'pipeline_metadata': {}
        }

        try:
            # Stage 1: Entity Extraction (Fuzzy Matching)
            fuzzy_matcher = self._get_fuzzy_matcher()
            entity_match = fuzzy_matcher.match(question)
            result['entities'] = [entity_match]
            stages_executed.append('fuzzy_entity_matcher')

            # Stage 2: Intent Classification
            intent_classifier = self._get_intent_classifier()
            intent_result = intent_classifier.classify(question, category)
            result['intent'] = intent_result
            stages_executed.append('intent_classifier')

            # Stage 3: Entity Normalization (based on type)
            normalized = {}

            # Normalize drugs
            if entity_match['entity_type'] == 'drug':
                drug_resolver = self._get_drug_resolver()
                if drug_resolver:
                    drug_info = drug_resolver.resolve(entity_match['entity'])
                    normalized['drugs'] = [drug_info]
                    stages_executed.append('drug_name_resolver')

            # Normalize genes (if TargetResolver available)
            elif entity_match['entity_type'] == 'gene':
                target_resolver = self._get_target_resolver()
                if target_resolver:
                    gene_info = target_resolver.resolve(entity_match['entity'])
                    normalized['genes'] = [gene_info]
                    stages_executed.append('target_resolver')

            result['normalized_entities'] = normalized

            # Stage 4: Generate Query Parameters
            query_params = self._generate_query_params(
                entity_match,
                intent_result,
                normalized
            )
            result['query_params'] = query_params

            # Stage 5: Semantic Enhancement (if needed for complex queries)
            if self._needs_semantic_enhancement(intent_result):
                semantic_resolver = self._get_semantic_resolver()
                if semantic_resolver:
                    enhanced = semantic_resolver.resolve(
                        question,
                        entities=result['entities'],
                        intent=intent_result
                    )
                    result['structured_query'] = enhanced.get('result', {})
                    stages_executed.append('semantic_query_resolver')

            # Calculate pipeline metrics
            total_latency = (time.time() - start_time) * 1000  # ms
            overall_confidence = self._calculate_confidence(
                entity_match.get('confidence', 0.0),
                intent_result.get('confidence', 0.0)
            )

            result['pipeline_metadata'] = {
                'stages_executed': stages_executed,
                'total_latency_ms': total_latency,
                'confidence': overall_confidence,
                'success': True
            }

        except Exception as e:
            logger.error(f"Pipeline error: {e}", exc_info=True)
            result['pipeline_metadata'] = {
                'stages_executed': stages_executed,
                'error': str(e),
                'success': False
            }

        return result

    def _generate_query_params(
        self,
        entity_match: Dict[str, Any],
        intent_result: Dict[str, Any],
        normalized: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Generate query parameters from pipeline results.

        Args:
            entity_match: Entity extraction result
            intent_result: Intent classification result
            normalized: Normalized entity info

        Returns:
            Query parameters dictionary
        """
        # Start with entity basics
        entity = entity_match.get('entity')
        entity_type = entity_match.get('entity_type')

        # Use normalized name if available
        if entity_type == 'drug' and 'drugs' in normalized:
            drug_info = normalized['drugs'][0]
            entity = drug_info.get('commercial_name', entity)
        elif entity_type == 'gene' and 'genes' in normalized:
            gene_info = normalized['genes'][0]
            entity = gene_info.get('canonical_id', entity)

        # Get base params from intent classifier
        query_params = {
            'entity_name': entity,
            'entity_type': entity_type,
            'k': 20  # default
        }

        # Add intent-specific params
        if 'query_type' in intent_result:
            query_type = intent_result['query_type']

            if query_type == 'cross_entity':
                query_params['k'] = 50
                query_params['cross_entity_search'] = True
            elif query_type == 'discovery':
                query_params['k'] = 100
                query_params['discovery_mode'] = True
            elif query_type == 'traversal':
                query_params['include_graph'] = True
                query_params['max_hops'] = 2

        # Add preferred space hint
        if 'primary_space' in intent_result:
            query_params['preferred_space'] = intent_result['primary_space']

        return query_params

    def _needs_semantic_enhancement(self, intent_result: Dict[str, Any]) -> bool:
        """
        Check if query needs semantic enhancement.

        Args:
            intent_result: Intent classification result

        Returns:
            True if semantic enhancement needed
        """
        # Use semantic enhancement for:
        # - Low confidence intents
        # - Cross-entity queries (gene→drug, disease→gene)
        # - Complex multi-step queries

        if intent_result.get('confidence', 1.0) < 0.75:
            return True

        query_type = intent_result.get('query_type')
        if query_type in ['cross_entity', 'discovery', 'traversal']:
            return True

        return False

    def _calculate_confidence(self, entity_confidence: float, intent_confidence: float) -> float:
        """
        Calculate overall pipeline confidence.

        Uses weighted average:
        - Entity extraction: 40%
        - Intent classification: 60%

        Args:
            entity_confidence: Entity extraction confidence
            intent_confidence: Intent classification confidence

        Returns:
            Overall confidence (0.0-1.0)
        """
        return (entity_confidence * 0.4) + (intent_confidence * 0.6)

    def get_stats(self) -> Dict[str, Any]:
        """
        Get statistics from all resolvers.

        Returns:
            Aggregated statistics
        """
        stats = {}

        if self._fuzzy_matcher:
            stats['fuzzy_matcher'] = self._fuzzy_matcher.get_stats()

        if self._intent_classifier:
            stats['intent_classifier'] = self._intent_classifier.get_stats()

        if self._drug_resolver:
            stats['drug_resolver'] = self._drug_resolver.get_stats()

        if self._target_resolver:
            stats['target_resolver'] = self._target_resolver.get_stats()

        if self._semantic_resolver:
            stats['semantic_resolver'] = self._semantic_resolver.get_stats()

        return stats


# Singleton instance
_pipeline_instance = None


def get_meta_layer_pipeline() -> MetaLayerPipeline:
    """
    Get singleton MetaLayerPipeline instance.

    Usage:
        pipeline = get_meta_layer_pipeline()
        result = pipeline.process("Find rescue drugs for SCN1A")
    """
    global _pipeline_instance
    if _pipeline_instance is None:
        _pipeline_instance = MetaLayerPipeline()
    return _pipeline_instance
