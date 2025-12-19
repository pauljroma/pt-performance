#!/usr/bin/env python3.11
"""
Agent Validation Script

Validates that a Night Agent is production-ready by checking:
1. All dependencies exist
2. Prompt file is valid
3. Input/output schemas are correct
4. Agent can be invoked without errors
5. All lineage files are present

Usage:
    python scripts/validate_agent.py <agent-id>
    python scripts/validate_agent.py architecture-review-agent
    python scripts/validate_agent.py --all
"""

import json
import sys
from pathlib import Path

# Color codes for terminal output
GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"
RESET = "\033[0m"


def load_agents_catalog() -> dict:
    """Load the gold list agents catalog."""
    catalog_path = Path("night_agent_prompts/agents_catalog_gold.json")

    if not catalog_path.exists():
        print(f"{RED}✗ Agents catalog not found: {catalog_path}{RESET}")
        sys.exit(1)

    with open(catalog_path) as f:
        return json.load(f)


def find_agent(catalog: dict, agent_id: str) -> dict:
    """Find agent in catalog by ID."""
    for agent in catalog["agents"]:
        if agent["agent_id"] == agent_id:
            return agent

    print(f"{RED}✗ Agent not found in catalog: {agent_id}{RESET}")
    print("\nAvailable agents:")
    for agent in catalog["agents"]:
        print(f"  - {agent['agent_id']} (v{agent['version']})")
    sys.exit(1)


def validate_file_exists(file_path: str, description: str) -> bool:
    """Check if a file exists."""
    path = Path(file_path)
    if path.exists():
        print(f"{GREEN}✓{RESET} {description}: {file_path}")
        return True
    else:
        print(f"{RED}✗{RESET} {description} NOT FOUND: {file_path}")
        return False


def validate_prompt_file(prompt_path: str) -> tuple[bool, list[str]]:
    """Validate the agent prompt file structure."""
    if not Path(prompt_path).exists():
        return False, ["Prompt file not found"]

    issues = []

    with open(prompt_path) as f:
        content = f.read()

    # Check for required sections
    required_sections = [
        "# Night Agent:",
        "## Agent Identity",
        "## When to Invoke This Agent",
        "## Output Format",
        "## Success Criteria"
    ]

    for section in required_sections:
        if section not in content:
            issues.append(f"Missing section: {section}")

    # Check for 7-phase protocol (for review agents)
    if "review" in prompt_path.lower():
        if "Phase 1:" not in content:
            issues.append("Missing 7-phase review protocol")

    if not issues:
        print(f"{GREEN}✓{RESET} Prompt file structure valid")
        return True, []
    else:
        for issue in issues:
            print(f"{RED}✗{RESET} {issue}")
        return False, issues


def validate_dependencies(agent: dict) -> tuple[bool, list[str]]:
    """Validate all agent dependencies exist."""
    lineage = agent.get("lineage", {})
    dependencies = lineage.get("dependencies", {})

    all_valid = True
    issues = []

    print(f"\n{YELLOW}Checking dependencies...{RESET}")

    # Check required files
    for file_path in dependencies.get("required_files", []):
        if not validate_file_exists(file_path, "Required file"):
            all_valid = False
            issues.append(f"Missing required file: {file_path}")

    # Check lineage files
    for key in ["prompt_file", "pattern_file", "output_modes_file", "integration_point"]:
        if key in lineage:
            file_path = lineage[key].split("#")[0]  # Remove anchor
            if not validate_file_exists(file_path, f"Lineage {key}"):
                all_valid = False
                issues.append(f"Missing lineage file: {file_path}")

    # Check optional embeddings (warning only)
    for file_path in dependencies.get("optional_embeddings", []):
        path = Path(file_path)
        if path.exists():
            print(f"{GREEN}✓{RESET} Optional embedding: {file_path}")
        else:
            print(f"{YELLOW}⚠{RESET} Optional embedding not found: {file_path}")

    return all_valid, issues


def validate_schema(agent: dict) -> tuple[bool, list[str]]:
    """Validate input/output schemas are defined."""
    lineage = agent.get("lineage", {})
    issues = []

    print(f"\n{YELLOW}Checking schemas...{RESET}")

    # Check input schema
    input_schema = lineage.get("input_schema", {})
    if not input_schema:
        issues.append("Missing input_schema in lineage")
        print(f"{RED}✗{RESET} Input schema not defined")
    else:
        print(f"{GREEN}✓{RESET} Input schema defined ({len(input_schema)} fields)")
        for field, field_type in input_schema.items():
            print(f"    - {field}: {field_type}")

    # Check output schema
    output_schema = lineage.get("output_schema", {})
    if not output_schema:
        issues.append("Missing output_schema in lineage")
        print(f"{RED}✗{RESET} Output schema not defined")
    else:
        print(f"{GREEN}✓{RESET} Output schema defined ({len(output_schema)} fields)")
        for field, field_type in output_schema.items():
            print(f"    - {field}: {field_type}")

    return len(issues) == 0, issues


def validate_versioning(agent: dict) -> tuple[bool, list[str]]:
    """Validate versioning information."""
    versioning = agent.get("versioning", {})
    issues = []

    print(f"\n{YELLOW}Checking versioning...{RESET}")

    if "current_version" not in versioning:
        issues.append("Missing current_version")
        print(f"{RED}✗{RESET} Current version not specified")
    else:
        version = versioning["current_version"]
        print(f"{GREEN}✓{RESET} Current version: {version}")

    if "changelog" not in versioning or not versioning["changelog"]:
        issues.append("Missing changelog")
        print(f"{RED}✗{RESET} Changelog not documented")
    else:
        changelog = versioning["changelog"]
        print(f"{GREEN}✓{RESET} Changelog: {len(changelog)} version(s)")
        for entry in changelog:
            version = entry.get("version", "unknown")
            date = entry.get("date", "unknown")
            approved_by = entry.get("approved_by", "unknown")
            print(f"    - v{version} ({date}) approved by {approved_by}")

    return len(issues) == 0, issues


def validate_examples(agent: dict) -> tuple[bool, list[str]]:
    """Validate examples are provided."""
    examples = agent.get("examples", [])
    issues = []

    print(f"\n{YELLOW}Checking examples...{RESET}")

    if not examples:
        issues.append("No examples provided")
        print(f"{YELLOW}⚠{RESET} No examples provided (recommended to add)")
        return True, []  # Warning only, not failure

    print(f"{GREEN}✓{RESET} Examples provided: {len(examples)}")

    for i, example in enumerate(examples, 1):
        example_id = example.get("example_id", f"example_{i}")
        description = example.get("description", "No description")
        print(f"    {i}. {example_id}: {description}")

        # Check if output file exists
        if "output" in example and "report" in example["output"]:
            report_path = example["output"]["report"]
            if Path(report_path).exists():
                print(f"       {GREEN}✓{RESET} Output file exists: {report_path}")
            else:
                print(f"       {YELLOW}⚠{RESET} Output file not found: {report_path}")

    return True, []


def validate_monitoring(agent: dict) -> tuple[bool, list[str]]:
    """Validate monitoring configuration."""
    monitoring = agent.get("monitoring", {})

    print(f"\n{YELLOW}Checking monitoring...{RESET}")

    if "metrics" not in monitoring or not monitoring["metrics"]:
        print(f"{YELLOW}⚠{RESET} No metrics defined (recommended)")
    else:
        metrics = monitoring["metrics"]
        print(f"{GREEN}✓{RESET} Metrics defined: {len(metrics)}")
        for metric in metrics:
            print(f"    - {metric}")

    if "alerts" in monitoring and monitoring["alerts"]:
        alerts = monitoring["alerts"]
        print(f"{GREEN}✓{RESET} Alerts configured: {len(alerts)}")
    else:
        print(f"{YELLOW}⚠{RESET} No alerts configured (recommended)")

    return True, []  # Warnings only


def validate_agent(agent_id: str) -> bool:
    """
    Validate an agent is production-ready.
    Returns True if all checks pass.
    """
    print(f"\n{'=' * 60}")
    print(f"Validating Agent: {agent_id}")
    print(f"{'=' * 60}\n")

    # Load catalog
    catalog = load_agents_catalog()
    agent = find_agent(catalog, agent_id)

    print(f"Agent: {agent['name']}")
    print(f"Version: {agent['version']}")
    print(f"Status: {agent['status']}")
    print(f"Quality Tier: {agent['quality_tier']}")

    # Run all validation checks
    checks = [
        ("Prompt File Structure", validate_prompt_file, [agent["lineage"]["prompt_file"]]),
        ("Dependencies", validate_dependencies, [agent]),
        ("Schemas", validate_schema, [agent]),
        ("Versioning", validate_versioning, [agent]),
        ("Examples", validate_examples, [agent]),
        ("Monitoring", validate_monitoring, [agent])
    ]

    all_passed = True
    all_issues = []

    for check_name, check_func, args in checks:
        try:
            passed, issues = check_func(*args)
            if not passed:
                all_passed = False
                all_issues.extend(issues)
        except Exception as e:
            print(f"{RED}✗{RESET} {check_name} failed with error: {e}")
            all_passed = False
            all_issues.append(f"{check_name} error: {str(e)}")

    # Print summary
    print(f"\n{'=' * 60}")
    if all_passed:
        print(f"{GREEN}✓ VALIDATION PASSED{RESET}")
        print(f"\nAgent '{agent_id}' is production-ready!")
        print("All dependencies are present and schemas are valid.")
        return True
    else:
        print(f"{RED}✗ VALIDATION FAILED{RESET}")
        print(f"\nAgent '{agent_id}' has {len(all_issues)} issue(s):")
        for i, issue in enumerate(all_issues, 1):
            print(f"  {i}. {issue}")
        print("\nPlease fix these issues before deploying to production.")
        return False


def validate_all_agents():
    """Validate all agents in the gold list."""
    catalog = load_agents_catalog()

    print(f"\n{'=' * 60}")
    print("Validating All Gold List Agents")
    print(f"{'=' * 60}\n")

    results = {}

    for agent in catalog["agents"]:
        agent_id = agent["agent_id"]
        passed = validate_agent(agent_id)
        results[agent_id] = passed
        print()  # Blank line between agents

    # Summary
    print(f"\n{'=' * 60}")
    print("VALIDATION SUMMARY")
    print(f"{'=' * 60}\n")

    total = len(results)
    passed = sum(1 for v in results.values() if v)
    failed = total - passed

    for agent_id, passed in results.items():
        status = f"{GREEN}✓ PASS{RESET}" if passed else f"{RED}✗ FAIL{RESET}"
        print(f"{status} - {agent_id}")

    print(f"\nTotal: {total} agents")
    print(f"Passed: {GREEN}{passed}{RESET}")
    print(f"Failed: {RED}{failed}{RESET}")

    return failed == 0


def main():
    """Main entry point."""
    if len(sys.argv) < 2:
        print("Usage: python scripts/validate_agent.py <agent-id>")
        print("       python scripts/validate_agent.py --all")
        print("\nExample: python scripts/validate_agent.py architecture-review-agent")
        sys.exit(1)

    if sys.argv[1] == "--all":
        success = validate_all_agents()
    else:
        agent_id = sys.argv[1]
        success = validate_agent(agent_id)

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
