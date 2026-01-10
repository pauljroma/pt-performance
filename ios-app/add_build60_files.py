#!/usr/bin/env python3
"""
Add Build 60 UX Polish files to Xcode project
"""
import uuid
import re
import sys

def generate_uuid():
    """Generate a 24-character hex ID like Xcode uses"""
    return uuid.uuid4().hex.upper()[:24]

def add_file_to_project(project_path, file_path, file_name, group_name):
    """Add a file reference and build file to Xcode project"""

    with open(project_path, 'r') as f:
        content = f.read()

    # Generate UUIDs for the file
    file_ref_id = generate_uuid()
    build_file_id = generate_uuid()

    print(f"Adding {file_name}:")
    print(f"  File Ref ID: {file_ref_id}")
    print(f"  Build File ID: {build_file_id}")

    # Check if file already exists in project
    if file_name in content:
        print(f"  ⚠️  {file_name} already in project")
        return content, None, None

    # 1. Add PBXBuildFile entry
    build_file_entry = f"\t\t{build_file_id} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* {file_name} */; }};\n"

    # Find the PBXBuildFile section and add after first entry
    build_file_pattern = r'(/\* Begin PBXBuildFile section \*/\n)'
    match = re.search(build_file_pattern, content)
    if match:
        insert_pos = match.end()
        content = content[:insert_pos] + build_file_entry + content[insert_pos:]
        print(f"  ✅ Added PBXBuildFile entry")
    else:
        print(f"  ❌ Could not find PBXBuildFile section")
        return content, None, None

    # 2. Add PBXFileReference entry
    file_ref_entry = f'\t\t{file_ref_id} /* {file_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {file_path}; sourceTree = "<group>"; }};\n'

    # Find the PBXFileReference section
    file_ref_pattern = r'(/\* Begin PBXFileReference section \*/\n)'
    match = re.search(file_ref_pattern, content)
    if match:
        insert_pos = match.end()
        content = content[:insert_pos] + file_ref_entry + content[insert_pos:]
        print(f"  ✅ Added PBXFileReference entry")
    else:
        print(f"  ❌ Could not find PBXFileReference section")
        return content, None, None

    return content, file_ref_id, build_file_id

def add_to_sources_build_phase(content, build_file_id, file_name):
    """Add file to Sources build phase for PTPerformance target"""

    # Find the Sources build phase for PTPerformance target
    pattern = r'(/\* Sources \*/ = \{[^}]+isa = PBXSourcesBuildPhase;[^}]+files = \(\n)'
    match = re.search(pattern, content, re.DOTALL)

    if match:
        insert_pos = match.end()
        build_phase_entry = f'\t\t\t\t{build_file_id} /* {file_name} in Sources */,\n'
        content = content[:insert_pos] + build_phase_entry + content[insert_pos:]
        print(f"  ✅ Added to Sources build phase")
        return content
    else:
        print(f"  ❌ Could not find Sources build phase")
        return content

def add_to_group(content, file_ref_id, file_name, group_name):
    """Add file reference to appropriate group"""

    # Find the group by name
    pattern = rf'(/\* {group_name} \*/ = \{{[^}}]+children = \(\n)'
    match = re.search(pattern, content, re.DOTALL)

    if match:
        insert_pos = match.end()
        group_entry = f'\t\t\t\t{file_ref_id} /* {file_name} */,\n'
        content = content[:insert_pos] + group_entry + content[insert_pos:]
        print(f"  ✅ Added to {group_name} group")
        return content
    else:
        print(f"  ❌ Could not find {group_name} group")
        return content

def main():
    project_path = '/Users/expo/Code/expo/ios-app/PTPerformance/PTPerformance.xcodeproj/project.pbxproj'

    # Build 60 files to add
    files_to_add = [
        {
            'file_path': 'Utils/LoadingStateView.swift',
            'file_name': 'LoadingStateView.swift',
            'group_name': 'Utils'
        },
        {
            'file_path': 'Utils/ErrorStateView.swift',
            'file_name': 'ErrorStateView.swift',
            'group_name': 'Utils'
        },
        {
            'file_path': 'ViewModels/SessionSummaryViewModel.swift',
            'file_name': 'SessionSummaryViewModel.swift',
            'group_name': 'ViewModels'
        }
    ]

    # Read project file once
    with open(project_path, 'r') as f:
        content = f.read()

    # Backup original
    with open(project_path + '.build60_backup', 'w') as f:
        f.write(content)
    print("✅ Created backup: project.pbxproj.build60_backup\n")

    # Add each file
    for file_info in files_to_add:
        content, file_ref_id, build_file_id = add_file_to_project(
            project_path,
            file_info['file_path'],
            file_info['file_name'],
            file_info['group_name']
        )

        if file_ref_id and build_file_id:
            # Add to Sources build phase
            content = add_to_sources_build_phase(content, build_file_id, file_info['file_name'])

            # Add to group
            content = add_to_group(content, file_ref_id, file_info['file_name'], file_info['group_name'])

        print()

    # Write updated project file
    with open(project_path, 'w') as f:
        f.write(content)

    print("✅ Updated project.pbxproj")
    print("✅ All Build 60 UX Polish files added to Xcode project!")

if __name__ == '__main__':
    main()
