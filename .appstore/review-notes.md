# App Review Notes — Modus v1.0.0

## Demo Account

- **Email**: review@getmodus.app
- **Password**: ModusReview2026
- **Sign-in method**: Tap "Sign in with Email" on the login screen, enter the email and password above.

## Testing Instructions

1. **Sign in** using the demo credentials above
2. **Today tab**: Shows your daily session, active programs, and performance status
3. **Workouts tab**: Browse 18 training programs. Tap any program to preview it. Tap "Enroll" to add it to your active programs.
4. **Recovery tab**: View health metrics including recovery score, fasting status, supplements, and lab alerts. Tap "Check In Now" to log a daily check-in.
5. **Settings tab**: View profile, app preferences, and account management

## Features That Require Special Hardware

- **Apple Health integration**: Requires a physical device with HealthKit. The app will prompt for HealthKit permissions when relevant features are accessed. If testing on a simulator, health data features will show placeholder states.
- **Face ID / Touch ID**: Biometric app lock is available in Settings. Falls back gracefully on devices without biometrics.
- **Apple Sign In**: Available as an alternative sign-in method on the login screen.

## Notes

- This app does not require a subscription to use core features during the review period.
- The app does not make medical claims or provide medical diagnoses. It is a training and fitness tracking tool.
- All health data is stored securely with AES-256 encryption and protected by row-level security policies.
- The app does not track users for advertising purposes.
