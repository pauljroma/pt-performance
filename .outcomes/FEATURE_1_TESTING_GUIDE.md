# Feature #1 Testing Guide - Exercise Videos & Explanations

**BUILD 170** | **Date:** 2026-01-11

---

## ✅ Test Data Now Available!

I've populated the database with test exercise data for 5 exercises:

1. **Barbell Bench Press**
2. **Dumbbell Bench Press**
3. **Barbell Squat**
4. **Goblet Squat**
5. **Dumbbell Row**

Each exercise now has:
- ✅ Video URL (demo video: Big Buck Bunny placeholder)
- ✅ Video thumbnail
- ✅ Technique cues (setup, execution, breathing)
- ✅ Form cues with timestamps
- ✅ Safety notes
- ✅ Common mistakes
- ✅ Equipment requirements
- ✅ Muscles targeted

---

## How to Test Feature #1

### Step 1: Open Exercise Substitution Feature

1. **In the PT Performance app**, navigate to the AI Substitution sheet
2. **Select a substitution reason:**
   - Injury/Pain
   - No Equipment
   - Too Difficult

### Step 2: Trigger Substitutions

To see exercises with video/instruction data, try these scenarios:

#### Scenario A: Equipment-Based Substitution
```
Original Exercise: Barbell Bench Press
Reason: No Equipment
Expected Substitutions: Dumbbell Bench Press (has video data)
```

#### Scenario B: Difficulty-Based Substitution
```
Original Exercise: Barbell Squat
Reason: Too Difficult
Expected Substitutions: Goblet Squat (has video data)
```

### Step 3: Verify Substitution Card Display

On each substitution card, you should see:
- ✅ Exercise name (e.g., "Dumbbell Bench Press")
- ✅ Rationale text (AI-generated reason)
- ✅ **Equipment tags** (blue) - e.g., "Dumbbells", "Flat Bench"
- ✅ **Muscle tags** (green) - e.g., "Chest", "Shoulders", "Triceps"
- ✅ **Difficulty badge** (orange) - "Beginner", "Intermediate", or "Advanced"
- ✅ **Confidence badge** (green) - e.g., "85% Match"
- ✅ **"View Details" button** (blue background, info icon)
- ✅ "Use This" button (prominent/primary style)

### Step 4: Tap "View Details"

When you tap the "View Details" button, a **modal sheet** should open with:

#### Video Section (Top)
- **With test data:** Video player showing Big Buck Bunny demo video
- **Without test data:** Placeholder box saying "Video Coming Soon"

#### Overview Section
- **"Why This Exercise"** heading
- Rationale text explaining why this substitution was chosen
- **Difficulty badge** (orange with chart icon)
- **Confidence badge** (green with checkmark seal)

#### How to Perform Section
Three cue groups with colored icons:

1. **Setup** (blue, figure.stand icon)
   - Numbered list (1., 2., 3., 4.)
   - Example: "Lie flat on bench with eyes under the bar"

2. **Execution** (purple, figure.strengthtraining icon)
   - Numbered list
   - Example: "Lower bar to mid-chest with control"

3. **Breathing** (teal, lungs.fill icon)
   - Numbered list
   - Example: "Inhale deeply as you lower the bar"

#### Equipment & Muscles Section
- **Equipment Needed** (blue tags)
  - Wrapping flow layout (tags wrap to next line if needed)
  - Example: [Dumbbells] [Flat Bench]

- **Muscles Targeted** (green tags)
  - Wrapping flow layout
  - Example: [Chest] [Shoulders] [Triceps]

#### Safety Section (Orange Warning Box)
- Orange border and background
- Exclamation triangle icon
- Example: "Always use a spotter when lifting heavy weight..."

#### Common Mistakes Section (Red Warning Box)
- Red border and background
- X-circle icon
- Example: "Flaring elbows out to 90 degrees (increases shoulder injury risk)..."

### Step 5: Test Interactions

- ✅ **Scroll** - Sheet should scroll smoothly through all sections
- ✅ **Video playback** - Tap play button, video should start
- ✅ **Video controls** - Play/pause, scrubbing, speed (0.5x/1.0x), loop
- ✅ **Dismiss** - Tap "Done" button in top-right to close sheet
- ✅ **Re-open** - Tap "View Details" again, should open fresh

---

## Expected Results Summary

### What You Should See ✅

1. **Substitution Cards:**
   - Equipment tags (blue)
   - Muscle tags (green)
   - Difficulty badge (orange)
   - "View Details" button (blue background)

2. **Detail Sheet:**
   - Video player with Big Buck Bunny demo
   - Technique cues organized by phase (Setup, Execution, Breathing)
   - Equipment and muscle tags
   - Safety warnings (orange box)
   - Common mistakes (red box)

### What You Might NOT See (Expected)

For exercises without test data:
- ❌ Video placeholder ("Video Coming Soon") instead of player
- ❌ Missing sections won't appear (e.g., if no safety_notes, Safety section hidden)
- ❌ Equipment/muscles might be empty if AI doesn't provide them

---

## Test Scenarios by Workout Type

### For Push Workout (Chest/Shoulders/Triceps)
```
Try substitutions for:
- Barbell Bench Press → Dumbbell Bench Press ✅ (has test data)
- Incline Barbell Press → Incline Dumbbell Press (might have data)
- Overhead Press → variations
```

### For Pull Workout (Back/Biceps)
```
Try substitutions for:
- Barbell Row → Dumbbell Row ✅ (has test data)
- Pull-ups → lat pulldowns
- Bent-over rows → cable rows
```

### For Leg Workout
```
Try substitutions for:
- Barbell Squat → Goblet Squat ✅ (has test data)
- Deadlifts → Romanian deadlifts
- Lunges → step-ups
```

---

## Troubleshooting

### Issue: "View Details" button doesn't appear
**Cause:** Edge function not returning enhanced data
**Fix:**
1. Check edge function is deployed: `supabase functions list`
2. Redeploy if needed: `supabase functions deploy ai-exercise-substitution`

### Issue: Detail sheet is empty or missing sections
**Cause:** Exercise doesn't have test data in database
**Expected:** Only 5 exercises have test data currently
**Workaround:** Try one of the 5 exercises listed above

### Issue: Video doesn't play
**Cause:** Demo video URL might be blocked or slow to load
**Expected:** Big Buck Bunny is a public test video, should work
**Workaround:** Check internet connection, try again

### Issue: Equipment/muscles don't show
**Cause:** AI might not be providing this data for certain substitutions
**Expected:** Edge function derives muscles from category/body_region
**Check:** Look at console logs for edge function response

---

## Data Currently Available

**Exercises WITH test data (5):**
| Exercise | Equipment | Muscles | Video | Instructions |
|----------|-----------|---------|-------|--------------|
| Barbell Bench Press | Barbell, Bench | Chest, Shoulders, Triceps | ✅ | ✅ |
| Dumbbell Bench Press | Dumbbells, Bench | Chest, Shoulders, Triceps | ✅ | ✅ |
| Barbell Squat | Barbell, Squat Rack | Quads, Glutes | ✅ | ✅ |
| Goblet Squat | Dumbbell or Kettlebell | Quads, Glutes | ✅ | ✅ |
| Dumbbell Row | Dumbbell, Bench | Back, Biceps | ✅ | ✅ |

**Other exercises:**
- Will show placeholder for video
- Might have equipment/muscles from AI
- Won't have technique cues, safety notes, or common mistakes yet

---

## What to Test Next

### Priority 1: Core Functionality ✅
- [x] "View Details" button appears
- [x] Detail sheet opens when tapped
- [x] Video player works (or placeholder shows)
- [x] All sections render correctly
- [x] Sheet dismisses with "Done" button

### Priority 2: Data Display ✅
- [x] Equipment tags display and wrap
- [x] Muscle tags display and wrap
- [x] Technique cues grouped properly
- [x] Safety/mistakes sections conditional

### Priority 3: Edge Cases
- [ ] Test with exercise that has NO test data → should show placeholder
- [ ] Test with bodyweight exercise → should show "No Equipment" or empty
- [ ] Test scrolling long instruction lists
- [ ] Test video on slow connection

---

## Next Steps After Testing

### If Everything Works ✅
1. **Upload BUILD 170 to TestFlight** (tomorrow when Apple limit resets)
2. **Add more video URLs** - Replace demo video with real exercise videos
3. **Populate more exercises** - Add instructions to top 50-100 exercises
4. **Get professional videos** - Record or license proper technique demonstrations

### If Issues Found 🐛
1. **Report bugs** - Note what doesn't work
2. **Fix in BUILD 171** - Patch any issues found
3. **Re-test** - Verify fixes work

---

## Database Query to Check Test Data

Run this in Supabase SQL Editor to verify data:

```sql
SELECT
  name,
  video_url IS NOT NULL as has_video,
  technique_cues IS NOT NULL as has_cues,
  safety_notes IS NOT NULL as has_safety,
  equipment_required,
  category,
  body_region
FROM exercise_templates
WHERE video_url IS NOT NULL
ORDER BY name;
```

Expected: 5 rows (Barbell Bench Press, Dumbbell Bench Press, Barbell Squat, Goblet Squat, Dumbbell Row)

---

## Quick Testing Checklist

Use this checklist when testing:

**Before Opening App:**
- [ ] BUILD 170 installed from TestFlight (or local build)
- [ ] Internet connection active
- [ ] Logged in to app

**In App:**
- [ ] Open AI Substitution sheet
- [ ] Select "No Equipment" reason
- [ ] Pick exercise with equipment (e.g., Barbell Bench Press)
- [ ] Tap "Get AI Suggestions"
- [ ] Verify substitution card shows equipment/muscles/difficulty
- [ ] Tap "View Details" button
- [ ] Verify modal opens

**In Detail Sheet:**
- [ ] Video player visible (or placeholder)
- [ ] Play video (if available)
- [ ] Read "Why This Exercise" section
- [ ] Check "How to Perform" has 3 cue groups
- [ ] See equipment tags (blue)
- [ ] See muscle tags (green)
- [ ] See safety notes (orange box)
- [ ] See common mistakes (red box)
- [ ] Scroll works smoothly
- [ ] Tap "Done" to dismiss

**Final Checks:**
- [ ] No crashes
- [ ] No "data not in correct format" errors
- [ ] UI looks professional
- [ ] Feature feels complete (even with placeholder videos)

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)

**Status:** ✅ TEST DATA READY - Start testing Feature #1!

