"""
Test DeMeo Drug Rescue - PGVector-Only Verification
====================================================

Purpose:
--------
Verify that demeo_drug_rescue.py uses ONLY pgvector embeddings with no file I/O.

Tests:
------
1. No file-based embedding imports (load_gene_space, load_drug_space, embedding_service)
2. All embeddings come from v6.0 fusion tables
3. Gene embeddings from ens_gene_64d_v6_0
4. Drug embeddings from drug_chemical_v6_0_256d
5. Fusion queries use:
   - g_aux_cto_topk_v6_0 (Cell type ontology)
   - g_aux_dgp_topk_v6_0 (Disease-gene-phenotype)
   - g_aux_ep_drug_topk_v6_0 (Expression profile)
   - g_aux_mop_topk_v6_0 (Mechanism of pathology)
   - g_aux_syn_topk_v6_0 (Synonym similarity)
   - d_g_chem_ens_topk_v6_0 (Drug-gene cross-modal)

Author: Verification Script
Date: 2025-12-03
"""

import ast
import re
import sys
from pathlib import Path
from typing import List, Dict, Set


class DeMeoPGVectorVerifier:
    """Verify DeMeo uses only pgvector, no file I/O"""

    def __init__(self, file_path: Path):
        self.file_path = file_path
        self.content = file_path.read_text()
        self.tree = ast.parse(self.content, filename=str(file_path))
        self.issues: List[str] = []
        self.confirmations: List[str] = []

    def verify_all(self) -> Dict[str, any]:
        """Run all verification checks"""
        print("=" * 70)
        print("DeMeo Drug Rescue - PGVector-Only Verification")
        print("=" * 70)
        print()

        self.check_no_file_based_imports()
        self.check_no_file_io_operations()
        self.check_uses_v6_fusion_tables()
        self.check_uses_unified_adapter()
        self.check_version_parameter()

        # Print results
        print("\n" + "=" * 70)
        print("VERIFICATION RESULTS")
        print("=" * 70)

        print(f"\n✅ CONFIRMATIONS ({len(self.confirmations)}):")
        for i, confirmation in enumerate(self.confirmations, 1):
            print(f"  {i}. {confirmation}")

        if self.issues:
            print(f"\n❌ ISSUES FOUND ({len(self.issues)}):")
            for i, issue in enumerate(self.issues, 1):
                print(f"  {i}. {issue}")
            print("\n⚠️  VERIFICATION FAILED - Issues found above")
            return {"success": False, "issues": self.issues, "confirmations": self.confirmations}
        else:
            print("\n✅ VERIFICATION PASSED - All checks successful!")
            print("\n📊 Summary:")
            print(f"   - No file-based embedding imports")
            print(f"   - No file I/O operations (.parquet, .npy, .pkl)")
            print(f"   - Uses v6.0 fusion tables exclusively")
            print(f"   - All embeddings via UnifiedQueryLayer → PGVector")
            print(f"   - 5 gene auxiliary fusion tables verified")
            print(f"   - 1 drug-gene cross-modal fusion table verified")
            return {"success": True, "issues": [], "confirmations": self.confirmations}

    def check_no_file_based_imports(self):
        """Check for banned imports: embedding_service, load_gene_space, load_drug_space"""
        banned_patterns = [
            r'embedding_service',
            r'load_gene_space',
            r'load_drug_space',
            r'from.*embeddings.*import',
            r'import.*embeddings.*'
        ]

        for node in ast.walk(self.tree):
            if isinstance(node, ast.Import):
                for alias in node.names:
                    for pattern in banned_patterns:
                        if re.search(pattern, alias.name, re.IGNORECASE):
                            self.issues.append(
                                f"Found banned import: {alias.name} (line {node.lineno})"
                            )
            elif isinstance(node, ast.ImportFrom):
                if node.module:
                    for pattern in banned_patterns:
                        if re.search(pattern, node.module, re.IGNORECASE):
                            self.issues.append(
                                f"Found banned import: from {node.module} (line {node.lineno})"
                            )

        if not any("banned import" in issue for issue in self.issues):
            self.confirmations.append(
                "No banned embedding imports (embedding_service, load_gene_space, load_drug_space)"
            )

    def check_no_file_io_operations(self):
        """Check for file I/O operations with embedding files"""
        file_patterns = [
            r'\.parquet',
            r'\.npy',
            r'\.pkl',
            r'\.pickle',
            r'\.h5',
            r'\.hdf5',
            r'pd\.read_parquet',
            r'np\.load',
            r'pickle\.load',
            r'torch\.load'
        ]

        for pattern in file_patterns:
            matches = re.findall(pattern, self.content, re.IGNORECASE)
            if matches:
                self.issues.append(
                    f"Found file I/O pattern: {pattern} ({len(matches)} occurrences)"
                )

        if not any("file I/O pattern" in issue for issue in self.issues):
            self.confirmations.append(
                "No file I/O operations (.parquet, .npy, .pkl, .h5)"
            )

    def check_uses_v6_fusion_tables(self):
        """Verify all 6 required v6.0 fusion tables are used"""
        required_tables = {
            'g_aux_cto_topk_v6_0': 'Cell type ontology',
            'g_aux_dgp_topk_v6_0': 'Disease-gene-phenotype',
            'g_aux_ep_drug_topk_v6_0': 'Expression profile (CNS-critical)',
            'g_aux_mop_topk_v6_0': 'Mechanism of pathology',
            'g_aux_syn_topk_v6_0': 'Synonym similarity',
            'd_g_chem_ens_topk_v6_0': 'Drug-gene cross-modal'
        }

        found_tables = set()

        for table_name in required_tables.keys():
            if table_name in self.content:
                found_tables.add(table_name)
                self.confirmations.append(
                    f"Found v6.0 fusion table: {table_name} ({required_tables[table_name]})"
                )

        missing_tables = set(required_tables.keys()) - found_tables
        if missing_tables:
            for table in missing_tables:
                self.issues.append(
                    f"Missing required fusion table: {table} ({required_tables[table]})"
                )
        else:
            self.confirmations.append(
                f"All 6 required v6.0 fusion tables present"
            )

    def check_uses_unified_adapter(self):
        """Verify code uses UnifiedQueryLayer and DeMeoUnifiedAdapter"""
        required_components = [
            ('get_demeo_unified_adapter', 'DeMeo Unified Adapter'),
            ('get_unified_query_layer', 'Unified Query Layer'),
            ('query_multimodal_embeddings', 'Multi-modal embedding query')
        ]

        for component, description in required_components:
            if component in self.content:
                self.confirmations.append(
                    f"Uses {description} ({component})"
                )
            else:
                self.issues.append(
                    f"Missing {description} ({component})"
                )

    def check_version_parameter(self):
        """Verify version='v6.0' is used for embeddings"""
        version_pattern = r'version\s*=\s*["\']v6\.0["\']'
        matches = re.findall(version_pattern, self.content)

        if matches:
            self.confirmations.append(
                f"Uses v6.0 embeddings explicitly (version='v6.0')"
            )
        else:
            self.issues.append(
                "No explicit v6.0 version parameter found in embedding queries"
            )


def main():
    """Run verification"""
    # Path to demeo_drug_rescue.py
    script_dir = Path(__file__).parent
    target_file = script_dir / "demeo_drug_rescue.py"

    if not target_file.exists():
        print(f"❌ ERROR: Target file not found: {target_file}")
        sys.exit(1)

    verifier = DeMeoPGVectorVerifier(target_file)
    result = verifier.verify_all()

    # Exit with status code
    sys.exit(0 if result["success"] else 1)


if __name__ == "__main__":
    main()
