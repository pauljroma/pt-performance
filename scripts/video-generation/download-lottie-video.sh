#!/bin/bash
# Download and convert a Lottie animation for bench press
# This is a quick-start script to get your first video

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${YELLOW}=== Lottie Video Quick Start ===${NC}"
echo ""

# Check for required tools
check_tool() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}Missing: $1${NC}"
        return 1
    fi
    echo -e "${GREEN}Found: $1${NC}"
    return 0
}

echo "Checking required tools..."
MISSING=0
check_tool "npm" || MISSING=1
check_tool "npx" || MISSING=1

if [ $MISSING -eq 1 ]; then
    echo ""
    echo -e "${RED}Please install Node.js first: https://nodejs.org/${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Step 1: Download Lottie Animation${NC}"
echo ""
echo "Go to LottieFiles and download a bench press animation:"
echo "  1. Visit: https://lottiefiles.com/search?q=bench+press&category=animations"
echo "  2. Or search: https://lottiefiles.com/search?q=workout&category=animations"
echo "  3. Click on an animation you like"
echo "  4. Click 'Download' -> 'Lottie JSON'"
echo "  5. Save as 'bench-press.json' in this directory"
echo ""

# Check if file exists
if [ ! -f "bench-press.json" ]; then
    echo -e "${YELLOW}Waiting for bench-press.json...${NC}"
    echo "Press Enter after downloading the file, or Ctrl+C to cancel"
    read -r

    if [ ! -f "bench-press.json" ]; then
        echo -e "${RED}File not found: bench-press.json${NC}"
        echo ""
        echo "Alternative: Use a sample Lottie file"
        echo "Creating a placeholder animation..."

        # Create a simple placeholder Lottie (circle animation)
        cat > bench-press.json << 'EOF'
{"v":"5.7.4","fr":30,"ip":0,"op":60,"w":1080,"h":1080,"nm":"Placeholder","ddd":0,"assets":[],"layers":[{"ddd":0,"ind":1,"ty":4,"nm":"Circle","sr":1,"ks":{"o":{"a":0,"k":100},"r":{"a":0,"k":0},"p":{"a":1,"k":[{"i":{"x":0.4,"y":1},"o":{"x":0.6,"y":0},"t":0,"s":[540,540,0]},{"i":{"x":0.4,"y":1},"o":{"x":0.6,"y":0},"t":30,"s":[540,400,0]},{"t":60,"s":[540,540,0]}]},"a":{"a":0,"k":[0,0,0]},"s":{"a":0,"k":[100,100,100]}},"ao":0,"shapes":[{"ty":"el","s":{"a":0,"k":[200,200]},"p":{"a":0,"k":[0,0]},"nm":"Ellipse","mn":"ADBE Vector Shape - Ellipse"},{"ty":"st","c":{"a":0,"k":[0.2,0.4,0.8,1]},"o":{"a":0,"k":100},"w":{"a":0,"k":8},"lc":2,"lj":2,"nm":"Stroke"},{"ty":"fl","c":{"a":0,"k":[0.3,0.5,0.9,1]},"o":{"a":0,"k":100},"r":1,"nm":"Fill"}],"ip":0,"op":60,"st":0}],"markers":[]}
EOF
        echo -e "${GREEN}Created placeholder animation${NC}"
    fi
fi

echo ""
echo -e "${BLUE}Step 2: Convert to MP4${NC}"
echo ""

# Install converter if needed
if ! npx lottie-to-video --version &>/dev/null 2>&1; then
    echo "Installing lottie-to-video..."
    npm install -g lottie-to-video 2>/dev/null || true
fi

# Try conversion with lottie-to-video
echo "Converting Lottie to MP4..."
if npx lottie-to-video bench-press.json -o bench-press-animated.mp4 --width 1080 --height 1080 2>/dev/null; then
    echo -e "${GREEN}Conversion successful!${NC}"
else
    echo -e "${YELLOW}lottie-to-video failed, trying alternative...${NC}"

    # Alternative: Use puppeteer-lottie
    if ! command -v puppeteer-lottie &> /dev/null; then
        echo "Installing puppeteer-lottie-cli..."
        npm install -g puppeteer-lottie-cli 2>/dev/null || true
    fi

    if puppeteer-lottie --input bench-press.json --output bench-press-animated.mp4 2>/dev/null; then
        echo -e "${GREEN}Conversion successful!${NC}"
    else
        echo -e "${RED}Conversion failed.${NC}"
        echo ""
        echo "Use online converter instead:"
        echo "  1. Visit: https://lottiefiles.com/lottie-to-mp4"
        echo "  2. Upload bench-press.json"
        echo "  3. Download as MP4"
        echo "  4. Rename to bench-press-animated.mp4"
        exit 1
    fi
fi

# Verify output
if [ -f "bench-press-animated.mp4" ]; then
    FILESIZE=$(stat -f%z "bench-press-animated.mp4" 2>/dev/null || stat -c%s "bench-press-animated.mp4")
    FILESIZE_MB=$(echo "scale=2; $FILESIZE / 1048576" | bc)

    echo ""
    echo -e "${GREEN}=== Video Created ===${NC}"
    echo "File: bench-press-animated.mp4"
    echo "Size: ${FILESIZE_MB}MB"
    echo ""

    echo -e "${BLUE}Step 3: Upload to Supabase${NC}"
    echo ""
    echo "Run the upload script:"
    echo "  ./upload-video.sh bench-press-animated.mp4 'Barbell Bench Press'"
    echo ""
    echo -e "${GREEN}Done!${NC}"
else
    echo -e "${RED}Video file not created${NC}"
    exit 1
fi
