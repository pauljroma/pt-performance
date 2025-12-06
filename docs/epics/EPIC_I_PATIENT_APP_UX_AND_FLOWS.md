# EPIC I – Patient App UX & Flows (iPhone-first)

## I.1 Purpose

Define a clean, low-friction experience for patients/athletes to:
- See today's plan
- Log work + pain quickly
- View basic progress
- Ask simple questions

This is **not** a clinical chart; it is a guided training/recovery companion.

---

## I.2 Primary Screens

### I.2.1 Home / Today

Elements:
- Program name + phase (e.g., "On-Ramp – Week 3")
- Session title ("Day 2 – Lower Body + Plyo")
- "Estimated time" (optional)
- "Start Session" button

Acceptance criteria:
- One tap from app open to "Start Session"
- Shows message if no program is active ("No scheduled work today")

---

### I.2.2 Session Execution Screen

For each exercise:
- Exercise name
- Target sets/reps/load
- Optional image or simple icon
- Expansion panel for:
  - Notes/cues
  - Demo (later)

Logging:
- For each set:
  - Actual reps
  - Actual load
  - RPE (0–10)
  - Optional per-exercise pain (0–10 slider)

Session-level:
- Overall pain (before / during / after)
- Free-text notes

UX requirements:
- Swiping between exercises
- "Complete Set" button
- "Skip exercise" with reason (pain, time, equipment)

---

### I.2.3 Session Complete

After submission:
- Confirmation screen:
  - Completed exercises
  - Summary: "3 sets, avg pain 2/10"
- Optional prompt:
  - "Anything feel off?" → notes

---

### I.2.4 History / Progress

Simple, not a full analytics suite:
- List of past sessions (date, completion %, pain indicator)
- Tap into a session to see logged sets + notes
- Basic charts:
  - Pain trend
  - Adherence over last 4 weeks

---

## I.3 Agent Considerations

Agents in zone-12:
- Implement SwiftUI views and navigation.
- Ensure patient-side logic never exposes internal formulas (1RM, tissue capacity) beyond needed cues.
- Respect clinical rules from `EPIC_G_PAIN_INTERPRETATION_MODEL.md`.

---

## I.4 Tasks Examples (for Linear)

- "Design Today Session view UX in SwiftUI." (zone-12)
- "Wire Today Session to Supabase today-session endpoint." (zone-12, zone-7)
- "Implement session logging UI and submission." (zone-12)
- "Implement basic pain/adherence charts in History tab." (zone-12, zone-7)
