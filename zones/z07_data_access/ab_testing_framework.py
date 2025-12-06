"""
A/B Testing Framework - Wave 2 Agent 11
Enables rigorous comparison of ML routing vs static routing

Features:
- A/B test configuration and management
- Traffic splitting (50/50, 90/10, etc.)
- Metric collection per variant
- Statistical significance testing (chi-square, t-test)
- Automated test analysis and reporting
"""

import time
import hashlib
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional, Tuple
from dataclasses import dataclass, asdict
from enum import Enum
from collections import defaultdict
import json

import numpy as np

# Try to import scipy for statistical tests
try:
    from scipy import stats
    SCIPY_AVAILABLE = True
except ImportError:
    SCIPY_AVAILABLE = False
    print("Warning: scipy not available. Statistical tests will be limited.")


class VariantType(Enum):
    """A/B test variant types"""
    CONTROL = "control"  # Static routing
    TREATMENT = "treatment"  # ML routing


@dataclass
class VariantConfig:
    """Configuration for an A/B test variant"""
    name: str
    variant_type: VariantType
    router_mode: str  # 'static' or 'ml'
    traffic_percentage: float  # 0.0-1.0
    enabled: bool = True


@dataclass
class ABTestConfig:
    """A/B test configuration"""
    test_name: str
    description: str
    start_time: datetime
    duration_days: int
    variants: Dict[str, VariantConfig]
    metrics_to_track: List[str]
    min_sample_size: int
    confidence_level: float  # e.g., 0.95 for 95%

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary"""
        return {
            'test_name': self.test_name,
            'description': self.description,
            'start_time': self.start_time.isoformat(),
            'duration_days': self.duration_days,
            'variants': {k: asdict(v) for k, v in self.variants.items()},
            'metrics_to_track': self.metrics_to_track,
            'min_sample_size': self.min_sample_size,
            'confidence_level': self.confidence_level
        }


@dataclass
class QueryMetrics:
    """Metrics for a single query execution"""
    query_id: str
    variant: str
    timestamp: datetime
    tier_selected: str
    tier_optimal: str
    latency_ms: float
    result_size: int
    was_optimal: bool

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary"""
        return {
            'query_id': self.query_id,
            'variant': self.variant,
            'timestamp': self.timestamp.isoformat(),
            'tier_selected': self.tier_selected,
            'tier_optimal': self.tier_optimal,
            'latency_ms': self.latency_ms,
            'result_size': self.result_size,
            'was_optimal': self.was_optimal
        }


@dataclass
class VariantMetrics:
    """Aggregated metrics for a variant"""
    variant_name: str
    sample_size: int
    accuracy: float  # Tier selection accuracy
    avg_latency_ms: float
    p50_latency_ms: float
    p95_latency_ms: float
    p99_latency_ms: float
    throughput_qps: float
    error_rate: float

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary"""
        return asdict(self)


@dataclass
class StatisticalTest:
    """Statistical test result"""
    test_name: str
    metric: str
    control_value: float
    treatment_value: float
    improvement_pct: float
    p_value: float
    is_significant: bool
    confidence_level: float

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary"""
        return asdict(self)


@dataclass
class ABTestResults:
    """Complete A/B test results"""
    test_config: ABTestConfig
    variant_metrics: Dict[str, VariantMetrics]
    statistical_tests: List[StatisticalTest]
    winner: Optional[str]
    recommendation: str
    test_duration_actual: timedelta

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary"""
        return {
            'test_config': self.test_config.to_dict(),
            'variant_metrics': {k: v.to_dict() for k, v in self.variant_metrics.items()},
            'statistical_tests': [t.to_dict() for t in self.statistical_tests],
            'winner': self.winner,
            'recommendation': self.recommendation,
            'test_duration_actual': str(self.test_duration_actual)
        }


class ABTestingFramework:
    """
    A/B testing framework for comparing routing strategies

    Enables rigorous experimentation with traffic splitting,
    metric collection, and statistical analysis.
    """

    def __init__(self, config: ABTestConfig):
        """
        Initialize A/B testing framework

        Args:
            config: Test configuration
        """
        self.config = config
        self.is_active = True
        self.start_time = datetime.now()

        # Data collection
        self.query_metrics: List[QueryMetrics] = []
        self.variant_samples: Dict[str, List[QueryMetrics]] = defaultdict(list)

        # Statistics
        self.total_queries = 0
        self.queries_per_variant = defaultdict(int)

    def assign_variant(self, query_id: str) -> str:
        """
        Assign query to a variant based on traffic split

        Uses consistent hashing for deterministic assignment

        Args:
            query_id: Unique query identifier

        Returns:
            Variant name
        """
        # Use hash for deterministic assignment
        hash_value = int(hashlib.md5(query_id.encode()).hexdigest(), 16)
        random_value = (hash_value % 10000) / 10000.0  # 0.0-1.0

        # Assign based on traffic percentages
        cumulative = 0.0
        for variant_name, variant_config in self.config.variants.items():
            if not variant_config.enabled:
                continue

            cumulative += variant_config.traffic_percentage
            if random_value < cumulative:
                return variant_name

        # Fallback to first variant
        return list(self.config.variants.keys())[0]

    def record_query(
        self,
        query_id: str,
        variant: str,
        tier_selected: str,
        tier_optimal: str,
        latency_ms: float,
        result_size: int = 0
    ):
        """
        Record query execution metrics

        Args:
            query_id: Unique query ID
            variant: Variant name
            tier_selected: Tier selected by router
            tier_optimal: Optimal tier for this query
            latency_ms: Query latency
            result_size: Number of rows returned
        """
        metrics = QueryMetrics(
            query_id=query_id,
            variant=variant,
            timestamp=datetime.now(),
            tier_selected=tier_selected,
            tier_optimal=tier_optimal,
            latency_ms=latency_ms,
            result_size=result_size,
            was_optimal=(tier_selected == tier_optimal)
        )

        self.query_metrics.append(metrics)
        self.variant_samples[variant].append(metrics)
        self.total_queries += 1
        self.queries_per_variant[variant] += 1

    def calculate_variant_metrics(self, variant_name: str) -> Optional[VariantMetrics]:
        """
        Calculate aggregated metrics for a variant

        Args:
            variant_name: Name of variant

        Returns:
            VariantMetrics or None if insufficient data
        """
        samples = self.variant_samples[variant_name]

        if not samples:
            return None

        # Calculate accuracy
        optimal_count = sum(1 for s in samples if s.was_optimal)
        accuracy = (optimal_count / len(samples)) * 100

        # Calculate latencies
        latencies = [s.latency_ms for s in samples]
        avg_latency = np.mean(latencies)
        p50 = np.percentile(latencies, 50)
        p95 = np.percentile(latencies, 95)
        p99 = np.percentile(latencies, 99)

        # Calculate throughput (queries per second)
        if len(samples) > 1:
            time_range = (samples[-1].timestamp - samples[0].timestamp).total_seconds()
            throughput = len(samples) / max(time_range, 1.0)
        else:
            throughput = 0.0

        return VariantMetrics(
            variant_name=variant_name,
            sample_size=len(samples),
            accuracy=accuracy,
            avg_latency_ms=avg_latency,
            p50_latency_ms=p50,
            p95_latency_ms=p95,
            p99_latency_ms=p99,
            throughput_qps=throughput,
            error_rate=0.0  # Could track errors if needed
        )

    def run_statistical_tests(
        self,
        control_variant: str,
        treatment_variant: str
    ) -> List[StatisticalTest]:
        """
        Run statistical tests comparing control vs treatment

        Args:
            control_variant: Name of control variant
            treatment_variant: Name of treatment variant

        Returns:
            List of StatisticalTest results
        """
        if not SCIPY_AVAILABLE:
            print("Warning: scipy not available, skipping statistical tests")
            return []

        control_samples = self.variant_samples[control_variant]
        treatment_samples = self.variant_samples[treatment_variant]

        if len(control_samples) < self.config.min_sample_size or \
           len(treatment_samples) < self.config.min_sample_size:
            print(f"Insufficient samples: control={len(control_samples)}, treatment={len(treatment_samples)}")
            return []

        tests = []

        # Test 1: Accuracy (Chi-square test)
        control_optimal = sum(1 for s in control_samples if s.was_optimal)
        control_suboptimal = len(control_samples) - control_optimal
        treatment_optimal = sum(1 for s in treatment_samples if s.was_optimal)
        treatment_suboptimal = len(treatment_samples) - treatment_optimal

        contingency_table = [
            [control_optimal, control_suboptimal],
            [treatment_optimal, treatment_suboptimal]
        ]

        chi2, p_value_accuracy = stats.chi2_contingency(contingency_table)[:2]

        control_accuracy = (control_optimal / len(control_samples)) * 100
        treatment_accuracy = (treatment_optimal / len(treatment_samples)) * 100
        accuracy_improvement = ((treatment_accuracy - control_accuracy) / control_accuracy) * 100

        tests.append(StatisticalTest(
            test_name="chi_square_accuracy",
            metric="accuracy",
            control_value=control_accuracy,
            treatment_value=treatment_accuracy,
            improvement_pct=accuracy_improvement,
            p_value=p_value_accuracy,
            is_significant=p_value_accuracy < (1 - self.config.confidence_level),
            confidence_level=self.config.confidence_level
        ))

        # Test 2: Latency (T-test)
        control_latencies = [s.latency_ms for s in control_samples]
        treatment_latencies = [s.latency_ms for s in treatment_samples]

        t_stat, p_value_latency = stats.ttest_ind(control_latencies, treatment_latencies)

        control_avg_latency = np.mean(control_latencies)
        treatment_avg_latency = np.mean(treatment_latencies)
        latency_improvement = ((control_avg_latency - treatment_avg_latency) / control_avg_latency) * 100

        tests.append(StatisticalTest(
            test_name="t_test_latency",
            metric="avg_latency_ms",
            control_value=control_avg_latency,
            treatment_value=treatment_avg_latency,
            improvement_pct=latency_improvement,
            p_value=p_value_latency,
            is_significant=p_value_latency < (1 - self.config.confidence_level),
            confidence_level=self.config.confidence_level
        ))

        # Test 3: P95 Latency (Mann-Whitney U test)
        u_stat, p_value_p95 = stats.mannwhitneyu(control_latencies, treatment_latencies)

        control_p95 = np.percentile(control_latencies, 95)
        treatment_p95 = np.percentile(treatment_latencies, 95)
        p95_improvement = ((control_p95 - treatment_p95) / control_p95) * 100

        tests.append(StatisticalTest(
            test_name="mann_whitney_p95",
            metric="p95_latency_ms",
            control_value=control_p95,
            treatment_value=treatment_p95,
            improvement_pct=p95_improvement,
            p_value=p_value_p95,
            is_significant=p_value_p95 < (1 - self.config.confidence_level),
            confidence_level=self.config.confidence_level
        ))

        return tests

    def analyze_results(self) -> ABTestResults:
        """
        Analyze A/B test results and determine winner

        Returns:
            ABTestResults with complete analysis
        """
        # Calculate metrics for all variants
        variant_metrics = {}
        for variant_name in self.config.variants.keys():
            metrics = self.calculate_variant_metrics(variant_name)
            if metrics:
                variant_metrics[variant_name] = metrics

        # Run statistical tests (assuming first two variants are control/treatment)
        variant_names = list(self.config.variants.keys())
        control_name = variant_names[0]
        treatment_name = variant_names[1] if len(variant_names) > 1 else variant_names[0]

        statistical_tests = self.run_statistical_tests(control_name, treatment_name)

        # Determine winner
        winner = self._determine_winner(variant_metrics, statistical_tests)

        # Generate recommendation
        recommendation = self._generate_recommendation(
            variant_metrics,
            statistical_tests,
            winner
        )

        test_duration = datetime.now() - self.start_time

        return ABTestResults(
            test_config=self.config,
            variant_metrics=variant_metrics,
            statistical_tests=statistical_tests,
            winner=winner,
            recommendation=recommendation,
            test_duration_actual=test_duration
        )

    def _determine_winner(
        self,
        variant_metrics: Dict[str, VariantMetrics],
        statistical_tests: List[StatisticalTest]
    ) -> Optional[str]:
        """
        Determine which variant won the test

        Args:
            variant_metrics: Metrics for all variants
            statistical_tests: Statistical test results

        Returns:
            Winner variant name or None
        """
        if len(variant_metrics) < 2:
            return None

        # Check if treatment has significant improvements
        significant_improvements = 0
        for test in statistical_tests:
            if test.is_significant and test.improvement_pct > 0:
                significant_improvements += 1

        # Treatment wins if it has significant improvements
        variant_names = list(variant_metrics.keys())
        treatment_name = variant_names[1] if len(variant_names) > 1 else None

        if significant_improvements >= 2 and treatment_name:
            return treatment_name

        # Control wins if treatment doesn't show significant improvement
        return variant_names[0]

    def _generate_recommendation(
        self,
        variant_metrics: Dict[str, VariantMetrics],
        statistical_tests: List[StatisticalTest],
        winner: Optional[str]
    ) -> str:
        """Generate recommendation based on test results"""
        if not winner:
            return "Insufficient data to make recommendation"

        recommendations = []

        # Check sample sizes
        for variant_name, metrics in variant_metrics.items():
            if metrics.sample_size < self.config.min_sample_size:
                recommendations.append(
                    f"Warning: {variant_name} has insufficient samples ({metrics.sample_size})"
                )

        # Analyze statistical significance
        significant_tests = [t for t in statistical_tests if t.is_significant]

        if not significant_tests:
            recommendations.append(
                "No statistically significant differences found. "
                "Consider extending test duration or increasing sample size."
            )
            return " ".join(recommendations)

        # Winner recommendation
        winner_metrics = variant_metrics[winner]

        recommendations.append(f"Recommended variant: {winner}")

        # Add specific improvements
        for test in significant_tests:
            if test.improvement_pct > 0:
                recommendations.append(
                    f"- {test.metric}: {test.improvement_pct:.1f}% improvement "
                    f"(p={test.p_value:.4f})"
                )

        recommendations.append(
            f"\n{winner} variant shows statistically significant improvements. "
            f"Recommend rolling out to 100% of traffic."
        )

        return " ".join(recommendations)

    def get_stats(self) -> Dict[str, Any]:
        """Get A/B test statistics"""
        return {
            'test_name': self.config.test_name,
            'is_active': self.is_active,
            'start_time': self.start_time.isoformat(),
            'total_queries': self.total_queries,
            'queries_per_variant': dict(self.queries_per_variant),
            'variants': list(self.config.variants.keys())
        }

    def export_results(self, path: str):
        """
        Export test results to JSON file

        Args:
            path: File path to export to
        """
        results = self.analyze_results()

        with open(path, 'w') as f:
            json.dump(results.to_dict(), f, indent=2)

    def stop_test(self):
        """Stop the A/B test"""
        self.is_active = False


def create_ml_vs_static_test(
    duration_days: int = 7,
    min_sample_size: int = 1000,
    traffic_split: Tuple[float, float] = (0.5, 0.5)
) -> ABTestConfig:
    """
    Create standard ML vs Static routing A/B test configuration

    Args:
        duration_days: Test duration in days
        min_sample_size: Minimum samples per variant
        traffic_split: (control %, treatment %) as fractions

    Returns:
        ABTestConfig
    """
    return ABTestConfig(
        test_name="ml_vs_static_routing",
        description="Compare ML-based routing against static rule-based routing",
        start_time=datetime.now(),
        duration_days=duration_days,
        variants={
            'control': VariantConfig(
                name='control',
                variant_type=VariantType.CONTROL,
                router_mode='static',
                traffic_percentage=traffic_split[0],
                enabled=True
            ),
            'treatment': VariantConfig(
                name='treatment',
                variant_type=VariantType.TREATMENT,
                router_mode='ml',
                traffic_percentage=traffic_split[1],
                enabled=True
            )
        },
        metrics_to_track=['accuracy', 'latency', 'throughput'],
        min_sample_size=min_sample_size,
        confidence_level=0.95
    )
