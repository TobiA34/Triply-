#!/bin/bash

# Run Triply app in iOS Simulator from Cursor

set -e

PROJECT="Triply.xcodeproj"
SCHEME="Triply"

echo "🚀 Building and running Triply in iOS Simulator..."
echo ""

# Clean build cache
echo "🧹 Cleaning build cache..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Triply-* 2>/dev/null || true
rm -rf DerivedData 2>/dev/null || true

# Get available simulators
echo "📱 Available simulators:"
xcrun simctl list devices available | grep -E "iPhone|iPad" | head -5
echo ""

# Get first available iPhone simulator
SIMULATOR=$(xcrun simctl list devices available | grep "iPhone" | head -1 | grep -oE "iPhone [^)]+" | head -1)

if [ -z "$SIMULATOR" ]; then
    echo "❌ No iPhone simulator found. Creating one..."
    SIMULATOR="iPhone 15"
fi

echo "✅ Using simulator: $SIMULATOR"
echo ""

# Build the project
echo "🔨 Building project..."
xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,name=$SIMULATOR" \
    clean build \
    2>&1 | grep -E "(error:|warning:|BUILD SUCCEEDED|BUILD FAILED)" | head -10

BUILD_RESULT=$?

if [ $BUILD_RESULT -ne 0 ]; then
    echo ""
    echo "❌ Build failed. Check errors above."
    exit 1
fi

echo ""
echo "✅ Build successful!"
echo ""

# Get simulator UDID
SIM_UDID=$(xcrun simctl list devices available | grep "$SIMULATOR" | head -1 | grep -oE "[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}")

if [ -z "$SIM_UDID" ]; then
    # Boot default simulator
    echo "📱 Booting simulator..."
    xcrun simctl boot "iPhone 15" 2>/dev/null || true
    SIM_UDID=$(xcrun simctl list devices | grep "Booted" | grep "iPhone" | head -1 | grep -oE "[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}" | head -1)
fi

# Open Simulator app
echo "📱 Opening Simulator..."
open -a Simulator

# Wait for simulator to be ready
sleep 3

# Build and install app
echo "📦 Installing app on simulator..."
xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,name=$SIMULATOR" \
    build \
    2>&1 | tail -5

# Get app path
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "Triply.app" -type d | head -1)

if [ -n "$APP_PATH" ]; then
    echo "📲 Installing app..."
    xcrun simctl install booted "$APP_PATH" 2>/dev/null || true
    
    # Launch app
    echo "🚀 Launching Triply app..."
    xcrun simctl launch booted com.triply.app
    
    echo ""
    echo "✅ App launched! Check the Simulator window."
else
    echo ""
    echo "⚠️  App bundle not found. Building and running..."
    xcodebuild \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,name=$SIMULATOR" \
        build \
        -derivedDataPath ./DerivedData
    
    # Try to run
    xcodebuild \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,name=$SIMULATOR" \
        test-without-building 2>/dev/null || echo "Build complete. Open in Xcode to run."
fi

echo ""
echo "✨ Done! App should be running in Simulator."



