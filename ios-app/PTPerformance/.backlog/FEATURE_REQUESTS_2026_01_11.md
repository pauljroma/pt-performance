# Feature Requests & Bug Backlog - 2026-01-11

**Source:** TestFlight Testing Feedback (BUILD 165-167)
**Date:** 2026-01-11
**Status:** Pending Implementation

## 1. Exercise Alternative - Video & Explanation (HIGH PRIORITY)

**Issue:** When requesting alternative exercises, users need visual guidance to ensure proper form.

**Current State:**
- AI substitution shows exercise name, rationale, confidence
- Missing: video demonstration, detailed explanation, form pointers

**Requested Features:**
- Video example for each alternative exercise
- Detailed exercise explanation
- Form pointers (key technique cues)
- Equipment requirements (already have)
- Target muscles (already have)

**Technical Approach:**
- Add `video_url` field to exercise_templates table
- Fetch video URL when displaying substitutions
- Create VideoPlayerView component for inline playback
- Add "How to Perform" section with step-by-step instructions
- Add "Key Form Pointers" section with bullet points

**Files to Modify:**
- `Services/ExerciseSubstitutionService.swift` - Fetch video URLs from templates
- `Views/AI/AISubstitutionSheet.swift` - Display video + instructions
- `Models/ExerciseSubstitution.swift` - Add video_url, instructions, pointers fields

**Priority:** HIGH (User safety and technique quality)

---

## 2. History Tab - Session Details (MEDIUM PRIORITY)

**Issue:** History tab shows sessions but missing detailed information about what was completed.

**Current State:**
- History tab exists but lacks session detail view
- User can't see what exercises were completed
- Can't see volume, RPE, pain scores from past sessions

**Requested Features:**
- Tap session to see full details
- Show all exercises completed in that session
- Display actual vs prescribed (sets, reps, load)
- Show RPE and pain scores
- Show session duration
- Show notes from that session

**Technical Approach:**
- Create SessionDetailView.swift
- Fetch exercise_logs for selected session
- Display in list format with actual values
- Show summary metrics at top
- Add navigation from HistoryView to SessionDetailView

**Files to Create:**
- `Views/History/SessionDetailView.swift`
- `ViewModels/SessionDetailViewModel.swift`

**Files to Modify:**
- `Views/History/HistoryView.swift` - Add navigation to detail view

**Priority:** MEDIUM (Enhances user tracking and progress visibility)

---

## 3. Nutrition Planning Module (HIGH PRIORITY)

**Issue:** Nutrition AI currently only gives one-off recommendations. Users need meal planning and tracking.

**Current State:**
- Nutrition tab shows AI recommendations
- One-time use only
- No meal logging
- No plan persistence
- No meal history

**Requested Features:**

### 3a. AI Meal Planning
- User creates nutrition plan with AI assistance
- Plan includes daily calorie target, macro split
- Meal timing recommendations (breakfast, lunch, dinner, snacks)
- Personalized to training schedule

### 3b. Meal Logging
- Log meals throughout the day
- Track actual calories and macros
- Photo upload for meals
- Quick-log common meals
- AI meal parser (photo → nutrition breakdown)

### 3c. Plan Management
- Save active nutrition plan
- View plan adherence (actual vs target)
- Adjust plan based on progress
- Get AI guidance at each meal (contextual to plan)

**Technical Approach:**

**Phase 1: Plan Creation & Storage**
- Create `nutrition_plans` table
  - Columns: id, patient_id, target_calories, target_protein, target_carbs, target_fats, created_at, status
- Create `meal_logs` table
  - Columns: id, patient_id, nutrition_plan_id, logged_at, meal_type, meal_name, calories, protein, carbs, fats, photo_url, notes
- Add NutritionPlanService.swift
- Create NutritionPlanView.swift

**Phase 2: Meal Logging**
- Create MealLogSheet.swift
- Add photo upload to Supabase Storage
- Connect ai-meal-parser edge function
- Quick-log favorites

**Phase 3: Plan Adherence Tracking**
- Daily summary view (actual vs target)
- Weekly trends chart
- AI coaching based on adherence

**Files to Create:**
- `Models/NutritionPlan.swift`
- `Models/MealLog.swift`
- `Services/NutritionPlanService.swift`
- `ViewModels/NutritionPlanViewModel.swift`
- `ViewModels/MealLogViewModel.swift`
- `Views/Nutrition/NutritionPlanView.swift`
- `Views/Nutrition/MealLogSheet.swift`
- `Views/Nutrition/MealLogHistoryView.swift`
- `Views/Nutrition/PlanAdherenceView.swift`

**Database Migrations:**
- `supabase/migrations/YYYYMMDD_create_nutrition_plans.sql`
- `supabase/migrations/YYYYMMDD_create_meal_logs.sql`
- `supabase/migrations/YYYYMMDD_add_rls_nutrition_tables.sql`

**Edge Functions (Already Exist):**
- `ai-meal-parser` - Parse photos → nutrition data
- `ai-nutrition-recommendation` - Already working!

**Priority:** HIGH (Core feature for complete PT + Nutrition solution)

---

## Implementation Order

### Sprint 1 (Next 2-3 Builds)
1. ✅ BUILD 165 - Fix nutrition decode (DONE)
2. ✅ BUILD 167 - Fix substitution API (DONE)
3. **BUILD 168** - Add video + explanation to exercise alternatives
4. **BUILD 169** - Add session detail view to history tab

### Sprint 2 (Following 3-4 Builds)
5. **BUILD 170** - Nutrition plan creation (database + UI)
6. **BUILD 171** - Meal logging (basic manual entry)
7. **BUILD 172** - Photo upload for meals
8. **BUILD 173** - AI meal parser integration
9. **BUILD 174** - Plan adherence tracking + charts

### Sprint 3 (Polish & Integration)
10. **BUILD 175** - Quick-log favorites
11. **BUILD 176** - Weekly nutrition summary
12. **BUILD 177** - AI coaching based on adherence
13. **BUILD 178** - Full integration testing + bug fixes

---

## Notes

- Exercise videos may require content creation (record or source)
- Nutrition planning is complex - consider MVP first (manual plan entry)
- Meal logging should integrate with existing readiness tracking
- AI meal parser edge function already exists - just needs iOS integration

---

## Testing Checklist (For Each Feature)

### Exercise Videos
- [ ] Video plays inline without leaving app
- [ ] Video loads quickly (optimized size)
- [ ] Form pointers clearly visible
- [ ] Instructions easy to read

### Session Details
- [ ] All exercises show in detail view
- [ ] Actual vs prescribed values accurate
- [ ] RPE and pain scores display correctly
- [ ] Session duration calculates properly

### Nutrition Planning
- [ ] Plan creation saves successfully
- [ ] Meal logging captures all data
- [ ] Photo upload works reliably
- [ ] AI parser returns accurate nutrition data
- [ ] Adherence calculations correct
- [ ] Charts render properly

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)

**Status:** Ready for sprint planning
