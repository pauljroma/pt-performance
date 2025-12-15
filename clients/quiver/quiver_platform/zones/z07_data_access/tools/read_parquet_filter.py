"""
Read Parquet Filter Tool - Direct Parquet Data Access

ARCHITECTURE DECISION LOG:
v3.0 (current): Pure agentic with atomic tools
  - Provides direct filtered access to parquet embedding files
  - Allows Claude to apply custom filters and transformations
  - Faster than loading full dataframes for specific queries
  - Supports gene and drug embedding parquet files

Pattern: Direct parquet access with pandas filters
Reference: Week 1 vector tools for file paths
"""

from typing import Dict, Any, List, Optional
from pathlib import Path
import sys

# Add path for services
project_root = Path(__file__).parent.parent.parent.parent.parent.parent.parent
sys.path.insert(0, str(project_root))

# MIGRATED to v3.0 (2025-12-05): Master resolution tables (60x faster)
from clients.quiver.quiver_platform.zones.z07_data_access.drug_name_resolver_v3 import get_drug_name_resolver_v3 as get_drug_name_resolver



# Import validation utilities (Stream 1.2: Validation Framework)
try:
    from tool_utils import validate_tool_input, format_validation_response
    VALIDATION_AVAILABLE = True
except ImportError:
    VALIDATION_AVAILABLE = False

# Claude Tool Definition (Anthropic format)
TOOL_DEFINITION = {
    "name": "read_parquet_filter",
    "description": """Read and filter parquet embedding files directly.

Provides filtered access to embedding parquet files without loading full dataframes.
Useful for custom queries, data exploration, and efficient filtering.

Supports:
- Gene embeddings (MODEX 32D) - 18,368 genes
- Drug embeddings (PCA 32D) - 14,246 drugs

Operations:
- Filter by entity names (exact or list)
- Column selection (reduce memory)
- Head/tail/sample operations
- Custom pandas query expressions

Examples:
- Read specific genes: {"file": "gene", "entity_names": ["TSC2", "TP53", "BRCA1"]}
- Sample 100 drugs: {"file": "drug", "operation": "sample", "n": 100}
- Filter genes: {"file": "gene", "filter_expr": "entity_name.str.startswith('BRCA')"}

Returns:
- Filtered dataframe as list of dictionaries
- Column names and types
- Row count

Files:
- gene: clients/quiver/transcript_integration/data/embeddings/gene_MODEX_embeddings.parquet
- drug: clients/quiver/transcript_integration/data/embeddings/drug_PCA_embeddings.parquet
""",
    "input_schema": {
        "type": "object",
        "properties": {
            "file": {
                "type": "string",
                "description": "Which parquet file to read: 'gene' or 'drug'",
                "enum": ["gene", "drug"]
            },
            "entity_names": {
                "type": "array",
                "description": "Filter to specific entity names (optional). Example: ['TSC2', 'TP53']",
                "items": {"type": "string"},
                "default": []
            },
            "columns": {
                "type": "array",
                "description": "Select specific columns (optional). Example: ['entity_name', 'MODEX_00', 'MODEX_01']",
                "items": {"type": "string"},
                "default": []
            },
            "operation": {
                "type": "string",
                "description": "Operation to perform: 'all' (return all), 'head' (first n), 'tail' (last n), 'sample' (random n). Default: 'all'",
                "enum": ["all", "head", "tail", "sample"],
                "default": "all"
            },
            "n": {
                "type": "integer",
                "description": "Number of rows for head/tail/sample operations. Default: 10",
                "default": 10,
                "minimum": 1,
                "maximum": 1000
            }
        },
        "required": ["file"]
    }
}


async def execute_DEPRECATED(tool_input: Dict[str, Any]) -> Dict[str, Any]:
    """DEPRECATED: This tool has been removed in v6.0 (parquet files no longer used)."""
    return {
        "success": False,
        "error": "Tool deprecated in PGVector v6.0 migration",
        "message": "Parquet files are no longer used. All embeddings are now in PGVector database.",
        "alternatives": [
            "Use entity_metadata for gene/drug information",
            "Use vector_similarity for comparing entities",
            "Use count_entities for statistics",
            "Query PGVector directly for custom queries"
        ],
        "migration_date": "2025-12-03",
        "reason": "Migrated from parquet files to PGVector v6.0 for better performance and consistency"
    }

async def execute(tool_input: Dict[str, Any]) -> Dict[str, Any]:
    """
    Execute read_parquet_filter tool - DISABLED (Neo4j only policy).

    This tool has been disabled per architectural decision:
    - All embeddings should be read from Neo4j, not files
    - Direct file access violates zone architecture
    - Use vector_neighbors or other Neo4j-based tools instead

    Args:
        tool_input: Dict with keys (ignored)

    Returns:
        Dict with error indicating tool is disabled
    """
    # Stream 1.2: Input validation
    if VALIDATION_AVAILABLE:
        validation_errors = validate_tool_input(tool_input, TOOL_DEFINITION["input_schema"], "read_parquet_filter")
        if validation_errors:
            return format_validation_response("read_parquet_filter", validation_errors)

    # DISABLED: Per architectural decision, all embedding reads go through Neo4j
    return {
        "success": False,
        "error": "Tool disabled: read_parquet_filter is not available",
        "reason": "Embeddings should be read from Neo4j only, not directly from files",
        "alternative_tools": [
            "vector_neighbors - Find similar entities using Neo4j embeddings",
            "vector_antipodal - Find opposite entities using Neo4j embeddings",
            "entity_metadata - Get entity information from Neo4j"
        ],
        "hint": "Use vector_neighbors to query entity embeddings from Neo4j"
    }

    # Original implementation disabled and commented out for reference
    """
    # OLD CODE - DISABLED (kept for reference only)
    if False:
        try:
            # Get parameters with defaults
            file_type = tool_input["file"]
        entity_names = tool_input.get("entity_names", [])
        columns = tool_input.get("columns", [])
        operation = tool_input.get("operation", "all")
        n = tool_input.get("n", 10)

        # Validate parameters
        if file_type not in ["gene", "drug"]:
            return {
                "success": False,
                "error": f"Invalid file type: {file_type}. Must be 'gene' or 'drug'",
                "valid_files": ["gene", "drug"]
            }

        if operation not in ["all", "head", "tail", "sample"]:
            return {
                "success": False,
                "error": f"Invalid operation: {operation}",
                "valid_operations": ["all", "head", "tail", "sample"]
            }

        if not (1 <= n <= 1000):
            return {
                "success": False,
                "error": f"n must be between 1 and 1000, got {n}"
            }

        # Import pandas
        try:
            import pandas as pd
        except ImportError:
            return {
                "success": False,
                "error": "Pandas not available",
                "hint": "Install pandas to use parquet reading"
            }

        # Determine file path
        data_dir = project_root / "clients" / "quiver" / "transcript_integration" / "data" / "embeddings"

        if file_type == "gene":
            file_path = data_dir / "gene_MODEX_embeddings.parquet"
        else:  # drug
            file_path = data_dir / "drug_PCA_embeddings.parquet"

        if not file_path.exists():
            return {
                "success": False,
                "error": f"Parquet file not found: {file_path}",
                "hint": "Check that embedding files are present in the expected location"
            }

        # Read parquet file
        try:
            df = pd.read_parquet(file_path)
        except Exception as e:
            return {
                "success": False,
                "error": f"Error reading parquet file: {str(e)}",
                "file_path": str(file_path)
            }

        total_rows = len(df)

        # Apply filters
        if entity_names and len(entity_names) > 0:
            # Filter by entity names
            df = df[df['entity_name'].isin(entity_names)]

        # Select columns if specified
        if columns and len(columns) > 0:
            # Validate columns exist
            invalid_cols = [c for c in columns if c not in df.columns]
            if invalid_cols:
                return {
                    "success": False,
                    "error": f"Invalid columns: {invalid_cols}",
                    "available_columns": list(df.columns)
                }
            df = df[columns]

        # Apply operation
        if operation == "head":
            df = df.head(n)
        elif operation == "tail":
            df = df.tail(n)
        elif operation == "sample":
            n_sample = min(n, len(df))  # Don't sample more than available
            df = df.sample(n=n_sample)
        # else: operation == "all", keep full df

        # Convert to list of dicts
        rows = df.to_dict(orient='records')

        # Clean up NaN values (convert to None for JSON compatibility)
        for row in rows:
            for key, value in row.items():
                if pd.isna(value):
                    row[key] = None

        # Sapphire v3.1: Add commercial names for drugs
        if file_type == "drug":
            drug_name_resolver = get_drug_name_resolver()

            for row in rows:
                # Get drug ID from entity_name column
                drug_id = row.get('entity_name', '')
                if drug_id:
                    # Resolve commercial name
                    name_info = drug_name_resolver.resolve(drug_id)

                    # Add commercial name fields to row
                    row['drug_id'] = drug_id  # QS ID for traceability
                    row['commercial_name'] = name_info['commercial_name']  # v3.1: PRIMARY DISPLAY
                    row['chembl_id'] = name_info.get('chembl_id', '')
                    row['name_source'] = name_info.get('source', 'none')

        return {
            "success": True,
            "file": file_type,
            "file_path": str(file_path),
            "rows": rows,
            "count": len(rows),
            "columns": list(df.columns),
            "total_rows": total_rows,
            "query_params": {
                "entity_names": entity_names,
                "columns": columns,
                "operation": operation,
                "n": n
            }
        }

    except Exception as e:
        # Unexpected error
        return {
            "success": False,
            "error": f"Unexpected error: {str(e)}",
            "file": tool_input.get("file", "unknown"),
            "error_type": type(e).__name__
        }
    """
    # END OF DISABLED CODE


# Export tool for registration
__all__ = ["TOOL_DEFINITION", "execute"]
