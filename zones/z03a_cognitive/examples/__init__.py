"""
z03a_cognitive.examples - Example implementations of IntelligentAgent patterns

Demonstrates common patterns for implementing IntelligentAgent:
- Tool Pattern: Agent that performs specific actions (e.g., create Linear issues)
- Query Pattern: Agent that retrieves and processes data (e.g., patient summaries)
"""

from .tool_pattern import ExerciseFlagToolAgent
from .query_pattern import PatientSummaryQueryAgent

__all__ = ['ExerciseFlagToolAgent', 'PatientSummaryQueryAgent']
