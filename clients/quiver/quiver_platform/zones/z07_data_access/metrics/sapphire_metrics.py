#!/usr/bin/env python3.11
"""
SAPPHIRE Metrics Collector

Collects and exposes metrics for SAPPHIRE v3.7 in Prometheus format.
Stream-only, in-memory metrics with thread-safe access.

Metrics Categories:
1. Session: tool usage, costs, errors
2. Performance: latency p50/p95/p99, SLA violations
3. Testing: coverage, pass rates

Usage:
    from metrics import get_metrics

    metrics = get_metrics()
    metrics.track_tool_call("vector_neighbors", duration_ms=245.3, success=True)
    metrics.track_session_cost(input_tokens=1500, output_tokens=300, cost_usd=0.0075)

    # Export Prometheus format
    prom_text = metrics.to_prometheus()
"""

import threading
import time
from collections import defaultdict
from datetime import datetime
from typing import Dict, List, Optional


class SapphireMetrics:
    """Thread-safe metrics collector for SAPPHIRE."""

    def __init__(self):
        self._lock = threading.Lock()

        # Session metrics
        self._sessions_total = 0
        self._tools_used = defaultdict(int)  # {tool_name: count}
        self._tool_errors = defaultdict(lambda: defaultdict(int))  # {tool_name: {error_type: count}}
        self._session_cost_usd = 0.0
        self._input_tokens_total = 0
        self._output_tokens_total = 0

        # Performance metrics (latencies in milliseconds)
        self._tool_latencies = defaultdict(list)  # {tool_name: [durations]}
        self._sla_violations = defaultdict(int)  # {tool_name: count}
        self._tool_duration_sum = defaultdict(float)  # {tool_name: sum_ms}
        self._tool_duration_count = defaultdict(int)  # {tool_name: count}

        # Test metrics
        self._test_coverage_percent = 0.0
        self._tests_passed = 0
        self._tests_failed = 0
        self._test_durations = {}  # {test_name: duration_seconds}

        # Metadata
        self._start_time = time.time()
        self._last_reset = datetime.now()

    def track_tool_call(
        self,
        tool_name: str,
        duration_ms: float,
        success: bool = True,
        error_type: Optional[str] = None
    ):
        """
        Track a tool call.

        Args:
            tool_name: Name of tool executed
            duration_ms: Execution time in milliseconds
            success: Whether call succeeded
            error_type: Type of error if failed (e.g., "timeout", "validation_error")
        """
        with self._lock:
            # Increment usage counter
            self._tools_used[tool_name] += 1

            # Track latency
            self._tool_latencies[tool_name].append(duration_ms)
            self._tool_duration_sum[tool_name] += duration_ms
            self._tool_duration_count[tool_name] += 1

            # Track errors
            if not success and error_type:
                self._tool_errors[tool_name][error_type] += 1

            # Check SLA violations (moderate target: p95 < 3000ms)
            if duration_ms > 3000:
                self._sla_violations[tool_name] += 1

    def track_session_cost(
        self,
        input_tokens: int,
        output_tokens: int,
        cost_usd: float
    ):
        """
        Track session cost metrics.

        Args:
            input_tokens: Input tokens used
            output_tokens: Output tokens generated
            cost_usd: Cost in USD
        """
        with self._lock:
            self._sessions_total += 1
            self._input_tokens_total += input_tokens
            self._output_tokens_total += output_tokens
            self._session_cost_usd += cost_usd

    def track_sla_violation(
        self,
        tool_name: str,
        target_ms: float,
        actual_ms: float
    ):
        """
        Track SLA violation.

        Args:
            tool_name: Name of tool
            target_ms: SLA target in milliseconds
            actual_ms: Actual duration in milliseconds
        """
        if actual_ms > target_ms:
            with self._lock:
                self._sla_violations[tool_name] += 1

    def track_test_result(
        self,
        test_name: str,
        passed: bool,
        duration_seconds: float
    ):
        """
        Track test result.

        Args:
            test_name: Name of test
            passed: Whether test passed
            duration_seconds: Test duration in seconds
        """
        with self._lock:
            if passed:
                self._tests_passed += 1
            else:
                self._tests_failed += 1

            self._test_durations[test_name] = duration_seconds

    def update_test_coverage(self, coverage_percent: float):
        """
        Update test coverage metric.

        Args:
            coverage_percent: Coverage percentage (0-100)
        """
        with self._lock:
            self._test_coverage_percent = coverage_percent

    def _calculate_percentile(self, values: List[float], percentile: int) -> float:
        """Calculate percentile from list of values."""
        if not values:
            return 0.0
        sorted_vals = sorted(values)
        index = int((percentile / 100.0) * len(sorted_vals))
        index = min(index, len(sorted_vals) - 1)
        return sorted_vals[index]

    def get_latency_percentiles(self, tool_name: str) -> Dict[str, float]:
        """
        Get latency percentiles for a tool.

        Args:
            tool_name: Name of tool

        Returns:
            Dict with p50, p95, p99 latencies
        """
        with self._lock:
            latencies = self._tool_latencies.get(tool_name, [])
            if not latencies:
                return {"p50": 0.0, "p95": 0.0, "p99": 0.0}

            return {
                "p50": self._calculate_percentile(latencies, 50),
                "p95": self._calculate_percentile(latencies, 95),
                "p99": self._calculate_percentile(latencies, 99),
            }

    def to_prometheus(self) -> str:
        """
        Export metrics in Prometheus format.

        Returns:
            Prometheus-formatted metrics string
        """
        with self._lock:
            lines = []

            # Session metrics
            lines.append("# HELP sapphire_sessions_total Total SAPPHIRE sessions")
            lines.append("# TYPE sapphire_sessions_total counter")
            lines.append(f"sapphire_sessions_total {self._sessions_total}")
            lines.append("")

            lines.append("# HELP sapphire_tools_used_total Total tool invocations by tool name")
            lines.append("# TYPE sapphire_tools_used_total counter")
            for tool_name, count in self._tools_used.items():
                lines.append(f'sapphire_tools_used_total{{tool_name="{tool_name}"}} {count}')
            lines.append("")

            lines.append("# HELP sapphire_tool_errors_total Tool errors by tool and error type")
            lines.append("# TYPE sapphire_tool_errors_total counter")
            for tool_name, errors in self._tool_errors.items():
                for error_type, count in errors.items():
                    lines.append(f'sapphire_tool_errors_total{{tool_name="{tool_name}",error_type="{error_type}"}} {count}')
            lines.append("")

            lines.append("# HELP sapphire_session_cost_usd Total session cost in USD")
            lines.append("# TYPE sapphire_session_cost_usd counter")
            lines.append(f"sapphire_session_cost_usd {self._session_cost_usd:.6f}")
            lines.append("")

            lines.append("# HELP sapphire_input_tokens_total Total input tokens")
            lines.append("# TYPE sapphire_input_tokens_total counter")
            lines.append(f"sapphire_input_tokens_total {self._input_tokens_total}")
            lines.append("")

            lines.append("# HELP sapphire_output_tokens_total Total output tokens")
            lines.append("# TYPE sapphire_output_tokens_total counter")
            lines.append(f"sapphire_output_tokens_total {self._output_tokens_total}")
            lines.append("")

            # Performance metrics
            lines.append("# HELP sapphire_tool_latency_seconds Tool latency percentiles in seconds")
            lines.append("# TYPE sapphire_tool_latency_seconds gauge")
            for tool_name in self._tool_latencies.keys():
                percentiles = self.get_latency_percentiles(tool_name)
                for p_name, p_value in percentiles.items():
                    lines.append(f'sapphire_tool_latency_seconds{{tool_name="{tool_name}",percentile="{p_name}"}} {p_value / 1000.0:.6f}')
            lines.append("")

            lines.append("# HELP sapphire_sla_violations_total SLA violations by tool")
            lines.append("# TYPE sapphire_sla_violations_total counter")
            for tool_name, count in self._sla_violations.items():
                lines.append(f'sapphire_sla_violations_total{{tool_name="{tool_name}"}} {count}')
            lines.append("")

            lines.append("# HELP sapphire_tool_duration_sum Sum of tool durations in seconds")
            lines.append("# TYPE sapphire_tool_duration_sum counter")
            for tool_name, duration_sum in self._tool_duration_sum.items():
                lines.append(f'sapphire_tool_duration_sum{{tool_name="{tool_name}"}} {duration_sum / 1000.0:.6f}')
            lines.append("")

            lines.append("# HELP sapphire_tool_duration_count Count of tool invocations")
            lines.append("# TYPE sapphire_tool_duration_count counter")
            for tool_name, count in self._tool_duration_count.items():
                lines.append(f'sapphire_tool_duration_count{{tool_name="{tool_name}"}} {count}')
            lines.append("")

            # Test metrics
            lines.append("# HELP sapphire_test_coverage_percent Test coverage percentage")
            lines.append("# TYPE sapphire_test_coverage_percent gauge")
            lines.append(f"sapphire_test_coverage_percent {self._test_coverage_percent:.2f}")
            lines.append("")

            lines.append("# HELP sapphire_tests_total Total tests by status")
            lines.append("# TYPE sapphire_tests_total counter")
            lines.append(f'sapphire_tests_total{{status="passed"}} {self._tests_passed}')
            lines.append(f'sapphire_tests_total{{status="failed"}} {self._tests_failed}')
            lines.append("")

            lines.append("# HELP sapphire_test_duration_seconds Test duration by test name")
            lines.append("# TYPE sapphire_test_duration_seconds gauge")
            for test_name, duration in self._test_durations.items():
                lines.append(f'sapphire_test_duration_seconds{{test_name="{test_name}"}} {duration:.6f}')
            lines.append("")

            # Uptime
            uptime = time.time() - self._start_time
            lines.append("# HELP sapphire_uptime_seconds Metrics collector uptime")
            lines.append("# TYPE sapphire_uptime_seconds counter")
            lines.append(f"sapphire_uptime_seconds {uptime:.0f}")
            lines.append("")

            return "\n".join(lines)

    def get_summary(self) -> Dict:
        """Get metrics summary as dict."""
        with self._lock:
            return {
                "sessions_total": self._sessions_total,
                "tools_used": dict(self._tools_used),
                "total_cost_usd": self._session_cost_usd,
                "input_tokens": self._input_tokens_total,
                "output_tokens": self._output_tokens_total,
                "test_coverage_percent": self._test_coverage_percent,
                "tests_passed": self._tests_passed,
                "tests_failed": self._tests_failed,
                "sla_violations": dict(self._sla_violations),
            }

    def reset(self):
        """Reset all metrics (for testing)."""
        with self._lock:
            self._sessions_total = 0
            self._tools_used.clear()
            self._tool_errors.clear()
            self._session_cost_usd = 0.0
            self._input_tokens_total = 0
            self._output_tokens_total = 0
            self._tool_latencies.clear()
            self._sla_violations.clear()
            self._tool_duration_sum.clear()
            self._tool_duration_count.clear()
            self._test_coverage_percent = 0.0
            self._tests_passed = 0
            self._tests_failed = 0
            self._test_durations.clear()
            self._last_reset = datetime.now()


# Singleton instance
_metrics_instance: Optional[SapphireMetrics] = None
_metrics_lock = threading.Lock()


def get_metrics() -> SapphireMetrics:
    """Get singleton metrics instance."""
    global _metrics_instance

    if _metrics_instance is None:
        with _metrics_lock:
            if _metrics_instance is None:
                _metrics_instance = SapphireMetrics()

    return _metrics_instance
