"""
Custom Business Metrics - Wave 2 Agent 13
Tracks business-impact metrics beyond infrastructure monitoring

Agent 13: Advanced Monitoring Engineer
Date: 2025-12-06

Features:
- Business KPIs (query success rate, user experience)
- Cost tracking (compute, storage, API calls)
- Performance SLOs/SLAs
- User experience metrics (perceived latency, satisfaction)
- Resource efficiency metrics

Note: This module exports metrics to Prometheus. The actual
monitoring/alerting runs on separate monitoring infrastructure.
"""

import time
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional
from dataclasses import dataclass, asdict
from enum import Enum

# Try to import Prometheus client
try:
    from prometheus_client import Counter, Histogram, Gauge, Summary, Info
    PROMETHEUS_AVAILABLE = True
except ImportError:
    PROMETHEUS_AVAILABLE = False
    print("Warning: prometheus_client not available. Custom metrics disabled.")


class MetricCategory(Enum):
    """Category of custom metric"""
    BUSINESS_KPI = "business_kpi"
    USER_EXPERIENCE = "user_experience"
    COST = "cost"
    SLO_SLA = "slo_sla"
    EFFICIENCY = "efficiency"


@dataclass
class BusinessMetricPoint:
    """Business metric data point"""
    category: MetricCategory
    name: str
    value: float
    timestamp: datetime
    tags: Dict[str, str]
    description: str


class CustomMetricsCollector:
    """
    Collects custom business metrics for Wave 2 monitoring

    Metrics are exported to Prometheus and consumed by monitoring infrastructure.
    """

    def __init__(self, export_to_prometheus: bool = True):
        """
        Initialize custom metrics collector

        Args:
            export_to_prometheus: Enable Prometheus export
        """
        self.export_to_prometheus = export_to_prometheus and PROMETHEUS_AVAILABLE

        # Initialize Prometheus metrics if available
        if self.export_to_prometheus:
            self._init_prometheus_metrics()
        else:
            # Fallback: in-memory storage
            self.metrics_history: List[BusinessMetricPoint] = []

    def _init_prometheus_metrics(self):
        """Initialize Prometheus metric collectors"""

        # Business KPIs
        self.query_success_rate = Gauge(
            'sapphire_query_success_rate',
            'Percentage of successful queries (Wave 2)',
            ['tier', 'query_type']
        )

        self.avg_query_latency_ms = Histogram(
            'sapphire_query_latency_milliseconds',
            'Query latency in milliseconds (Wave 2)',
            ['tier', 'query_type'],
            buckets=[1, 5, 10, 25, 50, 100, 250, 500, 1000]
        )

        # User Experience
        self.perceived_latency_ms = Histogram(
            'sapphire_perceived_latency_milliseconds',
            'User-perceived latency (end-to-end, Wave 2)',
            ['endpoint'],
            buckets=[50, 100, 200, 500, 1000, 2000, 5000]
        )

        self.user_satisfaction_score = Gauge(
            'sapphire_user_satisfaction_score',
            'User satisfaction score 0-100 (Wave 2)',
            ['endpoint']
        )

        # Cost Tracking
        self.compute_cost_usd = Counter(
            'sapphire_compute_cost_usd_total',
            'Cumulative compute cost in USD (Wave 2)',
            ['tier']
        )

        self.storage_cost_usd = Counter(
            'sapphire_storage_cost_usd_total',
            'Cumulative storage cost in USD (Wave 2)',
            ['tier']
        )

        self.api_call_cost_usd = Counter(
            'sapphire_api_call_cost_usd_total',
            'Cumulative API call cost in USD (Wave 2)',
            ['service']
        )

        # SLO/SLA Compliance
        self.slo_compliance_percent = Gauge(
            'sapphire_slo_compliance_percent',
            'SLO compliance percentage (Wave 2)',
            ['slo_name']
        )

        self.sla_violations_total = Counter(
            'sapphire_sla_violations_total',
            'Total SLA violations (Wave 2)',
            ['sla_name']
        )

        # Resource Efficiency
        self.queries_per_dollar = Gauge(
            'sapphire_queries_per_dollar',
            'Query efficiency (queries per dollar, Wave 2)',
            ['tier']
        )

        self.cache_hit_rate_percent = Gauge(
            'sapphire_cache_hit_rate_percent',
            'Cache hit rate percentage (Wave 2)',
            ['cache_type']
        )

        self.tier_routing_efficiency = Gauge(
            'sapphire_tier_routing_efficiency_percent',
            'Percentage of queries routed to optimal tier (Wave 2)',
            []
        )

        # Wave 2 Specific Metrics
        self.rust_speedup_factor = Gauge(
            'sapphire_rust_speedup_factor',
            'Rust speedup vs Python baseline (Wave 2)',
            []
        )

        self.ml_routing_accuracy = Gauge(
            'sapphire_ml_routing_accuracy_percent',
            'ML routing prediction accuracy (Wave 2)',
            []
        )

    # Business KPI Methods
    def record_query_success_rate(self, tier: str, query_type: str, success_rate: float):
        """Record query success rate (0.0-100.0)"""
        if self.export_to_prometheus:
            self.query_success_rate.labels(tier=tier, query_type=query_type).set(success_rate)
        else:
            self.metrics_history.append(BusinessMetricPoint(
                category=MetricCategory.BUSINESS_KPI,
                name="query_success_rate",
                value=success_rate,
                timestamp=datetime.now(),
                tags={'tier': tier, 'query_type': query_type},
                description=f"Query success rate for {tier}/{query_type}"
            ))

    def record_query_latency(self, tier: str, query_type: str, latency_ms: float):
        """Record query latency in milliseconds"""
        if self.export_to_prometheus:
            self.avg_query_latency_ms.labels(tier=tier, query_type=query_type).observe(latency_ms)

    # User Experience Methods
    def record_perceived_latency(self, endpoint: str, latency_ms: float):
        """Record end-to-end perceived latency"""
        if self.export_to_prometheus:
            self.perceived_latency_ms.labels(endpoint=endpoint).observe(latency_ms)
        else:
            self.metrics_history.append(BusinessMetricPoint(
                category=MetricCategory.USER_EXPERIENCE,
                name="perceived_latency",
                value=latency_ms,
                timestamp=datetime.now(),
                tags={'endpoint': endpoint},
                description=f"Perceived latency for {endpoint}"
            ))

    def record_user_satisfaction(self, endpoint: str, score: float):
        """Record user satisfaction score (0-100)"""
        if self.export_to_prometheus:
            self.user_satisfaction_score.labels(endpoint=endpoint).set(score)

    # Cost Tracking Methods
    def record_compute_cost(self, tier: str, cost_usd: float):
        """Record incremental compute cost"""
        if self.export_to_prometheus:
            self.compute_cost_usd.labels(tier=tier).inc(cost_usd)
        else:
            self.metrics_history.append(BusinessMetricPoint(
                category=MetricCategory.COST,
                name="compute_cost",
                value=cost_usd,
                timestamp=datetime.now(),
                tags={'tier': tier},
                description=f"Compute cost for {tier}"
            ))

    def record_storage_cost(self, tier: str, cost_usd: float):
        """Record incremental storage cost"""
        if self.export_to_prometheus:
            self.storage_cost_usd.labels(tier=tier).inc(cost_usd)

    def record_api_call_cost(self, service: str, cost_usd: float):
        """Record API call cost (e.g., Athena query cost)"""
        if self.export_to_prometheus:
            self.api_call_cost_usd.labels(service=service).inc(cost_usd)

    # SLO/SLA Methods
    def record_slo_compliance(self, slo_name: str, compliance_percent: float):
        """Record SLO compliance percentage (0.0-100.0)"""
        if self.export_to_prometheus:
            self.slo_compliance_percent.labels(slo_name=slo_name).set(compliance_percent)
        else:
            self.metrics_history.append(BusinessMetricPoint(
                category=MetricCategory.SLO_SLA,
                name="slo_compliance",
                value=compliance_percent,
                timestamp=datetime.now(),
                tags={'slo_name': slo_name},
                description=f"SLO compliance for {slo_name}"
            ))

    def record_sla_violation(self, sla_name: str):
        """Record an SLA violation"""
        if self.export_to_prometheus:
            self.sla_violations_total.labels(sla_name=sla_name).inc()

    # Resource Efficiency Methods
    def record_queries_per_dollar(self, tier: str, queries_per_dollar: float):
        """Record query efficiency metric"""
        if self.export_to_prometheus:
            self.queries_per_dollar.labels(tier=tier).set(queries_per_dollar)
        else:
            self.metrics_history.append(BusinessMetricPoint(
                category=MetricCategory.EFFICIENCY,
                name="queries_per_dollar",
                value=queries_per_dollar,
                timestamp=datetime.now(),
                tags={'tier': tier},
                description=f"Queries per dollar for {tier}"
            ))

    def record_cache_hit_rate(self, cache_type: str, hit_rate_percent: float):
        """Record cache hit rate (0.0-100.0)"""
        if self.export_to_prometheus:
            self.cache_hit_rate_percent.labels(cache_type=cache_type).set(hit_rate_percent)

    def record_tier_routing_efficiency(self, efficiency_percent: float):
        """Record percentage of queries routed to optimal tier"""
        if self.export_to_prometheus:
            self.tier_routing_efficiency.set(efficiency_percent)
        else:
            self.metrics_history.append(BusinessMetricPoint(
                category=MetricCategory.EFFICIENCY,
                name="tier_routing_efficiency",
                value=efficiency_percent,
                timestamp=datetime.now(),
                tags={},
                description="Overall tier routing efficiency"
            ))

    # Wave 2 Specific Methods
    def record_rust_speedup(self, speedup_factor: float):
        """Record Rust speedup factor vs Python baseline"""
        if self.export_to_prometheus:
            self.rust_speedup_factor.set(speedup_factor)

    def record_ml_routing_accuracy(self, accuracy_percent: float):
        """Record ML routing prediction accuracy"""
        if self.export_to_prometheus:
            self.ml_routing_accuracy.set(accuracy_percent)

    # Utility Methods
    def get_metrics_summary(self) -> Dict[str, Any]:
        """Get summary of all collected metrics (for non-Prometheus mode)"""
        if self.export_to_prometheus:
            return {
                'mode': 'prometheus',
                'prometheus_available': True,
                'message': 'Metrics exported to Prometheus'
            }

        # Group by category
        summary = {cat.value: [] for cat in MetricCategory}

        for metric in self.metrics_history:
            summary[metric.category.value].append(asdict(metric))

        return summary


# Predefined SLOs for Wave 2
WAVE2_SLOS = {
    'rust_query_latency_p95': {
        'name': 'Rust Query Latency P95',
        'target_ms': 60,
        'description': 'P95 query latency <60ms'
    },
    'rust_query_latency_p99': {
        'name': 'Rust Query Latency P99',
        'target_ms': 100,
        'description': 'P99 query latency <100ms'
    },
    'tier_routing_accuracy': {
        'name': 'Tier Routing Accuracy',
        'target_percent': 60,
        'description': 'At least 60% queries to optimal tier'
    },
    'ml_routing_inference': {
        'name': 'ML Routing Inference Time',
        'target_ms': 1,
        'description': 'ML inference <1ms'
    },
    'overall_availability': {
        'name': 'Overall Availability',
        'target_percent': 99.9,
        'description': '99.9% uptime (3 nines)'
    },
    'error_rate': {
        'name': 'Error Rate',
        'target_percent': 0.1,
        'description': 'Error rate <0.1%'
    }
}

# Cost Model for Wave 2
class CostModel:
    """Simplified cost model for Wave 2 infrastructure"""

    # Cost per million queries (estimated)
    COST_PER_MILLION_QUERIES = {
        'master': 10.00,   # PostgreSQL compute
        'pgvector': 12.00,  # PostgreSQL + vector ops
        'minio': 2.00,      # Object storage (cheap)
        'athena': 5.00      # Serverless SQL (per query)
    }

    # Cost per GB storage per month
    COST_PER_GB_MONTH = {
        'master': 0.10,     # PostgreSQL
        'pgvector': 0.10,   # Same as master
        'minio': 0.02,      # Object storage (very cheap)
        'athena': 0.02      # S3-based (very cheap)
    }

    @staticmethod
    def calculate_query_cost(tier: str, query_count: int) -> float:
        """Calculate cost for N queries on a tier"""
        cost_per_million = CostModel.COST_PER_MILLION_QUERIES.get(tier, 0)
        return (query_count / 1_000_000) * cost_per_million

    @staticmethod
    def calculate_storage_cost(tier: str, gb_stored: float, days: int = 30) -> float:
        """Calculate storage cost for GB*days"""
        cost_per_gb_month = CostModel.COST_PER_GB_MONTH.get(tier, 0)
        months = days / 30.0
        return gb_stored * cost_per_gb_month * months


# Example usage
if __name__ == "__main__":
    # Initialize collector
    collector = CustomMetricsCollector(export_to_prometheus=False)

    # Record business KPIs
    collector.record_query_success_rate('master', 'drug_resolution', 99.5)
    collector.record_query_latency('master', 'drug_resolution', 45.0)

    # Record user experience
    collector.record_perceived_latency('/api/v2/drug/resolve', 120.0)
    collector.record_user_satisfaction('/api/v2/drug/resolve', 95.0)

    # Record costs
    collector.record_compute_cost('master', 5.50)
    collector.record_api_call_cost('athena', 0.025)

    # Record SLO compliance
    collector.record_slo_compliance('rust_query_latency_p95', 98.5)

    # Record efficiency
    collector.record_queries_per_dollar('master', 100000)
    collector.record_tier_routing_efficiency(60.0)

    # Wave 2 specific
    collector.record_rust_speedup(10.0)
    collector.record_ml_routing_accuracy(75.0)

    # Get summary
    summary = collector.get_metrics_summary()
    print("Custom Metrics Summary:")
    for category, metrics in summary.items():
        if isinstance(metrics, list) and len(metrics) > 0:
            print(f"\n{category.upper()}:")
            for metric in metrics:
                print(f"  - {metric['name']}: {metric['value']}")
