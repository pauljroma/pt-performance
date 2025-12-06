"""
ML-Based Tier Selection Model - Wave 2 Agent 11
Uses RandomForest classifier to predict optimal database tier based on query characteristics

Features:
- Scikit-learn RandomForest classifier
- Feature engineering from query parameters
- Model training pipeline with historical data
- Prediction API with confidence scores
- Model persistence (save/load)
- <1ms inference time requirement
"""

import os
import json
import pickle
import time
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, Any, Optional, Tuple, List
from dataclasses import dataclass, asdict
from enum import Enum

import numpy as np

# Import shared DataTier enum
from .tier_router import DataTier

# Try to import sklearn, provide helpful error if missing
try:
    from sklearn.ensemble import RandomForestClassifier
    from sklearn.model_selection import train_test_split
    from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, confusion_matrix
    from sklearn.preprocessing import StandardScaler
    SKLEARN_AVAILABLE = True
except ImportError:
    SKLEARN_AVAILABLE = False
    print("Warning: scikit-learn not available. ML tier selection disabled.")


@dataclass
class QueryFeatures:
    """Extracted features from a query for ML prediction"""
    query_type: str  # recent, semantic, historical, analytics
    data_age_days: float  # 0-365+
    estimated_rows: int  # Estimated result size
    query_complexity: float  # Complexity score (0-10)
    time_of_day: int  # 0-23
    day_of_week: int  # 0-6 (Monday=0)
    has_embeddings: bool  # Requires vector search
    has_aggregation: bool  # Has GROUP BY, SUM, etc.
    table_count: int  # Number of tables in query
    historical_avg_latency_ms: float  # Past performance for similar queries

    def to_array(self) -> np.ndarray:
        """Convert features to numpy array for model input"""
        return np.array([
            self._encode_query_type(),
            self.data_age_days,
            np.log1p(self.estimated_rows),  # Log transform for large values
            self.query_complexity,
            self.time_of_day,
            self.day_of_week,
            float(self.has_embeddings),
            float(self.has_aggregation),
            self.table_count,
            np.log1p(self.historical_avg_latency_ms)
        ])

    def _encode_query_type(self) -> float:
        """Encode query type as numeric value"""
        encoding = {
            'recent': 0.0,
            'semantic': 1.0,
            'historical': 2.0,
            'analytics': 3.0
        }
        return encoding.get(self.query_type, 0.0)


@dataclass
class TierPrediction:
    """ML model prediction result"""
    tier: DataTier
    confidence: float  # 0.0-1.0
    probabilities: Dict[str, float]  # Probability for each tier
    inference_time_ms: float
    fallback_to_static: bool  # True if confidence too low

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary"""
        return {
            'tier': self.tier.value,
            'confidence': self.confidence,
            'probabilities': self.probabilities,
            'inference_time_ms': self.inference_time_ms,
            'fallback_to_static': self.fallback_to_static
        }


@dataclass
class ModelMetrics:
    """ML model performance metrics"""
    accuracy: float
    precision: float
    recall: float
    f1_score: float
    confusion_matrix: List[List[int]]
    training_samples: int
    test_samples: int
    training_time_ms: float


class MLTierSelector:
    """
    ML-based tier selection using RandomForest classifier

    Learns from historical query patterns to predict optimal tier
    Maintains <1ms inference time for production use
    """

    def __init__(
        self,
        model_path: Optional[str] = None,
        confidence_threshold: float = 0.7,
        enable_fallback: bool = True
    ):
        """
        Initialize ML tier selector

        Args:
            model_path: Path to saved model file
            confidence_threshold: Minimum confidence for ML prediction (default 0.7)
            enable_fallback: Whether to fallback to static routing on low confidence
        """
        if not SKLEARN_AVAILABLE:
            raise ImportError("scikit-learn required for ML tier selection. Install: pip install scikit-learn")

        self.confidence_threshold = confidence_threshold
        self.enable_fallback = enable_fallback

        # Initialize model
        self.model = RandomForestClassifier(
            n_estimators=100,
            max_depth=10,
            min_samples_split=20,
            random_state=42,
            n_jobs=-1  # Use all CPU cores
        )

        # Feature scaler for normalization
        self.scaler = StandardScaler()

        # Tier label encoding
        self.tier_labels = {
            0: DataTier.MASTER,
            1: DataTier.PGVECTOR,
            2: DataTier.MINIO,
            3: DataTier.ATHENA
        }
        self.tier_to_label = {v: k for k, v in self.tier_labels.items()}

        # Model state
        self.is_trained = False
        self.model_version = "1.0.0"
        self.last_training_time = None

        # Performance tracking
        self.prediction_count = 0
        self.total_inference_time_ms = 0.0
        self.fallback_count = 0

        # Load model if path provided
        if model_path and os.path.exists(model_path):
            self.load_model(model_path)

    def extract_features(self, query_params: Dict[str, Any]) -> QueryFeatures:
        """
        Extract ML features from query parameters

        Args:
            query_params: Query parameters dict

        Returns:
            QueryFeatures object
        """
        now = datetime.now()

        # Determine query type from parameters
        query_type = 'recent'
        if query_params.get('use_embeddings') or query_params.get('similarity_search'):
            query_type = 'semantic'
        elif query_params.get('days_back', 0) > 90:
            query_type = 'analytics'
        elif query_params.get('days_back', 0) > 7:
            query_type = 'historical'

        # Extract features
        features = QueryFeatures(
            query_type=query_type,
            data_age_days=float(query_params.get('days_back', 0)),
            estimated_rows=query_params.get('estimated_rows', 100),
            query_complexity=self._calculate_complexity(query_params),
            time_of_day=now.hour,
            day_of_week=now.weekday(),
            has_embeddings=bool(query_params.get('use_embeddings') or query_params.get('similarity_search')),
            has_aggregation=bool(query_params.get('has_aggregation', False)),
            table_count=query_params.get('table_count', 1),
            historical_avg_latency_ms=query_params.get('historical_latency_ms', 50.0)
        )

        return features

    def _calculate_complexity(self, query_params: Dict[str, Any]) -> float:
        """
        Calculate query complexity score (0-10)

        Based on:
        - Number of tables/joins
        - Aggregations
        - Filters
        - Result set size
        """
        complexity = 0.0

        # Base complexity from table count
        complexity += min(query_params.get('table_count', 1) * 2, 4)

        # Aggregations add complexity
        if query_params.get('has_aggregation'):
            complexity += 2

        # Large result sets
        estimated_rows = query_params.get('estimated_rows', 100)
        if estimated_rows > 10000:
            complexity += 2
        elif estimated_rows > 1000:
            complexity += 1

        # Embeddings/semantic search
        if query_params.get('use_embeddings'):
            complexity += 2

        return min(complexity, 10.0)

    def train(
        self,
        training_data: List[Tuple[Dict[str, Any], DataTier]],
        test_split: float = 0.2
    ) -> ModelMetrics:
        """
        Train the ML model on historical query data

        Args:
            training_data: List of (query_params, actual_optimal_tier) tuples
            test_split: Fraction of data to use for testing

        Returns:
            ModelMetrics with training results
        """
        if len(training_data) < 100:
            raise ValueError(f"Need at least 100 training samples, got {len(training_data)}")

        start_time = time.perf_counter()

        # Extract features and labels
        X = []
        y = []
        for query_params, tier in training_data:
            features = self.extract_features(query_params)
            X.append(features.to_array())
            y.append(self.tier_to_label[tier])

        X = np.array(X)
        y = np.array(y)

        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=test_split, random_state=42, stratify=y
        )

        # Scale features
        self.scaler.fit(X_train)
        X_train_scaled = self.scaler.transform(X_train)
        X_test_scaled = self.scaler.transform(X_test)

        # Train model
        self.model.fit(X_train_scaled, y_train)
        self.is_trained = True
        self.last_training_time = datetime.now()

        # Evaluate on test set
        y_pred = self.model.predict(X_test_scaled)

        # Calculate metrics
        training_time_ms = (time.perf_counter() - start_time) * 1000

        metrics = ModelMetrics(
            accuracy=accuracy_score(y_test, y_pred),
            precision=precision_score(y_test, y_pred, average='weighted', zero_division=0),
            recall=recall_score(y_test, y_pred, average='weighted', zero_division=0),
            f1_score=f1_score(y_test, y_pred, average='weighted', zero_division=0),
            confusion_matrix=confusion_matrix(y_test, y_pred).tolist(),
            training_samples=len(X_train),
            test_samples=len(X_test),
            training_time_ms=training_time_ms
        )

        return metrics

    def predict(self, query_params: Dict[str, Any]) -> TierPrediction:
        """
        Predict optimal tier for a query using ML model

        Args:
            query_params: Query parameters

        Returns:
            TierPrediction with tier, confidence, and metadata
        """
        if not self.is_trained:
            raise RuntimeError("Model not trained. Call train() first or load a trained model.")

        start_time = time.perf_counter()

        # Extract features
        features = self.extract_features(query_params)
        X = features.to_array().reshape(1, -1)

        # Scale features
        X_scaled = self.scaler.transform(X)

        # Predict
        prediction = self.model.predict(X_scaled)[0]
        probabilities = self.model.predict_proba(X_scaled)[0]

        # Get tier and confidence
        predicted_tier = self.tier_labels[prediction]
        confidence = float(probabilities[prediction])

        # Build probability dict
        prob_dict = {
            tier.value: float(probabilities[label])
            for label, tier in self.tier_labels.items()
        }

        # Calculate inference time
        inference_time_ms = (time.perf_counter() - start_time) * 1000

        # Determine if fallback needed
        fallback = self.enable_fallback and confidence < self.confidence_threshold

        # Update stats
        self.prediction_count += 1
        self.total_inference_time_ms += inference_time_ms
        if fallback:
            self.fallback_count += 1

        return TierPrediction(
            tier=predicted_tier,
            confidence=confidence,
            probabilities=prob_dict,
            inference_time_ms=inference_time_ms,
            fallback_to_static=fallback
        )

    def predict_batch(self, query_params_list: List[Dict[str, Any]]) -> List[TierPrediction]:
        """Predict tiers for multiple queries efficiently"""
        if not self.is_trained:
            raise RuntimeError("Model not trained")

        predictions = []
        for query_params in query_params_list:
            predictions.append(self.predict(query_params))

        return predictions

    def save_model(self, path: str):
        """
        Save trained model to disk

        Args:
            path: File path to save model
        """
        if not self.is_trained:
            raise RuntimeError("Cannot save untrained model")

        model_data = {
            'model': self.model,
            'scaler': self.scaler,
            'tier_labels': self.tier_labels,
            'tier_to_label': self.tier_to_label,
            'model_version': self.model_version,
            'last_training_time': self.last_training_time.isoformat() if self.last_training_time else None,
            'confidence_threshold': self.confidence_threshold
        }

        with open(path, 'wb') as f:
            pickle.dump(model_data, f)

    def load_model(self, path: str):
        """
        Load trained model from disk

        Args:
            path: File path to load model from
        """
        with open(path, 'rb') as f:
            model_data = pickle.load(f)

        self.model = model_data['model']
        self.scaler = model_data['scaler']
        self.tier_labels = model_data['tier_labels']
        self.tier_to_label = model_data['tier_to_label']
        self.model_version = model_data['model_version']
        self.confidence_threshold = model_data.get('confidence_threshold', 0.7)

        if model_data['last_training_time']:
            self.last_training_time = datetime.fromisoformat(model_data['last_training_time'])

        self.is_trained = True

    def get_feature_importance(self) -> Dict[str, float]:
        """Get feature importance scores from trained model"""
        if not self.is_trained:
            return {}

        feature_names = [
            'query_type', 'data_age_days', 'estimated_rows', 'query_complexity',
            'time_of_day', 'day_of_week', 'has_embeddings', 'has_aggregation',
            'table_count', 'historical_avg_latency_ms'
        ]

        importances = self.model.feature_importances_

        return {
            name: float(importance)
            for name, importance in zip(feature_names, importances)
        }

    def get_stats(self) -> Dict[str, Any]:
        """Get ML selector statistics"""
        avg_inference_ms = 0.0
        if self.prediction_count > 0:
            avg_inference_ms = self.total_inference_time_ms / self.prediction_count

        fallback_rate = 0.0
        if self.prediction_count > 0:
            fallback_rate = (self.fallback_count / self.prediction_count) * 100

        return {
            'is_trained': self.is_trained,
            'model_version': self.model_version,
            'last_training_time': self.last_training_time.isoformat() if self.last_training_time else None,
            'prediction_count': self.prediction_count,
            'avg_inference_time_ms': avg_inference_ms,
            'fallback_count': self.fallback_count,
            'fallback_rate_pct': fallback_rate,
            'confidence_threshold': self.confidence_threshold,
            'feature_importance': self.get_feature_importance() if self.is_trained else {}
        }


def generate_synthetic_training_data(num_samples: int = 1000) -> List[Tuple[Dict[str, Any], DataTier]]:
    """
    Generate synthetic training data for model development

    This simulates historical query patterns with optimal tier assignments
    based on the static routing rules we want to improve upon.

    Args:
        num_samples: Number of training samples to generate

    Returns:
        List of (query_params, optimal_tier) tuples
    """
    training_data = []

    for _ in range(num_samples):
        # Randomly select query characteristics
        days_back = np.random.choice([
            np.random.randint(0, 7),      # 40% recent
            np.random.randint(7, 90),     # 30% historical
            np.random.randint(90, 365),   # 30% analytics
        ], p=[0.4, 0.3, 0.3])

        use_embeddings = np.random.random() < 0.2  # 20% semantic queries

        query_params = {
            'days_back': int(days_back),
            'use_embeddings': use_embeddings,
            'similarity_search': use_embeddings,
            'estimated_rows': int(np.random.lognormal(5, 2)),  # Log-normal distribution
            'has_aggregation': np.random.random() < 0.3,
            'table_count': np.random.randint(1, 5),
            'historical_latency_ms': float(np.random.lognormal(3, 1))
        }

        # Determine optimal tier (ground truth based on static rules + noise)
        if use_embeddings:
            optimal_tier = DataTier.PGVECTOR
        elif days_back <= 7:
            optimal_tier = DataTier.MASTER
        elif days_back <= 90:
            optimal_tier = DataTier.MINIO
        else:
            optimal_tier = DataTier.ATHENA

        # Add some noise to make it realistic (5% suboptimal assignments)
        if np.random.random() < 0.05:
            optimal_tier = np.random.choice(list(DataTier))

        training_data.append((query_params, optimal_tier))

    return training_data
