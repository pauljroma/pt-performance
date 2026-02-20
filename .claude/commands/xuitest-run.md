# Run XCUITests for the Modus app

Runs XCUITests against the iOS Simulator. Provide a test class name or `--all`.

## Arguments
- `$ARGUMENTS`: Test class name (e.g., `MultiPersonaE2ETests`) or `--all`

## Implementation

For a specific test class:
```bash
cd /Users/expo/pt-performance/ios-app/PTPerformance && \
xcodebuild test -scheme PTPerformance \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:PTPerformanceUITests/$ARGUMENTS 2>&1 | tail -40
```

For `--all`:
```bash
cd /Users/expo/pt-performance/ios-app/PTPerformance && \
xcodebuild test -scheme PTPerformance \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:PTPerformanceUITests 2>&1 | tail -40
```

## Available Test Classes

| Class | What it tests |
|-------|---------------|
| `MultiPersonaE2ETests` | All 10 patient personas: login, Today/Programs/Profile hubs |
| `TherapistMultiPatientTests` | Therapist views all 10 patients in roster |
| `AuthFlowTests` | Login, registration, password reset |
| `OnboardingFlowTests` | First-launch onboarding |
| `WorkoutExecutionFlowTests` | Exercise logging during workout |
| `DemoModeFlowTests` | Demo mode without auth |
| `HubNavigationTests` | Tab navigation between hubs |
| `ProgramFlowTests` | Program browsing and enrollment |

Parse output for `** TEST SUCCEEDED **` or `** TEST FAILED **`.
