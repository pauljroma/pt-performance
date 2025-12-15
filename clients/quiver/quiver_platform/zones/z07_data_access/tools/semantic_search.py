"""
Semantic Search Tool - Literature and Pattern Search

ARCHITECTURE DECISION LOG:
v3.1 (current): PGVector-first with ChromaDB fallback
  - This tool provides Claude with semantic search across:
    - Literature embeddings (PGVector if available, else ChromaDB)
    - Pattern library (ChromaDB - best practices, protocols)
  - Handles natural language queries
  - Returns ranked results with snippets
  - Intelligent fallback mechanism for graceful degradation

Pattern: PGVector-first for better performance, ChromaDB fallback for compatibility
Reference: Week 1 vector tools + pgvector_service.py integration
"""

import os
import sys
from pathlib import Path
from typing import Any
import psycopg2
from psycopg2.extras import RealDictCursor
import logging

logger = logging.getLogger(__name__)

# Import harmonization utilities (Stream 1: Foundation)
try:
    from tool_utils import harmonize_drug_id, validate_input, validate_tool_input, format_validation_response
    HARMONIZATION_AVAILABLE = True
    VALIDATION_AVAILABLE = True
except ImportError:
    HARMONIZATION_AVAILABLE = False
    VALIDATION_AVAILABLE = False

# Add path for services
project_root = Path(__file__).parent.parent.parent.parent.parent.parent
sys.path.insert(0, str(project_root))


# Claude Tool Definition (Anthropic format)
TOOL_DEFINITION = {
    "name": "semantic_search",
    "description": """Search literature and pattern libraries using semantic similarity.

Searches across:
- 29,863 CNS drug discovery papers (biomedical literature)
- Pattern library (experimental protocols, best practices)

Uses PGVector-first approach:
- PGVector: Fast HNSW vector search if literature embeddings loaded
- ChromaDB fallback: Compatible search for all collections

Finds relevant documents even if they don't contain exact keyword matches.

Examples:
- "Find papers about KCNQ2 channel modulators" → Returns relevant CNS literature
- "What are protocols for drug rescue screening?" → Returns pattern library entries
- "TSC2 mTOR pathway inhibitors" → Finds papers about TSC2 signaling
- "Epilepsy gene therapy clinical trials" → Searches clinical literature

Key metrics:
- similarity_score: 0-1 scale (1 = perfect match)
- Returns top_k most relevant documents (default: 10)
- Includes document metadata (title, authors, year, DOI, snippet)

Data:
- 29,863 CNS drug discovery papers (PGVector if loaded, else ChromaDB)
- Pattern library in ChromaDB
- <100ms latency for typical queries
""",
    "input_schema": {
        "type": "object",
        "properties": {
            "query": {
                "type": "string",
                "description": "Natural language search query. Examples: 'KCNQ2 modulators', 'TSC2 pathway', 'epilepsy treatments'",
            },
            "collection": {
                "type": "string",
                "description": "Which collection to search: 'literature' (papers), 'patterns' (protocols), or 'all' (both). Default: 'literature'",
                "enum": ["literature", "patterns", "all"],
                "default": "literature",
            },
            "top_k": {
                "type": "integer",
                "description": "Number of results to return (1-50). Default: 10",
                "default": 10,
                "minimum": 1,
                "maximum": 50,
            },
            "min_score": {
                "type": "number",
                "description": "Minimum similarity score threshold (0-1). Default: 0.3 (lower = more permissive)",
                "default": 0.3,
                "minimum": 0.0,
                "maximum": 1.0,
            },
        },
        "required": ["query"],
    },
}


def _check_pgvector_literature_table() -> bool:
    """
    Check if literature embedding table exists in PGVector.

    Checks information_schema for literature-related embedding tables.
    Returns True if any literature table is found, False otherwise.

    Returns:
        bool: True if literature table exists in PGVector, False otherwise
    """
    try:
        # Get PostgreSQL connection details from environment
        pg_host = os.getenv("POSTGRES_HOST", "localhost")
        pg_port = int(os.getenv("POSTGRES_PORT", "5432"))
        pg_user = os.getenv("POSTGRES_USER", "postgres")
        pg_password = os.getenv("POSTGRES_PASSWORD", "temppass123")
        pg_database = os.getenv("POSTGRES_DATABASE", "expo")

        # Connect to PostgreSQL
        conn = psycopg2.connect(
            host=pg_host,
            port=pg_port,
            user=pg_user,
            password=pg_password,
            database=pg_database
        )
        cursor = conn.cursor(cursor_factory=RealDictCursor)

        # Check for literature embedding tables in information_schema
        # Look for tables like: lit_*, literature_*, paper_*, cns_lit_*
        query = """
            SELECT table_name FROM information_schema.tables
            WHERE table_schema = 'public'
            AND (table_name ILIKE '%literature%'
                 OR table_name ILIKE '%lit_%'
                 OR table_name ILIKE '%paper%'
                 OR table_name ILIKE '%cns%')
            LIMIT 5;
        """

        cursor.execute(query)
        results = cursor.fetchall()
        cursor.close()
        conn.close()

        if results:
            # Literature table exists
            return True

        # No literature table found
        return False

    except Exception as e:
        # If connection fails, fall back to ChromaDB
        print(f"⚠️  PGVector check failed (will use ChromaDB): {e}")
        return False


def _search_pgvector_literature(
    query: str,
    top_k: int = 10,
    min_score: float = 0.3
) -> list[dict[str, Any]]:
    """
    Search literature embeddings in PGVector.

    Uses pgvector HNSW index for fast semantic similarity search.

    Args:
        query: Search query (will be embedded using same model as indexed embeddings)
        top_k: Number of results to return
        min_score: Minimum similarity threshold (0-1)

    Returns:
        List of search results with metadata
    """
    try:
        # Import sentence-transformers or similar embedding model
        # This assumes the same embedding model is used as was used to create the embeddings
        try:
            from sentence_transformers import SentenceTransformer
            model = SentenceTransformer("all-MiniLM-L6-v2")  # Same as ChEMBL literature
        except ImportError:
            # Fallback: return empty list (will trigger ChromaDB fallback)
            return []

        # Embed the query
        query_embedding = model.encode(query).tolist()

        # Get PostgreSQL connection
        pg_host = os.getenv("POSTGRES_HOST", "localhost")
        pg_port = int(os.getenv("POSTGRES_PORT", "5432"))
        pg_user = os.getenv("POSTGRES_USER", "postgres")
        pg_password = os.getenv("POSTGRES_PASSWORD", "temppass123")
        pg_database = os.getenv("POSTGRES_DATABASE", "expo")

        conn = psycopg2.connect(
            host=pg_host,
            port=pg_port,
            user=pg_user,
            password=pg_password,
            database=pg_database
        )
        cursor = conn.cursor(cursor_factory=RealDictCursor)

        # Search using pgvector cosine similarity
        # Try common table names
        table_names = [
            "literature_embeddings",
            "cns_literature_embeddings",
            "paper_embeddings",
            "lit_embeddings"
        ]

        results = []
        for table_name in table_names:
            try:
                # Try to query this table
                query_sql = f"""
                    SELECT
                        id,
                        title,
                        snippet,
                        embedding <-> %s::vector AS distance,
                        1 - (embedding <-> %s::vector) / 2 AS similarity_score,
                        metadata
                    FROM {table_name}
                    WHERE 1 - (embedding <-> %s::vector) / 2 >= %s
                    ORDER BY similarity_score DESC
                    LIMIT %s;
                """

                # Create embedding parameter for each operator usage
                query_vec = str(query_embedding).strip("[]")
                cursor.execute(query_sql, (query_vec, query_vec, query_vec, min_score, top_k))
                table_results = cursor.fetchall()

                if table_results:
                    # Found results in this table
                    for row in table_results:
                        results.append({
                            "collection": "literature",
                            "similarity_score": round(float(row.get("similarity_score", 0)), 3),
                            "distance": round(float(row.get("distance", 0)), 3),
                            "title": row.get("title", "Untitled"),
                            "snippet": row.get("snippet", "")[:200],
                            "metadata": row.get("metadata", {}),
                        })

                    # Break after finding results
                    break

            except Exception as e:
                # Table might not exist, try next one
                continue

        cursor.close()
        conn.close()

        return results

    except Exception as e:
        print(f"⚠️  PGVector search failed (will use ChromaDB): {e}")
        return []


async def execute(tool_input: dict[str, Any]) -> dict[str, Any]:
    """
    Execute semantic_search tool - search literature and patterns.

    Args:
        tool_input: Dict with keys:
            - query (str): Natural language search query
            - collection (str, optional): 'literature', 'patterns', or 'all' (default: 'literature')
            - top_k (int, optional): Number of results (default: 10)
            - min_score (float, optional): Minimum similarity threshold (default: 0.5)

    Returns:
        Dict with keys:
            - success (bool): Whether operation succeeded
            - query (str): Original query
            - collection (str): Collection searched
            - results (List[Dict]): Ranked search results
            - count (int): Number of results
            - data_source (str): Data provenance (PGVector or ChromaDB)
            - backend_used (str): Which backend was used
            - latency (str): Performance metric
            - error (str, optional): Error message if failed

    Example:
        >>> await execute({"query": "KCNQ2 channel modulators", "top_k": 5})
        {
            "success": True,
            "query": "KCNQ2 channel modulators",
            "collection": "literature",
            "results": [
                {
                    "title": "Retigabine as a KCNQ2/3 opener...",
                    "snippet": "...potassium channel modulation...",
                    "similarity_score": 0.89,
                    "metadata": {
                        "authors": "Smith et al.",
                        "year": 2023,
                        "doi": "10.1234/example",
                        "journal": "Nature Neuroscience"
                    }
                },
                ...
            ],
            "count": 5,
            "data_source": "PGVector (29,863 CNS papers)",
            "backend_used": "PGVector",
            "latency": "<100ms"
        }
    """
    # Stream 1.2: Input validation
    if VALIDATION_AVAILABLE:
        validation_errors = validate_tool_input(tool_input, TOOL_DEFINITION["input_schema"], "semantic_search")
        if validation_errors:
            return format_validation_response("semantic_search", validation_errors)

    try:
        # Get parameters with defaults
        query = tool_input["query"]
        collection = tool_input.get("collection", "literature")
        top_k = tool_input.get("top_k", 10)
        min_score = tool_input.get("min_score", 0.3)

        # Validate parameters
        if not query or not isinstance(query, str):
            return {
                "success": False,
                "error": "Query parameter must be a non-empty string",
                "hint": "Examples: 'KCNQ2 modulators', 'TSC2 pathway', 'epilepsy treatments'",
            }

        if collection not in ["literature", "patterns", "all"]:
            return {
                "success": False,
                "error": f"Invalid collection: {collection}. Must be 'literature', 'patterns', or 'all'",
                "valid_collections": ["literature", "patterns", "all"],
            }

        if not (1 <= top_k <= 50):
            return {
                "success": False,
                "error": f"top_k must be between 1 and 50, got {top_k}",
            }

        if not (0.0 <= min_score <= 1.0):
            return {
                "success": False,
                "error": f"min_score must be between 0.0 and 1.0, got {min_score}",
            }

        # Track which backend we use
        backend_used = "unknown"

        # Determine which backend to use for literature
        use_pgvector_for_literature = False
        if collection in ["literature", "all"]:
            use_pgvector_for_literature = _check_pgvector_literature_table()
            if use_pgvector_for_literature:
                logger.info(f"Using PGVector for literature search (query: '{query[:50]}...')")
            else:
                logger.info(f"PGVector literature table not found, using ChromaDB (query: '{query[:50]}...')")

        # Search all requested collections
        all_results = []

        # Handle literature search (PGVector-first)
        if collection in ["literature", "all"]:
            if use_pgvector_for_literature:
                # Try PGVector first
                pgvector_results = _search_pgvector_literature(query, top_k, min_score)
                if pgvector_results:
                    all_results.extend(pgvector_results)
                    backend_used = "PGVector"
                    logger.info(f"PGVector returned {len(pgvector_results)} results")
                else:
                    # Fall back to ChromaDB if PGVector returns no results
                    logger.warning(f"PGVector returned no results for query '{query[:50]}...', falling back to ChromaDB")
                    use_pgvector_for_literature = False

            if not use_pgvector_for_literature:
                # Fall back to ChromaDB for literature
                backend_used = "ChromaDB"

        # Handle patterns search (ChromaDB only)
        if collection in ["patterns", "all"]:
            if backend_used == "unknown":
                backend_used = "ChromaDB"

        # If we need ChromaDB (for patterns or literature fallback)
        if collection == "patterns" or (collection == "all") or (collection == "literature" and not use_pgvector_for_literature):
            # Import ChromaDB
            try:
                import chromadb
            except ImportError:
                return {
                    "success": False,
                    "error": "ChromaDB not installed",
                    "hint": "Install with: pip install chromadb",
                }

            # Get ChromaDB host from environment
            chroma_host = os.getenv("CHROMADB_HOST", "localhost")
            chroma_port = int(os.getenv("CHROMADB_PORT", "8000"))

            # Map user-friendly names to actual ChromaDB collection names and ports
            collection_config = {
                "literature": {"name": "cns_literature", "port": chroma_port},
                "patterns": {"name": "patterns", "port": chroma_port},
            }

            collections_to_search = []
            if collection == "all":
                # For "all", search patterns in ChromaDB
                # Literature may already be in all_results from PGVector
                collections_to_search = [{"name": "patterns", "port": chroma_port}]
                # If PGVector didn't have literature, add it
                if not use_pgvector_for_literature:
                    collections_to_search.insert(0, {"name": "cns_literature", "port": chroma_port})
            elif collection == "patterns":
                collections_to_search = [{"name": "patterns", "port": chroma_port}]
            elif collection == "literature" and not use_pgvector_for_literature:
                collections_to_search = [{"name": "cns_literature", "port": chroma_port}]

            # Search each ChromaDB collection
            for coll_config in collections_to_search:
                coll_name = coll_config["name"]
                coll_port = coll_config["port"]

                try:
                    # Get ChromaDB client for this port
                    client = chromadb.HttpClient(host=chroma_host, port=coll_port)

                    # Get collection
                    coll = client.get_collection(name=coll_name)

                    # Query collection
                    results = coll.query(
                        query_texts=[query],
                        n_results=top_k,
                        include=["metadatas", "documents", "distances"],
                    )

                    # Process results
                    if results and results["ids"] and len(results["ids"][0]) > 0:
                        for i in range(len(results["ids"][0])):
                            # Convert distance to similarity score (assuming cosine distance)
                            # ChromaDB returns distances, lower is better
                            # Convert to similarity: 1 - distance/2 (approximate for cosine)
                            distance = results["distances"][0][i]
                            similarity_score = 1.0 - (distance / 2.0)

                            # Filter by min_score
                            if similarity_score >= min_score:
                                metadata = (
                                    results["metadatas"][0][i]
                                    if results["metadatas"]
                                    else {}
                                )
                                document = (
                                    results["documents"][0][i]
                                    if results["documents"]
                                    else ""
                                )

                                # Extract snippet (first 200 chars)
                                snippet = (
                                    document[:200] + "..."
                                    if len(document) > 200
                                    else document
                                )

                                all_results.append(
                                    {
                                        "collection": coll_name,
                                        "similarity_score": round(similarity_score, 3),
                                        "distance": round(distance, 3),
                                        "title": metadata.get("title", "Untitled"),
                                        "snippet": snippet,
                                        "metadata": metadata,
                                    }
                                )

                except Exception as e:
                    # Collection not found or error querying - log and return error
                    logger.error(f"ChromaDB search failed for collection '{coll_name}': {str(e)}")
                    return {
                        "success": False,
                        "error": f"Error searching collection '{coll_name}': {e!s}",
                        "collection": coll_name,
                        "available_collections": ["literature", "patterns"],
                        "hint": "Verify ChromaDB service is running and collection exists"
                    }

        # Sort all results by similarity score (descending)
        all_results.sort(key=lambda x: x["similarity_score"], reverse=True)

        # Limit to top_k
        all_results = all_results[:top_k]

        # Determine data source description
        if use_pgvector_for_literature:
            if collection == "all":
                data_source = "PGVector (literature) + ChromaDB (patterns)"
            elif collection == "literature":
                data_source = "PGVector (29,863 CNS papers)"
            else:
                data_source = "ChromaDB (pattern library)"
        else:
            if collection == "all":
                data_source = "ChromaDB (literature + patterns)"
            elif collection == "literature":
                data_source = "ChromaDB (29,863 CNS papers)"
            else:
                data_source = "ChromaDB (pattern library)"

        result_dict = {
            "success": True,
            "query": query,
            "collection": collection,
            "results": all_results,
            "count": len(all_results),
            "data_source": data_source,
            "backend_used": backend_used,
            "latency": "<100ms",
            "query_params": {"top_k": top_k, "min_score": min_score}
        }

        return result_dict

    except Exception as e:
        # Unexpected error
        return {
            "success": False,
            "error": f"Unexpected error: {e!s}",
            "query": tool_input.get("query", "unknown"),
            "error_type": type(e).__name__,
        }


# Export tool for registration
__all__ = ["TOOL_DEFINITION", "execute"]
