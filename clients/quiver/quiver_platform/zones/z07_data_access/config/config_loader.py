"""
Centralized Configuration Management for Sapphire Platform

This module provides a singleton ConfigLoader that loads environment configuration
from a single .env file at the platform root, eliminating the need for scattered
.env files and hardcoded os.getenv() calls throughout the codebase.

Usage:
    from zones.z07_data_access.config.config_loader import config

    # Dot-notation access
    postgres_host = config.get("postgres.host")
    postgres_port = config.get("postgres.port", default=5432)

    # Dictionary access
    all_postgres = config.get_section("postgres")

    # Environment mode
    mode = config.mode  # 'chainlit', 'batch', 'testing', etc.

Author: Sapphire Platform Team
Date: 2025-12-04
Version: 1.0
"""

import os
from pathlib import Path
from typing import Dict, Any, Optional
from dotenv import load_dotenv


class ConfigLoader:
    """
    Singleton configuration loader for Sapphire platform.

    Loads .env from platform root and provides structured access to all
    environment variables through dot-notation and dictionary methods.
    """

    _instance: Optional['ConfigLoader'] = None
    _config: Optional[Dict[str, Any]] = None
    _initialized: bool = False

    def __new__(cls):
        """Ensure singleton pattern - only one instance exists."""
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def __init__(self):
        """Initialize config loader (only runs once due to singleton)."""
        if not self._initialized:
            self._load_config()
            ConfigLoader._initialized = True

    @classmethod
    def _find_platform_root(cls) -> Path:
        """
        Find platform root by looking for quiver_platform directory.

        Returns:
            Path to quiver_platform directory

        Raises:
            RuntimeError: If platform root cannot be found
        """
        current = Path(__file__).resolve()

        # Walk up directory tree looking for quiver_platform
        for parent in current.parents:
            if parent.name == "quiver_platform":
                return parent

        # Fallback: Try known path structure
        # This file is in zones/z07_data_access/config/
        # Platform root is 3 levels up
        fallback = Path(__file__).parent.parent.parent
        if fallback.name == "quiver_platform":
            return fallback

        raise RuntimeError(
            f"Cannot find platform root from {__file__}. "
            "Expected to be inside quiver_platform directory."
        )

    @classmethod
    def _load_config(cls):
        """Load .env from platform root and parse into structured config."""
        platform_root = cls._find_platform_root()
        env_path = platform_root / ".env"

        if not env_path.exists():
            raise RuntimeError(
                f".env file not found at {env_path}. "
                f"Please create it from the template in .audit/environment_config_audit_20251204.md"
            )

        # Load .env file (override=True to ensure new .env takes precedence)
        # This is important during migration from old scattered .env files
        load_dotenv(env_path, override=True)

        # Parse configuration into structured dictionary
        cls._config = {
            # PostgreSQL Database Configuration
            "postgres": {
                "host": os.getenv("POSTGRES_HOST", "localhost"),
                "port": int(os.getenv("POSTGRES_PORT", "5435")),
                "db_processed": os.getenv("POSTGRES_DB_PROCESSED", "sapphire_database"),
                "db_raw": os.getenv("POSTGRES_DB_RAW", "raw_database"),
                "user": os.getenv("POSTGRES_USER", "expo"),
                "password": os.getenv("POSTGRES_PASSWORD", ""),
                "connection_string": None,  # Generated below
            },
            # Neo4j Graph Database Configuration
            "neo4j": {
                "uri": os.getenv("NEO4J_URI", "bolt://localhost:7687"),
                "user": os.getenv("NEO4J_USER", "neo4j"),
                "password": os.getenv("NEO4J_PASSWORD", ""),
            },
            # ChromaDB Vector Store Configuration
            "chromadb": {
                "host": os.getenv("CHROMADB_HOST", "localhost"),
                "port": int(os.getenv("CHROMADB_PORT", "8004")),
            },
            # API Keys
            "api_keys": {
                "anthropic": os.getenv("ANTHROPIC_API_KEY", ""),
                "openai": os.getenv("OPENAI_API_KEY", ""),  # Legacy, deprecated
            },
            # Application Mode
            "mode": os.getenv("SAPPHIRE_MODE", "chainlit"),
            "tools_enabled": os.getenv("SAPPHIRE_TOOLS_ENABLED", "false").lower() == "true",
            "enable_intelligence": os.getenv("ENABLE_INTELLIGENCE", "true").lower() == "true",
            # Master Resolution Tables (Phase 2)
            "master_tables": {
                "enabled": os.getenv("USE_MASTER_RESOLUTION", "false").lower() == "true",
                "drug_table": os.getenv("DRUG_MASTER_TABLE", "drug_master_v1_0"),
                "gene_table": os.getenv("GENE_MASTER_TABLE", "gene_master_v1_0"),
                "pathway_table": os.getenv("PATHWAY_MASTER_TABLE", "pathway_master_v1_0"),
            },
            # Reporting
            "reporting": {
                "base_url": os.getenv("REPORTS_BASE_URL", "http://localhost:8082"),
            },
            # Performance & Resilience (Phase 7)
            "performance": {
                "db_pool_size": int(os.getenv("DB_CONNECTION_POOL_SIZE", "20")),
                "db_timeout": int(os.getenv("DB_CONNECTION_TIMEOUT", "30")),
                "circuit_breaker": os.getenv("ENABLE_CIRCUIT_BREAKER", "true").lower() == "true",
                "default_tool_timeout": float(os.getenv("DEFAULT_TOOL_TIMEOUT", "30.0")),
            },
            # Wave 4 Deployment Configuration
            "deployment": {
                "wave4_enabled": os.getenv("ENABLE_WAVE4", "false").lower() == "true",
                "canary_percentage": int(os.getenv("WAVE4_CANARY_PERCENTAGE", "0")),
                "fallback_to_wave3": os.getenv("WAVE4_FALLBACK_ENABLED", "true").lower() == "true",
            },
            # Rust Primitives Configuration
            "rust_primitives": {
                "enabled": os.getenv("ENABLE_RUST_PRIMITIVES", "false").lower() == "true",
                "fallback_on_error": os.getenv("RUST_FALLBACK_ON_ERROR", "true").lower() == "true",
                "pool_size": int(os.getenv("RUST_POOL_SIZE", "50")),
                "connection_timeout_ms": int(os.getenv("RUST_CONNECTION_TIMEOUT_MS", "30000")),
            },
            # Tier Router Configuration
            "tier_router": {
                "enabled": os.getenv("ENABLE_TIER_ROUTER", "false").lower() == "true",
                "ml_enabled": os.getenv("TIER_ROUTER_ML_ENABLED", "false").lower() == "true",
                "tier1_threshold": float(os.getenv("TIER1_THRESHOLD", "0.95")),
                "tier2_threshold": float(os.getenv("TIER2_THRESHOLD", "0.80")),
                "tier3_threshold": float(os.getenv("TIER3_THRESHOLD", "0.60")),
                "tier4_fallback": os.getenv("TIER4_FALLBACK", "true").lower() == "true",
                "ml_model_path": os.getenv("TIER_ML_MODEL_PATH", "models/tier_routing_v2.pkl"),
                "ml_accuracy_target": float(os.getenv("TIER_ML_ACCURACY_TARGET", "0.87")),
            },
            # Cache Configuration
            "cache": {
                "enabled": os.getenv("ENABLE_CACHE", "true").lower() == "true",
                "max_size": int(os.getenv("CACHE_MAX_SIZE", "20000")),
                "ttl_seconds": int(os.getenv("CACHE_TTL_SECONDS", "7200")),
                "eviction_policy": os.getenv("CACHE_EVICTION_POLICY", "lru"),
            },
            # Monitoring Configuration
            "monitoring": {
                "metrics_enabled": os.getenv("ENABLE_METRICS", "true").lower() == "true",
                "export_port": int(os.getenv("METRICS_EXPORT_PORT", "9090")),
                "log_level": os.getenv("LOG_LEVEL", "INFO"),
                "alert_on_degradation": os.getenv("ALERT_ON_DEGRADATION", "true").lower() == "true",
            },
        }

        # Generate PostgreSQL connection string
        pg = cls._config["postgres"]
        cls._config["postgres"]["connection_string"] = (
            f"postgresql://{pg['user']}:{pg['password']}@{pg['host']}:{pg['port']}/{pg['db_processed']}"
        )

        # Validate required fields
        cls._validate_config()

    @classmethod
    def _validate_config(cls):
        """
        Validate that required configuration fields are present.

        Raises:
            RuntimeError: If required fields are missing or invalid
        """
        errors = []

        # Check PostgreSQL password
        if not cls._config["postgres"]["password"]:
            errors.append("POSTGRES_PASSWORD is required")

        # Check Neo4j password
        if not cls._config["neo4j"]["password"]:
            errors.append("NEO4J_PASSWORD is required")

        # Check Anthropic API key (only if intelligence enabled)
        if cls._config["enable_intelligence"] and not cls._config["api_keys"]["anthropic"]:
            errors.append("ANTHROPIC_API_KEY is required when ENABLE_INTELLIGENCE=true")

        # Check port is correct (common mistake)
        if cls._config["postgres"]["port"] == 5432:
            errors.append(
                "POSTGRES_PORT=5432 detected. PGVector container uses port 5435, not 5432. "
                "Please update .env to POSTGRES_PORT=5435"
            )

        # Check mode is valid
        valid_modes = ["chainlit", "chainlit_minimal", "batch", "testing"]
        if cls._config["mode"] not in valid_modes:
            errors.append(
                f"SAPPHIRE_MODE='{cls._config['mode']}' is invalid. "
                f"Valid modes: {', '.join(valid_modes)}"
            )

        if errors:
            raise RuntimeError(
                f"Configuration validation failed:\n" + "\n".join(f"  - {e}" for e in errors)
            )

    @classmethod
    def get(cls, key_path: str, default: Any = None) -> Any:
        """
        Get configuration value using dot-notation path.

        Args:
            key_path: Dot-separated path to config value (e.g., "postgres.host")
            default: Default value if key not found

        Returns:
            Configuration value or default

        Examples:
            >>> config.get("postgres.host")
            'localhost'
            >>> config.get("postgres.port")
            5435
            >>> config.get("invalid.path", "fallback")
            'fallback'
        """
        if not cls._initialized:
            cls._instance = ConfigLoader()

        keys = key_path.split(".")
        value = cls._config

        for key in keys:
            if isinstance(value, dict) and key in value:
                value = value[key]
            else:
                return default

        return value if value is not None else default

    @classmethod
    def get_section(cls, section: str) -> Dict[str, Any]:
        """
        Get entire configuration section as dictionary.

        Args:
            section: Top-level section name (e.g., "postgres", "neo4j")

        Returns:
            Dictionary with all keys in that section

        Examples:
            >>> config.get_section("postgres")
            {
                'host': 'localhost',
                'port': 5435,
                'db_processed': 'sapphire_database',
                ...
            }
        """
        if not cls._initialized:
            cls._instance = ConfigLoader()

        return cls._config.get(section, {})

    @property
    def mode(self) -> str:
        """Get current application mode (chainlit, batch, testing, etc.)."""
        return self.get("mode", "chainlit")

    @property
    def tools_enabled(self) -> bool:
        """Check if tools are enabled (true for batch, false for pure conversational)."""
        return self.get("tools_enabled", False)

    @property
    def master_tables_enabled(self) -> bool:
        """Check if master resolution tables are enabled (Phase 2)."""
        return self.get("master_tables.enabled", False)

    def __repr__(self) -> str:
        """String representation of config (hides sensitive values)."""
        return (
            f"<ConfigLoader mode={self.mode} "
            f"postgres={self.get('postgres.host')}:{self.get('postgres.port')} "
            f"neo4j={self.get('neo4j.uri')} "
            f"tools_enabled={self.tools_enabled}>"
        )


# ============================================================================
# Global config instance (singleton)
# ============================================================================

config = ConfigLoader()


# ============================================================================
# Backward Compatibility Helpers
# ============================================================================

def get_postgres_connection_config() -> Dict[str, Any]:
    """
    Get PostgreSQL connection configuration (backward compatibility).

    Returns:
        Dictionary with host, port, database, user, password

    Deprecated: Use config.get_section("postgres") instead
    """
    return config.get_section("postgres")


def get_neo4j_connection_config() -> Dict[str, str]:
    """
    Get Neo4j connection configuration (backward compatibility).

    Returns:
        Dictionary with uri, user, password

    Deprecated: Use config.get_section("neo4j") instead
    """
    return config.get_section("neo4j")


def get_connection_string() -> str:
    """
    Get PostgreSQL connection string (backward compatibility).

    Returns:
        Connection string: postgresql://user:pass@host:port/database

    Deprecated: Use config.get("postgres.connection_string") instead
    """
    return config.get("postgres.connection_string")


# ============================================================================
# Module-level exports
# ============================================================================

__all__ = [
    "config",
    "ConfigLoader",
    "get_postgres_connection_config",
    "get_neo4j_connection_config",
    "get_connection_string",
]
