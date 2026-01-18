---
title: "Workout Dashboard"
type: dashboard
tags:
  - workout
  - dashboard
  - index
---

# Workout Dashboard

**Total Workouts: 184** | Enhanced with 7 features: Movement Patterns, Equipment, Intensity, Muscles, Recovery, Scaling, Progression

---

## Quick Filters

### By Intensity Level
```dataview
TABLE WITHOUT ID
  link(file.name) as "Workout",
  date as "Date",
  intensity as "Intensity",
  duration_min + " min" as "Duration"
FROM "30_Resources/Workouts Neuro"
WHERE type = "workout" AND intensity >= 8
SORT date DESC
LIMIT 10
```

### Low Intensity / Recovery Workouts
```dataview
TABLE WITHOUT ID
  link(file.name) as "Workout",
  date as "Date",
  intensity as "Intensity"
FROM "30_Resources/Workouts Neuro"
WHERE type = "workout" AND intensity <= 5
SORT date DESC
LIMIT 10
```

---

## By Movement Pattern

### Hip Hinge Workouts
```dataview
TABLE WITHOUT ID
  link(file.name) as "Workout",
  date as "Date",
  primary_muscles as "Primary Muscles"
FROM "30_Resources/Workouts Neuro"
WHERE type = "workout" AND contains(movement_patterns, "hip-hinge")
SORT date DESC
LIMIT 15
```

### Vertical Pull Workouts (Pull Ups)
```dataview
TABLE WITHOUT ID
  link(file.name) as "Workout",
  date as "Date"
FROM "30_Resources/Workouts Neuro"
WHERE type = "workout" AND contains(movement_patterns, "vertical-pull")
SORT date DESC
LIMIT 15
```

### Horizontal Push (Bench Press)
```dataview
TABLE WITHOUT ID
  link(file.name) as "Workout",
  date as "Date"
FROM "30_Resources/Workouts Neuro"
WHERE type = "workout" AND contains(movement_patterns, "horizontal-push")
SORT date DESC
LIMIT 15
```

### Knee Dominant (Squats/Lunges)
```dataview
TABLE WITHOUT ID
  link(file.name) as "Workout",
  date as "Date"
FROM "30_Resources/Workouts Neuro"
WHERE type = "workout" AND contains(movement_patterns, "knee-dominant")
SORT date DESC
LIMIT 15
```

---

## By Equipment Available

### Minimal Equipment (Bodyweight + KB)
```dataview
TABLE WITHOUT ID
  link(file.name) as "Workout",
  date as "Date",
  equipment as "Equipment"
FROM "30_Resources/Workouts Neuro"
WHERE type = "workout" AND !contains(equipment, "barbell") AND !contains(equipment, "pull-up-bar")
SORT date DESC
LIMIT 10
```

### Barbell Required
```dataview
TABLE WITHOUT ID
  link(file.name) as "Workout",
  date as "Date"
FROM "30_Resources/Workouts Neuro"
WHERE type = "workout" AND contains(equipment, "barbell")
SORT date DESC
LIMIT 15
```

### Rower/Bike Conditioning
```dataview
TABLE WITHOUT ID
  link(file.name) as "Workout",
  date as "Date",
  energy_system as "Energy System"
FROM "30_Resources/Workouts Neuro"
WHERE type = "workout" AND (contains(equipment, "rower") OR contains(equipment, "bike"))
SORT date DESC
LIMIT 15
```

---

## By Primary Muscle Group

### Posterior Chain Focus (Hamstrings/Glutes)
```dataview
TABLE WITHOUT ID
  link(file.name) as "Workout",
  date as "Date"
FROM "30_Resources/Workouts Neuro"
WHERE type = "workout" AND (contains(primary_muscles, "hamstrings") OR contains(primary_muscles, "glutes"))
SORT date DESC
LIMIT 15
```

### Upper Body Push (Chest/Shoulders)
```dataview
TABLE WITHOUT ID
  link(file.name) as "Workout",
  date as "Date"
FROM "30_Resources/Workouts Neuro"
WHERE type = "workout" AND (contains(primary_muscles, "chest") OR contains(primary_muscles, "shoulders"))
SORT date DESC
LIMIT 15
```

### Lat/Back Focus
```dataview
TABLE WITHOUT ID
  link(file.name) as "Workout",
  date as "Date"
FROM "30_Resources/Workouts Neuro"
WHERE type = "workout" AND contains(primary_muscles, "lats")
SORT date DESC
LIMIT 15
```

---

## By Energy System

### Glycolytic (High Intensity Intervals)
```dataview
TABLE WITHOUT ID
  link(file.name) as "Workout",
  date as "Date",
  duration_min + " min" as "Duration"
FROM "30_Resources/Workouts Neuro"
WHERE type = "workout" AND energy_system = "glycolytic"
SORT date DESC
LIMIT 10
```

### Aerobic (Longer Duration)
```dataview
TABLE WITHOUT ID
  link(file.name) as "Workout",
  date as "Date"
FROM "30_Resources/Workouts Neuro"
WHERE type = "workout" AND energy_system = "aerobic"
SORT date DESC
LIMIT 10
```

---

## By Duration

### Quick Workouts (< 45 min)
```dataview
TABLE WITHOUT ID
  link(file.name) as "Workout",
  date as "Date",
  duration_min + " min" as "Duration"
FROM "30_Resources/Workouts Neuro"
WHERE type = "workout" AND duration_min < 45
SORT date DESC
LIMIT 15
```

### Full Sessions (60+ min)
```dataview
TABLE WITHOUT ID
  link(file.name) as "Workout",
  date as "Date",
  duration_min + " min" as "Duration"
FROM "30_Resources/Workouts Neuro"
WHERE type = "workout" AND duration_min >= 60
SORT date DESC
LIMIT 15
```

---

## Recovery Planning

### Workouts Needing 2+ Recovery Days
```dataview
TABLE WITHOUT ID
  link(file.name) as "Workout",
  date as "Date",
  recovery_days as "Recovery Days",
  soreness_expected as "Expect Soreness In"
FROM "30_Resources/Workouts Neuro"
WHERE type = "workout" AND recovery_days >= 2
SORT date DESC
LIMIT 10
```

### Suggested Next Workout Type
```dataview
TABLE WITHOUT ID
  link(file.name) as "Workout",
  date as "Date",
  suggested_next as "Follow With"
FROM "30_Resources/Workouts Neuro"
WHERE type = "workout" AND suggested_next != null
SORT date DESC
LIMIT 15
```

---

## Phase-Based Workouts

### Foundation Phase
```dataview
TABLE WITHOUT ID
  link(file.name) as "Workout",
  date as "Date",
  week as "Week"
FROM "30_Resources/Workouts Neuro"
WHERE type = "workout" AND phase = "foundation"
SORT date ASC
LIMIT 20
```

### Strength Phase
```dataview
TABLE WITHOUT ID
  link(file.name) as "Workout",
  date as "Date"
FROM "30_Resources/Workouts Neuro"
WHERE type = "workout" AND phase = "strength"
SORT date ASC
LIMIT 20
```

---

## Volume Analysis

### High Volume Days
```dataview
TABLE WITHOUT ID
  link(file.name) as "Workout",
  date as "Date",
  volume as "Volume",
  intensity as "Intensity"
FROM "30_Resources/Workouts Neuro"
WHERE type = "workout" AND volume = "high"
SORT date DESC
LIMIT 15
```

---

## Statistics Summary

### Workouts by Month
```dataview
TABLE WITHOUT ID
  dateformat(date, "yyyy-MM") as "Month",
  length(rows) as "Count"
FROM "30_Resources/Workouts Neuro"
WHERE type = "workout"
GROUP BY dateformat(date, "yyyy-MM")
SORT rows.date DESC
```

### Most Common Equipment
```dataview
TABLE WITHOUT ID
  equip as "Equipment",
  length(rows) as "Used In"
FROM "30_Resources/Workouts Neuro"
WHERE type = "workout"
FLATTEN equipment as equip
GROUP BY equip
SORT length(rows) DESC
LIMIT 15
```

### Most Targeted Muscles
```dataview
TABLE WITHOUT ID
  muscle as "Muscle",
  length(rows) as "Workouts"
FROM "30_Resources/Workouts Neuro"
WHERE type = "workout"
FLATTEN primary_muscles as muscle
GROUP BY muscle
SORT length(rows) DESC
LIMIT 10
```

---

## Quick Links

- [[00 - Periodization Master Plan]] - Annual programming
- [[01 - Warmup Blocks]] - Warmup options
- [[02 - Dynamic Mobility Blocks]] - Mobility routines
- [[03 - Strength Blocks]] - Strength protocols
- [[04 - Conditioning Blocks]] - Conditioning formats
- [[05 - Core Finisher Blocks]] - Core & cooldowns
- [[06 - Sample Week Templates]] - Weekly schedules
- [[Workout Index]] - Full workout list

---

## Enhancement Legend

Each enhanced workout includes:

| Field | Description |
|-------|-------------|
| `movement_patterns` | hip-hinge, vertical-pull, horizontal-push, knee-dominant, carry, core-rotation |
| `equipment` | barbell, kettlebell, dumbbells, pull-up-bar, rower, bike, trx, etc. |
| `intensity` | 1-10 scale |
| `volume` | low, moderate, moderate-high, high |
| `duration_min` | Estimated workout time |
| `energy_system` | aerobic, glycolytic, mixed |
| `primary_muscles` | Main muscles targeted |
| `secondary_muscles` | Supporting muscles |
| `recovery_days` | Recommended rest before similar workout |
| `suggested_next` | Complementary workout type |
| `soreness_expected` | Muscles likely to be sore |
