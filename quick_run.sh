#!/bin/bash

# Quick run script - just builds and runs once
# Useful for manual runs or CI/CD

set -e

PROJECT_PATH="/Users/tobiadegoroye/Developer/SwiftUI/Triply"
SCHEME="Triply"
BUNDLE_ID="com.triply.app"
SIMULATOR_UDID="11F27E2E-5199-43B7-9C11-E9159F59B324"
SDK="iphonesimulator"
DERIVED_DATA="./DerivedData"

cd "$PROJECT_PATH"

echo "📦 Building..."
xcodebuild -project "Triply.xcodeproj" \
    -scheme "$SCHEME" \
    -sdk "$SDK" \
    -derivedDataPath "$DERIVED_DATA" \
    build \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO

echo "📱 Installing..."
xcrun simctl install "$SIMULATOR_UDID" \
    "$DERIVED_DATA/Build/Products/Debug-iphonesimulator/Triply.app"

echo "🚀 Launching..."
xcrun simctl launch "$SIMULATOR_UDID" "$BUNDLE_ID"

echo "✅ Done!"


