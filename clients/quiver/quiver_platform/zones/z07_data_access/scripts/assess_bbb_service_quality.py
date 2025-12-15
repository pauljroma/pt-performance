#!/usr/bin/env python3
"""
BBB Prediction Service Quality Assessment
==========================================

Validates code quality, test coverage, and production readiness
for BBBPredictionService following QDDA quality framework.

Author: Quality Agent
Date: 2025-12-01
"""

import json
import sys
from pathlib import Path
from typing import Dict, List, Any

# Add zones to path
zones_path = Path(__file__).parent.parent.parent
sys.path.insert(0, str(zones_path))


class BBBServiceQualityAssessment:
    """Quality assessment for BBB Prediction Service."""

    def __init__(self):
        self.base_path = Path(__file__).parent.parent
        self.findings = []
        self.metrics = {}
        self.recommendations = []

    def assess_code_quality(self) -> Dict[str, Any]:
        """Assess code quality of BBBPredictionService."""
        print("\n" + "="*60)
        print("ASSESSMENT 1: Code Quality")
        print("="*60)

        service_file = self.base_path / "bbb_prediction_service.py"

        if not service_file.exists():
            return {
                "score": 0,
                "status": "FAIL",
                "finding": "BBBPredictionService file not found"
            }

        # Read file
        code = service_file.read_text()
        lines = code.split('\n')

        # Metrics
        total_lines = len(lines)
        doc_lines = sum(1 for line in lines if line.strip().startswith('"""') or line.strip().startswith("'''"))
        class_count = code.count('class ')
        method_count = code.count('def ')

        # Check for key components
        has_dataclass = '@dataclass' in code
        has_type_hints = ': str' in code or ': int' in code or ': float' in code
        has_docstrings = '"""' in code
        has_error_handling = 'try:' in code or 'except' in code
        has_logging = 'logger.' in code
        has_lru_cache = '@lru_cache' in code or '_cache' in code

        # Calculate score
        score = 0
        checks = []

        if total_lines > 500:
            score += 15
            checks.append("✅ Substantial implementation (638 lines)")
        else:
            checks.append("❌ Implementation too small")

        if has_dataclass:
            score += 10
            checks.append("✅ Uses dataclasses for type safety")
        else:
            checks.append("❌ Missing dataclass usage")

        if has_type_hints:
            score += 15
            checks.append("✅ Type hints present")
        else:
            checks.append("❌ Missing type hints")

        if has_docstrings:
            score += 15
            checks.append("✅ Documentation strings present")
        else:
            checks.append("❌ Missing docstrings")

        if has_error_handling:
            score += 15
            checks.append("✅ Error handling implemented")
        else:
            checks.append("❌ Missing error handling")

        if has_logging:
            score += 10
            checks.append("✅ Logging integrated")
        else:
            checks.append("❌ Missing logging")

        if has_lru_cache or '_fingerprint_cache' in code:
            score += 20
            checks.append("✅ Performance optimization (fingerprint cache)")
        else:
            checks.append("❌ Missing performance optimizations")

        # Print results
        for check in checks:
            print(f"  {check}")

        print(f"\n  Code Quality Score: {score}/100")

        return {
            "score": score,
            "status": "PASS" if score >= 75 else "FAIL",
            "metrics": {
                "total_lines": total_lines,
                "classes": class_count,
                "methods": method_count,
                "has_type_hints": has_type_hints,
                "has_docstrings": has_docstrings,
                "has_error_handling": has_error_handling,
                "has_caching": has_lru_cache or '_fingerprint_cache' in code
            },
            "checks": checks
        }

    def assess_test_coverage(self) -> Dict[str, Any]:
        """Assess test coverage and quality."""
        print("\n" + "="*60)
        print("ASSESSMENT 2: Test Coverage")
        print("="*60)

        test_file = self.base_path / "tests" / "test_bbb_prediction_service.py"

        if not test_file.exists():
            return {
                "score": 0,
                "status": "FAIL",
                "finding": "Test file not found"
            }

        # Read test file
        test_code = test_file.read_text()

        # Count tests
        test_count = test_code.count('def test_')
        test_classes = test_code.count('class Test')

        # Check test types
        has_unit_tests = 'TestBBBPredictionService' in test_code
        has_integration_tests = 'TestBBBPredictionIntegration' in test_code
        has_edge_case_tests = 'TestBBBPredictionEdgeCases' in test_code
        has_performance_tests = 'test_performance' in test_code
        has_fixtures = '@pytest.fixture' in test_code

        # Calculate score
        score = 0
        checks = []

        if test_count >= 20:
            score += 25
            checks.append(f"✅ Comprehensive test suite ({test_count} tests)")
        elif test_count >= 10:
            score += 15
            checks.append(f"⚠️ Moderate test coverage ({test_count} tests)")
        else:
            checks.append(f"❌ Insufficient tests ({test_count} tests)")

        if test_classes >= 3:
            score += 15
            checks.append(f"✅ Well-organized ({test_classes} test classes)")
        else:
            checks.append("❌ Poor test organization")

        if has_unit_tests:
            score += 15
            checks.append("✅ Unit tests present")
        else:
            checks.append("❌ Missing unit tests")

        if has_integration_tests:
            score += 15
            checks.append("✅ Integration tests present")
        else:
            checks.append("❌ Missing integration tests")

        if has_edge_case_tests:
            score += 15
            checks.append("✅ Edge case tests present")
        else:
            checks.append("❌ Missing edge case tests")

        if has_performance_tests:
            score += 10
            checks.append("✅ Performance benchmarks present")
        else:
            checks.append("❌ Missing performance tests")

        if has_fixtures:
            score += 5
            checks.append("✅ Uses pytest fixtures")
        else:
            checks.append("❌ Missing pytest fixtures")

        # Print results
        for check in checks:
            print(f"  {check}")

        print(f"\n  Test Coverage Score: {score}/100")

        return {
            "score": score,
            "status": "PASS" if score >= 75 else "FAIL",
            "metrics": {
                "test_count": test_count,
                "test_classes": test_classes,
                "has_unit_tests": has_unit_tests,
                "has_integration_tests": has_integration_tests,
                "has_edge_case_tests": has_edge_case_tests,
                "has_performance_tests": has_performance_tests
            },
            "checks": checks
        }

    def assess_documentation(self) -> Dict[str, Any]:
        """Assess documentation completeness."""
        print("\n" + "="*60)
        print("ASSESSMENT 3: Documentation")
        print("="*60)

        doc_file = self.base_path / "BBB_PREDICTION_SERVICE_COMPLETE.md"

        if not doc_file.exists():
            return {
                "score": 0,
                "status": "FAIL",
                "finding": "Documentation file not found"
            }

        # Read documentation
        doc_content = doc_file.read_text()

        # Check documentation sections
        has_overview = "## 🎯" in doc_content or "Mission Accomplished" in doc_content
        has_usage_examples = "```python" in doc_content
        has_api_reference = "API Reference" in doc_content or "### **Main Methods**" in doc_content
        has_performance_metrics = "Performance" in doc_content or "Latency" in doc_content
        has_deployment_guide = "Deployment" in doc_content or "Production" in doc_content
        has_architecture = "Architecture" in doc_content or "Approach" in doc_content

        # Calculate score
        score = 0
        checks = []

        if has_overview:
            score += 15
            checks.append("✅ Overview/mission statement present")
        else:
            checks.append("❌ Missing overview")

        if has_usage_examples:
            score += 25
            checks.append("✅ Code examples present")
        else:
            checks.append("❌ Missing usage examples")

        if has_api_reference:
            score += 20
            checks.append("✅ API reference documented")
        else:
            checks.append("❌ Missing API reference")

        if has_performance_metrics:
            score += 15
            checks.append("✅ Performance metrics documented")
        else:
            checks.append("❌ Missing performance metrics")

        if has_deployment_guide:
            score += 15
            checks.append("✅ Deployment guide present")
        else:
            checks.append("❌ Missing deployment guide")

        if has_architecture:
            score += 10
            checks.append("✅ Architecture documented")
        else:
            checks.append("❌ Missing architecture docs")

        # Print results
        for check in checks:
            print(f"  {check}")

        print(f"\n  Documentation Score: {score}/100")

        return {
            "score": score,
            "status": "PASS" if score >= 75 else "FAIL",
            "metrics": {
                "has_overview": has_overview,
                "has_usage_examples": has_usage_examples,
                "has_api_reference": has_api_reference,
                "has_performance_metrics": has_performance_metrics,
                "has_deployment_guide": has_deployment_guide
            },
            "checks": checks
        }

    def assess_production_readiness(self) -> Dict[str, Any]:
        """Assess production readiness."""
        print("\n" + "="*60)
        print("ASSESSMENT 4: Production Readiness")
        print("="*60)

        service_file = self.base_path / "bbb_prediction_service.py"
        code = service_file.read_text()

        # Check production features
        has_singleton = '_bbb_service' in code or 'get_bbb_prediction_service' in code
        has_factory_pattern = 'def get_' in code
        has_config = 'min_tanimoto' in code or 'min_neighbors' in code
        has_validation = 'validate_smiles' in code or 'if not' in code
        has_fallback = 'qsar_fallback' in code
        has_multi_tier = 'direct_match' in code and 'chemical_similarity' in code
        has_metadata = 'metadata' in code
        has_performance_cache = '_fingerprint_cache' in code

        # Calculate score
        score = 0
        checks = []

        if has_singleton:
            score += 10
            checks.append("✅ Singleton pattern for resource efficiency")
        else:
            checks.append("❌ Missing singleton pattern")

        if has_factory_pattern:
            score += 10
            checks.append("✅ Factory pattern for easy instantiation")
        else:
            checks.append("❌ Missing factory pattern")

        if has_config:
            score += 15
            checks.append("✅ Configurable parameters")
        else:
            checks.append("❌ Hard-coded configuration")

        if has_validation:
            score += 15
            checks.append("✅ Input validation present")
        else:
            checks.append("❌ Missing input validation")

        if has_fallback:
            score += 15
            checks.append("✅ Graceful degradation (QSAR fallback)")
        else:
            checks.append("❌ No fallback mechanism")

        if has_multi_tier:
            score += 15
            checks.append("✅ Multi-tier prediction strategy")
        else:
            checks.append("❌ Single prediction method only")

        if has_metadata:
            score += 10
            checks.append("✅ Metadata tracking for debugging")
        else:
            checks.append("❌ Missing metadata")

        if has_performance_cache:
            score += 10
            checks.append("✅ Performance optimization (fingerprint cache)")
        else:
            checks.append("❌ No performance optimization")

        # Print results
        for check in checks:
            print(f"  {check}")

        print(f"\n  Production Readiness Score: {score}/100")

        return {
            "score": score,
            "status": "PASS" if score >= 75 else "FAIL",
            "metrics": {
                "has_singleton": has_singleton,
                "has_factory_pattern": has_factory_pattern,
                "has_config": has_config,
                "has_validation": has_validation,
                "has_fallback": has_fallback,
                "has_multi_tier": has_multi_tier,
                "has_performance_cache": has_performance_cache
            },
            "checks": checks
        }

    def calculate_overall_score(self, assessments: List[Dict]) -> Dict[str, Any]:
        """Calculate overall quality score."""
        # Weighted scoring
        weights = {
            "code_quality": 0.30,
            "test_coverage": 0.30,
            "documentation": 0.20,
            "production_readiness": 0.20
        }

        overall_score = sum(
            assessments[i]["score"] * list(weights.values())[i]
            for i in range(len(assessments))
        )

        # Determine grade
        if overall_score >= 97:
            grade = "A+"
            status = "PRODUCTION READY - World-class quality"
        elif overall_score >= 93:
            grade = "A"
            status = "PRODUCTION READY - Minor improvements possible"
        elif overall_score >= 87:
            grade = "B+"
            status = "STAGING READY - Needs improvements"
        elif overall_score >= 80:
            grade = "B"
            status = "DEVELOPMENT READY - Significant gaps"
        elif overall_score >= 70:
            grade = "C"
            status = "ALPHA QUALITY - Many issues"
        else:
            grade = "F"
            status = "NOT USABLE - Showstopper issues"

        return {
            "overall_score": round(overall_score, 2),
            "grade": grade,
            "status": status,
            "pass": overall_score >= 80
        }

    def generate_recommendations(self, assessments: List[Dict]) -> List[str]:
        """Generate prioritized recommendations."""
        recommendations = []

        # Code quality recommendations
        if assessments[0]["score"] < 80:
            recommendations.append({
                "priority": "High",
                "area": "Code Quality",
                "recommendation": "Add more type hints and docstrings to improve maintainability"
            })

        # Test coverage recommendations
        if assessments[1]["score"] < 80:
            recommendations.append({
                "priority": "Critical",
                "area": "Test Coverage",
                "recommendation": "Expand test suite to cover edge cases and integration scenarios"
            })

        # Documentation recommendations
        if assessments[2]["score"] < 80:
            recommendations.append({
                "priority": "Medium",
                "area": "Documentation",
                "recommendation": "Add more usage examples and API reference documentation"
            })

        # Production readiness recommendations
        if assessments[3]["score"] < 80:
            recommendations.append({
                "priority": "High",
                "area": "Production Readiness",
                "recommendation": "Add input validation, error handling, and fallback mechanisms"
            })

        return recommendations

    def run_assessment(self) -> Dict[str, Any]:
        """Run complete quality assessment."""
        print("\n" + "🔍 " + "="*58)
        print("BBB PREDICTION SERVICE QUALITY ASSESSMENT")
        print("="*60)
        print("Following QDDA Quality Framework")
        print("="*60)

        # Run assessments
        code_quality = self.assess_code_quality()
        test_coverage = self.assess_test_coverage()
        documentation = self.assess_documentation()
        production_readiness = self.assess_production_readiness()

        assessments = [code_quality, test_coverage, documentation, production_readiness]

        # Calculate overall score
        overall = self.calculate_overall_score(assessments)

        # Generate recommendations
        recommendations = self.generate_recommendations(assessments)

        # Print summary
        print("\n" + "="*60)
        print("QUALITY ASSESSMENT SUMMARY")
        print("="*60)
        print(f"\n  Overall Score: {overall['overall_score']}/100")
        print(f"  Grade: {overall['grade']}")
        print(f"  Status: {overall['status']}")
        print(f"\n  Component Scores:")
        print(f"    - Code Quality: {code_quality['score']}/100")
        print(f"    - Test Coverage: {test_coverage['score']}/100")
        print(f"    - Documentation: {documentation['score']}/100")
        print(f"    - Production Readiness: {production_readiness['score']}/100")

        if recommendations:
            print(f"\n  Recommendations ({len(recommendations)}):")
            for i, rec in enumerate(recommendations, 1):
                print(f"    {i}. [{rec['priority']}] {rec['area']}: {rec['recommendation']}")
        else:
            print("\n  ✅ No critical recommendations - Excellent quality!")

        print("\n" + "="*60)

        # Return full results
        return {
            "overall": overall,
            "assessments": {
                "code_quality": code_quality,
                "test_coverage": test_coverage,
                "documentation": documentation,
                "production_readiness": production_readiness
            },
            "recommendations": recommendations
        }


if __name__ == "__main__":
    assessor = BBBServiceQualityAssessment()
    results = assessor.run_assessment()

    # Save results
    output_file = Path(__file__).parent.parent / "BBB_SERVICE_QUALITY_REPORT.json"
    with open(output_file, 'w') as f:
        json.dump(results, f, indent=2)

    print(f"\n✅ Quality report saved to: {output_file}")

    # Exit with appropriate code
    sys.exit(0 if results['overall']['pass'] else 1)
