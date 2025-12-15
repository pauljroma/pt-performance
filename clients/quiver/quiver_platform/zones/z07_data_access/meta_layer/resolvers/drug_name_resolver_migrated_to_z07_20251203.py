"""
Drug Name Resolver Service v2.1
Enhanced for MOA Expansion Support

NEW in v2.1 (December 2025 - MOA Expansion):
- Reverse mapping: CHEMBL ID → Drug name (for BBB dataset integration)
- PLATINUM drug embedding index: 2,327 EP drug mappings (Drug name ↔ CHEMBL)
- Bidirectional lookups: resolve_by_chembl(), resolve_by_drug_name()
- Enhanced for BBB/ADME prediction expansion workflows

PRESERVED from v2.0 (100% backward compatible):
- All existing 6-tier resolution cascade
- QS codes, BRD codes, LINCS mappings
- Neo4j fallback, signal preservation
- Performance: <10ms with LRU cache

Data Sources (7-tier priority order):
1. drug_priority_2000.csv - 2,000 priority drugs [HIGH confidence]
2. Drug_Name_Lookup_Complete.csv - 2,942 drugs [HIGH confidence, 100% QS coverage]
3. PLATINUM embedding index - 2,327 EP drug mappings [HIGH confidence]
4. ChEMBL-LINCS bridge - 1,560 BRD → ChEMBL [MEDIUM confidence]
5. LINCS sig_info - 51,219 unique compounds [MEDIUM confidence, 68.6% BRD]
6. Neo4j real-time fallback [MEDIUM confidence]
7. Original ID preservation [UNKNOWN confidence, 100% signal]

Zone: z07_data_access
Author: v2.0 base + Phase 5A MOA expansion enhancements
Date: 2025-12-01
"""

import os
import pandas as pd
from functools import lru_cache
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple
import logging
import re

logger = logging.getLogger(__name__)


class DrugNameResolverV21:
    """
    Enhanced drug name resolver with bidirectional CHEMBL mappings for MOA expansion.

    NEW FEATURES (v2.1):
    - resolve_by_chembl(chembl_id) → drug name
    - resolve_by_drug_name(drug_name) → CHEMBL ID
    - PLATINUM embedding index integration (2,327 drugs)
    - Optimized for BBB/ADME prediction workflows

    PRESERVED FEATURES (v2.0):
    - All existing resolution methods
    - QS codes, BRD codes, LINCS mappings
    - Neo4j fallback, caching, signal preservation

    Usage:
        resolver = DrugNameResolverV21()

        # v2.0 methods (preserved)
        info = resolver.resolve("QS0318588")

        # v2.1 methods (new)
        drug_name = resolver.resolve_by_chembl("CHEMBL113")  # → "Caffeine"
        chembl_id = resolver.resolve_by_drug_name("Caffeine")  # → "CHEMBL113"
    """

    def __init__(self, enable_neo4j_fallback: bool = False):
        """
        Initialize resolver with all data sources.

        Args:
            enable_neo4j_fallback: Enable real-time Neo4j lookups
        """
        self.enable_neo4j_fallback = enable_neo4j_fallback

        # Load all data sources (7-tier cascade)
        self.priority_drugs = self._load_priority_drugs()
        self.metadata_drugs = self._load_metadata_drugs()
        self.platinum_index = self._load_platinum_embedding_index()  # NEW v2.1
        self.chembl_lincs_bridge = self._load_chembl_lincs_bridge()
        self.lincs_sig_info = self._load_lincs_sig_info()

        # Build reverse indexes for v2.1 features
        self._build_reverse_indexes()

        # Initialize Neo4j connection if enabled
        self._neo4j_driver = None
        if self.enable_neo4j_fallback:
            self._init_neo4j()

        # Statistics
        self.total_qs_codes = len(self.metadata_drugs)
        self.total_priority = len(self.priority_drugs)
        self.total_platinum = len(self.platinum_index)  # NEW v2.1
        self.total_lincs = len(self.lincs_sig_info)
        self.total_chembl_bridge = len(self.chembl_lincs_bridge)
        self.known_unmapped_brds = 15876

        logger.info(f"DrugNameResolver v2.1 initialized: "
                   f"{self.total_qs_codes} QS codes, "
                   f"{self.total_priority} priority, "
                   f"{self.total_platinum} PLATINUM EP drugs (NEW), "
                   f"{self.total_lincs} LINCS compounds, "
                   f"{self.total_chembl_bridge} ChEMBL-LINCS bridge")

    def _load_priority_drugs(self) -> pd.DataFrame:
        """Load drug_priority_2000.csv (2K priority drugs)."""
        path = Path("/Users/expo/Code/expo/data/drug_expansion/drug_priority_2000.csv")

        if not path.exists():
            logger.warning(f"Priority drug file not found: {path}")
            return pd.DataFrame()

        df = pd.read_csv(path)
        df = df[df['qs_code'].notna()].copy()
        df['qs_code'] = df['qs_code'].str.upper()
        df['drug_name'] = df['drug_name'].str.strip()
        df.set_index('qs_code', inplace=True)

        return df

    def _load_metadata_drugs(self) -> pd.DataFrame:
        """
        Load Drug_Name_Lookup_Complete.csv (2,942 drugs with 100% QS coverage).

        This is the authoritative source for QS ID → commercial name mapping.
        Replaces drug_metadata.csv to achieve 100% QS coverage (was 99.9%).
        """
        path = Path("/Users/expo/Code/expo/clients/quiver/data/raw/Drug_Name_Lookup_Complete.csv")

        if not path.exists():
            logger.warning(f"Drug metadata file not found: {path}")
            return pd.DataFrame()

        df = pd.read_csv(path)

        # Map columns: CorpID → entity_name, DrugName → drug_name, ChEMBL → chembl_id
        df = df.rename(columns={
            'CorpID': 'entity_name',
            'DrugName': 'drug_name',
            'ChEMBL': 'chembl_id'
        })

        # Normalize for matching
        df['entity_name'] = df['entity_name'].str.upper()
        df['drug_name'] = df['drug_name'].fillna('').str.strip()
        df['chembl_id'] = df['chembl_id'].fillna('').str.strip()

        df.set_index('entity_name', inplace=True)

        return df

    def _load_platinum_embedding_index(self) -> pd.DataFrame:
        """
        Load PLATINUM drug embedding index (2,327 EP drug mappings).

        NEW in v2.1: Critical for MOA expansion - maps EP embedding space
        (drug names like "Caffeine", "Carbamazepine") to CHEMBL IDs.

        Source: data/variants/PLATINUM_drug_embedding_index_v1_0.csv
        """
        path = Path("/Users/expo/Code/expo/clients/quiver/data/variants/PLATINUM_drug_embedding_index_v1_0.csv")

        if not path.exists():
            logger.warning(f"PLATINUM index not found: {path}")
            return pd.DataFrame()

        df = pd.read_csv(path)

        # Filter to drugs with CHEMBL IDs
        df = df[df['chembl_id'].notna()].copy()

        # Normalize
        df['drug_name'] = df['drug_name'].str.strip()
        df['chembl_id'] = df['chembl_id'].str.strip().str.upper()

        # Keep entity_name for compatibility
        df['entity_name'] = df['entity_name'].fillna('').str.upper()

        logger.info(f"Loaded PLATINUM index: {len(df)} EP drug → CHEMBL mappings")

        return df

    def _load_chembl_lincs_bridge(self) -> pd.DataFrame:
        """Load ChEMBL-LINCS bridge (1,560 mappings)."""
        path = Path("/Users/expo/Code/expo/clients/quiver/data/Nov 26 Data/mappings/chembl_lincs_map.csv")

        if not path.exists():
            logger.warning(f"ChEMBL-LINCS bridge not found: {path}")
            return pd.DataFrame()

        df = pd.read_csv(path)
        df['lincs_pert_id'] = df['lincs_pert_id'].str.upper()
        df.set_index('lincs_pert_id', inplace=True)

        return df

    def _load_lincs_sig_info(self) -> pd.DataFrame:
        """Load LINCS sig_info (51K compounds)."""
        path_sig_info = Path("/Users/expo/Code/expo/clients/quiver/data/Nov 26 Data/lincs_l1000/GSE92742_Broad_LINCS_sig_info.txt")

        if path_sig_info.exists():
            df = pd.read_csv(path_sig_info, sep='\t', usecols=['pert_id', 'pert_iname', 'pert_type'])
            df = df[df['pert_type'] == 'trt_cp'].copy()
            df = df.drop_duplicates(subset=['pert_id'], keep='first')
            logger.info(f"Loaded LINCS sig_info: {len(df)} compounds")
        else:
            path_filtered = Path("/Users/expo/Code/expo/clients/quiver/transcript_integration/data/lincs_raw/lincs_compounds_only.txt")
            if not path_filtered.exists():
                logger.warning(f"LINCS compound file not found")
                return pd.DataFrame()
            df = pd.read_csv(path_filtered, sep='\t')
            df = df[df['pert_type'] == 'trt_cp'].copy()

        df['pert_id'] = df['pert_id'].str.upper()
        df['pert_iname'] = df['pert_iname'].fillna('').str.strip()
        df.set_index('pert_id', inplace=True)

        return df

    def _build_reverse_indexes(self):
        """
        Build reverse lookup indexes for v2.1 bidirectional queries.

        NEW in v2.1: Enables fast CHEMBL → Drug name and Drug name → CHEMBL lookups
        """
        # CHEMBL ID → Drug name (case-insensitive)
        self._chembl_to_drugname = {}

        # Priority drugs
        for qs_code, row in self.priority_drugs.iterrows():
            chembl_id = row.get('chembl_id', '')
            if chembl_id:
                self._chembl_to_drugname[chembl_id.upper()] = row['drug_name']

        # Metadata drugs
        for entity_name, row in self.metadata_drugs.iterrows():
            chembl_id = row.get('chembl_id', '')
            drug_name = row.get('drug_name', '')
            if chembl_id and drug_name:
                self._chembl_to_drugname[chembl_id.upper()] = drug_name

        # PLATINUM index (highest quality for EP drugs)
        for _, row in self.platinum_index.iterrows():
            chembl_id = row['chembl_id']
            drug_name = row['drug_name']
            self._chembl_to_drugname[chembl_id.upper()] = drug_name  # Override with PLATINUM

        # Drug name → CHEMBL ID (case-insensitive)
        self._drugname_to_chembl = {}

        # PLATINUM index (priority source)
        for _, row in self.platinum_index.iterrows():
            drug_name = row['drug_name'].lower()
            chembl_id = row['chembl_id'].upper()
            self._drugname_to_chembl[drug_name] = chembl_id

        # Metadata drugs (fallback)
        for entity_name, row in self.metadata_drugs.iterrows():
            drug_name = row.get('drug_name', '').lower()
            chembl_id = row.get('chembl_id', '').upper()
            if drug_name and chembl_id and drug_name not in self._drugname_to_chembl:
                self._drugname_to_chembl[drug_name] = chembl_id

        logger.info(f"Built reverse indexes: {len(self._chembl_to_drugname)} CHEMBL→name, "
                   f"{len(self._drugname_to_chembl)} name→CHEMBL")

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
        """Extract concentration suffix (e.g., "_10uM")."""
        concentration_match = re.search(r'_([\d.]+U?M)$', drug_id, flags=re.IGNORECASE)
        if concentration_match:
            concentration = concentration_match.group(1)
            base_id = drug_id[:concentration_match.start()]
            return base_id, concentration
        return drug_id, None

    def _neo4j_lookup(self, drug_name: Optional[str] = None,
                      chembl_id: Optional[str] = None) -> Optional[Dict[str, Any]]:
        """Real-time Neo4j fallback."""
        if not self._neo4j_driver or (not drug_name and not chembl_id):
            return None

        try:
            with self._neo4j_driver.session() as session:
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

    @lru_cache(maxsize=20000)
    def resolve(self, drug_id: str) -> Dict[str, Any]:
        """
        Resolve drug ID to commercial name and metadata (v2.0 method - preserved).

        7-tier resolution cascade (v2.1 adds PLATINUM as tier 3):
        1. Priority drugs (2K, HIGH confidence)
        2. Drug metadata (14K QS codes, MEDIUM confidence)
        3. PLATINUM embedding index (2.3K EP drugs, HIGH confidence) [NEW v2.1]
        4. ChEMBL-LINCS bridge (1.5K, MEDIUM confidence)
        5. LINCS sig_info (51K, MEDIUM confidence)
        6. Neo4j fallback (real-time, MEDIUM confidence)
        7. Original ID preservation (UNKNOWN confidence)

        Args:
            drug_id: QS code, BRD code, or drug name (with optional concentration)

        Returns:
            Dict with commercial_name, chembl_id, confidence, source, etc.
        """
        if not drug_id or not isinstance(drug_id, str):
            return self._empty_result(drug_id)

        original_id = drug_id.strip().upper()
        base_id, concentration = self._extract_concentration(original_id)

        # Tier 1: Priority drugs
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
                'source': 'priority_2000'
            }

        # Tier 2: Drug metadata
        if base_id in self.metadata_drugs.index:
            row = self.metadata_drugs.loc[base_id]
            commercial_name = row['drug_name']

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
                'aliases': [],
                'confidence': 'high',  # Upgraded from 'medium' - authoritative source
                'source': 'Drug_Name_Lookup_Complete'
            }

        # Tier 3: PLATINUM embedding index (NEW v2.1 - highest quality for EP drugs)
        platinum_match = self.platinum_index[
            (self.platinum_index['drug_name'].str.lower() == base_id.lower()) |
            (self.platinum_index['entity_name'] == base_id)
        ]

        if not platinum_match.empty:
            row = platinum_match.iloc[0]
            return {
                'drug_id': original_id,
                'base_id': base_id,
                'concentration': concentration,
                'commercial_name': row['drug_name'],
                'chembl_id': row['chembl_id'],
                'aliases': [],
                'confidence': 'high',
                'source': 'platinum_ep_index'  # NEW source type
            }

        # Tier 4: ChEMBL-LINCS bridge
        if base_id.startswith('BRD-') and base_id in self.chembl_lincs_bridge.index:
            chembl_id = self.chembl_lincs_bridge.loc[base_id, 'chembl_id']

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

        # Tier 5: LINCS sig_info
        if base_id.startswith('BRD-') and base_id in self.lincs_sig_info.index:
            row = self.lincs_sig_info.loc[base_id]
            return {
                'drug_id': original_id,
                'base_id': base_id,
                'concentration': concentration,
                'commercial_name': row['pert_iname'],
                'chembl_id': '',
                'aliases': [],
                'confidence': 'medium',
                'source': 'lincs_sig_info'
            }

        # Tier 6: Neo4j fallback
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

        # Tier 7: Original ID preservation
        return self._empty_result(original_id, base_id, concentration)

    @lru_cache(maxsize=20000)
    def resolve_by_chembl(self, chembl_id: str) -> Optional[str]:
        """
        NEW in v2.1: Resolve CHEMBL ID to drug name (reverse lookup).

        Critical for BBB/ADME prediction expansion where reference datasets
        use CHEMBL IDs but we need drug names for MOA queries.

        Args:
            chembl_id: CHEMBL ID (e.g., "CHEMBL113")

        Returns:
            Drug name (e.g., "Caffeine") or None if not found

        Example:
            >>> resolver.resolve_by_chembl("CHEMBL113")
            "Caffeine"
        """
        if not chembl_id:
            return None

        chembl_id_upper = chembl_id.strip().upper()

        # Check reverse index
        drug_name = self._chembl_to_drugname.get(chembl_id_upper)
        if drug_name:
            return drug_name

        # Fallback to Neo4j
        if self.enable_neo4j_fallback:
            neo4j_result = self._neo4j_lookup(chembl_id=chembl_id_upper)
            if neo4j_result:
                return neo4j_result['name']

        return None

    @lru_cache(maxsize=20000)
    def resolve_by_drug_name(self, drug_name: str) -> Optional[str]:
        """
        NEW in v2.1: Resolve drug name to CHEMBL ID (forward lookup).

        Optimized for MOA expansion where we have drug names from K-NN
        neighbors and need CHEMBL IDs for target queries.

        Args:
            drug_name: Drug name (e.g., "Caffeine")

        Returns:
            CHEMBL ID (e.g., "CHEMBL113") or None if not found

        Example:
            >>> resolver.resolve_by_drug_name("Caffeine")
            "CHEMBL113"
        """
        if not drug_name:
            return None

        drug_name_lower = drug_name.strip().lower()

        # Check reverse index
        chembl_id = self._drugname_to_chembl.get(drug_name_lower)
        if chembl_id:
            return chembl_id

        # Fallback to Neo4j
        if self.enable_neo4j_fallback:
            neo4j_result = self._neo4j_lookup(drug_name=drug_name)
            if neo4j_result:
                return neo4j_result.get('chembl_id')

        return None

    def _empty_result(self, drug_id: str, base_id: Optional[str] = None,
                      concentration: Optional[str] = None) -> Dict[str, Any]:
        """Return fallback result when no match found."""
        is_unmapped_brd = (drug_id.startswith('BRD-') and
                          base_id and base_id not in self.lincs_sig_info.index)

        return {
            'drug_id': drug_id,
            'base_id': base_id or drug_id,
            'concentration': concentration,
            'commercial_name': drug_id,
            'chembl_id': '',
            'aliases': [],
            'confidence': 'unknown',
            'source': 'unmapped_experimental' if is_unmapped_brd else 'none'
        }

    # Preserve all v2.0 methods
    def bulk_resolve(self, drug_ids: List[str]) -> Dict[str, Dict[str, Any]]:
        """Batch resolve multiple drug IDs (v2.0 method - preserved)."""
        return {drug_id: self.resolve(drug_id) for drug_id in drug_ids}

    def get_metadata(self, drug_id: str) -> Dict[str, Any]:
        """Get full metadata for a drug (v2.0 method - preserved)."""
        basic_info = self.resolve(drug_id)
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
        """Search for drugs by name (v2.0 method - preserved)."""
        query_lower = query.lower()
        matches = []

        for qs_code, row in self.priority_drugs.iterrows():
            if query_lower in row['drug_name'].lower():
                matches.append({
                    'drug_id': qs_code,
                    'commercial_name': row['drug_name'],
                    'chembl_id': row.get('chembl_id', ''),
                    'match_source': 'priority_2000'
                })

        if len(matches) < limit:
            for qs_code, row in self.metadata_drugs.iterrows():
                drug_name = row['drug_name']
                if drug_name and query_lower in drug_name.lower():
                    matches.append({
                        'drug_id': qs_code,
                        'commercial_name': drug_name,
                        'chembl_id': row.get('chembl_id', ''),
                        'match_source': 'Drug_Name_Lookup_Complete'
                    })

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
        """Generate case-insensitive Neo4j match clause (v2.0 helper - preserved)."""
        return f"WHERE toLower({var}.name) = toLower($drug_name)"

    def get_stats(self) -> Dict[str, Any]:
        """Return statistics (enhanced with v2.1 metrics)."""
        cache_info_resolve = self.resolve.cache_info()
        cache_info_chembl = self.resolve_by_chembl.cache_info()
        cache_info_drugname = self.resolve_by_drug_name.cache_info()

        return {
            'total_qs_codes': self.total_qs_codes,
            'priority_drugs': self.total_priority,
            'platinum_ep_drugs': self.total_platinum,  # NEW v2.1
            'lincs_compounds': self.total_lincs,
            'chembl_lincs_bridge': self.total_chembl_bridge,
            'reverse_index_chembl_to_name': len(self._chembl_to_drugname),  # NEW v2.1
            'reverse_index_name_to_chembl': len(self._drugname_to_chembl),  # NEW v2.1
            'cache_resolve': cache_info_resolve.currsize,
            'cache_resolve_by_chembl': cache_info_chembl.currsize,  # NEW v2.1
            'cache_resolve_by_drug_name': cache_info_drugname.currsize,  # NEW v2.1
            'neo4j_fallback_enabled': self.enable_neo4j_fallback,
            'version': '2.1'
        }


# Singleton instance
_resolver_v21_instance = None


def get_drug_name_resolver_v21(enable_neo4j_fallback: bool = False) -> DrugNameResolverV21:
    """
    Get singleton DrugNameResolverV21 instance.

    Usage:
        # v2.0 compatibility
        resolver = get_drug_name_resolver_v21()
        info = resolver.resolve("QS0318588")

        # v2.1 new features
        drug_name = resolver.resolve_by_chembl("CHEMBL113")  # → "Caffeine"
        chembl_id = resolver.resolve_by_drug_name("Caffeine")  # → "CHEMBL113"
    """
    global _resolver_v21_instance
    if _resolver_v21_instance is None:
        _resolver_v21_instance = DrugNameResolverV21(enable_neo4j_fallback=enable_neo4j_fallback)
    return _resolver_v21_instance


# Backward compatibility aliases for meta_layer migration
DrugNameResolver = DrugNameResolverV21
get_drug_name_resolver = get_drug_name_resolver_v21
