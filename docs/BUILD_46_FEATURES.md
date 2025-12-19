# Build 46 - New Features Specification

**Release Type:** Feature Release
**Target Build:** 46
**Focus:** User-facing features to enhance patient and therapist experience

---

## Features Overview

### 1. Patient Scheduling System 🗓️ (NEW - User Priority)

**User Story:**
As a patient, I want to schedule my workout sessions in advance so I can plan my training around my daily schedule.

**Key Capabilities:**
- View weekly/monthly calendar of scheduled sessions
- Schedule sessions from assigned program
- Reschedule or cancel sessions
- Set reminders for upcoming sessions
- See therapist availability (optional)

**Database Schema:**
```sql
CREATE TABLE scheduled_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(id),
    session_id UUID NOT NULL REFERENCES sessions(id),
    scheduled_date TIMESTAMPTZ NOT NULL,
    scheduled_time TIME NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('scheduled', 'completed', 'cancelled', 'rescheduled')),
    completed_at TIMESTAMPTZ,
    reminder_sent BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_scheduled_sessions_patient ON scheduled_sessions(patient_id);
CREATE INDEX idx_scheduled_sessions_date ON scheduled_sessions(scheduled_date);
```

**iOS Models:**
```swift
struct ScheduledSession: Codable, Identifiable {
    let id: String
    let patientId: String
    let sessionId: String
    let scheduledDate: Date
    let scheduledTime: Date
    let status: ScheduleStatus
    let completedAt: Date?
    let reminderSent: Bool
    let notes: String?

    enum ScheduleStatus: String, Codable {
        case scheduled
        case completed
        case cancelled
        case rescheduled
    }
}
```

**UI Components:**
- `CalendarView` - Weekly/monthly calendar
- `ScheduleSessionView` - Pick date/time for session
- `UpcomingSessionsView` - List of scheduled sessions
- `RescheduleView` - Modify existing schedule

**Complexity:** Medium-High
**Estimated Effort:** 2-3 days
**Priority:** HIGH (User requested)

---

### 2. Workout Templates Library 📚

**User Story:**
As a therapist, I want to create reusable workout templates so I can quickly assign proven programs to multiple patients.

**Key Capabilities:**
- Create workout templates from existing programs
- Template categories (Strength, Mobility, Rehab, etc.)
- Search and filter templates
- Preview template before assigning
- Customize template for specific patient

**Database Schema:**
```sql
CREATE TABLE workout_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL,
    difficulty_level TEXT CHECK (difficulty_level IN ('beginner', 'intermediate', 'advanced')),
    duration_weeks INTEGER,
    created_by UUID REFERENCES patients(id), -- therapist who created
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE template_phases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_id UUID REFERENCES workout_templates(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    sequence INTEGER NOT NULL,
    duration_weeks INTEGER
);

CREATE TABLE template_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phase_id UUID REFERENCES template_phases(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    sequence INTEGER NOT NULL,
    exercises JSONB -- Array of exercises with sets/reps
);
```

**UI Components:**
- `TemplateLibraryView` - Browse templates
- `TemplateDetailView` - Preview template
- `CreateTemplateView` - Create new template
- `AssignTemplateView` - Assign to patient

**Complexity:** Medium
**Estimated Effort:** 2 days
**Priority:** HIGH

---

### 3. Progress Charts & Analytics 📊

**User Story:**
As a patient, I want to see visual charts of my progress so I can track my improvement over time.

**Key Capabilities:**
- Volume progress (total weight lifted over time)
- Strength progression (1RM estimates)
- Consistency tracking (workouts per week)
- Exercise-specific trends
- Body metrics tracking (optional)

**Data Sources:**
- Exercise logs (existing)
- Workload flags (existing)
- Daily readiness (existing)

**Charts:**
1. **Volume Chart** - Total weight lifted per week
2. **Strength Chart** - Estimated 1RM progression
3. **Consistency Chart** - Sessions completed vs. scheduled
4. **Exercise Trend** - Performance on specific exercise over time

**iOS Implementation:**
```swift
import Charts // Swift Charts framework

struct ProgressChartsView: View {
    @State private var volumeData: [VolumeDataPoint] = []

    var body: some View {
        Chart(volumeData) { dataPoint in
            LineMark(
                x: .value("Week", dataPoint.week),
                y: .value("Volume", dataPoint.totalVolume)
            )
        }
    }
}

struct VolumeDataPoint: Identifiable {
    let id = UUID()
    let week: Date
    let totalVolume: Double
}
```

**Complexity:** Low-Medium
**Estimated Effort:** 1-2 days
**Priority:** MEDIUM

---

### 4. Social Features (Share Workouts) 🔗

**User Story:**
As a patient, I want to share my workout achievements so I can celebrate progress with friends and stay motivated.

**Key Capabilities:**
- Share completed workout summary
- Generate shareable workout card (image)
- Share to social media or messaging
- Privacy controls (what to share)

**Share Card Contents:**
- Workout name and date
- Exercises completed
- Total volume lifted
- Personal record achievements
- Optional: Progress photo

**iOS Implementation:**
```swift
struct ShareWorkoutView: View {
    let workout: CompletedWorkout

    var shareCard: some View {
        VStack {
            Text("Workout Complete!")
                .font(.title)
            Text(workout.name)
            // Stats
            HStack {
                StatView(label: "Exercises", value: "\(workout.exerciseCount)")
                StatView(label: "Volume", value: "\(workout.totalVolume) lbs")
            }
        }
        .background(Color.blue.gradient)
    }

    func shareWorkout() {
        let image = shareCard.snapshot()
        let activityVC = UIActivityViewController(
            activityItems: [image, "Just crushed my workout! 💪"],
            applicationActivities: nil
        )
        // Present activity view controller
    }
}
```

**Complexity:** Low
**Estimated Effort:** 1 day
**Priority:** LOW (Nice to have)

---

### 5. Nutrition Tracking 🥗

**User Story:**
As a patient, I want to track my nutrition alongside my workouts so I can optimize my recovery and results.

**Key Capabilities:**
- Log meals and snacks
- Track macros (protein, carbs, fats)
- Daily calorie tracking
- Nutrition goals set by therapist
- Meal photos (optional)

**Database Schema:**
```sql
CREATE TABLE nutrition_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(id),
    log_date DATE NOT NULL,
    meal_type TEXT CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
    description TEXT,
    calories INTEGER,
    protein_grams DECIMAL,
    carbs_grams DECIMAL,
    fats_grams DECIMAL,
    photo_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE nutrition_goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(id),
    daily_calories INTEGER,
    daily_protein_grams DECIMAL,
    daily_carbs_grams DECIMAL,
    daily_fats_grams DECIMAL,
    set_by UUID REFERENCES patients(id), -- therapist
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**UI Components:**
- `NutritionDashboardView` - Daily summary
- `LogMealView` - Quick meal logging
- `MacroBreakdownView` - Visual macro distribution
- `NutritionGoalsView` - View/edit goals

**Complexity:** Medium
**Estimated Effort:** 2 days
**Priority:** MEDIUM

---

### 6. Video Exercise Demonstrations 🎥

**User Story:**
As a patient, I want to watch video demonstrations of exercises so I can perform them with correct form.

**Key Capabilities:**
- Video library for each exercise
- Play inline or fullscreen
- Slow-motion playback
- Form cues and tips overlay
- Mark as watched

**Database Schema:**
```sql
ALTER TABLE exercises ADD COLUMN video_url TEXT;
ALTER TABLE exercises ADD COLUMN video_thumbnail_url TEXT;
ALTER TABLE exercises ADD COLUMN form_cues JSONB; -- Array of form tips

CREATE TABLE video_views (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(id),
    exercise_id UUID NOT NULL REFERENCES exercises(id),
    viewed_at TIMESTAMPTZ DEFAULT NOW()
);
```

**iOS Implementation:**
```swift
import AVKit

struct ExerciseVideoView: View {
    let exercise: Exercise
    @State private var player: AVPlayer?

    var body: some View {
        VStack {
            if let videoURL = exercise.videoURL {
                VideoPlayer(player: player)
                    .frame(height: 300)
                    .onAppear {
                        player = AVPlayer(url: videoURL)
                    }
            }

            // Form cues
            ForEach(exercise.formCues, id: \.self) { cue in
                FormCueRow(cue: cue)
            }
        }
    }
}
```

**Complexity:** Medium
**Estimated Effort:** 2 days
**Priority:** MEDIUM

**Content Requirements:**
- Need to create/source exercise videos
- Video hosting (Supabase Storage or external)
- Bandwidth considerations

---

## Implementation Priority

### Phase 1: Core Features (Week 1)
1. **Patient Scheduling System** (HIGH - User priority)
2. **Workout Templates Library** (HIGH - Therapist efficiency)

### Phase 2: Analytics & Engagement (Week 2)
3. **Progress Charts & Analytics** (MEDIUM - User engagement)
4. **Video Exercise Demonstrations** (MEDIUM - User experience)

### Phase 3: Optional Enhancements (Week 3)
5. **Nutrition Tracking** (MEDIUM - Holistic health)
6. **Social Features** (LOW - Nice to have)

---

## Database Migrations Needed

**Migration 1: Scheduled Sessions**
```sql
-- Create scheduled_sessions table
-- Add RLS policies
-- Create indexes
```

**Migration 2: Workout Templates**
```sql
-- Create workout_templates table
-- Create template_phases table
-- Create template_sessions table
-- Add RLS policies
```

**Migration 3: Nutrition Tracking**
```sql
-- Create nutrition_logs table
-- Create nutrition_goals table
-- Add RLS policies
```

**Migration 4: Video & Analytics**
```sql
-- Alter exercises table for videos
-- Create video_views table
-- Add analytics helper functions
```

---

## Technical Considerations

### Performance
- Implement caching for templates
- Lazy load videos
- Optimize chart rendering
- Paginate nutrition logs

### Security
- RLS policies for all new tables
- Video access control
- Nutrition data privacy
- Template sharing permissions

### Testing
- Integration tests for scheduling
- Template creation/assignment tests
- Chart data accuracy tests
- Video playback tests

---

## Success Metrics

**Patient Scheduling:**
- % of patients using scheduler
- Sessions scheduled vs. completed ratio
- Cancellation/reschedule rate

**Templates:**
- Number of templates created
- Template reuse rate
- Time saved creating programs

**Progress Charts:**
- Chart view engagement
- Correlation with workout consistency
- User satisfaction scores

**Videos:**
- Video completion rate
- Impact on exercise form quality
- Videos viewed per session

---

## Next Steps

1. Choose which feature to implement first
2. Create detailed implementation plan
3. Design database schema
4. Build iOS UI mockups
5. Implement and test
6. Deploy to TestFlight

**Which feature should we start with?**
