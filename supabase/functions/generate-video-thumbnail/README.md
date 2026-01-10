# Generate Video Thumbnail Edge Function

**Function:** `generate-video-thumbnail`
**Build:** 63
**Linear Issue:** YUK-40

## Purpose

Automatically generates thumbnail images from uploaded exercise videos. Extracts a frame at the 3-second mark and creates a 720x405 JPEG thumbnail.

## Features

- Automatically triggered when video uploaded to `exercise-videos` bucket
- Extracts frame at 3-second timestamp
- Resizes to 720x405 (16:9 aspect ratio)
- Saves as optimized JPEG in `thumbnails/` folder
- Updates `exercise_templates.video_thumbnail_url` automatically

## Configuration

- **Thumbnail Timestamp:** 3 seconds
- **Thumbnail Size:** 720x405 pixels
- **Format:** JPEG
- **Quality:** 85%
- **Location:** `exercise-videos/thumbnails/{video-name}.jpg`

## Deployment

### Deploy to Supabase

```bash
# Deploy the function
supabase functions deploy generate-video-thumbnail

# Set environment variables
supabase secrets set SUPABASE_URL=your-project-url
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your-service-key
```

### Test Locally

```bash
# Start local Supabase
supabase start

# Serve function locally
supabase functions serve generate-video-thumbnail

# Send test request
curl -X POST http://localhost:54321/functions/v1/generate-video-thumbnail \
  -H "Content-Type: application/json" \
  -d '{
    "type": "INSERT",
    "table": "objects",
    "record": {
      "name": "bench-press.mp4",
      "bucket_id": "exercise-videos"
    }
  }'
```

## Webhook Setup

### Option 1: Database Trigger (Recommended)

Create a trigger that calls the Edge Function when a video is uploaded:

```sql
-- Enable http extension
CREATE EXTENSION IF NOT EXISTS http WITH SCHEMA extensions;

-- Create trigger function
CREATE OR REPLACE FUNCTION trigger_thumbnail_generation()
RETURNS TRIGGER AS $$
DECLARE
  function_url TEXT := 'https://your-project.supabase.co/functions/v1/generate-video-thumbnail';
  service_key TEXT := 'your-service-role-key';
BEGIN
  PERFORM net.http_post(
    url := function_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || service_key
    ),
    body := jsonb_build_object(
      'type', TG_OP,
      'table', TG_TABLE_NAME,
      'record', row_to_json(NEW)
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on storage.objects
CREATE TRIGGER on_video_upload
AFTER INSERT ON storage.objects
FOR EACH ROW
WHEN (NEW.bucket_id = 'exercise-videos' AND NEW.name !~ '^thumbnails/')
EXECUTE FUNCTION trigger_thumbnail_generation();
```

### Option 2: Supabase Dashboard Webhook

1. Go to **Database > Webhooks**
2. Click **Create a new hook**
3. Configure:
   - **Name:** Video Thumbnail Generator
   - **Table:** storage.objects
   - **Events:** INSERT
   - **Type:** HTTP Request
   - **HTTP Request:**
     - URL: `https://your-project.supabase.co/functions/v1/generate-video-thumbnail`
     - Method: POST
     - Headers:
       ```json
       {
         "Content-Type": "application/json",
         "Authorization": "Bearer your-service-role-key"
       }
       ```
4. Save the webhook

## Production Implementation

**IMPORTANT:** This Edge Function includes a placeholder for video frame extraction. For production, you must integrate with a video processing service.

### Recommended Services

#### 1. Cloudinary (Easiest)

```typescript
// Upload to Cloudinary
const formData = new FormData();
formData.append('file', videoBlob);
formData.append('upload_preset', 'your_preset');

const response = await fetch(
  'https://api.cloudinary.com/v1_1/your_cloud/video/upload',
  { method: 'POST', body: formData }
);

const result = await response.json();

// Get thumbnail URL (auto-generated)
const thumbnailUrl = result.secure_url
  .replace('.mp4', '.jpg')
  .replace('/upload/', `/upload/w_720,h_405,c_fill/so_3/`);
```

**Pros:**
- Automatic thumbnail generation
- Free tier available
- Easy to implement
- No server management

**Cons:**
- External dependency
- Ongoing costs

#### 2. FFmpeg WASM

```typescript
import { createFFmpeg } from 'https://esm.sh/@ffmpeg/ffmpeg@0.11.6';

const ffmpeg = createFFmpeg({ log: true });
await ffmpeg.load();

ffmpeg.FS('writeFile', 'input.mp4', await fetchFile(videoBlob));
await ffmpeg.run(
  '-i', 'input.mp4',
  '-ss', '3',
  '-vframes', '1',
  '-vf', 'scale=720:405',
  '-q:v', '2',
  'output.jpg'
);

const data = ffmpeg.FS('readFile', 'output.jpg');
const thumbnail = new Blob([data.buffer], { type: 'image/jpeg' });
```

**Pros:**
- Self-contained solution
- No external costs
- Works offline

**Cons:**
- Large function size (~30MB)
- Slower processing
- Higher memory usage

#### 3. AWS MediaConvert

Use AWS Lambda + MediaConvert for professional video processing.

**Pros:**
- Professional quality
- Scalable
- Fast processing

**Cons:**
- More complex setup
- AWS costs
- Requires AWS account

## Response Format

### Success Response

```json
{
  "success": true,
  "message": "Thumbnail generated successfully",
  "thumbnail": "thumbnails/bench-press.jpg",
  "video": "bench-press.mp4"
}
```

### Error Response

```json
{
  "success": false,
  "error": "Error message",
  "recommendation": "Use Cloudinary or AWS MediaConvert for production"
}
```

## Monitoring

### View Function Logs

```bash
# View recent logs
supabase functions logs generate-video-thumbnail

# Stream logs in real-time
supabase functions logs generate-video-thumbnail --follow
```

### Supabase Dashboard

1. Go to **Edge Functions**
2. Select `generate-video-thumbnail`
3. View **Logs** tab for execution history

## Troubleshooting

### Thumbnail not generating

1. **Check function logs:**
   ```bash
   supabase functions logs generate-video-thumbnail
   ```

2. **Verify webhook is triggered:**
   - Check database trigger exists
   - Verify webhook configuration

3. **Test function manually:**
   ```bash
   curl -X POST https://your-project.supabase.co/functions/v1/generate-video-thumbnail \
     -H "Authorization: Bearer your-anon-key" \
     -H "Content-Type: application/json" \
     -d '{"type":"INSERT","record":{"name":"test.mp4","bucket_id":"exercise-videos"}}'
   ```

### Function timeout

- Default timeout: 60 seconds
- Increase in Supabase Dashboard if needed
- Consider using async processing for large videos

### Video processing fails

- Verify video format (MP4 H.264)
- Check video file is valid and not corrupted
- Ensure video is at least 3 seconds long
- Verify video file size is under 15 MB

## Security

- Function uses service role key (bypasses RLS)
- Only processes files in `exercise-videos` bucket
- Skips files already in `thumbnails/` folder
- Only processes video file types (.mp4, .mov)

## Related Files

- **Bucket README:** `/supabase/storage/buckets/exercise-videos/README.md`
- **Bucket Policies:** `/supabase/storage/policies/exercise-videos.sql`
- **Video Library Migration:** `/supabase/migrations/20251218000002_create_video_library.sql`

## Support

For issues with thumbnail generation:
- Check function logs first
- Verify video format and size
- Test with known-good video file
- Consider using external video processing service for production
