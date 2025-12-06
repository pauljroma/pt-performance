# EPIC – Therapy Protocol Manager

## Purpose
Design a reusable system for:
- Post-op protocols
- Chronic condition management
- PT/AT rehab guidelines
- Session-by-session constraints

---

## Features

### 1. Protocol Templates
Each protocol defines:
- Phases (ROM → activation → strength → plyo → throw)
- Allowed exercises by phase
- Forbidden exercises
- Load ceilings
- Pain ceilings
- Progression conditions

### 2. Dynamic Adaptation
The system modifies:
- load
- volume
- exercise selection
based on pain + adherence rules.

### 3. Agent Integration
Agents should be able to:
- Validate session against protocol
- Suggest safe modifications
- Raise zone-4b request when major deviation required

### 4. UI Integration
Therapist sees:
- Current phase
- Allowed → recommended → forbidden lists
- PT assistant explanation

---

## Data Model

### protocol_templates
- id (uuid)
- name (e.g., "Tommy John Surgery - Conservative")
- description
- injury_type
- surgery_type (if applicable)
- created_by (therapist_id)
- created_at

### protocol_phases
- protocol_template_id
- phase_name (e.g., "ROM Restoration")
- sequence
- duration_weeks
- allowed_exercise_categories (json array)
- forbidden_exercise_ids (json array)
- max_load_pct (of baseline or 1RM)
- max_pain_threshold
- progression_criteria (json)

### protocol_constraints
- protocol_phase_id
- constraint_type (load_ceiling, pain_ceiling, volume_ceiling)
- constraint_value
- enforcement_rule (hard_block, warn, suggest_alternative)

---

## Business Rules

### Rule 1: Phase Advancement
Patient can advance to next phase only if:
- Duration minimum met
- Pain trend stable or improving
- Progression criteria satisfied
- PT approval obtained (zone-4b)

### Rule 2: Exercise Selection
Program builder:
- Shows only allowed exercises for current phase
- Grays out forbidden exercises
- Suggests alternatives if selection blocked

### Rule 3: Load Management
If protocol specifies max_load_pct = 70:
- Target loads auto-capped at 70% of baseline
- PT assistant flags if prescription exceeds limit
- Requires plan change request to override

### Rule 4: Pain Monitoring
If pain exceeds protocol threshold:
- Auto-flag raised
- Next session intensity reduced
- Plan change request created if sustained

---

## Agent Tasks

### Task 1 - Build Protocol Schema (zone-7, zone-8)
- Create tables: protocol_templates, protocol_phases, protocol_constraints
- Seed common protocols:
  - Tommy John (conservative)
  - Tommy John (aggressive)
  - Rotator cuff repair
  - ACL reconstruction
  - General return-to-sport

### Task 2 - Program Builder Integration (zone-12)
- Protocol selector in program creation
- Phase editor respects protocol constraints
- Exercise picker filters by protocol rules
- Visual indicators for allowed/forbidden

### Task 3 - PT Assistant Validation (zone-3c)
- Before suggesting plan changes, check protocol
- If change violates protocol → escalate to zone-4b
- If change within protocol → suggest directly

### Task 4 - Linear Workflow (zone-4b)
- Protocol override requests require higher approval
- Flag "protocol-deviation" label
- Include protocol rationale in issue

---

## UI Mockup (Text)

### Program Creation Screen
```
┌─────────────────────────────────┐
│ Create Program                  │
├─────────────────────────────────┤
│ Patient: John Brebbia           │
│ Injury: Tricep Strain (Grade 1) │
│                                 │
│ Protocol Template:              │
│ ┌─────────────────────────────┐ │
│ │ [▼] Tricep Rehab Protocol   │ │
│ └─────────────────────────────┘ │
│                                 │
│ Phases (Auto-generated):        │
│ ✓ Phase 1: ROM (Week 1-2)      │
│ ✓ Phase 2: Activation (Week 3) │
│ ✓ Phase 3: Strength (Week 4-6) │
│ ✓ Phase 4: Return-to-Throw     │
│                                 │
│ [Create Program]                │
└─────────────────────────────────┘
```

### Exercise Selection (Phase 1: ROM)
```
┌─────────────────────────────────┐
│ Add Exercise - ROM Phase        │
├─────────────────────────────────┤
│ Allowed:                        │
│ ✓ Passive ROM                   │
│ ✓ Pendulum exercises            │
│ ✓ Gentle stretching             │
│                                 │
│ Forbidden (grayed):             │
│ ✗ Heavy pressing                │
│ ✗ Overhead work                 │
│ ✗ Throwing drills               │
│                                 │
│ Protocol: Max pain = 3/10       │
│ Protocol: No load >5 lbs        │
└─────────────────────────────────┘
```

---

## Definition of Done

- Protocol templates operational
- Program builder validates against templates
- Agents enforce safety via Linear
- PT can override with approval
- At least 3 common protocols seeded
- Documentation complete
