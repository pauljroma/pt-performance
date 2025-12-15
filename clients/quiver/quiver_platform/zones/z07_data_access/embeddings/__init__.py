"""
Embedding Operations
====================

Shared embedding utilities for EP signatures and vector operations.

Classes:
    EPLoader: Load ENS/ACT/LAT embeddings
    VectorOps: Vector operations (cosine similarity, projections)
"""

from quiver_common.embeddings.ep_loader import EPLoader
from quiver_common.embeddings.vector_ops import VectorOps

__all__ = ["EPLoader", "VectorOps"]
