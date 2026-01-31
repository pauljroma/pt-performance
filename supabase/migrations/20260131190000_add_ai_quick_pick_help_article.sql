-- Add AI Quick Pick Help Article
-- Build 358 - Documents the AI Quick Pick feature introduced in Build 352-357
-- Created: 2026-01-31

BEGIN;

-- First, add 'features' category if it doesn't exist
-- We need to alter the check constraint to allow the new category
ALTER TABLE public.help_articles DROP CONSTRAINT IF EXISTS help_articles_category_check;
ALTER TABLE public.help_articles ADD CONSTRAINT help_articles_category_check CHECK (category IN (
    'nutrition', 'recovery', 'arm-care', 'hitting',
    'speed', 'mobility', 'warmup', 'injury-prevention',
    'mental', 'training', 'features'
));

-- Insert the AI Quick Pick help article
INSERT INTO public.help_articles (
    slug,
    title,
    category,
    subcategory,
    content,
    excerpt,
    tags,
    difficulty,
    reading_time_minutes,
    author,
    reviewed_by,
    is_published,
    featured
) VALUES (
    'ai-quick-pick',
    'AI Quick Pick: Smart Workout Recommendations',
    'features',
    'workout-selection',
    E'# AI Quick Pick: Smart Workout Recommendations

AI Quick Pick is your intelligent workout assistant that recommends the perfect workout based on your current state and fitness goals.

## What is AI Quick Pick?

AI Quick Pick uses GPT-4 to analyze multiple factors about you and recommend workouts that are optimally suited for right now. Instead of guessing what to do or scrolling through endless options, AI Quick Pick instantly surfaces the best choices for you.

## How AI Quick Pick Personalizes Your Recommendations

AI Quick Pick considers five key factors when making recommendations:

### 1. Readiness Score
Your daily readiness check-in provides crucial data:
- **Sleep quality** - How well-rested you are
- **Soreness levels** - Current muscle fatigue and recovery status
- **Energy levels** - Your perceived energy for the day
- **Stress levels** - Mental and physical stress factors

### 2. Recent Workout History
AI Quick Pick reviews your last 7 days of training to:
- Avoid overworking muscle groups
- Ensure balanced training distribution
- Progress appropriately based on recent volume

### 3. Active Goals
Your fitness goals influence recommendations:
- Strength building
- Weight loss
- Muscle gain
- Mobility improvement
- Sport-specific training

### 4. Time of Day
Recommendations adjust based on when you''re working out:
- Morning workouts may favor energizing routines
- Evening sessions may include more intensive strength work
- Late-night workouts may suggest lighter options

### 5. Category Preferences
Your preferred workout types help narrow down the best matches from the available library.

## AI Mode vs. Shuffle Mode

Quick Pick offers two distinct modes:

### AI Mode (Recommended)
- Uses GPT-4 intelligence to analyze your data
- Considers all five personalization factors
- Provides 3 tailored recommendations with explanations
- Best for: Getting the optimal workout for your current state

### Shuffle Mode
- Randomly selects from your workout library
- Filtered by your category preferences only
- No personalization based on readiness or history
- Best for: When you want variety or to discover new workouts

## How to Use AI Quick Pick

### Step 1: Tap Quick Pick
From your home screen or workout library, tap the **Quick Pick** button (lightning bolt icon).

### Step 2: Select Your Preferences
Choose your preferences:
- Workout duration (15, 30, 45, or 60 minutes)
- Equipment available (bodyweight, dumbbells, barbell, etc.)
- Workout categories you''re interested in today

### Step 3: Tap "Get AI Picks"
Hit the **Get AI Picks** button to generate your personalized recommendations.

### Step 4: Review and Choose
AI Quick Pick presents 3 workout options:
- Each includes a brief explanation of why it''s recommended
- View workout details before committing
- Tap to start your selected workout

## Tips for Best Results

1. **Complete your daily readiness check-in** - The more data AI has, the better your recommendations
2. **Log all your workouts** - Consistent tracking improves future suggestions
3. **Update your goals regularly** - Keep your fitness objectives current
4. **Try the top recommendation** - The first option is usually the best match

## Frequently Asked Questions

**Q: How accurate are AI recommendations?**
A: AI Quick Pick improves over time as it learns from your workout patterns and feedback. Most users find the recommendations highly relevant after 1-2 weeks of consistent use.

**Q: Can I still choose my own workout?**
A: Absolutely! AI Quick Pick is a suggestion tool. You can always browse the full library and select any workout you prefer.

**Q: Does AI Quick Pick work offline?**
A: No, AI Quick Pick requires an internet connection to generate recommendations. Shuffle mode works offline.

**Q: How often should I use AI Quick Pick?**
A: Use it whenever you''re unsure what to do or want an optimized recommendation. Many users rely on it daily for their primary workout selection.',
    'AI Quick Pick uses GPT-4 to recommend workouts based on your readiness, workout history, goals, and preferences.',
    ARRAY['ai', 'quick pick', 'recommendations', 'gpt-4', 'personalization', 'workout selection', 'smart', 'intelligent'],
    'beginner',
    4,
    'PT Performance Development Team',
    'PT Performance Product Team',
    true,
    true
) ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title,
    category = EXCLUDED.category,
    subcategory = EXCLUDED.subcategory,
    content = EXCLUDED.content,
    excerpt = EXCLUDED.excerpt,
    tags = EXCLUDED.tags,
    difficulty = EXCLUDED.difficulty,
    reading_time_minutes = EXCLUDED.reading_time_minutes,
    author = EXCLUDED.author,
    reviewed_by = EXCLUDED.reviewed_by,
    is_published = EXCLUDED.is_published,
    featured = EXCLUDED.featured,
    last_updated = NOW();

COMMIT;
