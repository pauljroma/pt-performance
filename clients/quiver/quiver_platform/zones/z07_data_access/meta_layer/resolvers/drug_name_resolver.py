"""
Drug Name Resolver - Redirect to Canonical Location

MIGRATED TO: zones/z07_data_access/drug_name_resolver.py
DATE: 2025-12-03

This file maintains backward compatibility for imports.
All code should now import from the canonical location:
    from zones.z07_data_access.drug_name_resolver import DrugNameResolverV21
"""

# Redirect to canonical location using full import path
from clients.quiver.quiver_platform.zones.z07_data_access.drug_name_resolver import (
    DrugNameResolverV21,
    DrugNameResolver,  # Alias
    get_drug_name_resolver_v21,
    get_drug_name_resolver,  # Alias
)

__all__ = [
    'DrugNameResolverV21',
    'DrugNameResolver',
    'get_drug_name_resolver_v21',
    'get_drug_name_resolver',
]
