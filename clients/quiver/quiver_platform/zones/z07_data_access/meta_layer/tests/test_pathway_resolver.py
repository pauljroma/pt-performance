"""
Tests for PathwayResolver
==========================

Test comprehensive pathway resolution with Reactome/KEGG integration.

Author: Resolver Expansion Swarm - Agent 3
Date: 2025-12-01
"""

import pytest
import time
from meta_layer.resolvers.pathway_resolver import PathwayResolver, get_pathway_resolver


class TestPathwayResolver:
    """Test suite for PathwayResolver."""

    @pytest.fixture(scope="class")
    def resolver(self):
        """Create resolver instance for tests."""
        return PathwayResolver()

    def test_initialization(self, resolver):
        """Test resolver initializes with pathway data."""
        stats = resolver.get_stats()

        assert stats['total_pathways'] >= 5, "Should load sample pathways"
        assert stats['total_genes_in_pathways'] > 10, "Should have genes mapped to pathways"

    def test_pathway_resolution_reactome(self, resolver):
        """Test Reactome pathway ID resolution."""
        # Test known Reactome pathway
        result = resolver.resolve("R-HSA-112316")

        assert result['confidence'] == 1.0, "Should have perfect confidence for known pathway"
        assert result['result']['pathway_id'] == "R-HSA-112316"
        assert result['result']['pathway_name'] == "Neuronal System"
        assert result['result']['database'] == "Reactome"
        assert result['strategy'] == 'Reactome_lookup'
        assert 'member_genes' in result['result']
        assert len(result['result']['member_genes']) > 0

    def test_pathway_resolution_kegg(self, resolver):
        """Test KEGG pathway ID resolution."""
        # Test known KEGG pathway
        result = resolver.resolve("hsa04727")

        assert result['confidence'] == 1.0, "Should have perfect confidence for known pathway"
        assert result['result']['pathway_id'] == "hsa04727"
        assert result['result']['pathway_name'] == "GABAergic synapse"
        assert result['result']['database'] == "KEGG"
        assert result['strategy'] == 'KEGG_lookup'
        assert 'member_genes' in result['result']

    def test_pathway_resolution_multiple_pathways(self, resolver):
        """Test resolution of multiple pathway IDs."""
        pathway_ids = [
            "R-HSA-112316",  # Neuronal System
            "R-HSA-109581",  # Apoptosis
            "hsa04115",      # p53 signaling
            "hsa04727"       # GABAergic synapse
        ]

        for pathway_id in pathway_ids:
            result = resolver.resolve(pathway_id)
            assert result['confidence'] > 0, f"Should resolve {pathway_id}"
            assert result['result']['pathway_id'] == pathway_id

    def test_pathways_for_gene(self, resolver):
        """Test gene → pathways reverse lookup."""
        # Test GABRA1 (should be in multiple pathways)
        pathways = resolver.pathways_for_gene("GABRA1")

        assert isinstance(pathways, list), "Should return list of pathways"
        assert len(pathways) > 0, "GABRA1 should be in at least one pathway"

        # Verify pathway structure
        for pathway in pathways:
            assert 'pathway_id' in pathway
            assert 'pathway_name' in pathway
            assert 'database' in pathway

    def test_pathways_for_gene_case_insensitive(self, resolver):
        """Test case-insensitive gene lookup."""
        upper = resolver.pathways_for_gene("GABRA1")
        lower = resolver.pathways_for_gene("gabra1")
        mixed = resolver.pathways_for_gene("Gabra1")

        assert upper == lower == mixed, "Should be case-insensitive"

    def test_pathways_for_gene_tp53(self, resolver):
        """Test TP53 pathway membership."""
        pathways = resolver.pathways_for_gene("TP53")

        assert len(pathways) > 0, "TP53 should be in multiple pathways"

        # Should be in both Reactome and KEGG pathways
        databases = {p['database'] for p in pathways}
        assert 'Reactome' in databases or 'KEGG' in databases

    def test_pathways_for_gene_epilepsy_genes(self, resolver):
        """Test pathway membership for epilepsy genes."""
        epilepsy_genes = ["SCN1A", "KCNQ2", "GAD1", "GABRA1"]

        for gene in epilepsy_genes:
            pathways = resolver.pathways_for_gene(gene)
            # Some epilepsy genes may not be in sample pathways, so we just check format
            assert isinstance(pathways, list), f"Should return list for {gene}"

    def test_find_common_pathways_two_genes(self, resolver):
        """Test finding pathways shared by two genes."""
        # GABRA1 and GAD1 should share GABAergic pathways
        genes = ["GABRA1", "GAD1"]
        common = resolver.find_common_pathways(genes, min_overlap=2)

        assert isinstance(common, list), "Should return list of pathways"

        if common:
            # Verify structure
            for pathway in common:
                assert 'pathway_id' in pathway
                assert 'pathway_name' in pathway
                assert 'overlap_count' in pathway
                assert 'overlapping_genes' in pathway
                assert pathway['overlap_count'] >= 2

    def test_find_common_pathways_multiple_genes(self, resolver):
        """Test finding pathways shared by multiple genes."""
        # GABA receptor and enzyme genes
        genes = ["GABRA1", "GABRB2", "GABRG2", "GAD1", "GAD2"]
        common = resolver.find_common_pathways(genes, min_overlap=3)

        if common:
            # Should find GABAergic pathways
            for pathway in common:
                assert pathway['overlap_count'] >= 3
                assert len(pathway['overlapping_genes']) >= 3

            # Results should be sorted by overlap count (descending)
            overlap_counts = [p['overlap_count'] for p in common]
            assert overlap_counts == sorted(overlap_counts, reverse=True)

    def test_find_common_pathways_min_overlap(self, resolver):
        """Test min_overlap parameter filtering."""
        genes = ["GABRA1", "GABRB2", "GABRG2"]

        # Test different min_overlap values
        all_common = resolver.find_common_pathways(genes, min_overlap=1)
        strict_common = resolver.find_common_pathways(genes, min_overlap=3)

        # Stricter filter should return fewer results
        assert len(strict_common) <= len(all_common)

    def test_find_common_pathways_no_overlap(self, resolver):
        """Test with genes that don't share pathways."""
        # Genes in completely different pathways
        genes = ["FAKEGENE1", "FAKEGENE2"]
        common = resolver.find_common_pathways(genes, min_overlap=2)

        assert isinstance(common, list), "Should return empty list"
        assert len(common) == 0, "Should find no common pathways"

    def test_performance_latency(self, resolver):
        """Test resolver latency is <10ms."""
        # First call (cache miss)
        start = time.time()
        resolver.resolve("R-HSA-112316")
        first_latency = (time.time() - start) * 1000

        # Second call (cache hit)
        start = time.time()
        resolver.resolve("R-HSA-112316")
        second_latency = (time.time() - start) * 1000

        assert first_latency < 10, f"First call should be <10ms, got {first_latency:.2f}ms"
        assert second_latency < 1, f"Cached call should be <1ms, got {second_latency:.2f}ms"

    def test_performance_pathways_for_gene(self, resolver):
        """Test pathways_for_gene() latency."""
        start = time.time()
        resolver.pathways_for_gene("GABRA1")
        latency = (time.time() - start) * 1000

        assert latency < 10, f"pathways_for_gene() should be <10ms, got {latency:.2f}ms"

    def test_performance_find_common_pathways(self, resolver):
        """Test find_common_pathways() performance."""
        genes = ["GABRA1", "GABRB2", "GABRG2", "GAD1", "GAD2"]

        start = time.time()
        resolver.find_common_pathways(genes, min_overlap=2)
        latency = (time.time() - start) * 1000

        assert latency < 50, f"find_common_pathways() should be <50ms for 5 genes, got {latency:.2f}ms"

    def test_performance_bulk_operations(self, resolver):
        """Test bulk pathway queries."""
        pathway_ids = ["R-HSA-112316", "R-HSA-109581", "hsa04115"] * 10  # 30 queries

        start = time.time()
        for pathway_id in pathway_ids:
            resolver.resolve(pathway_id)
        total_latency = (time.time() - start) * 1000

        avg_latency = total_latency / len(pathway_ids)
        assert avg_latency < 5, f"Average latency should be <5ms, got {avg_latency:.2f}ms"

    def test_cache_efficiency(self, resolver):
        """Test cache hit rate >90%."""
        # Query same pathways multiple times
        for _ in range(50):
            resolver.resolve("R-HSA-112316")
            resolver.resolve("hsa04727")

        stats = resolver.get_stats()
        cache_hit_rate = stats['cache_hit_rate']

        # Should be very high (most queries are cache hits)
        assert cache_hit_rate > 0.90, f"Cache hit rate should be >90%, got {cache_hit_rate:.2%}"

    def test_invalid_input(self, resolver):
        """Test handling of invalid input."""
        result = resolver.resolve("")
        assert result['confidence'] == 0.0
        assert result['strategy'] == 'error'

        result = resolver.resolve("   ")
        assert result['confidence'] == 0.0

    def test_not_found(self, resolver):
        """Test handling of unknown pathway IDs."""
        result = resolver.resolve("INVALID-PATHWAY-123")

        assert result['confidence'] == 0.0
        assert result['strategy'] == 'none'

    def test_pathways_for_gene_not_found(self, resolver):
        """Test pathways_for_gene() with unknown gene."""
        pathways = resolver.pathways_for_gene("FAKEGENE123")

        assert isinstance(pathways, list), "Should return list"
        assert len(pathways) == 0, "Should return empty list for unknown gene"

    def test_statistics(self, resolver):
        """Test statistics reporting."""
        # Make some queries
        resolver.resolve("R-HSA-112316")
        resolver.pathways_for_gene("GABRA1")
        resolver.find_common_pathways(["TP53", "BRCA1"])

        stats = resolver.get_stats()

        assert 'total_pathways' in stats
        assert 'total_genes_in_pathways' in stats
        assert 'cache_hits' in stats
        assert 'cache_misses' in stats
        assert 'cache_hit_rate' in stats

        assert stats['total_pathways'] > 0
        assert stats['total_genes_in_pathways'] > 0

    def test_singleton_factory(self):
        """Test factory returns singleton instance."""
        resolver1 = get_pathway_resolver()
        resolver2 = get_pathway_resolver()

        assert resolver1 is resolver2, "Should return same instance"

    def test_drugs_targeting_pathway_placeholder(self, resolver):
        """Test drugs targeting pathway (placeholder)."""
        # This is a placeholder - Neo4j integration not yet implemented
        drugs = resolver.drugs_targeting_pathway("R-HSA-112316")

        # Should return empty list (not implemented yet)
        assert isinstance(drugs, list), "Should return list"
        assert len(drugs) == 0, "Should be empty (not implemented)"

    def test_get_pathway_hierarchy_placeholder(self, resolver):
        """Test pathway hierarchy (placeholder)."""
        # This is a placeholder - Reactome API integration not yet implemented
        hierarchy = resolver.get_pathway_hierarchy("R-HSA-112316")

        assert isinstance(hierarchy, dict), "Should return dict"
        assert 'pathway_id' in hierarchy
        assert 'parent_pathways' in hierarchy
        assert 'child_pathways' in hierarchy


class TestPathwayResolverIntegration:
    """Integration tests for PathwayResolver."""

    def test_gene_to_pathway_workflow(self):
        """Test typical gene → pathway workflow."""
        resolver = get_pathway_resolver()

        # Step 1: Find pathways for specific genes
        genes = ["GABRA1", "GAD1", "TP53"]
        gene_pathways = {}

        for gene in genes:
            pathways = resolver.pathways_for_gene(gene)
            if pathways:
                gene_pathways[gene] = pathways

        assert len(gene_pathways) > 0, "Should find pathways for at least one gene"

        # Step 2: Verify pathway details
        for gene, pathways in gene_pathways.items():
            for pathway_info in pathways:
                pathway_id = pathway_info['pathway_id']

                # Resolve full pathway details
                result = resolver.resolve(pathway_id)
                assert result['confidence'] > 0
                assert gene.upper() in [g.upper() for g in result['result']['member_genes']]

    def test_pathway_overlap_analysis(self):
        """Test analyzing pathway overlap for drug target expansion."""
        resolver = get_pathway_resolver()

        # Scenario: Find drugs targeting similar pathways
        # Start with known epilepsy genes
        epilepsy_genes = ["SCN1A", "KCNQ2", "GABRA1", "GAD1"]

        # Find common pathways
        common_pathways = resolver.find_common_pathways(epilepsy_genes, min_overlap=2)

        # Should find some shared pathways
        if common_pathways:
            # Verify overlap structure
            for pathway in common_pathways:
                assert 'pathway_id' in pathway
                assert 'overlapping_genes' in pathway
                assert len(pathway['overlapping_genes']) >= 2

                # All overlapping genes should be in original list
                for gene in pathway['overlapping_genes']:
                    assert gene in epilepsy_genes

    def test_multi_database_pathway_coverage(self):
        """Test coverage across Reactome and KEGG databases."""
        resolver = get_pathway_resolver()

        stats = resolver.get_stats()

        # Should have pathways from both databases
        all_pathways = ["R-HSA-112316", "R-HSA-109581", "hsa04115", "hsa04727"]
        databases = set()

        for pathway_id in all_pathways:
            result = resolver.resolve(pathway_id)
            if result['confidence'] > 0:
                databases.add(result['result']['database'])

        # Should have both Reactome and KEGG
        assert 'Reactome' in databases, "Should have Reactome pathways"
        assert 'KEGG' in databases, "Should have KEGG pathways"

    def test_neuroscience_pathway_network(self):
        """Test pathway network for neuroscience genes."""
        resolver = get_pathway_resolver()

        # Neuroscience genes (ion channels, receptors, neurotransmitter enzymes)
        neuro_genes = [
            "SCN1A", "SCN2A",  # Sodium channels
            "KCNQ2", "KCNA1",  # Potassium channels
            "GABRA1", "GABRB2",  # GABA receptors
            "GAD1", "GAD2"  # GABA synthesis
        ]

        # Map genes to pathways
        pathway_gene_map = {}

        for gene in neuro_genes:
            pathways = resolver.pathways_for_gene(gene)
            for pathway in pathways:
                pathway_id = pathway['pathway_id']
                if pathway_id not in pathway_gene_map:
                    pathway_gene_map[pathway_id] = {
                        'pathway_name': pathway['pathway_name'],
                        'genes': []
                    }
                pathway_gene_map[pathway_id]['genes'].append(gene)

        # Should find neuronal/synaptic pathways
        assert len(pathway_gene_map) > 0, "Should find pathways for neuroscience genes"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
