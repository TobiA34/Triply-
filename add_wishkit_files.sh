#!/bin/bash

# Script to add WishKit files to Xcode project
# This creates a simple list that can be used to add files manually or programmatically

PROJECT_DIR="/Users/tobiadegoroye/Developer/SwiftUI/Triply"
PROJECT_FILE="$PROJECT_DIR/Itinero.xcodeproj/project.pbxproj"

echo "🔧 Finding WishKit files to add..."
echo ""

# Find all Swift files
WISHKIT_FILES=$(find "$PROJECT_DIR/Libraries/WishKit" -name "*.swift" -type f | sort)
WISHKITSHARED_FILES=$(find "$PROJECT_DIR/Libraries/WishKitShared" -name "*.swift" -type f | sort)

echo "📋 Found files:"
echo "   WishKit: $(echo "$WISHKIT_FILES" | wc -l | tr -d ' ') files"
echo "   WishKitShared: $(echo "$WISHKITSHARED_FILES" | wc -l | tr -d ' ') files"
echo ""

# Create a list file
LIST_FILE="$PROJECT_DIR/wishkit_files_to_add.txt"
{
    echo "# WishKit Files to Add to Xcode Project"
    echo "# Generated on $(date)"
    echo ""
    echo "## WishKit Files:"
    echo "$WISHKIT_FILES" | sed 's|^.*/Libraries/|Libraries/|'
    echo ""
    echo "## WishKitShared Files:"
    echo "$WISHKITSHARED_FILES" | sed 's|^.*/Libraries/|Libraries/|'
} > "$LIST_FILE"

echo "✅ Created file list: wishkit_files_to_add.txt"
echo ""
echo "📝 To add these files in Xcode:"
echo "   1. Open Itinero.xcodeproj in Xcode"
echo "   2. Right-click 'Libraries' folder → 'Add Files to \"Itinero\"...'"
echo "   3. Navigate to Libraries/WishKit and select all .swift files"
echo "   4. Check 'Create groups' and 'Itinero' target"
echo "   5. Click 'Add'"
echo "   6. Repeat for Libraries/WishKitShared"
echo ""
echo "   Or use the file list: cat wishkit_files_to_add.txt"
