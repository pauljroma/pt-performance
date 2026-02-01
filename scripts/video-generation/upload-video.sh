#!/bin/bash
# Upload exercise video to Supabase storage and update database
# Usage: ./upload-video.sh <video-file> [exercise-name]

set -e

VIDEO_FILE="$1"
EXERCISE_NAME="${2:-}"

# Configuration
SUPABASE_PROJECT_ID="rpbxeaxlaoyoqkohytlw"
SUPABASE_URL="https://${SUPABASE_PROJECT_ID}.supabase.co"
BUCKET_NAME="exercise-videos"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check arguments
if [ -z "$VIDEO_FILE" ]; then
    echo -e "${RED}Error: No video file specified${NC}"
    echo "Usage: ./upload-video.sh <video-file> [exercise-name]"
    echo ""
    echo "Examples:"
    echo "  ./upload-video.sh bench-press-animated.mp4"
    echo "  ./upload-video.sh bench-press-animated.mp4 'Barbell Bench Press'"
    exit 1
fi

# Check file exists
if [ ! -f "$VIDEO_FILE" ]; then
    echo -e "${RED}Error: File not found: $VIDEO_FILE${NC}"
    exit 1
fi

# Get file info
FILENAME=$(basename "$VIDEO_FILE")
FILESIZE=$(stat -f%z "$VIDEO_FILE" 2>/dev/null || stat -c%s "$VIDEO_FILE")
FILESIZE_MB=$(echo "scale=2; $FILESIZE / 1048576" | bc)

echo -e "${YELLOW}=== PT Performance Video Upload ===${NC}"
echo "File: $FILENAME"
echo "Size: ${FILESIZE_MB}MB"
echo ""

# Check file size (50MB limit)
MAX_SIZE=52428800
if [ "$FILESIZE" -gt "$MAX_SIZE" ]; then
    echo -e "${RED}Error: File exceeds 50MB limit${NC}"
    echo "Consider compressing with: ffmpeg -i $VIDEO_FILE -vcodec libx264 -crf 28 output.mp4"
    exit 1
fi

# Check file extension
EXT="${FILENAME##*.}"
EXT_LOWER=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')
if [ "$EXT_LOWER" != "mp4" ] && [ "$EXT_LOWER" != "mov" ]; then
    echo -e "${RED}Error: Only .mp4 and .mov files are supported${NC}"
    exit 1
fi

# Check for Supabase CLI
if ! command -v npx &> /dev/null; then
    echo -e "${RED}Error: npx not found. Install Node.js first.${NC}"
    exit 1
fi

# Upload to Supabase Storage
echo -e "${YELLOW}Uploading to Supabase Storage...${NC}"

# Navigate to project root (for supabase link)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

# Method 1: Try using curl with service role key (preferred for automation)
if [ -n "$SUPABASE_SERVICE_ROLE_KEY" ]; then
    echo "Using service role key for upload..."

    UPLOAD_RESPONSE=$(curl -s -X POST \
        "${SUPABASE_URL}/storage/v1/object/${BUCKET_NAME}/${FILENAME}" \
        -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" \
        -H "Content-Type: video/mp4" \
        --data-binary "@${SCRIPT_DIR}/${VIDEO_FILE}" 2>&1)

    if echo "$UPLOAD_RESPONSE" | grep -q '"Key"'; then
        echo -e "${GREEN}Upload successful!${NC}"
    else
        echo -e "${RED}Upload failed: ${UPLOAD_RESPONSE}${NC}"
        exit 1
    fi
# Method 2: Try Supabase CLI
elif command -v supabase &> /dev/null || npx supabase --version &>/dev/null 2>&1; then
    echo "Using Supabase CLI..."

    # Check if linked to project
    if ! npx supabase projects list &>/dev/null 2>&1; then
        echo -e "${YELLOW}Not logged in. Attempting login...${NC}"
        echo "Please log in to Supabase CLI:"
        echo "  npx supabase login"
        echo ""
        echo "Or set SUPABASE_SERVICE_ROLE_KEY environment variable for automated uploads."
        exit 1
    fi

    # Upload using CLI (ss:// prefix for storage)
    npx supabase storage cp "${SCRIPT_DIR}/${VIDEO_FILE}" "ss:///${BUCKET_NAME}/${FILENAME}" --linked

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Upload successful!${NC}"
    else
        echo -e "${RED}Upload failed${NC}"
        exit 1
    fi
else
    # Method 3: Manual instructions
    echo -e "${YELLOW}No upload method available.${NC}"
    echo ""
    echo "Option 1: Set SUPABASE_SERVICE_ROLE_KEY and re-run"
    echo "  export SUPABASE_SERVICE_ROLE_KEY='your-service-role-key'"
    echo ""
    echo "Option 2: Install and configure Supabase CLI"
    echo "  npm install -g supabase"
    echo "  supabase login"
    echo ""
    echo "Option 3: Upload manually via Supabase Dashboard"
    echo "  1. Go to: https://supabase.com/dashboard/project/${SUPABASE_PROJECT_ID}/storage/buckets/exercise-videos"
    echo "  2. Click 'Upload file'"
    echo "  3. Select: ${VIDEO_FILE}"
    echo ""
    exit 1
fi

# Generate public URL
PUBLIC_URL="${SUPABASE_URL}/storage/v1/object/public/${BUCKET_NAME}/${FILENAME}"
echo ""
echo -e "${GREEN}Public URL:${NC}"
echo "$PUBLIC_URL"

# Get video duration using ffprobe if available
DURATION=""
if command -v ffprobe &> /dev/null; then
    DURATION=$(ffprobe -v quiet -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$VIDEO_FILE" 2>/dev/null | cut -d. -f1)
    if [ -n "$DURATION" ]; then
        echo "Duration: ${DURATION}s"
    fi
fi

# Generate SQL update command
echo ""
echo -e "${YELLOW}=== Update Database ===${NC}"
echo ""
echo "Run this SQL to link video to exercise:"
echo ""
echo -e "${GREEN}-- Option 1: Update by exercise name (recommended)${NC}"
if [ -n "$EXERCISE_NAME" ]; then
    echo "UPDATE exercise_templates"
    echo "SET"
    echo "  video_url = '${PUBLIC_URL}',"
    if [ -n "$DURATION" ]; then
        echo "  video_duration = ${DURATION},"
    fi
    echo "  video_file_size = ${FILESIZE}"
    echo "WHERE name ILIKE '%${EXERCISE_NAME}%';"
else
    echo "UPDATE exercise_templates"
    echo "SET"
    echo "  video_url = '${PUBLIC_URL}',"
    if [ -n "$DURATION" ]; then
        echo "  video_duration = ${DURATION},"
    fi
    echo "  video_file_size = ${FILESIZE}"
    echo "WHERE name ILIKE '%bench%press%';  -- Adjust pattern to match your exercise"
fi

echo ""
echo -e "${GREEN}-- Option 2: Update by exercise ID${NC}"
echo "UPDATE exercise_templates"
echo "SET"
echo "  video_url = '${PUBLIC_URL}',"
if [ -n "$DURATION" ]; then
    echo "  video_duration = ${DURATION},"
fi
echo "  video_file_size = ${FILESIZE}"
echo "WHERE id = 'YOUR_EXERCISE_ID';"

echo ""
echo -e "${YELLOW}=== Verification ===${NC}"
echo "1. Open PT Performance iOS app"
echo "2. Navigate to the exercise"
echo "3. Tap to view technique video"
echo "4. Confirm playback works correctly"
echo ""
echo -e "${GREEN}Done!${NC}"
