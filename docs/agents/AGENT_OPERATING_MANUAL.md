# AGENT OPERATING MANUAL
_For all LLM Agents working on the PT App & Platform_

## 1. Golden Rule
**Linear is the single source of truth.**
All work MUST start by syncing the latest Linear issues.

## 2. Required Behavior
Before every action:
1. `/sync-linear`
2. Select a task based on zone labels.
3. Read the task's Objective, Scope, and DoD.
4. Retrieve necessary context from `/docs`.

During task execution:
- Stay within Scope
- Modify only allowed files
- Write clean, minimal diffs

After execution:
- Add a Linear comment summarizing:
  - what changed
  - where
  - why
  - next steps
- Update status → In Progress or In Review

## 3. Zone Responsibilities
- **zone-7** → Data modeling, SQL, Supabase
- **zone-8** → Storage, migrations
- **zone-10b** → Tests, validation, data quality
- **zone-12** → SwiftUI, app development
- **zone-3c** → Backend logic, PT assistant
- **zone-4b** → Approval-required actions
- **zone-13** → Logs, monitoring
Agents must NEVER work outside their assigned zones.

## 4. Program Change Safety Rules
Agents may NOT:
- Give medical advice
- Modify rehab phases directly
- Increase throwing intensity without data support
- Accelerate return-to-throw phases

If a program change is warranted:
1. Create a **Plan Change Request** (zone-4b)
2. Include:
   - patient context
   - data reason
   - suggested adjustment
3. Set status = **In Review**

## 5. Clinical Logic Requirements
Use these thresholds:
- Pain > 5 → high severity
- Pain 3–5 for 2+ sessions → caution
- Velocity drop > 3 mph → medium flag
- Velocity drop > 5 mph → severe
- Adherence < 60% → caution flag
Agents must integrate these conditions into reasoning.

## 6. Coding Standards
SwiftUI:
- Small, composable views
- Use ViewModels for logic
- Use design tokens from DESIGN_TOKENS.md

SQL:
- Lowercase snake_case
- Prefix views with `vw_`

Backend:
- Clear functions:
  - getPatientSummary
  - getTodaySession
  - createPlanChangeRequest
- JSON responses only

## 7. Definition of Done (Global)
A task is done when:
- Code complies with scope
- Tests pass
- Data matches XLS expectations
- Linear issue updated with summary
- Status set to In Review

## 8. Prohibited Actions
Agents must NOT:
- Write clinical diagnoses
- Alter data outside allowed scope
- Skip Linear synchronization
- Close issues without DoD verification

## 9. Communication Style
- Clear
- Concise
- Structured
- No hallucinations
- Always cite which doc was used

---

# END OF OPERATING MANUAL
