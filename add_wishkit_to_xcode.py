#!/usr/bin/env python3
"""
Add WishKit files to Xcode project programmatically
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
    backup_path = project_path.with_suffix('.pbxproj.backup.' + generate_uuid())
    subprocess.run(['cp', str(project_path), str(backup_path)], check=True)
    print(f"✅ Backup created: {backup_path.name}")
    
    with open(project_path, 'w') as f:
        f.write(content)

def find_target_id(project_content):
    """Find the Itinero target ID"""
    # Look for the target
    match = re.search(r'/\* Itinero \*/ = \{isa = PBXNativeTarget; name = Itinero;', project_content)
    if match:
        # Find the ID before this
        before = project_content[:match.start()]
        # Find the last UUID before this match
        uuid_match = re.search(r'(\w{24})\s*/\* Itinero \*/', before)
        if uuid_match:
            return uuid_match.group(1)
    
    # Alternative: look for target in buildConfigurationList
    match = re.search(r'(\w{24})\s*/\* Itinero \*/ = \{isa = PBXNativeTarget', project_content)
    if match:
        return match.group(1)
    
    return None

def find_libraries_group(project_content):
    """Find the Libraries group ID"""
    # Look for Libraries group
    match = re.search(r'(\w{24})\s*/\* Libraries \*/ = \{isa = PBXGroup;', project_content)
    if match:
        return match.group(1)
    return None

def find_sources_build_phase(project_content, target_id):
    """Find the Sources build phase for the target"""
    if not target_id:
        return None
    
    # Look for buildPhases in the target
    pattern = rf'{re.escape(target_id)}.*?buildPhases = \(\s*([^)]+)\)'
    match = re.search(pattern, project_content, re.DOTALL)
    if match:
        build_phases = match.group(1)
        # Look for Sources build phase
        sources_match = re.search(r'(\w{24})\s*/\* Sources \*/', build_phases)
        if sources_match:
            return sources_match.group(1)
    
    return None

def add_file_to_project(project_content, file_path, libraries_group_id, target_id, sources_phase_id):
    """Add a single file to the project"""
    file_name = os.path.basename(file_path)
    file_ref_id = generate_uuid()
    build_file_id = generate_uuid()
    
    # Create file reference
    file_ref = f'\t\t{file_ref_id} /* {file_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{file_path}"; sourceTree = "<group>"; }};\n'
    
    # Create build file
    build_file = f'\t\t{build_file_id} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* {file_name} */; }};\n'
    
    # Add file reference section
    file_ref_section = re.search(r'(/\* Begin PBXFileReference section \*/)', project_content)
    if file_ref_section:
        insert_pos = file_ref_section.end()
        project_content = project_content[:insert_pos] + file_ref + project_content[insert_pos:]
    
    # Add build file section
    build_file_section = re.search(r'(/\* Begin PBXBuildFile section \*/)', project_content)
    if build_file_section:
        insert_pos = build_file_section.end()
        project_content = project_content[:insert_pos] + build_file + project_content[insert_pos:]
    
    # Add to Libraries group
    if libraries_group_id:
        group_pattern = rf'({re.escape(libraries_group_id)}.*?children = \()([^)]+)(\))'
        match = re.search(group_pattern, project_content, re.DOTALL)
        if match:
            children = match.group(2)
            new_child = f'\t\t\t\t{file_ref_id} /* {file_name} */,\n'
            project_content = project_content[:match.start(2)] + children + new_child + project_content[match.end(2):]
    
    # Add to Sources build phase
    if sources_phase_id:
        phase_pattern = rf'({re.escape(sources_phase_id)}.*?files = \()([^)]+)(\))'
        match = re.search(phase_pattern, project_content, re.DOTALL)
        if match:
            files = match.group(2)
            new_file = f'\t\t\t\t{build_file_id} /* {file_name} in Sources */,\n'
            project_content = project_content[:match.start(2)] + files + new_file + project_content[match.end(2):]
    
    return project_content, file_ref_id, build_file_id

def main():
    print("🔧 Adding WishKit files to Xcode project...")
    print("=" * 60)
    
    # Find all Swift files
    wishkit_files = find_all_swift_files("Libraries/WishKit")
    wishkitshared_files = find_all_swift_files("Libraries/WishKitShared")
    all_files = wishkit_files + wishkitshared_files
    
    if not all_files:
        print("❌ No Swift files found")
        return
    
    print(f"\n📋 Found {len(all_files)} Swift file(s) to add")
    print(f"   - WishKit: {len(wishkit_files)} files")
    print(f"   - WishKitShared: {len(wishkitshared_files)} files")
    
    # Read project file
    project_content = read_project_file()
    
    # Check which files are already added
    existing_count = 0
    files_to_add = []
    for file_path in all_files:
        file_name = os.path.basename(file_path)
        if file_name in project_content:
            existing_count += 1
        else:
            files_to_add.append(file_path)
    
    if existing_count > 0:
        print(f"\n⚠️  {existing_count} file(s) already in project")
    
    if not files_to_add:
        print("\n✅ All files already in project!")
        return
    
    print(f"\n📝 Adding {len(files_to_add)} file(s)...")
    
    # Find target and group IDs
    target_id = find_target_id(project_content)
    libraries_group_id = find_libraries_group(project_content)
    sources_phase_id = find_sources_build_phase(project_content, target_id) if target_id else None
    
    if not target_id:
        print("❌ Could not find Itinero target")
        print("   Please add files manually in Xcode")
        return
    
    if not libraries_group_id:
        print("⚠️  Libraries group not found, files will be added to root")
    
    # Add files
    added_count = 0
    for file_path in files_to_add[:10]:  # Limit to first 10 for testing
        try:
            project_content, file_ref_id, build_file_id = add_file_to_project(
                project_content, file_path, libraries_group_id, target_id, sources_phase_id
            )
            added_count += 1
            print(f"   ✅ Added: {os.path.basename(file_path)}")
        except Exception as e:
            print(f"   ❌ Failed to add {file_path}: {e}")
    
    if added_count > 0:
        write_project_file(project_content)
        print(f"\n✅ Successfully added {added_count} file(s)!")
        print("   Please open Xcode and verify the files are added correctly")
        print("   Then run this script again to add remaining files")
    else:
        print("\n❌ No files were added")
        print("   Please add files manually in Xcode")

if __name__ == "__main__":
    main()
