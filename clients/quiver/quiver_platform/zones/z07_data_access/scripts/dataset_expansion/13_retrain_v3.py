#!/usr/bin/env python3
"""
ML Model v3.0 Retrainer
========================

Train BBB QSAR Model v3.0 on expanded v3.0 dataset.

Input: data/bbb/chembl_bbb_data_v3_0.csv (~2,529 compounds)

Output: z05_models/artifacts/bbb_qsar_v3_0.pkl

Performance Targets:
- MAE < 0.6 (vs v2.0: 0.674)
- Accuracy > 80% (vs v2.0: 77.1%)
- R² > 0.3 (vs v2.0: 0.245)

Agent: agent_9_retrain_v3
Zone: z07_data_access/scripts/dataset_expansion
Date: 2025-12-01
"""

import sys
import json
import time
from pathlib import Path
from typing import Dict, Any
import pandas as pd
import numpy as np
import pickle

print("=" * 70)
print("Agent 9: ML Model v3.0 Trainer")
print("=" * 70)

# Add zones to path
zones_path = Path(__file__).parent.parent.parent.parent
sys.path.insert(0, str(zones_path))

# SAP-60 FIX (2025-12-08): Disabled zone violation - z07_data_access cannot import from z05_models
print("⚠️  BBBQSARModel disabled due to zone violation (SAP-60)")
MODEL_AVAILABLE = False
# try:
#     from z05_models.bbb_qsar_model import BBBQSARModel
#     print("✅ BBBQSARModel available")
#     MODEL_AVAILABLE = True
# except ImportError as e:
#     print(f"⚠️  BBBQSARModel not available: {e}")
#     MODEL_AVAILABLE = False


def load_v3_dataset() -> str:
    """Load v3.0 dataset."""
    print("\n" + "=" * 70)
    print("Loading v3.0 Dataset")
    print("=" * 70)

    v3_path = Path("/Users/expo/Code/expo/clients/quiver/data/bbb/chembl_bbb_data_v3_0.csv")

    if not v3_path.exists():
        print(f"❌ v3.0 dataset not found: {v3_path}")
        sys.exit(1)

    df = pd.read_csv(v3_path)
    print(f"✅ Loaded v3.0 dataset: {len(df)} compounds")
    print(f"   BBB+: {len(df[df['bbb_class'] == 'BBB+'])}")
    print(f"   BBB-: {len(df[df['bbb_class'] == 'BBB-'])}")
    print(f"   Uncertain: {len(df[df['bbb_class'] == 'uncertain'])}")

    return str(v3_path)


def train_v3_model(data_path: str) -> Dict[str, Any]:
    """Train BBB QSAR v3.0 model."""
    print("\n" + "=" * 70)
    print("Training v3.0 Model")
    print("=" * 70)

    if not MODEL_AVAILABLE:
        print("❌ BBBQSARModel not available - cannot train")
        sys.exit(1)

    # Initialize model
    model = BBBQSARModel()

    # Train model
    print("\n🏋️  Training Random Forest models...")
    print("   - Regressor (Log BB prediction)")
    print("   - Classifier (BBB class prediction)")

    start_time = time.time()
    results = model.train(data_path, test_size=0.2)
    training_time = time.time() - start_time

    print(f"\n✅ Training complete in {training_time:.1f}s")

    # Print results
    print("\n" + "=" * 70)
    print("v3.0 Model Performance")
    print("=" * 70)
    print(f"Training samples: {results['n_training_samples']}")
    print(f"Test samples: {results['n_test_samples']}")
    print(f"\nRegression (Log BB):")
    print(f"  MAE: {results['regressor_mae']:.3f}")
    print(f"  R²: {results['regressor_r2']:.3f}")
    print(f"\nClassification (BBB class):")
    print(f"  Accuracy: {results['classifier_accuracy']:.1%}")
    print(f"\nCross-Validation:")
    print(f"  CV MAE: {results['regressor_cv_mae']:.3f}")

    # Save model
    zones_root = Path(__file__).parent.parent.parent.parent
    model_path = zones_root / "z05_models" / "artifacts" / "bbb_qsar_v3_0.pkl"
    model_path.parent.mkdir(parents=True, exist_ok=True)

    with open(model_path, 'wb') as f:
        pickle.dump(model, f)

    print(f"\n✅ Saved model: {model_path}")

    # Add model path to results
    results['model_path'] = str(model_path)
    results['training_time'] = training_time

    return results


def load_comparison_data() -> Dict[str, Dict[str, Any]]:
    """Load v1.0 and v2.0 model performance for comparison."""
    print("\n" + "=" * 70)
    print("Loading Historical Performance")
    print("=" * 70)

    comparison_path = Path("/Users/expo/Code/expo/clients/quiver/data/bbb/expansion/model_comparison.json")

    if comparison_path.exists():
        with open(comparison_path, 'r') as f:
            comparison = json.load(f)
        print("✅ Loaded v1.0 and v2.0 performance data")
        return comparison
    else:
        print("⚠️  Historical comparison data not found")
        return {
            'v1_0': {
                'mae': 1.400,
                'accuracy': 0.415,
                'r2': -0.067,
                'training_samples': 5197
            },
            'v2_0': {
                'mae': 0.674,
                'accuracy': 0.771,
                'r2': 0.245,
                'training_samples': 1938
            }
        }


def compare_models(v3_results: Dict[str, Any], historical: Dict[str, Dict[str, Any]]) -> Dict[str, Any]:
    """Compare v3.0 with v1.0 and v2.0 models."""
    print("\n" + "=" * 70)
    print("Model Comparison (v1.0 vs v2.0 vs v3.0)")
    print("=" * 70)

    v1_mae = historical.get('v1_0', {}).get('mae', 1.4)
    v2_mae = historical.get('v2_0', {}).get('mae', 0.674)
    v3_mae = v3_results['regressor_mae']

    v1_acc = historical.get('v1_0', {}).get('accuracy', 0.415)
    v2_acc = historical.get('v2_0', {}).get('accuracy', 0.771)
    v3_acc = v3_results['classifier_accuracy']

    v1_r2 = historical.get('v1_0', {}).get('r2', -0.067)
    v2_r2 = historical.get('v2_0', {}).get('r2', 0.245)
    v3_r2 = v3_results['regressor_r2']

    print("\nMAE (Mean Absolute Error):")
    print(f"  v1.0: {v1_mae:.3f}")
    print(f"  v2.0: {v2_mae:.3f}")
    print(f"  v3.0: {v3_mae:.3f}")
    print(f"  v3.0 vs v2.0: {(v3_mae - v2_mae) / v2_mae * 100:+.1f}% change")

    print("\nAccuracy:")
    print(f"  v1.0: {v1_acc:.1%}")
    print(f"  v2.0: {v2_acc:.1%}")
    print(f"  v3.0: {v3_acc:.1%}")
    print(f"  v3.0 vs v2.0: {(v3_acc - v2_acc) / v2_acc * 100:+.1f}% change")

    print("\nR² Score:")
    print(f"  v1.0: {v1_r2:.3f}")
    print(f"  v2.0: {v2_r2:.3f}")
    print(f"  v3.0: {v3_r2:.3f}")
    print(f"  v3.0 vs v2.0: {v3_r2 - v2_r2:+.3f} change")

    print("\nTraining Samples:")
    print(f"  v1.0: {historical.get('v1_0', {}).get('training_samples', 5197)}")
    print(f"  v2.0: {historical.get('v2_0', {}).get('training_samples', 1938)}")
    print(f"  v3.0: {v3_results['n_training_samples']}")

    # Determine improvements
    mae_improved = v3_mae < v2_mae
    acc_improved = v3_acc > v2_acc
    r2_improved = v3_r2 > v2_r2

    comparison = {
        'v3_0': {
            'mae': v3_mae,
            'accuracy': v3_acc,
            'r2': v3_r2,
            'training_samples': v3_results['n_training_samples']
        },
        'improvements_vs_v2': {
            'mae_change_pct': (v3_mae - v2_mae) / v2_mae * 100,
            'accuracy_change_pct': (v3_acc - v2_acc) / v2_acc * 100,
            'r2_change': v3_r2 - v2_r2,
            'mae_improved': mae_improved,
            'accuracy_improved': acc_improved,
            'r2_improved': r2_improved
        },
        'v2_0': {
            'mae': v2_mae,
            'accuracy': v2_acc,
            'r2': v2_r2,
            'training_samples': historical.get('v2_0', {}).get('training_samples', 1938)
        },
        'v1_0': {
            'mae': v1_mae,
            'accuracy': v1_acc,
            'r2': v1_r2,
            'training_samples': historical.get('v1_0', {}).get('training_samples', 5197)
        }
    }

    # Print improvement summary
    print("\n" + "=" * 70)
    print("v3.0 Performance Assessment")
    print("=" * 70)

    if mae_improved:
        print(f"✅ MAE improved by {abs(comparison['improvements_vs_v2']['mae_change_pct']):.1f}%")
    else:
        print(f"⚠️  MAE regressed by {abs(comparison['improvements_vs_v2']['mae_change_pct']):.1f}%")

    if acc_improved:
        print(f"✅ Accuracy improved by {comparison['improvements_vs_v2']['accuracy_change_pct']:.1f}%")
    else:
        print(f"⚠️  Accuracy regressed by {abs(comparison['improvements_vs_v2']['accuracy_change_pct']):.1f}%")

    if r2_improved:
        print(f"✅ R² improved by {comparison['improvements_vs_v2']['r2_change']:.3f}")
    else:
        print(f"⚠️  R² regressed by {abs(comparison['improvements_vs_v2']['r2_change']):.3f}")

    # Overall grade
    improvements = sum([mae_improved, acc_improved, r2_improved])
    if improvements == 3:
        grade = "A+ (All metrics improved!)"
    elif improvements == 2:
        grade = "A (2 of 3 metrics improved)"
    elif improvements == 1:
        grade = "B (1 of 3 metrics improved)"
    else:
        grade = "C (No improvements)"

    print(f"\n🎯 Overall Grade: {grade}")

    return comparison


def main():
    """Main execution."""
    output_dir = Path("/Users/expo/Code/expo/clients/quiver/data/bbb/expansion_round2")
    output_dir.mkdir(parents=True, exist_ok=True)

    # Load v3.0 dataset
    v3_data_path = load_v3_dataset()

    # Train v3.0 model
    v3_results = train_v3_model(v3_data_path)

    # Load historical performance
    historical = load_comparison_data()

    # Compare models
    comparison = compare_models(v3_results, historical)

    # Save comparison
    comparison_file = output_dir / 'model_comparison_v3.json'
    with open(comparison_file, 'w') as f:
        json.dump(comparison, f, indent=2)
    print(f"\n✅ Saved model comparison: {comparison_file}")

    # Generate final report
    print("\n" + "=" * 70)
    print("Round 2 Expansion Complete!")
    print("=" * 70)
    print(f"Dataset: {v3_results['n_training_samples'] + v3_results['n_test_samples']} compounds")
    print(f"Model: BBB QSAR v3.0")
    print(f"MAE: {v3_results['regressor_mae']:.3f}")
    print(f"Accuracy: {v3_results['classifier_accuracy']:.1%}")
    print(f"R²: {v3_results['regressor_r2']:.3f}")
    print("=" * 70)

    print("\n✅ Agent 9 (Model v3.0 Retraining) Complete!")

    return 0


if __name__ == "__main__":
    sys.exit(main())
