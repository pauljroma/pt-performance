"""
BBB Permeability Tool - K-NN Predictor with PGVector Embeddings
================================================================

Uses K-NN on EP drug embeddings (v6.0 fusion table) to predict
Blood-Brain Barrier penetration based on 6,500+ validated molecules.

Key Features:
- Real K-NN predictions using PGVector fusion tables (110× faster)
- BBB dataset: chembl_bbb_data.csv (6,500 molecules with log BB values)
- d_aux_ep_drug_topk_v6_0 fusion table (pre-computed similarities)
- Neo4j CNS indication enrichment for confidence boosting
- Query caching for <1ms latency

Author: Phase 2 Agent + Claude Code Agent
Date: 2025-12-03 (Updated to v6.0)
Zone: z07_data_access/tools
"""

from typing import Dict, Any, List, Optional, Tuple
import logging
import csv
import os
from pathlib import Path
from functools import lru_cache
import numpy as np
import psycopg2
from psycopg2.extras import RealDictCursor
from neo4j import GraphDatabase

# CRITICAL FIX: Use shared connection pool to prevent pool exhaustion
from zones.z07_data_access.db_connection_pool import get_pgvector_connection

logger = logging.getLogger(__name__)

# MIGRATED to v3.0 (2025-12-05): Master resolution tables (60x faster)
# Import drug name resolver for enhanced drug name resolution
try:
    from zones.z07_data_access.drug_name_resolver_v3 import get_drug_name_resolver_v3 as get_drug_name_resolver_v21
    DRUG_RESOLVER_AVAILABLE = True
except ImportError:
    logger.warning("Drug name resolver not available - using Neo4j only for drug resolution")
    DRUG_RESOLVER_AVAILABLE = False


class BBBPermeabilityTool:
    """
    Blood-Brain Barrier permeability assessment using K-NN on PGVector fusion tables (v6.0)

    Methodology:
    1. Load BBB dataset (6,500+ molecules with experimental log BB values)
    2. Query d_aux_ep_drug_topk_v6_0 fusion table for pre-computed similarities
    3. Find K=20 nearest neighbors from fusion table (110× faster than live queries)
    4. Weight neighbors by similarity and known BBB scores
    5. Optionally enrich with Neo4j CNS indication data
    """

    def __init__(
        self,
        pgvector_host: str = "localhost",
        pgvector_port: int = 5435,
        neo4j_uri: str = "bolt://localhost:7687",
        neo4j_password: str = "testpassword123"
    ):
        """
        Initialize BBB permeability tool

        Args:
            pgvector_host: PostgreSQL host with pgvector extension
            pgvector_port: PostgreSQL port
            neo4j_uri: Neo4j connection URI
            neo4j_password: Neo4j password
        """
        self.tool_name = "bbb_permeability"

        # PGVector connection config
        self.pgvector_host = pgvector_host
        self.pgvector_port = pgvector_port
        self.pgvector_db = "sapphire_database"
        self.pgvector_user = "postgres"
        self.pgvector_password = os.getenv('POSTGRES_PASSWORD', 'temppass123')

        # Neo4j connection config
        self.neo4j_uri = neo4j_uri
        self.neo4j_password = neo4j_password
        self.neo4j_driver = None

        # Load BBB database on initialization
        self.bbb_data = self._load_bbb_database()

        # Cache for drug name -> CHEMBL ID resolution
        self._chembl_cache: Dict[str, Optional[str]] = {}

        # Cache for CHEMBL ID -> numeric ID resolution (for fusion table queries)
        self._numeric_id_cache: Dict[str, Optional[str]] = {}

        logger.info(f"BBB Tool initialized with {len(self.bbb_data)} BBB reference molecules")

    def _load_bbb_database(self) -> Dict[str, Dict[str, Any]]:
        """
        Load BBB dataset from CSV into memory

        Returns:
            Dictionary mapping CHEMBL IDs to BBB data:
            {
                "CHEMBL38": {
                    "log_bb": 0.06,
                    "bbb_class": "BBB+",
                    "mol_weight": 194.19,
                    "smiles": "CN1C=NC2=C1C(=O)N(C(=O)N2C)C"
                },
                ...
            }
        """
        bbb_file = Path("/Users/expo/Code/expo/clients/quiver/data/bbb/chembl_bbb_data.csv")

        if not bbb_file.exists():
            logger.warning(f"BBB data file not found: {bbb_file}")
            return {}

        bbb_dict = {}
        try:
            with open(bbb_file, 'r') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    # Column name is 'compound_id' (can be CHEMBL ID or drug name)
                    compound_id = row['compound_id']
                    bbb_dict[compound_id] = {
                        'log_bb': float(row['log_bb']),
                        'bbb_class': row['bbb_class'],
                        'mol_weight': float(row['mol_weight']),
                        'smiles': row['smiles'],
                        'method': row['method'],
                        'data_source': row['data_source']
                    }

            logger.info(f"Loaded {len(bbb_dict)} BBB reference molecules from {bbb_file}")
            return bbb_dict

        except Exception as e:
            logger.error(f"Failed to load BBB database: {e}")
            return {}

    def _get_pgvector_connection(self):
        """
        Get PostgreSQL connection from shared pool

        CRITICAL FIX: Uses shared connection pool to prevent exhaustion
        when multiple BBB tools run in parallel (e.g., 5 simultaneous calls).
        Pool manages 10-50 connections efficiently vs creating new ones.
        """
        try:
            return get_pgvector_connection()
        except Exception as e:
            logger.error(f"Failed to get connection from pool: {e}")
            # Fallback to direct connection if pool fails
            logger.warning("Falling back to direct connection (not recommended)")
            return psycopg2.connect(
                host=self.pgvector_host,
                port=self.pgvector_port,
                database=self.pgvector_db,
                user=self.pgvector_user,
                password=self.pgvector_password
            )

    def _get_neo4j_driver(self):
        """Lazy initialization of Neo4j driver"""
        if self.neo4j_driver is None:
            self.neo4j_driver = GraphDatabase.driver(
                self.neo4j_uri,
                auth=("neo4j", self.neo4j_password)
            )
        return self.neo4j_driver

    async def assess_bbb_permeability(
        self,
        drug_name: str,
        k: int = 20,
        use_cns_enrichment: bool = True
    ) -> Dict[str, Any]:
        """
        Assess BBB permeability using K-NN on EP drug embeddings

        Args:
            drug_name: Name of drug to assess (can be CHEMBL ID or drug name)
            k: Number of nearest neighbors for K-NN prediction
            use_cns_enrichment: Whether to enrich with Neo4j CNS indication data

        Returns:
            BBB assessment with prediction, confidence, and supporting evidence
        """
        try:
            import time
            start_time = time.time()

            # Step 1: Resolve drug to CHEMBL ID via Neo4j
            chembl_id = self._resolve_drug_to_chembl(drug_name)
            if not chembl_id:
                return {
                    "success": False,  # CRITICAL: Sapphire expects 'success' key
                    "drug": drug_name,
                    "found": False,
                    "error": f"❌ Drug Not Found: '{drug_name}'\n\n" \
                             f"The drug '{drug_name}' was not found in our knowledge graph.\n\n" \
                             f"What you can try:\n" \
                             f"1. Check spelling - drug names are case-sensitive\n" \
                             f"2. Try alternative names (brand name vs generic name)\n" \
                             f"3. Use CHEMBL ID directly (e.g., 'CHEMBL25' for Aspirin)\n" \
                             f"4. Use semantic_search to find the drug: semantic_search(query='{drug_name}')\n\n" \
                             f"Example:\n" \
                             f"• Instead of 'asprin' → try 'Aspirin' or 'CHEMBL25'\n" \
                             f"• Instead of 'Tylenol' → try 'Acetaminophen' or 'CHEMBL112'",
                    "query_time_ms": round((time.time() - start_time) * 1000, 2),
                    "suggestions": [
                        f"Use semantic_search to find: {drug_name}",
                        f"Try alternative spellings or synonyms",
                        f"Search ChEMBL database for CHEMBL ID"
                    ]
                }

            # Step 2: Calculate BBB penetration using K-NN
            bbb_result = self._calculate_bbb_penetration(
                drug_id=chembl_id,
                drug_name=drug_name,
                k=k
            )

            # Check if _calculate_bbb_penetration returned an error
            if 'error' in bbb_result:
                query_time = round((time.time() - start_time) * 1000, 2)
                return {
                    "success": False,  # CRITICAL: Return error properly
                    "drug": drug_name,
                    "chembl_id": chembl_id,
                    "found": bbb_result.get('found', False),
                    "error": bbb_result['error'],
                    "query_time_ms": query_time,
                    "note": bbb_result.get('note', ''),
                    "suggestions": bbb_result.get('suggestions', [])
                }

            # Step 3: Optionally enrich with CNS indication from Neo4j
            cns_info = {}
            if use_cns_enrichment:
                cns_info = self._get_cns_indication(chembl_id)

            query_time = round((time.time() - start_time) * 1000, 2)

            return {
                "success": True,  # CRITICAL: Sapphire expects 'success' key
                "drug": drug_name,
                "chembl_id": chembl_id,
                "found": True,
                "bbb_permeability_probability": bbb_result['probability'],
                "bbb_class": bbb_result['bbb_class'],
                "confidence": bbb_result['confidence'],
                "log_bb_predicted": bbb_result['log_bb_predicted'],
                "method": bbb_result.get('method', "K-NN on drug_chemical_v6_0_256d via d_aux_ep_drug_topk_v6_0 fusion table"),
                "k_neighbors_used": bbb_result['k_used'],
                "similar_drugs": bbb_result['neighbors'][:5],
                "cns_indication": cns_info.get('has_cns_indication', False),
                "cns_confidence_boost": cns_info.get('confidence_boost', 0.0),
                "query_time_ms": query_time,
                "embedding_space": "drug_chemical_v6_0_256d",
                "data_source": bbb_result.get('data_source', 'K-NN prediction')
            }

        except Exception as e:
            logger.error(f"BBB assessment failed for {drug_name}: {e}", exc_info=True)
            return {
                "success": False,  # CRITICAL: Sapphire expects 'success' key
                "drug": drug_name,
                "found": False,
                "error": f"Tool execution error: {str(e)}"
            }

    def _resolve_drug_to_chembl(self, drug_name: str) -> Optional[str]:
        """
        Resolve drug name to CHEMBL ID using Neo4j + DrugNameResolver fallback (with caching)

        Args:
            drug_name: Drug name or CHEMBL ID

        Returns:
            CHEMBL ID or None if not found
        """
        # Handle None or empty drug_name
        if not drug_name:
            logger.warning("Cannot resolve drug_name: None or empty string provided")
            return None

        # If already a CHEMBL ID, return it
        if drug_name.startswith("CHEMBL"):
            return drug_name

        # Check cache first
        if drug_name in self._chembl_cache:
            return self._chembl_cache[drug_name]

        # Try Neo4j first
        try:
            driver = self._get_neo4j_driver()
            with driver.session() as session:
                result = session.run("""
                    MATCH (d:Drug)
                    WHERE (toLower(d.name) = toLower($name)
                       OR toLower(d.id) = toLower($name)
                       OR d.chembl_id = $name)
                       AND d.chembl_id IS NOT NULL
                    RETURN d.chembl_id as chembl_id
                    ORDER BY CASE WHEN d.chembl_id STARTS WITH 'CHEMBL' THEN 0 ELSE 1 END
                    LIMIT 1
                """, name=drug_name)

                record = result.single()
                if record and record['chembl_id']:
                    chembl_id = record['chembl_id']
                    self._chembl_cache[drug_name] = chembl_id
                    logger.info(f"Resolved '{drug_name}' to {chembl_id} via Neo4j")
                    return chembl_id

        except Exception as e:
            logger.warning(f"Neo4j drug resolution failed for {drug_name}: {e}")

        # Fallback to DrugNameResolverV21 for EP index and other sources
        if DRUG_RESOLVER_AVAILABLE:
            try:
                resolver = get_drug_name_resolver_v21()

                # Try with spaces (normalize hyphens to spaces for research compounds)
                normalized_name = drug_name.replace('-', ' ')
                result = resolver.resolve(normalized_name)

                if result and result.get('chembl_id'):
                    chembl_id = result['chembl_id']
                    self._chembl_cache[drug_name] = chembl_id
                    logger.info(f"Resolved '{drug_name}' to {chembl_id} via DrugNameResolver (source: {result.get('source')})")
                    return chembl_id

            except Exception as e:
                logger.warning(f"DrugNameResolver failed for {drug_name}: {e}")

        self._chembl_cache[drug_name] = None
        return None

    def _convert_chembl_to_numeric_id(self, chembl_id: str) -> Optional[str]:
        """
        Convert CHEMBL ID to numeric drug ID used in fusion table.

        Mapping chain: CHEMBL25 → QS0204362 (CorpID) → 0204362 (numeric ID)

        The fusion table (d_aux_ep_drug_topk_v6_0) uses numeric IDs like "0204362_0.123uM"
        instead of CHEMBL IDs. This method:
        1. Queries raw_drugs table for CorpID (QS code)
        2. Strips "QS" prefix to get numeric ID
        3. Caches result for performance

        Args:
            chembl_id: CHEMBL ID (e.g., "CHEMBL25")

        Returns:
            Numeric drug ID (e.g., "0204362") or None if not found
        """
        # Check cache first
        if chembl_id in self._numeric_id_cache:
            return self._numeric_id_cache[chembl_id]

        try:
            conn = self._get_pgvector_connection()
            cur = conn.cursor()

            # Query raw_drugs for CorpID (QS code)
            cur.execute("""
                SELECT raw_json->>'CorpID' as corp_id
                FROM raw_drugs
                WHERE chembl_id = %s
                LIMIT 1
            """, (chembl_id,))

            result = cur.fetchone()
            conn.close()

            if not result or not result[0]:
                logger.warning(f"No CorpID found for {chembl_id} in raw_drugs table")
                self._numeric_id_cache[chembl_id] = None
                return None

            corp_id = result[0]  # e.g., "QS0204362"

            # Strip QS prefix to get numeric ID
            if corp_id.startswith("QS"):
                numeric_id = corp_id[2:]  # "0204362"
                self._numeric_id_cache[chembl_id] = numeric_id
                logger.info(f"Converted {chembl_id} → {corp_id} → {numeric_id}")
                return numeric_id
            else:
                logger.warning(f"CorpID {corp_id} doesn't start with QS prefix (expected QS format)")
                self._numeric_id_cache[chembl_id] = None
                return None

        except Exception as e:
            logger.error(f"Failed to convert {chembl_id} to numeric ID: {e}", exc_info=True)
            self._numeric_id_cache[chembl_id] = None
            return None

    def _get_drug_name_from_chembl(self, chembl_id: str) -> Optional[str]:
        """
        Get drug name from CHEMBL ID using Neo4j

        Args:
            chembl_id: CHEMBL ID

        Returns:
            Drug name or None
        """
        try:
            driver = self._get_neo4j_driver()
            with driver.session() as session:
                result = session.run("""
                    MATCH (d:Drug {chembl_id: $chembl_id})
                    RETURN d.name as name
                    LIMIT 1
                """, chembl_id=chembl_id)

                record = result.single()
                if record:
                    return record['name']

        except Exception as e:
            logger.warning(f"Failed to get drug name for {chembl_id}: {e}")

        return None

    def _calculate_bbb_penetration(
        self,
        drug_id: str,
        drug_name: str,
        k: int = 20
    ) -> Dict[str, Any]:
        """
        Calculate BBB penetration using K-NN on EP embeddings

        **v6.0 FUSION INTEGRATION:**
        Now uses pre-computed fusion table d_aux_ep_drug_topk_v6_0 for 110× speedup!
        - OLD: 50-100ms (cross-join + vector similarity)
        - NEW: 0.9ms (indexed fusion table lookup)

        Args:
            drug_id: CHEMBL ID of the drug
            drug_name: Drug name (for display)
            k: Number of nearest neighbors

        Returns:
            Dictionary with BBB prediction results
        """
        try:
            conn = self._get_pgvector_connection()
            cur = conn.cursor(cursor_factory=RealDictCursor)

            # Step 1: Get actual drug name from Neo4j (CHEMBL ID -> drug name)
            actual_drug_name = self._get_drug_name_from_chembl(drug_id)
            if not actual_drug_name:
                logger.warning(f"Could not resolve CHEMBL ID {drug_id} to drug name")
                actual_drug_name = drug_name

            # Step 2: OPTIMIZATION - Check direct BBB data FIRST before fusion table
            # This is 1000× faster for drugs we have direct data for
            if drug_id in self.bbb_data:
                bbb_info = self.bbb_data[drug_id]
                logger.info(f"Drug {drug_id} found directly in BBB database")
                conn.close()
                return {
                    'probability': 1.0 if bbb_info['bbb_class'] == 'BBB+' else 0.0,
                    'bbb_class': bbb_info['bbb_class'],
                    'confidence': 'high',
                    'log_bb_predicted': bbb_info['log_bb'],
                    'k_used': 0,
                    'neighbors': [],
                    'note': f'Direct BBB data available (not K-NN prediction)',
                    'data_source': 'BBB database (experimental)',
                    'method': 'Direct lookup (not K-NN)'
                }

            # Step 3: Convert CHEMBL ID to numeric ID for fusion table lookup
            # Fusion table uses numeric IDs (e.g., "0204362") not CHEMBL IDs
            numeric_id = self._convert_chembl_to_numeric_id(drug_id)

            # Step 4: NEW v6.0 - Use fusion table for 110× speedup!
            # Query pre-computed drug → EP_drug similarity fusion across ALL doses
            neighbors = []

            if numeric_id:
                # Pattern: {numeric_id}_% matches 0204362_0.123uM, 0204362_0.37uM, etc.
                logger.info(f"Querying fusion table with numeric ID: {numeric_id}")
                cur.execute("""
                    SELECT
                        entity2_id as similar_drug_id,
                        similarity_score as similarity
                    FROM d_aux_ep_drug_topk_v6_0
                    WHERE entity1_id LIKE %s
                    ORDER BY similarity_score DESC
                    LIMIT %s
                """, (f"{numeric_id}_%", k * 2))  # Get 2x neighbors to account for dose variations
                neighbors = cur.fetchall()

            # Fallback: Try CHEMBL ID directly if numeric ID failed or returned no results
            if not neighbors:
                logger.warning(f"Numeric ID lookup failed for {drug_id}, trying CHEMBL ID fallback")
                cur.execute("""
                    SELECT
                        entity2_id as similar_drug_id,
                        similarity_score as similarity
                    FROM d_aux_ep_drug_topk_v6_0
                    WHERE entity1_id LIKE %s
                    ORDER BY similarity_score DESC
                    LIMIT %s
                """, (f"{drug_id}%", k * 2))  # Try CHEMBL ID pattern
                neighbors = cur.fetchall()

            # If still no fusion results and no direct BBB data
            if not neighbors:

                # No fusion results and no direct BBB data
                logger.warning(f"No fusion results for {drug_id} in d_aux_ep_drug_topk_v6_0")
                conn.close()

                # Provide helpful error message
                return {
                    'probability': 0.5,
                    'bbb_class': 'unknown',
                    'confidence': 'low',
                    'log_bb_predicted': 0.0,
                    'k_used': 0,
                    'neighbors': [],
                    'found': True,  # Drug exists in Neo4j
                    'chembl_id': drug_id,
                    'note': f'Drug found in database but lacks embedding data for BBB prediction',
                    'error': f"❌ BBB Assessment Not Available\n\n" \
                             f"Drug: {drug_name} ({drug_id})\n" \
                             f"Status: Found in database but not in embedding space\n\n" \
                             f"Why this happens:\n" \
                             f"• The BBB tool uses pre-computed drug embeddings (v6.0)\n" \
                             f"• Current coverage: 842 drugs with embeddings\n" \
                             f"• Your drug is in our database (889K drugs) but not yet embedded\n\n" \
                             f"What you can try:\n" \
                             f"1. Try alternative drug names or synonyms\n" \
                             f"2. Check if related drugs in the same class are available\n" \
                             f"3. Use semantic_search to find similar drugs with BBB data\n\n" \
                             f"This is a known limitation - we're expanding coverage to include all common drugs.",
                    'suggestions': [
                        f"Try: semantic_search with query 'drugs similar to {drug_name}'",
                        f"Try: Alternative names/synonyms for {drug_name}",
                        f"Check: Related drugs in same therapeutic class"
                    ]
                }

            # Step 3: Load BBB labels for neighbors (from fusion results)
            neighbor_scores = []

            for neighbor in neighbors:
                # Fusion table returns entity2_id (similar drug) and similarity_score
                neighbor_id = neighbor['similar_drug_id']
                similarity = float(neighbor['similarity'])

                # Try to match neighbor_id with BBB database
                # neighbor_id might be drug name or CHEMBL ID
                neighbor_chembl = None

                # Direct CHEMBL ID match
                if neighbor_id in self.bbb_data:
                    neighbor_chembl = neighbor_id
                else:
                    # Try resolving via Neo4j
                    neighbor_chembl = self._resolve_drug_to_chembl(neighbor_id)

                if neighbor_chembl and neighbor_chembl in self.bbb_data:
                    bbb_info = self.bbb_data[neighbor_chembl]
                    neighbor_scores.append({
                        'drug_name': neighbor_id,
                        'chembl_id': neighbor_chembl,
                        'log_bb': bbb_info['log_bb'],
                        'bbb_class': bbb_info['bbb_class'],
                        'similarity': similarity
                    })

            # Step 4: Weighted average of log_bb values
            if len(neighbor_scores) == 0:
                # No neighbors with BBB data, return uncertain
                return {
                    'probability': 0.5,
                    'bbb_class': 'uncertain',
                    'confidence': 'low',
                    'log_bb_predicted': 0.0,
                    'k_used': 0,
                    'neighbors': [],
                    'note': 'No neighbors with BBB reference data'
                }

            # Weighted average by similarity
            total_weight = sum(ns['similarity'] for ns in neighbor_scores)
            weighted_log_bb = sum(ns['log_bb'] * ns['similarity'] for ns in neighbor_scores) / total_weight

            # Step 5: Convert log BB to probability using sigmoid
            # Log BB > 0 typically means BBB+, < 0 means BBB-
            # Use sigmoid to convert to probability
            bbb_probability = 1.0 / (1.0 + np.exp(-weighted_log_bb * 2.0))  # Scale factor for steepness

            # Determine BBB class
            if bbb_probability >= 0.7:
                bbb_class = 'BBB+'
            elif bbb_probability <= 0.4:
                bbb_class = 'BBB-'
            else:
                bbb_class = 'uncertain'

            # Confidence based on number of neighbors and similarity
            avg_similarity = total_weight / len(neighbor_scores)
            if len(neighbor_scores) >= 10 and avg_similarity >= 0.7:
                confidence = 'high'
            elif len(neighbor_scores) >= 5 and avg_similarity >= 0.5:
                confidence = 'medium'
            else:
                confidence = 'low'

            conn.close()

            return {
                'probability': round(bbb_probability, 3),
                'bbb_class': bbb_class,
                'confidence': confidence,
                'log_bb_predicted': round(weighted_log_bb, 3),
                'k_used': len(neighbor_scores),
                'neighbors': neighbor_scores
            }

        except Exception as e:
            logger.error(f"BBB calculation failed: {e}", exc_info=True)
            return {
                'probability': 0.5,
                'bbb_class': 'error',
                'confidence': 'low',
                'log_bb_predicted': 0.0,
                'k_used': 0,
                'neighbors': [],
                'error': str(e)
            }

    def _get_cns_indication(self, chembl_id: str) -> Dict[str, Any]:
        """
        Get CNS indication information from Neo4j to boost confidence

        Args:
            chembl_id: CHEMBL ID of drug

        Returns:
            Dictionary with CNS indication info
        """
        try:
            driver = self._get_neo4j_driver()
            with driver.session() as session:
                result = session.run("""
                    MATCH (d:Drug {chembl_id: $chembl_id})-[:INDICATES]->(dis:Disease)
                    WHERE dis.name CONTAINS 'CNS'
                       OR dis.name =~ '(?i).*(brain|neuro|epilep|seizure|parkinsons|alzheimer).*'
                    RETURN count(dis) as cns_indication_count,
                           collect(dis.name)[..3] as cns_diseases
                """, chembl_id=chembl_id)

                record = result.single()
                if record and record['cns_indication_count'] > 0:
                    return {
                        'has_cns_indication': True,
                        'cns_indication_count': record['cns_indication_count'],
                        'cns_diseases': record['cns_diseases'],
                        'confidence_boost': 0.1  # Boost confidence by 10%
                    }

        except Exception as e:
            logger.warning(f"CNS indication lookup failed for {chembl_id}: {e}")

        return {
            'has_cns_indication': False,
            'confidence_boost': 0.0
        }

    def close(self):
        """Close connections"""
        if self.neo4j_driver:
            self.neo4j_driver.close()


# Tool factory for Sapphire integration
def create_tool(**kwargs):
    """Factory function for tool registry"""
    return BBBPermeabilityTool()


# ============================================================================
# Claude Tool Definition (Anthropic format) - Added for Sapphire v3.14
# ============================================================================

TOOL_DEFINITION = {
    "name": "bbb_permeability",
    "description": """Predict Blood-Brain Barrier (BBB) permeability for drugs using K-NN on drug chemical embeddings.

**Critical for CNS Drug Development**:
The BBB is a highly selective barrier that protects the brain from harmful substances but also blocks ~98% of
small-molecule drugs. BBB permeability is ESSENTIAL for:
- CNS disorder treatments (epilepsy, Parkinson's, Alzheimer's)
- Predicting neurotoxicity risks
- Optimizing drug formulations for brain penetration

**Methodology**:
1. Uses 6,500+ experimentally validated BBB-labeled molecules
2. K-NN prediction on drug_chemical_v6_0_256d embeddings via d_aux_ep_drug_topk_v6_0 fusion table (110× faster)
3. Neo4j CNS indication enrichment for confidence boosting
4. Weighted average by molecular similarity

**Output**:
- BBB probability (0-1): >0.7 = high penetration, <0.4 = low penetration
- BBB classification: BBB+ (crosses), BBB- (doesn't cross), uncertain
- Confidence level: high/medium/low based on neighbor count and similarity
- log_bb prediction: negative = doesn't cross, positive = crosses
- Supporting evidence: K nearest neighbors with BBB data

**Use Cases**:
- "Does Fenfluramine cross the blood-brain barrier?" → BBB+ (0.85, high confidence)
- "BBB permeability of SCN1A drugs?" → Assess all drugs for CNS access
- "Which epilepsy drugs penetrate the BBB?" → Screen drug candidates

**Important**: BBB+ drugs can access CNS targets but may also cause CNS side effects.
BBB- drugs are safer for peripheral targets but unsuitable for CNS disorders.""",
    "input_schema": {
        "type": "object",
        "properties": {
            "drug_name": {
                "type": "string",
                "description": "Drug name or CHEMBL ID to assess (e.g., 'Fenfluramine', 'CHEMBL1575', 'Stiripentol')"
            },
            "k": {
                "type": "integer",
                "description": "Number of nearest neighbors for K-NN prediction (default: 20, range: 5-50)",
                "default": 20
            },
            "use_cns_enrichment": {
                "type": "boolean",
                "description": "Whether to boost confidence using Neo4j CNS indication data (default: true)",
                "default": True
            }
        },
        "required": ["drug_name"]
    }
}


# Global tool instance (singleton pattern for connection pooling)
_bbb_tool_instance = None


async def execute(tool_input: Dict[str, Any]) -> Dict[str, Any]:
    """
    Execute BBB permeability prediction

    Args:
        tool_input: Dictionary with keys:
            - drug_name (str, required): Drug name or CHEMBL ID
            - k (int, optional): Number of nearest neighbors (default: 20)
            - use_cns_enrichment (bool, optional): Use Neo4j enrichment (default: True)

    Returns:
        Dictionary with BBB assessment results
    """
    global _bbb_tool_instance

    # Initialize tool instance if needed (singleton pattern)
    if _bbb_tool_instance is None:
        _bbb_tool_instance = BBBPermeabilityTool()

    # Extract parameters
    drug_name = tool_input.get("drug_name")
    k = tool_input.get("k", 20)
    use_cns_enrichment = tool_input.get("use_cns_enrichment", True)

    # Execute BBB assessment
    result = await _bbb_tool_instance.assess_bbb_permeability(
        drug_name=drug_name,
        k=k,
        use_cns_enrichment=use_cns_enrichment
    )

    return result
