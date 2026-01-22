#!/bin/bash

# Script to show WishKit files and help add them to Xcode

PROJECT_DIR="/Users/tobiadegoroye/Developer/SwiftUI/Triply"

echo "📁 WishKit Files Location"
echo "========================"
echo ""
echo "Full path: $PROJECT_DIR/Libraries"
echo ""

# Open Finder windows
echo "🔍 Opening Finder windows..."
open "$PROJECT_DIR/Libraries/WishKit"
open "$PROJECT_DIR/Libraries/WishKitShared"

echo ""
echo "✅ Finder windows opened!"
echo ""
echo "📋 File Count:"
echo "   WishKit: $(find "$PROJECT_DIR/Libraries/WishKit" -name "*.swift" | wc -l | tr -d ' ') Swift files"
echo "   WishKitShared: $(find "$PROJECT_DIR/Libraries/WishKitShared" -name "*.swift" | wc -l | tr -d ' ') Swift files"
echo ""
echo "📝 To add in Xcode:"
echo "   1. In Xcode, right-click 'Libraries' folder"
echo "   2. Select 'Add Files to \"Itinero\"...'"
echo "   3. In the file picker, navigate to:"
echo "      $PROJECT_DIR/Libraries"
echo "   4. Select 'WishKit' and 'WishKitShared' folders"
echo "   5. Check 'Create groups' and 'Itinero' target"
echo "   6. Click 'Add'"
echo ""
