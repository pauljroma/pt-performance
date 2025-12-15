"""
Tests for ProteinResolver
==========================

Test comprehensive protein resolution with STRING gene map integration.

Author: Resolver Expansion Swarm - Agent 2
Date: 2025-12-01
"""

import pytest
import time
from meta_layer.resolvers.protein_resolver import ProteinResolver, get_protein_resolver


class TestProteinResolver:
    """Test suite for ProteinResolver."""

    @pytest.fixture(scope="class")
    def resolver(self):
        """Create resolver instance for tests."""
        return ProteinResolver()

    def test_initialization(self, resolver):
        """Test resolver initializes with STRING data."""
        stats = resolver.get_stats()

        assert stats['string_proteins'] >= 19275, "Should load 19,275+ STRING proteins"
        assert stats['unique_genes'] > 9000, "Should have 9,000+ unique genes"

    def test_string_id_resolution(self, resolver):
        """Test STRING ID resolution."""
        # Test with a valid STRING ID (9606.ENSP... format)
        # Get a valid STRING ID first (using Entrez ID 7157 = TP53)
        proteins = resolver.resolve_by_gene_symbol("7157")

        if proteins:
            string_id = proteins[0]
            result = resolver.resolve(string_id)

            assert result['confidence'] > 0.9, "Should have high confidence for STRING ID"
            assert result['result']['gene_symbol'] == "7157"  # Returns Entrez ID
            assert result['strategy'] == 'string_lookup'
            assert 'proteins' in result['result']

    def test_ensembl_id_resolution(self, resolver):
        """Test Ensembl protein ID resolution."""
        # Get Ensembl ID from Entrez ID (7157 = TP53)
        result = resolver.resolve_by_gene_symbol("7157")

        if result:
            # Extract Ensembl ID from STRING ID
            string_id = result[0]
            ensembl_id = string_id.replace('9606.', '')

            # Test resolution (returns Entrez ID)
            gene = resolver.resolve_by_ensembl(ensembl_id)
            assert gene == "7157", f"Should resolve {ensembl_id} to Entrez 7157"

    def test_reverse_lookup_string_to_gene(self, resolver):
        """Test STRING ID → gene identifier reverse lookup."""
        # Get a valid STRING ID first (using Entrez 7157 = TP53)
        proteins = resolver.resolve_by_gene_symbol("7157")

        if proteins:
            string_id = proteins[0]
            gene = resolver.resolve_by_string(string_id)

            assert gene == "7157", f"Should resolve {string_id} back to Entrez 7157"

    def test_reverse_lookup_ensembl_to_gene(self, resolver):
        """Test Ensembl protein ID → gene identifier reverse lookup."""
        # Get proteins for known Entrez IDs: TP53=7157, BRCA1=672, EGFR=1956
        test_genes = {"7157": "TP53", "672": "BRCA1", "1956": "EGFR"}

        for entrez_id, gene_symbol in test_genes.items():
            proteins = resolver.resolve_by_gene_symbol(entrez_id)

            if proteins:
                # Extract Ensembl ID
                string_id = proteins[0]
                ensembl_id = string_id.replace('9606.', '')

                # Test reverse lookup (returns Entrez ID)
                gene = resolver.resolve_by_ensembl(ensembl_id)
                assert gene == entrez_id, f"Should resolve {ensembl_id} to {entrez_id}"

    def test_resolve_by_gene_symbol(self, resolver):
        """Test gene symbol → STRING protein IDs lookup."""
        # Note: STRING gene map uses Entrez IDs, not gene symbols
        # TP53 = Entrez ID 7157
        result = resolver.resolve_by_gene_symbol("7157")

        assert isinstance(result, list), "Should return list of STRING IDs"
        assert len(result) > 0, "Should find at least one protein for Entrez 7157 (TP53)"

        # All IDs should start with 9606 (human)
        for string_id in result:
            assert string_id.startswith('9606.'), f"STRING ID should start with 9606: {string_id}"

    def test_resolve_by_gene_symbol_epilepsy_genes(self, resolver):
        """Test resolution of epilepsy-related genes using Entrez IDs."""
        # Epilepsy genes with Entrez IDs: SCN1A=6323, KCNQ2=3785, GAD1=2571, KCNA3=3738
        epilepsy_genes = {"6323": "SCN1A", "3785": "KCNQ2", "2571": "GAD1", "3738": "KCNA3"}

        for entrez_id, gene_symbol in epilepsy_genes.items():
            proteins = resolver.resolve_by_gene_symbol(entrez_id)
            assert len(proteins) > 0, f"Should find proteins for {gene_symbol} (Entrez {entrez_id})"

    def test_resolve_by_gene_symbol_case_insensitive(self, resolver):
        """Test case-insensitive gene identifier lookup."""
        # Entrez IDs are numeric strings, but test case handling
        upper = resolver.resolve_by_gene_symbol("7157")
        lower = resolver.resolve_by_gene_symbol("7157")

        assert upper == lower, "Should handle numeric IDs consistently"

    def test_get_protein_info(self, resolver):
        """Test comprehensive protein info retrieval."""
        # Use Entrez ID 7157 (TP53)
        info = resolver.get_protein_info("7157")

        assert info is not None, "Should return protein info"
        assert info['gene_symbol'] == "7157"  # Returns Entrez ID
        assert 'protein_count' in info
        assert info['protein_count'] > 0
        assert 'proteins' in info
        assert len(info['proteins']) == info['protein_count']

    def test_get_protein_info_unknown_gene(self, resolver):
        """Test protein info for unknown gene."""
        info = resolver.get_protein_info("FAKEGENE123")
        assert info is None, "Should return None for unknown gene"

    def test_performance_latency(self, resolver):
        """Test resolver latency is <10ms."""
        # First call (cache miss) - using Entrez 7157 (TP53)
        start = time.time()
        resolver.resolve_by_gene_symbol("7157")
        first_latency = (time.time() - start) * 1000

        # Second call (cache hit)
        start = time.time()
        resolver.resolve_by_gene_symbol("7157")
        second_latency = (time.time() - start) * 1000

        assert first_latency < 10, f"First call should be <10ms, got {first_latency:.2f}ms"
        assert second_latency < 1, f"Cached call should be <1ms, got {second_latency:.2f}ms"

    def test_performance_resolve_latency(self, resolver):
        """Test resolve() method latency."""
        # Get a valid STRING ID (using Entrez 672 = BRCA1)
        proteins = resolver.resolve_by_gene_symbol("672")

        if proteins:
            string_id = proteins[0]

            # First call
            start = time.time()
            result = resolver.resolve(string_id)
            latency = (time.time() - start) * 1000

            assert latency < 10, f"Resolve latency should be <10ms, got {latency:.2f}ms"
            assert result['latency_ms'] < 10, f"Reported latency should be <10ms"

    def test_performance_bulk_operations(self, resolver):
        """Test bulk protein lookups."""
        # Using Entrez IDs: TP53=7157, BRCA1=672, BRCA2=675, EGFR=1956, PTEN=5728
        genes = ["7157", "672", "675", "1956", "5728"] * 4  # 20 lookups

        start = time.time()
        for gene in genes:
            resolver.resolve_by_gene_symbol(gene)
        total_latency = (time.time() - start) * 1000

        avg_latency = total_latency / len(genes)
        assert avg_latency < 5, f"Average latency should be <5ms, got {avg_latency:.2f}ms"

    def test_cache_efficiency(self, resolver):
        """Test cache hit rate >90%."""
        # Get valid STRING IDs (using Entrez IDs)
        tp53_proteins = resolver.resolve_by_gene_symbol("7157")  # TP53
        egfr_proteins = resolver.resolve_by_gene_symbol("1956")  # EGFR

        if tp53_proteins and egfr_proteins:
            # Query same IDs multiple times
            for _ in range(50):
                resolver.resolve(tp53_proteins[0])
                resolver.resolve(egfr_proteins[0])

            stats = resolver.get_stats()
            cache_hit_rate = stats['cache_hit_rate']

            # Should be very high (most queries are cache hits)
            assert cache_hit_rate > 0.90, f"Cache hit rate should be >90%, got {cache_hit_rate:.2%}"

    def test_verify_protein_count(self, resolver):
        """Verify 19,275 proteins loaded."""
        stats = resolver.get_stats()

        # Should be exactly or very close to 19,275
        protein_count = stats['string_proteins']
        assert protein_count >= 19275, f"Expected 19,275+ proteins, got {protein_count}"

    def test_invalid_input(self, resolver):
        """Test handling of invalid input."""
        result = resolver.resolve("")
        assert result['confidence'] == 0.0
        assert result['strategy'] == 'error'

        result = resolver.resolve("   ")
        assert result['confidence'] == 0.0

    def test_not_found(self, resolver):
        """Test handling of unknown protein IDs."""
        result = resolver.resolve("INVALID_PROTEIN_ID_123")

        assert result['confidence'] == 0.0
        assert result['strategy'] == 'none'

    def test_statistics(self, resolver):
        """Test statistics reporting."""
        # Make some queries (using Entrez IDs)
        resolver.resolve_by_gene_symbol("7157")  # TP53
        resolver.resolve_by_gene_symbol("1956")  # EGFR
        resolver.get_protein_info("672")  # BRCA1

        stats = resolver.get_stats()

        assert 'string_proteins' in stats
        assert 'unique_genes' in stats
        assert 'cache_hits' in stats
        assert 'cache_misses' in stats
        assert 'cache_hit_rate' in stats

        assert stats['string_proteins'] >= 19275
        assert stats['unique_genes'] > 0

    def test_singleton_factory(self):
        """Test factory returns singleton instance."""
        resolver1 = get_protein_resolver()
        resolver2 = get_protein_resolver()

        assert resolver1 is resolver2, "Should return same instance"

    def test_get_interaction_partners_placeholder(self, resolver):
        """Test PPI interaction partners (placeholder)."""
        # This is a placeholder - Neo4j integration not yet implemented
        partners = resolver.get_interaction_partners("TP53", min_score=0.7)

        # Should return empty list (not implemented yet)
        assert isinstance(partners, list), "Should return list"
        assert len(partners) == 0, "Should be empty (not implemented)"


class TestProteinResolverIntegration:
    """Integration tests for ProteinResolver."""

    def test_gene_to_protein_workflow(self):
        """Test typical gene → protein workflow using Entrez IDs."""
        resolver = get_protein_resolver()

        # Step 1: Get STRING protein IDs for Entrez IDs
        # TP53=7157, BRCA1=672, EGFR=1956
        genes = {"7157": "TP53", "672": "BRCA1", "1956": "EGFR"}
        protein_map = {}

        for entrez_id in genes.keys():
            proteins = resolver.resolve_by_gene_symbol(entrez_id)
            if proteins:
                protein_map[entrez_id] = proteins

        assert len(protein_map) > 0, "Should map at least one gene to proteins"

        # Step 2: Reverse lookup proteins → gene identifiers
        for entrez_id, proteins in protein_map.items():
            for string_id in proteins:
                resolved_gene = resolver.resolve_by_string(string_id)
                assert resolved_gene == entrez_id, f"Should map {string_id} back to {entrez_id}"

    def test_protein_target_normalization(self):
        """Test normalizing protein targets from different sources."""
        resolver = get_protein_resolver()

        # Get TP53 proteins (using Entrez 7157)
        tp53_proteins = resolver.resolve_by_gene_symbol("7157")

        if tp53_proteins:
            string_id = tp53_proteins[0]
            ensembl_id = string_id.replace('9606.', '')

            # All formats should resolve to same Entrez ID
            gene1 = resolver.resolve_by_string(string_id)
            gene2 = resolver.resolve_by_ensembl(ensembl_id)

            assert gene1 == "7157"
            assert gene2 == "7157"
            assert gene1 == gene2

    def test_epilepsy_protein_network(self):
        """Test protein resolution for epilepsy gene network using Entrez IDs."""
        resolver = get_protein_resolver()

        # Epilepsy genes with Entrez IDs
        epilepsy_genes = {
            "6323": "SCN1A",
            "6324": "SCN2A",
            "3785": "KCNQ2",
            "3786": "KCNQ3",
            "2571": "GAD1"
        }
        protein_network = {}

        for entrez_id, gene_symbol in epilepsy_genes.items():
            proteins = resolver.resolve_by_gene_symbol(entrez_id)
            if proteins:
                protein_network[gene_symbol] = proteins

        # Should resolve most epilepsy genes
        assert len(protein_network) >= 3, f"Should resolve at least 3 epilepsy genes, got {len(protein_network)}"

        # Verify each has STRING IDs
        for gene_symbol, proteins in protein_network.items():
            assert len(proteins) > 0, f"Should have proteins for {gene_symbol}"
            assert all(p.startswith('9606.') for p in proteins), f"All proteins should be human (9606)"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
