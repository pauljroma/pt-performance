#!/usr/bin/env python3
"""
Merge CNS-Focused Compounds with v3.0 Dataset
===============================================

Check CNS compounds against v3.0 dataset and create v3.1 if substantial new data.

Input:
- data/bbb/chembl_bbb_data_v3_0.csv (2,529 compounds)
- data/bbb/expansion_round2/cns_focused_compounds.csv (80 CNS drugs)

Output:
- data/bbb/chembl_bbb_data_v3_1.csv (if >30 new compounds)
- CNS overlap analysis

Date: 2025-12-01
"""

import sys
from pathlib import Path
import pandas as pd

print("=" * 70)
print("CNS Data Integration Analysis")
print("=" * 70)

# Add zones to path
zones_path = Path(__file__).parent.parent.parent.parent
sys.path.insert(0, str(zones_path))

try:
    from rdkit import Chem
    RDKIT_AVAILABLE = True
except ImportError:
    RDKIT_AVAILABLE = False

# Load datasets
v3_path = Path("/Users/expo/Code/expo/clients/quiver/data/bbb/chembl_bbb_data_v3_0.csv")
cns_path = Path("/Users/expo/Code/expo/clients/quiver/data/bbb/expansion_round2/cns_focused_compounds.csv")

print("\n📂 Loading datasets...")
df_v3 = pd.read_csv(v3_path)
df_cns = pd.read_csv(cns_path)

print(f"   v3.0 dataset: {len(df_v3)} compounds")
print(f"   CNS dataset: {len(df_cns)} compounds")

# Canonicalize SMILES for comparison
if RDKIT_AVAILABLE:
    print("\n🔬 Canonicalizing SMILES...")

    v3_canonical = set()
    for smiles in df_v3['smiles']:
        try:
            mol = Chem.MolFromSmiles(smiles)
            if mol:
                v3_canonical.add(Chem.MolToSmiles(mol))
        except:
            continue

    cns_canonical = {}
    for idx, row in df_cns.iterrows():
        try:
            mol = Chem.MolFromSmiles(row['smiles'])
            if mol:
                canonical = Chem.MolToSmiles(mol)
                cns_canonical[canonical] = row
        except:
            continue

    print(f"   v3.0 canonical SMILES: {len(v3_canonical)}")
    print(f"   CNS canonical SMILES: {len(cns_canonical)}")

    # Find overlaps and new compounds
    overlap = v3_canonical.intersection(set(cns_canonical.keys()))
    new_smiles = set(cns_canonical.keys()) - v3_canonical

    print(f"\n📊 Overlap Analysis:")
    print(f"   Already in v3.0: {len(overlap)} CNS drugs")
    print(f"   NEW CNS drugs: {len(new_smiles)}")
    print(f"   Novelty rate: {len(new_smiles) / len(cns_canonical) * 100:.1f}%")

    # Show which CNS drugs are new
    if new_smiles:
        print(f"\n🆕 New CNS Drugs ({len(new_smiles)}):")
        new_drugs = []
        for smiles in new_smiles:
            row = cns_canonical[smiles]
            new_drugs.append({
                'name': row.get('compound_name', 'Unknown'),
                'brand': row.get('brand_name', ''),
                'class': row.get('cns_class', ''),
                'log_bb': row.get('log_bb', 0.0),
                'smiles': smiles
            })

        # Sort by Log BB (highest first)
        new_drugs.sort(key=lambda x: x['log_bb'], reverse=True)

        for i, drug in enumerate(new_drugs[:20], 1):  # Show top 20
            print(f"   {i:2d}. {drug['name']:20s} ({drug['brand']:15s}) Log BB: {drug['log_bb']:+.2f} - {drug['class']}")

        if len(new_drugs) > 20:
            print(f"   ... and {len(new_drugs) - 20} more")

    # Show which common CNS drugs are already in v3.0
    if overlap:
        print(f"\n✅ CNS Drugs Already in v3.0 ({len(overlap)}):")
        existing_drugs = []
        for smiles in overlap:
            if smiles in cns_canonical:
                row = cns_canonical[smiles]
                existing_drugs.append({
                    'name': row.get('compound_name', 'Unknown'),
                    'brand': row.get('brand_name', ''),
                    'class': row.get('cns_class', ''),
                    'log_bb': row.get('log_bb', 0.0)
                })

        existing_drugs.sort(key=lambda x: x['log_bb'], reverse=True)

        for i, drug in enumerate(existing_drugs[:15], 1):  # Show top 15
            print(f"   {i:2d}. {drug['name']:20s} ({drug['brand']:15s}) Log BB: {drug['log_bb']:+.2f}")

        if len(existing_drugs) > 15:
            print(f"   ... and {len(existing_drugs) - 15} more")

    # Create v3.1 if substantial new data
    if len(new_smiles) >= 30:
        print(f"\n🎯 Creating v3.1 dataset with {len(new_smiles)} new CNS compounds...")

        # Get new compound rows
        new_rows = [cns_canonical[smiles] for smiles in new_smiles]
        df_new_cns = pd.DataFrame(new_rows)

        # Standardize schema to match v3.0
        required_cols = ['compound_id', 'smiles', 'mol_weight', 'log_bb', 'bbb_class', 'method', 'literature_doi', 'data_source']
        for col in required_cols:
            if col not in df_new_cns.columns:
                if col == 'method':
                    df_new_cns[col] = 'experimental_CNS_drug'
                elif col == 'literature_doi':
                    df_new_cns[col] = 'FDA_approved_CNS'
                else:
                    df_new_cns[col] = None

        # Combine with v3.0
        df_v3_1 = pd.concat([df_v3[required_cols], df_new_cns[required_cols]], ignore_index=True)

        # Save v3.1
        v3_1_path = Path("/Users/expo/Code/expo/clients/quiver/data/bbb/chembl_bbb_data_v3_1.csv")
        df_v3_1.to_csv(v3_1_path, index=False)

        print(f"   ✅ Saved v3.1: {v3_1_path}")
        print(f"   Total compounds: {len(df_v3_1)}")
        print(f"   Growth: {len(new_smiles)} new compounds (+{len(new_smiles)/len(df_v3)*100:.1f}%)")

        # Statistics
        print(f"\n📈 v3.1 Dataset Stats:")
        print(f"   BBB+: {len(df_v3_1[df_v3_1['bbb_class'] == 'BBB+'])}")
        print(f"   BBB-: {len(df_v3_1[df_v3_1['bbb_class'] == 'BBB-'])}")
        print(f"   Uncertain: {len(df_v3_1[df_v3_1['bbb_class'] == 'uncertain'])}")

    else:
        print(f"\n⚠️  Only {len(new_smiles)} new compounds - not creating v3.1")
        print(f"   (Threshold: 30+ new compounds for new version)")

else:
    print("\n⚠️  RDKit not available - cannot perform SMILES comparison")

print("\n" + "=" * 70)
print("Analysis Complete!")
print("=" * 70)
