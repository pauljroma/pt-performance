#!/usr/bin/env python3
"""
Schema Validation Script for PT Performance iOS App

Compares Swift model CodingKeys against Supabase database schema to detect mismatches.
This prevents runtime decoding errors like those encountered in Build 44.

Usage:
    python3 scripts/validate_ios_schema.py [--fix] [--verbose]

Exit Codes:
    0 - All schemas match
    1 - Mismatches detected (blocking)
    2 - Warnings only (non-blocking)
"""

import os
import re
import sys
import json
import subprocess
from typing import Dict, List, Set, Tuple, Optional
from dataclasses import dataclass
from enum import Enum

# Color codes for terminal output
class Color:
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    BOLD = '\033[1m'
    END = '\033[0m'

class Severity(Enum):
    ERROR = "error"
    WARNING = "warning"
    INFO = "info"

@dataclass
class SchemaMismatch:
    """Represents a schema mismatch between iOS and database."""
    table_name: str
    model_name: str
    mismatch_type: str
    details: str
    severity: Severity
    remediation: str

@dataclass
class SwiftModel:
    """Represents a Swift model with its properties."""
    name: str
    file_path: str
    properties: Dict[str, str]  # property_name -> type
    coding_keys: Dict[str, str]  # swift_property -> database_column
    optional_properties: Set[str]  # Properties that are Optional<T>

@dataclass
class DatabaseTable:
    """Represents a database table schema."""
    name: str
    columns: Dict[str, str]  # column_name -> data_type
    nullable_columns: Set[str]
    primary_key: Optional[str]

class SchemaValidator:
    """Main validator class."""

    def __init__(self, verbose: bool = False):
        self.verbose = verbose
        self.mismatches: List[SchemaMismatch] = []
        self.models: Dict[str, SwiftModel] = {}
        self.tables: Dict[str, DatabaseTable] = {}

        # Model to table mapping (some models map to different table names)
        self.model_to_table_map = {
            "Patient": "patients",
            "Program": "programs",
            "Phase": "phases",
            "Session": "sessions",
            "Exercise": "exercises",
            "ExerciseLog": "exercise_logs",
            "WorkloadFlag": "workload_flags",
            "DailyReadiness": "daily_readiness",
            "SessionNote": "session_notes",
            "PatientFlag": "patient_flags",
            "Protocol": "protocols",
            "DeloadEvent": "deload_events",
            "LoadProgression": "load_progressions",
            "PhaseAdvancement": "phase_advancements",
        }

    def log(self, message: str, color: str = ""):
        """Log a message with optional color."""
        if self.verbose:
            print(f"{color}{message}{Color.END}" if color else message)

    def parse_swift_models(self, models_dir: str) -> None:
        """Parse all Swift model files."""
        self.log(f"\n{Color.BLUE}Parsing Swift models from {models_dir}...{Color.END}")

        for filename in os.listdir(models_dir):
            if not filename.endswith('.swift'):
                continue

            filepath = os.path.join(models_dir, filename)
            model = self._parse_swift_file(filepath)

            if model:
                self.models[model.name] = model
                self.log(f"  ✓ Parsed {model.name} ({len(model.coding_keys)} properties)")

    def _parse_swift_file(self, filepath: str) -> Optional[SwiftModel]:
        """Parse a single Swift file to extract model information."""
        with open(filepath, 'r') as f:
            content = f.read()

        # Extract struct name
        struct_match = re.search(r'struct\s+(\w+)\s*:', content)
        if not struct_match:
            return None

        model_name = struct_match.group(1)

        # Skip sample/test models
        if 'Sample' in model_name or 'Test' in model_name or 'Mock' in model_name:
            return None

        # Extract properties
        properties = {}
        optional_properties = set()

        # Match: let propertyName: Type or var propertyName: Type
        property_pattern = r'(?:let|var)\s+(\w+):\s*([^\s=\n{]+)'
        for match in re.finditer(property_pattern, content):
            prop_name = match.group(1)
            prop_type = match.group(2).strip()

            # Skip computed properties (those with { after type)
            if '{' in prop_type:
                continue

            properties[prop_name] = prop_type

            if '?' in prop_type:
                optional_properties.add(prop_name)

        # Extract CodingKeys enum
        coding_keys = {}

        # Find CodingKeys enum
        coding_keys_match = re.search(
            r'enum\s+CodingKeys:\s*String,\s*CodingKey\s*\{(.*?)\}',
            content,
            re.DOTALL
        )

        if coding_keys_match:
            coding_keys_content = coding_keys_match.group(1)

            # Match: case swiftName = "database_column"
            for match in re.finditer(r'case\s+(\w+)\s*=\s*"([^"]+)"', coding_keys_content):
                swift_name = match.group(1)
                db_column = match.group(2)
                coding_keys[swift_name] = db_column

            # Match: case columnName (when same as database)
            for match in re.finditer(r'case\s+(\w+)\s*$', coding_keys_content, re.MULTILINE):
                column_name = match.group(1)
                if column_name not in coding_keys:
                    coding_keys[column_name] = column_name

        return SwiftModel(
            name=model_name,
            file_path=filepath,
            properties=properties,
            coding_keys=coding_keys,
            optional_properties=optional_properties
        )

    def query_database_schema(self) -> None:
        """Query Supabase database schema."""
        self.log(f"\n{Color.BLUE}Querying database schema...{Color.END}")

        # Get database connection info from environment
        db_url = os.getenv('SUPABASE_DB_URL')
        if not db_url:
            self.log(f"{Color.YELLOW}Warning: SUPABASE_DB_URL not set, using .env file{Color.END}")
            # Try to load from clients/linear-bootstrap/.env
            env_path = os.path.join(os.getcwd(), 'clients', 'linear-bootstrap', '.env')
            if os.path.exists(env_path):
                with open(env_path) as f:
                    for line in f:
                        if line.startswith('SUPABASE_DB_URL'):
                            db_url = line.split('=', 1)[1].strip().strip('"')
                            break

        if not db_url:
            self.log(f"{Color.RED}Error: Cannot find database connection{Color.END}")
            sys.exit(1)

        # Query information_schema for all tables
        query = """
        SELECT
            table_name,
            column_name,
            data_type,
            is_nullable,
            column_default
        FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name IN (
            'patients', 'programs', 'phases', 'sessions', 'exercises',
            'exercise_logs', 'workload_flags', 'daily_readiness',
            'session_notes', 'patient_flags', 'protocols',
            'deload_events', 'load_progressions', 'phase_advancements'
        )
        ORDER BY table_name, ordinal_position;
        """

        try:
            # Use psql command to query database
            result = subprocess.run(
                ['psql', db_url, '-t', '-A', '-F,', '-c', query],
                capture_output=True,
                text=True,
                check=True
            )

            # Parse results
            current_table = None

            for line in result.stdout.strip().split('\n'):
                if not line:
                    continue

                parts = line.split(',')
                if len(parts) < 5:
                    continue

                table_name, column_name, data_type, is_nullable, column_default = parts

                if table_name not in self.tables:
                    self.tables[table_name] = DatabaseTable(
                        name=table_name,
                        columns={},
                        nullable_columns=set(),
                        primary_key=None
                    )

                self.tables[table_name].columns[column_name] = data_type

                if is_nullable == 'YES':
                    self.tables[table_name].nullable_columns.add(column_name)

            self.log(f"  ✓ Found {len(self.tables)} tables")

        except subprocess.CalledProcessError as e:
            self.log(f"{Color.RED}Error querying database: {e}{Color.END}")
            self.log(f"{Color.YELLOW}Stderr: {e.stderr}{Color.END}")
            sys.exit(1)
        except FileNotFoundError:
            self.log(f"{Color.RED}Error: psql command not found{Color.END}")
            self.log(f"{Color.YELLOW}Install PostgreSQL client tools or use alternative connection method{Color.END}")
            sys.exit(1)

    def validate_schemas(self) -> None:
        """Compare Swift models against database schema."""
        self.log(f"\n{Color.BLUE}Validating schemas...{Color.END}")

        for model_name, model in self.models.items():
            # Get corresponding table name
            table_name = self.model_to_table_map.get(model_name)

            if not table_name:
                self.log(f"  {Color.YELLOW}⚠ No table mapping for model {model_name}{Color.END}")
                continue

            if table_name not in self.tables:
                self.mismatches.append(SchemaMismatch(
                    table_name=table_name,
                    model_name=model_name,
                    mismatch_type="missing_table",
                    details=f"Table '{table_name}' not found in database",
                    severity=Severity.ERROR,
                    remediation=f"Create table '{table_name}' in database or update model_to_table_map"
                ))
                continue

            table = self.tables[table_name]
            self.log(f"  Checking {model_name} -> {table_name}")

            # Check each property in the model
            for swift_prop, db_column in model.coding_keys.items():
                if db_column not in table.columns:
                    self.mismatches.append(SchemaMismatch(
                        table_name=table_name,
                        model_name=model_name,
                        mismatch_type="missing_column",
                        details=f"Column '{db_column}' expected by Swift property '{swift_prop}' not found in table",
                        severity=Severity.ERROR,
                        remediation=f"Add column '{db_column}' to table '{table_name}' or update CodingKeys mapping"
                    ))
                    continue

                # Check nullability mismatch
                is_optional_in_swift = swift_prop in model.optional_properties
                is_nullable_in_db = db_column in table.nullable_columns

                if not is_optional_in_swift and is_nullable_in_db:
                    self.mismatches.append(SchemaMismatch(
                        table_name=table_name,
                        model_name=model_name,
                        mismatch_type="nullability_mismatch",
                        details=f"Column '{db_column}' is nullable in DB but non-optional in Swift ({swift_prop}: {model.properties.get(swift_prop)})",
                        severity=Severity.ERROR,
                        remediation=f"Either make Swift property optional ('{swift_prop}?') or add NOT NULL constraint to database column"
                    ))

                # Note: Type checking is complex (Swift String vs PostgreSQL text/varchar)
                # We skip detailed type checking for now

            # Check for columns in DB that aren't in Swift model
            for db_column in table.columns:
                # Skip system columns
                if db_column in ['created_at', 'updated_at'] and db_column not in [v for v in model.coding_keys.values()]:
                    continue

                if db_column not in model.coding_keys.values():
                    # This is a warning, not an error (DB can have extra columns)
                    self.mismatches.append(SchemaMismatch(
                        table_name=table_name,
                        model_name=model_name,
                        mismatch_type="extra_column",
                        details=f"Column '{db_column}' exists in database but not in Swift model",
                        severity=Severity.WARNING,
                        remediation=f"Add property to Swift model or remove column from database (if unused)"
                    ))

    def generate_report(self) -> None:
        """Generate validation report."""
        print(f"\n{'='*80}")
        print(f"{Color.BOLD}Schema Validation Report{Color.END}")
        print(f"{'='*80}\n")

        errors = [m for m in self.mismatches if m.severity == Severity.ERROR]
        warnings = [m for m in self.mismatches if m.severity == Severity.WARNING]

        print(f"Models checked: {len(self.models)}")
        print(f"Tables checked: {len(self.tables)}")
        print(f"Errors: {Color.RED}{len(errors)}{Color.END}")
        print(f"Warnings: {Color.YELLOW}{len(warnings)}{Color.END}")

        if errors:
            print(f"\n{Color.RED}{Color.BOLD}❌ ERRORS (Blocking):{Color.END}\n")
            for i, mismatch in enumerate(errors, 1):
                print(f"{i}. {Color.RED}[{mismatch.mismatch_type.upper()}]{Color.END} {mismatch.model_name} -> {mismatch.table_name}")
                print(f"   {mismatch.details}")
                print(f"   {Color.BLUE}Fix:{Color.END} {mismatch.remediation}\n")

        if warnings:
            print(f"\n{Color.YELLOW}{Color.BOLD}⚠️  WARNINGS (Non-blocking):{Color.END}\n")
            for i, mismatch in enumerate(warnings, 1):
                print(f"{i}. {Color.YELLOW}[{mismatch.mismatch_type.upper()}]{Color.END} {mismatch.model_name} -> {mismatch.table_name}")
                print(f"   {mismatch.details}")
                print(f"   {Color.BLUE}Suggestion:{Color.END} {mismatch.remediation}\n")

        if not errors and not warnings:
            print(f"\n{Color.GREEN}{Color.BOLD}✅ All schemas match!{Color.END}\n")

        print(f"{'='*80}\n")

    def get_exit_code(self) -> int:
        """Get appropriate exit code based on results."""
        errors = [m for m in self.mismatches if m.severity == Severity.ERROR]
        warnings = [m for m in self.mismatches if m.severity == Severity.WARNING]

        if errors:
            return 1  # Blocking errors
        elif warnings:
            return 2  # Warnings only
        else:
            return 0  # All good

def main():
    """Main entry point."""
    import argparse

    parser = argparse.ArgumentParser(description='Validate iOS schema against database')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')
    parser.add_argument('--fix', action='store_true', help='Attempt to auto-fix issues (not implemented)')

    args = parser.parse_args()

    # Initialize validator
    validator = SchemaValidator(verbose=args.verbose)

    # Find models directory
    models_dir = os.path.join(os.getcwd(), 'ios-app', 'PTPerformance', 'Models')

    if not os.path.exists(models_dir):
        # Try from clients/linear-bootstrap
        models_dir = os.path.join(os.getcwd(), 'clients', 'linear-bootstrap', 'ios-app', 'PTPerformance', 'Models')

    if not os.path.exists(models_dir):
        print(f"{Color.RED}Error: Cannot find Models directory{Color.END}")
        print(f"Looked in: {models_dir}")
        sys.exit(1)

    # Parse Swift models
    validator.parse_swift_models(models_dir)

    # Query database
    validator.query_database_schema()

    # Validate
    validator.validate_schemas()

    # Generate report
    validator.generate_report()

    # Exit with appropriate code
    sys.exit(validator.get_exit_code())

if __name__ == '__main__':
    main()
