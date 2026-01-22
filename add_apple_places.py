#!/usr/bin/env python3
"""
Add ApplePlacesManager.swift to Xcode project
"""

import re
import uuid
import os

PROJECT_FILE = "Triply.xcodeproj/project.pbxproj"

# UUIDs
APPLE_PLACES_FILE_REF = "A1B2C3D4E5F6789012345678"  # Will be generated
APPLE_PLACES_BUILD = "B2C3D4E5F678901234567890"  # Will be generated

def generate_uuid():
    return str(uuid.uuid4()).replace('-', '').upper()[:24]

def read_file(path):
    with open(path, 'r') as f:
        return f.read()

def write_file(path, content):
    with open(path, 'w') as f:
        f.write(content)

def add_file_reference(content, file_ref_id):
    pattern = r'(/\* Begin PBXFileReference section \*/)'
    match = re.search(pattern, content)
    if not match:
        return content, False
    
    if file_ref_id in content:
        return content, True
    
    insert_pos = match.end()
    new_ref = f"""
		{file_ref_id} /* Managers/ApplePlacesManager.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Managers/ApplePlacesManager.swift; sourceTree = "<group>"; }};"""
    
    content = content[:insert_pos] + new_ref + content[insert_pos:]
    return content, True

def add_build_file(content, file_ref_id, build_id):
    pattern = r'(/\* Begin PBXBuildFile section \*/)'
    match = re.search(pattern, content)
    if not match:
        return content, False
    
    if build_id in content:
        return content, True
    
    insert_pos = match.end()
    new_build = f"""
		{build_id} /* Managers/ApplePlacesManager.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* Managers/ApplePlacesManager.swift */; }};"""
    
    content = content[:insert_pos] + new_build + content[insert_pos:]
    return content, True

def add_to_managers_group(content, file_ref_id):
    pattern = r'(/\* Managers \*/ = \{[^}]*children = \(([^)]*)\);)'
    match = re.search(pattern, content, re.DOTALL)
    if not match:
        return content, False
    
    if file_ref_id in match.group(0):
        return content, True
    
    children_match = re.search(r'children = \(([^)]*)\);', match.group(0), re.DOTALL)
    if not children_match:
        return content, False
    
    children = children_match.group(1)
    new_child = f"\n\t\t\t\t{file_ref_id} /* Managers/ApplePlacesManager.swift */,"
    new_children = children + new_child
    
    group_content = match.group(0)
    new_group = group_content[:children_match.start(1)] + new_children + group_content[children_match.end(1):]
    content = content[:match.start()] + new_group + content[match.end():]
    return content, True

def add_to_sources(content, build_id):
    pattern = r'(/\* Sources \*/ = \{[^}]*files = \(([^)]*)\);)'
    match = re.search(pattern, content, re.DOTALL)
    if not match:
        return content, False
    
    if build_id in match.group(0):
        return content, True
    
    files_match = re.search(r'files = \(([^)]*)\);', match.group(0), re.DOTALL)
    if not files_match:
        return content, False
    
    files = files_match.group(1)
    new_file = f"\n\t\t\t\t{build_id} /* Managers/ApplePlacesManager.swift in Sources */,"
    new_files = files + new_file
    
    phase_content = match.group(0)
    new_phase = phase_content[:files_match.start(1)] + new_files + phase_content[files_match.end(1):]
    content = content[:match.start()] + new_phase + content[match.end():]
    return content, True

def main():
    print("🔧 Adding ApplePlacesManager to Xcode project...")
    
    file_ref_id = generate_uuid()
    build_id = generate_uuid()
    
    print(f"File Ref ID: {file_ref_id}")
    print(f"Build ID: {build_id}")
    
    content = read_file(PROJECT_FILE)
    backup = f"{PROJECT_FILE}.backup.{uuid.uuid4().hex[:8]}"
    write_file(backup, content)
    print(f"✅ Backup: {os.path.basename(backup)}")
    
    content, _ = add_file_reference(content, file_ref_id)
    print("✅ Added file reference")
    
    content, _ = add_build_file(content, file_ref_id, build_id)
    print("✅ Added build file")
    
    content, _ = add_to_managers_group(content, file_ref_id)
    print("✅ Added to Managers group")
    
    content, _ = add_to_sources(content, build_id)
    print("✅ Added to Sources")
    
    write_file(PROJECT_FILE, content)
    print("\n✅ Done!")

if __name__ == "__main__":
    main()



