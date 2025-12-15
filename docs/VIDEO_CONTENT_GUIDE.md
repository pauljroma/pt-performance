# Exercise Video Content Guide

**Build 46 - Video Infrastructure**
Last Updated: 2025-12-15

---

## Overview

This guide explains how to create, prepare, and upload exercise demonstration videos for the PT Performance app.

## Video Requirements

### Technical Specifications

- **Format:** MP4 (H.264 codec)
- **Resolution:** 1920x1080 (1080p) recommended
- **Frame Rate:** 30fps or 60fps
- **Aspect Ratio:** 16:9 (horizontal)
- **Duration:** 30-90 seconds per exercise
- **File Size:** < 50MB per video (optimize for mobile)
- **Audio:** Optional, but recommended for verbal cues

### Quality Standards

✅ **Good Video Practices:**
- Clear, well-lit subject
- Uncluttered background
- Multiple camera angles (if possible)
- Slow, controlled movements
- Full range of motion visible
- Professional demonstrator with proper form

❌ **Avoid:**
- Poor lighting or shadows
- Shaky camera work
- Background distractions
- Fast, unclear movements
- Partial or cut-off body parts
- Improper form demonstration

---

## Filming Guidelines

### Setup

1. **Camera Position:**
   - Side view for most exercises (squat, deadlift, press)
   - Front view for balance/stability exercises
   - 45-degree angle for compound movements
   - Ensure full body is in frame

2. **Lighting:**
   - Natural daylight preferred
   - Avoid harsh shadows
   - Ensure subject is well-lit from front
   - Test lighting before filming

3. **Background:**
   - Solid, neutral color (white, gray, or gym equipment)
   - No distracting elements
   - Professional gym setting preferred

### Recording

1. **Demonstration:**
   - Perform 2-3 complete repetitions
   - Move slowly and deliberately
   - Show full range of motion
   - Pause at key positions if helpful
   - Demonstrate both concentric and eccentric phases

2. **Multiple Takes:**
   - Record 3-5 takes of each exercise
   - Choose the best quality/form
   - Keep raw footage as backup

3. **Variations:**
   - Record common variations if applicable
   - Show regression/progression options
   - Demonstrate modifications for injuries

---

## Post-Production

### Editing Checklist

- [ ] Trim to 30-90 seconds
- [ ] Add text overlays for exercise name
- [ ] Add timestamp markers for form cues
- [ ] Color correction if needed
- [ ] Audio normalization
- [ ] Export to MP4 (H.264, 1080p)
- [ ] Optimize file size (< 50MB)

### Form Cue Timestamps

Identify 3-5 key form cues with timestamps:

```json
[
  {"cue": "Keep chest up and core braced", "timestamp": 5},
  {"cue": "Initiate movement from hips", "timestamp": 10},
  {"cue": "Drive through heels", "timestamp": 15},
  {"cue": "Full hip extension at top", "timestamp": 20},
  {"cue": "Control the descent", "timestamp": 25}
]
```

### Thumbnail Creation

Create a thumbnail image for each video:
- **Format:** JPG or PNG
- **Resolution:** 640x360 pixels
- **Content:** Mid-movement or starting position
- **File Size:** < 100KB

---

## Video Storage & Upload

### Storage Options

**Option 1: Supabase Storage (Recommended)**
```bash
# Upload video to Supabase Storage
supabase storage upload videos squat_demo.mp4

# Get public URL
https://[project-id].supabase.co/storage/v1/object/public/videos/squat_demo.mp4
```

**Option 2: Cloud CDN (Cloudflare, AWS CloudFront)**
- Better performance for large user base
- Lower egress costs
- Global distribution

**Option 3: YouTube/Vimeo (Embed)**
- Free hosting
- Automatic transcoding
- No bandwidth costs
- Less control over player

### Database Update

After uploading videos, update the database:

```sql
-- Update exercise with video information
UPDATE exercises
SET
    video_url = 'https://your-cdn.com/videos/squat_demo.mp4',
    video_thumbnail_url = 'https://your-cdn.com/thumbnails/squat_thumb.jpg',
    video_duration = 45,
    form_cues = '[
        {"cue": "Keep chest up", "timestamp": 5},
        {"cue": "Drive through heels", "timestamp": 15},
        {"cue": "Control descent", "timestamp": 25}
    ]'::jsonb
WHERE name = 'Squat';
```

Or use the mobile app admin panel (coming soon).

---

## Content Library Organization

### Naming Convention

Use consistent naming for easy management:

```
[exercise-name]_[variation]_[angle].mp4

Examples:
- squat_back_side.mp4
- bench_press_barbell_front.mp4
- deadlift_conventional_45deg.mp4
- plank_standard_side.mp4
```

### Folder Structure

```
videos/
├── lower-body/
│   ├── squat_back_side.mp4
│   ├── deadlift_conventional_45deg.mp4
│   └── lunge_forward_side.mp4
├── upper-body/
│   ├── bench_press_barbell_front.mp4
│   ├── row_barbell_side.mp4
│   └── shoulder_press_dumbbell_front.mp4
├── core/
│   ├── plank_standard_side.mp4
│   └── dead_bug_front.mp4
└── thumbnails/
    ├── squat_back_side.jpg
    └── bench_press_barbell_front.jpg
```

---

## Priority Exercises

Start with these commonly prescribed exercises:

### Lower Body (Priority 1)
1. Back Squat
2. Front Squat
3. Deadlift (Conventional)
4. Romanian Deadlift
5. Walking Lunge
6. Step Up
7. Single Leg RDL
8. Leg Press

### Upper Body (Priority 1)
1. Bench Press (Barbell)
2. Overhead Press
3. Barbell Row
4. Pull-Up
5. Dumbbell Bench Press
6. Dumbbell Row
7. Lat Pulldown
8. Chest Fly

### Core (Priority 2)
1. Plank
2. Side Plank
3. Dead Bug
4. Bird Dog
5. Pallof Press
6. Ab Wheel

### Rehab/Prehab (Priority 2)
1. Banded Clamshell
2. Hip Bridge
3. Single Leg Bridge
4. Band Pull-Apart
5. Face Pull
6. Wall Slide

---

## Video Analytics

Track video engagement to improve content:

### Metrics Available

```swift
// Fetch video statistics
let stats = try await VideoService.shared.fetchVideoStats(for: exerciseId)

// Available metrics:
- Total viewers (unique patients)
- Total views (all plays)
- Completed views (watched to end)
- Completion rate (%)
- Average watch duration
```

### Optimization Tips

- Low completion rate? Video may be too long
- Low view count? Exercise not commonly prescribed
- High replay rate? Consider adding more detail
- Dropoff at specific timestamp? Clarify that section

---

## Mobile Integration

Videos are automatically integrated into the app:

### Patient Experience

1. **Exercise List:** Thumbnail preview if video available
2. **Exercise Detail:** Full video player with form cues
3. **During Workout:** Quick reference video access
4. **Form Check:** Can watch between sets

### Therapist Tools

- See which videos patients have watched
- Track video engagement per patient
- Identify exercises needing better videos

---

## Budget & Resources

### DIY Option (Low Budget)

**Equipment Needed:**
- iPhone or modern smartphone ($0 if you have one)
- Tripod ($20-50)
- Basic lighting ($50-100)
- Free editing software (iMovie, DaVinci Resolve)

**Total:** ~$100

### Professional Option

**Services:**
- Videographer: $500-1000/day
- Studio rental: $200-500/day
- Professional editing: $50-100/video

**Total:** ~$5000 for 50 videos

### Hybrid Approach (Recommended)

- Film in-house with good equipment ($300-500)
- Outsource editing ($25-50/video)
- Professional for hero exercises only

**Total:** ~$2000 for 50 videos

---

## Next Steps

1. **Pilot Program:** Start with 10 most common exercises
2. **Gather Feedback:** Survey patients and therapists
3. **Iterate:** Improve based on usage data
4. **Scale:** Add more exercises over time

---

## Resources

- **Video Compression:** HandBrake (free)
- **Editing:** DaVinci Resolve (free), Final Cut Pro, Adobe Premiere
- **Hosting:** Supabase Storage, AWS S3, Cloudflare R2
- **CDN:** Cloudflare, AWS CloudFront
- **Stock Footage:** If needed, Storyblocks, Adobe Stock

---

## Support

Questions about video implementation?
- Technical: Check VideoService.swift documentation
- Content: This guide
- Database: See migration `20251215140000_add_exercise_videos.sql`

---

**Version:** 1.0
**Last Updated:** 2025-12-15
**Author:** Build 46 Swarm Agent 4
