#!/bin/bash
# Convert Lottie JSON animation to MP4 video
# Usage: ./convert-lottie.sh <input.json> <output.mp4> [width] [height] [fps]

set -e

INPUT_FILE="$1"
OUTPUT_FILE="$2"
WIDTH="${3:-1080}"
HEIGHT="${4:-1080}"
FPS="${5:-30}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check arguments
if [ -z "$INPUT_FILE" ] || [ -z "$OUTPUT_FILE" ]; then
    echo -e "${RED}Error: Missing arguments${NC}"
    echo "Usage: ./convert-lottie.sh <input.json> <output.mp4> [width] [height] [fps]"
    echo ""
    echo "Examples:"
    echo "  ./convert-lottie.sh bench-press.json bench-press.mp4"
    echo "  ./convert-lottie.sh bench-press.json bench-press.mp4 1080 1080 30"
    exit 1
fi

# Check input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo -e "${RED}Error: Input file not found: $INPUT_FILE${NC}"
    exit 1
fi

echo -e "${YELLOW}=== Lottie to MP4 Converter ===${NC}"
echo "Input: $INPUT_FILE"
echo "Output: $OUTPUT_FILE"
echo "Resolution: ${WIDTH}x${HEIGHT}"
echo "FPS: $FPS"
echo ""

# Check for puppeteer-lottie-cli (preferred method)
if command -v puppeteer-lottie &> /dev/null; then
    echo -e "${YELLOW}Using puppeteer-lottie...${NC}"
    puppeteer-lottie \
        --input "$INPUT_FILE" \
        --output "$OUTPUT_FILE" \
        --width "$WIDTH" \
        --height "$HEIGHT"

    echo -e "${GREEN}Conversion complete!${NC}"
    exit 0
fi

# Try lottie-to-video
if npx lottie-to-video --version &>/dev/null 2>&1; then
    echo -e "${YELLOW}Using lottie-to-video...${NC}"
    npx lottie-to-video "$INPUT_FILE" \
        -o "$OUTPUT_FILE" \
        --width "$WIDTH" \
        --height "$HEIGHT" \
        --fps "$FPS"

    echo -e "${GREEN}Conversion complete!${NC}"
    exit 0
fi

# Fallback: Use online converter info
echo -e "${YELLOW}No local converter found.${NC}"
echo ""
echo "Install a converter:"
echo "  npm install -g puppeteer-lottie-cli"
echo ""
echo "Or use online converters:"
echo "  - https://lottiefiles.com/lottie-to-mp4"
echo "  - https://www.kapwing.com/tools/convert/lottie-to-mp4"
echo ""
echo "Alternative: Use Remotion (React-based)"
echo "  npx create-video@latest"
echo "  # Then render Lottie using @remotion/lottie"

exit 1
