#!/usr/bin/env python3
"""
Test ML QSAR Integration
=========================

Tests integration of ML QSAR model (z05_models) with BBBPredictionService (z07_data_access).

Tests:
1. Service initialization with ML QSAR model
2. ML QSAR fallback predictions
3. Comparison: ML QSAR vs simple rules
4. Service stats with ML model info

Zone: z07_data_access/scripts
Author: Integration Testing Agent
Date: 2025-12-01
"""

import sys
from pathlib import Path

# Add zones to path
zones_path = Path(__file__).parent.parent.parent
sys.path.insert(0, str(zones_path))

from z07_data_access.bbb_prediction_service import get_bbb_prediction_service, BBBPredictionService


def test_ml_qsar_initialization():
    """Test 1: Service initialization with ML QSAR model."""
    print("=" * 70)
    print("Test 1: Service Initialization with ML QSAR Model")
    print("=" * 70)

    # Initialize with ML QSAR enabled
    service = BBBPredictionService(use_ml_qsar=True, precompute_fingerprints=False)

    stats = service.get_stats()

    print(f"\nML QSAR Available: {stats['ml_qsar_model']['available']}")
    print(f"ML QSAR Enabled: {stats['ml_qsar_model']['enabled']}")

    if stats['ml_qsar_model']['enabled']:
        print(f"Model Version: {stats['ml_qsar_model']['model_version']}")
        print(f"Training Stats: {stats['ml_qsar_model']['training_stats']}")
        print("\n✅ ML QSAR model loaded successfully")
    else:
        print("\n⚠️  ML QSAR model not loaded (may not be trained yet)")

    return service


def test_ml_qsar_fallback(service):
    """Test 2: ML QSAR fallback predictions."""
    print("\n" + "=" * 70)
    print("Test 2: ML QSAR Fallback Predictions")
    print("=" * 70)

    # Test with a novel structure (unlikely to have close matches)
    # Fluorinated compound - novel structure
    novel_smiles = "FC(F)(F)c1ccc(NC(=O)c2ccccc2)cc1"

    print(f"\nQuery SMILES: {novel_smiles}")
    print(f"Expected: ML QSAR fallback (no similar structures)\n")

    try:
        pred = service.predict_from_smiles(novel_smiles, k_neighbors=10)

        print(f"Prediction Method: {pred.prediction_method}")
        print(f"Predicted Log BB: {pred.predicted_log_bb:.3f}")
        print(f"Predicted Class: {pred.predicted_bbb_class}")
        print(f"Confidence: {pred.confidence:.2%}")

        if pred.prediction_method == 'ml_qsar':
            print("\n✅ ML QSAR fallback working correctly")
            print(f"Model Version: {pred.metadata.get('model_version')}")
            print(f"Features: {list(pred.metadata.get('features', {}).keys())}")
        elif pred.prediction_method == 'qsar_fallback':
            print("\n⚠️  Using simple QSAR rules (ML model may not be loaded)")
        else:
            print(f"\n✅ Found similar structures (method: {pred.prediction_method})")

        return pred

    except Exception as e:
        print(f"\n❌ Prediction failed: {e}")
        return None


def test_comparison_ml_vs_simple():
    """Test 3: Comparison of ML QSAR vs simple rules."""
    print("\n" + "=" * 70)
    print("Test 3: ML QSAR vs Simple Rules Comparison")
    print("=" * 70)

    # Initialize both services
    service_ml = BBBPredictionService(use_ml_qsar=True, precompute_fingerprints=False)
    service_simple = BBBPredictionService(use_ml_qsar=False, precompute_fingerprints=False)

    # Test compounds (unlikely to have exact matches)
    test_compounds = [
        ("Fluorinated aromatic", "FC(F)(F)c1ccc(N)cc1"),
        ("Complex steroid", "CC12CCC3C(C1CCC2O)CCC4=CC(=O)CCC34C"),
        ("Simple amine", "CCN(CC)CC")
    ]

    print("\nComparing ML QSAR vs Simple Rules:")
    print("-" * 70)

    for name, smiles in test_compounds:
        print(f"\n{name}: {smiles}")

        try:
            # ML prediction
            pred_ml = service_ml.predict_from_smiles(smiles, k_neighbors=10)

            # Simple rules prediction
            pred_simple = service_simple.predict_from_smiles(smiles, k_neighbors=10)

            print(f"  ML QSAR:      Log BB = {pred_ml.predicted_log_bb:+.3f}, "
                  f"Class = {pred_ml.predicted_bbb_class:12s}, "
                  f"Confidence = {pred_ml.confidence:.2%}")

            print(f"  Simple Rules: Log BB = {pred_simple.predicted_log_bb:+.3f}, "
                  f"Class = {pred_simple.predicted_bbb_class:12s}, "
                  f"Confidence = {pred_simple.confidence:.2%}")

            # Note differences
            if pred_ml.predicted_bbb_class != pred_simple.predicted_bbb_class:
                print(f"  ⚠️  Different classifications!")

        except Exception as e:
            print(f"  ❌ Error: {e}")

    print("\n✅ Comparison complete")


def test_service_stats():
    """Test 4: Service stats with ML model info."""
    print("\n" + "=" * 70)
    print("Test 4: Service Statistics with ML Model Info")
    print("=" * 70)

    service = get_bbb_prediction_service(use_ml_qsar=True)
    stats = service.get_stats()

    print(f"\nReference compounds: {stats['reference_compounds']}")
    print(f"Literature validated: {stats['literature_validated']}")
    print(f"QSAR predicted: {stats['qsar_predicted']}")

    print(f"\nFingerprint cache:")
    print(f"  - Cached: {stats['fingerprint_cache']['cached_fingerprints']}")
    print(f"  - Coverage: {stats['fingerprint_cache']['cache_coverage_pct']}%")
    print(f"  - Enabled: {stats['fingerprint_cache']['enabled']}")

    print(f"\nML QSAR model:")
    print(f"  - Available: {stats['ml_qsar_model']['available']}")
    print(f"  - Enabled: {stats['ml_qsar_model']['enabled']}")

    if stats['ml_qsar_model']['enabled']:
        print(f"  - Version: {stats['ml_qsar_model']['model_version']}")
        if 'training_stats' in stats['ml_qsar_model']:
            ts = stats['ml_qsar_model']['training_stats']
            print(f"  - Training MAE: {ts.get('regressor_mae', 'N/A')}")
            print(f"  - Accuracy: {ts.get('classifier_accuracy', 'N/A')}")

    print("\n✅ Service stats retrieved successfully")


def main():
    """Run all tests."""
    print("\n" + "=" * 70)
    print("ML QSAR Integration Test Suite")
    print("=" * 70)
    print("\nTesting integration of z05_models/bbb_qsar_model with")
    print("z07_data_access/bbb_prediction_service\n")

    # Test 1: Initialization
    service = test_ml_qsar_initialization()

    # Test 2: ML QSAR fallback
    test_ml_qsar_fallback(service)

    # Test 3: Comparison
    test_comparison_ml_vs_simple()

    # Test 4: Stats
    test_service_stats()

    print("\n" + "=" * 70)
    print("✅ All tests complete!")
    print("=" * 70)


if __name__ == "__main__":
    main()
