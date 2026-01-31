# PT Performance iOS App

A SwiftUI-based iOS application for physical therapy performance tracking, connecting patients with therapists for personalized workout programs, nutrition guidance, and progress monitoring.

## Overview

PT Performance enables:
- **Patients**: View daily workout sessions, log exercises, track nutrition, receive AI-powered guidance
- **Therapists**: Manage patient rosters, build custom programs, monitor progress and compliance

## Requirements

- **Xcode**: 15.0 or later
- **iOS Target**: 17.0+
- **Swift**: 5.9+
- **macOS**: Ventura 14.0+ (for development)

## Quick Start

1. Open `PTPerformance.xcodeproj` in Xcode
2. Select your target device or simulator (iOS 17+)
3. Build and run (Cmd+R)

The app connects to Supabase backend by default. For local development, environment variables can override the default configuration (see `Config.swift`).

## Project Structure

```
PTPerformance/
├── PTPerformanceApp.swift    # App entry point, Sentry init, AppState
├── RootView.swift            # Root navigation, session restoration
├── Config.swift              # App configuration (Supabase, WHOOP, AI)
│
├── Models/                   # Data models (49 files)
│   ├── Patient.swift, Exercise.swift, Program.swift
│   ├── AppError.swift        # Centralized error types
│   └── ...
│
├── ViewModels/               # ObservableObject view models (29 files)
│   ├── TodaySessionViewModel.swift
│   ├── PatientListViewModel.swift
│   └── ...
│
├── Views/                    # SwiftUI views organized by feature
│   ├── Auth/                 # Login, registration, password reset
│   ├── Patient/              # Patient-facing screens
│   ├── Therapist/            # Therapist dashboard and management
│   ├── Exercises/            # Exercise display and logging
│   ├── Nutrition/            # Meal tracking and nutrition goals
│   ├── Timers/               # Workout and interval timers
│   ├── Settings/             # App settings and preferences
│   └── ...
│
├── Services/                 # API and business logic (36 files)
│   ├── SupabaseClient.swift  # Database and auth client
│   ├── SentryConfig.swift    # Error monitoring
│   ├── StoreKitService.swift # In-app purchases
│   └── ...
│
├── Components/               # Reusable UI components
│   ├── Charts/               # Data visualization
│   ├── VideoPlayerView.swift
│   └── ...
│
├── Utils/                    # Utilities and helpers
│   ├── DesignSystem.swift    # Spacing, colors, animations
│   ├── ValidationHelpers.swift
│   └── ...
│
└── Assets.xcassets/          # App icons and images
```

## Key Features

### For Patients
- Daily session view with scheduled exercises
- Exercise logging with sets, reps, load, RPE, and pain scores
- Nutrition tracking and meal logging
- AI-powered exercise guidance and substitutions
- Progress analytics and history
- Interval timers for workouts
- WHOOP integration for recovery data
- Offline support with sync queue

### For Therapists
- Patient roster management
- Custom program builder
- Template library
- Progress monitoring dashboard
- Patient notes and flags

### Technical Features
- Supabase backend (auth, database, edge functions)
- Sentry error monitoring (HIPAA-compliant)
- StoreKit 2 subscriptions
- Apple Sign-In
- Deep link handling
- Offline queue manager

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| [supabase-swift](https://github.com/supabase/supabase-swift) | 2.0.0+ | Database, auth, edge functions |
| [sentry-cocoa](https://github.com/getsentry/sentry-cocoa) | 8.40.1 | Error and performance monitoring |

## Environment Variables

Optional overrides (set in Xcode scheme or Info.plist):

| Variable | Description |
|----------|-------------|
| `SUPABASE_URL` | Override default Supabase project URL |
| `SUPABASE_ANON_KEY` | Override default anon key |
| `SENTRY_DSN` | Sentry DSN for error reporting |
| `WHOOP_CLIENT_ID` | WHOOP API client ID |
| `WHOOP_CLIENT_SECRET` | WHOOP API client secret |

## Build and Deploy

See the following guides:
- `QUICK_LOCAL_BUILD_SETUP.md` - Local development setup
- `BUILD_AND_UPLOAD.md` - Archive and upload process
- `TESTFLIGHT_DEPLOYMENT_GUIDE.md` - TestFlight distribution

## Related Documentation

- `ARCHITECTURE.md` - Detailed architecture overview
- `WHOOP_INTEGRATION_README.md` - WHOOP API integration details
