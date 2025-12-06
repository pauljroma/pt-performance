# EPIC H – Therapist Dashboard (iPad Optimized)

## Purpose

Provide a high-signal, low-noise summary of:
- adherence
- pain
- velocity (if pitcher)
- flags
- recent sessions

---

## Requirements

### H1. Patient List (Therapist Tab)

Columns:
- name
- last session date
- adherence %
- current phase
- pain indicator (green/yellow/red)
- flag count

### H2. Patient Detail Screen

Sections:
1. **Header**
   - Name, age
   - Active program
   - Current phase
   - Injury summary

2. **Charts**
   - Pain trend
   - Strength/velocity trend (if applicable)

3. **Sessions**
   - List of recent sessions
   - Tap to open logs

4. **Flags**
   - "Pain spike"
   - "Low adherence"
   - "Velocity drop"
   - "Command decline"

### H3. Agent Tasks

- Build SwiftUI screens
- Wire Supabase queries
- Incorporate flags from Backend
