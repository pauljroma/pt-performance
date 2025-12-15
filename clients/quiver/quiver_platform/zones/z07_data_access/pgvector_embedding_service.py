"""
PGVector Embedding Service - PostgreSQL pgvector-based replacement for parquet embedding_service

REPLACES: embedding_service.py (parquet-based)
PURPOSE: Provide direct pgvector access for all embedding operations
CREATED: 2025-12-04
MIGRATION: Part of parquet → pgvector migration

This service provides the SAME API as the old embedding_service.py but uses
PostgreSQL pgvector instead of parquet files.

Usage:
    from pgvector_embedding_service import get_pgvector_embedding_service

    service = get_pgvector_embedding_service()
    embedding = service.get_drug_embedding("Aspirin")
    results = service.compute_rescue_scores("TSC2", top_k=10)
"""

import os
import logging
from typing import Dict, Any, List, Optional, Tuple
from dataclasses import dataclass
import numpy as np
import psycopg2
from psycopg2.extras import RealDictCursor

logger = logging.getLogger(__name__)


@dataclass
class RescueResult:
    """Result from rescue score computation."""
    drug_name: str
    rescue_score: float
    antipodal_distance: float
    tier: str
    similarity_score: Optional[float] = None


@dataclass
class SimilarityResult:
    """Result from similarity computation."""
    entity_name: str
    similarity_score: float
    tier: str
    embedding_space: Optional[str] = None


class PGVectorEmbeddingService:
    """
    PostgreSQL pgvector-based embedding service.

    Provides same API as old embedding_service.py but uses pgvector backend.
    """

    def __init__(self):
        """Initialize pgvector connection."""
        self.conn_config = {
            'host': os.getenv('PGVECTOR_HOST', 'localhost'),
            'port': int(os.getenv('PGVECTOR_PORT', '5435')),
            'database': os.getenv('PGVECTOR_DATABASE', 'sapphire_database'),
            'user': os.getenv('PGVECTOR_USER', 'postgres'),
            'password': os.getenv('PGVECTOR_PASSWORD', 'temppass123')
        }

        # Table configurations
        self.tables = {
            # Entity-specific tables (same-entity operations)
            'drug': 'drug_chemical_v6_0_256d',      # 256D - drug-only
            'gene': 'ens_gene_64d_v6_0',            # 64D - gene-only
            'drug_fusion': 'd_d_similarity_fusion_v6_0',
            'gene_fusion': 'g_g_1__ens__lincs',

            # Cross-entity table (drug-gene operations)
            'unified': 'modex_ep_unified_16d_v6_0'  # 16D - both drugs and genes
        }

        logger.info(f"PGVectorEmbeddingService initialized with tables: {self.tables}")

    def _get_connection(self):
        """Get PostgreSQL connection."""
        return psycopg2.connect(**self.conn_config)

    def get_drug_embedding(self, drug_name: str, use_unified: bool = False) -> Optional[np.ndarray]:
        """
        Get drug embedding from pgvector.

        Args:
            drug_name: Drug name or ID
            use_unified: If True, use unified table (16D) for cross-entity ops.
                        If False, use drug-only table (256D) for drug-drug ops.

        Returns:
            numpy array of embedding, or None if not found
        """
        table_name = self.tables['unified'] if use_unified else self.tables['drug']
        try:
            conn = self._get_connection()
            cur = conn.cursor()

            # Try exact match first
            cur.execute(f"""
                SELECT embedding
                FROM {table_name}
                WHERE id = %s
                LIMIT 1
            """, (drug_name,))

            result = cur.fetchone()

            if result:
                # Convert pgvector to numpy array
                # pgvector returns as a string like '[1.0,2.0,...]'
                embedding_str = result[0]
                if isinstance(embedding_str, str):
                    # Parse string representation
                    embedding_str = embedding_str.strip('[]')
                    embedding_list = [float(x) for x in embedding_str.split(',')]
                    embedding = np.array(embedding_list, dtype=np.float32)
                else:
                    embedding = np.array(embedding_str, dtype=np.float32)
                conn.close()
                return embedding

            # Try case-insensitive match
            cur.execute(f"""
                SELECT embedding
                FROM {table_name}
                WHERE LOWER(id) = LOWER(%s)
                LIMIT 1
            """, (drug_name,))

            result = cur.fetchone()
            conn.close()

            if result:
                embedding_str = result[0]
                if isinstance(embedding_str, str):
                    embedding_str = embedding_str.strip('[]')
                    embedding_list = [float(x) for x in embedding_str.split(',')]
                    return np.array(embedding_list, dtype=np.float32)
                else:
                    return np.array(embedding_str, dtype=np.float32)

            return None

        except Exception as e:
            logger.error(f"Error getting drug embedding for {drug_name}: {e}")
            return None

    def get_gene_embedding(self, gene_symbol: str, use_unified: bool = False) -> Optional[np.ndarray]:
        """
        Get gene embedding from pgvector.

        Args:
            gene_symbol: Gene symbol (e.g., "TSC2")
            use_unified: If True, use unified table (16D) for cross-entity ops.
                        If False, use gene-only table (64D) for gene-gene ops.

        Returns:
            numpy array of embedding, or None if not found
        """
        table_name = self.tables['unified'] if use_unified else self.tables['gene']
        try:
            conn = self._get_connection()
            cur = conn.cursor()

            # Try exact match
            cur.execute(f"""
                SELECT embedding
                FROM {table_name}
                WHERE id = %s
                LIMIT 1
            """, (gene_symbol,))

            result = cur.fetchone()

            if result:
                embedding_str = result[0]
                if isinstance(embedding_str, str):
                    embedding_str = embedding_str.strip('[]')
                    embedding_list = [float(x) for x in embedding_str.split(',')]
                    embedding = np.array(embedding_list, dtype=np.float32)
                else:
                    embedding = np.array(embedding_str, dtype=np.float32)
                conn.close()
                return embedding

            # Try case-insensitive
            cur.execute(f"""
                SELECT embedding
                FROM {table_name}
                WHERE LOWER(id) = LOWER(%s)
                LIMIT 1
            """, (gene_symbol,))

            result = cur.fetchone()
            conn.close()

            if result:
                embedding_str = result[0]
                if isinstance(embedding_str, str):
                    embedding_str = embedding_str.strip('[]')
                    embedding_list = [float(x) for x in embedding_str.split(',')]
                    return np.array(embedding_list, dtype=np.float32)
                else:
                    return np.array(embedding_str, dtype=np.float32)

            return None

        except Exception as e:
            logger.error(f"Error getting gene embedding for {gene_symbol}: {e}")
            return None

    def compute_rescue_scores(
        self,
        gene: str,
        top_k: int = 10,
        min_score: float = 0.0
    ) -> List[RescueResult]:
        """
        Compute drug rescue scores for a gene using pgvector.

        Uses antipodal (opposite direction) similarity as rescue potential.

        **CROSS-ENTITY OPERATION**: Uses unified table (16D) for drug-gene comparison.

        Args:
            gene: Gene symbol
            top_k: Number of top results
            min_score: Minimum rescue score threshold

        Returns:
            List of RescueResult objects
        """
        try:
            # Use unified table for cross-entity (drug-gene) operations
            gene_embedding = self.get_gene_embedding(gene, use_unified=True)

            if gene_embedding is None:
                raise ValueError(f"Gene not found: {gene}")

            conn = self._get_connection()
            cur = conn.cursor(cursor_factory=RealDictCursor)

            # Find antipodal drugs (opposite direction = rescue potential)
            # Negate the gene embedding to find opposite vectors
            negative_gene_embedding = (-gene_embedding).tolist()

            # Query unified table (drugs and genes in same 16D space)
            cur.execute("""
                SELECT
                    id as drug_name,
                    1 - (embedding <=> %s::vector) as similarity
                FROM modex_ep_unified_16d_v6_0
                ORDER BY embedding <=> %s::vector
                LIMIT %s
            """, (gene_embedding.tolist(), negative_gene_embedding, top_k * 2))

            results = []
            for row in cur.fetchall():
                # Similarity with original gene
                similarity = row['similarity']

                # Antipodal distance: 1 - similarity (opposite direction)
                # High antipodal distance = opposite direction = good rescue potential
                antipodal_dist = 1.0 - similarity

                # Rescue score: higher antipodal distance = better rescue potential
                rescue_score = min(1.0, max(0.0, antipodal_dist))

                if rescue_score < min_score:
                    continue

                # Tiering
                if rescue_score >= 0.8:
                    tier = "TIER 1"
                elif rescue_score >= 0.6:
                    tier = "TIER 2"
                elif rescue_score >= 0.4:
                    tier = "TIER 3"
                else:
                    tier = "TIER 4"

                results.append(RescueResult(
                    drug_name=row['drug_name'],
                    rescue_score=rescue_score,
                    antipodal_distance=antipodal_dist,
                    tier=tier,
                    similarity_score=similarity
                ))

                if len(results) >= top_k:
                    break

            conn.close()
            return results

        except Exception as e:
            logger.error(f"Error computing rescue scores for {gene}: {e}")
            raise

    def find_similar_genes(
        self,
        gene: str,
        top_k: int = 10,
        min_similarity: float = 0.0
    ) -> List[SimilarityResult]:
        """
        Find similar genes using pgvector.

        **SAME-ENTITY OPERATION**: Uses gene-only table (64D) for gene-gene comparison.

        Args:
            gene: Gene symbol
            top_k: Number of results
            min_similarity: Minimum similarity threshold

        Returns:
            List of SimilarityResult objects
        """
        try:
            # Use gene-only table for same-entity (gene-gene) operations
            gene_embedding = self.get_gene_embedding(gene, use_unified=False)

            if gene_embedding is None:
                raise ValueError(f"Gene not found: {gene}")

            conn = self._get_connection()
            cur = conn.cursor(cursor_factory=RealDictCursor)

            cur.execute("""
                SELECT
                    id as gene_symbol,
                    1 - (embedding <=> %s::vector) as similarity
                FROM ens_gene_64d_v6_0
                WHERE id != %s
                ORDER BY embedding <=> %s::vector
                LIMIT %s
            """, (gene_embedding.tolist(), gene, gene_embedding.tolist(), top_k))

            results = []
            for row in cur.fetchall():
                similarity = row['similarity']

                if similarity < min_similarity:
                    continue

                # Tiering
                if similarity >= 0.9:
                    tier = "TIER 1"
                elif similarity >= 0.7:
                    tier = "TIER 2"
                elif similarity >= 0.5:
                    tier = "TIER 3"
                else:
                    tier = "TIER 4"

                results.append(SimilarityResult(
                    entity_name=row['gene_symbol'],
                    similarity_score=similarity,
                    tier=tier,
                    embedding_space="ens_gene_64d_v6_0"
                ))

            conn.close()
            return results

        except Exception as e:
            logger.error(f"Error finding similar genes for {gene}: {e}")
            raise

    def find_similar_drugs(
        self,
        drug: str,
        top_k: int = 10,
        min_similarity: float = 0.0
    ) -> List[SimilarityResult]:
        """
        Find similar drugs using pgvector.

        **SAME-ENTITY OPERATION**: Uses drug-only table (256D) for drug-drug comparison.

        Args:
            drug: Drug name
            top_k: Number of results
            min_similarity: Minimum similarity threshold

        Returns:
            List of SimilarityResult objects
        """
        try:
            # Use drug-only table for same-entity (drug-drug) operations
            drug_embedding = self.get_drug_embedding(drug, use_unified=False)

            if drug_embedding is None:
                raise ValueError(f"Drug not found: {drug}")

            conn = self._get_connection()
            cur = conn.cursor(cursor_factory=RealDictCursor)

            cur.execute("""
                SELECT
                    id as drug_name,
                    1 - (embedding <=> %s::vector) as similarity
                FROM drug_chemical_v6_0_256d
                WHERE id != %s
                ORDER BY embedding <=> %s::vector
                LIMIT %s
            """, (drug_embedding.tolist(), drug, drug_embedding.tolist(), top_k))

            results = []
            for row in cur.fetchall():
                similarity = row['similarity']

                if similarity < min_similarity:
                    continue

                # Tiering
                if similarity >= 0.9:
                    tier = "TIER 1"
                elif similarity >= 0.7:
                    tier = "TIER 2"
                elif similarity >= 0.5:
                    tier = "TIER 3"
                else:
                    tier = "TIER 4"

                results.append(SimilarityResult(
                    entity_name=row['drug_name'],
                    similarity_score=similarity,
                    tier=tier,
                    embedding_space="drug_chemical_v6_0_256d"
                ))

            conn.close()
            return results

        except Exception as e:
            logger.error(f"Error finding similar drugs for {drug}: {e}")
            raise

    def get_stats(self) -> Dict[str, Any]:
        """Get service statistics."""
        try:
            conn = self._get_connection()
            cur = conn.cursor()

            # Count drugs
            cur.execute("SELECT COUNT(*) FROM drug_chemical_v6_0_256d")
            drug_count = cur.fetchone()[0]

            # Count genes
            cur.execute("SELECT COUNT(*) FROM ens_gene_64d_v6_0")
            gene_count = cur.fetchone()[0]

            conn.close()

            return {
                'drug_count': drug_count,
                'gene_count': gene_count,
                'backend': 'PostgreSQL pgvector',
                'tables': self.tables
            }

        except Exception as e:
            logger.error(f"Error getting stats: {e}")
            return {
                'error': str(e),
                'backend': 'PostgreSQL pgvector (connection failed)'
            }


# Singleton instance
_pgvector_service: Optional[PGVectorEmbeddingService] = None


def get_pgvector_embedding_service() -> PGVectorEmbeddingService:
    """Get or create singleton pgvector embedding service instance."""
    global _pgvector_service
    if _pgvector_service is None:
        _pgvector_service = PGVectorEmbeddingService()
    return _pgvector_service


if __name__ == "__main__":
    # Test the service
    import argparse

    parser = argparse.ArgumentParser(description="Test pgvector embedding service")
    parser.add_argument("--gene", default="TSC2", help="Gene to query")
    parser.add_argument("--drug", default="Aspirin", help="Drug to query")
    parser.add_argument("--top-k", type=int, default=5, help="Number of results")

    args = parser.parse_args()

    print(f"\n=== PGVector Embedding Service Test ===\n")

    service = get_pgvector_embedding_service()

    print(f"Service stats: {service.get_stats()}\n")

    print(f"Testing drug rescue for {args.gene}...\n")

    try:
        results = service.compute_rescue_scores(args.gene, top_k=args.top_k)

        print(f"Top {len(results)} rescue candidates for {args.gene}:\n")

        for i, result in enumerate(results, 1):
            print(f"{i}. {result.drug_name}")
            print(f"   Rescue Score: {result.rescue_score:.3f}")
            print(f"   Antipodal Distance: {result.antipodal_distance:.3f}")
            print(f"   Tier: {result.tier}")
            print()

        # Test gene similarity
        print(f"\nTop {args.top_k} genes similar to {args.gene}:\n")

        gene_results = service.find_similar_genes(args.gene, top_k=args.top_k)

        for i, result in enumerate(gene_results, 1):
            print(f"{i}. {result.entity_name}")
            print(f"   Similarity: {result.similarity_score:.3f}")
            print(f"   Tier: {result.tier}")
            print()

        # Test drug similarity
        print(f"\nTop {args.top_k} drugs similar to {args.drug}:\n")

        drug_results = service.find_similar_drugs(args.drug, top_k=args.top_k)

        for i, result in enumerate(drug_results, 1):
            print(f"{i}. {result.entity_name}")
            print(f"   Similarity: {result.similarity_score:.3f}")
            print(f"   Tier: {result.tier}")
            print()

    except ValueError as e:
        print(f"ERROR: {e}")
