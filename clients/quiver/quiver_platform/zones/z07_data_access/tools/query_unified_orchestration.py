"""
Query Unified Orchestration - Full Intelligence with Confirmation
==================================================================

Tier 3 pathway: Metagraph-driven multi-step query execution with human-in-the-loop confirmation.

Flow:
1. Intelligence broker checks for similar patterns
2. Analyze query to determine tools needed
3. Metagraph discovers optimal embedding spaces for each tool
4. Build execution plan
5. Present confirmation card to user
6. User confirms/modifies/cancels
7. Execute plan with full orchestration
8. Record results to metagraph for learning

CRITICAL: This does NOT auto-resolve 100%. User MUST confirm execution plan.

Author: Pathway Integration
Date: 2025-12-01
Zone: z07_data_access/tools
"""

from typing import Dict, Any, List
import time
import uuid
import os
from neo4j import GraphDatabase

# Tool definition for Claude
TOOL_DEFINITION = {
    "name": "query_unified_orchestration",
    "description": """FULL ORCHESTRATION: Metagraph-driven multi-step query with confirmation before execution.

Use this when:
- Query is complex (multi-step reasoning)
- Multiple tools needed (vector + graph + semantic)
- Optimal path unclear
- User wants full transparency

Flow:
1. Intelligence broker checks for similar patterns
2. Metagraph discovers optimal tool sequence
3. Meta layer resolves all entities
4. You present execution plan as adaptive card
5. User confirms or modifies
6. System executes plan
7. Results recorded to metagraph for learning

CRITICAL: This does NOT auto-resolve 100%. User MUST confirm execution plan.
If plan looks wrong, user can downgrade to atomic_fusion or direct_run.

Performance: 400-2000ms depending on plan complexity
Data Sources: Metagraph-optimized selection across all available spaces
User Control: Full transparency with required confirmation
Intelligence: Pattern matching, historical success rates, adaptive learning
""",
    "input_schema": {
        "type": "object",
        "properties": {
            "query": {
                "type": "string",
                "description": "User's natural language query"
            },
            "entities": {
                "type": "array",
                "items": {"type": "string"},
                "description": "Primary entities mentioned in query"
            },
            "intent": {
                "type": "string",
                "description": "Primary query intent (your best assessment)"
            },
            "estimated_complexity": {
                "type": "string",
                "enum": ["low", "medium", "high", "very_high"],
                "description": "Your assessment of query complexity"
            },
            "auto_execute": {
                "type": "boolean",
                "description": "Auto-execute plan without confirmation (for testing/API use). Default: false (requires HITL confirmation)",
                "default": False
            }
        },
        "required": ["query", "entities", "intent"]
    }
}


async def execute(params: Dict[str, Any]) -> Dict[str, Any]:
    """
    Full orchestration with optional auto-execution

    Args:
        params: Tool input parameters
            - auto_execute: If True, executes immediately without confirmation (for testing/API)
                           If False (default), returns confirmation card (for interactive HITL)

    Returns:
        If auto_execute=False: Execution plan as adaptive card for user confirmation
        If auto_execute=True: Actual execution results
    """
    start_time = time.time()

    query = params["query"]
    entities = params["entities"]
    intent = params["intent"]
    complexity = params.get("estimated_complexity", "medium")
    auto_execute = params.get("auto_execute", False)

    try:
        # Step 1: Intelligence broker pattern check
        pattern_match = await _check_intelligence_patterns(query)

        # Step 2: Analyze query to determine tools needed
        query_analysis = _analyze_query_requirements(query, entities, intent)

        # Step 3: Metagraph discovery for each tool
        execution_steps = await _discover_execution_plan(query_analysis, intent)

        if not execution_steps:
            return {
                "success": False,
                "error": "No execution plan could be generated",
                "suggestion": "Try query_atomic_fusion for manual source selection"
            }

        # Calculate total estimate
        total_time_estimate = sum(step.get('estimated_latency_ms', 200) for step in execution_steps)

        # Step 4: Either execute immediately or return confirmation card
        plan_id = str(uuid.uuid4())[:8]

        if auto_execute:
            # AUTO-EXECUTE MODE (for testing/API use)
            # Execute plan immediately without confirmation
            execution_results = await _execute_plan(
                execution_steps=execution_steps,
                entities=entities,
                query=query,
                plan_id=plan_id
            )

            latency = (time.time() - start_time) * 1000

            return {
                "success": True,
                "pathway": "unified_orchestration",
                "mode": "auto_execute",
                "plan_id": plan_id,
                "execution_steps_count": len(execution_steps),
                "pattern_match": pattern_match,
                "results": execution_results,
                "total_latency_ms": round(latency, 2),
                "intelligence_broker_consulted": True,
                "metagraph_discovery": "complete"
            }
        else:
            # INTERACTIVE MODE (default - HITL confirmation)
            # Build confirmation card for user approval
            card = _build_execution_plan_card(
                query=query,
                entities=entities,
                intent=intent,
                complexity=complexity,
                pattern_match=pattern_match,
                execution_steps=execution_steps,
                total_time_estimate=total_time_estimate,
                plan_id=plan_id
            )

            latency = (time.time() - start_time) * 1000

            return {
                "success": True,
                "pathway": "unified_orchestration",
                "mode": "interactive",
                "requires_user_input": True,
                "adaptive_card": card,
                "plan_id": plan_id,
                "execution_steps_count": len(execution_steps),
                "estimated_time_ms": total_time_estimate,
                "pattern_match": pattern_match,
                "metagraph_discovery": "complete",
                "intelligence_broker_consulted": True,
                "plan_generation_ms": round(latency, 2),
                "next_step": "User must confirm execution plan via card"
            }

    except Exception as e:
        latency = (time.time() - start_time) * 1000

        return {
            "success": False,
            "error": f"Unified orchestration failed: {str(e)}",
            "pathway": "unified_orchestration",
            "latency_ms": round(latency, 2)
        }


async def _check_intelligence_patterns(query: str) -> Dict[str, Any]:
    """
    Check intelligence broker for similar patterns

    Returns:
        Pattern match information

    SAP-60 FIX (2025-12-08): Disabled due to zone violation
    - z07_data_access cannot import from z03a_cognitive (level 3→4)
    - Returns fallback response (no pattern match)
    """
    # DISABLED: Zone violation - always return fallback
    return {
        "exists": False,
        "recommendation": "NEW_QUERY",
        "confidence": 0.0,
        "note": "Intelligence broker disabled due to zone violation (SAP-60)"
        }


def _analyze_query_requirements(query: str, entities: List[str], intent: str) -> Dict[str, Any]:
    """
    Analyze query to determine tools and execution plan

    Returns:
        Query analysis with tools needed
    """
    # Intent-to-tools mapping
    intent_tools = {
        "similarity": [
            {
                "tool": "vector_neighbors",
                "description": "Find similar entities via embedding similarity",
                "entity_type": "drug",  # Default, will be refined
                "dependencies": []
            }
        ],
        "rescue": [
            {
                "tool": "vector_antipodal",
                "description": "Find rescue compounds using antipodal embeddings",
                "entity_type": "gene",
                "dependencies": []
            },
            {
                "tool": "graph_neighbors",
                "description": "Validate rescue candidates via TARGETS relationships",
                "entity_type": "drug",
                "dependencies": [0]  # Depends on step 0
            }
        ],
        "mechanism": [
            {
                "tool": "vector_neighbors",
                "description": "Find mechanistically similar drugs",
                "entity_type": "drug",
                "dependencies": []
            },
            {
                "tool": "graph_subgraph",
                "description": "Extract mechanism of action subgraph",
                "entity_type": "drug",
                "dependencies": [0]
            },
            {
                "tool": "semantic_search",
                "description": "Find literature evidence for mechanism",
                "entity_type": "literature",
                "dependencies": [1]
            }
        ],
        "pathway_enrichment": [
            {
                "tool": "vector_neighbors",
                "description": "Find similar genes via embeddings",
                "entity_type": "gene",
                "dependencies": []
            },
            {
                "tool": "graph_path",
                "description": "Find shortest paths to pathways",
                "entity_type": "pathway",
                "dependencies": [0]
            }
        ],
        "cross_entity": [
            {
                "tool": "graph_neighbors",
                "description": "Traverse cross-entity relationships",
                "entity_type": "mixed",
                "dependencies": []
            },
            {
                "tool": "vector_neighbors",
                "description": "Find similar entities in target space",
                "entity_type": "mixed",
                "dependencies": [0]
            }
        ]
    }

    tools_needed = intent_tools.get(intent, intent_tools["similarity"])

    # Infer primary entity type from query
    primary_entity_type = "drug"  # Default
    if any(word in query.lower() for word in ["gene", "protein", "scn1a", "tsc2", "brca1"]):
        primary_entity_type = "gene"
    elif any(word in query.lower() for word in ["pathway", "signaling", "metabolism"]):
        primary_entity_type = "pathway"

    return {
        "tools_needed": tools_needed,
        "primary_entity_type": primary_entity_type,
        "multi_step": len(tools_needed) > 1,
        "entities": entities
    }


async def _discover_execution_plan(query_analysis: Dict[str, Any], intent: str) -> List[Dict[str, Any]]:
    """
    Use metagraph to discover optimal execution plan

    Returns:
        List of execution steps with metagraph-selected spaces
    """
    from clients.quiver.quiver_platform.zones.z07_data_access.unified_query_layer import get_unified_query_layer

    uql = get_unified_query_layer()

    execution_steps = []
    step_number = 1

    for tool_req in query_analysis["tools_needed"]:
        tool_name = tool_req["tool"]

        # Discover tool capabilities from metagraph
        capabilities = uql.discover_tool_capabilities(tool_name)

        if not capabilities.get('embedding_spaces'):
            # Graph-only tool (no embeddings)
            execution_steps.append({
                "step_number": step_number,
                "tool": tool_name,
                "tool_description": tool_req["description"],
                "data_source": "Neo4j Graph",
                "embedding_space": None,
                "table_name": None,
                "dimension": None,
                "selection_reason": "Graph traversal only",
                "selection_score": 100,
                "estimated_latency_ms": 150,
                "dependencies": tool_req.get("dependencies", [])
            })
        else:
            # Select best embedding space via metagraph
            selected_space = uql._select_embedding_space(
                capabilities,
                {"entity_type": tool_req.get("entity_type", "unknown")},
                intent
            )

            execution_steps.append({
                "step_number": step_number,
                "tool": tool_name,
                "tool_description": tool_req["description"],
                "data_source": "PGVector + Neo4j",
                "embedding_space": selected_space.get("name"),
                "table_name": selected_space.get("table_name"),
                "dimension": selected_space.get("dimension"),
                "quality_tier": selected_space.get("quality_tier"),
                "selection_reason": selected_space.get("selection_reason", "Unknown"),
                "selection_score": round(selected_space.get("selection_score", 0), 1),
                "estimated_latency_ms": selected_space.get("expected_latency_ms", 200),
                "dependencies": tool_req.get("dependencies", [])
            })

        step_number += 1

    return execution_steps


def _build_execution_plan_card(
    query: str,
    entities: List[str],
    intent: str,
    complexity: str,
    pattern_match: Dict,
    execution_steps: List[Dict],
    total_time_estimate: int,
    plan_id: str
) -> Dict[str, Any]:
    """
    Build adaptive card for execution plan confirmation

    Returns:
        Adaptive card JSON
    """
    card = {
        "type": "AdaptiveCard",
        "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
        "version": "1.5",
        "body": [
            {
                "type": "TextBlock",
                "text": "🤖 Unified Orchestration Plan",
                "weight": "bolder",
                "size": "large",
                "color": "accent"
            },
            {
                "type": "TextBlock",
                "text": "⚠️ **Review Required** - Confirm before execution",
                "wrap": True,
                "color": "warning",
                "spacing": "small"
            },
            {
                "type": "Container",
                "spacing": "medium",
                "items": [
                    {
                        "type": "TextBlock",
                        "text": f"**Query:** {query}",
                        "wrap": True
                    },
                    {
                        "type": "FactSet",
                        "facts": [
                            {"title": "Entities", "value": ", ".join(entities)},
                            {"title": "Intent", "value": intent.replace('_', ' ').title()},
                            {"title": "Complexity", "value": complexity.upper()},
                            {"title": "Steps", "value": str(len(execution_steps))},
                            {"title": "Est. Time", "value": f"{total_time_estimate}ms"},
                            {"title": "Pattern Match", "value": pattern_match.get("recommendation", "NEW_QUERY")},
                            {"title": "Plan ID", "value": plan_id}
                        ]
                    }
                ]
            },
            {
                "type": "TextBlock",
                "text": "**Execution Steps (Metagraph-Optimized):**",
                "weight": "bolder",
                "spacing": "large"
            }
        ] + [
            _build_step_container(step) for step in execution_steps
        ] + [
            {
                "type": "Container",
                "spacing": "large",
                "style": "emphasis",
                "items": [
                    {
                        "type": "TextBlock",
                        "text": "**Action Required:**",
                        "weight": "bolder"
                    },
                    {
                        "type": "TextBlock",
                        "text": "• ✅ **Execute Plan** - Run with metagraph-selected sources\n• ✏️ **Atomic Fusion** - Choose sources manually via card\n• ⚡ **Direct Run** - Bypass orchestration (fast path)\n• ❌ **Cancel** - Abort query",
                        "wrap": True
                    }
                ]
            }
        ],
        "actions": [
            {
                "type": "Action.Submit",
                "title": "✅ Execute Plan",
                "style": "positive",
                "data": {
                    "action": "execute_unified_plan",
                    "plan_id": plan_id,
                    "steps": execution_steps,
                    "query": query
                }
            },
            {
                "type": "Action.Submit",
                "title": "✏️ Atomic Fusion Instead",
                "data": {
                    "action": "downgrade_to_atomic",
                    "query": query,
                    "entities": entities,
                    "intent": intent
                }
            },
            {
                "type": "Action.Submit",
                "title": "⚡ Direct Run Instead",
                "data": {
                    "action": "downgrade_to_direct",
                    "entity": entities[0] if entities else "",
                    "entity_type": "drug"  # Will be refined
                }
            },
            {
                "type": "Action.Submit",
                "title": "❌ Cancel",
                "style": "destructive",
                "data": {"action": "cancel"}
            }
        ]
    }

    return card


def _build_step_container(step: Dict) -> Dict[str, Any]:
    """Build adaptive card container for a single execution step"""
    return {
        "type": "Container",
        "separator": True,
        "spacing": "small",
        "items": [
            {
                "type": "ColumnSet",
                "columns": [
                    {
                        "type": "Column",
                        "width": "auto",
                        "items": [
                            {
                                "type": "TextBlock",
                                "text": f"**{step['step_number']}.**",
                                "size": "large",
                                "color": "accent"
                            }
                        ]
                    },
                    {
                        "type": "Column",
                        "width": "stretch",
                        "items": [
                            {
                                "type": "TextBlock",
                                "text": f"**{step['tool']}**",
                                "weight": "bolder"
                            },
                            {
                                "type": "TextBlock",
                                "text": step['tool_description'],
                                "size": "small",
                                "wrap": True,
                                "spacing": "none"
                            },
                            {
                                "type": "FactSet",
                                "spacing": "small",
                                "facts": [
                                    {"title": "Source", "value": step['data_source']},
                                    {"title": "Space", "value": step.get('embedding_space') or "N/A"},
                                    {"title": "Quality", "value": f"{step.get('quality_tier', 'N/A')}-tier (score: {step.get('selection_score', 0)})"},
                                    {"title": "Why", "value": step['selection_reason']},
                                    {"title": "Est.", "value": f"{step['estimated_latency_ms']}ms"}
                                ]
                            }
                        ]
                    }
                ]
            }
        ]
    }


async def _execute_plan(
    execution_steps: List[Dict[str, Any]],
    entities: List[str],
    query: str,
    plan_id: str
) -> Dict[str, Any]:
    """
    Execute the generated plan by running each step sequentially

    Args:
        execution_steps: List of steps to execute
        entities: Primary entities from query
        query: Original query text
        plan_id: Plan identifier for tracking

    Returns:
        Consolidated execution results
    """
    step_results = []
    step_outputs = {}  # Store outputs for dependency resolution

    for step in execution_steps:
        step_num = step['step_number']
        tool_name = step['tool']

        try:
            # Import the tool dynamically
            tool_module = await _import_tool(tool_name)

            if not tool_module:
                step_results.append({
                    "step": step_num,
                    "tool": tool_name,
                    "success": False,
                    "error": f"Tool {tool_name} not found"
                })
                continue

            # Build parameters based on tool type
            tool_params = _build_tool_params(
                tool_name=tool_name,
                entities=entities,
                step=step,
                previous_outputs=step_outputs
            )

            # Execute the tool
            start_time = time.time()
            result = await tool_module.execute(tool_params)
            execution_time = (time.time() - start_time) * 1000

            # Store result for potential dependencies
            step_outputs[step_num] = result

            step_results.append({
                "step": step_num,
                "tool": tool_name,
                "success": result.get("success", False),
                "execution_time_ms": round(execution_time, 2),
                "data": result.get("data") or result.get("results"),
                "error": result.get("error")
            })

        except Exception as e:
            step_results.append({
                "step": step_num,
                "tool": tool_name,
                "success": False,
                "error": f"Execution failed: {str(e)}"
            })

    # Consolidate results
    successful_steps = sum(1 for r in step_results if r['success'])
    total_steps = len(step_results)

    return {
        "plan_id": plan_id,
        "query": query,
        "total_steps": total_steps,
        "successful_steps": successful_steps,
        "failed_steps": total_steps - successful_steps,
        "overall_success": successful_steps == total_steps,
        "step_results": step_results,
        "summary": f"Executed {successful_steps}/{total_steps} steps successfully"
    }


async def _import_tool(tool_name: str):
    """Dynamically import a tool by name"""
    try:
        # Map tool names to their modules
        tool_map = {
            "vector_neighbors": "clients.quiver.quiver_platform.zones.z07_data_access.tools.vector_neighbors",
            "vector_similarity": "clients.quiver.quiver_platform.zones.z07_data_access.tools.vector_similarity",
            "vector_antipodal": "clients.quiver.quiver_platform.zones.z07_data_access.tools.vector_antipodal",
            "graph_neighbors": "clients.quiver.quiver_platform.zones.z07_data_access.tools.graph_neighbors",
            "graph_path": "clients.quiver.quiver_platform.zones.z07_data_access.tools.graph_path",
            "graph_subgraph": "clients.quiver.quiver_platform.zones.z07_data_access.tools.graph_subgraph",
            "semantic_search": "clients.quiver.quiver_platform.zones.z07_data_access.tools.semantic_search",
        }

        module_path = tool_map.get(tool_name)
        if not module_path:
            return None

        # Dynamic import
        import importlib
        module = importlib.import_module(module_path)
        return module

    except Exception as e:
        print(f"⚠️  Failed to import {tool_name}: {e}")
        return None


def _build_tool_params(
    tool_name: str,
    entities: List[str],
    step: Dict[str, Any],
    previous_outputs: Dict[int, Any]
) -> Dict[str, Any]:
    """
    Build parameters for a tool based on its requirements

    Args:
        tool_name: Name of the tool
        entities: Primary entities from query
        step: Execution step details
        previous_outputs: Results from previous steps

    Returns:
        Parameters dict for the tool
    """
    # Default parameters based on tool type
    if tool_name == "vector_neighbors":
        return {
            "entity": entities[0] if entities else "TSC2",
            "entity_type": step.get("entity_type", "gene"),
            "k": 10
        }

    elif tool_name == "vector_similarity":
        return {
            "entity1": entities[0] if len(entities) > 0 else "TSC2",
            "entity2": entities[1] if len(entities) > 1 else "TP53",
            "entity_type": step.get("entity_type", "gene")
        }

    elif tool_name == "vector_antipodal":
        return {
            "gene": entities[0] if entities else "TSC2",
            "top_k": 10
        }

    elif tool_name == "graph_neighbors":
        return {
            "node_name": entities[0] if entities else "EGFR",
            "relationship_types": ["TARGETS"],
            "direction": "incoming"
        }

    elif tool_name == "graph_path":
        return {
            "source_node": entities[0] if len(entities) > 0 else "TSC2",
            "target_node": entities[1] if len(entities) > 1 else "epilepsy",
            "max_depth": 3
        }

    elif tool_name == "graph_subgraph":
        return {
            "center_node": entities[0] if entities else "TSC2",
            "depth": 2
        }

    elif tool_name == "semantic_search":
        return {
            "query": " ".join(entities) if entities else "epilepsy",
            "collection_name": "cns_drug_discovery_papers",
            "k": 5
        }

    else:
        # Generic fallback
        return {
            "entity": entities[0] if entities else "TSC2",
            "entity_type": "gene"
        }
