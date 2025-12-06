"""
Integration tests for PT agent backend:
- /patient-summary/{patientId}
- /today-session/{patientId}
- /pt-assistant/summary/{patientId}
- /pt-assistant/plan-change-proposal/{patientId}
"""

import os
import requests

BASE_URL = os.getenv("PT_BACKEND_BASE_URL", "http://localhost:4000")

DEMO_PATIENT_ID = os.getenv("DEMO_PATIENT_ID", "00000000-0000-0000-0000-000000000001")


def test_health():
    r = requests.get(f"{BASE_URL}/health")
    assert r.status_code == 200
    assert r.json().get("status") == "ok"


def test_today_session():
    r = requests.get(f"{BASE_URL}/today-session/{DEMO_PATIENT_ID}")
    assert r.status_code == 200
    data = r.json()
    # minimal shape checks
    assert "session" in data
    assert "exercises" in data
    assert isinstance(data["exercises"], list)


def test_patient_summary():
    r = requests.get(f"{BASE_URL}/patient-summary/{DEMO_PATIENT_ID}")
    assert r.status_code == 200
    data = r.json()
    assert "patient" in data
    assert "recentSessions" in data
    assert "painTrend" in data


def test_pt_assistant_summary():
    r = requests.get(f"{BASE_URL}/pt-assistant/summary/{DEMO_PATIENT_ID}")
    assert r.status_code == 200
    data = r.json()
    # Expect top-level keys like: statusSummary, riskFlags
    assert "statusSummary" in data
    assert "riskFlags" in data


def test_plan_change_proposal():
    payload = {
        "reason": "High pain and velocity drop in last 2 sessions",
        "trigger": {
            "pain": [6, 7],
            "velocity_drop_mph": 4
        }
    }
    r = requests.post(
        f"{BASE_URL}/pt-assistant/plan-change-proposal/{DEMO_PATIENT_ID}",
        json=payload,
    )
    assert r.status_code == 200
    data = r.json()
    # Expect this endpoint to create a Linear issue
    assert "issue" in data
    assert "id" in data["issue"]
    assert "identifier" in data["issue"]
