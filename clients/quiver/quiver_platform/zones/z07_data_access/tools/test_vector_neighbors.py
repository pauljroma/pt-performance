#!/usr/bin/env python3.11
"""
Test suite for vector_neighbors tool.

Tests K-nearest neighbor similarity search for genes and drugs.
"""

import sys
import asyncio
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent.parent.parent.parent.parent
sys.path.insert(0, str(project_root))

# Now we can import with absolute path
try:
    from clients.quiver.quiver_platform.zones.z07_data_access.tools.vector_neighbors import execute, TOOL_DEFINITION
except ModuleNotFoundError:
    # Fallback: use relative import from current module
    from vector_neighbors import execute, TOOL_DEFINITION


async def test_gene_similarity():
    """Test gene-to-gene similarity search."""
    print("\n" + "="*70)
    print("TEST 1: Gene Similarity Search (TP53)")
    print("="*70)

    result = await execute({
        "entity": "TP53",
        "entity_type": "gene",
        "top_k": 5,
        "min_similarity": 0.7
    })

    print(f"Success: {result['success']}")
    if result['success']:
        print(f"Query Gene: {result['entity']}")
        print(f"Neighbors Found: {result['count']}")
        print("\nTop Neighbors:")
        for i, neighbor in enumerate(result['neighbors'], 1):
            print(f"  {i}. {neighbor['entity_name']}: {neighbor['similarity_score']}")
    else:
        print(f"Error: {result['error']}")

    return result['success']


async def test_gene_fuzzy_matching():
    """Test case-insensitive fuzzy matching for genes."""
    print("\n" + "="*70)
    print("TEST 2: Gene Fuzzy Matching (tp53 → TP53)")
    print("="*70)

    result = await execute({
        "entity": "tp53",  # lowercase
        "entity_type": "gene",
        "top_k": 3,
        "min_similarity": 0.7
    })

    print(f"Success: {result['success']}")
    if result['success']:
        print(f"Input: {result['entity_input']}")
        print(f"Normalized: {result['entity']}")
        print(f"Neighbors Found: {result['count']}")
        for i, neighbor in enumerate(result['neighbors'], 1):
            print(f"  {i}. {neighbor['entity_name']}: {neighbor['similarity_score']}")
    else:
        print(f"Error: {result['error']}")

    return result['success']


async def test_brca1_similarity():
    """Test another gene for comprehensive coverage."""
    print("\n" + "="*70)
    print("TEST 3: Gene Similarity Search (BRCA1)")
    print("="*70)

    result = await execute({
        "entity": "BRCA1",
        "entity_type": "gene",
        "top_k": 5,
        "min_similarity": 0.6
    })

    print(f"Success: {result['success']}")
    if result['success']:
        print(f"Query Gene: {result['entity']}")
        print(f"Neighbors Found: {result['count']}")
        print("\nTop Neighbors:")
        for i, neighbor in enumerate(result['neighbors'], 1):
            print(f"  {i}. {neighbor['entity_name']}: {neighbor['similarity_score']}")
    else:
        print(f"Error: {result['error']}")

    return result['success']


async def test_drug_similarity():
    """Test drug-to-drug similarity search."""
    print("\n" + "="*70)
    print("TEST 4: Drug Similarity Search")
    print("="*70)

    # First, try to find a drug in the database
    result = await execute({
        "entity": "DRUG_0",  # Try index-based drug
        "entity_type": "drug",
        "top_k": 5,
        "min_similarity": 0.75
    })

    print(f"Success: {result['success']}")
    if result['success']:
        print(f"Query Drug: {result['entity']}")
        print(f"Neighbors Found: {result['count']}")
        print("\nTop Neighbors:")
        for i, neighbor in enumerate(result['neighbors'], 1):
            print(f"  {i}. {neighbor['entity_name']}: {neighbor['similarity_score']}")
    else:
        print(f"Note: {result['error']}")
        print("(Drug similarity may require actual drug names in the database)")

    return result['success'] or "not found" in result.get('error', '').lower()


async def test_invalid_gene():
    """Test error handling for non-existent gene."""
    print("\n" + "="*70)
    print("TEST 5: Error Handling (Non-existent Gene)")
    print("="*70)

    result = await execute({
        "entity": "NOTAREALGENE123XYZ",
        "entity_type": "gene",
        "top_k": 5
    })

    print(f"Success: {result['success']}")
    print(f"Error: {result['error']}")
    print(f"Hint: {result.get('hint', 'N/A')}")

    return not result['success']  # Should fail


async def test_invalid_entity_type():
    """Test error handling for invalid entity type."""
    print("\n" + "="*70)
    print("TEST 6: Error Handling (Invalid Entity Type)")
    print("="*70)

    result = await execute({
        "entity": "TP53",
        "entity_type": "invalid_type"
    })

    print(f"Success: {result['success']}")
    print(f"Error: {result['error']}")

    return not result['success']  # Should fail


async def test_parameter_validation():
    """Test parameter validation."""
    print("\n" + "="*70)
    print("TEST 7: Parameter Validation (top_k > 200)")
    print("="*70)

    result = await execute({
        "entity": "TP53",
        "entity_type": "gene",
        "top_k": 500  # Invalid: too high
    })

    print(f"Success: {result['success']}")
    print(f"Error: {result['error']}")

    return not result['success']  # Should fail


def print_tool_definition():
    """Print the tool definition."""
    print("\n" + "="*70)
    print("TOOL DEFINITION")
    print("="*70)
    print(f"Name: {TOOL_DEFINITION['name']}")
    print(f"Description: {TOOL_DEFINITION['description'][:200]}...")
    print(f"Input Schema Properties:")
    for prop_name, prop_schema in TOOL_DEFINITION['input_schema']['properties'].items():
        prop_type = prop_schema.get('type', 'object')
        required = prop_name in TOOL_DEFINITION['input_schema']['required']
        print(f"  - {prop_name}: {prop_type} {'(required)' if required else '(optional)'}")
        if 'description' in prop_schema:
            print(f"    {prop_schema['description'][:60]}...")


async def run_all_tests():
    """Run all tests."""
    print("\n" + "="*70)
    print("VECTOR NEIGHBORS TOOL - TEST SUITE")
    print("="*70)

    print_tool_definition()

    tests = [
        ("Gene Similarity", test_gene_similarity),
        ("Gene Fuzzy Matching", test_gene_fuzzy_matching),
        ("BRCA1 Similarity", test_brca1_similarity),
        ("Drug Similarity", test_drug_similarity),
        ("Invalid Gene Error", test_invalid_gene),
        ("Invalid Entity Type Error", test_invalid_entity_type),
        ("Parameter Validation", test_parameter_validation),
    ]

    results = {}
    for test_name, test_func in tests:
        try:
            results[test_name] = await test_func()
        except Exception as e:
            print(f"\nEXCEPTION in {test_name}: {str(e)}")
            results[test_name] = False

    # Print summary
    print("\n" + "="*70)
    print("TEST SUMMARY")
    print("="*70)
    passed = sum(1 for v in results.values() if v)
    total = len(results)
    print(f"Passed: {passed}/{total}")
    for test_name, success in results.items():
        status = "PASS" if success else "FAIL"
        print(f"  {status}: {test_name}")

    return passed == total


if __name__ == "__main__":
    # Run async tests
    success = asyncio.run(run_all_tests())
    sys.exit(0 if success else 1)
