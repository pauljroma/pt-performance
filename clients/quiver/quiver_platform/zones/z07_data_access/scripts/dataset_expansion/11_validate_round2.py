#!/usr/bin/env python3
"""
Round 2 Data Validator
=======================

Validate all Round 2 BBB dataset expansion data before merging.

Validation checks:
1. SMILES validation (RDKit parsing)
2. Log BB range (-5.0 to +2.0)
3. BBB class consistency
4. Molecular weight (50-1000 Da)
5. Duplicate detection (canonicalize SMILES)
6. Cross-reference with v2.0 dataset

Output: Validated, deduplicated compounds ready for merge

Agent: agent_7_validation
Zone: z07_data_access/scripts/dataset_expansion
Date: 2025-12-01
"""

import sys
import json
from pathlib import Path
from typing import List, Dict, Any
import pandas as pd
import numpy as np

print("=" * 70)
print("Agent 7: Round 2 Data Validator")
print("=" * 70)

# Add zones to path
zones_path = Path(__file__).parent.parent.parent.parent
sys.path.insert(0, str(zones_path))

try:
    from rdkit import Chem
    from rdkit.Chem import Descriptors
    RDKIT_AVAILABLE = True
    print("✅ RDKit available")
except ImportError:
    print("⚠️  RDKit not available - validation will be limited")
    RDKIT_AVAILABLE = False


def load_round2_datasets() -> List[pd.DataFrame]:
    """Load all Round 2 expansion datasets."""
    print("\n" + "=" * 70)
    print("Loading Round 2 Datasets")
    print("=" * 70)

    data_dir = Path("/Users/expo/Code/expo/clients/quiver/data/bbb/expansion_round2")
    datasets = []
    file_info = []

    # Expected files from Round 2 agents
    files = [
        'chembl_deep_dive.csv',
        'pubchem_bioassays.csv',
        'admetlab_compounds.csv',
        'swissadme_compounds.csv',
        'ochem_compounds.csv',
        'targetmol_cns.csv',
        'literature_compounds.csv'
    ]

    for filename in files:
        filepath = data_dir / filename
        if filepath.exists():
            df = pd.read_csv(filepath)
            datasets.append(df)
            file_info.append({
                'file': filename,
                'compounds': len(df),
                'source': df['data_source'].iloc[0] if 'data_source' in df.columns else 'unknown'
            })
            print(f"✅ Loaded {filename}: {len(df)} compounds")
        else:
            print(f"⚠️  Not found: {filename}")

    print(f"\n✅ Loaded {len(datasets)} datasets")
    print(f"   Total compounds: {sum(len(df) for df in datasets)}")

    return datasets


def validate_smiles(df: pd.DataFrame) -> pd.DataFrame:
    """Validate and canonicalize SMILES."""
    print("\n" + "=" * 70)
    print("Validating SMILES")
    print("=" * 70)

    if not RDKIT_AVAILABLE:
        print("⚠️  RDKit not available - skipping SMILES validation")
        return df

    valid_rows = []
    invalid_count = 0

    for idx, row in df.iterrows():
        smiles = row.get('smiles', '')

        if not smiles or pd.isna(smiles):
            invalid_count += 1
            continue

        # Try to parse SMILES
        mol = Chem.MolFromSmiles(smiles)

        if mol is None:
            invalid_count += 1
            print(f"   ⚠️  Invalid SMILES: {smiles[:50]}")
            continue

        # Canonicalize
        canonical_smiles = Chem.MolToSmiles(mol)

        # Update row with canonical SMILES
        row_dict = row.to_dict()
        row_dict['smiles'] = canonical_smiles

        # Recalculate mol weight if needed
        if 'mol_weight' not in row_dict or row_dict['mol_weight'] == 0:
            row_dict['mol_weight'] = Descriptors.MolWt(mol)

        valid_rows.append(row_dict)

    df_valid = pd.DataFrame(valid_rows)

    print(f"✅ Valid SMILES: {len(df_valid)}")
    print(f"❌ Invalid SMILES: {invalid_count}")
    print(f"   Validation rate: {len(df_valid) / (len(df_valid) + invalid_count) * 100:.1f}%")

    return df_valid


def validate_log_bb(df: pd.DataFrame) -> pd.DataFrame:
    """Validate Log BB values are in reasonable range."""
    print("\n" + "=" * 70)
    print("Validating Log BB Values")
    print("=" * 70)

    # Typical Log BB range: -5.0 to +2.0
    # Extreme outliers indicate data errors
    min_log_bb = -5.0
    max_log_bb = 2.0

    before = len(df)
    df = df[(df['log_bb'] >= min_log_bb) & (df['log_bb'] <= max_log_bb)].copy()
    after = len(df)

    removed = before - after

    print(f"✅ Valid Log BB range [{min_log_bb}, {max_log_bb}]: {after}")
    print(f"❌ Out of range: {removed}")

    return df


def validate_bbb_class_consistency(df: pd.DataFrame) -> pd.DataFrame:
    """Validate BBB class matches Log BB value."""
    print("\n" + "=" * 70)
    print("Validating BBB Class Consistency")
    print("=" * 70)

    inconsistencies = 0
    fixed = 0

    for idx, row in df.iterrows():
        log_bb = row['log_bb']
        bbb_class = row['bbb_class']

        # Expected classification:
        # BBB+ : Log BB > -1.0
        # BBB- : Log BB < -2.0
        # uncertain: -2.0 <= Log BB <= -1.0

        if log_bb > -1.0:
            expected = 'BBB+'
        elif log_bb < -2.0:
            expected = 'BBB-'
        else:
            expected = 'uncertain'

        if bbb_class != expected:
            inconsistencies += 1
            df.at[idx, 'bbb_class'] = expected
            fixed += 1

    print(f"⚠️  Inconsistencies found: {inconsistencies}")
    print(f"✅ Fixed: {fixed}")

    return df


def validate_molecular_weight(df: pd.DataFrame) -> pd.DataFrame:
    """Validate molecular weight is in reasonable range."""
    print("\n" + "=" * 70)
    print("Validating Molecular Weight")
    print("=" * 70)

    # Typical drug-like range: 50-1000 Da
    # Very small or very large molecules are unusual
    min_mw = 50
    max_mw = 1000

    before = len(df)

    # Only filter if mol_weight is available
    if 'mol_weight' in df.columns:
        df = df[(df['mol_weight'] >= min_mw) & (df['mol_weight'] <= max_mw)].copy()
    else:
        print("⚠️  No molecular weight column - skipping MW validation")

    after = len(df)
    removed = before - after

    print(f"✅ Valid MW range [{min_mw}, {max_mw} Da]: {after}")
    print(f"❌ Out of range: {removed}")

    return df


def remove_duplicates(df: pd.DataFrame) -> pd.DataFrame:
    """Remove duplicate compounds by SMILES."""
    print("\n" + "=" * 70)
    print("Removing Duplicates")
    print("=" * 70)

    before = len(df)

    # Remove exact duplicates by SMILES
    df = df.drop_duplicates(subset=['smiles'], keep='first')

    after = len(df)
    removed = before - after

    print(f"✅ Unique compounds: {after}")
    print(f"❌ Duplicates removed: {removed}")
    print(f"   Duplicate rate: {removed / before * 100:.1f}%")

    return df


def cross_reference_v2_dataset(df: pd.DataFrame) -> Dict[str, Any]:
    """Cross-reference with v2.0 dataset to identify overlaps."""
    print("\n" + "=" * 70)
    print("Cross-Referencing with v2.0 Dataset")
    print("=" * 70)

    v2_path = Path("/Users/expo/Code/expo/clients/quiver/data/bbb/chembl_bbb_data_v2_0.csv")

    if not v2_path.exists():
        print("⚠️  v2.0 dataset not found - skipping cross-reference")
        return {'overlap_count': 0, 'new_compounds': len(df)}

    df_v2 = pd.read_csv(v2_path)
    print(f"   v2.0 dataset: {len(df_v2)} compounds")

    # Canonicalize v2 SMILES if needed
    if RDKIT_AVAILABLE and 'smiles' in df_v2.columns:
        v2_smiles_set = set()
        for smiles in df_v2['smiles']:
            try:
                mol = Chem.MolFromSmiles(smiles)
                if mol:
                    canonical = Chem.MolToSmiles(mol)
                    v2_smiles_set.add(canonical)
            except:
                continue
    else:
        v2_smiles_set = set(df_v2['smiles'].dropna())

    # Count overlaps
    round2_smiles_set = set(df['smiles'])
    overlap = round2_smiles_set.intersection(v2_smiles_set)

    print(f"   Round 2 unique SMILES: {len(round2_smiles_set)}")
    print(f"   Overlap with v2.0: {len(overlap)}")
    print(f"   New compounds: {len(round2_smiles_set) - len(overlap)}")

    return {
        'overlap_count': len(overlap),
        'new_compounds': len(round2_smiles_set) - len(overlap),
        'overlap_rate': len(overlap) / len(round2_smiles_set) * 100 if round2_smiles_set else 0
    }


def generate_quality_scores(df: pd.DataFrame) -> pd.DataFrame:
    """Assign quality scores based on data source and method."""
    print("\n" + "=" * 70)
    print("Assigning Quality Scores")
    print("=" * 70)

    # Quality ranking:
    # 1. Experimental > Assay surrogate > QSAR prediction
    # 2. Literature validated (DOI) > Database
    # 3. Multiple sources = higher confidence

    quality_map = {
        # Experimental data (highest quality)
        'experimental': 5,
        'experimental_CNS_activity': 5,
        # Assay surrogates (medium-high quality)
        'ChEMBL_assay': 4,
        'PubChem_BioAssay': 4,
        # QSAR predictions (medium quality)
        'predicted_SwissADME': 3,
        # Sample/fallback data (lower quality)
        'sample': 2
    }

    df['quality_score'] = df['method'].apply(
        lambda x: quality_map.get(x, 3)  # Default: medium quality
    )

    print(f"✅ Quality scores assigned")
    print(f"   Quality distribution:")
    print(df['quality_score'].value_counts().sort_index(ascending=False))

    return df


def main():
    """Main validation execution."""
    output_dir = Path("/Users/expo/Code/expo/clients/quiver/data/bbb/expansion_round2")
    output_dir.mkdir(parents=True, exist_ok=True)

    # Load all Round 2 datasets
    datasets = load_round2_datasets()

    if not datasets:
        print("\n❌ No Round 2 datasets found!")
        return 1

    # Combine all datasets
    print("\n" + "=" * 70)
    print("Combining Datasets")
    print("=" * 70)

    df_combined = pd.concat(datasets, ignore_index=True)
    print(f"✅ Combined: {len(df_combined)} compounds")

    # Validation pipeline
    df_valid = validate_smiles(df_combined)
    df_valid = validate_log_bb(df_valid)
    df_valid = validate_bbb_class_consistency(df_valid)
    df_valid = validate_molecular_weight(df_valid)
    df_valid = remove_duplicates(df_valid)

    # Quality scoring
    df_valid = generate_quality_scores(df_valid)

    # Cross-reference with v2.0
    xref_stats = cross_reference_v2_dataset(df_valid)

    # Save validated dataset
    output_file = output_dir / 'validated_compounds.csv'
    df_valid.to_csv(output_file, index=False)
    print(f"\n✅ Saved validated dataset: {output_file}")
    print(f"   {len(df_valid)} compounds passed all validation checks")

    # Generate validation report
    validation_report = {
        'timestamp': pd.Timestamp.now().isoformat(),
        'total_input_compounds': len(df_combined),
        'validated_compounds': len(df_valid),
        'validation_rate': len(df_valid) / len(df_combined) * 100,
        'bbb_distribution': {
            'BBB+': int(len(df_valid[df_valid['bbb_class'] == 'BBB+'])),
            'BBB-': int(len(df_valid[df_valid['bbb_class'] == 'BBB-'])),
            'uncertain': int(len(df_valid[df_valid['bbb_class'] == 'uncertain']))
        },
        'log_bb_stats': {
            'min': float(df_valid['log_bb'].min()),
            'max': float(df_valid['log_bb'].max()),
            'mean': float(df_valid['log_bb'].mean()),
            'median': float(df_valid['log_bb'].median())
        },
        'data_sources': df_valid['data_source'].value_counts().to_dict() if 'data_source' in df_valid.columns else {},
        'quality_distribution': df_valid['quality_score'].value_counts().to_dict() if 'quality_score' in df_valid.columns else {},
        'cross_reference': xref_stats,
        'validation_criteria': {
            'smiles': 'RDKit parsing + canonicalization',
            'log_bb_range': '[-5.0, 2.0]',
            'molecular_weight_range': '[50, 1000] Da',
            'bbb_class_consistency': 'BBB+: Log BB > -1.0, BBB-: Log BB < -2.0',
            'deduplication': 'Canonical SMILES'
        }
    }

    report_file = output_dir / 'validation_report.json'
    with open(report_file, 'w') as f:
        json.dump(validation_report, f, indent=2)
    print(f"✅ Saved validation report: {report_file}")

    # Final statistics
    print("\n" + "=" * 70)
    print("Round 2 Validation Summary")
    print("=" * 70)
    print(f"Input compounds: {len(df_combined)}")
    print(f"Validated compounds: {len(df_valid)}")
    print(f"Validation rate: {validation_report['validation_rate']:.1f}%")
    print(f"\nBBB Distribution:")
    print(f"  BBB+: {validation_report['bbb_distribution']['BBB+']}")
    print(f"  BBB-: {validation_report['bbb_distribution']['BBB-']}")
    print(f"  Uncertain: {validation_report['bbb_distribution']['uncertain']}")
    print(f"\nLog BB Statistics:")
    print(f"  Range: [{validation_report['log_bb_stats']['min']:.2f}, {validation_report['log_bb_stats']['max']:.2f}]")
    print(f"  Mean: {validation_report['log_bb_stats']['mean']:.2f}")
    print(f"  Median: {validation_report['log_bb_stats']['median']:.2f}")
    print(f"\nCross-reference with v2.0:")
    print(f"  Overlap: {xref_stats['overlap_count']} compounds")
    print(f"  New compounds: {xref_stats['new_compounds']}")
    print("=" * 70)

    print("\n✅ Agent 7 (Round 2 Validation) Complete!")

    return 0


if __name__ == "__main__":
    sys.exit(main())
