#!/bin/bash

# Quick build script for Triply app
# Use this to just build without running

set -e

PROJECT_NAME="Triply"
SCHEME="Triply"
SIMULATOR="iPhone 15"

echo "🔨 Building Triply app..."

xcodebuild \
    -project "$PROJECT_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,name=$SIMULATOR" \
    clean build

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo "   Run './run.sh' to launch the app"
else
    echo ""
    echo "❌ Build failed!"
    exit 1
fi



