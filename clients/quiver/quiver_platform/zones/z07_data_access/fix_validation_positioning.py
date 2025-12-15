#!/usr/bin/env python3
"""
Fix Validation Code Positioning - Move validation to after docstring

The validation code was inserted before the docstring instead of after.
This script fixes the positioning for all 27 tools.
"""

import re
from pathlib import Path

TOOLS_DIR = Path(__file__).parent / "tools"

def fix_validation_positioning(content: str, tool_name: str) -> tuple[str, bool]:
    """
    Fix validation code positioning in tool file.

    Current (wrong):
        async def execute(...):
            # validation code
            \"\"\"docstring\"\"\"
            try:

    Target (correct):
        async def execute(...):
            \"\"\"docstring\"\"\"
            # validation code

            try:
    """
    # Pattern to match misplaced validation code
    # Group 1: function signature
    # Group 2: validation code block
    # Group 3: docstring
    # Group 4: rest of function
    pattern = r'(async def execute\([^)]+\) -> [Dd]ict\[str, Any\]:)\s*\n(    # Stream 1\.2: Input validation\s+if VALIDATION_AVAILABLE:[\s\S]*?return format_validation_response\([^)]+\))\s*\n(\s*"""[\s\S]*?""")\s*\n(\s+try:)'

    match = re.search(pattern, content)

    if not match:
        # Try alternative pattern with single quotes
        pattern = r"(async def execute\([^)]+\) -> [Dd]ict\[str, Any\]:)\s*\n(    # Stream 1\.2: Input validation\s+if VALIDATION_AVAILABLE:[\s\S]*?return format_validation_response\([^)]+\))\s*\n(\s*'''[\s\S]*?''')\s*\n(\s+try:)"
        match = re.search(pattern, content)

    if not match:
        return content, False

    # Reconstruct with correct order
    func_sig = match.group(1)
    validation_code = match.group(2)
    docstring = match.group(3)
    try_block = match.group(4)

    # New structure: signature -> docstring -> validation -> try
    new_structure = f"{func_sig}\n{docstring}\n{validation_code}\n\n{try_block}"

    # Replace in content
    content = content[:match.start()] + new_structure + content[match.end():]

    return content, True


# Get all tool files
tools = sorted(TOOLS_DIR.glob("*.py"))
tools = [t for t in tools if t.name != "__init__.py" and not t.name.startswith("test_")]

print("=" * 60)
print("Fixing Validation Code Positioning")
print("=" * 60)
print()

fixed = 0
skipped = 0
failed = 0

for tool_path in tools:
    tool_name = tool_path.stem
    print(f"Processing {tool_name}...", end=" ")

    try:
        # Read file
        with open(tool_path, 'r') as f:
            content = f.read()

        # Fix positioning
        new_content, changed = fix_validation_positioning(content, tool_name)

        if not changed:
            print("⏭️  (no validation code or already correct)")
            skipped += 1
            continue

        # Verify syntax
        try:
            compile(new_content, str(tool_path), 'exec')
        except SyntaxError as e:
            print(f"❌ Syntax error: {e}")
            failed += 1
            continue

        # Write back
        with open(tool_path, 'w') as f:
            f.write(new_content)

        print("✅ Fixed")
        fixed += 1

    except Exception as e:
        print(f"❌ Error: {e}")
        failed += 1

print()
print("=" * 60)
print(f"Fixed: {fixed}")
print(f"Skipped: {skipped}")
print(f"Failed: {failed}")
print("=" * 60)
