#!/bin/bash
# Check TestFlight Build Status

echo "=================================================="
echo "🔍 Checking TestFlight Build Status"
echo "=================================================="
echo ""

# Check local build artifacts
echo "Local Build Info:"
echo "---"
agvtool what-version 2>/dev/null || echo "Cannot get version"
echo ""

# Check IPA file
if [ -f "PTPerformance.ipa" ]; then
    echo "✅ IPA file exists"
    ls -lh PTPerformance.ipa | awk '{print "   Size: " $5}'

    # Extract and check Info.plist from IPA
    echo ""
    echo "IPA Contents:"
    unzip -l PTPerformance.ipa | grep "Info.plist" | head -3
else
    echo "❌ No IPA file found"
fi

echo ""
echo "=================================================="
echo "App Store Connect Links:"
echo "=================================================="
echo ""
echo "📱 TestFlight Builds:"
echo "   https://appstoreconnect.apple.com/apps/6756226704/testflight/ios"
echo ""
echo "📊 App Information:"
echo "   https://appstoreconnect.apple.com/apps/6756226704/appstore"
echo ""
echo "📧 Check email (paul@romatech.com) for:"
echo "   - Build processing notifications"
echo "   - Validation errors"
echo "   - Export compliance issues"
echo ""
echo "=================================================="
echo "Next Steps:"
echo "=================================================="
echo ""
echo "1. Check App Store Connect web interface"
echo "2. Look for Build 2 in TestFlight tab"
echo "3. Check for any error emails from Apple"
echo "4. If Build 2 is missing, it may have been rejected"
echo ""
echo "Common Issues:"
echo "  - Export compliance not answered"
echo "  - Missing privacy descriptions"
echo "  - Binary validation errors"
echo ""
