---
title: "Jordan Neuro Workouts Index"
type: index
tags:
  - workout
  - index
---

# Jordan Neuro Workouts

These workouts were captured from whiteboard photos at Strive Functional Training with Jordan.

**Total Workouts Transcribed: 47**

---

## Quick Navigation

- [[00 - Periodization Master Plan]] - 12-month training framework
- [[01 - Warmup Blocks]] - Active warmup options
- [[02 - Dynamic Mobility Blocks]] - Mobility routines
- [[03 - Strength Blocks]] - Strength training protocols
- [[04 - Conditioning Blocks]] - Conditioning formats
- [[05 - Core Finisher Blocks]] - Core work and cooldowns
- [[06 - Sample Week Templates]] - Pre-built weekly templates

---

## All Workouts

```dataview
TABLE date as "Date", file.tags as "Tags"
FROM "30_Resources/Workouts Neuro"
WHERE type = "workout"
SORT date DESC
```

---

## Workouts by Month

### 2018

| Month | Workouts |
|-------|----------|
| June | [[2018-06-05 Workout]], [[2018-06-06 Workout]], [[2018-06-14 Workout]], [[2018-06-19 Workout]], [[2018-06-26 Workout]], [[2018-06-27 Workout]], [[2018-06-30 Workout]] |
| July | [[2018-07-05 Workout]], [[2018-07-11 Workout]], [[2018-07-17 Workout]], [[2018-07-19 Workout]], [[2018-07-26 Workout]] |
| August | [[2018-08-02 Workout]], [[2018-08-07 Workout]], [[2018-08-13 Workout]], [[2018-08-22 Workout]], [[2018-08-28 Workout]], [[2018-08-30 Workout]] |
| October | [[2018-10-02 Workout]], [[2018-10-09 Workout]], [[2018-10-30 Workout]] |
| November | [[2018-11-01 Workout]], [[2018-11-13 Workout]], [[2018-11-20 Workout]] |
| December | [[2018-12-03 Workout]], [[2018-12-06 Workout]], [[2018-12-12 Workout]], [[2018-12-18 Workout]], [[2018-12-20 Workout]] |

### 2019

| Month | Workouts |
|-------|----------|
| January | [[2019-01-02 Workout]], [[2019-01-07 Workout]], [[2019-01-14 Workout]], [[2019-01-21 Workout]], [[2019-01-28 Workout]] |
| February | [[2019-02-04 Workout]], [[2019-02-11 Workout]], [[2019-02-18 Workout]], [[2019-02-25 Workout]] |
| March | [[2019-03-05 Workout]], [[2019-03-11 Workout]], [[2019-03-20 Workout]], [[2019-03-25 Workout]] |
| April | [[2019-04-08 Workout]], [[2019-04-15 Workout]], [[2019-04-22 Workout]] |
| May | [[2019-05-06 Workout]], [[2019-05-13 Workout]] |

---

## Workout Types by Tag

```dataview
TABLE length(rows) as "Count"
FROM "30_Resources/Workouts Neuro"
WHERE type = "workout"
FLATTEN tags as tag
WHERE !contains(tag, "workout") AND !contains(tag, "strength") AND !contains(tag, "conditioning")
GROUP BY tag
SORT length(rows) DESC
```

---

## Common Movement Patterns

### Warmup (Active)
- Row/Bike 2 min
- Jump Rope 30-100x
- Push Ups 10x
- Air Squats 10x
- KB Swings 10-15x
- Jumping Jacks 20x
- Monster Walks
- SL Bridges 20x

### Dynamic Mobility
- Hamstring Walks
- Quad Pulls
- Spiderman
- PVC Passover
- Toy Soldiers
- High Knee Pull/Skip
- Lunge + Reach/Twist
- Arm Circles
- Carioca
- Leg Cradles

### Primary Strength Movements
- **Squat:** Goblet, Front, Back, Split
- **Hinge:** Deadlift, RDL, KB Swing
- **Press:** Bench, Overhead, Push-Up
- **Pull:** Pull-Up, Row, Lat Pulldown
- **Carry:** Farmer, Suitcase, Front Rack
- **Core:** TGU, Plank, Dead Bug

### Conditioning Formats
- **AMRAP** - As Many Rounds As Possible
- **EMOM** - Every Minute On the Minute
- **Rounds for Time** - Complete X rounds
- **Chipper** - One-time through list
- **Ladder** - 3, 6, 9, 12, 15...
- **Intervals** - Work:Rest ratios

---

## Abbreviations Reference

| Abbrev | Meaning |
|--------|---------|
| e | each side |
| SA | Single Arm |
| SL | Single Leg |
| BB | Barbell |
| KB | Kettlebell |
| DB | Dumbbell |
| MB | Medicine Ball |
| BOR | Bent Over Row |
| TGU | Turkish Get Up |
| HKTC | High Knee Toe Catch |
| ER | External Rotation |
| RDL | Romanian Deadlift |
| AMRAP | As Many Rounds As Possible |
| EMOM | Every Minute On the Minute |

---

## How to Use This System

1. **Browse workouts** - Use the tables above or Dataview queries
2. **Build custom workouts** - Mix blocks from the numbered files (01-05)
3. **Follow periodization** - Use [[00 - Periodization Master Plan]] for long-term programming
4. **Sample weeks** - See [[06 - Sample Week Templates]] for ready-to-use schedules

---

## iOS Workout App Compatible

All workouts are formatted with:
- Clear section headers (Active, Dynamic, Strength, Conditioning)
- Standard exercise notation (sets x reps)
- Mobility cues after main lifts
- Timer-friendly conditioning blocks
