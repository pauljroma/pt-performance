# Modus -- App Store Connect Metadata

Reference document for completing App Store Connect submission. All fields below are ready to copy/paste into the corresponding App Store Connect fields.

---

## 1. App Name

```
Modus
```

Already set. Bundle display name matches (`CFBundleDisplayName = Modus`).

---

## 2. Subtitle

```
Train Smarter, Recover Faster
```

(30 characters exactly)

---

## 3. Description

```
Modus is the intelligent training platform that adapts to your body. Whether you are recovering from an injury, training for your sport, or building a consistent fitness routine, Modus gives you a personalized plan that adjusts to how you feel every single day.

DAILY READINESS SCORING
Every morning, Modus calculates your readiness to train based on sleep quality, heart rate variability, stress, soreness, and self-reported energy levels. Your workout intensity is automatically adjusted so you push hard on good days and recover smart on tough ones.

ADAPTIVE WORKOUT PROGRAMS
Follow structured programs that evolve with your progress. Modus tracks your sets, reps, weights, and RPE across every session, then uses that data to suggest progressive overload, deload weeks, and exercise substitutions. Swipe to complete sets, shake to quick-log, and never waste time navigating menus.

AI-POWERED COACHING INSIGHTS
Get personalized recommendations for recovery, nutrition, and performance optimization. AI features provide suggestions based on your training history and readiness data. All AI-generated content is informational only and is not a substitute for professional medical advice.

THERAPIST CONNECTION
Working with a physical therapist or coach? Modus lets your provider view your workout data, progress metrics, and readiness scores so they can guide your program remotely. Record exercise form-check videos and share them directly with your therapist for technique feedback.

APPLE HEALTH & APPLE WATCH
Sync HRV, sleep, heart rate, and workout data with Apple Health. Modus reads your recovery metrics to power readiness scoring and writes your completed workouts back for unified tracking across all your health apps. Apple Watch support lets you track workouts from your wrist.

BUILT FOR PRIVACY
Your health data belongs to you. Modus uses TLS 1.3 with certificate pinning, AES-256 encryption at rest, row-level security on every database table, and biometric protection via Face ID. We never sell your data, never show ads, and never track you for advertising purposes. HIPAA-aligned audit logging protects every access to your records.

WHO IS MODUS FOR?
- Athletes looking for structured, adaptive training programs
- Physical therapy patients tracking rehab progress with their provider
- Fitness enthusiasts who want data-driven workout planning
- Coaches and therapists managing athlete programs remotely
- Anyone who wants to train smarter, not just harder

FEATURES AT A GLANCE
- Daily readiness scores from HRV, sleep, and self-assessments
- Structured workout programs with progressive overload tracking
- Exercise library with video demonstrations
- Set/rep/weight logging with RPE and pain tracking
- AI-powered recovery and nutrition recommendations
- Therapist dashboard for remote patient monitoring
- Form-check video recording and sharing
- Apple Health bidirectional sync
- Apple Watch workout tracking
- Siri Shortcuts for hands-free logging
- iOS widgets for at-a-glance readiness and streaks
- Dark mode optimized interface
- Offline workout access

IMPORTANT: Modus is not a medical device and does not provide medical advice, diagnosis, or treatment. Content provided through the app, including exercise programs, readiness scores, and recovery recommendations, is for informational purposes only and should not be considered a substitute for professional medical advice. Always consult your physician or qualified healthcare provider before starting any exercise program.

Free to download. Premium subscription available for advanced features.
```

(3,898 characters -- within the 4,000 character limit)

---

## 4. Keywords

```
PT,physical therapy,workout,fitness,recovery,readiness,HRV,training,rehab,coach,exercise,strength
```

(97 characters -- within the 100 character limit)

**Keyword strategy notes:**
- "Modus" is already indexed from the app name, so it is not included in keywords.
- "PT" covers both "physical therapy" shorthand and "personal training" searches.
- High-value terms like "HRV," "readiness," and "rehab" differentiate from generic fitness apps.
- "coach" captures both coach-side and athlete-side search intent.

---

## 5. Category

| Field | Selection |
|-------|-----------|
| **Primary Category** | Health & Fitness |
| **Secondary Category** | Medical |

**Rationale:** The primary use case is fitness and workout tracking (Health & Fitness). The therapist connection, rehab tracking, and HIPAA-aligned features justify Medical as the secondary category. If Apple rejects Medical, use Sports as the fallback secondary.

---

## 6. Age Rating

Answer each question in the Apple age rating questionnaire as follows:

| Question | Answer |
|----------|--------|
| Unrestricted Web Access | No |
| Gambling and Contests | None |
| Simulated Gambling | None |
| Alcohol, Tobacco, or Drug Use or References | None |
| Sexual Content or Nudity | None |
| Profanity or Crude Humor | None |
| Horror/Fear Themes | None |
| Mature/Suggestive Themes | None |
| Medical/Treatment Information | Infrequent/Mild |
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |

**Resulting Rating: 12+**

The "Medical/Treatment Information" answer of "Infrequent/Mild" triggers the 12+ rating because the app displays readiness scores derived from health metrics, recovery recommendations, and facilitates therapist-patient communication about rehabilitation. The app does not diagnose conditions or prescribe treatments.

---

## 7. Privacy Nutrition Labels

Based on `PrivacyInfo.xcprivacy`, complete the App Store privacy questionnaire as follows:

### Data Used to Track You

**None.** `NSPrivacyTracking = false` and all collected data types have `NSPrivacyCollectedDataTypeTracking = false`.

### Data Linked to You

The following data types are collected and linked to your identity (`NSPrivacyCollectedDataTypeLinked = true`):

| Data Category | Data Type | Purpose |
|---------------|-----------|---------|
| **Health & Fitness** | Health | App Functionality |
| **Health & Fitness** | Fitness | App Functionality |
| **Contact Info** | Email Address | App Functionality |
| **Contact Info** | Name | App Functionality |
| **Identifiers** | User ID | App Functionality |
| **Photos or Videos** | Photos or Videos | App Functionality |
| **Other Data** | Other Data Types (therapy notes, SOAP notes, readiness assessments) | App Functionality |

### Data Not Linked to You

The following data types are collected but not linked to your identity (`NSPrivacyCollectedDataTypeLinked = false`):

| Data Category | Data Type | Purpose |
|---------------|-----------|---------|
| **Diagnostics** | Crash Data | Analytics |
| **Diagnostics** | Performance Data | Analytics |

### Summary for App Store Connect Privacy Form

When filling out the form in App Store Connect:

1. **Do you or your third-party partners collect data from this app?** Yes
2. **Is any of the collected data used for tracking purposes?** No
3. For each data type above, select "App Functionality" or "Analytics" as the purpose
4. For linked data types, confirm "Yes, linked to user's identity"
5. For crash/performance data, confirm "No, not linked to user's identity"

---

## 8. App Store Review Notes

Copy the following into the "Notes" field for the App Review team:

```
DEMO MODE:
Demo mode is available only in debug/development builds and is not included in this production binary. The app requires Sign in with Apple for authentication. No demo account is needed -- the reviewer can create a free account using any Apple ID.

HEALTHKIT USAGE:
Modus reads HRV, heart rate, sleep analysis, and step count data from HealthKit to calculate a daily readiness score and personalize recovery recommendations. Modus writes completed workout sessions back to HealthKit. HealthKit data is used solely for app functionality and is never shared with advertisers or used for tracking. HealthKit access is optional -- the app is fully functional without granting HealthKit permissions.

AI FEATURES:
AI-powered coaching insights (workout recommendations, recovery suggestions, exercise substitutions) are generated by server-side edge functions. All AI-generated content includes disclaimers that it is for informational purposes only and is not medical advice. Disclaimers appear in the Terms of Service (Section 3 and Section 4) and are surfaced in-app when AI features are used.

THERAPIST FEATURES:
The app allows licensed physical therapists and coaches to view their patients' workout data, progress metrics, and readiness scores. The app facilitates communication between therapists and patients but does not itself provide medical advice, diagnosis, or treatment. The therapist-patient relationship exists independently of the app.

BACKGROUND MODES:
The app uses "fetch" and "processing" background modes for HealthKit data sync (identifier: com.getmodus.health-sync, com.getmodus.health-processing) and background workout timer continuation (identifier: com.getmodus.timer.background).

ENCRYPTION:
This app does not use non-exempt encryption (ITSAppUsesNonExemptEncryption = NO). All encryption is handled by standard iOS/system frameworks (TLS via URLSession, Keychain, Data Protection).

SUBSCRIPTIONS:
The app offers auto-renewable subscriptions managed through StoreKit 2. Subscription management and cancellation are accessible via Apple ID Account Settings. Terms of service and privacy policy are linked in the app and on the website.

REVIEW ACCOUNT:
No special credentials are needed. Create a free account with Sign in with Apple. All core features (workout tracking, readiness scoring, exercise library) are available without a subscription. Premium features can be tested by subscribing through the sandbox environment.
```

---

## 9. What's New (Release Notes)

```
Welcome to Modus 1.0 -- your intelligent training companion.

What's inside:
- Daily readiness scoring powered by HRV, sleep, and self-assessments
- Adaptive workout programs that adjust to your progress
- Full exercise library with video demonstrations
- Set, rep, and weight tracking with RPE and pain logging
- AI-powered coaching insights for recovery and performance
- Therapist connection for remote rehab monitoring
- Form-check video recording to share with your provider
- Apple Health sync for HRV, sleep, heart rate, and workouts
- Apple Watch workout tracking
- Siri Shortcuts for hands-free logging
- Home screen widgets for readiness and streaks
- Biometric security with Face ID
- Dark mode throughout

Train smarter. Recover faster. Start today.
```

---

## 10. Support URL

```
https://getmodus.app
```

(Based on the website domain used in the landing page and contact email `support@getmodus.app`)

---

## 11. Marketing URL

```
https://getmodus.app
```

---

## 12. Privacy Policy URL

```
https://getmodus.app/privacy.html
```

---

## Additional App Store Connect Fields

### Copyright

```
2026 X2machines, LLC
```

### SKU

```
com.getmodus.app
```

### Content Rights

Does your app contain, show, or access third-party content? **No** (all content is original)

### App Store Icon

Use the app icon already configured in `ios-app/PTPerformance/Assets.xcassets/AppIcon.appiconset/`. Ensure a 1024x1024 PNG without alpha channel is available for the App Store listing.

### Screenshots Required

Prepare screenshots for:
- iPhone 6.9" display (iPhone 16 Pro Max) -- required
- iPhone 6.7" display (iPhone 15 Plus / 14 Pro Max) -- required
- iPad Pro 13" -- required if app supports iPad

Recommended screenshot subjects:
1. Daily Readiness Score (hero screen with readiness gauge and HRV/sleep stats)
2. Active Workout Session (set logging with swipe-to-complete)
3. Program Overview (structured workout calendar)
4. AI Coaching Insight (recovery or nutrition recommendation card)
5. Therapist Dashboard (patient list or shared progress view)
6. Apple Health Integration (sync confirmation or health data summary)

### App Preview Video (Optional)

15-30 second video showing: app launch, readiness check, starting a workout, completing a set, viewing AI insight. No hands or bezels required for App Store previews.
