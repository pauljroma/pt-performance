"""
Tests for DiseaseResolver
==========================

Test comprehensive disease resolution with gene-disease associations.

Author: Resolver Expansion Swarm - Agent 4
Date: 2025-12-01
"""

import pytest
import time
from meta_layer.resolvers.disease_resolver import DiseaseResolver, get_disease_resolver


class TestDiseaseResolver:
    """Test suite for DiseaseResolver."""

    @pytest.fixture(scope="class")
    def resolver(self):
        """Create resolver instance for tests."""
        return DiseaseResolver()

    def test_initialization(self, resolver):
        """Test resolver initializes with data."""
        stats = resolver.get_stats()

        assert stats['total_diseases'] > 0, "Should load disease data"
        assert stats['total_genes_in_diseases'] > 0, "Should have gene-disease associations"

    def test_forward_resolution_epilepsy(self, resolver):
        """Test disease resolution for DOID:1826 Epilepsy."""
        result = resolver.resolve("DOID:1826")

        assert result['confidence'] > 0.9, "Should have high confidence for exact match"
        assert result['result']['disease_name'] == "Epilepsy"
        assert result['result']['disease_id'] == "DOID:1826"
        assert result['result']['mesh_id'] == "D004827"
        assert 'G40' in result['result']['icd10_codes']
        assert 'SCN1A' in result['result']['associated_genes']
        assert result['strategy'] == 'disease_ontology_lookup'

    def test_forward_resolution_dravet_syndrome(self, resolver):
        """Test resolution of Dravet syndrome."""
        result = resolver.resolve("DOID:0060169")

        assert result['confidence'] > 0.9
        assert result['result']['disease_name'] == "Dravet syndrome"
        assert 'SCN1A' in result['result']['associated_genes']
        assert 'SCN2A' in result['result']['associated_genes']

    def test_forward_resolution_alzheimers(self, resolver):
        """Test resolution of Alzheimer's disease."""
        result = resolver.resolve("DOID:14762")

        assert result['confidence'] > 0.9
        assert result['result']['disease_name'] == "Alzheimer's disease"
        assert result['result']['mesh_id'] == "D000544"
        assert 'APP' in result['result']['associated_genes']
        assert 'APOE' in result['result']['associated_genes']

    def test_diseases_for_gene_scn1a(self, resolver):
        """Test diseases associated with SCN1A."""
        diseases = resolver.diseases_for_gene("SCN1A")

        assert len(diseases) > 0, "SCN1A should be associated with diseases"

        disease_names = [d['disease_name'] for d in diseases]
        assert "Epilepsy" in disease_names
        assert "Dravet syndrome" in disease_names

    def test_diseases_for_gene_case_insensitive(self, resolver):
        """Test gene-disease lookup is case-insensitive."""
        diseases_upper = resolver.diseases_for_gene("SCN1A")
        diseases_lower = resolver.diseases_for_gene("scn1a")
        diseases_mixed = resolver.diseases_for_gene("Scn1a")

        assert len(diseases_upper) == len(diseases_lower)
        assert len(diseases_upper) == len(diseases_mixed)

    def test_diseases_for_gene_kcnq2(self, resolver):
        """Test diseases associated with KCNQ2."""
        diseases = resolver.diseases_for_gene("KCNQ2")

        assert len(diseases) > 0
        disease_names = [d['disease_name'] for d in diseases]
        assert "Epilepsy" in disease_names
        assert "Benign familial neonatal seizures" in disease_names

    def test_diseases_for_gene_apoe(self, resolver):
        """Test diseases associated with APOE."""
        diseases = resolver.diseases_for_gene("APOE")

        assert len(diseases) > 0
        disease_names = [d['disease_name'] for d in diseases]
        assert "Alzheimer's disease" in disease_names

    def test_diseases_for_gene_not_found(self, resolver):
        """Test handling of genes with no disease associations."""
        diseases = resolver.diseases_for_gene("FAKEGENE123")

        assert len(diseases) == 0, "Should return empty list for unknown genes"

    def test_performance_latency(self, resolver):
        """Test resolver latency is <10ms."""
        # First call (cache miss)
        start = time.time()
        resolver.resolve("DOID:1826")
        first_latency = (time.time() - start) * 1000

        # Second call (cache hit)
        start = time.time()
        resolver.resolve("DOID:1826")
        second_latency = (time.time() - start) * 1000

        assert first_latency < 10, f"First call should be <10ms, got {first_latency:.2f}ms"
        assert second_latency < 1, f"Cached call should be <1ms, got {second_latency:.2f}ms"

    def test_performance_bulk_queries(self, resolver):
        """Test performance with multiple disease lookups."""
        diseases = ["DOID:1826", "DOID:0060169", "DOID:0060170", "DOID:14762"]

        start = time.time()
        for disease_id in diseases:
            resolver.resolve(disease_id)
        total_latency = (time.time() - start) * 1000

        avg_latency = total_latency / len(diseases)
        assert avg_latency < 10, f"Average latency should be <10ms, got {avg_latency:.2f}ms"

    def test_cache_efficiency(self, resolver):
        """Test cache hit rate >90%."""
        # Query same disease multiple times
        diseases = ["DOID:1826"] * 50 + ["DOID:14762"] * 50  # 100 queries, 2 unique

        for disease_id in diseases:
            resolver.resolve(disease_id)

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
        """Test handling of unknown disease IDs."""
        result = resolver.resolve("DOID:9999999")

        assert result['confidence'] == 0.0
        assert result['strategy'] == 'none'
        assert 'not found' in result['metadata']['reason'].lower()

    def test_metadata_structure(self, resolver):
        """Test resolution result metadata structure."""
        result = resolver.resolve("DOID:1826")

        assert 'result' in result
        assert 'confidence' in result
        assert 'strategy' in result
        assert 'metadata' in result
        assert 'latency_ms' in result

        # Check result structure
        assert 'disease_id' in result['result']
        assert 'disease_name' in result['result']
        assert 'mesh_id' in result['result']
        assert 'icd10_codes' in result['result']
        assert 'associated_genes' in result['result']
        assert 'synonyms' in result['result']

    def test_statistics(self, resolver):
        """Test statistics reporting."""
        # Make some queries
        resolver.resolve("DOID:1826")
        resolver.resolve("DOID:14762")
        resolver.resolve("DOID:9999999")

        stats = resolver.get_stats()

        assert 'query_count' in stats
        assert 'error_count' in stats
        assert 'cache_hits' in stats
        assert 'cache_misses' in stats
        assert 'total_diseases' in stats
        assert 'total_genes_in_diseases' in stats

        assert stats['query_count'] >= 3

    def test_singleton_factory(self):
        """Test factory returns singleton instance."""
        resolver1 = get_disease_resolver()
        resolver2 = get_disease_resolver()

        assert resolver1 is resolver2, "Should return same instance"


class TestDiseaseResolverIntegration:
    """Integration tests for DiseaseResolver."""

    def test_epilepsy_gene_discovery_workflow(self):
        """Test workflow for discovering epilepsy-related genes."""
        resolver = get_disease_resolver()

        # Step 1: Resolve epilepsy disease
        result = resolver.resolve("DOID:1826")
        assert result['confidence'] > 0.9

        genes = result['result']['associated_genes']
        assert len(genes) > 0, "Epilepsy should have associated genes"

        # Step 2: Verify bidirectional mapping (gene → disease)
        for gene in genes:
            diseases = resolver.diseases_for_gene(gene)
            disease_ids = [d['disease_id'] for d in diseases]
            assert "DOID:1826" in disease_ids, f"{gene} should map back to Epilepsy"

    def test_scn1a_disease_spectrum(self):
        """Test discovering full disease spectrum for SCN1A."""
        resolver = get_disease_resolver()

        diseases = resolver.diseases_for_gene("SCN1A")
        assert len(diseases) >= 2, "SCN1A should be associated with multiple diseases"

        disease_names = [d['disease_name'] for d in diseases]

        # SCN1A is associated with both general epilepsy and Dravet syndrome
        assert "Epilepsy" in disease_names
        assert "Dravet syndrome" in disease_names

    def test_therapeutic_area_filtering(self):
        """Test filtering diseases by therapeutic area (neurological)."""
        resolver = get_disease_resolver()

        # Get all neurological genes
        neuro_genes = ["SCN1A", "KCNQ2", "GAD1", "KCNA3"]

        all_diseases = set()
        for gene in neuro_genes:
            diseases = resolver.diseases_for_gene(gene)
            for disease in diseases:
                all_diseases.add(disease['disease_id'])

        # Should find epilepsy-related diseases
        assert "DOID:1826" in all_diseases  # Epilepsy
        assert len(all_diseases) > 0

    def test_mesh_id_mapping(self):
        """Test MeSH ID is correctly mapped."""
        resolver = get_disease_resolver()

        result = resolver.resolve("DOID:1826")
        mesh_id = result['result']['mesh_id']

        assert mesh_id == "D004827", "Should map to correct MeSH ID"

    def test_icd10_codes(self):
        """Test ICD-10 codes are provided."""
        resolver = get_disease_resolver()

        result = resolver.resolve("DOID:1826")
        icd10_codes = result['result']['icd10_codes']

        assert len(icd10_codes) > 0, "Should have ICD-10 codes"
        assert any(code.startswith('G40') for code in icd10_codes), "Epilepsy should have G40 codes"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
