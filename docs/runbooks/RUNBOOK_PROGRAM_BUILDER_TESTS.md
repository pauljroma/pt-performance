# RUNBOOK – Program Builder Test Cases

## Purpose

Ensure the Program Builder:
- Accurately represents Brebbia XLS programs.
- Supports multi-phase rehab + performance flows.
- Interacts correctly with analytics and PT assistant.

---

## 1. Test Case PB1 – Basic Multi-Phase Program

Scenario:
- Create program "Tricep Rehab + In-Season Maintenance".
- Phases:
  - Phase 1: Rehab (4 weeks)
  - Phase 2: Strength (6 weeks)
  - Phase 3: In-Season Maintenance (indefinite)

Expected:
- phases table has 3 entries with correct sequence/order.
- sessions assigned correctly to each phase.
- Therapist UI displays a clear phase list.

---

## 2. Test Case PB2 – Throwing Day Integration

Scenario:
- Phase includes 2 throwing days per week.
- Bullpen + plyo integrated into sessions.

Expected:
- For throwing sessions, session_exercises include:
  - bullpen drills
  - plyo drills
- Throwing workload analytics pick up these sessions correctly.

---

## 3. Test Case PB3 – Clinical Constraints

Scenario:
- Post-op shoulder: no overhead pressing or high-velo throwing in Phase 1.

Expected:
- Program Builder:
  - prevents adding overhead exercises in Phase 1.
  - warns if a high-velocity throwing session is scheduled.
- Constraints derived from exercise metadata (`EPIC_D_EXERCISE_LIBRARY_METADATA`).

---

## 4. Test Case PB4 – Progression Over Time

Scenario:
- Strength-based progression:
  - Week 1: 3x5 @ 70%
  - Week 2: 3x5 @ 75%
  - Week 3: 3x5 @ 80%

Expected:
- Program Builder applies progression rules across sessions automatically.
- On export to DB, session_exercises reflect the correct target loads.

---

## 5. Test Case PB5 – Program Modification

Scenario:
- PT makes mid-program adjustment:
  - reduce plyo volume by 30%.
  - shift throwing ladder by a week.

Expected:
- Program Builder updates:
  - sessions and exercises.
- PT Assistant sees updated plan on next sync.
- Plan Change Request created in Linear when initiated by agent.

---

## 6. Definition of Done

- Each test case can be executed end-to-end:
  - builder → DB → analytics → PT assistant.
- Program Builder considered stable for v1.
