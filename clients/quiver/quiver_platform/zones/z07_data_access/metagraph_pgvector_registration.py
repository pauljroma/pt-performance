#!/usr/bin/env python3
"""
PGVector Metagraph Registration
================================

Dynamic registration of PGVector embedding tables to Neo4j metagraph.

This script:
1. Queries PGVector information_schema for all embedding tables
2. Extracts metadata (dimensions, row count, entity type)
3. Creates/updates EmbeddingSpace nodes in Neo4j metagraph
4. Registers tables with quality_tier and pgvector_status

Key Innovation: Discovers tables dynamically from PGVector schema (NOT hardcoded)

Architecture:
- Source: PGVector (vector storage, discovery)
- Destination: Neo4j metagraph (metadata, intelligence)
- No hardcoded table lists - queries information_schema directly
- Infers entity_type and quality_tier from table naming patterns

Author: Quiver Platform - Metagraph Integration
Date: 2025-12-01
Version: 2.0 (Dynamic discovery via information_schema)
Zone: z07_data_access
"""

from typing import Dict, Any, List, Optional, Tuple
from neo4j import GraphDatabase
import psycopg2
from datetime import datetime
import logging
import sys

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class PGVectorMetagraphRegistration:
    """
    Register PGVector embedding tables to Neo4j metagraph

    Uses unified discovery pattern from unified_query_layer.py
    """

    def __init__(
        self,
        neo4j_uri: str = "bolt://localhost:7687",
        neo4j_auth: Tuple[str, str] = ("neo4j", "testpassword123"),
        pgvector_config: Dict = None
    ):
        """Initialize connections to Neo4j and PGVector"""

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

        # Statistics tracking
        self.stats = {
            "discovered": 0,
            "created": 0,
            "updated": 0,
            "skipped_empty": 0,
            "errors": []
        }

    def discover_pgvector_tables(self) -> List[Dict[str, Any]]:
        """
        Discover embedding tables from PGVector information_schema

        Queries information_schema.tables and information_schema.columns
        to find all tables with 'embedding' column.

        Returns:
            List of embedding table metadata
        """
        embedding_spaces = []

        try:
            with self.pgvector_conn.cursor() as cursor:
                # Query information_schema for tables with 'embedding' column
                # This discovers tables by pattern, not hardcoded list
                logger.info("Querying PGVector information_schema for embedding tables...")

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
                        OR t.table_name LIKE '%adr%'
                        OR t.table_name LIKE '%cto%'
                        OR t.table_name LIKE '%dgp%'
                        OR t.table_name LIKE '%dipole%'
                        OR t.table_name LIKE '%mop%'
                        OR t.table_name LIKE '%quadpole%'
                        OR t.table_name LIKE '%syn%'
                        OR t.table_name LIKE '%tripole%'
                    )
                    ORDER BY t.table_name
                """)

                candidate_tables = [(row[0], row[1]) for row in cursor.fetchall() if row[1] > 0]
                logger.info(f"Found {len(candidate_tables)} candidate tables with 'embedding' column")

                # For each table, extract metadata
                for table_name, _ in candidate_tables:
                    try:
                        # Get row count
                        cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
                        row_count = cursor.fetchone()[0]

                        if row_count == 0:
                            logger.debug(f"Skipping empty table: {table_name}")
                            self.stats["skipped_empty"] += 1
                            continue

                        # Get vector dimensions using pgvector's vector_dims() function
                        cursor.execute(f"""
                            SELECT vector_dims(embedding) as dimension
                            FROM {table_name}
                            WHERE embedding IS NOT NULL
                            LIMIT 1
                        """)

                        dim_result = cursor.fetchone()
                        if not dim_result or not dim_result[0]:
                            logger.debug(f"Could not determine dimension for {table_name}")
                            continue

                        dimension = dim_result[0]

                        # Infer entity type from table naming pattern
                        entity_type = self._infer_entity_type(table_name)

                        # Infer quality tier from version and type
                        quality_tier = self._infer_quality_tier(table_name)

                        # Infer priority (MODEX > ENS > LINCS > other)
                        priority = self._infer_priority(table_name)

                        # Create human-readable name
                        name = self._format_table_name(table_name)

                        embedding_space = {
                            'name': name,
                            'table_name': table_name,
                            'dimension': dimension,
                            'row_count': row_count,
                            'entity_type': entity_type,
                            'quality_tier': quality_tier,
                            'priority': priority,
                            'pgvector_status': 'loaded'
                        }

                        embedding_spaces.append(embedding_space)
                        self.stats["discovered"] += 1

                        logger.debug(f"Discovered: {table_name} ({dimension}D, {row_count:,} rows, {entity_type}, tier {quality_tier})")

                    except Exception as e:
                        logger.warning(f"Could not inspect table {table_name}: {e}")
                        self.stats["errors"].append(f"Inspection failed: {table_name}: {str(e)}")
                        continue

        except Exception as e:
            logger.error(f"Failed to discover PGVector tables: {e}")
            self.stats["errors"].append(f"Discovery failed: {str(e)}")

        logger.info(f"Discovered {len(embedding_spaces)} embedding spaces from PGVector")
        return embedding_spaces

    def _infer_entity_type(self, table_name: str) -> str:
        """Infer entity type from table naming pattern"""
        table_lower = table_name.lower()

        # Check for specific patterns
        if 'gene' in table_lower:
            return 'gene'
        elif 'drug' in table_lower:
            return 'drug'
        elif 'protein' in table_lower:
            return 'protein'
        elif 'pathway' in table_lower or 'mop' in table_lower:
            return 'pathway'
        elif 'disease' in table_lower or 'dgp' in table_lower:
            return 'disease'
        elif 'synapse' in table_lower or 'syn' in table_lower:
            return 'synapse'
        elif 'adverse' in table_lower or 'adr' in table_lower:
            return 'adverse_event'
        elif 'cell_type' in table_lower or 'cto' in table_lower:
            return 'cell_type'
        elif 'dipole' in table_lower:
            return 'dipole'
        elif 'quadpole' in table_lower:
            return 'quadpole'
        elif 'tripole' in table_lower:
            return 'tripole'
        else:
            return 'unknown'

    def _infer_quality_tier(self, table_name: str) -> str:
        """Infer quality tier from version and modex status"""
        table_lower = table_name.lower()

        # Higher versions → higher quality
        if 'v5' in table_lower:
            if 'v5_4' in table_lower or 'v5_5' in table_lower:
                return 'A'
            return 'A'
        elif 'v4' in table_lower:
            return 'B'
        elif 'v3' in table_lower:
            return 'C'
        else:
            # Default quality for unknown versions
            return 'B'

    def _infer_priority(self, table_name: str) -> str:
        """Infer priority: MODEX (primary) > ENS (fallback) > LINCS (fusion) > other"""
        table_lower = table_name.lower()

        if 'modex' in table_lower:
            return 'primary'
        elif 'ens' in table_lower:
            return 'fallback'
        elif 'lincs' in table_lower:
            return 'fusion'
        else:
            return 'enhancement'

    def _format_table_name(self, table_name: str) -> str:
        """Format table name into human-readable name"""
        # Convert snake_case to Title Case
        return table_name.replace('_', ' ').title()

    def register_to_metagraph(self, embedding_spaces: List[Dict[str, Any]]) -> None:
        """
        Register discovered embedding tables to Neo4j metagraph

        Creates or updates EmbeddingSpace nodes with full metadata
        """
        if not embedding_spaces:
            logger.warning("No embedding spaces to register")
            return

        logger.info(f"Registering {len(embedding_spaces)} embedding spaces to metagraph...")

        with self.neo4j.session() as session:
            for space in embedding_spaces:
                try:
                    # Check if already exists
                    result = session.run("""
                        MATCH (e:EmbeddingSpace)
                        WHERE toLower(e.name) = toLower($name)
                           OR toLower(e.table_name) = toLower($table_name)
                        RETURN e
                    """, name=space['name'], table_name=space['table_name'])

                    if result.single():
                        logger.debug(f"Updating existing: {space['table_name']}")

                        # Update existing node with latest metadata
                        session.run("""
                            MATCH (e:EmbeddingSpace)
                            WHERE toLower(e.table_name) = toLower($table_name)
                            SET e.dimension = $dimension,
                                e.row_count = $row_count,
                                e.entity_type = $entity_type,
                                e.quality_tier = $quality_tier,
                                e.priority = $priority,
                                e.pgvector_status = $pgvector_status,
                                e.last_synced = datetime()
                            RETURN e
                        """,
                        table_name=space['table_name'],
                        dimension=space['dimension'],
                        row_count=space['row_count'],
                        entity_type=space['entity_type'],
                        quality_tier=space['quality_tier'],
                        priority=space['priority'],
                        pgvector_status=space['pgvector_status'])

                        self.stats["updated"] += 1
                    else:
                        logger.debug(f"Creating new: {space['table_name']}")

                        # Create new EmbeddingSpace node
                        session.run("""
                            CREATE (e:EmbeddingSpace {
                                name: $name,
                                table_name: $table_name,
                                dimension: $dimension,
                                row_count: $row_count,
                                entity_type: $entity_type,
                                quality_tier: $quality_tier,
                                priority: $priority,
                                pgvector_status: $pgvector_status,
                                embedding_version: 'v5_0',
                                last_synced: datetime(),
                                created_at: datetime()
                            })
                        """,
                        name=space['name'],
                        table_name=space['table_name'],
                        dimension=space['dimension'],
                        row_count=space['row_count'],
                        entity_type=space['entity_type'],
                        quality_tier=space['quality_tier'],
                        priority=space['priority'],
                        pgvector_status=space['pgvector_status'])

                        self.stats["created"] += 1

                except Exception as e:
                    logger.error(f"Failed to register {space['table_name']}: {e}")
                    self.stats["errors"].append(f"Registration failed: {space['table_name']}: {str(e)}")

    def verify_registration(self) -> Dict[str, Any]:
        """
        Verify registration by querying Neo4j metagraph

        Returns:
            Verification statistics
        """
        logger.info("Verifying registration in metagraph...")

        with self.neo4j.session() as session:
            # Get total EmbeddingSpace nodes
            result = session.run("""
                MATCH (e:EmbeddingSpace)
                WHERE e.table_name IS NOT NULL
                RETURN COUNT(e) as total,
                       COUNT(DISTINCT e.entity_type) as entity_types,
                       AVG(e.dimension) as avg_dimension,
                       MAX(e.row_count) as max_rows
            """)

            stats = result.single()

            # Get breakdown by entity type
            result = session.run("""
                MATCH (e:EmbeddingSpace)
                WHERE e.table_name IS NOT NULL
                RETURN e.entity_type as entity_type,
                       COUNT(e) as count,
                       AVG(e.dimension) as avg_dim,
                       SUM(e.row_count) as total_rows
                ORDER BY count DESC
            """)

            breakdown = []
            for record in result:
                try:
                    avg_dim = record['avg_dim'] if record['avg_dim'] is not None else 0
                except (KeyError, TypeError):
                    avg_dim = 0
                try:
                    total_rows = record['total_rows'] if record['total_rows'] is not None else 0
                except (KeyError, TypeError):
                    total_rows = 0

                breakdown.append({
                    'entity_type': record['entity_type'],
                    'count': record['count'],
                    'avg_dimension': float(avg_dim),
                    'total_rows': int(total_rows)
                })

            # Get breakdown by quality tier
            result = session.run("""
                MATCH (e:EmbeddingSpace)
                WHERE e.table_name IS NOT NULL
                RETURN e.quality_tier as tier,
                       COUNT(e) as count
                ORDER BY tier DESC
            """)

            tiers = []
            for record in result:
                tiers.append({
                    'tier': record['tier'],
                    'count': record['count']
                })

            return {
                'total': stats['total'],
                'entity_types': stats['entity_types'],
                'avg_dimension': float(stats['avg_dimension']) if stats['avg_dimension'] else 0,
                'max_rows': stats['max_rows'],
                'by_entity_type': breakdown,
                'by_quality_tier': tiers
            }

    def print_summary(self, verification: Dict[str, Any]) -> None:
        """Print execution summary"""
        print("\n" + "="*80)
        print("PGVector Metagraph Registration Summary")
        print("="*80)

        print(f"\nDiscovery Statistics:")
        print(f"  Discovered:     {self.stats['discovered']}")
        print(f"  Created:        {self.stats['created']}")
        print(f"  Updated:        {self.stats['updated']}")
        print(f"  Skipped (empty):{self.stats['skipped_empty']}")
        print(f"  Errors:         {len(self.stats['errors'])}")

        if self.stats['errors']:
            print(f"\nErrors encountered:")
            for error in self.stats['errors']:
                print(f"  - {error}")

        print(f"\nMetagraph Verification:")
        print(f"  Total EmbeddingSpace nodes: {verification['total']}")
        print(f"  Entity types registered:    {verification['entity_types']}")
        print(f"  Average dimension:          {verification['avg_dimension']:.1f}D")
        print(f"  Max row count:              {verification['max_rows']:,}")

        print(f"\nBreakdown by Entity Type:")
        for item in verification['by_entity_type']:
            entity_type = item['entity_type'] or 'unknown'
            print(f"  {entity_type:20s} : {item['count']:3d} spaces, "
                  f"{item['avg_dimension']:5.1f}D avg, {item['total_rows']:,} total rows")

        print(f"\nBreakdown by Quality Tier:")
        for item in verification['by_quality_tier']:
            tier = item['tier'] or 'unknown'
            print(f"  Tier {tier}: {item['count']} spaces")

        print("\n" + "="*80)
        print("✅ PGVector embedding tables registered to metagraph!")
        print("="*80 + "\n")

    def run(self) -> int:
        """
        Execute complete registration workflow

        Returns:
            0 on success, 1 on failure
        """
        try:
            # Step 1: Discover tables from PGVector
            logger.info("Starting PGVector metagraph registration...")
            embedding_spaces = self.discover_pgvector_tables()

            if not embedding_spaces:
                logger.error("No embedding spaces discovered")
                return 1

            # Step 2: Register to metagraph
            self.register_to_metagraph(embedding_spaces)

            # Step 3: Verify registration
            verification = self.verify_registration()

            # Step 4: Print summary
            self.print_summary(verification)

            return 0

        except Exception as e:
            logger.error(f"Fatal error: {e}")
            return 1

        finally:
            self.close()

    def close(self):
        """Close database connections"""
        try:
            self.neo4j.close()
            self.pgvector_conn.close()
            logger.info("Database connections closed")
        except Exception as e:
            logger.warning(f"Error closing connections: {e}")


def main():
    """Main entry point"""
    registrar = PGVectorMetagraphRegistration()
    return registrar.run()


if __name__ == "__main__":
    sys.exit(main())
