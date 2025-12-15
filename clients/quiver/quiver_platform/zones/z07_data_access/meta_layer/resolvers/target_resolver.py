"""
TargetResolver - Gene/Protein Name Normalization
================================================

Normalizes gene and protein names across different databases and naming conventions.

Capabilities:
- Gene symbol normalization (SCN1A, KCNQ2, GAD1, KCNA3)
- Case-insensitive matching
- Synonym resolution (sodium channel → SCN1A)
- Protein name → gene mapping
- Ensembl, UniProt, HGNC cross-references

Performance: <5ms latency

Author: Meta Layer Swarm - Agent 6
Date: 2025-12-01
Version: 1.0.0
"""

import time
from typing import Dict, List, Optional, Any
from functools import lru_cache

from ..base_resolver import BaseResolver


class TargetResolver(BaseResolver):
    """
    Normalize gene/protein/target names.

    Usage:
        resolver = TargetResolver()
        result = resolver.resolve("SCN1A")
        # Returns: {'canonical_id': 'SCN1A', 'ensembl_id': 'ENSG...', ...}
    """

    def _initialize(self):
        """Initialize with gene/protein mappings."""
        # Known genes (epilepsy-focused for now)
        self.gene_mappings = {
            # Gene symbol → canonical info
            "scn1a": {
                "canonical_id": "SCN1A",
                "gene_name": "Sodium Voltage-Gated Channel Alpha Subunit 1",
                "ensembl_id": "ENSG00000144285",
                "uniprot_id": "P35498",
                "hgnc_id": "HGNC:10585",
                "aliases": ["NAC1", "GEFSP2", "SMEI"],
                "description": "Voltage-gated sodium channel"
            },
            "kcnq2": {
                "canonical_id": "KCNQ2",
                "gene_name": "Potassium Voltage-Gated Channel Subfamily Q Member 2",
                "ensembl_id": "ENSG00000075043",
                "uniprot_id": "O43526",
                "hgnc_id": "HGNC:6296",
                "aliases": ["BFNC", "EBN", "EIEE7"],
                "description": "Potassium channel"
            },
            "gad1": {
                "canonical_id": "GAD1",
                "gene_name": "Glutamate Decarboxylase 1",
                "ensembl_id": "ENSG00000128683",
                "uniprot_id": "Q99259",
                "hgnc_id": "HGNC:4092",
                "aliases": ["GAD67"],
                "description": "GABA synthesis enzyme"
            },
            "kcna3": {
                "canonical_id": "KCNA3",
                "gene_name": "Potassium Voltage-Gated Channel Subfamily A Member 3",
                "ensembl_id": "ENSG00000177424",
                "uniprot_id": "P22001",
                "hgnc_id": "HGNC:6220",
                "aliases": ["HGK5", "HLK3", "KV1.3"],
                "description": "Potassium channel"
            },
            "scn2a": {
                "canonical_id": "SCN2A",
                "gene_name": "Sodium Voltage-Gated Channel Alpha Subunit 2",
                "ensembl_id": "ENSG00000136531",
                "uniprot_id": "Q99250",
                "hgnc_id": "HGNC:10588",
                "aliases": ["EIEE11", "GEFSP3"],
                "description": "Voltage-gated sodium channel"
            },
            "gabrg2": {
                "canonical_id": "GABRG2",
                "gene_name": "Gamma-Aminobutyric Acid Type A Receptor Subunit Gamma2",
                "ensembl_id": "ENSG00000113327",
                "uniprot_id": "P18507",
                "hgnc_id": "HGNC:4087",
                "aliases": ["CAE2", "ECA2", "GEFSP3"],
                "description": "GABA-A receptor"
            }
        }

        # Descriptive names → gene mappings
        self.descriptive_mappings = {
            "sodium channel": "SCN1A",
            "voltage-gated sodium channel": "SCN1A",
            "nav1.1": "SCN1A",
            "potassium channel": "KCNQ2",
            "voltage-gated potassium channel": "KCNQ2",
            "kv7.2": "KCNQ2",
            "gaba": "GAD1",
            "gabaergic": "GAD1",
            "glutamate decarboxylase": "GAD1",
            "gad67": "GAD1",
        }

        self.logger.info(f"TargetResolver initialized: "
                        f"{len(self.gene_mappings)} genes, "
                        f"{len(self.descriptive_mappings)} descriptive mappings")

    def resolve(self, query: str, **kwargs) -> Dict[str, Any]:
        """
        Resolve gene/protein name to canonical form.

        Args:
            query: Gene/protein name (e.g., "SCN1A", "sodium channel")
            **kwargs: Additional parameters

        Returns:
            {
                'result': {
                    'canonical_id': 'SCN1A',
                    'gene_name': 'Sodium Voltage-Gated...',
                    'ensembl_id': 'ENSG00000144285',
                    'uniprot_id': 'P35498',
                    ...
                },
                'confidence': 0.0-1.0,
                'strategy': 'exact'|'alias'|'descriptive'|'none',
                'metadata': {...}
            }
        """
        start_time = time.time()

        if not self.validate(query):
            return self._error_result(query, "Invalid query")

        query_lower = query.strip().lower()

        # Strategy 1: Exact match on gene symbol
        if query_lower in self.gene_mappings:
            gene_info = self.gene_mappings[query_lower]
            result = self._format_success(gene_info, 1.0, 'exact')

        # Strategy 2: Check aliases
        elif alias_match := self._try_alias_match(query_lower):
            gene_info = self.gene_mappings[alias_match]
            result = self._format_success(gene_info, 0.95, 'alias')

        # Strategy 3: Descriptive name
        elif query_lower in self.descriptive_mappings:
            canonical = self.descriptive_mappings[query_lower]
            gene_info = self.gene_mappings[canonical.lower()]
            result = self._format_success(gene_info, 0.90, 'descriptive')

        else:
            # Not found
            result = self._empty_result(query, "Gene not found in database")

        # Record metrics
        latency_ms = (time.time() - start_time) * 1000
        self._record_query(latency_ms, success=result['confidence'] > 0.0)
        result['latency_ms'] = latency_ms

        return result

    def _try_alias_match(self, query: str) -> Optional[str]:
        """Check if query matches any gene alias."""
        for gene_id, gene_info in self.gene_mappings.items():
            aliases = [a.lower() for a in gene_info.get('aliases', [])]
            if query in aliases:
                return gene_id
        return None

    def _format_success(
        self,
        gene_info: Dict[str, Any],
        confidence: float,
        strategy: str
    ) -> Dict[str, Any]:
        """Format successful resolution."""
        return {
            'result': gene_info,
            'confidence': confidence,
            'strategy': strategy,
            'metadata': {
                'canonical_id': gene_info['canonical_id'],
                'gene_name': gene_info['gene_name']
            }
        }

    def get_stats(self) -> Dict[str, Any]:
        """Return resolver statistics."""
        return {
            **self.get_base_stats(),
            'total_genes': len(self.gene_mappings),
            'total_mappings': len(self.descriptive_mappings)
        }


# Singleton instance
_resolver_instance = None


def get_target_resolver() -> TargetResolver:
    """
    Get singleton TargetResolver instance.

    Usage:
        resolver = get_target_resolver()
        result = resolver.resolve("SCN1A")
    """
    global _resolver_instance
    if _resolver_instance is None:
        _resolver_instance = TargetResolver()
    return _resolver_instance
