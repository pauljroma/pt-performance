"""
Tests for IntelligentAgent Base Class - Wave 1 Foundation

Comprehensive test suite covering:
1. Base class instantiation
2. execute() interface
3. Context management
4. Error handling
5. Tool pattern example
6. Query pattern example
7. Context history tracking
8. Optional adoption (no breaking changes)
"""

import unittest
import sys
import os
from datetime import datetime

# Add zones directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from zones.z03a_cognitive.base import IntelligentAgent
from zones.z03a_cognitive.examples.tool_pattern_impl import ExerciseFlagToolAgent
from zones.z03a_cognitive.examples.query_pattern_impl import PatientSummaryQueryAgent


class ConcreteTestAgent(IntelligentAgent):
    """Concrete implementation for testing abstract base class."""

    def execute(self, context: dict) -> dict:
        """Simple test implementation."""
        # Track context if enabled
        self._track_context(context)

        return {
            "status": "success",
            "result": f"Processed: {context.get('test_data', 'none')}",
            "agent": self.name
        }


class TestIntelligentAgentBaseClass(unittest.TestCase):
    """Test 1-4: Base class instantiation, execute() interface, context management, error handling."""

    def test_01_base_class_instantiation(self):
        """Test 1: Base class can be instantiated via concrete implementation."""
        agent = ConcreteTestAgent(name="test_agent")

        self.assertEqual(agent.name, "test_agent")
        self.assertIsNotNone(agent.logger)
        self.assertFalse(agent.enable_context_history)
        self.assertIsNone(agent.context_history)

    def test_02_execute_interface(self):
        """Test 2: Execute interface works correctly."""
        agent = ConcreteTestAgent(name="test_agent")

        result = agent.execute({"test_data": "hello"})

        self.assertEqual(result["status"], "success")
        self.assertEqual(result["result"], "Processed: hello")
        self.assertEqual(result["agent"], "test_agent")

    def test_03_context_management(self):
        """Test 3: Context history tracking works when enabled."""
        agent = ConcreteTestAgent(name="test_agent", enable_context_history=True)

        # Execute multiple times
        agent.execute({"test_data": "first"})
        agent.execute({"test_data": "second"})
        agent.execute({"test_data": "third"})

        history = agent.get_context_history()

        self.assertIsNotNone(history)
        self.assertEqual(len(history), 3)
        self.assertEqual(history[0]["context"]["test_data"], "first")
        self.assertEqual(history[1]["context"]["test_data"], "second")
        self.assertEqual(history[2]["context"]["test_data"], "third")

        # Test clear history
        agent.clear_context_history()
        self.assertEqual(len(agent.get_context_history()), 0)

    def test_04_error_handling(self):
        """Test 4: Standard error handling works correctly."""
        agent = ConcreteTestAgent(name="test_agent")

        # Simulate error handling
        test_error = ValueError("Test error message")
        error_result = agent._handle_error(test_error, {"test": "context"})

        self.assertEqual(error_result["status"], "error")
        self.assertEqual(error_result["error"], "Test error message")
        self.assertEqual(error_result["error_type"], "ValueError")
        self.assertEqual(error_result["agent"], "test_agent")
        self.assertIsNotNone(error_result["timestamp"])
        self.assertEqual(error_result["context"]["test"], "context")


class TestToolPatternExample(unittest.TestCase):
    """Test 5: Tool pattern example (ExerciseFlagToolAgent)."""

    def test_05_tool_pattern_implementation(self):
        """Test 5: Tool pattern agent executes correctly."""
        agent = ExerciseFlagToolAgent(name="flag_test")

        # Sample exercise logs with flags
        exercise_logs = [
            {
                "id": "log-1",
                "exercise": "Squat",
                "prescribed_sets": 3,
                "actual_sets": 3,
                "pain": 3,
                "rpe": 6
            },
            {
                "id": "log-2",
                "exercise": "Deadlift",
                "prescribed_sets": 3,
                "actual_sets": 1,  # Low adherence
                "pain": 7,  # High pain
                "rpe": 8
            }
        ]

        # Execute in dry-run mode
        result = agent.execute({
            "patient_id": "test-patient-001",
            "exercise_logs": exercise_logs,
            "create_flags": False
        })

        self.assertEqual(result["status"], "success")
        self.assertGreater(len(result["flags_detected"]), 0)
        self.assertEqual(result["flags_created"], 0)  # Dry-run mode
        self.assertEqual(result["metadata"]["dry_run"], True)

        # Check that high pain flag was detected
        high_pain_flags = [f for f in result["flags_detected"] if f["type"] == "high_pain"]
        self.assertEqual(len(high_pain_flags), 1)
        self.assertEqual(high_pain_flags[0]["pain_score"], 7)

        # Check that low adherence flag was detected
        low_adherence_flags = [f for f in result["flags_detected"] if f["type"] == "low_adherence"]
        self.assertEqual(len(low_adherence_flags), 1)

    def test_05b_tool_pattern_validation(self):
        """Test 5b: Tool pattern validates input correctly."""
        agent = ExerciseFlagToolAgent(name="flag_test")

        # Missing patient_id
        result = agent.execute({
            "exercise_logs": []
        })

        self.assertEqual(result["status"], "error")
        self.assertIn("patient_id", result["error"])

        # Missing exercise_logs
        result = agent.execute({
            "patient_id": "test-patient"
        })

        self.assertEqual(result["status"], "error")
        self.assertIn("exercise_logs", result["error"])


class TestQueryPatternExample(unittest.TestCase):
    """Test 6: Query pattern example (PatientSummaryQueryAgent)."""

    def test_06_query_pattern_implementation(self):
        """Test 6: Query pattern agent executes correctly."""
        agent = PatientSummaryQueryAgent(name="summary_test")

        # Execute query
        result = agent.execute({
            "patient_id": "test-patient-002",
            "days_back": 7,
            "include_flags": True,
            "include_analytics": True
        })

        self.assertEqual(result["status"], "success")
        self.assertIn("summary", result)

        summary = result["summary"]
        self.assertEqual(summary["patient_id"], "test-patient-002")
        self.assertIn("period", summary)
        self.assertIn("performance", summary)
        self.assertIn("flags", summary)
        self.assertIn("analytics", summary)

        # Check performance metrics
        performance = summary["performance"]
        self.assertIn("total_sessions", performance)
        self.assertIn("avg_adherence", performance)
        self.assertIn("avg_pain", performance)
        self.assertIn("avg_rpe", performance)

    def test_06b_query_pattern_minimal(self):
        """Test 6b: Query pattern works with minimal configuration."""
        agent = PatientSummaryQueryAgent(name="summary_test")

        # Execute minimal query (no flags or analytics)
        result = agent.execute({
            "patient_id": "test-patient-003",
            "days_back": 3,
            "include_flags": False,
            "include_analytics": False
        })

        self.assertEqual(result["status"], "success")
        summary = result["summary"]

        self.assertIn("performance", summary)
        self.assertNotIn("flags", summary)
        self.assertNotIn("analytics", summary)

    def test_06c_query_pattern_validation(self):
        """Test 6c: Query pattern validates input correctly."""
        agent = PatientSummaryQueryAgent(name="summary_test")

        # Missing patient_id
        result = agent.execute({
            "days_back": 7
        })

        self.assertEqual(result["status"], "error")
        self.assertIn("patient_id", result["error"])

        # Invalid days_back
        result = agent.execute({
            "patient_id": "test-patient",
            "days_back": -5
        })

        self.assertEqual(result["status"], "error")
        self.assertIn("days_back", result["error"])


class TestContextHistoryFeature(unittest.TestCase):
    """Test 7: Context history tracking across multiple executions."""

    def test_07_context_history_tracking(self):
        """Test 7: Context history tracks multiple executions correctly."""
        agent = PatientSummaryQueryAgent(
            name="history_test",
            enable_context_history=True
        )

        # Execute multiple queries
        contexts = [
            {"patient_id": "patient-1", "days_back": 7},
            {"patient_id": "patient-2", "days_back": 14},
            {"patient_id": "patient-3", "days_back": 30}
        ]

        for ctx in contexts:
            agent.execute(ctx)

        history = agent.get_context_history()

        self.assertIsNotNone(history)
        self.assertEqual(len(history), 3)

        # Verify each context was tracked
        for i, ctx in enumerate(contexts):
            self.assertEqual(history[i]["context"]["patient_id"], ctx["patient_id"])
            self.assertEqual(history[i]["context"]["days_back"], ctx["days_back"])
            self.assertIn("timestamp", history[i])

    def test_07b_context_history_limit(self):
        """Test 7b: Context history limits to 100 entries."""
        agent = ConcreteTestAgent(name="limit_test", enable_context_history=True)

        # Execute 150 times
        for i in range(150):
            agent.execute({"iteration": i})

        history = agent.get_context_history()

        # Should be limited to 100
        self.assertEqual(len(history), 100)

        # Should keep the most recent 100
        self.assertEqual(history[-1]["context"]["iteration"], 149)
        self.assertEqual(history[0]["context"]["iteration"], 50)


class TestOptionalAdoption(unittest.TestCase):
    """Test 8: Verify optional adoption (no breaking changes to existing code)."""

    def test_08_optional_adoption_no_breaking_changes(self):
        """Test 8: Existing code works without adopting IntelligentAgent."""

        # Simulate existing agent that doesn't use IntelligentAgent
        class LegacyAgent:
            def __init__(self, name):
                self.name = name

            def process(self, data):
                return {"result": f"Processed {data}"}

        # Legacy agent should work independently
        legacy = LegacyAgent("legacy")
        result = legacy.process("test data")

        self.assertEqual(result["result"], "Processed test data")

        # New IntelligentAgent works alongside legacy
        modern = ConcreteTestAgent("modern")
        modern_result = modern.execute({"test_data": "test data"})

        self.assertEqual(modern_result["status"], "success")

        # Both can coexist
        self.assertIsNotNone(legacy)
        self.assertIsNotNone(modern)

        # IntelligentAgent is optional - agents can choose to inherit
        self.assertIsInstance(modern, IntelligentAgent)
        self.assertNotIsInstance(legacy, IntelligentAgent)


class TestFutureToolIntegration(unittest.TestCase):
    """Test Wave 3-4 tool integration placeholders."""

    def test_tool_integration_placeholders(self):
        """Verify Wave 3-4 tool integration hooks exist but are not yet implemented."""
        agent = ConcreteTestAgent("tool_test")

        # These should raise NotImplementedError (placeholders for future)
        with self.assertRaises(NotImplementedError):
            agent._register_tool("test_tool", lambda: None)

        with self.assertRaises(NotImplementedError):
            agent._call_tool("test_tool")


# Test suite runner
def run_tests():
    """Run all tests and return results."""
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()

    # Add all test classes
    suite.addTests(loader.loadTestsFromTestCase(TestIntelligentAgentBaseClass))
    suite.addTests(loader.loadTestsFromTestCase(TestToolPatternExample))
    suite.addTests(loader.loadTestsFromTestCase(TestQueryPatternExample))
    suite.addTests(loader.loadTestsFromTestCase(TestContextHistoryFeature))
    suite.addTests(loader.loadTestsFromTestCase(TestOptionalAdoption))
    suite.addTests(loader.loadTestsFromTestCase(TestFutureToolIntegration))

    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)

    return result


if __name__ == "__main__":
    result = run_tests()

    # Exit with appropriate code
    sys.exit(0 if result.wasSuccessful() else 1)
