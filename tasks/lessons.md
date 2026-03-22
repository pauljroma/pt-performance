# Lessons Learned

## Apple App Store Review

### Demo Account Must Work End-to-End (Builds 634-637)
- Demo login credentials must be real Supabase Auth accounts with working passwords
- Password validation on sign-in forms must be relaxed (non-empty only) — complexity rules are for registration
- `fetchUserRole` must find a record linked to the correct `auth.users.id`, not a stale UUID
- Demo accounts need premium override (`StoreKitService.shared.debugPremiumOverride = true`) so reviewers don't hit paywall gates
- Always verify credentials work via `curl` against the auth endpoint before submitting

### AI Privacy Consent Required (Guideline 5.1.1/5.1.2)
- Any data sent to third-party AI (OpenAI) requires explicit in-app consent BEFORE sending
- Must disclose: what data is sent, who receives it, how it's protected
- A privacy policy mention alone is NOT sufficient — needs in-app UI prompt
- Gate all AI service calls on `ConsentManager.isGranted(.aiPersonalization)`

### IAP Must Always Show Something (Guideline 2.1b)
- SubscriptionView must handle empty products state — show error + retry, never blank
- StoreKit sandbox may fail to load products; the UI must degrade gracefully
- Apple tests on iPad even for iPhone-only apps (compatibility mode)

### Review Notes Metadata (Guideline 2.3)
- Don't use internal/clinical language ("patient profiles", "therapist")
- Keep review notes focused on user-facing features
- Match terminology to what the app actually shows

### Account Lockout Risk
- SecurityMonitor lockout was 5 attempts / 30 min — too aggressive for reviewers
- Changed to 8 attempts / 5 min lockout — still secure but reviewer-friendly

### App Icon
- App Store Connect icon comes from the binary's asset catalog, not uploaded separately
- Icons must be RGB (no alpha channel) — Apple rejects RGBA
- Generate all 13 sizes from a single 1024x1024 source

## Build Process
- Always run from `cd ios-app/PTPerformance` — xcodebuild fails from repo root
- Keychain must be unlocked before archive (see `~/.ptp_build_keychain_pass`)
- `supabase db push` migration history often out of sync — use admin API directly for one-off changes
- App Store Connect API has stale submission cleanup issues — sometimes need web UI
