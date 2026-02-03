# PT Performance - Health Intelligence Platform Roadmap
## 30 Issues Across 5 New Epics (ACP-801 to ACP-1206)

---

## Executive Summary: Beating Ladder and Volt

PT Performance is positioned to become the first fitness app that truly understands the complete athlete picture. While Ladder focuses on celebrity trainer programs and Volt emphasizes algorithmic periodization, neither platform addresses the critical gaps in modern athletic performance:

| Gap | Ladder | Volt | PT Performance |
|-----|--------|------|----------------|
| Lab/Biomarker Integration | No | No | **First to market** |
| Recovery Protocols (Sauna/Cold) | No | No | **First to market** |
| Fasting Integration | No | No | **First to market** |
| Supplement Tracking | No | No | **First to market** |
| Unified AI Health Coach | Limited chat | Limited (Cortex) | **All data streams integrated** |
| Accurate AI Nutrition | Inaccurate | No | **Claude Vision-powered** |
| Android App | No (iOS only) | Yes (poor UX) | **Native with parity** |
| Progress Visualization | Basic | None | **Long-term trends** |

### Key Differentiators

1. **Unified Intelligence**: A single AI coach that understands training, sleep, labs, recovery, fasting, and supplements together - no competitor has this integrated view

2. **Science-Based Recovery**: First app to track sauna/cold plunge with HRV correlation analysis

3. **Lab-Informed Training**: Automatically adjust workouts based on biomarkers (low testosterone = reduce volume, high CRP = reduce intensity)

4. **Supplement Intelligence**: Momentous partnership for premium, science-backed recommendations with purchase integration

5. **Fasting-Aware Programming**: Workouts adapt to fasting state - first in the industry

---

## User Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Supplement Partner** | Momentous | Huberman-endorsed, premium positioning, athlete-focused formulations |
| **Lab Providers** | Quest + Labcorp | Both equally from day one - covers 90%+ of US lab results |
| **Android Timeline** | After iOS launch (6+ months) | Focus on iOS excellence first, Android as competitive weapon against Ladder |

---

## Implementation Timeline

### Q1 2026 - Foundation (Critical Priority)
- ACP-1201: Unified AI Health Coach
- ACP-801: Lab Results PDF Upload & Parsing
- ACP-1001: Intermittent Fasting Tracker
- ACP-901: Sauna Session Tracking
- ACP-1101: Supplement Tracking

### Q2 2026 - Core Features (High Priority)
- ACP-802: Biomarker Database & Reference Ranges
- ACP-803: Biomarker Dashboard & Trends
- ACP-804: AI Lab Analysis & Recommendations
- ACP-902: Cold Plunge/Ice Bath Tracking
- ACP-1102: Supplement Database
- ACP-1103: AI Supplement Recommendations (Momentous integration)
- ACP-1202: Accurate AI Nutrition (Beat Ladder)
- ACP-1204: Progress Visualization (Beat Volt)

### Q3 2026 - Intelligence Layer (Medium Priority)
- ACP-805: Lab-Based Training Adjustments
- ACP-806: Ask Questions About Labs (AI Chat)
- ACP-903: Contrast Therapy Protocols
- ACP-904: Recovery Protocol Database
- ACP-1002: Fasting Database Schema
- ACP-1003: Fasting-Aware Workout Scheduling
- ACP-1104: Supplement Bundle Builder (Momentous bundles)

### Q4 2026 - Polish & Expansion (Lower Priority)
- ACP-905: Recovery Impact Analysis
- ACP-906: Recovery Scheduling & Reminders
- ACP-1004: Fasting & Readiness Integration
- ACP-1005: Meal Timing Optimization
- ACP-1105: Supplement Timing Optimizer
- ACP-1106: Supplement-Lab Correlation
- ACP-1006: Fasting Benefits Tracking
- ACP-1205: Custom Exercise Library (Beat Volt)
- ACP-1206: Flexible Training Structure (Beat Volt)

### 2027 - Market Expansion
- ACP-1203: Android App (Beat Ladder's iOS-only limitation)

---

# EPIC 8: HEALTH INTELLIGENCE PLATFORM (6 Issues)
*"Your labs, decoded for performance"*

### ACP-801: Lab Results PDF Upload & Parsing
**Priority:** High | **Zone:** zone-12 (iOS)

**Description:**
Enable athletes to upload Quest and Labcorp PDF lab results directly in the app. AI-powered OCR extracts biomarker values from common panels including CBC, CMP, lipid, thyroid, and hormone panels. Manual entry fallback ensures all labs can be tracked regardless of format.

**Acceptance Criteria:**
- [ ] PDF upload via iOS document picker
- [ ] AI-powered extraction of key biomarkers (50+ supported)
- [ ] Support for Quest Diagnostics PDF format
- [ ] Support for Labcorp PDF format
- [ ] Confidence score for each extracted value
- [ ] Error handling for unparseable PDFs with clear user messaging
- [ ] Manual entry option for unsupported formats
- [ ] Lab result history stored securely with encryption

---

### ACP-802: Biomarker Database & Reference Ranges
**Priority:** High | **Zone:** zone-7 (Supabase)

**Description:**
Create comprehensive database schema for lab results with optimal ranges (not just clinical "normal" ranges). Store trends over time and support multiple lab providers for seamless data aggregation.

**Database Schema:**
```sql
-- Core tables
lab_results (
  id, patient_id, test_date, provider, pdf_url,
  parsed_at, confidence_score, created_at
)

biomarker_values (
  id, lab_result_id, biomarker_type, value, unit,
  flag, created_at
)

biomarker_reference_ranges (
  id, biomarker_type, optimal_low, optimal_high,
  normal_low, normal_high, athlete_optimal_low,
  athlete_optimal_high, gender, age_min, age_max
)
```

**Acceptance Criteria:**
- [ ] Database migrations created and tested
- [ ] 100+ biomarker types supported
- [ ] Athlete-specific optimal ranges (beyond clinical normal)
- [ ] Gender and age-adjusted reference ranges
- [ ] Support for Quest and Labcorp provider identifiers
- [ ] Audit trail for all lab data changes
- [ ] RLS policies for patient data security

---

### ACP-803: Biomarker Dashboard & Trends
**Priority:** High | **Zone:** zone-12 (iOS)

**Description:**
Visual dashboard showing key biomarkers with traffic light system (optimal/normal/concern). Historical trend charts enable athletes to track progress over time and correlate with training phases.

**Views:**
- LabsDashboardView - Overview of all key markers
- BiomarkerDetailView - Deep dive into single biomarker
- LabTrendChartView - Historical visualization
- LabComparisonView - Compare two lab panels

**Acceptance Criteria:**
- [ ] Traffic light visual system (green/yellow/red)
- [ ] 12-month trend charts for each biomarker
- [ ] Comparison view between lab panels
- [ ] Filter by biomarker category (hormones, metabolic, etc.)
- [ ] Export lab summary as PDF
- [ ] Pull-to-refresh for latest data
- [ ] Empty state for users without labs

---

### ACP-804: AI Lab Analysis & Recommendations
**Priority:** High | **Zone:** zone-8 (Edge Functions)

**Description:**
AI analysis of lab results in context of training load, sleep patterns, and nutrition. Generates actionable recommendations for performance optimization, not just clinical interpretation.

**Edge Function:** `ai-lab-analysis`
- Input: patient_id, lab_result_id
- Output: analysis, recommendations, correlations, confidence

**Acceptance Criteria:**
- [ ] AI analysis completed within 30 seconds
- [ ] Nutrition recommendations based on deficiencies
- [ ] Training adjustment suggestions based on hormones
- [ ] Sleep/recovery correlations identified
- [ ] Plain language explanations (no medical jargon)
- [ ] Disclaimer that analysis is not medical advice
- [ ] References to supporting research where applicable

---

### ACP-805: Lab-Based Training Adjustments
**Priority:** Medium | **Zone:** zone-8 (Edge Functions)

**Description:**
Automatically adjust training recommendations based on biomarker values. The system should make intelligent modifications to protect athlete health while optimizing performance.

**Adjustment Rules:**
- Low testosterone -> Reduce volume 20%, increase recovery days
- High CRP (inflammation) -> Reduce intensity, add mobility
- Low vitamin D -> Suggest outdoor training, supplement
- Anemia indicators -> Adjust cardio expectations, reduce HIIT
- High cortisol -> Reduce training stress, add recovery protocols

**Acceptance Criteria:**
- [ ] Automatic workout modifications when labs indicate need
- [ ] Clear explanation of why adjustments were made
- [ ] User can override AI recommendations
- [ ] Training adjustments logged for coach visibility
- [ ] Integration with readiness score system
- [ ] Threshold values configurable per athlete

---

### ACP-806: Ask Questions About Labs (AI Chat)
**Priority:** High | **Zone:** zone-12 (iOS)

**Description:**
Natural language Q&A interface for athletes to understand their lab results. Context-aware responses using patient history, training data, and nutrition logs.

**Example Questions:**
- "Why is my testosterone low?"
- "What should I eat to improve my iron levels?"
- "How does my cortisol affect my training?"
- "Is my vitamin D level good for an athlete?"
- "What's causing my high inflammation?"

**Acceptance Criteria:**
- [ ] Natural language input with voice support
- [ ] Responses contextualized to athlete's full profile
- [ ] Citation of specific lab values in responses
- [ ] Suggestions link to actionable app features
- [ ] Chat history preserved for continuity
- [ ] Medical disclaimer on every response
- [ ] Escalation path to consult healthcare provider

---

# EPIC 9: RECOVERY PROTOCOLS (6 Issues)
*"Science-backed recovery, tracked and optimized"*

### ACP-901: Sauna Session Tracking
**Priority:** High | **Zone:** zone-12 (iOS)

**Description:**
Log sauna sessions with type, duration, and temperature. Track frequency and total weekly minutes. Correlate with HRV and sleep improvements over time.

**Sauna Types:**
- Traditional (dry heat)
- Infrared
- Steam room

**UI Components:**
- Quick-log button on recovery tab
- Session timer with temperature input
- Weekly summary widget
- Monthly heat exposure chart

**Acceptance Criteria:**
- [ ] One-tap quick log for sessions
- [ ] Timer with temperature input (Fahrenheit/Celsius)
- [ ] Support for all three sauna types
- [ ] Weekly minutes tracked with goals
- [ ] Streak tracking for consistency
- [ ] Integration with HealthKit for heart rate during session
- [ ] Post-session notes field

---

### ACP-902: Cold Plunge/Ice Bath Tracking
**Priority:** High | **Zone:** zone-12 (iOS)

**Description:**
Log cold exposure sessions with temperature and duration. Include protocol recommendations from leading experts (Huberman, Wim Hof). Track progressive cold adaptation over time.

**Cold Exposure Types:**
- Cold shower (preset: 60F / 15C)
- Ice bath (preset: 40F / 4C)
- Cold plunge (preset: 50F / 10C)
- Cryotherapy

**Features:**
- Temperature presets with custom option
- Duration timer with haptic feedback at milestones
- Breathing guide for cold exposure
- Streak tracking for consistency
- Cold adaptation score over time

**Acceptance Criteria:**
- [ ] Quick-start with temperature presets
- [ ] Custom temperature input option
- [ ] Timer with 30-second haptic reminders
- [ ] Breathing exercise integration option
- [ ] Weekly cold exposure minutes tracked
- [ ] Progressive challenge suggestions
- [ ] HRV response correlation display

---

### ACP-903: Contrast Therapy Protocols
**Priority:** Medium | **Zone:** zone-12 (iOS)

**Description:**
Combined sauna and cold plunge protocols with guided sessions. Timer alternates between phases with audio/haptic cues. Protocol library includes evidence-based ratios.

**Protocol Library:**
- Standard (3:1 hot:cold ratio)
- Aggressive (2:1 ratio)
- Beginner (4:1 ratio)
- Custom ratio builder

**Acceptance Criteria:**
- [ ] Guided contrast therapy timer
- [ ] Alternating phase audio cues
- [ ] Visual countdown for each phase
- [ ] Protocol presets (3:1, 2:1, 4:1)
- [ ] Custom protocol builder
- [ ] Session summary with total exposure
- [ ] Save favorite protocols

---

### ACP-904: Recovery Protocol Database
**Priority:** High | **Zone:** zone-7 (Supabase)

**Description:**
Database schema for all recovery modalities. Track sessions over time and store protocol templates for guided recovery.

**Database Schema:**
```sql
recovery_sessions (
  id, patient_id, type, subtype, duration_seconds,
  temperature, temperature_unit, notes,
  heart_rate_avg, hrv_after, logged_at, created_at
)

recovery_protocols (
  id, name, description, type, phases,
  recommended_frequency, difficulty_level,
  evidence_rating, created_at
)

-- phases is JSONB array:
-- [{type: "hot", duration: 180, temp: 180},
--  {type: "cold", duration: 60, temp: 40}]
```

**Acceptance Criteria:**
- [ ] Support for sauna, cold, contrast, massage, compression
- [ ] Protocol templates with phase definitions
- [ ] Session history with full metadata
- [ ] Weekly/monthly aggregation queries optimized
- [ ] RLS policies for patient data security
- [ ] Indexes for common query patterns

---

### ACP-905: Recovery Impact Analysis
**Priority:** Medium | **Zone:** zone-8 (Edge Functions)

**Description:**
Correlate recovery sessions with measurable outcomes. Provide personalized insights like "Your HRV improved 15% after sauna days" or "Cold plunge before bed improves your sleep by 20 minutes."

**Edge Function:** `analyze-recovery-impact`

**Correlations Tracked:**
- Recovery session -> Next-day HRV change
- Recovery session -> Sleep quality improvement
- Recovery timing -> Performance in next workout
- Consistency -> Long-term HRV trend

**Acceptance Criteria:**
- [ ] Minimum 2 weeks of data before showing insights
- [ ] Statistical significance threshold for claims
- [ ] Personalized recommendations based on patterns
- [ ] "What works for you" summary view
- [ ] Comparison to population averages
- [ ] A/B suggestions to test new protocols

---

### ACP-906: Recovery Scheduling & Reminders
**Priority:** Medium | **Zone:** zone-12 (iOS)

**Description:**
Schedule recovery sessions with optimal timing recommendations. Push notifications ensure consistency. Integration with training calendar shows recovery in context of workouts.

**Scheduling Features:**
- Recurring recovery sessions
- Post-workout recovery suggestions
- Rest day recovery prompts
- Game day recovery protocols

**Acceptance Criteria:**
- [ ] Add recovery to calendar
- [ ] Recurring session scheduling
- [ ] Push notification reminders
- [ ] Optimal timing suggestions based on training
- [ ] Integration with iOS Calendar app
- [ ] Skip/reschedule without breaking streak

---

# EPIC 10: FASTING INTELLIGENCE (6 Issues)
*"Fast smarter, train harder"*

### ACP-1001: Intermittent Fasting Tracker
**Priority:** High | **Zone:** zone-12 (iOS)

**Description:**
Track fasting windows with one-tap start/stop. Support common protocols (16:8, 18:6, 20:4, OMAD, 5:2). Visual timer shows current fasting state with motivational milestones.

**Protocols Supported:**
- 16:8 (16 hours fasting, 8 eating)
- 18:6 (18 hours fasting, 6 eating)
- 20:4 (20 hours fasting, 4 eating)
- OMAD (One Meal a Day)
- 5:2 (5 normal days, 2 reduced calorie)
- Custom windows

**UI Features:**
- Fasting status widget (home screen)
- Circular progress timer
- Streak tracking calendar
- Milestone notifications (12h, 16h, 18h, 24h)

**Acceptance Criteria:**
- [ ] One-tap start/stop fasting
- [ ] Visual circular progress indicator
- [ ] Protocol presets with custom option
- [ ] Streak tracking with calendar view
- [ ] Milestone notifications with science facts
- [ ] Widget for iOS home screen
- [ ] History of all fasting sessions

---

### ACP-1002: Fasting Database Schema
**Priority:** High | **Zone:** zone-7 (Supabase)

**Description:**
Database schema for fasting logs tracking planned vs actual windows. Support multiple protocol types with adherence analytics.

**Database Schema:**
```sql
fasting_logs (
  id, patient_id, started_at, ended_at,
  planned_hours, actual_hours, protocol_type,
  completed, early_break_reason, notes, created_at
)

fasting_protocols (
  id, name, eating_window_hours, fasting_hours,
  description, difficulty_level, benefits, created_at
)
```

**Acceptance Criteria:**
- [ ] Track planned vs actual fasting duration
- [ ] Early break reason logging (optional)
- [ ] Protocol adherence percentage calculation
- [ ] Weekly/monthly fasting hours aggregation
- [ ] Longest fast tracking
- [ ] RLS policies for patient data security

---

### ACP-1003: Fasting-Aware Workout Scheduling
**Priority:** High | **Zone:** zone-8 (Edge Functions)

**Description:**
Adjust workout timing and intensity based on current fasting state. Intelligent recommendations for different training goals.

**Adjustment Rules:**
- Hypertrophy goal + fasted > 16h -> Suggest eating before workout
- Fat loss goal -> Allow fasted cardio, reduce intensity
- Extended fast (24h+) -> Warn about high-intensity, suggest mobility only
- Breaking fast -> Optimal post-workout nutrition window

**Edge Function:** `fasting-workout-optimizer`

**Acceptance Criteria:**
- [ ] Detect current fasting state from logs
- [ ] Adjust workout suggestions in real-time
- [ ] Goal-aware recommendations (muscle vs fat loss)
- [ ] Warning for extended fasts + intense training
- [ ] Optimal break-fast timing around workouts
- [ ] Override option for experienced fasters

---

### ACP-1004: Fasting & Readiness Integration
**Priority:** Medium | **Zone:** zone-12 (iOS)

**Description:**
Factor fasting state into the daily readiness score. Extended fasting periods appropriately reduce intensity recommendations while maintaining training consistency.

**Integration Points:**
- Readiness score adjustment for fasted state
- Today's workout view shows fasting status
- Workout intensity auto-scaled based on fast duration
- Clear messaging: "You're 18 hours fasted - we've reduced today's volume by 15%"

**Acceptance Criteria:**
- [ ] Fasting state visible on today's workout screen
- [ ] Readiness score factors in fast duration
- [ ] Automatic volume/intensity reduction for extended fasts
- [ ] Clear user messaging about adjustments
- [ ] User can override fasting-based adjustments
- [ ] Fasting badge on completed workouts

---

### ACP-1005: Meal Timing Optimization
**Priority:** Medium | **Zone:** zone-8 (Edge Functions)

**Description:**
AI recommendations for optimal meal timing around training. Considers fasting protocol, workout type, and performance goals.

**Recommendations Include:**
- Pre-workout nutrition window (when to eat before training)
- Post-workout anabolic window optimization
- Break-fast meal suggestions based on training day
- Evening eating cutoff for sleep optimization

**Edge Function:** `meal-timing-optimizer`

**Acceptance Criteria:**
- [ ] Pre-workout meal timing recommendations
- [ ] Post-workout nutrition window alerts
- [ ] Break-fast meal suggestions for training days
- [ ] Integration with nutrition logging
- [ ] Personalization based on individual response
- [ ] Push notifications for optimal eating times

---

### ACP-1006: Fasting Benefits Tracking
**Priority:** Low | **Zone:** zone-12 (iOS)

**Description:**
Track estimated autophagy windows and ketone states based on fasting duration. Educational content explains the science behind fasting benefits. Correlate with body composition changes.

**Tracked Milestones:**
- 12h: Metabolic switch begins
- 16h: Autophagy increases
- 18h: Fat burning accelerates
- 24h: Growth hormone increases
- 36h+: Deep autophagy

**Acceptance Criteria:**
- [ ] Visual timeline of fasting milestones
- [ ] Educational content at each milestone
- [ ] Estimated ketone state indicator
- [ ] Correlation with body composition trends
- [ ] Science-backed benefit explanations
- [ ] Links to research papers for interested users

---

# EPIC 11: SUPPLEMENT INTELLIGENCE (6 Issues)
*"Powered by Momentous - the athlete's choice"*

### ACP-1101: Supplement Tracking
**Priority:** High | **Zone:** zone-12 (iOS)

**Description:**
Log daily supplement intake with searchable database. Track timing (AM/PM, with food, pre-workout) and dosage with proper units. Quick-log favorites for daily routine.

**UI Components:**
- Daily supplement checklist
- Quick-log favorites bar
- Reminder notifications
- Weekly adherence summary

**Acceptance Criteria:**
- [ ] Searchable supplement database (500+ items)
- [ ] Daily checklist with one-tap logging
- [ ] Timing tracking (morning, evening, with food, etc.)
- [ ] Dosage input with unit selection
- [ ] Favorite supplements for quick logging
- [ ] Reminder notifications at scheduled times
- [ ] Weekly/monthly adherence tracking

---

### ACP-1102: Supplement Database
**Priority:** High | **Zone:** zone-7 (Supabase)

**Description:**
Comprehensive supplement catalog with evidence ratings, interaction warnings, and optimal dosing guidelines. Momentous products featured with deep integration.

**Database Schema:**
```sql
supplements (
  id, name, category, description, evidence_rating,
  typical_dose, dose_unit, timing_recommendation,
  food_requirement, interactions, momentous_sku,
  created_at
)

supplement_logs (
  id, patient_id, supplement_id, dosage, dose_unit,
  timing, logged_at, created_at
)

patient_supplement_stack (
  id, patient_id, supplement_id, dosage,
  frequency, timing, active, notes, created_at
)
```

**Categories:**
- Performance (creatine, beta-alanine, caffeine)
- Recovery (omega-3, curcumin, tart cherry)
- Sleep (magnesium, glycine, apigenin)
- Hormones (vitamin D, zinc, ashwagandha)
- General Health (multivitamin, probiotics)

**Acceptance Criteria:**
- [ ] 500+ supplements in database
- [ ] Evidence rating (A/B/C/D) for each supplement
- [ ] Interaction warnings between supplements
- [ ] Optimal dosing guidelines
- [ ] Momentous products flagged for easy identification
- [ ] Category filtering and search
- [ ] User-submitted supplement requests

---

### ACP-1103: AI Supplement Recommendations
**Priority:** High | **Zone:** zone-8 (Edge Functions)

**Description:**
Personalized supplement recommendations based on training goals, lab results, sleep quality, and recovery needs. Momentous products recommended where applicable.

**Edge Function:** `ai-supplement-recommendation`

**Recommendation Triggers:**
- Training goal: muscle gain -> Creatine, protein, HMB
- Lab result: low vitamin D -> Momentous Vitamin D3+K2
- Sleep issues -> Magnesium L-Threonate, Glycine
- Recovery needs -> Omega-3, Curcumin
- High training load -> Electrolytes, Adaptogens

**Acceptance Criteria:**
- [ ] Personalized recommendations based on goals
- [ ] Integration with lab results for deficiency-based suggestions
- [ ] Sleep data integration for sleep supplement suggestions
- [ ] Recovery data integration for anti-inflammatory suggestions
- [ ] Momentous product links with affiliate tracking
- [ ] Evidence citations for each recommendation
- [ ] User can dismiss/save recommendations

---

### ACP-1104: Supplement Bundle Builder
**Priority:** Medium | **Zone:** zone-12 (iOS)

**Description:**
Create custom supplement stacks or choose from pre-built bundles. Momentous partnership enables one-click purchasing with affiliate revenue.

**Pre-Built Bundles (Momentous):**
- Performance Stack (Creatine + Pre-workout + Protein)
- Recovery Stack (Omega-3 + Vitamin D + Magnesium)
- Sleep Stack (Magnesium + Apigenin + L-Theanine)
- Longevity Stack (Omega-3 + Vitamin D + Creatine)

**Acceptance Criteria:**
- [ ] Pre-built bundle templates
- [ ] Custom stack builder
- [ ] Total daily cost calculation
- [ ] Interaction checking between supplements
- [ ] Momentous purchase link integration
- [ ] Affiliate tracking for revenue
- [ ] Share stacks with friends/teammates

---

### ACP-1105: Supplement Timing Optimizer
**Priority:** Medium | **Zone:** zone-8 (Edge Functions)

**Description:**
Optimal timing recommendations for each supplement in the user's stack. Considers fasting windows, workout timing, and supplement interactions.

**Edge Function:** `supplement-timing-optimizer`

**Timing Rules:**
- Vitamin D: With breakfast (fat-soluble)
- Magnesium: 1 hour before bed
- Creatine: Post-workout
- Omega-3: With largest meal
- Caffeine: Not after 2pm

**Acceptance Criteria:**
- [ ] Daily supplement schedule generation
- [ ] Integration with fasting windows
- [ ] Workout-relative timing (pre/post)
- [ ] Push notification reminders
- [ ] Explanation for each timing recommendation
- [ ] Conflict resolution for competing timings

---

### ACP-1106: Supplement-Lab Correlation
**Priority:** Low | **Zone:** zone-8 (Edge Functions)

**Description:**
Track supplement effectiveness through lab result changes. Show clear before/after comparisons with statistical analysis.

**Edge Function:** `supplement-lab-correlation`

**Example Insights:**
- "Your vitamin D increased from 28 to 52 ng/mL after 3 months of D3 supplementation"
- "Omega-3 supplementation correlated with 15% reduction in inflammation markers"
- "Consider increasing magnesium dose - levels still below optimal"

**Acceptance Criteria:**
- [ ] Before/after lab comparison for supplements
- [ ] Minimum timeframe requirements for valid comparison
- [ ] Statistical confidence in correlations
- [ ] Dosage adjustment recommendations
- [ ] Cost-effectiveness analysis
- [ ] Share results with healthcare provider option

---

# EPIC 12: COMPETITIVE ADVANTAGE (6 Issues)
*"Beat Ladder. Beat Volt. Win the market."*

### ACP-1201: Unified AI Health Coach
**Priority:** Critical | **Zone:** zone-8 (Edge Functions)

**Description:**
Single AI coach that understands ALL data streams simultaneously. No competitor has this integrated view of the complete athlete.

**Data Streams Integrated:**
- Training performance & history
- Sleep quality & HRV (HealthKit/WHOOP)
- Lab biomarkers (Epic 8)
- Recovery modalities (Epic 9)
- Fasting state (Epic 10)
- Supplement intake (Epic 11)
- Nutrition & hydration
- Pain & readiness scores

**Edge Function:** `unified-ai-coach`

**Example Interactions:**
- "Your HRV is down 15%, you're 20 hours fasted, and your last workout was intense. I recommend a recovery day with light mobility and breaking your fast before any training."
- "Based on your low vitamin D labs and indoor training pattern, I suggest outdoor cardio sessions and a D3 supplement."

**Acceptance Criteria:**
- [ ] Access to all user data streams
- [ ] Holistic recommendations considering all factors
- [ ] Natural language chat interface
- [ ] Proactive insights (push notifications)
- [ ] Learning from user feedback
- [ ] Explainable recommendations (show reasoning)
- [ ] Override capabilities for user autonomy

---

### ACP-1202: Accurate AI Nutrition (Beat Ladder)
**Priority:** High | **Zone:** zone-8 (Edge Functions)

**Description:**
Photo-based meal logging with superior accuracy to Ladder's notoriously inaccurate AI nutrition feature. Powered by Claude Vision for best-in-class food recognition.

**Features:**
- Photo-based meal logging
- Claude Vision for food identification
- Accurate macro estimation
- Barcode scanning integration
- Voice meal logging
- Restaurant menu integration

**Edge Function:** `ai-nutrition-analysis`

**Acceptance Criteria:**
- [ ] Photo upload with instant analysis
- [ ] Macro accuracy within 15% of actual
- [ ] Support for multi-item meals
- [ ] Barcode scanning for packaged foods
- [ ] Voice input for quick logging
- [ ] Restaurant/chain menu database
- [ ] User correction for model improvement
- [ ] Comparison testing vs Ladder accuracy

---

### ACP-1203: Android App (Beat Ladder)
**Priority:** High | **Zone:** zone-13 (Android)

**Description:**
Native Android app with full feature parity. Ladder is iOS-only, leaving 50%+ of the market unaddressed. Volt has Android but with poor UX - we can win both.

**MVP Scope:**
- Core workout tracking
- Program library
- Basic analytics
- HealthConnect integration
- Supplement tracking
- Fasting tracker

**Acceptance Criteria:**
- [ ] Native Android development (Kotlin/Jetpack Compose)
- [ ] Feature parity with iOS core features
- [ ] Material Design 3 compliance
- [ ] HealthConnect integration
- [ ] Offline workout support
- [ ] Play Store rating target: 4.5+
- [ ] Performance parity with iOS app

---

### ACP-1204: Progress Visualization (Beat Volt)
**Priority:** High | **Zone:** zone-12 (iOS)

**Description:**
Long-term progress charts addressing Volt's biggest user complaint: "Volt collects data but provides no way to review progress." Comprehensive visualization of strength, body composition, and performance trends.

**Visualizations:**
- Strength progression (by exercise, muscle group)
- Body composition trends (weight, body fat %)
- Performance PRs timeline
- Volume trends (weekly, monthly)
- Consistency metrics

**Acceptance Criteria:**
- [ ] Exercise-specific strength charts
- [ ] Body composition trend graphs
- [ ] PR history with celebration moments
- [ ] Monthly/yearly comparison views
- [ ] Export progress reports as PDF
- [ ] Share progress images for social media
- [ ] Before/after photo timeline

---

### ACP-1205: Custom Exercise Library (Beat Volt)
**Priority:** Medium | **Zone:** zone-12 (iOS)

**Description:**
User-created exercises addressing Volt's limitation of not allowing custom exercises. Full video upload support with sharing capabilities.

**Features:**
- Create custom exercises
- Video upload for form reference
- Categorization and tagging
- Share exercises between users
- Import exercises from other users
- Coach-created team exercises

**Acceptance Criteria:**
- [ ] Custom exercise creation form
- [ ] Video upload (30 sec max)
- [ ] Category and muscle group tagging
- [ ] Public/private sharing options
- [ ] Exercise import from shared links
- [ ] Coach exercise library for teams
- [ ] Moderation for public exercises

---

### ACP-1206: Flexible Training Structure (Beat Volt)
**Priority:** Medium | **Zone:** zone-8 (Edge Functions)

**Description:**
Support non-athlete training patterns with flexible scheduling. Volt's rigid multi-week blocks don't work for recreational athletes with unpredictable schedules.

**Flexibility Features:**
- Skip workouts without "penalty"
- Swap workout days freely
- Adjust program on-the-fly
- No rigid multi-week blocks
- Life-aware scheduling (travel, busy periods)
- Quick workouts when time-crunched

**Edge Function:** `flexible-program-engine`

**Acceptance Criteria:**
- [ ] Skip workout without breaking program
- [ ] Swap any two workout days
- [ ] Insert rest days as needed
- [ ] Time-based workout scaling (30/45/60 min options)
- [ ] Travel mode with equipment limitations
- [ ] Catch-up mode after missed workouts
- [ ] No "you're behind" guilt messaging

---

# Summary

## Epic Overview

| Epic | Name | Issues | Focus |
|------|------|--------|-------|
| Epic 8 | Health Intelligence Platform | 6 | Labs/Biomarkers |
| Epic 9 | Recovery Protocols | 6 | Sauna/Cold Plunge |
| Epic 10 | Fasting Intelligence | 6 | IF Tracking |
| Epic 11 | Supplement Intelligence | 6 | Momentous Partnership |
| Epic 12 | Competitive Advantage | 6 | Beat Ladder/Volt |
| **Total** | | **30** | |

## Issue Distribution by Zone

| Zone | Count | Issues |
|------|-------|--------|
| zone-12 (iOS) | 15 | ACP-801, 803, 806, 901, 902, 903, 906, 1001, 1004, 1006, 1101, 1104, 1204, 1205 |
| zone-8 (Edge Functions) | 10 | ACP-804, 805, 1003, 1005, 905, 1103, 1105, 1106, 1201, 1202, 1206 |
| zone-7 (Supabase) | 4 | ACP-802, 904, 1002, 1102 |
| zone-13 (Android) | 1 | ACP-1203 |

## Priority Distribution

| Priority | Count | Issues |
|----------|-------|--------|
| Critical | 1 | ACP-1201 |
| High | 17 | ACP-801-804, 806, 901, 902, 904, 1001, 1002, 1003, 1101, 1102, 1103, 1202, 1203, 1204 |
| Medium | 9 | ACP-805, 903, 905, 906, 1004, 1005, 1104, 1105, 1205, 1206 |
| Low | 3 | ACP-1006, 1106 |

---

## Database Migrations Required

```sql
-- Migration: 20260202_health_intelligence.sql

-- Epic 8: Lab Results
CREATE TABLE lab_results (...);
CREATE TABLE biomarker_values (...);
CREATE TABLE biomarker_reference_ranges (...);

-- Epic 9: Recovery
CREATE TABLE recovery_sessions (...);
CREATE TABLE recovery_protocols (...);

-- Epic 10: Fasting
CREATE TABLE fasting_logs (...);
CREATE TABLE fasting_protocols (...);

-- Epic 11: Supplements
CREATE TABLE supplements (...);
CREATE TABLE supplement_logs (...);
CREATE TABLE patient_supplement_stack (...);
```

---

*Generated for PT Performance - Health Intelligence Platform Roadmap v1.0*
*Competitive targets: Ladder (joinladder.com), Volt Athletics (voltathletics.com)*
*Partner: Momentous (livemomentous.com)*
