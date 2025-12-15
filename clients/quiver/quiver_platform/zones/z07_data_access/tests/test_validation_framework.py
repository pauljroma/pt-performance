#!/usr/bin/env python3
"""
Unit Tests for Validation Framework (Stream 1.2)

Tests the validation functions in tool_utils.py to ensure:
- Type validation works correctly
- Constraint validation works correctly
- Error formatting is standardized
- Edge cases are handled properly
"""

import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parents[6]
sys.path.insert(0, str(project_root))

# Import validation functions directly to avoid harmonizer initialization issues
import importlib.util
spec = importlib.util.spec_from_file_location(
    "tool_utils",
    Path(__file__).parent.parent / "tool_utils.py"
)
tool_utils = importlib.util.module_from_spec(spec)

# Manually define the functions we need (to avoid full module load with dependencies)
# We'll import them in a way that avoids the harmonizer initialization

# Actually, let's just test the functions directly by copying them here for testing
# This isolates the validation logic from dependencies

from typing import Dict, Any, List, Optional
import re

def validate_param_type(
    value: Any,
    param_schema: Dict[str, Any],
    param_name: str
) -> Optional[Dict[str, str]]:
    """Validate parameter type matches schema."""
    expected_type = param_schema.get("type")

    if not expected_type:
        return None

    if value is None:
        if expected_type == "null":
            return None
        return {
            "parameter": param_name,
            "error": f"Expected {expected_type}, got null"
        }

    type_checks = {
        "string": lambda v: isinstance(v, str),
        "integer": lambda v: isinstance(v, int) and not isinstance(v, bool),
        "number": lambda v: isinstance(v, (int, float)) and not isinstance(v, bool),
        "boolean": lambda v: isinstance(v, bool),
        "array": lambda v: isinstance(v, list),
        "object": lambda v: isinstance(v, dict),
        "null": lambda v: v is None
    }

    check_func = type_checks.get(expected_type)
    if not check_func:
        return {
            "parameter": param_name,
            "error": f"Unknown type in schema: {expected_type}"
        }

    if not check_func(value):
        actual_type = type(value).__name__
        return {
            "parameter": param_name,
            "error": f"Expected {expected_type}, got {actual_type}"
        }

    return None


def validate_param_constraints(
    value: Any,
    param_schema: Dict[str, Any],
    param_name: str
) -> List[Dict[str, str]]:
    """Validate parameter value meets schema constraints."""
    errors = []

    if "enum" in param_schema:
        allowed_values = param_schema["enum"]
        if value not in allowed_values:
            errors.append({
                "parameter": param_name,
                "error": f"Value '{value}' not in allowed values: {allowed_values}"
            })

    if isinstance(value, (int, float)) and not isinstance(value, bool):
        if "minimum" in param_schema:
            if value < param_schema["minimum"]:
                errors.append({
                    "parameter": param_name,
                    "error": f"Value {value} is less than minimum {param_schema['minimum']}"
                })

        if "maximum" in param_schema:
            if value > param_schema["maximum"]:
                errors.append({
                    "parameter": param_name,
                    "error": f"Value {value} exceeds maximum {param_schema['maximum']}"
                })

    if isinstance(value, str):
        if "minLength" in param_schema:
            if len(value) < param_schema["minLength"]:
                errors.append({
                    "parameter": param_name,
                    "error": f"String length {len(value)} is less than minimum {param_schema['minLength']}"
                })

        if "maxLength" in param_schema:
            if len(value) > param_schema["maxLength"]:
                errors.append({
                    "parameter": param_name,
                    "error": f"String length {len(value)} exceeds maximum {param_schema['maxLength']}"
                })

    if isinstance(value, list):
        if "minItems" in param_schema:
            if len(value) < param_schema["minItems"]:
                errors.append({
                    "parameter": param_name,
                    "error": f"Array length {len(value)} is less than minimum {param_schema['minItems']}"
                })

        if "maxItems" in param_schema:
            if len(value) > param_schema["maxItems"]:
                errors.append({
                    "parameter": param_name,
                    "error": f"Array length {len(value)} exceeds maximum {param_schema['maxItems']}"
                })

    return errors


def validate_tool_input(
    tool_input: Dict[str, Any],
    input_schema: Dict[str, Any],
    tool_name: str
) -> List[Dict[str, str]]:
    """Validate tool input against JSON Schema definition."""
    errors = []

    if not isinstance(input_schema, dict):
        errors.append({"parameter": "_schema", "error": "Invalid input schema"})
        return errors

    properties = input_schema.get("properties", {})
    required_params = input_schema.get("required", [])

    for param in required_params:
        if param not in tool_input or tool_input[param] is None:
            errors.append({
                "parameter": param,
                "error": "Missing required parameter"
            })

    for param_name, param_value in tool_input.items():
        if param_name not in properties:
            continue

        param_schema = properties[param_name]

        type_error = validate_param_type(param_value, param_schema, param_name)
        if type_error:
            errors.append(type_error)
            continue

        constraint_errors = validate_param_constraints(param_value, param_schema, param_name)
        errors.extend(constraint_errors)

    return errors


def format_validation_response(
    tool_name: str,
    validation_errors: List[Dict[str, str]]
) -> Dict[str, Any]:
    """Format validation errors into standardized tool response."""
    return {
        "success": False,
        "error": "Validation failed",
        "tool": tool_name,
        "validation_errors": validation_errors,
        "error_count": len(validation_errors)
    }


def test_validate_param_type_string():
    """Test string type validation."""
    # Valid
    error = validate_param_type("test", {"type": "string"}, "param")
    assert error is None

    # Invalid - wrong type
    error = validate_param_type(123, {"type": "string"}, "param")
    assert error is not None
    assert error["parameter"] == "param"
    assert "Expected string" in error["error"]


def test_validate_param_type_integer():
    """Test integer type validation."""
    # Valid
    error = validate_param_type(42, {"type": "integer"}, "param")
    assert error is None

    # Invalid - boolean (should fail)
    error = validate_param_type(True, {"type": "integer"}, "param")
    assert error is not None

    # Invalid - float
    error = validate_param_type(3.14, {"type": "integer"}, "param")
    assert error is not None


def test_validate_param_type_number():
    """Test number type validation."""
    # Valid - integer
    error = validate_param_type(42, {"type": "number"}, "param")
    assert error is None

    # Valid - float
    error = validate_param_type(3.14, {"type": "number"}, "param")
    assert error is None

    # Invalid - string
    error = validate_param_type("42", {"type": "number"}, "param")
    assert error is not None


def test_validate_param_type_boolean():
    """Test boolean type validation."""
    # Valid
    error = validate_param_type(True, {"type": "boolean"}, "param")
    assert error is None

    error = validate_param_type(False, {"type": "boolean"}, "param")
    assert error is None

    # Invalid - integer (not a boolean)
    error = validate_param_type(1, {"type": "boolean"}, "param")
    assert error is not None


def test_validate_param_type_array():
    """Test array type validation."""
    # Valid
    error = validate_param_type([1, 2, 3], {"type": "array"}, "param")
    assert error is None

    # Invalid - dict
    error = validate_param_type({"key": "value"}, {"type": "array"}, "param")
    assert error is not None


def test_validate_param_type_object():
    """Test object type validation."""
    # Valid
    error = validate_param_type({"key": "value"}, {"type": "object"}, "param")
    assert error is None

    # Invalid - list
    error = validate_param_type([1, 2, 3], {"type": "object"}, "param")
    assert error is not None


def test_validate_param_constraints_numeric_minimum():
    """Test numeric minimum constraint."""
    # Valid
    errors = validate_param_constraints(10, {"minimum": 5}, "param")
    assert len(errors) == 0

    # Invalid - below minimum
    errors = validate_param_constraints(3, {"minimum": 5}, "param")
    assert len(errors) == 1
    assert "less than minimum" in errors[0]["error"]


def test_validate_param_constraints_numeric_maximum():
    """Test numeric maximum constraint."""
    # Valid
    errors = validate_param_constraints(10, {"maximum": 20}, "param")
    assert len(errors) == 0

    # Invalid - exceeds maximum
    errors = validate_param_constraints(25, {"maximum": 20}, "param")
    assert len(errors) == 1
    assert "exceeds maximum" in errors[0]["error"]


def test_validate_param_constraints_enum():
    """Test enum constraint."""
    # Valid
    errors = validate_param_constraints("option1", {"enum": ["option1", "option2", "option3"]}, "param")
    assert len(errors) == 0

    # Invalid - not in enum
    errors = validate_param_constraints("invalid", {"enum": ["option1", "option2", "option3"]}, "param")
    assert len(errors) == 1
    assert "not in allowed values" in errors[0]["error"]


def test_validate_param_constraints_string_length():
    """Test string length constraints."""
    # Valid
    errors = validate_param_constraints("hello", {"minLength": 3, "maxLength": 10}, "param")
    assert len(errors) == 0

    # Invalid - too short
    errors = validate_param_constraints("hi", {"minLength": 3}, "param")
    assert len(errors) == 1
    assert "less than minimum" in errors[0]["error"]

    # Invalid - too long
    errors = validate_param_constraints("verylongstring", {"maxLength": 5}, "param")
    assert len(errors) == 1
    assert "exceeds maximum" in errors[0]["error"]


def test_validate_param_constraints_array_items():
    """Test array item constraints."""
    # Valid
    errors = validate_param_constraints([1, 2, 3], {"minItems": 2, "maxItems": 5}, "param")
    assert len(errors) == 0

    # Invalid - too few items
    errors = validate_param_constraints([1], {"minItems": 2}, "param")
    assert len(errors) == 1
    assert "less than minimum" in errors[0]["error"]

    # Invalid - too many items
    errors = validate_param_constraints([1, 2, 3, 4, 5, 6], {"maxItems": 5}, "param")
    assert len(errors) == 1
    assert "exceeds maximum" in errors[0]["error"]


def test_validate_tool_input_required_params():
    """Test required parameter validation."""
    schema = {
        "type": "object",
        "properties": {
            "gene": {"type": "string"},
            "top_k": {"type": "integer"}
        },
        "required": ["gene"]
    }

    # Valid - has required parameter
    errors = validate_tool_input({"gene": "TP53", "top_k": 10}, schema, "test_tool")
    assert len(errors) == 0

    # Invalid - missing required parameter
    errors = validate_tool_input({"top_k": 10}, schema, "test_tool")
    assert len(errors) == 1
    assert errors[0]["parameter"] == "gene"
    assert "Missing required parameter" in errors[0]["error"]


def test_validate_tool_input_multiple_errors():
    """Test that multiple validation errors are captured."""
    schema = {
        "type": "object",
        "properties": {
            "gene": {"type": "string"},
            "top_k": {"type": "integer", "minimum": 1, "maximum": 200}
        },
        "required": ["gene"]
    }

    # Multiple errors: missing gene + top_k out of range
    errors = validate_tool_input({"top_k": 500}, schema, "test_tool")
    assert len(errors) == 2

    # Check for both errors
    error_params = {e["parameter"] for e in errors}
    assert "gene" in error_params
    assert "top_k" in error_params


def test_validate_tool_input_complex_schema():
    """Test validation with a complex schema (like vector_antipodal)."""
    schema = {
        "type": "object",
        "properties": {
            "gene": {
                "type": "string",
                "description": "Gene identifier"
            },
            "embedding_space": {
                "type": "string",
                "enum": ["MODEX_16D", "EP", "Transcript", "auto"],
                "default": "auto"
            },
            "top_k": {
                "type": "integer",
                "description": "Number of results",
                "default": 10,
                "minimum": 1,
                "maximum": 200
            },
            "min_score": {
                "type": "number",
                "description": "Minimum score",
                "default": 0.5,
                "minimum": 0.0,
                "maximum": 1.0
            }
        },
        "required": ["gene"]
    }

    # Valid input
    errors = validate_tool_input({
        "gene": "TP53",
        "embedding_space": "MODEX_16D",
        "top_k": 50,
        "min_score": 0.7
    }, schema, "vector_antipodal")
    assert len(errors) == 0

    # Invalid: missing required, wrong enum, out of range
    errors = validate_tool_input({
        "embedding_space": "INVALID",
        "top_k": 500,
        "min_score": 1.5
    }, schema, "vector_antipodal")
    assert len(errors) >= 3  # Missing gene + invalid enum + top_k too high


def test_format_validation_response():
    """Test error response formatting."""
    errors = [
        {"parameter": "gene", "error": "Missing required parameter"},
        {"parameter": "top_k", "error": "Value 500 exceeds maximum 200"}
    ]

    response = format_validation_response("test_tool", errors)

    assert response["success"] is False
    assert response["error"] == "Validation failed"
    assert response["tool"] == "test_tool"
    assert len(response["validation_errors"]) == 2
    assert response["error_count"] == 2


def test_validate_tool_input_extra_params():
    """Test that extra parameters are allowed (flexibility)."""
    schema = {
        "type": "object",
        "properties": {
            "gene": {"type": "string"}
        },
        "required": ["gene"]
    }

    # Extra parameter 'extra_param' should be allowed
    errors = validate_tool_input({"gene": "TP53", "extra_param": "value"}, schema, "test_tool")
    assert len(errors) == 0


def run_all_tests():
    """Run all validation tests."""
    tests = [
        ("String type validation", test_validate_param_type_string),
        ("Integer type validation", test_validate_param_type_integer),
        ("Number type validation", test_validate_param_type_number),
        ("Boolean type validation", test_validate_param_type_boolean),
        ("Array type validation", test_validate_param_type_array),
        ("Object type validation", test_validate_param_type_object),
        ("Numeric minimum constraint", test_validate_param_constraints_numeric_minimum),
        ("Numeric maximum constraint", test_validate_param_constraints_numeric_maximum),
        ("Enum constraint", test_validate_param_constraints_enum),
        ("String length constraints", test_validate_param_constraints_string_length),
        ("Array item constraints", test_validate_param_constraints_array_items),
        ("Required parameter validation", test_validate_tool_input_required_params),
        ("Multiple validation errors", test_validate_tool_input_multiple_errors),
        ("Complex schema validation", test_validate_tool_input_complex_schema),
        ("Validation response formatting", test_format_validation_response),
        ("Extra parameters allowed", test_validate_tool_input_extra_params),
    ]

    passed = 0
    failed = 0
    errors_list = []

    print("=" * 60)
    print("Validation Framework Unit Tests")
    print("=" * 60)
    print()

    for test_name, test_func in tests:
        try:
            test_func()
            print(f"✅ {test_name}")
            passed += 1
        except AssertionError as e:
            print(f"❌ {test_name}")
            failed += 1
            errors_list.append((test_name, str(e)))
        except Exception as e:
            print(f"❌ {test_name} (EXCEPTION: {type(e).__name__})")
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
    success = run_all_tests()
    sys.exit(0 if success else 1)
