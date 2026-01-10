# Exercise Videos Storage Bucket

**Bucket Name:** `exercise-videos`
**Created:** 2025-12-19
**Linear Issue:** YUK-38

## Purpose

This Supabase Storage bucket stores exercise demonstration videos for the PT Performance application. Videos are used in the video library feature and exercise templates.

## Configuration

- **Access:** Public read, authenticated write (admin/therapist only)
- **Max File Size:** 15 MB per video file
- **Allowed File Types:** MP4, MOV
- **Recommended Format:** MP4 (H.264 codec)
- **Recommended Resolution:** 1080p (1920x1080)
- **Recommended Duration:** 30-90 seconds per exercise
- **Target File Size:** 5-12 MB per video

## Folder Structure

```
exercise-videos/
├── thumbnails/              # Auto-generated thumbnails (720x405 JPG)
│   ├── {exercise-name}.jpg
│   └── ...
└── {exercise-name}.mp4      # Exercise demonstration videos
```

## Video Naming Convention

Use kebab-case naming that matches the exercise template name:
- `barbell-bench-press.mp4`
- `deadlift.mp4`
- `goblet-squat.mp4`
- `pull-up.mp4`

## Upload Process

### For Content Team

1. **Record video:**
   - Use stable camera position
   - Good lighting
   - Show full range of motion
   - 30-90 second duration
   - 1080p resolution minimum

2. **Export video:**
   - Format: MP4 (H.264)
   - Keep file size under 15 MB
   - Optimize with HandBrake or similar if needed

3. **Upload via Supabase Dashboard:**
   - Go to Storage > exercise-videos
   - Upload video with correct naming convention
   - Thumbnail will auto-generate via Edge Function

4. **Update database:**
   - Video URL will be: `https://{project}.supabase.co/storage/v1/object/public/exercise-videos/{filename}.mp4`
   - Update `exercise_templates.video_url` with the URL
   - Update `exercise_templates.video_file_size` with file size in bytes

### For Developers

**Programmatic Upload:**
```typescript
const { data, error } = await supabase.storage
  .from('exercise-videos')
  .upload('barbell-bench-press.mp4', videoFile, {
    cacheControl: '3600',
    upsert: false
  });
```

**Get Public URL:**
```typescript
const { data } = supabase.storage
  .from('exercise-videos')
  .getPublicUrl('barbell-bench-press.mp4');

console.log(data.publicUrl);
```

## Security Policies

Defined in `/supabase/storage/policies/exercise-videos.sql`:

1. **Public Read:** Anyone can view/download videos (for app display)
2. **Authenticated Write:** Only authenticated users can upload
3. **Admin/Therapist Delete:** Only users with admin or therapist role can delete videos

## Thumbnail Generation

Thumbnails are automatically generated via Edge Function when a new video is uploaded:
- Function: `generate-video-thumbnail`
- Frame: Extracted at 3-second mark
- Size: 720x405 pixels (16:9 aspect ratio)
- Format: JPEG (optimized for web)
- Location: `exercise-videos/thumbnails/{exercise-name}.jpg`

## Troubleshooting

### Video won't upload
- Check file size (must be < 15 MB)
- Verify file format (MP4 or MOV only)
- Ensure you're authenticated with proper role

### Video URL not working
- Verify bucket name is `exercise-videos` (not `exercise_videos`)
- Check the file exists in storage
- Confirm RLS policies are applied

### Thumbnail not generating
- Check Edge Function logs in Supabase Dashboard
- Verify video is valid MP4 format
- Ensure video is at least 3 seconds long

## Related Files

- **Bucket Policies:** `/supabase/storage/policies/exercise-videos.sql`
- **Edge Function:** `/supabase/functions/generate-video-thumbnail/index.ts`
- **Video Library Migration:** `/supabase/migrations/20251218000002_create_video_library.sql`
- **URL Validation Migration:** `/supabase/migrations/20251220000001_validate_video_urls.sql`

## Access URLs

**Project ID:** `rpbxeaxlaoyoqkohytlw`

**Public URL Pattern:**
```
https://rpbxeaxlaoyoqkohytlw.supabase.co/storage/v1/object/public/exercise-videos/{filename}
```

**Example:**
```
https://rpbxeaxlaoyoqkohytlw.supabase.co/storage/v1/object/public/exercise-videos/bench-press.mp4
https://rpbxeaxlaoyoqkohytlw.supabase.co/storage/v1/object/public/exercise-videos/thumbnails/bench-press.jpg
```

## Content Team Checklist

Before marking Build 63 complete, ensure:

- [ ] All 50+ exercise videos are uploaded
- [ ] Video naming matches exercise template names
- [ ] All thumbnails have been auto-generated
- [ ] `exercise_templates` table is updated with correct URLs
- [ ] Videos play correctly in iOS app
- [ ] File sizes are optimized (5-12 MB range)
- [ ] All videos are 1080p resolution
- [ ] Demonstrations show proper form and full range of motion

## Support

For issues with video storage or upload, contact:
- **Backend Team:** Storage bucket configuration
- **Infrastructure Team:** Supabase permissions and policies
- **Content Team Lead:** Video quality and content standards
