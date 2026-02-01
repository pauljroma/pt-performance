#!/bin/bash
# Generate AI exercise demonstration video using Runway Gen-3 Alpha Turbo
# Usage: ./generate-runway-video.sh <exercise-name> [output-file]

set -e

EXERCISE_NAME="$1"
OUTPUT_FILE="${2:-${EXERCISE_NAME// /-}-ai.mp4}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check API key
if [ -z "$RUNWAY_API_KEY" ]; then
    echo -e "${RED}Error: RUNWAY_API_KEY environment variable not set${NC}"
    echo ""
    echo "Get your API key from: https://runwayml.com/api"
    echo "Then run: export RUNWAY_API_KEY='your-key-here'"
    exit 1
fi

# Check exercise name
if [ -z "$EXERCISE_NAME" ]; then
    echo -e "${RED}Error: No exercise name specified${NC}"
    echo "Usage: ./generate-runway-video.sh <exercise-name> [output-file]"
    echo ""
    echo "Examples:"
    echo "  ./generate-runway-video.sh 'bench press'"
    echo "  ./generate-runway-video.sh 'squat' squat-demo.mp4"
    exit 1
fi

echo -e "${YELLOW}=== Runway Gen-3 Video Generator ===${NC}"
echo "Exercise: $EXERCISE_NAME"
echo "Output: $OUTPUT_FILE"
echo ""

# Build prompt
PROMPT="Professional fitness trainer demonstrating ${EXERCISE_NAME} exercise, white background studio lighting, side angle view showing proper form and technique, wearing athletic clothing, smooth controlled movement, educational demonstration style, gym setting"

echo -e "${BLUE}Prompt:${NC}"
echo "$PROMPT"
echo ""

# Generate video using Runway API
echo -e "${YELLOW}Generating video (this may take 1-2 minutes)...${NC}"

RESPONSE=$(curl -s -X POST "https://api.runwayml.com/v1/generations" \
    -H "Authorization: Bearer $RUNWAY_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
        \"model\": \"gen3a_turbo\",
        \"prompt\": \"$PROMPT\",
        \"duration\": 10,
        \"ratio\": \"1:1\"
    }")

# Check for errors
if echo "$RESPONSE" | grep -q "error"; then
    echo -e "${RED}Error from Runway API:${NC}"
    echo "$RESPONSE" | jq -r '.error // .'
    exit 1
fi

# Get generation ID
GENERATION_ID=$(echo "$RESPONSE" | jq -r '.id // empty')

if [ -z "$GENERATION_ID" ]; then
    echo -e "${RED}Failed to get generation ID${NC}"
    echo "$RESPONSE"
    exit 1
fi

echo "Generation ID: $GENERATION_ID"
echo ""

# Poll for completion
echo -e "${YELLOW}Waiting for video generation...${NC}"
MAX_ATTEMPTS=60
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    sleep 5
    ATTEMPT=$((ATTEMPT + 1))

    STATUS_RESPONSE=$(curl -s "https://api.runwayml.com/v1/generations/$GENERATION_ID" \
        -H "Authorization: Bearer $RUNWAY_API_KEY")

    STATUS=$(echo "$STATUS_RESPONSE" | jq -r '.status // empty')

    case "$STATUS" in
        "SUCCEEDED")
            VIDEO_URL=$(echo "$STATUS_RESPONSE" | jq -r '.output[0] // empty')
            if [ -n "$VIDEO_URL" ]; then
                echo -e "${GREEN}Generation complete!${NC}"
                echo ""

                # Download video
                echo -e "${YELLOW}Downloading video...${NC}"
                curl -s -o "raw-$OUTPUT_FILE" "$VIDEO_URL"

                # Add AI disclosure overlay
                echo -e "${YELLOW}Adding AI disclosure overlay...${NC}"
                ffmpeg -y -i "raw-$OUTPUT_FILE" \
                    -vf "drawtext=text='AI-Generated Demonstration':fontsize=20:fontcolor=gray@0.7:x=10:y=h-35:borderw=1:bordercolor=black@0.3" \
                    "$OUTPUT_FILE" 2>/dev/null

                # Cleanup
                rm -f "raw-$OUTPUT_FILE"

                echo -e "${GREEN}Video saved: $OUTPUT_FILE${NC}"
                echo ""
                echo "Cost: ~\$0.30 (10 second Gen-3 Turbo)"
                exit 0
            fi
            ;;
        "FAILED")
            echo -e "${RED}Generation failed${NC}"
            echo "$STATUS_RESPONSE" | jq -r '.error // .'
            exit 1
            ;;
        "PROCESSING"|"PENDING")
            echo "  Status: $STATUS (attempt $ATTEMPT/$MAX_ATTEMPTS)"
            ;;
        *)
            echo "  Unknown status: $STATUS"
            ;;
    esac
done

echo -e "${RED}Timeout waiting for generation${NC}"
exit 1
