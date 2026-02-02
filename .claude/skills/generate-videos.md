# Generate Exercise Videos

Batch generate exercise demonstration videos from a list.

## Trigger

```
/generate-videos [exercise-list]
```

**Examples:**
- `/generate-videos squat,deadlift,lunge`
- `/generate-videos bench-press`
- `/generate-videos all-missing` - Generate for all exercises without videos

## Prerequisites

1. Navigate to video generation toolkit:
```bash
cd scripts/video-generation
npm install
```

2. For AI-generated videos, set environment:
```bash
export RUNWAY_API_KEY="your-key"
```

3. Supabase CLI authenticated for storage upload

## Execution Steps

### Phase 1: Parse Exercise List

1. **If comma-separated list:**
   - Split by comma: `["squat", "deadlift", "lunge"]`

2. **If "all-missing":**
```sql
SELECT name, id
FROM exercise_templates
WHERE video_url IS NULL
ORDER BY usage_count DESC
LIMIT 20;
```

### Phase 2: Generate Videos

For each exercise in the list:

#### Option A: Lottie Animation (Recommended)

```bash
# 1. Search LottieFiles for animation
# https://lottiefiles.com/search?q=[exercise-name]

# 2. Download JSON file

# 3. Convert to MP4
./convert-lottie.sh [exercise].json [exercise]-animated.mp4
```

#### Option B: AI-Generated (Runway)

```bash
./generate-runway-video.sh "[exercise name]"

# Add AI disclosure watermark
ffmpeg -i [exercise]-raw.mp4 \
  -vf "drawtext=text='AI-Generated':fontsize=24:fontcolor=gray@0.7:x=10:y=h-40" \
  [exercise]-ai.mp4
```

#### Option C: Remotion Motion Graphics

```bash
cd remotion
npx remotion render ExerciseDemo [exercise]-motion.mp4 \
  --props='{"exercise":"[exercise-name]"}'
```

### Phase 3: Upload to Supabase Storage

```bash
# Upload each video
./upload-video.sh [exercise]-animated.mp4

# Verify upload
supabase storage ls exercise-videos/
```

Storage URL format:
```
https://rpbxeaxlaoyoqkohytlw.supabase.co/storage/v1/object/public/exercise-videos/[filename].mp4
```

### Phase 4: Update Database

For each uploaded video:

```sql
UPDATE exercise_templates
SET
  video_url = 'https://rpbxeaxlaoyoqkohytlw.supabase.co/storage/v1/object/public/exercise-videos/[exercise].mp4',
  video_duration = 30,
  updated_at = NOW()
WHERE name ILIKE '%[exercise]%';
```

Execute via Supabase Dashboard SQL Editor:
- URL: https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql

### Phase 5: Verification

```sql
-- Verify videos were linked
SELECT name, video_url, video_duration
FROM exercise_templates
WHERE video_url IS NOT NULL
ORDER BY updated_at DESC
LIMIT 10;
```

## Output

```
Video Generation Complete

Generated: 3 videos
Method: Lottie Animation

| Exercise | Status | Duration |
|----------|--------|----------|
| squat | Uploaded | 30s |
| deadlift | Uploaded | 30s |
| lunge | Uploaded | 30s |

Database: 3 exercise_templates updated
Storage: 3 files in exercise-videos bucket

Next Steps:
1. Open iOS app
2. Navigate to any updated exercise
3. Verify video plays correctly
```

## Batch Generation Script

For large batches, use this helper:

```bash
#!/bin/bash
# generate-batch.sh

EXERCISES="squat,deadlift,bench-press,overhead-press,barbell-row"

IFS=',' read -ra EXERCISE_LIST <<< "$EXERCISES"

for exercise in "${EXERCISE_LIST[@]}"; do
    echo "Processing: $exercise"

    # Generate (using Lottie approach)
    ./convert-lottie.sh "${exercise}.json" "${exercise}-animated.mp4"

    # Upload
    ./upload-video.sh "${exercise}-animated.mp4"

    echo "Completed: $exercise"
done

echo "Batch complete!"
```

## Troubleshooting

### "Lottie file not found"
- Search LottieFiles manually: https://lottiefiles.com/free-animations/fitness
- Download JSON file to scripts/video-generation/

### "Upload failed"
- Check Supabase CLI auth: `supabase login`
- Verify storage bucket exists: `exercise-videos`
- Check file size < 50MB

### "Video not playing in app"
- Verify URL is publicly accessible
- Check video format is MP4 (H.264)
- Ensure video_url column updated in database

## Reference

See also:
- `scripts/video-generation/README.md` - Full toolkit documentation
- `scripts/video-generation/upload-video.sh` - Upload script
- `scripts/video-generation/convert-lottie.sh` - Conversion script
