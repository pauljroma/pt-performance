"""
Semantic Collections Tool - List ChromaDB Collections

ARCHITECTURE DECISION LOG:
v3.0 (current): Pure agentic with atomic tools
  - Lists available semantic search collections
  - Shows collection metadata (count, embedding model)
  - Helps Claude choose the right collection for semantic_search

Pattern: Wraps ChromaDB for collection enumeration
Reference: Week 1 tools for consistent structure
"""

from typing import Dict, Any, List
from pathlib import Path
import sys

# Add path for services
project_root = Path(__file__).parent.parent.parent.parent.parent.parent
sys.path.insert(0, str(project_root))



# Import validation utilities (Stream 1.2: Validation Framework)
try:
    from tool_utils import validate_tool_input, format_validation_response
    VALIDATION_AVAILABLE = True
except ImportError:
    VALIDATION_AVAILABLE = False

# Claude Tool Definition (Anthropic format)
TOOL_DEFINITION = {
    "name": "semantic_collections",
    "description": """List available semantic search collections in ChromaDB.

Returns information about all collections available for semantic search:
- Collection name
- Document count
- Embedding model used
- Description and use cases

Useful before calling semantic_search to know which collections are available.

Examples:
- "What collections can I search?" → Lists all collections
- "Show me literature collections" → Filters to literature
- "How many papers are in the database?" → Returns count

Current collections:
- literature: 29,863 CNS drug discovery papers
- patterns: Experimental protocols and best practices
- (more coming in future releases)
""",
    "input_schema": {
        "type": "object",
        "properties": {},
        "required": []
    }
}


async def execute(tool_input: Dict[str, Any]) -> Dict[str, Any]:
    """
    Execute semantic_collections tool - list ChromaDB collections.

    Args:
        tool_input: Dict (no parameters required)

    Returns:
        Dict with keys:
            - success (bool): Whether operation succeeded
            - collections (List[Dict]): List of collections with metadata
            - total_collections (int): Number of collections
            - total_documents (int): Total document count across all collections
            - error (str, optional): Error message if failed

    Example:
        >>> await execute({})
        {
            "success": True,
            "collections": [
                {
                    "name": "literature",
                    "document_count": 29863,
                    "embedding_model": "all-MiniLM-L6-v2",
                    "description": "CNS drug discovery papers"
                },
                {
                    "name": "patterns",
                    "document_count": 145,
                    "embedding_model": "all-MiniLM-L6-v2",
                    "description": "Experimental protocols and best practices"
                }
            ],
            "total_collections": 2,
            "total_documents": 30008
        }
    """
    # Stream 1.2: Input validation
    if VALIDATION_AVAILABLE:
        validation_errors = validate_tool_input(tool_input, TOOL_DEFINITION["input_schema"], "semantic_collections")
        if validation_errors:
            return format_validation_response("semantic_collections", validation_errors)

    try:
        # Import ChromaDB provider
        try:
            from zones.z08_persist.providers.chroma_provider import get_chroma_client
        except ImportError:
            return {
                "success": False,
                "error": "ChromaDB provider not available",
                "hint": "Check that ChromaDB dependencies are installed"
            }

        # Get ChromaDB client
        chroma_client = get_chroma_client()
        if chroma_client is None:
            return {
                "success": False,
                "error": "ChromaDB client not initialized",
                "hint": "Check that ChromaDB is running and accessible"
            }

        # List all collections
        collections = []
        total_documents = 0

        # Known collection descriptions
        collection_descriptions = {
            "literature": "CNS drug discovery papers (biomedical literature)",
            "patterns": "Experimental protocols and best practices",
            "clinical_trials": "Clinical trial data and outcomes",
            "gene_annotations": "Gene function and pathway annotations"
        }

        try:
            # Get all collections from ChromaDB
            all_collections = chroma_client.list_collections()

            for coll in all_collections:
                # Get collection details
                try:
                    collection_obj = chroma_client.get_collection(name=coll.name)
                    doc_count = collection_obj.count()

                    collections.append({
                        "name": coll.name,
                        "document_count": doc_count,
                        "description": collection_descriptions.get(coll.name, "No description available"),
                        "available_for_semantic_search": True
                    })

                    total_documents += doc_count

                except Exception as e:
                    # Collection exists but can't get details
                    collections.append({
                        "name": coll.name,
                        "document_count": 0,
                        "description": "Unable to retrieve details",
                        "error": str(e)
                    })

        except Exception as e:
            return {
                "success": False,
                "error": f"Error listing collections: {str(e)}",
                "hint": "Check ChromaDB connection and permissions"
            }

        return {
            "success": True,
            "collections": collections,
            "total_collections": len(collections),
            "total_documents": total_documents,
            "usage_hint": "Use semantic_search tool with 'collection' parameter to search these collections"
        }

    except Exception as e:
        # Unexpected error
        return {
            "success": False,
            "error": f"Unexpected error: {str(e)}",
            "error_type": type(e).__name__
        }


# Export tool for registration
__all__ = ["TOOL_DEFINITION", "execute"]
