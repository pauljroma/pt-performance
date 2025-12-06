# EPIC E – Program Builder Specification

## Purpose

Give therapists a structured, intuitive editor to build:
- Multi-week phases
- Daily sessions
- Exercise prescriptions
- Loading progressions
- Throwing ladders
- Rehab flows

---

## Requirements

### E1. Phase Editor

Fields:
- name
- sequence
- duration (weeks)
- goals
- constraints:
  - no overhead work until week X
  - max intensity %

Agents should enforce these.

### E2. Session Editor

Fields:
- name
- weekday
- intensity rating (0–10)
- throwing day? (boolean)
- notes

UI:
- Drag-and-drop to reorder exercises
- Quick-add features

### E3. Exercise Prescription Editor

Includes:
- target_sets
- target_reps
- target_load (manual or auto-computed)
- target_rpe
- tempo
- notes

Auto-population features:
- Load suggestions from strength model
- Constraints from clinical tags

### E4. Throwing Integration

For pitching-specific days:
- ball weight sequence
- pitch types to include
- max pitch count
- subjective command target

### E5. Agent Tasks

- Build SwiftUI Program Builder (PT-only)
- Write backend logic
- Auto-apply progressions week to week
- Error-check based on metadata
