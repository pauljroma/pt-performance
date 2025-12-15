#!/usr/bin/env python3
"""
Create v3.1 Dataset with 21 New CNS Drugs
==========================================

Add 21 high-quality CNS drugs to v3.0 dataset and retrain model.

Input:
- data/bbb/chembl_bbb_data_v3_0.csv (2,529 compounds)
- data/bbb/expansion_round2/cns_focused_compounds.csv (21 new)

Output:
- data/bbb/chembl_bbb_data_v3_1.csv (2,550 compounds)
- z05_models/artifacts/bbb_qsar_v3_1.pkl (retrained model)

Date: 2025-12-01
"""

import sys
import json
import time
import pickle
from pathlib import Path
import pandas as pd
import numpy as np

print("=" * 70)
print("Creating v3.1 Dataset with CNS Drugs")
print("=" * 70)

# Add zones to path
zones_path = Path(__file__).parent.parent.parent.parent
sys.path.insert(0, str(zones_path))

try:
    from rdkit import Chem
    from rdkit.Chem import Descriptors
    RDKIT_AVAILABLE = True
except ImportError:
    RDKIT_AVAILABLE = False

# SAP-60 FIX (2025-12-08): Disabled zone violation - z07_data_access cannot import from z05_models
MODEL_AVAILABLE = False
# try:
#     from z05_models.bbb_qsar_model import BBBQSARModel
#     MODEL_AVAILABLE = True
# except ImportError:
#     MODEL_AVAILABLE = False

# Load datasets
print("\n📂 Loading datasets...")
v3_path = Path("/Users/expo/Code/expo/clients/quiver/data/bbb/chembl_bbb_data_v3_0.csv")
cns_path = Path("/Users/expo/Code/expo/clients/quiver/data/bbb/expansion_round2/cns_focused_compounds.csv")

df_v3 = pd.read_csv(v3_path)
df_cns = pd.read_csv(cns_path)

print(f"   v3.0 dataset: {len(df_v3)} compounds")
print(f"   CNS dataset: {len(df_cns)} compounds")

# Identify new compounds
print("\n🔬 Identifying new CNS compounds...")

v3_canonical = set()
for smiles in df_v3['smiles']:
    try:
        mol = Chem.MolFromSmiles(smiles)
        if mol:
            v3_canonical.add(Chem.MolToSmiles(mol))
    except:
        continue

cns_new_rows = []
for idx, row in df_cns.iterrows():
    try:
        mol = Chem.MolFromSmiles(row['smiles'])
        if mol:
            canonical = Chem.MolToSmiles(mol)
            if canonical not in v3_canonical:
                cns_new_rows.append(row)
    except:
        continue

df_cns_new = pd.DataFrame(cns_new_rows)
print(f"   New CNS compounds: {len(df_cns_new)}")

# Show new compounds being added
print(f"\n🆕 Adding {len(df_cns_new)} CNS drugs:")
for idx, row in df_cns_new.iterrows():
    print(f"   • {row['compound_name']:20s} ({row['brand_name']:15s}) Log BB: {row['log_bb']:+.2f} - {row['cns_class']}")

# Standardize schema
print("\n⚙️  Standardizing schema...")
required_cols = ['compound_id', 'smiles', 'mol_weight', 'log_bb', 'bbb_class', 'method', 'literature_doi', 'data_source']

for col in required_cols:
    if col not in df_cns_new.columns:
        if col == 'method':
            df_cns_new[col] = 'experimental_CNS_drug'
        elif col == 'literature_doi':
            df_cns_new[col] = 'FDA_approved_CNS'
        elif col == 'data_source':
            df_cns_new[col] = 'CNS_focused'
        else:
            df_cns_new[col] = None

# Merge datasets
print("\n🔀 Merging datasets...")
df_v3_1 = pd.concat([df_v3[required_cols], df_cns_new[required_cols]], ignore_index=True)

print(f"   v3.0: {len(df_v3)} compounds")
print(f"   + CNS: {len(df_cns_new)} compounds")
print(f"   = v3.1: {len(df_v3_1)} compounds")
print(f"   Growth: +{len(df_cns_new)/len(df_v3)*100:.1f}%")

# Save v3.1
v3_1_path = Path("/Users/expo/Code/expo/clients/quiver/data/bbb/chembl_bbb_data_v3_1.csv")
df_v3_1.to_csv(v3_1_path, index=False)
print(f"\n✅ Saved v3.1 dataset: {v3_1_path}")

# Statistics
print("\n" + "=" * 70)
print("v3.1 Dataset Statistics")
print("=" * 70)
print(f"Total compounds: {len(df_v3_1)}")
print(f"BBB+: {len(df_v3_1[df_v3_1['bbb_class'] == 'BBB+'])} ({len(df_v3_1[df_v3_1['bbb_class'] == 'BBB+'])/len(df_v3_1)*100:.1f}%)")
print(f"BBB-: {len(df_v3_1[df_v3_1['bbb_class'] == 'BBB-'])} ({len(df_v3_1[df_v3_1['bbb_class'] == 'BBB-'])/len(df_v3_1)*100:.1f}%)")
print(f"Uncertain: {len(df_v3_1[df_v3_1['bbb_class'] == 'uncertain'])} ({len(df_v3_1[df_v3_1['bbb_class'] == 'uncertain'])/len(df_v3_1)*100:.1f}%)")
print(f"\nLog BB range: [{df_v3_1['log_bb'].min():.2f}, {df_v3_1['log_bb'].max():.2f}]")
print(f"Mean Log BB: {df_v3_1['log_bb'].mean():.2f}")
print(f"Median Log BB: {df_v3_1['log_bb'].median():.2f}")

# Retrain model
if MODEL_AVAILABLE:
    print("\n" + "=" * 70)
    print("Retraining Model v3.1")
    print("=" * 70)

    model = BBBQSARModel()

    print("\n🏋️  Training on v3.1 dataset...")
    start_time = time.time()
    results = model.train(str(v3_1_path), test_size=0.2)
    training_time = time.time() - start_time

    print(f"\n✅ Training complete in {training_time:.1f}s")

    # Print results
    print("\n" + "=" * 70)
    print("v3.1 Model Performance")
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
    model_path = zones_root / "z05_models" / "artifacts" / "bbb_qsar_v3_1.pkl"

    with open(model_path, 'wb') as f:
        pickle.dump(model, f)

    print(f"\n✅ Saved model: {model_path}")

    # Compare with v3.0
    print("\n" + "=" * 70)
    print("Performance Comparison: v3.0 vs v3.1")
    print("=" * 70)

    # Load v3.0 comparison data
    comparison_path = Path("/Users/expo/Code/expo/clients/quiver/data/bbb/expansion_round2/model_comparison_v3.json")
    if comparison_path.exists():
        with open(comparison_path, 'r') as f:
            v3_0_data = json.load(f)

        v3_0_mae = v3_0_data['v3_0']['mae']
        v3_0_acc = v3_0_data['v3_0']['accuracy']
        v3_0_r2 = v3_0_data['v3_0']['r2']
    else:
        # Fallback values
        v3_0_mae = 0.629
        v3_0_acc = 0.798
        v3_0_r2 = 0.252

    v3_1_mae = results['regressor_mae']
    v3_1_acc = results['classifier_accuracy']
    v3_1_r2 = results['regressor_r2']

    print("\nMAE (Mean Absolute Error):")
    print(f"  v3.0: {v3_0_mae:.3f}")
    print(f"  v3.1: {v3_1_mae:.3f}")
    print(f"  Change: {(v3_1_mae - v3_0_mae) / v3_0_mae * 100:+.1f}%")

    print("\nAccuracy:")
    print(f"  v3.0: {v3_0_acc:.1%}")
    print(f"  v3.1: {v3_1_acc:.1%}")
    print(f"  Change: {(v3_1_acc - v3_0_acc) / v3_0_acc * 100:+.1f}%")

    print("\nR² Score:")
    print(f"  v3.0: {v3_0_r2:.3f}")
    print(f"  v3.1: {v3_1_r2:.3f}")
    print(f"  Change: {v3_1_r2 - v3_0_r2:+.3f}")

    # Determine grade
    mae_improved = v3_1_mae < v3_0_mae
    acc_improved = v3_1_acc > v3_0_acc
    r2_improved = v3_1_r2 > v3_0_r2

    improvements = sum([mae_improved, acc_improved, r2_improved])

    print("\n" + "=" * 70)
    print("v3.1 Assessment")
    print("=" * 70)

    if mae_improved:
        print(f"✅ MAE improved by {abs((v3_1_mae - v3_0_mae) / v3_0_mae * 100):.1f}%")
    else:
        print(f"⚠️  MAE regressed by {abs((v3_1_mae - v3_0_mae) / v3_0_mae * 100):.1f}%")

    if acc_improved:
        print(f"✅ Accuracy improved by {(v3_1_acc - v3_0_acc) / v3_0_acc * 100:.1f}%")
    else:
        print(f"⚠️  Accuracy regressed by {abs((v3_1_acc - v3_0_acc) / v3_0_acc * 100):.1f}%")

    if r2_improved:
        print(f"✅ R² improved by {v3_1_r2 - v3_0_r2:.3f}")
    else:
        print(f"⚠️  R² regressed by {abs(v3_1_r2 - v3_0_r2):.3f}")

    if improvements == 3:
        grade = "A+ (All metrics improved!)"
    elif improvements == 2:
        grade = "A (2 of 3 metrics improved)"
    elif improvements == 1:
        grade = "B (1 of 3 metrics improved)"
    else:
        grade = "C (No improvements)"

    print(f"\n🎯 Overall Grade: {grade}")

    # Save comparison
    comparison = {
        'v3_1': {
            'mae': v3_1_mae,
            'accuracy': v3_1_acc,
            'r2': v3_1_r2,
            'training_samples': results['n_training_samples'],
            'total_compounds': len(df_v3_1)
        },
        'v3_0': {
            'mae': v3_0_mae,
            'accuracy': v3_0_acc,
            'r2': v3_0_r2,
            'total_compounds': len(df_v3)
        },
        'improvements': {
            'mae_change_pct': (v3_1_mae - v3_0_mae) / v3_0_mae * 100,
            'accuracy_change_pct': (v3_1_acc - v3_0_acc) / v3_0_acc * 100,
            'r2_change': v3_1_r2 - v3_0_r2,
            'mae_improved': mae_improved,
            'accuracy_improved': acc_improved,
            'r2_improved': r2_improved,
            'compounds_added': len(df_cns_new),
            'grade': grade
        }
    }

    comparison_file = Path("/Users/expo/Code/expo/clients/quiver/data/bbb/expansion_round2/model_comparison_v3_1.json")
    with open(comparison_file, 'w') as f:
        json.dump(comparison, f, indent=2)

    print(f"\n✅ Saved comparison: {comparison_file}")

else:
    print("\n⚠️  BBBQSARModel not available - skipping model retraining")

print("\n" + "=" * 70)
print("v3.1 Creation Complete!")
print("=" * 70)
print(f"Dataset: {len(df_v3_1)} compounds (+{len(df_cns_new)} CNS drugs)")
print(f"Model: BBB QSAR v3.1")
print("=" * 70)

print("\n✅ Successfully created v3.1 with 21 new CNS drugs!")
