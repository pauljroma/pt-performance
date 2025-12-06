# EPIC D – Exercise Library Metadata & Classification

## Purpose

Create a rich, extensible exercise library to support:
- Strength programming
- Mobility flows
- Plyometric sequences
- Throwing drills
- Return-to-throw criteria
- Clinical interventions

This library becomes the backbone of:
- Program builder
- Patient session UI
- Therapist editing
- AI recommendations

---

## Requirements

### D1. Exercise Taxonomy

Every exercise must include:

- **exercise_templates.name**
- **category**:
  - strength
  - mobility
  - plyo
  - bullpen
  - rehab
  - stability
  - cardio
- **body_region**:
  - shoulder, elbow, wrist
  - hip, knee, ankle
  - spine (thoracic, lumbar, cervical)
- **movement_pattern**:
  - hinge, squat, push, pull, rotation, carry
- **equipment**:
  - DB, BB, KB, bands, medball, plyo wall, mound, weighted ball
- **load_type**:
  - weight, distance, time, velocity, intent (RPE)

**Definition of Done:**
- At least 50 common exercises seeded (seed DB).
- Metadata is stored in JSON, not just text.

---

## D2. Clinical Tags

Some exercises have clinical meaning:

- contraindicated_post_surgery
- contraindicated_pain_zone
- promotes_internal_rotation
- valgus_stress_sensitive

Agents must use these tags in zone-4b decisions.

---

## D3. Throwing-Specific Tags

For drills and bullpen work:

- pitch_type_supported (array)
- ball_weight_oz
- drill_category:
  - "constraint drill"
  - "mechanical pattern"
  - "arm care"
  - "lead leg block"
- velocity_tracking_required (boolean)

---

## D4. Programming Metadata

To support automated progression:

- default_set_rep_scheme
- default_rm_method
- progression_type:
  - linear load
  - linear reps
  - undulating
  - volume wave
- tissue_capacity_rating (0–10)

---

## D5. Agent Tasks

- Seed exercise library in Supabase (50–100 items).
- Build search/filter API for therapists.
- Use metadata to auto-suggest exercises.
- Build views to show:
  - "progressions compatible with patient injury"
  - "suggested replacements for painful exercises"
