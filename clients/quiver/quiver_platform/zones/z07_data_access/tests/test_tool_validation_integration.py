#!/usr/bin/env python3
"""
Integration Tests for Tool Validation (Stream 1.2)

Tests that actual Sapphire tools properly validate their inputs and return
standardized error responses when given invalid parameters.
"""

import sys
import asyncio
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parents[6]
sys.path.insert(0, str(project_root))


async def test_vector_antipodal_missing_required():
    """Test vector_antipodal rejects missing required parameter."""
    from clients.quiver.quiver_platform.zones.z07_data_access.tools import vector_antipodal

    # Missing required 'gene' parameter
    result = await vector_antipodal.execute({"top_k": 10})

    assert result["success"] is False, "Should fail validation"
    assert result["error"] == "Validation failed", "Should be validation error"
    assert "validation_errors" in result, "Should have validation_errors"

    # Check that 'gene' is in the errors
    error_params = [e["parameter"] for e in result["validation_errors"]]
    assert "gene" in error_params, "Should report missing 'gene' parameter"

    print("✅ vector_antipodal rejects missing required parameter")


async def test_vector_antipodal_out_of_range():
    """Test vector_antipodal rejects out-of-range parameter."""
    from clients.quiver.quiver_platform.zones.z07_data_access.tools import vector_antipodal

    # top_k exceeds maximum of 200
    result = await vector_antipodal.execute({"gene": "TP53", "top_k": 500})

    assert result["success"] is False, "Should fail validation"
    assert "validation_errors" in result, "Should have validation_errors"

    # Check that top_k error is present
    top_k_errors = [e for e in result["validation_errors"] if e["parameter"] == "top_k"]
    assert len(top_k_errors) > 0, "Should have top_k error"
    assert "exceeds maximum" in top_k_errors[0]["error"].lower(), "Should mention exceeds maximum"

    print("✅ vector_antipodal rejects out-of-range parameter")


async def test_vector_antipodal_invalid_enum():
    """Test vector_antipodal rejects invalid enum value."""
    from clients.quiver.quiver_platform.zones.z07_data_access.tools import vector_antipodal

    # Invalid embedding_space value
    result = await vector_antipodal.execute({
        "gene": "TP53",
        "embedding_space": "INVALID_SPACE"
    })

    assert result["success"] is False, "Should fail validation"
    assert "validation_errors" in result, "Should have validation_errors"

    # Check that embedding_space error is present
    space_errors = [e for e in result["validation_errors"] if e["parameter"] == "embedding_space"]
    assert len(space_errors) > 0, "Should have embedding_space error"
    assert "not in allowed values" in space_errors[0]["error"], "Should mention allowed values"

    print("✅ vector_antipodal rejects invalid enum value")


async def test_drug_interactions_wrong_type():
    """Test drug_interactions rejects wrong parameter type."""
    from clients.quiver.quiver_platform.zones.z07_data_access.tools import drug_interactions

    # max_results should be integer, not string
    result = await drug_interactions.execute({
        "drug": "Aspirin",
        "max_results": "twenty"  # Wrong type
    })

    assert result["success"] is False, "Should fail validation"
    assert "validation_errors" in result, "Should have validation_errors"

    # Check that max_results type error is present
    max_results_errors = [e for e in result["validation_errors"] if e["parameter"] == "max_results"]
    assert len(max_results_errors) > 0, "Should have max_results error"
    assert "expected integer" in max_results_errors[0]["error"].lower(), "Should mention type mismatch"

    print("✅ drug_interactions rejects wrong parameter type")


async def test_graph_path_multiple_errors():
    """Test graph_path returns multiple validation errors."""
    from clients.quiver.quiver_platform.zones.z07_data_access.tools import graph_path

    # Missing required params + invalid type
    result = await graph_path.execute({
        "max_depth": "five"  # Wrong type, and missing required params
    })

    assert result["success"] is False, "Should fail validation"
    assert "validation_errors" in result, "Should have validation_errors"
    assert len(result["validation_errors"]) >= 2, "Should have multiple errors"

    print("✅ graph_path returns multiple validation errors")


async def test_count_entities_valid_input():
    """Test count_entities accepts valid input (no validation errors)."""
    from clients.quiver.quiver_platform.zones.z07_data_access.tools import count_entities

    # This tool has no required parameters, should accept empty input
    result = await count_entities.execute({})

    # Should not have validation errors (may have execution errors if services unavailable)
    assert "validation_errors" not in result or len(result.get("validation_errors", [])) == 0, \
        "Should not have validation errors for valid input"

    print("✅ count_entities accepts valid input without validation errors")


async def test_semantic_collections_no_params():
    """Test semantic_collections works with no parameters."""
    from clients.quiver.quiver_platform.zones.z07_data_access.tools import semantic_collections

    # No parameters required
    result = await semantic_collections.execute({})

    # Should not have validation errors
    assert "validation_errors" not in result or len(result.get("validation_errors", [])) == 0, \
        "Should not have validation errors"

    print("✅ semantic_collections works with no parameters")


async def test_error_response_format():
    """Test that all validation errors follow standardized format."""
    from clients.quiver.quiver_platform.zones.z07_data_access.tools import vector_antipodal

    result = await vector_antipodal.execute({"top_k": 500})

    # Check standardized error response format
    assert "success" in result, "Should have 'success' field"
    assert result["success"] is False, "success should be False"
    assert "error" in result, "Should have 'error' field"
    assert result["error"] == "Validation failed", "error should be 'Validation failed'"
    assert "tool" in result, "Should have 'tool' field"
    assert "validation_errors" in result, "Should have 'validation_errors' field"
    assert isinstance(result["validation_errors"], list), "validation_errors should be a list"
    assert "error_count" in result, "Should have 'error_count' field"
    assert result["error_count"] == len(result["validation_errors"]), "error_count should match length"

    # Check individual error format
    for error in result["validation_errors"]:
        assert "parameter" in error, "Each error should have 'parameter' field"
        assert "error" in error, "Each error should have 'error' message field"

    print("✅ Validation errors follow standardized format")


async def run_all_tests():
    """Run all integration tests."""
    tests = [
        ("vector_antipodal missing required", test_vector_antipodal_missing_required),
        ("vector_antipodal out of range", test_vector_antipodal_out_of_range),
        ("vector_antipodal invalid enum", test_vector_antipodal_invalid_enum),
        ("drug_interactions wrong type", test_drug_interactions_wrong_type),
        ("graph_path multiple errors", test_graph_path_multiple_errors),
        ("count_entities valid input", test_count_entities_valid_input),
        ("semantic_collections no params", test_semantic_collections_no_params),
        ("error response format", test_error_response_format),
    ]

    passed = 0
    failed = 0
    errors_list = []

    print("=" * 60)
    print("Tool Validation Integration Tests")
    print("=" * 60)
    print()

    for test_name, test_func in tests:
        try:
            await test_func()
            passed += 1
        except AssertionError as e:
            print(f"❌ {test_name}: {str(e)}")
            failed += 1
            errors_list.append((test_name, str(e)))
        except Exception as e:
            print(f"❌ {test_name} (EXCEPTION): {type(e).__name__}: {str(e)}")
            failed += 1
            errors_list.append((test_name, f"{type(e).__name__}: {str(e)}"))

    print()
    print("=" * 60)
    print(f"Results: {passed} passed, {failed} failed")
    print("=" * 60)

    if errors_list:
        print("\nErrors:")
        for test_name, error in errors_list:
            print(f"\n{test_name}:")
            print(f"  {error}")

    return failed == 0


if __name__ == "__main__":
    success = asyncio.run(run_all_tests())
    sys.exit(0 if success else 1)
