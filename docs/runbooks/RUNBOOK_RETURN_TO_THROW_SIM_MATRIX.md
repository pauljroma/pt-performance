# RUNBOOK – Return-to-Throw Simulation Matrix

**Purpose:** Create a set of standardized return-to-throw simulation scenarios to test:
- volume progression
- intensity progression
- pain & velocity responses
- plan-change triggers

---

## 1. Axes of the Matrix

### Athlete Axis
- A: Elite pitcher (Brebbia-like)
- B: High school pitcher
- C: Post-op shoulder

### Program Axis
- P1: 8-week on-ramp (standard)
- P2: Aggressive ramp-up
- P3: Conservative / extended ramp

### Condition Axis
- C1: No complications
- C2: Pain spikes mid-program
- C3: Velocity drop mid-program
- C4: Low adherence

---

## 2. Example Simulation Cells

### Scenario A-P1-C1 (Baseline Success)
- Athlete: Elite pitcher
- Program: Standard 8-week on-ramp
- Condition: No complications
- Expectation:
  - Gradual velocity increase
  - Pain stable/low
  - No plan change needed

### Scenario A-P1-C2 (Pain Spike)
- Same program, but:
  - Pain > 5 around week 3
- Expectation:
  - Risk engine flags this
  - Plan Change Request created
  - Volume/intensity reduced next week

### Scenario B-P2-C3 (Velocity Drop)
- High school pitcher with aggressive ramp
- Velocity drops > 5 mph in week 2–3
- Expectation:
  - Severity = high
  - Engine suggests slowing progression
  - PT approval required in Linear

### Scenario C-P3-C2 (Post-Op, Pain Spike)
- Post-op shoulder on conservative ramp
- Pain 4–7 in early weeks
- Expectation:
  - Engine halts progression
  - No throwing volume increases
  - Plan Change Request emphasizes need for PT review

---

## 3. Implementation Guidelines

- Use Simulation Engine (see RUNBOOK_ATHLETE_SIMULATION_ENGINE).
- Seed each matrix scenario with:
  - program template
  - athlete profile
  - noise parameters

Sim outputs go into:
- bullpen_logs
- pain_logs
- session logs

---

## 4. Definition of Done

- At least 4–6 key scenarios implemented.
- Each scenario reliably triggers the expected flags and plan changes.
- PT assistant summaries are correct for each scenario.
