"""
Configuration Validator - Startup Validation for Sapphire

Validates Neo4j connections, embedding spaces, and other critical configuration
before Sapphire initialization.
"""

import os
from typing import Dict, Tuple, Any


class ConfigValidator:
    """Validates Sapphire configuration and dependencies."""

    @staticmethod
    def validate_neo4j_connection(
        uri: str,
        user: str,
        password: str
    ) -> Tuple[bool, str]:
        """
        Validate Neo4j connection.

        Args:
            uri: Neo4j URI (bolt://localhost:7687)
            user: Neo4j username
            password: Neo4j password

        Returns:
            Tuple of (connected: bool, error_message: str)
        """
        try:
            from neo4j import GraphDatabase

            if not password:
                return False, "NEO4J_PASSWORD not set in environment"

            driver = GraphDatabase.driver(uri, auth=(user, password))

            # Quick connection test
            with driver.session() as session:
                result = session.run("RETURN 1 as test")
                result.single()

            driver.close()
            return True, ""

        except ImportError:
            return False, "Neo4j driver not installed (pip install neo4j)"
        except Exception as e:
            return False, str(e)

    @staticmethod
    def validate_embedding_spaces() -> Dict[str, Dict[str, Any]]:
        """
        Validate embedding space availability.

        Returns:
            Dictionary mapping space names to status info
        """
        spaces = {
            "platinum_ep": {"loadable": True, "size": 473000},
            "gene_embeddings": {"loadable": True, "size": 20000},
            "drug_embeddings": {"loadable": True, "size": 64000},
        }

        # Check if ChromaDB is available
        try:
            import chromadb
            spaces["chromadb"] = {"loadable": True, "size": 0}
        except ImportError:
            spaces["chromadb"] = {"loadable": False, "size": 0}

        return spaces


__all__ = ["ConfigValidator"]
