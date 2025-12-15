#!/usr/bin/env python3
"""Test mechanistic_explainer with rescue predictions DISABLED."""

import sys
import os
from pathlib import Path
import time

# Add path for tool imports
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from tools.mechanistic_explainer import execute
import asyncio
import json

async def test_rapamycin():
    print("=" * 80)
    print("TESTING mechanistic_explainer (NO RESCUE PREDICTIONS)")
    print("=" * 80)
    print()

    tool_input = {
        "drug": "Rapamycin",
        "disease": "tuberous sclerosis",
        "min_confidence": 0.0,
        "max_depth": 4,
        "include_rescue": False,  # DISABLE RESCUE
        "explanation_style": "detailed"
    }

    print(f"Input: {json.dumps(tool_input, indent=2)}")
    print()

    start = time.time()
    result = await execute(tool_input)
    elapsed = time.time() - start

    print(f"⏱️  Completed in {elapsed:.2f}s")
    print()
    print("Result:")
    print(json.dumps(result, indent=2, default=str))

asyncio.run(test_rapamycin())
