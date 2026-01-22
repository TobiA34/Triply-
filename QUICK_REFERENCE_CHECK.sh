#!/bin/bash

# Quick Reference Check - Simple version
# Just checks for the most common issues

echo "🔍 Quick Reference Check..."
echo ""

PROJECT_DIR="/Users/tobiadegoroye/Developer/SwiftUI/Triply"
PROJECT_FILE="$PROJECT_DIR/Triply.xcodeproj/project.pbxproj"

# Check for missing files (files referenced but don't exist)
echo "Checking for missing files..."
MISSING=$(grep -o 'path = "[^"]*"' "$PROJECT_FILE" | sed 's/path = "//;s/"//' | while read path; do
    [ -z "$path" ] && continue
    [[ "$path" == *".xcassets"* ]] && continue
    [[ "$path" == *".entitlements"* ]] && continue
    [[ "$path" == *".storekit"* ]] && continue
    
    if [ ! -f "$PROJECT_DIR/$path" ] && [ ! -d "$PROJECT_DIR/$path" ]; then
        echo "$path"
    fi
done)

if [ -z "$MISSING" ]; then
    echo "✅ No missing files found"
else
    echo "❌ Missing files:"
    echo "$MISSING" | while read file; do
        echo "   - $file"
    done
fi

echo ""
echo "✅ Check complete!"
echo ""
echo "💡 For detailed check, run: swift check_reference_files.swift"



