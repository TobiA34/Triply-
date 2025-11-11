#!/bin/bash

# Run Triply on Physical iPhone 14 Pro

set -e

PROJECT="Triply.xcodeproj"
SCHEME="Triply"

echo "📱 Building for iPhone 14 Pro..."
echo ""

# Find connected iPhone
DEVICE=$(xcrun xctrace list devices 2>&1 | grep -i "iphone" | grep -v "Simulator" | head -1)

if [ -z "$DEVICE" ]; then
    echo "❌ No iPhone found. Please:"
    echo "   1. Connect your iPhone 14 Pro via USB"
    echo "   2. Unlock your iPhone"
    echo "   3. Trust this computer when prompted"
    exit 1
fi

echo "✅ Found device: $DEVICE"
echo ""

# Extract device UDID
DEVICE_UDID=$(echo "$DEVICE" | grep -oE "[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}")

if [ -z "$DEVICE_UDID" ]; then
    echo "❌ Could not extract device UDID"
    exit 1
fi

echo "📱 Device UDID: $DEVICE_UDID"
echo ""
echo "⚠️  IMPORTANT: You need to configure code signing in Xcode first!"
echo ""
echo "📝 Steps:"
echo "   1. Open project: open Triply.xcodeproj"
echo "   2. Click 'Triply' project → 'Triply' target"
echo "   3. Go to 'Signing & Capabilities' tab"
echo "   4. Check 'Automatically manage signing'"
echo "   5. Select your Team (Apple ID)"
echo "   6. Then run this script again"
echo ""
echo "Or build from Xcode:"
echo "   - Select your iPhone in device selector"
echo "   - Press Cmd+R to build and run"
echo ""

# Try to build (will fail without signing, but shows what's needed)
echo "🔨 Attempting build..."
xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "id=$DEVICE_UDID" \
    build \
    2>&1 | grep -E "(error:|warning:|BUILD SUCCEEDED|requires a development team)" | head -5

echo ""
echo "💡 If you see 'requires a development team', configure signing in Xcode first."



