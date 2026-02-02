# Sync Exercise Content

Import exercises from external sources (CSV, JSON, spreadsheet) into exercise_templates.

## Trigger

```
/sync-content [file-path]
```

**Examples:**
- `/sync-content exercises.csv`
- `/sync-content new-exercises.json`
- `/sync-content --dry-run exercises.csv` (preview only)

## Prerequisites

1. Source file in supported format (CSV, JSON)
2. Supabase access configured
3. File follows expected schema

## Expected Schema

### CSV Format

```csv
name,category,equipment,primary_muscles,difficulty,instructions,video_url
Barbell Back Squat,lower_body,barbell,"quadriceps,glutes",intermediate,"Stand with feet shoulder-width apart...",
Romanian Deadlift,lower_body,barbell,"hamstrings,glutes",intermediate,"Hold barbell at hip level...",
```

### JSON Format

```json
{
  "exercises": [
    {
      "name": "Barbell Back Squat",
      "category": "lower_body",
      "equipment": ["barbell", "squat_rack"],
      "primary_muscles": ["quadriceps", "glutes"],
      "secondary_muscles": ["hamstrings", "core"],
      "difficulty": "intermediate",
      "instructions": "Stand with feet shoulder-width apart...",
      "cues": ["Keep chest up", "Drive through heels"],
      "video_url": null
    }
  ]
}
```

## Execution Steps

### Phase 1: Parse Source File

```bash
# Detect file type
FILE_TYPE="${FILE_PATH##*.}"

# Parse based on type
if [ "$FILE_TYPE" = "csv" ]; then
    # Parse CSV
    # Use csvkit or custom parser
elif [ "$FILE_TYPE" = "json" ]; then
    # Parse JSON
    cat "$FILE_PATH" | jq '.exercises[]'
fi
```

### Phase 2: Validate Against Schema

Required fields:
- `name` (string, unique)
- `category` (enum: upper_body, lower_body, core, full_body, cardio, mobility)
- `equipment` (array of strings)
- `difficulty` (enum: beginner, intermediate, advanced)

Optional fields:
- `primary_muscles` (array)
- `secondary_muscles` (array)
- `instructions` (text)
- `cues` (array)
- `video_url` (URL)
- `sport_specific` (array)

### Phase 3: Check for Duplicates

```sql
-- Find existing exercises by name
SELECT id, name
FROM exercise_templates
WHERE name IN ([LIST_OF_NAMES]);
```

### Phase 4: Generate SQL

For new exercises (INSERT):

```sql
INSERT INTO exercise_templates (
  name, category, equipment, primary_muscles,
  secondary_muscles, difficulty, instructions, cues
) VALUES (
  'Barbell Back Squat',
  'lower_body',
  ARRAY['barbell', 'squat_rack'],
  ARRAY['quadriceps', 'glutes'],
  ARRAY['hamstrings', 'core'],
  'intermediate',
  'Stand with feet shoulder-width apart...',
  ARRAY['Keep chest up', 'Drive through heels']
);
```

For existing exercises (UPDATE):

```sql
UPDATE exercise_templates SET
  category = 'lower_body',
  equipment = ARRAY['barbell', 'squat_rack'],
  primary_muscles = ARRAY['quadriceps', 'glutes'],
  instructions = 'Stand with feet shoulder-width apart...',
  updated_at = NOW()
WHERE name = 'Barbell Back Squat';
```

### Phase 5: Execute Import

**Dry Run Mode:**
```
Dry Run - No changes will be made

To Import:
- 15 new exercises
- 3 updates to existing

New Exercises:
1. Barbell Back Squat (lower_body)
2. Romanian Deadlift (lower_body)
...

Updates:
1. Bench Press - updating instructions
...

Run without --dry-run to apply changes.
```

**Execute Mode:**

Apply via Supabase Dashboard SQL Editor:
- URL: https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql
- Paste generated SQL
- Execute

### Phase 6: Generate Videos for New Exercises

If new exercises were added:

```bash
# Extract names of new exercises
NEW_EXERCISES="barbell-back-squat,romanian-deadlift,..."

# Trigger video generation
# /generate-videos $NEW_EXERCISES
```

### Phase 7: Verification

```sql
-- Verify import
SELECT
  name, category, difficulty,
  CASE WHEN video_url IS NOT NULL THEN 'Yes' ELSE 'No' END as has_video
FROM exercise_templates
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC;
```

## Output

```
Content Sync Complete

Source: exercises.csv
Records Processed: 18

Results:
- New exercises: 15
- Updated: 3
- Skipped (invalid): 0

New Exercises Added:
1. Barbell Back Squat
2. Romanian Deadlift
3. Bulgarian Split Squat
...

Updates Applied:
1. Bench Press - instructions updated
2. Pull-up - added cues
3. Plank - changed difficulty

Next Steps:
- Run /generate-videos for new exercises
- Verify in iOS app
```

## Sample Import Script

```javascript
// scripts/import-exercises.js

const fs = require('fs');
const { parse } = require('csv-parse/sync');

async function importExercises(filePath) {
  const content = fs.readFileSync(filePath, 'utf-8');

  let exercises;
  if (filePath.endsWith('.csv')) {
    exercises = parse(content, { columns: true });
  } else {
    exercises = JSON.parse(content).exercises;
  }

  // Validate
  const valid = exercises.filter(validateExercise);
  const invalid = exercises.filter(e => !validateExercise(e));

  console.log(`Valid: ${valid.length}, Invalid: ${invalid.length}`);

  // Generate SQL
  const sql = valid.map(generateInsertSQL).join('\n');

  // Output
  fs.writeFileSync('import.sql', sql);
  console.log('SQL written to import.sql');
}

function validateExercise(ex) {
  return ex.name && ex.category && ex.difficulty;
}

function generateInsertSQL(ex) {
  return `INSERT INTO exercise_templates (name, category, difficulty)
    VALUES ('${ex.name}', '${ex.category}', '${ex.difficulty}')
    ON CONFLICT (name) DO UPDATE SET
      category = EXCLUDED.category,
      updated_at = NOW();`;
}
```

## Reference

See also:
- `supabase/migrations/` - Database schema
- `/generate-videos` - Video generation skill
- `scripts/sample_workouts/` - Sample exercise data
