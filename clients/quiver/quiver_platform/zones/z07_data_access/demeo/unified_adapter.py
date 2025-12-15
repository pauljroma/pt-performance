"""
DeMeo v2.0 - Unified Query Layer Adapter
=========================================

Purpose:
--------
Adapter for seamless integration between DeMeo drug rescue framework
and the Unified Query Layer for PGVector embedding retrieval.

Features:
---------
- Query gene embeddings from MODEX/ENS/LINCS spaces
- Query drug embeddings from multiple embedding spaces
- Batch embedding queries for efficiency
- Multi-modal embedding retrieval (all 3 spaces in parallel)
- Automatic fallback: v6.0 → v5.0 embeddings
- Caching support for repeated queries

Architecture:
------------
DeMeo → DeMeoUnifiedAdapter → UnifiedQueryLayer → PGVector

Author: DeMeo Integration Team
Date: 2025-12-03
Version: 2.0.0-alpha1
Zone: z07_data_access
"""

from typing import Dict, Any, List, Optional
import numpy as np
import logging
from dataclasses import dataclass
import asyncio

logger = logging.getLogger(__name__)


@dataclass
class EmbeddingResult:
    """Result from a single embedding query"""
    entity_name: str
    entity_type: str
    embedding: np.ndarray
    space: str
    dimension: int
    confidence: float
    source_table: str
    metadata: Dict[str, Any]


@dataclass
class MultiModalEmbeddingResult:
    """Result from multi-modal embedding query (MODEX + ENS + LINCS)"""
    entity_name: str
    entity_type: str
    modex: Optional[EmbeddingResult]
    ens: Optional[EmbeddingResult]
    lincs: Optional[EmbeddingResult]
    spaces_found: List[str]
    agreement_coefficient: Optional[float] = None


class DeMeoUnifiedAdapter:
    """
    Adapter for DeMeo to query embeddings via Unified Query Layer

    This adapter provides a simple interface for DeMeo to retrieve
    embeddings from PGVector without needing to know about database
    connections, table names, or query optimization.

    Usage:
        adapter = DeMeoUnifiedAdapter(unified_query_layer)

        # Single space query
        result = await adapter.query_gene_embedding("SCN1A", space="modex")

        # Multi-modal query
        result = await adapter.query_multimodal_embeddings("SCN1A", entity_type="gene")
    """

    def __init__(self, unified_query_layer):
        """
        Initialize adapter with Unified Query Layer instance

        Args:
            unified_query_layer: UnifiedQueryLayer instance
        """
        self.uql = unified_query_layer
        self.tool_name = "demeo"

        # Cache for repeated queries (simple dict cache)
        self._embedding_cache: Dict[str, EmbeddingResult] = {}

        logger.info("DeMeoUnifiedAdapter initialized")

    async def query_gene_embedding(
        self,
        gene: str,
        space: str = "modex",
        version: str = "v6.0"
    ) -> Optional[EmbeddingResult]:
        """
        Query gene embedding from a single embedding space

        Args:
            gene: Gene symbol (e.g., "SCN1A", "CDKL5")
            space: Embedding space ("modex", "ens", or "lincs")
            version: Embedding version ("v6.0" or "v5.0")

        Returns:
            EmbeddingResult if found, None otherwise
        """
        cache_key = f"gene:{gene}:{space}:{version}"

        # Check cache
        if cache_key in self._embedding_cache:
            logger.debug(f"Cache hit for {cache_key}")
            return self._embedding_cache[cache_key]

        # Query via Unified Layer
        table_name = self._get_table_name(space, "gene", version)

        query_params = {
            'entity_name': gene,
            'entity_type': 'gene',
            'preferred_space': table_name,
            'k': 1,  # Get exact match
            'include_graph_context': False  # Just embeddings, no graph
        }

        try:
            result = await self.uql.execute_query(
                tool_name=self.tool_name,
                query_params=query_params,
                intent=f"gene_embedding_{space}"
            )

            if not result.get('success', False):
                logger.warning(f"Failed to query {gene} from {space}: {result.get('error')}")
                return None

            # Extract embedding from result
            embedding_result = self._parse_embedding_result(result, gene, "gene", space)

            # Cache result
            if embedding_result:
                self._embedding_cache[cache_key] = embedding_result

            return embedding_result

        except Exception as e:
            logger.error(f"Error querying gene embedding for {gene} in {space}: {e}")
            return None

    async def query_drug_embedding(
        self,
        drug: str,
        space: str = "modex",
        version: str = "v6.0"
    ) -> Optional[EmbeddingResult]:
        """
        Query drug embedding from a single embedding space

        Args:
            drug: Drug name or identifier
            space: Embedding space ("modex", "ens", or "lincs")
            version: Embedding version ("v6.0" or "v5.0")

        Returns:
            EmbeddingResult if found, None otherwise
        """
        cache_key = f"drug:{drug}:{space}:{version}"

        # Check cache
        if cache_key in self._embedding_cache:
            logger.debug(f"Cache hit for {cache_key}")
            return self._embedding_cache[cache_key]

        # Query via Unified Layer
        table_name = self._get_table_name(space, "drug", version)

        query_params = {
            'entity_name': drug,
            'entity_type': 'drug',
            'preferred_space': table_name,
            'k': 1,
            'include_graph_context': False
        }

        try:
            result = await self.uql.execute_query(
                tool_name=self.tool_name,
                query_params=query_params,
                intent=f"drug_embedding_{space}"
            )

            if not result.get('success', False):
                logger.warning(f"Failed to query {drug} from {space}: {result.get('error')}")
                return None

            embedding_result = self._parse_embedding_result(result, drug, "drug", space)

            if embedding_result:
                self._embedding_cache[cache_key] = embedding_result

            return embedding_result

        except Exception as e:
            logger.error(f"Error querying drug embedding for {drug} in {space}: {e}")
            return None

    async def query_multimodal_embeddings(
        self,
        entity: str,
        entity_type: str = "gene",
        version: str = "v6.0"
    ) -> MultiModalEmbeddingResult:
        """
        Query embeddings from all 3 modalities (MODEX + ENS + LINCS) in parallel

        This is the preferred method for DeMeo multi-modal consensus, as it
        queries all spaces efficiently in parallel.

        Args:
            entity: Entity name (gene or drug)
            entity_type: "gene" or "drug"
            version: Embedding version ("v6.0" or "v5.0")

        Returns:
            MultiModalEmbeddingResult with embeddings from all available spaces
        """
        logger.info(f"Querying multi-modal embeddings for {entity} ({entity_type})")

        # Query all 3 spaces in parallel
        if entity_type == "gene":
            modex_task = self.query_gene_embedding(entity, "modex", version)
            ens_task = self.query_gene_embedding(entity, "ens", version)
            lincs_task = self.query_gene_embedding(entity, "lincs", version)
        else:  # drug
            modex_task = self.query_drug_embedding(entity, "modex", version)
            ens_task = self.query_drug_embedding(entity, "ens", version)
            lincs_task = self.query_drug_embedding(entity, "lincs", version)

        # Await all queries in parallel
        modex_result, ens_result, lincs_result = await asyncio.gather(
            modex_task, ens_task, lincs_task,
            return_exceptions=True
        )

        # Handle exceptions
        if isinstance(modex_result, Exception):
            logger.error(f"MODEX query failed: {modex_result}")
            modex_result = None
        if isinstance(ens_result, Exception):
            logger.error(f"ENS query failed: {ens_result}")
            ens_result = None
        if isinstance(lincs_result, Exception):
            logger.error(f"LINCS query failed: {lincs_result}")
            lincs_result = None

        # Determine which spaces were found
        spaces_found = []
        if modex_result:
            spaces_found.append("modex")
        if ens_result:
            spaces_found.append("ens")
        if lincs_result:
            spaces_found.append("lincs")

        logger.info(f"Multi-modal query complete: {len(spaces_found)}/3 spaces found ({', '.join(spaces_found)})")

        return MultiModalEmbeddingResult(
            entity_name=entity,
            entity_type=entity_type,
            modex=modex_result,
            ens=ens_result,
            lincs=lincs_result,
            spaces_found=spaces_found
        )

    async def batch_query_embeddings(
        self,
        entities: List[str],
        entity_type: str = "gene",
        space: str = "modex",
        version: str = "v6.0"
    ) -> Dict[str, Optional[EmbeddingResult]]:
        """
        Query multiple embeddings in batch (parallel)

        Args:
            entities: List of entity names
            entity_type: "gene" or "drug"
            space: Embedding space
            version: Embedding version

        Returns:
            Dict mapping entity name to EmbeddingResult (None if not found)
        """
        logger.info(f"Batch querying {len(entities)} {entity_type} embeddings from {space}")

        # Create tasks for all entities
        if entity_type == "gene":
            tasks = [self.query_gene_embedding(entity, space, version) for entity in entities]
        else:
            tasks = [self.query_drug_embedding(entity, space, version) for entity in entities]

        # Execute in parallel
        results = await asyncio.gather(*tasks, return_exceptions=True)

        # Map results
        result_dict = {}
        for entity, result in zip(entities, results):
            if isinstance(result, Exception):
                logger.error(f"Batch query failed for {entity}: {result}")
                result_dict[entity] = None
            else:
                result_dict[entity] = result

        found_count = sum(1 for r in result_dict.values() if r is not None)
        logger.info(f"Batch query complete: {found_count}/{len(entities)} embeddings found")

        return result_dict

    def _get_table_name(self, space: str, entity_type: str, version: str) -> str:
        """
        Map space + entity_type + version to ACTUAL PGVector table name

        FIXED 2025-12-04: Use actual table names from production database

        Args:
            space: "modex", "ens", or "lincs"
            entity_type: "gene" or "drug"
            version: "v6.0" or "v5.0"

        Returns:
            Actual PGVector table name
        """
        # ACTUAL TABLE NAMES (from embedding_config.py)
        # v6.0 tables:
        # - Gene: ens_gene_64d_v6_0
        # - Gene+Drug unified: modex_ep_unified_16d_v6_0
        # - Drug: drug_chemical_v6_0_256d
        # - LINCS gene: lincs_gene_32d_v5_0
        # - LINCS drug: lincs_drug_32d_v5_0

        if version == "v6.0":
            if entity_type == "gene":
                if space == "ens":
                    return "ens_gene_64d_v6_0"
                elif space == "modex":
                    # MODEX for genes uses unified table (drug+gene 16D)
                    return "modex_ep_unified_16d_v6_0"
                elif space == "lincs":
                    return "lincs_gene_32d_v5_0"  # v5.0 table still used
            else:  # drug
                if space == "ens":
                    # ENS for drugs uses unified table (drug+gene 16D)
                    return "modex_ep_unified_16d_v6_0"
                elif space == "modex":
                    return "modex_ep_unified_16d_v6_0"
                elif space == "lincs":
                    return "lincs_drug_32d_v5_0"  # v5.0 table still used

        # Fallback for v5.0 or unknown
        return f"{space}_{entity_type}_embeddings"

    def _parse_embedding_result(
        self,
        uql_result: Dict[str, Any],
        entity: str,
        entity_type: str,
        space: str
    ) -> Optional[EmbeddingResult]:
        """
        Parse UnifiedQueryLayer result into EmbeddingResult

        Args:
            uql_result: Result from UnifiedQueryLayer.execute_query()
            entity: Entity name
            entity_type: "gene" or "drug"
            space: Embedding space

        Returns:
            EmbeddingResult if valid, None otherwise
        """
        try:
            # Check if entity was found
            if not uql_result.get('found', False):
                logger.warning(f"Entity {entity} not found in {space}")
                return None

            # Extract entity embedding (v6.0+: UQL returns entity_embedding directly)
            embedding_raw = uql_result.get('entity_embedding')

            if embedding_raw is None:
                logger.warning(f"No embedding found in UQL result for {entity}")
                return None

            # Convert to numpy array if needed
            if isinstance(embedding_raw, list):
                embedding = np.array(embedding_raw, dtype=np.float64)
            elif isinstance(embedding_raw, np.ndarray):
                embedding = embedding_raw
            else:
                logger.error(f"Unknown embedding type: {type(embedding_raw)}")
                return None

            # Extract metadata
            dimension = uql_result.get('dimension', len(embedding))
            confidence = 1.0  # Direct embedding query has full confidence
            source_table = uql_result.get('space', 'unknown')

            metadata = {
                'space': space,
                'query_duration_ms': uql_result.get('metagraph_metadata', {}).get('query_duration_ms', 0),
                'learned_from_metagraph': uql_result.get('metagraph_metadata', {}).get('learned_from_metagraph', False),
                'matched_entity': uql_result.get('matched_entity', entity)
            }

            return EmbeddingResult(
                entity_name=entity,
                entity_type=entity_type,
                embedding=embedding,
                space=space,
                dimension=dimension,
                confidence=confidence,
                source_table=source_table,
                metadata=metadata
            )

        except Exception as e:
            logger.error(f"Failed to parse embedding result for {entity}: {e}")
            return None

    def clear_cache(self):
        """Clear the embedding cache"""
        self._embedding_cache.clear()
        logger.info("Embedding cache cleared")

    def get_cache_stats(self) -> Dict[str, Any]:
        """Get cache statistics"""
        return {
            'cache_size': len(self._embedding_cache),
            'cached_entities': list(self._embedding_cache.keys())
        }


# ============================================================================
# Factory Function
# ============================================================================

def get_demeo_unified_adapter(unified_query_layer) -> DeMeoUnifiedAdapter:
    """
    Factory function to create DeMeoUnifiedAdapter

    Args:
        unified_query_layer: UnifiedQueryLayer instance

    Returns:
        DeMeoUnifiedAdapter instance

    Usage:
        from zones.z07_data_access.unified_query_layer import get_unified_query_layer
        from zones.z07_data_access.demeo.unified_adapter import get_demeo_unified_adapter

        uql = get_unified_query_layer()
        adapter = get_demeo_unified_adapter(uql)

        # Query gene embedding
        result = await adapter.query_gene_embedding("SCN1A", space="modex")
        print(f"Embedding dimension: {result.dimension}")
    """
    return DeMeoUnifiedAdapter(unified_query_layer)
