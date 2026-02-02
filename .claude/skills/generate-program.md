# Generate Training Program

Create a training program from template for a specific sport or goal.

## Trigger

```
/generate-program [sport-or-goal]
```

**Examples:**
- `/generate-program baseball`
- `/generate-program acl-recovery`
- `/generate-program strength-general`
- `/generate-program --list` - Show available templates

## Prerequisites

1. Program templates in database
2. Exercise library populated
3. Supabase access

## Available Templates

| Template | Duration | Focus |
|----------|----------|-------|
| `baseball-pitcher` | 12 weeks | Arm care, rotational power |
| `baseball-position` | 10 weeks | Hitting power, agility |
| `acl-recovery-phase1` | 6 weeks | Range of motion, quad strength |
| `acl-recovery-phase2` | 8 weeks | Strength, proprioception |
| `acl-recovery-phase3` | 8 weeks | Power, sport-specific |
| `strength-general` | 8 weeks | Full body strength |
| `mobility-general` | 4 weeks | Flexibility, joint health |

## Execution Steps

### Phase 1: Select Template

```sql
-- Get template details
SELECT
  id, name, description, duration_weeks,
  sessions_per_week, focus_areas
FROM program_templates
WHERE slug = '[sport-or-goal]';
```

### Phase 2: Generate Program Structure

```sql
-- Create program from template
INSERT INTO programs (
  name,
  description,
  duration_weeks,
  sessions_per_week,
  created_by,
  template_id
)
SELECT
  name || ' - Custom',
  description,
  duration_weeks,
  sessions_per_week,
  '[therapist-id]',
  id
FROM program_templates
WHERE slug = '[sport-or-goal]'
RETURNING id;
```

### Phase 3: Generate Sessions

```sql
-- Create session templates for each week
INSERT INTO session_templates (
  program_id,
  week_number,
  day_of_week,
  focus,
  estimated_duration
)
SELECT
  [new-program-id],
  week,
  day,
  focus,
  45
FROM generate_series(1, [duration_weeks]) as week,
     generate_series(1, [sessions_per_week]) as day;
```

### Phase 4: Assign Exercises

Use AI to select appropriate exercises:

```bash
# Call AI workout recommendation
curl -X POST "https://rpbxeaxlaoyoqkohytlw.supabase.co/functions/v1/ai-workout-recommendation" \
  -H "Authorization: Bearer [ANON_KEY]" \
  -H "Content-Type: application/json" \
  -d '{
    "sport": "[sport]",
    "goal": "[goal]",
    "equipment": ["barbell", "dumbbells", "bands"],
    "session_count": [sessions-per-week],
    "week": 1
  }'
```

### Phase 5: Apply Progressive Overload

```sql
-- Set progression parameters
UPDATE session_exercises
SET
  week_1_sets = 3,
  week_1_reps = 10,
  week_4_sets = 4,
  week_4_reps = 8,
  progression_type = 'linear'
WHERE session_template_id IN (
  SELECT id FROM session_templates
  WHERE program_id = [new-program-id]
);
```

### Phase 6: Generate Output

```markdown
# Generated Program: Baseball Pitcher

**Duration:** 12 weeks
**Sessions/Week:** 4
**Focus:** Arm care, rotational power, lower body strength

---

## Weekly Structure

| Day | Focus | Duration |
|-----|-------|----------|
| Monday | Upper Body Push + Arm Care | 45 min |
| Tuesday | Lower Body + Plyometrics | 50 min |
| Thursday | Upper Body Pull + Core | 45 min |
| Saturday | Full Body + Conditioning | 55 min |

---

## Phase 1: Foundation (Weeks 1-4)

### Week 1 Sample

**Monday - Upper Push + Arm Care**
1. Band Pull-Aparts - 3x15
2. External Rotation - 3x12
3. Incline DB Press - 3x10
4. Landmine Press - 3x10
5. Tricep Pushdowns - 3x12
6. Arm Care Circuit - 10 min

---

## Progression

| Metric | Week 1 | Week 4 | Week 8 | Week 12 |
|--------|--------|--------|--------|---------|
| Volume | 100% | 115% | 130% | 120% |
| Intensity | 65% | 70% | 75% | 80% |
| Plyos | 0 | Low | Med | Sport |

---

*Program ID: [uuid]*
*Created: 2025-01-30*
```

## Output

```
Program Generated

Name: Baseball Pitcher - Custom
Duration: 12 weeks
Sessions: 48 total (4/week)
Exercises: 156 assigned

Structure:
- Phase 1: Foundation (Weeks 1-4)
- Phase 2: Strength (Weeks 5-8)
- Phase 3: Power (Weeks 9-12)

Program ID: abc123-def456

Next Steps:
1. Review in Supabase Dashboard
2. Assign to patient with /assign-program
3. Generate scheduled sessions
```

## Reference

- `supabase/functions/ai-workout-recommendation/` - AI exercise selection
- `scripts/sample_workouts/` - Template data
- Database: `program_templates`, `session_templates`, `session_exercises`
