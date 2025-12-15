"""
Vector Operations
=================

Shared vector operations for embeddings.

Functions:
    - Cosine similarity (pairwise and batch)
    - Vector projections
    - Normalization
    - Distance metrics

Usage:
    >>> from quiver_common.embeddings.vector_ops import VectorOps
    >>> similarity = VectorOps.cosine_similarity(vec1, vec2)
    >>> normalized = VectorOps.normalize(vec)
"""

from typing import Optional, List
import numpy as np


class VectorOps:
    """
    Static methods for vector operations.

    All methods work with numpy arrays.
    """

    @staticmethod
    def cosine_similarity(vec1: np.ndarray, vec2: np.ndarray) -> float:
        """
        Compute cosine similarity between two vectors.

        Args:
            vec1: First vector (any dimension)
            vec2: Second vector (same dimension as vec1)

        Returns:
            Cosine similarity score [-1, 1]

        Example:
            >>> vec1 = np.array([1, 2, 3])
            >>> vec2 = np.array([4, 5, 6])
            >>> VectorOps.cosine_similarity(vec1, vec2)
            0.9746318461970762
        """
        # Handle zero vectors
        norm1 = np.linalg.norm(vec1)
        norm2 = np.linalg.norm(vec2)

        if norm1 == 0 or norm2 == 0:
            return 0.0

        return np.dot(vec1, vec2) / (norm1 * norm2)

    @staticmethod
    def cosine_similarity_batch(
        query_vec: np.ndarray, matrix: np.ndarray
    ) -> np.ndarray:
        """
        Compute cosine similarity between a query vector and all rows in a matrix.

        More efficient than pairwise cosine_similarity in a loop.

        Args:
            query_vec: Query vector (d dimensions)
            matrix: Matrix of vectors (n × d)

        Returns:
            Array of similarity scores (n,)

        Example:
            >>> query = np.array([1, 2, 3])
            >>> matrix = np.array([[4, 5, 6], [7, 8, 9]])
            >>> VectorOps.cosine_similarity_batch(query, matrix)
            array([0.97463185, 0.95941195])
        """
        # Normalize query vector
        query_norm = query_vec / np.linalg.norm(query_vec)

        # Normalize matrix rows
        matrix_norms = np.linalg.norm(matrix, axis=1, keepdims=True)
        matrix_norms[matrix_norms == 0] = 1  # Avoid division by zero
        matrix_normalized = matrix / matrix_norms

        # Compute dot products
        similarities = np.dot(matrix_normalized, query_norm)

        return similarities

    @staticmethod
    def euclidean_distance(vec1: np.ndarray, vec2: np.ndarray) -> float:
        """
        Compute Euclidean distance between two vectors.

        Args:
            vec1: First vector
            vec2: Second vector

        Returns:
            Euclidean distance (≥ 0)

        Example:
            >>> vec1 = np.array([1, 2, 3])
            >>> vec2 = np.array([4, 5, 6])
            >>> VectorOps.euclidean_distance(vec1, vec2)
            5.196152422706632
        """
        return np.linalg.norm(vec1 - vec2)

    @staticmethod
    def manhattan_distance(vec1: np.ndarray, vec2: np.ndarray) -> float:
        """
        Compute Manhattan (L1) distance between two vectors.

        Args:
            vec1: First vector
            vec2: Second vector

        Returns:
            Manhattan distance (≥ 0)

        Example:
            >>> vec1 = np.array([1, 2, 3])
            >>> vec2 = np.array([4, 5, 6])
            >>> VectorOps.manhattan_distance(vec1, vec2)
            9.0
        """
        return np.sum(np.abs(vec1 - vec2))

    @staticmethod
    def normalize(vec: np.ndarray, ord: int = 2) -> np.ndarray:
        """
        Normalize vector to unit length.

        Args:
            vec: Input vector
            ord: Norm order (default: 2 for L2 norm)

        Returns:
            Normalized vector (same shape as input)

        Example:
            >>> vec = np.array([3, 4])
            >>> VectorOps.normalize(vec)
            array([0.6, 0.8])
        """
        norm = np.linalg.norm(vec, ord=ord)
        if norm == 0:
            return vec
        return vec / norm

    @staticmethod
    def project_onto(vec: np.ndarray, basis: np.ndarray) -> np.ndarray:
        """
        Project vector onto basis vector.

        Args:
            vec: Vector to project
            basis: Basis vector

        Returns:
            Projected vector

        Example:
            >>> vec = np.array([3, 4])
            >>> basis = np.array([1, 0])
            >>> VectorOps.project_onto(vec, basis)
            array([3., 0.])
        """
        basis_norm = np.linalg.norm(basis)
        if basis_norm == 0:
            return np.zeros_like(vec)

        basis_unit = basis / basis_norm
        projection_length = np.dot(vec, basis_unit)
        return projection_length * basis_unit

    @staticmethod
    def pearson_correlation(vec1: np.ndarray, vec2: np.ndarray) -> float:
        """
        Compute Pearson correlation coefficient between two vectors.

        Args:
            vec1: First vector
            vec2: Second vector

        Returns:
            Pearson correlation [-1, 1]

        Example:
            >>> vec1 = np.array([1, 2, 3, 4, 5])
            >>> vec2 = np.array([2, 4, 6, 8, 10])
            >>> VectorOps.pearson_correlation(vec1, vec2)
            1.0
        """
        return np.corrcoef(vec1, vec2)[0, 1]

    @staticmethod
    def spearman_correlation(vec1: np.ndarray, vec2: np.ndarray) -> float:
        """
        Compute Spearman rank correlation between two vectors.

        Args:
            vec1: First vector
            vec2: Second vector

        Returns:
            Spearman correlation [-1, 1]

        Example:
            >>> vec1 = np.array([1, 2, 3, 4, 5])
            >>> vec2 = np.array([5, 6, 7, 8, 7])
            >>> VectorOps.spearman_correlation(vec1, vec2)
            0.8207826816681233
        """
        from scipy.stats import spearmanr
        return spearmanr(vec1, vec2)[0]

    @staticmethod
    def concatenate_embeddings(
        embeddings: List[np.ndarray], weights: Optional[List[float]] = None
    ) -> np.ndarray:
        """
        Concatenate multiple embeddings (optionally weighted).

        Args:
            embeddings: List of embedding vectors
            weights: Optional weights for each embedding (default: equal weights)

        Returns:
            Concatenated embedding

        Example:
            >>> ens = np.array([1, 2, 3])
            >>> act = np.array([4, 5, 6])
            >>> lat = np.array([7, 8, 9])
            >>> VectorOps.concatenate_embeddings([ens, act, lat])
            array([1, 2, 3, 4, 5, 6, 7, 8, 9])
        """
        if weights is None:
            return np.concatenate(embeddings)

        # Apply weights before concatenation
        weighted_embeddings = [
            emb * weight for emb, weight in zip(embeddings, weights)
        ]
        return np.concatenate(weighted_embeddings)

    @staticmethod
    def average_embeddings(embeddings: List[np.ndarray]) -> np.ndarray:
        """
        Average multiple embeddings (element-wise mean).

        Args:
            embeddings: List of embedding vectors (same dimension)

        Returns:
            Average embedding

        Example:
            >>> emb1 = np.array([1, 2, 3])
            >>> emb2 = np.array([4, 5, 6])
            >>> VectorOps.average_embeddings([emb1, emb2])
            array([2.5, 3.5, 4.5])
        """
        return np.mean(embeddings, axis=0)

    @staticmethod
    def top_k_similar(
        query_vec: np.ndarray, matrix: np.ndarray, k: int = 10
    ) -> List[int]:
        """
        Find indices of top-k most similar vectors in matrix.

        Uses cosine similarity.

        Args:
            query_vec: Query vector
            matrix: Matrix of candidate vectors
            k: Number of results

        Returns:
            List of indices (sorted by similarity, descending)

        Example:
            >>> query = np.array([1, 2, 3])
            >>> matrix = np.array([[1, 2, 3], [4, 5, 6], [7, 8, 9]])
            >>> VectorOps.top_k_similar(query, matrix, k=2)
            [0, 1]  # Indices of most similar vectors
        """
        similarities = VectorOps.cosine_similarity_batch(query_vec, matrix)
        top_indices = np.argsort(similarities)[::-1][:k]
        return top_indices.tolist()

    @staticmethod
    def batch_pairwise_distances(
        matrix1: np.ndarray, matrix2: np.ndarray, metric: str = "cosine"
    ) -> np.ndarray:
        """
        Compute pairwise distances between all vectors in two matrices.

        Args:
            matrix1: First matrix (n × d)
            matrix2: Second matrix (m × d)
            metric: Distance metric ("cosine", "euclidean", "manhattan")

        Returns:
            Distance matrix (n × m)

        Example:
            >>> mat1 = np.array([[1, 2], [3, 4]])
            >>> mat2 = np.array([[5, 6], [7, 8]])
            >>> VectorOps.batch_pairwise_distances(mat1, mat2, metric="euclidean")
            array([[5.65685425, 8.48528137],
                   [2.82842712, 5.65685425]])
        """
        from scipy.spatial.distance import cdist

        if metric == "cosine":
            return cdist(matrix1, matrix2, metric="cosine")
        elif metric == "euclidean":
            return cdist(matrix1, matrix2, metric="euclidean")
        elif metric == "manhattan":
            return cdist(matrix1, matrix2, metric="cityblock")
        else:
            raise ValueError(f"Unknown metric: {metric}")

    @staticmethod
    def standardize(vec: np.ndarray) -> np.ndarray:
        """
        Standardize vector to zero mean and unit variance.

        Args:
            vec: Input vector

        Returns:
            Standardized vector

        Example:
            >>> vec = np.array([1, 2, 3, 4, 5])
            >>> VectorOps.standardize(vec)
            array([-1.41421356, -0.70710678,  0.        ,  0.70710678,  1.41421356])
        """
        mean = np.mean(vec)
        std = np.std(vec)
        if std == 0:
            return vec - mean
        return (vec - mean) / std
