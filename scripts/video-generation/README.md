# Exercise Video Generation Toolkit

Generate demonstration videos for the PT Performance app exercise library.

## Quick Start

```bash
# 1. Navigate to this directory
cd scripts/video-generation

# 2. Install dependencies
npm install

# 3. Generate your first video (Lottie approach - fastest)
./download-lottie-video.sh

# 4. Upload to Supabase
./upload-video.sh bench-press-animated.mp4
```

## 4 Approaches

| Approach | Time | Cost | Quality | Best For |
|----------|------|------|---------|----------|
| [1. Lottie Animation](#1-lottie-animation) | 30 min | $0-50 | Professional | MVP, fast iteration |
| [2. AI-Generated](#2-ai-generated-runway) | 2 hrs | ~$3/video | Realistic | Premium feel |
| [3. Motion Graphics](#3-motion-graphics-remotion) | 4-8 hrs | $0 | Custom | Full control |
| [4. 3D Model](#4-3d-model-blender) | 6-12 hrs | $0 | Cinematic | Premium library |

---

## 1. Lottie Animation

**Recommended for MVP** - Fastest path to professional videos.

### Download from LottieFiles

1. Visit [LottieFiles Fitness](https://lottiefiles.com/free-animations/fitness)
2. Search for "bench press" or specific exercise
3. Download as `.lottie` or `.json`
4. Convert to MP4:

```bash
# Using lottie-to-video CLI
npx lottie-to-video input.json -o bench-press-animated.mp4 --width 1080 --height 1080

# Or use the bundled script
./convert-lottie.sh input.json bench-press-animated.mp4
```

### Alternative: VectorFitExercises Library

Purchase access at vectorfit.com (~$100-300 for 1,400+ exercises)

---

## 2. AI-Generated (Runway)

**Best for realistic human demonstrations.**

### Setup

1. Sign up at [runwayml.com/api](https://runwayml.com/api)
2. Get API key from dashboard
3. Set environment variable:

```bash
export RUNWAY_API_KEY="your-key-here"
```

### Generate Video

```bash
# Using the helper script
./generate-runway-video.sh "bench press"

# Or directly with curl
curl -X POST "https://api.runwayml.com/v1/gen3/turbo" \
  -H "Authorization: Bearer $RUNWAY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Professional fitness trainer demonstrating bench press exercise, white background studio, side angle view, proper form, athletic wear, educational demonstration",
    "duration": 10
  }'
```

### Add AI Disclosure (Required)

```bash
ffmpeg -i input.mp4 -vf "drawtext=text='AI-Generated Demonstration':fontsize=24:fontcolor=gray@0.7:x=10:y=h-40" bench-press-ai.mp4
```

---

## 3. Motion Graphics (Remotion)

**Best for fully custom, scalable production.**

### Setup

```bash
# Create new Remotion project
npx create-video@latest pt-exercise-videos
cd pt-exercise-videos
npm install
```

### Create Exercise Component

See `remotion/ExerciseDemo.tsx` template in this directory.

### Render Video

```bash
npx remotion render BenchPress bench-press-motion.mp4 --props='{"exercise":"bench-press"}'
```

---

## 4. 3D Model (Blender + Mixamo)

**Best for premium, cinematic quality.**

### Setup

1. Download [Blender](https://www.blender.org/download/) (free)
2. Create account at [Mixamo](https://www.mixamo.com/) (free with Adobe ID)

### Workflow

1. Download character from Mixamo
2. Find/create bench press animation
3. Import into Blender
4. Setup white background scene
5. Render to MP4

See `blender/render_exercise.py` for automation script.

---

## Upload to Supabase

After generating any video:

```bash
# Upload video
./upload-video.sh bench-press-animated.mp4

# Or manually with Supabase CLI
npx supabase storage cp bench-press-animated.mp4 \
  sb://rpbxeaxlaoyoqkohytlw/exercise-videos/bench-press.mp4
```

### Update Database

```sql
UPDATE exercise_templates
SET
  video_url = 'https://rpbxeaxlaoyoqkohytlw.supabase.co/storage/v1/object/public/exercise-videos/bench-press.mp4',
  video_duration = 30
WHERE name ILIKE '%bench%press%';
```

---

## Verification

1. Upload test video to `exercise-videos` bucket
2. Update one exercise template with video URL
3. Open PT Performance iOS app
4. Navigate to that exercise
5. Confirm video plays in VideoPlayerView

---

## File Naming Convention

```
{exercise-slug}-{style}.mp4

Examples:
- bench-press-animated.mp4    (Lottie)
- bench-press-ai.mp4          (Runway)
- bench-press-motion.mp4      (Remotion)
- bench-press-3d.mp4          (Blender)
```

---

## Recommended Order

1. **Day 1 AM**: Download Lottie animation, convert to MP4
2. **Day 1 PM**: Generate Runway AI video with prompt
3. **Day 2**: Build Remotion prototype with stick figure
4. **Day 3**: Setup Blender + Mixamo pipeline

Total: ~2-3 days, ~$3

---

## Long-term Recommendation

For a solo developer, **Lottie animations (Approach 1)** is recommended:
- Fastest time to market
- Professional, consistent quality
- One-time library purchase (~$100-300 for 1,400+ exercises)
- No ongoing API costs
- No AI disclosure complexity

Upgrade to 3D models later if users engage well with video content.
