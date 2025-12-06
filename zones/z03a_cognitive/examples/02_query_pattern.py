"""
Query Pattern Example - PatientSummaryQueryAgent

Demonstrates the Query pattern where an IntelligentAgent retrieves and processes
data without side effects. This agent generates patient performance summaries
by querying exercise logs and computing analytics.

Pattern Characteristics:
- Read-only operations (no side effects)
- Data aggregation and analysis
- Context-aware processing
- Structured output generation

Usage:
    agent = PatientSummaryQueryAgent(name="patient_summary")
    result = agent.execute({
        "patient_id": "demo-patient-123",
        "include_flags": True,
        "days_back": 7
    })

Wave 1: Demonstrates execute() interface with data retrieval
Wave 3-4: Will add semantic search and LLM-powered summaries
"""

from typing import Dict, Any, List
from datetime import datetime, timedelta
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))

from z03a_cognitive.base import IntelligentAgent


class PatientSummaryQueryAgent(IntelligentAgent):
    """
    Query pattern agent that retrieves and analyzes patient performance data.

    This agent demonstrates:
    - Read-only data retrieval
    - Analytics computation
    - Context management
    - Structured summary generation
    """

    def __init__(self, name: str = "patient_summary_query", enable_context_history: bool = False):
        super().__init__(name, enable_context_history)

    def execute(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute patient summary query.

        Args:
            context: {
                "patient_id": str,
                "include_flags": bool (default: True),
                "days_back": int (default: 7),
                "include_analytics": bool (default: True)
            }

        Returns:
            {
                "status": "success" | "error",
                "summary": {
                    "patient_id": str,
                    "period": {...},
                    "performance": {...},
                    "flags": [...],
                    "analytics": {...}
                },
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
            include_flags = context.get("include_flags", True)
            days_back = context.get("days_back", 7)
            include_analytics = context.get("include_analytics", True)

            self.logger.info(f"Generating summary for patient {patient_id} (last {days_back} days)")

            # Retrieve data (simulated for Wave 1)
            exercise_data = self._retrieve_exercise_data(patient_id, days_back)

            # Build summary
            summary = self._build_summary(
                patient_id,
                exercise_data,
                days_back,
                include_flags,
                include_analytics
            )

            return {
                "status": "success",
                "summary": summary,
                "metadata": {
                    "agent": self.name,
                    "query_timestamp": datetime.utcnow().isoformat(),
                    "data_points": len(exercise_data)
                }
            }

        except Exception as e:
            return self._handle_error(e, context)

    def _validate_context(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Validate input context has required fields."""
        if "patient_id" not in context:
            return {"valid": False, "error": "Missing required field: patient_id"}

        days_back = context.get("days_back", 7)
        if not isinstance(days_back, int) or days_back < 1:
            return {"valid": False, "error": "days_back must be a positive integer"}

        return {"valid": True}

    def _retrieve_exercise_data(self, patient_id: str, days_back: int) -> List[dict]:
        """
        Retrieve exercise data for the specified period.

        Wave 1: Simulated data for demonstration
        Wave 3-4: Will use actual database queries with semantic search
        """
        # Simulate exercise data retrieval
        simulated_data = [
            {
                "date": (datetime.utcnow() - timedelta(days=i)).isoformat(),
                "exercise": "Squat",
                "sets": 3,
                "reps": 10,
                "load": 135 + (i * 5),
                "pain": min(i, 5),
                "rpe": 6 + (i % 3),
                "adherence": 0.9 - (i * 0.05)
            }
            for i in range(min(days_back, 5))
        ]

        self.logger.info(f"Retrieved {len(simulated_data)} exercise records")
        return simulated_data

    def _build_summary(
        self,
        patient_id: str,
        exercise_data: List[dict],
        days_back: int,
        include_flags: bool,
        include_analytics: bool
    ) -> Dict[str, Any]:
        """Build comprehensive patient summary."""
        summary = {
            "patient_id": patient_id,
            "period": {
                "days": days_back,
                "start_date": (datetime.utcnow() - timedelta(days=days_back)).isoformat(),
                "end_date": datetime.utcnow().isoformat()
            },
            "performance": self._compute_performance(exercise_data)
        }

        if include_flags:
            summary["flags"] = self._detect_summary_flags(exercise_data)

        if include_analytics:
            summary["analytics"] = self._compute_analytics(exercise_data)

        return summary

    def _compute_performance(self, exercise_data: List[dict]) -> Dict[str, Any]:
        """Compute performance metrics."""
        if not exercise_data:
            return {
                "total_sessions": 0,
                "avg_adherence": 0.0,
                "avg_pain": 0.0,
                "avg_rpe": 0.0
            }

        return {
            "total_sessions": len(exercise_data),
            "avg_adherence": round(
                sum(d.get("adherence", 0) for d in exercise_data) / len(exercise_data),
                2
            ),
            "avg_pain": round(
                sum(d.get("pain", 0) for d in exercise_data) / len(exercise_data),
                1
            ),
            "avg_rpe": round(
                sum(d.get("rpe", 0) for d in exercise_data) / len(exercise_data),
                1
            ),
            "total_volume_lbs": sum(
                d.get("sets", 0) * d.get("reps", 0) * d.get("load", 0)
                for d in exercise_data
            )
        }

    def _detect_summary_flags(self, exercise_data: List[dict]) -> List[dict]:
        """Detect flags based on summary data."""
        flags = []

        # Check for high pain trend
        recent_pain = [d.get("pain", 0) for d in exercise_data[:3]]
        if recent_pain and sum(recent_pain) / len(recent_pain) > 5:
            flags.append({
                "type": "high_pain_trend",
                "severity": "HIGH",
                "description": "Average pain score trending above safe threshold",
                "avg_pain": round(sum(recent_pain) / len(recent_pain), 1)
            })

        # Check for declining adherence
        if len(exercise_data) >= 3:
            recent_adherence = [d.get("adherence", 1.0) for d in exercise_data[:3]]
            if all(a < 0.7 for a in recent_adherence):
                flags.append({
                    "type": "declining_adherence",
                    "severity": "MEDIUM",
                    "description": "Consistent low adherence over recent sessions",
                    "avg_adherence": round(sum(recent_adherence) / len(recent_adherence), 2)
                })

        return flags

    def _compute_analytics(self, exercise_data: List[dict]) -> Dict[str, Any]:
        """Compute advanced analytics."""
        if not exercise_data:
            return {}

        # Load progression analysis
        loads = [d.get("load", 0) for d in exercise_data if d.get("load")]
        load_progression = None
        if len(loads) >= 2:
            load_progression = {
                "initial": loads[-1],
                "current": loads[0],
                "change_lbs": loads[0] - loads[-1],
                "change_percent": round(((loads[0] - loads[-1]) / loads[-1] * 100), 1) if loads[-1] > 0 else 0
            }

        # Pain trend analysis
        pain_scores = [d.get("pain", 0) for d in exercise_data]
        pain_trend = "stable"
        if len(pain_scores) >= 3:
            recent_avg = sum(pain_scores[:3]) / 3
            older_avg = sum(pain_scores[3:]) / max(len(pain_scores[3:]), 1) if len(pain_scores) > 3 else recent_avg
            if recent_avg > older_avg + 1:
                pain_trend = "increasing"
            elif recent_avg < older_avg - 1:
                pain_trend = "decreasing"

        return {
            "load_progression": load_progression,
            "pain_trend": pain_trend,
            "consistency_score": round(
                sum(1 for d in exercise_data if d.get("adherence", 0) >= 0.8) / len(exercise_data),
                2
            )
        }


# Example usage demonstration
if __name__ == "__main__":
    # Create agent
    agent = PatientSummaryQueryAgent(enable_context_history=True)

    # Execute basic query
    print("\n=== Basic Patient Summary ===")
    result = agent.execute({
        "patient_id": "demo-patient-123",
        "days_back": 7
    })

    if result["status"] == "success":
        summary = result["summary"]
        print(f"Patient ID: {summary['patient_id']}")
        print(f"Period: {summary['period']['days']} days")
        print(f"\nPerformance:")
        for key, value in summary['performance'].items():
            print(f"  {key}: {value}")

        if summary.get('flags'):
            print(f"\nFlags Detected: {len(summary['flags'])}")
            for flag in summary['flags']:
                print(f"  - {flag['type']} ({flag['severity']}): {flag['description']}")

        if summary.get('analytics'):
            print(f"\nAnalytics:")
            for key, value in summary['analytics'].items():
                print(f"  {key}: {value}")

    # Execute minimal query (no flags or analytics)
    print("\n\n=== Minimal Query (Performance Only) ===")
    result = agent.execute({
        "patient_id": "demo-patient-456",
        "days_back": 3,
        "include_flags": False,
        "include_analytics": False
    })

    if result["status"] == "success":
        summary = result["summary"]
        print(f"Patient ID: {summary['patient_id']}")
        print(f"Performance: {summary['performance']}")
        print(f"Metadata: {result['metadata']}")

    # Check context history
    print("\n\n=== Context History ===")
    history = agent.get_context_history()
    if history:
        print(f"Tracked {len(history)} executions")
        for i, entry in enumerate(history, 1):
            print(f"{i}. {entry['timestamp']}: patient_id={entry['context']['patient_id']}")
