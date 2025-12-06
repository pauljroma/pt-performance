# MOCK ATHLETE PROFILES – Standardized Test Patients

**Purpose:** Enable predictable, repeatable QA across app, backend, analytics, and agents.

---

## Profile 1 – Elite Pitcher (Brebbia Model)
- **sport:** Baseball
- **position:** RHP (relief)
- **baseline_velocity:** 93 mph
- **command_score:** 7/10
- **injury:** Tricep strain (Grade 1)
- **pain_sensitivity:** 0.6
- **adherence_tendency:** 0.95
- **PT goals:**
  - Return-to-throw progression
  - Stabilization of elbow pain
  - Maintain velocity during in-season

---

## Profile 2 – High School Pitcher (Developmental)
- **baseline_velocity:** 78 mph
- **command:** 4/10
- **moderate injury history** (rotator cuff tendinitis)
- **adherence:** 0.7
- **pain_sensitivity:** 0.8
- **Goals:**
  - Improve mechanics
  - Build strength baseline
  - Complete 8-week on-ramp

---

## Profile 3 – Post-Op Shoulder Patient
- **surgery_date:** recent
- **pain baseline:** 4–6
- **NO throwing in early phases**
- **Goals:**
  - Phase 1 controlled ROM
  - Phase 2 isometric activation
  - Phase 3 strength

---

## Profile 4 – Collegiate Position Player (Performance Focus)
- **sport:** Baseball
- **position:** SS/2B
- **baseline_squat:** 315 lbs (1RM)
- **baseline_bench:** 225 lbs
- **injury:** None (healthy)
- **pain_sensitivity:** 0.4
- **adherence_tendency:** 0.85
- **Goals:**
  - Increase lower body power
  - Maintain upper body strength
  - Improve sprint times

---

## Profile 5 – Weekend Warrior (Recreational Adult)
- **age:** 42
- **sport:** Recreational baseball
- **chronic conditions:** Lower back stiffness
- **adherence:** 0.6
- **pain_sensitivity:** 0.7
- **Goals:**
  - Pain-free participation
  - Gradual strength restoration
  - Injury prevention focus

---

## Definition of Done
- Agents must generate correct analytics & flags on all profiles.
- Program builder must produce phase-appropriate plans for each.
- PT assistant must never violate clinical constraints for Profiles 1 and 3.
- Each profile has seed data that can be auto-loaded for testing.
