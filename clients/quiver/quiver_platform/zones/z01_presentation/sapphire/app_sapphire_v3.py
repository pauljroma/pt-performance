#!/usr/bin/env python3.11
"""
QNVS Sapphire v3.23 - Pure Agentic Biomedical Research Assistant with Atomic Fusion Primitives

Architecture: Pure Agentic with 60 Atomic Tools + 14 Fusion Primitives + 3-Tier Query Pathways
- Claude Sonnet 4.5 orchestrates all data access AND pathway selection
- Three query tiers: Direct Runs (fast), Atomic Fusion (user-controlled), Unified Orchestration (full intelligence)
- 60 atomic tools including 14 fusion table wrappers for composable multi-hop reasoning
- Atomic fusion primitives: Direct 1:1 mapping to all 14 PostgreSQL v6.0 fusion tables
- Metagraph-driven embedding discovery (154 spaces, 35 tools registered)
- Unified query layer with meta layer resolvers
- Intelligence broker integration for pattern matching and safety
- Adaptive cards for user control and confirmation
- Fuzzy matching for entity names (handles typos)
- Multi-tool orchestration for complex queries
- Commercial drug name resolution (Sapphire v3.1)
- Multi-embedding space support (9 spaces: ENS, MODEX, Transcript, PCA, PLATINUM, DFP, 473K LINCS)
- CNS safety assessment (BBB permeability, ADME/Tox prediction)

Version History:
- v2.0: Manual routing with TF-IDF + capability handlers
- v2.5: Hybrid fast-path (archived - cost optimization)
- v3.0: Pure agentic with 15 atomic tools
- v3.1: Drug combinations + commercial names + multi-space
- v3.2: Provenance discovery with EP attribution + 8/9 embedding spaces + JSON persistence
- v3.3: Reporting facility + 226GB PostgreSQL integration (session analytics, drug/LINCS detail tools)
- v3.4: Streaming API + parallel tool execution with asyncio.gather()
- v3.5: Extended context (64K tokens, 10 turns, 20 exchanges) for complex multi-tool queries
- v3.6: Maximum context (200K tokens) with LiteLLM compression (90%+ compression at scale) + environment fixes
- v3.7: LiteLLM-Anthropic bridge integration (message history compression, cost tracking, caching) - PRODUCTION
- v3.7.1: Python 3.9 compatibility fix + multi-port ChromaDB support
- v3.7.2: Enhanced error handling + error message display in UI
- v3.7.3: Fixed vector_neighbors auto-detection + tools verified working
- v3.8: Service integration tools (Literature Search Agent, Biomarker Discovery, Evidence Chains)
- v3.12: CNS safety tools (BBB Permeability, ADME/Tox Predictor)
- v3.13: Three-tier query pathways (Direct Run, Atomic Fusion, Unified Orchestration) with metagraph integration
- v3.14: Complete tool integration - Re-enabled CNS safety (2) + Advanced analytical tools (3) = 35 total
- v3.15: Strategic Intelligence Tools - Clinical trials + Target validation + Drug repurposing (3) = 38 total
- v3.16: Scientist Reports - Disease analysis reports with AI grading (2) = 40 total
- v3.17: DeMeo v2.0 Drug Rescue - Multi-modal Bayesian fusion with metagraph caching (1) = 41 total
- v3.18: Intent Classifier - Query intent classification for optimized pathway routing (1) = 42 total
- v3.22: Fusion Discovery - Drug/gene fusion discovery + entity connection tracking + 85% goal dashboard (4) = 46 total
- v3.23: Atomic Fusion Primitives - 14 atomic wrappers for all fusion tables (d_aux_*, g_aux_*, d_g_*, d_d_*, g_g_*) (14) = 60 total (current)

Tools Available (60):
  Vector (5): vector_antipodal, vector_neighbors, provenance_discovery, vector_similarity, vector_dimensions
  Reporting (3): session_analytics, drug_properties_detail, lincs_expression_detail
  Graph (4): graph_neighbors, graph_path, graph_subgraph, graph_properties
  Semantic (2): semantic_search, semantic_collections
  Utilities (5): entity_metadata, count_entities, available_spaces, execute_cypher, read_parquet_filter
  Drug Combinations (4): drug_interactions, drug_lookalikes, drug_combinations_synergy, rescue_combinations
  Transcriptomic Rescue (1): transcriptomic_rescue
  Service Integrations (3): literature_search_agent, biomarker_discovery, literature_evidence
  CNS Safety (2): bbb_permeability, adme_tox_predictor
  Query Pathways (3): query_direct_run, query_atomic_fusion, query_unified_orchestration
  Advanced Analytics (3): causal_inference, mechanistic_explainer, uncertainty_estimation
  Strategic Intelligence (3): clinical_trial_intelligence, target_validation_scorer, drug_repurposing_ranker
  Scientist Reports (2): generate_scientist_report, generate_all_scientist_reports
  DeMeo v2.0 (1): demeo_drug_rescue
  Intent Classification (1): classify_intent
  Fusion Discovery (4): fusion_discovery_drug, fusion_discovery_gene, entity_connection_tracker, signal_tracking_dashboard
  Atomic Fusion Primitives (14): query_drug_adr_similarity, query_drug_celltype_similarity, query_drug_dgp_similarity,
    query_drug_ep_similarity, query_drug_mop_similarity, query_gene_celltype_similarity, query_gene_dgp_similarity,
    query_gene_ep_similarity, query_gene_mop_similarity, query_gene_syndrome_similarity, query_drug_gene_similarity,
    query_drug_gene_ep_similarity, query_drug_drug_similarity, query_gene_gene_similarity

Data Access:
- 18,368 genes (MODEX 32D embeddings) + ENS v3.1 (64D) + Transcript v1 (32D)
- 14,246 drugs (PCA 32D embeddings) + 473K LINCS (Transcript v1 32D)
- 1.3M nodes, 9.5M relationships (Neo4j)
- 29,863 CNS drug discovery papers (ChromaDB)
- Commercial drug name resolution (2K priority + 14K metadata + 20K LINCS)
- 3 integrated microservices (Literature Search Agent, Biomarker Discovery, Literature Evidence API)
- CNS safety databases (BBB permeability, ADME/Tox profiles)
"""

import asyncio
import json
import os
import sys
import uuid
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, Optional

import chainlit as cl

# Add project root to path - IMPORTANT: Use .resolve() to get absolute path
_file_path = Path(__file__).resolve()
project_root = _file_path.parent

# Add quiver_platform root (3 levels up: sapphire -> z01_presentation -> zones -> quiver_platform)
# THIS MUST BE FIRST to avoid conflicts with /Users/expo/Code/expo/zones
quiver_platform_root = _file_path.parent.parent.parent.parent
sys.path.insert(0, str(quiver_platform_root))

# Add project root after quiver_platform
sys.path.insert(1, str(project_root))

# Add quiver root and expo root (parent of 'clients') to path
quiver_root = quiver_platform_root.parent
expo_root = quiver_root.parent.parent  # Go up to /Users/expo/Code/expo (parent of 'clients')
sys.path.append(str(quiver_root))  # Use append instead of insert to put it at the end
sys.path.append(str(expo_root))     # Use append instead of insert to put it at the end

# Add .claude/skills to path for Sapphire Scientist skill
skills_path = quiver_root / ".claude" / "skills"
sys.path.insert(2, str(skills_path))  # After quiver_platform and project_root

# Import LiteLLM-Anthropic bridge for compression and cost tracking
# Import all 15 tools
# Load environment
from dotenv import load_dotenv

# Import Phase 1-3 Agents (Sapphire v3.24+)
# NOTE: Agent imports temporarily disabled - modules not yet restored
# from zones.z03a_cognitive.agents.intelligence_orchestrator import IntelligenceOrchestrator
# from zones.z05_ml.agents.drug_repurposing import DrugRepurposingAgent
# from zones.z05_ml.agents.target_discovery import TargetDiscoveryAgent
# from zones.z05_ml.agents.safety_prediction import SafetyPredictionAgent
# from zones.z05_ml.agents.pathway_analysis import PathwayAnalysisAgent

from zones.z07_data_access.litellm_anthropic_bridge import (
    get_litellm_client,
)
from zones.z07_data_access.metrics import (
    get_metrics,
)
from zones.z07_data_access.tools.available_spaces import (
    TOOL_DEFINITION as available_spaces_def,
)
from zones.z07_data_access.tools.available_spaces import (
    execute as available_spaces_exec,
)
from zones.z07_data_access.tools.count_entities import (
    TOOL_DEFINITION as count_entities_def,
)
from zones.z07_data_access.tools.count_entities import (
    execute as count_entities_exec,
)
from zones.z07_data_access.tools.drug_combinations_synergy import (
    TOOL_DEFINITION as drug_combinations_synergy_def,
)
from zones.z07_data_access.tools.drug_combinations_synergy import (
    execute as drug_combinations_synergy_exec,
)

# Sapphire v3.1: Drug combination tools (4)
from zones.z07_data_access.tools.drug_interactions import (
    TOOL_DEFINITION as drug_interactions_def,
)
from zones.z07_data_access.tools.drug_interactions import (
    execute as drug_interactions_exec,
)
from zones.z07_data_access.tools.drug_lookalikes import (
    TOOL_DEFINITION as drug_lookalikes_def,
)
from zones.z07_data_access.tools.drug_lookalikes import (
    execute as drug_lookalikes_exec,
)
from zones.z07_data_access.tools.drug_properties_detail import (
    TOOL_DEFINITION as drug_properties_detail_def,
)
from zones.z07_data_access.tools.drug_properties_detail import (
    execute as drug_properties_detail_exec,
)
from zones.z07_data_access.tools.entity_metadata import (
    TOOL_DEFINITION as entity_metadata_def,
)
from zones.z07_data_access.tools.entity_metadata import (
    execute as entity_metadata_exec,
)
from zones.z07_data_access.tools.execute_cypher import (
    TOOL_DEFINITION as execute_cypher_def,
)
from zones.z07_data_access.tools.execute_cypher import (
    execute as execute_cypher_exec,
)
from zones.z07_data_access.tools.graph_neighbors import (
    TOOL_DEFINITION as graph_neighbors_def,
)
from zones.z07_data_access.tools.graph_neighbors import (
    execute as graph_neighbors_exec,
)
from zones.z07_data_access.tools.graph_path import (
    TOOL_DEFINITION as graph_path_def,
)
from zones.z07_data_access.tools.graph_path import (
    execute as graph_path_exec,
)
from zones.z07_data_access.tools.graph_properties import (
    TOOL_DEFINITION as graph_properties_def,
)
from zones.z07_data_access.tools.graph_properties import (
    execute as graph_properties_exec,
)
from zones.z07_data_access.tools.graph_subgraph import (
    TOOL_DEFINITION as graph_subgraph_def,
)
from zones.z07_data_access.tools.graph_subgraph import (
    execute as graph_subgraph_exec,
)
from zones.z07_data_access.tools.lincs_expression_detail import (
    TOOL_DEFINITION as lincs_expression_detail_def,
)
from zones.z07_data_access.tools.lincs_expression_detail import (
    execute as lincs_expression_detail_exec,
)
from zones.z07_data_access.tools.provenance_discovery import (
    TOOL_DEFINITION as provenance_discovery_def,
)
from zones.z07_data_access.tools.provenance_discovery import (
    execute as provenance_discovery_exec,
)
from zones.z07_data_access.tools.read_parquet_filter import (
    TOOL_DEFINITION as read_parquet_filter_def,
)
from zones.z07_data_access.tools.read_parquet_filter import (
    execute as read_parquet_filter_exec,
)
from zones.z07_data_access.tools.rescue_combinations import (
    TOOL_DEFINITION as rescue_combinations_def,
)
from zones.z07_data_access.tools.rescue_combinations import (
    execute as rescue_combinations_exec,
)
from zones.z07_data_access.tools.semantic_collections import (
    TOOL_DEFINITION as semantic_collections_def,
)
from zones.z07_data_access.tools.semantic_collections import (
    execute as semantic_collections_exec,
)
from zones.z07_data_access.tools.semantic_search import (
    TOOL_DEFINITION as semantic_search_def,
)
from zones.z07_data_access.tools.semantic_search import (
    execute as semantic_search_exec,
)

# Sapphire v3.3: Reporting & PostgreSQL Detail Tools
from zones.z07_data_access.tools.session_analytics import (
    TOOL_DEFINITION as session_analytics_def,
)
from zones.z07_data_access.tools.session_analytics import (
    execute as session_analytics_exec,
)

# Sapphire v3.2: Transcriptomic rescue scoring (Agent 12 validated)
from zones.z07_data_access.tools.transcriptomic_rescue import (
    TOOL_DEFINITION as transcriptomic_rescue_def,
)
from zones.z07_data_access.tools.transcriptomic_rescue import (
    execute as transcriptomic_rescue_exec,
)
from zones.z07_data_access.tools.vector_antipodal import (
    TOOL_DEFINITION as vector_antipodal_def,
)
from zones.z07_data_access.tools.vector_antipodal import (
    execute as vector_antipodal_exec,
)
from zones.z07_data_access.tools.vector_dimensions import (
    TOOL_DEFINITION as vector_dimensions_def,
)
from zones.z07_data_access.tools.vector_dimensions import (
    execute as vector_dimensions_exec,
)
from zones.z07_data_access.tools.vector_neighbors import (
    TOOL_DEFINITION as vector_neighbors_def,
)
from zones.z07_data_access.tools.vector_neighbors import (
    execute as vector_neighbors_exec,
)
from zones.z07_data_access.tools.vector_similarity import (
    TOOL_DEFINITION as vector_similarity_def,
)
from zones.z07_data_access.tools.vector_similarity import (
    execute as vector_similarity_exec,
)

# Sapphire v3.8: Service Integration Tools (3)
from zones.z07_data_access.tools.literature_search_agent import (
    TOOL_DEFINITION as literature_search_agent_def,
)
from zones.z07_data_access.tools.literature_search_agent import (
    execute as literature_search_agent_exec,
)
from zones.z07_data_access.tools.biomarker_discovery import (
    TOOL_DEFINITION as biomarker_discovery_def,
)
from zones.z07_data_access.tools.biomarker_discovery import (
    execute as biomarker_discovery_exec,
)
from zones.z07_data_access.tools.literature_evidence import (
    TOOL_DEFINITION as literature_evidence_def,
)
from zones.z07_data_access.tools.literature_evidence import (
    execute as literature_evidence_exec,
)

# Sapphire v3.12: CNS Safety Tools (2) - RE-ENABLED in v3.14
from zones.z07_data_access.tools.bbb_permeability import (
    TOOL_DEFINITION as bbb_permeability_def,
)
from zones.z07_data_access.tools.bbb_permeability import (
    execute as bbb_permeability_exec,
)
from zones.z07_data_access.tools.adme_tox_predictor import (
    TOOL_DEFINITION as adme_tox_predictor_def,
)
from zones.z07_data_access.tools.adme_tox_predictor import (
    execute as adme_tox_predictor_exec,
)

# Sapphire v3.13: Three-Tier Query Pathway System (3)
from zones.z07_data_access.tools.query_direct_run import (
    TOOL_DEFINITION as query_direct_run_def,
)
from zones.z07_data_access.tools.query_direct_run import (
    execute as query_direct_run_exec,
)
from zones.z07_data_access.tools.query_atomic_fusion import (
    TOOL_DEFINITION as query_atomic_fusion_def,
)
from zones.z07_data_access.tools.query_atomic_fusion import (
    execute as query_atomic_fusion_exec,
)
from zones.z07_data_access.tools.query_unified_orchestration import (
    TOOL_DEFINITION as query_unified_orchestration_def,
)
from zones.z07_data_access.tools.query_unified_orchestration import (
    execute as query_unified_orchestration_exec,
)

# Sapphire v3.14: Advanced Analytical Tools (3) - NEW
from zones.z07_data_access.tools.causal_inference import (
    TOOL_DEFINITION as causal_inference_def,
)
from zones.z07_data_access.tools.causal_inference import (
    execute as causal_inference_exec,
)
from zones.z07_data_access.tools.mechanistic_explainer import (
    TOOL_DEFINITION as mechanistic_explainer_def,
)
from zones.z07_data_access.tools.mechanistic_explainer import (
    execute as mechanistic_explainer_exec,
)
from zones.z07_data_access.tools.uncertainty_estimation import (
    TOOL_DEFINITION as uncertainty_estimation_def,
)
from zones.z07_data_access.tools.uncertainty_estimation import (
    execute as uncertainty_estimation_exec,
)

# Sapphire v3.15: Strategic Intelligence Tools (3)
from zones.z07_data_access.tools.clinical_trial_intelligence import (
    TOOL_DEFINITION as clinical_trial_intelligence_def,
)
from zones.z07_data_access.tools.clinical_trial_intelligence import (
    execute as clinical_trial_intelligence_exec,
)
from zones.z07_data_access.tools.target_validation_scorer import (
    TOOL_DEFINITION as target_validation_scorer_def,
)
from zones.z07_data_access.tools.target_validation_scorer import (
    execute as target_validation_scorer_exec,
)
from zones.z07_data_access.tools.drug_repurposing_ranker import (
    TOOL_DEFINITION as drug_repurposing_ranker_def,
)
from zones.z07_data_access.tools.drug_repurposing_ranker import (
    execute as drug_repurposing_ranker_exec,
)

# Sapphire v3.16: Scientist Reports (2) - NEW
from zones.z07_data_access.tools.scientist_reports import (
    TOOL_DEFINITION as scientist_report_def,
)
from zones.z07_data_access.tools.scientist_reports import (
    execute as scientist_report_exec,
)
from zones.z07_data_access.tools.scientist_reports import (
    BATCH_TOOL_DEFINITION as batch_scientist_reports_def,
)
from zones.z07_data_access.tools.scientist_reports import (
    execute_batch as batch_scientist_reports_exec,
)

# Sapphire v3.17: DeMeo v2.0 Drug Rescue (1) - NEW
from zones.z07_data_access.tools.demeo_drug_rescue import (
    TOOL_DEFINITION as demeo_drug_rescue_def,
)
from zones.z07_data_access.tools.demeo_drug_rescue import (
    execute as demeo_drug_rescue_exec,
)

# Sapphire v3.18: Intent Classifier (1) - NEW
from zones.z07_data_access.intent_classifier import (
    TOOL_DEFINITION as intent_classifier_def,
)
from zones.z07_data_access.intent_classifier import (
    execute as intent_classifier_exec,
)

# Sapphire v3.22: Fusion Discovery Tools (4) - NEW
from zones.z07_data_access.tools.fusion_discovery_drug import (
    TOOL_DEFINITION as fusion_discovery_drug_def,
)
from zones.z07_data_access.tools.fusion_discovery_drug import (
    execute as fusion_discovery_drug_exec,
)
from zones.z07_data_access.tools.fusion_discovery_gene import (
    TOOL_DEFINITION as fusion_discovery_gene_def,
)
from zones.z07_data_access.tools.fusion_discovery_gene import (
    execute as fusion_discovery_gene_exec,
)
from zones.z07_data_access.tools.entity_connection_tracker import (
    TOOL_DEFINITION as entity_connection_tracker_def,
)
from zones.z07_data_access.tools.entity_connection_tracker import (
    execute as entity_connection_tracker_exec,
)
from zones.z07_data_access.tools.signal_tracking_dashboard import (
    TOOL_DEFINITION as signal_tracking_dashboard_def,
)
from zones.z07_data_access.tools.signal_tracking_dashboard import (
    execute as signal_tracking_dashboard_exec,
)

# Sapphire v3.23: Atomic Fusion Table Wrappers (14) - NEW
# Drug Auxiliary Fusion (5)
from zones.z07_data_access.tools.query_drug_adr_similarity import (
    TOOL_DEFINITION as query_drug_adr_similarity_def,
)
from zones.z07_data_access.tools.query_drug_adr_similarity import (
    execute as query_drug_adr_similarity_exec,
)
from zones.z07_data_access.tools.query_drug_celltype_similarity import (
    TOOL_DEFINITION as query_drug_celltype_similarity_def,
)
from zones.z07_data_access.tools.query_drug_celltype_similarity import (
    execute as query_drug_celltype_similarity_exec,
)
from zones.z07_data_access.tools.query_drug_dgp_similarity import (
    TOOL_DEFINITION as query_drug_dgp_similarity_def,
)
from zones.z07_data_access.tools.query_drug_dgp_similarity import (
    execute as query_drug_dgp_similarity_exec,
)
from zones.z07_data_access.tools.query_drug_ep_similarity import (
    TOOL_DEFINITION as query_drug_ep_similarity_def,
)
from zones.z07_data_access.tools.query_drug_ep_similarity import (
    execute as query_drug_ep_similarity_exec,
)
from zones.z07_data_access.tools.query_drug_mop_similarity import (
    TOOL_DEFINITION as query_drug_mop_similarity_def,
)
from zones.z07_data_access.tools.query_drug_mop_similarity import (
    execute as query_drug_mop_similarity_exec,
)

# Gene Auxiliary Fusion (5)
from zones.z07_data_access.tools.query_gene_celltype_similarity import (
    TOOL_DEFINITION as query_gene_celltype_similarity_def,
)
from zones.z07_data_access.tools.query_gene_celltype_similarity import (
    execute as query_gene_celltype_similarity_exec,
)
from zones.z07_data_access.tools.query_gene_dgp_similarity import (
    TOOL_DEFINITION as query_gene_dgp_similarity_def,
)
from zones.z07_data_access.tools.query_gene_dgp_similarity import (
    execute as query_gene_dgp_similarity_exec,
)
from zones.z07_data_access.tools.query_gene_ep_similarity import (
    TOOL_DEFINITION as query_gene_ep_similarity_def,
)
from zones.z07_data_access.tools.query_gene_ep_similarity import (
    execute as query_gene_ep_similarity_exec,
)
from zones.z07_data_access.tools.query_gene_mop_similarity import (
    TOOL_DEFINITION as query_gene_mop_similarity_def,
)
from zones.z07_data_access.tools.query_gene_mop_similarity import (
    execute as query_gene_mop_similarity_exec,
)
from zones.z07_data_access.tools.query_gene_syndrome_similarity import (
    TOOL_DEFINITION as query_gene_syndrome_similarity_def,
)
from zones.z07_data_access.tools.query_gene_syndrome_similarity import (
    execute as query_gene_syndrome_similarity_exec,
)

# Cross-Modal Fusion (2)
from zones.z07_data_access.tools.query_drug_gene_similarity import (
    TOOL_DEFINITION as query_drug_gene_similarity_def,
)
from zones.z07_data_access.tools.query_drug_gene_similarity import (
    execute as query_drug_gene_similarity_exec,
)
from zones.z07_data_access.tools.query_drug_gene_ep_similarity import (
    TOOL_DEFINITION as query_drug_gene_ep_similarity_def,
)
from zones.z07_data_access.tools.query_drug_gene_ep_similarity import (
    execute as query_drug_gene_ep_similarity_exec,
)

# Same-Modal Fusion (2)
from zones.z07_data_access.tools.query_drug_drug_similarity import (
    TOOL_DEFINITION as query_drug_drug_similarity_def,
)
from zones.z07_data_access.tools.query_drug_drug_similarity import (
    execute as query_drug_drug_similarity_exec,
)
from zones.z07_data_access.tools.query_gene_gene_similarity import (
    TOOL_DEFINITION as query_gene_gene_similarity_def,
)
from zones.z07_data_access.tools.query_gene_gene_similarity import (
    execute as query_gene_gene_similarity_exec,
)

load_dotenv()

# Load Sapphire Scientist skill for world-class scientific reasoning
try:
    from sapphire_scientist.chainlit_integration import load_sapphire_scientist

    print("\n" + "=" * 80)
    print("LOADING SAPPHIRE SCIENTIST SKILL")
    print("=" * 80)

    sapphire_scientist = load_sapphire_scientist()
    print(sapphire_scientist.get_context_summary())
    print("=" * 80 + "\n")

    # Get the enhanced system prompt with all metagraph knowledge
    SCIENTIST_SYSTEM_PROMPT = sapphire_scientist.get_system_prompt()
    SAPPHIRE_SCIENTIST_ENABLED = True

except Exception as e:
    print(f"\n⚠️  Sapphire Scientist skill failed to load: {e}")
    print("Continuing with standard Sapphire system prompt...\n")
    SAPPHIRE_SCIENTIST_ENABLED = False
    SCIENTIST_SYSTEM_PROMPT = None

# Override ChromaDB port - external port for literature-chromadb container
# Shell environment may have wrong port (8000), correct external port is 8004
os.environ["CHROMADB_HOST"] = os.getenv("CHROMADB_HOST", "localhost")
os.environ["CHROMADB_PORT"] = "8004"  # Force correct external port

# Startup validation - validate Neo4j and embedding configuration
from zones.z07_data_access.config_validator import (
    ConfigValidator,
)

print("\n" + "=" * 80)
print("SAPPHIRE V3 STARTUP VALIDATION")
print("=" * 80)

# Validate Neo4j connection
neo4j_uri = os.getenv("NEO4J_URI", "bolt://localhost:7687")
neo4j_user = os.getenv("NEO4J_USER", "neo4j")
neo4j_password = os.getenv("NEO4J_PASSWORD")

neo4j_connected, neo4j_error = ConfigValidator.validate_neo4j_connection(
    neo4j_uri, neo4j_user, neo4j_password
)

if neo4j_connected:
    print(f"✅ Neo4j connected: {neo4j_uri}")
else:
    print("❌ Neo4j connection failed:")
    print(f"   {neo4j_error}")
    print("   ⚠️  Sapphire will fall back to file-based embeddings")

# Validate embedding spaces
space_status = ConfigValidator.validate_embedding_spaces()
loadable_count = sum(1 for s in space_status.values() if s["loadable"])
total_count = len(space_status)

print(f"✅ Embedding spaces: {loadable_count}/{total_count} loadable")

if loadable_count < total_count:
    unloadable = [
        name for name, status in space_status.items() if not status["loadable"]
    ]
    print(f"   ⚠️  Unloadable: {', '.join(unloadable)}")

print("=" * 80 + "\n")


# Custom JSON encoder to handle Neo4j DateTime and other special types
class Neo4jJSONEncoder(json.JSONEncoder):
    """Custom JSON encoder that handles Neo4j temporal types and other special objects."""

    def default(self, obj):
        # Handle Neo4j DateTime, Date, Time types
        if hasattr(obj, "iso_format"):
            return obj.iso_format()
        # Handle Python datetime
        if isinstance(obj, datetime):
            return obj.isoformat()
        # Handle sets
        if isinstance(obj, set):
            return list(obj)
        # Handle bytes
        if isinstance(obj, bytes):
            return obj.decode("utf-8", errors="replace")
        # Default behavior
        return super().default(obj)


# JSON-based conversation persistence (for 20-50 conversations/day)
SESSION_STORAGE_PATH = Path(__file__).parent / "data" / "sessions"
SESSION_STORAGE_PATH.mkdir(parents=True, exist_ok=True)


def save_conversation_to_json(
    session_id: str, conversation_data: dict[str, Any]
) -> None:
    """Save conversation to JSON file."""
    try:
        session_file = SESSION_STORAGE_PATH / f"session_{session_id}.json"
        with open(session_file, "w") as f:
            json.dump(conversation_data, f, indent=2, cls=Neo4jJSONEncoder)
        print(f"✅ Conversation saved to {session_file}")
    except Exception as e:
        print(f"⚠️  Failed to save conversation: {e}")


def load_conversation_from_json(session_id: str) -> Optional[dict[str, Any]]:
    """Load conversation from JSON file."""
    try:
        session_file = SESSION_STORAGE_PATH / f"session_{session_id}.json"
        if session_file.exists():
            with open(session_file) as f:
                return json.load(f)
    except Exception as e:
        print(f"⚠️  Failed to load conversation: {e}")
    return None


# Tool registry: Maps tool names to (definition, executor)
TOOL_REGISTRY = {
    # Vector tools (5)
    "vector_antipodal": (vector_antipodal_def, vector_antipodal_exec),
    "vector_neighbors": (vector_neighbors_def, vector_neighbors_exec),
    "provenance_discovery": (provenance_discovery_def, provenance_discovery_exec),
    "vector_similarity": (vector_similarity_def, vector_similarity_exec),
    "vector_dimensions": (vector_dimensions_def, vector_dimensions_exec),
    # Graph tools (4)
    "graph_neighbors": (graph_neighbors_def, graph_neighbors_exec),
    "graph_path": (graph_path_def, graph_path_exec),
    "graph_subgraph": (graph_subgraph_def, graph_subgraph_exec),
    "graph_properties": (graph_properties_def, graph_properties_exec),
    # Semantic tools (2)
    "semantic_search": (semantic_search_def, semantic_search_exec),
    "semantic_collections": (semantic_collections_def, semantic_collections_exec),
    # Utility tools (5)
    "entity_metadata": (entity_metadata_def, entity_metadata_exec),
    "count_entities": (count_entities_def, count_entities_exec),
    "available_spaces": (available_spaces_def, available_spaces_exec),
    "execute_cypher": (execute_cypher_def, execute_cypher_exec),
    "read_parquet_filter": (read_parquet_filter_def, read_parquet_filter_exec),
    # Sapphire v3.1: Drug combination tools (4)
    "drug_interactions": (drug_interactions_def, drug_interactions_exec),
    "drug_lookalikes": (drug_lookalikes_def, drug_lookalikes_exec),
    "drug_combinations_synergy": (
        drug_combinations_synergy_def,
        drug_combinations_synergy_exec,
    ),
    "rescue_combinations": (rescue_combinations_def, rescue_combinations_exec),
    # Sapphire v3.2: Transcriptomic rescue scoring (1)
    "transcriptomic_rescue": (transcriptomic_rescue_def, transcriptomic_rescue_exec),
    # Sapphire v3.3: Reporting & PostgreSQL Detail Tools (3)
    "session_analytics": (session_analytics_def, session_analytics_exec),
    "drug_properties_detail": (drug_properties_detail_def, drug_properties_detail_exec),
    "lincs_expression_detail": (
        lincs_expression_detail_def,
        lincs_expression_detail_exec,
    ),
    # Sapphire v3.8: Service Integration Tools (3)
    "literature_search_agent": (literature_search_agent_def, literature_search_agent_exec),
    "biomarker_discovery": (biomarker_discovery_def, biomarker_discovery_exec),
    "literature_evidence": (literature_evidence_def, literature_evidence_exec),
    # Sapphire v3.12: CNS Safety Tools (2) - RE-ENABLED in v3.14
    # TEMPORARILY DISABLED: Recursion bug causes system lockup (2025-12-15)
    # TODO: Fix recursion depth issue in bbb_permeability tool
    # See: .outcomes/SAPPHIRE_V323_BAYESIAN_TOOLS_BUG_2025-12-15.md
    # "bbb_permeability": (bbb_permeability_def, bbb_permeability_exec),
    "adme_tox_predictor": (adme_tox_predictor_def, adme_tox_predictor_exec),
    # Sapphire v3.13: Three-Tier Query Pathway System (3)
    "query_direct_run": (query_direct_run_def, query_direct_run_exec),
    "query_atomic_fusion": (query_atomic_fusion_def, query_atomic_fusion_exec),
    "query_unified_orchestration": (query_unified_orchestration_def, query_unified_orchestration_exec),
    # Sapphire v3.14: Advanced Analytical Tools (3)
    "causal_inference": (causal_inference_def, causal_inference_exec),
    # TEMPORARILY DISABLED: Recursion bug causes system lockup (2025-12-15)
    # TODO: Fix recursion depth issue in mechanistic_explainer tool
    # See: .outcomes/SAPPHIRE_V323_BAYESIAN_TOOLS_BUG_2025-12-15.md
    # "mechanistic_explainer": (mechanistic_explainer_def, mechanistic_explainer_exec),
    "uncertainty_estimation": (uncertainty_estimation_def, uncertainty_estimation_exec),
    # Sapphire v3.15: Strategic Intelligence Tools (3) - NEW
    "clinical_trial_intelligence": (clinical_trial_intelligence_def, clinical_trial_intelligence_exec),
    "target_validation_scorer": (target_validation_scorer_def, target_validation_scorer_exec),
    "drug_repurposing_ranker": (drug_repurposing_ranker_def, drug_repurposing_ranker_exec),
    # Sapphire v3.16: Scientist Reports (2)
    "generate_scientist_report": (scientist_report_def, scientist_report_exec),
    "generate_all_scientist_reports": (batch_scientist_reports_def, batch_scientist_reports_exec),
    # Sapphire v3.17: DeMeo v2.0 Drug Rescue (1) - NEW
    "demeo_drug_rescue": (demeo_drug_rescue_def, demeo_drug_rescue_exec),
    # Sapphire v3.18: Intent Classifier (1) - NEW
    "classify_intent": (intent_classifier_def, intent_classifier_exec),
    # Sapphire v3.22: Fusion Discovery Tools (4) - NEW
    "fusion_discovery_drug": (fusion_discovery_drug_def, fusion_discovery_drug_exec),
    "fusion_discovery_gene": (fusion_discovery_gene_def, fusion_discovery_gene_exec),
    "entity_connection_tracker": (entity_connection_tracker_def, entity_connection_tracker_exec),
    "signal_tracking_dashboard": (signal_tracking_dashboard_def, signal_tracking_dashboard_exec),
    # Sapphire v3.23: Atomic Fusion Table Wrappers (14) - NEW
    # Drug Auxiliary Fusion (5)
    "query_drug_adr_similarity": (query_drug_adr_similarity_def, query_drug_adr_similarity_exec),
    "query_drug_celltype_similarity": (query_drug_celltype_similarity_def, query_drug_celltype_similarity_exec),
    "query_drug_dgp_similarity": (query_drug_dgp_similarity_def, query_drug_dgp_similarity_exec),
    "query_drug_ep_similarity": (query_drug_ep_similarity_def, query_drug_ep_similarity_exec),
    "query_drug_mop_similarity": (query_drug_mop_similarity_def, query_drug_mop_similarity_exec),
    # Gene Auxiliary Fusion (5)
    "query_gene_celltype_similarity": (query_gene_celltype_similarity_def, query_gene_celltype_similarity_exec),
    "query_gene_dgp_similarity": (query_gene_dgp_similarity_def, query_gene_dgp_similarity_exec),
    "query_gene_ep_similarity": (query_gene_ep_similarity_def, query_gene_ep_similarity_exec),
    "query_gene_mop_similarity": (query_gene_mop_similarity_def, query_gene_mop_similarity_exec),
    "query_gene_syndrome_similarity": (query_gene_syndrome_similarity_def, query_gene_syndrome_similarity_exec),
    # Cross-Modal Fusion (2)
    "query_drug_gene_similarity": (query_drug_gene_similarity_def, query_drug_gene_similarity_exec),
    "query_drug_gene_ep_similarity": (query_drug_gene_ep_similarity_def, query_drug_gene_ep_similarity_exec),
    # Same-Modal Fusion (2)
    "query_drug_drug_similarity": (query_drug_drug_similarity_def, query_drug_drug_similarity_exec),
    "query_gene_gene_similarity": (query_gene_gene_similarity_def, query_gene_gene_similarity_exec),
}

# Base Sapphire system prompt (used if Sapphire Scientist skill not available)
BASE_SAPPHIRE_PROMPT = """You are Sapphire v3.23, an AI assistant for drug discovery with 60 atomic tools including 14 fusion primitives for composable multi-hop reasoning.

**📊 Unified Reporting System:**
🌐 http://100.84.49.12:8082 - Access all reports and analytics
- Scientist Reports: Disease-specific drug discovery reports (Epilepsy, ALS, Parkinson's, Alzheimer's, Pain, GLP-1, TSC2)
- Batch Analytics: Cross-disease comparative analysis
- Session Analytics: Query history and discovery tracking
- Drug Discovery: Comprehensive literature and safety assessments

**🗄️ Data Access:**
- 18,368 genes | 14,246 FDA drugs | 1.3M Neo4j nodes | 29,863 CNS papers
- 154 embedding spaces | BBB permeability | ADME/Tox safety profiles

**🎯 Query Pathways (Choose Based on Complexity):**

1. **query_direct_run** ⚡ (<100ms) - Simple queries ("drugs similar to gabapentin")
2. **query_atomic_fusion** 🎯 (200-500ms) - User-controlled fusion across multiple embedding spaces
3. **query_unified_orchestration** 🤖 (400-2000ms) - Complex multi-step reasoning with execution plans

**🧠 NEW: Intent Classification:**
Use **classify_intent** to automatically detect query intent and get optimal pathway recommendations before executing queries. This helps you choose the best execution strategy.

**🛠️ Tool Categories (60 tools):**

**Vector (5)**: vector_antipodal, vector_neighbors, provenance_discovery, vector_similarity, vector_dimensions
**Graph (4)**: graph_neighbors, graph_path, graph_subgraph, graph_properties
**Semantic (2)**: semantic_search, semantic_collections
**Reporting (5)**: session_analytics, drug_properties_detail, lincs_expression_detail, generate_scientist_report, generate_all_scientist_reports
**Drug Combos (4)**: drug_interactions, drug_lookalikes, drug_combinations_synergy, rescue_combinations
**CNS Safety (2)**: bbb_permeability, adme_tox_predictor
**Transcriptomic (1)**: transcriptomic_rescue
**DeMeo v2.0 (1)**: demeo_drug_rescue ⭐ World-class multi-modal Bayesian fusion with metagraph caching
**Intent Classification (1)**: classify_intent
**Fusion Discovery (4)**: fusion_discovery_drug, fusion_discovery_gene, entity_connection_tracker, signal_tracking_dashboard
**Atomic Fusion Primitives (14)**: ⭐ NEW - Composable multi-hop reasoning across all 14 fusion tables
  - Drug Auxiliary (5): query_drug_adr_similarity, query_drug_celltype_similarity, query_drug_dgp_similarity, query_drug_ep_similarity, query_drug_mop_similarity
  - Gene Auxiliary (5): query_gene_celltype_similarity, query_gene_dgp_similarity, query_gene_ep_similarity, query_gene_mop_similarity, query_gene_syndrome_similarity
  - Cross-Modal (2): query_drug_gene_similarity, query_drug_gene_ep_similarity
  - Same-Modal (2): query_drug_drug_similarity, query_gene_gene_similarity
**Literature (3)**: literature_search_agent, biomarker_discovery, literature_evidence
**Utilities (5)**: entity_metadata, count_entities, available_spaces, execute_cypher, read_parquet_filter
**Advanced Analytics (3)**: causal_inference, mechanistic_explainer, uncertainty_estimation
**Strategic Intel (3)**: clinical_trial_intelligence, target_validation_scorer, drug_repurposing_ranker

**📝 Quick Examples:**

1. **Atomic Fusion (NEW):** "What drugs have similar ADR to aspirin?" → query_drug_adr_similarity
2. **Rare Disease (NEW):** "Genes causing Dravet-like syndromes?" → query_gene_syndrome_similarity
3. **Drug Targeting (NEW):** "What genes does valproate affect?" → query_drug_gene_similarity
4. **Multi-Hop Reasoning (NEW):** query_gene_syndrome_similarity → query_gene_dgp_similarity → query_drug_gene_similarity (composable chains!)
5. **Drug Discovery (DeMeo):** "What drugs rescue SCN1A for Dravet?" → demeo_drug_rescue
6. **Disease Report:** "Generate epilepsy scientist report" → generate_scientist_report
7. **Safety Check:** "Is valproic acid BBB+?" → bbb_permeability + adme_tox_predictor
8. **Session History:** "What did I discover last week?" → session_analytics

**💡 Best Practices:**
- Use classify_intent first for complex queries to determine optimal pathway
- Start with pathway tools (direct_run/atomic_fusion/unified_orchestration) for integrated intelligence
- Use generate_scientist_report for comprehensive disease analysis
- Combine multiple tools for complex workflows (e.g., vector_antipodal + bbb_permeability + literature_search_agent)
- Check unified reporting system for pre-generated insights: http://100.84.49.12:8082

Be concise, cite sources, format with markdown, and provide actionable insights.
"""

# Use Sapphire Scientist enhanced prompt if available, otherwise fall back to base prompt
if SAPPHIRE_SCIENTIST_ENABLED and SCIENTIST_SYSTEM_PROMPT:
    # Append Sapphire v3.13 tool context to Sapphire Scientist prompt
    SAPPHIRE_V3_TOOLS_CONTEXT = """

## SAPPHIRE V3.16 TOOLS & REPORTING INTEGRATION

**📊 Unified Reporting System:**
🌐 http://100.84.49.12:8082 - Pre-generated insights and analytics dashboard

**🛠️ 42 Sapphire Tools Available:**
Query Pathways (3) | Vector (5) | Graph (4) | Semantic (2) | Reporting (5)
Drug Combos (4) | CNS Safety (2) | Transcriptomic (1) | DeMeo (1) | Intent (1)
Literature (3) | Utilities (5) | Advanced Analytics (3) | Strategic Intel (3)

**🗄️ Data Access:**
18,368 genes | 14,246 drugs | 1.3M Neo4j nodes | 29,863 CNS papers | 154 embedding spaces

**🎯 Integration Strategy:**
1. Use your metagraph knowledge for confidence scoring and pattern recognition
2. Leverage Sapphire tools for real-time database queries
3. Check unified reporting system for pre-generated disease insights
4. Combine metagraph patterns + tool results for world-class recommendations

**Example Workflow:**
"What treats STXBP1?" → Your metagraph: 99.61% similar to SCN1A → vector_antipodal for candidates → bbb_permeability for safety → Synthesize with your confidence formula

Leverage your scientific reasoning with Sapphire's comprehensive data access.
"""
    SYSTEM_PROMPT = SCIENTIST_SYSTEM_PROMPT + SAPPHIRE_V3_TOOLS_CONTEXT
    print("✅ Using Sapphire Scientist enhanced system prompt with metagraph knowledge")
else:
    SYSTEM_PROMPT = BASE_SAPPHIRE_PROMPT
    print("✅ Using base Sapphire system prompt")


async def execute_tool(tool_name: str, tool_input: dict[str, Any]) -> dict[str, Any]:
    """Execute a tool by name with given input."""
    import time
    import asyncio

    metrics = get_metrics()
    start_time = time.time()

    if tool_name not in TOOL_REGISTRY:
        duration_ms = (time.time() - start_time) * 1000
        metrics.track_tool_call(tool_name, duration_ms, success=False, error_type="unknown_tool")
        return {
            "success": False,
            "error": f"Unknown tool: {tool_name}",
            "available_tools": list(TOOL_REGISTRY.keys()),
        }

    try:
        _, executor = TOOL_REGISTRY[tool_name]

        # Add timeout to prevent tools from hanging indefinitely
        # Default: 45 seconds - balance between slow operations and UX
        # Can be overridden per-tool if needed
        # demeo_drug_rescue gets 120s due to Bayesian fusion complexity
        TOOL_TIMEOUT = 120.0 if tool_name == "demeo_drug_rescue" else 45.0

        try:
            result = await asyncio.wait_for(executor(tool_input), timeout=TOOL_TIMEOUT)
        except asyncio.TimeoutError:
            duration_ms = (time.time() - start_time) * 1000
            metrics.track_tool_call(tool_name, duration_ms, success=False, error_type="timeout")
            print(f"⏱️  Tool execution timeout in {tool_name} after {TOOL_TIMEOUT}s")
            return {
                "success": False,
                "error": f"Tool execution timed out after {TOOL_TIMEOUT} seconds",
                "tool_name": tool_name,
                "error_type": "timeout",
                "timeout_seconds": TOOL_TIMEOUT
            }

        # Track successful execution
        duration_ms = (time.time() - start_time) * 1000
        success = result.get("success", True)
        error_type = result.get("error_type") if not success else None
        metrics.track_tool_call(tool_name, duration_ms, success=success, error_type=error_type)

        return result
    except Exception as e:
        # Catch any unhandled exceptions in tools
        duration_ms = (time.time() - start_time) * 1000
        metrics.track_tool_call(tool_name, duration_ms, success=False, error_type=type(e).__name__)

        print(f"❌ Tool execution exception in {tool_name}: {e}")
        import traceback

        traceback.print_exc()
        return {
            "success": False,
            "error": f"Tool execution failed: {e!s}",
            "tool_name": tool_name,
            "error_type": type(e).__name__,
        }


async def execute_tools_parallel(
    tool_calls: list[dict[str, Any]], show_thinking: bool = False
) -> list[dict[str, Any]]:
    """
    Execute multiple tools in parallel using asyncio.gather()

    Args:
        tool_calls: List of {tool_name, tool_input, tool_use_id}
        show_thinking: Whether to show tool execution in UI

    Returns:
        List of tool results in same order as input
    """

    async def execute_single_tool(tool_call):
        tool_name = tool_call["tool_name"]
        tool_input = tool_call["tool_input"]
        tool_use_id = tool_call["tool_use_id"]

        if show_thinking:
            await cl.Message(
                content=f"🔧 **{tool_name}** starting...", author="System"
            ).send()

        # Execute tool
        result = await execute_tool(tool_name, tool_input)

        if show_thinking:
            status = "✅" if result.get("success") else "❌"
            count_info = f" ({result['count']} results)" if "count" in result else ""
            error_info = (
                f": {result.get('error', 'Unknown error')}"
                if not result.get("success")
                else ""
            )
            await cl.Message(
                content=f"{status} **{tool_name}** complete{count_info}{error_info}",
                author="System",
            ).send()

        return {"tool_use_id": tool_use_id, "tool_name": tool_name, "result": result}

    # Execute all tools in parallel
    results = await asyncio.gather(*[execute_single_tool(tc) for tc in tool_calls])
    return results


async def compress_tool_result(result: dict, tool_name: str) -> str:
    """
    Compress large tool results to prevent API timeouts.
    Uses intelligent truncation with summary preservation.
    """
    result_json = json.dumps(result, cls=Neo4jJSONEncoder)

    # If result is reasonable size, return as-is
    if len(result_json) <= 5000:
        return result_json

    # For large results, create a compressed version
    print(f"🗜️ Compressing {tool_name} result: {len(result_json)} chars")

    # Try to preserve key fields and truncate large arrays
    compressed_result = result.copy()

    # Common patterns to compress
    for key in ['results', 'drugs', 'genes', 'candidates', 'data', 'rows']:
        if key in compressed_result and isinstance(compressed_result[key], list):
            original_len = len(compressed_result[key])
            if original_len > 10:
                # Keep first 10 items and add summary
                compressed_result[key] = compressed_result[key][:10]
                compressed_result[f'{key}_truncated'] = f"Showing 10 of {original_len} items"
                print(f"   Truncated {key}: {original_len} → 10 items")

    # Re-serialize
    compressed_json = json.dumps(compressed_result, cls=Neo4jJSONEncoder)

    # If still too large, do hard truncation
    if len(compressed_json) > 10000:
        compressed_json = compressed_json[:10000] + f'\n... [TRUNCATED: {len(result_json) - 10000} chars omitted]'
        print(f"   Hard truncated: {len(result_json)} → 10000 chars")

    reduction = 100 - int(100 * len(compressed_json) / len(result_json))
    print(f"   Final size: {len(result_json)} → {len(compressed_json)} chars ({reduction}% reduction)")

    return compressed_json


async def run_pure_agentic_query(
    query: str,
    conversation_history: list[dict[str, Any]] = None,
    show_thinking: bool = True,
) -> dict[str, Any]:
    """
    Run a query using pure agentic orchestration with Chainlit UI feedback.

    Args:
        query: User query
        conversation_history: Previous messages (for context)
        show_thinking: Show tool calls in UI

    Returns:
        Dict with final_answer, tool_calls, reasoning
    """
    # Get API key
    api_key = os.getenv("ANTHROPIC_API_KEY")
    if not api_key:
        return {
            "success": False,
            "error": "ANTHROPIC_API_KEY not set",
            "final_answer": "Error: API key not configured",
        }

    # Use LiteLLM-Anthropic bridge for compression + cost tracking
    client = get_litellm_client(api_key=api_key, enable_compression=True)

    # Prepare tool definitions for Claude
    tools = [tool_def for tool_def, _ in TOOL_REGISTRY.values()]

    # Build conversation messages (include history if provided)
    messages = []
    if conversation_history:
        messages.extend(conversation_history)
    messages.append({"role": "user", "content": query})

    tool_calls_log = []

    # Allow up to 10 turns for multi-tool orchestration (doubled from 5 for complex queries)
    for turn in range(10):
        # Call Claude with tools
        try:
            response = client.messages.create(
                model="claude-sonnet-4-5-20250929",
                max_tokens=64000,  # Max output tokens for Claude Sonnet 4.5
                system=SYSTEM_PROMPT,
                messages=messages,
                tools=tools,
            )
        except Exception as e:
            return {
                "success": False,
                "error": f"API call failed: {e!s}",
                "final_answer": f"Error calling Claude API: {e!s}",
            }

        # Check if Claude wants to use tools
        if response.stop_reason == "end_turn":
            # Claude finished without using tools (just text response)
            final_answer = ""
            for block in response.content:
                if block.type == "text":
                    final_answer += block.text

            return {
                "success": True,
                "final_answer": final_answer,
                "tool_calls": tool_calls_log,
                "turns": turn + 1,
            }

        elif response.stop_reason == "tool_use":
            # Claude wants to use tools
            assistant_message_content = []
            tool_results_content = []

            for block in response.content:
                assistant_message_content.append(block)

                if block.type == "tool_use":
                    tool_name = block.name
                    tool_input = block.input
                    tool_use_id = block.id

                    # Show tool call in UI if enabled
                    if show_thinking:
                        await cl.Message(
                            content=f"🔧 **Using tool**: `{tool_name}`\n```json\n{json.dumps(tool_input, indent=2)}\n```",
                            author="System",
                        ).send()

                    # Execute tool
                    result = await execute_tool(tool_name, tool_input)

                    # Show result summary in UI
                    if show_thinking:
                        if result.get("success"):
                            summary = "✅ Tool succeeded"
                            if "count" in result:
                                summary += f" ({result['count']} results)"
                        else:
                            summary = f"❌ Tool failed: {result.get('error', 'Unknown error')}"

                        await cl.Message(content=summary, author="System").send()

                    # Log tool call
                    tool_calls_log.append(
                        {"tool": tool_name, "input": tool_input, "result": result}
                    )

                    # Add tool result to conversation (compress large responses)
                    result_json = await compress_tool_result(result, tool_name)

                    tool_results_content.append(
                        {
                            "type": "tool_result",
                            "tool_use_id": tool_use_id,
                            "content": result_json,
                        }
                    )

            # Add assistant message and tool results to conversation
            messages.append({"role": "assistant", "content": assistant_message_content})
            messages.append({"role": "user", "content": tool_results_content})

        else:
            # Unexpected stop reason
            return {
                "success": False,
                "error": f"Unexpected stop reason: {response.stop_reason}",
                "final_answer": "Error: Unexpected response from Claude",
                "tool_calls": tool_calls_log,
                "turns": turn + 1,
            }

    # Exceeded max turns
    return {
        "success": False,
        "error": "Exceeded maximum turns (10)",
        "final_answer": "Query too complex - exceeded maximum tool orchestration depth",
        "tool_calls": tool_calls_log,
        "turns": 10,
    }


async def orchestrate_with_streaming(
    query: str,
    conversation_history: list[dict[str, Any]] = None,
    show_thinking: bool = True,
    max_turns: int = 10,  # Doubled from 5 for complex multi-tool queries
) -> dict[str, Any]:
    """
    Enhanced orchestration with streaming and parallel tool execution

    Key improvements:
    1. Uses client.messages.stream() for progressive responses
    2. Executes multiple tools in parallel via asyncio.gather()
    3. Streams partial text to UI as it's generated
    4. Handles tool_use blocks properly in streaming mode

    Args:
        query: User's question
        conversation_history: Previous messages (optional)
        show_thinking: Show intermediate steps
        max_turns: Max orchestration rounds

    Returns:
        Dict with success, final_answer, tool_calls, turns
    """
    # Get API key
    api_key = os.getenv("ANTHROPIC_API_KEY")
    if not api_key:
        return {
            "success": False,
            "error": "ANTHROPIC_API_KEY not set",
            "final_answer": "Error: API key not configured",
        }

    # Use LiteLLM-Anthropic bridge for compression + cost tracking
    client = get_litellm_client(api_key=api_key, enable_compression=True)

    # Prepare tool definitions for Claude
    tools = [tool_def for tool_def, _ in TOOL_REGISTRY.values()]

    # Build messages
    messages = []
    if conversation_history:
        messages.extend(conversation_history)
    messages.append({"role": "user", "content": query})

    tool_calls_log = []
    response_message = await cl.Message(content="").send()
    accumulated_text = ""

    for turn in range(max_turns):
        try:
            # Use streaming API
            # Note: Watchdog provides timeout protection at process level
            with (
                client.messages.stream(
                    model="claude-sonnet-4-5-20250929",
                    max_tokens=64000,  # Max output tokens for Claude Sonnet 4.5
                    system=SYSTEM_PROMPT,
                    messages=messages,
                    tools=tools,
                ) as stream
            ):
                # Collect tool uses and text as they stream
                tool_uses = []
                assistant_content = []
                current_text = ""

                for event in stream:
                    # Handle different event types
                    if event.type == "content_block_start":
                        # Just track that a block started, don't collect yet
                        pass

                    elif event.type == "content_block_delta":
                        if event.delta.type == "text_delta":
                            # Stream text to UI
                            chunk = event.delta.text
                            current_text += chunk
                            accumulated_text += chunk
                            await response_message.stream_token(chunk)

                        elif event.delta.type == "input_json_delta":
                            # Accumulate tool input JSON
                            # Note: We'll get the complete input in message_stop
                            pass

                    elif event.type == "content_block_stop":
                        # Block finished
                        pass

                    elif event.type == "message_stop":
                        # Message complete - get final message
                        final_message = stream.get_final_message()

                        # Extract complete tool uses
                        for block in final_message.content:
                            assistant_content.append(block)
                            if block.type == "tool_use":
                                tool_uses.append(
                                    {
                                        "id": block.id,
                                        "name": block.name,
                                        "input": block.input,
                                    }
                                )

                # Update UI with accumulated text
                await response_message.update()

                # Get stop reason
                final_message = stream.get_final_message()
                stop_reason = final_message.stop_reason

                # Handle based on stop reason
                if stop_reason == "end_turn":
                    # No tools needed - we're done!
                    return {
                        "success": True,
                        "final_answer": accumulated_text,
                        "tool_calls": tool_calls_log,
                        "turns": turn + 1,
                    }

                elif stop_reason == "tool_use":
                    # Execute tools IN PARALLEL
                    tool_calls = [
                        {
                            "tool_name": tu["name"],
                            "tool_input": tu["input"],
                            "tool_use_id": tu["id"],
                        }
                        for tu in tool_uses
                        if "name" in tu and "input" in tu  # Filter complete tool uses
                    ]

                    if not tool_calls:
                        # No valid tool calls
                        continue

                    # PARALLEL EXECUTION
                    tool_results = await execute_tools_parallel(
                        tool_calls, show_thinking
                    )

                    # Check for adaptive cards in tool results
                    for tr in tool_results:
                        result = tr.get("result", {})
                        if result.get("requires_user_input") and result.get("adaptive_card"):
                            # Render adaptive card
                            await render_adaptive_card(
                                result["adaptive_card"],
                                tr["tool_name"]
                            )

                    # Log tool calls
                    tool_calls_log.extend(
                        [
                            {
                                "tool": tr["tool_name"],
                                "input": next(
                                    tc["tool_input"]
                                    for tc in tool_calls
                                    if tc["tool_use_id"] == tr["tool_use_id"]
                                ),
                                "result": tr["result"],
                            }
                            for tr in tool_results
                        ]
                    )

                    # Add assistant message to conversation
                    messages.append({"role": "assistant", "content": assistant_content})

                    # Add tool results to conversation (compress large responses)
                    compressed_tool_results = []
                    for tr in tool_results:
                        result_json = await compress_tool_result(tr["result"], tr["tool_name"])
                        compressed_tool_results.append({
                            "type": "tool_result",
                            "tool_use_id": tr["tool_use_id"],
                            "content": result_json,
                        })

                    messages.append({
                        "role": "user",
                        "content": compressed_tool_results,
                    })

                    # Continue to next turn (Claude will see tool results)
                    response_message = await cl.Message(content="").send()
                    accumulated_text = ""
                    continue

                else:
                    # Other stop reasons
                    return {
                        "success": True,
                        "final_answer": accumulated_text,
                        "tool_calls": tool_calls_log,
                        "turns": turn + 1,
                    }

        except Exception as e:
            return {
                "success": False,
                "error": f"Streaming error: {e!s}",
                "final_answer": f"Error: {e!s}",
            }

    # Max turns reached
    return {
        "success": True,
        "final_answer": accumulated_text or "Maximum orchestration turns reached.",
        "tool_calls": tool_calls_log,
        "turns": max_turns,
    }


@cl.on_chat_start
async def on_chat_start():
    """Initialize session when user starts chat."""
    # Generate unique session ID
    session_id = str(uuid.uuid4())
    session_start = datetime.now().isoformat()

    # Get reports base URL from environment or use default
    # For proxy access, set REPORTS_BASE_URL=http://your-proxy-server:8082
    reports_base_url = os.getenv("REPORTS_BASE_URL", "http://localhost:8082")

    # Build concise welcome message
    if SAPPHIRE_SCIENTIST_ENABLED:
        welcome_header = f"""# Welcome to Sapphire v3.23 + Scientist 🧬
**World-class computational biologist with metagraph knowledge + 60 atomic tools + 14 fusion primitives**"""
    else:
        welcome_header = f"""# Welcome to Sapphire v3.23 🚀
**AI assistant for drug discovery with 60 atomic tools + 14 fusion primitives for composable multi-hop reasoning**"""

    # Welcome message
    await cl.Message(
        content=welcome_header + f"""

## 📊 Unified Reporting System
🌐 **[Access All Reports & Analytics](http://100.84.49.12:8082)**

Pre-generated disease reports ready to view:
- **Epilepsy** | **ALS** | **Parkinson's** | **Alzheimer's** | **Chronic Pain** | **GLP-1** | **TSC2**

Or ask me: *"Generate TSC2 scientist report"*

---

## 🗄️ Data Access
18,368 genes | 14,246 drugs | 1.3M Neo4j nodes | 29,863 papers | 154 embedding spaces

## 🎯 Query Pathways (3)
1. **query_direct_run** ⚡ (<100ms) - Fast similarity queries
2. **query_atomic_fusion** 🎯 (200-500ms) - User-controlled multi-source fusion
3. **query_unified_orchestration** 🤖 (400-2000ms) - Full intelligence with plan confirmation

## 🛠️ Tool Categories (60 tools)
Vector (5) | Graph (4) | Semantic (2) | Reporting (5) | Drug Combos (4)
CNS Safety (2) | Transcriptomic (1) | DeMeo (1) | Intent (1) | Fusion Discovery (4)
**Atomic Fusion Primitives (14)** ⭐ NEW - Composable multi-hop reasoning!
Literature (3) | Utilities (5) | Advanced Analytics (3) | Strategic Intel (3)

## 📝 Quick Examples

**Drug Discovery:**
- "What drugs rescue SCN1A?" → vector_antipodal + bbb_permeability
- "Find drug combinations for STXBP1" → rescue_combinations + drug_interactions

**Reports & Analytics:**
- "Generate epilepsy scientist report" → Comprehensive disease analysis
- "Show my query history from last week" → session_analytics

**Literature & Safety:**
- "Papers about KCNQ2 modulators" → semantic_search
- "Is valproic acid safe for CNS?" → bbb_permeability + adme_tox_predictor

**Graph Queries:**
- "What does EGFR target?" → graph_neighbors
- "Find path from SCN1A to valproate" → graph_path

---

💡 **Tip:** Check the [unified reporting system](http://100.84.49.12:8082) for pre-generated insights before querying!

*Session: `{session_id[:8]}...`*
""",
        author="Sapphire v3.22 + Scientist" if SAPPHIRE_SCIENTIST_ENABLED else "Sapphire v3.22",
    ).send()

    # Initialize session
    cl.user_session.set("session_id", session_id)
    cl.user_session.set("conversation_history", [])
    cl.user_session.set("query_count", 0)
    cl.user_session.set("session_start", session_start)

    # Initialize Agent Mode (default: OFF - uses existing Sapphire)
    cl.user_session.set("agent_mode", False)

    # Initialize Intelligence Orchestrator with available agents
    try:
        available_agents = {
            "drug_repurposing": DrugRepurposingAgent(),
            "target_discovery": TargetDiscoveryAgent(),
            "safety_prediction": SafetyPredictionAgent(),
            "pathway_analysis": PathwayAnalysisAgent(),
        }
        orchestrator = IntelligenceOrchestrator(available_agents=available_agents)
        cl.user_session.set("orchestrator", orchestrator)
    except Exception as e:
        print(f"⚠️  Failed to initialize Intelligence Orchestrator: {e}")
        cl.user_session.set("orchestrator", None)

    # Save initial session to JSON
    save_conversation_to_json(
        session_id,
        {
            "session_id": session_id,
            "session_start": session_start,
            "conversation_history": [],
            "query_count": 0,
        },
    )

    print(
        f"✅ Sapphire v3.22 session initialized: {session_id[:8]}... with {len(TOOL_REGISTRY)} tools"
    )


async def render_adaptive_card(card_data: Dict[str, Any], tool_name: str) -> None:
    """
    Render an adaptive card in Chainlit UI

    Args:
        card_data: Adaptive card JSON
        tool_name: Name of tool that generated the card
    """
    try:
        # Chainlit supports adaptive cards via Actions
        # For now, render as formatted JSON with instructions
        card_json = json.dumps(card_data, indent=2)

        await cl.Message(
            content=f"""## 🎯 Interactive Card from `{tool_name}`

The tool has generated an interactive card for you to make selections.

**Card Preview:**
```json
{card_json}
```

**Instructions:**
1. Review the options presented in the card
2. The next implementation phase will render this as a fully interactive Chainlit adaptive card
3. For now, please describe your selections in your next message

**Available Actions:**
{_extract_card_actions(card_data)}
""",
            author="System",
        ).send()

    except Exception as e:
        await cl.Message(
            content=f"⚠️ Failed to render adaptive card: {e}",
            author="System",
        ).send()


def _extract_card_actions(card_data: Dict[str, Any]) -> str:
    """Extract and format actions from adaptive card"""
    actions = card_data.get("actions", [])

    if not actions:
        return "- No actions available"

    action_list = []
    for action in actions:
        title = action.get("title", "Unknown")
        action_type = action.get("data", {}).get("action", "unknown")
        action_list.append(f"- **{title}** ({action_type})")

    return "\n".join(action_list)


@cl.on_message
async def on_message(message: cl.Message):
    """Handle incoming user messages with pure agentic orchestration."""
    query = message.content

    # Handle /agent toggle command
    if query.startswith("/agent"):
        parts = query.split()
        if len(parts) > 1:
            if parts[1].lower() == "on":
                cl.user_session.set("agent_mode", True)
                await cl.Message(
                    content="✅ **Agent Mode ENABLED**\n\nQueries will now be routed through the Intelligence Orchestrator with Phase 1-3 agents:\n- Drug Repurposing Agent\n- Target Discovery Agent\n- Safety Prediction Agent\n- Pathway Analysis Agent\n\nUse `/agent off` to return to standard Sapphire.",
                    author="System"
                ).send()
                return
            elif parts[1].lower() == "off":
                cl.user_session.set("agent_mode", False)
                await cl.Message(
                    content="✅ **Agent Mode DISABLED**\n\nQueries will now use standard Sapphire orchestration with 60 atomic tools.",
                    author="System"
                ).send()
                return
            elif parts[1].lower() == "status":
                agent_mode = cl.user_session.get("agent_mode", False)
                status = "**ENABLED**" if agent_mode else "**DISABLED**"
                await cl.Message(
                    content=f"📊 **Agent Mode Status**: {status}\n\nUse `/agent on` or `/agent off` to toggle.",
                    author="System"
                ).send()
                return
        else:
            await cl.Message(
                content="ℹ️ **Agent Mode Commands:**\n- `/agent on` - Enable Phase 1-3 agent pipeline\n- `/agent off` - Use standard Sapphire (default)\n- `/agent status` - Check current mode",
                author="System"
            ).send()
            return

    # Get session data
    conversation_history = cl.user_session.get("conversation_history", [])
    query_count = cl.user_session.get("query_count", 0)
    session_id = cl.user_session.get("session_id", "unknown")
    session_start = cl.user_session.get("session_start", datetime.now().isoformat())

    # Increment query count
    query_count += 1
    cl.user_session.set("query_count", query_count)

    # CRITICAL FIX #4: Save session IMMEDIATELY with in_progress status
    # This ensures query is persisted even if crash occurs during tool execution
    current_query_entry = {
        "timestamp": datetime.now().isoformat(),
        "query": query,
        "status": "in_progress",
        "query_number": query_count
    }

    save_conversation_to_json(
        session_id,
        {
            "session_id": session_id,
            "session_start": session_start,
            "last_updated": datetime.now().isoformat(),
            "query_count": query_count,
            "conversation_history": conversation_history,
            "current_query": current_query_entry,  # Track in-progress query
        },
    )

    try:
        # Check if Agent Mode is enabled
        agent_mode = cl.user_session.get("agent_mode", False)

        if agent_mode:
            # Route through Intelligence Orchestrator (Phase 1-3 agents)
            orchestrator = cl.user_session.get("orchestrator")
            if orchestrator:
                await cl.Message(
                    content="🤖 *Routing through Intelligence Orchestrator...*",
                    author="System"
                ).send()

                agent_result = await orchestrator.execute({
                    "query": query,
                    "context": {"session_id": cl.user_session.get("session_id")},
                    "max_agents": 3
                })

                # Send agent response
                if agent_result.get("response"):
                    await cl.Message(
                        content=agent_result["response"],
                        author="Sapphire (Agent Mode)"
                    ).send()

                    # Show which agents were used
                    agents_used = agent_result.get("agents_used", [])
                    confidence = agent_result.get("confidence", 0.0)
                    metadata_footer = f"\n\n---\n*Agent Mode • Query #{query_count} • Agents: {', '.join(agents_used) if agents_used else 'None'} • Confidence: {confidence:.2f}*"
                    await cl.Message(content=metadata_footer, author="System").send()

                    # Update conversation history
                    conversation_history.append({"role": "user", "content": query})
                    conversation_history.append({"role": "assistant", "content": agent_result["response"]})
                else:
                    await cl.Message(
                        content="❌ **Agent Mode Error**: No response from orchestrator\n\nTry disabling Agent Mode with `/agent off`",
                        author="System"
                    ).send()
            else:
                await cl.Message(
                    content="❌ **Agent Mode Error**: Orchestrator not initialized\n\nDisabling Agent Mode...",
                    author="System"
                ).send()
                cl.user_session.set("agent_mode", False)
        else:
            # Use standard Sapphire orchestration (existing behavior)
            result = await orchestrate_with_streaming(
                query=query,
                conversation_history=conversation_history,
                show_thinking=True,  # Show tool calls in UI
            )

            # Send metadata footer (response was already streamed)
            if result.get("success"):
                final_answer = result["final_answer"]

                # Track session cost metrics
                try:
                    litellm_client = get_litellm_client()
                    stats = litellm_client.get_stats()
                    metrics = get_metrics()
                    metrics.track_session_cost(
                        input_tokens=stats["total_input_tokens"],
                        output_tokens=stats["total_output_tokens"],
                        cost_usd=stats["total_cost_usd"],
                    )
                except Exception as e:
                    print(f"⚠️  Failed to track session cost: {e}")

                # Add metadata footer
                tool_count = len(result.get("tool_calls", []))
                turns = result.get("turns", 0)

                metadata_footer = f"\n\n---\n*Query #{query_count} • {tool_count} tool{'s' if tool_count != 1 else ''} used • {turns} turn{'s' if turns != 1 else ''}*"

                await cl.Message(content=metadata_footer, author="System").send()

                # Update conversation history (keep last 20 messages for longer context)
                conversation_history.append({"role": "user", "content": query})
                conversation_history.append({"role": "assistant", "content": final_answer})
                if len(conversation_history) > 40:  # 20 exchanges (doubled from 10)
                    conversation_history = conversation_history[-40:]
                cl.user_session.set("conversation_history", conversation_history)

                # CRITICAL FIX #4: Save conversation with 'completed' status
                save_conversation_to_json(
                    session_id,
                    {
                        "session_id": session_id,
                        "session_start": session_start,
                        "last_updated": datetime.now().isoformat(),
                        "query_count": query_count,
                        "conversation_history": conversation_history,
                        "tool_calls": result.get("tool_calls", []),
                        "current_query": {
                            **current_query_entry,
                            "status": "completed",  # Mark as successfully completed
                            "response": final_answer,
                            "tool_count": len(result.get("tool_calls", [])),
                            "completed_at": datetime.now().isoformat()
                        },
                    },
                )

            else:
                # Error occurred - save session with error status
                error_msg = result.get("error", "Unknown error")
                await cl.Message(
                    content=f"❌ **Error**: {error_msg}\n\nPlease try rephrasing your query or contact support if this persists.",
                    author="Sapphire",
                ).send()

                # CRITICAL FIX #4: Save session with 'error' status
                save_conversation_to_json(
                    session_id,
                    {
                        "session_id": session_id,
                        "session_start": session_start,
                        "last_updated": datetime.now().isoformat(),
                        "query_count": query_count,
                        "conversation_history": conversation_history,
                        "current_query": {
                            **current_query_entry,
                            "status": "error",
                            "error": error_msg,
                            "failed_at": datetime.now().isoformat()
                        },
                    },
                )

    except Exception as e:
        # Show error
        await cl.Message(
            content=f"❌ **Unexpected Error**: {e!s}\n\nPlease try again or contact support.",
            author="Sapphire",
        ).send()

        # CRITICAL FIX #4: Save session with 'crashed' status
        # This ensures we capture the exception that caused the crash
        try:
            save_conversation_to_json(
                session_id,
                {
                    "session_id": session_id,
                    "session_start": session_start,
                    "last_updated": datetime.now().isoformat(),
                    "query_count": query_count,
                    "conversation_history": conversation_history,
                    "current_query": {
                        **current_query_entry,
                        "status": "crashed",
                        "exception": str(e),
                        "crashed_at": datetime.now().isoformat()
                    },
                },
            )
        except Exception as save_error:
            print(f"⚠️  Failed to save crash session: {save_error}")

        print(f"Error in on_message: {e!s}")
        import traceback

        traceback.print_exc()


if __name__ == "__main__":
    print(f"""
╔══════════════════════════════════════════════════════════════════════╗
║   Sapphire v3.23 - Atomic Fusion Primitives + Composable Reasoning   ║
╚══════════════════════════════════════════════════════════════════════╝

✅ {len(TOOL_REGISTRY)} atomic tools loaded (60 total)
✅ 14 atomic fusion primitives (100% fusion table coverage!)
✅ Claude Sonnet 4.5 with 64K context window ready
✅ Extended orchestration (10 turns, 20 exchanges)
✅ Parallel tool execution enabled
✅ Composable multi-hop reasoning enabled

Fusion Coverage:
  • Drug Auxiliary (5): ADR, Cell Type, DGP, EP, MOP
  • Gene Auxiliary (5): Cell Type, DGP, EP, MOP, Syndrome
  • Cross-Modal (2): Drug→Gene, Drug→Gene EP
  • Same-Modal (2): Drug-Drug, Gene-Gene

Data Access:
  • 18,368 genes (MODEX 32D)
  • 14,246 drugs (PCA 32D)
  • 1.3M nodes, 9.5M relationships (Neo4j)
  • 29,863 CNS papers (ChromaDB)
  • 14 fusion tables (12.3M pre-computed pairs, 492 MB)

Starting Chainlit server...
""")
