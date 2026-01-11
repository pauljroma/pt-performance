# PT Performance - Release Planning Document

**Generated:** 2026-01-11
**Repository:** pt-performance
**Linear Project:** MVP 1 — PT App & Agent Pilot
**Team:** Agent-Control-Plane (ACP)
**Linear URL:** https://linear.app/x2machines/project/mvp-1-pt-app-and-agent-pilot-d86e35fb091b

---

## Executive Summary

The PT Performance iOS application is a physical therapy performance platform designed for MLB athletes (initially John Brebbia, post-tricep strain rehab). Based on comprehensive analysis of the repository and documented Linear workspace state, here is the current status and recommended release path.

### Current State Overview

| Area | Status | Notes |
|------|--------|-------|
| **iOS App** | ✅ Build 88+ deployed to TestFlight | AI Chat, core features functional |
| **Supabase Backend** | ✅ Complete | Edge functions, RLS policies, analytics views |
| **Performance Optimization** | ✅ Wave 2 Complete | 10x Rust speedup, 4-tier routing |
| **HIPAA Compliance** | ⚠️ B+ (87/100) | 4 blockers before production launch |
| **Linear Issues** | 50 issues tracked | Most marked Done (per Dec 2025 export) |

---

## I. Current Release Status

### Build History (Recent)

| Build | Date | Key Features | Status |
|-------|------|--------------|--------|
| **88** | Dec 27, 2025 | AI Chat Complete, GPT-4 + Claude integration | ✅ TestFlight |
| **83** | Dec 26, 2025 | Demo account data (Nic Roma) | ✅ TestFlight |
| **81** | Dec 25, 2025 | AI Chat deployment | ✅ TestFlight |
| **77** | Dec 24, 2025 | AI Helper MVP (8-agent swarm) | ✅ TestFlight |
| **61** | Dec 16, 2025 | Form Validation & Accessibility | ✅ TestFlight |
| **46** | Dec 15, 2025 | New Features (Scheduling, Templates, Charts) | ✅ TestFlight |

### Completed Features

#### Core Patient Experience
- ✅ Patient authentication (email/password via Supabase)
- ✅ Today's Session view with exercise list
- ✅ Exercise logging (sets, reps, load, RPE, pain)
- ✅ Session history with chronological view
- ✅ Pain trend tracking
- ✅ Adherence percentage display
- ✅ Demo accounts (athlete + therapist)

#### Therapist Dashboard
- ✅ Patient list with flags
- ✅ Patient detail view with metrics
- ✅ Program viewer (phases → sessions → exercises)
- ✅ Notes and assessment interface

#### AI Features (Build 77-88)
- ✅ AI Chat with GPT-4 (personalized PT guidance)
- ✅ AI Safety Check with Claude 3.5 Sonnet
- ✅ AI Exercise Substitution suggestions
- ✅ Patient-context-aware responses

#### Backend Infrastructure
- ✅ Supabase schema (18+ tables)
- ✅ Analytics views (adherence, pain trend, throwing workload)
- ✅ Row-Level Security (RLS) policies
- ✅ Edge Functions (ai-chat-completion, ai-safety-check)
- ✅ Agent backend skeleton (Node.js + Express)

#### Performance (Wave 2)
- ✅ 10x Rust speedup (0.052ms latency)
- ✅ 4-tier database routing (Master, PGVector, MinIO, Athena)
- ✅ ML-based adaptive routing (75% accuracy)
- ✅ 1,700+ qps throughput
- ✅ Comprehensive monitoring dashboards

---

## II. Pre-Release Blockers

### 🔴 Critical (Must Fix Before Production)

Based on the HIPAA Compliance Review (Build 95), these 4 items MUST be resolved:

#### 1. Privacy Policy Integration
**Status:** Not implemented
**Effort:** 1-2 days
**Requirements:**
- Add Notice of Privacy Practices to app
- Add HIPAA-compliant privacy policy screen
- Get user acknowledgment on first launch
- Add Settings > Legal section

#### 2. PHI in Application Logs
**Status:** Critical gap (PHI exposed in logs)
**Effort:** 1 day
**Requirements:**
- Implement PHI scrubbing in LoggingService
- Disable verbose patient name logging in production
- Add log encryption or disable file logging in production
- Implement automatic log purging (30 days max)

#### 3. Business Associate Agreements (BAAs)
**Status:** Verification needed
**Effort:** Administrative (1-2 weeks)
**Requirements:**
- Verify signed BAA with Supabase
- Obtain BAA from OpenAI (for GPT-4 chat)
- Obtain BAA from Anthropic (for Claude safety check)
- Obtain BAA from Sentry (before enabling crash reporting)
- **Alternative:** Disable AI features until BAAs secured

#### 4. Incident Response Plan
**Status:** Not documented
**Effort:** 1-2 days
**Requirements:**
- Document breach notification procedure
- Create `SECURITY_INCIDENT_RESPONSE.md`
- Establish incident response team
- Test audit log forensics capabilities

### 🟡 Important (Should Fix Soon)

#### 5. Analytics Privacy
- Remove patient UUIDs from analytics events
- Use aggregate metrics only

#### 6. Patient Data Access UI
- Add Settings > My Data > Request Data Export
- Add audit log viewer for patients

#### 7. Sentry Crash Reporting
- Complete PHI filtering configuration
- Test crash report scrubbing

---

## III. Recommended Release Path

### Option A: Minimal Production Release (Recommended)

**Target:** 1-2 weeks
**Scope:** Address HIPAA blockers only

| Week | Tasks | Deliverable |
|------|-------|-------------|
| **Week 1** | Privacy policy integration, log sanitization | Build 96-97 |
| **Week 2** | BAA verification, incident response docs | Production Go |

**Build 96 Scope:**
- [ ] Privacy policy and Terms of Service screens
- [ ] First-launch consent flow
- [ ] PHI scrubbing in LoggingService
- [ ] Disable file logging in production builds

**Build 97 Scope:**
- [ ] Incident response documentation
- [ ] Final HIPAA compliance review
- [ ] Legal sign-off

### Option B: Feature Release + Compliance

**Target:** 3-4 weeks
**Scope:** HIPAA fixes + new features from Build 46 spec

| Week | Tasks | Deliverable |
|------|-------|-------------|
| **Week 1** | Privacy + log fixes | Build 96 |
| **Week 2** | Patient Scheduling System | Build 97 |
| **Week 3** | Workout Templates + Progress Charts | Build 98 |
| **Week 4** | Final testing, BAAs, production | Build 99 (Production) |

**New Features (from BUILD_46_FEATURES.md):**
1. **Patient Scheduling System** (HIGH priority - user requested)
   - Calendar view for workout scheduling
   - Reschedule/cancel functionality
   - Reminders

2. **Workout Templates Library** (HIGH priority)
   - Therapist creates reusable templates
   - Template categories
   - Assign to patients

3. **Progress Charts & Analytics** (MEDIUM priority)
   - Volume progress charts
   - Strength progression (1RM estimates)
   - Consistency tracking

4. **Video Exercise Demonstrations** (MEDIUM priority)
   - Video library per exercise
   - Form cues overlay

---

## IV. Linear Workspace Status

### Issue Summary (from Dec 2025 export)

**Total Issues:** 50
**Status:** Most marked "Done" in Dec 2025 snapshot

### Key Completed Issues (ACP-*)
- ACP-103: Session Handoff foundation
- ACP-83-86: Schema, seed data, analytics views
- ACP-91-99: iOS app core features
- ACP-57: Final MVP Review placeholder

### Issues Needing Updates

Based on current state, these Linear updates are recommended:

1. **Create new epic:** HIPAA Production Readiness
   - ACP-XXX: Privacy policy integration
   - ACP-XXX: Log sanitization
   - ACP-XXX: BAA verification tracking
   - ACP-XXX: Incident response plan

2. **Create Build 46 feature issues:**
   - ACP-XXX: Patient Scheduling System
   - ACP-XXX: Workout Templates Library
   - ACP-XXX: Progress Charts & Analytics

3. **Update issue statuses:**
   - Mark AI Chat issues (Build 77-88) as Done
   - Close completed performance optimization issues

---

## V. Technical Debt & Known Issues

### 1. Build Warnings (Non-Critical)
- Duplicate build file warnings (OnboardingCoordinator.swift, etc.)
- Deprecated iOS 17 onChange syntax (6 occurrences)
- Unused variable in HelpArticleView.swift

### 2. Disabled Features
- `ProgressChartsView.swift` renamed to `.broken` (missing dependencies)
- Analytics tab shows placeholder "Analytics Coming Soon"

### 3. Architecture Notes
- Config.swift shows Build 88, may need increment for next release
- WHOOP integration placeholders exist but not implemented
- AI features use edge functions (not direct API calls)

---

## VI. Release Checklist

### Pre-Release
- [ ] All HIPAA blockers resolved
- [ ] Privacy policy approved by legal
- [ ] BAAs signed with all vendors (or AI features disabled)
- [ ] Incident response plan documented
- [ ] Build number incremented in Config.swift
- [ ] TestFlight build uploaded and tested

### Release Day
- [ ] App Store submission
- [ ] Release notes prepared
- [ ] Support documentation updated
- [ ] Monitoring dashboards reviewed
- [ ] Team notified of go-live

### Post-Release
- [ ] Monitor crash reports (Sentry, when enabled)
- [ ] Track user feedback
- [ ] Monitor Linear for bug reports
- [ ] Week 1 stability review

---

## VII. Recommended Actions

### Immediate (This Week)
1. **Decide release path:** Option A (minimal) or Option B (features)
2. **Start Privacy Policy work:** Create legal review request
3. **BAA outreach:** Contact Supabase, OpenAI, Anthropic for BAA status
4. **Create Linear issues:** For HIPAA blockers

### Short-Term (2 Weeks)
1. Complete Build 96 with privacy/logging fixes
2. Document incident response procedures
3. Obtain legal sign-off on privacy policy

### Medium-Term (1 Month)
1. Production launch with HIPAA compliance
2. Begin Build 46 features (if Option B)
3. Enable Sentry crash reporting with PHI filtering

---

## VIII. Version Planning

| Version | Build Range | Target Date | Scope |
|---------|------------|-------------|-------|
| **1.0** | 88-97 | Jan 2026 | Current features + HIPAA compliance |
| **1.1** | 98-105 | Feb 2026 | Scheduling + Templates |
| **1.2** | 106-115 | Mar 2026 | Charts + Analytics |
| **1.3** | 116-125 | Apr 2026 | Video + Social |

---

## IX. Success Metrics

### Production Launch KPIs
- Zero HIPAA compliance gaps
- App Store approval on first submission
- <5% crash rate in first week
- >80% session completion rate

### Feature Adoption (Post-Launch)
- Daily active users (DAU)
- Sessions logged per week
- Therapist engagement rate
- AI chat utilization

---

## Summary

**Current Status:** TestFlight Build 88 with comprehensive feature set

**Production Blocker:** HIPAA compliance (4 critical items)

**Recommended Path:** Option A - 1-2 week sprint to resolve compliance, then production launch

**Key Decision Needed:** 
1. Confirm release scope (Option A vs B)
2. Legal review of privacy policy
3. BAA status with AI vendors

---

*Generated: 2026-01-11*
*Source: PT Performance Repository Analysis*
*Linear Project: MVP 1 — PT App & Agent Pilot*
