# Wave 2 Production Performance Report

**Version:** 1.0
**Date:** 2025-12-06
**Owner:** Agent 12 - Production Deployment Engineer
**Status:** Validation Framework Ready

---

## Executive Summary

This report provides comprehensive performance validation procedures for Wave 2 optimizations in production, comparing real-world performance against Wave 1 and Wave 2 baseline benchmarks. The validation framework ensures Wave 2 meets or exceeds all performance targets under actual production workload conditions.

### Performance Targets (Wave 2 Baseline)

| Metric | Wave 1 Baseline | Wave 2 Target | Production Validation |
|--------|-----------------|---------------|----------------------|
| **Latency P95** | 0.082ms | 0.052ms (37% faster) | ≤ 0.055ms (allows margin) |
| **Latency P99** | 0.089ms | 0.055ms (38% faster) | ≤ 0.060ms (allows margin) |
| **Throughput** | 850 qps | 1,700 qps (2x) | ≥ 1,650 qps (sustained) |
| **Routing %** | 42% | 60% (+43%) | ≥ 55% (real workload) |
| **Routing Overhead** | 0.42ms | 0.0018ms (233x faster) | ≤ 0.005ms (allows margin) |

---

## Table of Contents

1. [Performance Validation Framework](#performance-validation-framework)
2. [Real-World Latency Analysis](#real-world-latency-analysis)
3. [Real-World Throughput Analysis](#real-world-throughput-analysis)
4. [Tier Distribution Analysis](#tier-distribution-analysis)
5. [Resource Utilization Analysis](#resource-utilization-analysis)
6. [Comparison Analysis](#comparison-analysis)
7. [Production Metrics Collection](#production-metrics-collection)

---

## Performance Validation Framework

### Validation Methodology

**Three-Phase Validation Approach:**

1. **Synthetic Benchmarks:** Controlled load tests matching Wave 2 baseline conditions
2. **Production Shadow Testing:** Run Wave 2 alongside Wave 1 on same traffic
3. **Full Production Validation:** Measure performance under real workload

### Validation Tools

#### 1. Production Performance Collector

```python
#!/usr/bin/env python3
"""
Collect production performance metrics for Wave 2 validation.
Runs continuously and exports metrics to Prometheus.
"""

import time
import requests
from prometheus_client import Gauge, Histogram, Counter, start_http_server

class Wave2ProductionMonitor:
    """Monitor Wave 2 performance in production."""

    def __init__(self):
        # Latency metrics
        self.latency_gauge = Gauge(
            'wave2_latency_ms',
            'Query latency in milliseconds',
            ['percentile', 'component']
        )

        self.latency_histogram = Histogram(
            'wave2_query_duration_seconds',
            'Query duration histogram',
            buckets=[0.00001, 0.00005, 0.0001, 0.0005, 0.001, 0.005, 0.01]
        )

        # Throughput metrics
        self.throughput_gauge = Gauge(
            'wave2_throughput_qps',
            'Queries per second',
            ['window']
        )

        self.query_counter = Counter(
            'wave2_queries_total',
            'Total queries processed',
            ['tier', 'status']
        )

        # Routing metrics
        self.routing_gauge = Gauge(
            'wave2_routing_percentage',
            'Percentage of queries routed to non-master tiers'
        )

        self.tier_distribution_gauge = Gauge(
            'wave2_tier_distribution_pct',
            'Percentage distribution by tier',
            ['tier']
        )

        # Resource metrics
        self.resource_gauge = Gauge(
            'wave2_resource_usage',
            'Resource utilization',
            ['resource', 'component']
        )

    def collect_metrics(self, window_seconds=60):
        """Collect metrics over a time window."""

        start_time = time.time()
        latencies = []
        tier_counts = {
            'master': 0,
            'pgvector': 0,
            'minio': 0,
            'athena': 0
        }

        # Collect from application metrics endpoint
        metrics_url = "http://localhost:9090/metrics"

        while time.time() - start_time < window_seconds:
            response = requests.get(metrics_url)
            metrics = self._parse_prometheus_metrics(response.text)

            # Record latency
            if 'rust_query_duration_seconds' in metrics:
                latency_ms = metrics['rust_query_duration_seconds'] * 1000
                latencies.append(latency_ms)
                self.latency_histogram.observe(latency_ms / 1000)

            # Record tier routing
            for tier in tier_counts:
                tier_counts[tier] = metrics.get(f'tier_{tier}_queries_total', 0)

            time.sleep(0.1)  # 100ms sampling rate

        # Calculate percentiles
        if latencies:
            latencies.sort()
            p50 = latencies[len(latencies) // 2]
            p95 = latencies[int(len(latencies) * 0.95)]
            p99 = latencies[int(len(latencies) * 0.99)]
            p99_9 = latencies[int(len(latencies) * 0.999)]

            self.latency_gauge.labels(percentile='p50', component='rust').set(p50)
            self.latency_gauge.labels(percentile='p95', component='rust').set(p95)
            self.latency_gauge.labels(percentile='p99', component='rust').set(p99)
            self.latency_gauge.labels(percentile='p99_9', component='rust').set(p99_9)

        # Calculate throughput
        total_queries = sum(tier_counts.values())
        qps = total_queries / window_seconds
        self.throughput_gauge.labels(window=f'{window_seconds}s').set(qps)

        # Calculate routing percentage
        non_master_queries = sum(v for k, v in tier_counts.items() if k != 'master')
        routing_pct = (non_master_queries / total_queries * 100) if total_queries > 0 else 0
        self.routing_gauge.set(routing_pct)

        # Record tier distribution
        for tier, count in tier_counts.items():
            pct = (count / total_queries * 100) if total_queries > 0 else 0
            self.tier_distribution_gauge.labels(tier=tier).set(pct)

        return {
            'latency': {'p50': p50, 'p95': p95, 'p99': p99, 'p99_9': p99_9},
            'throughput_qps': qps,
            'routing_percentage': routing_pct,
            'tier_distribution': {
                tier: (count / total_queries * 100) if total_queries > 0 else 0
                for tier, count in tier_counts.items()
            }
        }

    def _parse_prometheus_metrics(self, text):
        """Parse Prometheus text format metrics."""
        metrics = {}
        for line in text.split('\n'):
            if line and not line.startswith('#'):
                parts = line.split()
                if len(parts) >= 2:
                    metrics[parts[0]] = float(parts[1])
        return metrics


if __name__ == "__main__":
    monitor = Wave2ProductionMonitor()
    start_http_server(8001)  # Expose metrics on :8001

    print("Wave 2 Production Monitor started on :8001")
    print("Collecting metrics every 60 seconds...")

    while True:
        results = monitor.collect_metrics(window_seconds=60)
        print(f"\n[{time.strftime('%Y-%m-%d %H:%M:%S')}]")
        print(f"Latency P95: {results['latency']['p95']:.4f}ms")
        print(f"Throughput: {results['throughput_qps']:.0f} qps")
        print(f"Routing: {results['routing_percentage']:.1f}%")
```

#### 2. Production Baseline Comparator

```python
#!/usr/bin/env python3
"""
Compare production performance to Wave 1 and Wave 2 baselines.
"""

import json
import requests
from typing import Dict, Any

class BaselineComparator:
    """Compare production metrics to baselines."""

    def __init__(self, wave1_baseline_file: str, wave2_baseline_file: str):
        with open(wave1_baseline_file) as f:
            self.wave1_baseline = json.load(f)

        with open(wave2_baseline_file) as f:
            self.wave2_baseline = json.load(f)

    def collect_production_metrics(self) -> Dict[str, Any]:
        """Collect current production metrics."""

        response = requests.get("http://localhost:9090/api/v1/query", params={
            'query': 'rust_latency_p95_ms'
        })
        latency_p95 = response.json()['data']['result'][0]['value'][1]

        response = requests.get("http://localhost:9090/api/v1/query", params={
            'query': 'rate(rust_queries_total[1m])'
        })
        throughput = response.json()['data']['result'][0]['value'][1]

        response = requests.get("http://localhost:9090/api/v1/query", params={
            'query': 'tier_routing_percentage'
        })
        routing_pct = response.json()['data']['result'][0]['value'][1]

        return {
            'latency_p95_ms': float(latency_p95),
            'throughput_qps': float(throughput),
            'routing_percentage': float(routing_pct)
        }

    def compare(self) -> Dict[str, Any]:
        """Compare production to baselines."""

        prod = self.collect_production_metrics()
        wave1 = self.wave1_baseline
        wave2 = self.wave2_baseline

        # Calculate improvements
        latency_improvement_vs_wave1 = (
            (wave1['latency_p95_ms'] - prod['latency_p95_ms']) /
            wave1['latency_p95_ms'] * 100
        )

        throughput_improvement_vs_wave1 = (
            (prod['throughput_qps'] - wave1['throughput_qps']) /
            wave1['throughput_qps'] * 100
        )

        routing_improvement_vs_wave1 = (
            prod['routing_percentage'] - wave1['routing_percentage']
        )

        # Check if meets Wave 2 targets
        meets_latency_target = prod['latency_p95_ms'] <= wave2['latency_p95_ms'] * 1.05
        meets_throughput_target = prod['throughput_qps'] >= wave2['throughput_qps'] * 0.95
        meets_routing_target = prod['routing_percentage'] >= wave2['routing_percentage'] * 0.90

        return {
            'production': prod,
            'wave1_baseline': wave1,
            'wave2_baseline': wave2,
            'vs_wave1': {
                'latency_improvement_pct': latency_improvement_vs_wave1,
                'throughput_improvement_pct': throughput_improvement_vs_wave1,
                'routing_improvement_pct': routing_improvement_vs_wave1
            },
            'meets_wave2_targets': {
                'latency': meets_latency_target,
                'throughput': meets_throughput_target,
                'routing': meets_routing_target,
                'overall': all([meets_latency_target, meets_throughput_target, meets_routing_target])
            }
        }

    def print_report(self):
        """Print comparison report."""

        results = self.compare()

        print("=" * 70)
        print("WAVE 2 PRODUCTION PERFORMANCE COMPARISON")
        print("=" * 70)

        print("\n📊 CURRENT PRODUCTION METRICS")
        print(f"  Latency P95:   {results['production']['latency_p95_ms']:.4f}ms")
        print(f"  Throughput:    {results['production']['throughput_qps']:.0f} qps")
        print(f"  Routing:       {results['production']['routing_percentage']:.1f}%")

        print("\n📈 IMPROVEMENT VS WAVE 1 BASELINE")
        print(f"  Latency:       {results['vs_wave1']['latency_improvement_pct']:+.1f}% faster")
        print(f"  Throughput:    {results['vs_wave1']['throughput_improvement_pct']:+.1f}% higher")
        print(f"  Routing:       {results['vs_wave1']['routing_improvement_pct']:+.1f}% more")

        print("\n🎯 WAVE 2 TARGET VALIDATION")
        status = results['meets_wave2_targets']
        print(f"  Latency:       {'✅' if status['latency'] else '❌'} {status['latency']}")
        print(f"  Throughput:    {'✅' if status['throughput'] else '❌'} {status['throughput']}")
        print(f"  Routing:       {'✅' if status['routing'] else '❌'} {status['routing']}")
        print(f"  Overall:       {'✅ PASS' if status['overall'] else '❌ FAIL'}")

        print("=" * 70)

        return results['meets_wave2_targets']['overall']


if __name__ == "__main__":
    comparator = BaselineComparator(
        wave1_baseline_file='.outcomes/wave1_benchmark_results.json',
        wave2_baseline_file='.outcomes/wave2_benchmark_results.json'
    )

    success = comparator.print_report()
    exit(0 if success else 1)
```

---

## Real-World Latency Analysis

### Latency Measurement Procedures

#### 1. Continuous Latency Monitoring

**Metrics Collection Points:**

```python
# At application layer
@app.before_request
def before_request():
    g.start_time = time.perf_counter()

@app.after_request
def after_request(response):
    if hasattr(g, 'start_time'):
        latency_ms = (time.perf_counter() - g.start_time) * 1000
        LATENCY_HISTOGRAM.observe(latency_ms / 1000)
        LATENCY_SUMMARY.observe(latency_ms / 1000)
    return response
```

**Query-Level Instrumentation:**

```rust
// In Rust DatabaseReaderV2
pub async fn resolve_drug(&self, drug_id: &str) -> Result<Drug> {
    let start = std::time::Instant::now();

    let result = self._resolve_drug_internal(drug_id).await;

    let latency_ms = start.elapsed().as_secs_f64() * 1000.0;
    QUERY_LATENCY_HISTOGRAM
        .with_label_values(&["resolve_drug", "rust_v2"])
        .observe(latency_ms / 1000.0);

    result
}
```

#### 2. Production Latency Benchmarks

**Benchmark Script:**

```bash
#!/bin/bash
# production_latency_benchmark.sh
# Measure production latency over 1 hour

echo "Starting production latency benchmark..."
echo "Duration: 3600 seconds (1 hour)"
echo "Sampling: Every 1 second"

RESULTS_FILE="wave2_prod_latency_$(date +%Y%m%d_%H%M%S).json"

python3 <<EOF
import json
import time
import requests

results = {
    'start_time': time.time(),
    'samples': []
}

for i in range(3600):
    # Query Prometheus for current latency percentiles
    response = requests.get('http://localhost:9090/api/v1/query', params={
        'query': 'histogram_quantile(0.95, rate(rust_query_duration_seconds_bucket[1m]))'
    })
    p95 = float(response.json()['data']['result'][0]['value'][1]) * 1000

    response = requests.get('http://localhost:9090/api/v1/query', params={
        'query': 'histogram_quantile(0.99, rate(rust_query_duration_seconds_bucket[1m]))'
    })
    p99 = float(response.json()['data']['result'][0]['value'][1]) * 1000

    sample = {
        'timestamp': time.time(),
        'p95_ms': p95,
        'p99_ms': p99
    }

    results['samples'].append(sample)

    if i % 60 == 0:
        avg_p95 = sum(s['p95_ms'] for s in results['samples']) / len(results['samples'])
        print(f"[{i//60}min] Avg P95: {avg_p95:.4f}ms")

    time.sleep(1)

# Calculate statistics
p95_values = [s['p95_ms'] for s in results['samples']]
p99_values = [s['p99_ms'] for s in results['samples']]

results['summary'] = {
    'p95_min': min(p95_values),
    'p95_max': max(p95_values),
    'p95_avg': sum(p95_values) / len(p95_values),
    'p95_median': sorted(p95_values)[len(p95_values)//2],
    'p99_min': min(p99_values),
    'p99_max': max(p99_values),
    'p99_avg': sum(p99_values) / len(p99_values),
    'p99_median': sorted(p99_values)[len(p99_values)//2]
}

with open('$RESULTS_FILE', 'w') as f:
    json.dump(results, f, indent=2)

print("\n" + "="*60)
print("PRODUCTION LATENCY BENCHMARK COMPLETE")
print("="*60)
print(f"P95 - Min: {results['summary']['p95_min']:.4f}ms, "
      f"Max: {results['summary']['p95_max']:.4f}ms, "
      f"Avg: {results['summary']['p95_avg']:.4f}ms")
print(f"P99 - Min: {results['summary']['p99_min']:.4f}ms, "
      f"Max: {results['summary']['p99_max']:.4f}ms, "
      f"Avg: {results['summary']['p99_avg']:.4f}ms")
print(f"\nResults saved to: $RESULTS_FILE")
EOF
```

### Expected Production Latency Distribution

**Wave 2 Target Distribution (Under Real Load):**

```
Percentile Distribution:
┌─────────────┬──────────┬───────────┬──────────┐
│ Percentile  │ Target   │ Max Allow │ Alert At │
├─────────────┼──────────┼───────────┼──────────┤
│ P50         │ 0.050ms  │ 0.053ms   │ 0.060ms  │
│ P75         │ 0.051ms  │ 0.054ms   │ 0.062ms  │
│ P90         │ 0.051ms  │ 0.055ms   │ 0.063ms  │
│ P95         │ 0.052ms  │ 0.055ms   │ 0.065ms  │
│ P99         │ 0.055ms  │ 0.060ms   │ 0.070ms  │
│ P99.9       │ 0.058ms  │ 0.065ms   │ 0.080ms  │
└─────────────┴──────────┴───────────┴──────────┘

Note: Max Allow includes 5-10% margin for production variability
```

### Latency Regression Detection

```python
#!/usr/bin/env python3
"""
Detect latency regressions in production.
"""

import numpy as np
from scipy import stats

class LatencyRegressionDetector:
    """Detect statistically significant latency regressions."""

    def __init__(self, baseline_p95=0.052, baseline_p99=0.055):
        self.baseline_p95 = baseline_p95
        self.baseline_p99 = baseline_p99

    def detect_regression(self, production_samples: list, confidence=0.95):
        """
        Detect if production latency is significantly worse than baseline.

        Args:
            production_samples: List of P95 latency values (ms)
            confidence: Confidence level for statistical test

        Returns:
            dict with regression status and statistics
        """

        # Calculate statistics
        mean = np.mean(production_samples)
        std = np.std(production_samples)
        n = len(production_samples)

        # One-sample t-test: Is production mean > baseline?
        t_statistic, p_value = stats.ttest_1samp(
            production_samples,
            self.baseline_p95,
            alternative='greater'
        )

        # Regression detected if p-value < (1 - confidence)
        regression_detected = p_value < (1 - confidence)

        # Calculate effect size (Cohen's d)
        cohens_d = (mean - self.baseline_p95) / std if std > 0 else 0

        return {
            'regression_detected': regression_detected,
            'p_value': p_value,
            'production_mean': mean,
            'production_std': std,
            'baseline': self.baseline_p95,
            'difference_ms': mean - self.baseline_p95,
            'difference_pct': ((mean - self.baseline_p95) / self.baseline_p95) * 100,
            'cohens_d': cohens_d,
            'severity': self._classify_severity(cohens_d),
            'recommendation': self._get_recommendation(regression_detected, cohens_d)
        }

    def _classify_severity(self, cohens_d):
        """Classify regression severity based on effect size."""
        if abs(cohens_d) < 0.2:
            return "negligible"
        elif abs(cohens_d) < 0.5:
            return "small"
        elif abs(cohens_d) < 0.8:
            return "medium"
        else:
            return "large"

    def _get_recommendation(self, regression_detected, cohens_d):
        """Get recommendation based on regression analysis."""
        if not regression_detected:
            return "No action needed - performance within baseline"

        if abs(cohens_d) < 0.5:
            return "Monitor - small regression detected, continue observing"
        elif abs(cohens_d) < 0.8:
            return "Investigate - medium regression, review recent changes"
        else:
            return "URGENT - large regression, consider rollback"


if __name__ == "__main__":
    # Example usage
    import json

    # Load production samples
    with open('wave2_prod_latency_20251206_120000.json') as f:
        data = json.load(f)

    samples = [s['p95_ms'] for s in data['samples']]

    detector = LatencyRegressionDetector(baseline_p95=0.052)
    result = detector.detect_regression(samples)

    print("LATENCY REGRESSION ANALYSIS")
    print("="*60)
    print(f"Regression Detected: {result['regression_detected']}")
    print(f"Production Mean:     {result['production_mean']:.4f}ms")
    print(f"Baseline:            {result['baseline']:.4f}ms")
    print(f"Difference:          {result['difference_ms']:+.4f}ms ({result['difference_pct']:+.1f}%)")
    print(f"Statistical Power:   p={result['p_value']:.4f}")
    print(f"Effect Size:         {result['cohens_d']:.2f} ({result['severity']})")
    print(f"\nRecommendation: {result['recommendation']}")
```

---

## Real-World Throughput Analysis

### Throughput Measurement Procedures

#### 1. Sustained Throughput Benchmark

```bash
#!/bin/bash
# sustained_throughput_benchmark.sh
# Measure sustained throughput over 24 hours

echo "Starting 24-hour sustained throughput benchmark..."

RESULTS_FILE="wave2_prod_throughput_$(date +%Y%m%d).json"

python3 <<EOF
import json
import time
import requests

results = {
    'start_time': time.time(),
    'duration_hours': 24,
    'samples': []
}

# Collect throughput every 5 minutes for 24 hours
for i in range(288):  # 24 hours * 12 samples/hour
    # Query total queries in last 5 minutes
    response = requests.get('http://localhost:9090/api/v1/query', params={
        'query': 'rate(rust_queries_total[5m])'
    })

    qps = float(response.json()['data']['result'][0]['value'][1])

    # Query by tier
    tier_qps = {}
    for tier in ['master', 'pgvector', 'minio', 'athena']:
        response = requests.get('http://localhost:9090/api/v1/query', params={
            'query': f'rate(tier_{tier}_queries_total[5m])'
        })
        tier_qps[tier] = float(response.json()['data']['result'][0]['value'][1])

    sample = {
        'timestamp': time.time(),
        'total_qps': qps,
        'tier_qps': tier_qps
    }

    results['samples'].append(sample)

    if i % 12 == 0:  # Every hour
        hour = i // 12
        recent = results['samples'][-12:]
        avg_qps = sum(s['total_qps'] for s in recent) / len(recent)
        print(f"[Hour {hour}] Avg QPS: {avg_qps:.0f}")

    time.sleep(300)  # 5 minutes

# Calculate 24-hour statistics
all_qps = [s['total_qps'] for s in results['samples']]

results['summary'] = {
    'min_qps': min(all_qps),
    'max_qps': max(all_qps),
    'avg_qps': sum(all_qps) / len(all_qps),
    'median_qps': sorted(all_qps)[len(all_qps)//2],
    'p95_qps': sorted(all_qps)[int(len(all_qps)*0.95)],
    'p5_qps': sorted(all_qps)[int(len(all_qps)*0.05)],
    'meets_target': sum(all_qps) / len(all_qps) >= 1650
}

with open('$RESULTS_FILE', 'w') as f:
    json.dump(results, f, indent=2)

print("\n" + "="*60)
print("24-HOUR SUSTAINED THROUGHPUT BENCHMARK COMPLETE")
print("="*60)
print(f"Average QPS:    {results['summary']['avg_qps']:.0f}")
print(f"Min QPS:        {results['summary']['min_qps']:.0f}")
print(f"Max QPS:        {results['summary']['max_qps']:.0f}")
print(f"Median QPS:     {results['summary']['median_qps']:.0f}")
print(f"Target (1650):  {'✅ MET' if results['summary']['meets_target'] else '❌ MISSED'}")
EOF
```

#### 2. Peak Load Handling

**Test peak traffic handling (2x baseline):**

```python
#!/usr/bin/env python3
"""
Test Wave 2 handling of peak load (2x normal traffic).
"""

import asyncio
import aiohttp
import time
import statistics

async def send_query(session, url, query_id):
    """Send a single query and measure latency."""
    start = time.perf_counter()
    try:
        async with session.get(url) as response:
            await response.text()
            latency_ms = (time.perf_counter() - start) * 1000
            return {'success': True, 'latency_ms': latency_ms}
    except Exception as e:
        latency_ms = (time.perf_counter() - start) * 1000
        return {'success': False, 'latency_ms': latency_ms, 'error': str(e)}

async def peak_load_test(target_qps=3400, duration_seconds=3600):
    """
    Test peak load at 2x baseline (1700 * 2 = 3400 qps).

    Args:
        target_qps: Target queries per second
        duration_seconds: Test duration
    """

    url = "http://localhost:8000/api/drugs/CHEMBL113"
    interval = 1.0 / target_qps  # Time between queries

    results = []
    start_time = time.time()

    async with aiohttp.ClientSession() as session:
        query_id = 0

        while time.time() - start_time < duration_seconds:
            # Send burst of queries
            tasks = []
            batch_start = time.time()

            # Send queries at target rate
            while time.time() - batch_start < 1.0:
                task = send_query(session, url, query_id)
                tasks.append(task)
                query_id += 1
                await asyncio.sleep(interval)

            # Wait for batch to complete
            batch_results = await asyncio.gather(*tasks)
            results.extend(batch_results)

            # Log progress every minute
            if query_id % (target_qps * 60) == 0:
                elapsed = time.time() - start_time
                success_count = sum(1 for r in results if r['success'])
                success_rate = success_count / len(results) * 100
                latencies = [r['latency_ms'] for r in results if r['success']]
                p95 = sorted(latencies)[int(len(latencies) * 0.95)] if latencies else 0

                print(f"[{int(elapsed/60)}min] "
                      f"Queries: {len(results)}, "
                      f"Success: {success_rate:.1f}%, "
                      f"P95: {p95:.2f}ms")

    # Final statistics
    success_results = [r for r in results if r['success']]
    latencies = [r['latency_ms'] for r in success_results]

    return {
        'duration_seconds': duration_seconds,
        'target_qps': target_qps,
        'total_queries': len(results),
        'successful_queries': len(success_results),
        'success_rate': len(success_results) / len(results) * 100,
        'actual_qps': len(results) / duration_seconds,
        'latency': {
            'min': min(latencies),
            'max': max(latencies),
            'mean': statistics.mean(latencies),
            'median': statistics.median(latencies),
            'p95': sorted(latencies)[int(len(latencies) * 0.95)],
            'p99': sorted(latencies)[int(len(latencies) * 0.99)]
        }
    }


if __name__ == "__main__":
    print("Starting peak load test (2x baseline)...")
    print("Target: 3,400 qps for 1 hour")

    results = asyncio.run(peak_load_test(target_qps=3400, duration_seconds=3600))

    print("\n" + "="*60)
    print("PEAK LOAD TEST RESULTS")
    print("="*60)
    print(f"Target QPS:        {results['target_qps']}")
    print(f"Actual QPS:        {results['actual_qps']:.0f}")
    print(f"Success Rate:      {results['success_rate']:.1f}%")
    print(f"Latency P95:       {results['latency']['p95']:.2f}ms")
    print(f"Latency P99:       {results['latency']['p99']:.2f}ms")

    # Validate against targets
    print("\n🎯 TARGET VALIDATION")
    print(f"  Success Rate > 99%:    {'✅' if results['success_rate'] > 99 else '❌'}")
    print(f"  P95 < 0.070ms:         {'✅' if results['latency']['p95'] < 0.070 else '❌'}")
    print(f"  Actual QPS ≥ Target:   {'✅' if results['actual_qps'] >= results['target_qps'] else '❌'}")
```

---

## Tier Distribution Analysis

### Production Tier Distribution Monitoring

```python
#!/usr/bin/env python3
"""
Monitor and analyze tier distribution in production.
"""

import time
import requests
from collections import defaultdict

class TierDistributionAnalyzer:
    """Analyze query distribution across tiers."""

    def __init__(self):
        self.tier_counters = defaultdict(int)

    def collect_distribution(self, duration_seconds=3600):
        """Collect tier distribution over time window."""

        start_time = time.time()
        samples = []

        while time.time() - start_time < duration_seconds:
            # Query current tier counts
            tier_counts = {}
            for tier in ['master', 'pgvector', 'minio', 'athena']:
                response = requests.get('http://localhost:9090/api/v1/query', params={
                    'query': f'tier_{tier}_queries_total'
                })
                count = int(float(response.json()['data']['result'][0]['value'][1]))
                tier_counts[tier] = count

            samples.append({
                'timestamp': time.time(),
                'tier_counts': tier_counts.copy()
            })

            time.sleep(60)  # Sample every minute

        # Calculate distribution
        total_queries = sum(samples[-1]['tier_counts'].values())
        distribution = {
            tier: (count / total_queries * 100) if total_queries > 0 else 0
            for tier, count in samples[-1]['tier_counts'].items()
        }

        # Calculate routing percentage (non-master)
        non_master = sum(v for k, v in samples[-1]['tier_counts'].items() if k != 'master')
        routing_pct = (non_master / total_queries * 100) if total_queries > 0 else 0

        return {
            'total_queries': total_queries,
            'tier_distribution_pct': distribution,
            'routing_percentage': routing_pct,
            'samples': samples
        }

    def validate_distribution(self, distribution):
        """Validate tier distribution meets targets."""

        targets = {
            'master': (35, 45),      # 35-45%
            'pgvector': (15, 25),    # 15-25%
            'minio': (15, 25),       # 15-25%
            'athena': (15, 25)       # 15-25%
        }

        validation = {}
        for tier, (min_pct, max_pct) in targets.items():
            actual = distribution['tier_distribution_pct'][tier]
            in_range = min_pct <= actual <= max_pct
            validation[tier] = {
                'actual_pct': actual,
                'target_range': (min_pct, max_pct),
                'in_range': in_range
            }

        # Overall routing percentage
        validation['routing'] = {
            'actual_pct': distribution['routing_percentage'],
            'target_min': 55.0,
            'meets_target': distribution['routing_percentage'] >= 55.0
        }

        return validation

    def print_report(self, distribution, validation):
        """Print distribution analysis report."""

        print("="*70)
        print("TIER DISTRIBUTION ANALYSIS")
        print("="*70)

        print(f"\nTotal Queries: {distribution['total_queries']:,}")
        print(f"Routing Percentage: {distribution['routing_percentage']:.1f}% "
              f"({'✅' if validation['routing']['meets_target'] else '❌'} target: ≥55%)")

        print("\nTier Distribution:")
        for tier in ['master', 'pgvector', 'minio', 'athena']:
            v = validation[tier]
            status = '✅' if v['in_range'] else '❌'
            print(f"  {tier:12} {v['actual_pct']:5.1f}%  "
                  f"{status} (target: {v['target_range'][0]}-{v['target_range'][1]}%)")

        print("="*70)


if __name__ == "__main__":
    analyzer = TierDistributionAnalyzer()

    print("Collecting tier distribution for 1 hour...")
    distribution = analyzer.collect_distribution(duration_seconds=3600)

    validation = analyzer.validate_distribution(distribution)
    analyzer.print_report(distribution, validation)
```

---

## Resource Utilization Analysis

### Production Resource Monitoring

```yaml
# Key resource metrics to monitor

cpu_utilization:
  metric: container_cpu_usage_seconds_total
  target: < 75%
  alert: > 85%
  calculation: rate(container_cpu_usage_seconds_total[5m])

memory_utilization:
  metric: container_memory_usage_bytes
  target: < 80%
  alert: > 90%
  calculation: container_memory_usage_bytes / container_spec_memory_limit_bytes

connection_pool:
  active_connections:
    metric: rust_connection_pool_active
    target: 60-80 (at full load)
    alert: > 95

  pool_utilization:
    metric: rust_connection_pool_utilization
    target: 75-85%
    alert: > 90%

  pool_size:
    metric: rust_connection_pool_size
    expected_range: 10-100
    should_scale: true

database_connections:
  postgres_connections:
    metric: pg_stat_activity_count
    per_tier:
      master: < 100
      pgvector: < 50

network_io:
  bytes_sent:
    metric: container_network_transmit_bytes_total
    monitor: rate over 5m

  bytes_received:
    metric: container_network_receive_bytes_total
    monitor: rate over 5m
```

### Resource Capacity Testing

```python
#!/usr/bin/env python3
"""
Test resource utilization under various load levels.
"""

import subprocess
import time
import requests

def get_resource_metrics():
    """Get current resource utilization."""

    # CPU
    cpu_response = requests.get('http://localhost:9090/api/v1/query', params={
        'query': 'rate(container_cpu_usage_seconds_total{container="pt-app"}[1m])'
    })
    cpu_pct = float(cpu_response.json()['data']['result'][0]['value'][1]) * 100

    # Memory
    mem_response = requests.get('http://localhost:9090/api/v1/query', params={
        'query': 'container_memory_usage_bytes{container="pt-app"} / container_spec_memory_limit_bytes{container="pt-app"}'
    })
    mem_pct = float(mem_response.json()['data']['result'][0]['value'][1]) * 100

    # Connection pool
    pool_response = requests.get('http://localhost:9090/api/v1/query', params={
        'query': 'rust_connection_pool_utilization'
    })
    pool_pct = float(pool_response.json()['data']['result'][0]['value'][1]) * 100

    pool_size_response = requests.get('http://localhost:9090/api/v1/query', params={
        'query': 'rust_connection_pool_size'
    })
    pool_size = int(float(pool_size_response.json()['data']['result'][0]['value'][1]))

    return {
        'cpu_pct': cpu_pct,
        'memory_pct': mem_pct,
        'pool_utilization_pct': pool_pct,
        'pool_size': pool_size
    }

def capacity_test_at_load(qps, duration_seconds=300):
    """Test resource utilization at specific QPS load."""

    print(f"\nTesting at {qps} QPS for {duration_seconds}s...")

    # Start load generator
    load_gen = subprocess.Popen([
        'python3', 'scripts/load_generator.py',
        '--qps', str(qps),
        '--duration', str(duration_seconds)
    ])

    # Wait for ramp-up
    time.sleep(30)

    # Collect samples
    samples = []
    for i in range(duration_seconds // 10):
        metrics = get_resource_metrics()
        samples.append(metrics)
        time.sleep(10)

    # Wait for load gen to complete
    load_gen.wait()

    # Calculate averages
    avg_metrics = {
        'qps': qps,
        'cpu_pct': sum(s['cpu_pct'] for s in samples) / len(samples),
        'memory_pct': sum(s['memory_pct'] for s in samples) / len(samples),
        'pool_utilization_pct': sum(s['pool_utilization_pct'] for s in samples) / len(samples),
        'pool_size_avg': sum(s['pool_size'] for s in samples) / len(samples),
        'pool_size_max': max(s['pool_size'] for s in samples)
    }

    return avg_metrics

def run_capacity_test_suite():
    """Run full capacity test suite."""

    load_levels = [
        ('Baseline', 1700),
        ('1.5x', 2550),
        ('2x Peak', 3400),
        ('3x Spike', 5100)
    ]

    results = []

    print("="*70)
    print("WAVE 2 CAPACITY TEST SUITE")
    print("="*70)

    for name, qps in load_levels:
        result = capacity_test_at_load(qps, duration_seconds=300)
        results.append((name, result))

        print(f"\n{name} ({qps} QPS):")
        print(f"  CPU:         {result['cpu_pct']:.1f}%")
        print(f"  Memory:      {result['memory_pct']:.1f}%")
        print(f"  Pool Util:   {result['pool_utilization_pct']:.1f}%")
        print(f"  Pool Size:   {result['pool_size_avg']:.0f} avg, {result['pool_size_max']} max")

    # Validate auto-scaling
    print("\n" + "="*70)
    print("AUTO-SCALING VALIDATION")
    print("="*70)

    baseline_pool = results[0][1]['pool_size_avg']
    peak_pool = results[2][1]['pool_size_max']

    print(f"Baseline load pool size: {baseline_pool:.0f}")
    print(f"Peak load pool size:     {peak_pool}")
    print(f"Scaling ratio:           {peak_pool/baseline_pool:.1f}x")
    print(f"Auto-scaling working:    {'✅ YES' if peak_pool > baseline_pool * 1.5 else '❌ NO'}")

    return results


if __name__ == "__main__":
    results = run_capacity_test_suite()
```

---

## Comparison Analysis

### Wave 1 vs Wave 2 Production Comparison

```python
#!/usr/bin/env python3
"""
Comprehensive comparison of Wave 1 vs Wave 2 in production.
"""

import json

class Wave1VsWave2Comparator:
    """Compare Wave 1 and Wave 2 production performance."""

    def __init__(self):
        self.metrics = [
            'latency_p50_ms',
            'latency_p95_ms',
            'latency_p99_ms',
            'throughput_qps',
            'routing_percentage',
            'cpu_utilization_pct',
            'memory_utilization_pct'
        ]

    def load_data(self, wave1_file, wave2_file):
        """Load Wave 1 and Wave 2 production data."""

        with open(wave1_file) as f:
            self.wave1_data = json.load(f)

        with open(wave2_file) as f:
            self.wave2_data = json.load(f)

    def calculate_improvements(self):
        """Calculate improvement percentages."""

        improvements = {}

        for metric in self.metrics:
            wave1_value = self.wave1_data.get(metric, 0)
            wave2_value = self.wave2_data.get(metric, 0)

            # For latency and utilization, lower is better
            if 'latency' in metric or 'utilization' in metric:
                improvement_pct = ((wave1_value - wave2_value) / wave1_value) * 100
            else:
                # For throughput and routing, higher is better
                improvement_pct = ((wave2_value - wave1_value) / wave1_value) * 100

            improvements[metric] = {
                'wave1': wave1_value,
                'wave2': wave2_value,
                'improvement_pct': improvement_pct,
                'improvement_direction': 'better' if improvement_pct > 0 else 'worse'
            }

        return improvements

    def generate_report(self):
        """Generate comprehensive comparison report."""

        improvements = self.calculate_improvements()

        report = []
        report.append("="*80)
        report.append("WAVE 1 vs WAVE 2 PRODUCTION COMPARISON REPORT")
        report.append("="*80)
        report.append("")

        # Latency section
        report.append("📊 LATENCY PERFORMANCE")
        report.append("-"*80)
        for metric in ['latency_p50_ms', 'latency_p95_ms', 'latency_p99_ms']:
            imp = improvements[metric]
            status = '✅' if imp['improvement_pct'] > 0 else '⚠️'
            report.append(f"  {metric:20} Wave1: {imp['wave1']:.4f}ms  →  "
                         f"Wave2: {imp['wave2']:.4f}ms  "
                         f"{status} {imp['improvement_pct']:+.1f}%")
        report.append("")

        # Throughput section
        report.append("🚀 THROUGHPUT PERFORMANCE")
        report.append("-"*80)
        imp = improvements['throughput_qps']
        status = '✅' if imp['improvement_pct'] > 0 else '⚠️'
        report.append(f"  Queries per second:  Wave1: {imp['wave1']:.0f} qps  →  "
                     f"Wave2: {imp['wave2']:.0f} qps  "
                     f"{status} {imp['improvement_pct']:+.1f}%")
        report.append("")

        # Routing section
        report.append("🎯 TIER ROUTING")
        report.append("-"*80)
        imp = improvements['routing_percentage']
        status = '✅' if imp['improvement_pct'] > 0 else '⚠️'
        report.append(f"  Routing percentage:  Wave1: {imp['wave1']:.1f}%  →  "
                     f"Wave2: {imp['wave2']:.1f}%  "
                     f"{status} {imp['improvement_pct']:+.1f}%")
        report.append("")

        # Resource utilization section
        report.append("💻 RESOURCE UTILIZATION")
        report.append("-"*80)
        for metric in ['cpu_utilization_pct', 'memory_utilization_pct']:
            imp = improvements[metric]
            status = '✅' if imp['improvement_pct'] > 0 else '⚠️'
            report.append(f"  {metric:25} Wave1: {imp['wave1']:.1f}%  →  "
                         f"Wave2: {imp['wave2']:.1f}%  "
                         f"{status} {imp['improvement_pct']:+.1f}%")
        report.append("")

        # Overall assessment
        report.append("="*80)
        report.append("OVERALL ASSESSMENT")
        report.append("="*80)

        positive_improvements = sum(1 for imp in improvements.values()
                                   if imp['improvement_pct'] > 5)
        total_metrics = len(improvements)

        report.append(f"Metrics improved: {positive_improvements}/{total_metrics}")
        report.append(f"Overall status: {'✅ WAVE 2 SUCCESSFUL' if positive_improvements >= total_metrics * 0.8 else '⚠️ NEEDS REVIEW'}")
        report.append("="*80)

        return '\n'.join(report)


if __name__ == "__main__":
    comparator = Wave1VsWave2Comparator()
    comparator.load_data(
        wave1_file='wave1_production_metrics.json',
        wave2_file='wave2_production_metrics.json'
    )

    report = comparator.generate_report()
    print(report)

    # Save report
    with open('.outcomes/wave1_vs_wave2_comparison.txt', 'w') as f:
        f.write(report)

    print("\nReport saved to: .outcomes/wave1_vs_wave2_comparison.txt")
```

---

## Production Metrics Collection

### Automated Metrics Export

```yaml
# prometheus_rules.yml
# Prometheus recording rules for Wave 2 metrics

groups:
  - name: wave2_performance
    interval: 60s
    rules:
      # Latency percentiles
      - record: wave2:latency:p50
        expr: histogram_quantile(0.50, rate(rust_query_duration_seconds_bucket[5m]))

      - record: wave2:latency:p95
        expr: histogram_quantile(0.95, rate(rust_query_duration_seconds_bucket[5m]))

      - record: wave2:latency:p99
        expr: histogram_quantile(0.99, rate(rust_query_duration_seconds_bucket[5m]))

      # Throughput
      - record: wave2:throughput:qps
        expr: rate(rust_queries_total[1m])

      # Routing percentage
      - record: wave2:routing:percentage
        expr: |
          (
            sum(rate(tier_pgvector_queries_total[5m])) +
            sum(rate(tier_minio_queries_total[5m])) +
            sum(rate(tier_athena_queries_total[5m]))
          ) /
          sum(rate(rust_queries_total[5m])) * 100

      # Tier distribution
      - record: wave2:tier:master_pct
        expr: rate(tier_master_queries_total[5m]) / rate(rust_queries_total[5m]) * 100

      - record: wave2:tier:pgvector_pct
        expr: rate(tier_pgvector_queries_total[5m]) / rate(rust_queries_total[5m]) * 100

      - record: wave2:tier:minio_pct
        expr: rate(tier_minio_queries_total[5m]) / rate(rust_queries_total[5m]) * 100

      - record: wave2:tier:athena_pct
        expr: rate(tier_athena_queries_total[5m]) / rate(rust_queries_total[5m]) * 100

      # Resource utilization
      - record: wave2:resource:cpu_pct
        expr: rate(container_cpu_usage_seconds_total{container="pt-app"}[5m]) * 100

      - record: wave2:resource:memory_pct
        expr: container_memory_usage_bytes{container="pt-app"} / container_spec_memory_limit_bytes{container="pt-app"} * 100

      - record: wave2:pool:utilization_pct
        expr: rust_connection_pool_active / rust_connection_pool_size * 100
```

### Daily Performance Report

```python
#!/usr/bin/env python3
"""
Generate daily Wave 2 performance report.
Run via cron: 0 0 * * * /path/to/daily_report.py
"""

import datetime
import requests
import json

def generate_daily_report():
    """Generate daily performance summary."""

    # Query yesterday's metrics
    end_time = datetime.datetime.now()
    start_time = end_time - datetime.timedelta(days=1)

    report = {
        'date': end_time.strftime('%Y-%m-%d'),
        'period': f"{start_time.strftime('%Y-%m-%d %H:%M')} - {end_time.strftime('%Y-%m-%d %H:%M')}"
    }

    # Collect metrics from Prometheus
    base_url = 'http://localhost:9090/api/v1/query'

    metrics_queries = {
        'latency_p95_avg': 'avg_over_time(wave2:latency:p95[24h])',
        'latency_p99_avg': 'avg_over_time(wave2:latency:p99[24h])',
        'throughput_avg': 'avg_over_time(wave2:throughput:qps[24h])',
        'routing_pct_avg': 'avg_over_time(wave2:routing:percentage[24h])',
        'cpu_pct_avg': 'avg_over_time(wave2:resource:cpu_pct[24h])',
        'memory_pct_avg': 'avg_over_time(wave2:resource:memory_pct[24h])'
    }

    for metric_name, query in metrics_queries.items():
        response = requests.get(base_url, params={'query': query})
        value = float(response.json()['data']['result'][0]['value'][1])
        report[metric_name] = value

    # Format and print report
    print("="*70)
    print(f"WAVE 2 DAILY PERFORMANCE REPORT - {report['date']}")
    print("="*70)
    print(f"\nPeriod: {report['period']}")
    print("\nPerformance Metrics (24-hour averages):")
    print(f"  Latency P95:       {report['latency_p95_avg']*1000:.4f}ms")
    print(f"  Latency P99:       {report['latency_p99_avg']*1000:.4f}ms")
    print(f"  Throughput:        {report['throughput_avg']:.0f} qps")
    print(f"  Routing:           {report['routing_pct_avg']:.1f}%")
    print(f"  CPU Utilization:   {report['cpu_pct_avg']:.1f}%")
    print(f"  Memory Utilization:{report['memory_pct_avg']:.1f}%")

    # Validation
    print("\nTarget Validation:")
    print(f"  Latency < 0.055ms:  {'✅' if report['latency_p95_avg']*1000 < 0.055 else '❌'}")
    print(f"  Throughput ≥ 1650:  {'✅' if report['throughput_avg'] >= 1650 else '❌'}")
    print(f"  Routing ≥ 55%:      {'✅' if report['routing_pct_avg'] >= 55 else '❌'}")
    print("="*70)

    # Save report
    filename = f".outcomes/daily_reports/wave2_report_{report['date']}.json"
    with open(filename, 'w') as f:
        json.dump(report, f, indent=2)

    return report


if __name__ == "__main__":
    report = generate_daily_report()
```

---

**Document Version:** 1.0
**Last Updated:** 2025-12-06
**Owner:** Agent 12 - Production Deployment Engineer
**Status:** Ready for Production Validation
