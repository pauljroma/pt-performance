"""
MOA/Pathway Expansion Service with Resolver Integration
========================================================

Zone: z07_data_access
Purpose: Extend drug predictions using MOA and chemical similarity

Provides multi-strategy drug similarity search for BBB prediction expansion
when direct matches are unavailable:

1. Direct matches (100% confidence)
2. MOA-based expansion via gene targets (75% × Jaccard confidence)
3. Chemical structure similarity via Tanimoto (50% × Tanimoto confidence)

Key Integrations:
- GeneNameResolver: Normalizes gene symbols using HGNC cache (9,886+ genes)
- ChemicalResolver: Calculates Tanimoto similarity using RDKit Morgan fingerprints
- Neo4j: Drug-target relationships and SMILES structures

Architecture:
- Uses Neo4j TARGETS relationships (Drug → Gene) with normalized gene symbols
- Computes Jaccard similarity for shared gene targets (MOA similarity)
- Calculates Tanimoto similarity for chemical structures
- Returns functionally and structurally similar drugs for prediction expansion

Performance:
- Gene normalization: <10ms with LRU cache
- Chemical similarity: Morgan fingerprints (radius=2, 2048 bits)
- Expected coverage improvement: +30-40% vs MOA-only

Author: Phase 5A Implementation + Resolver Integration
Date: 2025-12-01
Version: 2.0.0
"""

from typing import Dict, List, Set, Optional, Any, Tuple
import logging
from neo4j import GraphDatabase
from dataclasses import dataclass

from .meta_layer.resolvers.gene_name_resolver import get_gene_name_resolver
from .meta_layer.resolvers.chemical_resolver import get_chemical_resolver

logger = logging.getLogger(__name__)


@dataclass
class MOASimilarity:
    """Drug with MOA similarity to query drug"""
    drug_name: str
    chembl_id: str
    jaccard_similarity: float
    shared_targets: int
    total_targets: int
    shared_genes: List[str]


@dataclass
class ChemicalSimilarity:
    """Drug with chemical structure similarity to query drug"""
    drug_name: str
    chembl_id: str
    smiles: str
    tanimoto_similarity: float
    confidence: float  # 0.5 * tanimoto_similarity


class MOAExpansionService:
    """
    Multi-strategy drug similarity service for BBB prediction expansion

    Integrates:
    - GeneNameResolver: Normalizes gene targets (UniProt → HGNC symbols)
    - ChemicalResolver: Calculates Tanimoto similarity for structures
    - Neo4j: Drug-target relationships and SMILES data

    Usage:
        service = MOAExpansionService(neo4j_uri, neo4j_password)

        # Find drugs with similar MOA (gene targets)
        moa_similar = service.find_moa_similar_drugs(
            chembl_id="CHEMBL113",
            min_jaccard=0.3
        )

        # Find drugs with similar chemical structure
        chem_similar = service.find_similar_drugs_by_smiles(
            chembl_id="CHEMBL113",
            reference_dataset=bbb_dataset,
            min_tanimoto=0.6
        )

        # Expand predictions with combined strategies
        predictions = service.expand_predictions_with_moa(
            neighbors_without_data=[...],
            reference_dataset=bbb_dataset,
            min_jaccard=0.3,
            min_tanimoto=0.6,
            use_chemical_similarity=True
        )

        # Returns combined results:
        # - Direct matches (100% confidence)
        # - MOA matches (75% × Jaccard)
        # - Chemical matches (50% × Tanimoto)
    """

    def __init__(
        self,
        neo4j_uri: str = "bolt://localhost:7687",
        neo4j_user: str = "neo4j",
        neo4j_password: Optional[str] = None
    ):
        """
        Initialize MOA expansion service

        Args:
            neo4j_uri: Neo4j connection URI
            neo4j_user: Neo4j username
            neo4j_password: Neo4j password
        """
        if not neo4j_password:
            import os
            neo4j_password = os.getenv('NEO4J_PASSWORD', 'password')

        self.neo4j_uri = neo4j_uri
        self.neo4j_user = neo4j_user
        self.neo4j_password = neo4j_password
        self.driver = None

        # Initialize resolvers
        self.gene_resolver = get_gene_name_resolver()
        self.chemical_resolver = get_chemical_resolver()

        # Cache for drug targets
        self._target_cache: Dict[str, Set[str]] = {}

        logger.info("MOA Expansion Service initialized with GeneNameResolver and ChemicalResolver")

    def _get_driver(self):
        """Lazy initialize Neo4j driver"""
        if self.driver is None:
            self.driver = GraphDatabase.driver(
                self.neo4j_uri,
                auth=(self.neo4j_user, self.neo4j_password)
            )
        return self.driver

    def get_drug_targets(
        self,
        drug_name: Optional[str] = None,
        chembl_id: Optional[str] = None,
        normalize_genes: bool = True
    ) -> Set[str]:
        """
        Get gene targets for a drug from Neo4j with optional gene normalization

        Args:
            drug_name: Drug name (optional)
            chembl_id: CHEMBL ID (optional, preferred)
            normalize_genes: Use GeneNameResolver to normalize gene symbols (default: True)

        Returns:
            Set of normalized gene symbols targeted by this drug
        """
        # Check cache first
        cache_key = chembl_id or drug_name
        if cache_key and cache_key in self._target_cache:
            return self._target_cache[cache_key]

        targets = set()

        try:
            driver = self._get_driver()
            with driver.session() as session:
                # Query 1: Match by CHEMBL ID (most reliable)
                if chembl_id:
                    result = session.run("""
                        MATCH (d:Drug {chembl_id: $chembl_id})-[:TARGETS]->(g:Gene)
                        RETURN DISTINCT g.symbol as gene_symbol, g.uniprot_id as uniprot_id
                    """, chembl_id=chembl_id)

                    for record in result:
                        gene_symbol = record.get('gene_symbol')
                        uniprot_id = record.get('uniprot_id')

                        if normalize_genes:
                            # Try to resolve by UniProt first (most reliable)
                            if uniprot_id:
                                resolved = self.gene_resolver.resolve_by_uniprot(uniprot_id)
                                if resolved:
                                    targets.add(resolved)
                                    continue

                            # Fall back to gene symbol normalization
                            if gene_symbol:
                                resolved_result = self.gene_resolver.resolve(gene_symbol)
                                if resolved_result.get('confidence', 0) > 0:
                                    normalized_symbol = resolved_result['result'].get('hgnc_symbol')
                                    if normalized_symbol:
                                        targets.add(normalized_symbol)
                                else:
                                    # Use original if normalization fails
                                    targets.add(gene_symbol)
                        else:
                            if gene_symbol:
                                targets.add(gene_symbol)

                # Query 2: Match by drug name (fallback)
                if not targets and drug_name:
                    result = session.run("""
                        MATCH (d:Drug)-[:TARGETS]->(g:Gene)
                        WHERE toLower(d.name) = toLower($drug_name)
                        RETURN DISTINCT g.symbol as gene_symbol, g.uniprot_id as uniprot_id
                    """, drug_name=drug_name)

                    for record in result:
                        gene_symbol = record.get('gene_symbol')
                        uniprot_id = record.get('uniprot_id')

                        if normalize_genes:
                            # Try to resolve by UniProt first
                            if uniprot_id:
                                resolved = self.gene_resolver.resolve_by_uniprot(uniprot_id)
                                if resolved:
                                    targets.add(resolved)
                                    continue

                            # Fall back to gene symbol normalization
                            if gene_symbol:
                                resolved_result = self.gene_resolver.resolve(gene_symbol)
                                if resolved_result.get('confidence', 0) > 0:
                                    normalized_symbol = resolved_result['result'].get('hgnc_symbol')
                                    if normalized_symbol:
                                        targets.add(normalized_symbol)
                                else:
                                    targets.add(gene_symbol)
                        else:
                            if gene_symbol:
                                targets.add(gene_symbol)

            # Cache result
            if cache_key:
                self._target_cache[cache_key] = targets

            logger.debug(f"Found {len(targets)} normalized targets for {cache_key}")

        except Exception as e:
            logger.warning(f"Failed to get drug targets for {cache_key}: {e}")

        return targets

    def get_drug_smiles(
        self,
        drug_name: Optional[str] = None,
        chembl_id: Optional[str] = None
    ) -> Optional[str]:
        """
        Get SMILES string for a drug from Neo4j

        Args:
            drug_name: Drug name (optional)
            chembl_id: CHEMBL ID (optional, preferred)

        Returns:
            SMILES string or None if not found
        """
        try:
            driver = self._get_driver()
            with driver.session() as session:
                # Query by CHEMBL ID (most reliable)
                if chembl_id:
                    result = session.run("""
                        MATCH (d:Drug {chembl_id: $chembl_id})
                        RETURN d.smiles as smiles
                        LIMIT 1
                    """, chembl_id=chembl_id)

                    record = result.single()
                    if record and record['smiles']:
                        return record['smiles']

                # Query by drug name (fallback)
                if drug_name:
                    result = session.run("""
                        MATCH (d:Drug)
                        WHERE toLower(d.name) = toLower($drug_name)
                        RETURN d.smiles as smiles
                        LIMIT 1
                    """, drug_name=drug_name)

                    record = result.single()
                    if record and record['smiles']:
                        return record['smiles']

        except Exception as e:
            logger.warning(f"Failed to get SMILES for {chembl_id or drug_name}: {e}")

        return None

    def get_reference_drugs_with_smiles(
        self,
        reference_dataset: Dict[str, Any]
    ) -> List[Tuple[str, str, str]]:
        """
        Get SMILES strings for all drugs in reference dataset

        Args:
            reference_dataset: Dict mapping CHEMBL ID → reference data

        Returns:
            List of (chembl_id, drug_name, smiles) tuples
        """
        drugs_with_smiles = []

        try:
            driver = self._get_driver()
            with driver.session() as session:
                # Batch query for all reference drugs
                result = session.run("""
                    MATCH (d:Drug)
                    WHERE d.chembl_id IN $chembl_ids AND d.smiles IS NOT NULL
                    RETURN d.chembl_id as chembl_id, d.name as drug_name, d.smiles as smiles
                """, chembl_ids=list(reference_dataset.keys()))

                for record in result:
                    chembl_id = record['chembl_id']
                    drug_name = record['drug_name']
                    smiles = record['smiles']

                    if chembl_id and drug_name and smiles:
                        drugs_with_smiles.append((chembl_id, drug_name, smiles))

            logger.info(f"Found SMILES for {len(drugs_with_smiles)}/{len(reference_dataset)} reference drugs")

        except Exception as e:
            logger.error(f"Failed to get reference drug SMILES: {e}")

        return drugs_with_smiles

    def find_similar_drugs_by_smiles(
        self,
        drug_name: Optional[str] = None,
        chembl_id: Optional[str] = None,
        smiles: Optional[str] = None,
        reference_dataset: Optional[Dict[str, Any]] = None,
        min_tanimoto: float = 0.6,
        max_results: int = 50
    ) -> List[ChemicalSimilarity]:
        """
        Find drugs with similar chemical structure using Tanimoto similarity

        Args:
            drug_name: Query drug name (optional)
            chembl_id: Query drug CHEMBL ID (optional)
            smiles: Query drug SMILES (optional, if not provided will be fetched)
            reference_dataset: Dict mapping CHEMBL ID → reference data (optional)
            min_tanimoto: Minimum Tanimoto similarity threshold (0-1)
            max_results: Maximum number of results to return

        Returns:
            List of ChemicalSimilarity objects, sorted by Tanimoto similarity (descending)
        """
        # Step 1: Get query SMILES
        query_smiles = smiles
        if not query_smiles:
            query_smiles = self.get_drug_smiles(drug_name, chembl_id)

        if not query_smiles:
            logger.warning(f"No SMILES found for {chembl_id or drug_name}")
            return []

        # Validate SMILES
        if not self.chemical_resolver.validate_smiles(query_smiles):
            logger.warning(f"Invalid SMILES for {chembl_id or drug_name}: {query_smiles}")
            return []

        logger.debug(f"Query drug SMILES: {query_smiles}")

        # Step 2: Get reference drugs with SMILES
        if reference_dataset:
            # Use provided reference dataset
            reference_drugs = self.get_reference_drugs_with_smiles(reference_dataset)
        else:
            # Query all drugs from Neo4j
            try:
                driver = self._get_driver()
                with driver.session() as session:
                    result = session.run("""
                        MATCH (d:Drug)
                        WHERE d.smiles IS NOT NULL
                        AND ($chembl_id IS NULL OR d.chembl_id <> $chembl_id)
                        RETURN d.chembl_id as chembl_id, d.name as drug_name, d.smiles as smiles
                        LIMIT 10000
                    """, chembl_id=chembl_id)

                    reference_drugs = [
                        (record['chembl_id'], record['drug_name'], record['smiles'])
                        for record in result
                        if record['chembl_id'] and record['drug_name'] and record['smiles']
                    ]

            except Exception as e:
                logger.error(f"Failed to get reference drugs: {e}")
                return []

        if not reference_drugs:
            logger.warning("No reference drugs with SMILES found")
            return []

        logger.info(f"Comparing against {len(reference_drugs)} reference drugs")

        # Step 3: Calculate Tanimoto similarity for all reference drugs
        similar_drugs = []

        # Prepare reference list for ChemicalResolver
        reference_smiles_list = [(name, smiles_str) for _, name, smiles_str in reference_drugs]

        # Use ChemicalResolver to find similar structures
        similar_structures = self.chemical_resolver.find_similar_structures(
            query_smiles=query_smiles,
            reference_smiles_list=reference_smiles_list,
            min_tanimoto=min_tanimoto
        )

        # Convert to ChemicalSimilarity objects
        for struct in similar_structures:
            # Find matching CHEMBL ID
            matching_drug = next(
                (d for d in reference_drugs if d[1] == struct['drug_name']),
                None
            )

            if matching_drug:
                chembl_id_match, drug_name_match, smiles_match = matching_drug

                similar_drugs.append(ChemicalSimilarity(
                    drug_name=drug_name_match,
                    chembl_id=chembl_id_match,
                    smiles=smiles_match,
                    tanimoto_similarity=struct['tanimoto'],
                    confidence=struct['confidence']  # Already 0.5 * tanimoto
                ))

        # Sort by Tanimoto similarity (descending)
        similar_drugs.sort(key=lambda x: x.tanimoto_similarity, reverse=True)

        logger.info(f"Found {len(similar_drugs)} chemically similar drugs (Tanimoto >= {min_tanimoto})")

        return similar_drugs[:max_results]

    def find_moa_similar_drugs(
        self,
        drug_name: Optional[str] = None,
        chembl_id: Optional[str] = None,
        min_jaccard: float = 0.3,
        max_results: int = 50
    ) -> List[MOASimilarity]:
        """
        Find drugs with similar MOA (shared gene targets)

        Args:
            drug_name: Query drug name (optional)
            chembl_id: Query drug CHEMBL ID (optional, preferred)
            min_jaccard: Minimum Jaccard similarity threshold (0-1)
            max_results: Maximum number of results to return

        Returns:
            List of MOASimilarity objects, sorted by Jaccard similarity (descending)
        """
        # Step 1: Get targets for query drug
        query_targets = self.get_drug_targets(drug_name, chembl_id)

        if not query_targets:
            logger.warning(f"No targets found for {chembl_id or drug_name}")
            return []

        logger.debug(f"Query drug has {len(query_targets)} targets")

        # Step 2: Find drugs sharing these targets
        similar_drugs = []

        try:
            driver = self._get_driver()
            with driver.session() as session:
                # Find all drugs that target any of the same genes
                result = session.run("""
                    MATCH (d1:Drug)-[:TARGETS]->(g:Gene)<-[:TARGETS]-(d2:Drug)
                    WHERE g.symbol IN $target_genes
                    AND d1 <> d2
                    AND ($chembl_id IS NULL OR d1.chembl_id = $chembl_id)
                    AND ($drug_name IS NULL OR toLower(d1.name) = toLower($drug_name))
                    RETURN DISTINCT
                        d2.name as drug_name,
                        d2.chembl_id as chembl_id,
                        collect(DISTINCT g.symbol) as shared_genes
                """, {
                    "target_genes": list(query_targets),
                    "chembl_id": chembl_id,
                    "drug_name": drug_name
                })

                for record in result:
                    similar_drug_name = record['drug_name']
                    similar_chembl_id = record['chembl_id']
                    shared_genes = set(record['shared_genes'])

                    if not similar_drug_name or not similar_chembl_id:
                        continue

                    # Get all targets for similar drug (may include more than shared)
                    similar_targets = self.get_drug_targets(
                        drug_name=similar_drug_name,
                        chembl_id=similar_chembl_id
                    )

                    if not similar_targets:
                        continue

                    # Compute Jaccard similarity
                    intersection = len(query_targets & similar_targets)
                    union = len(query_targets | similar_targets)

                    if union > 0:
                        jaccard = intersection / union

                        if jaccard >= min_jaccard:
                            similar_drugs.append(MOASimilarity(
                                drug_name=similar_drug_name,
                                chembl_id=similar_chembl_id,
                                jaccard_similarity=jaccard,
                                shared_targets=len(shared_genes),
                                total_targets=len(similar_targets),
                                shared_genes=sorted(list(shared_genes))[:10]  # Limit to first 10
                            ))

        except Exception as e:
            logger.error(f"MOA similarity search failed: {e}", exc_info=True)
            return []

        # Sort by Jaccard similarity (descending)
        similar_drugs.sort(key=lambda x: x.jaccard_similarity, reverse=True)

        logger.info(f"Found {len(similar_drugs)} MOA-similar drugs (Jaccard >= {min_jaccard})")

        return similar_drugs[:max_results]

    def expand_predictions_with_moa(
        self,
        neighbors_without_data: List[Dict[str, Any]],
        reference_dataset: Dict[str, Any],
        min_jaccard: float = 0.3,
        min_tanimoto: float = 0.6,
        use_chemical_similarity: bool = True
    ) -> List[Dict[str, Any]]:
        """
        Expand predictions using MOA and chemical similarity

        This is a higher-level function that takes a list of K-NN neighbors
        without reference data and attempts to find similar drugs (via MOA or
        chemical structure) that DO have reference data.

        Args:
            neighbors_without_data: List of dicts with keys:
                - drug_name: str
                - chembl_id: str
                - similarity: float (K-NN similarity)
            reference_dataset: Dict mapping CHEMBL ID → reference data
            min_jaccard: Minimum MOA Jaccard similarity (default: 0.3)
            min_tanimoto: Minimum chemical Tanimoto similarity (default: 0.6)
            use_chemical_similarity: Enable chemical similarity search (default: True)

        Returns:
            List of expanded predictions with keys:
                - original_drug: str
                - original_chembl: str
                - matched_drug: str
                - matched_chembl: str
                - similarity_score: float (MOA jaccard or chemical tanimoto)
                - knn_similarity: float (original K-NN similarity)
                - reference_data: dict (from reference_dataset)
                - confidence: float (combined confidence score)
                - source: str ('moa_expansion' or 'chemical_expansion')
                - match_type: str ('direct', 'moa', or 'chemical')
        """
        expanded_predictions = []
        seen_matches = set()  # Track (original_chembl, matched_chembl) to avoid duplicates

        for i, neighbor in enumerate(neighbors_without_data, 1):
            drug_name = neighbor.get('drug_name')
            chembl_id = neighbor.get('chembl_id')
            knn_similarity = neighbor.get('similarity', 1.0)

            logger.debug(f"Processing neighbor {i}/{len(neighbors_without_data)}: {drug_name}")

            # Check if this is a direct match (already in reference dataset)
            if chembl_id in reference_dataset:
                match_key = (chembl_id, chembl_id)
                if match_key not in seen_matches:
                    expanded_predictions.append({
                        'original_drug': drug_name,
                        'original_chembl': chembl_id,
                        'matched_drug': drug_name,
                        'matched_chembl': chembl_id,
                        'similarity_score': 1.0,
                        'knn_similarity': knn_similarity,
                        'reference_data': reference_dataset[chembl_id],
                        'confidence': 1.0,  # 100% confidence for direct matches
                        'source': 'direct_match',
                        'match_type': 'direct'
                    })
                    seen_matches.add(match_key)
                continue

            # Strategy 1: MOA-based expansion (gene target similarity)
            moa_similar_drugs = self.find_moa_similar_drugs(
                drug_name=drug_name,
                chembl_id=chembl_id,
                min_jaccard=min_jaccard,
                max_results=20
            )

            # Check if any MOA-similar drugs are in reference dataset
            for sim_drug in moa_similar_drugs:
                if sim_drug.chembl_id in reference_dataset:
                    match_key = (chembl_id, sim_drug.chembl_id)
                    if match_key not in seen_matches:
                        # Found a MOA match!
                        expanded_predictions.append({
                            'original_drug': drug_name,
                            'original_chembl': chembl_id,
                            'matched_drug': sim_drug.drug_name,
                            'matched_chembl': sim_drug.chembl_id,
                            'similarity_score': sim_drug.jaccard_similarity,
                            'knn_similarity': knn_similarity,
                            'reference_data': reference_dataset[sim_drug.chembl_id],
                            'confidence': 0.75 * sim_drug.jaccard_similarity,  # 75% base × Jaccard
                            'shared_targets': sim_drug.shared_targets,
                            'source': 'moa_expansion',
                            'match_type': 'moa'
                        })
                        seen_matches.add(match_key)

            # Strategy 2: Chemical structure similarity (if enabled and RDKit available)
            if use_chemical_similarity and self.chemical_resolver.rdkit_available:
                try:
                    chem_similar_drugs = self.find_similar_drugs_by_smiles(
                        drug_name=drug_name,
                        chembl_id=chembl_id,
                        reference_dataset=reference_dataset,
                        min_tanimoto=min_tanimoto,
                        max_results=20
                    )

                    # Check if any chemically similar drugs are in reference dataset
                    for chem_drug in chem_similar_drugs:
                        if chem_drug.chembl_id in reference_dataset:
                            match_key = (chembl_id, chem_drug.chembl_id)
                            if match_key not in seen_matches:
                                # Found a chemical similarity match!
                                expanded_predictions.append({
                                    'original_drug': drug_name,
                                    'original_chembl': chembl_id,
                                    'matched_drug': chem_drug.drug_name,
                                    'matched_chembl': chem_drug.chembl_id,
                                    'similarity_score': chem_drug.tanimoto_similarity,
                                    'knn_similarity': knn_similarity,
                                    'reference_data': reference_dataset[chem_drug.chembl_id],
                                    'confidence': chem_drug.confidence,  # 50% base × Tanimoto
                                    'tanimoto_similarity': chem_drug.tanimoto_similarity,
                                    'source': 'chemical_expansion',
                                    'match_type': 'chemical'
                                })
                                seen_matches.add(match_key)

                except Exception as e:
                    logger.warning(f"Chemical similarity search failed for {drug_name}: {e}")

        # Sort by confidence (descending)
        expanded_predictions.sort(key=lambda x: x['confidence'], reverse=True)

        # Log summary statistics
        direct_count = sum(1 for p in expanded_predictions if p['match_type'] == 'direct')
        moa_count = sum(1 for p in expanded_predictions if p['match_type'] == 'moa')
        chemical_count = sum(1 for p in expanded_predictions if p['match_type'] == 'chemical')

        logger.info(
            f"Expansion complete: {len(expanded_predictions)} predictions from {len(neighbors_without_data)} neighbors "
            f"(Direct: {direct_count}, MOA: {moa_count}, Chemical: {chemical_count})"
        )

        return expanded_predictions

    def close(self):
        """Close Neo4j driver"""
        if self.driver:
            self.driver.close()
            self.driver = None

    def __enter__(self):
        """Context manager entry"""
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit"""
        self.close()


# Convenience function for one-off queries
def find_moa_similar_drugs(
    drug_name: Optional[str] = None,
    chembl_id: Optional[str] = None,
    min_jaccard: float = 0.3,
    max_results: int = 50,
    neo4j_uri: str = "bolt://localhost:7687",
    neo4j_password: Optional[str] = None
) -> List[MOASimilarity]:
    """
    Convenience function to find MOA-similar drugs without instantiating service

    Args:
        drug_name: Query drug name
        chembl_id: Query drug CHEMBL ID (preferred)
        min_jaccard: Minimum Jaccard similarity (0-1)
        max_results: Maximum results to return
        neo4j_uri: Neo4j connection URI
        neo4j_password: Neo4j password

    Returns:
        List of MOASimilarity objects
    """
    with MOAExpansionService(neo4j_uri=neo4j_uri, neo4j_password=neo4j_password) as service:
        return service.find_moa_similar_drugs(
            drug_name=drug_name,
            chembl_id=chembl_id,
            min_jaccard=min_jaccard,
            max_results=max_results
        )
