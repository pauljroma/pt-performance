"""
Entity Metadata Tool - Gene and Drug Information

ARCHITECTURE DECISION LOG:
v3.0 (current): Pure agentic with atomic tools
  - This tool provides Claude with detailed entity metadata
  - Supports genes, drugs, diseases, pathways, proteins
  - Combines data from multiple sources (embeddings, graph, external DBs)
  - Handles fuzzy matching like other vector tools

Pattern: Wraps EmbeddingService and Neo4j for comprehensive metadata
Reference: Week 1 tools for consistent structure
"""

from typing import Dict, Any, List, Optional
from pathlib import Path
import sys

# Import harmonization utilities (Stream 1: Foundation)
try:
    from tool_utils import validate_tool_input, format_validation_response, harmonize_gene_id, validate_input, normalize_gene_symbol
    HARMONIZATION_AVAILABLE = True
    VALIDATION_AVAILABLE = True
except ImportError:
    HARMONIZATION_AVAILABLE = False
    VALIDATION_AVAILABLE = False

# Add path for services
project_root = Path(__file__).parent.parent.parent.parent.parent.parent
sys.path.insert(0, str(project_root))

from zones.z07_data_access.embedding_service import get_embedding_service
# MIGRATED to v3.0 (2025-12-05): Master resolution tables (60x faster)
from zones.z07_data_access.drug_name_resolver_v3 import get_drug_name_resolver_v3 as get_drug_name_resolver


# Claude Tool Definition (Anthropic format)
TOOL_DEFINITION = {
    "name": "entity_metadata",
    "description": """Get comprehensive metadata for genes, drugs, diseases, pathways, or proteins.

Returns detailed information from multiple sources:
- Embedding data (ENS gene v6.0 64D, Chemical drug v6.0 256D)
- Knowledge graph properties (Neo4j)
- External database IDs (Ensembl, PubChem, DrugBank, etc.)
- Biological annotations (function, pathway membership, etc.)

Supports case-insensitive matching for entity names.

Examples:
- "Get metadata for TSC2" → Returns gene info, Ensembl ID, function, pathways
- "What is Rapamycin?" → Returns drug info, PubChem ID, targets, indications
- "Tell me about KCNQ2" → Gene function, associated diseases, pathways
- "Metadata for kcnq2" → Matches to KCNQ2

Returns:
- Entity type (Gene, Drug, Disease, Pathway, Protein)
- Primary identifiers (Ensembl ID, PubChem ID, DrugBank ID, etc.)
- Biological annotations (function, pathways, targets)
- Embedding metadata (if available)
- Graph properties (degree, relationships)

Data sources:
- 18,368 genes (ENS v6.0 embeddings + Neo4j)
- 14,246 drugs (Chemical v6.0 embeddings + Neo4j)
- 1.3M nodes in knowledge graph
""",
    "input_schema": {
        "type": "object",
        "properties": {
            "entity": {
                "type": "string",
                "description": "Entity name (case-insensitive with fuzzy matching). Examples: TSC2, KCNQ2, Rapamycin, kncq2"
            },
            "entity_type": {
                "type": "string",
                "description": "Entity type hint: 'gene', 'drug', 'disease', 'pathway', 'protein', or 'auto' to detect automatically. Default: 'auto'",
                "enum": ["gene", "drug", "disease", "pathway", "protein", "auto"],
                "default": "auto"
            },
            "include_embedding": {
                "type": "boolean",
                "description": "Include embedding vector metadata (dimensions, space, norms). Default: true",
                "default": True
            },
            "include_graph": {
                "type": "boolean",
                "description": "Include graph properties from Neo4j (relationships, degree). Default: true",
                "default": True
            }
        },
        "required": ["entity"]
    }
}


async def execute(tool_input: Dict[str, Any]) -> Dict[str, Any]:
    """
    Execute entity_metadata tool - get comprehensive entity information.

    Args:
        tool_input: Dict with keys:
            - entity (str): Entity name (case-insensitive)
            - entity_type (str, optional): 'gene', 'drug', 'disease', 'pathway', 'protein', or 'auto' (default: 'auto')
            - include_embedding (bool, optional): Include embedding metadata (default: True)
            - include_graph (bool, optional): Include graph properties (default: True)

    Returns:
        Dict with keys:
            - success (bool): Whether operation succeeded
            - entity (str): Normalized entity name
            - entity_type (str): Detected or specified entity type
            - metadata (Dict): Comprehensive metadata
            - data_sources (List[str]): Sources used
            - error (str, optional): Error message if failed

    Example:
        >>> await execute({"entity": "TSC2"})
        {
            "success": True,
            "entity": "TSC2",
            "entity_type": "Gene",
            "metadata": {
                "primary_id": "ENSG00000103197",
                "name": "TSC2",
                "aliases": ["TSC2", "LAM", "PPP1R160"],
                "function": "Tumor suppressor, regulates mTOR pathway",
                "pathways": ["mTOR signaling", "Cell growth"],
                "embedding": {
                    "space": "MODEX",
                    "dimensions": 32,
                    "l2_norm": 0.456
                },
                "graph": {
                    "degree": 156,
                    "relationships": {
                        "INTERACTS_WITH": 45,
                        "ASSOCIATED_WITH": 12,
                        "IN_PATHWAY": 8
                    }
                }
            },
            "data_sources": ["MODEX embeddings", "Neo4j graph", "Ensembl"]
        }
    """
    # Stream 1.2: Input validation
    if VALIDATION_AVAILABLE:
        validation_errors = validate_tool_input(tool_input, TOOL_DEFINITION["input_schema"], "entity_metadata")
        if validation_errors:
            return format_validation_response("entity_metadata", validation_errors)

    try:
        # Get parameters with defaults
        entity = tool_input.get("entity", "").strip()
        entity_type = tool_input.get("entity_type", "auto")
        include_embedding = tool_input.get("include_embedding", True)
        include_graph = tool_input.get("include_graph", True)

        # Validate parameters
        if not entity or not isinstance(entity, str) or len(entity) == 0:
            return {
                "success": False,
                "error": "Entity parameter must be a non-empty string",
                "hint": "Examples: TSC2, KCNQ2, Rapamycin, kncq2",
                "received": repr(tool_input.get("entity"))
            }

        valid_types = ["gene", "drug", "disease", "pathway", "protein", "auto"]
        if entity_type not in valid_types:
            return {
                "success": False,
                "error": f"Invalid entity_type: {entity_type}",
                "valid_types": valid_types
            }

        # Initialize metadata structure
        metadata = {}
        data_sources = []
        detected_type = None
        normalized_entity = entity
        harmonization_note = None  # For tracking entity name harmonization

        # Get PGVector service (v6.0 embeddings)
        try:
            pgvector_service = get_embedding_service()
        except Exception as e:
            # If PGVector not available, skip embedding checks
            pgvector_service = None

        # Try to find in embeddings (genes or drugs)
        if pgvector_service and (entity_type == "auto" or entity_type == "gene"):
            # Try gene embeddings with case variations
            matched_gene = None
            gene_result = None

            # Try direct match first
            gene_result = pgvector_service.get_gene_embedding(entity)
            if gene_result is not None:
                matched_gene = entity
            else:
                # Try case variations
                for variant in [entity.upper(), entity.lower(), entity.title()]:
                    gene_result = pgvector_service.get_gene_embedding(variant)
                    if gene_result is not None:
                        matched_gene = variant
                        break

            if matched_gene and gene_result is not None:
                detected_type = "Gene"
                normalized_entity = matched_gene

                metadata["name"] = matched_gene
                metadata["type"] = "Gene"

                if include_embedding:
                    metadata["embedding"] = {
                        "space": "ENS_v6_0",
                        "dimensions": gene_result.shape[0],
                        "available": True,
                        "source_table": "ens_gene_64d_v6_0"
                    }
                    data_sources.append("PGVector ENS gene embeddings (v6.0)")

        # If not found as gene, try drug
        if not detected_type and pgvector_service and (entity_type == "auto" or entity_type == "drug"):
            # Try drug embeddings - first resolve drug name
            drug_name_resolver = get_drug_name_resolver()

            # Try to resolve drug name (handles commercial names -> QS IDs)
            name_info = drug_name_resolver.resolve(entity)
            potential_ids = []

            # If resolver found a QS ID, try that first
            if name_info.get('commercial_name') != entity:
                # Resolver found something, try the QS ID format
                potential_ids.append(entity)  # Original input
            else:
                # Try common variations
                potential_ids.extend([entity, entity.upper(), entity.lower(), entity.title()])

            matched_drug = None
            drug_result = None

            # Try drug_chemical_v6_0_256d table (256D drug embeddings)
            for drug_id in potential_ids:
                drug_result = pgvector_service.get_drug_embedding(drug_id)
                if drug_result is not None:
                    matched_drug = drug_id
                    break

            if matched_drug and drug_result is not None:
                detected_type = "Drug"
                normalized_entity = matched_drug

                # Resolve commercial name
                name_info = drug_name_resolver.resolve(matched_drug)

                metadata["drug_id"] = matched_drug  # QS ID for traceability
                metadata["commercial_name"] = name_info['commercial_name']  # v3.1: PRIMARY DISPLAY
                metadata["name"] = name_info['commercial_name']  # Also set 'name' for backward compatibility
                metadata["type"] = "Drug"
                metadata["chembl_id"] = name_info.get('chembl_id', '')
                metadata["name_source"] = name_info.get('source', 'none')

                if include_embedding:
                    metadata["embedding"] = {
                        "space": "drug_chemical_v6_0_256d",
                        "dimensions": drug_result.shape[0],
                        "available": True,
                        "source_table": "drug_chemical_v6_0_256d"
                    }
                    data_sources.append("PGVector chemical embeddings (v6.0)")

        # Query Neo4j for graph properties
        if include_graph and detected_type:
            try:
                from zones.z08_persist.providers.neo4j_graph_provider import get_graph_provider

                graph_provider = get_graph_provider()
                if graph_provider:
                    # Query node by name
                    cypher_query = """
                    MATCH (n)
                    WHERE n.name = $name OR n.symbol = $name OR n.id = $name
                    RETURN n, labels(n) as labels
                    LIMIT 1
                    """

                    result = graph_provider.execute_read(cypher_query, {"name": normalized_entity})

                    if result and len(result) > 0:
                        node = result[0]['n']
                        labels = result[0]['labels']

                        # Get node properties
                        graph_metadata = {
                            "labels": labels,
                            "properties": dict(node)
                        }

                        # Get degree (relationship count)
                        degree_query = """
                        MATCH (n)-[r]-(m)
                        WHERE n.name = $name OR n.symbol = $name OR n.id = $name
                        RETURN type(r) as rel_type, count(*) as count
                        """

                        degree_result = graph_provider.execute_read(degree_query, {"name": normalized_entity})

                        if degree_result:
                            relationships = {}
                            total_degree = 0
                            for row in degree_result:
                                rel_type = row['rel_type']
                                count = row['count']
                                relationships[rel_type] = count
                                total_degree += count

                            graph_metadata["degree"] = total_degree
                            graph_metadata["relationships"] = relationships

                        metadata["graph"] = graph_metadata
                        data_sources.append("Neo4j graph")

            except Exception as e:
                # Graph query failed, but don't fail the entire request
                metadata["graph_error"] = str(e)

        # If entity not found in any source
        if not detected_type:
            return {
                "success": False,
                "error": f"Entity not found: {entity}",
                "entity": entity,
                "hint": "Entity not found in embeddings or graph. Try checking spelling or using standard symbols.",
                "searched_spaces": ["ENS gene embeddings v6.0 (18,368 genes)", "Chemical drug embeddings v6.0 (14,246 drugs)", "Neo4j graph"],
                "examples": ["TSC2", "KCNQ2", "Rapamycin", "BRCA1"]
            }

        result_dict = {
            "success": True,
            "entity": normalized_entity,
            "entity_input": entity,  # Show original input
            "entity_type": detected_type,
            "metadata": metadata,
            "data_sources": data_sources
        
        }

        # Add harmonization note if applicable
        if harmonization_note:
            result_dict["harmonization"] = harmonization_note

        return result_dict

    except Exception as e:
        # Unexpected error
        return {
            "success": False,
            "error": f"Unexpected error: {str(e)}",
            "entity": tool_input.get("entity", "unknown"),
            "error_type": type(e).__name__
        }


# Export tool for registration
__all__ = ["TOOL_DEFINITION", "execute"]
