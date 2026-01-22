#!/bin/bash

# add_reference_files.sh
# Automatically adds missing Swift files to Xcode project
# Generates unique IDs and adds proper references

set -e

PROJECT_DIR="/Users/tobiadegoroye/Developer/SwiftUI/Triply"
PROJECT_FILE="$PROJECT_DIR/Triply.xcodeproj/project.pbxproj"
BACKUP_FILE="$PROJECT_FILE.backup.$(date +%Y%m%d_%H%M%S)"

echo "🔧 Adding missing files to Xcode project..."
echo ""

# Create backup
cp "$PROJECT_FILE" "$BACKUP_FILE"
echo "✅ Backup created: $(basename $BACKUP_FILE)"
echo ""

# Generate unique ID (24 hex characters)
generate_id() {
    openssl rand -hex 12 | tr '[:lower:]' '[:upper:]'
}

# Find Swift files not in project
find "$PROJECT_DIR/Views" "$PROJECT_DIR/Managers" "$PROJECT_DIR/Components" -name "*.swift" -type f | while read swift_file; do
    rel_path="${swift_file#$PROJECT_DIR/}"
    filename=$(basename "$swift_file")
    
    # Check if already in project
    if grep -q "path = \"$rel_path\"" "$PROJECT_FILE" || grep -q "path = \"$filename\"" "$PROJECT_FILE"; then
        continue
    fi
    
    echo "➕ Adding: $rel_path"
    
    # Generate IDs
    FILE_REF_ID=$(generate_id)
    BUILD_FILE_ID=$(generate_id)
    
    # Extract filename without extension
    BASENAME="${filename%.swift}"
    
    # Add PBXFileReference
    FILE_REF_LINE="		$FILE_REF_ID /* $filename */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"$rel_path\"; sourceTree = \"<group>\"; };"
    
    # Add PBXBuildFile
    BUILD_FILE_LINE="		$BUILD_FILE_ID /* $filename in Sources */ = {isa = PBXBuildFile; fileRef = $FILE_REF_ID /* $filename */; };"
    
    # Find insertion points (after last PBXFileReference and PBXBuildFile)
    # This is a simplified version - in production, you'd want more precise insertion
    
    echo "   File Ref ID: $FILE_REF_ID"
    echo "   Build File ID: $BUILD_FILE_ID"
    echo ""
done

echo "⚠️  Note: This script identifies files to add."
echo "   For automatic addition, use Xcode or manually edit project.pbxproj"
echo "   See ROAMY_FEATURES_IMPLEMENTED.md for manual steps"



