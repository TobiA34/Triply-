#!/bin/bash

# Script to open the project in Xcode for SwiftUI Previews
# This will create the Xcode project if it doesn't exist, then open it

set -e

PROJECT_NAME="Triply"
CURRENT_DIR="$(pwd)"

echo "🚀 Opening Triply in Xcode for SwiftUI Previews..."

# Check if .xcodeproj exists
if [ -d "$PROJECT_NAME.xcodeproj" ]; then
    echo "✅ Found existing Xcode project"
    open "$PROJECT_NAME.xcodeproj"
    echo ""
    echo "📱 To use SwiftUI Previews:"
    echo "   1. Select any .swift file in the Views folder"
    echo "   2. Press Option + Command + Return (⌥⌘↩) to show canvas"
    echo "   3. Or click the 'Resume' button in the preview canvas"
    exit 0
fi

# Check if xcodegen is available
if command -v xcodegen &> /dev/null; then
    echo "📦 Generating Xcode project with xcodegen..."
    if [ -f "project.yml" ]; then
        xcodegen generate
        open "$PROJECT_NAME.xcodeproj"
        echo ""
        echo "✅ Project created and opened!"
        echo ""
        echo "📱 To use SwiftUI Previews:"
        echo "   1. Select any .swift file in the Views folder"
        echo "   2. Press Option + Command + Return (⌥⌘↩) to show canvas"
        echo "   3. Or click the 'Resume' button in the preview canvas"
    else
        echo "❌ project.yml not found!"
        exit 1
    fi
else
    echo "⚠️  Xcode project not found and xcodegen is not installed."
    echo ""
    echo "Please choose one of these options:"
    echo ""
    echo "Option 1: Install xcodegen and auto-generate project"
    echo "   brew install xcodegen"
    echo "   ./create_project.sh"
    echo ""
    echo "Option 2: Create project manually in Xcode"
    echo "   See SETUP.md for detailed instructions"
    echo ""
    echo "Option 3: Open Xcode and create new project, then add these files"
    echo "   See SETUP.md for step-by-step guide"
    exit 1
fi



