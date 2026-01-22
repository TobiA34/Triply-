#!/usr/bin/env python3
"""
Add GooglePlacesManager.swift and ActivitySuggestionsView.swift to Xcode project
"""

import re
import uuid
import os

PROJECT_FILE = "Triply.xcodeproj/project.pbxproj"

# UUIDs generated
GOOGLE_PLACES_FILE_REF = "0B268DC499F84C4280381751"
ACTIVITY_SUGGESTIONS_FILE_REF = "4CDDB771E8D147119D419B5D"
GOOGLE_PLACES_BUILD = "3264E88B388C4F1882A92A6E"
ACTIVITY_SUGGESTIONS_BUILD = "6D5A0C7D436741A7A83A9123"

def read_file(path):
    with open(path, 'r') as f:
        return f.read()

def write_file(path, content):
    with open(path, 'w') as f:
        f.write(content)

def add_file_references(content):
    # Find PBXFileReference section
    pattern = r'(/\* Begin PBXFileReference section \*/)'
    match = re.search(pattern, content)
    if not match:
        return content, False
    
    insert_pos = match.end()
    
    # Check if already added
    if GOOGLE_PLACES_FILE_REF in content:
        print("✅ GooglePlacesManager.swift already in project")
        return content, True
    
    # Add file references
    new_refs = f"""
		{GOOGLE_PLACES_FILE_REF} /* Managers/GooglePlacesManager.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Managers/GooglePlacesManager.swift; sourceTree = "<group>"; }};
		{ACTIVITY_SUGGESTIONS_FILE_REF} /* Views/ActivitySuggestionsView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Views/ActivitySuggestionsView.swift; sourceTree = "<group>"; }};"""
    
    content = content[:insert_pos] + new_refs + content[insert_pos:]
    return content, True

def add_build_files(content):
    # Find PBXBuildFile section
    pattern = r'(/\* Begin PBXBuildFile section \*/)'
    match = re.search(pattern, content)
    if not match:
        return content, False
    
    insert_pos = match.end()
    
    # Check if already added
    if GOOGLE_PLACES_BUILD in content:
        print("✅ Build files already in project")
        return content, True
    
    # Add build files
    new_builds = f"""
		{GOOGLE_PLACES_BUILD} /* Managers/GooglePlacesManager.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {GOOGLE_PLACES_FILE_REF} /* Managers/GooglePlacesManager.swift */; }};
		{ACTIVITY_SUGGESTIONS_BUILD} /* Views/ActivitySuggestionsView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {ACTIVITY_SUGGESTIONS_FILE_REF} /* Views/ActivitySuggestionsView.swift */; }};"""
    
    content = content[:insert_pos] + new_builds + content[insert_pos:]
    return content, True

def add_to_managers_group(content):
    # Find Managers group
    pattern = r'(/\* Managers \*/ = \{[^}]*children = \(([^)]*)\);)'
    match = re.search(pattern, content, re.DOTALL)
    if not match:
        return content, False
    
    group_content = match.group(0)
    if GOOGLE_PLACES_FILE_REF in group_content:
        print("✅ GooglePlacesManager already in Managers group")
        return content, True
    
    # Add to children
    children_match = re.search(r'children = \(([^)]*)\);', group_content, re.DOTALL)
    if not children_match:
        return content, False
    
    children = children_match.group(1)
    new_child = f"\n\t\t\t\t{GOOGLE_PLACES_FILE_REF} /* Managers/GooglePlacesManager.swift */,"
    
    # Insert after last child
    insert_pos = children_match.end(1)
    new_children = children + new_child
    new_group_content = group_content[:children_match.start(1)] + new_children + group_content[insert_pos:]
    
    content = content[:match.start()] + new_group_content + content[match.end():]
    return content, True

def add_to_views_group(content):
    # Find Views group
    pattern = r'(/\* Views \*/ = \{[^}]*children = \(([^)]*)\);)'
    match = re.search(pattern, content, re.DOTALL)
    if not match:
        return content, False
    
    group_content = match.group(0)
    if ACTIVITY_SUGGESTIONS_FILE_REF in group_content:
        print("✅ ActivitySuggestionsView already in Views group")
        return content, True
    
    # Add to children
    children_match = re.search(r'children = \(([^)]*)\);', group_content, re.DOTALL)
    if not children_match:
        return content, False
    
    children = children_match.group(1)
    new_child = f"\n\t\t\t\t{ACTIVITY_SUGGESTIONS_FILE_REF} /* Views/ActivitySuggestionsView.swift */,"
    
    # Insert after last child
    insert_pos = children_match.end(1)
    new_children = children + new_child
    new_group_content = group_content[:children_match.start(1)] + new_children + group_content[insert_pos:]
    
    content = content[:match.start()] + new_group_content + content[match.end():]
    return content, True

def add_to_sources_build_phase(content):
    # Find Sources build phase
    pattern = r'(/\* Sources \*/ = \{[^}]*files = \(([^)]*)\);)'
    match = re.search(pattern, content, re.DOTALL)
    if not match:
        return content, False
    
    phase_content = match.group(0)
    if GOOGLE_PLACES_BUILD in phase_content:
        print("✅ Files already in Sources build phase")
        return content, True
    
    # Add to files
    files_match = re.search(r'files = \(([^)]*)\);', phase_content, re.DOTALL)
    if not files_match:
        return content, False
    
    files = files_match.group(1)
    new_file1 = f"\n\t\t\t\t{GOOGLE_PLACES_BUILD} /* Managers/GooglePlacesManager.swift in Sources */,"
    new_file2 = f"\n\t\t\t\t{ACTIVITY_SUGGESTIONS_BUILD} /* Views/ActivitySuggestionsView.swift in Sources */,"
    
    # Insert after last file
    insert_pos = files_match.end(1)
    new_files = files + new_file1 + new_file2
    new_phase_content = phase_content[:files_match.start(1)] + new_files + phase_content[insert_pos:]
    
    content = content[:match.start()] + new_phase_content + content[match.end():]
    return content, True

def main():
    print("🔧 Adding Google Places files to Xcode project...")
    print("=" * 60)
    
    # Create backup
    backup_file = f"{PROJECT_FILE}.backup.{uuid.uuid4().hex[:8]}"
    content = read_file(PROJECT_FILE)
    write_file(backup_file, content)
    print(f"✅ Backup created: {os.path.basename(backup_file)}")
    
    # Add file references
    content, added = add_file_references(content)
    if added:
        print("✅ Added file references")
    
    # Add build files
    content, added = add_build_files(content)
    if added:
        print("✅ Added build files")
    
    # Add to Managers group
    content, added = add_to_managers_group(content)
    if added:
        print("✅ Added to Managers group")
    
    # Add to Views group
    content, added = add_to_views_group(content)
    if added:
        print("✅ Added to Views group")
    
    # Add to Sources build phase
    content, added = add_to_sources_build_phase(content)
    if added:
        print("✅ Added to Sources build phase")
    
    # Write updated content
    write_file(PROJECT_FILE, content)
    print("\n✅ Project file updated successfully!")
    print("\n💡 Next steps:")
    print("   1. Open Xcode")
    print("   2. Clean Build Folder (⇧⌘K)")
    print("   3. Build (⌘B)")

if __name__ == "__main__":
    main()



