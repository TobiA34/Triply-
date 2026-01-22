#!/bin/bash

# Script to ensure simulator opens and app runs

set -e

PROJECT="Triply.xcodeproj"
SCHEME="Triply"
BUNDLE_ID="com.triply.app"

echo "📱 Opening iPhone Simulator..."
echo ""

# Get booted simulator or boot one
BOOTED_SIM=$(xcrun simctl list devices booted | grep "iPhone" | head -1 | grep -oE "[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}")

if [ -z "$BOOTED_SIM" ]; then
    echo "📱 No simulator booted. Booting iPhone 15 Pro..."
    xcrun simctl boot "iPhone 15 Pro" 2>/dev/null || xcrun simctl boot "iPhone 15" 2>/dev/null || true
    sleep 2
    BOOTED_SIM=$(xcrun simctl list devices booted | grep "iPhone" | head -1 | grep -oE "[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}")
fi

# Open Simulator app (brings window to front)
echo "🪟 Opening Simulator window..."
open -a Simulator

# Wait for Simulator to be ready
sleep 3

# Build and run using xcodebuild
echo "🔨 Building and running app..."
xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,id=$BOOTED_SIM" \
    build \
    -derivedDataPath ./DerivedData 2>&1 | grep -E "(error:|warning:|BUILD SUCCEEDED|BUILD FAILED)" | tail -5

BUILD_RESULT=$?

if [ $BUILD_RESULT -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo ""
    
    # Find the app
    APP_PATH=$(find ./DerivedData -name "Triply.app" -type d | head -1)
    
    if [ -n "$APP_PATH" ]; then
        echo "📲 Installing app on simulator..."
        xcrun simctl install booted "$APP_PATH" 2>/dev/null || true
        
        echo "🚀 Launching app..."
        xcrun simctl launch booted "$BUNDLE_ID" 2>/dev/null || true
        
        echo ""
        echo "✅ App should now be visible in Simulator!"
        echo "   If not, check the Simulator window - it may be behind other windows."
    else
        echo "⚠️  App bundle not found. Try running from Xcode instead."
    fi
else
    echo ""
    echo "❌ Build failed. Check errors above."
    exit 1
fi

echo ""
echo "💡 If simulator window is not visible:"
echo "   1. Check Dock for Simulator icon"
echo "   2. Press Cmd+Tab to switch to Simulator"
echo "   3. Or run: open -a Simulator"







