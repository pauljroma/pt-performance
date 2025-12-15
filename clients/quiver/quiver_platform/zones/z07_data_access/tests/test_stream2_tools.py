#!/usr/bin/env python3
"""
Test Suite for Stream 2 Advanced Reasoning Tools

Tests all 3 tools with known relationships to validate:
1. Mechanistic Explainer - Mechanism discovery
2. Causal Inference - Causality assessment
3. Uncertainty Estimation - Confidence quantification

Test Cases:
- Strong causal relationships (SCN1A → Dravet)
- Drug mechanisms (Rapamycin → TSC)
- Weak associations (confounded)
- Edge cases (not found, invalid inputs)
"""

import asyncio
import sys
from pathlib import Path
import json
import time
from typing import Dict, Any, List

# Add parent directory to path for tool imports
sys.path.insert(0, str(Path(__file__).parent.parent))

# Import the three Stream 2 tools
try:
    from tools import mechanistic_explainer, causal_inference, uncertainty_estimation
    TOOLS_AVAILABLE = True
except ImportError as e:
    print(f"❌ Error importing tools: {e}")
    TOOLS_AVAILABLE = False


# Test Cases Database
TEST_CASES = {
    "mechanistic_explainer": [
        {
            "name": "Rapamycin → Tuberous Sclerosis",
            "input": {
                "drug": "Rapamycin",
                "disease": "Tuberous Sclerosis",
                "explanation_style": "detailed"
            },
            "expected": {
                "success": True,
                "mechanism_count": ">0",
                "confidence": ">0.7",
                "keywords": ["mTOR", "pathway", "TSC"]
            }
        },
        {
            "name": "Fenfluramine → Dravet Syndrome",
            "input": {
                "drug": "Fenfluramine",
                "disease": "Dravet Syndrome",
                "gene": "SCN1A",
                "include_rescue": True
            },
            "expected": {
                "success": True,
                "mechanism_count": ">0",
                "rescue_count": ">0",
                "keywords": ["SCN1A", "rescue", "serotonin"]
            }
        },
        {
            "name": "Aspirin → Cardiovascular Disease",
            "input": {
                "drug": "Aspirin",
                "disease": "Cardiovascular Disease",
                "explanation_style": "summary"
            },
            "expected": {
                "success": True,
                "mechanism_count": ">0",
                "keywords": ["COX", "prostaglandin"]
            }
        },
        {
            "name": "Invalid drug (not found)",
            "input": {
                "drug": "NonExistentDrug12345",
                "disease": "Cancer"
            },
            "expected": {
                "success": False,
                "error": "not found"
            }
        }
    ],
    "causal_inference": [
        {
            "name": "SCN1A → Dravet Syndrome (strong causal)",
            "input": {
                "cause": "SCN1A",
                "effect": "Dravet Syndrome",
                "explanation_detail": "detailed"
            },
            "expected": {
                "success": True,
                "causal_strength": ">0.7",
                "criteria_met": ">=6",
                "causal_direction": "forward",
                "keywords": ["STRONG", "causal"]
            }
        },
        {
            "name": "Aspirin → Cardiovascular Disease (probable causal)",
            "input": {
                "cause": "Aspirin",
                "effect": "Cardiovascular Disease"
            },
            "expected": {
                "success": True,
                "causal_strength": ">0.6",
                "criteria_met": ">=5",
                "keywords": ["PROBABLE", "RCT"]
            }
        },
        {
            "name": "BRCA1 → Breast Cancer (strong causal)",
            "input": {
                "cause": "BRCA1",
                "effect": "Breast Cancer"
            },
            "expected": {
                "success": True,
                "causal_strength": ">0.7",
                "criteria_met": ">=6"
            }
        },
        {
            "name": "Invalid cause (not found)",
            "input": {
                "cause": "NonExistentGene12345",
                "effect": "Cancer"
            },
            "expected": {
                "success": False,
                "error": "not found"
            }
        }
    ],
    "uncertainty_estimation": [
        {
            "name": "High confidence prediction",
            "input": {
                "prediction_type": "rescue_score",
                "point_estimate": 0.85,
                "entity1": "Fenfluramine",
                "entity2": "SCN1A",
                "method": "all",
                "evidence_metadata": {
                    "sample_size": 2000,
                    "replication_count": 5
                }
            },
            "expected": {
                "success": True,
                "confidence_interval": "exists",
                "uncertainty_width": "<0.20",
                "reliability_score": ">0.7",
                "keywords": ["HIGH CONFIDENCE"]
            }
        },
        {
            "name": "Moderate confidence prediction",
            "input": {
                "prediction_type": "similarity_score",
                "point_estimate": 0.65,
                "method": "bootstrap",
                "evidence_metadata": {
                    "sample_size": 500,
                    "replication_count": 2
                }
            },
            "expected": {
                "success": True,
                "confidence_interval": "exists",
                "uncertainty_width": "<0.30",
                "reliability_score": ">0.5"
            }
        },
        {
            "name": "Low confidence prediction",
            "input": {
                "prediction_type": "custom",
                "point_estimate": 0.45,
                "method": "all",
                "evidence_metadata": {
                    "sample_size": 100,
                    "replication_count": 1
                }
            },
            "expected": {
                "success": True,
                "epistemic_uncertainty": ">0.2",
                "reliability_score": "<0.7"
            }
        },
        {
            "name": "Invalid point estimate",
            "input": {
                "prediction_type": "rescue_score",
                "point_estimate": 1.5  # Out of range
            },
            "expected": {
                "success": False,
                "error": "must be between"
            }
        }
    ]
}


class TestRunner:
    """Test runner for Stream 2 tools."""

    def __init__(self):
        self.results = {
            "mechanistic_explainer": [],
            "causal_inference": [],
            "uncertainty_estimation": []
        }
        self.summary = {
            "total": 0,
            "passed": 0,
            "failed": 0,
            "errors": 0
        }

    async def run_all_tests(self):
        """Run all test cases for all tools."""
        print("=" * 80)
        print("STREAM 2 TOOLS - COMPREHENSIVE TEST SUITE")
        print("=" * 80)
        print()

        if not TOOLS_AVAILABLE:
            print("❌ Tools not available. Cannot run tests.")
            return

        # Test each tool
        await self.test_mechanistic_explainer()
        await self.test_causal_inference()
        await self.test_uncertainty_estimation()

        # Print summary
        self.print_summary()

    async def test_mechanistic_explainer(self):
        """Test mechanistic_explainer tool."""
        print("📋 Testing Mechanistic Explainer")
        print("-" * 80)

        for test_case in TEST_CASES["mechanistic_explainer"]:
            await self.run_test(
                "mechanistic_explainer",
                test_case,
                mechanistic_explainer.execute
            )

        print()

    async def test_causal_inference(self):
        """Test causal_inference tool."""
        print("📋 Testing Causal Inference")
        print("-" * 80)

        for test_case in TEST_CASES["causal_inference"]:
            await self.run_test(
                "causal_inference",
                test_case,
                causal_inference.execute
            )

        print()

    async def test_uncertainty_estimation(self):
        """Test uncertainty_estimation tool."""
        print("📋 Testing Uncertainty Estimation")
        print("-" * 80)

        for test_case in TEST_CASES["uncertainty_estimation"]:
            await self.run_test(
                "uncertainty_estimation",
                test_case,
                uncertainty_estimation.execute
            )

        print()

    async def run_test(self, tool_name: str, test_case: Dict, execute_func):
        """Run a single test case."""
        test_name = test_case["name"]
        test_input = test_case["input"]
        expected = test_case["expected"]

        self.summary["total"] += 1

        print(f"  Testing: {test_name}...", end=" ")

        try:
            # Execute tool
            start_time = time.time()
            result = await execute_func(test_input)
            elapsed = (time.time() - start_time) * 1000  # ms

            # Validate result
            passed, validation_msg = self.validate_result(result, expected)

            if passed:
                print(f"✅ PASS ({elapsed:.0f}ms)")
                self.summary["passed"] += 1
                self.results[tool_name].append({
                    "test": test_name,
                    "status": "PASS",
                    "elapsed_ms": elapsed,
                    "result": result
                })
            else:
                print(f"❌ FAIL ({elapsed:.0f}ms)")
                print(f"     Reason: {validation_msg}")
                self.summary["failed"] += 1
                self.results[tool_name].append({
                    "test": test_name,
                    "status": "FAIL",
                    "elapsed_ms": elapsed,
                    "reason": validation_msg,
                    "result": result
                })

        except Exception as e:
            print(f"💥 ERROR")
            print(f"     Exception: {str(e)}")
            self.summary["errors"] += 1
            self.results[tool_name].append({
                "test": test_name,
                "status": "ERROR",
                "error": str(e)
            })

    def validate_result(self, result: Dict[str, Any], expected: Dict[str, Any]) -> tuple:
        """
        Validate result against expected outcomes.

        Returns:
            (passed: bool, message: str)
        """
        # Check success flag
        if "success" in expected:
            if result.get("success") != expected["success"]:
                return (False, f"Expected success={expected['success']}, got {result.get('success')}")

        # Check error presence
        if expected.get("success") == False:
            if "error" in expected:
                error_keyword = expected["error"]
                if error_keyword not in result.get("error", "").lower():
                    return (False, f"Expected error containing '{error_keyword}'")
            return (True, "Error case validated")

        # Check numeric thresholds
        for key, threshold in expected.items():
            if key in ["mechanism_count", "rescue_count", "criteria_met"]:
                # Check >= before > to avoid ">=" matching ">" first
                if isinstance(threshold, str) and threshold.startswith(">="):
                    min_value = float(threshold[2:])
                    if result.get(key, 0) < min_value:
                        return (False, f"{key} should be >={min_value}, got {result.get(key)}")
                elif isinstance(threshold, str) and threshold.startswith(">"):
                    min_value = float(threshold[1:])
                    if result.get(key, 0) <= min_value:
                        return (False, f"{key} should be >{min_value}, got {result.get(key)}")

            elif key in ["causal_strength", "confidence", "reliability_score"]:
                if isinstance(threshold, str) and threshold.startswith(">"):
                    min_value = float(threshold[1:])
                    if result.get(key, 0) <= min_value:
                        return (False, f"{key} should be >{min_value}, got {result.get(key)}")

            elif key in ["uncertainty_width", "epistemic_uncertainty"]:
                if isinstance(threshold, str) and threshold.startswith("<"):
                    max_value = float(threshold[1:])
                    if result.get(key, 1.0) >= max_value:
                        return (False, f"{key} should be <{max_value}, got {result.get(key)}")
                elif isinstance(threshold, str) and threshold.startswith(">"):
                    min_value = float(threshold[1:])
                    if result.get(key, 0) <= min_value:
                        return (False, f"{key} should be >{min_value}, got {result.get(key)}")

        # Check keywords
        if "keywords" in expected:
            result_str = json.dumps(result).lower()
            for keyword in expected["keywords"]:
                if keyword.lower() not in result_str:
                    return (False, f"Expected keyword '{keyword}' not found in result")

        # Check existence
        if "confidence_interval" in expected and expected["confidence_interval"] == "exists":
            if "confidence_interval" not in result:
                return (False, "confidence_interval not present in result")

        return (True, "All checks passed")

    def print_summary(self):
        """Print test summary."""
        print("=" * 80)
        print("TEST SUMMARY")
        print("=" * 80)
        print()

        total = self.summary["total"]
        passed = self.summary["passed"]
        failed = self.summary["failed"]
        errors = self.summary["errors"]

        pass_rate = (passed / total * 100) if total > 0 else 0

        print(f"Total Tests:   {total}")
        print(f"✅ Passed:     {passed}")
        print(f"❌ Failed:     {failed}")
        print(f"💥 Errors:     {errors}")
        print(f"Pass Rate:     {pass_rate:.1f}%")
        print()

        # Per-tool breakdown
        for tool_name in ["mechanistic_explainer", "causal_inference", "uncertainty_estimation"]:
            tool_results = self.results[tool_name]
            tool_passed = sum(1 for r in tool_results if r["status"] == "PASS")
            tool_total = len(tool_results)

            print(f"{tool_name}: {tool_passed}/{tool_total} passed")

        print()
        print("=" * 80)

        # Save results to file
        self.save_results()

    def save_results(self):
        """Save test results to JSON file."""
        output_file = Path(__file__).parent / "test_stream2_results.json"

        with open(output_file, 'w') as f:
            json.dump({
                "summary": self.summary,
                "results": self.results
            }, f, indent=2)

        print(f"📄 Results saved to: {output_file}")


async def main():
    """Main test runner."""
    runner = TestRunner()
    await runner.run_all_tests()


if __name__ == "__main__":
    asyncio.run(main())
