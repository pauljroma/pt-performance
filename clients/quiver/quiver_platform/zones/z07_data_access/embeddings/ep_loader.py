"""
EP Embedding Loader
===================

Load and manage ENS, ACT, LAT embeddings for EP signatures.

Purpose:
    - Unified interface for all EP embedding types
    - Lazy loading for memory efficiency
    - Query by drug/gene identifiers
    - Cross-modal operations

EP Embedding Types:
    - ENS (Ensemble v4.11): 40D embeddings
    - ACT (Activation v4.1.4.2): 40D embeddings
    - LAT (Latent v4.2): 40D embeddings

Usage:
    >>> loader = EPLoader()
    >>> ens_emb = loader.get_ens_embedding("CHEMBL1234")
    >>> act_emb = loader.get_act_embedding("BRCA1")
    >>> all_embs = loader.get_all_embeddings("CHEMBL1234")
"""

from typing import Optional, Dict, List, Tuple
import logging
from pathlib import Path

import numpy as np
import pandas as pd

logger = logging.getLogger(__name__)


class EPLoader:
    """
    Load and manage EP embeddings (ENS/ACT/LAT).

    Features:
        - Lazy loading (load on first access)
        - Support for all three embedding types
        - Query by ChEMBL ID, gene symbol, or other identifiers
        - Memory-efficient storage

    Attributes:
        data_dir: Base directory for embedding data
        ens_embeddings: ENS embedding matrix (lazy-loaded)
        act_embeddings: ACT embedding matrix (lazy-loaded)
        lat_embeddings: LAT embedding matrix (lazy-loaded)
        ens_index: ChEMBL ID → row index mapping
        act_index: Gene symbol → row index mapping
        lat_index: Identifier → row index mapping
    """

    def __init__(self, data_dir: Optional[str] = None):
        """
        Initialize EP embedding loader.

        Args:
            data_dir: Base directory containing embedding data
                     (default: /Users/expo/Code/expo/data/embeddings/)
        """
        if data_dir is None:
            data_dir = Path(__file__).parents[3] / "data/embeddings"

        self.data_dir = Path(data_dir)

        # Lazy-loaded embeddings
        self._ens_embeddings: Optional[np.ndarray] = None
        self._act_embeddings: Optional[np.ndarray] = None
        self._lat_embeddings: Optional[np.ndarray] = None

        # Index mappings (identifier → row index)
        self._ens_index: Optional[Dict[str, int]] = None
        self._act_index: Optional[Dict[str, int]] = None
        self._lat_index: Optional[Dict[str, int]] = None

        # Metadata
        self._ens_metadata: Optional[pd.DataFrame] = None
        self._act_metadata: Optional[pd.DataFrame] = None
        self._lat_metadata: Optional[pd.DataFrame] = None

        logger.info(f"EPLoader initialized with data_dir: {self.data_dir}")

    @property
    def ens_embeddings(self) -> np.ndarray:
        """
        Get ENS embeddings (lazy-loaded).

        Returns:
            ENS embedding matrix (n_drugs × 40)
        """
        if self._ens_embeddings is None:
            self._load_ens_embeddings()
        return self._ens_embeddings

    @property
    def act_embeddings(self) -> np.ndarray:
        """
        Get ACT embeddings (lazy-loaded).

        Returns:
            ACT embedding matrix (n_genes × 40)
        """
        if self._act_embeddings is None:
            self._load_act_embeddings()
        return self._act_embeddings

    @property
    def lat_embeddings(self) -> np.ndarray:
        """
        Get LAT embeddings (lazy-loaded).

        Returns:
            LAT embedding matrix (n_items × 40)
        """
        if self._lat_embeddings is None:
            self._load_lat_embeddings()
        return self._lat_embeddings

    def _load_ens_embeddings(self):
        """Load ENS embeddings and metadata from disk."""
        ens_file = self.data_dir / "ens_v4.11_embeddings.npy"
        metadata_file = self.data_dir / "ens_v4.11_metadata.csv"

        try:
            # Load embeddings
            self._ens_embeddings = np.load(ens_file)
            logger.info(f"Loaded ENS embeddings: {self._ens_embeddings.shape}")

            # Load metadata
            self._ens_metadata = pd.read_csv(metadata_file)

            # Build index (ChEMBL ID → row index)
            self._ens_index = {
                row["chembl_id"]: idx
                for idx, row in self._ens_metadata.iterrows()
            }
            logger.info(f"Loaded ENS metadata: {len(self._ens_index)} drugs")

        except FileNotFoundError as e:
            logger.warning(f"ENS embeddings not found: {e}")
            self._ens_embeddings = np.array([])
            self._ens_index = {}
            self._ens_metadata = pd.DataFrame()

    def _load_act_embeddings(self):
        """Load ACT embeddings and metadata from disk."""
        act_file = self.data_dir / "act_v4.1.4.2_embeddings.npy"
        metadata_file = self.data_dir / "act_v4.1.4.2_metadata.csv"

        try:
            # Load embeddings
            self._act_embeddings = np.load(act_file)
            logger.info(f"Loaded ACT embeddings: {self._act_embeddings.shape}")

            # Load metadata
            self._act_metadata = pd.read_csv(metadata_file)

            # Build index (gene symbol → row index)
            self._act_index = {
                row["gene_symbol"]: idx
                for idx, row in self._act_metadata.iterrows()
            }
            logger.info(f"Loaded ACT metadata: {len(self._act_index)} genes")

        except FileNotFoundError as e:
            logger.warning(f"ACT embeddings not found: {e}")
            self._act_embeddings = np.array([])
            self._act_index = {}
            self._act_metadata = pd.DataFrame()

    def _load_lat_embeddings(self):
        """Load LAT embeddings and metadata from disk."""
        lat_file = self.data_dir / "lat_v4.2_embeddings.npy"
        metadata_file = self.data_dir / "lat_v4.2_metadata.csv"

        try:
            # Load embeddings
            self._lat_embeddings = np.load(lat_file)
            logger.info(f"Loaded LAT embeddings: {self._lat_embeddings.shape}")

            # Load metadata
            self._lat_metadata = pd.read_csv(metadata_file)

            # Build index (identifier → row index)
            self._lat_index = {
                row["identifier"]: idx
                for idx, row in self._lat_metadata.iterrows()
            }
            logger.info(f"Loaded LAT metadata: {len(self._lat_index)} items")

        except FileNotFoundError as e:
            logger.warning(f"LAT embeddings not found: {e}")
            self._lat_embeddings = np.array([])
            self._lat_index = {}
            self._lat_metadata = pd.DataFrame()

    def get_ens_embedding(self, chembl_id: str) -> Optional[np.ndarray]:
        """
        Get ENS embedding for a drug.

        Args:
            chembl_id: ChEMBL ID (e.g., "CHEMBL1234")

        Returns:
            ENS embedding (40D) or None if not found

        Example:
            >>> loader.get_ens_embedding("CHEMBL1234")
            array([0.123, -0.456, ...])  # 40D vector
        """
        if self._ens_index is None:
            self._load_ens_embeddings()

        if chembl_id not in self._ens_index:
            logger.warning(f"ENS embedding not found for {chembl_id}")
            return None

        row_idx = self._ens_index[chembl_id]
        return self.ens_embeddings[row_idx]

    def get_act_embedding(self, gene_symbol: str) -> Optional[np.ndarray]:
        """
        Get ACT embedding for a gene.

        Args:
            gene_symbol: HGNC gene symbol (e.g., "TP53")

        Returns:
            ACT embedding (40D) or None if not found

        Example:
            >>> loader.get_act_embedding("TP53")
            array([0.789, -0.321, ...])  # 40D vector
        """
        if self._act_index is None:
            self._load_act_embeddings()

        if gene_symbol not in self._act_index:
            logger.warning(f"ACT embedding not found for {gene_symbol}")
            return None

        row_idx = self._act_index[gene_symbol]
        return self.act_embeddings[row_idx]

    def get_lat_embedding(self, identifier: str) -> Optional[np.ndarray]:
        """
        Get LAT embedding for an identifier.

        Args:
            identifier: Generic identifier (ChEMBL, gene, etc.)

        Returns:
            LAT embedding (40D) or None if not found

        Example:
            >>> loader.get_lat_embedding("CHEMBL1234")
            array([0.456, -0.789, ...])  # 40D vector
        """
        if self._lat_index is None:
            self._load_lat_embeddings()

        if identifier not in self._lat_index:
            logger.warning(f"LAT embedding not found for {identifier}")
            return None

        row_idx = self._lat_index[identifier]
        return self.lat_embeddings[row_idx]

    def get_all_embeddings(
        self, identifier: str
    ) -> Dict[str, Optional[np.ndarray]]:
        """
        Get all available embeddings for an identifier.

        Tries to fetch ENS, ACT, LAT embeddings for the given identifier.

        Args:
            identifier: ChEMBL ID, gene symbol, or other identifier

        Returns:
            Dictionary with all found embeddings:
            {
                "ens": np.ndarray or None (40D),
                "act": np.ndarray or None (40D),
                "lat": np.ndarray or None (40D),
                "concatenated": np.ndarray or None (120D if all found)
            }

        Example:
            >>> loader.get_all_embeddings("CHEMBL1234")
            {
                'ens': array([...]),  # 40D
                'act': None,
                'lat': array([...]),  # 40D
                'concatenated': None  # Not all embeddings found
            }
        """
        result = {
            "ens": self.get_ens_embedding(identifier),
            "act": self.get_act_embedding(identifier),
            "lat": self.get_lat_embedding(identifier),
            "concatenated": None,
        }

        # Create concatenated embedding if all three exist
        if all(emb is not None for emb in [result["ens"], result["act"], result["lat"]]):
            result["concatenated"] = np.concatenate([
                result["ens"],
                result["act"],
                result["lat"]
            ])

        return result

    def search_ens_by_similarity(
        self, query_embedding: np.ndarray, top_k: int = 10
    ) -> List[Tuple[str, float]]:
        """
        Find most similar ENS embeddings to a query vector.

        Args:
            query_embedding: Query vector (40D)
            top_k: Number of results to return

        Returns:
            List of (chembl_id, similarity_score) tuples

        Example:
            >>> query_emb = loader.get_ens_embedding("CHEMBL1234")
            >>> similar = loader.search_ens_by_similarity(query_emb, top_k=5)
            >>> similar
            [('CHEMBL5678', 0.987), ('CHEMBL9012', 0.945), ...]
        """
        from quiver_common.embeddings.vector_ops import VectorOps

        # Compute cosine similarities
        similarities = VectorOps.cosine_similarity_batch(
            query_embedding, self.ens_embeddings
        )

        # Get top-k indices
        top_indices = np.argsort(similarities)[::-1][:top_k]

        # Map indices to ChEMBL IDs
        idx_to_chembl = {v: k for k, v in self._ens_index.items()}

        results = [
            (idx_to_chembl[idx], similarities[idx])
            for idx in top_indices
            if idx in idx_to_chembl
        ]

        return results

    def get_embedding_stats(self) -> Dict[str, any]:
        """
        Get statistics about loaded embeddings.

        Returns:
            Dictionary with embedding counts and dimensions:
            {
                "ens_count": int,
                "act_count": int,
                "lat_count": int,
                "ens_dims": int,
                "act_dims": int,
                "lat_dims": int,
            }
        """
        stats = {
            "ens_count": len(self._ens_index) if self._ens_index else 0,
            "act_count": len(self._act_index) if self._act_index else 0,
            "lat_count": len(self._lat_index) if self._lat_index else 0,
            "ens_dims": self.ens_embeddings.shape[1] if len(self.ens_embeddings) > 0 else 0,
            "act_dims": self.act_embeddings.shape[1] if len(self.act_embeddings) > 0 else 0,
            "lat_dims": self.lat_embeddings.shape[1] if len(self.lat_embeddings) > 0 else 0,
        }
        return stats

    def has_ens_embedding(self, chembl_id: str) -> bool:
        """Check if ENS embedding exists for ChEMBL ID."""
        if self._ens_index is None:
            self._load_ens_embeddings()
        return chembl_id in self._ens_index

    def has_act_embedding(self, gene_symbol: str) -> bool:
        """Check if ACT embedding exists for gene symbol."""
        if self._act_index is None:
            self._load_act_embeddings()
        return gene_symbol in self._act_index

    def has_lat_embedding(self, identifier: str) -> bool:
        """Check if LAT embedding exists for identifier."""
        if self._lat_index is None:
            self._load_lat_embeddings()
        return identifier in self._lat_index
