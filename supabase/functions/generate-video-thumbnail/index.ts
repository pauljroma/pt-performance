// Build 63: Generate Video Thumbnail Edge Function (YUK-40)
// Automatically extracts thumbnail from uploaded exercise videos
// Triggered on video upload to exercise-videos bucket

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

// Configuration
const THUMBNAIL_TIMESTAMP = 3; // Extract frame at 3 seconds
const THUMBNAIL_WIDTH = 720;
const THUMBNAIL_HEIGHT = 405; // 16:9 aspect ratio
const THUMBNAIL_QUALITY = 85; // JPEG quality (0-100)

interface VideoUploadEvent {
  type: string;
  table: string;
  record: {
    id: string;
    name: string;
    bucket_id: string;
    metadata: any;
  };
  old_record: any;
}

serve(async (req) => {
  try {
    // Get Supabase client with service role (bypasses RLS)
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Parse the webhook event
    const event: VideoUploadEvent = await req.json();

    console.log('Thumbnail generation triggered:', {
      type: event.type,
      bucket: event.record.bucket_id,
      filename: event.record.name
    });

    // Only process INSERT events on exercise-videos bucket
    if (event.type !== 'INSERT' || event.record.bucket_id !== 'exercise-videos') {
      return new Response(
        JSON.stringify({ message: 'Not a video upload event, skipping' }),
        { headers: { 'Content-Type': 'application/json' }, status: 200 }
      );
    }

    const videoFilename = event.record.name;

    // Skip if this is already a thumbnail
    if (videoFilename.startsWith('thumbnails/')) {
      console.log('Skipping thumbnail file:', videoFilename);
      return new Response(
        JSON.stringify({ message: 'Thumbnail file, skipping' }),
        { headers: { 'Content-Type': 'application/json' }, status: 200 }
      );
    }

    // Only process video files
    const videoExtensions = ['.mp4', '.mov', '.MP4', '.MOV'];
    const isVideo = videoExtensions.some(ext => videoFilename.endsWith(ext));

    if (!isVideo) {
      console.log('Not a video file:', videoFilename);
      return new Response(
        JSON.stringify({ message: 'Not a video file, skipping' }),
        { headers: { 'Content-Type': 'application/json' }, status: 200 }
      );
    }

    console.log('Processing video:', videoFilename);

    // Download the video file from storage
    const { data: videoData, error: downloadError } = await supabase.storage
      .from('exercise-videos')
      .download(videoFilename);

    if (downloadError || !videoData) {
      throw new Error(`Failed to download video: ${downloadError?.message}`);
    }

    console.log('Video downloaded, size:', videoData.size, 'bytes');

    // Generate thumbnail using FFmpeg
    // Note: This requires FFmpeg to be available in the Deno Deploy environment
    // For production, you may need to use a video processing service like Cloudinary or AWS MediaConvert

    const thumbnailFilename = getThumbnailFilename(videoFilename);

    // For now, we'll create a placeholder approach since FFmpeg may not be available
    // In production, this should be replaced with actual video frame extraction

    try {
      // Attempt to use FFmpeg via WASM or external service
      const thumbnail = await extractVideoFrame(videoData, THUMBNAIL_TIMESTAMP);

      // Upload thumbnail to storage
      const { error: uploadError } = await supabase.storage
        .from('exercise-videos')
        .upload(thumbnailFilename, thumbnail, {
          contentType: 'image/jpeg',
          cacheControl: '3600',
          upsert: true
        });

      if (uploadError) {
        throw new Error(`Failed to upload thumbnail: ${uploadError.message}`);
      }

      console.log('Thumbnail generated successfully:', thumbnailFilename);

      // Update exercise_templates table with thumbnail URL if video_url matches
      const videoUrl = `https://${supabaseUrl.replace('https://', '')}/storage/v1/object/public/exercise-videos/${videoFilename}`;
      const thumbnailUrl = `https://${supabaseUrl.replace('https://', '')}/storage/v1/object/public/exercise-videos/${thumbnailFilename}`;

      await supabase
        .from('exercise_templates')
        .update({ video_thumbnail_url: thumbnailUrl })
        .eq('video_url', videoUrl);

      return new Response(
        JSON.stringify({
          success: true,
          message: 'Thumbnail generated successfully',
          thumbnail: thumbnailFilename,
          video: videoFilename
        }),
        { headers: { 'Content-Type': 'application/json' }, status: 200 }
      );

    } catch (error) {
      console.error('FFmpeg not available, falling back to placeholder');

      // Fallback: Create a simple placeholder or skip
      // In production, integrate with a video processing service
      return new Response(
        JSON.stringify({
          success: false,
          message: 'Thumbnail generation requires external video processing service',
          error: error.message,
          recommendation: 'Use Cloudinary, AWS MediaConvert, or similar service for production'
        }),
        { headers: { 'Content-Type': 'application/json' }, status: 500 }
      );
    }

  } catch (error) {
    console.error('Error generating thumbnail:', error);

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
        stack: error.stack
      }),
      { headers: { 'Content-Type': 'application/json' }, status: 500 }
    );
  }
});

/**
 * Extract filename for thumbnail from video filename
 * Example: 'bench-press.mp4' -> 'thumbnails/bench-press.jpg'
 */
function getThumbnailFilename(videoFilename: string): string {
  const baseName = videoFilename.replace(/\.[^.]+$/, ''); // Remove extension
  return `thumbnails/${baseName}.jpg`;
}

/**
 * Extract a single frame from video at specified timestamp
 * This is a placeholder function - in production, integrate with:
 * - FFmpeg WASM (https://ffmpegwasm.netlify.app/)
 * - Cloudinary (https://cloudinary.com/documentation/video_manipulation_and_delivery)
 * - AWS MediaConvert
 * - Google Cloud Video Intelligence API
 */
async function extractVideoFrame(
  videoBlob: Blob,
  timestampSeconds: number
): Promise<Blob> {
  // PRODUCTION IMPLEMENTATION OPTIONS:

  // Option 1: Use FFmpeg WASM (requires ~30MB WASM file)
  // const ffmpeg = createFFmpeg({ log: true });
  // await ffmpeg.load();
  // ffmpeg.FS('writeFile', 'input.mp4', await fetchFile(videoBlob));
  // await ffmpeg.run('-i', 'input.mp4', '-ss', `${timestampSeconds}`, '-vframes', '1', '-vf', `scale=${THUMBNAIL_WIDTH}:${THUMBNAIL_HEIGHT}`, 'output.jpg');
  // const data = ffmpeg.FS('readFile', 'output.jpg');
  // return new Blob([data.buffer], { type: 'image/jpeg' });

  // Option 2: Call external API (Cloudinary example)
  // const formData = new FormData();
  // formData.append('file', videoBlob);
  // formData.append('upload_preset', 'your_preset');
  // const response = await fetch('https://api.cloudinary.com/v1_1/your_cloud/video/upload', {
  //   method: 'POST',
  //   body: formData
  // });
  // const result = await response.json();
  // const thumbnailUrl = result.secure_url.replace('.mp4', '.jpg').replace('/upload/', `/upload/w_${THUMBNAIL_WIDTH},h_${THUMBNAIL_HEIGHT},c_fill/`);
  // const thumbnailResponse = await fetch(thumbnailUrl);
  // return await thumbnailResponse.blob();

  // Option 3: Use AWS MediaConvert or Lambda
  // (Implement AWS SDK call here)

  // PLACEHOLDER: Return empty blob (replace with actual implementation)
  throw new Error('Video frame extraction not implemented - integrate with video processing service');
}

/* ============================================================================
   DEPLOYMENT INSTRUCTIONS
   ============================================================================

   1. Deploy this Edge Function:
      ```bash
      supabase functions deploy generate-video-thumbnail
      ```

   2. Create database webhook to trigger function on video upload:
      ```sql
      CREATE OR REPLACE FUNCTION trigger_thumbnail_generation()
      RETURNS TRIGGER AS $$
      DECLARE
        function_url TEXT := 'https://rpbxeaxlaoyoqkohytlw.supabase.co/functions/v1/generate-video-thumbnail';
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
            'record', row_to_json(NEW),
            'old_record', row_to_json(OLD)
          )
        );
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER on_video_upload
      AFTER INSERT ON storage.objects
      FOR EACH ROW
      WHEN (NEW.bucket_id = 'exercise-videos')
      EXECUTE FUNCTION trigger_thumbnail_generation();
      ```

   3. Alternative: Set up Storage webhook in Supabase Dashboard
      - Go to Database > Webhooks
      - Create new webhook
      - Type: storage.objects INSERT
      - Filter: bucket_id = 'exercise-videos'
      - Function URL: https://your-project.supabase.co/functions/v1/generate-video-thumbnail

   ============================================================================
   TESTING
   ============================================================================

   Test the function locally:
   ```bash
   supabase functions serve generate-video-thumbnail
   ```

   Send test request:
   ```bash
   curl -X POST http://localhost:54321/functions/v1/generate-video-thumbnail \
     -H "Content-Type: application/json" \
     -d '{
       "type": "INSERT",
       "table": "objects",
       "record": {
         "id": "test-id",
         "name": "bench-press.mp4",
         "bucket_id": "exercise-videos",
         "metadata": {}
       }
     }'
   ```

   ============================================================================
   PRODUCTION RECOMMENDATIONS
   ============================================================================

   For production deployment, integrate with a proper video processing service:

   1. **Cloudinary** (Recommended - easiest)
      - Upload videos to Cloudinary instead of Supabase Storage
      - Cloudinary auto-generates thumbnails
      - Use transformation URLs for different sizes
      - Cost: Free tier available, then pay-as-you-go

   2. **AWS MediaConvert**
      - Professional-grade video processing
      - Create thumbnail extraction jobs
      - Store in S3, reference from Supabase
      - Cost: ~$0.015/minute of video

   3. **Google Cloud Video Intelligence**
      - ML-powered thumbnail selection (picks best frame)
      - Integrate with Cloud Functions
      - Cost: $0.10 per 1000 minutes

   4. **FFmpeg WASM in Edge Function**
      - Fully self-contained solution
      - Adds ~30MB to function size
      - Slower than external services
      - Free (hosting costs only)

   ============================================================================
*/
