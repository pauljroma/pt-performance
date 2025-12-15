#!/usr/bin/env python3
"""
Test BBB K-NN Predictor with Real Data
======================================

Tests the new K-NN based BBB permeability predictor using:
- Known BBB+ drugs: Fenfluramine (CHEMBL274098), Caffeine (CHEMBL38)
- Known BBB- drugs: Vancomycin (CHEMBL1201580)

Success criteria:
- BBB+ drugs should get probability > 0.7
- BBB- drugs should get probability < 0.4
- Query latency < 150ms
- No hash-based placeholders

Author: Claude Code Agent
Date: 2025-12-01
"""

import asyncio
import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent.parent.parent.parent.parent
sys.path.insert(0, str(project_root))

from bbb_permeability import BBBPermeabilityTool


class Colors:
    """ANSI color codes for terminal output"""
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    RESET = '\033[0m'
    BOLD = '\033[1m'


async def test_bbb_drug(tool: BBBPermeabilityTool, drug_name: str, expected_class: str):
    """Test BBB prediction for a single drug"""
    print(f"\n{Colors.BLUE}Testing {drug_name}...{Colors.RESET}")

    result = await tool.assess_bbb_permeability(drug_name, k=20, use_cns_enrichment=True)

    if not result['found']:
        print(f"{Colors.RED}FAIL: Drug not found - {result.get('error', 'Unknown error')}{Colors.RESET}")
        return False

    # Extract results
    probability = result['bbb_permeability_probability']
    bbb_class = result['bbb_class']
    confidence = result['confidence']
    k_used = result['k_neighbors_used']
    query_time = result['query_time_ms']

    # Print detailed results
    print(f"  CHEMBL ID: {result['chembl_id']}")
    print(f"  BBB Probability: {probability:.3f}")
    print(f"  BBB Class: {bbb_class}")
    print(f"  Confidence: {confidence}")
    print(f"  K Neighbors Used: {k_used}")
    print(f"  Query Time: {query_time}ms")
    print(f"  Log BB Predicted: {result.get('log_bb_predicted', 'N/A')}")
    print(f"  CNS Indication: {result.get('cns_indication', False)}")

    # Validation checks
    passed = True
    errors = []

    # Check expected class
    if expected_class == "BBB+" and probability <= 0.7:
        errors.append(f"BBB+ drug got low probability: {probability:.3f} (expected > 0.7)")
        passed = False
    elif expected_class == "BBB-" and probability >= 0.4:
        errors.append(f"BBB- drug got high probability: {probability:.3f} (expected < 0.4)")
        passed = False

    # Check query time
    if query_time > 150:
        errors.append(f"Query time exceeded SLO: {query_time}ms (expected < 150ms)")
        passed = False

    # Check that we used real neighbors
    if k_used == 0:
        errors.append("No neighbors found - prediction may be hash-based")
        passed = False

    # Print similar drugs
    if 'similar_drugs' in result and len(result['similar_drugs']) > 0:
        print(f"\n  Top Similar Drugs:")
        for i, drug in enumerate(result['similar_drugs'][:3], 1):
            print(f"    {i}. {drug['drug_name']} (similarity: {drug['similarity']:.3f}, BBB: {drug['bbb_class']})")

    # Print results
    if passed:
        print(f"\n  {Colors.GREEN}{Colors.BOLD}PASS{Colors.RESET}")
    else:
        print(f"\n  {Colors.RED}{Colors.BOLD}FAIL{Colors.RESET}")
        for error in errors:
            print(f"    - {error}")

    return passed


async def run_tests():
    """Run comprehensive BBB K-NN tests"""
    print(f"{Colors.BOLD}BBB K-NN Predictor Test Suite{Colors.RESET}")
    print("=" * 60)

    # Initialize tool
    print(f"\n{Colors.BLUE}Initializing BBB Tool...{Colors.RESET}")
    tool = BBBPermeabilityTool(
        pgvector_host="localhost",
        pgvector_port=5435,
        neo4j_uri="bolt://localhost:7687",
        neo4j_password="testpassword123"
    )

    # Test cases: (drug_name, expected_class)
    # Note: Using drugs that are in both BBB dataset AND EP_DRUG_39D_v5_0 space
    test_cases = [
        ("CHEMBL113", "BBB+"),      # Caffeine - known BBB+ drug
        ("CHEMBL262777", "BBB-"),   # Vancomycin - known BBB- drug (large antibiotic)
        ("CHEMBL12", "BBB+"),       # Diazepam - known BBB+ CNS drug
        ("Caffeine", "BBB+"),       # Test with drug name directly
        ("Vancomycin", "BBB-"),     # Test with drug name directly
    ]

    results = []
    for drug_name, expected_class in test_cases:
        passed = await test_bbb_drug(tool, drug_name, expected_class)
        results.append((drug_name, expected_class, passed))

    # Summary
    print(f"\n{Colors.BOLD}Test Summary{Colors.RESET}")
    print("=" * 60)

    passed_count = sum(1 for _, _, passed in results if passed)
    total_count = len(results)

    for drug_name, expected_class, passed in results:
        status = f"{Colors.GREEN}PASS{Colors.RESET}" if passed else f"{Colors.RED}FAIL{Colors.RESET}"
        print(f"  {drug_name} ({expected_class}): {status}")

    print(f"\n{Colors.BOLD}Total: {passed_count}/{total_count} tests passed{Colors.RESET}")

    if passed_count == total_count:
        print(f"\n{Colors.GREEN}{Colors.BOLD}ALL TESTS PASSED!{Colors.RESET}")
    else:
        print(f"\n{Colors.YELLOW}{Colors.BOLD}SOME TESTS FAILED{Colors.RESET}")

    # Cleanup
    tool.close()

    return passed_count == total_count


if __name__ == "__main__":
    success = asyncio.run(run_tests())
    sys.exit(0 if success else 1)
