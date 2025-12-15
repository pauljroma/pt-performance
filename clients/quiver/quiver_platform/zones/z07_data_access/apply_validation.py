#!/usr/bin/env python3
"""
Automated Validation Framework Application Script - Stream 1.2

This script automatically applies input validation to all 27 Sapphire tools.
It adds schema-based validation at the start of each tool's execute() function.

Features:
- Automatic backup creation (.py.bak files)
- Dry-run mode for safety (preview changes without applying)
- Detailed progress tracking and reporting
- Validation of changes (ensures code is syntactically correct)
- Rollback support (restore from .py.bak files)

Usage:
    # Dry run (preview changes)
    python3 apply_validation.py --dry-run

    # Apply to specific tool
    python3 apply_validation.py --tool vector_antipodal

    # Apply to all tools
    python3 apply_validation.py

    # Force overwrite existing backups
    python3 apply_validation.py --force

Author: Sapphire v4.0 Integration - Stream 1.2
Date: 2025-11-29
Version: 1.0
"""

import os
import sys
import re
import json
import shutil
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Tuple, Optional
import argparse

# Add project root to path
project_root = Path(__file__).parents[6]
sys.path.insert(0, str(project_root))

# Tool directory
TOOLS_DIR = Path(__file__).parent / "tools"
REPORT_DIR = Path(__file__).parent / "tools"


def get_all_tools() -> List[Path]:
    """
    Get all tool files in the tools directory.

    Returns:
        List of Path objects for all .py files (excluding test files)
    """
    tools = []
    for tool_file in TOOLS_DIR.glob("*.py"):
        # Skip test files and __init__.py
        if tool_file.name.startswith("test_") or tool_file.name == "__init__.py":
            continue
        tools.append(tool_file)
    return sorted(tools)


def backup_tool(tool_path: Path, force: bool = False) -> Tuple[bool, str]:
    """
    Create backup of tool file before modification.

    Args:
        tool_path: Path to tool file
        force: If True, overwrite existing backup

    Returns:
        Tuple of (success, message)
    """
    backup_path = tool_path.with_suffix(".py.bak")

    if backup_path.exists() and not force:
        return (False, f"Backup already exists: {backup_path.name}. Use --force to overwrite.")

    try:
        shutil.copy2(tool_path, backup_path)
        return (True, f"Backup created: {backup_path.name}")
    except Exception as e:
        return (False, f"Failed to create backup: {str(e)}")


def has_validation(tool_content: str) -> bool:
    """
    Check if tool already has validation implemented.

    Args:
        tool_content: Tool file content as string

    Returns:
        True if validation is already present
    """
    # Look for validation import and usage
    validation_patterns = [
        r"from tool_utils import.*validate_tool_input",
        r"validate_tool_input\(",
        r"VALIDATION_AVAILABLE\s*=\s*True"
    ]

    for pattern in validation_patterns:
        if re.search(pattern, tool_content):
            return True

    return False


def add_validation_import(tool_content: str) -> str:
    """
    Add validation utilities import to tool file.

    Adds import after existing harmonization import or at the top of imports section.

    Args:
        tool_content: Tool file content as string

    Returns:
        Modified content with validation import added
    """
    # Check if validation import already exists
    if "validate_tool_input" in tool_content:
        return tool_content

    # Pattern to find existing harmonization import
    harmonization_import_pattern = r"(from tool_utils import [^\n]+)"

    match = re.search(harmonization_import_pattern, tool_content)

    if match:
        # Extend existing import
        existing_import = match.group(1)

        # Check if it already has validate_tool_input
        if "validate_tool_input" in existing_import:
            return tool_content

        # Add validation functions to existing import
        new_import = existing_import.replace(
            "from tool_utils import",
            "from tool_utils import validate_tool_input, format_validation_response,"
        )

        tool_content = tool_content.replace(existing_import, new_import)

    else:
        # No harmonization import, add new import after other imports
        # Find the import section (before TOOL_DEFINITION)
        tool_def_match = re.search(r"^# Claude Tool Definition", tool_content, re.MULTILINE)

        if tool_def_match:
            insert_pos = tool_def_match.start()

            validation_import = """
# Import validation utilities (Stream 1.2: Validation Framework)
try:
    from tool_utils import validate_tool_input, format_validation_response
    VALIDATION_AVAILABLE = True
except ImportError:
    VALIDATION_AVAILABLE = False

"""
            tool_content = (
                tool_content[:insert_pos] +
                validation_import +
                tool_content[insert_pos:]
            )

    return tool_content


def add_validation_to_execute(tool_content: str, tool_name: str) -> Tuple[str, bool]:
    """
    Add validation logic to execute() function.

    Adds validation check at the start of execute(), right after the docstring.

    Args:
        tool_content: Tool file content as string
        tool_name: Name of the tool (for error messages)

    Returns:
        Tuple of (modified_content, parameter_name, success)
    """
    # Find the execute function - flexible pattern to handle different parameter names
    # Matches: tool_input, params, input_params, etc.
    execute_pattern = r'(async def execute\((\w+):\s*[Dd]ict\[str,\s*Any\]\) -> [Dd]ict\[str,\s*Any\]:)\s*("""[\s\S]*?"""|\'\'\'[\s\S]*?\'\'\')?'

    match = re.search(execute_pattern, tool_content)

    if not match:
        return (tool_content, False)

    # Extract parameter name from function signature
    param_name = match.group(2)

    # Build validation code block using the actual parameter name
    # Use 4-space indentation for function body
    validation_code = f'''    # Stream 1.2: Input validation
    if VALIDATION_AVAILABLE:
        validation_errors = validate_tool_input({param_name}, TOOL_DEFINITION["input_schema"], "{tool_name}")
        if validation_errors:
            return format_validation_response("{tool_name}", validation_errors)
'''

    # Insert validation code after docstring (or after function signature if no docstring)
    if match.group(3):  # Has docstring (group 3 is the docstring)
        insert_pos = match.end()
    else:  # No docstring
        insert_pos = match.end(1)  # After function signature
        validation_code = "\n" + validation_code  # Add newline before code

    # Check if validation already exists near this position
    check_region = tool_content[insert_pos:insert_pos + 500]
    if "validate_tool_input" in check_region:
        return (tool_content, False)  # Already has validation

    tool_content = (
        tool_content[:insert_pos] +
        validation_code +
        tool_content[insert_pos:]
    )

    return (tool_content, True)


def apply_validation_to_tool(
    tool_path: Path,
    dry_run: bool = False,
    force: bool = False
) -> Dict[str, any]:
    """
    Apply validation framework to a single tool.

    Args:
        tool_path: Path to tool file
        dry_run: If True, don't actually modify files
        force: If True, overwrite existing backups

    Returns:
        Dict with result information:
        {
            "tool": tool_name,
            "success": bool,
            "changes_made": bool,
            "message": str,
            "backup_created": bool
        }
    """
    tool_name = tool_path.stem
    result = {
        "tool": tool_name,
        "success": False,
        "changes_made": False,
        "message": "",
        "backup_created": False
    }

    try:
        # Read tool file
        with open(tool_path, 'r') as f:
            original_content = f.read()

        # Check if already has validation
        if has_validation(original_content):
            result["message"] = "Already has validation"
            result["success"] = True
            return result

        # Step 1: Add validation import
        modified_content = add_validation_import(original_content)

        # Step 2: Add validation to execute()
        modified_content, validation_added = add_validation_to_execute(modified_content, tool_name)

        if not validation_added:
            result["message"] = "Could not add validation to execute() - pattern not found"
            return result

        # Check if any changes were made
        if modified_content == original_content:
            result["message"] = "No changes needed"
            result["success"] = True
            return result

        result["changes_made"] = True

        if dry_run:
            result["message"] = "Dry run - would add validation"
            result["success"] = True
            return result

        # Create backup
        backup_success, backup_msg = backup_tool(tool_path, force)
        result["backup_created"] = backup_success

        if not backup_success:
            result["message"] = backup_msg
            return result

        # Write modified content
        with open(tool_path, 'w') as f:
            f.write(modified_content)

        result["success"] = True
        result["message"] = "Validation added successfully"

        # Verify syntax
        try:
            compile(modified_content, str(tool_path), 'exec')
        except SyntaxError as e:
            result["message"] = f"Syntax error after changes: {str(e)}"
            result["success"] = False

            # Restore from backup
            backup_path = tool_path.with_suffix(".py.bak")
            if backup_path.exists():
                shutil.copy2(backup_path, tool_path)
                result["message"] += " - Restored from backup"

    except Exception as e:
        result["message"] = f"Error: {str(e)}"

    return result


def main():
    """Main execution function."""
    parser = argparse.ArgumentParser(
        description="Apply validation framework to Sapphire tools"
    )
    parser.add_argument(
        "--tool",
        type=str,
        help="Apply to specific tool only (tool name without .py)"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview changes without applying them"
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite existing backups"
    )

    args = parser.parse_args()

    # Get tools to process
    if args.tool:
        tool_path = TOOLS_DIR / f"{args.tool}.py"
        if not tool_path.exists():
            print(f"Error: Tool not found: {tool_path}")
            sys.exit(1)
        tools = [tool_path]
    else:
        tools = get_all_tools()

    # Print header
    mode = "DRY RUN" if args.dry_run else "LIVE UPDATE"
    print("=" * 60)
    print(f"# Sapphire Tool Validation Framework Application - Stream 1.2")
    print(f"# Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"# Mode: {mode}")
    print(f"# Tools to process: {len(tools)}")
    print("=" * 60)
    print()

    # Process each tool
    results = []
    successful = 0
    failed = 0
    skipped = 0

    for tool_path in tools:
        print(f"Processing: {tool_path.name}...", end=" ")

        result = apply_validation_to_tool(tool_path, args.dry_run, args.force)
        results.append(result)

        if result["success"]:
            if result["changes_made"]:
                print("✅ UPDATED")
                successful += 1
            else:
                print("⏭️  SKIPPED (already has validation)")
                skipped += 1
        else:
            print(f"❌ FAILED: {result['message']}")
            failed += 1

    # Print summary
    print()
    print("=" * 60)
    print("# Summary")
    print("=" * 60)
    print(f"✅ Successful: {successful}/{len(tools)}")
    print(f"❌ Failed: {failed}")
    print(f"⏭️  Skipped: {skipped}")
    print()

    # Save detailed report
    if not args.dry_run:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        report_path = REPORT_DIR / f"validation_report_{timestamp}.json"

        report = {
            "timestamp": datetime.now().isoformat(),
            "mode": mode,
            "total_tools": len(tools),
            "successful": successful,
            "failed": failed,
            "skipped": skipped,
            "results": results
        }

        with open(report_path, 'w') as f:
            json.dump(report, f, indent=2)

        print(f"Report: {report_path}")
        print()

    # Exit code
    sys.exit(0 if failed == 0 else 1)


if __name__ == "__main__":
    main()
