"""
SAPPHIRE Metrics Package

Unified metrics collection for SAPPHIRE v3.7:
- Session metrics (tool usage, costs, errors)
- Performance metrics (latency, SLA compliance)
- Test coverage metrics (pass rate, failures)

Stream-only architecture (no disk persistence).
Thread-safe for concurrent access.
"""

from .sapphire_metrics import SapphireMetrics, get_metrics

__all__ = ["SapphireMetrics", "get_metrics"]
