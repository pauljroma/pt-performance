#!/usr/bin/env python3
"""
Meta Layer - Basic Usage Examples
==================================

Simple examples showing how to use individual resolvers
and the complete pipeline.

Author: Meta Layer Swarm - Agent 2
Date: 2025-12-01
"""

import sys
from pathlib import Path

# Add expo root to path
expo_root = Path(__file__).parent.parent.parent.parent.parent.parent.parent
sys.path.insert(0, str(expo_root))


def example_1_fuzzy_matching():
    """Example 1: Fuzzy entity matching."""
    print("="*60)
    print("Example 1: Fuzzy Entity Matching")
    print("="*60)

    from zones.z07_data_access.meta_layer.resolvers import (
        get_fuzzy_entity_matcher
    )

    matcher = get_fuzzy_entity_matcher()

    # Test cases
    queries = [
        "lamotrigine",               # Exact match
        "vpa",                       # Synonym
        "lamtorigine",               # Typo
        "antiepileptic drugs",       # Category
        "Which drugs for epilepsy",  # Extract from question
    ]

    for query in queries:
        result = matcher.match(query)
        print(f"\nQuery: '{query}'")
        print(f"  → Entity: {result['entity']}")
        print(f"  → Type: {result['entity_type']}")
        print(f"  → Confidence: {result['confidence']:.2f}")
        print(f"  → Strategy: {result['strategy']}")


def example_2_intent_classification():
    """Example 2: Intent classification."""
    print("\n" + "="*60)
    print("Example 2: Intent Classification")
    print("="*60)

    from zones.z07_data_access.meta_layer.classifiers import (
        get_intent_classifier
    )

    classifier = get_intent_classifier()

    # Test questions
    questions = [
        "What is the BBB permeability of lamotrigine?",
        "Find drugs similar to phenytoin",
        "Find rescue candidates for gene SCN1A",
        "What is the mechanism of action for gabapentin?",
    ]

    for question in questions:
        result = classifier.classify(question)
        print(f"\nQuestion: '{question}'")
        print(f"  → Intent: {result['intent']}")
        print(f"  → Tool: {result['tool']}")
        print(f"  → Space: {result['primary_space']}")
        print(f"  → Confidence: {result['confidence']:.2f}")


def example_3_drug_name_resolution():
    """Example 3: Drug name resolution."""
    print("\n" + "="*60)
    print("Example 3: Drug Name Resolution")
    print("="*60)

    from zones.z07_data_access.meta_layer.resolvers import (
        get_drug_name_resolver
    )

    resolver = get_drug_name_resolver()

    # Test drug IDs
    drug_ids = [
        "lamotrigine",      # Commercial name
        "QS0318588",        # QS code (if available)
        "BRD-K12345678",    # BRD code (example)
    ]

    for drug_id in drug_ids:
        result = resolver.resolve(drug_id)
        print(f"\nDrug ID: '{drug_id}'")
        print(f"  → Commercial Name: {result['commercial_name']}")
        print(f"  → CHEMBL ID: {result.get('chembl_id', 'N/A')}")
        print(f"  → Confidence: {result['confidence']}")
        print(f"  → Source: {result['source']}")


def example_4_complete_pipeline():
    """Example 4: Complete pipeline."""
    print("\n" + "="*60)
    print("Example 4: Complete Pipeline")
    print("="*60)

    from zones.z07_data_access.meta_layer import (
        get_meta_layer_pipeline
    )

    pipeline = get_meta_layer_pipeline()

    # Complex questions
    questions = [
        "Assess BBB permeability of lamotrigine",
        "Find drugs similar to phenytoin",
        "Find rescue candidates for epilepsy gene SCN1A",
    ]

    for question in questions:
        print(f"\n{'─'*60}")
        print(f"Question: '{question}'")
        print('─'*60)

        result = pipeline.process(question)

        # Show pipeline results
        if result['entities']:
            entity = result['entities'][0]
            print(f"  Entity: {entity['entity']} ({entity['entity_type']})")
            print(f"  Entity Confidence: {entity['confidence']:.2f}")

        if result['intent']:
            intent = result['intent']
            print(f"  Intent: {intent['intent']}")
            print(f"  Tool: {intent['tool']}")
            print(f"  Space: {intent['primary_space']}")

        if result['query_params']:
            params = result['query_params']
            print(f"  Query Params:")
            print(f"    - entity_name: {params.get('entity_name')}")
            print(f"    - entity_type: {params.get('entity_type')}")
            print(f"    - preferred_space: {params.get('preferred_space')}")
            print(f"    - k: {params.get('k')}")

        metadata = result['pipeline_metadata']
        print(f"  Pipeline:")
        print(f"    - Stages: {', '.join(metadata.get('stages_executed', []))}")
        print(f"    - Latency: {metadata.get('total_latency_ms', 0):.1f}ms")
        print(f"    - Confidence: {metadata.get('confidence', 0):.2f}")


def example_5_stats():
    """Example 5: Resolver statistics."""
    print("\n" + "="*60)
    print("Example 5: Resolver Statistics")
    print("="*60)

    from zones.z07_data_access.meta_layer import (
        get_meta_layer_pipeline
    )

    pipeline = get_meta_layer_pipeline()

    # Run some queries first
    queries = [
        "lamotrigine",
        "Find drugs similar to phenytoin",
        "rescue candidates for SCN1A"
    ]

    for query in queries:
        pipeline.process(query)

    # Get statistics
    stats = pipeline.get_stats()

    print("\nPipeline Statistics:")
    for component, component_stats in stats.items():
        print(f"\n{component}:")
        for key, value in component_stats.items():
            print(f"  {key}: {value}")


if __name__ == "__main__":
    example_1_fuzzy_matching()
    example_2_intent_classification()
    example_3_drug_name_resolution()
    example_4_complete_pipeline()
    example_5_stats()

    print("\n" + "="*60)
    print("✅ All examples complete!")
    print("="*60)
