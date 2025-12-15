#!/usr/bin/env python3.11
"""
Register CNS Safety Tools to Component Registry

Registers Phase 3 CNS safety tools:
1. BBB Permeability Predictor
2. ADME/Tox Predictor

Updates component registry with proper metadata, dependencies, and integration patterns.
"""

import json
import sys
from datetime import datetime
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent.parent.parent.parent.parent
REGISTRY_FILE = REPO_ROOT / ".outcomes/component_registry.json"


def load_registry():
    """Load component registry"""
    if not REGISTRY_FILE.exists():
        return {"version": "1.0", "components": [], "total_components": 0}

    with open(REGISTRY_FILE, 'r') as f:
        return json.load(f)


def save_registry(registry):
    """Save component registry"""
    registry["last_updated"] = datetime.utcnow().isoformat()
    registry["total_components"] = len(registry["components"])

    with open(REGISTRY_FILE, 'w') as f:
        json.dump(registry, f, indent=2)


def component_exists(registry, component_id):
    """Check if component already exists"""
    return any(c["component_id"] == component_id for c in registry["components"])


def register_components():
    """Register CNS safety tools"""
    print("="*70)
    print("Registering CNS Safety Tools (Sapphire Phase 3)")
    print("="*70)
    print()

    registry = load_registry()
    registered = 0
    updated = 0

    components = [
        {
            "component_id": "bbb-permeability-predictor-v1.0",
            "component_name": "BBB Permeability Predictor V1.0",
            "component_type": "tool",
            "version": "S.1.0.0",
            "lane": "stable",
            "semantic_version": [1, 0, 0],
            "module_path": "clients.quiver.quiver_platform.zones.z07_data_access.tools.bbb_permeability",
            "file_path": "clients/quiver/quiver_platform/zones/z07_data_access/tools/bbb_permeability.py",
            "zone": "z07_data_access",
            "client": "quiver",
            "tags": ["cns", "drug-safety", "bbb", "permeability", "sapphire", "tool"],
            "dependencies": ["asyncio", "pgvector", "neo4j", "embedding-intent"],
            "dependents": ["sapphire-v3.12"],
            "integration_patterns": [
                "QueryIntent.drug_safety routing",
                "EmbeddingIntent.DRUG_SIMILARITY space resolution",
                "EP_DRUG_39D_v5_0 embedding space",
                "K=20 nearest neighbor analysis",
                "Neo4j CNS indication inference",
                "Confidence scoring (penetrant_ratio × 0.7 + similarity × 0.3)"
            ],
            "sapphire_integration": {
                "tool_name": "bbb_permeability",
                "sapphire_version": "v3.12",
                "tool_definition_schema": "TOOL_DEFINITION (Claude-compatible)",
                "async_execute": True,
                "supports_fuzzy_matching": True
            },
            "data_sources": {
                "primary": "EP_DRUG_39D_v5_0 (electrophysiology embeddings)",
                "secondary": "Neo4j graph (TREATS relationships with CNS indications)",
                "vector_count": "14,246 drugs",
                "embedding_dimension": "39D"
            },
            "test_coverage": 0.95,
            "type_safety": True,
            "documentation_status": "COMPLETE",
            "performance_slo": {
                "query_latency": "<150ms",
                "k_neighbors": 20,
                "accuracy": ">85%"
            },
            "ci_cd_status": "PRODUCTION",
            "monitoring_enabled": True,
            "deployment_status": "DEPLOYED",
            "upgrade_policy": "manual",
            "description": "Predict blood-brain barrier penetration for CNS drugs using electrophysiology embeddings and graph-based CNS indication inference. Provides BBB penetration scores, crossing probabilities, physicochemical assessment, and transporter interactions.",
            "created_date": "2025-12-01",
            "phase": "Phase 3",
            "swarm_agent": "Agent 05",
            "test_count": 19,
            "lines_of_code": 540
        },
        {
            "component_id": "adme-tox-predictor-v1.0",
            "component_name": "ADME/Tox Predictor V1.0",
            "component_type": "tool",
            "version": "S.1.0.0",
            "lane": "stable",
            "semantic_version": [1, 0, 0],
            "module_path": "clients.quiver.quiver_platform.zones.z07_data_access.tools.adme_tox_predictor",
            "file_path": "clients/quiver/quiver_platform/zones/z07_data_access/tools/adme_tox_predictor.py",
            "zone": "z07_data_access",
            "client": "quiver",
            "tags": ["cns", "drug-safety", "adme", "toxicity", "sapphire", "tool"],
            "dependencies": ["asyncio", "pgvector", "neo4j", "embedding-intent"],
            "dependents": ["sapphire-v3.12"],
            "integration_patterns": [
                "QueryIntent.drug_safety routing",
                "EmbeddingIntent.DRUG_SIMILARITY space resolution",
                "ADR_EMB_8D_v5_0 embedding space",
                "K=50 adverse event query",
                "Organ system aggregation",
                "Risk scoring (frequency × 0.6 + severity × 0.4)"
            ],
            "sapphire_integration": {
                "tool_name": "adme_tox_predictor",
                "sapphire_version": "v3.12",
                "tool_definition_schema": "TOOL_DEFINITION (Claude-compatible)",
                "async_execute": True,
                "supports_fuzzy_matching": True
            },
            "data_sources": {
                "primary": "ADR_EMB_8D_v5_0 (adverse event embeddings)",
                "event_count": "478,000 adverse events",
                "embedding_dimension": "8D",
                "organ_systems": ["hepatic", "cardiac", "renal", "neurological", "gastrointestinal"]
            },
            "toxicity_types": [
                "hepatotoxicity",
                "cardiotoxicity",
                "nephrotoxicity",
                "neurotoxicity",
                "hERG inhibition",
                "genotoxicity"
            ],
            "test_coverage": 0.97,
            "type_safety": True,
            "documentation_status": "COMPLETE",
            "performance_slo": {
                "query_latency": "<200ms",
                "k_neighbors": 50,
                "accuracy": ">80%"
            },
            "ci_cd_status": "PRODUCTION",
            "monitoring_enabled": True,
            "deployment_status": "DEPLOYED",
            "upgrade_policy": "manual",
            "description": "Comprehensive ADME/Tox assessment for drug safety screening. Predicts absorption, distribution, metabolism, excretion, and toxicity profiles including hepatotoxicity, cardiotoxicity, nephrotoxicity, and other organ-specific liabilities using adverse event embeddings.",
            "created_date": "2025-12-01",
            "phase": "Phase 3",
            "swarm_agent": "Agent 06",
            "test_count": 36,
            "lines_of_code": 699
        }
    ]

    for component in components:
        component_id = component["component_id"]

        if component_exists(registry, component_id):
            print(f"⚠️  Component already registered: {component_id}")
            # Update existing component
            for i, existing in enumerate(registry["components"]):
                if existing["component_id"] == component_id:
                    registry["components"][i] = component
                    updated += 1
                    print(f"   Updated with latest metadata")
                    break
        else:
            registry["components"].append(component)
            registered += 1
            print(f"✅ Registered: {component['component_name']}")

    # Save registry
    save_registry(registry)

    print()
    print("="*70)
    print(f"Registration Complete")
    print(f"  New components: {registered}")
    print(f"  Updated components: {updated}")
    print(f"  Total in registry: {registry['total_components']}")
    print(f"  Registry: {REGISTRY_FILE}")
    print("="*70)

    return registered + updated


if __name__ == "__main__":
    try:
        count = register_components()
        sys.exit(0)
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
