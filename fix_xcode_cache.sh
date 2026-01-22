#!/bin/bash

# Fix Xcode "Failed to load container" error
# This script clears Xcode caches and derived data

echo "🔧 Fixing Xcode container loading issue..."
echo ""

PROJECT_DIR="/Users/tobiadegoroye/Developer/SwiftUI/Triply"
PROJECT_FILE="$PROJECT_DIR/Triply.xcodeproj/project.pbxproj"

# Step 1: Verify project file is valid
echo "📋 Step 1: Verifying project file..."
if plutil -lint "$PROJECT_FILE" > /dev/null 2>&1; then
    echo "   ✅ Project file syntax is valid"
else
    echo "   ❌ Project file has syntax errors!"
    exit 1
fi

# Step 2: Check for backup
echo ""
echo "📋 Step 2: Creating backup..."
BACKUP_FILE="$PROJECT_FILE.backup.$(date +%Y%m%d_%H%M%S)"
cp "$PROJECT_FILE" "$BACKUP_FILE"
echo "   ✅ Backup created: $(basename $BACKUP_FILE)"

# Step 3: Clear Xcode caches
echo ""
echo "📋 Step 3: Clearing Xcode caches..."

# Derived Data
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"
if [ -d "$DERIVED_DATA" ]; then
    echo "   🗑️  Clearing DerivedData..."
    rm -rf "$DERIVED_DATA"/*
    echo "   ✅ DerivedData cleared"
fi

# Module Cache
MODULE_CACHE="$HOME/Library/Developer/Xcode/DerivedData/ModuleCache.noindex"
if [ -d "$MODULE_CACHE" ]; then
    echo "   🗑️  Clearing ModuleCache..."
    rm -rf "$MODULE_CACHE"/*
    echo "   ✅ ModuleCache cleared"
fi

# Xcode User Data
USER_DATA="$HOME/Library/Developer/Xcode/UserData"
if [ -d "$USER_DATA" ]; then
    echo "   🗑️  Clearing UserData caches..."
    find "$USER_DATA" -name "*.xcuserstate" -delete 2>/dev/null
    echo "   ✅ UserData caches cleared"
fi

echo ""
echo "✅ Cache clearing complete!"
echo ""
echo "💡 Next steps:"
echo "   1. Quit Xcode completely (⌘Q)"
echo "   2. Wait 5 seconds"
echo "   3. Reopen Xcode"
echo "   4. Open the project again"
echo ""
echo "If the issue persists, try:"
echo "   - Restart your Mac"
echo "   - Check Xcode Console for specific errors"
echo "   - Verify file permissions on project.pbxproj"



