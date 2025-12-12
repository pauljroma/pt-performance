#!/usr/bin/env python3
"""
Linear Compression Infrastructure

Provides compression capabilities for Linear MCP server with:
- Circuit breaker pattern for resilience
- Timeout protection
- Graceful fallback
- Metrics tracking

Author: claude-code-agent
Date: 2025-12-07
Version: 1.0
"""

import asyncio
import json
import logging
import subprocess
import time
from dataclasses import dataclass, field
from enum import Enum
from typing import Optional, Tuple, Dict
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)


# ============================================================================
# Circuit Breaker
# ============================================================================

class CircuitState(Enum):
    """Circuit breaker states."""
    CLOSED = "closed"  # Normal operation
    OPEN = "open"  # Failing, skip compression
    HALF_OPEN = "half_open"  # Testing recovery


@dataclass
class CircuitBreaker:
    """
    Circuit breaker for compression service.

    Prevents cascading failures by auto-disabling compression
    when the service is unavailable.
    """
    failure_threshold: int = 3  # Failures before opening
    recovery_timeout: int = 60  # Seconds before retry
    success_threshold: int = 2  # Successes to close from half-open

    # Internal state
    state: CircuitState = CircuitState.CLOSED
    failure_count: int = 0
    success_count: int = 0
    last_failure_time: Optional[datetime] = None

    def record_success(self):
        """Record successful compression."""
        if self.state == CircuitState.HALF_OPEN:
            self.success_count += 1
            if self.success_count >= self.success_threshold:
                logger.info("Circuit breaker closing (recovery successful)")
                self.state = CircuitState.CLOSED
                self.failure_count = 0
                self.success_count = 0
        elif self.state == CircuitState.CLOSED:
            # Reset failure count on success
            self.failure_count = 0

    def record_failure(self):
        """Record failed compression."""
        self.failure_count += 1
        self.last_failure_time = datetime.now()

        if self.state == CircuitState.CLOSED:
            if self.failure_count >= self.failure_threshold:
                logger.warning(
                    f"Circuit breaker opening ({self.failure_count} failures)"
                )
                self.state = CircuitState.OPEN
        elif self.state == CircuitState.HALF_OPEN:
            logger.warning("Circuit breaker re-opening (test failed)")
            self.state = CircuitState.OPEN
            self.success_count = 0

    def can_attempt(self) -> bool:
        """Check if compression attempt is allowed."""
        if self.state == CircuitState.CLOSED:
            return True

        if self.state == CircuitState.HALF_OPEN:
            return True

        # OPEN state - check if recovery timeout passed
        if self.last_failure_time:
            time_since_failure = (datetime.now() - self.last_failure_time).total_seconds()
            if time_since_failure >= self.recovery_timeout:
                logger.info("Circuit breaker entering half-open (testing recovery)")
                self.state = CircuitState.HALF_OPEN
                self.success_count = 0
                return True

        return False

    def get_status(self) -> Dict:
        """Get circuit breaker status."""
        return {
            "state": self.state.value,
            "failure_count": self.failure_count,
            "success_count": self.success_count,
            "last_failure": self.last_failure_time.isoformat() if self.last_failure_time else None
        }


# ============================================================================
# Compression Manager
# ============================================================================

@dataclass
class CompressionMetrics:
    """Compression service metrics."""
    total_compressions: int = 0
    successful_compressions: int = 0
    failed_compressions: int = 0
    fallback_count: int = 0
    total_tokens_saved: int = 0
    compression_ratios: list = field(default_factory=list)

    @property
    def success_rate(self) -> float:
        """Calculate success rate."""
        if self.total_compressions == 0:
            return 0.0
        return self.successful_compressions / self.total_compressions

    @property
    def average_compression_ratio(self) -> float:
        """Calculate average compression ratio."""
        if not self.compression_ratios:
            return 0.0
        return sum(self.compression_ratios) / len(self.compression_ratios)


class CompressionManager:
    """
    Manages compression for Linear MCP server.

    Features:
    - Calls compression MCP service
    - Circuit breaker for resilience
    - Timeout protection
    - Graceful fallback
    - Metrics tracking
    """

    def __init__(
        self,
        timeout_seconds: int = 5,
        min_size_kb: int = 10,
        min_compression_ratio: float = 1.5
    ):
        """
        Initialize compression manager.

        Args:
            timeout_seconds: Max seconds for compression operation
            min_size_kb: Minimum text size (KB) to compress
            min_compression_ratio: Minimum ratio to consider effective
        """
        self.timeout_seconds = timeout_seconds
        self.min_size_kb = min_size_kb
        self.min_compression_ratio = min_compression_ratio

        self.circuit_breaker = CircuitBreaker()
        self.metrics = CompressionMetrics()

    async def compress_text(
        self,
        text: str,
        level: str = "balanced"
    ) -> Tuple[str, Dict]:
        """
        Compress text using compression MCP service.

        Args:
            text: Text to compress
            level: Compression level (fast/balanced/aggressive)

        Returns:
            Tuple of (compressed_text, metadata)
            Falls back to original text on any error.
        """
        start_time = time.time()

        try:
            # Pre-flight checks
            if not await self.should_compress(text):
                logger.debug("Compression skipped (pre-flight validation)")
                return self._create_fallback_response(text, "skipped_validation")

            # Estimate input tokens
            input_tokens = self._estimate_tokens(text)

            # Call compression service with timeout
            compressed_text = await asyncio.wait_for(
                self._call_compression_service(text, level),
                timeout=self.timeout_seconds
            )

            # Estimate output tokens
            output_tokens = self._estimate_tokens(compressed_text)

            # Validate compression effectiveness
            if output_tokens == 0:
                raise ValueError("Compression produced empty output")

            compression_ratio = input_tokens / output_tokens

            if compression_ratio < self.min_compression_ratio:
                logger.warning(
                    f"Compression ineffective: {compression_ratio:.1f}x "
                    f"(min {self.min_compression_ratio}x)"
                )
                return self._create_fallback_response(text, "ineffective_compression")

            # Success - update metrics and circuit breaker
            duration = time.time() - start_time
            metadata = {
                "original_tokens": input_tokens,
                "compressed_tokens": output_tokens,
                "compression_ratio": compression_ratio,
                "tokens_saved": input_tokens - output_tokens,
                "level": level,
                "duration_sec": duration,
                "status": "success"
            }

            self.circuit_breaker.record_success()
            self._update_metrics(metadata, success=True)

            logger.info(
                f"Compression successful: {compression_ratio:.1f}x "
                f"({input_tokens:,} → {output_tokens:,} tokens) in {duration:.2f}s"
            )

            return compressed_text, metadata

        except asyncio.TimeoutError:
            logger.error(f"Compression timeout ({self.timeout_seconds}s)")
            self.circuit_breaker.record_failure()
            self._update_metrics({}, success=False)
            return self._create_fallback_response(text, "timeout")

        except Exception as e:
            logger.error(f"Compression error: {e}")
            self.circuit_breaker.record_failure()
            self._update_metrics({}, success=False)
            return self._create_fallback_response(text, f"error: {str(e)}")

    async def should_compress(self, text: str) -> bool:
        """
        Determine if compression should be attempted.

        Checks:
        - Text size meets minimum
        - Circuit breaker allows attempt

        Returns:
            True if compression should proceed
        """
        # Check size threshold
        text_size_kb = len(text) / 1024
        if text_size_kb < self.min_size_kb:
            logger.debug(f"Text too small for compression: {text_size_kb:.1f}KB")
            return False

        # Check circuit breaker
        if not self.circuit_breaker.can_attempt():
            logger.warning("Compression blocked by circuit breaker")
            return False

        return True

    async def _call_compression_service(
        self,
        text: str,
        level: str
    ) -> str:
        """
        Call compression MCP service via subprocess.

        Uses claude mcp call to invoke compression service.
        """
        # Prepare MCP tool call
        tool_args = {
            "conversation_text": text,
            "level": level
        }

        # Call via subprocess (simulates MCP call)
        # In production, this would use proper MCP client
        process = await asyncio.create_subprocess_exec(
            "claude",
            "mcp",
            "call",
            "compression-service",
            "compress_conversation",
            json.dumps(tool_args),
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )

        stdout, stderr = await process.communicate()

        if process.returncode != 0:
            raise RuntimeError(f"Compression service call failed: {stderr.decode()}")

        # Parse response
        response = json.loads(stdout.decode())

        # Extract compressed text from response
        # Format depends on MCP service response structure
        if "content" in response and len(response["content"]) > 0:
            # Extract from markdown response
            content = response["content"][0]["text"]
            # Parse compressed text from markdown
            if "## Compressed Text" in content:
                compressed = content.split("## Compressed Text")[1]
                compressed = compressed.split("```")[1].strip()
                return compressed

        raise ValueError("Could not extract compressed text from response")

    def _estimate_tokens(self, text: str) -> int:
        """Estimate token count (4 chars per token)."""
        return len(text) // 4

    def _create_fallback_response(
        self,
        original_text: str,
        reason: str
    ) -> Tuple[str, Dict]:
        """Create fallback response (use original text)."""
        tokens = self._estimate_tokens(original_text)

        metadata = {
            "original_tokens": tokens,
            "compressed_tokens": tokens,
            "compression_ratio": 1.0,
            "tokens_saved": 0,
            "level": "none",
            "duration_sec": 0.0,
            "status": "fallback",
            "fallback_reason": reason
        }

        self.metrics.fallback_count += 1

        return original_text, metadata

    def _update_metrics(self, metadata: Dict, success: bool):
        """Update compression metrics."""
        self.metrics.total_compressions += 1

        if success:
            self.metrics.successful_compressions += 1
            self.metrics.total_tokens_saved += metadata.get("tokens_saved", 0)
            self.metrics.compression_ratios.append(metadata.get("compression_ratio", 1.0))
        else:
            self.metrics.failed_compressions += 1

    def get_metrics(self) -> Dict:
        """Get current metrics."""
        return {
            "total_compressions": self.metrics.total_compressions,
            "successful_compressions": self.metrics.successful_compressions,
            "failed_compressions": self.metrics.failed_compressions,
            "fallback_count": self.metrics.fallback_count,
            "success_rate": self.metrics.success_rate,
            "total_tokens_saved": self.metrics.total_tokens_saved,
            "average_compression_ratio": self.metrics.average_compression_ratio,
            "circuit_breaker": self.circuit_breaker.get_status()
        }

    def reset_metrics(self):
        """Reset all metrics."""
        self.metrics = CompressionMetrics()


# ============================================================================
# Global Instance
# ============================================================================

# Create global compression manager instance
compression_manager = CompressionManager()


# ============================================================================
# Convenience Functions
# ============================================================================

async def compress_text(text: str, level: str = "balanced") -> Tuple[str, Dict]:
    """
    Compress text using global compression manager.

    Convenience function for easy integration.
    """
    return await compression_manager.compress_text(text, level)


async def should_compress(text: str) -> bool:
    """Check if text should be compressed."""
    return await compression_manager.should_compress(text)


def get_compression_metrics() -> Dict:
    """Get compression metrics."""
    return compression_manager.get_metrics()
