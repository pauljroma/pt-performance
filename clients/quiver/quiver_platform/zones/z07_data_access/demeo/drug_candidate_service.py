"""
Drug Candidate Service for DeMeo v3.0

Queries PostgreSQL for biologically relevant drug candidates for a given gene.
Replaces mock drug names (Drug_1, Drug_2) with real ChEMBL/DrugBank drugs.

Data Sources:
- ChEMBL: 14,246 FDA-approved and investigational drugs
- DrugBank: Drug targets, mechanisms, approval status
- LINCS: Perturbation signatures for gene expression

Author: DeMeo v3.0 Integration Team
Date: 2025-12-03
Zone: z07_data_access/demeo
"""

from typing import List, Dict, Any, Optional
import logging

from zones.z07_data_access.postgres_connection import get_connection

logger = logging.getLogger(__name__)


async def get_drug_candidates_for_gene(
    gene: str,
    top_k: int = 100,
    min_evidence_score: float = 0.1
) -> List[Dict[str, Any]]:
    """
    Query drugs with evidence for rescuing the specified gene.

    Combines multiple evidence sources:
    1. Direct targets: Drugs that target the gene/protein
    2. LINCS perturbations: Drugs that modulate gene expression
    3. Pathway membership: Drugs targeting genes in same pathways

    Args:
        gene: Gene symbol (e.g., 'SCN1A', 'TSC2', 'KCNQ2')
        top_k: Maximum number of candidates to return
        min_evidence_score: Minimum evidence score threshold (0-1)

    Returns:
        List of drug candidates with metadata and evidence scores

    Example:
        >>> candidates = await get_drug_candidates_for_gene('SCN1A', top_k=20)
        >>> candidates[0]
        {
            'drugbank_id': 'DB00794',
            'drug_name': 'Primidone',
            'smiles': 'CCC1(C(=O)NCNC1=O)c2ccccc2',
            'mechanism': 'GABA potentiator',
            'approval_status': 'approved',
            'prior_evidence': 0.85,
            'evidence_types': 'direct_target, lincs_perturbation'
        }
    """
    try:
        async with get_connection() as conn:
            # Query combining multiple evidence sources
            query = """
            WITH gene_drugs AS (
                -- Evidence Source 1: Direct Targets from DrugBank
                SELECT DISTINCT
                    d.drugbank_id,
                    d.drug_name,
                    d.canonical_smiles,
                    d.mechanism_of_action,
                    d.approval_status,
                    1.0 as evidence_score,
                    'direct_target' as evidence_type
                FROM drugs d
                JOIN drug_targets t ON d.drugbank_id = t.drugbank_id
                WHERE UPPER(t.target_gene) = UPPER($1)
                   OR UPPER(t.target_protein) LIKE '%' || UPPER($1) || '%'

                UNION

                -- Evidence Source 2: LINCS Perturbations (gene expression modulation)
                SELECT DISTINCT
                    d.drugbank_id,
                    d.drug_name,
                    d.canonical_smiles,
                    d.mechanism_of_action,
                    d.approval_status,
                    LEAST(ABS(l.z_score) / 10.0, 1.0) as evidence_score,
                    'lincs_perturbation' as evidence_type
                FROM drugs d
                JOIN lincs_perturbations l ON d.drugbank_id = l.drug_id
                WHERE UPPER(l.gene_symbol) = UPPER($1)
                  AND ABS(l.z_score) > 2.0  -- Significant perturbation

                UNION

                -- Evidence Source 3: Pathway Co-targeting (same pathways as gene)
                SELECT DISTINCT
                    d.drugbank_id,
                    d.drug_name,
                    d.canonical_smiles,
                    d.mechanism_of_action,
                    d.approval_status,
                    0.6 as evidence_score,  -- Lower confidence for pathway evidence
                    'pathway_cotarget' as evidence_type
                FROM drugs d
                JOIN drug_targets t ON d.drugbank_id = t.drugbank_id
                JOIN gene_pathways gp1 ON UPPER(t.target_gene) = UPPER(gp1.gene_symbol)
                JOIN gene_pathways gp2 ON gp1.pathway_id = gp2.pathway_id
                WHERE UPPER(gp2.gene_symbol) = UPPER($1)
                  AND UPPER(t.target_gene) != UPPER($1)  -- Exclude direct targets (already captured)
            )
            SELECT
                drugbank_id,
                drug_name,
                canonical_smiles,
                mechanism_of_action,
                approval_status,
                MAX(evidence_score) as max_evidence_score,
                STRING_AGG(DISTINCT evidence_type, ', ') as evidence_types,
                COUNT(DISTINCT evidence_type) as evidence_count
            FROM gene_drugs
            WHERE evidence_score >= $3  -- Apply min evidence threshold
            GROUP BY drugbank_id, drug_name, canonical_smiles, mechanism_of_action, approval_status
            HAVING MAX(evidence_score) >= $3
            ORDER BY
                -- Prioritize: multiple evidence types > single strong evidence
                evidence_count DESC,
                max_evidence_score DESC,
                -- Prefer approved drugs over investigational
                CASE
                    WHEN approval_status = 'approved' THEN 1
                    WHEN approval_status = 'investigational' THEN 2
                    ELSE 3
                END ASC,
                drug_name ASC
            LIMIT $2
            """

            results = await conn.fetch(query, gene, top_k, min_evidence_score)

            if not results:
                logger.warning(f"No drug candidates found for gene {gene}")
                return []

            candidates = [
                {
                    "drugbank_id": str(r["drugbank_id"]),
                    "drug_name": str(r["drug_name"]),
                    "smiles": str(r["canonical_smiles"]) if r["canonical_smiles"] else None,
                    "mechanism": str(r["mechanism_of_action"]) if r["mechanism_of_action"] else "Unknown",
                    "approval_status": str(r["approval_status"]) if r["approval_status"] else "unknown",
                    "prior_evidence": float(r["max_evidence_score"]),
                    "evidence_types": str(r["evidence_types"]),
                    "evidence_count": int(r["evidence_count"])
                }
                for r in results
            ]

            logger.info(f"Found {len(candidates)} drug candidates for gene {gene}")
            return candidates

    except Exception as e:
        logger.error(f"Failed to query drug candidates for {gene}: {e}", exc_info=True)

        # Fallback: return empty list (DeMeo will handle gracefully)
        return []


async def get_fallback_drug_candidates(top_k: int = 20) -> List[Dict[str, Any]]:
    """
    Get generic high-value drug candidates when gene-specific query fails.

    Returns approved CNS drugs as fallback candidates.

    Args:
        top_k: Number of drugs to return

    Returns:
        List of fallback drug candidates
    """
    try:
        async with get_connection() as conn:
            query = """
            SELECT DISTINCT
                d.drugbank_id,
                d.drug_name,
                d.canonical_smiles,
                d.mechanism_of_action,
                d.approval_status
            FROM drugs d
            WHERE d.approval_status = 'approved'
              AND (
                  d.indication ILIKE '%neurological%'
                  OR d.indication ILIKE '%epilepsy%'
                  OR d.indication ILIKE '%seizure%'
                  OR d.indication ILIKE '%cns%'
                  OR d.mechanism_of_action ILIKE '%gaba%'
                  OR d.mechanism_of_action ILIKE '%sodium channel%'
              )
            ORDER BY d.drug_name ASC
            LIMIT $1
            """

            results = await conn.fetch(query, top_k)

            return [
                {
                    "drugbank_id": str(r["drugbank_id"]),
                    "drug_name": str(r["drug_name"]),
                    "smiles": str(r["canonical_smiles"]) if r["canonical_smiles"] else None,
                    "mechanism": str(r["mechanism_of_action"]) if r["mechanism_of_action"] else "Unknown",
                    "approval_status": "approved",
                    "prior_evidence": 0.3,  # Low default evidence
                    "evidence_types": "cns_indication",
                    "evidence_count": 1
                }
                for r in results
            ]

    except Exception as e:
        logger.error(f"Fallback drug query failed: {e}")
        return []
