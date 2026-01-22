#!/bin/bash

# Script to build and run Triply on physical device

set -e

echo "📱 Building Triply for Physical Device..."
echo ""

# Get device UDID
DEVICE_UDID=$(xcrun xctrace list devices 2>&1 | grep "iPhone" | grep -v "Simulator" | head -1 | grep -oE "[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}" | head -1)

if [ -z "$DEVICE_UDID" ]; then
    echo "❌ No iPhone device found. Please connect your iPhone via USB."
    exit 1
fi

echo "✅ Found device: $DEVICE_UDID"
echo ""

# Open in Xcode for signing configuration
echo "📝 Opening Xcode for signing configuration..."
echo "   1. Select your Team in Signing & Capabilities"
echo "   2. Xcode will automatically manage signing"
echo "   3. Press Cmd+R to build and run"
echo ""

open Triply.xcodeproj

echo ""
echo "💡 Alternative: Build from command line after configuring signing:"
echo "   xcodebuild -project Triply.xcodeproj \\"
echo "     -scheme Triply \\"
echo "     -destination 'id=$DEVICE_UDID' \\"
echo "     build"
echo ""



