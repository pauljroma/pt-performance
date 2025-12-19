# Video Sourcing Strategy - Build 69 Agent 4

## Overview
This document outlines the strategy for sourcing, uploading, and managing 50+ exercise videos for the PTPerformance iOS app.

## Video Requirements

### Technical Specifications
- **Format**: MP4 (H.264 codec)
- **Resolution**: 1080p (1920x1080) minimum
- **Duration**: 30-90 seconds per exercise
- **File Size**: 5-15MB per video (target)
- **Frame Rate**: 30fps
- **Audio**: Optional (can be silent or with coaching cues)
- **Orientation**: Landscape or Portrait (landscape preferred for demo clarity)

### Content Requirements
- **Total Count**: 50+ exercise videos
- **Categories**:
  - Upper Body Push: 8 exercises
  - Upper Body Pull: 7 exercises
  - Lower Body Squat/Hinge: 8 exercises
  - Lower Body Lunge/Accessories: 7 exercises
  - Core & Stability: 10 exercises
  - Accessories & Mobility: 10 exercises

## Sourcing Options

### Option 1: Free Stock Video Resources (RECOMMENDED FOR DEMO)
Use royalty-free exercise videos from these sources:

1. **Pexels Videos** (https://www.pexels.com/videos/)
   - Search terms: "exercise", "workout", "gym", "fitness", "strength training"
   - License: Free for commercial use, no attribution required
   - Quality: High (1080p, 4K available)
   - Coverage: ~30-40 common exercises

2. **Pixabay Videos** (https://pixabay.com/videos/)
   - Search terms: "fitness", "training", "bodyweight", "gym equipment"
   - License: Free for commercial use
   - Quality: High
   - Coverage: ~20-30 exercises

3. **Mixkit** (https://mixkit.co/free-stock-video/fitness/)
   - Curated fitness video collection
   - License: Free for commercial use
   - Quality: Professional grade
   - Coverage: ~15-25 exercises

4. **Coverr** (https://coverr.co/)
   - Search: "fitness", "exercise", "workout"
   - License: Free for commercial use
   - Quality: High
   - Coverage: ~10-15 exercises

### Option 2: Record Custom Videos
For exercises not available in stock footage:

**Equipment Needed**:
- Smartphone with 1080p video capability
- Tripod or stable mount
- Good lighting (natural or ring light)
- Clean background
- Exercise equipment (or bodyweight alternatives)

**Recording Guidelines**:
- Film at 1080p, 30fps
- Keep duration 30-60 seconds
- Show exercise from multiple angles if possible
- Demonstrate proper form with controlled tempo
- Include setup, execution, and finish
- Ensure proper lighting and framing

**Recommended Angles**:
- Lateral view (side): Shows depth and range of motion
- Frontal view: Shows symmetry and form
- 45-degree angle: Comprehensive view

### Option 3: Placeholder Videos (FOR DEVELOPMENT)
For immediate development and testing:

**Strategy**:
- Create 30-second solid color videos with text overlay
- Each video displays exercise name
- Use ffmpeg to generate programmatically
- Allows full app functionality testing without real content

**Implementation**:
```bash
# Generate placeholder video
ffmpeg -f lavfi -i color=c=blue:s=1920x1080:d=30 \
  -vf "drawtext=text='Exercise Name':fontsize=60:fontcolor=white:x=(w-text_w)/2:y=(h-text_h)/2" \
  -c:v libx264 -pix_fmt yuv420p output.mp4
```

## Recommended Approach (Hybrid)

For Build 69, use a hybrid approach:

1. **Phase 1: Foundation (5-10 videos)**
   - Source 5-10 most common exercises from Pexels/Pixabay
   - Focus on: Squat, Deadlift, Bench Press, Pull-up, Plank, Push-up, Lunge, Row
   - These demonstrate all video functionality

2. **Phase 2: Expansion (20-30 videos)**
   - Add stock videos for remaining common movements
   - Fill gaps with placeholder videos for less common exercises
   - Prioritize exercises used in "Winter Lift" program

3. **Phase 3: Production (50+ videos)**
   - Replace placeholders with custom recordings or licensed content
   - Ensure professional quality and consistency
   - Add coaching cues and multiple angles

## Video Processing Pipeline

### 1. Download/Record
```bash
# Create directory structure
mkdir -p videos/source
mkdir -p videos/processed
mkdir -p videos/thumbnails
```

### 2. Process Videos
```bash
# Standardize format, resolution, and compression
ffmpeg -i input.mp4 \
  -vf scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2 \
  -c:v libx264 -preset medium -crf 23 \
  -c:a aac -b:a 128k \
  -movflags +faststart \
  output.mp4
```

### 3. Generate Thumbnails
```bash
# Extract thumbnail at 3 seconds
ffmpeg -i input.mp4 -ss 00:00:03 -vframes 1 \
  -vf scale=1920:1080 \
  thumbnail.jpg
```

### 4. Upload to Supabase Storage
```bash
# Upload via Supabase CLI
supabase storage cp videos/processed/squat.mp4 exercise-videos/squat.mp4
supabase storage cp videos/thumbnails/squat.jpg exercise-videos/thumbnails/squat.jpg
```

## Exercise Video Mapping

### High Priority Exercises (Stock Footage Available)
These are commonly available in stock video libraries:

**Upper Body**:
- Barbell Bench Press ✓
- Push-ups ✓
- Pull-ups ✓
- Barbell Row ✓
- Dumbbell Shoulder Press ✓
- Bicep Curl ✓
- Tricep Extension ✓
- Dips ✓

**Lower Body**:
- Barbell Back Squat ✓
- Deadlift ✓
- Walking Lunges ✓
- Leg Press ✓
- Calf Raise ✓
- Leg Curl ✓
- Leg Extension ✓

**Core**:
- Plank ✓
- Side Plank ✓
- Mountain Climbers ✓
- Russian Twist ✓
- Dead Bug ✓
- Bird Dog ✓

### Medium Priority (May Need Recording)
- Romanian Deadlift
- Bulgarian Split Squat
- Landmine Press
- Face Pull
- Pallof Press
- Nordic Hamstring Curl
- Ab Wheel Rollout

### Low Priority (Use Placeholders Initially)
- Thread the Needle
- World's Greatest Stretch
- Foam Roll Thoracic
- Cat-Cow Stretch
- Inverted Row

## Storage Structure

```
exercise-videos/
├── upper-body/
│   ├── bench-press.mp4
│   ├── pushup.mp4
│   └── ...
├── lower-body/
│   ├── squat.mp4
│   ├── deadlift.mp4
│   └── ...
├── core/
│   ├── plank.mp4
│   └── ...
├── accessories/
│   └── ...
└── thumbnails/
    ├── bench-press.jpg
    ├── pushup.jpg
    └── ...
```

## Estimated Timeline

### Quick Path (Placeholders + 10 Real Videos)
- **Day 1**: Create placeholder generation script (2 hours)
- **Day 1**: Generate 50 placeholders (1 hour)
- **Day 1**: Source 10 stock videos (2 hours)
- **Day 1**: Process and upload all videos (2 hours)
- **Day 1**: Generate thumbnails (1 hour)
- **Day 1**: Update database (1 hour)
- **Total**: 1 day

### Professional Path (50+ Real Videos)
- **Week 1**: Source 30 stock videos (10 hours)
- **Week 2**: Record 20 custom videos (20 hours)
- **Week 3**: Process all videos (5 hours)
- **Week 3**: Generate thumbnails (3 hours)
- **Week 3**: Upload and update database (2 hours)
- **Total**: 3 weeks

## Budget Considerations

### Free Option
- $0 - Use stock footage and placeholders
- Time: 1 day for basic implementation

### Licensed Stock Footage
- $50-200 for premium stock video packs
- Examples: Envato Elements, Shutterstock, Adobe Stock
- Get 50+ exercise videos in consistent quality

### Professional Production
- $2,000-5,000 for professional videographer
- Consistent lighting, quality, branding
- Custom content ownership

## Recommendation for Build 69

**Immediate Implementation (This Build)**:
1. Create placeholder generation script
2. Generate 50 placeholder videos
3. Source and add 5-10 real stock videos for demo
4. Fully implement upload, thumbnail, and database update pipeline
5. Document the process for future content team

**Next Phase (Post-Build 69)**:
1. Content team sources remaining stock videos
2. Plan custom video production for gaps
3. Replace placeholders systematically
4. Add coaching audio overlays

This approach allows:
- Full app functionality testing NOW
- Gradual content improvement
- No blocking on video production
- Clear path to production quality

## Success Metrics

- ✓ 50+ videos uploaded to Supabase Storage
- ✓ All videos have thumbnails
- ✓ exercise_templates table updated with URLs
- ✓ Videos playable in iOS app
- ✓ Metadata CSV created
- ✓ Process documented for content team
