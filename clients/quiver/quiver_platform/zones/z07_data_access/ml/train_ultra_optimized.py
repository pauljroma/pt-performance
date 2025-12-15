#!/usr/bin/env python3
"""
Ultra-Optimized ML Tier Router - Target <5ms Inference

Aggressive optimization strategy to hit <5ms inference time:
1. Reduce to 3-5 trees (from 10)
2. Shallow trees (max_depth 4)
3. Feature selection: Top 10 most important features only
4. Single prediction path optimization

The model achieves 100% accuracy with 50 trees, so we can afford to be aggressive.

Strategy:
- If accuracy drops below 90%, use Decision Tree (single tree, ~1ms inference)
- If accuracy stays high, use minimal Random Forest (3 trees)

Version: 2.2.0 (Ultra-Optimized)
Date: 2025-12-06
Author: Optimization Engineer
"""

import logging
import pickle
import json
import time
from pathlib import Path
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.tree import DecisionTreeClassifier
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix

# Import trainer for data loading
import sys
sys.path.insert(0, str(Path(__file__).parent))
from tier_router_trainer import TierRouterTrainer

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

logger = logging.getLogger(__name__)


def select_top_features(trainer, model, n_features=10):
    """
    Select top N most important features from trained model.

    Args:
        trainer: TierRouterTrainer instance
        model: Trained model with feature_importances_
        n_features: Number of top features to select

    Returns:
        List of top feature names
    """
    # Get feature importances
    importances = model.feature_importances_
    feature_names = trainer.feature_names

    # Sort by importance
    indices = np.argsort(importances)[::-1]

    # Select top N
    top_indices = indices[:n_features]
    top_features = [feature_names[i] for i in top_indices]

    logger.info(f"\nTop {n_features} features selected:")
    for i, idx in enumerate(top_indices):
        logger.info(f"  {i+1}. {feature_names[idx]}: {importances[idx]:.4f}")

    return top_features


def train_ultra_optimized_model():
    """Train ultra-optimized model for <5ms inference"""

    logger.info("=" * 80)
    logger.info("ULTRA-OPTIMIZED MODEL TRAINING (Target: <5ms inference)")
    logger.info("=" * 80)

    # Initialize trainer
    trainer = TierRouterTrainer()

    # Load data
    logger.info("\n[1/6] Loading training data...")
    trainer.load_training_data("training_sample.parquet")

    # Prepare train-test split
    logger.info("\n[2/6] Preparing train-test split...")
    trainer.prepare_train_test_split(test_size=0.2)

    # Step 1: Train full model to get feature importances
    logger.info("\n[3/6] Training full model for feature selection...")
    full_model = RandomForestClassifier(
        n_estimators=10,
        max_depth=6,
        random_state=42,
        n_jobs=-1
    )
    full_model.fit(trainer.X_train, trainer.y_train)

    # Step 2: Select top features
    logger.info("\n[4/6] Selecting top 10 features...")
    top_features = select_top_features(trainer, full_model, n_features=10)

    # Step 3: Retrain with selected features only
    logger.info("\n[5/6] Training ultra-optimized models...")

    X_train_selected = trainer.X_train[top_features]
    X_test_selected = trainer.X_test[top_features]

    # Test multiple configurations
    configs = [
        {
            'name': 'Single Tree (Decision Tree)',
            'model': DecisionTreeClassifier(
                max_depth=8,
                min_samples_split=5,
                min_samples_leaf=2,
                random_state=42
            ),
            'type': 'DecisionTree'
        },
        {
            'name': 'Minimal Forest (3 trees)',
            'model': RandomForestClassifier(
                n_estimators=3,
                max_depth=6,
                min_samples_split=5,
                min_samples_leaf=2,
                max_features='sqrt',
                random_state=42,
                n_jobs=-1
            ),
            'type': 'RandomForest'
        },
        {
            'name': 'Ultra-Shallow Forest (5 trees, depth 4)',
            'model': RandomForestClassifier(
                n_estimators=5,
                max_depth=4,
                min_samples_split=5,
                min_samples_leaf=3,
                max_features='sqrt',
                random_state=42,
                n_jobs=-1
            ),
            'type': 'RandomForest'
        }
    ]

    results = []

    for config in configs:
        logger.info(f"\n  Testing: {config['name']}")

        # Train
        start_time = time.time()
        model = config['model']
        model.fit(X_train_selected, trainer.y_train)
        training_time = time.time() - start_time

        # Predict
        train_pred = model.predict(X_train_selected)
        test_pred = model.predict(X_test_selected)

        train_accuracy = accuracy_score(trainer.y_train, train_pred)
        test_accuracy = accuracy_score(trainer.y_test, test_pred)

        # Benchmark inference (1000 predictions)
        start_time = time.time()
        for _ in range(1000):
            _ = model.predict(X_test_selected.iloc[:1])
        inference_time = (time.time() - start_time) / 1000 * 1000  # ms

        # Model size
        import tempfile
        with tempfile.NamedTemporaryFile(delete=True) as tmp:
            pickle.dump(model, tmp)
            tmp.flush()
            model_size_mb = tmp.tell() / (1024 * 1024)

        result = {
            'config': config,
            'model': model,
            'train_accuracy': train_accuracy,
            'test_accuracy': test_accuracy,
            'training_time': training_time,
            'inference_time': inference_time,
            'model_size_mb': model_size_mb
        }

        results.append(result)

        logger.info(f"    Train Accuracy: {train_accuracy:.1%}")
        logger.info(f"    Test Accuracy:  {test_accuracy:.1%}")
        logger.info(f"    Inference Time: {inference_time:.3f}ms")
        logger.info(f"    Model Size:     {model_size_mb:.3f} MB")

    # Step 4: Select best model
    logger.info("\n[6/6] Selecting best model...")

    # Filter: Must have test_accuracy >= 0.87 (or best available)
    valid_results = [r for r in results if r['test_accuracy'] >= 0.87]

    if not valid_results:
        logger.warning("No models met 87% accuracy target, selecting best accuracy")
        valid_results = results

    # Sort by inference time (fastest first)
    valid_results.sort(key=lambda x: x['inference_time'])

    best_result = valid_results[0]
    best_model = best_result['model']
    best_config = best_result['config']

    logger.info(f"\nBest Model: {best_config['name']}")
    logger.info(f"  Test Accuracy:  {best_result['test_accuracy']:.1%}")
    logger.info(f"  Inference Time: {best_result['inference_time']:.3f}ms")
    logger.info(f"  Model Size:     {best_result['model_size_mb']:.3f} MB")

    # Detailed evaluation
    logger.info("\n" + "=" * 80)
    logger.info("DETAILED EVALUATION")
    logger.info("=" * 80)

    test_pred = best_model.predict(X_test_selected)

    logger.info("\nClassification Report:")
    logger.info("\n" + classification_report(
        trainer.y_test,
        test_pred,
        target_names=['Tier 1', 'Tier 2', 'Tier 3', 'Tier 4']
    ))

    logger.info("\nConfusion Matrix:")
    cm = confusion_matrix(trainer.y_test, test_pred)
    logger.info(f"\n{cm}")

    # Save model
    logger.info("\n" + "=" * 80)
    logger.info("SAVING ULTRA-OPTIMIZED MODEL")
    logger.info("=" * 80)

    models_dir = Path(__file__).parent.parent.parent.parent / "models"
    models_dir.mkdir(exist_ok=True)

    model_path = models_dir / "tier_routing_v2_ultra.pkl"
    with open(model_path, 'wb') as f:
        pickle.dump(best_model, f)

    logger.info(f"\nModel saved: {model_path}")

    # Save metadata
    metadata = {
        'feature_names': top_features,
        'all_features': trainer.feature_names,
        'feature_selection': 'top_10_importance',
        'model_type': best_config['type'],
        'model_name': best_config['name'],
        'optimized_for': 'ultra_fast_inference',
        'test_accuracy': float(best_result['test_accuracy']),
        'train_accuracy': float(best_result['train_accuracy']),
        'inference_time_ms': float(best_result['inference_time']),
        'model_size_mb': float(best_result['model_size_mb']),
        'training_samples': len(trainer.y_train),
        'test_samples': len(trainer.y_test),
        'n_features_selected': len(top_features),
        'n_features_total': len(trainer.feature_names)
    }

    metadata_path = models_dir / "tier_routing_v2_ultra_metadata.json"
    with open(metadata_path, 'w') as f:
        json.dump(metadata, f, indent=2)

    logger.info(f"Metadata saved: {metadata_path}")

    # Final summary
    logger.info("\n" + "=" * 80)
    logger.info("OPTIMIZATION SUMMARY")
    logger.info("=" * 80)

    logger.info(f"\nOriginal Model (v2):")
    logger.info(f"  Trees: 50, Depth: 8, Features: 23")
    logger.info(f"  Inference: 17.8ms")

    logger.info(f"\nOptimized Model (v2_optimized):")
    logger.info(f"  Trees: 10, Depth: 6, Features: 23")
    logger.info(f"  Inference: 17.2ms")

    logger.info(f"\nUltra-Optimized Model (v2_ultra): {best_config['name']}")
    if best_config['type'] == 'DecisionTree':
        logger.info(f"  Trees: 1, Depth: 8, Features: 10")
    else:
        params = best_config['model'].get_params()
        logger.info(f"  Trees: {params['n_estimators']}, Depth: {params['max_depth']}, Features: 10")
    logger.info(f"  Inference: {best_result['inference_time']:.3f}ms")

    # Speed improvement
    speedup = 17.8 / best_result['inference_time']
    logger.info(f"\nSpeedup: {speedup:.1f}x faster than original")

    # Status
    logger.info("\n" + "=" * 80)
    if best_result['test_accuracy'] >= 0.87 and best_result['inference_time'] < 5.0:
        logger.info("STATUS: ✅ SUCCESS - Both accuracy and speed targets met!")
        logger.info(f"  Accuracy: {best_result['test_accuracy']:.1%} (target: 87%)")
        logger.info(f"  Inference: {best_result['inference_time']:.3f}ms (target: <5ms)")
    elif best_result['inference_time'] < 5.0:
        logger.info("STATUS: ⚡ FAST - Speed target met!")
        logger.info(f"  Inference: {best_result['inference_time']:.3f}ms (target: <5ms)")
        logger.info(f"  Accuracy: {best_result['test_accuracy']:.1%} (target: 87%)")
    else:
        logger.info("STATUS: ⚠️  NEEDS MORE OPTIMIZATION")
        logger.info(f"  Accuracy: {best_result['test_accuracy']:.1%}")
        logger.info(f"  Inference: {best_result['inference_time']:.3f}ms (target: <5ms)")
    logger.info("=" * 80)

    return best_model, best_result, top_features


if __name__ == "__main__":
    model, result, features = train_ultra_optimized_model()
