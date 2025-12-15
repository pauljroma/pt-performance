"""
Tests for GeneNameResolver
===========================

Test comprehensive gene name resolution with HGNC cache integration.

Author: Resolver Expansion Swarm - Agent 1
Date: 2025-12-01
"""

import pytest
import time
from meta_layer.resolvers.gene_name_resolver import GeneNameResolver, get_gene_name_resolver


class TestGeneNameResolver:
    """Test suite for GeneNameResolver."""

    @pytest.fixture(scope="class")
    def resolver(self):
        """Create resolver instance for tests."""
        return GeneNameResolver()

    def test_initialization(self, resolver):
        """Test resolver initializes with data."""
        stats = resolver.get_stats()

        assert stats['hgnc_genes'] > 9000, "Should load 9,886+ HGNC genes"
        assert stats['string_proteins'] > 19000, "Should load 19,275+ STRING proteins"
        assert stats['total_symbols'] > 9000, "Should have 9,000+ total symbols"

    def test_forward_resolution_exact_match(self, resolver):
        """Test exact gene symbol resolution."""
        result = resolver.resolve("TP53")

        assert result['confidence'] > 0.9, "Should have high confidence for exact match"
        assert result['result']['hgnc_symbol'] == "TP53"
        assert result['result']['entrez_id'] == "7157"
        assert result['result']['uniprot_id'] == "P04637"
        assert result['strategy'] in ['hgnc_cache', 'string_map']

    def test_forward_resolution_case_insensitive(self, resolver):
        """Test case-insensitive gene symbol resolution."""
        result_upper = resolver.resolve("TP53")
        result_lower = resolver.resolve("tp53")
        result_mixed = resolver.resolve("Tp53")

        assert result_upper['result']['hgnc_symbol'] == "TP53"
        assert result_lower['result']['hgnc_symbol'] == "TP53"
        assert result_mixed['result']['hgnc_symbol'] == "TP53"

    def test_forward_resolution_epilepsy_genes(self, resolver):
        """Test resolution of epilepsy-related genes."""
        epilepsy_genes = ["SCN1A", "KCNQ2", "GAD1", "KCNA3"]

        for gene in epilepsy_genes:
            result = resolver.resolve(gene)
            assert result['confidence'] > 0, f"Should resolve {gene}"
            assert result['result']['hgnc_symbol'] == gene

    def test_reverse_resolution_by_entrez(self, resolver):
        """Test Entrez ID → gene symbol reverse lookup."""
        # TP53 = Entrez 7157
        symbol = resolver.resolve_by_entrez("7157")
        assert symbol == "TP53", "Should resolve Entrez 7157 to TP53"

        # BRCA1 = Entrez 672
        symbol = resolver.resolve_by_entrez("672")
        assert symbol == "BRCA1", "Should resolve Entrez 672 to BRCA1"

    def test_reverse_resolution_by_uniprot(self, resolver):
        """Test UniProt ID → gene symbol reverse lookup."""
        # TP53 = UniProt P04637
        symbol = resolver.resolve_by_uniprot("P04637")
        assert symbol == "TP53", "Should resolve UniProt P04637 to TP53"

        # Case insensitive
        symbol = resolver.resolve_by_uniprot("p04637")
        assert symbol == "TP53", "Should be case-insensitive"

    def test_reverse_resolution_by_ensembl(self, resolver):
        """Test Ensembl ID → gene symbol reverse lookup."""
        # Should resolve Ensembl protein IDs from STRING map
        # Note: Specific Ensembl IDs depend on STRING data
        result = resolver.resolve("TP53")

        if 'ensembl_id' in result['result'] and result['result']['ensembl_id']:
            ensembl_id = result['result']['ensembl_id']
            symbol = resolver.resolve_by_ensembl(ensembl_id)
            assert symbol == "TP53", f"Should resolve {ensembl_id} back to TP53"

    def test_bulk_resolve(self, resolver):
        """Test batch resolution of multiple genes."""
        genes = ["TP53", "EGFR", "BRCA1", "BRCA2", "PTEN"]
        results = resolver.bulk_resolve(genes)

        assert len(results) == len(genes), "Should return result for each gene"

        for gene in genes:
            assert gene in results, f"Should have result for {gene}"
            assert results[gene]['confidence'] > 0, f"Should resolve {gene}"

    def test_get_gene_info(self, resolver):
        """Test comprehensive gene info retrieval."""
        info = resolver.get_gene_info("TP53")

        assert info is not None, "Should return gene info"
        assert info['hgnc_symbol'] == "TP53"
        assert 'entrez_id' in info
        assert 'uniprot_id' in info

    def test_get_genes_by_uniprot_list(self, resolver):
        """Test batch UniProt → gene symbol lookup."""
        uniprot_ids = ["P04637", "P00533", "P38398"]  # TP53, EGFR, BRCA1
        results = resolver.get_genes_by_uniprot_list(uniprot_ids)

        assert len(results) == len(uniprot_ids)
        assert results["P04637"] == "TP53"
        assert results["P00533"] == "EGFR"
        assert results["P38398"] == "BRCA1"

    def test_performance_latency(self, resolver):
        """Test resolver latency is <10ms."""
        # First call (cache miss)
        start = time.time()
        resolver.resolve("TP53")
        first_latency = (time.time() - start) * 1000

        # Second call (cache hit)
        start = time.time()
        resolver.resolve("TP53")
        second_latency = (time.time() - start) * 1000

        assert first_latency < 10, f"First call should be <10ms, got {first_latency:.2f}ms"
        assert second_latency < 1, f"Cached call should be <1ms, got {second_latency:.2f}ms"

    def test_performance_bulk_latency(self, resolver):
        """Test bulk resolution performance."""
        genes = ["TP53", "EGFR", "BRCA1", "BRCA2", "PTEN"] * 4  # 20 genes

        start = time.time()
        resolver.bulk_resolve(genes)
        total_latency = (time.time() - start) * 1000

        avg_latency = total_latency / len(genes)
        assert avg_latency < 5, f"Average latency should be <5ms, got {avg_latency:.2f}ms"

    def test_cache_efficiency(self, resolver):
        """Test cache hit rate >90%."""
        genes = ["TP53"] * 50 + ["EGFR"] * 50  # 100 queries, only 2 unique

        # Resolve all
        for gene in genes:
            resolver.resolve(gene)

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
        """Test handling of unknown gene symbols."""
        result = resolver.resolve("FAKEGENE123")

        assert result['confidence'] == 0.0
        assert result['strategy'] == 'none'
        assert 'not found' in result['metadata']['reason'].lower()

    def test_statistics(self, resolver):
        """Test statistics reporting."""
        # Make some queries
        resolver.resolve("TP53")
        resolver.resolve("EGFR")
        resolver.resolve("FAKEGENE")

        stats = resolver.get_stats()

        assert 'query_count' in stats
        assert 'error_count' in stats
        assert 'cache_hits' in stats
        assert 'cache_misses' in stats
        assert 'hgnc_genes' in stats
        assert 'string_proteins' in stats

        assert stats['query_count'] >= 3

    def test_singleton_factory(self):
        """Test factory returns singleton instance."""
        resolver1 = get_gene_name_resolver()
        resolver2 = get_gene_name_resolver()

        assert resolver1 is resolver2, "Should return same instance"


class TestGeneNameResolverIntegration:
    """Integration tests for GeneNameResolver."""

    def test_moa_expansion_workflow(self):
        """Test typical MOA expansion workflow."""
        resolver = get_gene_name_resolver()

        # Step 1: Resolve gene symbols to UniProt IDs
        genes = ["SCN1A", "KCNQ2", "GAD1"]
        uniprot_ids = []

        for gene in genes:
            result = resolver.resolve(gene)
            if result['confidence'] > 0 and 'uniprot_id' in result['result']:
                uniprot_ids.append(result['result']['uniprot_id'])

        assert len(uniprot_ids) > 0, "Should resolve at least one gene to UniProt"

        # Step 2: Reverse lookup UniProt → gene
        for uniprot_id in uniprot_ids:
            gene = resolver.resolve_by_uniprot(uniprot_id)
            assert gene in genes, f"Should map {uniprot_id} back to original gene"

    def test_drug_target_normalization(self):
        """Test normalizing drug targets from Neo4j."""
        resolver = get_gene_name_resolver()

        # Simulate drug targets from Neo4j (mixed formats)
        targets = [
            "TP53",      # Already HGNC
            "7157",      # Entrez ID
            "P04637",    # UniProt
        ]

        normalized = set()

        for target in targets:
            # Try as gene symbol
            result = resolver.resolve(target)
            if result['confidence'] > 0:
                normalized.add(result['result']['hgnc_symbol'])
                continue

            # Try as Entrez ID
            gene = resolver.resolve_by_entrez(target)
            if gene:
                normalized.add(gene)
                continue

            # Try as UniProt ID
            gene = resolver.resolve_by_uniprot(target)
            if gene:
                normalized.add(gene)

        assert "TP53" in normalized, "Should normalize all formats to TP53"
        assert len(normalized) == 1, "All three formats should map to same gene"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
