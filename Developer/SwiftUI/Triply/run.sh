#!/bin/bash

# Script to build and run the Triply app from command line
# This allows you to work in Cursor and run the app without opening Xcode

set -e

PROJECT_NAME="Triply"
SCHEME="Triply"
SIMULATOR="iPhone 15"

echo "🚀 Building and running Triply app..."
echo ""

# Check if project exists
if [ ! -d "$PROJECT_NAME.xcodeproj" ]; then
    echo "❌ Xcode project not found!"
    echo "   Run: ./create_project.sh"
    exit 1
fi

# Get available simulators
echo "📱 Checking available simulators..."
AVAILABLE_SIM=$(xcrun simctl list devices available | grep "$SIMULATOR" | head -1)

if [ -z "$AVAILABLE_SIM" ]; then
    echo "⚠️  '$SIMULATOR' not found. Available iPhones:"
    xcrun simctl list devices available | grep "iPhone" | head -5
    echo ""
    echo "   Edit run.sh and change SIMULATOR variable, or use:"
    FIRST_IPHONE=$(xcrun simctl list devices available | grep "iPhone" | head -1 | sed 's/.*(\(.*\))/\1/' | tr -d ' ')
    SIMULATOR_UDID="$FIRST_IPHONE"
    echo "   Using first available iPhone..."
else
    SIMULATOR_UDID=$(echo "$AVAILABLE_SIM" | grep -oE '\([A-F0-9-]+\)' | tr -d '()')
fi

# Boot simulator
echo "📱 Booting simulator..."
xcrun simctl boot "$SIMULATOR_UDID" 2>/dev/null || true
open -a Simulator
sleep 2

# Build the project
echo "🔨 Building project..."
xcodebuild \
    -project "$PROJECT_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,id=$SIMULATOR_UDID" \
    -derivedDataPath ./DerivedData \
    build \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO 2>&1 | grep -E "(error:|warning:|BUILD SUCCEEDED|BUILD FAILED)" | tail -10

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo ""
echo "✅ Build successful!"
echo ""

# Find the built app
APP_PATH=$(find ./DerivedData -name "*.app" -type d | grep -v "Test" | head -1)

if [ -z "$APP_PATH" ]; then
    # Try default derived data location
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "Triply*.app" -type d 2>/dev/null | head -1)
fi

if [ -n "$APP_PATH" ]; then
    echo "📦 Installing app..."
    xcrun simctl install "$SIMULATOR_UDID" "$APP_PATH"
    
    BUNDLE_ID="com.triply.app"
    
    echo "🎉 Launching app..."
    xcrun simctl launch "$SIMULATOR_UDID" "$BUNDLE_ID"
    
    echo ""
    echo "✅ App launched! Check the Simulator window."
    echo ""
    echo "💡 The app is now running. Keep this terminal open."
    echo "   To stop: Close Simulator or press Ctrl+C"
else
    echo "❌ Could not find built app."
    echo ""
    echo "💡 Try building once in Xcode first:"
    echo "   ./open_in_xcode.sh"
    echo "   Then build (⌘B) and run (⌘R) once"
    echo "   After that, this script should work!"
    exit 1
fi
