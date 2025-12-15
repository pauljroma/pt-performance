#!/usr/bin/env python3
"""Quick test of mechanistic explainer after Gene→Protein fix."""

import sys
import asyncio
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from tools import mechanistic_explainer

async def test():
    """Test Aspirin → CVD mechanistic discovery."""
    print("Testing: Aspirin → Cardiovascular Disease\n")

    result = await mechanistic_explainer.execute({
        "drug": "Aspirin",
        "disease": "Cardiovascular Disease",
        "explanation_style": "summary"
    })

    print(f"Success: {result.get('success')}")
    print(f"Mechanisms found: {result.get('mechanism_count', 0)}")
    print(f"Summary: {result.get('summary', 'N/A')}")

    if result.get('mechanisms'):
        print("\nFirst mechanism:")
        mech = result['mechanisms'][0]
        print(f"  Type: {mech.get('type')}")
        print(f"  Narrative: {mech.get('narrative')}")
        print(f"  Confidence: {mech.get('confidence')}")

asyncio.run(test())
