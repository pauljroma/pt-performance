"""
Enhancers - Query Optimization and Enrichment
==============================================

Enhancers transform and optimize queries for better results.

Available Enhancers:
- SemanticQueryResolver - Convert vague queries to structured queries [NEW]
"""

from .semantic_query_resolver import SemanticQueryResolver, get_semantic_query_resolver

__all__ = [
    "SemanticQueryResolver",
    "get_semantic_query_resolver",
]
