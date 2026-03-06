# App Store Connect Metadata Checklist — Modus v1.0.0

## App Identity
- **App Name**: Modus
- **Bundle ID**: com.ptperformance.app
- **SKU**: (set in App Store Connect)
- **Primary Language**: English (U.S.)

## Version Information
- **Marketing Version**: 1.0.0
- **Build Number**: 616+
- **Category (Primary)**: Health & Fitness
- **Category (Secondary)**: Sports

## Description & Marketing
- **Subtitle** (30 chars max): `Athletic Performance Training`
- **Description**: See [app-description.md](app-description.md)
- **Promotional Text** (170 chars max): `Build structured training plans for your season, event, or competition. Track strength, speed, and recovery in one place.`
- **Keywords** (100 chars max): `athlete training,performance training,sprint training,strength workout,sports performance`
- **Keywords (alt)**: `strength training,sports training,athlete workout,sprint training,performance fitness`
- **What's New** (v1.0.0): See [release-notes-1.0.md](release-notes-1.0.md)

## URLs
- [x] **Privacy Policy**: https://www.getmodus.app/privacy.html
- [x] **Terms of Service**: https://www.getmodus.app/terms.html
- [x] **Support URL**: https://www.getmodus.app/support.html
- [x] **Marketing URL**: https://www.getmodus.app

## Screenshots Required
- [x] **6.7" iPhone** (1320x2868) — 3 screenshots: Today's Session, Programs, Health Hub
- [x] **6.1" iPhone** — Can reuse 6.7" set in App Store Connect
- [ ] **iPad Pro 12.9"** — Only needed if supporting iPad
- Optional: Add more screens (Settings, workout detail, achievements) for better conversion

## App Review
- [x] **Demo Account**:
  - Email: `review@getmodus.app`
  - Password: `ModusReview2026`
  - User ID: `b9f7af9a-0716-4a65-96c3-4804feba94bd`
  - Patient ID: `c171d99a-7f9c-471b-a6ca-add04ef1d335`
  - Sign-in method: Email/password on the login screen
- [x] **Review Notes**: See [review-notes.md](review-notes.md)
- [x] **Age Rating**: 4+
  - Violence: None
  - Sexual Content: None
  - Drug / Alcohol: None
  - Medical: None
  - Unrestricted web access: No
  - Contests/gambling: No

## Technical
- [x] **ExportOptions.plist**: Configured for `app-store-connect`
- [x] **PrivacyInfo.xcprivacy**: Complete privacy manifest
- [x] **App Icons**: Full set including 1024x1024 marketing icon
- [x] **Info.plist**: All privacy usage strings present
- [x] **CI/CD**: GitHub Actions workflow ready (`ios-app-store-release.yml`)

## Legal
- [x] **Privacy Policy**: Published at getmodus.app/privacy.html
- [x] **Terms of Service**: Published at getmodus.app/terms.html
- [ ] **HIPAA BAA with Supabase**: Verify in place
- [ ] **Sentry DPA/BAA**: Verify in place

## Pre-Submission Verification
- [x] Build succeeds
- [x] SwiftLint clean
- [x] Unit tests pass (PTPerformanceTests)
- [x] UI tests: 90 passed, 64 expected failures (feature-flagged features), 0 unexpected
- [x] Feature flags verified (22 MVP flags correct)
- [x] Demo mode gated (#if DEBUG)
- [x] Config versions match (1.0.0 / Build 616)
- [x] Leaderboard tab gated by feature flag (fixed this session)
