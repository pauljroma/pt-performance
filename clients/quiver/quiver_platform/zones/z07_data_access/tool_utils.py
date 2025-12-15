#!/usr/bin/env python3
"""
Tool Utilities - Shared harmonization and validation for Sapphire tools

Provides centralized identifier harmonization and validation for all 27 Sapphire tools.

Features:
- Drug identifier harmonization (RxNorm ↔ ChEMBL ↔ LINCS)
- Gene identifier harmonization (HGNC ↔ Entrez ↔ UniProt ↔ STRING)
- Input validation for all identifier types
- Schema-based tool input validation (Stream 1.2)
- Singleton pattern for efficient reuse across tools

Usage:
    >>> from tool_utils import get_drug_harmonizer, harmonize_drug_id
    >>> harmonizer = get_drug_harmonizer()
    >>> all_ids = harmonizer.get_all_identifiers(chembl_id="CHEMBL1234")

    >>> # Or use convenience functions
    >>> harmonize_drug_id("aspirin")  # Returns dict with all IDs
    >>> harmonize_gene_id("TP53")     # Returns dict with all IDs
    >>> validate_input("gene", "TP53")  # Returns (True, None) or (False, error_msg)

    >>> # Schema-based validation (Stream 1.2)
    >>> errors = validate_tool_input({"gene": "TP53"}, TOOL_DEFINITION["input_schema"], "vector_antipodal")
    >>> if errors:
    >>>     return format_validation_response("vector_antipodal", errors)

Author: Sapphire v4.0 Integration
Date: 2025-11-29
Version: 1.1 (Stream 1.2: Validation Framework)
"""

from typing import Optional, Dict, Any, Tuple, Union, List
import logging
from functools import lru_cache
import sys
import re
from pathlib import Path

# Add zone paths for imports
project_root = Path(__file__).parents[3]
sys.path.insert(0, str(project_root))

from zones.z10c_utility.identifiers.drug_harmonizer import DrugHarmonizer
from zones.z10c_utility.identifiers.gene_harmonizer import GeneHarmonizer
from zones.z10c_utility.utils import validation

logger = logging.getLogger(__name__)

# Singleton instances (initialized once, reused across all tools)
_drug_harmonizer: Optional[DrugHarmonizer] = None
_gene_harmonizer: Optional[GeneHarmonizer] = None


def get_drug_harmonizer() -> DrugHarmonizer:
    """
    Get or create the singleton DrugHarmonizer instance.

    Returns:
        DrugHarmonizer instance with LRU caching enabled

    Example:
        >>> harmonizer = get_drug_harmonizer()
        >>> chembl_id = harmonizer.rxnorm_to_chembl("1234567")
    """
    global _drug_harmonizer

    if _drug_harmonizer is None:
        logger.info("Initializing DrugHarmonizer singleton")
        _drug_harmonizer = DrugHarmonizer()
        logger.info(f"DrugHarmonizer ready: {_drug_harmonizer.get_mapping_stats()}")

    return _drug_harmonizer


def get_gene_harmonizer() -> GeneHarmonizer:
    """
    Get or create the singleton GeneHarmonizer instance.

    Returns:
        GeneHarmonizer instance with LRU caching enabled

    Example:
        >>> harmonizer = get_gene_harmonizer()
        >>> entrez_id = harmonizer.hgnc_to_entrez("TP53")
    """
    global _gene_harmonizer

    if _gene_harmonizer is None:
        logger.info("Initializing GeneHarmonizer singleton")
        _gene_harmonizer = GeneHarmonizer()
        logger.info(f"GeneHarmonizer ready: {_gene_harmonizer.get_mapping_stats()}")

    return _gene_harmonizer


def harmonize_drug_id(
    drug_id: str,
    id_type: Optional[str] = None
) -> Dict[str, Any]:
    """
    Harmonize drug identifier to all known formats.

    Automatically detects ID type if not specified:
    - ChEMBL format: CHEMBL followed by digits
    - RxNorm format: digits only
    - LINCS format: BRD-K followed by digits
    - Drug name: anything else (requires database lookup)

    Args:
        drug_id: Drug identifier in any format
        id_type: Optional explicit type ("chembl", "rxnorm", "lincs", "name")

    Returns:
        Dictionary with all found identifiers:
        {
            "rxnorm_id": str or None,
            "chembl_id": str or None,
            "lincs_pert_ids": List[str],
            "drug_name": str or None,
            "id_type_detected": str,
            "success": bool
        }

    Example:
        >>> harmonize_drug_id("CHEMBL1234")
        {
            'rxnorm_id': '1234567',
            'chembl_id': 'CHEMBL1234',
            'lincs_pert_ids': ['BRD-K12345678'],
            'drug_name': 'Aspirin',
            'id_type_detected': 'chembl',
            'success': True
        }
    """
    harmonizer = get_drug_harmonizer()

    # Detect ID type if not specified
    if id_type is None:
        if validation.validate_chembl_id(drug_id):
            id_type = "chembl"
        elif validation.validate_rxnorm_id(drug_id):
            id_type = "rxnorm"
        elif drug_id.startswith("BRD-K"):
            id_type = "lincs"
        else:
            id_type = "name"

    result = {
        "rxnorm_id": None,
        "chembl_id": None,
        "lincs_pert_ids": [],
        "drug_name": None,
        "id_type_detected": id_type,
        "success": False
    }

    try:
        # Perform harmonization based on ID type
        if id_type == "chembl":
            ids = harmonizer.get_all_identifiers(chembl_id=drug_id)
            result.update(ids)
            result["success"] = ids["chembl_id"] is not None

        elif id_type == "rxnorm":
            ids = harmonizer.get_all_identifiers(rxnorm_id=drug_id)
            result.update(ids)
            result["drug_name"] = harmonizer.get_drug_name(drug_id)
            result["success"] = ids["rxnorm_id"] is not None

        elif id_type == "lincs":
            ids = harmonizer.get_all_identifiers(lincs_pert_id=drug_id)
            result.update(ids)
            result["success"] = len(ids["lincs_pert_ids"]) > 0

        elif id_type == "name":
            # For drug names, we'd need a name→RxNorm lookup
            # This would require additional database queries
            # For now, return the name as-is
            result["drug_name"] = drug_id
            result["success"] = True

    except Exception as e:
        logger.error(f"Error harmonizing drug ID '{drug_id}': {e}")
        result["error"] = str(e)

    return result


def harmonize_gene_id(
    gene_id: str,
    id_type: Optional[str] = None
) -> Dict[str, Any]:
    """
    Harmonize gene identifier to all known formats.

    Automatically detects ID type if not specified:
    - HGNC symbol: uppercase letters/numbers/hyphens (e.g., TP53, IL-6)
    - Entrez ID: digits only
    - UniProt ID: uppercase letters + digits (e.g., P04637)
    - STRING ID: organism.ENS... format

    Args:
        gene_id: Gene identifier in any format
        id_type: Optional explicit type ("hgnc", "entrez", "uniprot", "string")

    Returns:
        Dictionary with all found identifiers:
        {
            "hgnc_symbol": str or None,
            "entrez_id": str or None,
            "uniprot_id": str or None,
            "string_id": str or None,
            "id_type_detected": str,
            "success": bool
        }

    Example:
        >>> harmonize_gene_id("TP53")
        {
            'hgnc_symbol': 'TP53',
            'entrez_id': '7157',
            'uniprot_id': 'P04637',
            'string_id': '9606.ENSP00000269305',
            'id_type_detected': 'hgnc',
            'success': True
        }
    """
    harmonizer = get_gene_harmonizer()

    # Detect ID type if not specified
    if id_type is None:
        if validation.validate_gene_symbol(gene_id):
            id_type = "hgnc"
        elif gene_id.isdigit():
            id_type = "entrez"
        elif validation.validate_string_id(gene_id):
            id_type = "string"
        elif len(gene_id) == 6 and gene_id[0].isalpha():
            id_type = "uniprot"  # Heuristic for UniProt
        else:
            id_type = "hgnc"  # Default to HGNC

    result = {
        "hgnc_symbol": None,
        "entrez_id": None,
        "uniprot_id": None,
        "string_id": None,
        "id_type_detected": id_type,
        "success": False
    }

    try:
        # Perform harmonization based on ID type
        if id_type == "hgnc":
            ids = harmonizer.get_all_identifiers(hgnc_symbol=gene_id)
            result.update(ids)
            result["success"] = ids["hgnc_symbol"] is not None

        elif id_type == "entrez":
            ids = harmonizer.get_all_identifiers(entrez_id=gene_id)
            result.update(ids)
            result["success"] = ids["entrez_id"] is not None

        elif id_type == "uniprot":
            ids = harmonizer.get_all_identifiers(uniprot_id=gene_id)
            result.update(ids)
            result["success"] = ids["uniprot_id"] is not None

        elif id_type == "string":
            ids = harmonizer.get_all_identifiers(string_id=gene_id)
            result.update(ids)
            result["success"] = ids["string_id"] is not None

    except Exception as e:
        logger.error(f"Error harmonizing gene ID '{gene_id}': {e}")
        result["error"] = str(e)

    return result


def validate_input(
    input_type: str,
    value: Any,
    **kwargs
) -> Tuple[bool, Optional[str]]:
    """
    Validate input value based on type.

    Supported input types:
    - "chembl_id": ChEMBL identifier
    - "gene_symbol": HGNC gene symbol
    - "rxnorm_id": RxNorm concept ID
    - "string_id": STRING protein ID
    - "embedding": Numpy array (requires expected_dims kwarg)
    - "numeric_range": Numeric value (requires min_value/max_value kwargs)
    - "date": Date string (requires format kwarg)

    Args:
        input_type: Type of validation to perform
        value: Value to validate
        **kwargs: Additional type-specific parameters

    Returns:
        Tuple of (is_valid, error_message)
        error_message is None if valid

    Example:
        >>> validate_input("chembl_id", "CHEMBL1234")
        (True, None)

        >>> validate_input("gene_symbol", "invalid_gene")
        (False, "Invalid HGNC gene symbol format")

        >>> validate_input("numeric_range", 50, min_value=0, max_value=100)
        (True, None)
    """
    try:
        if input_type == "chembl_id":
            if validation.validate_chembl_id(value):
                return (True, None)
            return (False, f"Invalid ChEMBL ID format: '{value}'. Expected: CHEMBL followed by digits")

        elif input_type == "gene_symbol":
            if validation.validate_gene_symbol(value):
                return (True, None)
            return (False, f"Invalid HGNC gene symbol format: '{value}'. Expected: uppercase letters/numbers/hyphens")

        elif input_type == "rxnorm_id":
            if validation.validate_rxnorm_id(value):
                return (True, None)
            return (False, f"Invalid RxNorm ID format: '{value}'. Expected: digits only")

        elif input_type == "string_id":
            if validation.validate_string_id(value):
                return (True, None)
            return (False, f"Invalid STRING ID format: '{value}'. Expected: organism.ENSP...")

        elif input_type == "embedding":
            expected_dims = kwargs.get("expected_dims")
            if expected_dims is None:
                return (False, "expected_dims parameter required for embedding validation")

            if not validation.validate_embedding_dimensions(value, expected_dims):
                return (False, f"Invalid embedding dimensions. Expected: {expected_dims}, Got: {value.shape[0] if hasattr(value, 'shape') else 'N/A'}")

            if not validation.validate_embedding_values(value):
                return (False, "Embedding contains invalid values (NaN or Inf)")

            return (True, None)

        elif input_type == "numeric_range":
            min_value = kwargs.get("min_value")
            max_value = kwargs.get("max_value")

            if not validation.validate_numeric_range(value, min_value, max_value):
                return (False, f"Value {value} out of range [{min_value}, {max_value}]")

            return (True, None)

        elif input_type == "date":
            date_format = kwargs.get("format", "%Y-%m-%d")

            if not validation.validate_date_format(value, date_format):
                return (False, f"Invalid date format. Expected: {date_format}")

            return (True, None)

        else:
            return (False, f"Unknown input type: {input_type}")

    except Exception as e:
        return (False, f"Validation error: {str(e)}")


def normalize_gene_symbol(gene_symbol: str) -> str:
    """
    Normalize gene symbol to standard format (uppercase).

    Args:
        gene_symbol: Gene symbol in any case

    Returns:
        Uppercase gene symbol

    Example:
        >>> normalize_gene_symbol("tp53")
        'TP53'
    """
    return gene_symbol.upper().strip()


def format_validation_error(
    tool_name: str,
    param_name: str,
    error_message: str
) -> Dict[str, Any]:
    """
    Format validation error for tool response (legacy function).

    Args:
        tool_name: Name of the tool
        param_name: Parameter that failed validation
        error_message: Validation error message

    Returns:
        Formatted error response dict

    Example:
        >>> format_validation_error("vector_antipodal", "gene", "Invalid gene symbol")
        {
            'success': False,
            'error': 'Validation error in vector_antipodal',
            'parameter': 'gene',
            'details': 'Invalid gene symbol',
            'hint': 'Please provide a valid gene identifier'
        }
    """
    return {
        "success": False,
        "error": f"Validation error in {tool_name}",
        "parameter": param_name,
        "details": error_message,
        "hint": "Please provide a valid identifier or check the tool documentation"
    }


# ============================================================================
# STREAM 1.2: SCHEMA-BASED VALIDATION FRAMEWORK
# ============================================================================

def validate_tool_input(
    tool_input: Dict[str, Any],
    input_schema: Dict[str, Any],
    tool_name: str
) -> List[Dict[str, str]]:
    """
    Validate tool input against JSON Schema definition.

    This is the main validation entry point for all tools. It validates:
    - Required parameters are present
    - Parameter types match schema
    - Parameter values meet constraints (min, max, enum, pattern, etc.)

    Args:
        tool_input: Input parameters from user/Claude
        input_schema: JSON Schema from TOOL_DEFINITION["input_schema"]
        tool_name: Tool name for error messages

    Returns:
        List of validation errors (empty if valid):
        [
            {"parameter": "gene", "error": "Missing required parameter"},
            {"parameter": "top_k", "error": "Value 500 exceeds maximum 200"}
        ]

    Example:
        >>> schema = {"type": "object", "properties": {"gene": {"type": "string"}}, "required": ["gene"]}
        >>> errors = validate_tool_input({"gene": "TP53"}, schema, "vector_antipodal")
        >>> if errors:
        >>>     return format_validation_response("vector_antipodal", errors)
    """
    errors = []

    # Validate schema structure
    if not isinstance(input_schema, dict):
        errors.append({"parameter": "_schema", "error": "Invalid input schema"})
        return errors

    # Get schema properties
    properties = input_schema.get("properties", {})
    required_params = input_schema.get("required", [])

    # Step 1: Check required parameters
    for param in required_params:
        if param not in tool_input or tool_input[param] is None:
            errors.append({
                "parameter": param,
                "error": "Missing required parameter"
            })

    # Step 2: Validate each provided parameter
    for param_name, param_value in tool_input.items():
        # Skip validation if not in schema (allow extra params for flexibility)
        if param_name not in properties:
            continue

        param_schema = properties[param_name]

        # Validate type
        type_error = validate_param_type(param_value, param_schema, param_name)
        if type_error:
            errors.append(type_error)
            continue  # Skip constraint validation if type is wrong

        # Validate constraints
        constraint_errors = validate_param_constraints(param_value, param_schema, param_name)
        errors.extend(constraint_errors)

    return errors


def validate_param_type(
    value: Any,
    param_schema: Dict[str, Any],
    param_name: str
) -> Optional[Dict[str, str]]:
    """
    Validate parameter type matches schema.

    Supports JSON Schema types:
    - string, integer, number, boolean, array, object, null

    Args:
        value: Parameter value to validate
        param_schema: Schema definition for this parameter
        param_name: Parameter name for error messages

    Returns:
        Error dict if invalid, None if valid

    Example:
        >>> validate_param_type("TP53", {"type": "string"}, "gene")
        None  # Valid

        >>> validate_param_type("TP53", {"type": "integer"}, "top_k")
        {"parameter": "top_k", "error": "Expected integer, got string"}
    """
    expected_type = param_schema.get("type")

    if not expected_type:
        return None  # No type constraint

    # Handle null values
    if value is None:
        if expected_type == "null":
            return None
        return {
            "parameter": param_name,
            "error": f"Expected {expected_type}, got null"
        }

    # Type mapping: Python type → JSON Schema type
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
    """
    Validate parameter value meets schema constraints.

    Supports JSON Schema constraints:
    - Numeric: minimum, maximum, exclusiveMinimum, exclusiveMaximum
    - String: minLength, maxLength, pattern, enum
    - Array: minItems, maxItems, uniqueItems
    - General: enum

    Args:
        value: Parameter value to validate
        param_schema: Schema definition for this parameter
        param_name: Parameter name for error messages

    Returns:
        List of validation errors (empty if valid)

    Example:
        >>> validate_param_constraints(500, {"minimum": 1, "maximum": 200}, "top_k")
        [{"parameter": "top_k", "error": "Value 500 exceeds maximum 200"}]
    """
    errors = []

    # Enum validation (applies to all types)
    if "enum" in param_schema:
        allowed_values = param_schema["enum"]
        if value not in allowed_values:
            errors.append({
                "parameter": param_name,
                "error": f"Value '{value}' not in allowed values: {allowed_values}"
            })

    # Numeric constraints
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        # Minimum
        if "minimum" in param_schema:
            if value < param_schema["minimum"]:
                errors.append({
                    "parameter": param_name,
                    "error": f"Value {value} is less than minimum {param_schema['minimum']}"
                })

        # Maximum
        if "maximum" in param_schema:
            if value > param_schema["maximum"]:
                errors.append({
                    "parameter": param_name,
                    "error": f"Value {value} exceeds maximum {param_schema['maximum']}"
                })

        # Exclusive minimum
        if "exclusiveMinimum" in param_schema:
            if value <= param_schema["exclusiveMinimum"]:
                errors.append({
                    "parameter": param_name,
                    "error": f"Value {value} must be greater than {param_schema['exclusiveMinimum']}"
                })

        # Exclusive maximum
        if "exclusiveMaximum" in param_schema:
            if value >= param_schema["exclusiveMaximum"]:
                errors.append({
                    "parameter": param_name,
                    "error": f"Value {value} must be less than {param_schema['exclusiveMaximum']}"
                })

    # String constraints
    if isinstance(value, str):
        # Min length
        if "minLength" in param_schema:
            if len(value) < param_schema["minLength"]:
                errors.append({
                    "parameter": param_name,
                    "error": f"String length {len(value)} is less than minimum {param_schema['minLength']}"
                })

        # Max length
        if "maxLength" in param_schema:
            if len(value) > param_schema["maxLength"]:
                errors.append({
                    "parameter": param_name,
                    "error": f"String length {len(value)} exceeds maximum {param_schema['maxLength']}"
                })

        # Pattern (regex)
        if "pattern" in param_schema:
            pattern = param_schema["pattern"]
            if not re.match(pattern, value):
                errors.append({
                    "parameter": param_name,
                    "error": f"Value '{value}' does not match required pattern: {pattern}"
                })

    # Array constraints
    if isinstance(value, list):
        # Min items
        if "minItems" in param_schema:
            if len(value) < param_schema["minItems"]:
                errors.append({
                    "parameter": param_name,
                    "error": f"Array length {len(value)} is less than minimum {param_schema['minItems']}"
                })

        # Max items
        if "maxItems" in param_schema:
            if len(value) > param_schema["maxItems"]:
                errors.append({
                    "parameter": param_name,
                    "error": f"Array length {len(value)} exceeds maximum {param_schema['maxItems']}"
                })

        # Unique items
        if param_schema.get("uniqueItems", False):
            if len(value) != len(set(map(str, value))):  # Convert to str for hashability
                errors.append({
                    "parameter": param_name,
                    "error": "Array contains duplicate items"
                })

    return errors


def format_validation_response(
    tool_name: str,
    validation_errors: List[Dict[str, str]]
) -> Dict[str, Any]:
    """
    Format validation errors into standardized tool response.

    Args:
        tool_name: Name of the tool
        validation_errors: List of validation errors from validate_tool_input()

    Returns:
        Formatted error response dict with all validation errors

    Example:
        >>> errors = [
        ...     {"parameter": "gene", "error": "Missing required parameter"},
        ...     {"parameter": "top_k", "error": "Value 500 exceeds maximum 200"}
        ... ]
        >>> format_validation_response("vector_antipodal", errors)
        {
            "success": False,
            "error": "Validation failed",
            "tool": "vector_antipodal",
            "validation_errors": [
                {"parameter": "gene", "error": "Missing required parameter"},
                {"parameter": "top_k", "error": "Value 500 exceeds maximum 200"}
            ],
            "error_count": 2
        }
    """
    return {
        "success": False,
        "error": "Validation failed",
        "tool": tool_name,
        "validation_errors": validation_errors,
        "error_count": len(validation_errors)
    }


# Pre-initialize harmonizers on module import for faster first access
# This happens once when any tool first imports this module
try:
    get_drug_harmonizer()
    get_gene_harmonizer()
    logger.info("Tool utilities initialized successfully")
except Exception as e:
    logger.warning(f"Failed to pre-initialize harmonizers: {e}. Will initialize on first use.")
