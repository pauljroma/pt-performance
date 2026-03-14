# Modus 90-Day Post-Launch Roadmap

**Start date:** 1.0 public launch
**Baseline:** Patient MVP (Today, Workouts, Recovery, Settings)

---

## Month 1: Retention and Progress Polish (Weeks 1-4)

### Product Scope
- Workout completion celebrations and progress visualization
- Weekly summary improvements with trend indicators
- Streak recovery mechanics (missed-day grace period)
- Push notification tuning for daily engagement
- Bug fixes from launch feedback

### Engineering Tasks
- [ ] Instrument workout completion funnel (start -> complete -> log)
- [ ] Add progress chart to Recovery tab (7-day and 30-day views)
- [ ] Implement streak grace period logic (1 missed day before reset)
- [ ] Configure push notification schedule (morning readiness, workout reminder)
- [ ] Fix any crash reports from Sentry within 48h SLA
- [ ] Add client-side analytics events for key user actions

### Testing Expansion
- [ ] Enable `ios-ci.yml` unit tests in CI (currently re-enabled)
- [ ] Add smoke tests for workout start/complete flow
- [ ] Add integration test for streak calculation logic
- [ ] Set up TestFlight beta group for external testers (10-20 users)

### Rollout Gates
- 1.0 live in App Store
- Crash-free rate > 99%
- Day-1 retention > 40%
- No P0 bugs open

### Success Metrics
| Metric | Target |
|--------|--------|
| DAU/MAU ratio | > 20% |
| Workout completion rate | > 60% of started workouts |
| Day-7 retention | > 25% |
| Crash-free sessions | > 99.5% |
| App Store rating | > 4.0 |

---

## Month 2: Bounded AI Guidance and Summaries (Weeks 5-8)

### Product Scope
- Enable AI exercise substitution (already built, flag ON)
- Post-workout AI summary (short, motivating, non-medical)
- Weekly AI review summary via push notification
- AI progressive overload suggestions during workout
- HealthKit data integration for readiness scoring

### Engineering Tasks
- [ ] Enable `ai_substitution_enabled` remotely (already default ON)
- [ ] Build post-workout summary edge function (short text, no medical claims)
- [ ] Enable `ai_progressive_overload_enabled` remotely
- [ ] Implement weekly AI digest push notification
- [ ] Add HealthKit sleep + HRV data to readiness algorithm
- [ ] Add AI response caching to reduce edge function costs
- [ ] Review and update privacy nutrition label if data collection changes

### Testing Expansion
- [ ] Add edge function integration tests for AI endpoints
- [ ] Add UI test for exercise substitution flow
- [ ] Load test edge functions (target: < 2s p95 response time)
- [ ] Expand TestFlight beta to 50-100 users

### Rollout Gates
- Month 1 metrics met
- AI edge functions pass integration tests
- AI responses reviewed for medical claim compliance
- Privacy policy updated if new data types collected

### Success Metrics
| Metric | Target |
|--------|--------|
| AI substitution usage | > 10% of workouts |
| Post-workout summary engagement | > 30% read rate |
| HealthKit opt-in rate | > 40% |
| Edge function p95 latency | < 2 seconds |
| No AI-related support tickets | < 5/week |

---

## Month 3: Therapist Private Beta and Paywall (Weeks 9-12)

### Product Scope
- Therapist mode private beta (invite-only, 5-10 therapists)
- Patient-therapist linking flow
- Therapist dashboard: patient list, progress overview
- Subscription paywall for premium features
- In-app purchase verification end-to-end

### Engineering Tasks
- [ ] Enable `therapist_mode_enabled` for beta therapist accounts only (remote flag + allowlist)
- [ ] Enable `therapist_linking_enabled` for linked patients
- [ ] Build therapist dashboard with patient list and progress cards
- [ ] Implement StoreKit 2 subscription flow
- [ ] Enable `paywall_enabled` with free tier baseline
- [ ] Add subscription status to user profile
- [ ] Implement receipt validation via edge function
- [ ] Add therapist-specific RLS policies for patient data access

### Testing Expansion
- [ ] Add UI tests for therapist login and dashboard
- [ ] Add integration tests for patient-therapist linking
- [ ] Add StoreKit testing with sandbox environment
- [ ] Add RLS tests for therapist data access patterns
- [ ] Full regression suite for patient MVP (ensure no regressions)

### Rollout Gates
- Month 2 metrics met
- Therapist beta feedback positive (NPS > 30)
- StoreKit sandbox purchases verified
- RLS policies pass audit for therapist access patterns
- Legal review of therapist data access consent

### Success Metrics
| Metric | Target |
|--------|--------|
| Therapist beta signups | 5-10 therapists |
| Patient-therapist links | > 20 active links |
| Subscription conversion | > 2% of MAU |
| Therapist NPS | > 30 |
| Zero patient data leaks | 0 incidents |

---

## Post-90-Day Candidates (Prioritize Based on Data)

These features are built or partially built but require metrics-driven prioritization:

| Feature | Prerequisite |
|---------|-------------|
| Baseball pack | Sufficient baseball-sport users in cohort |
| Pain tracking | Therapist beta validates clinical workflow |
| Body composition tools | HealthKit integration stable |
| Nutrition/fasting | AI guidance compliance reviewed |
| WHOOP integration | Partnership agreement |
| Leaderboards/social | Community size > 1000 MAU |
| Advanced analytics | Sufficient data volume for meaningful insights |
