"""
Tool Pattern Example - ExerciseFlagToolAgent

Demonstrates the Tool pattern where an IntelligentAgent performs specific actions
based on input context. This agent analyzes exercise logs and creates flags for
concerning patterns (high pain, low adherence, etc.).

Pattern Characteristics:
- Action-oriented (creates, updates, deletes)
- Side effects (database writes, API calls)
- Validation and safety checks
- Clear success/failure outcomes

Usage:
    agent = ExerciseFlagToolAgent(name="flag_creator")
    result = agent.execute({
        "patient_id": "demo-patient-123",
        "exercise_logs": [...],
        "create_flags": True
    })

Wave 1: Demonstrates execute() interface with structured output
Wave 3-4: Will add LLM reasoning and automated tool selection
"""

from typing import Dict, Any, List
from datetime import datetime
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))

from z03a_cognitive.base import IntelligentAgent


class ExerciseFlagToolAgent(IntelligentAgent):
    """
    Tool pattern agent that analyzes exercise logs and creates performance flags.

    This agent demonstrates:
    - Input validation
    - Business logic processing
    - Structured output generation
    - Error handling with partial results
    """

    def __init__(self, name: str = "exercise_flag_tool", enable_context_history: bool = False):
        super().__init__(name, enable_context_history)
        self.flag_rules = self._initialize_flag_rules()

    def _initialize_flag_rules(self) -> Dict[str, Any]:
        """Define flag detection rules."""
        return {
            "high_pain": {
                "threshold": 5,
                "severity": "HIGH",
                "description": "Pain score exceeds safe threshold"
            },
            "low_adherence": {
                "threshold": 0.7,  # 70% completion required
                "severity": "MEDIUM",
                "description": "Exercise adherence below target"
            },
            "rpe_spike": {
                "threshold": 2,  # RPE increase of 2+ points
                "severity": "MEDIUM",
                "description": "Perceived exertion spike detected"
            }
        }

    def execute(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute flag analysis and creation.

        Args:
            context: {
                "patient_id": str,
                "exercise_logs": List[dict],
                "create_flags": bool (default: False, dry-run mode)
            }

        Returns:
            {
                "status": "success" | "error" | "partial",
                "flags_detected": List[dict],
                "flags_created": int,
                "metadata": {...}
            }
        """
        try:
            # Track context if enabled
            self._track_context(context)

            # Validate input
            validation_result = self._validate_context(context)
            if not validation_result["valid"]:
                return {
                    "status": "error",
                    "error": validation_result["error"],
                    "agent": self.name
                }

            patient_id = context["patient_id"]
            exercise_logs = context["exercise_logs"]
            create_flags = context.get("create_flags", False)

            self.logger.info(f"Analyzing {len(exercise_logs)} exercise logs for patient {patient_id}")

            # Detect flags
            flags_detected = self._detect_flags(exercise_logs, patient_id)

            # Create flags if requested
            flags_created = 0
            if create_flags and flags_detected:
                flags_created = self._create_flags(flags_detected)

            return {
                "status": "success",
                "flags_detected": flags_detected,
                "flags_created": flags_created,
                "metadata": {
                    "agent": self.name,
                    "patient_id": patient_id,
                    "logs_analyzed": len(exercise_logs),
                    "timestamp": datetime.utcnow().isoformat(),
                    "dry_run": not create_flags
                }
            }

        except Exception as e:
            return self._handle_error(e, context)

    def _validate_context(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Validate input context has required fields."""
        if "patient_id" not in context:
            return {"valid": False, "error": "Missing required field: patient_id"}

        if "exercise_logs" not in context:
            return {"valid": False, "error": "Missing required field: exercise_logs"}

        if not isinstance(context["exercise_logs"], list):
            return {"valid": False, "error": "exercise_logs must be a list"}

        return {"valid": True}

    def _detect_flags(self, exercise_logs: List[dict], patient_id: str) -> List[dict]:
        """Analyze exercise logs and detect concerning patterns."""
        flags = []

        for log in exercise_logs:
            # High pain detection
            if log.get("pain", 0) > self.flag_rules["high_pain"]["threshold"]:
                flags.append({
                    "type": "high_pain",
                    "severity": self.flag_rules["high_pain"]["severity"],
                    "description": self.flag_rules["high_pain"]["description"],
                    "patient_id": patient_id,
                    "exercise_log_id": log.get("id"),
                    "pain_score": log.get("pain"),
                    "detected_at": datetime.utcnow().isoformat()
                })

            # Low adherence detection (completed sets vs prescribed)
            prescribed_sets = log.get("prescribed_sets", 0)
            actual_sets = log.get("actual_sets", 0)
            if prescribed_sets > 0:
                adherence = actual_sets / prescribed_sets
                if adherence < self.flag_rules["low_adherence"]["threshold"]:
                    flags.append({
                        "type": "low_adherence",
                        "severity": self.flag_rules["low_adherence"]["severity"],
                        "description": self.flag_rules["low_adherence"]["description"],
                        "patient_id": patient_id,
                        "exercise_log_id": log.get("id"),
                        "adherence_rate": round(adherence, 2),
                        "detected_at": datetime.utcnow().isoformat()
                    })

        self.logger.info(f"Detected {len(flags)} flags for patient {patient_id}")
        return flags

    def _create_flags(self, flags: List[dict]) -> int:
        """
        Create flags in database (simulated for Wave 1).

        Wave 3-4: Will use actual database connection.
        """
        self.logger.info(f"Creating {len(flags)} flags (simulated)")
        # Simulate flag creation
        return len(flags)


# Example usage demonstration
if __name__ == "__main__":
    # Example exercise logs with concerning patterns
    sample_logs = [
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
        },
        {
            "id": "log-3",
            "exercise": "Press",
            "prescribed_sets": 3,
            "actual_sets": 2,
            "pain": 2,
            "rpe": 5
        }
    ]

    # Create agent
    agent = ExerciseFlagToolAgent(enable_context_history=True)

    # Execute in dry-run mode
    print("\n=== Dry Run Mode ===")
    result = agent.execute({
        "patient_id": "demo-patient-123",
        "exercise_logs": sample_logs,
        "create_flags": False
    })

    print(f"Status: {result['status']}")
    print(f"Flags detected: {len(result['flags_detected'])}")
    for flag in result['flags_detected']:
        print(f"  - {flag['type']}: {flag['description']} (severity: {flag['severity']})")

    # Execute with flag creation
    print("\n=== Create Flags Mode ===")
    result = agent.execute({
        "patient_id": "demo-patient-123",
        "exercise_logs": sample_logs,
        "create_flags": True
    })

    print(f"Status: {result['status']}")
    print(f"Flags created: {result['flags_created']}")
    print(f"Metadata: {result['metadata']}")
