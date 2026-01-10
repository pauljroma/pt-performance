#!/usr/bin/env python3
"""
Automated Xcode Project File Addition Script
Adds Swift files to PTPerformance.xcodeproj
"""

import os
import re
import sys
import uuid

def generate_uuid():
    """Generate 24-character uppercase hex UUID for Xcode"""
    return uuid.uuid4().hex[:24].upper()

def add_files_to_xcode_project():
    """Add BUILD 115 mode system files to Xcode project"""

    project_file = 'PTPerformance.xcodeproj/project.pbxproj'

    if not os.path.exists(project_file):
        print(f"❌ Error: {project_file} not found")
        sys.exit(1)

    # Read project file
    with open(project_file, 'r') as f:
        project_content = f.read()

    # Files to add with their groups
    files_to_add = [
        ('Models/Mode.swift', 'Models', 'Mode.swift'),
        ('Models/ModeFeature.swift', 'Models', 'ModeFeature.swift'),
        ('Services/ModeService.swift', 'Services', 'ModeService.swift'),
        ('ViewModels/FeatureVisibilityViewModel.swift', 'ViewModels', 'FeatureVisibilityViewModel.swift'),
        ('ViewModels/ModeSwitchingViewModel.swift', 'ViewModels', 'ModeSwitchingViewModel.swift'),
        ('Views/Components/ModeTheme.swift', 'Views/Components', 'ModeTheme.swift'),
        ('Views/Components/ModeThemeModifier.swift', 'Views/Components', 'ModeThemeModifier.swift'),
        ('Views/Therapist/ModeSwitchingPanel.swift', 'Views/Therapist', 'ModeSwitchingPanel.swift'),
    ]

    # Check files exist
    print("Checking files exist...")
    for filepath, group, filename in files_to_add:
        if not os.path.exists(filepath):
            print(f"  ❌ {filepath} - NOT FOUND")
            sys.exit(1)
        else:
            print(f"  ✅ {filepath}")

    print(f"\n✅ All {len(files_to_add)} files exist\n")

    # Generate UUIDs
    file_uuids = {}
    build_uuids = {}

    for filepath, group, filename in files_to_add:
        file_uuids[filename] = generate_uuid()
        build_uuids[filename] = generate_uuid()

    print("Generated UUIDs for all files\n")

    # Find PBXSourcesBuildPhase section
    sources_phase_match = re.search(
        r'(/\* Sources \*/.*?isa = PBXSourcesBuildPhase;.*?files = \()(.*?)(\);)',
        project_content,
        re.DOTALL
    )

    if not sources_phase_match:
        print("❌ Could not find PBXSourcesBuildPhase")
        sys.exit(1)

    # Build the additions
    file_references = []
    build_files = []
    sources_build_phase_files = []

    for filepath, group, filename in files_to_add:
        file_ref_uuid = file_uuids[filename]
        build_uuid = build_uuids[filename]

        # PBXFileReference entry
        file_ref = f"""		{file_ref_uuid} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = "<group>"; }};"""
        file_references.append(file_ref)

        # PBXBuildFile entry
        build_file = f"""		{build_uuid} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* {filename} */; }};"""
        build_files.append(build_file)

        # Sources build phase entry
        sources_entry = f"""				{build_uuid} /* {filename} in Sources */,"""
        sources_build_phase_files.append(sources_entry)

    # Find insertion points and add entries

    # 1. Add to PBXBuildFile section
    build_file_section = re.search(
        r'(/\* Begin PBXBuildFile section \*/)(.*?)(/\* End PBXBuildFile section \*/)',
        project_content,
        re.DOTALL
    )

    if build_file_section:
        new_build_section = build_file_section.group(1) + build_file_section.group(2).rstrip() + '\n' + '\n'.join(build_files) + '\n' + build_file_section.group(3)
        project_content = project_content.replace(build_file_section.group(0), new_build_section)
        print(f"✅ Added {len(build_files)} PBXBuildFile entries")

    # 2. Add to PBXFileReference section
    file_ref_section = re.search(
        r'(/\* Begin PBXFileReference section \*/)(.*?)(/\* End PBXFileReference section \*/)',
        project_content,
        re.DOTALL
    )

    if file_ref_section:
        new_ref_section = file_ref_section.group(1) + file_ref_section.group(2).rstrip() + '\n' + '\n'.join(file_references) + '\n' + file_ref_section.group(3)
        project_content = project_content.replace(file_ref_section.group(0), new_ref_section)
        print(f"✅ Added {len(file_references)} PBXFileReference entries")

    # 3. Add to PBXSourcesBuildPhase
    current_sources = sources_phase_match.group(2)
    new_sources = current_sources.rstrip() + '\n' + '\n'.join(sources_build_phase_files) + '\n'
    new_sources_section = sources_phase_match.group(1) + new_sources + sources_phase_match.group(3)
    project_content = project_content.replace(sources_phase_match.group(0), new_sources_section)
    print(f"✅ Added {len(sources_build_phase_files)} files to Sources build phase")

    # 4. Add files to their respective PBXGroup sections
    # This is simplified - adds to Models, Services, ViewModels, Views groups
    group_additions = {
        'Models': [file_uuids['Mode.swift'], file_uuids['ModeFeature.swift']],
        'Services': [file_uuids['ModeService.swift']],
        'ViewModels': [file_uuids['FeatureVisibilityViewModel.swift'], file_uuids['ModeSwitchingViewModel.swift']],
    }

    for group_name, uuids in group_additions.items():
        # Find the group
        group_pattern = rf'(/\* {group_name} \*/.*?children = \()(.*?)(\);)'
        group_match = re.search(group_pattern, project_content, re.DOTALL)

        if group_match:
            # Find corresponding filenames
            group_files = [fn for fp, g, fn in files_to_add if g == group_name]

            entries = [f"\t\t\t\t{file_uuids[fn]} /* {fn} */," for fn in group_files]

            new_group = group_match.group(1) + group_match.group(2).rstrip() + '\n' + '\n'.join(entries) + '\n' + group_match.group(3)
            project_content = project_content.replace(group_match.group(0), new_group)
            print(f"✅ Added {len(entries)} files to {group_name} group")

    # Write updated project file
    backup_file = project_file + '.backup'
    with open(backup_file, 'w') as f:
        f.write(project_content)
    print(f"\n✅ Backup created: {backup_file}")

    with open(project_file, 'w') as f:
        f.write(project_content)
    print(f"✅ Updated: {project_file}")

    print(f"\n{'='*60}")
    print("✅ SUCCESS: All {len(files_to_add)} files added to Xcode project!")
    print(f"{'='*60}\n")

    print("Next steps:")
    print("1. Open Xcode to verify files appear in Project Navigator")
    print("2. Build the project: xcodebuild build")
    print("3. Run app-builder script to deploy")
    print()

if __name__ == '__main__':
    print("\n" + "="*60)
    print("  Xcode Project File Addition - BUILD 115 Mode System")
    print("="*60 + "\n")

    add_files_to_xcode_project()
