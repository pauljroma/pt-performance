# CLAUDE.md -- Modus iOS App

This file is the authoritative source of truth for Claude Code working in this repository.

## Core Directive

Quality-first iOS development for a HIPAA-compliant physical therapy and fitness platform. Every code change must build, pass lint, and pass tests before it is considered complete. Patient health data is protected information -- treat it accordingly.

## Architecture

- **Pattern**: MVVM with SwiftUI. ViewModels are `@MainActor class ... : ObservableObject`.
- **DB Access**: Always through `PTSupabaseClient.shared` singleton (`Services/SupabaseClient.swift`). Never instantiate a second client.
- **Date Decoding**: Use `PTSupabaseClient.flexibleDecoder` for all manual Supabase response decoding. The backend returns mixed `TIMESTAMPTZ`, `TIMESTAMP`, and `DATE` formats.
- **Edge Functions**: All AI features route through Supabase Edge Functions in `supabase/functions/`. Never call OpenAI/Anthropic APIs directly from client code.
- **Security Layer**: `Services/Security/` contains `AuditLogger`, `DataEncryptionService`, `SecureStore`, `PatientDataGuard`, `BiometricAuthService`, `JailbreakDetector`. Use these; do not bypass.

## iOS Code Standards

- Mark all ViewModels `@MainActor`. Published properties must update on main thread.
- Use `async/await` for all network calls. No completion handlers for new code.
- Codable models live in `Models/`. Match property names to Supabase column names (snake_case via `CodingKeys`).
- SwiftUI views go in `Views/`, components in `Components/`, extensions in `Extensions/`.
- Config constants in `Config.swift`. Product IDs, API URLs, feature flags -- all centralized there.
- Accessibility identifiers are required on all interactive elements (see `AuthFlowTestHelper.AccessibilityID`).

## Supabase Rules

- **RLS Always On**: Every table must have Row Level Security policies. Never disable RLS, even for migrations.
- **No Raw SQL from Client**: All queries go through the Supabase Swift SDK via `PTSupabaseClient.shared.client`.
- **Migrations**: Numbered files in `supabase/migrations/` using format `YYYYMMDDHHMMSS_description.sql`. Always use `ON CONFLICT DO NOTHING` for seed data (idempotency).
- **Edge Functions**: TypeScript, deployed via `supabase/functions/deploy_ai_functions.sh`. Test with `supabase/functions/test_ai_functions.sh`.
- **Auth**: Supabase Auth with Apple Sign In (`Services/AppleSignInService.swift`) and magic link. Demo mode bypasses auth for testing.

## Test User Personas (10 Mock Patients)

Therapist: **Sarah Thompson** `00000000-0000-0000-0000-000000000100` (demo-pt@ptperformance.app)

| # | Name | UUID (aaaaaaaa-bbbb-cccc-dddd-...) | Sport | Injury | Mode |
|---|------|-------------------------------------|-------|--------|------|
| 1 | Marcus Rivera | ...000000000001 | Baseball | Labrum Repair | rehab |
| 2 | Alyssa Chen | ...000000000002 | Basketball | ACL Reconstruction | rehab |
| 3 | Tyler Brooks | ...000000000003 | Football | Hamstring Strain | performance |
| 4 | Emma Fitzgerald | ...000000000004 | Soccer | Ankle Sprain | rehab |
| 5 | Jordan Williams | ...000000000005 | CrossFit | Rotator Cuff Tendinitis | strength |
| 6 | Sophia Nakamura | ...000000000006 | Swimming | Shoulder Impingement | rehab |
| 7 | Deshawn Patterson | ...000000000007 | Track & Field | Quad Strain | performance |
| 8 | Olivia Martinez | ...000000000008 | Volleyball | Patellar Tendinitis | strength |
| 9 | Liam O'Connor | ...000000000009 | Hockey | Hip Labral Tear | rehab |
| 10 | Isabella Rossi | ...00000000000a | Tennis | Tennis Elbow | strength |

Seed SQL: `supabase/migrations/20260217200000_seed_10_mock_patients.sql`
Comprehensive data: `supabase/migrations/20260220000000_seed_comprehensive_test_data.sql`

## Post-Code-Change Checklist

After every code change, run these in order:

```bash
# 1. Build
cd ios-app/PTPerformance && xcodebuild -scheme PTPerformance -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5

# 2. Lint
cd ios-app/PTPerformance && swiftlint lint --config .swiftlint.yml --quiet

# 3. Unit Tests
cd ios-app/PTPerformance && xcodebuild test -scheme PTPerformance -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:PTPerformanceTests 2>&1 | tail -20

# 4. UI Tests (before TestFlight only)
cd ios-app/PTPerformance && xcodebuild test -scheme PTPerformance -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:PTPerformanceUITests 2>&1 | tail -20
```

## Common Anti-Patterns -- DO NOT

- **Do not** store patient data in UserDefaults. Use `SecureStore` or Supabase.
- **Do not** use `force_cast` or `force_try` outside previews and sample data.
- **Do not** create new SupabaseClient instances. Use `PTSupabaseClient.shared`.
- **Do not** bypass RLS with `service_role` key in client code. Service key stays server-side.
- **Do not** hardcode UUIDs in production code. Test UUIDs above are for test data only.
- **Do not** call AI APIs (OpenAI, Anthropic) directly from Swift. Route through edge functions.
- **Do not** commit `.env` files. Secrets go in Xcode scheme environment variables or App Store Connect.
- **Do not** skip `@MainActor` on ViewModels. UI state updates off main thread cause crashes.
- **Do not** write migrations without `ON CONFLICT` clauses for insert operations.

## Key File Paths

| Purpose | Path |
|---------|------|
| App entry | `ios-app/PTPerformance/PTPerformanceApp.swift` |
| Root navigation | `ios-app/PTPerformance/RootView.swift` |
| Supabase client | `ios-app/PTPerformance/Services/SupabaseClient.swift` |
| Config/secrets | `ios-app/PTPerformance/Config.swift` |
| SwiftLint config | `ios-app/PTPerformance/.swiftlint.yml` |
| Xcode project | `ios-app/PTPerformance/PTPerformance.xcodeproj/project.pbxproj` |
| Edge functions | `supabase/functions/` |
| Migrations | `supabase/migrations/` |
| UI Tests | `ios-app/PTPerformance/PTPerformanceUITests/` |
| Build runbook | `.claude/BUILD_RUNBOOK.md` |
| Migration runbook | `.claude/MIGRATION_RUNBOOK.md` |

## Current Build

Build **637** (check `CURRENT_PROJECT_VERSION` in `project.pbxproj` for latest). Bundle ID: `com.ptperformance.app`. Scheme: `PTPerformance`. App name: **Korza Training**.

## Workflow Orchestration

### 1. Plan Mode Default
- Enter plan mode for any non-trivial task (3+ steps or architectural decisions).
- If something goes sideways, stop and re-plan immediately.
- Use plan mode for verification steps, not just building.
- Write detailed specs upfront to reduce ambiguity.

### 2. Subagent Strategy
- Use subagents liberally to keep the main context window clean.
- Offload research, exploration, and parallel analysis to subagents.
- For complex problems, throw more compute at it via subagents.
- Use one task per subagent for focused execution.

### 3. Self-Improvement Loop
- After any correction from the user, update `tasks/lessons.md` with the pattern.
- Write rules that prevent the same mistake from recurring.
- Ruthlessly iterate on these lessons until the mistake rate drops.
- Review lessons at session start for the relevant project.

### 4. Verification Before Done
- Never mark a task complete without proving it works.
- Diff behavior between main and your changes when relevant.
- Ask: "Would a staff engineer approve this?"
- Run tests, check logs, and demonstrate correctness.

### 5. Demand Elegance (Balanced)
- For non-trivial changes, pause and ask: "Is there a more elegant way?"
- If a fix feels hacky, reframe: "Knowing everything I know now, implement the elegant solution."
- Skip this for simple, obvious fixes; do not over-engineer.
- Challenge your own work before presenting it.

### 6. Autonomous Bug Fixing
- When given a bug report, just fix it. Do not ask for hand-holding.
- Identify logs, errors, and failing tests, then resolve them.
- Require zero context switching from the user.
- Go fix failing CI tests without being told how.

## Task Management
1. **Plan First:** Write the plan to `tasks/todo.md` with checkable items.
2. **Verify Plan:** Check in before starting implementation.
3. **Track Progress:** Mark items complete as you go.
4. **Explain Changes:** Provide a high-level summary at each step.
5. **Document Results:** Add a review section to `tasks/todo.md`.
6. **Capture Lessons:** Update `tasks/lessons.md` after corrections.

## Core Principles
- **Simplicity First:** Make every change as simple as possible. Minimize code impact.
- **No Laziness:** Find root causes. Avoid temporary fixes. Maintain senior developer standards.
- **Minimal Impact:** Only touch what is necessary. Avoid side effects and new bugs.
