#!/usr/bin/env python3
"""
Parse workout markdown files and generate SQL migration.
Converts date-labeled workouts to proper JSONB structure.
"""

import os
import re
import json
import uuid
from datetime import datetime
from pathlib import Path

def parse_frontmatter(content):
    """Extract YAML frontmatter from markdown."""
    match = re.match(r'^---\n(.*?)\n---\n', content, re.DOTALL)
    if not match:
        return {}, content

    frontmatter = {}
    for line in match.group(1).split('\n'):
        if ':' in line and not line.strip().startswith('-'):
            key, value = line.split(':', 1)
            key = key.strip()
            value = value.strip().strip('"\'')
            frontmatter[key] = value

    body = content[match.end():]
    return frontmatter, body

def parse_table(lines):
    """Parse a markdown table into list of dicts."""
    if len(lines) < 2:
        return []

    # Get headers from first line
    headers = [h.strip() for h in lines[0].split('|') if h.strip()]

    # Skip separator line (line 1)
    rows = []
    for line in lines[2:]:
        if not line.strip() or line.strip().startswith('**') or line.strip().startswith('>'):
            break
        cells = [c.strip() for c in line.split('|') if c.strip()]
        if cells:
            row = {}
            for i, cell in enumerate(cells):
                if i < len(headers):
                    row[headers[i].lower()] = cell
            rows.append(row)

    return rows

def extract_sections(body):
    """Extract workout sections from markdown body."""
    sections = {}
    current_section = None
    current_lines = []

    for line in body.split('\n'):
        # New section header (## Active, ## Dynamic, etc.)
        if line.startswith('## '):
            if current_section:
                sections[current_section] = current_lines
            current_section = line[3:].strip()
            current_lines = []
        elif current_section:
            current_lines.append(line)

    if current_section:
        sections[current_section] = current_lines

    return sections

def infer_block_type(section_name):
    """Infer block type from section name."""
    name_lower = section_name.lower()
    if 'active' in name_lower or 'warmup' in name_lower or 'warm-up' in name_lower:
        return 'cardio'
    elif 'dynamic' in name_lower or 'mobility' in name_lower:
        return 'dynamic_stretch'
    elif 'shoulder' in name_lower or 'prep' in name_lower or 'activation' in name_lower:
        return 'activation'
    elif 'strength' in name_lower:
        return 'push'  # Will be refined based on content
    elif 'condition' in name_lower or 'circuit' in name_lower:
        return 'functional'
    elif 'finish' in name_lower or 'cool' in name_lower or 'recovery' in name_lower:
        return 'recovery'
    elif 'core' in name_lower:
        return 'core'
    return 'functional'

def parse_strength_section(lines):
    """Parse strength section with numbered exercises."""
    exercises = []
    current_exercise = None
    current_table_lines = []
    notes = []

    for line in lines:
        # New exercise (### 1. Strict Press to Push Press)
        match = re.match(r'^###\s*\d+\.\s*(.+)', line)
        if match:
            # Save previous exercise
            if current_exercise and current_table_lines:
                table = parse_table(current_table_lines)
                current_exercise['sets_detail'] = table
                current_exercise['notes'] = ' '.join(notes)
                exercises.append(current_exercise)

            current_exercise = {'name': match.group(1).strip()}
            current_table_lines = []
            notes = []
        elif line.startswith('|'):
            current_table_lines.append(line)
        elif line.startswith('**Rest:**') or line.startswith('**Accessory:**'):
            notes.append(line.replace('**', '').strip())

    # Save last exercise
    if current_exercise and current_table_lines:
        table = parse_table(current_table_lines)
        current_exercise['sets_detail'] = table
        current_exercise['notes'] = ' '.join(notes)
        exercises.append(current_exercise)

    return exercises

def convert_to_database_format(workout_data, frontmatter):
    """Convert parsed workout to database JSONB format."""
    blocks = []
    sequence = 1

    for section_name, section_lines in workout_data.items():
        # Skip non-exercise sections
        if any(skip in section_name.lower() for skip in ['progression', 'recovery', 'notes']):
            continue

        block_type = infer_block_type(section_name)
        block_id = str(uuid.uuid4())  # Generate proper UUID

        exercises = []
        ex_sequence = 1

        # Check if this is the Strength section (has ### subsections)
        section_text = '\n'.join(section_lines)
        if '### ' in section_text and 'strength' in section_name.lower():
            strength_exercises = parse_strength_section(section_lines)
            for ex in strength_exercises:
                sets_info = ex.get('sets_detail', [])
                num_sets = len(sets_info)

                # Build reps string from first set
                reps = sets_info[0].get('reps', '') if sets_info else ''

                # Build notes with load progression
                load_notes = []
                for i, s in enumerate(sets_info):
                    load = s.get('load', '')
                    rpe = s.get('rpe', '')
                    if load or rpe:
                        load_notes.append(f"Set {i+1}: {load} (RPE {rpe})" if rpe else f"Set {i+1}: {load}")

                notes = '. '.join(load_notes)
                if ex.get('notes'):
                    notes = notes + '. ' + ex['notes'] if notes else ex['notes']

                exercises.append({
                    'id': str(uuid.uuid4()),  # Generate proper UUID
                    'name': ex['name'],
                    'sequence': ex_sequence,
                    'prescribed_sets': num_sets if num_sets > 0 else 3,
                    'prescribed_reps': reps,
                    'notes': notes
                })
                ex_sequence += 1
        else:
            # Parse regular table section
            table = parse_table(section_lines)
            for row in table:
                ex_name = row.get('exercise', row.get('name', ''))
                if not ex_name:
                    continue

                # Get reps/duration
                reps = row.get('duration/reps', row.get('reps', row.get('duration', '')))
                notes = row.get('notes', row.get('purpose', ''))

                # Parse rounds from section name (e.g., "Active - 3 Rounds")
                rounds_match = re.search(r'(\d+)\s*[Rr]ounds?', section_name)
                prescribed_sets = int(rounds_match.group(1)) if rounds_match else None

                # Check for conditioning rounds
                if 'conditioning' in section_name.lower():
                    rounds_match = re.search(r'(\d+)\s*[Rr]ounds?', section_name)
                    if rounds_match:
                        notes = f"{notes}. {rounds_match.group(1)} rounds total" if notes else f"{rounds_match.group(1)} rounds total"

                ex_data = {
                    'id': str(uuid.uuid4()),  # Generate proper UUID
                    'name': ex_name,
                    'sequence': ex_sequence
                }

                if prescribed_sets:
                    ex_data['prescribed_sets'] = prescribed_sets
                if reps:
                    ex_data['prescribed_reps'] = reps
                if notes:
                    ex_data['notes'] = notes

                exercises.append(ex_data)
                ex_sequence += 1

        if exercises:
            blocks.append({
                'id': block_id,
                'name': section_name,
                'block_type': block_type,
                'sequence': sequence,
                'exercises': exercises
            })
            sequence += 1

    return blocks

def date_to_display_name(date_str):
    """Convert 2018-08-13 to 'August 13, 2018'."""
    try:
        dt = datetime.strptime(date_str, '%Y-%m-%d')
        return dt.strftime('%B %-d, %Y')
    except:
        return date_str

def escape_sql_string(s):
    """Escape single quotes for SQL strings."""
    return s.replace("'", "''")

def generate_sql_update(filename, blocks, frontmatter):
    """Generate SQL UPDATE statement for a workout."""
    date_str = frontmatter.get('date', '')
    display_name = date_to_display_name(date_str)

    duration = frontmatter.get('duration_min', '60')

    # Build description from metadata
    patterns = frontmatter.get('movement_patterns', '')
    desc_parts = []
    if 'vertical-push' in patterns or 'press' in patterns:
        desc_parts.append('pressing')
    if 'single-leg' in patterns:
        desc_parts.append('single-leg work')
    if 'hinge' in patterns:
        desc_parts.append('hinge movements')
    if 'conditioning' in patterns:
        desc_parts.append('conditioning')

    description = f"Full-body workout with {', '.join(desc_parts)}" if desc_parts else "Comprehensive training session"

    # Generate tags
    tags = ['strength', 'full-body']
    if frontmatter.get('phase'):
        tags.append(frontmatter['phase'])

    # Escape single quotes in JSON
    exercises_json = escape_sql_string(json.dumps(blocks, indent=4))
    tags_str = '{' + ','.join(tags) + '}'

    sql = f"""
-- Fix "{display_name}" workout
UPDATE system_workout_templates
SET
    description = '{escape_sql_string(description)}',
    difficulty = 'intermediate',
    duration_minutes = {duration},
    exercises = '{exercises_json}'::jsonb,
    tags = '{tags_str}'
WHERE name = '{display_name}';
"""
    return sql

def main():
    """Process all workout files and generate migration."""
    workout_dir = Path('/Users/expo/pt-performance/workout-data')
    output_lines = [
        "-- BUILD 332: Fix all date-labeled workout templates",
        "-- Generated from original Dropbox workout files",
        "-- Replaces incorrect '1,2,3,4,5' exercise names with actual exercise data",
        ""
    ]

    # Find all date-labeled workout files
    workout_files = sorted(workout_dir.glob('20??-??-?? Workout.md'))

    processed = 0
    errors = []

    for filepath in workout_files:
        try:
            with open(filepath, 'r') as f:
                content = f.read()

            frontmatter, body = parse_frontmatter(content)
            sections = extract_sections(body)
            blocks = convert_to_database_format(sections, frontmatter)

            if blocks:
                sql = generate_sql_update(filepath.name, blocks, frontmatter)
                output_lines.append(sql)
                processed += 1
                print(f"Processed: {filepath.name}")
        except Exception as e:
            errors.append(f"{filepath.name}: {e}")
            print(f"Error: {filepath.name}: {e}")

    # Add verification
    output_lines.append("""
-- Verify updates
DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO updated_count
    FROM system_workout_templates
    WHERE name ~ '^[A-Z][a-z]+ [0-9]+, 20[0-9]{2}$'
      AND exercises::text NOT LIKE '%"name": "1"%';

    RAISE NOTICE 'Updated % date-labeled workout templates with proper exercise data', updated_count;
END $$;
""")

    # Write output
    output_path = workout_dir / 'fix_all_date_workouts.sql'
    with open(output_path, 'w') as f:
        f.write('\n'.join(output_lines))

    print(f"\nProcessed {processed} workouts")
    print(f"Output: {output_path}")

    if errors:
        print(f"\nErrors ({len(errors)}):")
        for e in errors[:10]:
            print(f"  {e}")

if __name__ == '__main__':
    main()
