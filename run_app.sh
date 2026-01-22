#!/bin/bash
# Quick run script for Triply app

echo "=== Triply App Run Helper ==="
echo ""

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode not found. Please install Xcode from the App Store."
    exit 1
fi

echo "✓ Xcode found"
echo ""

# Check scheme
if [ -f "Triply.xcodeproj/xcshareddata/xcschemes/Triply.xcscheme" ]; then
    echo "✓ Triply scheme exists"
else
    echo "✗ Triply scheme missing"
    echo "  Please create it in Xcode: Product → Scheme → Manage Schemes..."
    exit 1
fi

echo ""
echo "=== Instructions ==="
echo "1. Open Xcode: open Triply.xcodeproj"
echo "2. Select 'Triply' scheme from dropdown"
echo "3. Select a simulator (e.g., iPhone 15)"
echo "4. Press Cmd+R to run"
echo ""
echo "OR use command line:"
echo "  xcodebuild -project Triply.xcodeproj -scheme Triply -destination 'platform=iOS Simulator,name=iPhone 15' build"
echo ""
