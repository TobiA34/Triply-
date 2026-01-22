#!/usr/bin/env python3

"""
fix_duplicate_paths.py
Automatically fixes duplicate path prefixes in Xcode project file.
When a group has a path property, its children should NOT include that path in their paths.

Example:
- Group has: path = Libraries;
- File has: path = "Libraries/CurrencyPicker/CurrencyAdapter.swift";
- Should be: path = "CurrencyPicker/CurrencyAdapter.swift";
"""

import re
import sys
from pathlib import Path
from datetime import datetime

PROJECT_DIR = Path("/Users/tobiadegoroye/Developer/SwiftUI/Triply")
PROJECT_FILE = PROJECT_DIR / "Triply.xcodeproj/project.pbxproj"


def find_groups_with_paths(project_content):
    """Find all groups that have path properties."""
    groups = {}
    
    # Find all group definitions by looking for PBXGroup with path property
    # Pattern: ID /* name */ = { ... isa = PBXGroup; ... path = value; ... }
    lines = project_content.split('\n')
    current_group_id = None
    in_group = False
    brace_count = 0
    is_pbx_group = False
    group_start_line = 0
    
    for i, line in enumerate(lines):
        # Check for group start: ID /* name */ = {
        group_match = re.match(r'^\s+([A-F0-9]{24})\s+/\*[^*]+\*/\s*=\s*\{', line)
        if group_match:
            current_group_id = group_match.group(1)
            in_group = True
            brace_count = 1
            is_pbx_group = False
            group_start_line = i
            continue
        
        if in_group:
            # Count braces
            brace_count += line.count('{') - line.count('}')
            
            # Check if it's a PBXGroup
            if 'isa = PBXGroup;' in line:
                is_pbx_group = True
            
            # Check for path property
            path_match = re.search(r'path\s*=\s*([^;]+);', line)
            if path_match and is_pbx_group and current_group_id:
                path_value = path_match.group(1).strip().strip('"').strip()
                if path_value and path_value != '.':
                    groups[current_group_id] = path_value
            
            # Group ended
            if brace_count == 0:
                in_group = False
                current_group_id = None
                is_pbx_group = False
    
    return groups




def find_all_file_references(project_content):
    """Find all file references and their paths."""
    file_refs = []
    
    # Use regex to find all PBXFileReference entries with paths
    # Pattern: ID /* name */ = { ... isa = PBXFileReference; ... path = "path"; ... }
    pattern = re.compile(
        r'^\s+([A-F0-9]{24})\s+/\*[^*]+\*/\s*=\s*\{.*?isa\s*=\s*PBXFileReference.*?path\s*=\s*"([^"]+)";',
        re.MULTILINE | re.DOTALL
    )
    
    for match in pattern.finditer(project_content):
        ref_id = match.group(1)
        file_path = match.group(2)
        file_refs.append({
            'id': ref_id,
            'path': file_path
        })
    
    return file_refs


def fix_duplicate_paths(project_content):
    """Fix all duplicate path prefixes."""
    fixes = []
    new_content = project_content
    
    # Find all groups with paths
    groups_with_paths = find_groups_with_paths(project_content)
    
    # Find all file references
    all_file_refs = find_all_file_references(project_content)
    
    print(f"   Found {len(groups_with_paths)} group(s) with path properties:")
    for group_id, group_path in groups_with_paths.items():
        print(f"      - {group_path}")
    
    print(f"   Found {len(all_file_refs)} file reference(s)")
    
    # Check each file reference against all groups with paths
    for file_ref in all_file_refs:
        file_path = file_ref['path']
        
        # Check against each group path
        for group_id, group_path in groups_with_paths.items():
            if file_path.startswith(f"{group_path}/"):
                # Found duplicate path!
                new_path = file_path[len(group_path) + 1:]
                
                # Replace in content
                old_pattern = f'path = "{file_path}";'
                new_pattern = f'path = "{new_path}";'
                
                if old_pattern in new_content:
                    new_content = new_content.replace(old_pattern, new_pattern)
                    fixes.append({
                        'old': file_path,
                        'new': new_path,
                        'group': group_path
                    })
                    break  # Only fix once per file
    
    return new_content, fixes


def main():
    """Main function."""
    print("🔍 Fixing duplicate path prefixes in Xcode project...")
    print()
    
    # Create backup
    backup_file = PROJECT_FILE.with_suffix(f".backup.{datetime.now().strftime('%Y%m%d_%H%M%S')}")
    backup_file.write_bytes(PROJECT_FILE.read_bytes())
    print(f"✅ Backup created: {backup_file.name}")
    print()
    
    # Read project file
    project_content = PROJECT_FILE.read_text()
    
    # Fix duplicate paths
    print("🔧 Scanning for duplicate paths...")
    print()
    new_content, fixes = fix_duplicate_paths(project_content)
    
    if fixes:
        print()
        print(f"✅ Fixed {len(fixes)} duplicate path(s):")
        for fix in fixes:
            print(f"   • {fix['old']}")
            print(f"     → {fix['new']}")
            print(f"     (Group: {fix['group']})")
            print()
        
        # Write fixed content
        PROJECT_FILE.write_text(new_content)
        print("✅ Project file updated!")
    else:
        print("   ✅ No duplicate paths found!")
    
    print()
    print(f"📝 Backup saved at: {backup_file}")
    print()
    print("💡 Tip: Clean build folder (⌘⇧K) and rebuild (⌘B) after running this script.")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"❌ Error: {e}", file=sys.stderr)
        sys.exit(1)

