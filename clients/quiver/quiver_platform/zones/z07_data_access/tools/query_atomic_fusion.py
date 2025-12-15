"""
Query Atomic Fusion - Adaptive Cards for User-Controlled Data Source Selection
================================================================================

Tier 2 pathway: Claude presents embedding space options via adaptive cards,
user selects sources, system executes atomic searches in parallel and fuses results.

Flow:
1. Resolve entity via meta layer
2. Query metagraph for available embedding spaces
3. Build adaptive card with space options
4. User selects sources
5. Execute searches in parallel
6. Fuse results (embeddings + optional graph enrichment)

Author: Pathway Integration
Date: 2025-12-01
Zone: z07_data_access/tools
"""

from typing import Dict, Any, List
import time
from neo4j import GraphDatabase
import os

# Tool definition for Claude
TOOL_DEFINITION = {
    "name": "query_atomic_fusion",
    "description": """ADAPTIVE CARDS: Present embedding space options to user, execute atomic searches in parallel, fuse results.

Use this when:
- Multiple embedding spaces could work
- User should control data sources
- Query needs fusion (e.g., "structural + mechanism similarity")
- Entity name needs fuzzy matching

Flow:
1. You query metagraph to discover available spaces
2. You present adaptive card with space options
3. User selects sources
4. System executes atomic searches in parallel
5. Results are fused: embeddings first, then optional graph enrichment

This uses meta layer for entity resolution but user controls source selection.

Performance: 200-500ms depending on selected spaces
Data Sources: User-selected from metagraph-discovered embedding spaces
User Control: Full transparency and selection via adaptive cards
""",
    "input_schema": {
        "type": "object",
        "properties": {
            "query": {
                "type": "string",
                "description": "User's natural language query for context"
            },
            "entity_name": {
                "type": "string",
                "description": "Primary entity to search for"
            },
            "entity_type": {
                "type": "string",
                "enum": ["drug", "gene", "protein", "disease", "pathway"],
                "description": "Type of entity"
            },
            "intent": {
                "type": "string",
                "enum": ["similarity", "rescue", "mechanism", "pathway_enrichment", "cross_entity", "fusion_comparison"],
                "description": "Query intent to guide source recommendations"
            },
            "k": {
                "type": "integer",
                "description": "Number of neighbors per space (1-50)",
                "default": 20,
                "minimum": 1,
                "maximum": 50
            }
        },
        "required": ["query", "entity_name", "entity_type", "intent"]
    }
}


async def execute(params: Dict[str, Any]) -> Dict[str, Any]:
    """
    Adaptive card workflow for source selection + fusion

    Args:
        params: Tool input parameters

    Returns:
        Adaptive card for user selection OR results if user already selected
    """
    start_time = time.time()

    query = params["query"]
    entity_name = params["entity_name"]
    entity_type = params["entity_type"]
    intent = params["intent"]
    k = params.get("k", 20)

    try:
        # Step 1: Resolve entity via meta layer
        resolved_name, confidence = await _resolve_entity(entity_name, entity_type)

        # Step 2: Discover available spaces from metagraph
        available_spaces = await _discover_spaces_from_metagraph(entity_type)

        if not available_spaces:
            return {
                "success": False,
                "error": f"No embedding spaces found for entity_type: {entity_type}",
                "suggestion": "Try query_direct_run with explicit space selection"
            }

        # Step 3: Recommend spaces based on intent
        recommendations = _recommend_spaces_for_intent(available_spaces, intent)

        # Step 4: Build adaptive card
        card = _build_source_selection_card(
            query=query,
            entity_name=entity_name,
            resolved_name=resolved_name,
            confidence=confidence,
            intent=intent,
            available_spaces=available_spaces,
            recommendations=recommendations,
            k=k
        )

        latency = (time.time() - start_time) * 1000

        # Return adaptive card for user to select sources
        return {
            "success": True,
            "pathway": "atomic_fusion",
            "requires_user_input": True,
            "adaptive_card": card,
            "resolved_entity": resolved_name,
            "resolution_confidence": confidence,
            "available_spaces_count": len(available_spaces),
            "recommended_spaces": [s["name"] for s in recommendations["recommended"]],
            "recommendation_reason": recommendations["reason"],
            "card_generation_ms": round(latency, 2),
            "next_step": "User will select embedding spaces via card, then system executes fusion"
        }

    except Exception as e:
        latency = (time.time() - start_time) * 1000

        return {
            "success": False,
            "error": f"Atomic fusion setup failed: {str(e)}",
            "pathway": "atomic_fusion",
            "latency_ms": round(latency, 2)
        }


async def _resolve_entity(entity_name: str, entity_type: str) -> tuple[str, float]:
    """
    Resolve entity name using meta layer resolvers

    Returns:
        (resolved_name, confidence)
    """
    try:
        # Import resolvers dynamically
        if entity_type == "drug":
            from clients.quiver.quiver_platform.zones.z07_data_access.meta_layer.resolvers.drug_name_resolver import DrugNameResolver
            resolver = DrugNameResolver()
        elif entity_type == "gene":
            from clients.quiver.quiver_platform.zones.z07_data_access.meta_layer.resolvers.gene_name_resolver import GeneNameResolver
            resolver = GeneNameResolver()
        else:
            # No resolver for this type, return as-is
            return entity_name, 1.0

        resolution = resolver.resolve(entity_name)

        if resolution["confidence"] == "unknown":
            return entity_name, 0.5

        # Map confidence levels to numeric scores
        confidence_map = {
            "high": 0.95,
            "medium": 0.75,
            "low": 0.5,
            "unknown": 0.3
        }

        return resolution["result"], confidence_map.get(resolution["confidence"], 0.5)

    except Exception as e:
        # Resolver failed, return original
        print(f"⚠️  Entity resolution failed: {e}")
        return entity_name, 0.5


async def _discover_spaces_from_metagraph(entity_type: str) -> List[Dict[str, Any]]:
    """
    Query metagraph to discover embedding spaces for entity type

    Returns:
        List of embedding space metadata
    """
    try:
        driver = GraphDatabase.driver(
            os.getenv("NEO4J_URI", "bolt://localhost:7687"),
            auth=(
                os.getenv("NEO4J_USER", "neo4j"),
                os.getenv("NEO4J_PASSWORD", "testpassword123")
            )
        )

        with driver.session() as session:
            result = session.run("""
                MATCH (e:EmbeddingSpace)
                WHERE e.entity_type = $entity_type
                  AND e.row_count > 0
                  AND e.pgvector_status = 'loaded'
                RETURN
                    e.name as name,
                    e.table_name as table_name,
                    e.dimension as dimension,
                    e.row_count as entity_count,
                    e.quality_tier as quality_tier,
                    e.embedding_version as version
                ORDER BY e.quality_tier, e.row_count DESC
            """, entity_type=entity_type)

            spaces = [dict(record) for record in result]

        driver.close()

        return spaces

    except Exception as e:
        print(f"⚠️  Metagraph query failed: {e}")
        return []


def _recommend_spaces_for_intent(spaces: List[Dict], intent: str) -> Dict:
    """
    Recommend embedding spaces based on query intent

    Returns:
        {"recommended": [...], "reason": "..."}
    """
    intent_preferences = {
        "similarity": {
            "prefer_keywords": ["gold", "ep_drug", "ens_gene"],
            "reason": "Gold fusion and primary embeddings provide best general similarity search"
        },
        "rescue": {
            "prefer_keywords": ["modex_ep", "modex_gene"],
            "reason": "MODEX embeddings capture mechanism for rescue queries (antipodal search)"
        },
        "mechanism": {
            "prefer_keywords": ["modex"],
            "reason": "MODEX optimized for mechanism of action similarity"
        },
        "pathway_enrichment": {
            "prefer_keywords": ["ens_gene", "modex_gene"],
            "reason": "Gene embeddings with pathway context for enrichment analysis"
        },
        "cross_entity": {
            "prefer_keywords": ["gold", "modex"],
            "reason": "Multi-entity fusion requires comprehensive embeddings"
        },
        "fusion_comparison": {
            "prefer_keywords": ["all"],  # Recommend multiple for comparison
            "reason": "Comparing across embedding spaces - select multiple for fusion analysis"
        }
    }

    preferences = intent_preferences.get(intent, intent_preferences["similarity"])

    recommended = []

    # If "all" keyword, recommend top 3 by quality
    if "all" in preferences["prefer_keywords"]:
        recommended = sorted(spaces, key=lambda x: (x.get('quality_tier', 'Z'), -x.get('entity_count', 0)))[:3]
    else:
        # Match by keywords
        for space in spaces:
            space_name_lower = space.get('name', '').lower()
            for keyword in preferences["prefer_keywords"]:
                if keyword.lower() in space_name_lower:
                    recommended.append(space)
                    break

    # If no matches, recommend top 2 by quality
    if not recommended:
        recommended = sorted(spaces, key=lambda x: (x.get('quality_tier', 'Z'), -x.get('entity_count', 0)))[:2]

    return {
        "recommended": recommended,
        "reason": preferences["reason"]
    }


def _build_source_selection_card(
    query: str,
    entity_name: str,
    resolved_name: str,
    confidence: float,
    intent: str,
    available_spaces: List[Dict],
    recommendations: Dict,
    k: int
) -> Dict[str, Any]:
    """
    Build adaptive card for user to select embedding spaces

    Returns:
        Adaptive card JSON
    """
    # Format space choices
    choices = []
    default_selections = []

    for space in available_spaces:
        is_recommended = any(
            rec.get('name') == space.get('name')
            for rec in recommendations["recommended"]
        )

        choice_title = _format_space_choice(space, is_recommended)

        choices.append({
            "title": choice_title,
            "value": space["table_name"]
        })

        # Pre-select recommended spaces
        if is_recommended:
            default_selections.append(space["table_name"])

    card = {
        "type": "AdaptiveCard",
        "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
        "version": "1.5",
        "body": [
            {
                "type": "TextBlock",
                "text": "🎯 Atomic Fusion Query",
                "weight": "bolder",
                "size": "large"
            },
            {
                "type": "TextBlock",
                "text": f"**Query:** {query}",
                "wrap": True,
                "spacing": "small"
            },
            {
                "type": "FactSet",
                "spacing": "medium",
                "facts": [
                    {"title": "Entity", "value": entity_name},
                    {"title": "Resolved To", "value": resolved_name},
                    {"title": "Confidence", "value": f"{confidence:.0%}"},
                    {"title": "Intent", "value": intent.replace('_', ' ').title()},
                    {"title": "Neighbors/Space", "value": str(k)}
                ]
            },
            {
                "type": "TextBlock",
                "text": "**Select embedding spaces to search:**",
                "weight": "bolder",
                "spacing": "large"
            },
            {
                "type": "TextBlock",
                "text": f"💡 *Recommendation:* {recommendations['reason']}",
                "wrap": True,
                "isSubtle": True,
                "spacing": "small"
            },
            {
                "type": "Input.ChoiceSet",
                "id": "embedding_spaces",
                "isMultiSelect": True,
                "style": "expanded",
                "choices": choices,
                "value": ",".join(default_selections) if default_selections else None
            },
            {
                "type": "TextBlock",
                "text": "**Options:**",
                "weight": "bolder",
                "spacing": "large"
            },
            {
                "type": "Input.Toggle",
                "id": "graph_enrichment",
                "title": "Add graph relationships after embedding fusion?",
                "value": "true",
                "wrap": True
            },
            {
                "type": "Input.Toggle",
                "id": "cross_entity",
                "title": "Enable cross-entity queries (e.g., gene→drug via Neo4j bridge)?",
                "value": "false",
                "wrap": True
            }
        ],
        "actions": [
            {
                "type": "Action.Submit",
                "title": "🚀 Execute Fusion",
                "style": "positive",
                "data": {
                    "action": "execute_atomic_fusion",
                    "query": query,
                    "entity_name": resolved_name,
                    "entity_type": available_spaces[0].get('entity_type', 'unknown') if available_spaces else 'unknown',
                    "intent": intent,
                    "k": k
                }
            },
            {
                "type": "Action.Submit",
                "title": "⚡ Switch to Direct Run",
                "data": {
                    "action": "switch_to_direct",
                    "entity_name": resolved_name,
                    "entity_type": available_spaces[0].get('entity_type', 'unknown') if available_spaces else 'unknown'
                }
            }
        ]
    }

    return card


def _format_space_choice(space: Dict, is_recommended: bool) -> str:
    """Format space choice for adaptive card"""
    marker = "⭐ " if is_recommended else ""
    name = space.get('name', 'Unknown')
    dimension = space.get('dimension', 0)
    quality = space.get('quality_tier', '?')
    count = space.get('entity_count', 0)

    return f"{marker}{name} ({dimension}D, {quality}-tier) - {count:,} entities"
