#!/usr/bin/env python3
"""
Automated Harmonization Application Script
==========================================

Applies identifier harmonization pattern to Sapphire tools.

Usage:
    python apply_harmonization.py [--dry-run] [--tool TOOL_NAME]

Options:
    --dry-run: Show what would be changed without modifying files
    --tool: Apply to specific tool only (e.g., --tool graph_neighbors)

Author: Sapphire v4.0 Stream 1
Date: 2025-11-29
"""

import re
import sys
from pathlib import Path
from typing import Dict, List, Tuple, Optional
import json
from datetime import datetime

# Tool classifications from harmonization guide
GENE_TOOLS = [
    "graph_neighbors",
    "graph_path",
    "graph_subgraph",
    "transcriptomic_rescue",
    "provenance_discovery",
    "entity_metadata",
]

DRUG_TOOLS = [
    "drug_interactions",
    "drug_lookalikes",
    "drug_combinations_synergy",
    "rescue_combinations",
    "drug_properties_detail",
    "vector_similarity",
    "semantic_search",
]

# lincs_expression_detail accepts both gene and drug
DUAL_TOOLS = [
    "lincs_expression_detail",
]

# Tools already updated
COMPLETED_TOOLS = [
    "vector_antipodal",
    "vector_neighbors",
]


class HarmonizationApplier:
    """Applies harmonization pattern to tool files."""

    def __init__(self, tools_dir: Path, dry_run: bool = False):
        self.tools_dir = tools_dir
        self.dry_run = dry_run
        self.changes_made = []
        self.errors = []

    def get_import_block(self, tool_type: str) -> str:
        """Get the import block to add."""
        if tool_type == "gene":
            imports = "harmonize_gene_id, validate_input, normalize_gene_symbol"
        elif tool_type == "drug":
            imports = "harmonize_drug_id, validate_input"
        else:  # dual
            imports = "harmonize_gene_id, harmonize_drug_id, validate_input, normalize_gene_symbol"

        return f"""
# Import harmonization utilities (Stream 1: Foundation)
try:
    from tool_utils import {imports}
    HARMONIZATION_AVAILABLE = True
except ImportError:
    HARMONIZATION_AVAILABLE = False
"""

    def get_gene_harmonization_logic(self) -> str:
        """Get gene harmonization logic to insert in execute function."""
        return """
        # STREAM 1: Identifier harmonization
        harmonization_note = None
        gene_normalized = gene

        if HARMONIZATION_AVAILABLE:
            # Try harmonization (handles Entrez IDs, UniProt IDs, etc.)
            harmonized = harmonize_gene_id(gene)
            if harmonized["success"] and harmonized["hgnc_symbol"]:
                gene_normalized = harmonized["hgnc_symbol"]
                harmonization_note = f"Harmonized {harmonized['id_type_detected']} → HGNC"
            else:
                # Fall back to original input (might be a gene symbol)
                gene_normalized = normalize_gene_symbol(gene)
        else:
            # No harmonization available, use original input
            gene_normalized = gene.upper().strip()
"""

    def get_drug_harmonization_logic(self) -> str:
        """Get drug harmonization logic to insert in execute function."""
        return """
        # STREAM 1: Identifier harmonization
        harmonization_note = None
        drug_normalized = drug_name

        if HARMONIZATION_AVAILABLE:
            # Try harmonization (handles ChEMBL IDs, RxNorm IDs, LINCS IDs)
            harmonized = harmonize_drug_id(drug_name)
            if harmonized["success"]:
                # Use ChEMBL ID if available (most tools use ChEMBL)
                if harmonized.get("chembl_id"):
                    drug_chembl_id = harmonized["chembl_id"]
                    harmonization_note = f"Harmonized {harmonized['id_type_detected']} → ChEMBL"
                # Or use the drug name
                if harmonized.get("drug_name"):
                    drug_normalized = harmonized["drug_name"]
"""

    def update_tool_description(self, content: str, tool_type: str, param_name: str) -> str:
        """Update tool description to mention multiple ID formats."""

        if tool_type == "gene":
            new_desc = f'Gene identifier in any format: HGNC symbol (TP53), Entrez ID (7157), or UniProt ID (P04637). Case-insensitive.'
        elif tool_type == "drug":
            new_desc = f'Drug identifier in any format: Drug name, ChEMBL ID (CHEMBL1234), RxNorm ID (1234567), or LINCS ID (BRD-K...).'
        else:
            return content

        # Find the parameter description and update it
        # Pattern: "param_name": { ... "description": "..." }
        pattern = rf'("{param_name}"\s*:\s*\{{[^}}]*"description"\s*:\s*)"([^"]*)"'

        def replacer(match):
            return f'{match.group(1)}"{new_desc}"'

        updated = re.sub(pattern, replacer, content, count=1)

        if updated != content:
            self.changes_made.append(f"Updated {param_name} description")

        return updated

    def add_harmonization_to_return(self, content: str) -> str:
        """Add harmonization note to return statement."""

        # Find return dict patterns and add harmonization field
        # Look for: return { ... }

        # Pattern 1: Multi-line return dict
        pattern1 = r'(return\s+\{[^}]*"success"\s*:\s*True[^}]*)\}'

        def replacer1(match):
            dict_content = match.group(1)
            # Check if harmonization already added
            if '"harmonization"' in dict_content:
                return match.group(0)

            # Convert to result_dict pattern and add harmonization
            replacement = dict_content.replace('return {', 'result_dict = {')
            replacement += """
        }

        # Add harmonization note if applicable
        if harmonization_note:
            result_dict["harmonization"] = harmonization_note

        return result_dict"""
            return replacement

        updated = re.sub(pattern1, replacer1, content, count=1)

        if updated != content:
            self.changes_made.append("Added harmonization to return statement")

        return updated

    def process_tool(self, tool_name: str) -> bool:
        """Process a single tool file."""

        tool_file = self.tools_dir / f"{tool_name}.py"

        if not tool_file.exists():
            self.errors.append(f"Tool file not found: {tool_file}")
            return False

        # Determine tool type
        if tool_name in GENE_TOOLS:
            tool_type = "gene"
            param_name = "gene"
        elif tool_name in DRUG_TOOLS:
            tool_type = "drug"
            param_name = "drug_name" if tool_name == "drug_properties_detail" else "drug"
        elif tool_name in DUAL_TOOLS:
            tool_type = "dual"
            param_name = "gene"  # primary param
        else:
            self.errors.append(f"Unknown tool type for: {tool_name}")
            return False

        print(f"\n{'='*60}")
        print(f"Processing: {tool_name} (type: {tool_type})")
        print(f"{'='*60}")

        # Read current content
        content = tool_file.read_text()

        # Check if already harmonized
        if "HARMONIZATION_AVAILABLE" in content:
            print(f"⚠️  Tool already has harmonization imports - skipping")
            return True

        # Store original for comparison
        original_content = content
        self.changes_made = []

        # 1. Add imports after other imports
        import_block = self.get_import_block(tool_type)

        # Find where to insert (after last import, before TOOL_DEFINITION)
        import_pattern = r'((?:^import .*\n|^from .* import .*\n)+)'
        match = re.search(import_pattern, content, re.MULTILINE)

        if match:
            # Insert after last import
            insert_pos = match.end()
            content = content[:insert_pos] + import_block + content[insert_pos:]
            self.changes_made.append("Added harmonization imports")
        else:
            # Fallback: insert before TOOL_DEFINITION
            if "TOOL_DEFINITION" in content:
                insert_pos = content.index("TOOL_DEFINITION")
                content = content[:insert_pos] + import_block + "\n" + content[insert_pos:]
                self.changes_made.append("Added harmonization imports (before TOOL_DEFINITION)")

        # 2. Update tool description
        content = self.update_tool_description(content, tool_type, param_name)

        # 3. Add harmonization logic in execute function
        # Find the execute function and add logic after parameter extraction

        if tool_type == "gene":
            harmonization_logic = self.get_gene_harmonization_logic()
            # Look for pattern: gene = tool_input.get("gene"...) or gene = tool_input["gene"]
            pattern = r'(gene\s*=\s*tool_input(?:\[|\.get\().*?\n)'
            replacement = r'\1' + harmonization_logic
        elif tool_type == "drug":
            harmonization_logic = self.get_drug_harmonization_logic()
            # Look for pattern: drug_name = tool_input...
            if param_name == "drug_name":
                pattern = r'(drug_name\s*=\s*tool_input(?:\[|\.get\().*?\n)'
            else:
                pattern = r'(drug\s*=\s*tool_input(?:\[|\.get\().*?\n)'
            replacement = r'\1' + harmonization_logic
        else:  # dual
            # For dual tools, add both (more complex)
            harmonization_logic = self.get_gene_harmonization_logic()
            pattern = r'(gene\s*=\s*tool_input(?:\[|\.get\().*?\n)'
            replacement = r'\1' + harmonization_logic

        match = re.search(pattern, content)
        if match:
            content = re.sub(pattern, replacement, content, count=1)
            self.changes_made.append(f"Added harmonization logic after {param_name} extraction")
        else:
            print(f"⚠️  Could not find {param_name} parameter extraction - manual review needed")

        # 4. Update return statement to include harmonization note
        content = self.add_harmonization_to_return(content)

        # 5. Replace gene/drug with gene_normalized/drug_normalized in queries
        if tool_type == "gene":
            # Replace gene usage with gene_normalized in Neo4j/SQL queries
            # Be careful not to replace in comments or strings
            # This is a heuristic - may need manual review
            if "gene_normalized" not in content:
                print("⚠️  Manual review recommended: Update gene variable to gene_normalized in queries")

        # Show changes
        if self.changes_made:
            print(f"\n✅ Changes to apply:")
            for change in self.changes_made:
                print(f"   - {change}")
        else:
            print(f"\n⚠️  No changes identified")

        # Write if not dry-run
        if not self.dry_run:
            # Create backup
            backup_file = tool_file.with_suffix('.py.bak')
            backup_file.write_text(original_content)

            # Write updated content
            tool_file.write_text(content)
            print(f"\n💾 Saved changes to {tool_file}")
            print(f"📦 Backup created: {backup_file}")
        else:
            print(f"\n🔍 DRY RUN - No files modified")

        return True

    def run(self, specific_tool: Optional[str] = None):
        """Run harmonization on all tools or specific tool."""

        if specific_tool:
            tools_to_process = [specific_tool]
        else:
            tools_to_process = GENE_TOOLS + DRUG_TOOLS + DUAL_TOOLS

        print(f"\n{'#'*60}")
        print(f"# Sapphire Tool Harmonization Batch Update")
        print(f"# Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"# Mode: {'DRY RUN' if self.dry_run else 'LIVE UPDATE'}")
        print(f"# Tools to process: {len(tools_to_process)}")
        print(f"{'#'*60}")

        results = {
            "successful": [],
            "failed": [],
            "skipped": []
        }

        for tool in tools_to_process:
            if tool in COMPLETED_TOOLS:
                print(f"\n✓ Skipping {tool} (already completed)")
                results["skipped"].append(tool)
                continue

            try:
                success = self.process_tool(tool)
                if success:
                    results["successful"].append(tool)
                else:
                    results["failed"].append(tool)
            except Exception as e:
                print(f"\n❌ Error processing {tool}: {e}")
                self.errors.append(f"{tool}: {str(e)}")
                results["failed"].append(tool)

        # Final summary
        print(f"\n\n{'#'*60}")
        print(f"# SUMMARY")
        print(f"{'#'*60}")
        print(f"✅ Successful: {len(results['successful'])}")
        print(f"❌ Failed: {len(results['failed'])}")
        print(f"⏭️  Skipped: {len(results['skipped'])}")

        if results["successful"]:
            print(f"\nSuccessfully processed:")
            for tool in results["successful"]:
                print(f"  ✓ {tool}")

        if results["failed"]:
            print(f"\nFailed:")
            for tool in results["failed"]:
                print(f"  ✗ {tool}")

        if self.errors:
            print(f"\nErrors encountered:")
            for error in self.errors:
                print(f"  ! {error}")

        # Save report
        report = {
            "timestamp": datetime.now().isoformat(),
            "mode": "dry_run" if self.dry_run else "live",
            "results": results,
            "errors": self.errors
        }

        report_file = self.tools_dir / f"harmonization_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        if not self.dry_run:
            report_file.write_text(json.dumps(report, indent=2))
            print(f"\n📊 Report saved: {report_file}")

        return results


def main():
    """Main entry point."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Apply harmonization pattern to Sapphire tools"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be changed without modifying files"
    )
    parser.add_argument(
        "--tool",
        type=str,
        help="Process specific tool only (e.g., graph_neighbors)"
    )

    args = parser.parse_args()

    # Get tools directory
    script_dir = Path(__file__).parent
    tools_dir = script_dir / "tools"

    if not tools_dir.exists():
        print(f"❌ Tools directory not found: {tools_dir}")
        return 1

    # Run harmonization
    applier = HarmonizationApplier(tools_dir, dry_run=args.dry_run)
    results = applier.run(specific_tool=args.tool)

    # Exit code based on results
    if results["failed"]:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
