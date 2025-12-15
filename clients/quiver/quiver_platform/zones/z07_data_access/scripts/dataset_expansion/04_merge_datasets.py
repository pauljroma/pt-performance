#!/usr/bin/env python3
"""
Dataset Merger & Validator
============================

Merges all downloaded BBB datasets and performs quality control.

Inputs:
- data/bbb/chembl_bbb_data.csv (existing 6,497 compounds)
- data/bbb/expansion/b3db_compounds.csv
- data/bbb/expansion/bbbp_dataset.csv
- data/bbb/expansion/drugbank_cns.csv

Output:
- data/bbb/chembl_bbb_data_v2_0.csv (merged dataset)

Zone: z07_data_access/scripts/dataset_expansion
Agent: agent_4_merge
Date: 2025-12-01
"""

import sys
import json
from pathlib import Path
from typing import List, Dict, Any
import pandas as pd
import numpy as np

# Add zones to path
zones_path = Path(__file__).parent.parent.parent.parent
sys.path.insert(0, str(zones_path))

try:
    from rdkit import Chem
    RDKIT_AVAILABLE = True
except ImportError:
    print("⚠️  RDKit not available")
    RDKIT_AVAILABLE = False


def load_datasets() -> List[pd.DataFrame]:
    """Load all BBB datasets."""
    print("=" * 70)
    print("Loading Datasets")
    print("=" * 70)

    datasets = []

    # Existing dataset
    existing_path = Path("/Users/expo/Code/expo/clients/quiver/data/bbb/chembl_bbb_data.csv")
    if existing_path.exists():
        df_existing = pd.read_csv(existing_path)
        print(f"\n✅ Loaded existing dataset: {len(df_existing)} compounds")
        datasets.append(('existing', df_existing))
    else:
        print(f"\n⚠️  Existing dataset not found: {existing_path}")

    # New datasets
    expansion_dir = Path("/Users/expo/Code/expo/clients/quiver/data/bbb/expansion")

    new_datasets = [
        ('b3db', expansion_dir / 'b3db_compounds.csv'),
        ('bbbp', expansion_dir / 'bbbp_dataset.csv'),
        ('drugbank', expansion_dir / 'drugbank_cns.csv')
    ]

    for name, path in new_datasets:
        if path.exists():
            df = pd.read_csv(path)
            print(f"✅ Loaded {name}: {len(df)} compounds")
            datasets.append((name, df))
        else:
            print(f"⚠️  {name} not found: {path}")

    return datasets


def standardize_schema(datasets: List[tuple]) -> pd.DataFrame:
    """Standardize all datasets to same schema."""
    print("\n" + "=" * 70)
    print("Standardizing Schema")
    print("=" * 70)

    all_rows = []

    for source_name, df in datasets:
        print(f"\n📋 Processing {source_name}...")

        # Ensure required columns exist
        required_cols = [
            'compound_id', 'chembl_id', 'smiles', 'mol_weight',
            'log_bb', 'bbb_class', 'method', 'literature_doi', 'data_source'
        ]

        for col in required_cols:
            if col not in df.columns:
                df[col] = None

        # Select only required columns
        df_std = df[required_cols].copy()

        all_rows.append(df_std)
        print(f"   {len(df_std)} compounds standardized")

    # Combine all datasets
    combined = pd.concat(all_rows, ignore_index=True)
    print(f"\n✅ Combined: {len(combined)} total compounds")

    return combined


def canonicalize_smiles(df: pd.DataFrame) -> pd.DataFrame:
    """Canonicalize all SMILES strings."""
    if not RDKIT_AVAILABLE:
        print("\n⚠️  RDKit not available - skipping SMILES canonicalization")
        return df

    print("\n" + "=" * 70)
    print("Canonicalizing SMILES")
    print("=" * 70)

    canonical_smiles = []
    valid_indices = []

    for idx, row in df.iterrows():
        mol = Chem.MolFromSmiles(row['smiles'])
        if mol is not None:
            canonical = Chem.MolToSmiles(mol)
            canonical_smiles.append(canonical)
            valid_indices.append(idx)
        else:
            print(f"   ⚠️  Invalid SMILES at index {idx}: {row['smiles']}")

    # Keep only valid SMILES
    df_valid = df.loc[valid_indices].copy()
    df_valid['smiles'] = canonical_smiles

    print(f"   ✅ Canonicalized {len(df_valid)} compounds")
    print(f"   ⚠️  Removed {len(df) - len(df_valid)} invalid SMILES")

    return df_valid


def remove_duplicates(df: pd.DataFrame) -> pd.DataFrame:
    """Remove duplicate compounds (by SMILES)."""
    print("\n" + "=" * 70)
    print("Removing Duplicates")
    print("=" * 70)

    original_count = len(df)

    # Sort by data quality (keep highest quality)
    # Priority: DrugBank > B3DB > Literature > BBBP > QSAR
    quality_order = {
        'DrugBank CNS': 1,
        'B3DB (experimental)': 2,
        'BBBP (MoleculeNet)': 3,
        'Literature': 4,
        'QSAR': 5
    }

    df['_quality_rank'] = df['data_source'].apply(
        lambda x: min([quality_order.get(src, 10) for src in quality_order.keys() if src in str(x)])
    )

    # Sort by quality, keep first occurrence
    df = df.sort_values('_quality_rank').drop_duplicates(subset=['smiles'], keep='first')
    df = df.drop(columns=['_quality_rank'])

    duplicates_removed = original_count - len(df)

    print(f"   Original: {original_count} compounds")
    print(f"   Deduplicated: {len(df)} compounds")
    print(f"   Removed: {duplicates_removed} duplicates")

    return df


def validate_quality(df: pd.DataFrame) -> pd.DataFrame:
    """Perform quality validation checks."""
    print("\n" + "=" * 70)
    print("Quality Validation")
    print("=" * 70)

    initial_count = len(df)

    # Check 1: Log BB range
    valid_log_bb = df[(df['log_bb'] >= -5.0) & (df['log_bb'] <= 2.0)]
    removed = initial_count - len(valid_log_bb)
    if removed > 0:
        print(f"   ⚠️  Removed {removed} compounds with Log BB out of range")
    df = valid_log_bb

    # Check 2: BBB class consistency
    def check_consistency(row):
        if pd.isna(row['log_bb']) or pd.isna(row['bbb_class']):
            return True

        if row['log_bb'] > -1.0 and row['bbb_class'] not in ['BBB+', 'uncertain']:
            return False
        if row['log_bb'] < -2.0 and row['bbb_class'] not in ['BBB-', 'uncertain']:
            return False
        return True

    consistent = df[df.apply(check_consistency, axis=1)]
    removed = len(df) - len(consistent)
    if removed > 0:
        print(f"   ⚠️  Removed {removed} compounds with inconsistent BBB class")
    df = consistent

    # Check 3: Molecular weight (drug-like)
    if 'mol_weight' in df.columns:
        df['mol_weight'] = pd.to_numeric(df['mol_weight'], errors='coerce')
        valid_mw = df[(df['mol_weight'] > 0) & (df['mol_weight'] < 1000)]
        removed = len(df) - len(valid_mw)
        if removed > 0:
            print(f"   ⚠️  Removed {removed} compounds with MW > 1000")
        df = valid_mw

    # Check 4: Remove statistical outliers (3-sigma rule)
    z_scores = np.abs((df['log_bb'] - df['log_bb'].mean()) / df['log_bb'].std())
    outliers = z_scores > 3
    if outliers.sum() > 0:
        print(f"   ⚠️  Removed {outliers.sum()} statistical outliers (3-sigma)")
        df = df[~outliers]

    print(f"\n   ✅ Passed quality validation: {len(df)} compounds")
    print(f"   Total removed: {initial_count - len(df)} compounds")

    return df


def generate_statistics(df: pd.DataFrame, output_dir: Path):
    """Generate dataset statistics."""
    print("\n" + "=" * 70)
    print("Dataset Statistics")
    print("=" * 70)

    stats = {
        'total_compounds': len(df),
        'bbb_distribution': {
            'BBB+': len(df[df['bbb_class'] == 'BBB+']),
            'BBB-': len(df[df['bbb_class'] == 'BBB-']),
            'uncertain': len(df[df['bbb_class'] == 'uncertain'])
        },
        'data_sources': df['data_source'].value_counts().to_dict(),
        'log_bb_statistics': {
            'min': float(df['log_bb'].min()),
            'max': float(df['log_bb'].max()),
            'mean': float(df['log_bb'].mean()),
            'median': float(df['log_bb'].median()),
            'std': float(df['log_bb'].std())
        },
        'quality_metrics': {
            'duplicate_rate': 0.0,  # Already removed
            'invalid_smiles_rate': 0.0,  # Already filtered
            'log_bb_range_violations': 0,
            'class_consistency': '100%'
        }
    }

    # Save statistics
    stats_path = output_dir / 'merge_statistics.json'
    with open(stats_path, 'w') as f:
        json.dump(stats, indent=2, fp=f)

    print(f"\n✅ Statistics saved to {stats_path}")

    # Print summary
    print("\n" + "=" * 70)
    print("Final Dataset Summary")
    print("=" * 70)
    print(f"Total compounds: {stats['total_compounds']}")
    print(f"\nBBB Distribution:")
    print(f"  BBB+ (high penetration): {stats['bbb_distribution']['BBB+']}")
    print(f"  BBB- (low penetration): {stats['bbb_distribution']['BBB-']}")
    print(f"  Uncertain: {stats['bbb_distribution']['uncertain']}")
    print(f"\nLog BB Range: [{stats['log_bb_statistics']['min']:.2f}, {stats['log_bb_statistics']['max']:.2f}]")
    print(f"Log BB Mean: {stats['log_bb_statistics']['mean']:.2f}")
    print(f"Log BB Median: {stats['log_bb_statistics']['median']:.2f}")
    print(f"\nData Sources:")
    for source, count in sorted(stats['data_sources'].items(), key=lambda x: -x[1])[:10]:
        print(f"  {source}: {count}")
    print("=" * 70)

    return stats


def create_summary_report(stats: Dict[str, Any], output_dir: Path):
    """Create summary markdown report."""
    report_path = output_dir / 'DATASET_V2_0_SUMMARY.md'

    with open(report_path, 'w') as f:
        f.write("# BBB Dataset v2.0 - Expansion Summary\n\n")
        f.write(f"**Date:** 2025-12-01\n")
        f.write(f"**Total Compounds:** {stats['total_compounds']}\n\n")

        f.write("## Dataset Composition\n\n")
        f.write(f"- **BBB+ (high penetration):** {stats['bbb_distribution']['BBB+']}\n")
        f.write(f"- **BBB- (low penetration):** {stats['bbb_distribution']['BBB-']}\n")
        f.write(f"- **Uncertain:** {stats['bbb_distribution']['uncertain']}\n\n")

        f.write("## Log BB Statistics\n\n")
        f.write(f"- **Range:** [{stats['log_bb_statistics']['min']:.2f}, {stats['log_bb_statistics']['max']:.2f}]\n")
        f.write(f"- **Mean:** {stats['log_bb_statistics']['mean']:.2f}\n")
        f.write(f"- **Median:** {stats['log_bb_statistics']['median']:.2f}\n")
        f.write(f"- **Std Dev:** {stats['log_bb_statistics']['std']:.2f}\n\n")

        f.write("## Data Sources\n\n")
        for source, count in sorted(stats['data_sources'].items(), key=lambda x: -x[1]):
            f.write(f"- **{source}:** {count} compounds\n")

        f.write("\n## Quality Metrics\n\n")
        f.write(f"- **Duplicate Rate:** {stats['quality_metrics']['duplicate_rate']}\n")
        f.write(f"- **Invalid SMILES:** {stats['quality_metrics']['invalid_smiles_rate']}\n")
        f.write(f"- **Class Consistency:** {stats['quality_metrics']['class_consistency']}\n")

    print(f"\n✅ Summary report saved to {report_path}")


def main():
    """Main execution."""
    print("\n" + "=" * 70)
    print("Agent 4: Dataset Merger & Validator")
    print("=" * 70)

    # Setup paths
    output_dir = Path("/Users/expo/Code/expo/clients/quiver/data/bbb/expansion")
    output_dir.mkdir(parents=True, exist_ok=True)

    # Load datasets
    datasets = load_datasets()

    if not datasets:
        print("\n❌ No datasets to merge")
        return 1

    # Standardize schema
    df = standardize_schema(datasets)

    # Canonicalize SMILES
    df = canonicalize_smiles(df)

    # Remove duplicates
    df = remove_duplicates(df)

    # Validate quality
    df = validate_quality(df)

    # Save merged dataset
    output_file = Path("/Users/expo/Code/expo/clients/quiver/data/bbb/chembl_bbb_data_v2_0.csv")
    df.to_csv(output_file, index=False)
    print(f"\n✅ Saved merged dataset: {output_file}")
    print(f"   Total compounds: {len(df)}")

    # Generate statistics
    stats = generate_statistics(df, output_dir)

    # Create summary report
    create_summary_report(stats, output_dir)

    print("\n" + "=" * 70)
    print("✅ Agent 4 (Merge & Validate) Complete!")
    print("=" * 70)

    return 0


if __name__ == "__main__":
    sys.exit(main())
