# RUNBOOK – Data & Supabase Implementation
Zones: zone-7, zone-8, zone-10b
Goal: Implement full data layer (schema → migrations → seed → views → validation)

---

## 1. Preparation

### Inputs
- `infra/001_init_supabase.sql`
- `infra/002_epic_enhancements.sql`
- `PT_APP_DATA_MODEL_FROM_XLS.md`
- `EPIC_A`, `EPIC_B`, `EPIC_C`

### Tools
- Supabase dashboard
- Supabase CLI (`supabase db push`)
- psql (optional)
- Claude agent via `/sync-linear`

---

## 2. Steps

### Step A — Validate Schema (zone-7)
1. Load `001_init_supabase.sql` and `002_epic_enhancements.sql`.
2. Extract all table definitions.
3. Validate:
   - Foreign keys
   - Timestamp defaults
   - CHECK constraints (pain, rpe ≤ 10)
4. Compare to XLS-derived model:
   - bullpen logs
   - plyo logs
   - strength data
   - phases/sessions
5. Update schema if gaps exist.

**Definition of Done (DoD):**
- Schema covers all patient, program, S&C, bullpen, and plyo data.
- No missing entities from XLS.

---

### Step B — Push Schema to Supabase (zone-8)
Run:

```bash
supabase db push
```

If errors:
- Fix ordering
- Break file into migrations
- Re-run until schema is live

**DoD:**
- Tables created successfully
- Supabase dashboard confirms structure

---

### Step C — Seed Demo Data (zone-7, zone-8)
1. Insert:
   - 1 therapist
   - 1 patient (Brebbia sample)
   - 1 active program
   - 1 phase (week 1)
   - 3 sessions
   - 5–10 exercises per session
2. Insert bullpen + plyo logs for variety.

**DoD:**
- Today-session API can return real data.
- Therapist dashboard shows meaningful signals.

---

### Step D — Create Analytics Views (zone-7, zone-10b)

Implement:
- vw_patient_adherence
- vw_pain_trend
- vw_throwing_workload
- vw_onramp_progress (optional v1)

**DoD:**
- Views produce correct outputs for seeded patient.

---

### Step E — Data Quality Tests (zone-10b)

Implement:
- SQL queries to detect missing/invalid fields
- Unit tests for:
  - RM formulas
  - pain interpretation logic

**DoD:**
- Data quality script produces "no issues" for seeded data.

---

## 3. Final Outputs
- Fully deployed schema
- Seeded demo program
- Working analytics
- Summary comment in Linear issue
- Status moved to In Review
