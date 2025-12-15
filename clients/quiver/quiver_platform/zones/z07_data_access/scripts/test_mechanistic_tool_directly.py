#!/usr/bin/env python3
"""Test the mechanistic_explainer TOOL directly (not just the query)."""

import sys
import os
from pathlib import Path

# Add path for tool imports
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from tools.mechanistic_explainer import execute
import asyncio
import json

async def test_rapamycin():
    print("=" * 80)
    print("TESTING mechanistic_explainer TOOL DIRECTLY")
    print("=" * 80)
    print()

    tool_input = {
        "drug": "Rapamycin",
        "disease": "tuberous sclerosis",
        "min_confidence": 0.0,  # Set to 0 to see ALL mechanisms regardless of confidence
        "max_depth": 4,
        "explanation_style": "detailed"
    }

    print(f"Input: {json.dumps(tool_input, indent=2)}")
    print()

    result = await execute(tool_input)

    print("Result:")
    print(json.dumps(result, indent=2))
    print()

    if result.get("success"):
        print(f"✅ SUCCESS! Found {result.get('mechanism_count', 0)} mechanisms")

        for i, mech in enumerate(result.get("mechanisms", []), 1):
            print(f"\nMechanism {i}:")
            print(f"  Type: {mech.get('mechanism_type')}")
            print(f"  Confidence: {mech.get('confidence')}")
            print(f"  Narrative: {mech.get('narrative', 'N/A')[:200]}")
    else:
        print(f"❌ FAILED: {result.get('error')}")

asyncio.run(test_rapamycin())
