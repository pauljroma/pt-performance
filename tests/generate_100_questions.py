#!/usr/bin/env python3
"""
Generate complete 100-question test suite for Wave 2
Creates all 5 categories with proper question distribution
"""

import json
from pathlib import Path

def generate_tier_routing_questions():
    """Generate 25 tier routing questions (TR-001 to TR-025)"""
    # Already created in the JSON file
    return []  # Will be read from existing file

def generate_ml_routing_questions():
    """Generate 25 ML routing & adaptive questions (ML-001 to ML-025)"""
    questions = []

    # ML-001: Basic ML prediction
    questions.append({
        "id": "ML-001",
        "category": "ml_routing_adaptive",
        "question": "ML router predicts optimal tier for complex query pattern",
        "query_params": {
            "days_back": 15,
            "estimated_rows": 25000,
            "query_complexity": 5.5,
            "has_aggregation": True
        },
        "expected_results": {
            "ml_prediction_used": True,
            "confidence_above_threshold": True,
            "inference_time_ms": {"max": 50.0},
            "rationale": "ML model should predict tier based on learned patterns"
        },
        "pass_criteria": "ML prediction used AND inference_time < 50ms AND confidence > 0.7"
    })

    # ML-002: Fallback to static routing
    questions.append({
        "id": "ML-002",
        "category": "ml_routing_adaptive",
        "question": "ML router falls back to static routing when confidence low",
        "query_params": {
            "days_back": 15,
            "estimated_rows": 1000,
            "unusual_pattern": True
        },
        "expected_results": {
            "ml_prediction_attempted": True,
            "ml_fallback_to_static": True,
            "static_tier_selected": "minio",
            "rationale": "Low confidence ML predictions should fallback to static routing rules"
        },
        "pass_criteria": "ml_fallback == True AND tier selected by static rules"
    })

    # ML-003: Feature extraction accuracy
    questions.append({
        "id": "ML-003",
        "category": "ml_routing_adaptive",
        "question": "Extract features correctly from query parameters",
        "query_params": {
            "days_back": 45,
            "estimated_rows": 10000,
            "query_complexity": 7.0,
            "has_embeddings": False,
            "has_aggregation": True,
            "table_count": 3
        },
        "expected_results": {
            "features_extracted": 10,
            "all_features_valid": True,
            "no_nan_values": True,
            "rationale": "Feature extraction must handle all parameter types correctly"
        },
        "pass_criteria": "10 features extracted AND no NaN AND all numeric"
    })

    # ML-004: Model training with synthetic data
    questions.append({
        "id": "ML-004",
        "category": "ml_routing_adaptive",
        "question": "Train ML model with 1000 synthetic query examples",
        "query_params": {
            "training_samples": 1000,
            "balanced_classes": True
        },
        "expected_results": {
            "model_trained": True,
            "training_accuracy": {"min": 0.75},
            "model_file_saved": True,
            "rationale": "Model should train successfully with balanced synthetic data"
        },
        "pass_criteria": "model.is_trained == True AND accuracy >= 0.75"
    })

    # ML-005: Confidence threshold boundary
    questions.append({
        "id": "ML-005",
        "category": "ml_routing_adaptive",
        "question": "Handle prediction with confidence exactly at threshold (0.7)",
        "query_params": {
            "days_back": 20,
            "force_confidence": 0.7
        },
        "expected_results": {
            "ml_prediction_used": True,
            "confidence": 0.7,
            "threshold": 0.7,
            "rationale": "Confidence == threshold should use ML prediction (not fallback)"
        },
        "pass_criteria": "ml_prediction_used == True (boundary condition: >= threshold)"
    })

    # ML-006 to ML-010: Pattern analyzer tests
    for i in range(6, 11):
        questions.append({
            "id": f"ML-{i:03d}",
            "category": "ml_routing_adaptive",
            "question": f"Pattern analyzer test {i}: query pattern classification",
            "query_params": {
                "days_back": i * 10,
                "result_size": i * 1000,
                "latency_ms": i * 5.0
            },
            "expected_results": {
                "pattern_classified": True,
                "pattern_type": "frequent" if i % 2 == 0 else "complex",
                "rationale": f"Classify query pattern based on parameters (test {i})"
            },
            "pass_criteria": "pattern_type is not None AND classification_confidence > 0.6"
        })

    # ML-011 to ML-015: Adaptive threshold tests
    for i in range(11, 16):
        load_pct = 50 + (i - 11) * 10  # 50%, 60%, 70%, 80%, 90%
        questions.append({
            "id": f"ML-{i:03d}",
            "category": "ml_routing_adaptive",
            "question": f"Adaptive threshold adjusts under {load_pct}% load",
            "query_params": {
                "current_load": load_pct,
                "latency_p95": 50.0,
                "routing_accuracy": 0.85
            },
            "expected_results": {
                "threshold_adjusted": True if load_pct > 70 else False,
                "adjustment_direction": "increase" if load_pct > 70 else "none",
                "rationale": f"Thresholds should adjust dynamically at {load_pct}% load"
            },
            "pass_criteria": "threshold adjustment matches expected for load level"
        })

    # ML-016 to ML-020: A/B testing framework
    for i in range(16, 21):
        questions.append({
            "id": f"ML-{i:03d}",
            "category": "ml_routing_adaptive",
            "question": f"A/B test variant assignment (test {i})",
            "query_params": {
                "user_id": f"user_{i}",
                "test_id": "ml_vs_static_routing"
            },
            "expected_results": {
                "variant_assigned": True,
                "variant": "control" if i % 2 == 0 else "treatment",
                "assignment_consistent": True,
                "rationale": f"Consistent variant assignment based on hash(user_id)"
            },
            "pass_criteria": "same user_id always gets same variant"
        })

    # ML-021: Statistical significance test
    questions.append({
        "id": "ML-021",
        "category": "ml_routing_adaptive",
        "question": "A/B test statistical significance with 1000 samples",
        "query_params": {
            "control_samples": 500,
            "treatment_samples": 500,
            "treatment_improvement": 0.15
        },
        "expected_results": {
            "p_value": {"max": 0.05},
            "statistically_significant": True,
            "confidence_level": 0.95,
            "rationale": "15% improvement with 1000 samples should be statistically significant"
        },
        "pass_criteria": "p_value < 0.05 AND significant == True"
    })

    # ML-022: Model persistence (save/load)
    questions.append({
        "id": "ML-022",
        "category": "ml_routing_adaptive",
        "question": "Save and load ML model (persistence round-trip)",
        "query_params": {
            "train_model": True,
            "save_path": "/tmp/ml_tier_model_test.pkl"
        },
        "expected_results": {
            "model_saved": True,
            "model_loaded": True,
            "predictions_match": True,
            "rationale": "Saved and loaded model should make identical predictions"
        },
        "pass_criteria": "model loaded successfully AND predictions match pre-save"
    })

    # ML-023: Batch prediction performance
    questions.append({
        "id": "ML-023",
        "category": "ml_routing_adaptive",
        "question": "Batch predict 100 queries efficiently",
        "query_params": {
            "batch_size": 100,
            "parallel": True
        },
        "expected_results": {
            "all_predictions_returned": True,
            "total_time_ms": {"max": 500.0},
            "avg_time_per_query_ms": {"max": 5.0},
            "rationale": "Batch prediction should be ~10x faster than serial"
        },
        "pass_criteria": "total_time < 500ms (5ms per query average)"
    })

    # ML-024: Feature importance validation
    questions.append({
        "id": "ML-024",
        "category": "ml_routing_adaptive",
        "question": "Get feature importance from trained model",
        "query_params": {
            "trained_model": True
        },
        "expected_results": {
            "feature_count": 10,
            "importance_sum": 1.0,
            "top_feature": "days_back",
            "rationale": "days_back should be most important feature for tier selection"
        },
        "pass_criteria": "10 features AND sum(importance) ≈ 1.0 AND days_back rank == 1"
    })

    # ML-025: Query pattern export for training
    questions.append({
        "id": "ML-025",
        "category": "ml_routing_adaptive",
        "question": "Export query patterns as ML training data",
        "query_params": {
            "pattern_count": 100
        },
        "expected_results": {
            "training_samples_exported": 100,
            "features_per_sample": 10,
            "labels_included": True,
            "rationale": "Pattern analyzer should export data in ML-ready format"
        },
        "pass_criteria": "100 samples exported AND all have features + labels"
    })

    return questions

def generate_health_monitoring_questions():
    """Generate 20 health monitoring & failover questions (HM-001 to HM-020)"""
    questions = []

    # HM-001: Single tier health check
    questions.append({
        "id": "HM-001",
        "category": "health_monitoring_failover",
        "question": "Health check detects healthy tier (Master)",
        "query_params": {
            "tier": "master",
            "latency_ms": 5.0
        },
        "expected_results": {
            "tier_status": "healthy",
            "tier_available": True,
            "latency_within_threshold": True,
            "rationale": "Tier with <100ms latency should be marked healthy"
        },
        "pass_criteria": "status == 'healthy' AND available == True"
    })

    # HM-002: Degraded tier detection
    questions.append({
        "id": "HM-002",
        "category": "health_monitoring_failover",
        "question": "Health check detects degraded tier (high latency)",
        "query_params": {
            "tier": "minio",
            "latency_ms": 300.0
        },
        "expected_results": {
            "tier_status": "degraded",
            "tier_available": True,
            "latency_exceeded_healthy_threshold": True,
            "rationale": "Latency 100-500ms should mark tier as degraded but available"
        },
        "pass_criteria": "status == 'degraded' AND available == True"
    })

    # HM-003: Unavailable tier detection
    questions.append({
        "id": "HM-003",
        "category": "health_monitoring_failover",
        "question": "Health check detects unavailable tier (connection failed)",
        "query_params": {
            "tier": "athena",
            "connection_error": True
        },
        "expected_results": {
            "tier_status": "unavailable",
            "tier_available": False,
            "error_recorded": True,
            "rationale": "Connection failures should mark tier as unavailable"
        },
        "pass_criteria": "status == 'unavailable' AND available == False"
    })

    # HM-004 to HM-008: Failover chain tests
    failover_scenarios = [
        ("HM-004", "minio", "master", "MinIO fails, fallback to Master"),
        ("HM-005", "athena", "minio", "Athena fails, fallback to MinIO"),
        ("HM-006", "athena", "master", "Athena + MinIO fail, fallback to Master"),
        ("HM-007", "pgvector", "master", "PGVector fails, fallback to Master"),
        ("HM-008", "all_tiers", "master", "All tiers fail, ultimate fallback to Master")
    ]

    for qid, failed_tier, fallback_tier, description in failover_scenarios:
        questions.append({
            "id": qid,
            "category": "health_monitoring_failover",
            "question": description,
            "query_params": {
                "preferred_tier": failed_tier,
                "tier_available": False
            },
            "expected_results": {
                "tier_selected": fallback_tier,
                "failover_occurred": True,
                "failover_time_ms": {"max": 10.0},
                "rationale": f"When {failed_tier} unavailable, should failover to {fallback_tier}"
            },
            "pass_criteria": f"tier == '{fallback_tier}' AND failover_time < 10ms"
        })

    # HM-009: Circuit breaker activation
    questions.append({
        "id": "HM-009",
        "category": "health_monitoring_failover",
        "question": "Circuit breaker opens after 3 consecutive failures",
        "query_params": {
            "tier": "minio",
            "consecutive_failures": 3
        },
        "expected_results": {
            "circuit_breaker_open": True,
            "tier_excluded": True,
            "max_consecutive_failures": 3,
            "rationale": "Circuit breaker should open after max_consecutive_failures threshold"
        },
        "pass_criteria": "circuit_breaker_open == True AND tier excluded from routing"
    })

    # HM-010: Circuit breaker recovery
    questions.append({
        "id": "HM-010",
        "category": "health_monitoring_failover",
        "question": "Circuit breaker closes after tier recovers",
        "query_params": {
            "tier": "minio",
            "previous_failures": 3,
            "health_check_passed": True
        },
        "expected_results": {
            "circuit_breaker_closed": True,
            "tier_included": True,
            "consecutive_failures_reset": True,
            "rationale": "Successful health check should reset circuit breaker"
        },
        "pass_criteria": "circuit_breaker_closed == True AND consecutive_failures == 0"
    })

    # HM-011 to HM-015: Concurrent health checks
    for i in range(11, 16):
        questions.append({
            "id": f"HM-{i:03d}",
            "category": "health_monitoring_failover",
            "question": f"Concurrent health checks for all tiers (test {i})",
            "query_params": {
                "check_all_tiers": True,
                "parallel": True
            },
            "expected_results": {
                "all_tiers_checked": True,
                "total_check_time_ms": {"max": 200.0},
                "no_race_conditions": True,
                "rationale": "Parallel health checks should complete faster than serial"
            },
            "pass_criteria": "all 4 tiers checked AND total_time < 200ms"
        })

    # HM-016: Background monitoring thread lifecycle
    questions.append({
        "id": "HM-016",
        "category": "health_monitoring_failover",
        "question": "Start and stop background health monitoring thread",
        "query_params": {
            "start_monitoring": True,
            "check_interval_seconds": 5
        },
        "expected_results": {
            "thread_started": True,
            "thread_is_daemon": True,
            "checks_running": True,
            "thread_stopped_cleanly": True,
            "rationale": "Background monitoring thread should start/stop without hanging"
        },
        "pass_criteria": "thread started AND stopped without timeout"
    })

    # HM-017: Health history tracking
    questions.append({
        "id": "HM-017",
        "category": "health_monitoring_failover",
        "question": "Track health history for last 100 checks",
        "query_params": {
            "run_checks": 150,
            "history_size": 100
        },
        "expected_results": {
            "history_entries": 100,
            "oldest_entry_dropped": True,
            "deque_maxlen": 100,
            "rationale": "Health history should maintain fixed size with FIFO eviction"
        },
        "pass_criteria": "history_size == 100 (oldest entries evicted)"
    })

    # HM-018: Get available tiers for routing
    questions.append({
        "id": "HM-018",
        "category": "health_monitoring_failover",
        "question": "Get list of available tiers from health monitor",
        "query_params": {
            "tier_health": {
                "master": "healthy",
                "pgvector": "healthy",
                "minio": "degraded",
                "athena": "unavailable"
            }
        },
        "expected_results": {
            "available_tiers": ["master", "pgvector", "minio"],
            "unavailable_count": 1,
            "rationale": "Degraded tiers are still available, only unavailable excluded"
        },
        "pass_criteria": "available_tiers == ['master', 'pgvector', 'minio']"
    })

    # HM-019: Get best available tier from preference list
    questions.append({
        "id": "HM-019",
        "category": "health_monitoring_failover",
        "question": "Select best available tier from preference list",
        "query_params": {
            "preference_list": ["athena", "minio", "master"],
            "tier_health": {
                "athena": "unavailable",
                "minio": "healthy",
                "master": "healthy"
            }
        },
        "expected_results": {
            "best_tier": "minio",
            "rationale": "First available tier in preference list should be selected"
        },
        "pass_criteria": "best_tier == 'minio' (athena unavailable, skip to minio)"
    })

    # HM-020: Health check timeout handling
    questions.append({
        "id": "HM-020",
        "category": "health_monitoring_failover",
        "question": "Handle health check timeout (tier unresponsive)",
        "query_params": {
            "tier": "athena",
            "check_timeout_seconds": 5,
            "tier_response_time": 10
        },
        "expected_results": {
            "timeout_occurred": True,
            "tier_status": "unavailable",
            "error_type": "timeout",
            "rationale": "Timeouts should mark tier as unavailable"
        },
        "pass_criteria": "status == 'unavailable' AND error contains 'timeout'"
    })

    return questions

def generate_integration_production_questions():
    """Generate 20 integration & production questions (IP-001 to IP-020)"""
    questions = []

    # IP-001 to IP-005: End-to-end query flows
    for i in range(1, 6):
        days = i * 20  # 20, 40, 60, 80, 100 days
        questions.append({
            "id": f"IP-{i:03d}",
            "category": "integration_production",
            "question": f"End-to-end query flow: {days} days historical data",
            "query_params": {
                "days_back": days,
                "estimated_rows": i * 10000
            },
            "expected_results": {
                "query_routed": True,
                "tier_selected_correctly": True,
                "result_returned": True,
                "total_latency_ms": {"max": 100.0},
                "rationale": f"Full query flow for {days}-day data should complete successfully"
            },
            "pass_criteria": "query successful AND total_latency < 100ms"
        })

    # IP-006 to IP-010: Deployment phase validation
    phases = [
        ("IP-006", "canary", 5, "5% canary deployment"),
        ("IP-007", "ramp_25", 25, "25% traffic ramp"),
        ("IP-008", "ramp_50", 50, "50% traffic ramp"),
        ("IP-009", "full", 100, "100% full production"),
        ("IP-010", "rollback", 0, "Emergency rollback to 0%")
    ]

    for qid, phase, traffic_pct, description in phases:
        questions.append({
            "id": qid,
            "category": "integration_production",
            "question": description,
            "query_params": {
                "deployment_phase": phase,
                "traffic_percentage": traffic_pct
            },
            "expected_results": {
                "phase_active": True,
                "traffic_split_correct": True,
                "wave2_queries": traffic_pct,
                "wave1_queries": 100 - traffic_pct,
                "rationale": f"Traffic should split {traffic_pct}% to Wave 2, {100-traffic_pct}% to Wave 1"
            },
            "pass_criteria": f"wave2_traffic == {traffic_pct}% AND wave1_traffic == {100-traffic_pct}%"
        })

    # IP-011: Rollback procedure validation
    questions.append({
        "id": "IP-011",
        "category": "integration_production",
        "question": "Validate <5 minute rollback time",
        "query_params": {
            "trigger_rollback": True,
            "disable_wave2": True
        },
        "expected_results": {
            "rollback_time_seconds": {"max": 300},
            "wave2_disabled": True,
            "wave1_active": True,
            "no_query_failures": True,
            "rationale": "Emergency rollback should complete in <5 minutes"
        },
        "pass_criteria": "rollback_time < 300s AND no failed queries"
    })

    # IP-012: Capacity planning validation
    questions.append({
        "id": "IP-012",
        "category": "integration_production",
        "question": "Validate capacity for 2x traffic spike",
        "query_params": {
            "baseline_qps": 1700,
            "spike_multiplier": 2.0
        },
        "expected_results": {
            "max_qps": 3400,
            "latency_degradation": {"max": 1.5},
            "no_connection_errors": True,
            "rationale": "System should handle 2x traffic with <50% latency increase"
        },
        "pass_criteria": "handles 3400 qps AND latency_increase < 50%"
    })

    # IP-013: Configuration hot-reload
    questions.append({
        "id": "IP-013",
        "category": "integration_production",
        "question": "Hot-reload tier router configuration without restart",
        "query_params": {
            "modify_config": {"master_days": 10},
            "reload_config": True
        },
        "expected_results": {
            "config_reloaded": True,
            "no_service_downtime": True,
            "new_config_active": True,
            "rationale": "Config changes should apply without service restart"
        },
        "pass_criteria": "config updated AND zero downtime"
    })

    # IP-014: Performance SLA validation
    questions.append({
        "id": "IP-014",
        "category": "integration_production",
        "question": "Validate all Wave 2 performance SLAs met",
        "query_params": {
            "run_performance_validation": True,
            "sample_size": 10000
        },
        "expected_results": {
            "rust_latency_p95": {"max": 0.055},
            "routing_overhead_avg": {"max": 0.005},
            "throughput_qps": {"min": 1650},
            "routing_percentage": {"min": 55},
            "rationale": "All Wave 2 SLAs must be met in production"
        },
        "pass_criteria": "all SLAs met (latency, throughput, routing %)"
    })

    # IP-015 to IP-018: Error recovery scenarios
    error_scenarios = [
        ("IP-015", "database_timeout", "Database connection timeout recovery"),
        ("IP-016", "cache_corruption", "Cache corruption detection and recovery"),
        ("IP-017", "config_invalid", "Invalid configuration error handling"),
        ("IP-018", "memory_pressure", "High memory pressure graceful degradation")
    ]

    for qid, error_type, description in error_scenarios:
        questions.append({
            "id": qid,
            "category": "integration_production",
            "question": description,
            "query_params": {
                "inject_error": error_type
            },
            "expected_results": {
                "error_detected": True,
                "recovery_successful": True,
                "no_data_loss": True,
                "fallback_activated": True,
                "rationale": f"{description} should recover gracefully"
            },
            "pass_criteria": "error recovered AND service continues"
        })

    # IP-019: Multi-tier query scenario
    questions.append({
        "id": "IP-019",
        "category": "integration_production",
        "question": "Execute query spanning multiple tiers (federation)",
        "query_params": {
            "query_type": "federated",
            "tiers_involved": ["master", "minio", "athena"]
        },
        "expected_results": {
            "all_tiers_queried": True,
            "results_merged": True,
            "total_latency_ms": {"max": 500.0},
            "rationale": "Federated queries should aggregate results from multiple tiers"
        },
        "pass_criteria": "results from all 3 tiers AND total_latency < 500ms"
    })

    # IP-020: Production monitoring integration
    questions.append({
        "id": "IP-020",
        "category": "integration_production",
        "question": "Verify metrics exported to monitoring system",
        "query_params": {
            "execute_queries": 100,
            "export_metrics": True
        },
        "expected_results": {
            "prometheus_metrics_exported": True,
            "grafana_dashboard_updated": True,
            "alert_rules_evaluated": True,
            "rationale": "All Wave 2 metrics should integrate with monitoring stack"
        },
        "pass_criteria": "metrics exported AND dashboards updated AND alerts working"
    })

    return questions

def generate_edge_case_questions():
    """Generate 10 edge case & error handling questions (EC-001 to EC-010)"""
    questions = []

    # EC-001: Division by zero prevention
    questions.append({
        "id": "EC-001",
        "category": "edge_cases_error_handling",
        "question": "Get routing metrics with zero queries executed",
        "query_params": {
            "new_router": True,
            "query_count": 0
        },
        "expected_results": {
            "no_division_by_zero": True,
            "metrics_returned": True,
            "total_queries": 0,
            "routing_percentage": 0.0,
            "rationale": "Zero queries should not cause division by zero errors"
        },
        "pass_criteria": "no exceptions AND routing_percentage == 0.0"
    })

    # EC-002: NaN/Infinity in feature values
    questions.append({
        "id": "EC-002",
        "category": "edge_cases_error_handling",
        "question": "Handle NaN/Infinity in ML feature extraction",
        "query_params": {
            "days_back": float('inf'),
            "estimated_rows": float('nan')
        },
        "expected_results": {
            "invalid_values_detected": True,
            "values_sanitized": True,
            "fallback_to_defaults": True,
            "rationale": "NaN/Infinity should be sanitized to valid defaults"
        },
        "pass_criteria": "no NaN/Inf in final features AND prediction succeeds"
    })

    # EC-003: Missing dependencies (sklearn)
    questions.append({
        "id": "EC-003",
        "category": "edge_cases_error_handling",
        "question": "Graceful degradation when sklearn not installed",
        "query_params": {
            "ml_routing_requested": True,
            "sklearn_available": False
        },
        "expected_results": {
            "ml_disabled": True,
            "fallback_to_static": True,
            "warning_logged": True,
            "rationale": "Missing sklearn should fallback to static routing with warning"
        },
        "pass_criteria": "static routing used AND warning in logs"
    })

    # EC-004: Missing dependencies (boto3)
    questions.append({
        "id": "EC-004",
        "category": "edge_cases_error_handling",
        "question": "Graceful degradation when boto3 not installed (Athena unavailable)",
        "query_params": {
            "preferred_tier": "athena",
            "boto3_available": False
        },
        "expected_results": {
            "athena_disabled": True,
            "fallback_to_minio": True,
            "warning_logged": True,
            "rationale": "Missing boto3 should disable Athena tier with fallback"
        },
        "pass_criteria": "athena unavailable AND fallback triggered"
    })

    # EC-005: Empty query params dict
    questions.append({
        "id": "EC-005",
        "category": "edge_cases_error_handling",
        "question": "Handle completely empty query_params dict",
        "query_params": {},
        "expected_results": {
            "defaults_applied": True,
            "tier_selected": "master",
            "no_exceptions": True,
            "rationale": "Empty params should apply sensible defaults"
        },
        "pass_criteria": "tier == 'master' AND no errors"
    })

    # EC-006: Null/None values in query params
    questions.append({
        "id": "EC-006",
        "category": "edge_cases_error_handling",
        "question": "Handle None values in query parameters",
        "query_params": {
            "days_back": None,
            "estimated_rows": None,
            "table": None
        },
        "expected_results": {
            "none_values_handled": True,
            "defaults_substituted": True,
            "tier_selected": "master",
            "rationale": "None values should be replaced with defaults"
        },
        "pass_criteria": "no AttributeError AND tier selected"
    })

    # EC-007: Extremely large estimated_rows
    questions.append({
        "id": "EC-007",
        "category": "edge_cases_error_handling",
        "question": "Handle extremely large estimated_rows (1 billion+)",
        "query_params": {
            "days_back": 365,
            "estimated_rows": 1_000_000_000
        },
        "expected_results": {
            "large_value_handled": True,
            "tier": "athena",
            "no_overflow": True,
            "rationale": "Billion-row queries should route to Athena without overflow"
        },
        "pass_criteria": "tier == 'athena' AND no numeric overflow"
    })

    # EC-008: Concurrent modifications to stats
    questions.append({
        "id": "EC-008",
        "category": "edge_cases_error_handling",
        "question": "Thread-safe stats updates with concurrent queries",
        "query_params": {
            "concurrent_queries": 100,
            "threads": 10
        },
        "expected_results": {
            "all_queries_completed": True,
            "stats_accurate": True,
            "no_race_conditions": True,
            "total_queries": 100,
            "rationale": "Concurrent stats updates must be thread-safe"
        },
        "pass_criteria": "total_queries == 100 AND tier_counts sum to 100"
    })

    # EC-009: Invalid tier name in config
    questions.append({
        "id": "EC-009",
        "category": "edge_cases_error_handling",
        "question": "Handle invalid tier name in configuration",
        "query_params": {
            "preferred_tier": "invalid_tier_xyz"
        },
        "expected_results": {
            "invalid_tier_detected": True,
            "fallback_to_master": True,
            "error_logged": True,
            "rationale": "Invalid tier names should fallback gracefully"
        },
        "pass_criteria": "tier == 'master' (fallback) AND error logged"
    })

    # EC-010: Database connection failure
    questions.append({
        "id": "EC-010",
        "category": "edge_cases_error_handling",
        "question": "Handle pattern analyzer database connection failure",
        "query_params": {
            "record_pattern": True,
            "database_available": False
        },
        "expected_results": {
            "connection_error_handled": True,
            "query_continues": True,
            "pattern_not_recorded": True,
            "rationale": "Pattern recording failure should not block query execution"
        },
        "pass_criteria": "query succeeds despite pattern recording failure"
    })

    return questions

def main():
    """Generate complete 100-question test suite"""
    print("Generating Wave 2 100-Question Test Suite...")

    # Read existing tier routing questions
    existing_file = Path(__file__).parent / "100_QUESTION_TEST_SUITE_WAVE2_v1.0.json"
    with open(existing_file, 'r') as f:
        data = json.load(f)

    existing_questions = data["questions"]
    print(f"✓ Read {len(existing_questions)} existing tier routing questions")

    # Generate remaining categories
    ml_questions = generate_ml_routing_questions()
    print(f"✓ Generated {len(ml_questions)} ML routing questions")

    hm_questions = generate_health_monitoring_questions()
    print(f"✓ Generated {len(hm_questions)} health monitoring questions")

    ip_questions = generate_integration_production_questions()
    print(f"✓ Generated {len(ip_questions)} integration/production questions")

    ec_questions = generate_edge_case_questions()
    print(f"✓ Generated {len(ec_questions)} edge case questions")

    # Combine all questions
    all_questions = existing_questions + ml_questions + hm_questions + ip_questions + ec_questions

    # Update data structure
    data["questions"] = all_questions

    print(f"\n✓ Total questions: {len(all_questions)}")
    print(f"  - Tier Routing: {len(existing_questions)}")
    print(f"  - ML Routing & Adaptive: {len(ml_questions)}")
    print(f"  - Health Monitoring & Failover: {len(hm_questions)}")
    print(f"  - Integration & Production: {len(ip_questions)}")
    print(f"  - Edge Cases & Error Handling: {len(ec_questions)}")

    # Write complete file
    with open(existing_file, 'w') as f:
        json.dump(data, f, indent=2)

    print(f"\n✓ Wrote complete test suite to: {existing_file}")
    print("\nNext steps:")
    print("1. Run: python tests/question_executor_wave2.py (after creating it)")
    print("2. Run: pytest tests/test_100_questions_wave2.py -v")
    print("3. Generate reports: python tests/batch_generate_wave2_reports.py")

if __name__ == "__main__":
    main()
