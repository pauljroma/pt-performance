"""
Tests for CellLineResolver
===========================

Test comprehensive cell line resolution with metadata.

Author: Resolver Expansion Swarm - Agent 5
Date: 2025-12-01
"""

import pytest
import time
from meta_layer.resolvers.cellline_resolver import CellLineResolver, get_cellline_resolver


class TestCellLineResolver:
    """Test suite for CellLineResolver."""

    @pytest.fixture(scope="class")
    def resolver(self):
        """Create resolver instance for tests."""
        return CellLineResolver()

    def test_initialization(self, resolver):
        """Test resolver initializes with data."""
        stats = resolver.get_stats()

        assert stats['total_cell_lines'] > 0, "Should load cell line data"

    def test_forward_resolution_hek293(self, resolver):
        """Test cell line resolution for CVCL_0030 HEK293."""
        result = resolver.resolve("CVCL_0030")

        assert result['confidence'] > 0.9, "Should have high confidence for exact match"
        assert result['result']['cell_line_name'] == "HEK293"
        assert result['result']['cell_line_id'] == "CVCL_0030"
        assert result['result']['species'] == "Homo sapiens"
        assert result['result']['tissue'] == "Kidney"
        assert result['result']['disease'] == "Normal"
        assert result['result']['atcc_id'] == "CRL-1573"
        assert result['strategy'] == 'cellosaurus_lookup'

    def test_forward_resolution_hela(self, resolver):
        """Test resolution of HeLa cell line."""
        result = resolver.resolve("CVCL_0045")

        assert result['confidence'] > 0.9
        assert result['result']['cell_line_name'] == "HeLa"
        assert result['result']['tissue'] == "Cervix"
        assert result['result']['disease'] == "Cervical adenocarcinoma"

    def test_forward_resolution_shsy5y(self, resolver):
        """Test resolution of SH-SY5Y neuroblastoma cell line."""
        result = resolver.resolve("CVCL_0063")

        assert result['confidence'] > 0.9
        assert result['result']['cell_line_name'] == "SH-SY5Y"
        assert result['result']['tissue'] == "Brain"
        assert result['result']['disease'] == "Neuroblastoma"

    def test_resolve_by_name_hek293(self, resolver):
        """Test resolving cell line by name."""
        cell_line_id = resolver.resolve_by_name("HEK293")

        assert cell_line_id == "CVCL_0030", "Should resolve HEK293 to CVCL_0030"

    def test_resolve_by_name_case_insensitive(self, resolver):
        """Test name resolution is case-insensitive."""
        id_upper = resolver.resolve_by_name("HEK293")
        id_lower = resolver.resolve_by_name("hek293")
        id_mixed = resolver.resolve_by_name("Hek293")

        assert id_upper == "CVCL_0030"
        assert id_lower == "CVCL_0030"
        assert id_mixed == "CVCL_0030"

    def test_resolve_by_name_with_synonym(self, resolver):
        """Test resolving cell line by synonym."""
        # Test HEK293 synonyms
        cell_line_id = resolver.resolve_by_name("293")
        assert cell_line_id == "CVCL_0030"

        cell_line_id = resolver.resolve_by_name("HEK-293")
        assert cell_line_id == "CVCL_0030"

    def test_resolve_by_name_not_found(self, resolver):
        """Test handling of unknown cell line names."""
        cell_line_id = resolver.resolve_by_name("FAKECELL123")

        assert cell_line_id is None, "Should return None for unknown cell lines"

    def test_cell_lines_for_tissue_brain(self, resolver):
        """Test getting cell lines from Brain tissue."""
        cell_lines = resolver.cell_lines_for_tissue("Brain")

        assert len(cell_lines) > 0, "Should find brain cell lines"

        cell_line_names = [cl['cell_line_name'] for cl in cell_lines]
        assert "SH-SY5Y" in cell_line_names

    def test_cell_lines_for_tissue_kidney(self, resolver):
        """Test getting cell lines from Kidney tissue."""
        cell_lines = resolver.cell_lines_for_tissue("Kidney")

        assert len(cell_lines) > 0
        cell_line_names = [cl['cell_line_name'] for cl in cell_lines]
        assert "HEK293" in cell_line_names

    def test_cell_lines_for_tissue_not_found(self, resolver):
        """Test handling of tissues with no cell lines."""
        cell_lines = resolver.cell_lines_for_tissue("FakeTissue")

        assert len(cell_lines) == 0, "Should return empty list for unknown tissues"

    def test_species_information(self, resolver):
        """Test species information is correct."""
        # Human cell line
        result = resolver.resolve("CVCL_0030")
        assert result['result']['species'] == "Homo sapiens"

        # Hamster cell line
        result = resolver.resolve("CVCL_0023")
        assert result['result']['species'] == "Cricetulus griseus"

    def test_performance_latency(self, resolver):
        """Test resolver latency is <10ms."""
        # First call (cache miss)
        start = time.time()
        resolver.resolve("CVCL_0030")
        first_latency = (time.time() - start) * 1000

        # Second call (cache hit)
        start = time.time()
        resolver.resolve("CVCL_0030")
        second_latency = (time.time() - start) * 1000

        assert first_latency < 10, f"First call should be <10ms, got {first_latency:.2f}ms"
        assert second_latency < 1, f"Cached call should be <1ms, got {second_latency:.2f}ms"

    def test_performance_bulk_queries(self, resolver):
        """Test performance with multiple cell line lookups."""
        cell_lines = ["CVCL_0030", "CVCL_0045", "CVCL_0023", "CVCL_0063"]

        start = time.time()
        for cell_line_id in cell_lines:
            resolver.resolve(cell_line_id)
        total_latency = (time.time() - start) * 1000

        avg_latency = total_latency / len(cell_lines)
        assert avg_latency < 10, f"Average latency should be <10ms, got {avg_latency:.2f}ms"

    def test_cache_efficiency(self, resolver):
        """Test cache hit rate >90%."""
        # Query same cell line multiple times
        cell_lines = ["CVCL_0030"] * 50 + ["CVCL_0045"] * 50  # 100 queries, 2 unique

        for cell_line_id in cell_lines:
            resolver.resolve(cell_line_id)

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
        """Test handling of unknown cell line IDs."""
        result = resolver.resolve("CVCL_9999999")

        assert result['confidence'] == 0.0
        assert result['strategy'] == 'none'
        assert 'not found' in result['metadata']['reason'].lower()

    def test_metadata_structure(self, resolver):
        """Test resolution result metadata structure."""
        result = resolver.resolve("CVCL_0030")

        assert 'result' in result
        assert 'confidence' in result
        assert 'strategy' in result
        assert 'metadata' in result
        assert 'latency_ms' in result

        # Check result structure
        assert 'cell_line_id' in result['result']
        assert 'cell_line_name' in result['result']
        assert 'species' in result['result']
        assert 'tissue' in result['result']
        assert 'disease' in result['result']
        assert 'atcc_id' in result['result']
        assert 'synonyms' in result['result']

    def test_statistics(self, resolver):
        """Test statistics reporting."""
        # Make some queries
        resolver.resolve("CVCL_0030")
        resolver.resolve("CVCL_0045")
        resolver.resolve("CVCL_9999999")

        stats = resolver.get_stats()

        assert 'query_count' in stats
        assert 'error_count' in stats
        assert 'cache_hits' in stats
        assert 'cache_misses' in stats
        assert 'total_cell_lines' in stats

        assert stats['query_count'] >= 3

    def test_singleton_factory(self):
        """Test factory returns singleton instance."""
        resolver1 = get_cellline_resolver()
        resolver2 = get_cellline_resolver()

        assert resolver1 is resolver2, "Should return same instance"


class TestCellLineResolverIntegration:
    """Integration tests for CellLineResolver."""

    def test_experimental_context_workflow(self):
        """Test workflow for adding cell line context to experimental data."""
        resolver = get_cellline_resolver()

        # Step 1: Resolve cell line by name (from experiment metadata)
        cell_line_id = resolver.resolve_by_name("HEK293")
        assert cell_line_id is not None

        # Step 2: Get full cell line metadata
        result = resolver.resolve(cell_line_id)
        assert result['confidence'] > 0.9

        # Step 3: Extract context
        tissue = result['result']['tissue']
        species = result['result']['species']
        disease = result['result']['disease']

        assert tissue == "Kidney"
        assert species == "Homo sapiens"
        assert disease == "Normal"

    def test_tissue_cell_line_discovery(self):
        """Test discovering all cell lines for a tissue."""
        resolver = get_cellline_resolver()

        # Find all brain cell lines
        brain_cell_lines = resolver.cell_lines_for_tissue("Brain")
        assert len(brain_cell_lines) > 0

        # Verify each cell line
        for cell_line_info in brain_cell_lines:
            cell_line_id = cell_line_info['cell_line_id']
            result = resolver.resolve(cell_line_id)

            assert result['confidence'] > 0.9
            assert result['result']['tissue'] == "Brain"

    def test_neuroblastoma_cell_line_context(self):
        """Test getting context for neuroblastoma research."""
        resolver = get_cellline_resolver()

        # SH-SY5Y is a common neuroblastoma cell line
        result = resolver.resolve("CVCL_0063")

        assert result['result']['tissue'] == "Brain"
        assert result['result']['disease'] == "Neuroblastoma"
        assert result['result']['species'] == "Homo sapiens"

    def test_synonym_normalization(self):
        """Test normalizing different cell line name formats."""
        resolver = get_cellline_resolver()

        # Different formats for HEK293
        formats = ["HEK293", "HEK-293", "293"]

        cell_line_ids = set()
        for format_name in formats:
            cell_line_id = resolver.resolve_by_name(format_name)
            if cell_line_id:
                cell_line_ids.add(cell_line_id)

        # Should all resolve to same ID
        assert len(cell_line_ids) == 1, "All formats should resolve to same ID"
        assert "CVCL_0030" in cell_line_ids

    def test_atcc_cross_reference(self):
        """Test ATCC ID cross-referencing."""
        resolver = get_cellline_resolver()

        result = resolver.resolve("CVCL_0030")
        atcc_id = result['result']['atcc_id']

        assert atcc_id is not None, "Should have ATCC cross-reference"
        assert atcc_id.startswith('C'), "ATCC IDs typically start with C"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
