"""
Configuration package for Sapphire Platform

Provides centralized configuration management through ConfigLoader singleton.
"""

from .config_loader import (
    config,
    ConfigLoader,
    get_postgres_connection_config,
    get_neo4j_connection_config,
    get_connection_string,
)

__all__ = [
    "config",
    "ConfigLoader",
    "get_postgres_connection_config",
    "get_neo4j_connection_config",
    "get_connection_string",
]
