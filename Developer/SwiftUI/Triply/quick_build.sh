#!/bin/bash

# Quick build script that handles database locks

set -e

PROJECT_NAME="Triply"
SCHEME="Triply"

echo "🔨 Building $PROJECT_NAME..."

# Kill any stuck processes
pkill -9 xcodebuild 2>/dev/null || true
sleep 1

# Clean only if needed
if [ "$1" == "clean" ]; then
    echo "🧹 Cleaning build..."
    rm -rf ~/Library/Developer/Xcode/DerivedData/Triply-* 2>/dev/null || true
    xcodebuild clean -project "$PROJECT_NAME.xcodeproj" -scheme "$SCHEME" 2>/dev/null || true
fi

# Build
echo "📦 Building..."
xcodebuild \
    -project "$PROJECT_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -destination 'generic/platform=iOS Simulator' \
    build \
    2>&1 | grep -E "(error:|warning:|BUILD SUCCEEDED|BUILD FAILED)" | head -10

echo ""
echo "✅ Build complete!"



