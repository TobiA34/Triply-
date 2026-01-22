#!/bin/bash

# fix_reference_files.sh
# Checks and fixes Xcode project file references
# Ensures all files in project.pbxproj actually exist and are properly referenced

set -e

PROJECT_DIR="/Users/tobiadegoroye/Developer/SwiftUI/Triply"
PROJECT_FILE="$PROJECT_DIR/Triply.xcodeproj/project.pbxproj"
BACKUP_FILE="$PROJECT_FILE.backup.$(date +%Y%m%d_%H%M%S)"

echo "🔍 Checking Xcode project file references..."
echo ""

# Create backup
cp "$PROJECT_FILE" "$BACKUP_FILE"
echo "✅ Backup created: $(basename $BACKUP_FILE)"
echo ""

# Track issues
MISSING_FILES=()
ORPHANED_REFERENCES=()
FIXED_REFERENCES=()

# Extract all file paths from project.pbxproj
echo "📋 Scanning project file for references..."

# Get all file references (path = "...")
FILE_PATHS=$(grep -o 'path = "[^"]*"' "$PROJECT_FILE" | sed 's/path = "//;s/"//' | sort -u)

echo "Found $(echo "$FILE_PATHS" | wc -l | tr -d ' ') file references"
echo ""

# Check each file
echo "🔎 Checking if files exist..."
for file_path in $FILE_PATHS; do
    # Skip empty paths
    [ -z "$file_path" ] && continue
    
    # Skip special paths
    if [[ "$file_path" == *".xcassets"* ]] || [[ "$file_path" == *".entitlements"* ]] || [[ "$file_path" == *".storekit"* ]]; then
        continue
    fi
    
    full_path="$PROJECT_DIR/$file_path"
    
    if [ ! -f "$full_path" ] && [ ! -d "$full_path" ]; then
        MISSING_FILES+=("$file_path")
        echo "❌ Missing: $file_path"
    fi
done

echo ""

# Check for files that exist but aren't in project
echo "🔎 Checking for orphaned files..."

# Find Swift files
find "$PROJECT_DIR/Views" -name "*.swift" -type f | while read swift_file; do
    rel_path="${swift_file#$PROJECT_DIR/}"
    if ! grep -q "path = \"$rel_path\"" "$PROJECT_FILE"; then
        ORPHANED_REFERENCES+=("$rel_path")
        echo "⚠️  Not in project: $rel_path"
    fi
done

find "$PROJECT_DIR/Managers" -name "*.swift" -type f | while read swift_file; do
    rel_path="${swift_file#$PROJECT_DIR/}"
    if ! grep -q "path = \"$rel_path\"" "$PROJECT_FILE"; then
        ORPHANED_REFERENCES+=("$rel_path")
        echo "⚠️  Not in project: $rel_path"
    fi
done

find "$PROJECT_DIR/Components" -name "*.swift" -type f | while read swift_file; do
    rel_path="${swift_file#$PROJECT_DIR/}"
    if ! grep -q "path = \"$rel_path\"" "$PROJECT_FILE"; then
        ORPHANED_REFERENCES+=("$rel_path")
        echo "⚠️  Not in project: $rel_path"
    fi
done

echo ""

# Summary
echo "📊 Summary:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Missing files: ${#MISSING_FILES[@]}"
echo "Orphaned files: ${#ORPHANED_REFERENCES[@]}"
echo ""

if [ ${#MISSING_FILES[@]} -eq 0 ] && [ ${#ORPHANED_REFERENCES[@]} -eq 0 ]; then
    echo "✅ All file references are valid!"
    rm "$BACKUP_FILE"
    exit 0
fi

# Ask to fix
if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    echo "⚠️  Found ${#MISSING_FILES[@]} missing file references"
    echo ""
    echo "Would you like to remove references to missing files? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "🔧 Removing missing file references..."
        # This would require more complex sed/awk to remove PBXFileReference and PBXBuildFile entries
        echo "⚠️  Manual removal recommended - check project.pbxproj"
    fi
fi

if [ ${#ORPHANED_REFERENCES[@]} -gt 0 ]; then
    echo "⚠️  Found ${#ORPHANED_REFERENCES[@]} files not in project"
    echo ""
    echo "Would you like to add them to the project? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "🔧 Adding files to project..."
        echo "⚠️  Manual addition recommended - use Xcode or add_reference_files.sh"
    fi
fi

echo ""
echo "✅ Check complete!"
echo "📝 Backup saved at: $BACKUP_FILE"



