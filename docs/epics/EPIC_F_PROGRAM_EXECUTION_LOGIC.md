# EPIC F – Program Execution Logic

## Purpose

Define how the system determines:
- What "today's session" is
- How programs advance
- How skipping affects schedule
- How agents should modify plans safely

---

## Requirements

### F1. Determining Today's Session

Inputs:
- active program
- phase sequence
- session sequence
- patient local date
- throwing frequency

Algorithm:
1. Identify active phase.
2. Determine session for current day by:
   - sequence OR
   - weekday
3. Mark "missed" if >48 hours behind.

### F2. Skipping Logic

If patient misses:
- 1 day → keep phase
- 2–3 days → repeat prior session
- 4+ days → move back one full week (plan-change request)

### F3. Progression Rules

Strength:
- If pain < 3 and all reps completed → increase load 2–5%
- If pain 4–5 → maintain
- If pain > 5 → propose plan change (zone-4b)

Throwing:
- If velocity stable or rising → increase throwing volume
- If velocity drop >3 mph → maintain
- If pain spike → auto-flag

### F4. Agent Tasks

- Implement getTodaySession() backend.
- Implement skipping and auto-adjust logic.
- Create Plan Change Request generator.
