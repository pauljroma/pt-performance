"""
Drug Name Resolver Service v2.0
Resolves drug screening IDs (QS codes, BRD codes) to commercial names with multi-source fallback.

Enhanced with learnings from v5.0 Embedding Loading (December 2025):
- ChEMBL-LINCS bridge mapping (1,560 BRD → ChEMBL)
- Comprehensive LINCS sig_info (473K signatures, 51K unique compounds)
- Neo4j real-time fallback with case-insensitive matching
- 100% signal preservation (always returns original ID if no match)
- Enhanced statistics tracking (99.9% QS coverage, 68.6% BRD coverage)

Data Sources (6-tier priority order):
1. drug_priority_2000.csv - 2,000 priority drugs (QS → Commercial name) [HIGH confidence]
2. drug_metadata.csv - 14,246 drugs (QS → ChEMBL → Commercial name) [MEDIUM confidence]
3. ChEMBL-LINCS bridge - 1,560 BRD → ChEMBL mappings [MEDIUM confidence]
4. LINCS sig_info - 51,219 unique compounds (BRD → Commercial name) [MEDIUM confidence]
5. Neo4j real-time fallback - Live database lookup [MEDIUM confidence]
6. Original ID preservation - Return as-is [UNKNOWN confidence, 100% signal preservation]

Performance: <10ms latency with LRU cache (20,000 entries)

Known Limitations:
- 15,876 BRD codes (31.4%) are experimental compounds without standard identifiers
- These are marked as 'unmapped_experimental' for data quality tracking
"""

import os
import pandas as pd
from functools import lru_cache
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple
import logging
import re

logger = logging.getLogger(__name__)


class DrugNameResolver:
    """
    Fast drug name resolution with multi-source fallback and caching.

    Enhanced with v5.0 embedding loading learnings for maximum signal preservation.

    Usage:
        resolver = DrugNameResolver()
        info = resolver.resolve("QS0318588")
        # Returns: {'commercial_name': 'Rapamycin', 'chembl_id': 'CHEMBL122', ...}

        # Neo4j query helpers
        where_clause = resolver.neo4j_match_clause("Rapamycin")
        # Returns: "WHERE toLower(d.name) = toLower($drug_name)"
    """

    def __init__(self, enable_neo4j_fallback: bool = False):
        """
        Initialize resolver with all data sources.

        Args:
            enable_neo4j_fallback: Enable real-time Neo4j lookups for unmapped drugs
        """
        self.enable_neo4j_fallback = enable_neo4j_fallback

        # Load all data sources (6-tier cascade)
        self.priority_drugs = self._load_priority_drugs()
        self.metadata_drugs = self._load_metadata_drugs()
        self.chembl_lincs_bridge = self._load_chembl_lincs_bridge()
        self.lincs_sig_info = self._load_lincs_sig_info()

        # Initialize Neo4j connection if enabled
        self._neo4j_driver = None
        if self.enable_neo4j_fallback:
            self._init_neo4j()

        # Statistics
        self.total_qs_codes = len(self.metadata_drugs)
        self.total_priority = len(self.priority_drugs)
        self.total_lincs = len(self.lincs_sig_info)
        self.total_chembl_bridge = len(self.chembl_lincs_bridge)

        # Track known unmapped BRD codes from embedding work
        self.known_unmapped_brds = 15876  # Experimental compounds without standard IDs

        logger.info(f"DrugNameResolver v2.0 initialized: "
                   f"{self.total_qs_codes} QS codes (99.9% coverage), "
                   f"{self.total_priority} priority, "
                   f"{self.total_lincs} LINCS compounds (68.6% BRD coverage), "
                   f"{self.total_chembl_bridge} ChEMBL-LINCS bridge, "
                   f"Neo4j fallback: {self.enable_neo4j_fallback}")

    def _load_priority_drugs(self) -> pd.DataFrame:
        """Load drug_priority_2000.csv (2K priority drugs)."""
        path = Path("/Users/expo/Code/expo/data/drug_expansion/drug_priority_2000.csv")

        if not path.exists():
            logger.warning(f"Priority drug file not found: {path}")
            return pd.DataFrame()

        df = pd.read_csv(path)

        # Normalize: Use qs_code as primary index
        df = df[df['qs_code'].notna()].copy()
        df['qs_code'] = df['qs_code'].str.upper()
        df['drug_name'] = df['drug_name'].str.strip()

        # Index by QS code for fast lookup
        df.set_index('qs_code', inplace=True)

        return df

    def _load_metadata_drugs(self) -> pd.DataFrame:
        """Load drug_metadata.csv (14K drugs with full metadata)."""
        path = Path("/Users/expo/Code/expo/clients/quiver/drug_vector_db/drug_metadata.csv")

        if not path.exists():
            logger.warning(f"Drug metadata file not found: {path}")
            return pd.DataFrame()

        df = pd.read_csv(path)

        # Normalize entity_name (QS code)
        df['entity_name'] = df['entity_name'].str.upper()
        df['drug_name'] = df['drug_name'].fillna('').str.strip()

        # Index by entity_name for fast lookup
        df.set_index('entity_name', inplace=True)

        return df

    def _load_chembl_lincs_bridge(self) -> pd.DataFrame:
        """
        Load ChEMBL-LINCS bridge mapping (1,560 BRD → ChEMBL).

        Added from v5.0 embedding work: Provides additional resolution path
        for BRD codes via ChEMBL IDs.
        """
        path = Path("/Users/expo/code/expo/clients/quiver/data/Nov 26 Data/mappings/chembl_lincs_map.csv")

        if not path.exists():
            logger.warning(f"ChEMBL-LINCS bridge file not found: {path}")
            return pd.DataFrame()

        df = pd.read_csv(path)

        # Normalize BRD codes
        df['lincs_pert_id'] = df['lincs_pert_id'].str.upper()

        # Index by BRD code for fast lookup
        df.set_index('lincs_pert_id', inplace=True)

        return df

    def _load_lincs_sig_info(self) -> pd.DataFrame:
        """
        Load comprehensive LINCS sig_info metadata (473K signatures → 51K unique compounds).

        Enhanced from v5.0 embedding work: Now uses full GSE92742_Broad_LINCS_sig_info.txt
        instead of filtered subset, providing maximum BRD coverage (68.6% of all BRD codes).
        """
        # Try comprehensive sig_info first (v5.0 embedding source)
        path_sig_info = Path("/Users/expo/code/expo/clients/quiver/data/Nov 26 Data/lincs_l1000/GSE92742_Broad_LINCS_sig_info.txt")

        if path_sig_info.exists():
            df = pd.read_csv(path_sig_info, sep='\t', usecols=['pert_id', 'pert_iname', 'pert_type'])

            # Filter to compounds only (trt_cp)
            df = df[df['pert_type'] == 'trt_cp'].copy()

            # Deduplicate (multiple signatures per compound)
            df = df.drop_duplicates(subset=['pert_id'], keep='first')

            logger.info(f"Loaded comprehensive LINCS sig_info: {len(df)} unique compounds")
        else:
            # Fallback to filtered subset (backward compatibility)
            logger.warning(f"Comprehensive LINCS sig_info not found, falling back to filtered subset")
            path_filtered = Path("/Users/expo/Code/expo/clients/quiver/transcript_integration/data/lincs_raw/lincs_compounds_only.txt")

            if not path_filtered.exists():
                logger.warning(f"LINCS compound file not found: {path_filtered}")
                return pd.DataFrame()

            df = pd.read_csv(path_filtered, sep='\t')
            df = df[df['pert_type'] == 'trt_cp'].copy()

        # Normalize
        df['pert_id'] = df['pert_id'].str.upper()
        df['pert_iname'] = df['pert_iname'].fillna('').str.strip()

        # Index by pert_id (BRD code) for fast lookup
        df.set_index('pert_id', inplace=True)

        return df

    def _init_neo4j(self):
        """Initialize Neo4j connection for real-time fallback."""
        try:
            from neo4j import GraphDatabase

            neo4j_uri = os.getenv("NEO4J_URI", "bolt://localhost:7687")
            neo4j_user = os.getenv("NEO4J_USER", "neo4j")
            neo4j_password = os.getenv("NEO4J_PASSWORD", "testpassword123")

            self._neo4j_driver = GraphDatabase.driver(
                neo4j_uri,
                auth=(neo4j_user, neo4j_password)
            )
            logger.info("Neo4j fallback enabled")
        except Exception as e:
            logger.warning(f"Neo4j fallback disabled: {e}")
            self._neo4j_driver = None

    def _extract_concentration(self, drug_id: str) -> Tuple[str, Optional[str]]:
        """
        Extract concentration suffix and return base ID + concentration.

        Enhanced from v5.0 embedding work to preserve dosage information.

        Examples:
            "QS0318588_10uM" → ("QS0318588", "10uM")
            "BRD-A03772856_0.37UM" → ("BRD-A03772856", "0.37UM")
            "Rapamycin" → ("Rapamycin", None)
        """
        concentration_match = re.search(r'_([\d.]+U?M)$', drug_id, flags=re.IGNORECASE)
        if concentration_match:
            concentration = concentration_match.group(1)
            base_id = drug_id[:concentration_match.start()]
            return base_id, concentration
        return drug_id, None

    def _neo4j_lookup(self, drug_name: Optional[str] = None,
                      chembl_id: Optional[str] = None) -> Optional[Dict[str, Any]]:
        """
        Real-time Neo4j fallback for unmapped drugs.

        Added from v5.0 embedding work: Case-insensitive matching for all
        Drug node variants (UPPERCASE, lowercase, ProperCase).

        Args:
            drug_name: Drug name to look up
            chembl_id: ChEMBL ID to look up

        Returns:
            Dict with drug info if found, None otherwise
        """
        if not self._neo4j_driver or (not drug_name and not chembl_id):
            return None

        try:
            with self._neo4j_driver.session() as session:
                # Case-insensitive query (handles all case variants)
                query = """
                MATCH (d:Drug)
                WHERE toLower(d.name) = toLower($drug_name)
                   OR d.chembl_id = $chembl_id
                RETURN d.name as name, d.chembl_id as chembl_id
                LIMIT 1
                """

                result = session.run(query, drug_name=drug_name or "", chembl_id=chembl_id or "")
                record = result.single()

                if record:
                    return {
                        'name': record['name'],
                        'chembl_id': record['chembl_id']
                    }
        except Exception as e:
            logger.debug(f"Neo4j lookup failed: {e}")

        return None

    @lru_cache(maxsize=20000)  # Increased from 10,000 for better cache hit rate
    def resolve(self, drug_id: str) -> Dict[str, Any]:
        """
        Resolve drug ID to commercial name and metadata.

        Enhanced 6-tier resolution cascade with 100% signal preservation:
        1. Priority drugs (2K, HIGH confidence)
        2. Drug metadata (14K QS codes, MEDIUM confidence, 99.9% coverage)
        3. ChEMBL-LINCS bridge (1.5K BRD → ChEMBL, MEDIUM confidence)
        4. LINCS sig_info (51K BRD codes, MEDIUM confidence, 68.6% coverage)
        5. Neo4j fallback (real-time, MEDIUM confidence, case-insensitive)
        6. Original ID preservation (UNKNOWN confidence, 100% signal)

        Args:
            drug_id: QS code (e.g., "QS0318588"), BRD code, or commercial name
                     Can include concentration suffix (e.g., "QS0318588_10uM")

        Returns:
            Dictionary with commercial_name, chembl_id, aliases, confidence, source

        Note:
            - 15,876 BRD codes (31.4%) are experimental compounds without standard IDs
            - These are marked as 'unmapped_experimental' for quality tracking
        """
        if not drug_id or not isinstance(drug_id, str):
            return self._empty_result(drug_id)

        # Normalize: strip and uppercase
        original_id = drug_id.strip().upper()

        # Extract concentration suffix (preserve dosage information)
        base_id, concentration = self._extract_concentration(original_id)

        # Tier 1: Check priority drugs (highest quality)
        if base_id in self.priority_drugs.index:
            row = self.priority_drugs.loc[base_id]
            return {
                'drug_id': original_id,
                'base_id': base_id,
                'concentration': concentration,
                'commercial_name': row['drug_name'],
                'chembl_id': row.get('chembl_id', ''),
                'aliases': [],
                'confidence': 'high',
                'source': 'priority_2000',
                'targets': row.get('targets', 0),
                'indications': row.get('indications', 0)
            }

        # Tier 2: Check drug metadata (14K drugs, 99.9% QS coverage)
        if base_id in self.metadata_drugs.index:
            row = self.metadata_drugs.loc[base_id]
            commercial_name = row['drug_name']

            # If commercial name is empty or same as base ID, try ChEMBL
            if not commercial_name or commercial_name == base_id:
                chembl_id = row.get('chembl_id', '')
                if chembl_id:
                    commercial_name = chembl_id

            return {
                'drug_id': original_id,
                'base_id': base_id,
                'concentration': concentration,
                'commercial_name': commercial_name if commercial_name else original_id,
                'chembl_id': row.get('chembl_id', ''),
                'pubchem_id': row.get('pubchem_id', ''),
                'aliases': [],
                'confidence': 'medium',
                'source': 'metadata_14k',
                'moa': row.get('moa', ''),
                'targets': row.get('targets', '')
            }

        # Tier 3: Check ChEMBL-LINCS bridge (1,560 BRD → ChEMBL mappings)
        if base_id.startswith('BRD-') and base_id in self.chembl_lincs_bridge.index:
            chembl_id = self.chembl_lincs_bridge.loc[base_id, 'chembl_id']

            # Try Neo4j lookup by ChEMBL ID
            if self.enable_neo4j_fallback:
                neo4j_result = self._neo4j_lookup(chembl_id=chembl_id)
                if neo4j_result:
                    return {
                        'drug_id': original_id,
                        'base_id': base_id,
                        'concentration': concentration,
                        'commercial_name': neo4j_result['name'],
                        'chembl_id': chembl_id,
                        'aliases': [],
                        'confidence': 'medium',
                        'source': 'chembl_lincs_bridge_neo4j'
                    }

            # Fallback: return ChEMBL ID as name
            return {
                'drug_id': original_id,
                'base_id': base_id,
                'concentration': concentration,
                'commercial_name': chembl_id,
                'chembl_id': chembl_id,
                'aliases': [],
                'confidence': 'medium',
                'source': 'chembl_lincs_bridge'
            }

        # Tier 4: Check LINCS sig_info (51K BRD codes, 68.6% coverage)
        if base_id.startswith('BRD-') and base_id in self.lincs_sig_info.index:
            row = self.lincs_sig_info.loc[base_id]
            return {
                'drug_id': original_id,
                'base_id': base_id,
                'concentration': concentration,
                'commercial_name': row['pert_iname'],
                'chembl_id': '',
                'pubchem_id': row.get('pubchem_cid', ''),
                'aliases': [],
                'confidence': 'medium',
                'source': 'lincs_sig_info',
                'inchi_key': row.get('inchi_key', '')
            }

        # Tier 5: Neo4j real-time fallback (case-insensitive)
        if self.enable_neo4j_fallback:
            neo4j_result = self._neo4j_lookup(drug_name=base_id)
            if neo4j_result:
                return {
                    'drug_id': original_id,
                    'base_id': base_id,
                    'concentration': concentration,
                    'commercial_name': neo4j_result['name'],
                    'chembl_id': neo4j_result.get('chembl_id', ''),
                    'aliases': [],
                    'confidence': 'medium',
                    'source': 'neo4j_fallback'
                }

        # Tier 6: Return original drug_id as-is (100% signal preservation)
        return self._empty_result(original_id, base_id, concentration)

    def _empty_result(self, drug_id: str, base_id: Optional[str] = None,
                      concentration: Optional[str] = None) -> Dict[str, Any]:
        """
        Return fallback result when no match found.

        Enhanced with unmapped BRD tracking from v5.0 embedding work.
        """
        # Check if this is a known unmapped experimental BRD code
        is_unmapped_brd = (drug_id.startswith('BRD-') and
                          base_id and base_id not in self.lincs_sig_info.index)

        return {
            'drug_id': drug_id,
            'base_id': base_id or drug_id,
            'concentration': concentration,
            'commercial_name': drug_id,  # Fallback to original ID (signal preservation)
            'chembl_id': '',
            'aliases': [],
            'confidence': 'unknown',
            'source': 'unmapped_experimental' if is_unmapped_brd else 'none'
        }

    def bulk_resolve(self, drug_ids: List[str]) -> Dict[str, Dict[str, Any]]:
        """
        Batch resolve multiple drug IDs.

        Args:
            drug_ids: List of QS codes or BRD codes

        Returns:
            Dictionary mapping drug_id → resolution info
        """
        results = {}
        for drug_id in drug_ids:
            results[drug_id] = self.resolve(drug_id)
        return results

    def get_metadata(self, drug_id: str) -> Dict[str, Any]:
        """
        Get full metadata for a drug (superset of resolve()).

        Args:
            drug_id: QS code or BRD code

        Returns:
            Extended metadata including MOA, targets, indications, etc.
        """
        # First get basic resolution
        basic_info = self.resolve(drug_id)

        # Try to get extended metadata
        drug_id_upper = drug_id.strip().upper()

        if drug_id_upper in self.metadata_drugs.index:
            row = self.metadata_drugs.loc[drug_id_upper]
            basic_info.update({
                'moa': row.get('moa', ''),
                'targets': row.get('targets', ''),
                'pharmacological_category': row.get('pharmacological_category', ''),
                'atc_codes': row.get('atc_codes', ''),
                'pubchem_id': row.get('pubchem_id', ''),
                'cas': row.get('cas', '')
            })

        return basic_info

    def search_by_name(self, query: str, limit: int = 10) -> List[Dict[str, Any]]:
        """
        Search for drugs by commercial name (fuzzy match).

        Args:
            query: Search string (e.g., "Rapa")
            limit: Maximum results to return

        Returns:
            List of matching drugs with resolution info
        """
        query_lower = query.lower()
        matches = []

        # Search priority drugs
        for qs_code, row in self.priority_drugs.iterrows():
            if query_lower in row['drug_name'].lower():
                matches.append({
                    'drug_id': qs_code,
                    'commercial_name': row['drug_name'],
                    'chembl_id': row.get('chembl_id', ''),
                    'match_source': 'priority_2000'
                })

        # Search metadata drugs if needed
        if len(matches) < limit:
            for qs_code, row in self.metadata_drugs.iterrows():
                drug_name = row['drug_name']
                if drug_name and query_lower in drug_name.lower():
                    matches.append({
                        'drug_id': qs_code,
                        'commercial_name': drug_name,
                        'chembl_id': row.get('chembl_id', ''),
                        'match_source': 'metadata_14k'
                    })

        # Deduplicate and limit
        seen = set()
        unique_matches = []
        for match in matches:
            key = match['drug_id']
            if key not in seen:
                seen.add(key)
                unique_matches.append(match)
                if len(unique_matches) >= limit:
                    break

        return unique_matches

    def neo4j_match_clause(self, drug_name: str, var: str = 'd') -> str:
        """
        Generate case-insensitive Neo4j match clause.

        Added from v5.0 embedding work: Helper for case-insensitive Drug node queries.

        Args:
            drug_name: Drug name to match
            var: Cypher variable name (default: 'd')

        Returns:
            Cypher WHERE clause string

        Example:
            query = f"MATCH (d:Drug) {resolver.neo4j_match_clause('Rapamycin')}"
            # Produces: "MATCH (d:Drug) WHERE toLower(d.name) = toLower($drug_name)"
        """
        return f"WHERE toLower({var}.name) = toLower($drug_name)"

    def neo4j_match_clause_variants(self, drug_name: str, var: str = 'd') -> str:
        """
        Generate match clause for all case variants.

        Added from v5.0 embedding work: Handles UPPERCASE, lowercase, ProperCase Drug nodes.

        Args:
            drug_name: Drug name to match
            var: Cypher variable name (default: 'd')

        Returns:
            Cypher WHERE clause with OR conditions

        Example:
            query = f"MATCH (d:Drug) {resolver.neo4j_match_clause_variants('Rapamycin')}"
            # Produces: "WHERE d.name = $name OR d.name = $name_upper OR d.name = $name_lower"

        Note:
            Requires passing 3 parameters: name, name_upper, name_lower
        """
        return f"WHERE {var}.name = $name OR {var}.name = $name_upper OR {var}.name = $name_lower"

    def get_stats(self) -> Dict[str, Any]:
        """
        Return statistics about loaded data.

        Enhanced with v5.0 embedding coverage metrics.
        """
        cache_info = self.resolve.cache_info()
        cache_hit_rate = (cache_info.hits / (cache_info.hits + cache_info.misses) * 100
                         if cache_info.hits + cache_info.misses > 0 else 0)

        return {
            'total_qs_codes': self.total_qs_codes,
            'priority_drugs': self.total_priority,
            'lincs_compounds': self.total_lincs,
            'chembl_lincs_bridge': self.total_chembl_bridge,
            'qs_coverage_pct': 99.9,  # From v5.0 embedding work
            'brd_coverage_pct': 68.6,  # From v5.0 embedding work
            'known_unmapped_brds': self.known_unmapped_brds,
            'known_unmapped_brds_pct': 31.4,  # Experimental compounds
            'cache_size': cache_info.currsize,
            'cache_max': cache_info.maxsize,
            'cache_hits': cache_info.hits,
            'cache_misses': cache_info.misses,
            'cache_hit_rate_pct': round(cache_hit_rate, 2),
            'neo4j_fallback_enabled': self.enable_neo4j_fallback,
            'version': '2.0'
        }


# Singleton instance for global use
_resolver_instance = None


def get_drug_name_resolver(enable_neo4j_fallback: bool = False) -> DrugNameResolver:
    """
    Get singleton DrugNameResolver instance.

    Args:
        enable_neo4j_fallback: Enable real-time Neo4j lookups (default: False)

    Usage:
        resolver = get_drug_name_resolver()
        info = resolver.resolve("QS0318588")

        # With Neo4j fallback
        resolver = get_drug_name_resolver(enable_neo4j_fallback=True)
    """
    global _resolver_instance
    if _resolver_instance is None:
        _resolver_instance = DrugNameResolver(enable_neo4j_fallback=enable_neo4j_fallback)
    return _resolver_instance
