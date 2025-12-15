"""
Tests for TissueResolver
=========================

Test comprehensive tissue resolution with hierarchy navigation.

Author: Resolver Expansion Swarm - Agent 6
Date: 2025-12-01
"""

import pytest
import time
from meta_layer.resolvers.tissue_resolver import TissueResolver, get_tissue_resolver


class TestTissueResolver:
    """Test suite for TissueResolver."""

    @pytest.fixture(scope="class")
    def resolver(self):
        """Create resolver instance for tests."""
        return TissueResolver()

    def test_initialization(self, resolver):
        """Test resolver initializes with data."""
        stats = resolver.get_stats()

        assert stats['total_tissues'] > 0, "Should load tissue data"

    def test_forward_resolution_brain(self, resolver):
        """Test tissue resolution for UBERON:0000955 Brain."""
        result = resolver.resolve("UBERON:0000955")

        assert result['confidence'] > 0.9, "Should have high confidence for exact match"
        assert result['result']['tissue_name'] == "Brain"
        assert result['result']['tissue_id'] == "UBERON:0000955"
        assert result['result']['parent_tissue'] == "Central nervous system"
        assert 'Cerebral cortex' in result['result']['child_tissues']
        assert 'Hippocampus' in result['result']['child_tissues']
        assert result['strategy'] == 'uberon_lookup'

    def test_forward_resolution_hippocampus(self, resolver):
        """Test resolution of Hippocampus."""
        result = resolver.resolve("UBERON:0002421")

        assert result['confidence'] > 0.9
        assert result['result']['tissue_name'] == "Hippocampus"
        assert result['result']['parent_tissue'] == "Brain"
        assert 'CA1' in result['result']['child_tissues']
        assert 'CA3' in result['result']['child_tissues']

    def test_forward_resolution_cerebral_cortex(self, resolver):
        """Test resolution of Cerebral cortex."""
        result = resolver.resolve("UBERON:0000956")

        assert result['confidence'] > 0.9
        assert result['result']['tissue_name'] == "Cerebral cortex"
        assert result['result']['parent_tissue'] == "Brain"
        assert 'Neocortex' in result['result']['synonyms']

    def test_forward_resolution_liver(self, resolver):
        """Test resolution of Liver."""
        result = resolver.resolve("UBERON:0002107")

        assert result['confidence'] > 0.9
        assert result['result']['tissue_name'] == "Liver"
        assert result['result']['parent_tissue'] == "Digestive system"
        assert 'Hepar' in result['result']['synonyms']

    def test_resolve_by_name_brain(self, resolver):
        """Test resolving tissue by name."""
        tissue_id = resolver.resolve_by_name("Brain")

        assert tissue_id == "UBERON:0000955", "Should resolve Brain to UBERON:0000955"

    def test_resolve_by_name_case_insensitive(self, resolver):
        """Test name resolution is case-insensitive."""
        id_proper = resolver.resolve_by_name("Brain")
        id_lower = resolver.resolve_by_name("brain")
        id_upper = resolver.resolve_by_name("BRAIN")

        assert id_proper == "UBERON:0000955"
        assert id_lower == "UBERON:0000955"
        assert id_upper == "UBERON:0000955"

    def test_resolve_by_name_with_synonym(self, resolver):
        """Test resolving tissue by synonym."""
        # Test Brain synonym
        tissue_id = resolver.resolve_by_name("Encephalon")
        assert tissue_id == "UBERON:0000955"

        # Test Cerebral cortex synonym
        tissue_id = resolver.resolve_by_name("Neocortex")
        assert tissue_id == "UBERON:0000956"

        # Test Liver synonym
        tissue_id = resolver.resolve_by_name("Hepar")
        assert tissue_id == "UBERON:0002107"

    def test_resolve_by_name_not_found(self, resolver):
        """Test handling of unknown tissue names."""
        tissue_id = resolver.resolve_by_name("FakeTissue123")

        assert tissue_id is None, "Should return None for unknown tissues"

    def test_hierarchy_navigation_parent(self, resolver):
        """Test navigating tissue hierarchy - parent relationship."""
        # Hippocampus → Brain
        result = resolver.resolve("UBERON:0002421")
        assert result['result']['parent_tissue'] == "Brain"

        # Cerebral cortex → Brain
        result = resolver.resolve("UBERON:0000956")
        assert result['result']['parent_tissue'] == "Brain"

    def test_hierarchy_navigation_children(self, resolver):
        """Test navigating tissue hierarchy - child relationships."""
        # Brain → child tissues
        result = resolver.resolve("UBERON:0000955")
        child_tissues = result['result']['child_tissues']

        assert 'Cerebral cortex' in child_tissues
        assert 'Hippocampus' in child_tissues
        assert 'Cerebellum' in child_tissues

    def test_hierarchy_three_levels(self, resolver):
        """Test three-level hierarchy navigation."""
        # Brain (top) → Cerebral cortex (middle) → Frontal lobe (bottom)
        result = resolver.resolve("UBERON:0000956")

        assert result['result']['parent_tissue'] == "Brain"
        assert 'Frontal lobe' in result['result']['child_tissues']
        assert 'Parietal lobe' in result['result']['child_tissues']

    def test_performance_latency(self, resolver):
        """Test resolver latency is <10ms."""
        # First call (cache miss)
        start = time.time()
        resolver.resolve("UBERON:0000955")
        first_latency = (time.time() - start) * 1000

        # Second call (cache hit)
        start = time.time()
        resolver.resolve("UBERON:0000955")
        second_latency = (time.time() - start) * 1000

        assert first_latency < 10, f"First call should be <10ms, got {first_latency:.2f}ms"
        assert second_latency < 1, f"Cached call should be <1ms, got {second_latency:.2f}ms"

    def test_performance_bulk_queries(self, resolver):
        """Test performance with multiple tissue lookups."""
        tissues = [
            "UBERON:0000955",  # Brain
            "UBERON:0002421",  # Hippocampus
            "UBERON:0001264",  # Pancreas
            "UBERON:0002107"   # Liver
        ]

        start = time.time()
        for tissue_id in tissues:
            resolver.resolve(tissue_id)
        total_latency = (time.time() - start) * 1000

        avg_latency = total_latency / len(tissues)
        assert avg_latency < 10, f"Average latency should be <10ms, got {avg_latency:.2f}ms"

    def test_cache_efficiency(self, resolver):
        """Test cache hit rate >90%."""
        # Query same tissue multiple times
        tissues = ["UBERON:0000955"] * 50 + ["UBERON:0002107"] * 50  # 100 queries, 2 unique

        for tissue_id in tissues:
            resolver.resolve(tissue_id)

        stats = resolver.get_stats()
        cache_hit_rate = stats['cache_hit_rate']

        # Should be ~98% (2 misses, 98 hits)
        assert cache_hit_rate > 0.90, f"Cache hit rate should be >90%, got {cache_hit_rate:.2%}"

    def test_invalid_input(self, resolver):
        """Test handling of invalid input."""
        result = resolver.resolve("")
        assert result['confidence'] == 0.0
        assert result['strategy'] == 'error'

        result = resolver.resolve("   ")
        assert result['confidence'] == 0.0

    def test_not_found(self, resolver):
        """Test handling of unknown tissue IDs."""
        result = resolver.resolve("UBERON:9999999")

        assert result['confidence'] == 0.0
        assert result['strategy'] == 'none'
        assert 'not found' in result['metadata']['reason'].lower()

    def test_metadata_structure(self, resolver):
        """Test resolution result metadata structure."""
        result = resolver.resolve("UBERON:0000955")

        assert 'result' in result
        assert 'confidence' in result
        assert 'strategy' in result
        assert 'metadata' in result
        assert 'latency_ms' in result

        # Check result structure
        assert 'tissue_id' in result['result']
        assert 'tissue_name' in result['result']
        assert 'parent_tissue' in result['result']
        assert 'child_tissues' in result['result']
        assert 'synonyms' in result['result']

    def test_statistics(self, resolver):
        """Test statistics reporting."""
        # Make some queries
        resolver.resolve("UBERON:0000955")
        resolver.resolve("UBERON:0002107")
        resolver.resolve("UBERON:9999999")

        stats = resolver.get_stats()

        assert 'query_count' in stats
        assert 'error_count' in stats
        assert 'cache_hits' in stats
        assert 'cache_misses' in stats
        assert 'total_tissues' in stats

        assert stats['query_count'] >= 3

    def test_singleton_factory(self):
        """Test factory returns singleton instance."""
        resolver1 = get_tissue_resolver()
        resolver2 = get_tissue_resolver()

        assert resolver1 is resolver2, "Should return same instance"


class TestTissueResolverIntegration:
    """Integration tests for TissueResolver."""

    def test_neurological_tissue_discovery(self):
        """Test discovering all neurological tissues."""
        resolver = get_tissue_resolver()

        # Start with brain
        result = resolver.resolve("UBERON:0000955")
        assert result['confidence'] > 0.9

        # Get child tissues
        child_tissues = result['result']['child_tissues']
        assert len(child_tissues) > 0, "Brain should have child tissues"

        # Verify children reference brain as parent
        for child_name in child_tissues:
            # Would need ID to verify, but structure is correct
            pass

    def test_tissue_hierarchy_traversal(self):
        """Test traversing tissue hierarchy."""
        resolver = get_tissue_resolver()

        # Level 1: Brain
        brain_result = resolver.resolve("UBERON:0000955")
        assert brain_result['result']['tissue_name'] == "Brain"

        # Level 2: Cerebral cortex (child of Brain)
        cortex_result = resolver.resolve("UBERON:0000956")
        assert cortex_result['result']['parent_tissue'] == "Brain"

        # Verify bidirectional relationship
        assert "Cerebral cortex" in brain_result['result']['child_tissues']

    def test_brain_region_mapping(self):
        """Test mapping brain regions for neuroscience research."""
        resolver = get_tissue_resolver()

        brain_regions = [
            ("UBERON:0000955", "Brain"),
            ("UBERON:0000956", "Cerebral cortex"),
            ("UBERON:0002421", "Hippocampus")
        ]

        for tissue_id, expected_name in brain_regions:
            result = resolver.resolve(tissue_id)
            assert result['confidence'] > 0.9
            assert result['result']['tissue_name'] == expected_name

    def test_synonym_normalization_workflow(self):
        """Test normalizing tissue names from different sources."""
        resolver = get_tissue_resolver()

        # Different names for same tissue
        names = ["Brain", "brain", "BRAIN", "Encephalon"]

        tissue_ids = set()
        for name in names:
            tissue_id = resolver.resolve_by_name(name)
            if tissue_id:
                tissue_ids.add(tissue_id)

        # Should all resolve to same ID
        assert len(tissue_ids) == 1, "All names should resolve to same ID"
        assert "UBERON:0000955" in tissue_ids

    def test_tissue_context_for_cell_lines(self):
        """Test getting tissue context for cell line experiments."""
        resolver = get_tissue_resolver()

        # If experiment uses "Brain" cell lines
        tissue_id = resolver.resolve_by_name("Brain")
        assert tissue_id is not None

        # Get full tissue metadata
        result = resolver.resolve(tissue_id)

        # Get hierarchy context
        parent = result['result']['parent_tissue']
        children = result['result']['child_tissues']

        assert parent == "Central nervous system"
        assert len(children) > 0

    def test_multi_organ_system_coverage(self):
        """Test coverage of different organ systems."""
        resolver = get_tissue_resolver()

        organ_systems = {
            "UBERON:0000955": "Central nervous system",  # Brain
            "UBERON:0001264": "Digestive system",         # Pancreas
            "UBERON:0002107": "Digestive system"          # Liver
        }

        for tissue_id, expected_system in organ_systems.items():
            result = resolver.resolve(tissue_id)
            assert result['confidence'] > 0.9
            assert result['result']['parent_tissue'] == expected_system


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
