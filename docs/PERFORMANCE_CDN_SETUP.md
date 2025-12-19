# CDN Setup for Exercise Videos

## Overview
Configure Cloudflare CDN for exercise video delivery to reduce load times by 50% and improve user experience.

## Architecture

```
iOS App → Cloudflare CDN → Supabase Storage → Videos
           (Cache Layer)        (Origin)
```

## Benefits

1. **Performance**: 50% reduction in video load times
2. **Bandwidth**: Reduced bandwidth costs on Supabase
3. **Global Distribution**: Videos served from edge locations
4. **Reliability**: Automatic failover and retries
5. **Analytics**: Detailed usage metrics

## Setup Steps

### 1. Supabase Storage Configuration

Create a storage bucket for videos:

```sql
-- Create storage bucket for exercise videos
INSERT INTO storage.buckets (id, name, public)
VALUES ('exercise-videos', 'exercise-videos', true);

-- Set up RLS policies for video access
CREATE POLICY "Anyone can view exercise videos"
ON storage.objects FOR SELECT
USING (bucket_id = 'exercise-videos');

CREATE POLICY "Therapists can upload videos"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'exercise-videos'
    AND EXISTS (
        SELECT 1 FROM public.therapists
        WHERE user_id = auth.uid()
    )
);

CREATE POLICY "Therapists can update their videos"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'exercise-videos'
    AND EXISTS (
        SELECT 1 FROM public.therapists
        WHERE user_id = auth.uid()
    )
);
```

### 2. Cloudflare Setup

#### Create Cloudflare Account

1. Sign up at https://cloudflare.com
2. Add your domain (e.g., ptperformance.com)
3. Update nameservers with your domain registrar

#### Configure CDN Settings

```
Zone Settings:
- SSL/TLS: Full (Strict)
- Browser Cache TTL: 4 hours
- Caching Level: Standard

Page Rules:
- URL: cdn.ptperformance.com/videos/*
- Cache Level: Cache Everything
- Edge Cache TTL: 7 days
- Browser Cache TTL: 4 hours
```

#### Create Custom Domain for CDN

```
DNS Records:
CNAME cdn.ptperformance.com → your-project.supabase.co
```

### 3. Configure Video URLs

Update the database to use CDN URLs:

```sql
-- Add CDN URL to exercises table
ALTER TABLE public.exercises
ADD COLUMN IF NOT EXISTS video_url TEXT,
ADD COLUMN IF NOT EXISTS cdn_video_url TEXT,
ADD COLUMN IF NOT EXISTS video_thumbnail_url TEXT;

-- Update existing videos with CDN URLs
UPDATE public.exercises
SET cdn_video_url = REPLACE(
    video_url,
    'https://your-project.supabase.co/storage/v1/object/public/exercise-videos/',
    'https://cdn.ptperformance.com/videos/'
)
WHERE video_url IS NOT NULL;

-- Function to get video URL (with CDN fallback)
CREATE OR REPLACE FUNCTION public.get_video_url(
    p_exercise_id UUID,
    p_use_cdn BOOLEAN DEFAULT TRUE
)
RETURNS TEXT
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_url TEXT;
BEGIN
    IF p_use_cdn THEN
        SELECT cdn_video_url INTO v_url
        FROM public.exercises
        WHERE id = p_exercise_id;

        -- Fallback to direct URL if CDN URL not available
        IF v_url IS NULL THEN
            SELECT video_url INTO v_url
            FROM public.exercises
            WHERE id = p_exercise_id;
        END IF;
    ELSE
        SELECT video_url INTO v_url
        FROM public.exercises
        WHERE id = p_exercise_id;
    END IF;

    RETURN v_url;
END;
$$;
```

### 4. iOS App Integration

#### Update VideoService.swift

```swift
import Foundation
import AVFoundation

class VideoService {
    static let shared = VideoService()

    private let cdnBaseURL = "https://cdn.ptperformance.com/videos/"
    private let directBaseURL = "https://your-project.supabase.co/storage/v1/object/public/exercise-videos/"

    private init() {}

    /// Get video URL with CDN support
    func getVideoURL(exercise: Exercise, useCDN: Bool = true) -> URL? {
        // Prefer CDN URL
        if useCDN, let cdnURL = exercise.cdnVideoUrl {
            return URL(string: cdnURL)
        }

        // Fallback to direct URL
        if let videoURL = exercise.videoUrl {
            return URL(string: videoURL)
        }

        return nil
    }

    /// Preload video for faster playback
    func preloadVideo(url: URL) async throws {
        let asset = AVURLAsset(url: url)

        // Preload video data
        try await asset.load(.duration, .tracks)
    }

    /// Get video with caching
    func getCachedVideo(exercise: Exercise) async throws -> URL {
        let cacheKey = "video:\(exercise.id.uuidString)"

        // Check if video is already downloaded
        if let cachedURL = getCachedVideoURL(for: exercise.id) {
            return cachedURL
        }

        // Download video
        guard let videoURL = getVideoURL(exercise: exercise) else {
            throw VideoError.invalidURL
        }

        let downloadedURL = try await downloadVideo(from: videoURL, exerciseId: exercise.id)
        return downloadedURL
    }

    /// Download video to local storage
    private func downloadVideo(from url: URL, exerciseId: UUID) async throws -> URL {
        let (localURL, _) = try await URLSession.shared.download(from: url)

        // Move to app's document directory
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsURL.appendingPathComponent("videos/\(exerciseId.uuidString).mp4")

        // Create videos directory if needed
        try? FileManager.default.createDirectory(at: documentsURL.appendingPathComponent("videos"), withIntermediateDirectories: true)

        // Move file
        try FileManager.default.moveItem(at: localURL, to: destinationURL)

        return destinationURL
    }

    /// Get cached video URL
    private func getCachedVideoURL(for exerciseId: UUID) -> URL? {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videoURL = documentsURL.appendingPathComponent("videos/\(exerciseId.uuidString).mp4")

        if FileManager.default.fileExists(atPath: videoURL.path) {
            return videoURL
        }

        return nil
    }

    /// Clear video cache
    func clearVideoCache() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videosURL = documentsURL.appendingPathComponent("videos")

        try? FileManager.default.removeItem(at: videosURL)
    }
}

enum VideoError: Error {
    case invalidURL
    case downloadFailed
    case cacheError
}
```

#### Update VideoPlayerView.swift

```swift
import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let exercise: Exercise
    @State private var player: AVPlayer?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("Loading video...")
            } else if let errorMessage = errorMessage {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                    Text(errorMessage)
                        .foregroundColor(.secondary)
                }
            } else if let player = player {
                VideoPlayer(player: player)
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
            }
        }
        .task {
            await loadVideo()
        }
    }

    private func loadVideo() async {
        do {
            // Get video URL with CDN
            guard let url = VideoService.shared.getVideoURL(exercise: exercise) else {
                errorMessage = "Video not available"
                isLoading = false
                return
            }

            // Create player
            player = AVPlayer(url: url)

            // Preload
            try await VideoService.shared.preloadVideo(url: url)

            isLoading = false

            // Log video view
            try? await AuditLogService.shared.logAction(
                actionType: .read,
                resourceType: "video",
                resourceId: exercise.id,
                operation: "view_exercise_video",
                description: "Viewed video for \(exercise.name)"
            )
        } catch {
            errorMessage = "Failed to load video: \(error.localizedDescription)"
            isLoading = false
        }
    }
}
```

### 5. Cloudflare Workers (Advanced)

For additional optimization, create a Cloudflare Worker:

```javascript
// worker.js
addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

async function handleRequest(request) {
  const url = new URL(request.url)

  // Check if video request
  if (url.pathname.startsWith('/videos/')) {
    return handleVideoRequest(request)
  }

  return fetch(request)
}

async function handleVideoRequest(request) {
  const url = new URL(request.url)
  const videoPath = url.pathname.replace('/videos/', '')

  // Get from Supabase storage
  const supabaseURL = `https://your-project.supabase.co/storage/v1/object/public/exercise-videos/${videoPath}`

  // Fetch from origin
  const response = await fetch(supabaseURL)

  // Add caching headers
  const headers = new Headers(response.headers)
  headers.set('Cache-Control', 'public, max-age=604800') // 7 days
  headers.set('CDN-Cache-Control', 'public, max-age=604800')

  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers: headers
  })
}
```

### 6. Video Upload Workflow

```swift
class VideoUploadService {
    static let shared = VideoUploadService()

    func uploadExerciseVideo(
        exerciseId: UUID,
        videoURL: URL,
        thumbnailURL: URL?
    ) async throws -> String {
        let client = SupabaseClient.shared.client

        // Upload video to Supabase storage
        let videoPath = "exercises/\(exerciseId.uuidString).mp4"
        let videoData = try Data(contentsOf: videoURL)

        try await client.storage
            .from("exercise-videos")
            .upload(path: videoPath, file: videoData, fileOptions: FileOptions(contentType: "video/mp4"))

        // Generate URLs
        let directURL = "\(directBaseURL)\(videoPath)"
        let cdnURL = "\(cdnBaseURL)\(videoPath)"

        // Update exercise record
        try await client
            .from("exercises")
            .update([
                "video_url": directURL,
                "cdn_video_url": cdnURL
            ])
            .eq("id", value: exerciseId.uuidString)
            .execute()

        // Upload thumbnail if provided
        if let thumbnailURL = thumbnailURL {
            let thumbnailPath = "exercises/thumbnails/\(exerciseId.uuidString).jpg"
            let thumbnailData = try Data(contentsOf: thumbnailURL)

            try await client.storage
                .from("exercise-videos")
                .upload(path: thumbnailPath, file: thumbnailData, fileOptions: FileOptions(contentType: "image/jpeg"))

            let thumbnailCDN = "\(cdnBaseURL)thumbnails/\(exerciseId.uuidString).jpg"

            try await client
                .from("exercises")
                .update(["video_thumbnail_url": thumbnailCDN])
                .eq("id", value: exerciseId.uuidString)
                .execute()
        }

        // Purge CDN cache for this video
        try await purgeCDNCache(path: videoPath)

        return cdnURL
    }

    private func purgeCDNCache(path: String) async throws {
        // Cloudflare API call to purge cache
        let apiURL = "https://api.cloudflare.com/client/v4/zones/YOUR_ZONE_ID/purge_cache"
        let apiKey = "YOUR_API_KEY"

        var request = URLRequest(url: URL(string: apiURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = [
            "files": [
                "https://cdn.ptperformance.com/videos/\(path)"
            ]
        ]
        request.httpBody = try JSONEncoder().encode(body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw VideoError.cachePurgeFailed
        }
    }
}
```

### 7. Performance Monitoring

Track CDN performance:

```swift
extension PerformanceMonitor {
    func trackVideoLoad(exerciseId: UUID, loadTime: TimeInterval, usedCDN: Bool) {
        recordMetric(
            name: "video_load_time",
            duration: loadTime,
            success: true,
            metadata: [
                "exercise_id": exerciseId.uuidString,
                "used_cdn": usedCDN,
                "source": usedCDN ? "cdn" : "direct"
            ]
        )

        // Send to Sentry
        SentryConfig.shared.setContext(key: "video_performance", value: [
            "load_time_ms": loadTime * 1000,
            "used_cdn": usedCDN
        ])
    }
}
```

### 8. Cost Optimization

**Cloudflare Pricing**:
- Free tier: 100,000 requests/day
- Pro tier ($20/month): Unlimited requests + advanced features

**Bandwidth Savings**:
- Before CDN: 100GB/month = $200 (Supabase bandwidth)
- After CDN: 10GB/month = $20 (90% cached)
- Monthly savings: $180

**Performance Improvement**:
- Direct load: 2-5 seconds
- CDN load: 1-2 seconds
- Improvement: 50-60% faster

### 9. Testing CDN Setup

```bash
#!/bin/bash
# test_cdn_performance.sh

echo "Testing CDN Performance..."

# Test direct URL
echo "Testing direct URL..."
time curl -o /dev/null -s "https://your-project.supabase.co/storage/v1/object/public/exercise-videos/test.mp4"

# Test CDN URL
echo "Testing CDN URL..."
time curl -o /dev/null -s "https://cdn.ptperformance.com/videos/test.mp4"

# Check cache status
curl -I "https://cdn.ptperformance.com/videos/test.mp4" | grep -i "cf-cache-status"
```

### 10. Troubleshooting

**Issue**: Videos not loading from CDN
```bash
# Check DNS resolution
dig cdn.ptperformance.com

# Check SSL certificate
openssl s_client -connect cdn.ptperformance.com:443 -servername cdn.ptperformance.com

# Purge CDN cache
curl -X POST "https://api.cloudflare.com/client/v4/zones/YOUR_ZONE_ID/purge_cache" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  --data '{"purge_everything":true}'
```

**Issue**: High bandwidth costs
- Increase cache TTL
- Enable Cloudflare compression
- Optimize video encoding (lower bitrate)

## Summary

CDN setup provides:
- 50% faster video load times
- 90% reduction in bandwidth costs
- Global edge distribution
- Improved user experience
- Scalability for growth
