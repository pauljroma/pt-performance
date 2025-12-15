"""
DeMeo v2.0 - Metagraph Client
==============================

Purpose:
--------
Neo4j metagraph client for storing and retrieving DeMeo rescue patterns,
disease signatures, and mechanism clusters.

Features:
---------
- Store LearnedRescuePattern nodes (drug rescue predictions)
- Store DiseaseSignature nodes (multi-modal v-scores)
- Store MechanismCluster nodes (mechanism-based groupings)
- Query patterns with confidence thresholds
- Query disease signatures for genes
- Pattern caching for 100-1000x speedup
- Active learning support (cycle tracking, validation status)

Architecture:
------------
DeMeo → DeMeoMetagraphClient → Neo4j Metagraph

Node Types:
-----------
1. LearnedRescuePattern: Drug rescue predictions with explainability
   - Properties: pattern_id, gene, disease, consensus_score, confidence,
                tool_contributions, cycle, discovered_at, validated

2. DiseaseSignature: Multi-modal disease v-scores
   - Properties: signature_id, gene, disease, v_score_summary,
                modex_weight, ens_weight, lincs_weight, cycle

3. MechanismCluster: Mechanism-based drug clusters
   - Properties: cluster_id, mechanism, member_count, validated_targets

Author: DeMeo Integration Team
Date: 2025-12-03
Version: 2.0.0-alpha1
Zone: z07_data_access
"""

from typing import Dict, Any, List, Optional
from dataclasses import dataclass, asdict
from datetime import datetime
import logging
import json
import uuid

logger = logging.getLogger(__name__)


@dataclass
class LearnedRescuePattern:
    """
    Drug rescue pattern learned by DeMeo

    Represents a single drug's rescue prediction for a gene-disease pair,
    with full explainability (tool contributions, consensus score, confidence).
    """
    pattern_id: str
    gene: str
    disease: str
    drug: str
    consensus_score: float
    confidence: float
    tool_contributions: Dict[str, float]
    modex_vscore: float
    ens_vscore: float
    lincs_vscore: float
    agreement_coefficient: float
    cycle: int
    discovered_at: str
    validated: Optional[bool] = None
    validation_date: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None


@dataclass
class DiseaseSignature:
    """
    Multi-modal disease signature (v-scores)

    Stores aggregated v-scores from MODEX/ENS/LINCS for a gene-disease pair.
    """
    signature_id: str
    gene: str
    disease: str
    v_score_summary: Dict[str, float]  # {"modex": X, "ens": Y, "lincs": Z}
    modex_weight: float
    ens_weight: float
    lincs_weight: float
    cycle: int
    created_at: str
    metadata: Optional[Dict[str, Any]] = None


@dataclass
class MechanismCluster:
    """
    Mechanism-based drug cluster

    Groups drugs by shared mechanisms of action.
    """
    cluster_id: str
    mechanism: str
    member_drugs: List[str]
    member_count: int
    validated_targets: List[str]
    discovered_cycle: int
    created_at: str
    metadata: Optional[Dict[str, Any]] = None


class DeMeoMetagraphClient:
    """
    Neo4j client for DeMeo metagraph operations

    This client provides a simple interface for storing and retrieving
    DeMeo patterns, signatures, and clusters in the Neo4j metagraph.

    Usage:
        client = DeMeoMetagraphClient(neo4j_driver)

        # Store a rescue pattern
        pattern = LearnedRescuePattern(...)
        await client.store_rescue_pattern(pattern)

        # Query cached patterns
        patterns = await client.query_rescue_patterns("SCN1A", "Dravet Syndrome")

    Note:
        Requires Neo4j migrations to be applied first:
        - demeo_schema_v1.cypher (constraints)
        - demeo_indexes_v1.cypher (12 indexes)
        - demeo_edges_v1.cypher (relationships)
    """

    def __init__(self, neo4j_driver):
        """
        Initialize metagraph client

        Args:
            neo4j_driver: Neo4j GraphDatabase.driver instance
        """
        self.neo4j = neo4j_driver
        logger.info("DeMeoMetagraphClient initialized")

    async def store_rescue_pattern(
        self,
        pattern: LearnedRescuePattern
    ) -> Dict[str, Any]:
        """
        Store a learned rescue pattern in the metagraph

        This creates or updates a LearnedRescuePattern node in Neo4j,
        enabling instant retrieval for future queries (caching).

        Args:
            pattern: LearnedRescuePattern to store

        Returns:
            Dict with status and pattern_id

        Example:
            pattern = LearnedRescuePattern(
                pattern_id=str(uuid.uuid4()),
                gene="SCN1A",
                disease="Dravet Syndrome",
                drug="Stiripentol",
                consensus_score=0.87,
                confidence=0.92,
                tool_contributions={"vector_antipodal": 0.15, ...},
                modex_vscore=0.82,
                ens_vscore=0.79,
                lincs_vscore=0.85,
                agreement_coefficient=0.88,
                cycle=1,
                discovered_at="2025-12-03T00:00:00Z"
            )
            result = await client.store_rescue_pattern(pattern)
        """
        cypher = '''
        MERGE (p:LearnedRescuePattern {pattern_id: $pattern_id})
        SET p.gene = $gene,
            p.disease = $disease,
            p.drug = $drug,
            p.consensus_score = $consensus_score,
            p.confidence = $confidence,
            p.tool_contributions = $tool_contributions_json,
            p.modex_vscore = $modex_vscore,
            p.ens_vscore = $ens_vscore,
            p.lincs_vscore = $lincs_vscore,
            p.agreement_coefficient = $agreement_coefficient,
            p.cycle = $cycle,
            p.discovered_at = datetime($discovered_at),
            p.validated = $validated,
            p.validation_date = datetime($validation_date),
            p.metadata = $metadata_json,
            p.updated_at = datetime()
        RETURN p.pattern_id as pattern_id, p.consensus_score as score
        '''

        params = {
            'pattern_id': pattern.pattern_id,
            'gene': pattern.gene,
            'disease': pattern.disease,
            'drug': pattern.drug,
            'consensus_score': pattern.consensus_score,
            'confidence': pattern.confidence,
            'tool_contributions_json': json.dumps(pattern.tool_contributions),
            'modex_vscore': pattern.modex_vscore,
            'ens_vscore': pattern.ens_vscore,
            'lincs_vscore': pattern.lincs_vscore,
            'agreement_coefficient': pattern.agreement_coefficient,
            'cycle': pattern.cycle,
            'discovered_at': pattern.discovered_at,
            'validated': pattern.validated,
            'validation_date': pattern.validation_date if pattern.validation_date else None,
            'metadata_json': json.dumps(pattern.metadata) if pattern.metadata else "{}"
        }

        try:
            with self.neo4j.session() as session:
                result = session.run(cypher, **params)
                record = result.single()

                logger.info(f"Stored rescue pattern: {pattern.gene}-{pattern.disease}-{pattern.drug} "
                           f"(score={pattern.consensus_score:.3f})")

                return {
                    'success': True,
                    'pattern_id': record['pattern_id'],
                    'score': record['score']
                }

        except Exception as e:
            logger.error(f"Failed to store rescue pattern: {e}")
            return {
                'success': False,
                'error': str(e)
            }

    async def query_rescue_patterns(
        self,
        gene: str,
        disease: str,
        min_confidence: float = 0.70,
        limit: int = 20
    ) -> List[LearnedRescuePattern]:
        """
        Query cached rescue patterns from metagraph

        This provides instant retrieval of previously computed rankings,
        avoiding expensive recomputation (100-1000x speedup).

        Args:
            gene: Gene symbol
            disease: Disease name
            min_confidence: Minimum confidence threshold (0-1)
            limit: Maximum number of patterns to return

        Returns:
            List of LearnedRescuePattern objects, sorted by consensus_score DESC

        Example:
            patterns = await client.query_rescue_patterns("SCN1A", "Dravet Syndrome")
            for pattern in patterns:
                print(f"{pattern.drug}: {pattern.consensus_score:.3f}")
        """
        cypher = '''
        MATCH (p:LearnedRescuePattern {gene: $gene, disease: $disease})
        WHERE p.confidence >= $min_confidence
        RETURN p
        ORDER BY p.consensus_score DESC
        LIMIT $limit
        '''

        params = {
            'gene': gene,
            'disease': disease,
            'min_confidence': min_confidence,
            'limit': limit
        }

        try:
            with self.neo4j.session() as session:
                result = session.run(cypher, **params)

                patterns = []
                for record in result:
                    node = record['p']
                    pattern = self._parse_rescue_pattern_node(node)
                    patterns.append(pattern)

                logger.info(f"Retrieved {len(patterns)} cached patterns for {gene}-{disease}")
                return patterns

        except Exception as e:
            logger.error(f"Failed to query rescue patterns: {e}")
            return []

    async def store_disease_signature(
        self,
        signature: DiseaseSignature
    ) -> Dict[str, Any]:
        """
        Store a disease signature in the metagraph

        Disease signatures store multi-modal v-scores for gene-disease pairs,
        enabling fast lookup for signature-based analyses.

        Args:
            signature: DiseaseSignature to store

        Returns:
            Dict with status and signature_id
        """
        cypher = '''
        MERGE (sig:DiseaseSignature {signature_id: $signature_id})
        SET sig.gene = $gene,
            sig.disease = $disease,
            sig.v_score_summary = $v_score_summary_json,
            sig.modex_weight = $modex_weight,
            sig.ens_weight = $ens_weight,
            sig.lincs_weight = $lincs_weight,
            sig.cycle = $cycle,
            sig.created_at = datetime($created_at),
            sig.metadata = $metadata_json,
            sig.updated_at = datetime()
        RETURN sig.signature_id as signature_id
        '''

        params = {
            'signature_id': signature.signature_id,
            'gene': signature.gene,
            'disease': signature.disease,
            'v_score_summary_json': json.dumps(signature.v_score_summary),
            'modex_weight': signature.modex_weight,
            'ens_weight': signature.ens_weight,
            'lincs_weight': signature.lincs_weight,
            'cycle': signature.cycle,
            'created_at': signature.created_at,
            'metadata_json': json.dumps(signature.metadata) if signature.metadata else "{}"
        }

        try:
            with self.neo4j.session() as session:
                result = session.run(cypher, **params)
                record = result.single()

                logger.info(f"Stored disease signature: {signature.gene}-{signature.disease}")

                return {
                    'success': True,
                    'signature_id': record['signature_id']
                }

        except Exception as e:
            logger.error(f"Failed to store disease signature: {e}")
            return {
                'success': False,
                'error': str(e)
            }

    async def query_disease_signature(
        self,
        gene: str,
        disease: str
    ) -> Optional[DiseaseSignature]:
        """
        Query disease signature for a gene-disease pair

        Args:
            gene: Gene symbol
            disease: Disease name

        Returns:
            DiseaseSignature if found, None otherwise
        """
        cypher = '''
        MATCH (sig:DiseaseSignature {gene: $gene, disease: $disease})
        RETURN sig
        ORDER BY sig.cycle DESC
        LIMIT 1
        '''

        params = {
            'gene': gene,
            'disease': disease
        }

        try:
            with self.neo4j.session() as session:
                result = session.run(cypher, **params)
                record = result.single()

                if not record:
                    return None

                signature = self._parse_disease_signature_node(record['sig'])
                logger.info(f"Retrieved disease signature for {gene}-{disease}")
                return signature

        except Exception as e:
            logger.error(f"Failed to query disease signature: {e}")
            return None

    async def update_pattern_validation(
        self,
        pattern_id: str,
        validated: bool,
        validation_date: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Update validation status for a rescue pattern

        This supports active learning by tracking which patterns have been
        experimentally validated.

        Args:
            pattern_id: Pattern ID
            validated: True if validated, False if invalidated
            validation_date: ISO datetime string (defaults to now)

        Returns:
            Dict with status
        """
        if validation_date is None:
            validation_date = datetime.utcnow().isoformat() + "Z"

        cypher = '''
        MATCH (p:LearnedRescuePattern {pattern_id: $pattern_id})
        SET p.validated = $validated,
            p.validation_date = datetime($validation_date),
            p.updated_at = datetime()
        RETURN p.pattern_id as pattern_id, p.validated as validated
        '''

        params = {
            'pattern_id': pattern_id,
            'validated': validated,
            'validation_date': validation_date
        }

        try:
            with self.neo4j.session() as session:
                result = session.run(cypher, **params)
                record = result.single()

                if not record:
                    return {
                        'success': False,
                        'error': f'Pattern {pattern_id} not found'
                    }

                logger.info(f"Updated validation for pattern {pattern_id}: validated={validated}")

                return {
                    'success': True,
                    'pattern_id': record['pattern_id'],
                    'validated': record['validated']
                }

        except Exception as e:
            logger.error(f"Failed to update pattern validation: {e}")
            return {
                'success': False,
                'error': str(e)
            }

    async def store_mechanism_cluster(
        self,
        cluster: MechanismCluster
    ) -> Dict[str, Any]:
        """
        Store a mechanism cluster in the metagraph

        Args:
            cluster: MechanismCluster to store

        Returns:
            Dict with status and cluster_id
        """
        cypher = '''
        MERGE (c:MechanismCluster {cluster_id: $cluster_id})
        SET c.mechanism = $mechanism,
            c.member_drugs = $member_drugs,
            c.member_count = $member_count,
            c.validated_targets = $validated_targets,
            c.discovered_cycle = $discovered_cycle,
            c.created_at = datetime($created_at),
            c.metadata = $metadata_json,
            c.updated_at = datetime()
        RETURN c.cluster_id as cluster_id
        '''

        params = {
            'cluster_id': cluster.cluster_id,
            'mechanism': cluster.mechanism,
            'member_drugs': cluster.member_drugs,
            'member_count': cluster.member_count,
            'validated_targets': cluster.validated_targets,
            'discovered_cycle': cluster.discovered_cycle,
            'created_at': cluster.created_at,
            'metadata_json': json.dumps(cluster.metadata) if cluster.metadata else "{}"
        }

        try:
            with self.neo4j.session() as session:
                result = session.run(cypher, **params)
                record = result.single()

                logger.info(f"Stored mechanism cluster: {cluster.mechanism} ({cluster.member_count} drugs)")

                return {
                    'success': True,
                    'cluster_id': record['cluster_id']
                }

        except Exception as e:
            logger.error(f"Failed to store mechanism cluster: {e}")
            return {
                'success': False,
                'error': str(e)
            }

    def _parse_rescue_pattern_node(self, node) -> LearnedRescuePattern:
        """Parse Neo4j node into LearnedRescuePattern"""
        tool_contributions = json.loads(node['tool_contributions']) if isinstance(node['tool_contributions'], str) else node['tool_contributions']
        metadata = json.loads(node.get('metadata', '{}')) if isinstance(node.get('metadata'), str) else node.get('metadata', {})

        return LearnedRescuePattern(
            pattern_id=node['pattern_id'],
            gene=node['gene'],
            disease=node['disease'],
            drug=node['drug'],
            consensus_score=node['consensus_score'],
            confidence=node['confidence'],
            tool_contributions=tool_contributions,
            modex_vscore=node['modex_vscore'],
            ens_vscore=node['ens_vscore'],
            lincs_vscore=node['lincs_vscore'],
            agreement_coefficient=node['agreement_coefficient'],
            cycle=node['cycle'],
            discovered_at=node['discovered_at'].isoformat() if hasattr(node['discovered_at'], 'isoformat') else node['discovered_at'],
            validated=node.get('validated'),
            validation_date=node.get('validation_date').isoformat() if node.get('validation_date') and hasattr(node.get('validation_date'), 'isoformat') else node.get('validation_date'),
            metadata=metadata
        )

    def _parse_disease_signature_node(self, node) -> DiseaseSignature:
        """Parse Neo4j node into DiseaseSignature"""
        v_score_summary = json.loads(node['v_score_summary']) if isinstance(node['v_score_summary'], str) else node['v_score_summary']
        metadata = json.loads(node.get('metadata', '{}')) if isinstance(node.get('metadata'), str) else node.get('metadata', {})

        return DiseaseSignature(
            signature_id=node['signature_id'],
            gene=node['gene'],
            disease=node['disease'],
            v_score_summary=v_score_summary,
            modex_weight=node['modex_weight'],
            ens_weight=node['ens_weight'],
            lincs_weight=node['lincs_weight'],
            cycle=node['cycle'],
            created_at=node['created_at'].isoformat() if hasattr(node['created_at'], 'isoformat') else node['created_at'],
            metadata=metadata
        )

    async def get_stats(self) -> Dict[str, Any]:
        """
        Get statistics about stored patterns

        Returns:
            Dict with counts and statistics
        """
        cypher = '''
        MATCH (p:LearnedRescuePattern)
        WITH COUNT(p) as pattern_count,
             AVG(p.consensus_score) as avg_score,
             AVG(p.confidence) as avg_confidence
        MATCH (sig:DiseaseSignature)
        WITH pattern_count, avg_score, avg_confidence, COUNT(sig) as signature_count
        MATCH (c:MechanismCluster)
        RETURN pattern_count, avg_score, avg_confidence, signature_count, COUNT(c) as cluster_count
        '''

        try:
            with self.neo4j.session() as session:
                result = session.run(cypher)
                record = result.single()

                if not record:
                    return {
                        'pattern_count': 0,
                        'signature_count': 0,
                        'cluster_count': 0
                    }

                return {
                    'pattern_count': record['pattern_count'],
                    'signature_count': record['signature_count'],
                    'cluster_count': record['cluster_count'],
                    'avg_consensus_score': record['avg_score'],
                    'avg_confidence': record['avg_confidence']
                }

        except Exception as e:
            logger.error(f"Failed to get stats: {e}")
            return {
                'error': str(e)
            }


# ============================================================================
# Factory Function
# ============================================================================

def get_demeo_metagraph_client(neo4j_driver) -> DeMeoMetagraphClient:
    """
    Factory function to create DeMeoMetagraphClient

    Args:
        neo4j_driver: Neo4j GraphDatabase.driver instance

    Returns:
        DeMeoMetagraphClient instance

    Usage:
        from neo4j import GraphDatabase
        from zones.z07_data_access.demeo.metagraph_client import get_demeo_metagraph_client

        driver = GraphDatabase.driver("bolt://localhost:7687", auth=("neo4j", "password"))
        client = get_demeo_metagraph_client(driver)

        # Store a pattern
        pattern = LearnedRescuePattern(...)
        await client.store_rescue_pattern(pattern)

        # Query patterns
        patterns = await client.query_rescue_patterns("SCN1A", "Dravet Syndrome")
    """
    return DeMeoMetagraphClient(neo4j_driver)
