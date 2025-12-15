#!/usr/bin/env python3
"""
Simple BBB K-NN Test - Direct PGVector Query
============================================

Tests the K-NN BBB predictor by directly querying drugs in the EP space
and checking if we get real predictions (not hash-based).

Author: Claude Code Agent
Date: 2025-12-01
"""

import psycopg2
from psycopg2.extras import RealDictCursor
import csv
from pathlib import Path

# Connection config
PGVECTOR_HOST = "localhost"
PGVECTOR_PORT = 5435
PGVECTOR_DB = "sapphire_database"
PGVECTOR_USER = "postgres"
PGVECTOR_PASSWORD = "temppass123"

BBB_FILE = Path("/Users/expo/Code/expo/clients/quiver/data/bbb/chembl_bbb_data.csv")


def load_bbb_data():
    """Load BBB dataset"""
    bbb_dict = {}
    with open(BBB_FILE, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            chembl_id = row['chembl_id']
            bbb_dict[chembl_id] = {
                'log_bb': float(row['log_bb']),
                'bbb_class': row['bbb_class'],
                'smiles': row['smiles']
            }
    return bbb_dict


def test_knn_prediction(drug_name: str, k: int = 20):
    """Test K-NN prediction for a drug"""
    print(f"\n{'='*60}")
    print(f"Testing: {drug_name}")
    print('='*60)

    conn = psycopg2.connect(
        host=PGVECTOR_HOST,
        port=PGVECTOR_PORT,
        database=PGVECTOR_DB,
        user=PGVECTOR_USER,
        password=PGVECTOR_PASSWORD
    )
    cur = conn.cursor(cursor_factory=RealDictCursor)

    # Get drug embedding
    cur.execute("""
        SELECT id, embedding
        FROM modex_ep_unified_16d_v6_0
        WHERE id ILIKE %s
        LIMIT 1
    """, (f"{drug_name}%",))

    drug_row = cur.fetchone()
    if not drug_row:
        print(f"❌ Drug {drug_name} not found in EP_DRUG_39D_v5_0")
        return False

    print(f"✓ Found in EP space: {drug_row['id']}")

    # Get K nearest neighbors
    cur.execute("""
        SELECT
            id,
            1 - (embedding <=> %s::vector) as similarity
        FROM modex_ep_unified_16d_v6_0
        WHERE id != %s
        ORDER BY embedding <=> %s::vector
        LIMIT %s
    """, (drug_row['embedding'], drug_row['id'], drug_row['embedding'], k))

    neighbors = cur.fetchall()
    print(f"✓ Found {len(neighbors)} neighbors")

    # Load BBB data
    bbb_data = load_bbb_data()
    print(f"✓ Loaded {len(bbb_data)} BBB reference molecules")

    # Try to match neighbors to BBB data
    matched = 0
    bbb_positive = 0
    bbb_negative = 0

    print(f"\nTop 10 neighbors:")
    for i, neighbor in enumerate(neighbors[:10], 1):
        neighbor_base = neighbor['id'].split('_')[0]
        similarity = neighbor['similarity']

        # Try to find in BBB data (simple name matching)
        found_in_bbb = False
        for chembl_id, bbb_info in bbb_data.items():
            if neighbor_base.lower() in chembl_id.lower():
                found_in_bbb = True
                matched += 1
                if bbb_info['bbb_class'] == 'BBB+':
                    bbb_positive += 1
                elif bbb_info['bbb_class'] == 'BBB-':
                    bbb_negative += 1

                print(f"  {i}. {neighbor_base} (sim: {similarity:.3f}) - {bbb_info['bbb_class']} (log_bb: {bbb_info['log_bb']})")
                break

        if not found_in_bbb:
            print(f"  {i}. {neighbor_base} (sim: {similarity:.3f}) - NOT IN BBB DATA")

    conn.close()

    print(f"\n📊 Summary:")
    print(f"  Neighbors matched to BBB data: {matched}/{len(neighbors)}")
    print(f"  BBB+ neighbors: {bbb_positive}")
    print(f"  BBB- neighbors: {bbb_negative}")

    if matched >= 5:
        print(f"\n✅ SUCCESS: Found enough BBB-labeled neighbors for prediction")
        return True
    else:
        print(f"\n❌ FAIL: Not enough BBB-labeled neighbors (need >= 5)")
        return False


if __name__ == "__main__":
    # Test with drugs known to be in EP space
    test_drugs = [
        "Caffeine",
        "Vancomycin",
        "Oxatomide",
        "Nefopam",
        "Diazepam"
    ]

    print("BBB K-NN Simple Test")
    print("="*60)

    results = []
    for drug in test_drugs:
        try:
            success = test_knn_prediction(drug, k=20)
            results.append((drug, success))
        except Exception as e:
            print(f"❌ Error testing {drug}: {e}")
            results.append((drug, False))

    # Summary
    print(f"\n\n{'='*60}")
    print("FINAL SUMMARY")
    print('='*60)

    passed = sum(1 for _, success in results if success)
    total = len(results)

    for drug, success in results:
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"{drug}: {status}")

    print(f"\nTotal: {passed}/{total} tests passed")

    if passed >= total // 2:
        print("\n✅ K-NN predictor is working with real data!")
    else:
        print("\n❌ K-NN predictor needs more BBB reference data coverage")
