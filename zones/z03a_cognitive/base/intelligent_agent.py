"""
IntelligentAgent Base Class - Wave 1 Foundation

Provides a standardized interface for intelligent agents with execute() pattern,
context management, error handling, and optional tool integration hooks.

Design Principles:
- Optional adoption (no breaking changes to existing code)
- Clear execute() interface for all agent operations
- Standardized context and error handling
- Extensible for Wave 3-4 tool integration
- Enable future agent migration without rewrite

Usage:
    class MyAgent(IntelligentAgent):
        def execute(self, context: dict) -> dict:
            # Implement agent logic here
            return {"status": "success", "result": data}
"""

from abc import ABC, abstractmethod
from typing import Dict, Any, Optional
import logging
from datetime import datetime


class IntelligentAgent(ABC):
    """
    Base class for intelligent agents with semantic search, reasoning, and tool calling.

    Wave 1 Foundation: Provides execute() interface and context management.
    Wave 3-4: Will add tool integration, semantic search, and LLM reasoning.

    Attributes:
        name (str): Agent identifier for logging and tracking
        logger (logging.Logger): Configured logger instance
        context_history (list): History of execution contexts for debugging
    """

    def __init__(self, name: str, enable_context_history: bool = False):
        """
        Initialize the intelligent agent.

        Args:
            name: Agent identifier (used for logging)
            enable_context_history: Whether to track context history (default: False)
        """
        self.name = name
        self.logger = self._setup_logger()
        self.enable_context_history = enable_context_history
        self.context_history = [] if enable_context_history else None
        self.logger.info(f"Initialized {self.__class__.__name__}: {self.name}")

    def _setup_logger(self) -> logging.Logger:
        """Configure logger for this agent instance."""
        logger = logging.getLogger(f"intelligent_agent.{self.name}")
        if not logger.handlers:
            handler = logging.StreamHandler()
            formatter = logging.Formatter(
                '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
            )
            handler.setFormatter(formatter)
            logger.addHandler(handler)
            logger.setLevel(logging.INFO)
        return logger

    @abstractmethod
    def execute(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute the agent with the given context.

        This is the primary interface method that all agents must implement.

        Args:
            context: Dictionary containing input data and configuration
                Required keys depend on agent implementation

        Returns:
            Dictionary containing execution results:
                - status: "success" | "error" | "partial"
                - result: Agent-specific output data
                - metadata: Optional execution metadata

        Raises:
            NotImplementedError: Must be implemented by subclass
        """
        pass

    def _handle_error(self, error: Exception, context: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        Standard error handling for agent execution.

        Args:
            error: Exception that occurred during execution
            context: Optional context that was being processed

        Returns:
            Standardized error response dictionary
        """
        error_msg = f"{self.name} execution failed: {str(error)}"
        self.logger.error(error_msg, exc_info=True)

        return {
            "status": "error",
            "error": str(error),
            "error_type": type(error).__name__,
            "agent": self.name,
            "timestamp": datetime.utcnow().isoformat(),
            "context": context if context else None
        }

    def _track_context(self, context: Dict[str, Any]) -> None:
        """
        Track context in history if enabled.

        Args:
            context: Context dictionary to track
        """
        if self.enable_context_history and self.context_history is not None:
            self.context_history.append({
                "timestamp": datetime.utcnow().isoformat(),
                "context": context.copy()
            })

            # Limit history to last 100 entries to prevent memory bloat
            if len(self.context_history) > 100:
                self.context_history = self.context_history[-100:]

    def get_context_history(self) -> Optional[list]:
        """
        Get the context execution history.

        Returns:
            List of historical contexts if enabled, None otherwise
        """
        return self.context_history if self.enable_context_history else None

    def clear_context_history(self) -> None:
        """Clear the context execution history."""
        if self.enable_context_history and self.context_history is not None:
            self.context_history.clear()
            self.logger.info(f"Cleared context history for {self.name}")

    # Wave 3-4: Tool integration hooks (placeholder for future)
    def _register_tool(self, tool_name: str, tool_func: callable) -> None:
        """
        Placeholder for Wave 3-4 tool registration.

        Future: Enable agents to register and call external tools.
        """
        raise NotImplementedError("Tool integration coming in Wave 3-4")

    def _call_tool(self, tool_name: str, **kwargs) -> Any:
        """
        Placeholder for Wave 3-4 tool calling.

        Future: Enable agents to invoke registered tools.
        """
        raise NotImplementedError("Tool integration coming in Wave 3-4")
