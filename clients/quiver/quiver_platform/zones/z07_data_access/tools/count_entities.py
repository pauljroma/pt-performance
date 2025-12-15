"""
Count Entities Tool - Aggregate Statistics

ARCHITECTURE DECISION LOG:
v3.0 (current): Pure agentic with atomic tools
  - Provides Claude with database statistics and counts
  - Useful for understanding data scope before queries
  - Fast aggregation queries

Pattern: Wraps EmbeddingService and Neo4j for counts
Reference: Week 1 tools for consistent structure
"""
# MIGRATION NOTE (2025-12-04): Updated to use pgvector_embedding_service (pgvector backend)
# Previous version used parquet-based embedding_service


from typing import Dict, Any, Optional
from pathlib import Path
import sys

# Add path for services
project_root = Path(__file__).parent.parent.parent.parent.parent.parent
sys.path.insert(0, str(project_root))

from zones.z07_data_access.embedding_service import get_embedding_service as get_embedding_service



# Import validation utilities (Stream 1.2: Validation Framework)
try:
    from tool_utils import validate_tool_input, format_validation_response
    VALIDATION_AVAILABLE = True
except ImportError:
    VALIDATION_AVAILABLE = False

# Claude Tool Definition (Anthropic format)
TOOL_DEFINITION = {
    "name": "count_entities",
    "description": """Get aggregate statistics and counts for entities in the database.

Returns counts for:
- Genes (in MODEX embeddings and Neo4j)
- Drugs (in PCA embeddings and Neo4j)
- Diseases, Pathways, Proteins (in Neo4j graph)
- Relationships (edges in Neo4j)
- Literature (papers in ChromaDB)

Useful for understanding data scope before running queries.

Examples:
- "How many genes are in the database?" → Returns gene count
- "Count of all entity types" → Returns breakdown by type
- "How many drugs target TSC2?" → Requires graph_neighbors, not this tool
- "Database statistics" → Returns comprehensive counts

Returns:
- Entity counts by type (Gene, Drug, Disease, Pathway, Protein)
- Relationship counts (graph edges)
- Literature counts (papers)
- Embedding space sizes

Data sources:
- MODEX embeddings: 18,368 genes
- PCA embeddings: 14,246 drugs
- Neo4j graph: 1.3M nodes, 9.5M relationships
- ChromaDB: 29,863 papers
""",
    "input_schema": {
        "type": "object",
        "properties": {
            "entity_type": {
                "type": "string",
                "description": "Which entity type to count: 'gene', 'drug', 'disease', 'pathway', 'protein', 'relationship', 'literature', or 'all'. Default: 'all'",
                "enum": ["gene", "drug", "disease", "pathway", "protein", "relationship", "literature", "all"],
                "default": "all"
            },
            "include_breakdown": {
                "type": "boolean",
                "description": "Include detailed breakdowns (e.g., genes by chromosome, drugs by tier). Default: false",
                "default": False
            }
        },
        "required": []
    }
}


async def execute(tool_input: Dict[str, Any]) -> Dict[str, Any]:
    """
    Execute count_entities tool - get aggregate statistics.

    Args:
        tool_input: Dict with keys:
            - entity_type (str, optional): Type to count or 'all' (default: 'all')
            - include_breakdown (bool, optional): Include detailed breakdowns (default: False)

    Returns:
        Dict with keys:
            - success (bool): Whether operation succeeded
            - counts (Dict): Entity counts by type
            - total_entities (int): Total entity count
            - total_relationships (int): Total relationship count
            - data_sources (List[str]): Sources queried
            - error (str, optional): Error message if failed

    Example:
        >>> await execute({"entity_type": "all"})
        {
            "success": True,
            "counts": {
                "genes": 18368,
                "drugs": 14246,
                "diseases": 12543,
                "pathways": 3456,
                "proteins": 45678,
                "relationships": 9500000,
                "literature": 29863
            },
            "total_entities": 94291,
            "total_relationships": 9500000,
            "data_sources": ["MODEX embeddings", "PCA embeddings", "Neo4j graph", "ChromaDB"]
        }
    """
    # Stream 1.2: Input validation
    if VALIDATION_AVAILABLE:
        validation_errors = validate_tool_input(tool_input, TOOL_DEFINITION["input_schema"], "count_entities")
        if validation_errors:
            return format_validation_response("count_entities", validation_errors)

    try:
        # Get parameters with defaults
        entity_type = tool_input.get("entity_type", "all")
        include_breakdown = tool_input.get("include_breakdown", False)

        valid_types = ["gene", "drug", "disease", "pathway", "protein", "relationship", "literature", "all"]
        if entity_type not in valid_types:
            return {
                "success": False,
                "error": f"Invalid entity_type: {entity_type}",
                "valid_types": valid_types
            }

        counts = {}
        data_sources = []

        # Get embedding service
        embedding_service = get_embedding_service()

        # Count genes (from MODEX embeddings)
        if entity_type in ["gene", "all"] and embedding_service:
            gene_count = len(embedding_service.gene_df)
            counts["genes"] = gene_count
            data_sources.append("MODEX embeddings")

            if include_breakdown:
                # Could add breakdown by chromosome, etc.
                counts["genes_detail"] = {
                    "in_embeddings": gene_count,
                    "space": "MODEX",
                    "dimensions": 32
                }

        # Count drugs (from PCA embeddings)
        if entity_type in ["drug", "all"] and embedding_service:
            drug_count = len(embedding_service.drug_df)
            counts["drugs"] = drug_count
            data_sources.append("PCA embeddings")

            if include_breakdown:
                counts["drugs_detail"] = {
                    "in_embeddings": drug_count,
                    "space": "PCA",
                    "dimensions": 32
                }

        # Count graph entities (from Neo4j)
        if entity_type in ["disease", "pathway", "protein", "relationship", "all"]:
            try:
                from zones.z08_persist.providers.neo4j_graph_provider import get_graph_provider

                graph_provider = get_graph_provider()
                if graph_provider:
                    # Count nodes by label
                    if entity_type in ["disease", "all"]:
                        disease_query = "MATCH (n:Disease) RETURN count(n) as count"
                        result = graph_provider.execute_read(disease_query, {})
                        if result and len(result) > 0:
                            counts["diseases"] = result[0]['count']

                    if entity_type in ["pathway", "all"]:
                        pathway_query = "MATCH (n:Pathway) RETURN count(n) as count"
                        result = graph_provider.execute_read(pathway_query, {})
                        if result and len(result) > 0:
                            counts["pathways"] = result[0]['count']

                    if entity_type in ["protein", "all"]:
                        protein_query = "MATCH (n:Protein) RETURN count(n) as count"
                        result = graph_provider.execute_read(protein_query, {})
                        if result and len(result) > 0:
                            counts["proteins"] = result[0]['count']

                    if entity_type in ["relationship", "all"]:
                        rel_query = "MATCH ()-[r]->() RETURN count(r) as count"
                        result = graph_provider.execute_read(rel_query, {})
                        if result and len(result) > 0:
                            counts["relationships"] = result[0]['count']

                        if include_breakdown:
                            # Count by relationship type
                            rel_type_query = "MATCH ()-[r]->() RETURN type(r) as rel_type, count(*) as count ORDER BY count DESC LIMIT 10"
                            result = graph_provider.execute_read(rel_type_query, {})
                            if result:
                                rel_breakdown = {}
                                for row in result:
                                    rel_breakdown[row['rel_type']] = row['count']
                                counts["relationships_detail"] = rel_breakdown

                    data_sources.append("Neo4j graph")

            except Exception as e:
                counts["graph_error"] = str(e)

        # Count literature (from ChromaDB)
        if entity_type in ["literature", "all"]:
            try:
                from zones.z08_persist.providers.chroma_provider import get_chroma_client

                chroma_client = get_chroma_client()
                if chroma_client:
                    # Get literature collection
                    try:
                        lit_coll = chroma_client.get_collection(name="literature")
                        counts["literature"] = lit_coll.count()
                        data_sources.append("ChromaDB")
                    except Exception:
                        # Collection doesn't exist
                        counts["literature"] = 0

            except Exception as e:
                counts["literature_error"] = str(e)

        # Calculate totals
        total_entities = sum([
            counts.get("genes", 0),
            counts.get("drugs", 0),
            counts.get("diseases", 0),
            counts.get("pathways", 0),
            counts.get("proteins", 0)
        ])

        total_relationships = counts.get("relationships", 0)

        return {
            "success": True,
            "counts": counts,
            "total_entities": total_entities,
            "total_relationships": total_relationships,
            "data_sources": data_sources,
            "query_params": {
                "entity_type": entity_type,
                "include_breakdown": include_breakdown
            }
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
