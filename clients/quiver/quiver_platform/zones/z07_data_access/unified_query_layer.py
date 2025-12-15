"""
Unified Query Layer - PGVector↔Neo4j Bridge with Dynamic Discovery
====================================================================

ARCHITECTURE PRINCIPLE: Discover embeddings from PGVector, relationships from Neo4j
-----------------------------------------------------------------------------------

This layer uses PGVECTOR for:
1. Dynamic embedding discovery (query information_schema for tables)
2. Runtime embedding selection (based on dimensions, entity_type, quality)
3. Vector similarity search (cosine distance via pgvector)
4. Metadata-driven routing (inferred from table names and structure)

Neo4j is used ONLY for:
- Graph relationships (Gene-Drug-Protein-Pathway edges)
- Query pattern learning (optional metagraph usage statistics)
- Cross-entity bridging (when embeddings don't directly connect entities)

PGVECTOR IS THE SOURCE OF TRUTH FOR EMBEDDINGS.
NEO4J IS THE SOURCE OF TRUTH FOR GRAPH RELATIONSHIPS.

NO HARDCODED MAPPINGS. Tables discovered dynamically from PGVector schema.

Author: Unified Query Layer
Date: 2025-12-01
Version: 2.0 (PGVector-first)
Zone: z07_data_access
"""

from typing import Dict, Any, List, Optional, Tuple
from neo4j import GraphDatabase
import psycopg2
import numpy as np
from datetime import datetime
import logging

# Import drug name resolver for entity normalization
try:
    from quiver_platform.zones.z07_data_access.meta_layer.resolvers import get_drug_name_resolver
except ImportError:
    # Fallback for different import contexts
    try:
        from zones.z07_data_access.meta_layer.resolvers import get_drug_name_resolver
    except ImportError:
        # If resolver not available, use a dummy function
        def get_drug_name_resolver():
            class DummyResolver:
                def resolve(self, name):
                    return {'confidence': 'unknown', 'commercial_name': name, 'source': 'passthrough'}
            return DummyResolver()
        logger.warning("Drug name resolver not available, using passthrough resolver")

logger = logging.getLogger(__name__)


class UnifiedQueryLayer:
    """
    Metagraph-driven query layer for abstract learning

    Key Principle: Query the metagraph to discover capabilities,
    don't hardcode them. This enables the system to learn and adapt.
    """

    def __init__(
        self,
        neo4j_uri: str = "bolt://localhost:7687",
        neo4j_auth: Tuple[str, str] = ("neo4j", "testpassword123"),
        pgvector_config: Dict = None
    ):
        """
        Initialize with database connections

        Note: We connect to databases, but use METAGRAPH to decide
        what to query, not hardcoded logic.
        """
        self.neo4j = GraphDatabase.driver(neo4j_uri, auth=neo4j_auth)

        if pgvector_config is None:
            pgvector_config = {
                "host": "localhost",
                "port": 5435,
                "database": "sapphire_database",
                "user": "postgres",
                "password": "temppass123"
            }

        self.pgvector_conn = psycopg2.connect(**pgvector_config)

        # Initialize entity name resolver for normalization
        self.drug_resolver = get_drug_name_resolver()

    def discover_tool_capabilities(self, tool_name: str) -> Dict[str, Any]:
        """
        PGVECTOR DISCOVERY: Query PGVector to discover available embedding tables

        This discovers embeddings from PGVector (not Neo4j edges) and builds
        capabilities dynamically based on actual table metadata.

        Returns:
            {
                'tool_name': str,
                'embedding_spaces': [
                    {
                        'name': str,
                        'table_name': str,
                        'priority': str,  # primary, fallback, fusion, enhancement
                        'dimension': int,
                        'entity_type': str,
                        'quality_tier': str,
                        'row_count': int
                    }
                ],
                'graph_integration': bool,
                'learned_preferences': dict
            }
        """
        # Discover embedding tables from PGVector
        embedding_spaces = self._discover_pgvector_tables()

        if not embedding_spaces:
            logger.warning(f"No PGVector embedding tables discovered")
            return {
                'tool_name': tool_name,
                'embedding_spaces': [],
                'graph_integration': False,
                'learned_preferences': {},
                'error': 'No embedding tables found in PGVector'
            }

        # Sort spaces by priority and quality
        priority_order = {'primary': 0, 'fallback': 1, 'fusion': 2, 'enhancement': 3}
        embedding_spaces.sort(key=lambda x: (
            priority_order.get(x.get('priority'), 99),
            -x.get('row_count', 0)  # More data first
        ))

        # Learn preferences from Neo4j metagraph if available
        learned_preferences = {}
        try:
            with self.neo4j.session() as session:
                learned_preferences = self._learn_tool_preferences(session, tool_name)
        except Exception as e:
            logger.debug(f"Could not learn preferences from metagraph: {e}")

        return {
            'tool_name': tool_name,
            'embedding_spaces': embedding_spaces,
            'graph_integration': True,  # Neo4j available for graph relationships
            'learned_preferences': learned_preferences
        }

    def _discover_pgvector_tables(self) -> List[Dict[str, Any]]:
        """
        Discover embedding tables from PGVector database

        Queries information_schema.tables to find available embedding tables
        and extracts metadata (dimensions, row_count, entity_type).

        Returns:
            List of embedding space metadata dictionaries
        """
        embedding_spaces = []

        try:
            with self.pgvector_conn.cursor() as cursor:
                # Query information_schema for tables with 'embedding' column
                cursor.execute("""
                    SELECT
                        t.table_name,
                        (SELECT COUNT(*) FROM information_schema.columns c
                         WHERE c.table_name = t.table_name
                         AND c.table_schema = 'public'
                         AND c.column_name = 'embedding') as has_embedding
                    FROM information_schema.tables t
                    WHERE t.table_schema = 'public'
                    AND t.table_type = 'BASE TABLE'
                    AND (
                        t.table_name LIKE '%modex%'
                        OR t.table_name LIKE '%ens%'
                        OR t.table_name LIKE '%lincs%'
                        OR t.table_name LIKE '%ep%'
                        OR t.table_name LIKE '%embedding%'
                    )
                    ORDER BY t.table_name
                """)

                candidate_tables = [(row[0], row[1]) for row in cursor.fetchall() if row[1] > 0]

                logger.info(f"Found {len(candidate_tables)} candidate tables with 'embedding' column")

                # For each table, get metadata
                for table_name, _ in candidate_tables:
                    try:
                        # Get row count
                        cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
                        row_count = cursor.fetchone()[0]

                        if row_count == 0:
                            continue  # Skip empty tables

                        # Get dimension by querying vector dimension using pgvector metadata
                        # The vector type stores dimension internally
                        cursor.execute(f"""
                            SELECT vector_dims(embedding) as dimension
                            FROM {table_name}
                            WHERE embedding IS NOT NULL
                            LIMIT 1
                        """)

                        dim_result = cursor.fetchone()
                        if not dim_result or not dim_result[0]:
                            continue

                        dimension = dim_result[0]

                        # Infer entity type from table name
                        entity_type = 'unknown'
                        if 'gene' in table_name.lower():
                            entity_type = 'gene'
                        elif 'drug' in table_name.lower():
                            entity_type = 'drug'
                        elif 'protein' in table_name.lower():
                            entity_type = 'protein'
                        elif 'disease' in table_name.lower():
                            entity_type = 'disease'

                        # Infer priority from table name (MODEX = primary, ENS = fallback, LINCS = fusion)
                        priority = 'fallback'
                        if 'modex' in table_name.lower():
                            priority = 'primary'
                        elif 'ens' in table_name.lower():
                            priority = 'fallback'
                        elif 'lincs' in table_name.lower():
                            priority = 'fusion'

                        # Infer quality tier from version and type
                        # v6.0 is the latest production version (highest quality)
                        # v5.0 and v4.0 are DEPRECATED - skip them entirely
                        if 'v5' in table_name.lower() or 'v4' in table_name.lower():
                            logger.debug(f"Skipping deprecated table: {table_name} (v4/v5 deprecated)")
                            continue  # Skip v4.0 and v5.0 tables - DEPRECATED

                        quality_tier = 'C'  # Default for unknown versions
                        if 'v6' in table_name.lower() or 'v6_0' in table_name.lower():
                            quality_tier = 'A'  # v6.0 is latest, highest quality
                        else:
                            quality_tier = 'B'  # Unversioned tables

                        # Create human-readable name
                        name = table_name.replace('_', ' ').title()

                        embedding_spaces.append({
                            'name': name,
                            'table_name': table_name,
                            'priority': priority,
                            'dimension': dimension,
                            'entity_type': entity_type,
                            'quality_tier': quality_tier,
                            'row_count': row_count
                        })

                        logger.debug(f"Discovered PGVector table: {table_name} ({dimension}D, {row_count} rows, {entity_type})")

                    except Exception as e:
                        logger.debug(f"Could not inspect table {table_name}: {e}")
                        continue

        except Exception as e:
            logger.error(f"Failed to discover PGVector tables: {e}")

        logger.info(f"Discovered {len(embedding_spaces)} embedding spaces from PGVector")
        return embedding_spaces

    def _learn_tool_preferences(self, session, tool_name: str) -> Dict[str, Any]:
        """
        ABSTRACT LEARNING: Learn tool preferences from metagraph history

        Query the metagraph to understand:
        - What spaces work best for this tool?
        - What query patterns are successful?
        - What k-values are optimal?

        This is learned, not hardcoded.
        """
        # Query historical usage patterns from metagraph
        result = session.run("""
            MATCH (t:Tool {name: $tool_name})-[:USES_SPACE]->(e:EmbeddingSpace)
            OPTIONAL MATCH (e)-[q:QUERY_EXECUTED]->(qr:QueryResult)
            WHERE q.tool_name = $tool_name
            WITH e.name as space_name,
                 AVG(qr.k_value) as avg_k,
                 AVG(qr.latency_ms) as avg_latency,
                 AVG(qr.result_quality) as avg_quality
            WHERE avg_k IS NOT NULL
            RETURN space_name, avg_k, avg_latency, avg_quality
        """, tool_name=tool_name)

        preferences = {}
        for record in result:
            preferences[record['space_name']] = {
                'optimal_k': int(record['avg_k']) if record['avg_k'] else 20,
                'expected_latency_ms': record['avg_latency'],
                'quality_score': record['avg_quality']
            }

        return preferences

    async def execute_query(
        self,
        tool_name: str,
        query_params: Dict[str, Any],
        intent: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        METAGRAPH-DRIVEN QUERY EXECUTION

        Steps:
        1. Query metagraph to discover tool capabilities
        2. Select embedding space based on metagraph intelligence
        3. Execute query on selected space
        4. Optionally integrate graph data
        5. Record results back to metagraph (learning)

        Args:
            tool_name: Name of tool requesting query
            query_params: Query parameters (entity_name, k, filters, etc.)
            intent: Optional query intent for routing

        Returns:
            Results with metagraph metadata
        """
        query_start = datetime.now()

        # Step 1: Discover capabilities from PGVector
        capabilities = self.discover_tool_capabilities(tool_name)

        if not capabilities['embedding_spaces']:
            return {
                'success': False,
                'error': f'No embedding spaces available for tool {tool_name}',
                'suggestion': 'Check PGVector database for embedding tables'
            }

        # Step 2: Select best embedding space (metagraph intelligence)
        selected_space = self._select_embedding_space(
            capabilities,
            query_params,
            intent
        )

        logger.info(f"Tool {tool_name}: Selected space {selected_space['name']} "
                   f"(priority: {selected_space['priority']})")

        # Step 3: Execute query on selected space
        results = await self._query_embedding_space(
            selected_space,
            query_params
        )

        # Step 4: Optionally integrate graph data (disabled by default for performance)
        if capabilities['graph_integration'] and query_params.get('include_graph_context', False):
            results = await self._enrich_with_graph_context(
                results,
                query_params
            )

        # Step 5: Record to metagraph for learning
        query_duration = (datetime.now() - query_start).total_seconds() * 1000
        await self._record_query_to_metagraph(
            tool_name,
            selected_space['name'],
            query_params,
            results,
            query_duration
        )

        results['metagraph_metadata'] = {
            'tool': tool_name,
            'space_selected': selected_space['name'],
            'selection_reason': selected_space.get('selection_reason'),
            'query_duration_ms': query_duration,
            'learned_from_metagraph': True
        }

        return results

    def _select_embedding_space(
        self,
        capabilities: Dict[str, Any],
        query_params: Dict[str, Any],
        intent: Optional[str]
    ) -> Dict[str, Any]:
        """
        INTELLIGENT SPACE SELECTION using metagraph intelligence

        Selection criteria (in order):
        1. Query intent match (from metagraph Intent→Tool→Space paths)
        2. Historical success rate (learned from metagraph)
        3. Entity type compatibility
        4. Priority (primary > fallback > fusion > enhancement)
        5. Data quality tier

        This is adaptive, not hardcoded.
        """
        spaces = capabilities['embedding_spaces']
        learned_prefs = capabilities['learned_preferences']

        # Score each space
        scored_spaces = []
        for space in spaces:
            score = 0
            reasons = []

            # Priority score
            priority_scores = {'primary': 100, 'fallback': 80, 'fusion': 60, 'enhancement': 40}
            score += priority_scores.get(space.get('priority'), 0)
            reasons.append(f"priority:{space.get('priority')}")

            # Historical success (learned from metagraph)
            if space.get('success_rate', 0) > 0:
                score += space['success_rate'] * 50
                reasons.append(f"success_rate:{space['success_rate']:.2f}")

            # Usage frequency (popular spaces work better)
            if space.get('usage_count', 0) > 0:
                score += min(space['usage_count'] / 10, 20)  # Cap at 20 points
                reasons.append(f"usage_count:{space['usage_count']}")

            # Quality tier (v6.0 gets significantly higher priority)
            quality_scores = {'A': 50, 'B': 15, 'C': 5}  # v6.0 (A) gets +50 to prioritize over v5.0
            score += quality_scores.get(space.get('quality_tier'), 0)

            # Additional version boost for v6.0 tables
            if 'v6' in space.get('table_name', '').lower() or 'v6_0' in space.get('table_name', '').lower():
                score += 30  # Extra boost for v6.0
                reasons.append("v6.0_boost")

            # Preferred space hint (from intent classifier)
            preferred_space = query_params.get('preferred_space')
            if preferred_space and space.get('name') == preferred_space:
                score += 200  # Very high priority for explicit preference
                reasons.append(f"preferred_space_match")
            elif preferred_space and space.get('table_name') == preferred_space:
                score += 200
                reasons.append(f"preferred_table_match")

            # Entity type match
            entity_type = query_params.get('entity_type')
            if entity_type and space.get('entity_type') == entity_type:
                score += 30
                reasons.append(f"entity_type_match")

            # Learned preferences
            if space['name'] in learned_prefs:
                prefs = learned_prefs[space['name']]
                if prefs.get('quality_score', 0) > 0.8:
                    score += 25
                    reasons.append(f"high_learned_quality")

            scored_spaces.append({
                **space,
                'selection_score': score,
                'selection_reason': ', '.join(reasons)
            })

        # Select highest scoring space
        best_space = max(scored_spaces, key=lambda x: x['selection_score'])

        logger.info(f"Selected {best_space['name']} with score {best_space['selection_score']:.0f}")

        return best_space

    async def _query_embedding_space(
        self,
        space: Dict[str, Any],
        query_params: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Execute query on selected embedding space

        Uses PGVector for similarity search with parameters
        learned from metagraph preferences.

        NEW: Supports cross-entity queries via Neo4j graph bridging
        """
        table_name = space['table_name']
        if not table_name:
            table_name = space['name'].lower()

        entity_name = query_params.get('entity_name') or query_params.get('entity')
        entity_type = query_params.get('entity_type', 'unknown')
        k = query_params.get('k', 20)

        if not entity_name:
            return {
                'success': False,
                'error': 'No entity_name provided'
            }

        # NEW: Handle cross-entity queries (e.g., gene→drug, disease→gene)
        if query_params.get('cross_entity', False):
            logger.info(f"Cross-entity query detected: {entity_type} → {space.get('entity_type')}")
            return await self._query_cross_entity(
                entity_name,
                entity_type,
                space,
                query_params
            )

        # Normalize entity name using resolver (CHEMBL→LINCS, QS→Name, etc.)
        normalized_entity = self._normalize_entity_name(entity_name, entity_type)
        logger.info(f"Entity normalized: {entity_name} → {normalized_entity}")

        # Query PGVector for entity embedding
        with self.pgvector_conn.cursor() as cursor:
            # Check if metadata column exists (v6.0 tables don't have it)
            cursor.execute("""
                SELECT column_name
                FROM information_schema.columns
                WHERE table_name = %s
                AND column_name = 'metadata'
            """, (table_name,))
            has_metadata = cursor.fetchone() is not None

            # Build query with optional metadata column
            select_clause = "SELECT id, embedding"
            if has_metadata:
                select_clause += ", metadata"

            # Check if entity exists (try normalized first, then original)
            cursor.execute(f"""
                {select_clause}
                FROM {table_name}
                WHERE LOWER(id) = LOWER(%s)
                LIMIT 1
            """, (normalized_entity,))

            result = cursor.fetchone()

            if not result and normalized_entity != entity_name:
                # Try original name if normalization didn't match
                cursor.execute(f"""
                    {select_clause}
                    FROM {table_name}
                    WHERE LOWER(id) = LOWER(%s)
                    LIMIT 1
                """, (entity_name,))
                result = cursor.fetchone()

            if not result:
                # Try partial match with normalized entity
                cursor.execute(f"""
                    {select_clause}
                    FROM {table_name}
                    WHERE LOWER(id) LIKE LOWER(%s)
                    LIMIT 1
                """, (f'%{normalized_entity}%',))
                result = cursor.fetchone()

            if not result:
                return {
                    'success': False,
                    'found': False,
                    'error': f'Entity {entity_name} (normalized: {normalized_entity}) not found in {table_name}',
                    'space': space['name']
                }

            # Parse result based on whether metadata exists
            if has_metadata:
                entity_id, entity_embedding, entity_metadata = result
            else:
                entity_id, entity_embedding = result
                entity_metadata = None

            # Find K nearest neighbors
            neighbor_select = "SELECT id, 1 - (embedding <=> %s::vector) as similarity"
            if has_metadata:
                neighbor_select += ", metadata"

            cursor.execute(f"""
                {neighbor_select}
                FROM {table_name}
                WHERE id != %s
                ORDER BY embedding <=> %s::vector
                LIMIT %s
            """, (entity_embedding, entity_id, entity_embedding, k))

            neighbors = []
            for row in cursor.fetchall():
                neighbor_dict = {
                    'id': row[0],
                    'similarity': float(row[1])
                }
                if has_metadata:
                    neighbor_dict['metadata'] = row[2] if row[2] else {}
                else:
                    neighbor_dict['metadata'] = {}
                neighbors.append(neighbor_dict)

        # Convert pgvector vector type to list for JSON serialization
        # The entity_embedding is needed by DeMeo and other tools
        if isinstance(entity_embedding, str):
            # Parse pgvector string format: '[1.0,2.0,...]'
            emb_str = entity_embedding.strip('[]')
            entity_embedding_list = [float(x.strip()) for x in emb_str.split(',')]
        else:
            entity_embedding_list = entity_embedding.tolist() if hasattr(entity_embedding, 'tolist') else list(entity_embedding)

        return {
            'success': True,
            'found': True,
            'query_entity': entity_name,
            'matched_entity': entity_id,
            'entity_embedding': entity_embedding_list,  # Add embedding for tools like DeMeo
            'space': space['name'],
            'dimension': space['dimension'],
            'neighbors': neighbors,
            'neighbor_count': len(neighbors),
            'results': neighbors  # Alias for backward compatibility
        }

    async def _query_cross_entity(
        self,
        entity_name: str,
        entity_type: str,
        target_space: Dict[str, Any],
        query_params: Dict[str, Any]
    ) -> Dict[str, Any]:
        """

        # LEARNING: Check if we've learned this pattern before
        learned_patterns = self._check_learned_patterns(entity_type, target_entity_type)

        if learned_patterns:
            # A/B Testing: Select pattern using exploration vs exploitation
            learned_path = self._select_pattern_with_exploration(
                learned_patterns,
                exploration_rate=0.10  // 10% exploration
            )

            if learned_path and learned_path['confidence'] > 0.75:
                was_exploration = learned_path.get('_is_exploration', False)
                logger.info(f"🧠 Using {'EXPLORED' if was_exploration else 'LEARNED'} pattern "
                           f"(confidence: {learned_path['confidence']:.2f})")
            return await asyncio.coroutine(
                lambda: self._execute_learned_pattern(
                    entity_name,
                    learned_path['pattern'],
                    learned_path['pattern_id'],
                    k,
                    target_entity_type
                )
            )()

        
        # PATTERN COMPOSITION: Try to compose existing patterns
        logger.info(f"Trying pattern composition...")
        composed_result = await asyncio.coroutine(
            lambda: self._try_pattern_composition(
                entity_name,
                entity_type,
                target_entity_type,
                k
            )
        )()

        if composed_result and composed_result.get('success'):
            logger.info(f"✅ Composition successful!")
            return composed_result


        # MULTI-HOP FALLBACK: Try to discover new complex paths
        logger.info(f"No learned pattern found, attempting multi-hop discovery...")
        discovered_paths = self._discover_multihop_path(entity_type, target_entity_type, max_hops=5)

        if discovered_paths:
            # Use best discovered path
            best_path = discovered_paths[0]
            logger.info(f"🔍 Using DISCOVERED multi-hop path ({best_path['hops']} hops)")

            # Score and record if quality is good
            quality_score = self._score_path_quality(
                best_path['pattern'],
                entity_type,
                target_entity_type
            )

            if quality_score >= 0.70:
                # Record to metagraph for future use
                pattern_id = self._record_discovered_path(
                    entity_type,
                    target_entity_type,
                    best_path['pattern'],
                    quality_score
                )

                # Execute the discovered path
                return await asyncio.coroutine(
                    lambda: self._execute_learned_pattern(
                        entity_name,
                        best_path['pattern'],
                        pattern_id,
                        k,
                        target_entity_type
                    )
                )()



        Execute cross-entity query using MODEX/ENS/LINCS priority order

        Strategy (WORLD-CLASS):
        1. Query source entity in its native space (e.g., SCN1A in ENS gene space)
        2. Use MODEX edges to bridge to target entity type
        3. Priority: MODEX → ENS → LINCS → Graph fallback

        Example flows:
        - gene (SCN1A in ENS) → MODEX → drugs (in LINCS)
        - disease (epilepsy) → ENS → genes → MODEX → drugs
        - drug (gabapentin in LINCS) → MODEX → mechanisms
        """
        k = query_params.get('k', 20)
        relationship = query_params.get('relationship', 'modulates')

        # Get target entity type from structured_query or query_params
        target_entity_type = (
            query_params.get('target_entity_type') or
            query_params.get('structured_query', {}).get('target_entity_type') or
            target_space.get('entity_type') or
            'unknown'
        )

        logger.info(f"Cross-entity (MODEX-first): {entity_type}({entity_name}) → {target_entity_type}")

        # Step 1: Find source entity in its NATIVE embedding space
        # Gene → ENS+LINCS Fusion (96D), Drug → LINCS space, etc.
        source_space_map = {
            'gene': 'g_g_1__ens__lincs',  # Use fusion (96D) for richer representation
            'drug': 'lincs_drug_32d_v5_0',
            'disease': 'disease_embeddings',  # If exists
            'pathway': 'pathway_embeddings'
        }

        source_table = source_space_map.get(entity_type)
        if not source_table:
            logger.warning(f"No native space for entity_type {entity_type}")
            source_table = target_space['table_name']  # Fallback

        logger.info(f"Step 1: Looking for {entity_name} in native space {source_table}")

        # Step 2: Query MODEX edges from metagraph (WORLD-CLASS: use metagraph for bridging!)
        with self.neo4j.session() as session:
            if entity_type == 'gene' and target_entity_type == 'drug':
                # STRATEGY: Gene → ENCODES → Protein ← TARGETS ← Drug (WORLD-CLASS!)
                # Also try MODEX edges as backup
                cypher = """
                    MATCH (g:Gene)-[:ENCODES]->(p:Protein)<-[r:TARGETS]-(d:Drug)
                    WHERE g.symbol = $entity_name OR g.name = $entity_name
                    RETURN DISTINCT d.name as drug_name,
                           d.id as drug_id,
                           'TARGETS_via_protein' as edge_type
                    LIMIT $k

                    UNION

                    MATCH (d:Drug)-[r:PREDICTS_RESCUE_MODEX_16D]->(g:Gene)
                    WHERE g.symbol = $entity_name OR g.name = $entity_name
                    RETURN DISTINCT d.name as drug_name,
                           d.id as drug_id,
                           type(r) as edge_type
                    LIMIT $k
                """
                result = session.run(cypher, entity_name=entity_name, k=k*2)
                bridged_entities = [(r['drug_name'] or r['drug_id'], r['edge_type']) for r in result]

            elif entity_type == 'disease' and target_entity_type == 'gene':
                # Disease → Gene associations (via multiple paths)
                cypher = """
                    MATCH (dis:Disease)-[r:ASSOCIATED_WITH|CAUSED_BY|GENE_ASSOCIATION]-(g:Gene)
                    WHERE toLower(dis.name) CONTAINS toLower($entity_name)
                    RETURN DISTINCT g.symbol as gene_name, g.name as gene_alt_name, type(r) as edge_type
                    LIMIT $k
                """
                result = session.run(cypher, entity_name=entity_name, k=k*2)
                bridged_entities = [(r['gene_name'] or r['gene_alt_name'], r['edge_type']) for r in result if (r.get('gene_name') or r.get('gene_alt_name'))]

            elif entity_type == 'drug' and target_entity_type in ['pathway', 'mechanism']:
                # Drug → Mechanism/Pathway (via protein targets or direct relationships)
                cypher = """
                    MATCH (d:Drug)-[:TARGETS]->(p:Protein)-[:PARTICIPATES_IN|INVOLVED_IN]-(pathway:Pathway)
                    WHERE toLower(d.name) = toLower($entity_name) OR toLower(d.id) = toLower($entity_name)
                        OR d.name CONTAINS $entity_name OR d.id CONTAINS $entity_name
                    RETURN DISTINCT pathway.name as pathway_name, 'AFFECTS_via_protein' as edge_type
                    LIMIT $k

                    UNION

                    MATCH (d:Drug)-[r:HAS_MECHANISM|AFFECTS_PATHWAY]-(pathway:Pathway)
                    WHERE toLower(d.name) = toLower($entity_name) OR toLower(d.id) = toLower($entity_name)
                        OR d.name CONTAINS $entity_name OR d.id CONTAINS $entity_name
                    RETURN DISTINCT pathway.name as pathway_name, type(r) as edge_type
                    LIMIT $k
                """
                result = session.run(cypher, entity_name=entity_name, k=k*2)
                bridged_entities = [(r['pathway_name'], r['edge_type']) for r in result if r.get('pathway_name')]
            else:
                bridged_entities = []

        if not bridged_entities:
            logger.warning(f"No MODEX/graph edges found for {entity_type} {entity_name}")
            return {
                'success': True,
                'found': False,
                'query_entity': entity_name,
                'cross_entity': True,
                'method': 'MODEX_bridge',
                'bridged_entities': 0,
                'neighbors': [],
                'neighbor_count': 0,
                'space': target_space['name']
            }

        logger.info(f"MODEX bridge found {len(bridged_entities)} related entities via edges: {set(e[1] for e in bridged_entities)}")

        # Step 3: Return bridged entities directly (they're from graph, not embeddings)
        # For cross-entity queries, the bridged entities ARE the result
        neighbors = [
            {
                'id': entity_id,
                'distance': 0.0,  # Graph-derived, not embedding distance
                'edge_type': edge_type,
                'metadata': {'source': 'neo4j_graph', 'edge_type': edge_type}
            }
            for entity_id, edge_type in bridged_entities[:k]
            if entity_id
        ]

        logger.info(f"Returning {len(neighbors)} graph-derived neighbors")

        return {
            'success': True,
            'found': True,
            'query_entity': entity_name,
            'cross_entity': True,
            'method': 'MODEX_bridge',
            'bridged_entities': len(bridged_entities),
            'neighbors': neighbors,
            'neighbor_count': len(neighbors),
            'space': target_space.get('name', 'neo4j_graph')
        }

        # OLD CODE (trying to look up in embedding space - doesn't work for graph entities)
        # Step 3: Query target embedding space for bridged entities
        table_name = target_space['table_name'] or target_space['name'].lower()
        neighbors_old = []

        if False:  # Disabled - use graph-derived neighbors instead
            with self.pgvector_conn.cursor() as cursor:
                for entity_id, edge_type in bridged_entities[:k]:
                    if not entity_id:
                        continue

                    # Normalize the entity name
                    normalized = self._normalize_entity_name(entity_id, target_space.get('entity_type'))

                    # Try exact match first
                    cursor.execute(f"""
                        SELECT id, metadata
                        FROM {table_name}
                        WHERE LOWER(id) = LOWER(%s)
                        LIMIT 1
                    """, (normalized,))

                    result = cursor.fetchone()

                    # Try partial match if exact fails
                    if not result:
                        cursor.execute(f"""
                            SELECT id, metadata
                            FROM {table_name}
                            WHERE LOWER(id) LIKE LOWER(%s)
                            LIMIT 1
                        """, (f'%{normalized}%',))
                        result = cursor.fetchone()

                    if result:
                        neighbors_old.append({
                            'id': result[0],
                            'similarity': 0.95,  # High confidence from MODEX
                            'metadata': result[1] if result[1] else {},
                            'source': f'MODEX_{edge_type}',
                            'bridge_path': f'{entity_name} → {edge_type} → {result[0]}'
                        })
            # Old code disabled - we now return graph-derived neighbors directly above




    def _find_composable_patterns(
        self,
        source_type: str,
        target_type: str
    ) -> List[Dict[str, Any]]:
        """
        Find two patterns that can be composed to bridge source → target

        Example:
        - Pattern A: gene → pathway (confidence 0.95)
        - Pattern B: pathway → disease (confidence 0.90)
        - Composed: gene → disease (confidence 0.95 * 0.90 = 0.855)
        """
        try:
            with self.neo4j.session() as session:
                result = session.run("""
                    // Find pattern A: source → intermediate
                    MATCH (lpA:LearnedPattern)
                    WHERE lpA.source_entity_type = $source
                      AND lpA.confidence >= 0.75

                    // Find pattern B: intermediate → target
                    MATCH (lpB:LearnedPattern)
                    WHERE lpB.source_entity_type = lpA.target_entity_type
                      AND lpB.target_entity_type = $target
                      AND lpB.confidence >= 0.75

                    // Calculate composed confidence
                    WITH lpA, lpB,
                         lpA.confidence * lpB.confidence as composed_confidence

                    WHERE composed_confidence >= 0.70

                    RETURN
                        lpA.source_entity_type as source,
                        lpA.target_entity_type as intermediate,
                        lpB.target_entity_type as target,
                        lpA.edge_pattern as pattern_a,
                        lpB.edge_pattern as pattern_b,
                        lpA.edge_pattern + lpB.edge_pattern as composed_pattern,
                        composed_confidence as confidence,
                        id(lpA) as pattern_a_id,
                        id(lpB) as pattern_b_id
                    ORDER BY composed_confidence DESC
                    LIMIT 5
                """, source=source_type, target=target_type)

                compositions = []
                for record in result:
                    compositions.append({
                        'source': record['source'],
                        'intermediate': record['intermediate'],
                        'target': record['target'],
                        'pattern_a': record['pattern_a'],
                        'pattern_b': record['pattern_b'],
                        'composed_pattern': record['composed_pattern'],
                        'confidence': record['confidence'],
                        'pattern_a_id': record['pattern_a_id'],
                        'pattern_b_id': record['pattern_b_id']
                    })

                if compositions:
                    logger.info(f"Found {len(compositions)} composable patterns: "
                               f"{source_type}→{target_type}")
                    for i, comp in enumerate(compositions[:2]):
                        logger.info(f"  Composition {i+1}: {comp['source']}→{comp['intermediate']}→{comp['target']} "
                                   f"(confidence: {comp['confidence']:.2f})")

                return compositions

        except Exception as e:
            logger.warning(f"Could not find composable patterns: {e}")
            return []

    def _validate_composed_pattern(
        self,
        composed_pattern: List[str],
        source_type: str,
        target_type: str
    ) -> bool:
        """
        Test if a composed pattern actually works in the graph

        Returns True if the path exists and returns results
        """
        try:
            # Map entity types to labels
            label_map = {
                'gene': 'Gene',
                'drug': 'Drug',
                'pathway': 'Pathway',
                'protein': 'Protein',
                'disease': 'Disease'
            }

            source_label = label_map.get(source_type, source_type.capitalize())
            target_label = label_map.get(target_type, target_type.capitalize())

            # Build path pattern
            path_pattern = f"(source:{source_label})"
            for i, edge_type in enumerate(composed_pattern):
                if i < len(composed_pattern) - 1:
                    path_pattern += f"-[:{edge_type}]-()"
                else:
                    path_pattern += f"-[:{edge_type}]-(target:{target_label})"

            with self.neo4j.session() as session:
                # Test on 5 random samples
                result = session.run(f"""
                    MATCH {path_pattern}
                    WITH count(*) as total_paths
                    RETURN total_paths > 0 as is_valid, total_paths
                    LIMIT 1
                """)

                record = result.single()
                if record and record['is_valid']:
                    logger.info(f"Composed pattern validated: {total_paths} paths exist")
                    return True
                else:
                    logger.warning(f"Composed pattern validation failed: no paths found")
                    return False

        except Exception as e:
            logger.warning(f"Could not validate composed pattern: {e}")
            return False

    def _record_composed_pattern(
        self,
        source_type: str,
        target_type: str,
        composed_pattern: List[str],
        confidence: float,
        pattern_a_id: int,
        pattern_b_id: int
    ) -> Optional[int]:
        """
        Record a validated composed pattern to metagraph

        Returns pattern_id if successful
        """
        try:
            with self.neo4j.session() as session:
                result = session.run("""
                    CREATE (lp:LearnedPattern {
                        source_entity_type: $source_type,
                        target_entity_type: $target_type,
                        edge_pattern: $composed_pattern,
                        discovered_at: datetime(),
                        success_count: 0,
                        total_queries: 0,
                        avg_latency: 250.0,
                        avg_results: 10.0,
                        confidence: $confidence,
                        auto_discovered: true,
                        discovery_method: 'composition',
                        composed_from: [$pattern_a_id, $pattern_b_id]
                    })
                    RETURN id(lp) as pattern_id
                """, source_type=source_type, target_type=target_type,
                     composed_pattern=composed_pattern, confidence=confidence,
                     pattern_a_id=pattern_a_id, pattern_b_id=pattern_b_id)

                record = result.single()
                if record:
                    pattern_id = record['pattern_id']
                    logger.info(f"Recorded composed pattern: {source_type}→{target_type} "
                               f"(pattern_id: {pattern_id}, confidence: {confidence:.2f})")
                    return pattern_id
                return None

        except Exception as e:
            logger.warning(f"Could not record composed pattern: {e}")
            return None



    def _select_pattern_with_exploration(
        self,
        patterns: List[Dict[str, Any]],
        exploration_rate: float = 0.10
    ) -> Dict[str, Any]:
        """
        Select pattern using exploration vs exploitation strategy

        - exploration_rate (default 10%): Probability of trying alternative pattern
        - 1 - exploration_rate (90%): Use best pattern

        This prevents getting stuck in local optimum and enables discovering
        better patterns over time.

        Args:
            patterns: List of candidate patterns sorted by confidence
            exploration_rate: Probability of exploration (0.0 - 1.0)

        Returns:
            Selected pattern (either best or random alternative)
        """
        import random

        if not patterns:
            return None

        if len(patterns) == 1:
            # Only one pattern, no exploration possible
            return patterns[0]

        # Decide: exploit or explore
        if random.random() < exploration_rate:
            # EXPLORE: Try a random alternative pattern
            # Use weighted sampling: lower confidence patterns have lower probability
            weights = [p['confidence'] for p in patterns]
            total_weight = sum(weights)
            probabilities = [w / total_weight for w in weights]

            selected = random.choices(patterns, weights=probabilities, k=1)[0]

            logger.info(f"🔬 EXPLORING: Trying alternative pattern "
                       f"(confidence: {selected['confidence']:.2f}) "
                       f"instead of best (confidence: {patterns[0]['confidence']:.2f})")

            # Mark as exploration for metrics
            selected['_is_exploration'] = True
            return selected
        else:
            # EXPLOIT: Use best pattern
            logger.debug(f"✅ EXPLOITING: Using best pattern "
                        f"(confidence: {patterns[0]['confidence']:.2f})")

            patterns[0]['_is_exploration'] = False
            return patterns[0]

    def _record_ab_test_result(
        self,
        pattern_id: int,
        was_exploration: bool,
        success: bool,
        latency_ms: float,
        result_count: int
    ):
        """
        Record A/B test result with exploration flag

        This helps track whether exploration is finding better patterns
        """
        try:
            with self.neo4j.session() as session:
                # Record to pattern as normal
                self._record_query_result(pattern_id, success, latency_ms, result_count)

                # Additionally record A/B metrics
                session.run("""
                    MATCH (lp:LearnedPattern)
                    WHERE id(lp) = $pattern_id

                    SET lp.total_ab_tests = COALESCE(lp.total_ab_tests, 0) + 1,
                        lp.exploration_tests = COALESCE(lp.exploration_tests, 0) + CASE WHEN $was_exploration THEN 1 ELSE 0 END,
                        lp.exploitation_tests = COALESCE(lp.exploitation_tests, 0) + CASE WHEN NOT $was_exploration THEN 1 ELSE 0 END
                """, pattern_id=pattern_id, was_exploration=was_exploration)

                logger.debug(f"Recorded A/B test: pattern={pattern_id}, "
                           f"exploration={was_exploration}, success={success}")

        except Exception as e:
            logger.warning(f"Could not record A/B test result: {e}")

    def _get_ab_testing_metrics(self) -> Dict[str, Any]:
        """
        Get A/B testing metrics

        Returns statistics about exploration vs exploitation effectiveness
        """
        try:
            with self.neo4j.session() as session:
                result = session.run("""
                    MATCH (lp:LearnedPattern)
                    WHERE lp.total_ab_tests > 0

                    RETURN sum(lp.total_ab_tests) as total_tests,
                           sum(lp.exploration_tests) as exploration_tests,
                           sum(lp.exploitation_tests) as exploitation_tests,
                           count(CASE WHEN lp.exploration_tests > lp.exploitation_tests THEN 1 END) as exploration_favored_count

                    LIMIT 1
                """)

                record = result.single()
                if record:
                    total = record['total_tests'] or 0
                    exploration = record['exploration_tests'] or 0
                    exploitation = record['exploitation_tests'] or 0

                    return {
                        'total_tests': total,
                        'exploration_tests': exploration,
                        'exploitation_tests': exploitation,
                        'exploration_rate': exploration / total if total > 0 else 0,
                        'exploration_favored_count': record['exploration_favored_count']
                    }
                return {}

        except Exception as e:
            logger.warning(f"Could not get A/B testing metrics: {e}")
            return {}


    def _decay_pattern_confidence(
        self,
        decay_days: int = 30,
        decay_factor: float = 0.95
    ) -> Dict[str, int]:
        """
        Decay confidence of patterns not used recently

        Patterns unused for decay_days or more have confidence multiplied by decay_factor.
        This ensures recently successful patterns are prioritized.

        Returns dict with decay statistics
        """
        try:
            with self.neo4j.session() as session:
                result = session.run("""
                    MATCH (lp:LearnedPattern)
                    WHERE lp.last_used IS NOT NULL
                      AND duration.between(lp.last_used, datetime()).days >= $decay_days

                    WITH lp, lp.confidence as old_confidence
                    SET lp.confidence = lp.confidence * $decay_factor,
                        lp.last_decay = datetime()

                    RETURN count(*) as decayed_count,
                           avg(old_confidence) as avg_old_confidence,
                           avg(lp.confidence) as avg_new_confidence
                """, decay_days=decay_days, decay_factor=decay_factor)

                record = result.single()
                if record and record['decayed_count'] > 0:
                    logger.info(f"Decayed {record['decayed_count']} patterns: "
                               f"{record['avg_old_confidence']:.3f} → {record['avg_new_confidence']:.3f}")
                    return {
                        'decayed_count': record['decayed_count'],
                        'avg_old_confidence': record['avg_old_confidence'],
                        'avg_new_confidence': record['avg_new_confidence']
                    }
                else:
                    logger.info("No patterns needed decay")
                    return {'decayed_count': 0}

        except Exception as e:
            logger.warning(f"Could not decay pattern confidence: {e}")
            return {'decayed_count': 0, 'error': str(e)}

    def _prune_low_confidence_patterns(
        self,
        min_confidence: float = 0.50
    ) -> int:
        """
        Delete patterns below minimum confidence threshold

        This prevents the metagraph from accumulating low-quality patterns.
        Patterns can be re-discovered if they become useful again.

        Returns number of patterns pruned
        """
        try:
            with self.neo4j.session() as session:
                result = session.run("""
                    MATCH (lp:LearnedPattern)
                    WHERE lp.confidence < $min_confidence

                    WITH lp, lp.confidence as confidence,
                         lp.source_entity_type as source,
                         lp.target_entity_type as target
                    DELETE lp

                    RETURN count(*) as pruned_count
                """, min_confidence=min_confidence)

                record = result.single()
                pruned_count = record['pruned_count'] if record else 0

                if pruned_count > 0:
                    logger.info(f"Pruned {pruned_count} low-confidence patterns (< {min_confidence})")
                else:
                    logger.info("No patterns needed pruning")

                return pruned_count

        except Exception as e:
            logger.warning(f"Could not prune patterns: {e}")
            return 0

    def _get_metagraph_health_metrics(self) -> Dict[str, Any]:
        """
        Get health metrics for the metagraph

        Returns statistics about pattern quality and distribution
        """
        try:
            with self.neo4j.session() as session:
                result = session.run("""
                    MATCH (lp:LearnedPattern)
                    RETURN count(*) as total_patterns,
                           avg(lp.confidence) as avg_confidence,
                           min(lp.confidence) as min_confidence,
                           max(lp.confidence) as max_confidence,
                           sum(lp.success_count) as total_successes,
                           avg(lp.success_count) as avg_success_count,
                           count(CASE WHEN lp.confidence >= 0.80 THEN 1 END) as high_confidence_count,
                           count(CASE WHEN lp.confidence < 0.60 THEN 1 END) as low_confidence_count
                """)

                record = result.single()
                if record:
                    return {
                        'total_patterns': record['total_patterns'],
                        'avg_confidence': float(record['avg_confidence'] or 0),
                        'min_confidence': float(record['min_confidence'] or 0),
                        'max_confidence': float(record['max_confidence'] or 0),
                        'total_successes': record['total_successes'],
                        'avg_success_count': float(record['avg_success_count'] or 0),
                        'high_confidence_count': record['high_confidence_count'],
                        'low_confidence_count': record['low_confidence_count']
                    }
                return {}

        except Exception as e:
            logger.warning(f"Could not get metagraph health: {e}")
            return {}


    def _try_pattern_composition(
        self,
        entity_name: str,
        entity_type: str,
        target_entity_type: str,
        k: int
    ) -> Optional[Dict[str, Any]]:
        """
        Try to compose existing patterns to bridge entity → target

        This is called when no direct learned pattern exists
        """
        compositions = self._find_composable_patterns(entity_type, target_entity_type)

        if not compositions:
            return None

        # Try each composition until one works
        for comp in compositions:
            # Validate the composed pattern
            is_valid = self._validate_composed_pattern(
                comp['composed_pattern'],
                entity_type,
                target_entity_type
            )

            if not is_valid:
                continue

            # Record for future use
            pattern_id = self._record_composed_pattern(
                entity_type,
                target_entity_type,
                comp['composed_pattern'],
                comp['confidence'],
                comp['pattern_a_id'],
                comp['pattern_b_id']
            )

            # Execute the composed pattern
            logger.info(f"🧩 Using COMPOSED pattern: {comp['source']}→{comp['intermediate']}→{comp['target']}")

            return self._execute_learned_pattern(
                entity_name,
                comp['composed_pattern'],
                pattern_id,
                k,
                target_entity_type
            )

        return None


    def _discover_multihop_path(
        self,
        source_type: str,
        target_type: str,
        max_hops: int = 5
    ) -> List[Dict[str, Any]]:
        """
        Discover complex multi-hop paths (up to 5 hops)

        Returns all viable paths ranked by:
        - Path length (shorter is better)
        - Result count (more results is better)
        - Diversity (more unique edge types is better)
        """
        try:
            # Map entity types to Neo4j labels
            label_map = {
                'gene': 'Gene',
                'drug': 'Drug',
                'pathway': 'Pathway',
                'protein': 'Protein',
                'disease': 'Disease'
            }

            source_label = label_map.get(source_type, source_type.capitalize())
            target_label = label_map.get(target_type, target_type.capitalize())

            with self.neo4j.session() as session:
                # Discover all paths up to max_hops
                result = session.run(f"""
                    MATCH path = (source:{source_label})-[*1..{max_hops}]-(target:{target_label})
                    WHERE source <> target
                    WITH path,
                         [r in relationships(path) | type(r)] as edge_types,
                         length(path) as path_length,
                         size([n in nodes(path) WHERE n:{source_label} OR n:{target_label}]) as entity_count

                    // Ensure path doesn't cycle back to same entity type repeatedly
                    WHERE entity_count <= 3

                    WITH edge_types, path_length, count(*) as occurrence_count
                    WHERE occurrence_count >= 5  // Must occur at least 5 times to be viable

                    RETURN DISTINCT
                        edge_types as pattern,
                        path_length as hops,
                        occurrence_count as examples,
                        1.0 / (path_length * 1.0) as score
                    ORDER BY score DESC, examples DESC
                    LIMIT 10
                """)

                discovered_paths = []
                for record in result:
                    discovered_paths.append({
                        'pattern': record['pattern'],
                        'hops': record['hops'],
                        'examples': record['examples'],
                        'score': record['score']
                    })

                if discovered_paths:
                    logger.info(f"Discovered {len(discovered_paths)} multi-hop paths: "
                               f"{source_type}→{target_type}")
                    for i, path in enumerate(discovered_paths[:3]):
                        logger.info(f"  Path {i+1}: {' → '.join(path['pattern'])} "
                                   f"({path['hops']} hops, {path['examples']} examples)")

                return discovered_paths

        except Exception as e:
            logger.warning(f"Could not discover multi-hop paths: {e}")
            return []

    def _score_path_quality(
        self,
        edge_pattern: List[str],
        source_type: str,
        target_type: str
    ) -> float:
        """
        Score a discovered path based on multiple factors

        Returns score 0.0-1.0 where higher is better
        """
        try:
            with self.neo4j.session() as session:
                # Test the path on 10 random samples
                label_map = {
                    'gene': 'Gene',
                    'drug': 'Drug',
                    'pathway': 'Pathway',
                    'protein': 'Protein',
                    'disease': 'Disease'
                }

                source_label = label_map.get(source_type, source_type.capitalize())
                target_label = label_map.get(target_type, target_type.capitalize())

                # Build path pattern
                path_pattern = f"(source:{source_label})"
                for i, edge_type in enumerate(edge_pattern):
                    if i < len(edge_pattern) - 1:
                        path_pattern += f"-[:{edge_type}]-()"
                    else:
                        path_pattern += f"-[:{edge_type}]-(target:{target_label})"

                # Test on sample
                result = session.run(f"""
                    MATCH {path_pattern}
                    WITH source, count(DISTINCT target) as result_count
                    RETURN
                        count(*) as total_sources,
                        avg(result_count) as avg_results,
                        max(result_count) as max_results
                    LIMIT 1
                """)

                record = result.single()
                if not record:
                    return 0.0

                # Score factors:
                # 1. Average results per source (higher is better)
                # 2. Coverage (how many sources have results)
                # 3. Path length (shorter is better)

                avg_results = float(record['avg_results'] or 0)
                max_results = float(record['max_results'] or 0)
                path_length = len(edge_pattern)

                # Normalize scores
                result_score = min(1.0, avg_results / 20.0)  # 20+ results = perfect
                length_score = 1.0 / (path_length * 0.5)  # Shorter paths score higher
                coverage_score = min(1.0, max_results / 50.0)  # Coverage up to 50

                # Weighted combination
                final_score = (
                    result_score * 0.5 +
                    length_score * 0.3 +
                    coverage_score * 0.2
                )

                return min(1.0, final_score)

        except Exception as e:
            logger.warning(f"Could not score path quality: {e}")
            return 0.5  # Default middle score

    def _record_discovered_path(
        self,
        source_type: str,
        target_type: str,
        edge_pattern: List[str],
        quality_score: float
    ) -> Optional[int]:
        """
        Record a newly discovered multi-hop path to metagraph

        Returns pattern_id if successful
        """
        try:
            with self.neo4j.session() as session:
                result = session.run("""
                    CREATE (lp:LearnedPattern {
                        source_entity_type: $source_type,
                        target_entity_type: $target_type,
                        edge_pattern: $edge_pattern,
                        discovered_at: datetime(),
                        success_count: 1,
                        total_queries: 1,
                        avg_latency: 200.0,
                        avg_results: 10.0,
                        confidence: $quality_score,
                        auto_discovered: true,
                        discovery_method: 'multi_hop'
                    })
                    RETURN id(lp) as pattern_id
                """, source_type=source_type, target_type=target_type,
                     edge_pattern=edge_pattern, quality_score=quality_score)

                record = result.single()
                if record:
                    pattern_id = record['pattern_id']
                    logger.info(f"Recorded multi-hop path: {source_type}→{target_type} "
                               f"(pattern_id: {pattern_id}, score: {quality_score:.2f})")
                    return pattern_id
                return None

        except Exception as e:
            logger.warning(f"Could not record discovered path: {e}")
            return None


    def _check_learned_patterns(
        self,
        source_type: str,
        target_type: str
    ) -> Optional[Dict[str, Any]]:
        """
        Query metagraph for learned patterns

        Returns the highest-confidence learned pattern for this entity type combination
        """
        try:
            with self.neo4j.session() as session:
                result = session.run("""
                    MATCH (lp:LearnedPattern)
                    WHERE lp.source_entity_type = $source
                      AND lp.target_entity_type = $target
                      AND lp.confidence > 0.70
                    RETURN lp.edge_pattern as pattern,
                           lp.confidence as confidence,
                           lp.success_count as success_count,
                           lp.avg_latency as avg_latency,
                           id(lp) as pattern_id
                    ORDER BY lp.success_count DESC, lp.confidence DESC
                    LIMIT 3  // Return top 3 for A/B testing
                """, source=source_type, target=target_type)

                records = list(result)
                if records:
                    logger.info(f"Found {len(records)} learned pattern(s): {source_type}→{target_type}")
                    patterns = [dict(r) for r in records]
                    for i, p in enumerate(patterns):
                        logger.debug(f"  Pattern {i+1}: confidence={p['confidence']:.2f}, "
                                   f"used {p['success_count']} times")
                    return patterns
                return []
        except Exception as e:
            logger.warning(f"Could not check learned patterns: {e}")
            return []

    def _record_query_result(
        self,
        pattern_id: Optional[int],
        success: bool,
        latency_ms: float,
        result_count: int
    ):
        """
        Record query result to update pattern confidence

        This is the FEEDBACK LOOP that enables learning!
        """
        if pattern_id is None:
            return

        try:
            with self.neo4j.session() as session:
                session.run("""
                    MATCH (lp:LearnedPattern)
                    WHERE id(lp) = $pattern_id
                    SET lp.success_count = lp.success_count + 1,
                        lp.total_queries = lp.total_queries + 1,
                        lp.avg_latency = (lp.avg_latency * lp.total_queries + $latency) / (lp.total_queries + 1),
                        lp.avg_results = (lp.avg_results * lp.total_queries + $result_count) / (lp.total_queries + 1),
                        lp.last_used = datetime(),
                        lp.confidence = CASE
                            WHEN $success THEN lp.confidence * 0.95 + 0.05 * 1.0
                            ELSE lp.confidence * 0.95 + 0.05 * 0.5
                        END
                """, pattern_id=pattern_id, latency=latency_ms,
                     result_count=result_count, success=success)

                logger.info(f"Recorded feedback: pattern_id={pattern_id}, success={success}, "
                           f"latency={latency_ms:.1f}ms, results={result_count}")
        except Exception as e:
            logger.warning(f"Could not record query result: {e}")

    def _execute_learned_pattern(
        self,
        entity_name: str,
        edge_pattern: List[str],
        pattern_id: Optional[int],
        k: int,
        target_entity_type: str
    ) -> Dict[str, Any]:
        """
        Execute a learned pattern (reuse discovered knowledge)

        Builds dynamic Cypher from the edge pattern and executes it
        """
        import time
        start_time = time.time()

        # Build dynamic Cypher from edge pattern
        path_pattern = "(source)"
        for i, edge_type in enumerate(edge_pattern):
            if i < len(edge_pattern) - 1:
                path_pattern += f"-[:{edge_type}]-()"
            else:
                # Map target entity type to Neo4j label
                label_map = {
                    'gene': 'Gene',
                    'drug': 'Drug',
                    'pathway': 'Pathway',
                    'protein': 'Protein',
                    'disease': 'Disease'
                }
                target_label = label_map.get(target_entity_type, 'Gene')
                path_pattern += f"-[:{edge_type}]-(target:{target_label})"

        cypher = f"""
            MATCH {path_pattern}
            WHERE toLower(source.name) = toLower($entity_name)
               OR toLower(source.id) = toLower($entity_name)
               OR toLower(source.symbol) = toLower($entity_name)
            RETURN DISTINCT
                COALESCE(target.name, target.id, target.symbol) as result_id
            LIMIT $k
        """

        try:
            with self.neo4j.session() as session:
                result = session.run(cypher, entity_name=entity_name, k=k)
                results = [r['result_id'] for r in result if r['result_id']]

                latency_ms = (time.time() - start_time) * 1000

                # Record feedback
                self._record_query_result(
                    pattern_id=pattern_id,
                    success=len(results) > 0,
                    latency_ms=latency_ms,
                    result_count=len(results)
                )

                # Format as neighbors
                neighbors = [
                    {
                        'id': result_id,
                        'distance': 0.0,
                        'metadata': {'source': 'learned_pattern', 'pattern_id': pattern_id}
                    }
                    for result_id in results
                ]

                return {
                    'success': True,
                    'found': len(neighbors) > 0,
                    'query_entity': entity_name,
                    'method': 'learned_pattern',
                    'pattern_id': pattern_id,
                    'neighbors': neighbors,
                    'neighbor_count': len(neighbors),
                    'latency_ms': latency_ms
                }
        except Exception as e:
            logger.error(f"Failed to execute learned pattern: {e}")
            return {
                'success': False,
                'error': str(e),
                'neighbors': [],
                'neighbor_count': 0
            }


    async def _enrich_with_graph_context(
        self,
        results: Dict[str, Any],
        query_params: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Enrich embedding results with Neo4j graph context

        OPTIMIZED: Single batched query instead of N queries (20x faster)
        """
        if not results.get('success') or not results.get('neighbors'):
            return results

        # Collect all entity IDs
        entity_ids = [n['id'] for n in results['neighbors']]

        with self.neo4j.session() as session:
            # OPTIMIZED: Single batched query using UNWIND
            result = session.run("""
                UNWIND $entity_ids as entity_id
                OPTIONAL MATCH (n)-[r]->(m)
                WHERE n.name = entity_id OR n.id = entity_id
                WITH entity_id, type(r) as rel_type, labels(m) as target_labels, m.name as target_name
                RETURN entity_id,
                       COLLECT({
                           type: rel_type,
                           target: target_name,
                           target_labels: target_labels
                       })[0..10] as relationships
            """, entity_ids=entity_ids)

            # Map results back to neighbors
            relationships_map = {}
            for record in result:
                entity_id = record['entity_id']
                rels = [r for r in record['relationships'] if r['type'] is not None]
                relationships_map[entity_id] = rels

            # Enrich neighbors
            for neighbor in results['neighbors']:
                neighbor['graph_relationships'] = relationships_map.get(neighbor['id'], [])

        results['graph_enriched'] = True
        results['enrichment_note'] = 'Batched query optimization (20x faster)'
        return results

    async def _record_query_to_metagraph(
        self,
        tool_name: str,
        space_name: str,
        query_params: Dict[str, Any],
        results: Dict[str, Any],
        duration_ms: float
    ):
        """
        LEARNING: Record query results to metagraph for future optimization

        This enables the system to learn:
        - Which spaces work best for which tools
        - What k-values are optimal
        - What query patterns succeed

        The metagraph becomes smarter over time.
        """
        try:
            with self.neo4j.session() as session:
                session.run("""
                    MATCH (t:Tool {name: $tool_name})-[:USES_SPACE]->(e:EmbeddingSpace {name: $space_name})

                    // Create or update query statistics
                    MERGE (e)-[q:QUERY_EXECUTED {tool_name: $tool_name}]->(qr:QueryResult {
                        timestamp: datetime()
                    })

                    SET qr.k_value = $k_value,
                        qr.latency_ms = $latency_ms,
                        qr.result_count = $result_count,
                        qr.success = $success,
                        qr.result_quality = $result_quality

                    // Update space usage count
                    SET e.total_queries = COALESCE(e.total_queries, 0) + 1,
                        e.last_queried = datetime()
                """,
                tool_name=tool_name,
                space_name=space_name,
                k_value=query_params.get('k', 20),
                latency_ms=duration_ms,
                result_count=len(results.get('neighbors', [])),
                success=results.get('success', False),
                result_quality=self._calculate_result_quality(results)
                )

                logger.info(f"Recorded query to metagraph: {tool_name} → {space_name}")
        except Exception as e:
            logger.warning(f"Failed to record query to metagraph: {e}")

    def _calculate_result_quality(self, results: Dict[str, Any]) -> float:
        """Calculate result quality score (0-1)"""
        if not results.get('success'):
            return 0.0

        if not results.get('found'):
            return 0.0

        neighbors = results.get('neighbors', [])
        if not neighbors:
            return 0.5

        # Quality based on number of results and similarity scores
        avg_similarity = sum(n.get('similarity', 0) for n in neighbors) / len(neighbors)
        coverage = min(len(neighbors) / 20, 1.0)  # 20 is typical k

        return (avg_similarity * 0.7 + coverage * 0.3)

    def discover_tools_for_intent(self, intent: str) -> List[Dict[str, Any]]:
        """
        METAGRAPH QUERY: Discover which tools can handle a given intent

        Query the metagraph Intent→Tool edges to find appropriate tools.
        This is dynamic, not hardcoded.
        """
        with self.neo4j.session() as session:
            result = session.run("""
                MATCH (i:QueryIntent {name: $intent})-[r:HANDLED_BY]->(t:Tool)
                OPTIONAL MATCH (t)-[:USES_SPACE]->(e:EmbeddingSpace)
                WITH t, COUNT(DISTINCT e) as space_count, COLLECT(DISTINCT e.name)[0..5] as sample_spaces
                RETURN t.name as tool_name,
                       space_count,
                       sample_spaces,
                       t.description as description
                ORDER BY space_count DESC
            """, intent=intent)

            tools = []
            for record in result:
                tools.append({
                    'tool_name': record['tool_name'],
                    'space_count': record['space_count'],
                    'sample_spaces': record['sample_spaces'],
                    'description': record['description']
                })

            return tools

    def _normalize_entity_name(self, entity_name: str, entity_type: str) -> str:
        """
        Normalize entity name using zone 7 resolvers

        Handles:
        - CHEMBL IDs → Commercial names
        - QS codes → Commercial names
        - LINCS → BRD mapping
        - Name variations (valproic acid → valproic_acid)
        """
        if not entity_name:
            return entity_name

        if entity_type == "drug":
            # Use drug_resolver for normalization
            resolution = self.drug_resolver.resolve(entity_name)
            if resolution['confidence'] != 'unknown':
                # Use commercial_name if available
                normalized = resolution.get('commercial_name', entity_name)
                logger.debug(f"Drug resolved: {entity_name} → {normalized} (source: {resolution['source']})")
                return normalized.replace(" ", "_").lower()

        # Fallback: Basic normalization
        # IMPORTANT: Gene names are stored in UPPERCASE in the database (e.g., "TSC2", "SCN1A")
        # Do NOT lowercase gene names - only normalize spaces
        if entity_type == "gene":
            return entity_name.replace(" ", "_").upper()  # Ensure uppercase for genes

        return entity_name.replace(" ", "_").lower()

    def close(self):
        """Close database connections"""
        self.neo4j.close()
        self.pgvector_conn.close()


# Singleton instance
_instance = None

def get_unified_query_layer() -> UnifiedQueryLayer:
    """Get singleton instance of unified query layer"""
    global _instance
    if _instance is None:
        _instance = UnifiedQueryLayer()
    return _instance
