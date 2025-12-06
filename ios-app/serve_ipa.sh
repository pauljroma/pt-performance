#!/bin/bash

echo "📡 Serving IPA over HTTP (Tailscale)"
echo "===================================="

cd /Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance/build

if [ ! -f "PTPerformance.ipa" ]; then
    echo "❌ No IPA found. Run ./deploy_testflight.sh first"
    exit 1
fi

# Get Tailscale IP
TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || ifconfig | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}')

echo ""
echo "✅ Starting HTTP server..."
echo ""
echo "📱 On your iPad, open Safari and go to:"
echo ""
echo "   http://$TAILSCALE_IP:8080/PTPerformance.ipa"
echo ""
echo "   Or scan this QR code:"
echo ""
qrencode -t ANSIUTF8 "http://$TAILSCALE_IP:8080/PTPerformance.ipa" 2>/dev/null || echo "   (Install qrencode for QR: brew install qrencode)"
echo ""
echo "⚠️  Note: Direct IPA install from Safari requires enterprise cert"
echo "    Recommended: Use TestFlight instead, or upload to diawi.com"
echo ""
echo "Starting server on port 8080..."
echo "Press Ctrl+C to stop"
echo ""

python3 -m http.server 8080
