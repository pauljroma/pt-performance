"""
z03a_cognitive.base - Intelligence base classes for future agent migration

This module provides the foundational IntelligentAgent base class that enables
semantic search, reasoning, and tool calling capabilities. It's designed for
optional adoption - existing agents continue working without modification.
"""

from .intelligent_agent import IntelligentAgent

__all__ = ['IntelligentAgent']
