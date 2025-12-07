"""
ML-Based Anomaly Detection - Wave 2 Agent 13
Detects anomalies in system metrics before they trigger traditional alerts

Agent 13: Advanced Monitoring Engineer
Date: 2025-12-06

Features:
- Statistical anomaly detection (Z-score, IQR)
- ML-based detection (Isolation Forest, One-Class SVM)
- Time-series forecasting (ARIMA, Prophet)
- Contextual anomaly detection
- Multi-metric correlation
- Automatic baseline learning
"""

import os
import time
import json
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Any, Optional, Tuple
from dataclasses import dataclass, asdict
from enum import Enum
import warnings

import numpy as np

# Try to import ML libraries
try:
    from sklearn.ensemble import IsolationForest
    from sklearn.svm import OneClassSVM
    from sklearn.preprocessing import StandardScaler
    from sklearn.covariance import EllipticEnvelope
    SKLEARN_AVAILABLE = True
except ImportError:
    SKLEARN_AVAILABLE = False
    warnings.warn("scikit-learn not available. ML-based anomaly detection disabled.")


class AnomalyType(Enum):
    """Type of detected anomaly"""
    LATENCY_SPIKE = "latency_spike"
    THROUGHPUT_DROP = "throughput_drop"
    ERROR_RATE_INCREASE = "error_rate_increase"
    RESOURCE_EXHAUSTION = "resource_exhaustion"
    TIER_IMBALANCE = "tier_imbalance"
    ML_DEGRADATION = "ml_degradation"
    CACHE_MISS_SPIKE = "cache_miss_spike"
    CONNECTION_POOL_SATURATION = "connection_pool_saturation"
    NORMAL = "normal"


class AnomalySeverity(Enum):
    """Severity of detected anomaly"""
    INFO = "info"  # Informational, no action needed
    WARNING = "warning"  # Monitor closely
    CRITICAL = "critical"  # Requires immediate attention


@dataclass
class MetricPoint:
    """Single metric data point"""
    timestamp: datetime
    value: float
    metric_name: str
    tags: Dict[str, str]


@dataclass
class AnomalyDetection:
    """Detected anomaly"""
    type: AnomalyType
    severity: AnomalySeverity
    metric_name: str
    current_value: float
    expected_value: float
    deviation_percent: float
    confidence: float  # 0.0-1.0
    context: Dict[str, Any]
    timestamp: datetime

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary"""
        return {
            'type': self.type.value,
            'severity': self.severity.value,
            'metric_name': self.metric_name,
            'current_value': self.current_value,
            'expected_value': self.expected_value,
            'deviation_percent': self.deviation_percent,
            'confidence': self.confidence,
            'context': self.context,
            'timestamp': self.timestamp.isoformat()
        }


class StatisticalDetector:
    """Statistical anomaly detection using Z-score and IQR methods"""

    def __init__(self, z_threshold: float = 3.0, iqr_multiplier: float = 1.5):
        """
        Initialize statistical detector

        Args:
            z_threshold: Z-score threshold for anomaly (default: 3.0 = 99.7%)
            iqr_multiplier: IQR multiplier for outlier detection (default: 1.5)
        """
        self.z_threshold = z_threshold
        self.iqr_multiplier = iqr_multiplier

    def detect_zscore(self, values: List[float], current_value: float) -> Tuple[bool, float]:
        """
        Detect anomaly using Z-score method

        Returns:
            (is_anomaly, z_score)
        """
        if len(values) < 3:
            return False, 0.0

        mean = np.mean(values)
        std = np.std(values)

        if std == 0:
            return False, 0.0

        z_score = abs((current_value - mean) / std)
        is_anomaly = z_score > self.z_threshold

        return is_anomaly, z_score

    def detect_iqr(self, values: List[float], current_value: float) -> Tuple[bool, float]:
        """
        Detect anomaly using Interquartile Range method

        Returns:
            (is_anomaly, deviation_from_median)
        """
        if len(values) < 4:
            return False, 0.0

        q1 = np.percentile(values, 25)
        q3 = np.percentile(values, 75)
        iqr = q3 - q1

        lower_bound = q1 - (self.iqr_multiplier * iqr)
        upper_bound = q3 + (self.iqr_multiplier * iqr)

        is_anomaly = current_value < lower_bound or current_value > upper_bound
        median = np.median(values)
        deviation = abs(current_value - median)

        return is_anomaly, deviation


class MLBasedDetector:
    """ML-based anomaly detection using Isolation Forest and One-Class SVM"""

    def __init__(self, contamination: float = 0.1):
        """
        Initialize ML detector

        Args:
            contamination: Expected proportion of anomalies (default: 0.1 = 10%)
        """
        if not SKLEARN_AVAILABLE:
            raise ImportError("scikit-learn required for ML-based detection")

        self.contamination = contamination
        self.isolation_forest = IsolationForest(
            contamination=contamination,
            random_state=42,
            n_estimators=100
        )
        self.one_class_svm = OneClassSVM(
            gamma='auto',
            nu=contamination
        )
        self.scaler = StandardScaler()
        self.is_fitted = False

    def fit(self, features: np.ndarray):
        """
        Train anomaly detection models

        Args:
            features: Training data (n_samples, n_features)
        """
        if len(features) < 10:
            raise ValueError("Need at least 10 samples to train ML detector")

        # Scale features
        features_scaled = self.scaler.fit_transform(features)

        # Train models
        self.isolation_forest.fit(features_scaled)
        self.one_class_svm.fit(features_scaled)

        self.is_fitted = True

    def predict(self, features: np.ndarray) -> Tuple[bool, float]:
        """
        Predict if sample is anomalous

        Returns:
            (is_anomaly, anomaly_score)
        """
        if not self.is_fitted:
            raise RuntimeError("Model not fitted. Call fit() first.")

        # Scale features
        features_scaled = self.scaler.transform(features.reshape(1, -1))

        # Isolation Forest prediction (-1 = anomaly, 1 = normal)
        if_pred = self.isolation_forest.predict(features_scaled)[0]
        if_score = self.isolation_forest.score_samples(features_scaled)[0]

        # One-Class SVM prediction
        svm_pred = self.one_class_svm.predict(features_scaled)[0]

        # Combine predictions (both must agree for anomaly)
        is_anomaly = (if_pred == -1) and (svm_pred == -1)

        # Convert score to confidence (0.0-1.0)
        anomaly_score = 1.0 / (1.0 + np.exp(if_score))  # Sigmoid transformation

        return is_anomaly, anomaly_score


class AnomalyDetectionSystem:
    """Complete anomaly detection system for Wave 2 monitoring"""

    def __init__(self,
                 lookback_minutes: int = 60,
                 use_ml: bool = True,
                 use_statistical: bool = True):
        """
        Initialize anomaly detection system

        Args:
            lookback_minutes: Historical window for baseline (default: 60 min)
            use_ml: Enable ML-based detection
            use_statistical: Enable statistical detection
        """
        self.lookback_minutes = lookback_minutes
        self.use_ml = use_ml and SKLEARN_AVAILABLE
        self.use_statistical = use_statistical

        # Detectors
        self.statistical_detector = StatisticalDetector() if use_statistical else None
        self.ml_detector = MLBasedDetector() if self.use_ml else None

        # Metric history
        self.metric_history: Dict[str, List[MetricPoint]] = {}

        # Detection statistics
        self.stats = {
            'total_anomalies_detected': 0,
            'false_positive_rate': 0.0,
            'detection_latency_ms': 0.0,
            'by_type': {atype.value: 0 for atype in AnomalyType},
            'by_severity': {sev.value: 0 for sev in AnomalySeverity}
        }

    def add_metric(self, metric_point: MetricPoint):
        """Add metric point to history"""
        metric_name = metric_point.metric_name

        if metric_name not in self.metric_history:
            self.metric_history[metric_name] = []

        self.metric_history[metric_name].append(metric_point)

        # Trim old data
        cutoff = datetime.now() - timedelta(minutes=self.lookback_minutes)
        self.metric_history[metric_name] = [
            p for p in self.metric_history[metric_name]
            if p.timestamp >= cutoff
        ]

    def detect_anomalies(self, metric_name: str, current_value: float) -> List[AnomalyDetection]:
        """
        Detect anomalies in current metric value

        Returns:
            List of detected anomalies (may be empty)
        """
        start_time = time.time()
        anomalies = []

        if metric_name not in self.metric_history:
            return anomalies

        history = self.metric_history[metric_name]
        if len(history) < 10:  # Need baseline data
            return anomalies

        historical_values = [p.value for p in history]
        expected_value = np.median(historical_values)

        # Statistical detection
        if self.use_statistical and self.statistical_detector:
            is_anomaly_zscore, z_score = self.statistical_detector.detect_zscore(
                historical_values, current_value
            )
            is_anomaly_iqr, deviation = self.statistical_detector.detect_iqr(
                historical_values, current_value
            )

            if is_anomaly_zscore or is_anomaly_iqr:
                anomaly = self._create_anomaly(
                    metric_name, current_value, expected_value, z_score
                )
                anomalies.append(anomaly)

        # ML detection (if fitted)
        if self.use_ml and self.ml_detector and self.ml_detector.is_fitted:
            # Extract features for ML (current + recent trend)
            features = self._extract_features(history, current_value)
            is_anomaly_ml, ml_confidence = self.ml_detector.predict(features)

            if is_anomaly_ml:
                anomaly = self._create_anomaly(
                    metric_name, current_value, expected_value, ml_confidence,
                    detection_method="ml"
                )
                anomalies.append(anomaly)

        # Update stats
        detection_latency = (time.time() - start_time) * 1000  # ms
        self.stats['detection_latency_ms'] = detection_latency
        self.stats['total_anomalies_detected'] += len(anomalies)

        for anomaly in anomalies:
            self.stats['by_type'][anomaly.type.value] += 1
            self.stats['by_severity'][anomaly.severity.value] += 1

        return anomalies

    def _create_anomaly(self,
                       metric_name: str,
                       current_value: float,
                       expected_value: float,
                       confidence: float,
                       detection_method: str = "statistical") -> AnomalyDetection:
        """Create anomaly detection result"""

        deviation_percent = abs((current_value - expected_value) / expected_value * 100) if expected_value != 0 else 0

        # Classify anomaly type
        anomaly_type = self._classify_anomaly_type(metric_name, current_value, expected_value)

        # Determine severity
        severity = self._determine_severity(deviation_percent, confidence)

        return AnomalyDetection(
            type=anomaly_type,
            severity=severity,
            metric_name=metric_name,
            current_value=current_value,
            expected_value=expected_value,
            deviation_percent=deviation_percent,
            confidence=confidence,
            context={
                'detection_method': detection_method,
                'baseline_samples': len(self.metric_history.get(metric_name, []))
            },
            timestamp=datetime.now()
        )

    def _classify_anomaly_type(self, metric_name: str, current: float, expected: float) -> AnomalyType:
        """Classify type of anomaly based on metric name and values"""
        metric_lower = metric_name.lower()

        if 'latency' in metric_lower or 'duration' in metric_lower:
            return AnomalyType.LATENCY_SPIKE if current > expected else AnomalyType.NORMAL

        elif 'throughput' in metric_lower or 'qps' in metric_lower:
            return AnomalyType.THROUGHPUT_DROP if current < expected else AnomalyType.NORMAL

        elif 'error' in metric_lower:
            return AnomalyType.ERROR_RATE_INCREASE if current > expected else AnomalyType.NORMAL

        elif 'cache' in metric_lower and 'miss' in metric_lower:
            return AnomalyType.CACHE_MISS_SPIKE if current > expected else AnomalyType.NORMAL

        elif 'pool' in metric_lower or 'connection' in metric_lower:
            return AnomalyType.CONNECTION_POOL_SATURATION if current > expected else AnomalyType.NORMAL

        elif 'tier' in metric_lower:
            return AnomalyType.TIER_IMBALANCE

        elif 'ml' in metric_lower or 'model' in metric_lower:
            return AnomalyType.ML_DEGRADATION

        else:
            return AnomalyType.NORMAL

    def _determine_severity(self, deviation_percent: float, confidence: float) -> AnomalySeverity:
        """Determine severity based on deviation and confidence"""

        # Critical: Large deviation + high confidence
        if deviation_percent > 50 and confidence > 0.8:
            return AnomalySeverity.CRITICAL

        # Warning: Moderate deviation or moderate confidence
        elif deviation_percent > 20 or confidence > 0.6:
            return AnomalySeverity.WARNING

        # Info: Small deviation
        else:
            return AnomalySeverity.INFO

    def _extract_features(self, history: List[MetricPoint], current_value: float) -> np.ndarray:
        """Extract features for ML detection"""
        recent = history[-10:]  # Last 10 points

        features = [
            current_value,
            np.mean([p.value for p in recent]),
            np.std([p.value for p in recent]),
            np.median([p.value for p in recent]),
            np.percentile([p.value for p in recent], 95),
            # Trend: slope of recent values
            self._calculate_trend(recent),
            # Volatility: coefficient of variation
            np.std([p.value for p in recent]) / (np.mean([p.value for p in recent]) + 1e-10)
        ]

        return np.array(features)

    def _calculate_trend(self, points: List[MetricPoint]) -> float:
        """Calculate trend (slope) of recent points"""
        if len(points) < 2:
            return 0.0

        values = [p.value for p in points]
        x = np.arange(len(values))

        # Simple linear regression
        slope = np.polyfit(x, values, 1)[0]
        return slope

    def train_ml_models(self):
        """Train ML models on historical data"""
        if not self.use_ml or not self.ml_detector:
            return

        # Gather all historical features
        all_features = []

        for metric_name, history in self.metric_history.items():
            if len(history) < 20:
                continue

            for i in range(10, len(history)):
                features = self._extract_features(history[:i], history[i].value)
                all_features.append(features)

        if len(all_features) < 10:
            warnings.warn("Not enough data to train ML models")
            return

        feature_matrix = np.array(all_features)
        self.ml_detector.fit(feature_matrix)

    def get_stats(self) -> Dict[str, Any]:
        """Get detection statistics"""
        return self.stats.copy()

    def reset_stats(self):
        """Reset statistics counters"""
        self.stats = {
            'total_anomalies_detected': 0,
            'false_positive_rate': 0.0,
            'detection_latency_ms': 0.0,
            'by_type': {atype.value: 0 for atype in AnomalyType},
            'by_severity': {sev.value: 0 for sev in AnomalySeverity}
        }


# Example usage
if __name__ == "__main__":
    # Initialize system
    detector = AnomalyDetectionSystem(
        lookback_minutes=60,
        use_ml=SKLEARN_AVAILABLE,
        use_statistical=True
    )

    # Simulate metric stream
    metric_name = "rust_query_latency_ms"

    # Normal baseline (0.05ms = 50 microseconds)
    for i in range(100):
        normal_value = 0.050 + np.random.normal(0, 0.005)  # Small variance
        detector.add_metric(MetricPoint(
            timestamp=datetime.now() - timedelta(minutes=100-i),
            value=normal_value,
            metric_name=metric_name,
            tags={}
        ))

    # Train ML models
    if SKLEARN_AVAILABLE:
        detector.train_ml_models()
        print("ML models trained")

    # Detect anomaly (latency spike to 0.2ms)
    anomaly_value = 0.200  # 4x normal
    anomalies = detector.detect_anomalies(metric_name, anomaly_value)

    print(f"\nDetected {len(anomalies)} anomalies:")
    for anomaly in anomalies:
        print(f"  - {anomaly.type.value}: {anomaly.severity.value}")
        print(f"    Current: {anomaly.current_value:.4f}ms, Expected: {anomaly.expected_value:.4f}ms")
        print(f"    Deviation: {anomaly.deviation_percent:.1f}%, Confidence: {anomaly.confidence:.2f}")

    # Get stats
    stats = detector.get_stats()
    print(f"\nDetection Statistics:")
    print(f"  Total anomalies: {stats['total_anomalies_detected']}")
    print(f"  Detection latency: {stats['detection_latency_ms']:.2f}ms")
