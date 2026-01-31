# PT Performance Architecture

This document describes the high-level architecture, patterns, and conventions used in the PT Performance iOS app.

## Architecture Pattern: MVVM

The app follows the **Model-View-ViewModel (MVVM)** pattern with SwiftUI:

```
┌─────────────────────────────────────────────────────────────────┐
│                           Views                                  │
│  (SwiftUI views observe ViewModels via @StateObject/@ObservedObject) │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        ViewModels                                │
│  (ObservableObject classes with @Published properties)          │
│  Handle business logic, data transformation, state management   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Services                                 │
│  (Singleton services for API, caching, auth, analytics)         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                          Models                                  │
│  (Codable structs for data representation)                      │
└─────────────────────────────────────────────────────────────────┘
```

## Directory Structure

### Models (`/Models/`)

Data structures representing domain entities. All models conform to `Codable` for JSON serialization with Supabase.

**Key Models:**
- `Patient.swift`, `Exercise.swift`, `Program.swift` - Core domain
- `AppError.swift` - Centralized error types with user-friendly messages
- `DailyReadiness.swift`, `ReadinessScore.swift` - Readiness tracking
- `NutritionLog.swift`, `MealPlan.swift` - Nutrition features

### ViewModels (`/ViewModels/`)

`ObservableObject` classes that manage state and business logic for views. Each ViewModel is marked with `@MainActor` to ensure UI updates happen on the main thread.

**Pattern:**
```swift
@MainActor
class TodaySessionViewModel: ObservableObject {
    @Published var session: Session?
    @Published var exercises: [Exercise] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabase = PTSupabaseClient.shared

    func fetchTodaySession() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Fetch from service
        } catch {
            errorMessage = AppError.from(error).errorDescription
        }
    }
}
```

**Key ViewModels:**
- `TodaySessionViewModel` - Daily workout session
- `PatientListViewModel` - Therapist's patient roster
- `ProgramBuilderViewModel` - Program creation
- `NutritionDashboardViewModel` - Nutrition tracking

### Views (`/Views/`)

SwiftUI views organized by feature area:

| Directory | Purpose |
|-----------|---------|
| `Auth/` | Login, registration, password reset |
| `Patient/` | Patient home, profile, goals |
| `Therapist/` | Dashboard, patient management |
| `Exercises/` | Exercise display, logging, info |
| `Nutrition/` | Meal logging, goals, analytics |
| `Readiness/` | Daily check-in, readiness dashboard |
| `Timers/` | Interval timers, timer history |
| `Settings/` | Preferences, account, debug |
| `Onboarding/` | First-launch experience |
| `Help/` | Help articles, support |

### Services (`/Services/`)

Singleton services handling external integrations and shared functionality:

| Service | Purpose |
|---------|---------|
| `SupabaseClient.swift` | Database queries, authentication |
| `SentryConfig.swift` | Error monitoring configuration |
| `StoreKitService.swift` | In-app purchase handling |
| `SessionManager.swift` | Auth session monitoring |
| `OfflineQueueManager.swift` | Offline operation queuing |
| `ImageCacheService.swift` | Image caching |
| `AnalyticsService.swift` | Event tracking |
| `ModeService.swift` | Patient mode (athlete/rehab) |

### Components (`/Components/`)

Reusable UI components shared across views:
- `VideoPlayerView.swift` - Exercise video player
- `FilterChip.swift` - Filter selection UI
- `Charts/` - Data visualization components

### Utils (`/Utils/`)

Helpers and utilities:
- `DesignSystem.swift` - Spacing, colors, shadows, animations
- `ValidationHelpers.swift` - Form validation
- `ViewOptimizations.swift` - Performance modifiers

## Key Patterns

### @StateObject vs @ObservedObject

```swift
// @StateObject: View OWNS the ViewModel (creates and manages lifecycle)
struct PatientDetailView: View {
    @StateObject private var viewModel = PatientDetailViewModel()
}

// @ObservedObject: View RECEIVES ViewModel from parent (doesn't own it)
struct ExerciseRow: View {
    @ObservedObject var exercise: ExerciseViewModel
}

// @EnvironmentObject: Shared app-wide state
struct RootView: View {
    @EnvironmentObject var appState: AppState
}
```

### Async/Await Pattern

All async operations use Swift concurrency:

```swift
@MainActor
class ViewModel: ObservableObject {
    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let data = try await service.fetchData()
            self.data = data
        } catch {
            errorMessage = AppError.from(error).errorDescription
        }
    }
}

// In View:
.task {
    await viewModel.loadData()
}
```

### Request Deduplication

Prevents duplicate concurrent API calls:

```swift
private var fetchTask: Task<Void, Never>?

func fetchData() async {
    fetchTask?.cancel()
    fetchTask = Task {
        // ... fetch logic
    }
}
```

### Error Handling

Centralized error handling via `AppError`:

```swift
// Convert system errors to user-friendly messages
let appError = AppError.from(error)
errorMessage = appError.errorDescription
recoverySuggestion = appError.recoverySuggestion

// Check error behavior
if appError.shouldRetry { showRetryButton = true }
if appError.shouldSignOut { await signOut() }
```

### Navigation

Tab-based navigation with role-specific tabs:

```swift
// RootView determines which tab view based on role
if appState.userRole == .patient {
    PatientTabView()  // Today, Programs, Nutrition, Timers, Settings
} else if appState.userRole == .therapist {
    TherapistTabView()  // Dashboard, Patients, Programs, Settings
}
```

NavigationStack for hierarchical navigation within tabs:

```swift
NavigationStack {
    PatientListView()
        .navigationDestination(for: Patient.self) { patient in
            PatientDetailView(patient: patient)
        }
}
```

## Data Flow

```
┌──────────────────────────────────────────────────────────────┐
│                         App Launch                            │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│  PTPerformanceApp.init()                                     │
│  - Initialize Sentry                                          │
│  - Track app launch performance                               │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│  RootView.restoreSession()                                    │
│  - Check for existing Supabase session                        │
│  - Fetch user role (patient/therapist)                        │
│  - Update AppState                                            │
└──────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
┌─────────────────────────┐     ┌─────────────────────────┐
│  Not Authenticated      │     │  Authenticated          │
│  → AuthLandingView      │     │  → Check Privacy Notice │
└─────────────────────────┘     └─────────────────────────┘
                                              │
                              ┌───────────────┴───────────────┐
                              ▼                               ▼
                    ┌─────────────────┐           ┌─────────────────┐
                    │  Patient Role   │           │  Therapist Role │
                    │  PatientTabView │           │  TherapistTabView│
                    └─────────────────┘           └─────────────────┘
```

## Third-Party Dependencies

### Supabase (supabase-swift 2.0+)

- **Auth**: Email/password, Apple Sign-In, session management
- **Database**: PostgreSQL via PostgREST API
- **Edge Functions**: Server-side logic (patient registration, etc.)
- **Realtime**: Not currently used

Configuration in `SupabaseClient.swift` with flexible JSON decoder for date handling.

### Sentry (sentry-cocoa 8.40.1)

- **Error Tracking**: Automatic crash reporting
- **Performance**: App launch, transaction tracing
- **Privacy**: HIPAA-compliant filtering (no emails, auth headers)
- **Environments**: development (debug), production (release)

Configuration in `SentryConfig.swift`.

## Design System

Centralized in `Utils/DesignSystem.swift`:

```swift
// Spacing
Spacing.xs  // 8pt
Spacing.md  // 16pt
Spacing.lg  // 24pt

// Corner Radius
CornerRadius.sm  // 8pt
CornerRadius.md  // 12pt

// Animations
AnimationDuration.quick     // 0.2s
AnimationDuration.standard  // 0.3s
```

## Offline Support

`OfflineQueueManager` handles offline operations:
- Queues failed operations when offline
- Syncs pending operations on app launch and connectivity restore
- Currently used for exercise log submissions

## Testing

Test targets:
- `PTPerformanceTests/` - Unit tests
- `PTPerformanceUITests/` - UI tests

Run tests: Cmd+U in Xcode
