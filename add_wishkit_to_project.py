#!/usr/bin/env python3
"""
Add WishKit and WishKitShared files to Xcode project
"""

import os
import re
import uuid
import subprocess
from pathlib import Path

PROJECT_FILE = "Itinero.xcodeproj/project.pbxproj"
PROJECT_DIR = Path(__file__).parent

def generate_uuid():
    """Generate a 24-character hex string for Xcode UUID"""
    return uuid.uuid4().hex[:24].upper()

def find_all_swift_files(directory):
    """Find all Swift files in a directory recursively"""
    swift_files = []
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.swift'):
                full_path = os.path.join(root, file)
                rel_path = os.path.relpath(full_path, PROJECT_DIR)
                swift_files.append(rel_path)
    return sorted(swift_files)

def read_project_file():
    """Read the project.pbxproj file"""
    project_path = PROJECT_DIR / PROJECT_FILE
    with open(project_path, 'r') as f:
        return f.read()

def write_project_file(content):
    """Write the project.pbxproj file"""
    project_path = PROJECT_DIR / PROJECT_FILE
    # Create backup
    backup_path = project_path.with_suffix('.pbxproj.backup')
    subprocess.run(['cp', str(project_path), str(backup_path)], check=True)
    print(f"✅ Backup created: {backup_path.name}")
    
    with open(project_path, 'w') as f:
        f.write(content)

def find_main_group_id(project_content):
    """Find the main group ID"""
    # Look for the main group (usually the project root)
    match = re.search(r'rootObject\s*=\s*(\w+)\s*/\* Project object \*/', project_content)
    if match:
        project_id = match.group(1)
        # Find the mainGroup reference
        match = re.search(rf'{project_id}\s*=\s*\{{[^}}]*mainGroup\s*=\s*(\w+)\s*;', project_content)
        if match:
            return match.group(1)
    return None

def find_libraries_group_id(project_content, main_group_id):
    """Find the Libraries group ID, or return None if it doesn't exist"""
    # Find children of main group
    match = re.search(rf'{main_group_id}\s*=\s*\{{[^}}]*children\s*=\s*\(([^)]+)\)', project_content, re.DOTALL)
    if match:
        children = match.group(1)
        # Look for Libraries group
        lib_match = re.search(r'(\w+)\s*/\* Libraries \*/', children)
        if lib_match:
            return lib_match.group(1)
    return None

def add_file_reference(project_content, file_path, file_ref_id, group_id):
    """Add a file reference to the project"""
    # Create file reference entry
    file_name = os.path.basename(file_path)
    file_ref_entry = f'\t\t{file_ref_id} /* {file_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{file_name}"; sourceTree = "<group>"; }};\n'
    
    # Add to PBXFileReference section
    file_ref_section = re.search(r'(/\* Begin PBXFileReference section \*/)', project_content)
    if file_ref_section:
        insert_pos = file_ref_section.end()
        project_content = project_content[:insert_pos] + file_ref_entry + project_content[insert_pos:]
    
    # Add to group's children
    group_pattern = rf'({group_id}\s*=\s*\{{[^}}]*children\s*=\s*\()'
    match = re.search(group_pattern, project_content)
    if match:
        insert_pos = match.end()
        child_entry = f'\t\t\t\t{file_ref_id} /* {file_name} */,\n'
        project_content = project_content[:insert_pos] + child_entry + project_content[insert_pos:]
    
    return project_content

def add_build_file(project_content, file_ref_id, build_file_id):
    """Add a build file reference"""
    # Add to PBXBuildFile section
    build_file_entry = f'\t\t{build_file_id} /* {os.path.basename(file_ref_id)} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* {os.path.basename(file_ref_id)} */; }};\n'
    
    build_file_section = re.search(r'(/\* Begin PBXBuildFile section \*/)', project_content)
    if build_file_section:
        insert_pos = build_file_section.end()
        project_content = project_content[:insert_pos] + build_file_entry + project_content[insert_pos:]
    
    # Add to Sources build phase
    sources_pattern = r'(/\* Sources \*/ = \{[^}]*files = \()'
    match = re.search(sources_pattern, project_content)
    if match:
        insert_pos = match.end()
        sources_entry = f'\t\t\t\t{build_file_id} /* {os.path.basename(file_ref_id)} in Sources */,\n'
        project_content = project_content[:insert_pos] + sources_entry + project_content[insert_pos:]
    
    return project_content

def main():
    print("🔧 Adding WishKit files to Xcode project...")
    print("=" * 60)
    
    # Find all Swift files
    wishkit_files = find_all_swift_files("Libraries/WishKit")
    wishkitshared_files = find_all_swift_files("Libraries/WishKitShared")
    
    all_files = wishkit_files + wishkitshared_files
    
    if not all_files:
        print("❌ No Swift files found in Libraries/WishKit or Libraries/WishKitShared")
        return
    
    print(f"\n📋 Found {len(all_files)} Swift file(s) to add")
    print(f"   - WishKit: {len(wishkit_files)} files")
    print(f"   - WishKitShared: {len(wishkitshared_files)} files")
    
    # Read project file
    project_content = read_project_file()
    
    # Check if files are already added
    existing_files = []
    for file_path in all_files:
        file_name = os.path.basename(file_path)
        if file_name in project_content:
            existing_files.append(file_path)
    
    if existing_files:
        print(f"\n⚠️  {len(existing_files)} file(s) already in project, skipping...")
        all_files = [f for f in all_files if f not in existing_files]
    
    if not all_files:
        print("\n✅ All files already in project!")
        return
    
    # Find main group
    main_group_id = find_main_group_id(project_content)
    if not main_group_id:
        print("❌ Could not find main group")
        return
    
    # Find or create Libraries group
    libraries_group_id = find_libraries_group_id(project_content, main_group_id)
    if not libraries_group_id:
        print("⚠️  Libraries group not found, creating...")
        libraries_group_id = generate_uuid()
        # This is complex - for now, just use main group
        libraries_group_id = main_group_id
        print(f"   Using main group: {libraries_group_id}")
    
    # Add files
    print(f"\n📝 Adding {len(all_files)} file(s)...")
    added_count = 0
    
    for file_path in all_files:
        if not os.path.exists(file_path):
            print(f"   ⚠️  File not found: {file_path}, skipping...")
            continue
        
        file_ref_id = generate_uuid()
        build_file_id = generate_uuid()
        
        try:
            project_content = add_file_reference(project_content, file_path, file_ref_id, libraries_group_id)
            project_content = add_build_file(project_content, file_ref_id, build_file_id)
            added_count += 1
            if added_count % 10 == 0:
                print(f"   Added {added_count}/{len(all_files)} files...")
        except Exception as e:
            print(f"   ❌ Error adding {file_path}: {e}")
    
    if added_count > 0:
        write_project_file(project_content)
        print(f"\n✅ Successfully added {added_count} file(s) to project!")
        print("\n💡 Next steps:")
        print("   1. Open Xcode")
        print("   2. Clean build folder (⌘⇧K)")
        print("   3. Build project (⌘B)")
    else:
        print("\n⚠️  No files were added")

if __name__ == "__main__":
    main()



