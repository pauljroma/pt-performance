#!/usr/bin/env python3
"""
Round 2 Dataset Merger
=======================

Merge Round 2 expansion data with existing v2.0 dataset.

Inputs:
- data/bbb/chembl_bbb_data_v2_0.csv (2,423 compounds)
- data/bbb/expansion_round2/validated_compounds.csv (~167)

Output:
- data/bbb/chembl_bbb_data_v3_0.csv

Target: 2,500+ total unique compounds

Agent: agent_8_merge_round2
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
print("Agent 8: Round 2 Dataset Merger")
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
    print("⚠️  RDKit not available")
    RDKIT_AVAILABLE = False


def load_datasets() -> tuple[pd.DataFrame, pd.DataFrame]:
    """Load v2.0 and Round 2 validated datasets."""
    print("\n" + "=" * 70)
    print("Loading Datasets")
    print("=" * 70)

    # Load v2.0 dataset
    v2_path = Path("/Users/expo/Code/expo/clients/quiver/data/bbb/chembl_bbb_data_v2_0.csv")
    if not v2_path.exists():
        print(f"❌ v2.0 dataset not found: {v2_path}")
        sys.exit(1)

    df_v2 = pd.read_csv(v2_path)
    print(f"✅ Loaded v2.0 dataset: {len(df_v2)} compounds")

    # Load Round 2 validated dataset
    r2_path = Path("/Users/expo/Code/expo/clients/quiver/data/bbb/expansion_round2/validated_compounds.csv")
    if not r2_path.exists():
        print(f"❌ Round 2 validated dataset not found: {r2_path}")
        sys.exit(1)

    df_r2 = pd.read_csv(r2_path)
    print(f"✅ Loaded Round 2 dataset: {len(df_r2)} compounds")

    return df_v2, df_r2


def standardize_schema(df: pd.DataFrame, source: str) -> pd.DataFrame:
    """Standardize column schema across datasets."""
    print(f"\n⚙️  Standardizing schema for {source}...")

    # Required columns
    required = [
        'compound_id', 'smiles', 'mol_weight',
        'log_bb', 'bbb_class', 'method',
        'literature_doi', 'data_source'
    ]

    # Add missing columns with defaults
    for col in required:
        if col not in df.columns:
            if col == 'literature_doi':
                df[col] = 'unknown'
            elif col == 'data_source':
                df[col] = source
            elif col == 'method':
                df[col] = 'unknown'
            else:
                df[col] = None

    # Select and reorder columns
    df = df[required].copy()

    print(f"   ✅ Standardized {len(df)} rows")
    return df


def canonicalize_all_smiles(df: pd.DataFrame) -> pd.DataFrame:
    """Canonicalize all SMILES strings for consistent deduplication."""
    print("\n" + "=" * 70)
    print("Canonicalizing SMILES")
    print("=" * 70)

    if not RDKIT_AVAILABLE:
        print("⚠️  RDKit not available - skipping canonicalization")
        return df

    canonical_rows = []
    failed = 0

    for idx, row in df.iterrows():
        smiles = row['smiles']

        if not smiles or pd.isna(smiles):
            failed += 1
            continue

        try:
            mol = Chem.MolFromSmiles(smiles)
            if mol is None:
                failed += 1
                continue

            canonical_smiles = Chem.MolToSmiles(mol)
            row_dict = row.to_dict()
            row_dict['smiles'] = canonical_smiles
            canonical_rows.append(row_dict)

        except Exception as e:
            failed += 1
            continue

    df_canonical = pd.DataFrame(canonical_rows)

    print(f"✅ Canonicalized: {len(df_canonical)}")
    print(f"❌ Failed: {failed}")

    return df_canonical


def merge_with_quality_priority(df_v2: pd.DataFrame, df_r2: pd.DataFrame) -> pd.DataFrame:
    """Merge datasets, keeping highest quality version of duplicates."""
    print("\n" + "=" * 70)
    print("Merging with Quality Priority")
    print("=" * 70)

    # Assign quality scores if not present
    if 'quality_score' not in df_v2.columns:
        # v2.0 has mostly BBBP data (high quality)
        df_v2['quality_score'] = 4  # Default high quality for v2.0

    if 'quality_score' not in df_r2.columns:
        df_r2['quality_score'] = 3  # Default medium quality for Round 2

    # Add source tracking
    df_v2['dataset_source'] = 'v2.0'
    df_r2['dataset_source'] = 'Round2'

    # Combine datasets
    df_combined = pd.concat([df_v2, df_r2], ignore_index=True)
    print(f"   Combined total: {len(df_combined)}")

    # Sort by quality score (higher = better), then by dataset_source (v2.0 first)
    df_combined = df_combined.sort_values(
        by=['quality_score', 'dataset_source'],
        ascending=[False, True]  # Higher quality first, v2.0 first if tied
    )

    # Remove duplicates, keeping first (highest quality)
    before_dedup = len(df_combined)
    df_merged = df_combined.drop_duplicates(subset=['smiles'], keep='first')
    after_dedup = len(df_merged)
    removed = before_dedup - after_dedup

    print(f"✅ Unique compounds: {after_dedup}")
    print(f"❌ Duplicates removed: {removed}")
    print(f"   Kept from v2.0: {len(df_merged[df_merged['dataset_source'] == 'v2.0'])}")
    print(f"   Kept from Round 2: {len(df_merged[df_merged['dataset_source'] == 'Round2'])}")

    return df_merged


def final_validation(df: pd.DataFrame) -> pd.DataFrame:
    """Final validation checks on merged dataset."""
    print("\n" + "=" * 70)
    print("Final Validation")
    print("=" * 70)

    # Check for any remaining issues
    before = len(df)

    # Remove rows with missing critical data
    df = df.dropna(subset=['smiles', 'log_bb', 'bbb_class'])

    # Verify Log BB range
    df = df[(df['log_bb'] >= -5.0) & (df['log_bb'] <= 2.0)]

    # Verify MW range (if available)
    if 'mol_weight' in df.columns:
        df = df[(df['mol_weight'] >= 50) & (df['mol_weight'] <= 1000)]

    after = len(df)
    removed = before - after

    print(f"✅ Final validated: {after}")
    if removed > 0:
        print(f"⚠️  Final cleanup removed: {removed}")

    return df


def generate_statistics(df: pd.DataFrame, df_v2: pd.DataFrame, df_r2: pd.DataFrame) -> Dict[str, Any]:
    """Generate comprehensive merge statistics."""
    print("\n" + "=" * 70)
    print("Generating Statistics")
    print("=" * 70)

    new_from_round2 = len(df[df['dataset_source'] == 'Round2'])

    stats = {
        'timestamp': pd.Timestamp.now().isoformat(),
        'v2_0_compounds': len(df_v2),
        'round2_validated_compounds': len(df_r2),
        'v3_0_total_compounds': len(df),
        'new_compounds_added': new_from_round2,
        'bbb_distribution': {
            'BBB+': int(len(df[df['bbb_class'] == 'BBB+'])),
            'BBB-': int(len(df[df['bbb_class'] == 'BBB-'])),
            'uncertain': int(len(df[df['bbb_class'] == 'uncertain']))
        },
        'bbb_distribution_pct': {
            'BBB+': float(len(df[df['bbb_class'] == 'BBB+']) / len(df) * 100),
            'BBB-': float(len(df[df['bbb_class'] == 'BBB-']) / len(df) * 100),
            'uncertain': float(len(df[df['bbb_class'] == 'uncertain']) / len(df) * 100)
        },
        'log_bb_stats': {
            'min': float(df['log_bb'].min()),
            'max': float(df['log_bb'].max()),
            'mean': float(df['log_bb'].mean()),
            'median': float(df['log_bb'].median()),
            'std': float(df['log_bb'].std())
        },
        'data_sources': df['data_source'].value_counts().to_dict() if 'data_source' in df.columns else {},
        'dataset_composition': {
            'from_v2.0': int(len(df[df['dataset_source'] == 'v2.0'])),
            'from_round2': new_from_round2
        },
        'quality_distribution': df['quality_score'].value_counts().to_dict() if 'quality_score' in df.columns else {}
    }

    print(f"✅ Statistics generated")
    return stats


def main():
    """Main execution."""
    output_dir = Path("/Users/expo/Code/expo/clients/quiver/data/bbb/expansion_round2")
    output_dir.mkdir(parents=True, exist_ok=True)

    # Load datasets
    df_v2, df_r2 = load_datasets()

    # Standardize schemas
    df_v2 = standardize_schema(df_v2, 'v2.0')
    df_r2 = standardize_schema(df_r2, 'Round2')

    # Canonicalize SMILES
    df_v2 = canonicalize_all_smiles(df_v2)
    df_r2 = canonicalize_all_smiles(df_r2)

    # Merge with quality priority
    df_merged = merge_with_quality_priority(df_v2, df_r2)

    # Final validation
    df_final = final_validation(df_merged)

    # Save v3.0 dataset
    v3_path = Path("/Users/expo/Code/expo/clients/quiver/data/bbb/chembl_bbb_data_v3_0.csv")
    df_final.to_csv(v3_path, index=False)
    print(f"\n✅ Saved v3.0 dataset: {v3_path}")
    print(f"   Total compounds: {len(df_final)}")

    # Generate statistics
    stats = generate_statistics(df_final, df_v2, df_r2)

    # Save merge statistics
    stats_file = output_dir / 'merge_statistics.json'
    with open(stats_file, 'w') as f:
        json.dump(stats, f, indent=2)
    print(f"✅ Saved merge statistics: {stats_file}")

    # Print summary
    print("\n" + "=" * 70)
    print("Round 2 Merge Summary")
    print("=" * 70)
    print(f"v2.0 dataset: {stats['v2_0_compounds']} compounds")
    print(f"Round 2 validated: {stats['round2_validated_compounds']} compounds")
    print(f"v3.0 total: {stats['v3_0_total_compounds']} compounds")
    print(f"New compounds added: {stats['new_compounds_added']}")
    print(f"\nBBB Distribution:")
    print(f"  BBB+: {stats['bbb_distribution']['BBB+']} ({stats['bbb_distribution_pct']['BBB+']:.1f}%)")
    print(f"  BBB-: {stats['bbb_distribution']['BBB-']} ({stats['bbb_distribution_pct']['BBB-']:.1f}%)")
    print(f"  Uncertain: {stats['bbb_distribution']['uncertain']} ({stats['bbb_distribution_pct']['uncertain']:.1f}%)")
    print(f"\nLog BB Statistics:")
    print(f"  Range: [{stats['log_bb_stats']['min']:.2f}, {stats['log_bb_stats']['max']:.2f}]")
    print(f"  Mean: {stats['log_bb_stats']['mean']:.2f}")
    print(f"  Median: {stats['log_bb_stats']['median']:.2f}")
    print(f"  Std Dev: {stats['log_bb_stats']['std']:.2f}")
    print(f"\nDataset Composition:")
    print(f"  From v2.0: {stats['dataset_composition']['from_v2.0']}")
    print(f"  From Round 2: {stats['dataset_composition']['from_round2']}")
    print("=" * 70)

    print("\n✅ Agent 8 (Round 2 Merge) Complete!")

    return 0


if __name__ == "__main__":
    sys.exit(main())
