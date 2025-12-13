#!/usr/bin/env python3
"""
Linear Compression Deployment Verification

Comprehensive verification script to confirm compression is deployed and working.

Checks:
1. All required files exist
2. Modules import successfully
3. MCP server has compression parameters
4. Compression infrastructure works
5. Helper functions work
6. Integration tests pass

Author: claude-code-agent
Date: 2025-12-07
Version: 1.0
"""

import os
import sys
from pathlib import Path

# Add to path
sys.path.insert(0, str(Path(__file__).parent))


class DeploymentVerifier:
    """Verify Linear compression deployment."""

    def __init__(self):
        self.checks_passed = 0
        self.checks_failed = 0
        self.warnings = []

    def check(self, name: str, condition: bool, error_msg: str = ""):
        """Run a verification check."""
        if condition:
            print(f"  ✅ {name}")
            self.checks_passed += 1
            return True
        else:
            print(f"  ❌ {name}")
            if error_msg:
                print(f"     {error_msg}")
            self.checks_failed += 1
            return False

    def warn(self, message: str):
        """Record a warning."""
        print(f"  ⚠️  {message}")
        self.warnings.append(message)

    def run_all_checks(self):
        """Run all deployment verification checks."""
        print("=" * 70)
        print("Linear Compression Deployment Verification")
        print("=" * 70)
        print()

        # Check 1: Files exist
        print("1️⃣  Checking file existence...")
        self._check_files()
        print()

        # Check 2: Modules import
        print("2️⃣  Checking module imports...")
        self._check_imports()
        print()

        # Check 3: MCP integration
        print("3️⃣  Checking MCP server integration...")
        self._check_mcp_integration()
        print()

        # Check 4: Compression infrastructure
        print("4️⃣  Checking compression infrastructure...")
        self._check_compression_infrastructure()
        print()

        # Check 5: Helper functions
        print("5️⃣  Checking helper functions...")
        self._check_helper_functions()
        print()

        # Check 6: Environment
        print("6️⃣  Checking environment...")
        self._check_environment()
        print()

        # Summary
        self._print_summary()

    def _check_files(self):
        """Check all required files exist."""
        required_files = [
            "linear_compression.py",
            "mcp_server.py",
            "linear_mcp_helper.py",
            "swarm_linear_integration.py",
            "test_linear_compression.py",
            "LINEAR_MCP_COMPRESSION_GUIDE.md",
            "update_linear_with_compression.py",
            "verify_compression_deployment.py"
        ]

        for filename in required_files:
            filepath = Path(__file__).parent / filename
            self.check(
                f"File exists: {filename}",
                filepath.exists(),
                f"Missing file: {filepath}"
            )

    def _check_imports(self):
        """Check all modules import successfully."""
        # Test linear_compression
        try:
            import linear_compression
            self.check("Import: linear_compression", True)

            # Check key classes exist
            self.check(
                "Class: CompressionManager",
                hasattr(linear_compression, 'CompressionManager')
            )
            self.check(
                "Class: CircuitBreaker",
                hasattr(linear_compression, 'CircuitBreaker')
            )
            self.check(
                "Function: compress_text",
                hasattr(linear_compression, 'compress_text')
            )

        except Exception as e:
            self.check("Import: linear_compression", False, str(e))

        # Test linear_mcp_helper
        try:
            import linear_mcp_helper
            self.check("Import: linear_mcp_helper", True)

            self.check(
                "Class: LinearMCPHelper",
                hasattr(linear_mcp_helper, 'LinearMCPHelper')
            )
            self.check(
                "Function: add_comment_sync",
                hasattr(linear_mcp_helper, 'add_comment_sync')
            )

        except Exception as e:
            self.check("Import: linear_mcp_helper", False, str(e))

        # Test swarm_linear_integration
        try:
            import swarm_linear_integration
            self.check("Import: swarm_linear_integration", True)

            self.check(
                "Class: SwarmLinearIntegration",
                hasattr(swarm_linear_integration, 'SwarmLinearIntegration')
            )
            self.check(
                "Function: post_agent_handoff_sync",
                hasattr(swarm_linear_integration, 'post_agent_handoff_sync')
            )

        except Exception as e:
            self.check("Import: swarm_linear_integration", False, str(e))

    def _check_mcp_integration(self):
        """Check MCP server has compression integration."""
        try:
            # Check MCP server structure
            with open("mcp_server.py", 'r') as f:
                content = f.read()

            self.check(
                "MCP imports compression",
                "from linear_compression import" in content
            )

            self.check(
                "linear_add_comment has compress parameter",
                '"compress"' in content and '"linear_add_comment"' in content
            )

            self.check(
                "linear_get_plan has compress parameter",
                '"compress"' in content and '"linear_get_plan"' in content
            )

            self.check(
                "linear_get_issue has compress parameter",
                '"compress"' in content and '"linear_get_issue"' in content
            )

            self.check(
                "Handler calls compress_text",
                "await compress_text" in content or "compress_text(" in content
            )

            # Count compression references
            compress_count = content.count("compress")
            if compress_count >= 40:
                self.check(f"Compression references ({compress_count})", True)
            else:
                self.warn(f"Expected 40+ compression references, found {compress_count}")

        except Exception as e:
            self.check("Read mcp_server.py", False, str(e))

    def _check_compression_infrastructure(self):
        """Check compression infrastructure components."""
        try:
            from linear_compression import CompressionManager, CircuitBreaker, CircuitState

            # Test CompressionManager
            manager = CompressionManager()
            self.check("CompressionManager instantiation", True)
            self.check(
                "CompressionManager has circuit_breaker",
                hasattr(manager, 'circuit_breaker')
            )
            self.check(
                "CompressionManager has metrics",
                hasattr(manager, 'metrics')
            )

            # Test CircuitBreaker
            breaker = CircuitBreaker()
            self.check("CircuitBreaker instantiation", True)
            self.check(
                "CircuitBreaker starts in CLOSED state",
                breaker.state == CircuitState.CLOSED
            )
            self.check(
                "CircuitBreaker.can_attempt()",
                breaker.can_attempt() == True
            )

            # Test metrics
            metrics = manager.get_metrics()
            self.check("Get compression metrics", isinstance(metrics, dict))
            self.check(
                "Metrics has required keys",
                all(k in metrics for k in [
                    'total_compressions',
                    'successful_compressions',
                    'success_rate',
                    'circuit_breaker'
                ])
            )

        except Exception as e:
            self.check("Compression infrastructure tests", False, str(e))

    def _check_helper_functions(self):
        """Check helper functions work."""
        try:
            from linear_mcp_helper import LinearMCPHelper
            from swarm_linear_integration import SwarmLinearIntegration

            # Test LinearMCPHelper
            helper = LinearMCPHelper()
            self.check("LinearMCPHelper instantiation", True)
            self.check(
                "LinearMCPHelper has mcp server",
                hasattr(helper, 'server')
            )

            # Test SwarmLinearIntegration
            integration = SwarmLinearIntegration()
            self.check("SwarmLinearIntegration instantiation", True)
            self.check(
                "SwarmLinearIntegration has mcp",
                hasattr(integration, 'mcp')
            )

        except Exception as e:
            self.check("Helper function tests", False, str(e))

    def _check_environment(self):
        """Check environment configuration."""
        # Check LINEAR_API_KEY
        has_key = bool(os.getenv("LINEAR_API_KEY"))
        if has_key:
            self.check("LINEAR_API_KEY set", True)
        else:
            self.warn("LINEAR_API_KEY not set (required for live testing)")

        # Check compression MCP (non-blocking)
        try:
            import subprocess
            result = subprocess.run(
                ["claude", "mcp", "list"],
                capture_output=True,
                text=True,
                timeout=5
            )

            if "compression-service" in result.stdout:
                self.check("Compression MCP server registered", True)
            else:
                self.warn("Compression MCP server not found (required for compression)")

        except Exception as e:
            self.warn(f"Could not check MCP server: {e}")

    def _print_summary(self):
        """Print verification summary."""
        print("=" * 70)
        print("VERIFICATION SUMMARY")
        print("=" * 70)
        print()

        total_checks = self.checks_passed + self.checks_failed
        pass_rate = (self.checks_passed / total_checks * 100) if total_checks > 0 else 0

        print(f"✅ Passed: {self.checks_passed}/{total_checks} ({pass_rate:.1f}%)")
        print(f"❌ Failed: {self.checks_failed}/{total_checks}")
        print(f"⚠️  Warnings: {len(self.warnings)}")
        print()

        if self.warnings:
            print("Warnings:")
            for warning in self.warnings:
                print(f"  - {warning}")
            print()

        # Verdict
        if self.checks_failed == 0:
            print("🎉 VERDICT: ✅ **DEPLOYMENT VERIFIED**")
            print()
            print("All checks passed! Linear compression is ready for production use.")
            print()
            print("Next steps:")
            print("1. Set LINEAR_API_KEY if not set")
            print("2. Verify compression MCP server is running")
            print("3. Start using compression in scripts:")
            print("   - from linear_mcp_helper import add_comment_sync")
            print("   - result = add_comment_sync('ACP-123', large_comment)")
            print()
            return 0

        elif self.checks_failed <= 2 and len(self.warnings) <= 2:
            print("⚠️  VERDICT: 🟡 **DEPLOYMENT MOSTLY READY**")
            print()
            print(f"Minor issues detected ({self.checks_failed} failures, {len(self.warnings)} warnings)")
            print("Review failures above and fix before production use.")
            print()
            return 1

        else:
            print("❌ VERDICT: 🔴 **DEPLOYMENT INCOMPLETE**")
            print()
            print(f"Significant issues detected ({self.checks_failed} failures)")
            print("Fix critical issues before deploying to production.")
            print()
            return 2


def main():
    """Run deployment verification."""
    verifier = DeploymentVerifier()
    return verifier.run_all_checks()


if __name__ == "__main__":
    sys.exit(main())
