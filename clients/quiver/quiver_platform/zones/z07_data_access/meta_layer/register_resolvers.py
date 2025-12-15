#!/usr/bin/env python3.11
"""
Register Meta Layer Resolvers with Component Registry

Registers all meta layer resolvers (gene, drug, pathway) with the PostgreSQL-based
component registry for proper discovery and reuse.

Usage:
    python3.11 register_resolvers.py
"""

import psycopg2
from datetime import datetime
from pathlib import Path

DB_CONFIG = {
    'host': 'localhost',
    'port': 5435,
    'database': 'sapphire_database',
    'user': 'postgres',
    'password': 'temppass123'
}

RESOLVERS = [
    {
        'component_id': 'gene-name-resolver-v1.0',
        'component_name': 'Gene Name Resolver V1.0',
        'component_type': 'resolver',
        'version': 'S.1.0.0',
        'lane': 'stable',
        'zone': 'z07',
        'file_path': 'clients/quiver/quiver_platform/zones/z07_data_access/meta_layer/resolvers/gene_name_resolver.py',
        'description': 'Comprehensive gene/protein name normalization with HGNC cache integration. Normalizes across Gene ↔ Entrez ↔ Ensembl ↔ UniProt with <10ms latency.',
        'tags': ['resolver', 'gene', 'normalization', 'hgnc', 'meta-layer'],
        'provides': ['gene_symbol_normalization', 'entrez_resolution', 'uniprot_resolution', 'ensembl_resolution'],
        'dependencies': ['base_resolver', 'hgnc_cache', 'string_gene_map'],
        'governance': 'PLATINUM',
        'lifecycle_stage': 'production',
        'deployment_status': 'DEPLOYED',
        'test_coverage': 85.0,
        'monitoring_enabled': True,
        'authors': ['Resolver Expansion Swarm - Agent 1'],
        'created_by': 'resolver_expansion_swarm_v1_0',
        'purpose': 'Provide consistent gene name normalization across all MOA expansion and Sapphire tools'
    },
    {
        'component_id': 'drug-name-resolver-v1.0',
        'component_name': 'Drug Name Resolver V1.0',
        'component_type': 'resolver',
        'version': 'S.1.0.0',
        'lane': 'stable',
        'zone': 'z07',
        'file_path': 'clients/quiver/quiver_platform/zones/z07_data_access/meta_layer/resolvers/drug_name_resolver.py',
        'description': 'Drug and chemical name normalization across ChEMBL, PubChem, DrugBank with alias support.',
        'tags': ['resolver', 'drug', 'normalization', 'chembl', 'meta-layer'],
        'provides': ['drug_name_normalization', 'chembl_resolution', 'pubchem_resolution'],
        'dependencies': ['base_resolver'],
        'governance': 'PLATINUM',
        'lifecycle_stage': 'production',
        'deployment_status': 'DEPLOYED',
        'authors': ['Resolver Expansion Swarm - Agent 2'],
        'created_by': 'resolver_expansion_swarm_v1_0',
        'purpose': 'Provide consistent drug name normalization across MOA expansion and drug tools'
    },
    {
        'component_id': 'pathway-name-resolver-v1.0',
        'component_name': 'Pathway Name Resolver V1.0',
        'component_type': 'resolver',
        'version': 'S.1.0.0',
        'lane': 'stable',
        'zone': 'z07',
        'file_path': 'clients/quiver/quiver_platform/zones/z07_data_access/meta_layer/resolvers/pathway_name_resolver.py',
        'description': 'Pathway name normalization across KEGG, Reactome, WikiPathways databases.',
        'tags': ['resolver', 'pathway', 'normalization', 'kegg', 'reactome', 'meta-layer'],
        'provides': ['pathway_name_normalization', 'kegg_resolution', 'reactome_resolution'],
        'dependencies': ['base_resolver'],
        'governance': 'PLATINUM',
        'lifecycle_stage': 'production',
        'deployment_status': 'DEPLOYED',
        'authors': ['Resolver Expansion Swarm - Agent 3'],
        'created_by': 'resolver_expansion_swarm_v1_0',
        'purpose': 'Provide consistent pathway name normalization across pathway analysis tools'
    }
]


def register_resolvers():
    """Register all meta layer resolvers with component registry"""
    print("=" * 80)
    print("REGISTERING META LAYER RESOLVERS WITH COMPONENT REGISTRY")
    print("=" * 80)
    print()

    # Connect to PostgreSQL
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
        print("✅ Connected to PostgreSQL component registry\n")
    except Exception as e:
        print(f"❌ Failed to connect to database: {e}")
        return

    registered_count = 0
    updated_count = 0

    for resolver in RESOLVERS:
        component_id = resolver['component_id']

        # Check if already exists
        cursor.execute("""
            SELECT id FROM master_component_registry
            WHERE component_id = %s
        """, (component_id,))

        existing = cursor.fetchone()

        if existing:
            # Update existing
            cursor.execute("""
                UPDATE master_component_registry
                SET component_name = %s,
                    description = %s,
                    tags = %s,
                    version = %s,
                    file_path = %s,
                    deployment_status = %s,
                    lifecycle_stage = %s,
                    governance = %s,
                    test_coverage = %s,
                    monitoring_enabled = %s,
                    updated_at = %s
                WHERE component_id = %s
            """, (
                resolver['component_name'],
                resolver['description'],
                resolver['tags'],
                resolver['version'],
                resolver['file_path'],
                resolver.get('deployment_status'),
                resolver.get('lifecycle_stage'),
                resolver.get('governance'),
                resolver.get('test_coverage'),
                resolver.get('monitoring_enabled', False),
                datetime.utcnow(),
                component_id
            ))
            updated_count += 1
            print(f"🔄 Updated: {component_id}")
        else:
            # Insert new
            cursor.execute("""
                INSERT INTO master_component_registry (
                    component_id, component_name, component_type, version, lane,
                    zone, file_path, description, tags, authors,
                    dependencies, governance, lifecycle_stage, deployment_status,
                    test_coverage, monitoring_enabled, created_at, updated_at
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                component_id,
                resolver['component_name'],
                resolver['component_type'],
                resolver['version'],
                resolver['lane'],
                resolver['zone'],
                resolver['file_path'],
                resolver['description'],
                resolver['tags'],
                resolver.get('authors', []),
                resolver.get('dependencies', []),
                resolver.get('governance'),
                resolver.get('lifecycle_stage'),
                resolver.get('deployment_status'),
                resolver.get('test_coverage'),
                resolver.get('monitoring_enabled', False),
                datetime.utcnow(),
                datetime.utcnow()
            ))
            registered_count += 1
            print(f"✅ Registered: {component_id}")

    # Commit changes
    conn.commit()
    cursor.close()
    conn.close()

    print()
    print("=" * 80)
    print(f"REGISTRATION COMPLETE")
    print(f"  New registrations: {registered_count}")
    print(f"  Updates: {updated_count}")
    print("=" * 80)


if __name__ == '__main__':
    register_resolvers()
