#!/usr/bin/env python3
"""
Quick fix script to manually apply validation to remaining 9 tools.
"""
import re
from pathlib import Path

TOOLS_DIR = Path("tools")

# Tools that still need validation
REMAINING_TOOLS = [
    "drug_interactions",
    "drug_lookalikes",
    "graph_neighbors",
    "graph_path",
    "graph_subgraph",
    "provenance_discovery",
    "rescue_combinations",
    "semantic_search",
    "transcriptomic_rescue"
]

def add_validation_imports(content: str) -> str:
    """Add validation imports to harmonization import."""
    # Find harmonization import
    pattern = r'(from tool_utils import [^\n]+)\n(\s+HARMONIZATION_AVAILABLE = True)'

    def replacer(match):
        imports = match.group(1)
        # Add validation imports if not present
        if "validate_tool_input" not in imports:
            imports = imports.replace(
                "from tool_utils import",
                "from tool_utils import validate_tool_input, format_validation_response,"
            )
        return f"{imports}\n    HARMONIZATION_AVAILABLE = True\n    VALIDATION_AVAILABLE = True"

    content = re.sub(pattern, replacer, content)

    # Also handle the except clause
    content = content.replace(
        "except ImportError:\n    HARMONIZATION_AVAILABLE = False",
        "except ImportError:\n    HARMONIZATION_AVAILABLE = False\n    VALIDATION_AVAILABLE = False"
    )

    return content

def add_validation_code(content: str, tool_name: str) -> str:
    """Add validation code to execute function."""
    # Find execute function and its docstring
    pattern = r'(async def execute\([^)]+\) -> [Dd]ict\[str, Any\]:)\s*("""[\s\S]*?""")\s*\n(\s+)(try:|[^#\s])'

    def replacer(match):
        signature = match.group(1)
        docstring = match.group(2)
        indent = match.group(3)
        next_line = match.group(4)

        # Extract parameter name from signature
        param_match = re.search(r'execute\((\w+):', signature)
        param_name = param_match.group(1) if param_match else "tool_input"

        validation_code = f'''    # Stream 1.2: Input validation
    if VALIDATION_AVAILABLE:
        validation_errors = validate_tool_input({param_name}, TOOL_DEFINITION["input_schema"], "{tool_name}")
        if validation_errors:
            return format_validation_response("{tool_name}", validation_errors)

'''

        return f"{signature}\n{docstring}\n{validation_code}{indent}{next_line}"

    content = re.sub(pattern, replacer, content, count=1)
    return content

# Process each tool
for tool_name in REMAINING_TOOLS:
    tool_path = TOOLS_DIR / f"{tool_name}.py"

    if not tool_path.exists():
        print(f"❌ {tool_name}: File not found")
        continue

    # Read file
    with open(tool_path, 'r') as f:
        content = f.read()

    # Check if already has validation
    if "validate_tool_input" in content and "VALIDATION_AVAILABLE" in content:
        print(f"⏭️  {tool_name}: Already has validation")
        continue

    # Apply changes
    original_content = content
    content = add_validation_imports(content)
    content = add_validation_code(content, tool_name)

    if content == original_content:
        print(f"⚠️  {tool_name}: No changes made")
        continue

    # Write back
    with open(tool_path, 'w') as f:
        f.write(content)

    # Verify syntax
    try:
        compile(content, str(tool_path), 'exec')
        print(f"✅ {tool_name}: Validation added successfully")
    except SyntaxError as e:
        print(f"❌ {tool_name}: Syntax error - {e}")
        # Restore original
        with open(tool_path, 'w') as f:
            f.write(original_content)

print("\nDone!")
