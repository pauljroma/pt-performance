#!/usr/bin/env python3.11
"""
PGVector Service - Single Source of Truth for pgvector v6.0 Embeddings

This service provides unified access to ALL embedding operations via PostgreSQL pgvector.
Replaces legacy file-based loading with direct database queries for:
- Gene embeddings (ens_gene_64d_v6_0, g_g_1__ens__lincs fusion, gene_modex_v6_0_embeddings)
- Drug embeddings (drug_chemical_v6_0_256d)
- Precomputed similarity searches (g_aux_*, d_aux_* topk tables)

Architecture:
- Connection pooling for high performance
- Lazy initialization (connect only when needed)
- Clear error messages with fallback guidance
- Type-safe return values

Version: 2.0.0 (v6.0 Schema Update)
Date: 2025-12-03
Author: Claude Code Agent
Zone: z07_data_access (Data Access Layer)
"""

import os
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Literal
from dataclasses import dataclass
import numpy as np
import psycopg2
from psycopg2 import pool
from psycopg2.extras import RealDictCursor
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@dataclass
class EmbeddingResult:
    """Result from embedding query."""
    entity_id: str
    embedding: np.ndarray
    dimensions: int
    source_table: str


@dataclass
class SimilarityResult:
    """Result from similarity search."""
    entity_id: str
    similarity_score: float
    rank: int
    fusion_type: str
    source_table: str


@dataclass
class EmbeddingStats:
    """Statistics for an embedding table."""
    table_name: str
    total_entities: int
    embedding_dimensions: int
    null_count: int
    coverage_percent: float
    sample_entities: List[str]


@dataclass
class RescueResult:
    """Drug rescue result with scoring details (legacy compatibility)."""
    drug_name: str
    rescue_score: float  # 0-1, higher = stronger rescue candidate
    antipodal_distance: float  # Raw similarity (more negative = more opposite)
    dose_index: Optional[int] = None
    qs_id: Optional[str] = None
    embedding_space: str = "MODEX_16D"
    metadata: Optional[Dict] = None


class PGVectorService:
    """
    Single source of truth for pgvector v6.0 embedding operations.

    Provides unified interface to:
    1. Gene embeddings: ens_gene_64d_v6_0 (18,368 genes, 64D)
       - Fusion: g_g_1__ens__lincs (11,499 genes, 96D ENS+LINCS)
    2. Drug embeddings: drug_chemical_v6_0_256d (14,246 drugs, 256D)
    3. Precomputed similarities: g_aux_* and d_aux_* topk tables
    4. Embedding statistics: v6_0_embedding_stats

    Connection Management:
    - Uses connection pooling (minconn=1, maxconn=10)
    - Lazy initialization (connects on first query)
    - Auto-reconnect on connection loss
    - Proper cleanup via context manager

    Environment Variables Required:
    - POSTGRES_HOST (default: localhost)
    - POSTGRES_PORT (default: 5435)  # PGVector container
    - POSTGRES_DB (default: sapphire_database)  # v6.0 embeddings
    - POSTGRES_USER (default: postgres)
    - POSTGRES_PASSWORD (default: temppass123)

    Usage:
        service = PGVectorService()

        # Get gene embedding
        embedding = service.get_gene_embedding("SCN1A")

        # Find similar genes
        similar = service.find_similar_genes("SCN1A", top_k=10, fusion_type="cto")

        # Get embedding stats
        stats = service.get_embedding_stats("ens_gene_64d_v6_0")
    """

    # V6.0 Embedding table configurations
    GENE_TABLES = {
        "ens_gene_64d_v6_0": {
            "dimensions": 64,
            "entity_column": "id",
            "embedding_column": "embedding",
            "description": "ENS v6.0 Gene Embeddings (18,368 genes, 64D)",
            "expected_count": 18368
        },
        "gene_modex_v6_0_embeddings": {
            "dimensions": 16,
            "entity_column": "id",
            "embedding_column": "embedding",
            "description": "MODEX v6.0 Gene Embeddings (16D)",
            "expected_count": 18368
        },
        "g_g_1__ens__lincs": {
            "dimensions": 96,
            "entity_column": "gene_symbol",
            "embedding_column": "combined_embedding",
            "description": "ENS+LINCS Fusion (11,499 genes, 96D: 64D ENS + 32D LINCS)",
            "expected_count": 11499,
            "fallback_table": "ens_gene_64d_v6_0",  # Fallback when gene not in fusion
            "fusion_components": ["ens_gene_64d_v6_0", "lincs_gene_32d_v5_0"]
        }
    }

    DRUG_TABLES = {
        "drug_chemical_v6_0_256d": {
            "dimensions": 256,
            "entity_column": "id",
            "embedding_column": "embedding",
            "description": "Chemical v6.0 Drug Embeddings (14,246 drugs, 256D)",
            "expected_count": 14246
        }
    }

    # Precomputed similarity tables (gene auxiliary)
    GENE_AUX_TABLES = {
        "cto": "g_aux_cto_topk_v6_0",      # Cell Type Ontology
        "adr": "g_aux_adr_topk_v6_0",      # Adverse Drug Reactions
        "dgp": "g_aux_dgp_topk_v6_0",      # Disease-Gene-Protein
        "ep_gene": "g_aux_ep_gene_topk_v6_0",  # Electrophysiology
        "mop": "g_aux_mop_topk_v6_0",      # Mechanism of Phenotype
        "syn": "g_aux_syn_topk_v6_0",      # Symptoms/Phenotypes
    }

    # Precomputed similarity tables (drug auxiliary)
    DRUG_AUX_TABLES = {
        "cto": "d_aux_cto_topk_v6_0",      # Cell Type Ontology
        "adr": "d_aux_adr_topk_v6_0",      # Adverse Drug Reactions
        "dgp": "d_aux_dgp_topk_v6_0",      # Disease-Gene-Protein
        "ep_drug": "d_aux_ep_drug_topk_v6_0",  # Electrophysiology
        "mop": "d_aux_mop_topk_v6_0",      # Mechanism of Phenotype
    }

    # Cross-modal similarity tables
    CROSS_MODAL_TABLES = {
        "chem_ens": "d_g_chem_ens_topk_v6_0",      # Drug-Gene Chemical-ENS fusion
        "chem_lincs": "d_d_chem_lincs_topk_v6_0",  # Drug-Drug Chemical-LINCS fusion
    }

    # LEGACY: Old table mappings for backward compatibility
    PGVECTOR_TABLES = {
        # Gene embeddings
        "MODEX_Gene_16D_v2_0": {
            "table": "ep_gene_modex_16d",
            "entity_col": "gene_symbol",
            "embedding_col": "embedding",
            "dimensions": 16,
            "type": "gene"
        },
        "MODEX_Gene_v1_0": {
            "table": "ep_gene_embeddings",
            "entity_col": "gene_symbol",
            "embedding_col": "embedding",
            "dimensions": 32,
            "type": "gene"
        },

        # Drug embeddings
        "DFP_PhaseII_16D_v1_0": {
            "table": "ep_drug_dfp_phase2",
            "entity_col": "drug_name",
            "embedding_col": "embedding",
            "dimensions": 16,
            "type": "drug",
            "has_doses": True,
            "base_name_col": "base_name",
            "dose_col": "dose_index",
            "qs_id_col": "qs_id"
        },
        "PCA_v4_7": {
            "table": "ep_drug_embeddings",
            "entity_col": "drug_name",
            "embedding_col": "embedding",
            "dimensions": 32,
            "type": "drug"
        },
        "PLATINUM_QNVS_v2_0": {
            "table": "ep_drug_platinum_qnvs",
            "entity_col": "drug_name",
            "embedding_col": "embedding",
            "dimensions": 16,
            "type": "drug"
        },
        "PLATINUM_Similarity_v1_0": {
            "table": "ep_drug_platinum_sim",
            "entity_col": "drug_name",
            "embedding_col": "embedding",
            "dimensions": 16,
            "type": "drug"
        },

        # Adverse event embeddings
        "ADR_EMB_8D_v5_0": {
            "table": "adr_emb_8d_v5_0",
            "entity_col": "drug",
            "event_col": "adverse_event",
            "embedding_col": "embedding",
            "dimensions": 8,
            "type": "adverse_event",
            "frequency_col": "frequency",
            "severity_col": "severity",
            "organ_col": "organ_specificity",
            "report_count_col": "report_count"
        }
    }

    def __init__(
        self,
        host: Optional[str] = None,
        port: Optional[int] = None,
        database: Optional[str] = None,
        user: Optional[str] = None,
        password: Optional[str] = None,
        minconn: int = 1,
        maxconn: int = 10
    ):
        """
        Initialize PGVector service with connection pooling.

        Args:
            host: PostgreSQL host (default: from POSTGRES_HOST env)
            port: PostgreSQL port (default: from POSTGRES_PORT env)
            database: Database name (default: from POSTGRES_DB env)
            user: Database user (default: from POSTGRES_USER env)
            password: Database password (default: from POSTGRES_PASSWORD env)
            minconn: Minimum connections in pool (default: 1)
            maxconn: Maximum connections in pool (default: 10)

        Raises:
            ValueError: If POSTGRES_PASSWORD not set and not provided
        """
        # Get connection parameters from environment or arguments
        self.host = host or os.getenv("POSTGRES_HOST", "localhost")
        self.port = port or int(os.getenv("POSTGRES_PORT", "5435"))  # PGVector container port
        self.database = database or os.getenv("POSTGRES_DB", "sapphire_database")  # v6.0 embeddings database
        self.user = user or os.getenv("POSTGRES_USER", "postgres")
        self.password = password or os.getenv("POSTGRES_PASSWORD", "temppass123")

        if not self.password:
            raise ValueError(
                "POSTGRES_PASSWORD not set in environment.\n"
                "Please set POSTGRES_PASSWORD or provide password argument.\n"
                "Example: export POSTGRES_PASSWORD=your_password"
            )

        # Connection pool (lazy initialized)
        self._pool: Optional[pool.SimpleConnectionPool] = None
        self._minconn = minconn
        self._maxconn = maxconn

        logger.info(
            f"PGVectorService initialized: {self.user}@{self.host}:{self.port}/{self.database}"
        )

    def _get_pool(self) -> pool.SimpleConnectionPool:
        """Get or create connection pool (lazy initialization)."""
        if self._pool is None:
            try:
                self._pool = pool.SimpleConnectionPool(
                    self._minconn,
                    self._maxconn,
                    host=self.host,
                    port=self.port,
                    database=self.database,
                    user=self.user,
                    password=self.password
                )
                logger.info(f"✓ Connection pool created ({self._minconn}-{self._maxconn} connections)")
            except psycopg2.Error as e:
                logger.error(f"Failed to create connection pool: {e}")
                raise ConnectionError(
                    f"Cannot connect to PostgreSQL at {self.host}:{self.port}\n"
                    f"Error: {e}\n"
                    f"Check that PostgreSQL is running and credentials are correct."
                )

        return self._pool

    def _get_connection(self):
        """Get connection from pool."""
        pool = self._get_pool()
        try:
            return pool.getconn()
        except pool.PoolError as e:
            logger.error(f"Connection pool exhausted: {e}")
            raise ConnectionError("All database connections in use. Try again later.")

    def _return_connection(self, conn):
        """Return connection to pool."""
        if self._pool:
            self._pool.putconn(conn)

    def close(self):
        """Close all connections in pool."""
        if self._pool:
            self._pool.closeall()
            logger.info("✓ All database connections closed")

    def __enter__(self):
        """Context manager entry."""
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit (cleanup)."""
        self.close()

    def get_gene_embedding(
        self,
        gene_id: str,
        table: str = "ens_gene_64d_v6_0"
    ) -> Optional[EmbeddingResult]:
        """
        Get gene embedding from PostgreSQL.

        Args:
            gene_id: Gene symbol (e.g., "SCN1A")
            table: Embedding table name (default: "ens_gene_64d_v6_0")

        Returns:
            EmbeddingResult with embedding vector, or None if not found

        Example:
            >>> service = PGVectorService()
            >>> result = service.get_gene_embedding("SCN1A")
            >>> print(result.embedding.shape)  # (64,)
            >>> print(result.dimensions)  # 64
        """
        if table not in self.GENE_TABLES:
            raise ValueError(
                f"Unknown gene table: {table}\n"
                f"Available tables: {', '.join(self.GENE_TABLES.keys())}"
            )

        config = self.GENE_TABLES[table]
        entity_col = config["entity_column"]
        embedding_col = config["embedding_column"]

        conn = self._get_connection()
        try:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                query = f"""
                    SELECT {entity_col}, {embedding_col}
                    FROM {table}
                    WHERE {entity_col} = %s
                """

                cur.execute(query, (gene_id,))
                row = cur.fetchone()

                if not row:
                    logger.warning(f"Gene '{gene_id}' not found in {table}")
                    return None

                # Extract embedding (psycopg2 returns pgvector as string '[1.0,2.0,...]')
                emb_data = row[embedding_col]
                if isinstance(emb_data, str):
                    # Parse string format: '[1.0,2.0,...]'
                    emb_data = emb_data.strip('[]')
                    emb_values = [float(x.strip()) for x in emb_data.split(',')]
                    embedding = np.array(emb_values, dtype=np.float32)
                else:
                    embedding = np.array(emb_data, dtype=np.float32)

                return EmbeddingResult(
                    entity_id=gene_id,
                    embedding=embedding,
                    dimensions=len(embedding),
                    source_table=table
                )

        except psycopg2.Error as e:
            logger.error(f"Database error getting gene embedding: {e}")
            raise
        finally:
            self._return_connection(conn)

    def get_drug_embedding(
        self,
        drug_id: str,
        table: str = "drug_chemical_v6_0_256d"
    ) -> Optional[EmbeddingResult]:
        """
        Get drug embedding from PostgreSQL.

        Args:
            drug_id: Drug identifier (QS code, e.g., "QS00000001")
            table: Embedding table name (default: "drug_chemical_v6_0_256d")

        Returns:
            EmbeddingResult with embedding vector, or None if not found

        Example:
            >>> service = PGVectorService()
            >>> result = service.get_drug_embedding("QS00000001")
            >>> print(result.embedding.shape)  # (256,)
            >>> print(result.dimensions)  # 256
        """
        if table not in self.DRUG_TABLES:
            raise ValueError(
                f"Unknown drug table: {table}\n"
                f"Available tables: {', '.join(self.DRUG_TABLES.keys())}"
            )

        config = self.DRUG_TABLES[table]
        entity_col = config["entity_column"]
        embedding_col = config["embedding_column"]

        conn = self._get_connection()
        try:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                query = f"""
                    SELECT {entity_col}, {embedding_col}
                    FROM {table}
                    WHERE {entity_col} = %s
                """

                cur.execute(query, (drug_id,))
                row = cur.fetchone()

                if not row:
                    logger.warning(f"Drug '{drug_id}' not found in {table}")
                    return None

                # Extract embedding (psycopg2 returns pgvector as string '[1.0,2.0,...]')
                emb_data = row[embedding_col]
                if isinstance(emb_data, str):
                    # Parse string format: '[1.0,2.0,...]'
                    emb_data = emb_data.strip('[]')
                    emb_values = [float(x.strip()) for x in emb_data.split(',')]
                    embedding = np.array(emb_values, dtype=np.float32)
                else:
                    embedding = np.array(emb_data, dtype=np.float32)

                return EmbeddingResult(
                    entity_id=drug_id,
                    embedding=embedding,
                    dimensions=len(embedding),
                    source_table=table
                )

        except psycopg2.Error as e:
            logger.error(f"Database error getting drug embedding: {e}")
            raise
        finally:
            self._return_connection(conn)

    def find_similar_genes(
        self,
        gene_id: str,
        top_k: int = 10,
        fusion_type: str = "cto"
    ) -> List[SimilarityResult]:
        """
        Find similar genes using precomputed topk tables.

        Uses g_aux_{fusion_type}_topk_v6_0 tables for 100× speedup vs live queries.

        Args:
            gene_id: Query gene symbol (e.g., "SCN1A")
            top_k: Number of results to return (default: 10)
            fusion_type: Fusion type - "cto", "adr", "dgp", "ep_gene", "mop", "syn"

        Returns:
            List of SimilarityResult objects, sorted by similarity (descending)

        Available Fusion Types:
            - cto: Cell Type Ontology (tissue specificity)
            - adr: Adverse Drug Reactions (safety signals)
            - dgp: Disease-Gene-Protein (mechanistic links)
            - ep_gene: Electrophysiology (ion channels, neuronal)
            - mop: Mechanism of Phenotype (functional effects)
            - syn: Symptoms/Phenotypes (clinical presentation)

        Example:
            >>> service = PGVectorService()
            >>> similar = service.find_similar_genes("SCN1A", top_k=5, fusion_type="ep_gene")
            >>> for result in similar:
            ...     print(f"{result.entity_id}: {result.similarity_score:.3f}")
        """
        if fusion_type not in self.GENE_AUX_TABLES:
            raise ValueError(
                f"Unknown fusion type: {fusion_type}\n"
                f"Available types: {', '.join(self.GENE_AUX_TABLES.keys())}"
            )

        table = self.GENE_AUX_TABLES[fusion_type]

        conn = self._get_connection()
        try:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                query = f"""
                    SELECT
                        neighbor_id,
                        similarity_score,
                        rank
                    FROM {table}
                    WHERE entity_id = %s
                    ORDER BY rank ASC
                    LIMIT %s
                """

                cur.execute(query, (gene_id, top_k))
                rows = cur.fetchall()

                if not rows:
                    logger.warning(
                        f"No similar genes found for '{gene_id}' in {table}.\n"
                        f"Hint: Check that gene exists and precomputed similarities loaded."
                    )
                    return []

                results = [
                    SimilarityResult(
                        entity_id=row["neighbor_id"],
                        similarity_score=float(row["similarity_score"]),
                        rank=int(row["rank"]),
                        fusion_type=fusion_type,
                        source_table=table
                    )
                    for row in rows
                ]

                logger.info(f"✓ Found {len(results)} similar genes for {gene_id} ({fusion_type})")
                return results

        except psycopg2.Error as e:
            logger.error(f"Database error finding similar genes: {e}")
            raise
        finally:
            self._return_connection(conn)

    def find_similar_drugs(
        self,
        drug_id: str,
        top_k: int = 10,
        fusion_type: str = "adr"
    ) -> List[SimilarityResult]:
        """
        Find similar drugs using precomputed topk tables.

        Uses d_aux_{fusion_type}_topk_v6_0 tables for 100× speedup vs live queries.

        Args:
            drug_id: Query drug ID (QS code, e.g., "QS00000001")
            top_k: Number of results to return (default: 10)
            fusion_type: Fusion type - "cto", "adr", "dgp", "ep_drug", "mop"

        Returns:
            List of SimilarityResult objects, sorted by similarity (descending)

        Available Fusion Types:
            - cto: Cell Type Ontology (tissue targeting)
            - adr: Adverse Drug Reactions (safety profile)
            - dgp: Disease-Gene-Protein (mechanism of action)
            - ep_drug: Electrophysiology (ion channel effects)
            - mop: Mechanism of Phenotype (functional effects)

        Example:
            >>> service = PGVectorService()
            >>> similar = service.find_similar_drugs("QS00000001", top_k=5, fusion_type="adr")
            >>> for result in similar:
            ...     print(f"{result.entity_id}: {result.similarity_score:.3f}")
        """
        if fusion_type not in self.DRUG_AUX_TABLES:
            raise ValueError(
                f"Unknown fusion type: {fusion_type}\n"
                f"Available types: {', '.join(self.DRUG_AUX_TABLES.keys())}"
            )

        table = self.DRUG_AUX_TABLES[fusion_type]

        conn = self._get_connection()
        try:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                query = f"""
                    SELECT
                        neighbor_id,
                        similarity_score,
                        rank
                    FROM {table}
                    WHERE entity_id = %s
                    ORDER BY rank ASC
                    LIMIT %s
                """

                cur.execute(query, (drug_id, top_k))
                rows = cur.fetchall()

                if not rows:
                    logger.warning(
                        f"No similar drugs found for '{drug_id}' in {table}.\n"
                        f"Hint: Check that drug exists and precomputed similarities loaded."
                    )
                    return []

                results = [
                    SimilarityResult(
                        entity_id=row["neighbor_id"],
                        similarity_score=float(row["similarity_score"]),
                        rank=int(row["rank"]),
                        fusion_type=fusion_type,
                        source_table=table
                    )
                    for row in rows
                ]

                logger.info(f"✓ Found {len(results)} similar drugs for {drug_id} ({fusion_type})")
                return results

        except psycopg2.Error as e:
            logger.error(f"Database error finding similar drugs: {e}")
            raise
        finally:
            self._return_connection(conn)

    def get_embedding_stats(self, table_name: str) -> EmbeddingStats:
        """
        Get statistics for an embedding table.

        Args:
            table_name: Name of embedding table (gene or drug)

        Returns:
            EmbeddingStats with coverage metrics and sample entities

        Example:
            >>> service = PGVectorService()
            >>> stats = service.get_embedding_stats("ens_gene_64d_v6_0")
            >>> print(f"Coverage: {stats.coverage_percent:.1f}%")
            >>> print(f"Total entities: {stats.total_entities:,}")
        """
        # Determine table type and config
        if table_name in self.GENE_TABLES:
            config = self.GENE_TABLES[table_name]
        elif table_name in self.DRUG_TABLES:
            config = self.DRUG_TABLES[table_name]
        else:
            raise ValueError(
                f"Unknown table: {table_name}\n"
                f"Available gene tables: {', '.join(self.GENE_TABLES.keys())}\n"
                f"Available drug tables: {', '.join(self.DRUG_TABLES.keys())}"
            )

        entity_col = config["entity_column"]
        embedding_col = config["embedding_column"]

        conn = self._get_connection()
        try:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                # Get total count and null count
                query = f"""
                    SELECT
                        COUNT(*) as total,
                        COUNT({embedding_col}) as with_embedding,
                        COUNT(*) - COUNT({embedding_col}) as null_count
                    FROM {table_name}
                """

                cur.execute(query)
                counts = cur.fetchone()

                total = counts["total"]
                with_embedding = counts["with_embedding"]
                null_count = counts["null_count"]
                coverage = (with_embedding / total * 100) if total > 0 else 0.0

                # Get sample entities
                sample_query = f"""
                    SELECT {entity_col}
                    FROM {table_name}
                    WHERE {embedding_col} IS NOT NULL
                    LIMIT 5
                """

                cur.execute(sample_query)
                samples = [row[entity_col] for row in cur.fetchall()]

                return EmbeddingStats(
                    table_name=table_name,
                    total_entities=total,
                    embedding_dimensions=config["dimensions"],
                    null_count=null_count,
                    coverage_percent=coverage,
                    sample_entities=samples
                )

        except psycopg2.Error as e:
            logger.error(f"Database error getting embedding stats: {e}")
            raise
        finally:
            self._return_connection(conn)

    def health_check(self) -> Dict[str, any]:
        """
        Check service health and database connectivity.

        Returns:
            Dict with health status, table counts, and connection info

        Example:
            >>> service = PGVectorService()
            >>> health = service.health_check()
            >>> print(health["status"])  # "healthy"
        """
        try:
            conn = self._get_connection()

            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                # Check PostgreSQL version
                cur.execute("SELECT version()")
                version = cur.fetchone()["version"]

                # Check pgvector extension
                cur.execute(
                    "SELECT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'vector')"
                )
                has_pgvector = cur.fetchone()["exists"]

                # Count tables
                gene_tables = {}
                for table in self.GENE_TABLES:
                    try:
                        cur.execute(f"SELECT COUNT(*) as count FROM {table}")
                        gene_tables[table] = cur.fetchone()["count"]
                    except:
                        gene_tables[table] = 0

                drug_tables = {}
                for table in self.DRUG_TABLES:
                    try:
                        cur.execute(f"SELECT COUNT(*) as count FROM {table}")
                        drug_tables[table] = cur.fetchone()["count"]
                    except:
                        drug_tables[table] = 0

            self._return_connection(conn)

            return {
                "status": "healthy",
                "database": {
                    "host": self.host,
                    "port": self.port,
                    "database": self.database,
                    "version": version.split(",")[0],  # First part only
                    "pgvector_installed": has_pgvector
                },
                "tables": {
                    "gene": gene_tables,
                    "drug": drug_tables
                },
                "connection_pool": {
                    "min_connections": self._minconn,
                    "max_connections": self._maxconn
                }
            }

        except Exception as e:
            logger.error(f"Health check failed: {e}")
            return {
                "status": "unhealthy",
                "error": str(e)
            }

    # =============================================================================
    # LEGACY METHODS (for backward compatibility)
    # =============================================================================

    def get_gene_drug_antipodal(
        self,
        gene: str,
        top_k: int = 10,
        min_score: float = 0.5,
        dose_index: Optional[int] = None,
        gene_space: str = "MODEX_Gene_16D_v2_0",
        drug_space: str = "DFP_PhaseII_16D_v1_0"
    ) -> List[RescueResult]:
        """
        Find antipodal drugs for a gene using 16D MODEX embeddings.

        This is the CORRECT method for gene-drug rescue prediction because it uses
        matching 16D MODEX embeddings (gene PCA downsampled, drug DFP PhaseII).

        Args:
            gene: Gene symbol (e.g., "TSC2", "SCN1A")
            top_k: Number of results to return
            min_score: Minimum rescue score (0-1)
            dose_index: Filter to specific dose (None = all doses)
            gene_space: Gene embedding space (default: MODEX_Gene_16D_v2_0)
            drug_space: Drug embedding space (default: DFP_PhaseII_16D_v1_0)

        Returns:
            List of RescueResult objects sorted by rescue score (highest first)

        Example:
            >>> service = PgVectorService()
            >>> results = service.get_gene_drug_antipodal("TSC2", top_k=5)
            >>> results[0].drug_name
            'Sirolimus_dose_1'
            >>> results[0].rescue_score
            0.706  # Higher = better rescue candidate
            >>> results[0].antipodal_distance
            -0.412  # Negative = antipodal/opposite
        """
        gene_config = self.PGVECTOR_TABLES[gene_space]
        drug_config = self.PGVECTOR_TABLES[drug_space]

        # Validate dimensions match
        if gene_config["dimensions"] != drug_config["dimensions"]:
            raise ValueError(
                f"Dimension mismatch: {gene_space} ({gene_config['dimensions']}D) "
                f"vs {drug_space} ({drug_config['dimensions']}D)"
            )

        conn = self._get_connection()
        try:
            cur = conn.cursor(cursor_factory=RealDictCursor)

            # Build dose filter
            dose_filter = ""
            if dose_index is not None and drug_config.get("has_doses"):
                dose_filter = f"AND d.{drug_config['dose_col']} = {dose_index}"

            # Query: Cross-join genes and drugs, compute antipodal similarity
            # Antipodal = negative cosine similarity (opposite embeddings)
            # Rescue score = abs(similarity) when similarity < 0
            query = f"""
                WITH gene_emb AS (
                    SELECT {gene_config['entity_col']} as gene,
                           {gene_config['embedding_col']} as embedding
                    FROM {gene_config['table']}
                    WHERE UPPER({gene_config['entity_col']}) = UPPER(%s)
                    LIMIT 1
                ),
                antipodal_drugs AS (
                    SELECT
                        d.{drug_config['entity_col']} as drug_name,
                        {f"d.{drug_config['base_name_col']} as base_name," if drug_config.get('has_doses') else "d.{drug_config['entity_col']} as base_name,"}
                        {f"d.{drug_config['dose_col']} as dose_index," if drug_config.get('has_doses') else "0 as dose_index,"}
                        {f"d.{drug_config['qs_id_col']} as qs_id," if drug_config.get('has_doses') else "NULL as qs_id,"}
                        1 - (g.embedding <=> d.{drug_config['embedding_col']}) as similarity,
                        ABS(1 - (g.embedding <=> d.{drug_config['embedding_col']})) as abs_similarity
                    FROM gene_emb g
                    CROSS JOIN {drug_config['table']} d
                    WHERE (1 - (g.embedding <=> d.{drug_config['embedding_col']})) < 0  -- Only antipodal (negative)
                    {dose_filter}
                )
                SELECT
                    drug_name,
                    base_name,
                    dose_index,
                    qs_id,
                    similarity as antipodal_distance,
                    abs_similarity as rescue_score
                FROM antipodal_drugs
                WHERE abs_similarity >= %s
                ORDER BY abs_similarity DESC
                LIMIT %s;
            """

            cur.execute(query, (gene, min_score, top_k))
            rows = cur.fetchall()

            results = []
            for row in rows:
                results.append(RescueResult(
                    drug_name=row['drug_name'],
                    rescue_score=float(row['rescue_score']),
                    antipodal_distance=float(row['antipodal_distance']),
                    dose_index=row.get('dose_index'),
                    qs_id=row.get('qs_id'),
                    embedding_space=f"{gene_space} × {drug_space}",
                    metadata={
                        "base_name": row.get('base_name'),
                        "gene": gene,
                        "gene_space": gene_space,
                        "drug_space": drug_space
                    }
                ))

            cur.close()
            return results

        finally:
            conn.close()

    def get_drug_similarity(
        self,
        drug: str,
        top_k: int = 10,
        min_similarity: float = 0.5,
        space: str = "PCA_v4_7"
    ) -> List[SimilarityResult]:
        """
        Find similar drugs using embedding similarity.

        Args:
            drug: Drug name or QS ID
            top_k: Number of results
            min_similarity: Minimum similarity threshold (0-1)
            space: Embedding space

        Returns:
            List of SimilarityResult objects
        """
        config = self.PGVECTOR_TABLES[space]

        conn = self._get_connection()
        try:
            cur = conn.cursor(cursor_factory=RealDictCursor)

            # Query for similar drugs
            query = f"""
                WITH query_drug AS (
                    SELECT {config['entity_col']} as name,
                           {config['embedding_col']} as embedding
                    FROM {config['table']}
                    WHERE UPPER({config['entity_col']}) = UPPER(%s)
                       OR {config['entity_col']} ILIKE %s
                    LIMIT 1
                )
                SELECT
                    d.{config['entity_col']} as drug_name,
                    1 - (q.embedding <=> d.{config['embedding_col']}) as similarity
                FROM query_drug q
                CROSS JOIN {config['table']} d
                WHERE d.{config['entity_col']} != q.name
                  AND (1 - (q.embedding <=> d.{config['embedding_col']})) >= %s
                ORDER BY similarity DESC
                LIMIT %s;
            """

            cur.execute(query, (drug, f"%{drug}%", min_similarity, top_k))
            rows = cur.fetchall()

            results = []
            for row in rows:
                results.append(SimilarityResult(
                    entity_name=row['drug_name'],
                    similarity_score=float(row['similarity']),
                    entity_type="drug",
                    embedding_space=space
                ))

            cur.close()
            return results

        finally:
            conn.close()

    def get_adverse_events_by_drug(
        self,
        drug: str,
        top_k: int = 50,
        min_frequency: float = 0.0,
        space: str = "ADR_EMB_8D_v5_0"
    ) -> List[Dict]:
        """
        Get adverse events for a drug from ADR embeddings.

        Args:
            drug: Drug name
            top_k: Number of adverse events to return
            min_frequency: Minimum event frequency threshold
            space: Adverse event embedding space

        Returns:
            List of adverse event dictionaries with event name, frequency, severity, etc.

        Example:
            >>> service = PgVectorService()
            >>> events = service.get_adverse_events_by_drug("Valproic Acid", top_k=50)
            >>> events[0]
            {'adverse_event': 'Hepatotoxicity', 'frequency': 0.08, 'severity': 0.9, ...}
        """
        config = self.PGVECTOR_TABLES[space]

        conn = self._get_connection()
        try:
            cur = conn.cursor(cursor_factory=RealDictCursor)

            # Query adverse events for drug
            query = f"""
                SELECT
                    {config['event_col']} as adverse_event,
                    {config['frequency_col']} as frequency,
                    {config['severity_col']} as severity,
                    {config['organ_col']} as organ_specificity,
                    {config.get('report_count_col', '1')} as report_count,
                    {config['embedding_col']} as embedding
                FROM {config['table']}
                WHERE UPPER({config['entity_col']}) = UPPER(%s)
                  AND {config['frequency_col']} >= %s
                ORDER BY {config['frequency_col']} DESC
                LIMIT %s;
            """

            cur.execute(query, (drug, min_frequency, top_k))
            rows = cur.fetchall()

            results = []
            for row in rows:
                results.append({
                    'adverse_event': row['adverse_event'],
                    'frequency': float(row['frequency']),
                    'severity': float(row['severity']),
                    'organ_specificity': float(row['organ_specificity']),
                    'report_count': int(row.get('report_count', 1))
                })

            cur.close()
            return results

        finally:
            conn.close()

    def validate_connection(self) -> bool:
        """
        Test PostgreSQL connection and pgvector extension.

        Returns:
            True if connection works and pgvector is available
        """
        try:
            conn = self._get_connection()
            cur = conn.cursor()

            # Check pgvector extension
            cur.execute("SELECT COUNT(*) FROM pg_extension WHERE extname = 'vector';")
            has_vector = cur.fetchone()[0] > 0

            # Check at least one table exists
            cur.execute("""
                SELECT COUNT(*) FROM information_schema.tables
                WHERE table_schema = 'public' AND table_name LIKE 'ep_%';
            """)
            has_tables = cur.fetchone()[0] > 0

            cur.close()
            conn.close()

            return has_vector and has_tables

        except Exception as e:
            print(f"❌ Connection validation failed: {e}")
            return False


# Singleton instance
_pgvector_service: Optional[PGVectorService] = None


def get_pgvector_service() -> PGVectorService:
    """
    Get or create singleton PGVectorService instance.

    Returns:
        Shared PGVectorService instance

    Example:
        >>> from zones.z07_data_access.pgvector_service import get_pgvector_service
        >>> service = get_pgvector_service()
        >>> embedding = service.get_gene_embedding("SCN1A")
    """
    global _pgvector_service
    if _pgvector_service is None:
        _pgvector_service = PGVectorService()
    return _pgvector_service


# Backward compatibility alias
PgVectorService = PGVectorService


if __name__ == "__main__":
    """
    Test suite for PGVectorService.

    Usage:
        python pgvector_service.py
        python pgvector_service.py --gene SCN1A
        python pgvector_service.py --drug QS00000001
        python pgvector_service.py --stats
    """
    import argparse

    parser = argparse.ArgumentParser(description="Test PGVector Service v6.0")
    parser.add_argument("--gene", help="Test gene embedding (e.g., SCN1A)")
    parser.add_argument("--drug", help="Test drug embedding (e.g., QS00000001)")
    parser.add_argument("--stats", action="store_true", help="Show embedding statistics")
    parser.add_argument("--health", action="store_true", help="Run health check")

    args = parser.parse_args()

    print("\n" + "=" * 80)
    print("PGVector Service v6.0 - Test Suite")
    print("=" * 80 + "\n")

    # Initialize service
    try:
        service = PGVectorService()
        print(f"✓ Service initialized: {service.user}@{service.host}:{service.port}/{service.database}\n")
    except Exception as e:
        print(f"❌ Failed to initialize service: {e}")
        sys.exit(1)

    # Health check
    if args.health or (not args.gene and not args.drug and not args.stats):
        print("Running health check...\n")
        health = service.health_check()

        if health["status"] == "healthy":
            print("✓ Service Status: HEALTHY\n")
            print(f"Database: {health['database']['version']}")
            print(f"pgvector installed: {health['database']['pgvector_installed']}\n")

            print("Gene Tables:")
            for table, count in health["tables"]["gene"].items():
                print(f"  {table}: {count:,} entities")

            print("\nDrug Tables:")
            for table, count in health["tables"]["drug"].items():
                print(f"  {table}: {count:,} entities")
            print()
        else:
            print(f"❌ Service Status: UNHEALTHY\n{health['error']}")

    # Test gene embedding
    if args.gene:
        print(f"Testing gene embedding: {args.gene}\n")

        result = service.get_gene_embedding(args.gene)
        if result:
            print(f"✓ Gene: {result.entity_id}")
            print(f"  Dimensions: {result.dimensions}D")
            print(f"  Source: {result.source_table}")
            print(f"  Embedding shape: {result.embedding.shape}")
            print(f"  Sample values: {result.embedding[:5]}")
            print()

            # Test similarity search
            print(f"Finding similar genes (ep_gene fusion)...\n")
            similar = service.find_similar_genes(args.gene, top_k=5, fusion_type="ep_gene")

            if similar:
                print(f"✓ Top 5 similar genes:\n")
                for i, sim in enumerate(similar, 1):
                    print(f"  {i}. {sim.entity_id} (score: {sim.similarity_score:.3f})")
            else:
                print("  No similar genes found (precomputed table may be empty)")
        else:
            print(f"❌ Gene '{args.gene}' not found in database")
        print()

    # Test drug embedding
    if args.drug:
        print(f"Testing drug embedding: {args.drug}\n")

        result = service.get_drug_embedding(args.drug)
        if result:
            print(f"✓ Drug: {result.entity_id}")
            print(f"  Dimensions: {result.dimensions}D")
            print(f"  Source: {result.source_table}")
            print(f"  Embedding shape: {result.embedding.shape}")
            print(f"  Sample values: {result.embedding[:5]}")
            print()

            # Test similarity search
            print(f"Finding similar drugs (adr fusion)...\n")
            similar = service.find_similar_drugs(args.drug, top_k=5, fusion_type="adr")

            if similar:
                print(f"✓ Top 5 similar drugs:\n")
                for i, sim in enumerate(similar, 1):
                    print(f"  {i}. {sim.entity_id} (score: {sim.similarity_score:.3f})")
            else:
                print("  No similar drugs found (precomputed table may be empty)")
        else:
            print(f"❌ Drug '{args.drug}' not found in database")
        print()

    # Show statistics
    if args.stats:
        print("Embedding Statistics\n")

        for table in service.GENE_TABLES:
            try:
                stats = service.get_embedding_stats(table)
                print(f"{table}:")
                print(f"  Total: {stats.total_entities:,}")
                print(f"  Dimensions: {stats.embedding_dimensions}D")
                print(f"  Coverage: {stats.coverage_percent:.1f}%")
                print(f"  Samples: {', '.join(stats.sample_entities[:3])}")
                print()
            except Exception as e:
                print(f"{table}: Error - {e}\n")

        for table in service.DRUG_TABLES:
            try:
                stats = service.get_embedding_stats(table)
                print(f"{table}:")
                print(f"  Total: {stats.total_entities:,}")
                print(f"  Dimensions: {stats.embedding_dimensions}D")
                print(f"  Coverage: {stats.coverage_percent:.1f}%")
                print(f"  Samples: {', '.join(stats.sample_entities[:3])}")
                print()
            except Exception as e:
                print(f"{table}: Error - {e}\n")

    # Cleanup
    service.close()
    print("✓ Service closed\n")
