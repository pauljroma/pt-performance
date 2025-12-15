"""
PGVector Embedding Configuration - 111 Production Tables

Generated from PostgreSQL pgvector tables.
Legacy MODEX v5.0 tables removed 2025-12-03.

REMOVED (9 tables):
  1. ep_drug_39d_v5_0 → Use modex_ep_unified_16d_v6_0
  2. modex_drug_ep_16d_v5_0 → Use modex_ep_unified_16d_v6_0
  3. modex_drug_lincs_16d_v5_0 → Use chemical_v6_0 + LINCS-drug fusion
  4. modex_gene_ep_16d_v5_0 → Use ens_gene_64d_v6_0
  5. modex_gene_lincs_16d_v5_0 → Use ens_gene + LINCS-gene fusion
  6. ens_gene_7d_v5_4_archived_20251203 → Use ens_gene_64d_v6_0
  7. dipole_modex_emb_16d_v5_0 → Use dipole_ens_emb_64d_v6_0
  8. tripole_modex_emb_16d_v5_0 → Use tripole_ens_emb_64d_v6_0
  9. quadpole_modex_emb_16d_v5_0 → Use quadpole_ens_emb_64d_v6_0
"""

import os
from typing import Dict, Literal, Optional
from dataclasses import dataclass


@dataclass
class PGVectorTableConfig:
    """Configuration for a single pgvector table."""
    name: str
    table_name: str
    type: Literal["gene", "drug", "fusion", "summary"]
    dimensions: Optional[int]
    entity_column: str
    embedding_column: Optional[str]
    description: str
    category: Literal["embedding", "gene_fusion", "drug_fusion", "cross_fusion", "summary"]


# 111 PGVECTOR TABLES
PRODUCTION_PGVECTOR_TABLES: Dict[str, PGVectorTableConfig] = {
    "adr_emb_8d_v5_0": PGVectorTableConfig(
        name="adr_emb_8d_v5_0",
        table_name="adr_emb_8d_v5_0",
        type="fusion",
        dimensions=None,
        entity_column="entity_id",
        embedding_column="embedding",
        description="PGVector: adr_emb_8d_v5_0",
        category="embedding"
    ),
    "cto_emb_9d_v5_0": PGVectorTableConfig(
        name="cto_emb_9d_v5_0",
        table_name="cto_emb_9d_v5_0",
        type="fusion",
        dimensions=None,
        entity_column="entity_id",
        embedding_column="embedding",
        description="PGVector: cto_emb_9d_v5_0",
        category="embedding"
    ),
    "d_adr_safety_fusion_v6_0": PGVectorTableConfig(
        name="d_adr_safety_fusion_v6_0",
        table_name="d_adr_safety_fusion_v6_0",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: d_adr_safety_fusion_v6_0",
        category="fusion"
    ),
    "d_aux_adr_topk_v6_0": PGVectorTableConfig(
        name="d_aux_adr_topk_v6_0",
        table_name="d_aux_adr_topk_v6_0",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: d_aux_adr_topk_v6_0",
        category="fusion"
    ),
    "d_aux_cto_topk_v6_0": PGVectorTableConfig(
        name="d_aux_cto_topk_v6_0",
        table_name="d_aux_cto_topk_v6_0",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: d_aux_cto_topk_v6_0",
        category="fusion"
    ),
    "d_aux_dgp_topk_v6_0": PGVectorTableConfig(
        name="d_aux_dgp_topk_v6_0",
        table_name="d_aux_dgp_topk_v6_0",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: d_aux_dgp_topk_v6_0",
        category="fusion"
    ),
    "d_aux_ep_drug_topk_v6_0": PGVectorTableConfig(
        name="d_aux_ep_drug_topk_v6_0",
        table_name="d_aux_ep_drug_topk_v6_0",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: d_aux_ep_drug_topk_v6_0",
        category="fusion"
    ),
    "d_aux_mop_topk_v6_0": PGVectorTableConfig(
        name="d_aux_mop_topk_v6_0",
        table_name="d_aux_mop_topk_v6_0",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: d_aux_mop_topk_v6_0",
        category="fusion"
    ),
    "d_d_1__ep__modex_lincs": PGVectorTableConfig(
        name="d_d_1__ep__modex_lincs",
        table_name="d_d_1__ep__modex_lincs",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: d_d_1__ep__modex_lincs",
        category="embedding"
    ),
    "d_d_2__ep__lincs_32d": PGVectorTableConfig(
        name="d_d_2__ep__lincs_32d",
        table_name="d_d_2__ep__lincs_32d",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: d_d_2__ep__lincs_32d",
        category="embedding"
    ),
    "d_d_3__ep__adr": PGVectorTableConfig(
        name="d_d_3__ep__adr",
        table_name="d_d_3__ep__adr",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: d_d_3__ep__adr",
        category="embedding"
    ),
    "d_d_4__modex_lincs__lincs_32d": PGVectorTableConfig(
        name="d_d_4__modex_lincs__lincs_32d",
        table_name="d_d_4__modex_lincs__lincs_32d",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: d_d_4__modex_lincs__lincs_32d",
        category="embedding"
    ),
    "d_d_5__modex_lincs__adr": PGVectorTableConfig(
        name="d_d_5__modex_lincs__adr",
        table_name="d_d_5__modex_lincs__adr",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: d_d_5__modex_lincs__adr",
        category="embedding"
    ),
    "d_d_6__modex_lincs__syn": PGVectorTableConfig(
        name="d_d_6__modex_lincs__syn",
        table_name="d_d_6__modex_lincs__syn",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: d_d_6__modex_lincs__syn",
        category="embedding"
    ),
    "d_d_7__modex_lincs__cto": PGVectorTableConfig(
        name="d_d_7__modex_lincs__cto",
        table_name="d_d_7__modex_lincs__cto",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: d_d_7__modex_lincs__cto",
        category="embedding"
    ),
    "d_d_8__lincs_32d__adr": PGVectorTableConfig(
        name="d_d_8__lincs_32d__adr",
        table_name="d_d_8__lincs_32d__adr",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: d_d_8__lincs_32d__adr",
        category="embedding"
    ),
    "d_d_chem_lincs_topk_v6_0": PGVectorTableConfig(
        name="d_d_chem_lincs_topk_v6_0",
        table_name="d_d_chem_lincs_topk_v6_0",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: d_d_chem_lincs_topk_v6_0",
        category="fusion"
    ),
    "d_d_d_10__ep__lincs_32d__adr": PGVectorTableConfig(
        name="d_d_d_10__ep__lincs_32d__adr",
        table_name="d_d_d_10__ep__lincs_32d__adr",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: d_d_d_10__ep__lincs_32d__adr",
        category="embedding"
    ),
    "d_d_d_1__ep__modex_lincs__adr": PGVectorTableConfig(
        name="d_d_d_1__ep__modex_lincs__adr",
        table_name="d_d_d_1__ep__modex_lincs__adr",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: d_d_d_1__ep__modex_lincs__adr",
        category="embedding"
    ),
    "d_d_d_2__ep__modex_lincs__syn": PGVectorTableConfig(
        name="d_d_d_2__ep__modex_lincs__syn",
        table_name="d_d_d_2__ep__modex_lincs__syn",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: d_d_d_2__ep__modex_lincs__syn",
        category="embedding"
    ),
    "d_d_d_3__ep__modex_lincs__cto": PGVectorTableConfig(
        name="d_d_d_3__ep__modex_lincs__cto",
        table_name="d_d_d_3__ep__modex_lincs__cto",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: d_d_d_3__ep__modex_lincs__cto",
        category="embedding"
    ),
    "d_d_d_4__ep__adr__syn": PGVectorTableConfig(
        name="d_d_d_4__ep__adr__syn",
        table_name="d_d_d_4__ep__adr__syn",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: d_d_d_4__ep__adr__syn",
        category="embedding"
    ),
    "d_d_d_5__ep__adr__cto": PGVectorTableConfig(
        name="d_d_d_5__ep__adr__cto",
        table_name="d_d_d_5__ep__adr__cto",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: d_d_d_5__ep__adr__cto",
        category="embedding"
    ),
    "d_d_d_6__modex_lincs__adr__syn": PGVectorTableConfig(
        name="d_d_d_6__modex_lincs__adr__syn",
        table_name="d_d_d_6__modex_lincs__adr__syn",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: d_d_d_6__modex_lincs__adr__syn",
        category="embedding"
    ),
    "d_d_d_7__modex_lincs__adr__cto": PGVectorTableConfig(
        name="d_d_d_7__modex_lincs__adr__cto",
        table_name="d_d_d_7__modex_lincs__adr__cto",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: d_d_d_7__modex_lincs__adr__cto",
        category="embedding"
    ),
    "d_d_d_8__modex_lincs__syn__cto": PGVectorTableConfig(
        name="d_d_d_8__modex_lincs__syn__cto",
        table_name="d_d_d_8__modex_lincs__syn__cto",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: d_d_d_8__modex_lincs__syn__cto",
        category="embedding"
    ),
    "d_d_g_1__ep_drug__modex_drug_lincs__ens_gene": PGVectorTableConfig(
        name="d_d_g_1__ep_drug__modex_drug_lincs__ens_gene",
        table_name="d_d_g_1__ep_drug__modex_drug_lincs__ens_gene",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: d_d_g_1__ep_drug__modex_drug_lincs__ens_gene",
        category="embedding"
    ),
    "d_d_g_2__ep_drug__modex_drug_lincs__modex_gene_ep": PGVectorTableConfig(
        name="d_d_g_2__ep_drug__modex_drug_lincs__modex_gene_ep",
        table_name="d_d_g_2__ep_drug__modex_drug_lincs__modex_gene_ep",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: d_d_g_2__ep_drug__modex_drug_lincs__modex_gene_ep",
        category="embedding"
    ),
    "d_d_g_3__ep_drug__modex_drug_lincs__modex_gene_lincs": PGVectorTableConfig(
        name="d_d_g_3__ep_drug__modex_drug_lincs__modex_gene_lincs",
        table_name="d_d_g_3__ep_drug__modex_drug_lincs__modex_gene_lincs",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: d_d_g_3__ep_drug__modex_drug_lincs__modex_gene_lincs",
        category="embedding"
    ),
    "d_d_g_4__ep_drug__adr_drug__ens_gene": PGVectorTableConfig(
        name="d_d_g_4__ep_drug__adr_drug__ens_gene",
        table_name="d_d_g_4__ep_drug__adr_drug__ens_gene",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: d_d_g_4__ep_drug__adr_drug__ens_gene",
        category="embedding"
    ),
    "d_d_g_5__modex_drug_lincs__adr__ens_gene": PGVectorTableConfig(
        name="d_d_g_5__modex_drug_lincs__adr__ens_gene",
        table_name="d_d_g_5__modex_drug_lincs__adr__ens_gene",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: d_d_g_5__modex_drug_lincs__adr__ens_gene",
        category="embedding"
    ),
    "d_d_g_6__modex_drug_lincs__adr__modex_gene_ep": PGVectorTableConfig(
        name="d_d_g_6__modex_drug_lincs__adr__modex_gene_ep",
        table_name="d_d_g_6__modex_drug_lincs__adr__modex_gene_ep",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: d_d_g_6__modex_drug_lincs__adr__modex_gene_ep",
        category="embedding"
    ),
    "d_d_g_7__modex_drug_lincs__adr__modex_gene_lincs": PGVectorTableConfig(
        name="d_d_g_7__modex_drug_lincs__adr__modex_gene_lincs",
        table_name="d_d_g_7__modex_drug_lincs__adr__modex_gene_lincs",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: d_d_g_7__modex_drug_lincs__adr__modex_gene_lincs",
        category="embedding"
    ),
    "d_d_g_8__lincs_drug_32d__adr__modex_gene_lincs": PGVectorTableConfig(
        name="d_d_g_8__lincs_drug_32d__adr__modex_gene_lincs",
        table_name="d_d_g_8__lincs_drug_32d__adr__modex_gene_lincs",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: d_d_g_8__lincs_drug_32d__adr__modex_gene_lincs",
        category="embedding"
    ),
    "d_d_g_9__ep_drug__lincs_drug_32d__modex_gene_lincs": PGVectorTableConfig(
        name="d_d_g_9__ep_drug__lincs_drug_32d__modex_gene_lincs",
        table_name="d_d_g_9__ep_drug__lincs_drug_32d__modex_gene_lincs",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: d_d_g_9__ep_drug__lincs_drug_32d__modex_gene_lincs",
        category="embedding"
    ),
    "d_d_similarity_fusion_v6_0": PGVectorTableConfig(
        name="d_d_similarity_fusion_v6_0",
        table_name="d_d_similarity_fusion_v6_0",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: d_d_similarity_fusion_v6_0",
        category="fusion"
    ),
    "d_g_10__adr_drug__ens_gene": PGVectorTableConfig(
        name="d_g_10__adr_drug__ens_gene",
        table_name="d_g_10__adr_drug__ens_gene",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: d_g_10__adr_drug__ens_gene",
        category="embedding"
    ),
    "d_g_11__adr_drug__modex_gene_ep": PGVectorTableConfig(
        name="d_g_11__adr_drug__modex_gene_ep",
        table_name="d_g_11__adr_drug__modex_gene_ep",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: d_g_11__adr_drug__modex_gene_ep",
        category="embedding"
    ),
    "d_g_12__adr_drug__modex_gene_lincs": PGVectorTableConfig(
        name="d_g_12__adr_drug__modex_gene_lincs",
        table_name="d_g_12__adr_drug__modex_gene_lincs",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: d_g_12__adr_drug__modex_gene_lincs",
        category="embedding"
    ),
    "d_g_13__dgp__ens_gene": PGVectorTableConfig(
        name="d_g_13__dgp__ens_gene",
        table_name="d_g_13__dgp__ens_gene",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: d_g_13__dgp__ens_gene",
        category="embedding"
    ),
    "d_g_14__dgp__modex_gene_ep": PGVectorTableConfig(
        name="d_g_14__dgp__modex_gene_ep",
        table_name="d_g_14__dgp__modex_gene_ep",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: d_g_14__dgp__modex_gene_ep",
        category="embedding"
    ),
    "d_g_15__dgp__modex_gene_lincs": PGVectorTableConfig(
        name="d_g_15__dgp__modex_gene_lincs",
        table_name="d_g_15__dgp__modex_gene_lincs",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: d_g_15__dgp__modex_gene_lincs",
        category="embedding"
    ),
    "d_g_1__ep_drug__ens_gene": PGVectorTableConfig(
        name="d_g_1__ep_drug__ens_gene",
        table_name="d_g_1__ep_drug__ens_gene",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: d_g_1__ep_drug__ens_gene",
        category="embedding"
    ),
    "d_g_2__ep_drug__modex_gene_ep": PGVectorTableConfig(
        name="d_g_2__ep_drug__modex_gene_ep",
        table_name="d_g_2__ep_drug__modex_gene_ep",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: d_g_2__ep_drug__modex_gene_ep",
        category="embedding"
    ),
    "d_g_3__ep_drug__modex_gene_lincs": PGVectorTableConfig(
        name="d_g_3__ep_drug__modex_gene_lincs",
        table_name="d_g_3__ep_drug__modex_gene_lincs",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: d_g_3__ep_drug__modex_gene_lincs",
        category="embedding"
    ),
    "d_g_4__modex_drug_lincs__ens_gene": PGVectorTableConfig(
        name="d_g_4__modex_drug_lincs__ens_gene",
        table_name="d_g_4__modex_drug_lincs__ens_gene",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: d_g_4__modex_drug_lincs__ens_gene",
        category="embedding"
    ),
    "d_g_5__modex_drug_lincs__modex_gene_ep": PGVectorTableConfig(
        name="d_g_5__modex_drug_lincs__modex_gene_ep",
        table_name="d_g_5__modex_drug_lincs__modex_gene_ep",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: d_g_5__modex_drug_lincs__modex_gene_ep",
        category="embedding"
    ),
    "d_g_6__modex_drug_lincs__modex_gene_lincs": PGVectorTableConfig(
        name="d_g_6__modex_drug_lincs__modex_gene_lincs",
        table_name="d_g_6__modex_drug_lincs__modex_gene_lincs",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: d_g_6__modex_drug_lincs__modex_gene_lincs",
        category="embedding"
    ),
    "d_g_7__lincs_drug_32d__ens_gene": PGVectorTableConfig(
        name="d_g_7__lincs_drug_32d__ens_gene",
        table_name="d_g_7__lincs_drug_32d__ens_gene",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: d_g_7__lincs_drug_32d__ens_gene",
        category="embedding"
    ),
    "d_g_8__lincs_drug_32d__modex_gene_ep": PGVectorTableConfig(
        name="d_g_8__lincs_drug_32d__modex_gene_ep",
        table_name="d_g_8__lincs_drug_32d__modex_gene_ep",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: d_g_8__lincs_drug_32d__modex_gene_ep",
        category="embedding"
    ),
    "d_g_9__lincs_drug_32d__modex_gene_lincs": PGVectorTableConfig(
        name="d_g_9__lincs_drug_32d__modex_gene_lincs",
        table_name="d_g_9__lincs_drug_32d__modex_gene_lincs",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: d_g_9__lincs_drug_32d__modex_gene_lincs",
        category="embedding"
    ),
    "d_g_chem_ens_topk_v6_0": PGVectorTableConfig(
        name="d_g_chem_ens_topk_v6_0",
        table_name="d_g_chem_ens_topk_v6_0",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: d_g_chem_ens_topk_v6_0",
        category="fusion"
    ),
    "d_g_chem_ep_topk_v6_0": PGVectorTableConfig(
        name="d_g_chem_ep_topk_v6_0",
        table_name="d_g_chem_ep_topk_v6_0",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: d_g_chem_ep_topk_v6_0",
        category="fusion"
    ),
    "d_g_similarity_fusion_v6_0": PGVectorTableConfig(
        name="d_g_similarity_fusion_v6_0",
        table_name="d_g_similarity_fusion_v6_0",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: d_g_similarity_fusion_v6_0",
        category="fusion"
    ),
    "d_g_target_fusion_v6_0": PGVectorTableConfig(
        name="d_g_target_fusion_v6_0",
        table_name="d_g_target_fusion_v6_0",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: d_g_target_fusion_v6_0",
        category="fusion"
    ),
    "dgp_emb_12d_v5_0": PGVectorTableConfig(
        name="dgp_emb_12d_v5_0",
        table_name="dgp_emb_12d_v5_0",
        type="fusion",
        dimensions=None,
        entity_column="entity_id",
        embedding_column="embedding",
        description="PGVector: dgp_emb_12d_v5_0",
        category="embedding"
    ),
    "dipole_ens_emb_64d_v6_0": PGVectorTableConfig(
        name="dipole_ens_emb_64d_v6_0",
        table_name="dipole_ens_emb_64d_v6_0",
        type="fusion",
        dimensions=None,
        entity_column="entity_id",
        embedding_column="embedding",
        description="PGVector: dipole_ens_emb_64d_v6_0",
        category="embedding"
    ),
    "dipole_ens_emb_7d_v5_0_archived_20251203": PGVectorTableConfig(
        name="dipole_ens_emb_7d_v5_0_archived_20251203",
        table_name="dipole_ens_emb_7d_v5_0_archived_20251203",
        type="fusion",
        dimensions=None,
        entity_column="entity_id",
        embedding_column="embedding",
        description="PGVector: dipole_ens_emb_7d_v5_0_archived_20251203",
        category="embedding"
    ),
    "drug_chemical_v6_0_256d": PGVectorTableConfig(
        name="drug_chemical_v6_0_256d",
        table_name="drug_chemical_v6_0_256d",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: drug_chemical_v6_0_256d",
        category="embedding"
    ),
    "ens_gene_64d_v6_0": PGVectorTableConfig(
        name="ens_gene_64d_v6_0",
        table_name="ens_gene_64d_v6_0",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: ens_gene_64d_v6_0",
        category="embedding"
    ),
    "g_aux_cto_topk_v6_0": PGVectorTableConfig(
        name="g_aux_cto_topk_v6_0",
        table_name="g_aux_cto_topk_v6_0",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: g_aux_cto_topk_v6_0",
        category="fusion"
    ),
    "g_aux_dgp_topk_v6_0": PGVectorTableConfig(
        name="g_aux_dgp_topk_v6_0",
        table_name="g_aux_dgp_topk_v6_0",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: g_aux_dgp_topk_v6_0",
        category="fusion"
    ),
    "g_aux_ep_drug_topk_v6_0": PGVectorTableConfig(
        name="g_aux_ep_drug_topk_v6_0",
        table_name="g_aux_ep_drug_topk_v6_0",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: g_aux_ep_drug_topk_v6_0",
        category="fusion"
    ),
    "g_aux_mop_topk_v6_0": PGVectorTableConfig(
        name="g_aux_mop_topk_v6_0",
        table_name="g_aux_mop_topk_v6_0",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: g_aux_mop_topk_v6_0",
        category="fusion"
    ),
    "g_aux_syn_topk_v6_0": PGVectorTableConfig(
        name="g_aux_syn_topk_v6_0",
        table_name="g_aux_syn_topk_v6_0",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: g_aux_syn_topk_v6_0",
        category="fusion"
    ),
    "g_g_1__ens__modex_ep": PGVectorTableConfig(
        name="g_g_1__ens__modex_ep",
        table_name="g_g_1__ens__modex_ep",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: g_g_1__ens__modex_ep",
        category="embedding"
    ),
    "g_g_2__ens__modex_lincs": PGVectorTableConfig(
        name="g_g_2__ens__modex_lincs",
        table_name="g_g_2__ens__modex_lincs",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: g_g_2__ens__modex_lincs",
        category="embedding"
    ),
    "g_g_3__modex_ep__modex_lincs": PGVectorTableConfig(
        name="g_g_3__modex_ep__modex_lincs",
        table_name="g_g_3__modex_ep__modex_lincs",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: g_g_3__modex_ep__modex_lincs",
        category="embedding"
    ),
    "g_g_ens_lincs_topk_v6_0": PGVectorTableConfig(
        name="g_g_ens_lincs_topk_v6_0",
        table_name="g_g_ens_lincs_topk_v6_0",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: g_g_ens_lincs_topk_v6_0",
        category="fusion"
    ),
    "g_g_g_1__ens__modex_ep__modex_lincs": PGVectorTableConfig(
        name="g_g_g_1__ens__modex_ep__modex_lincs",
        table_name="g_g_g_1__ens__modex_ep__modex_lincs",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: g_g_g_1__ens__modex_ep__modex_lincs",
        category="embedding"
    ),
    "hexa_1__all_root_embeddings": PGVectorTableConfig(
        name="hexa_1__all_root_embeddings",
        table_name="hexa_1__all_root_embeddings",
        type="fusion",
        dimensions=None,
        entity_column="entity_id",
        embedding_column="embedding",
        description="PGVector: hexa_1__all_root_embeddings",
        category="embedding"
    ),
    "lincs_drug_32d_v5_0": PGVectorTableConfig(
        name="lincs_drug_32d_v5_0",
        table_name="lincs_drug_32d_v5_0",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: lincs_drug_32d_v5_0",
        category="embedding"
    ),
    "lincs_gene_32d_v5_0": PGVectorTableConfig(
        name="lincs_gene_32d_v5_0",
        table_name="lincs_gene_32d_v5_0",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: lincs_gene_32d_v5_0",
        category="embedding"
    ),
    "master_fusion__all_embeddings": PGVectorTableConfig(
        name="master_fusion__all_embeddings",
        table_name="master_fusion__all_embeddings",
        type="fusion",
        dimensions=None,
        entity_column="entity_id",
        embedding_column="embedding",
        description="PGVector: master_fusion__all_embeddings",
        category="fusion"
    ),
    "modex_ep__adr": PGVectorTableConfig(
        name="modex_ep__adr",
        table_name="modex_ep__adr",
        type="fusion",
        dimensions=None,
        entity_column="entity_id",
        embedding_column="embedding",
        description="PGVector: modex_ep__adr",
        category="embedding"
    ),
    "modex_ep__cto": PGVectorTableConfig(
        name="modex_ep__cto",
        table_name="modex_ep__cto",
        type="fusion",
        dimensions=None,
        entity_column="entity_id",
        embedding_column="embedding",
        description="PGVector: modex_ep__cto",
        category="embedding"
    ),
    "modex_ep__mop": PGVectorTableConfig(
        name="modex_ep__mop",
        table_name="modex_ep__mop",
        type="fusion",
        dimensions=None,
        entity_column="entity_id",
        embedding_column="embedding",
        description="PGVector: modex_ep__mop",
        category="embedding"
    ),
    "modex_ep__syn": PGVectorTableConfig(
        name="modex_ep__syn",
        table_name="modex_ep__syn",
        type="fusion",
        dimensions=None,
        entity_column="entity_id",
        embedding_column="embedding",
        description="PGVector: modex_ep__syn",
        category="embedding"
    ),
    "modex_ep_unified_16d_v6_0": PGVectorTableConfig(
        name="modex_ep_unified_16d_v6_0",
        table_name="modex_ep_unified_16d_v6_0",
        type="fusion",
        dimensions=None,
        entity_column="entity_id",
        embedding_column="embedding",
        description="PGVector: modex_ep_unified_16d_v6_0",
        category="embedding"
    ),
    "mop_d_1__mop__ep_drug": PGVectorTableConfig(
        name="mop_d_1__mop__ep_drug",
        table_name="mop_d_1__mop__ep_drug",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: mop_d_1__mop__ep_drug",
        category="embedding"
    ),
    "mop_d_2__mop__modex_drug_lincs": PGVectorTableConfig(
        name="mop_d_2__mop__modex_drug_lincs",
        table_name="mop_d_2__mop__modex_drug_lincs",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: mop_d_2__mop__modex_drug_lincs",
        category="embedding"
    ),
    "mop_d_g_1__mop__ep_drug__ens_gene": PGVectorTableConfig(
        name="mop_d_g_1__mop__ep_drug__ens_gene",
        table_name="mop_d_g_1__mop__ep_drug__ens_gene",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: mop_d_g_1__mop__ep_drug__ens_gene",
        category="embedding"
    ),
    "mop_d_g_2__mop__modex_drug_lincs__modex_gene_ep": PGVectorTableConfig(
        name="mop_d_g_2__mop__modex_drug_lincs__modex_gene_ep",
        table_name="mop_d_g_2__mop__modex_drug_lincs__modex_gene_ep",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: mop_d_g_2__mop__modex_drug_lincs__modex_gene_ep",
        category="embedding"
    ),
    "mop_d_g_3__mop__modex_drug_lincs__modex_gene_lincs": PGVectorTableConfig(
        name="mop_d_g_3__mop__modex_drug_lincs__modex_gene_lincs",
        table_name="mop_d_g_3__mop__modex_drug_lincs__modex_gene_lincs",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: mop_d_g_3__mop__modex_drug_lincs__modex_gene_lincs",
        category="embedding"
    ),
    "mop_d_g_4__mop__modex_drug_lincs__adr__modex_gene_lincs": PGVectorTableConfig(
        name="mop_d_g_4__mop__modex_drug_lincs__adr__modex_gene_lincs",
        table_name="mop_d_g_4__mop__modex_drug_lincs__adr__modex_gene_lincs",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: mop_d_g_4__mop__modex_drug_lincs__adr__modex_gene_lincs",
        category="embedding"
    ),
    "mop_d_g_5__mop__ep__modex_drug_lincs__ens_gene": PGVectorTableConfig(
        name="mop_d_g_5__mop__ep__modex_drug_lincs__ens_gene",
        table_name="mop_d_g_5__mop__ep__modex_drug_lincs__ens_gene",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: mop_d_g_5__mop__ep__modex_drug_lincs__ens_gene",
        category="embedding"
    ),
    "mop_d_g_6__mop__ep__modex_drug_lincs__adr__ens_gene": PGVectorTableConfig(
        name="mop_d_g_6__mop__ep__modex_drug_lincs__adr__ens_gene",
        table_name="mop_d_g_6__mop__ep__modex_drug_lincs__adr__ens_gene",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: mop_d_g_6__mop__ep__modex_drug_lincs__adr__ens_gene",
        category="embedding"
    ),
    "mop_emb_15d_v5_0": PGVectorTableConfig(
        name="mop_emb_15d_v5_0",
        table_name="mop_emb_15d_v5_0",
        type="fusion",
        dimensions=None,
        entity_column="entity_id",
        embedding_column="embedding",
        description="PGVector: mop_emb_15d_v5_0",
        category="embedding"
    ),
    "mop_g_1__mop__ens_gene": PGVectorTableConfig(
        name="mop_g_1__mop__ens_gene",
        table_name="mop_g_1__mop__ens_gene",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: mop_g_1__mop__ens_gene",
        category="embedding"
    ),
    "mop_g_2__mop__modex_gene_ep": PGVectorTableConfig(
        name="mop_g_2__mop__modex_gene_ep",
        table_name="mop_g_2__mop__modex_gene_ep",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: mop_g_2__mop__modex_gene_ep",
        category="embedding"
    ),
    "mop_g_3__mop__modex_gene_lincs": PGVectorTableConfig(
        name="mop_g_3__mop__modex_gene_lincs",
        table_name="mop_g_3__mop__modex_gene_lincs",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: mop_g_3__mop__modex_gene_lincs",
        category="embedding"
    ),
    "mop_ult_1__mop__all_gene_modalities": PGVectorTableConfig(
        name="mop_ult_1__mop__all_gene_modalities",
        table_name="mop_ult_1__mop__all_gene_modalities",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: mop_ult_1__mop__all_gene_modalities",
        category="embedding"
    ),
    "mop_ult_3__mop__all_drug_modalities": PGVectorTableConfig(
        name="mop_ult_3__mop__all_drug_modalities",
        table_name="mop_ult_3__mop__all_drug_modalities",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: mop_ult_3__mop__all_drug_modalities",
        category="embedding"
    ),
    "mop_ult_4__mop__hexa_1": PGVectorTableConfig(
        name="mop_ult_4__mop__hexa_1",
        table_name="mop_ult_4__mop__hexa_1",
        type="fusion",
        dimensions=None,
        entity_column="entity_id",
        embedding_column="embedding",
        description="PGVector: mop_ult_4__mop__hexa_1",
        category="embedding"
    ),
    "penta_1__ep__modex_drug_lincs__adr__syn__cto": PGVectorTableConfig(
        name="penta_1__ep__modex_drug_lincs__adr__syn__cto",
        table_name="penta_1__ep__modex_drug_lincs__adr__syn__cto",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: penta_1__ep__modex_drug_lincs__adr__syn__cto",
        category="embedding"
    ),
    "penta_2__ep__modex_drug_lincs__adr__syn__ens_gene": PGVectorTableConfig(
        name="penta_2__ep__modex_drug_lincs__adr__syn__ens_gene",
        table_name="penta_2__ep__modex_drug_lincs__adr__syn__ens_gene",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: penta_2__ep__modex_drug_lincs__adr__syn__ens_gene",
        category="embedding"
    ),
    "penta_3__ep__modex_drug_lincs__adr__syn__modex_gene_ep": PGVectorTableConfig(
        name="penta_3__ep__modex_drug_lincs__adr__syn__modex_gene_ep",
        table_name="penta_3__ep__modex_drug_lincs__adr__syn__modex_gene_ep",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: penta_3__ep__modex_drug_lincs__adr__syn__modex_gene_ep",
        category="embedding"
    ),
    "penta_4__ep__modex_drug_lincs__adr__syn__modex_gene_lincs": PGVectorTableConfig(
        name="penta_4__ep__modex_drug_lincs__adr__syn__modex_gene_lincs",
        table_name="penta_4__ep__modex_drug_lincs__adr__syn__modex_gene_lincs",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: penta_4__ep__modex_drug_lincs__adr__syn__modex_gene_lincs",
        category="embedding"
    ),
    "quad_1__ep_drug__modex_drug_lincs__adr__ens_gene": PGVectorTableConfig(
        name="quad_1__ep_drug__modex_drug_lincs__adr__ens_gene",
        table_name="quad_1__ep_drug__modex_drug_lincs__adr__ens_gene",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: quad_1__ep_drug__modex_drug_lincs__adr__ens_gene",
        category="embedding"
    ),
    "quad_2__ep_drug__modex_drug_lincs__adr__modex_gene_ep": PGVectorTableConfig(
        name="quad_2__ep_drug__modex_drug_lincs__adr__modex_gene_ep",
        table_name="quad_2__ep_drug__modex_drug_lincs__adr__modex_gene_ep",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: quad_2__ep_drug__modex_drug_lincs__adr__modex_gene_ep",
        category="embedding"
    ),
    "quad_3__ep_drug__modex_drug_lincs__adr__modex_gene_lincs": PGVectorTableConfig(
        name="quad_3__ep_drug__modex_drug_lincs__adr__modex_gene_lincs",
        table_name="quad_3__ep_drug__modex_drug_lincs__adr__modex_gene_lincs",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: quad_3__ep_drug__modex_drug_lincs__adr__modex_gene_lincs",
        category="embedding"
    ),
    "quad_4__modex_drug_lincs__adr__syn__ens_gene": PGVectorTableConfig(
        name="quad_4__modex_drug_lincs__adr__syn__ens_gene",
        table_name="quad_4__modex_drug_lincs__adr__syn__ens_gene",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: quad_4__modex_drug_lincs__adr__syn__ens_gene",
        category="embedding"
    ),
    "quad_5__modex_drug_lincs__adr__cto__ens_gene": PGVectorTableConfig(
        name="quad_5__modex_drug_lincs__adr__cto__ens_gene",
        table_name="quad_5__modex_drug_lincs__adr__cto__ens_gene",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: quad_5__modex_drug_lincs__adr__cto__ens_gene",
        category="embedding"
    ),
    "quadpole_ens_emb_64d_v6_0": PGVectorTableConfig(
        name="quadpole_ens_emb_64d_v6_0",
        table_name="quadpole_ens_emb_64d_v6_0",
        type="fusion",
        dimensions=None,
        entity_column="entity_id",
        embedding_column="embedding",
        description="PGVector: quadpole_ens_emb_64d_v6_0",
        category="embedding"
    ),
    "quadpole_ens_emb_7d_v5_0_archived_20251203": PGVectorTableConfig(
        name="quadpole_ens_emb_7d_v5_0_archived_20251203",
        table_name="quadpole_ens_emb_7d_v5_0_archived_20251203",
        type="fusion",
        dimensions=None,
        entity_column="entity_id",
        embedding_column="embedding",
        description="PGVector: quadpole_ens_emb_7d_v5_0_archived_20251203",
        category="embedding"
    ),
    "syn_emb_10d_v5_0": PGVectorTableConfig(
        name="syn_emb_10d_v5_0",
        table_name="syn_emb_10d_v5_0",
        type="fusion",
        dimensions=None,
        entity_column="entity_id",
        embedding_column="embedding",
        description="PGVector: syn_emb_10d_v5_0",
        category="embedding"
    ),
    "tripole_ens_emb_64d_v6_0": PGVectorTableConfig(
        name="tripole_ens_emb_64d_v6_0",
        table_name="tripole_ens_emb_64d_v6_0",
        type="fusion",
        dimensions=None,
        entity_column="entity_id",
        embedding_column="embedding",
        description="PGVector: tripole_ens_emb_64d_v6_0",
        category="embedding"
    ),
    "tripole_ens_emb_7d_v5_0_archived_20251203": PGVectorTableConfig(
        name="tripole_ens_emb_7d_v5_0_archived_20251203",
        table_name="tripole_ens_emb_7d_v5_0_archived_20251203",
        type="fusion",
        dimensions=None,
        entity_column="entity_id",
        embedding_column="embedding",
        description="PGVector: tripole_ens_emb_7d_v5_0_archived_20251203",
        category="embedding"
    ),
    "v6_0_drug_summary": PGVectorTableConfig(
        name="v6_0_drug_summary",
        table_name="v6_0_drug_summary",
        type="drug",
        dimensions=None,
        entity_column="drug_name",
        embedding_column="embedding",
        description="PGVector: v6_0_drug_summary",
        category="summary"
    ),
    "v6_0_gene_summary": PGVectorTableConfig(
        name="v6_0_gene_summary",
        table_name="v6_0_gene_summary",
        type="gene",
        dimensions=None,
        entity_column="gene_symbol",
        embedding_column="embedding",
        description="PGVector: v6_0_gene_summary",
        category="summary"
    ),
    "g_g_1__ens__lincs": PGVectorTableConfig(
        name="g_g_1__ens__lincs",
        table_name="g_g_1__ens__lincs",
        type="fusion",
        dimensions=96,
        entity_column="gene_symbol",
        embedding_column="combined_embedding",
        description="Gene fusion: ENS (64D) + LINCS (32D) = 96D combined embedding",
        category="gene_fusion"
    ),
}


def get_connection_config() -> Dict[str, any]:
    """Get PostgreSQL connection configuration."""
    return {
        "host": os.getenv("POSTGRES_HOST", "localhost"),
        "port": int(os.getenv("POSTGRES_PORT", "5432")),
        "database": os.getenv("POSTGRES_DATABASE", "sapphire_database"),
        "user": os.getenv("POSTGRES_USER", "postgres"),
        "password": os.getenv("POSTGRES_PASSWORD", ""),
    }

# Production embedding configurations for Sapphire
PRODUCTION_EMBEDDINGS = {
    "gene": {
        "primary": "ens_gene_64d_v6_0",
        "fallback": "modex_gene_v1_0_32d_v6_0",
        "neo4j": "MODEX_Gene_v1_0",
        "dimensions": 64
    },
    "drug": {
        "primary": "chemical_v6_0",
        "fallback": "modex_drug_pca_32d_v6_0",
        "neo4j": "Drug_PCA_32D",
        "dimensions": 16
    },
    "fusion": {
        "gene": "gene_fusion_discovery_v6_0",
        "drug": "drug_fusion_discovery_v6_0"
    }
}
