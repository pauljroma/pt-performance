"""
BaseResolver - Abstract Base Class for All Meta Layer Components
=================================================================

All resolvers, classifiers, and enhancers must inherit from this class
to ensure consistent interfaces and behavior.

Pattern:
    class MyResolver(BaseResolver):
        def _initialize(self):
            # Load data sources
            pass

        def resolve(self, query: str, **kwargs) -> Dict[str, Any]:
            # Main resolution logic
            return {
                'result': ...,
                'confidence': 0.95,
                'strategy': 'exact_match',
                'metadata': {...}
            }

        def get_stats(self) -> Dict[str, int]:
            # Return statistics
            return {'total_queries': 100}

Author: Meta Layer Swarm - Agent 1
Date: 2025-12-01
Version: 1.0.0
"""

from abc import ABC, abstractmethod
from typing import Dict, Any, List, Optional
from functools import lru_cache
import logging
import time


class BaseResolver(ABC):
    """
    Abstract base class for all meta layer components.

    All resolvers must implement:
    - _initialize()  - Load data sources and build indices
    - resolve()      - Main resolution method
    - get_stats()    - Return resolver statistics

    Optional:
    - bulk_resolve() - Batch resolution (default implementation provided)
    - validate()     - Validate input before resolution
    """

    def __init__(self):
        """Initialize resolver with logging and metrics."""
        self.logger = logging.getLogger(self.__class__.__name__)
        self._query_count = 0
        self._total_latency = 0.0
        self._error_count = 0

        # Call subclass initialization
        self._initialize()

        self.logger.info(f"{self.__class__.__name__} initialized")

    @abstractmethod
    def _initialize(self):
        """
        Load data sources, build indices, etc.

        Called during __init__(). Subclasses must implement this
        to set up any required data structures or connections.
        """
        pass

    @abstractmethod
    def resolve(self, query: str, **kwargs) -> Dict[str, Any]:
        """
        Main resolution method.

        Args:
            query: Input query string
            **kwargs: Additional parameters specific to resolver

        Returns:
            {
                'result': resolved value (str, list, dict, etc.),
                'confidence': float (0.0-1.0),
                'strategy': str (which strategy was used),
                'metadata': dict (additional info),
                'latency_ms': float (query latency)
            }

        Raises:
            ValueError: If query is invalid
        """
        pass

    @abstractmethod
    def get_stats(self) -> Dict[str, int]:
        """
        Return resolver statistics.

        Returns:
            {
                'query_count': int,
                'error_count': int,
                'avg_latency_ms': float,
                'cache_hits': int,
                'cache_misses': int,
                ... (resolver-specific stats)
            }
        """
        pass

    def bulk_resolve(self, queries: List[str], **kwargs) -> Dict[str, Dict[str, Any]]:
        """
        Batch resolve multiple queries.

        Default implementation calls resolve() for each query.
        Subclasses can override for optimized batch processing.

        Args:
            queries: List of query strings
            **kwargs: Additional parameters

        Returns:
            Dictionary mapping query → result
        """
        results = {}
        for query in queries:
            try:
                results[query] = self.resolve(query, **kwargs)
            except Exception as e:
                self.logger.error(f"Bulk resolve error for '{query}': {e}")
                results[query] = self._error_result(query, str(e))

        return results

    def validate(self, query: str, **kwargs) -> bool:
        """
        Validate input before resolution.

        Default implementation checks for non-empty string.
        Subclasses can override for custom validation.

        Args:
            query: Input query
            **kwargs: Additional parameters

        Returns:
            True if valid, False otherwise
        """
        if not query or not isinstance(query, str):
            return False

        if len(query.strip()) == 0:
            return False

        return True

    def _record_query(self, latency_ms: float, success: bool = True):
        """
        Record query metrics.

        Args:
            latency_ms: Query latency in milliseconds
            success: Whether query succeeded
        """
        self._query_count += 1
        self._total_latency += latency_ms

        if not success:
            self._error_count += 1

    def _empty_result(self, query: str, reason: str = "No match found") -> Dict[str, Any]:
        """
        Return empty result when no match found.

        Args:
            query: Original query
            reason: Why no match was found

        Returns:
            Standard empty result dictionary
        """
        return {
            'result': query,
            'confidence': 0.0,
            'strategy': 'none',
            'metadata': {
                'reason': reason,
                'original_query': query
            }
        }

    def _error_result(self, query: str, error: str) -> Dict[str, Any]:
        """
        Return error result when resolution fails.

        Args:
            query: Original query
            error: Error message

        Returns:
            Standard error result dictionary
        """
        self._error_count += 1

        return {
            'result': None,
            'confidence': 0.0,
            'strategy': 'error',
            'metadata': {
                'error': error,
                'original_query': query
            }
        }

    def _format_result(
        self,
        result: Any,
        confidence: float,
        strategy: str,
        metadata: Optional[Dict[str, Any]] = None,
        latency_ms: Optional[float] = None
    ) -> Dict[str, Any]:
        """
        Format result in standard format.

        Args:
            result: Resolved value
            confidence: Confidence score (0.0-1.0)
            strategy: Strategy used
            metadata: Additional metadata
            latency_ms: Query latency

        Returns:
            Standard result dictionary
        """
        formatted = {
            'result': result,
            'confidence': confidence,
            'strategy': strategy,
            'metadata': metadata or {}
        }

        if latency_ms is not None:
            formatted['latency_ms'] = latency_ms

        return formatted

    def get_base_stats(self) -> Dict[str, Any]:
        """
        Get base statistics available to all resolvers.

        Returns:
            Dictionary of base statistics
        """
        avg_latency = (
            self._total_latency / self._query_count
            if self._query_count > 0
            else 0.0
        )

        return {
            'query_count': self._query_count,
            'error_count': self._error_count,
            'success_count': self._query_count - self._error_count,
            'avg_latency_ms': avg_latency,
            'error_rate': (
                self._error_count / self._query_count
                if self._query_count > 0
                else 0.0
            )
        }

    def __repr__(self) -> str:
        """String representation of resolver."""
        return f"{self.__class__.__name__}(queries={self._query_count})"
