#!/usr/bin/env python3
"""
Obsidian Workout Import Script

Imports workout templates from Obsidian Markdown files into the system_workout_templates table.

Expected Markdown format:
---
tags: [strength, full-body, intermediate]
duration: 60
difficulty: intermediate
---

# Full Body Day A

## Cardio
- 5 min Row Machine

## Dynamic Stretch
- World's Greatest Stretch - 2x5 each side
- Leg Swings - 2x10 each

## Push
- Barbell Bench Press - 4x8-10 @ RPE 8
- Incline DB Press - 3x10-12

## Recovery
- Foam Roll - 5 min

Usage:
    python import_obsidian_workouts.py /path/to/workouts --output migrations.sql
    python import_obsidian_workouts.py /path/to/workouts --apply  # Apply directly to Supabase
"""

import os
import re
import json
import uuid
import argparse
from pathlib import Path
from typing import Optional
from dataclasses import dataclass, field, asdict


# Block type mapping from Obsidian section names to database enum values
BLOCK_TYPE_MAP = {
    # Warmup/Cardio
    "cardio": "cardio",
    "warm up": "cardio",
    "warmup": "cardio",
    "warm-up": "cardio",
    "active": "cardio",  # "Active" warmup section
    # Dynamic/Mobility
    "dynamic stretch": "dynamic_stretch",
    "dynamic stretching": "dynamic_stretch",
    "dynamic": "dynamic_stretch",  # Just "Dynamic" header
    "mobility": "dynamic_stretch",
    # Prehab/Activation
    "prehab": "prehab",
    "pre-hab": "prehab",
    "activation": "prehab",
    # Push
    "push": "push",
    "pressing": "push",
    "chest": "push",
    "shoulders": "push",
    # Pull
    "pull": "pull",
    "pulling": "pull",
    "back": "pull",
    "rows": "pull",
    # Hinge
    "hinge": "hinge",
    "deadlift": "hinge",
    "hip hinge": "hinge",
    "posterior chain": "hinge",
    # Squat/Lunge
    "lunge": "lunge_squat",
    "squat": "lunge_squat",
    "lunge/squat": "lunge_squat",
    "lunges": "lunge_squat",
    "squats": "lunge_squat",
    "legs": "lunge_squat",
    "lower body": "lunge_squat",
    # Functional/Conditioning/Core
    "functional": "functional",
    "core": "functional",
    "conditioning": "functional",  # Conditioning sections like "Conditioning - Chipper"
    "finisher": "functional",
    "chipper": "functional",
    "amrap": "functional",
    "emom": "functional",
    # Strength (general)
    "strength": "push",  # Default strength to push, will be refined
    # Recovery
    "recovery": "recovery",
    "cool down": "recovery",
    "cooldown": "recovery",
    "cool-down": "recovery",
    "stretch": "recovery",
    "stretching": "recovery",
    "foam roll": "recovery",
    "progression": "recovery",  # Notes sections
    "notes": "recovery",
}

# Category inference from tags and content
CATEGORY_KEYWORDS = {
    "strength": ["strength", "power", "build", "hypertrophy", "muscle"],
    "mobility": ["mobility", "flexibility", "stretch", "yoga"],
    "cardio": ["cardio", "conditioning", "hiit", "endurance", "run", "bike"],
    "rehab": ["rehab", "recovery", "prehab", "injury", "physical therapy"],
    "hybrid": ["hybrid", "full-body", "full body", "total body"],
}

DIFFICULTY_MAP = {
    "beginner": "beginner",
    "easy": "beginner",
    "novice": "beginner",
    "intermediate": "intermediate",
    "moderate": "intermediate",
    "advanced": "advanced",
    "hard": "advanced",
    "expert": "advanced",
}


@dataclass
class Exercise:
    """Represents an exercise within a workout block."""
    id: str
    exercise_template_id: str  # Will be matched later or use placeholder
    name: str
    sequence: int
    prescribed_sets: int = 3
    prescribed_reps: Optional[str] = None
    prescribed_load: Optional[float] = None
    load_unit: Optional[str] = None
    rest_period_seconds: Optional[int] = None
    notes: Optional[str] = None


@dataclass
class WorkoutBlock:
    """Represents a workout block containing exercises."""
    id: str
    name: str
    block_type: str
    sequence: int
    exercises: list = field(default_factory=list)


@dataclass
class WorkoutTemplate:
    """Represents a parsed workout template."""
    id: str
    name: str
    description: Optional[str] = None
    category: Optional[str] = None
    difficulty: Optional[str] = None
    estimated_duration_minutes: Optional[int] = None
    blocks: list = field(default_factory=list)
    tags: list = field(default_factory=list)
    source_file: Optional[str] = None


def parse_frontmatter(content: str) -> tuple[dict, str]:
    """Extract YAML frontmatter and remaining content."""
    frontmatter = {}
    body = content

    # Check for YAML frontmatter
    if content.startswith("---"):
        parts = content.split("---", 2)
        if len(parts) >= 3:
            yaml_content = parts[1].strip()
            body = parts[2].strip()

            current_key = None
            current_list = None

            for line in yaml_content.split("\n"):
                # Check for list item (indented with -)
                list_match = re.match(r'^\s+-\s+(.+)$', line)
                if list_match and current_key:
                    if current_list is None:
                        current_list = []
                    current_list.append(list_match.group(1).strip().strip('"\''))
                    continue

                # Save any pending list
                if current_key and current_list is not None:
                    frontmatter[current_key] = current_list
                    current_list = None
                    current_key = None

                line = line.strip()
                if not line or line.startswith("#"):
                    continue

                if ":" in line:
                    key, value = line.split(":", 1)
                    key = key.strip()
                    value = value.strip()

                    # Empty value means upcoming list
                    if not value:
                        current_key = key
                        current_list = []
                        continue

                    # Parse list format [item1, item2]
                    if value.startswith("[") and value.endswith("]"):
                        items = value[1:-1].split(",")
                        frontmatter[key] = [item.strip().strip('"\'') for item in items if item.strip()]
                    else:
                        # Try to parse as number
                        try:
                            frontmatter[key] = int(value)
                        except ValueError:
                            try:
                                frontmatter[key] = float(value)
                            except ValueError:
                                frontmatter[key] = value.strip('"\'')

            # Save any pending list at end
            if current_key and current_list is not None:
                frontmatter[current_key] = current_list

    return frontmatter, body


def parse_table_row(cells: list, sequence: int) -> Optional[Exercise]:
    """Parse a markdown table row into an Exercise object."""
    if len(cells) < 1:
        return None

    exercise_id = str(uuid.uuid4())
    exercise_template_id = str(uuid.uuid4())

    name = cells[0].strip()
    if not name or name.lower() in ['exercise', 'movement', '---', '']:
        return None

    sets = 3  # Default
    reps = None
    load = None
    load_unit = None
    notes = None

    # Second column is usually reps or purpose
    if len(cells) >= 2:
        col2 = cells[1].strip()
        # Check if it's a number (reps)
        reps_match = re.search(r'(\d+)(?:e)?', col2)
        if reps_match:
            reps = col2
        else:
            # It's a note/purpose
            notes = col2

    # Third column might be Load, Notes, or scaling info
    if len(cells) >= 3:
        col3 = cells[2].strip()
        # Check for load
        load_match = re.search(r'(\d+(?:\.\d+)?)\s*(lbs?|kg)?', col3, re.I)
        if load_match and load_match.group(2):
            load = float(load_match.group(1))
            unit = load_match.group(2).lower()
            load_unit = "kg" if unit.startswith("k") else "lbs"
        elif col3 and col3.lower() not in ['notes', '---', '']:
            notes = (notes + "; " + col3) if notes else col3

    # Fourth column is often RPE or additional notes
    if len(cells) >= 4:
        col4 = cells[3].strip()
        rpe_match = re.search(r'(\d+(?:-\d+)?)', col4)
        if rpe_match and col4.lower() not in ['rpe', '---', '']:
            if notes:
                notes = notes + f"; RPE {rpe_match.group(1)}"
            else:
                notes = f"RPE {rpe_match.group(1)}"

    return Exercise(
        id=exercise_id,
        exercise_template_id=exercise_template_id,
        name=name,
        sequence=sequence,
        prescribed_sets=sets,
        prescribed_reps=reps,
        prescribed_load=load,
        load_unit=load_unit,
        rest_period_seconds=None,
        notes=notes
    )


def parse_exercise_line(line: str, sequence: int) -> Optional[Exercise]:
    """Parse a single exercise line into an Exercise object."""
    line = line.strip()
    if not line or line.startswith("#"):
        return None

    # Remove list markers
    line = re.sub(r"^[-*]\s*", "", line)
    if not line:
        return None

    exercise_id = str(uuid.uuid4())
    exercise_template_id = str(uuid.uuid4())  # Placeholder, will match later

    # Try to extract sets x reps patterns
    # Patterns: "3x10", "3 x 10", "3 sets x 10 reps", "4x8-10", "3x30s", etc.

    sets = 3  # Default
    reps = None
    load = None
    load_unit = None
    rest = None
    notes = None
    name = line

    # Pattern: "Exercise Name - 3x10 @ 135lbs"
    # or "Exercise Name - 3x10-12 @ RPE 8"
    # or "Exercise Name - 5 min"

    # Split on delimiter ONLY when followed by a number (sets/reps/duration)
    # This preserves exercise names like "Cat-Cow" or "90/90 Hip Switches"
    parts_match = re.match(r'^(.+?)\s*[-–—]\s*(\d.*)$', line)
    if parts_match:
        name = parts_match.group(1).strip()
        details = parts_match.group(2).strip()

        # Check for duration format (e.g., "5 min", "30s", "2:00")
        duration_match = re.search(r'(\d+)\s*(min|mins|minute|minutes|sec|secs|seconds?|s)\b', details, re.I)
        if duration_match:
            duration_val = int(duration_match.group(1))
            duration_unit = duration_match.group(2).lower()
            if duration_unit.startswith('min'):
                sets = 1
                reps = f"{duration_val} min"
            else:
                sets = 1
                reps = f"{duration_val}s"
        else:
            # Parse sets x reps
            sets_reps_match = re.search(r'(\d+)\s*[xX×]\s*(\d+(?:-\d+)?)', details)
            if sets_reps_match:
                sets = int(sets_reps_match.group(1))
                reps = sets_reps_match.group(2)

            # Check for "each side" or "each"
            if re.search(r'each\s*(side|leg|arm)?', details, re.I):
                if reps:
                    reps = f"{reps} each"
                else:
                    each_match = re.search(r'(\d+)\s*each', details, re.I)
                    if each_match:
                        reps = f"{each_match.group(1)} each"

            # Parse load (weight)
            load_match = re.search(r'@?\s*(\d+(?:\.\d+)?)\s*(lbs?|kg|pounds?|kilos?)', details, re.I)
            if load_match:
                load = float(load_match.group(1))
                unit = load_match.group(2).lower()
                load_unit = "kg" if unit.startswith("k") else "lbs"

            # Parse RPE
            rpe_match = re.search(r'RPE\s*(\d+(?:-\d+)?)', details, re.I)
            if rpe_match:
                notes = f"RPE {rpe_match.group(1)}"

            # Parse rest
            rest_match = re.search(r'rest\s*:?\s*(\d+)\s*(sec|s|min|m)?', details, re.I)
            if rest_match:
                rest_val = int(rest_match.group(1))
                rest_unit = rest_match.group(2) or "s"
                rest = rest_val * 60 if rest_unit.startswith("m") else rest_val
    else:
        # Just exercise name, use defaults
        name = line.strip()

    # Clean up name
    name = name.strip()
    if not name:
        return None

    return Exercise(
        id=exercise_id,
        exercise_template_id=exercise_template_id,
        name=name,
        sequence=sequence,
        prescribed_sets=sets,
        prescribed_reps=reps,
        prescribed_load=load,
        load_unit=load_unit,
        rest_period_seconds=rest,
        notes=notes
    )


def parse_exercises_from_content(block_content: str) -> list:
    """Parse exercises from block content - handles both tables and bullet lists."""
    exercises = []
    exercise_seq = 1

    lines = block_content.split("\n")
    in_table = False
    table_headers = []

    for line in lines:
        line = line.strip()

        # Skip empty lines, comments, callouts, and metadata
        if not line or line.startswith(">") or line.startswith("**") or line.startswith("*"):
            continue
        if line.startswith("#"):  # Skip H3+ headings but note them
            continue

        # Detect table rows
        if "|" in line:
            cells = [c.strip() for c in line.split("|")]
            # Remove empty first/last cells from |...|
            cells = [c for c in cells if c]

            # Skip separator rows (|---|---|)
            if cells and all(re.match(r'^[-:]+$', c) for c in cells):
                continue

            # Skip header rows
            if cells and cells[0].lower() in ['exercise', 'movement', 'set', 'reps']:
                table_headers = cells
                in_table = True
                continue

            if cells:
                exercise = parse_table_row(cells, exercise_seq)
                if exercise:
                    exercises.append(exercise)
                    exercise_seq += 1

        # Bullet list items
        elif line.startswith("-") or line.startswith("*"):
            exercise = parse_exercise_line(line, exercise_seq)
            if exercise:
                exercises.append(exercise)
                exercise_seq += 1

    return exercises


def parse_workout_file(filepath: Path) -> Optional[WorkoutTemplate]:
    """Parse a single Obsidian markdown file into a WorkoutTemplate."""
    try:
        content = filepath.read_text(encoding="utf-8")
    except Exception as e:
        print(f"Error reading {filepath}: {e}")
        return None

    frontmatter, body = parse_frontmatter(content)

    # Skip non-workout files (block templates, indexes, etc.)
    file_type = frontmatter.get("type", "")
    if file_type in ["program-block", "index", "dashboard", "home"]:
        return None

    # Extract workout name from title frontmatter, H1 heading, or filename
    name = frontmatter.get("title")
    if not name:
        name_match = re.search(r'^#\s+(.+)$', body, re.MULTILINE)
        if name_match:
            name = name_match.group(1).strip()
        else:
            name = filepath.stem.replace("_", " ").replace("-", " ").title()

    # Clean up name - remove "Workout -" prefix if present
    name = re.sub(r'^Workout\s*[-–—]\s*', '', name)

    # Extract description (first paragraph after title, or from frontmatter)
    description = None
    desc_match = re.search(r'^#\s+.+\n\n(.+?)(?=\n\n|\n##|\Z)', body, re.MULTILINE | re.DOTALL)
    if desc_match:
        desc = desc_match.group(1).strip()
        if not desc.startswith("#") and not desc.startswith("|"):
            description = desc

    # Get metadata from frontmatter - strategic mapping
    tags = frontmatter.get("tags", [])
    if isinstance(tags, str):
        tags = [tags]

    # Add movement patterns, equipment, muscles to tags for searchability
    movement_patterns = frontmatter.get("movement_patterns", [])
    if isinstance(movement_patterns, list):
        tags.extend(movement_patterns)

    equipment = frontmatter.get("equipment", [])
    if isinstance(equipment, list):
        tags.extend(equipment)

    primary_muscles = frontmatter.get("primary_muscles", [])
    if isinstance(primary_muscles, list):
        tags.extend(primary_muscles)

    # Dedupe and clean tags
    tags = list(set(t.lower().replace("_", "-") for t in tags if t))

    # Duration: use duration_min from frontmatter
    duration = frontmatter.get("duration_min") or frontmatter.get("duration") or frontmatter.get("estimated_duration")
    if isinstance(duration, str):
        try:
            duration = int(duration)
        except ValueError:
            duration = None

    # Difficulty: infer from phase or intensity
    difficulty = frontmatter.get("difficulty")
    if not difficulty:
        phase = frontmatter.get("phase", "").lower()
        intensity = frontmatter.get("intensity", 5)

        if phase == "foundation" or (isinstance(intensity, (int, float)) and intensity <= 4):
            difficulty = "beginner"
        elif phase in ["strength", "power"] or (isinstance(intensity, (int, float)) and intensity >= 8):
            difficulty = "advanced"
        else:
            difficulty = "intermediate"
    else:
        difficulty = DIFFICULTY_MAP.get(difficulty.lower(), difficulty.lower())

    # Category: infer from tags, content, or energy_system
    category = frontmatter.get("category")
    if not category:
        energy_system = frontmatter.get("energy_system", "").lower()
        if energy_system in ["aerobic", "cardio"]:
            category = "cardio"
        elif "strength" in tags or "power" in tags:
            category = "strength"
        elif "conditioning" in tags:
            category = "hybrid"

    if not category and tags:
        for cat, keywords in CATEGORY_KEYWORDS.items():
            if any(kw in tags for kw in keywords):
                category = cat
                break

    if not category:
        content_lower = body.lower()
        for cat, keywords in CATEGORY_KEYWORDS.items():
            if any(kw in content_lower for kw in keywords):
                category = cat
                break

    if not category:
        category = "hybrid"  # Default for mixed workouts

    # Parse blocks (H2 sections)
    blocks = []
    block_pattern = re.compile(r'^##\s+(.+)$', re.MULTILINE)
    block_matches = list(block_pattern.finditer(body))

    for i, match in enumerate(block_matches):
        block_name = match.group(1).strip()

        # Skip non-exercise blocks
        skip_blocks = ["progression", "notes", "recovery recommendations", "rep scheme", "enhancement"]
        if any(skip in block_name.lower() for skip in skip_blocks):
            continue

        # Determine block type
        block_type = "functional"  # Default
        block_name_lower = block_name.lower()
        for key, btype in BLOCK_TYPE_MAP.items():
            if key in block_name_lower:
                block_type = btype
                break

        # Get block content (until next H2 or end)
        start = match.end()
        end = block_matches[i + 1].start() if i + 1 < len(block_matches) else len(body)
        block_content = body[start:end].strip()

        # Use new parser that handles both tables and bullet lists
        exercises = parse_exercises_from_content(block_content)

        if exercises:  # Only add blocks with exercises
            block = WorkoutBlock(
                id=str(uuid.uuid4()),
                name=block_name,
                block_type=block_type,
                sequence=len(blocks) + 1,
                exercises=exercises
            )
            blocks.append(block)

    if not blocks:
        # Only warn for actual workout files
        if frontmatter.get("type") == "workout" or "Workout" in filepath.name:
            print(f"Warning: No blocks found in {filepath}")
        return None

    return WorkoutTemplate(
        id=str(uuid.uuid4()),
        name=name,
        description=description,
        category=category,
        difficulty=difficulty,
        estimated_duration_minutes=duration,
        blocks=blocks,
        tags=tags,
        source_file=filepath.name
    )


def workout_to_json(workout: WorkoutTemplate) -> dict:
    """Convert workout template to JSON-serializable dict."""
    blocks_data = []
    for block in workout.blocks:
        exercises_data = []
        for ex in block.exercises:
            ex_dict = {
                "id": ex.id,
                "exercise_template_id": ex.exercise_template_id,
                "name": ex.name,
                "sequence": ex.sequence,
                "prescribed_sets": ex.prescribed_sets,
            }
            if ex.prescribed_reps:
                ex_dict["prescribed_reps"] = ex.prescribed_reps
            if ex.prescribed_load:
                ex_dict["prescribed_load"] = ex.prescribed_load
            if ex.load_unit:
                ex_dict["load_unit"] = ex.load_unit
            if ex.rest_period_seconds:
                ex_dict["rest_period_seconds"] = ex.rest_period_seconds
            if ex.notes:
                ex_dict["notes"] = ex.notes
            exercises_data.append(ex_dict)

        blocks_data.append({
            "id": block.id,
            "name": block.name,
            "block_type": block.block_type,
            "sequence": block.sequence,
            "exercises": exercises_data
        })

    return {
        "id": workout.id,
        "name": workout.name,
        "description": workout.description,
        "category": workout.category,
        "difficulty": workout.difficulty,
        "estimated_duration_minutes": workout.estimated_duration_minutes,
        "blocks": blocks_data,
        "tags": workout.tags,
        "source_file": workout.source_file
    }


def generate_sql_insert(workout: WorkoutTemplate) -> str:
    """Generate SQL INSERT statement for a workout template."""
    workout_dict = workout_to_json(workout)

    # Escape single quotes in strings
    def escape_sql(val):
        if val is None:
            return "NULL"
        if isinstance(val, str):
            return "'" + val.replace("'", "''") + "'"
        if isinstance(val, bool):
            return "TRUE" if val else "FALSE"
        if isinstance(val, (list, dict)):
            return "'" + json.dumps(val).replace("'", "''") + "'"
        return str(val)

    # Map tags to array format - escape any special chars in tag names
    clean_tags = [t.replace("'", "''").replace('"', '') for t in workout.tags] if workout.tags else []
    tags_array = "'{" + ",".join(clean_tags) + "}'" if clean_tags else "'{}'::text[]"

    # Escape source file
    source_file = escape_sql(workout.source_file) if workout.source_file else "NULL"

    sql = f"""INSERT INTO system_workout_templates (
    id, name, description, category, difficulty,
    duration_minutes, exercises, tags, source_file, created_at
) VALUES (
    '{workout.id}',
    {escape_sql(workout.name)},
    {escape_sql(workout.description)},
    {escape_sql(workout.category)},
    {escape_sql(workout.difficulty)},
    {escape_sql(workout.estimated_duration_minutes)},
    {escape_sql(workout_dict['blocks'])}::jsonb,
    {tags_array},
    {source_file},
    NOW()
);"""
    return sql


def import_workouts(input_path: str, output_file: Optional[str] = None, apply: bool = False):
    """Import workout files from a directory."""
    input_dir = Path(input_path)

    if not input_dir.exists():
        print(f"Error: Path does not exist: {input_path}")
        return

    # Find all markdown files
    if input_dir.is_file():
        md_files = [input_dir]
    else:
        md_files = list(input_dir.glob("**/*.md"))

    print(f"Found {len(md_files)} markdown files")

    workouts = []
    for filepath in md_files:
        print(f"Parsing: {filepath.name}")
        workout = parse_workout_file(filepath)
        if workout:
            workouts.append(workout)
            print(f"  -> {workout.name} ({len(workout.blocks)} blocks, {sum(len(b.exercises) for b in workout.blocks)} exercises)")

    print(f"\nSuccessfully parsed {len(workouts)} workouts")

    if not workouts:
        print("No workouts to import")
        return

    # Generate SQL
    sql_statements = []
    sql_statements.append("-- Obsidian Workout Import")
    sql_statements.append(f"-- Generated from {len(workouts)} workout files")
    sql_statements.append("-- Run this migration after the system_workout_templates table is created")
    sql_statements.append("")
    sql_statements.append("BEGIN;")
    sql_statements.append("")

    for workout in workouts:
        sql_statements.append(f"-- {workout.name}")
        sql_statements.append(generate_sql_insert(workout))
        sql_statements.append("")

    sql_statements.append("COMMIT;")

    sql_content = "\n".join(sql_statements)

    if output_file:
        output_path = Path(output_file)
        output_path.write_text(sql_content, encoding="utf-8")
        print(f"\nSQL written to: {output_file}")
    else:
        # Default output location
        output_path = Path(__file__).parent.parent / "supabase" / "migrations" / "20260118000005_seed_system_templates.sql"
        output_path.write_text(sql_content, encoding="utf-8")
        print(f"\nSQL written to: {output_path}")

    # Also output JSON for reference
    json_output = [workout_to_json(w) for w in workouts]
    json_path = output_path.with_suffix(".json")
    json_path.write_text(json.dumps(json_output, indent=2), encoding="utf-8")
    print(f"JSON reference written to: {json_path}")

    if apply:
        print("\n--apply flag set, but direct database application not implemented.")
        print("Please run the generated SQL migration file manually:")
        print(f"  psql $DATABASE_URL -f {output_path}")


def main():
    parser = argparse.ArgumentParser(
        description="Import Obsidian workout files into system_workout_templates"
    )
    parser.add_argument(
        "input_path",
        help="Path to directory containing Obsidian markdown files"
    )
    parser.add_argument(
        "--output", "-o",
        help="Output SQL file path (default: supabase/migrations/20260118000005_seed_system_templates.sql)"
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Apply directly to database (requires SUPABASE_URL env var)"
    )
    parser.add_argument(
        "--preview",
        action="store_true",
        help="Preview parsed workouts without generating SQL"
    )

    args = parser.parse_args()

    if args.preview:
        input_dir = Path(args.input_path)
        if input_dir.is_file():
            md_files = [input_dir]
        else:
            md_files = list(input_dir.glob("**/*.md"))

        for filepath in md_files[:5]:  # Preview first 5
            print(f"\n{'='*60}")
            print(f"File: {filepath.name}")
            print('='*60)
            workout = parse_workout_file(filepath)
            if workout:
                print(json.dumps(workout_to_json(workout), indent=2))
    else:
        import_workouts(args.input_path, args.output, args.apply)


if __name__ == "__main__":
    main()
