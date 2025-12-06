"""
Adaptive Threshold Adjustment - Wave 2 Agent 11
Dynamically adjusts routing thresholds based on workload and performance

Features:
- Dynamic threshold adjustment for tier selection
- Workload-based tuning (adapts to query patterns)
- Performance feedback loop
- Threshold history tracking
- Automatic optimization based on latency and throughput
"""

import time
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional, Tuple
from dataclasses import dataclass, asdict
from collections import deque
import json
from pathlib import Path

import numpy as np


@dataclass
class ThresholdConfig:
    """Configuration for tier selection thresholds"""
    master_days: float  # Days threshold for Master tier
    minio_days: float  # Days threshold for MinIO tier
    confidence_threshold: float  # ML confidence threshold
    latency_threshold_ms: float  # Max acceptable latency
    last_updated: datetime
    performance_score: float  # 0-100 score

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary"""
        return {
            'master_days': self.master_days,
            'minio_days': self.minio_days,
            'confidence_threshold': self.confidence_threshold,
            'latency_threshold_ms': self.latency_threshold_ms,
            'last_updated': self.last_updated.isoformat(),
            'performance_score': self.performance_score
        }


@dataclass
class WorkloadMetrics:
    """Current workload metrics"""
    queries_per_second: float
    avg_latency_ms: float
    p95_latency_ms: float
    p99_latency_ms: float
    master_load_pct: float
    tier_utilization: Dict[str, float]
    timestamp: datetime

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary"""
        return {
            'queries_per_second': self.queries_per_second,
            'avg_latency_ms': self.avg_latency_ms,
            'p95_latency_ms': self.p95_latency_ms,
            'p99_latency_ms': self.p99_latency_ms,
            'master_load_pct': self.master_load_pct,
            'tier_utilization': self.tier_utilization,
            'timestamp': self.timestamp.isoformat()
        }


@dataclass
class ThresholdAdjustment:
    """Record of a threshold adjustment"""
    timestamp: datetime
    old_config: ThresholdConfig
    new_config: ThresholdConfig
    reason: str
    expected_improvement: str

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary"""
        return {
            'timestamp': self.timestamp.isoformat(),
            'old_config': self.old_config.to_dict(),
            'new_config': self.new_config.to_dict(),
            'reason': self.reason,
            'expected_improvement': self.expected_improvement
        }


class AdaptiveThresholdManager:
    """
    Manages adaptive threshold adjustment for tier routing

    Monitors workload patterns and automatically adjusts routing thresholds
    to optimize performance and resource utilization.
    """

    def __init__(
        self,
        initial_config: Optional[ThresholdConfig] = None,
        adjustment_interval_minutes: int = 15,
        history_window_size: int = 100
    ):
        """
        Initialize adaptive threshold manager

        Args:
            initial_config: Starting threshold configuration
            adjustment_interval_minutes: How often to evaluate adjustments
            history_window_size: Number of historical metrics to keep
        """
        # Default configuration
        if initial_config is None:
            initial_config = ThresholdConfig(
                master_days=7.0,
                minio_days=90.0,
                confidence_threshold=0.7,
                latency_threshold_ms=100.0,
                last_updated=datetime.now(),
                performance_score=50.0
            )

        self.current_config = initial_config
        self.adjustment_interval = timedelta(minutes=adjustment_interval_minutes)
        self.last_adjustment_time = datetime.now()

        # History tracking
        self.metrics_history: deque = deque(maxlen=history_window_size)
        self.adjustment_history: List[ThresholdAdjustment] = []

        # Performance targets
        self.target_master_load_pct = 40.0  # Target 40% load on master
        self.target_avg_latency_ms = 50.0   # Target 50ms average latency
        self.max_p95_latency_ms = 200.0     # Max 200ms p95 latency

        # Adjustment parameters
        self.min_master_days = 3.0
        self.max_master_days = 14.0
        self.min_minio_days = 30.0
        self.max_minio_days = 180.0
        self.min_confidence = 0.5
        self.max_confidence = 0.9

        # Statistics
        self.total_adjustments = 0
        self.performance_improvements = 0

    def record_metrics(self, metrics: WorkloadMetrics):
        """
        Record current workload metrics

        Args:
            metrics: Current workload metrics
        """
        self.metrics_history.append(metrics)

    def should_adjust(self) -> bool:
        """
        Check if thresholds should be adjusted

        Returns:
            True if adjustment is due
        """
        time_since_last = datetime.now() - self.last_adjustment_time
        return time_since_last >= self.adjustment_interval

    def evaluate_and_adjust(self) -> Optional[ThresholdAdjustment]:
        """
        Evaluate current performance and adjust thresholds if needed

        Returns:
            ThresholdAdjustment if adjustment made, None otherwise
        """
        if not self.should_adjust():
            return None

        if len(self.metrics_history) < 10:
            # Need more data
            return None

        # Analyze recent metrics
        recent_metrics = list(self.metrics_history)[-20:]  # Last 20 samples

        avg_master_load = np.mean([m.master_load_pct for m in recent_metrics])
        avg_latency = np.mean([m.avg_latency_ms for m in recent_metrics])
        avg_p95 = np.mean([m.p95_latency_ms for m in recent_metrics])

        # Determine if adjustment needed
        adjustment = self._determine_adjustment(
            avg_master_load,
            avg_latency,
            avg_p95
        )

        if adjustment:
            self.last_adjustment_time = datetime.now()
            self.adjustment_history.append(adjustment)
            self.current_config = adjustment.new_config
            self.total_adjustments += 1

        return adjustment

    def _determine_adjustment(
        self,
        avg_master_load: float,
        avg_latency: float,
        avg_p95: float
    ) -> Optional[ThresholdAdjustment]:
        """
        Determine what threshold adjustments to make

        Args:
            avg_master_load: Average master tier load %
            avg_latency: Average query latency
            avg_p95: Average p95 latency

        Returns:
            ThresholdAdjustment or None
        """
        old_config = self.current_config
        new_config = ThresholdConfig(
            master_days=old_config.master_days,
            minio_days=old_config.minio_days,
            confidence_threshold=old_config.confidence_threshold,
            latency_threshold_ms=old_config.latency_threshold_ms,
            last_updated=datetime.now(),
            performance_score=old_config.performance_score
        )

        reason = []
        expected_improvement = []
        adjusted = False

        # Adjust master_days based on load
        if avg_master_load > self.target_master_load_pct + 10:
            # Master overloaded, reduce threshold (route less to master)
            new_threshold = max(
                self.min_master_days,
                new_config.master_days * 0.9
            )
            if new_threshold != new_config.master_days:
                new_config.master_days = new_threshold
                reason.append(f"Master load high ({avg_master_load:.1f}%), reducing master_days")
                expected_improvement.append("Reduce master tier load")
                adjusted = True

        elif avg_master_load < self.target_master_load_pct - 10:
            # Master underutilized, increase threshold (route more to master)
            new_threshold = min(
                self.max_master_days,
                new_config.master_days * 1.1
            )
            if new_threshold != new_config.master_days:
                new_config.master_days = new_threshold
                reason.append(f"Master load low ({avg_master_load:.1f}%), increasing master_days")
                expected_improvement.append("Better utilize master tier")
                adjusted = True

        # Adjust confidence threshold based on latency
        if avg_p95 > self.max_p95_latency_ms:
            # High latency, reduce confidence threshold (more static routing)
            new_threshold = max(
                self.min_confidence,
                new_config.confidence_threshold - 0.05
            )
            if new_threshold != new_config.confidence_threshold:
                new_config.confidence_threshold = new_threshold
                reason.append(f"High p95 latency ({avg_p95:.1f}ms), reducing ML confidence threshold")
                expected_improvement.append("Reduce latency with more conservative routing")
                adjusted = True

        elif avg_latency < self.target_avg_latency_ms and avg_p95 < self.max_p95_latency_ms * 0.7:
            # Good latency, can increase confidence threshold (more ML routing)
            new_threshold = min(
                self.max_confidence,
                new_config.confidence_threshold + 0.05
            )
            if new_threshold != new_config.confidence_threshold:
                new_config.confidence_threshold = new_threshold
                reason.append(f"Low latency ({avg_latency:.1f}ms), increasing ML confidence threshold")
                expected_improvement.append("Leverage ML routing more aggressively")
                adjusted = True

        # Adjust MinIO threshold based on tier utilization
        if len(self.metrics_history) > 0:
            recent_utilization = self.metrics_history[-1].tier_utilization
            minio_util = recent_utilization.get('minio', 0)

            if minio_util > 80:
                # MinIO overloaded, increase threshold (route less to MinIO)
                new_threshold = min(
                    self.max_minio_days,
                    new_config.minio_days * 1.1
                )
                if new_threshold != new_config.minio_days:
                    new_config.minio_days = new_threshold
                    reason.append(f"MinIO utilization high ({minio_util:.1f}%), increasing minio_days")
                    expected_improvement.append("Balance load across tiers")
                    adjusted = True

        if not adjusted:
            return None

        # Calculate performance score
        new_config.performance_score = self._calculate_performance_score(
            avg_master_load,
            avg_latency,
            avg_p95
        )

        return ThresholdAdjustment(
            timestamp=datetime.now(),
            old_config=old_config,
            new_config=new_config,
            reason="; ".join(reason),
            expected_improvement=", ".join(expected_improvement)
        )

    def _calculate_performance_score(
        self,
        master_load: float,
        avg_latency: float,
        p95_latency: float
    ) -> float:
        """
        Calculate overall performance score (0-100)

        Args:
            master_load: Master tier load %
            avg_latency: Average latency
            p95_latency: P95 latency

        Returns:
            Performance score
        """
        score = 100.0

        # Penalize master load deviation
        load_deviation = abs(master_load - self.target_master_load_pct)
        score -= min(load_deviation * 0.5, 20)

        # Penalize high latency
        if avg_latency > self.target_avg_latency_ms:
            latency_penalty = ((avg_latency - self.target_avg_latency_ms) / self.target_avg_latency_ms) * 30
            score -= min(latency_penalty, 30)

        # Penalize high p95
        if p95_latency > self.max_p95_latency_ms:
            p95_penalty = ((p95_latency - self.max_p95_latency_ms) / self.max_p95_latency_ms) * 30
            score -= min(p95_penalty, 30)

        return max(score, 0.0)

    def get_current_thresholds(self) -> ThresholdConfig:
        """Get current threshold configuration"""
        return self.current_config

    def get_adjustment_history(self, limit: int = 10) -> List[ThresholdAdjustment]:
        """
        Get recent threshold adjustments

        Args:
            limit: Maximum number of adjustments to return

        Returns:
            List of recent ThresholdAdjustment objects
        """
        return self.adjustment_history[-limit:]

    def export_history(self, path: str):
        """
        Export adjustment history to JSON file

        Args:
            path: File path to export to
        """
        history_data = [adj.to_dict() for adj in self.adjustment_history]

        with open(path, 'w') as f:
            json.dump({
                'current_config': self.current_config.to_dict(),
                'total_adjustments': self.total_adjustments,
                'adjustment_history': history_data
            }, f, indent=2)

    def import_history(self, path: str):
        """
        Import adjustment history from JSON file

        Args:
            path: File path to import from
        """
        with open(path, 'r') as f:
            data = json.load(f)

        # Restore current config
        config_data = data['current_config']
        self.current_config = ThresholdConfig(
            master_days=config_data['master_days'],
            minio_days=config_data['minio_days'],
            confidence_threshold=config_data['confidence_threshold'],
            latency_threshold_ms=config_data['latency_threshold_ms'],
            last_updated=datetime.fromisoformat(config_data['last_updated']),
            performance_score=config_data['performance_score']
        )

        self.total_adjustments = data['total_adjustments']

    def get_stats(self) -> Dict[str, Any]:
        """Get adaptive threshold statistics"""
        recent_adjustments = self.get_adjustment_history(limit=5)

        avg_performance = 0.0
        if self.adjustment_history:
            avg_performance = np.mean([adj.new_config.performance_score for adj in self.adjustment_history])

        return {
            'current_config': self.current_config.to_dict(),
            'total_adjustments': self.total_adjustments,
            'performance_improvements': self.performance_improvements,
            'avg_performance_score': avg_performance,
            'recent_adjustments': [adj.to_dict() for adj in recent_adjustments],
            'metrics_history_size': len(self.metrics_history),
            'last_adjustment_time': self.last_adjustment_time.isoformat()
        }

    def reset(self):
        """Reset to default configuration"""
        self.current_config = ThresholdConfig(
            master_days=7.0,
            minio_days=90.0,
            confidence_threshold=0.7,
            latency_threshold_ms=100.0,
            last_updated=datetime.now(),
            performance_score=50.0
        )
        self.metrics_history.clear()
        self.adjustment_history.clear()
        self.total_adjustments = 0
        self.performance_improvements = 0


def simulate_workload_scenario(
    scenario: str,
    duration_minutes: int = 60
) -> List[WorkloadMetrics]:
    """
    Simulate different workload scenarios for testing

    Args:
        scenario: Scenario name ('normal', 'high_load', 'unbalanced', 'spike')
        duration_minutes: Duration to simulate

    Returns:
        List of WorkloadMetrics
    """
    metrics = []
    base_time = datetime.now()

    for minute in range(duration_minutes):
        timestamp = base_time + timedelta(minutes=minute)

        if scenario == 'normal':
            qps = 100 + np.random.normal(0, 10)
            master_load = 40 + np.random.normal(0, 5)
            avg_latency = 50 + np.random.normal(0, 10)

        elif scenario == 'high_load':
            qps = 200 + np.random.normal(0, 20)
            master_load = 70 + np.random.normal(0, 10)
            avg_latency = 120 + np.random.normal(0, 30)

        elif scenario == 'unbalanced':
            qps = 100 + np.random.normal(0, 10)
            master_load = 80 + np.random.normal(0, 5)
            avg_latency = 60 + np.random.normal(0, 15)

        elif scenario == 'spike':
            # Spike every 15 minutes
            if minute % 15 < 5:
                qps = 300 + np.random.normal(0, 30)
                master_load = 85 + np.random.normal(0, 5)
                avg_latency = 150 + np.random.normal(0, 40)
            else:
                qps = 80 + np.random.normal(0, 10)
                master_load = 30 + np.random.normal(0, 5)
                avg_latency = 40 + np.random.normal(0, 10)

        else:
            raise ValueError(f"Unknown scenario: {scenario}")

        metric = WorkloadMetrics(
            queries_per_second=max(qps, 0),
            avg_latency_ms=max(avg_latency, 10),
            p95_latency_ms=avg_latency * 2,
            p99_latency_ms=avg_latency * 3,
            master_load_pct=min(max(master_load, 0), 100),
            tier_utilization={
                'master': master_load,
                'pgvector': 30 + np.random.normal(0, 5),
                'minio': 40 + np.random.normal(0, 5),
                'athena': 20 + np.random.normal(0, 5)
            },
            timestamp=timestamp
        )

        metrics.append(metric)

    return metrics
