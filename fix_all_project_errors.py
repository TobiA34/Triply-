#!/usr/bin/env python3

"""
fix_all_project_errors.py
Comprehensive script to automatically detect and fix Xcode project errors:
1. Missing file references (files that don't exist)
2. Duplicate path prefixes
3. Incorrect file paths
4. Orphaned references (references to deleted files)
"""

import re
import sys
import os
from pathlib import Path
from datetime import datetime
from collections import defaultdict

PROJECT_DIR = Path("/Users/tobiadegoroye/Developer/SwiftUI/Triply")
PROJECT_FILE = PROJECT_DIR / "Triply.xcodeproj/project.pbxproj"


def create_backup():
    """Create a backup of the project file."""
    backup_file = PROJECT_FILE.with_suffix(f".backup.{datetime.now().strftime('%Y%m%d_%H%M%S')}")
    backup_file.write_bytes(PROJECT_FILE.read_bytes())
    return backup_file


def find_groups_with_paths(project_content):
    """Find all groups that have path properties."""
    groups = {}
    lines = project_content.split('\n')
    current_group_id = None
    in_group = False
    brace_count = 0
    is_pbx_group = False
    
    for i, line in enumerate(lines):
        group_match = re.match(r'^\s+([A-F0-9]{24})\s+/\*[^*]+\*/\s*=\s*\{', line)
        if group_match:
            current_group_id = group_match.group(1)
            in_group = True
            brace_count = 1
            is_pbx_group = False
            continue
        
        if in_group:
            brace_count += line.count('{') - line.count('}')
            
            if 'isa = PBXGroup;' in line:
                is_pbx_group = True
            
            path_match = re.search(r'path\s*=\s*([^;]+);', line)
            if path_match and is_pbx_group:
                path_value = path_match.group(1).strip().strip('"').strip()
                if path_value and path_value != '.':
                    groups[current_group_id] = path_value
            
            if brace_count == 0:
                in_group = False
                current_group_id = None
                is_pbx_group = False
    
    return groups


def find_all_file_references(project_content):
    """Find all file references and their paths."""
    file_refs = []
    
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


def find_build_file_references(project_content):
    """Find all PBXBuildFile references to file references."""
    build_files = {}
    
    pattern = re.compile(
        r'^\s+([A-F0-9]{24})\s+/\*[^*]+\*/\s+in\s+Sources\s*=\s*\{.*?fileRef\s*=\s*([A-F0-9]{24})\s+/\*[^*]+\*/\s*;',
        re.MULTILINE | re.DOTALL
    )
    
    for match in pattern.finditer(project_content):
        build_id = match.group(1)
        file_ref_id = match.group(2)
        build_files[file_ref_id] = build_id
    
    return build_files


def check_missing_files(file_refs, groups_with_paths):
    """Check which file references point to non-existent files."""
    missing = []
    existing = []
    
    for ref in file_refs:
        file_path = ref['path']
        
        # Skip special paths
        if any(skip in file_path for skip in ['.xcassets', '.entitlements', '.storekit', '.app']):
            continue
        
        # Try direct path first
        full_path = PROJECT_DIR / file_path
        
        # If not found, try with group paths (for nested groups)
        if not full_path.exists():
            # Check if path might be relative to a group with path property
            for group_path in groups_with_paths.values():
                potential_path = PROJECT_DIR / group_path / file_path
                if potential_path.exists():
                    full_path = potential_path
                    break
        
        if full_path.exists():
            existing.append(ref)
        else:
            missing.append(ref)
    
    return missing, existing


def fix_duplicate_paths(project_content, groups_with_paths, file_refs):
    """Fix duplicate path prefixes."""
    fixes = []
    new_content = project_content
    
    for file_ref in file_refs:
        file_path = file_ref['path']
        
        for group_id, group_path in groups_with_paths.items():
            if file_path.startswith(f"{group_path}/"):
                new_path = file_path[len(group_path) + 1:]
                old_pattern = f'path = "{file_path}";'
                new_pattern = f'path = "{new_path}";'
                
                if old_pattern in new_content:
                    new_content = new_content.replace(old_pattern, new_pattern)
                    fixes.append({
                        'old': file_path,
                        'new': new_path,
                        'type': 'duplicate_path'
                    })
                    break
    
    return new_content, fixes


def remove_missing_file_references(project_content, missing_refs, build_files):
    """Remove references to missing files from the project."""
    fixes = []
    new_content = project_content
    
    for ref in missing_refs:
        ref_id = ref['id']
        file_path = ref['path']
        
        # Remove PBXFileReference
        ref_pattern = re.compile(
            rf'^\s+{re.escape(ref_id)}\s+/\*[^*]+\*/\s*=\s*\{{.*?\}};',
            re.MULTILINE | re.DOTALL
        )
        if ref_pattern.search(new_content):
            new_content = ref_pattern.sub('', new_content)
            fixes.append({
                'file': file_path,
                'type': 'removed_missing'
            })
        
        # Remove PBXBuildFile if exists
        if ref_id in build_files:
            build_id = build_files[ref_id]
            # Escape braces properly in regex
            escaped_build_id = re.escape(build_id)
            build_pattern = re.compile(
                rf'^\s+{escaped_build_id}\s+/\*[^*]+\*/\s+in\s+Sources\s*=\s*\{{[^}}]+\}};',
                re.MULTILINE | re.DOTALL
            )
            if build_pattern.search(new_content):
                new_content = build_pattern.sub('', new_content)
        
        # Remove from group children lists
        children_pattern = re.compile(
            rf'(\s+{re.escape(ref_id)}\s+/\*[^*]+\*/\s*[,)])',
            re.MULTILINE
        )
        new_content = children_pattern.sub('', new_content)
    
    # Clean up empty lines
    new_content = re.sub(r'\n\s*\n\s*\n', '\n\n', new_content)
    
    return new_content, fixes


def find_orphaned_files():
    """Find Swift files that exist but aren't in the project."""
    orphaned = []
    
    # Directories to check
    dirs_to_check = ['Views', 'Managers', 'Models', 'Extensions', 'Components', 'Widgets', 'Intents']
    
    for dir_name in dirs_to_check:
        dir_path = PROJECT_DIR / dir_name
        if not dir_path.exists():
            continue
        
        for swift_file in dir_path.rglob('*.swift'):
            rel_path = str(swift_file.relative_to(PROJECT_DIR))
            
            # Check if file is referenced in project
            project_content = PROJECT_FILE.read_text()
            if f'path = "{rel_path}"' not in project_content:
                orphaned.append(rel_path)
    
    return orphaned


def main():
    """Main function."""
    print("🔧 Fixing all Xcode project errors...")
    print("=" * 60)
    print()
    
    # Create backup
    backup_file = create_backup()
    print(f"✅ Backup created: {backup_file.name}")
    print()
    
    # Read project file
    project_content = PROJECT_FILE.read_text()
    
    # Step 1: Find groups with paths
    print("📋 Step 1: Analyzing project structure...")
    groups_with_paths = find_groups_with_paths(project_content)
    file_refs = find_all_file_references(project_content)
    build_files = find_build_file_references(project_content)
    
    print(f"   Found {len(groups_with_paths)} group(s) with path properties")
    print(f"   Found {len(file_refs)} file reference(s)")
    print(f"   Found {len(build_files)} build file reference(s)")
    print()
    
    all_fixes = []
    
    # Step 2: Check for missing files
    print("🔍 Step 2: Checking for missing files...")
    missing_refs, existing_refs = check_missing_files(file_refs, groups_with_paths)
    
    if missing_refs:
        print(f"   ⚠️  Found {len(missing_refs)} missing file(s):")
        for ref in missing_refs[:10]:  # Show first 10
            print(f"      • {ref['path']}")
        if len(missing_refs) > 10:
            print(f"      ... and {len(missing_refs) - 10} more")
        print()
        
        # Remove missing file references
        print("   🗑️  Removing missing file references...")
        project_content, fixes = remove_missing_file_references(project_content, missing_refs, build_files)
        all_fixes.extend(fixes)
        print(f"   ✅ Removed {len(fixes)} missing file reference(s)")
    else:
        print("   ✅ No missing files found")
    print()
    
    # Step 3: Fix duplicate paths
    print("🔍 Step 3: Checking for duplicate path prefixes...")
    project_content, fixes = fix_duplicate_paths(project_content, groups_with_paths, file_refs)
    
    if fixes:
        print(f"   ⚠️  Found {len(fixes)} duplicate path(s):")
        for fix in fixes:
            print(f"      • {fix['old']} → {fix['new']}")
        all_fixes.extend(fixes)
        print(f"   ✅ Fixed {len(fixes)} duplicate path(s)")
    else:
        print("   ✅ No duplicate paths found")
    print()
    
    # Step 4: Find orphaned files (files not in project)
    print("🔍 Step 4: Checking for orphaned files...")
    orphaned = find_orphaned_files()
    
    if orphaned:
        print(f"   ⚠️  Found {len(orphaned)} file(s) not in project:")
        for file_path in orphaned[:10]:  # Show first 10
            print(f"      • {file_path}")
        if len(orphaned) > 10:
            print(f"      ... and {len(orphaned) - 10} more")
        print()
        print("   💡 These files exist but aren't referenced in the project.")
        print("      Add them manually in Xcode if needed.")
    else:
        print("   ✅ No orphaned files found")
    print()
    
    # Summary
    print("=" * 60)
    print("📊 Summary:")
    print("=" * 60)
    
    if all_fixes:
        print(f"✅ Fixed {len(all_fixes)} issue(s):")
        fixes_by_type = defaultdict(int)
        for fix in all_fixes:
            fixes_by_type[fix.get('type', 'unknown')] += 1
        
        for fix_type, count in fixes_by_type.items():
            type_name = fix_type.replace('_', ' ').title()
            print(f"   • {type_name}: {count}")
        
        # Write fixed content
        PROJECT_FILE.write_text(project_content)
        print()
        print("✅ Project file updated!")
    else:
        print("✅ No issues found! Project file is clean.")
    
    print()
    print(f"📝 Backup saved at: {backup_file}")
    print()
    print("💡 Next steps:")
    print("   1. Clean build folder in Xcode (⌘⇧K)")
    print("   2. Build project (⌘B)")
    if orphaned:
        print("   3. Consider adding orphaned files to the project if needed")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"❌ Error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)

