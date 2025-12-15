#!/usr/bin/env python3
"""
ML Model Retrainer
===================

Retrains BBB QSAR ML model on expanded dataset.

Input: data/bbb/chembl_bbb_data_v2_0.csv
Output: z05_models/artifacts/bbb_qsar_v2_0.pkl

Zone: z05_models
Agent: agent_5_retrain
Date: 2025-12-01
"""

import sys
import json
from pathlib import Path

# Add zones to path
zones_path = Path(__file__).parent.parent.parent.parent
sys.path.insert(0, str(zones_path))

# SAP-60 FIX (2025-12-08): Disabled zone violation - z07_data_access cannot import from z05_models
# This script should be moved to z05_models or refactored to use allowed zones
# from z05_models.bbb_qsar_model import BBBQSARModel
print("ERROR: This script has zone violations and needs refactoring. See SAP-60.")
sys.exit(1)


def main():
    """Retrain ML model on expanded dataset."""
    print("\n" + "=" * 70)
    print("Agent 5: ML Model Retrainer")
    print("=" * 70)

    # Paths
    data_path = "/Users/expo/Code/expo/clients/quiver/data/bbb/chembl_bbb_data_v2_0.csv"
    zones_root = Path(__file__).parent.parent.parent.parent
    model_v1_path = zones_root / "z05_models" / "artifacts" / "bbb_qsar_v1_0.pkl"
    model_v2_path = zones_root / "z05_models" / "artifacts" / "bbb_qsar_v2_0.pkl"
    report_path = zones_root / "z05_models" / "BBB_QSAR_ML_MODEL_REPORT_v2_0.md"

    # Check if data exists
    if not Path(data_path).exists():
        print(f"❌ Expanded dataset not found: {data_path}")
        return 1

    # Initialize new model
    print("\n1. Initializing BBB QSAR Model v2.0...")
    model_v2 = BBBQSARModel()

    # Train on expanded dataset
    print("\n2. Training model on expanded dataset...")
    print(f"   Data: {data_path}")

    try:
        stats_v2 = model_v2.train(data_path, test_size=0.2, random_state=42)

        print("\n3. Training Results (v2.0):")
        print(f"   Training samples: {stats_v2['n_training_samples']}")
        print(f"   Test samples: {stats_v2['n_test_samples']}")
        print(f"\n   Regressor (Log BB):")
        print(f"   - MAE: {stats_v2['regressor_mae']:.3f}")
        print(f"   - R²: {stats_v2['regressor_r2']:.3f}")
        print(f"   - CV MAE: {stats_v2['regressor_cv_mae']:.3f}")
        print(f"\n   Classifier (BBB Class):")
        print(f"   - Accuracy: {stats_v2['classifier_accuracy']:.1%}")

    except Exception as e:
        print(f"❌ Training failed: {e}")
        import traceback
        traceback.print_exc()
        return 1

    # Load v1.0 model for comparison
    print("\n4. Loading v1.0 model for comparison...")
    try:
        model_v1 = BBBQSARModel.load(str(model_v1_path))
        stats_v1 = model_v1.training_stats

        print("   ✅ Loaded v1.0 model")

        # Compare performance
        print("\n5. Performance Comparison:")
        print(f"\n   {'Metric':<20} {'v1.0':<15} {'v2.0':<15} {'Change':<15}")
        print(f"   {'-'*20} {'-'*15} {'-'*15} {'-'*15}")

        mae_v1 = stats_v1.get('regressor_mae', 0)
        mae_v2 = stats_v2['regressor_mae']
        mae_change = ((mae_v2 - mae_v1) / mae_v1 * 100) if mae_v1 > 0 else 0

        acc_v1 = stats_v1.get('classifier_accuracy', 0)
        acc_v2 = stats_v2['classifier_accuracy']
        acc_change = ((acc_v2 - acc_v1) / acc_v1 * 100) if acc_v1 > 0 else 0

        r2_v1 = stats_v1.get('regressor_r2', 0)
        r2_v2 = stats_v2['regressor_r2']

        print(f"   {'MAE':<20} {mae_v1:<15.3f} {mae_v2:<15.3f} {mae_change:+.1f}%")
        print(f"   {'Accuracy':<20} {acc_v1:<15.1%} {acc_v2:<15.1%} {acc_change:+.1f}%")
        print(f"   {'R²':<20} {r2_v1:<15.3f} {r2_v2:<15.3f}")
        print(f"   {'Training samples':<20} {stats_v1.get('n_training_samples', 0):<15} {stats_v2['n_training_samples']:<15}")

        comparison = {
            'v1_0': {
                'mae': mae_v1,
                'accuracy': acc_v1,
                'r2': r2_v1,
                'training_samples': stats_v1.get('n_training_samples', 0)
            },
            'v2_0': {
                'mae': mae_v2,
                'accuracy': acc_v2,
                'r2': r2_v2,
                'training_samples': stats_v2['n_training_samples']
            },
            'improvements': {
                'mae_change_pct': mae_change,
                'accuracy_change_pct': acc_change,
                'mae_improved': mae_v2 < mae_v1,
                'accuracy_improved': acc_v2 > acc_v1,
                'r2_improved': r2_v2 > r2_v1
            }
        }

    except Exception as e:
        print(f"   ⚠️  Could not load v1.0 model: {e}")
        comparison = None

    # Save v2.0 model
    print(f"\n6. Saving v2.0 model to {model_v2_path}...")
    model_v2_path.parent.mkdir(exist_ok=True)
    model_v2.save(str(model_v2_path))
    print("   ✅ Model saved")

    # Generate report
    print(f"\n7. Generating report to {report_path}...")
    with open(report_path, 'w') as f:
        f.write("# BBB QSAR ML Model Training Report v2.0\n\n")
        f.write(f"**Date:** 2025-12-01\n")
        f.write(f"**Model Version:** 2.0.0\n")
        f.write(f"**Dataset:** chembl_bbb_data_v2_0.csv\n")
        f.write(f"**Zone:** z05_models\n\n")

        f.write("## Training Results (v2.0)\n\n")
        f.write(f"- **Training samples:** {stats_v2['n_training_samples']}\n")
        f.write(f"- **Test samples:** {stats_v2['n_test_samples']}\n\n")

        f.write("### Regressor (Log BB Prediction)\n\n")
        f.write(f"- **MAE:** {stats_v2['regressor_mae']:.3f}\n")
        f.write(f"- **R²:** {stats_v2['regressor_r2']:.3f}\n")
        f.write(f"- **Cross-validation MAE:** {stats_v2['regressor_cv_mae']:.3f}\n\n")

        f.write("### Classifier (BBB Class Prediction)\n\n")
        f.write(f"- **Accuracy:** {stats_v2['classifier_accuracy']:.1%}\n\n")

        if comparison:
            f.write("## Performance Comparison\n\n")
            f.write(f"| Metric | v1.0 | v2.0 | Change |\n")
            f.write(f"|--------|------|------|--------|\n")
            f.write(f"| MAE | {comparison['v1_0']['mae']:.3f} | {comparison['v2_0']['mae']:.3f} | {comparison['improvements']['mae_change_pct']:+.1f}% |\n")
            f.write(f"| Accuracy | {comparison['v1_0']['accuracy']:.1%} | {comparison['v2_0']['accuracy']:.1%} | {comparison['improvements']['accuracy_change_pct']:+.1f}% |\n")
            f.write(f"| R² | {comparison['v1_0']['r2']:.3f} | {comparison['v2_0']['r2']:.3f} | {'✅' if comparison['improvements']['r2_improved'] else '⚠️'} |\n")
            f.write(f"| Training Samples | {comparison['v1_0']['training_samples']} | {comparison['v2_0']['training_samples']} | +{comparison['v2_0']['training_samples'] - comparison['v1_0']['training_samples']} |\n\n")

            f.write("### Key Improvements\n\n")
            if comparison['improvements']['mae_improved']:
                f.write(f"- ✅ MAE improved by {abs(comparison['improvements']['mae_change_pct']):.1f}%\n")
            else:
                f.write(f"- ⚠️  MAE decreased by {abs(comparison['improvements']['mae_change_pct']):.1f}%\n")

            if comparison['improvements']['accuracy_improved']:
                f.write(f"- ✅ Accuracy improved by {abs(comparison['improvements']['accuracy_change_pct']):.1f}%\n")
            else:
                f.write(f"- ⚠️  Accuracy decreased by {abs(comparison['improvements']['accuracy_change_pct']):.1f}%\n")

            if comparison['improvements']['r2_improved']:
                f.write(f"- ✅ R² improved (better correlation)\n")

        f.write("\n### Feature Importance\n\n")
        for feature, importance in sorted(
            stats_v2['feature_importance'].items(),
            key=lambda x: x[1],
            reverse=True
        ):
            f.write(f"- **{feature}:** {importance:.3f}\n")

        f.write(f"\n**Model saved to:** `{model_v2_path}`\n")

    print("   ✅ Report generated")

    # Save comparison JSON
    if comparison:
        comparison_path = Path("/Users/expo/Code/expo/clients/quiver/data/bbb/expansion/model_comparison.json")
        with open(comparison_path, 'w') as f:
            json.dump(comparison, indent=2, fp=f)
        print(f"\n   ✅ Comparison saved to {comparison_path}")

    print("\n" + "=" * 70)
    print("✅ Agent 5 (Retrain Model) Complete!")
    print("=" * 70)

    return 0


if __name__ == "__main__":
    sys.exit(main())
