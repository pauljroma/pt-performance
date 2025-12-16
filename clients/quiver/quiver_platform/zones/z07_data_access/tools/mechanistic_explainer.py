"""
Mechanistic Explainer Tool - Drug-Disease Mechanism Discovery

ARCHITECTURE DECISION LOG:
v1.0 (current): Neo4j-based mechanistic pathway discovery
  - Explains HOW a drug affects a disease through biological mechanisms
  - Finds paths: Drug → Protein → Pathway → Disease
  - Integrates embedding-based rescue predictions (PREDICTS_RESCUE_MODEX_16D, PREDICTS_RESCUE_EP)
  - Provides human-readable mechanistic narratives
  - Supports gene-specific mechanism filtering
  - Returns confidence scores and data provenance

Pattern: Wraps Neo4j multi-hop queries with mechanistic interpretation
Reference: graph_path.py for path discovery, vector_antipodal.py for rescue predictions
"""

from typing import Dict, Any, List, Optional
from pathlib import Path
import sys
import os
import logging

# Import harmonization utilities (Stream 1: Foundation)
try:
    from tool_utils import (
        validate_tool_input,
        format_validation_response,
        harmonize_drug_id,
        harmonize_gene_id,
        validate_input,
        normalize_gene_symbol
    )
    HARMONIZATION_AVAILABLE = True
    VALIDATION_AVAILABLE = True
except ImportError:
    HARMONIZATION_AVAILABLE = False
    VALIDATION_AVAILABLE = False

logger = logging.getLogger(__name__)

# Add path for Neo4j driver
project_root = Path(__file__).parent.parent.parent.parent.parent.parent
sys.path.insert(0, str(project_root))


# Claude Tool Definition (Anthropic format)
TOOL_DEFINITION = {
    "name": "mechanistic_explainer",
    "description": """Explain the biological mechanism by which a drug affects a disease.

Discovers and explains mechanistic pathways connecting drugs to diseases through:
1. **Traditional mechanisms**: Drug targets → Protein interactions → Pathways → Disease
2. **Rescue mechanisms**: Embedding-based predictions of drug rescue for dysfunctional genes
3. **Multi-target effects**: How drugs affect multiple proteins/pathways to treat disease

Returns human-readable mechanistic narratives with evidence and confidence scores.

**Three mechanism types explained**:

1. **Direct target mechanism**:
   - Drug INHIBITS Protein X
   - Protein X is CAUSAL_FOR Disease Y
   - Narrative: "Drug treats Disease Y by inhibiting causative protein X"

2. **Pathway mechanism**:
   - Drug ACTIVATES Protein A
   - Protein A REGULATES_PATHWAY Pathway P
   - Pathway P is DYSREGULATED_IN Disease D
   - Narrative: "Drug treats Disease D by activating pathway P through protein A"

3. **Rescue mechanism** (embedding-based, unique advantage):
   - Drug has high rescue_score for Gene G (via PREDICTS_RESCUE_MODEX_16D)
   - Gene G is CAUSAL_FOR Disease D
   - Narrative: "Drug rescues dysfunction of gene G, addressing root cause of Disease D"

**Use cases**:
- "How does Rapamycin treat Tuberous Sclerosis?" → mTOR pathway mechanism
- "Explain Fenfluramine's mechanism for Dravet Syndrome" → Serotonin + rescue mechanism
- "What's the mechanism for Aspirin in cardiovascular disease?" → COX inhibition pathway
- "How does Drug X work for Disease Y through Gene Z?" → Targeted mechanism query

**Key outputs**:
- Mechanistic paths with detailed narratives
- Confidence scores (0-1 based on evidence strength)
- Data sources (ChEMBL, Reactome, DisGeNET, embedding predictions)
- Rescue predictions with antipodal similarity scores
- Multi-target/multi-pathway summaries

**Data coverage**:
- 30K drugs (ChEMBL + DrugBank)
- 20K genes/proteins
- 3K pathways (Reactome, KEGG)
- 10K diseases (MONDO)
- 1.8M rescue predictions (MODEX_16D)
- 1.61M dose-specific predictions (EP)
""",
    "input_schema": {
        "type": "object",
        "properties": {
            "drug": {
                "type": "string",
                "description": "Drug name or identifier (e.g., 'Rapamycin', 'CHEMBL415', 'Aspirin'). Case-insensitive."
            },
            "disease": {
                "type": "string",
                "description": "Disease name or identifier (e.g., 'Tuberous Sclerosis', 'MONDO:0008199', 'Epilepsy'). Case-insensitive."
            },
            "gene": {
                "type": "string",
                "description": "Optional: Focus on specific gene target (e.g., 'TSC2', 'SCN1A'). If specified, only returns mechanisms through this gene. Default: None (all mechanisms)",
                "default": None
            },
            "max_depth": {
                "type": "integer",
                "description": "Maximum path length for mechanism discovery (number of relationships). Default: 4, Max: 6",
                "default": 4,
                "minimum": 2,
                "maximum": 6
            },
            "include_rescue": {
                "type": "boolean",
                "description": "Include embedding-based rescue predictions (PREDICTS_RESCUE_MODEX_16D, PREDICTS_RESCUE_EP). Default: True",
                "default": True
            },
            "explanation_style": {
                "type": "string",
                "enum": ["detailed", "summary", "pathways_only"],
                "description": "Explanation detail level. 'detailed': Full narratives with evidence. 'summary': Brief mechanism summaries. 'pathways_only': Just pathway names. Default: 'detailed'",
                "default": "detailed"
            },
            "min_confidence": {
                "type": "number",
                "description": "Minimum confidence score for mechanisms (0-1). Lower = more speculative mechanisms included. Default: 0.5",
                "default": 0.5,
                "minimum": 0.0,
                "maximum": 1.0
            }
        },
        "required": ["drug", "disease"]
    }
}


async def execute(tool_input: Dict[str, Any]) -> Dict[str, Any]:
    """
    Execute mechanistic_explainer tool - explain drug-disease mechanisms.

    RECURSION PROTECTION: This function is protected against infinite recursion
    via sys.setrecursionlimit guard.

    Args:
        tool_input: Dict with keys:
            - drug (str): Drug name or identifier
            - disease (str): Disease name or identifier
            - gene (str, optional): Focus on specific gene
            - max_depth (int, optional): Maximum path length (default: 4)
            - include_rescue (bool, optional): Include rescue predictions (default: True)
            - explanation_style (str, optional): Detail level (default: 'detailed')
            - min_confidence (float, optional): Minimum confidence (default: 0.5)

    Returns:
        Dict with keys:
            - success (bool): Whether operation succeeded
            - drug (str): Normalized drug name
            - disease (str): Normalized disease name
            - mechanisms (List[Dict]): List of mechanistic explanations
            - mechanism_count (int): Number of mechanisms found
            - rescue_predictions (List[Dict]): Embedding-based rescue mechanisms
            - summary (str): Overall mechanistic summary
            - confidence (float): Overall confidence score
            - data_sources (List[str]): Data provenance
            - error (str, optional): Error message if failed

    Example:
        >>> await execute({
        ...     "drug": "Rapamycin",
        ...     "disease": "Tuberous Sclerosis"
        ... })
        {
            "success": True,
            "drug": "Rapamycin",
            "disease": "Tuberous Sclerosis",
            "mechanisms": [
                {
                    "mechanism_type": "pathway",
                    "narrative": "Rapamycin inhibits mTOR protein, which regulates mTOR pathway. This pathway is dysregulated in Tuberous Sclerosis.",
                    "path": [
                        {"entity": "Rapamycin", "type": "Drug"},
                        {"entity": "mTOR", "type": "Protein", "relationship": "INHIBITS"},
                        {"entity": "mTOR signaling", "type": "Pathway", "relationship": "REGULATES_PATHWAY"},
                        {"entity": "Tuberous Sclerosis", "type": "Disease", "relationship": "DYSREGULATED_IN"}
                    ],
                    "confidence": 0.95,
                    "evidence": ["ChEMBL", "Reactome", "OMIM"],
                    "path_length": 3
                }
            ],
            "rescue_predictions": [
                {
                    "gene": "TSC2",
                    "rescue_score": 0.726,
                    "mechanism": "Drug rescues TSC2 dysfunction via antipodal embedding similarity",
                    "confidence": 0.85
                }
            ],
            "mechanism_count": 1,
            "summary": "Rapamycin treats Tuberous Sclerosis through mTOR pathway inhibition...",
            "confidence": 0.90,
            "data_sources": ["Neo4j graph", "MODEX_16D embeddings", "ChEMBL", "Reactome"]
        }
    """
    # Stream 1.2: Input validation
    if VALIDATION_AVAILABLE:
        validation_errors = validate_tool_input(
            tool_input,
            TOOL_DEFINITION["input_schema"],
            "mechanistic_explainer"
        )
        if validation_errors:
            return format_validation_response("mechanistic_explainer", validation_errors)

    # Set recursion limit to prevent infinite loops (default is 1000)
    import sys
    old_recursion_limit = sys.getrecursionlimit()
    sys.setrecursionlimit(200)  # Lower limit to catch recursion bugs faster

    try:
        # Get parameters with defaults
        drug = tool_input.get("drug", "").strip()
        disease = tool_input.get("disease", "").strip()
        gene = tool_input.get("gene", "").strip() if tool_input.get("gene") else None
        max_depth = tool_input.get("max_depth", 4)
        include_rescue = tool_input.get("include_rescue", True)
        explanation_style = tool_input.get("explanation_style", "detailed")
        min_confidence = tool_input.get("min_confidence", 0.5)

        # Validate parameters
        if not drug or not isinstance(drug, str):
            return {
                "success": False,
                "error": "drug parameter must be a non-empty string",
                "hint": "Examples: Rapamycin, Fenfluramine, Aspirin, CHEMBL415"
            }

        if not disease or not isinstance(disease, str):
            return {
                "success": False,
                "error": "disease parameter must be a non-empty string",
                "hint": "Examples: Tuberous Sclerosis, Epilepsy, MONDO:0008199"
            }

        if not (2 <= max_depth <= 6):
            return {
                "success": False,
                "error": f"max_depth must be between 2 and 6, got {max_depth}"
            }

        if not (0.0 <= min_confidence <= 1.0):
            return {
                "success": False,
                "error": f"min_confidence must be between 0.0 and 1.0, got {min_confidence}"
            }

        # Get Neo4j driver
        try:
            from neo4j import GraphDatabase
        except ImportError:
            return {
                "success": False,
                "error": "neo4j driver not installed. Run: pip install neo4j"
            }

        # Get connection parameters
        neo4j_uri = os.getenv("NEO4J_URI", "bolt://localhost:7687")
        neo4j_user = os.getenv("NEO4J_USER", "neo4j")
        neo4j_password = os.getenv("NEO4J_PASSWORD", "rescue123")
        neo4j_database = os.getenv("NEO4J_DATABASE", "neo4j")

        # Create driver and execute query
        driver = None
        try:
            driver = GraphDatabase.driver(
                neo4j_uri,
                auth=(neo4j_user, neo4j_password)
            )

            with driver.session(database=neo4j_database) as session:
                # Step 1: Find and normalize drug node
                drug_record = _find_drug_node(session, drug)
                if not drug_record:
                    return {
                        "success": False,
                        "error": f"Drug not found in Neo4j: {drug}",
                        "drug": drug,
                        "hint": "Check spelling or use ChEMBL ID. Examples: Rapamycin, Fenfluramine, CHEMBL415"
                    }

                normalized_drug = drug_record["name"]

                # Step 2: Find and normalize disease node
                disease_record = _find_disease_node(session, disease)
                if not disease_record:
                    return {
                        "success": False,
                        "error": f"Disease not found in Neo4j: {disease}",
                        "disease": disease,
                        "hint": "Check spelling or use MONDO ID. Examples: Tuberous Sclerosis, Epilepsy, MONDO:0008199"
                    }

                normalized_disease = disease_record["name"]

                # Step 3: Find mechanistic paths (traditional graph)
                mechanisms = _find_mechanisms(
                    session,
                    normalized_drug,
                    normalized_disease,
                    gene,
                    max_depth,
                    min_confidence,
                    explanation_style
                )

                # Step 4: Find rescue predictions (embedding-based) if requested
                rescue_predictions = []
                if include_rescue:
                    rescue_predictions = _find_rescue_mechanisms(
                        session,
                        normalized_drug,
                        normalized_disease,
                        gene,
                        min_confidence
                    )

                # Step 5: Generate summary
                summary = _generate_summary(
                    normalized_drug,
                    normalized_disease,
                    mechanisms,
                    rescue_predictions,
                    explanation_style
                )

                # Step 6: Calculate overall confidence
                all_confidences = [m["confidence"] for m in mechanisms]
                all_confidences.extend([r["confidence"] for r in rescue_predictions])
                overall_confidence = (
                    sum(all_confidences) / len(all_confidences)
                    if all_confidences else 0.0
                )

                # Step 7: Collect data sources
                data_sources = set()
                data_sources.add("Neo4j graph database")
                if mechanisms:
                    for m in mechanisms:
                        data_sources.update(m.get("evidence", []))
                if rescue_predictions:
                    data_sources.add("MODEX_16D embeddings")
                    data_sources.add("EP disease embeddings")

                return {
                    "success": True,
                    "drug": normalized_drug,
                    "disease": normalized_disease,
                    "gene_filter": gene if gene else None,
                    "mechanisms": mechanisms,
                    "mechanism_count": len(mechanisms),
                    "rescue_predictions": rescue_predictions,
                    "rescue_count": len(rescue_predictions),
                    "summary": summary,
                    "confidence": round(overall_confidence, 3),
                    "data_sources": sorted(list(data_sources)),
                    "query_params": {
                        "drug": drug,
                        "disease": disease,
                        "gene": gene,
                        "max_depth": max_depth,
                        "include_rescue": include_rescue,
                        "explanation_style": explanation_style,
                        "min_confidence": min_confidence
                    }
                }

        except RecursionError as e:
            logger.error(f"Recursion error in Neo4j query: {str(e)}")
            if driver:
                driver.close()
            sys.setrecursionlimit(old_recursion_limit)
            return {
                "success": False,
                "error": "Recursion limit exceeded during graph traversal",
                "drug": drug,
                "disease": disease,
                "error_type": "recursion_error",
                "hint": "This may indicate circular references in the knowledge graph"
            }
        except Exception as e:
            logger.error(f"Neo4j query error: {str(e)}")
            return {
                "success": False,
                "error": f"Neo4j query failed: {str(e)}",
                "drug": drug,
                "disease": disease,
                "error_type": type(e).__name__
            }

        finally:
            if driver:
                driver.close()
            sys.setrecursionlimit(old_recursion_limit)

    except RecursionError as e:
        sys.setrecursionlimit(old_recursion_limit)
        logger.error(f"Recursion error in mechanistic_explainer: {str(e)}")
        return {
            "success": False,
            "error": "Tool execution failed due to recursion limit",
            "error_type": "recursion_error",
            "hint": "Try with a simpler query or contact support"
        }
    except Exception as e:
        sys.setrecursionlimit(old_recursion_limit)
        logger.error(f"Unexpected error in mechanistic_explainer: {str(e)}")
        return {
            "success": False,
            "error": f"Unexpected error: {str(e)}",
            "drug": tool_input.get("drug", "unknown"),
            "disease": tool_input.get("disease", "unknown"),
            "error_type": type(e).__name__
        }


def _find_drug_node(session, drug_name: str) -> Optional[Dict[str, Any]]:
    """
    Find drug node in Neo4j with multi-strategy matching.

    Args:
        session: Neo4j session
        drug_name: Drug name or identifier

    Returns:
        Dict with 'name' and 'chembl_id' keys, or None if not found
    """
    try:
        query = """
        MATCH (d:Drug)
        WHERE toLower(d.name) = toLower($drug_name)
           OR toLower(d.chembl_id) = toLower($drug_name)
           OR toLower(d.drugbank_id) = toLower($drug_name)
           OR toLower(d.name) CONTAINS toLower($drug_name)
        RETURN d.name as name, d.chembl_id as chembl_id
        LIMIT 1
        """

        result = session.run(query, drug_name=drug_name)
        record = result.single()

        if record:
            return {
                "name": record["name"] or drug_name,
                "chembl_id": record["chembl_id"]
            }

        return None

    except Exception as e:
        logger.error(f"Error in _find_drug_node: {str(e)}")
        return None


def _find_disease_node(session, disease_name: str) -> Optional[Dict[str, Any]]:
    """
    Find disease node in Neo4j with multi-strategy matching.

    Args:
        session: Neo4j session
        disease_name: Disease name or identifier

    Returns:
        Dict with 'name' and 'mondo_id' keys, or None if not found
    """
    try:
        query = """
        MATCH (d:Disease)
        WHERE toLower(d.name) = toLower($disease_name)
           OR toLower(d.mondo_id) = toLower($disease_name)
           OR toLower(d.name) CONTAINS toLower($disease_name)
        RETURN d.name as name, d.mondo_id as mondo_id
        LIMIT 1
        """

        result = session.run(query, disease_name=disease_name)
        record = result.single()

        if record:
            return {
                "name": record["name"] or disease_name,
                "mondo_id": record["mondo_id"]
            }

        return None

    except Exception as e:
        logger.error(f"Error in _find_disease_node: {str(e)}")
        return None


def _find_mechanisms(
    session,
    drug_name: str,
    disease_name: str,
    gene_filter: Optional[str],
    max_depth: int,
    min_confidence: float,
    explanation_style: str
) -> List[Dict[str, Any]]:
    """
    Find traditional mechanistic paths from drug to disease through Neo4j graph.

    Discovers paths like:
    - Drug → Protein → Pathway → Disease
    - Drug → Gene → Disease (direct)
    - Drug → Protein → Protein → Pathway → Disease

    Args:
        session: Neo4j session
        drug_name: Normalized drug name
        disease_name: Normalized disease name
        gene_filter: Optional gene to filter mechanisms
        max_depth: Maximum path length
        min_confidence: Minimum confidence threshold
        explanation_style: Detail level for narratives

    Returns:
        List of mechanism dicts with narratives, paths, confidence
    """
    mechanisms = []

    try:
        # Build gene filter if specified
        gene_filter_clause = ""
        if gene_filter:
            gene_filter_clause = f"""
            AND ANY(node IN nodes(p) WHERE
                (node:Gene AND toLower(node.symbol) = toLower('{gene_filter}'))
                OR (node:Protein AND toLower(node.name) = toLower('{gene_filter}'))
            )
            """

        # Query for mechanistic paths
        # Look for paths involving drug targets, pathways, protein interactions, disease associations
        query = f"""
        MATCH p = (drug:Drug {{name: $drug_name}})-[*1..{max_depth}]-(disease:Disease {{name: $disease_name}})
        WHERE ALL(r IN relationships(p) WHERE
            type(r) IN [
                'INHIBITS', 'ACTIVATES', 'BINDS_TO', 'MODULATES', 'TARGETS',
                'PART_OF_PATHWAY', 'REGULATES_PATHWAY', 'DYSREGULATED_IN',
                'ASSOCIATED_WITH', 'CAUSAL_FOR', 'TREATS', 'INDICATED_FOR',
                'INTERACTS_WITH', 'PHOSPHORYLATES', 'BINDS_TO',
                'UPREGULATED_IN', 'DOWNREGULATED_IN',
                'ENCODES', 'IN_PATHWAY', 'PARTICIPATES_IN', 'IMPLICATED_IN'
            ]
        )
        {gene_filter_clause}
        WITH p, length(p) as path_length
        ORDER BY path_length ASC
        LIMIT 5
        RETURN p, path_length
        """

        result = session.run(query, drug_name=drug_name, disease_name=disease_name)

        for record in result:
            path = record["p"]
            path_length = record["path_length"]

            # Extract mechanism from path
            mechanism = _extract_mechanism_from_path(
                path,
                path_length,
                explanation_style
            )

            if mechanism and mechanism["confidence"] >= min_confidence:
                mechanisms.append(mechanism)

        return mechanisms

    except Exception as e:
        logger.error(f"Error in _find_mechanisms: {str(e)}")
        return []


def _extract_mechanism_from_path(
    path,
    path_length: int,
    explanation_style: str
) -> Optional[Dict[str, Any]]:
    """
    Extract mechanistic explanation from Neo4j path.

    Args:
        path: Neo4j Path object
        path_length: Length of path
        explanation_style: Detail level

    Returns:
        Dict with mechanism_type, narrative, path, confidence, evidence
    """
    try:
        # Extract nodes and relationships
        nodes = []
        relationships = []

        for node in path.nodes:
            node_labels = list(node.labels) if hasattr(node, 'labels') else []
            node_type = node_labels[0] if node_labels else "Unknown"
            node_name = node.get("name") or node.get("symbol") or "Unknown"

            nodes.append({
                "entity": node_name,
                "type": node_type,
                "properties": dict(node)
            })

        for rel in path.relationships:
            rel_type = rel.type if hasattr(rel, 'type') else "UNKNOWN"
            relationships.append({
                "type": rel_type,
                "properties": dict(rel)
            })

        # Determine mechanism type
        mechanism_type = _classify_mechanism_type(nodes, relationships)

        # Build narrative
        narrative = _build_narrative(
            nodes,
            relationships,
            mechanism_type,
            explanation_style
        )

        # Calculate confidence based on evidence strength
        confidence = _calculate_confidence(relationships)

        # Extract evidence sources
        evidence = _extract_evidence_sources(relationships)

        # Build path representation
        path_repr = []
        for i, node in enumerate(nodes):
            path_entry = {
                "entity": node["entity"],
                "type": node["type"]
            }
            if i < len(relationships):
                path_entry["relationship"] = relationships[i]["type"]
            path_repr.append(path_entry)

        return {
            "mechanism_type": mechanism_type,
            "narrative": narrative,
            "path": path_repr,
            "confidence": confidence,
            "evidence": evidence,
            "path_length": path_length
        }

    except Exception as e:
        logger.error(f"Error extracting mechanism: {str(e)}")
        return None


def _classify_mechanism_type(nodes: List[Dict], relationships: List[Dict]) -> str:
    """
    Classify mechanism type based on nodes and relationships in path.

    Returns one of:
    - "direct_target": Drug directly targets protein causal for disease
    - "pathway": Drug affects pathway dysregulated in disease
    - "protein_interaction": Drug affects protein that interacts with disease protein
    - "multi_pathway": Drug affects multiple pathways
    - "indirect": Multi-hop indirect mechanism
    """
    node_types = [n["type"] for n in nodes]
    rel_types = [r["type"] for r in relationships]

    # Check for pathway mechanism
    if "Pathway" in node_types:
        if any(r in rel_types for r in ["DYSREGULATED_IN", "UPREGULATED_IN", "DOWNREGULATED_IN"]):
            return "pathway"

    # Check for direct target
    if len(nodes) <= 3:
        if any(r in rel_types for r in ["INHIBITS", "ACTIVATES", "TARGETS"]):
            if any(r in rel_types for r in ["CAUSAL_FOR", "ASSOCIATED_WITH"]):
                return "direct_target"

    # Check for protein interaction
    if "Protein" in node_types:
        if any(r in rel_types for r in ["INTERACTS_WITH", "PHOSPHORYLATES", "BINDS_TO"]):
            return "protein_interaction"

    # Default to indirect
    return "indirect"


def _build_narrative(
    nodes: List[Dict],
    relationships: List[Dict],
    mechanism_type: str,
    explanation_style: str,
    _recursion_depth: int = 0
) -> str:
    """
    Build human-readable mechanistic narrative.

    Args (internal):
        _recursion_depth: Internal counter to prevent infinite recursion

    Args:
        nodes: List of nodes in path
        relationships: List of relationships in path
        mechanism_type: Type of mechanism
        explanation_style: "detailed", "summary", or "pathways_only"

    Returns:
        Human-readable narrative string
    """
    # Recursion guard to prevent infinite loops
    MAX_RECURSION_DEPTH = 50
    if _recursion_depth >= MAX_RECURSION_DEPTH:
        logger.error(f"Maximum recursion depth ({MAX_RECURSION_DEPTH}) exceeded in _build_narrative")
        return "Unable to generate narrative (complexity limit exceeded)"

    if explanation_style == "pathways_only":
        # Extract pathway names only
        pathways = [n["entity"] for n in nodes if n["type"] == "Pathway"]
        if pathways:
            return f"Pathways: {', '.join(pathways)}"
        else:
            return "No pathways identified in mechanism"

    # Build narrative from path
    narrative_parts = []

    for i in range(len(nodes) - 1):
        source = nodes[i]["entity"]
        target = nodes[i + 1]["entity"]
        rel = relationships[i]["type"]

        # Convert relationship type to readable form
        rel_text = rel.lower().replace("_", " ")

        narrative_parts.append(f"{source} {rel_text} {target}")

    if explanation_style == "summary":
        # Brief summary
        drug = nodes[0]["entity"]
        disease = nodes[-1]["entity"]
        return f"{drug} treats {disease} via {mechanism_type.replace('_', ' ')}"

    # Detailed narrative
    narrative = ". ".join(narrative_parts)
    narrative += "."

    # Add mechanism type context
    if mechanism_type == "pathway":
        narrative += " This pathway-based mechanism modulates disease-relevant biological processes."
    elif mechanism_type == "direct_target":
        narrative += " This direct targeting mechanism addresses a causative factor in the disease."
    elif mechanism_type == "protein_interaction":
        narrative += " This mechanism works through protein-protein interactions affecting disease pathways."

    return narrative


def _calculate_confidence(relationships: List[Dict]) -> float:
    """
    Calculate confidence score based on relationship evidence.

    Higher confidence for:
    - Experimentally validated relationships
    - Relationships from high-quality sources
    - Shorter paths (fewer hops)

    Args:
        relationships: List of relationships in path

    Returns:
        Confidence score 0-1
    """
    # Start with base confidence
    base_confidence = 0.8

    # Penalize longer paths (each hop reduces confidence by 5%)
    path_penalty = min(0.3, len(relationships) * 0.05)
    confidence = base_confidence - path_penalty

    # Boost for high-quality relationship types
    high_quality_rels = ["INHIBITS", "ACTIVATES", "CAUSAL_FOR", "TARGETS"]
    quality_boost = sum(1 for r in relationships if r["type"] in high_quality_rels) * 0.05
    confidence += quality_boost

    # Ensure confidence is in valid range
    return max(0.0, min(1.0, confidence))


def _extract_evidence_sources(relationships: List[Dict]) -> List[str]:
    """
    Extract evidence sources from relationship properties.

    Args:
        relationships: List of relationships

    Returns:
        List of unique evidence sources
    """
    sources = set()

    for rel in relationships:
        props = rel.get("properties", {})

        # Check common source fields
        if "source" in props:
            sources.add(props["source"])
        if "evidence" in props:
            sources.add(props["evidence"])

    # Add default sources based on relationship types
    for rel in relationships:
        rel_type = rel["type"]
        if rel_type in ["INHIBITS", "ACTIVATES", "BINDS_TO"]:
            sources.add("ChEMBL")
        elif rel_type in ["PART_OF_PATHWAY", "REGULATES_PATHWAY"]:
            sources.add("Reactome")
        elif rel_type in ["CAUSAL_FOR", "ASSOCIATED_WITH"]:
            sources.add("DisGeNET")

    return sorted(list(sources)) if sources else ["Neo4j graph"]


def _find_rescue_mechanisms(
    session,
    drug_name: str,
    disease_name: str,
    gene_filter: Optional[str],
    min_confidence: float
) -> List[Dict[str, Any]]:
    """
    Find embedding-based rescue predictions for drug-disease pair.

    Uses PREDICTS_RESCUE_MODEX_16D and PREDICTS_RESCUE_EP edges.

    Args:
        session: Neo4j session
        drug_name: Normalized drug name
        disease_name: Normalized disease name
        gene_filter: Optional gene to filter predictions
        min_confidence: Minimum confidence threshold

    Returns:
        List of rescue prediction dicts
    """
    rescue_predictions = []

    try:
        # Build gene filter
        gene_filter_clause = ""
        if gene_filter:
            gene_filter_clause = f"AND toLower(g.symbol) = toLower('{gene_filter}')"

        # Query for rescue predictions through disease-associated genes
        query = f"""
        MATCH (drug:Drug {{name: $drug_name}})-[r:PREDICTS_RESCUE_MODEX_16D|PREDICTS_RESCUE_EP]->(g:Gene)-[assoc:CAUSAL_FOR|ASSOCIATED_WITH]->(disease:Disease {{name: $disease_name}})
        WHERE r.rescue_score >= $min_confidence
        {gene_filter_clause}
        RETURN g.symbol as gene,
               r.rescue_score as rescue_score,
               r.raw_similarity as antipodal_distance,
               type(r) as prediction_type,
               r.source as source,
               assoc.confidence_score as disease_association_confidence
        ORDER BY r.rescue_score DESC
        LIMIT 10
        """

        result = session.run(
            query,
            drug_name=drug_name,
            disease_name=disease_name,
            min_confidence=min_confidence
        )

        for record in result:
            gene = record["gene"]
            rescue_score = record["rescue_score"]
            antipodal_distance = record["antipodal_distance"]
            prediction_type = record["prediction_type"]
            source = record["source"] or prediction_type
            disease_assoc_conf = record.get("disease_association_confidence", 0.8)

            # Calculate overall confidence (rescue score × disease association)
            confidence = rescue_score * disease_assoc_conf

            # Build mechanism narrative
            if prediction_type == "PREDICTS_RESCUE_MODEX_16D":
                mechanism = f"Drug rescues {gene} dysfunction via MODEX_16D embedding proximity (antipodal score: {round(antipodal_distance, 3)}). {gene} is causative for {disease_name}."
            else:
                mechanism = f"Drug rescues {gene} dysfunction via EP disease model (rescue score: {round(rescue_score, 3)}). {gene} is associated with {disease_name}."

            rescue_predictions.append({
                "gene": gene,
                "rescue_score": round(rescue_score, 3),
                "antipodal_distance": round(antipodal_distance, 3) if antipodal_distance else None,
                "mechanism": mechanism,
                "confidence": round(confidence, 3),
                "prediction_type": prediction_type.replace("PREDICTS_RESCUE_", ""),
                "source": source
            })

        return rescue_predictions

    except Exception as e:
        logger.error(f"Error in _find_rescue_mechanisms: {str(e)}")
        return []


def _generate_summary(
    drug_name: str,
    disease_name: str,
    mechanisms: List[Dict],
    rescue_predictions: List[Dict],
    explanation_style: str
) -> str:
    """
    Generate overall mechanistic summary.

    Args:
        drug_name: Drug name
        disease_name: Disease name
        mechanisms: List of traditional mechanisms
        rescue_predictions: List of rescue predictions
        explanation_style: Detail level

    Returns:
        Summary string
    """
    if not mechanisms and not rescue_predictions:
        return f"No mechanisms found connecting {drug_name} to {disease_name}."

    if explanation_style == "pathways_only":
        pathways = []
        for m in mechanisms:
            for node in m.get("path", []):
                if node.get("type") == "Pathway":
                    pathways.append(node["entity"])
        return f"Pathways involved: {', '.join(set(pathways))}" if pathways else "No pathways identified"

    # Build summary
    summary_parts = []

    # Add traditional mechanisms
    if mechanisms:
        mech_count = len(mechanisms)
        mech_types = list(set(m["mechanism_type"] for m in mechanisms))
        summary_parts.append(
            f"{drug_name} treats {disease_name} through {mech_count} mechanism(s): "
            f"{', '.join([mt.replace('_', ' ') for mt in mech_types])}"
        )

    # Add rescue predictions
    if rescue_predictions:
        genes = [r["gene"] for r in rescue_predictions]
        summary_parts.append(
            f"Additionally, embedding-based predictions suggest {drug_name} rescues dysfunction in: "
            f"{', '.join(genes[:5])}"  # Show top 5 genes
        )

    summary = ". ".join(summary_parts) + "."

    return summary


# Export tool for registration
__all__ = ["TOOL_DEFINITION", "execute"]
