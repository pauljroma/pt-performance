#!/usr/bin/env python3
"""
Import workout markdown files from Obsidian format.

Parses markdown files with YAML frontmatter and structured workout blocks,
outputting JSONB structure and SQL INSERT statements.

Block Structure:
1. Cardio, 2. Dynamic Stretch, 3. Prehab, 4. Push, 5. Pull,
6. Hinge, 7. Lunge/Squat, 8. Functional, 9. Recovery

Expected Markdown Format:
---
tags: [strength, full-body, intermediate]
duration: 60
---

# Full Body Day A

## Cardio
- 5 min Row Machine

## Push
- Barbell Bench Press - 4x8-10 @ RPE 8

Usage:
    python import_obsidian_workouts.py /path/to/workouts
    python import_obsidian_workouts.py /path/to/workouts --sql-only
    python import_obsidian_workouts.py /path/to/workouts --json-only
    python import_obsidian_workouts.py /path/to/workouts --table my_workouts
"""

import argparse
import json
import os
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional


# Valid block names in order
VALID_BLOCKS = [
    "Cardio",
    "Dynamic Stretch",
    "Prehab",
    "Push",
    "Pull",
    "Hinge",
    "Lunge/Squat",
    "Functional",
    "Recovery",
]


@dataclass
class Exercise:
    """Represents a single exercise with its parameters."""

    name: str
    sets: Optional[int] = None
    reps: Optional[str] = None
    duration: Optional[str] = None
    rpe: Optional[int] = None
    each_side: bool = False
    notes: Optional[str] = None

    def to_dict(self) -> dict:
        """Convert to dictionary, excluding None values."""
        result = {"name": self.name}
        if self.sets is not None:
            result["sets"] = self.sets
        if self.reps is not None:
            result["reps"] = self.reps
        if self.duration is not None:
            result["duration"] = self.duration
        if self.rpe is not None:
            result["rpe"] = self.rpe
        if self.each_side:
            result["each_side"] = True
        if self.notes:
            result["notes"] = self.notes
        return result


@dataclass
class WorkoutBlock:
    """Represents a workout block (e.g., Push, Pull, Cardio)."""

    name: str
    exercises: list[Exercise] = field(default_factory=list)

    def to_dict(self) -> dict:
        """Convert to dictionary."""
        return {
            "name": self.name,
            "exercises": [ex.to_dict() for ex in self.exercises],
        }


@dataclass
class Workout:
    """Represents a complete workout with metadata and blocks."""

    name: str
    tags: list[str] = field(default_factory=list)
    duration: Optional[int] = None
    blocks: list[WorkoutBlock] = field(default_factory=list)

    def to_jsonb(self) -> dict:
        """Convert to JSONB structure."""
        return {"blocks": [block.to_dict() for block in self.blocks]}

    def to_full_dict(self) -> dict:
        """Convert to full dictionary including metadata."""
        return {
            "name": self.name,
            "tags": self.tags,
            "duration": self.duration,
            "content": self.to_jsonb(),
        }


def parse_yaml_frontmatter(content: str) -> tuple[dict, str]:
    """
    Parse YAML frontmatter from markdown content.

    Returns:
        Tuple of (frontmatter dict, remaining content)
    """
    frontmatter = {}
    remaining = content

    # Check for YAML frontmatter (starts with ---)
    if content.startswith("---"):
        parts = content.split("---", 2)
        if len(parts) >= 3:
            yaml_content = parts[1].strip()
            remaining = parts[2].strip()

            # Simple YAML parsing for our specific format
            for line in yaml_content.split("\n"):
                line = line.strip()
                if not line or ":" not in line:
                    continue

                key, value = line.split(":", 1)
                key = key.strip()
                value = value.strip()

                if key == "tags":
                    # Parse tags: [tag1, tag2, tag3] or tag1, tag2, tag3
                    if value.startswith("[") and value.endswith("]"):
                        value = value[1:-1]
                    frontmatter["tags"] = [
                        t.strip() for t in value.split(",") if t.strip()
                    ]
                elif key == "duration":
                    try:
                        frontmatter["duration"] = int(value)
                    except ValueError:
                        pass
                else:
                    frontmatter[key] = value

    return frontmatter, remaining


def parse_exercise_line(line: str) -> Optional[Exercise]:
    """
    Parse an exercise line into an Exercise object.

    Supports formats:
    - "Exercise Name - 3x10 @ RPE 8"
    - "Exercise Name - 3x8-10"
    - "Exercise Name - 5 min"
    - "Exercise Name - 3x10 each side"
    - "Exercise Name" (just the name)
    """
    # Remove leading bullet/dash and whitespace
    line = re.sub(r"^[-*]\s*", "", line.strip())

    if not line:
        return None

    exercise = Exercise(name="")

    # Check for "each side"
    if "each side" in line.lower():
        exercise.each_side = True
        line = re.sub(r"\s*each\s+side\s*", " ", line, flags=re.IGNORECASE)

    # Extract RPE (@ RPE 8 or @RPE8)
    rpe_match = re.search(r"@\s*RPE\s*(\d+)", line, re.IGNORECASE)
    if rpe_match:
        exercise.rpe = int(rpe_match.group(1))
        line = re.sub(r"\s*@\s*RPE\s*\d+\s*", " ", line, flags=re.IGNORECASE)

    # Split by " - " to separate name from parameters
    if " - " in line:
        parts = line.split(" - ", 1)
        exercise.name = parts[0].strip()
        params = parts[1].strip() if len(parts) > 1 else ""
    else:
        exercise.name = line.strip()
        params = ""

    if params:
        # Check for duration pattern (e.g., "5 min", "30 sec", "2 minutes")
        duration_match = re.search(
            r"(\d+)\s*(min|mins|minutes|sec|secs|seconds)", params, re.IGNORECASE
        )
        if duration_match:
            exercise.duration = f"{duration_match.group(1)} {duration_match.group(2)}"
        else:
            # Check for sets x reps pattern (e.g., "3x10", "4x8-10", "3 x 10")
            sets_reps_match = re.search(r"(\d+)\s*[xX]\s*(\d+(?:-\d+)?)", params)
            if sets_reps_match:
                exercise.sets = int(sets_reps_match.group(1))
                exercise.reps = sets_reps_match.group(2)

    # Clean up the name
    exercise.name = exercise.name.strip()

    return exercise if exercise.name else None


def parse_markdown_workout(content: str) -> Workout:
    """
    Parse a complete workout markdown file.

    Expected format:
    ---
    tags: [strength, full-body]
    duration: 60
    ---

    # Workout Name

    ## Block Name
    - Exercise 1 - 3x10
    - Exercise 2 - 4x8-10 @ RPE 8
    """
    # Parse frontmatter
    frontmatter, body = parse_yaml_frontmatter(content)

    workout = Workout(
        name="",
        tags=frontmatter.get("tags", []),
        duration=frontmatter.get("duration"),
    )

    current_block: Optional[WorkoutBlock] = None
    lines = body.split("\n")

    for line in lines:
        line_stripped = line.strip()

        # Skip empty lines
        if not line_stripped:
            continue

        # Check for workout name (# heading)
        if line_stripped.startswith("# ") and not line_stripped.startswith("## "):
            workout.name = line_stripped[2:].strip()
            continue

        # Check for block heading (## heading)
        if line_stripped.startswith("## "):
            block_name = line_stripped[3:].strip()
            current_block = WorkoutBlock(name=block_name)
            workout.blocks.append(current_block)
            continue

        # Check for exercise line (starts with - or *)
        if (line_stripped.startswith("-") or line_stripped.startswith("*")) and current_block:
            exercise = parse_exercise_line(line_stripped)
            if exercise:
                current_block.exercises.append(exercise)

    return workout


def generate_sql_insert(workout: Workout, table_name: str = "workouts") -> str:
    """Generate SQL INSERT statement for a workout."""
    tags_array = "ARRAY[" + ", ".join(f"'{t}'" for t in workout.tags) + "]::text[]"
    if not workout.tags:
        tags_array = "ARRAY[]::text[]"

    duration_value = workout.duration if workout.duration else "NULL"
    jsonb_content = json.dumps(workout.to_jsonb())

    sql = f"""INSERT INTO {table_name} (name, tags, duration_minutes, content)
VALUES (
    '{workout.name.replace("'", "''")}',
    {tags_array},
    {duration_value},
    '{jsonb_content}'::jsonb
);"""

    return sql


def process_directory(directory: Path, output_sql: bool = True, output_json: bool = True, table_name: str = "workouts") -> list[Workout]:
    """
    Process all markdown files in a directory.

    Args:
        directory: Path to directory containing markdown files
        output_sql: Whether to output SQL statements
        output_json: Whether to output JSON
        table_name: Name of the table for SQL INSERT statements

    Returns:
        List of parsed Workout objects
    """
    workouts = []

    if not directory.exists():
        print(f"Error: Directory '{directory}' does not exist", file=sys.stderr)
        return workouts

    md_files = list(directory.glob("*.md"))

    if not md_files:
        print(f"No markdown files found in '{directory}'", file=sys.stderr)
        return workouts

    for md_file in sorted(md_files):
        print(f"\n{'=' * 60}", file=sys.stderr)
        print(f"Processing: {md_file.name}", file=sys.stderr)
        print(f"{'=' * 60}", file=sys.stderr)

        content = md_file.read_text(encoding="utf-8")
        workout = parse_markdown_workout(content)
        workouts.append(workout)

        if output_json:
            print(f"\n-- JSON Output for {md_file.name}:")
            print(json.dumps(workout.to_full_dict(), indent=2))

        if output_sql:
            print(f"\n-- SQL Insert for {md_file.name}:")
            print(generate_sql_insert(workout, table_name))

    return workouts


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Import workout markdown files from Obsidian format",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Example usage:
  %(prog)s /path/to/workouts
  %(prog)s /path/to/workouts --sql-only
  %(prog)s /path/to/workouts --json-only
  %(prog)s /path/to/workouts --table my_workouts

Block Structure:
  1. Cardio, 2. Dynamic Stretch, 3. Prehab, 4. Push, 5. Pull,
  6. Hinge, 7. Lunge/Squat, 8. Functional, 9. Recovery
        """,
    )

    parser.add_argument(
        "directory",
        type=Path,
        help="Directory containing workout markdown files",
    )

    parser.add_argument(
        "--sql-only",
        action="store_true",
        help="Output only SQL INSERT statements",
    )

    parser.add_argument(
        "--json-only",
        action="store_true",
        help="Output only JSON structure",
    )

    parser.add_argument(
        "--table",
        type=str,
        default="workouts",
        help="Table name for SQL INSERT statements (default: workouts)",
    )

    parser.add_argument(
        "--validate",
        action="store_true",
        help="Validate block names against standard block structure",
    )

    args = parser.parse_args()

    output_sql = not args.json_only
    output_json = not args.sql_only

    workouts = process_directory(args.directory, output_sql=output_sql, output_json=output_json, table_name=args.table)

    if args.validate:
        print(f"\n{'=' * 60}", file=sys.stderr)
        print("Validation Report", file=sys.stderr)
        print(f"{'=' * 60}", file=sys.stderr)

        for workout in workouts:
            invalid_blocks = [
                block.name for block in workout.blocks if block.name not in VALID_BLOCKS
            ]
            if invalid_blocks:
                print(
                    f"Warning: '{workout.name}' has non-standard blocks: {invalid_blocks}",
                    file=sys.stderr,
                )

    print(f"\n-- Processed {len(workouts)} workout(s)", file=sys.stderr)


if __name__ == "__main__":
    main()
