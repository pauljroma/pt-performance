# PT Performance
## Strategic Roadmap & Business Case

**Prepared:** February 2026
**Version:** 1.0
**Classification:** Confidential

---

# Executive Summary

PT Performance is a mobile-first platform revolutionizing physical therapy outcomes through real-time patient monitoring, therapist decision support, and AI-powered adaptation. The platform serves as "the operating system for physical therapy outcomes."

**Key Highlights:**
- **Market Opportunity:** $45B fragmented PT market with 70% patient non-completion rate
- **Product:** Production-ready iOS app (Build 88+) with 27 AI-powered edge functions
- **Differentiation:** Only platform combining PT-designed arm care, pain-aware AI, and parent transparency
- **Revenue Model:** B2C subscriptions ($99-148/yr) + B2B clinic partnerships ($3K-10K ACV)
- **Ask:** Strategic partnership and go-to-market support for initial market validation

---

# Table of Contents

1. [The Problem](#1-the-problem)
2. [The Solution](#2-the-solution)
3. [Market Opportunity](#3-market-opportunity)
4. [Product Overview](#4-product-overview)
5. [Competitive Landscape](#5-competitive-landscape)
6. [Business Model](#6-business-model)
7. [Go-to-Market Strategy](#7-go-to-market-strategy)
8. [Strategic Roadmap](#8-strategic-roadmap)
9. [Financial Projections](#9-financial-projections)
10. [Team & Execution](#10-team--execution)
11. [Investment & Use of Funds](#11-investment--use-of-funds)
12. [Risks & Mitigations](#12-risks--mitigations)
13. [Appendix](#13-appendix)

---

# 1. The Problem

## Physical Therapy is Broken

The physical therapy industry faces a critical outcomes crisis:

| Problem | Impact |
|---------|--------|
| **70% non-completion rate** | Patients abandon programs before reaching outcomes |
| **Zero visibility between visits** | PTs have no idea what patients do at home |
| **Documentation burden** | 40% of PT time spent on paperwork, not patients |
| **No outcome differentiation** | Clinics can't prove they're better than competitors |
| **Reimbursement pressure** | Declining rates require efficiency gains |

## The Throwing Athlete Crisis

Baseball specifically faces an injury epidemic:

- **UCL injuries up 400%** in youth baseball over 20 years
- **$30M+ spent annually** on Tommy John surgeries in MLB alone
- **No standardized arm care** protocols outside elite programs
- **Parents left in the dark** about their child's training compliance
- **Coaches lack visibility** into athlete readiness and recovery

## Why Now?

Several tailwinds make this the optimal time:

1. **Post-COVID digital adoption** - Patients expect app-based engagement
2. **Value-based care shift** - Payers rewarding outcomes, not visits
3. **Remote monitoring reimbursement** - New CPT codes for digital PT
4. **Consumerization of healthcare** - Patients choosing providers like products
5. **Wearable proliferation** - WHOOP, Apple Watch data available for integration

---

# 2. The Solution

## PT Performance Platform

A comprehensive ecosystem connecting patients, therapists, coaches, and parents around outcomes.

### Core Value Propositions

| Stakeholder | Value Delivered |
|-------------|-----------------|
| **Patients** | Frictionless tracking, AI-powered personalization, faster recovery |
| **Therapists** | Real-time compliance visibility, automated documentation, outcome differentiation |
| **Coaches** | Team-wide compliance tracking, injury prevention protocols, parent communication |
| **Parents** | Transparency into child's training, injury risk alerts, peace of mind |

### Platform Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    PATIENT EXPERIENCE                        │
│  iOS App │ Apple Watch │ Widgets │ Siri │ Offline Mode      │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────┴───────────────────────────────────┐
│                    INTELLIGENCE LAYER                        │
│  AI Adaptation │ Pain Detection │ Fatigue Modeling │ Safety │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────┴───────────────────────────────────┐
│                    DATA PLATFORM                             │
│  Supabase │ 27 Edge Functions │ HealthKit │ WHOOP │ RLS     │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────┴───────────────────────────────────┐
│                    PROVIDER TOOLS                            │
│  Therapist Dashboard │ Coach Platform │ Parent View          │
└─────────────────────────────────────────────────────────────┘
```

---

# 3. Market Opportunity

## Total Addressable Market (TAM)

| Segment | Market Size | Notes |
|---------|-------------|-------|
| Physical Therapy Services | $45B | US market, growing 6% CAGR |
| Sports Performance Training | $12B | Strength & conditioning market |
| Digital Health & Fitness | $96B | Global, 15% CAGR |
| Youth Sports | $19B | Parents spending on training |

## Serviceable Addressable Market (SAM)

| Segment | Size | Calculation |
|---------|------|-------------|
| PT Clinics (US) | 40,000 | Independent and small chains |
| Baseball Players (US) | 15M | Youth through college |
| Travel Baseball Teams | 12,000 | Premium youth programs |
| College Baseball Programs | 300 | D1/D2/D3 programs |

## Serviceable Obtainable Market (SOM) - Year 1

| Segment | Target | Revenue Potential |
|---------|--------|-------------------|
| PT Clinics | 50 clinics | $250K ARR |
| Individual Athletes | 5,000 users | $500K ARR |
| Travel Teams | 100 teams | $150K ARR |
| **Total Year 1** | | **$900K ARR** |

---

# 4. Product Overview

## Current Product Status

| Metric | Status |
|--------|--------|
| **Build Number** | 88 (TestFlight-ready) |
| **App Version** | 1.0.0 |
| **Platform** | iOS + watchOS |
| **Backend** | Supabase (27 Edge Functions) |
| **AI Models** | GPT-4 Turbo + Claude 3.5 Sonnet |

## Feature Set

### Patient Features (Live)

| Feature | Description |
|---------|-------------|
| **One-Tap Workout Start** | Pre-loaded daily session, instant access |
| **Exercise Logging** | Sets, reps, load, RPE, pain tracking |
| **Offline Mode** | Full functionality without network |
| **Pain Tracking** | Visual charts, trend analysis |
| **Readiness Check-In** | 5 questions, 30 seconds, daily |
| **Streak System** | Gamification with protection alerts |
| **Apple Watch App** | Standalone with voice logging |
| **Health Integration** | HealthKit sync, HRV, sleep data |

### Therapist Features (Live)

| Feature | Description |
|---------|-------------|
| **Patient Dashboard** | Real-time compliance visibility |
| **Program Builder** | Multi-phase program creation |
| **Progress Analytics** | Adherence, pain trends, outcomes |
| **Session Calendar** | Drag-to-reschedule, reminders |
| **Notes System** | Clinical charting integration |

### AI Features (Live)

| Feature | Description |
|---------|-------------|
| **Exercise Substitution** | Equipment and injury-aware alternatives |
| **Readiness Adjustment** | Auto-modify based on daily readiness |
| **Progressive Overload** | Intelligent load progression |
| **Safety Guardrails** | Blocks intensity if pain rising |

### Baseball Features (Building)

| Feature | Description |
|---------|-------------|
| **Jaeger Band Protocol** | Full J-Band routine with video |
| **Arm Care Assessment** | 30-second daily shoulder/elbow check |
| **Position-Specific Programs** | Pitcher, Catcher, IF, OF routines |
| **UCL Health Tracking** | Weekly elbow stress monitoring |
| **Game Day Protocols** | Pre-game activation, post-game recovery |

## Product Screenshots

*[Insert app screenshots here]*

---

# 5. Competitive Landscape

## Market Map

```
                    HIGH CLINICAL DEPTH
                           │
         PT Performance    │    Bridge Athletic
              ★            │         ○
                           │
    CONSUMER ─────────────┼───────────── ENTERPRISE
    FOCUSED               │              FOCUSED
                           │
           Volt            │    WebPT / Clinicient
             ○             │         ○
                           │
                    LOW CLINICAL DEPTH
```

## Competitive Analysis

| Feature | PT Performance | Volt | Ladder | Bridge |
|---------|---------------|------|--------|--------|
| **Pain Tracking** | Yes - AI-aware | No | Basic | No |
| **Baseball Protocols** | Deep (180+ workouts) | Basic | No | No |
| **Parent View** | Yes (unique) | No | No | No |
| **AI Adaptation** | Yes - safety-aware | Yes | No | Limited |
| **Apple Watch** | Standalone app | No | No | No |
| **Offline Mode** | Full support | Limited | No | No |
| **WHOOP Integration** | Yes | No | No | No |
| **Pricing** | $99-148/yr | $120-200/yr | $180/yr | Enterprise |

## Competitive Advantages

1. **Only pain-aware AI** - Blocks intensity increases when pain rising
2. **Deepest baseball content** - 180+ PT-designed workouts vs. basic coverage
3. **Parent transparency** - Unique feature for youth athlete market
4. **Apple ecosystem integration** - Watch, Widgets, Siri, HealthKit
5. **Clinical credibility** - PT-designed, not trainer-designed
6. **Offline-first architecture** - Works without network for daily training

---

# 6. Business Model

## Revenue Streams

### B2C Direct (Athletes)

| Plan | Price | Features |
|------|-------|----------|
| **Free** | $0 | Basic tracking, 1 program, limited library |
| **Premium** | $99/year | Unlimited programs, full library, AI, Watch app |
| **Baseball Pack** | +$49/year | 180+ baseball workouts, arm care, position programs |

### B2B2C (Clinics)

| Plan | Price | Features |
|------|-------|----------|
| **Starter** | $199/mo | 50 patients, basic analytics |
| **Professional** | $499/mo | 200 patients, advanced analytics, API |
| **Enterprise** | Custom | Unlimited, integrations, dedicated support |

### B2B (Teams)

| Plan | Price | Features |
|------|-------|----------|
| **Team** | $15/athlete/year | Coach dashboard, parent view, compliance |
| **Organization** | Custom | Multi-team, admin portal, custom branding |

## Unit Economics

| Metric | Target |
|--------|--------|
| **ACV (Clinic)** | $3,000 - $10,000 |
| **ACV (Individual)** | $99 - $148 |
| **Gross Margin** | 80%+ |
| **CAC (B2C)** | $25 |
| **CAC (B2B)** | $500 |
| **LTV:CAC Ratio** | 3:1+ |
| **Payback Period** | 6 months |

## Revenue Projections

| Year | B2C | B2B Clinic | B2B Team | Total ARR |
|------|-----|------------|----------|-----------|
| **Year 1** | $500K | $250K | $150K | $900K |
| **Year 2** | $1.5M | $1M | $500K | $3M |
| **Year 3** | $4M | $3M | $1.5M | $8.5M |

---

# 7. Go-to-Market Strategy

## Phase 1: Founder-Led Sales (Months 1-6)

**Focus:** Validate product-market fit with design partners

| Channel | Target | Approach |
|---------|--------|----------|
| **PT Network** | 10 clinics | Personal relationships, free pilots |
| **Baseball Connections** | 5 travel teams | Coach referrals, tournament presence |
| **Direct Athletes** | 1,000 users | TestFlight beta, social media |

**Success Metrics:**
- 10 paying clinic customers
- 40% D7 retention
- 4.5+ App Store rating
- 3 case studies

## Phase 2: Repeatable Sales (Months 7-12)

**Focus:** Build scalable acquisition channels

| Channel | Investment | Expected CAC |
|---------|------------|--------------|
| **Content Marketing** | $5K/mo | $20 |
| **Paid Social (Meta)** | $10K/mo | $30 |
| **PT Conference Presence** | $15K | $200 (B2B) |
| **Baseball Showcase Events** | $10K | $15 |
| **Referral Program** | 20% revenue share | $10 |

## Phase 3: Scale (Year 2+)

**Focus:** Channel partnerships and enterprise

| Partner Type | Examples | Model |
|--------------|----------|-------|
| **EHR Integrations** | WebPT, Clinicient | Revenue share |
| **Equipment Companies** | Rogue, Driveline | Co-marketing |
| **Baseball Organizations** | Perfect Game, USSSA | Licensing |
| **Insurance/Payers** | Cigna, United | Outcomes contracts |

---

# 8. Strategic Roadmap

## 2026 Roadmap

### Q1: Foundation & Validation (Current)

| Milestone | Status | Target Date |
|-----------|--------|-------------|
| iOS app TestFlight release | Done | Complete |
| 10 Claude Code skills | Done | Complete |
| Make.com automation | Done | Complete |
| First 5 beta clinics | In Progress | Feb 2026 |
| App Store submission | Planned | Mar 2026 |

### Q2: Market Entry

| Milestone | Target Date |
|-----------|-------------|
| App Store launch | Apr 2026 |
| Baseball Pack content complete | Apr 2026 |
| First 25 paying clinics | May 2026 |
| 2,500 individual subscribers | Jun 2026 |
| Parent dashboard launch | Jun 2026 |

### Q3: Growth & Expansion

| Milestone | Target Date |
|-----------|-------------|
| 50 clinic customers | Jul 2026 |
| 5,000 individual subscribers | Aug 2026 |
| Team platform launch | Aug 2026 |
| WHOOP deep integration | Sep 2026 |
| First enterprise deal | Sep 2026 |

### Q4: Scale Preparation

| Milestone | Target Date |
|-----------|-------------|
| $75K MRR | Oct 2026 |
| Series A preparation | Nov 2026 |
| Android development start | Nov 2026 |
| 100 clinic customers | Dec 2026 |
| $900K ARR | Dec 2026 |

## Product Roadmap (100 Issues, 7 Epics)

### Epic 1: Friction-Free UX (20 issues)
*Goal: Apple-level user experience*

- One-tap workout start
- Swipe-based exercise completion
- Smart pre-loading for instant access
- Gesture-based set logging
- Elimination of confirmation dialogs

### Epic 2: Baseball Pack Premium (25 issues)
*Goal: Deepest baseball training platform*

- Jaeger Band Protocol with video
- Arm Care Daily Assessment
- Position-specific programs (Pitcher, Catcher, IF, OF)
- UCL Health Assessment
- Game Day Features (pre-game, post-game, travel)
- Throwing velocity tracker

### Epic 3: Intelligent Personalization (15 issues)
*Goal: AI that adapts to the individual*

- Readiness-based auto-adjustment
- Pain-aware intensity blocking
- Progressive overload AI
- Recovery optimization
- Fatigue modeling

### Epic 4: Coach & Team Platform (10 issues)
*Goal: Team-wide visibility and management*

- Roster management
- Compliance dashboards
- Parent view (unique differentiator)
- Team leaderboards
- Bulk program assignment

### Epic 5: Content & Education (10 issues)
*Goal: Comprehensive exercise library*

- 180+ baseball workouts
- HD video demonstrations
- Form cues overlay
- Arm care education hub
- Movement screen protocol

### Epic 6: Platform & Integrations (10 issues)
*Goal: Ecosystem connectivity*

- Deep Apple ecosystem (Watch, Widgets, Siri)
- WHOOP recovery integration
- Calendar sync (game schedules)
- EHR partnerships
- Radar gun sync

### Epic 7: Engagement & Retention (10 issues)
*Goal: Habits that stick*

- 50+ achievements
- Level/XP system
- Team challenges
- Smart notifications
- Weekly progress summaries

---

# 9. Financial Projections

## Revenue Model

### Year 1 Build-Up

| Quarter | B2C Subs | Clinic ARR | Team ARR | Total ARR |
|---------|----------|------------|----------|-----------|
| Q1 | $25K | $25K | $10K | $60K |
| Q2 | $100K | $75K | $40K | $215K |
| Q3 | $200K | $150K | $75K | $425K |
| Q4 | $375K | $250K | $125K | $750K |

### 3-Year Projection

| Metric | Year 1 | Year 2 | Year 3 |
|--------|--------|--------|--------|
| **ARR** | $900K | $3M | $8.5M |
| **Customers (Clinic)** | 50 | 200 | 500 |
| **Subscribers (Individual)** | 5,000 | 20,000 | 60,000 |
| **Teams** | 100 | 400 | 1,000 |
| **Gross Margin** | 78% | 82% | 85% |
| **Burn Rate** | $50K/mo | $100K/mo | $200K/mo |

## Key Assumptions

| Assumption | Value | Rationale |
|------------|-------|-----------|
| B2C conversion rate | 5% | Industry benchmark for freemium |
| Baseball Pack attach rate | 40% | Strong product-market fit |
| Clinic churn | 10%/year | High switching costs |
| B2C churn | 30%/year | Industry average |
| CAC payback | 6 months | Efficient growth |

---

# 10. Team & Execution

## Current Team

| Role | Status | Responsibilities |
|------|--------|------------------|
| **Founder/CEO** | Active | Vision, domain expertise, relationships |
| **Operating Partner** | Active | Delivery accountability, milestone tracking |
| **iOS Engineering** | Contract | SwiftUI development, 162 views built |
| **Backend Engineering** | Contract | Supabase, 27 edge functions |
| **Content** | Freelance | Video production, education content |

## Hiring Plan

| Role | Timing | Priority |
|------|--------|----------|
| **Growth Lead** | Q2 2026 | High |
| **Full-Stack Engineer** | Q2 2026 | High |
| **Customer Success** | Q3 2026 | Medium |
| **Content Lead** | Q3 2026 | Medium |
| **Android Engineer** | Q4 2026 | Medium |

## Operating Model

**Founder-Guided, Operator-Run**

- Founder provides vision, domain expertise, key relationships
- Operating partner drives daily execution and milestone tracking
- Contract teams scale up/down based on roadmap needs
- Linear-driven workflow with agent-assisted development
- Clear definitions of done for each feature

## Development Velocity

| Metric | Current |
|--------|---------|
| Build cadence | Weekly releases |
| Features per month | 8-12 |
| Test coverage | 26+ tests per feature |
| Bug resolution | <48 hours |
| Documentation | 40+ runbooks |

---

# 11. Investment & Use of Funds

## Current Funding Status

| Source | Amount | Status |
|--------|--------|--------|
| Bootstrapped | $150K | Deployed |
| Revenue | $0 | Pre-revenue |

## Funding Ask

**Seed Round: $500K - $1M**

| Use | Allocation | Purpose |
|-----|------------|---------|
| **Engineering** | 40% | Full-time iOS + backend engineers |
| **Go-to-Market** | 30% | Sales, marketing, conference presence |
| **Content** | 15% | Video library, baseball protocols |
| **Operations** | 15% | Infrastructure, tools, legal |

## Milestones to Series A

| Milestone | Target | Timeline |
|-----------|--------|----------|
| $75K MRR | Validated PMF | Q4 2026 |
| 100 clinic customers | Repeatable sales | Q4 2026 |
| 10,000 individual users | Consumer traction | Q1 2027 |
| 60% D30 retention | Product stickiness | Q1 2027 |
| 4.8 App Store rating | User love | Q1 2027 |

---

# 12. Risks & Mitigations

## Technical Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| iOS app rejection | Low | High | Pre-submission review, compliance checklist |
| AI hallucination | Medium | Medium | Safety guardrails, human review |
| Data breach | Low | Critical | HIPAA compliance, encryption, RLS |
| Scale issues | Medium | Medium | Supabase infrastructure, load testing |

## Market Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Competition response | High | Medium | Speed to market, niche focus |
| Slow clinic adoption | Medium | High | Free trials, outcome guarantees |
| Economic downturn | Medium | Medium | Essential healthcare positioning |
| Reimbursement changes | Low | High | Direct-to-consumer backup |

## Execution Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Key person dependency | High | High | Documentation, knowledge transfer |
| Hiring challenges | Medium | Medium | Contractor flexibility, remote-first |
| Runway pressure | Medium | High | Capital efficiency, milestone-based spending |

---

# 13. Appendix

## A. Product Feature Inventory

### Live Features (162 Views, 72 Services)

**Authentication & Onboarding**
- Supabase-based auth
- Role-based navigation (patient vs therapist)
- Profile management

**Patient Experience**
- Today's Session View
- Exercise Logging (sets, reps, load, RPE, pain)
- History & Analytics
- Readiness Tracking
- Streak System
- Calendar Integration
- Quick Session Logging
- Apple Watch App

**Therapist Experience**
- Program Builder
- Patient Dashboard
- Compliance Tracking
- Notes System
- Analytics

**AI & Intelligence**
- Exercise Substitution (GPT-4)
- Readiness Adjustment (Claude 3.5)
- Safety Guardrails
- Progressive Overload

**Platform**
- Offline Mode
- HealthKit Integration
- WHOOP Integration
- Push Notifications
- Widgets

## B. Technical Architecture

**Frontend Stack**
- SwiftUI (iOS 16+)
- watchOS 9+
- Combine for reactive programming
- MVVM architecture

**Backend Stack**
- Supabase (PostgreSQL)
- 27 Edge Functions (TypeScript/Deno)
- Row-Level Security
- Real-time subscriptions

**AI/ML Stack**
- OpenAI GPT-4 Turbo
- Anthropic Claude 3.5 Sonnet
- Custom safety layer

**Infrastructure**
- Supabase Cloud
- Sentry (error monitoring)
- GitHub (source control)
- Linear (project management)

## C. Compliance & Security

**HIPAA Compliance**
- Business Associate Agreement (BAA) ready
- Audit logging implemented
- Encryption at rest and in transit
- Access controls via RLS

**App Store Compliance**
- Health data usage disclosure
- Privacy policy
- Terms of service
- Age gating

## D. Competitive Feature Matrix

| Feature | PT Performance | Volt | Ladder | Bridge | BridgeAthletic |
|---------|---------------|------|--------|--------|----------------|
| iOS App | Yes | Yes | Yes | Yes | Yes |
| Android App | Planned | Yes | Yes | Yes | Yes |
| Apple Watch | Yes | No | No | No | No |
| Offline Mode | Yes | Limited | No | No | Limited |
| AI Adaptation | Yes | Yes | No | Limited | Yes |
| Pain Tracking | Yes | No | Basic | No | No |
| Baseball Specific | Yes (180+) | Basic | No | No | Basic |
| Parent View | Yes | No | No | No | No |
| WHOOP Integration | Yes | No | No | No | No |
| HIPAA Compliant | Yes | No | No | Yes | Yes |
| Pricing (Annual) | $99-148 | $120-200 | $180 | Enterprise | Enterprise |

## E. Customer Testimonials

*[To be added after beta program]*

## F. Market Research Sources

- IBISWorld Physical Therapy Industry Report
- Grand View Research Sports Medicine Market
- Statista Youth Sports Spending
- American Physical Therapy Association Annual Survey
- NCAA Injury Surveillance Program

---

# Contact

**PT Performance, Inc.**

[Founder Name]
[Email]
[Phone]

[Website URL]

---

*This document contains confidential information. Do not distribute without permission.*
