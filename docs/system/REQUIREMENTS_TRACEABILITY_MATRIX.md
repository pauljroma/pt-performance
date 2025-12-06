# REQUIREMENTS TRACEABILITY MATRIX
_Link XLS → Epics → Tasks → Zones → Code_

---

| Requirement Source | Epic | Task | Zone | Code Asset |
|-------------------|------|------|------|------------|
| Personal sheet | EPIC_A | Patient Status Card | zone-7,12 | TherapistDashboardView.swift |
| Body Comp. sheet | EPIC_A | Body Comp Trends | zone-7,10b,12 | vw_body_comp + charts |
| S&C sheet | EPIC_B | 1RM Calc | zone-7,10b | strength_utils.py |
| S&C sheet | EPIC_B | Strength Targets | zone-3c | backend strength endpoint |
| Bullpen sheet | EPIC_C | Hit-Spot% | zone-7,10b | bullpen_logs + views |
| Bullpen sheet | EPIC_C | Velocity Trends | zone-7,10b,12 | velocity charts |
| On-Ramp sheet | EPIC_C | Weekly Velo Progression | zone-7,10b,12 | vw_onramp_progress |
| Plyo sheet | EPIC_C | Plyo Drill Analytics | zone-7,10b,12 | plyo_logs + UI |
| Clinical pain rules | EPIC_G | Pain Engine | zone-3c,10b | pain_engine.py |
| Return-to-throw | EPIC_RETURN_TO_THROW | RTT Engine | zone-3c,7 | rtt_engine.py |
| Dashboard | EPIC_H | Therapist Dashboard | zone-12,7 | SwiftUI views |
| AI governance | AGENT_OPERATING_MANUAL | Agent Rules | zone-4b | AGENT_OPERATING_MANUAL.md |
| Patient UX | EPIC_I | Today Session | zone-12 | TodaySessionView.swift |
| Patient UX | EPIC_I | Exercise Logging | zone-12 | ExerciseLogView.swift |
| PT Assistant | EPIC_J | Summary Endpoint | zone-3c | pt_assistant_service.py |
| PT Assistant | EPIC_J | Plan Change Creator | zone-3c,4b | plan_change_creator.py |
| Data Quality | EPIC_K | Integrity Tests | zone-10b | DATA_INTEGRITY_TESTS.md |
| Data Quality | EPIC_K | 1RM Unit Tests | zone-10b | test_strength_utils.py |
| Monitoring | EPIC_L | Agent Logs | zone-13 | agent_logs table |
| Monitoring | EPIC_L | Metrics Views | zone-13,7 | vw_agent_metrics |
| Exercise Library | EPIC_D | Seed Library | zone-7,8 | seed_exercises.sql |
| Exercise Library | EPIC_D | Clinical Tags | zone-7 | exercise_templates.clinical_tags |
| Program Builder | EPIC_E | Phase Editor | zone-12 | PhaseEditorView.swift |
| Program Builder | EPIC_E | Session Editor | zone-12 | SessionEditorView.swift |
| Program Execution | EPIC_F | getTodaySession() | zone-3c,7 | session_engine.py |
| Program Execution | EPIC_F | Skipping Logic | zone-3c | progression_engine.py |
| Throwing Workload | EPIC_THROWING_WORKLOAD | Dashboard | zone-12,7 | ThrowingWorkloadView.swift |
| Throwing Workload | EPIC_THROWING_WORKLOAD | vw_throwing_workload | zone-7 | 002_epic_enhancements.sql |

---

## Traceability Rules

1. **Every XLS sheet** → maps to at least one Epic
2. **Every Epic** → breaks into Linear issues
3. **Every Linear issue** → assigned to zones
4. **Every zone** → produces code assets
5. **Every code asset** → tested via runbooks

---

## Coverage Verification

### XLS Sheets Covered
- ✅ Personal
- ✅ S&C
- ✅ Body Comp
- ✅ Skill Tracker Bullpen
- ✅ Skill Tracker 8 Week On Ramp
- ✅ Skill Tracker Plyo Drills

### Epics Implemented
- ✅ EPIC_A - Personal & Clinical Context
- ✅ EPIC_B - Strength & S&C Model
- ✅ EPIC_C - Throwing/On-Ramp/Plyo
- ✅ EPIC_D - Exercise Library
- ✅ EPIC_E - Program Builder
- ✅ EPIC_F - Program Execution
- ✅ EPIC_G - Pain Interpretation
- ✅ EPIC_H - Therapist Dashboard
- ✅ EPIC_I - Patient App UX
- ✅ EPIC_J - PT Assistant Agent
- ✅ EPIC_K - Data Quality
- ✅ EPIC_L - Monitoring
- ✅ EPIC_THROWING_WORKLOAD
- ✅ EPIC_RETURN_TO_THROW

### Zones Utilized
- ✅ zone-7 (Data/SQL)
- ✅ zone-8 (Storage/Migrations)
- ✅ zone-10b (Tests/Quality)
- ✅ zone-12 (Mobile/SwiftUI)
- ✅ zone-3c (Backend/Agent)
- ✅ zone-4b (Approvals)
- ✅ zone-13 (Monitoring)

---

## Definition of Done

- All XLS requirements traced to code
- No orphaned epics
- All zones have clear deliverables
- Acceptance criteria linked back to XLS ground truth
