#!/usr/bin/env python3
"""
Strategic Analysis System Validation - SAP-49

Direct validation script that tests the 3 strategic analysis tools:
1. clinical_trial_intelligence
2. drug_repurposing_ranker
3. target_validation_scorer

Produces comprehensive validation report.
"""

import os
import sys
import asyncio
import time
from pathlib import Path
import json

# Add paths
tools_dir = Path(__file__).parent
platform_root = Path(__file__).parent.parent.parent.parent
quiver_root = platform_root.parent
expo_root = quiver_root.parent.parent

sys.path.insert(0, str(expo_root))
sys.path.insert(0, str(tools_dir))

# Import tools directly
import clinical_trial_intelligence
import drug_repurposing_ranker
import target_validation_scorer


class ValidationReport:
    """Tracks validation results."""

    def __init__(self):
        self.tests_run = 0
        self.tests_passed = 0
        self.tests_failed = 0
        self.results = []
        self.production_gaps = []

    def record_test(self, test_name, passed, details=None, latency_ms=None):
        """Record a test result."""
        self.tests_run += 1
        if passed:
            self.tests_passed += 1
        else:
            self.tests_failed += 1

        self.results.append({
            "test": test_name,
            "passed": passed,
            "details": details,
            "latency_ms": latency_ms
        })

    def record_gap(self, gap, severity="HIGH"):
        """Record a production readiness gap."""
        self.production_gaps.append({
            "gap": gap,
            "severity": severity
        })

    def print_summary(self):
        """Print validation summary."""
        print("\n" + "=" * 80)
        print("STRATEGIC ANALYSIS SYSTEM VALIDATION REPORT - SAP-49")
        print("=" * 80)

        print(f"\n📊 Test Results: {self.tests_passed}/{self.tests_run} passed ({(self.tests_passed/self.tests_run*100):.1f}%)")
        print(f"   ✓ Passed: {self.tests_passed}")
        print(f"   ✗ Failed: {self.tests_failed}")

        print("\n" + "-" * 80)
        print("DETAILED TEST RESULTS")
        print("-" * 80)

        for result in self.results:
            status = "✓" if result["passed"] else "✗"
            test = result["test"]
            latency = f" ({result['latency_ms']:.0f}ms)" if result["latency_ms"] else ""
            print(f"{status} {test}{latency}")

            if result["details"] and not result["passed"]:
                print(f"     Error: {result['details']}")

        if self.production_gaps:
            print("\n" + "-" * 80)
            print("PRODUCTION READINESS GAPS")
            print("-" * 80)

            for gap in self.production_gaps:
                severity_icon = {"CRITICAL": "🔴", "HIGH": "🟠", "MEDIUM": "🟡", "LOW": "🟢"}.get(gap["severity"], "⚪")
                print(f"{severity_icon} [{gap['severity']}] {gap['gap']}")

        print("\n" + "=" * 80)


async def validate_clinical_trial_intelligence(report: ValidationReport):
    """Validate clinical trial intelligence tool."""
    print("\n[1/3] Validating Clinical Trial Intelligence...")

    # Test 1: Basic search
    try:
        start = time.time()
        result = await clinical_trial_intelligence.execute({
            "query": "epilepsy trials",
            "max_results": 10
        })
        latency = (time.time() - start) * 1000

        if result.get("success"):
            report.record_test(
                "Clinical Trial Intelligence - Basic Search",
                True,
                f"Found {result.get('total_trials_found', 0)} trials",
                latency
            )
        else:
            report.record_test(
                "Clinical Trial Intelligence - Basic Search",
                False,
                result.get("error", "Unknown error")
            )

        # Check data sources
        data_sources = result.get("data_sources", [])
        if "OMOP Clinical Twin (PostgreSQL)" in str(data_sources):
            report.record_gap("OMOP Clinical Twin returns MOCK data - needs real implementation", "CRITICAL")

    except Exception as e:
        report.record_test(
            "Clinical Trial Intelligence - Basic Search",
            False,
            str(e)
        )

    # Test 2: Dravet syndrome specific
    try:
        start = time.time()
        result = await clinical_trial_intelligence.execute({
            "query": "Dravet syndrome",
            "trial_phase": ["PHASE2", "PHASE3"],
            "max_results": 20
        })
        latency = (time.time() - start) * 1000

        report.record_test(
            "Clinical Trial Intelligence - Dravet Syndrome",
            result.get("success", False),
            latency_ms=latency
        )
    except Exception as e:
        report.record_test("Clinical Trial Intelligence - Dravet Syndrome", False, str(e))


async def validate_drug_repurposing_ranker(report: ValidationReport):
    """Validate drug repurposing ranker tool."""
    print("\n[2/3] Validating Drug Repurposing Ranker...")

    # Test 1: Basic repurposing
    try:
        start = time.time()
        result = await drug_repurposing_ranker.execute({
            "disease": "Dravet syndrome",
            "max_results": 20
        })
        latency = (time.time() - start) * 1000

        if result.get("success"):
            report.record_test(
                "Drug Repurposing - Basic Ranking",
                True,
                f"Screened {result.get('total_drugs_screened', 0)} drugs, found {result.get('drugs_meeting_criteria', 0)} candidates",
                latency
            )

            # Check if real drug database
            if result.get("total_drugs_screened", 0) < 100:
                report.record_gap(
                    f"Drug database has only {result['total_drugs_screened']} drugs (should be 14,246) - MOCK data",
                    "CRITICAL"
                )
        else:
            report.record_test(
                "Drug Repurposing - Basic Ranking",
                False,
                result.get("error")
            )
    except Exception as e:
        report.record_test("Drug Repurposing - Basic Ranking", False, str(e))

    # Test 2: Gene-targeted repurposing
    try:
        start = time.time()
        result = await drug_repurposing_ranker.execute({
            "disease": "Dravet syndrome",
            "target_gene": "SCN1A",
            "max_results": 10
        })
        latency = (time.time() - start) * 1000

        report.record_test(
            "Drug Repurposing - Gene-Targeted (SCN1A)",
            result.get("success", False),
            latency_ms=latency
        )

        # Check for v6.0 fusion integration
        candidates = result.get("repurposing_candidates", [])
        if candidates and candidates[0].get("evidence_breakdown"):
            # Check if using fusion
            pass  # Would need to inspect sources
    except Exception as e:
        report.record_test("Drug Repurposing - Gene-Targeted (SCN1A)", False, str(e))

    # Test 3: CNS filter
    try:
        result = await drug_repurposing_ranker.execute({
            "disease": "epilepsy",
            "include_cns_only": True,
            "max_results": 10
        })

        report.record_test(
            "Drug Repurposing - CNS Filter",
            result.get("success", False)
        )
    except Exception as e:
        report.record_test("Drug Repurposing - CNS Filter", False, str(e))


async def validate_target_validation_scorer(report: ValidationReport):
    """Validate target validation scorer tool."""
    print("\n[3/3] Validating Target Validation Scorer...")

    # Test 1: SCN1A validation for Dravet
    try:
        start = time.time()
        result = await target_validation_scorer.execute({
            "gene": "SCN1A",
            "disease": "Dravet syndrome"
        })
        latency = (time.time() - start) * 1000

        if result.get("success"):
            report.record_test(
                "Target Validation - SCN1A/Dravet",
                True,
                f"Validation score: {result.get('validation_score', 0):.2f}, Recommendation: {result.get('recommendation', 'N/A')}",
                latency
            )

            # Check evidence dimensions
            evidence = result.get("evidence_breakdown", {})
            expected_dims = [
                "genetic_evidence",
                "expression_evidence",
                "pathway_evidence",
                "druggability",
                "literature_evidence",
                "clinical_evidence"
            ]

            missing_dims = [d for d in expected_dims if d not in evidence]
            if missing_dims:
                report.record_gap(
                    f"Missing evidence dimensions: {missing_dims}",
                    "HIGH"
                )
        else:
            report.record_test(
                "Target Validation - SCN1A/Dravet",
                False,
                result.get("error")
            )
    except Exception as e:
        report.record_test("Target Validation - SCN1A/Dravet", False, str(e))

    # Test 2: Check v6.0 fusion for druggability
    try:
        result = await target_validation_scorer.execute({
            "gene": "KCNQ2",
            "disease": "epilepsy"
        })

        report.record_test(
            "Target Validation - KCNQ2/Epilepsy",
            result.get("success", False)
        )

        # Check if druggability used fusion
        if result.get("evidence_breakdown", {}).get("druggability"):
            druggability = result["evidence_breakdown"]["druggability"]
            if druggability.get("fusion_available"):
                report.record_test(
                    "Target Validation - v6.0 Fusion Integration",
                    True,
                    f"Fusion drug count: {druggability.get('fusion_drug_count', 'N/A')}"
                )
            else:
                report.record_gap(
                    "Druggability scoring not using v6.0 fusion tables",
                    "MEDIUM"
                )
    except Exception as e:
        report.record_test("Target Validation - KCNQ2/Epilepsy", False, str(e))


async def validate_full_workflow(report: ValidationReport):
    """Validate full strategic analysis workflow."""
    print("\n[4/4] Validating Full Strategic Workflow...")

    try:
        # Step 1: Validate target
        target_result = await target_validation_scorer.execute({
            "gene": "SCN1A",
            "disease": "Dravet syndrome"
        })

        # Step 2: Rank repurposing drugs if target validated
        if target_result.get("validation_score", 0) >= 0.5:
            repurposing_result = await drug_repurposing_ranker.execute({
                "disease": "Dravet syndrome",
                "target_gene": "SCN1A",
                "include_cns_only": True,
                "max_results": 5
            })

            # Step 3: Check trials for top drug
            if repurposing_result.get("repurposing_candidates"):
                top_drug = repurposing_result["repurposing_candidates"][0]["drug_name"]
                trial_result = await clinical_trial_intelligence.execute({
                    "query": f"Dravet syndrome {top_drug}",
                    "max_results": 5
                })

                if trial_result.get("success"):
                    report.record_test(
                        "Full Strategic Workflow - Target→Drug→Trials",
                        True,
                        f"Validated {top_drug} for Dravet syndrome"
                    )
                else:
                    report.record_test(
                        "Full Strategic Workflow - Target→Drug→Trials",
                        False,
                        "Trial search failed"
                    )
            else:
                report.record_test(
                    "Full Strategic Workflow - Target→Drug→Trials",
                    False,
                    "No repurposing candidates found"
                )
        else:
            report.record_test(
                "Full Strategic Workflow - Target→Drug→Trials",
                False,
                "Target validation failed"
            )
    except Exception as e:
        report.record_test("Full Strategic Workflow - Target→Drug→Trials", False, str(e))


async def identify_production_gaps(report: ValidationReport):
    """Identify all production readiness gaps."""

    report.record_gap(
        "OMOP Clinical Twin integration is MOCKED - needs real PostgreSQL queries",
        "CRITICAL"
    )

    report.record_gap(
        "Neo4j Knowledge Graph queries are MOCKED - needs real Cypher queries",
        "CRITICAL"
    )

    report.record_gap(
        "Drug database has 3 mock drugs instead of 14,246 real drugs",
        "CRITICAL"
    )

    report.record_gap(
        "LINCS L1000 transcriptomic scoring is MOCKED",
        "HIGH"
    )

    report.record_gap(
        "BBB permeability tool integration is MOCKED",
        "HIGH"
    )

    report.record_gap(
        "ADME/Tox predictor integration is MOCKED",
        "HIGH"
    )

    report.record_gap(
        "Literature database queries (29,863 papers) are MOCKED",
        "MEDIUM"
    )

    report.record_gap(
        "Patent/FDA database queries are MOCKED",
        "MEDIUM"
    )

    report.record_gap(
        "Clinical precedent scoring is MOCKED",
        "MEDIUM"
    )

    report.record_gap(
        "Genetic evidence scoring is mostly MOCKED (hard-coded for SCN1A/Dravet)",
        "HIGH"
    )


async def main():
    """Main validation execution."""
    print("=" * 80)
    print("STRATEGIC ANALYSIS SYSTEM VALIDATION - SAP-49")
    print("=" * 80)
    print("\nValidating 3-tool strategic analysis system:")
    print("  1. clinical_trial_intelligence")
    print("  2. drug_repurposing_ranker")
    print("  3. target_validation_scorer")

    report = ValidationReport()

    # Run validations
    await validate_clinical_trial_intelligence(report)
    await validate_drug_repurposing_ranker(report)
    await validate_target_validation_scorer(report)
    await validate_full_workflow(report)
    await identify_production_gaps(report)

    # Print report
    report.print_summary()

    # Production readiness assessment
    print("\n" + "=" * 80)
    print("PRODUCTION READINESS ASSESSMENT")
    print("=" * 80)

    pass_rate = (report.tests_passed / report.tests_run * 100) if report.tests_run > 0 else 0
    critical_gaps = len([g for g in report.production_gaps if g["severity"] == "CRITICAL"])

    print(f"\nTest Pass Rate: {pass_rate:.1f}% ({report.tests_passed}/{report.tests_run})")
    print(f"Critical Production Gaps: {critical_gaps}")

    if pass_rate < 70 or critical_gaps > 2:
        print("\n🔴 NOT PRODUCTION READY")
        print("   System has major implementation gaps.")
        print("   Most data sources are mocked.")
        print("   Estimated 4-6 weeks for full implementation.")
    elif pass_rate < 90 or critical_gaps > 0:
        print("\n🟡 PARTIALLY PRODUCTION READY")
        print("   Core functionality works but has gaps.")
        print("   Requires additional implementation work.")
    else:
        print("\n🟢 PRODUCTION READY")
        print("   System validated and ready for production use.")

    # Save report
    os.makedirs(".outcomes", exist_ok=True)
    report_file = ".outcomes/sap49_validation_report.json"
    with open(report_file, "w") as f:
        json.dump({
            "tests_run": report.tests_run,
            "tests_passed": report.tests_passed,
            "tests_failed": report.tests_failed,
            "pass_rate": pass_rate,
            "production_gaps": report.production_gaps,
            "results": report.results
        }, f, indent=2)

    print(f"\n📄 Detailed report saved to: {report_file}")
    print("\n" + "=" * 80)

    return 0 if pass_rate >= 70 and critical_gaps == 0 else 1


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)
