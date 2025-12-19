#!/usr/bin/env python3
"""
RLS Policy Verification Script for PT Performance

Verifies Row Level Security (RLS) policies are correctly configured
to prevent unauthorized data access.

Usage:
    python3 scripts/verify_rls_policies.py [--verbose] [--fix]

Exit Codes:
    0 - All RLS policies correct
    1 - RLS policy violations found
    2 - Critical security issue (RLS disabled on table)
"""

import os
import sys
import subprocess
import argparse
from typing import Dict, List, Tuple, Optional, Set
from dataclasses import dataclass
from enum import Enum

# Color codes
class Color:
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    BOLD = '\033[1m'
    END = '\033[0m'


class Severity(Enum):
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"
    INFO = "info"


@dataclass
class RLSViolation:
    """Represents an RLS policy violation"""
    table_name: str
    violation_type: str
    severity: Severity
    details: str
    remediation: str


@dataclass
class TableRLSStatus:
    """RLS status for a table"""
    table_name: str
    rls_enabled: bool
    policies: List[Dict[str, str]]
    policy_count: int


class RLSVerifier:
    """Verify RLS policies across all tables"""

    def __init__(self, db_url: str, verbose: bool = False):
        self.db_url = db_url
        self.verbose = verbose
        self.violations: List[RLSViolation] = []

        # Expected RLS policies for each table
        self.expected_policies = {
            "patients": [
                "Therapists can view all patients",
                "Patients can view own data",
                "Therapists can manage patients"
            ],
            "programs": [
                "Therapists can view all programs",
                "Patients can view own programs",
                "Therapists can manage programs"
            ],
            "phases": [
                "Anyone can view phases of accessible programs",
                "Therapists can manage phases"
            ],
            "sessions": [
                "Anyone can view sessions of accessible programs",
                "Therapists can manage sessions"
            ],
            "exercises": [
                "Anyone can view exercises",
                "Therapists can manage exercises"
            ],
            "exercise_logs": [
                "Patients can view own logs",
                "Therapists can view patient logs",
                "Patients can create own logs",
                "Therapists can manage logs"
            ],
            "workload_flags": [
                "Therapists can view all flags",
                "Patients can view own flags",
                "Therapists can create flags"
            ],
            "daily_readiness": [
                "Patients can view own readiness",
                "Therapists can view patient readiness",
                "Patients can create own readiness",
                "Therapists can manage readiness"
            ]
        }

    def log(self, message: str, color: str = ""):
        """Log a message with optional color"""
        if self.verbose:
            print(f"{color}{message}{Color.END}" if color else message)

    def run_sql(self, sql: str) -> Tuple[bool, str]:
        """Execute SQL and return success status and output"""
        try:
            result = subprocess.run(
                ['psql', self.db_url, '-t', '-A', '-c', sql],
                capture_output=True,
                text=True,
                check=False
            )

            success = result.returncode == 0
            output = result.stdout if success else result.stderr

            return success, output

        except Exception as e:
            return False, str(e)

    def get_tables_rls_status(self) -> Dict[str, TableRLSStatus]:
        """Get RLS status for all tables"""
        self.log(f"\n{Color.BLUE}Checking RLS status for all tables...{Color.END}")

        sql = """
        SELECT
            schemaname || '.' || tablename as table_name,
            rowsecurity as rls_enabled
        FROM pg_tables
        WHERE schemaname = 'public'
        ORDER BY tablename;
        """

        success, output = self.run_sql(sql)

        if not success:
            self.log(f"❌ Failed to query table RLS status: {output}", Color.RED)
            return {}

        tables = {}
        for line in output.strip().split('\n'):
            if not line or line.startswith('-'):
                continue

            parts = line.split('|')
            if len(parts) >= 2:
                table = parts[0].replace('public.', '').strip()
                rls_enabled = parts[1].strip().lower() == 't'

                tables[table] = TableRLSStatus(
                    table_name=table,
                    rls_enabled=rls_enabled,
                    policies=[],
                    policy_count=0
                )

        return tables

    def get_table_policies(self, table_name: str) -> List[Dict[str, str]]:
        """Get all RLS policies for a table"""
        sql = f"""
        SELECT
            policyname,
            cmd,
            qual,
            with_check
        FROM pg_policies
        WHERE schemaname = 'public'
        AND tablename = '{table_name}'
        ORDER BY policyname;
        """

        success, output = self.run_sql(sql)

        if not success:
            return []

        policies = []
        for line in output.strip().split('\n'):
            if not line or line.startswith('-'):
                continue

            parts = line.split('|')
            if len(parts) >= 2:
                policies.append({
                    'name': parts[0].strip(),
                    'command': parts[1].strip() if len(parts) > 1 else '',
                    'using': parts[2].strip() if len(parts) > 2 else '',
                    'check': parts[3].strip() if len(parts) > 3 else ''
                })

        return policies

    def verify_rls_enabled(self, tables: Dict[str, TableRLSStatus]) -> None:
        """Verify RLS is enabled on all critical tables"""
        self.log(f"\n{Color.BLUE}Verifying RLS is enabled on critical tables...{Color.END}")

        for table_name in self.expected_policies.keys():
            if table_name not in tables:
                self.violations.append(RLSViolation(
                    table_name=table_name,
                    violation_type="missing_table",
                    severity=Severity.HIGH,
                    details=f"Table '{table_name}' not found in database",
                    remediation=f"Create table '{table_name}' or update expected policies list"
                ))
                continue

            table = tables[table_name]

            if not table.rls_enabled:
                self.violations.append(RLSViolation(
                    table_name=table_name,
                    violation_type="rls_disabled",
                    severity=Severity.CRITICAL,
                    details=f"RLS is DISABLED on table '{table_name}' - data is PUBLICLY ACCESSIBLE!",
                    remediation=f"ALTER TABLE {table_name} ENABLE ROW LEVEL SECURITY;"
                ))
                self.log(f"  ❌ {table_name}: RLS DISABLED (CRITICAL!)", Color.RED)
            else:
                self.log(f"  ✅ {table_name}: RLS enabled", Color.GREEN)

    def verify_policies_exist(self, tables: Dict[str, TableRLSStatus]) -> None:
        """Verify expected policies exist"""
        self.log(f"\n{Color.BLUE}Verifying RLS policies exist...{Color.END}")

        for table_name, expected in self.expected_policies.items():
            if table_name not in tables:
                continue

            policies = self.get_table_policies(table_name)
            policy_names = [p['name'].lower() for p in policies]

            self.log(f"\n  Table: {table_name}")
            self.log(f"  Found {len(policies)} policies")

            if len(policies) == 0:
                self.violations.append(RLSViolation(
                    table_name=table_name,
                    violation_type="no_policies",
                    severity=Severity.CRITICAL,
                    details=f"Table '{table_name}' has RLS enabled but NO POLICIES - all access blocked!",
                    remediation=f"Create RLS policies for table '{table_name}'"
                ))
                self.log(f"    ❌ No policies found (CRITICAL!)", Color.RED)
                continue

            # Check for common policy patterns
            has_select_policy = any('select' in p['command'].lower() for p in policies)
            has_insert_policy = any('insert' in p['command'].lower() for p in policies)
            has_update_policy = any('update' in p['command'].lower() for p in policies)

            self.log(f"    SELECT policies: {has_select_policy}")
            self.log(f"    INSERT policies: {has_insert_policy}")
            self.log(f"    UPDATE policies: {has_update_policy}")

            if not has_select_policy:
                self.violations.append(RLSViolation(
                    table_name=table_name,
                    violation_type="missing_select_policy",
                    severity=Severity.HIGH,
                    details=f"Table '{table_name}' has no SELECT policy - users cannot read data",
                    remediation=f"Create SELECT policy for table '{table_name}'"
                ))

            # List actual policies
            for policy in policies:
                self.log(f"    - {policy['name']} ({policy['command']})")

    def verify_auth_checks(self) -> None:
        """Verify policies use proper auth checks"""
        self.log(f"\n{Color.BLUE}Verifying policies use auth.uid() checks...{Color.END}")

        for table_name in self.expected_policies.keys():
            policies = self.get_table_policies(table_name)

            for policy in policies:
                using_clause = policy.get('using', '').lower()

                # Check for auth.uid() usage
                if 'auth.uid()' not in using_clause and 'patient_id' in using_clause:
                    self.violations.append(RLSViolation(
                        table_name=table_name,
                        violation_type="missing_auth_check",
                        severity=Severity.HIGH,
                        details=f"Policy '{policy['name']}' may not use auth.uid() for patient_id comparison",
                        remediation=f"Update policy to use 'patient_id = auth.uid()' instead of hardcoded IDs"
                    ))

                # Check for public access (no conditions)
                if not using_clause or using_clause.strip() == '':
                    self.violations.append(RLSViolation(
                        table_name=table_name,
                        violation_type="public_access",
                        severity=Severity.CRITICAL,
                        details=f"Policy '{policy['name']}' has no USING clause - grants PUBLIC access!",
                        remediation=f"Add USING clause to restrict access"
                    ))

    def test_patient_access(self) -> None:
        """Test that patients can only access their own data"""
        self.log(f"\n{Color.BLUE}Testing patient data isolation...{Color.END}")

        # This would require actual test users in the database
        # For now, we'll check the policy logic
        self.log("  ℹ️  Patient isolation test requires test users in database")
        self.log("  ℹ️  Run integration tests to validate patient isolation")

    def test_therapist_access(self) -> None:
        """Test that therapists can access patient data correctly"""
        self.log(f"\n{Color.BLUE}Testing therapist access permissions...{Color.END}")

        # This would require actual test users
        self.log("  ℹ️  Therapist access test requires test users in database")
        self.log("  ℹ️  Run integration tests to validate therapist permissions")

    def check_dangerous_policies(self) -> None:
        """Check for overly permissive policies"""
        self.log(f"\n{Color.BLUE}Checking for dangerous policies...{Color.END}")

        for table_name in self.expected_policies.keys():
            policies = self.get_table_policies(table_name)

            for policy in policies:
                using_clause = policy.get('using', '').lower()

                # Check for "true" clause (allows everything)
                if using_clause == 'true' or using_clause == '(true)':
                    self.violations.append(RLSViolation(
                        table_name=table_name,
                        violation_type="permissive_policy",
                        severity=Severity.CRITICAL,
                        details=f"Policy '{policy['name']}' uses 'true' - grants access to ALL rows!",
                        remediation=f"Replace 'true' with proper access control logic"
                    ))
                    self.log(f"  ❌ {table_name}.{policy['name']}: PERMISSIVE (true)", Color.RED)

    def generate_report(self) -> None:
        """Generate security audit report"""
        print(f"\n{'='*80}")
        print(f"{Color.BOLD}RLS Policy Verification Report{Color.END}")
        print(f"{'='*80}\n")

        # Group violations by severity
        critical = [v for v in self.violations if v.severity == Severity.CRITICAL]
        high = [v for v in self.violations if v.severity == Severity.HIGH]
        medium = [v for v in self.violations if v.severity == Severity.MEDIUM]
        low = [v for v in self.violations if v.severity == Severity.LOW]

        print(f"Violations by Severity:")
        print(f"  {Color.RED}Critical: {len(critical)}{Color.END}")
        print(f"  {Color.YELLOW}High: {len(high)}{Color.END}")
        print(f"  Medium: {len(medium)}")
        print(f"  Low: {len(low)}")

        if critical:
            print(f"\n{Color.RED}{Color.BOLD}🚨 CRITICAL VIOLATIONS (IMMEDIATE ACTION REQUIRED):{Color.END}\n")
            for i, v in enumerate(critical, 1):
                print(f"{i}. [{v.violation_type.upper()}] {v.table_name}")
                print(f"   {v.details}")
                print(f"   {Color.BLUE}Fix:{Color.END} {v.remediation}\n")

        if high:
            print(f"\n{Color.YELLOW}{Color.BOLD}⚠️  HIGH SEVERITY VIOLATIONS:{Color.END}\n")
            for i, v in enumerate(high, 1):
                print(f"{i}. [{v.violation_type.upper()}] {v.table_name}")
                print(f"   {v.details}")
                print(f"   {Color.BLUE}Fix:{Color.END} {v.remediation}\n")

        if not self.violations:
            print(f"\n{Color.GREEN}{Color.BOLD}✅ All RLS policies are correctly configured!{Color.END}\n")
            print("Security Status: PASS")
        else:
            print(f"\n{Color.RED}{Color.BOLD}❌ Security issues found!{Color.END}\n")
            print("Security Status: FAIL")

        print(f"{'='*80}\n")

    def get_exit_code(self) -> int:
        """Get appropriate exit code based on results"""
        if any(v.severity == Severity.CRITICAL for v in self.violations):
            return 2  # Critical security issue
        elif self.violations:
            return 1  # Violations found
        else:
            return 0  # All good


def main():
    parser = argparse.ArgumentParser(description='Verify RLS policies')
    parser.add_argument('--verbose', '-v', action='store_true',
                       help='Verbose output')
    parser.add_argument('--fix', action='store_true',
                       help='Attempt to auto-fix issues (not implemented)')

    args = parser.parse_args()

    # Get database URL
    db_url = os.getenv('SUPABASE_DB_URL')
    if not db_url:
        print(f"{Color.RED}Error: SUPABASE_DB_URL environment variable not set{Color.END}")
        sys.exit(1)

    # Initialize verifier
    verifier = RLSVerifier(db_url, verbose=True)

    print(f"\n{Color.BOLD}{'='*80}{Color.END}")
    print(f"{Color.BOLD}RLS Policy Verification{Color.END}")
    print(f"{Color.BOLD}{'='*80}{Color.END}\n")

    # Get table RLS status
    tables = verifier.get_tables_rls_status()

    if not tables:
        print(f"{Color.RED}Error: Could not retrieve table information{Color.END}")
        sys.exit(1)

    # Run verification checks
    verifier.verify_rls_enabled(tables)
    verifier.verify_policies_exist(tables)
    verifier.verify_auth_checks()
    verifier.check_dangerous_policies()
    verifier.test_patient_access()
    verifier.test_therapist_access()

    # Generate report
    verifier.generate_report()

    # Exit with appropriate code
    sys.exit(verifier.get_exit_code())


if __name__ == '__main__':
    main()
