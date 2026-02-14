#!/usr/bin/env python3
"""
Add Audio Health Journal files to PTPerformance.xcodeproj
"""

import os
import re
import sys
import uuid

def generate_uuid():
    """Generate 24-character uppercase hex UUID for Xcode"""
    return uuid.uuid4().hex[:24].upper()

def add_journal_files():
    """Add journal files to Xcode project"""

    project_file = 'PTPerformance.xcodeproj/project.pbxproj'

    if not os.path.exists(project_file):
        print(f"❌ Error: {project_file} not found")
        sys.exit(1)

    # Read project file
    with open(project_file, 'r') as f:
        project_content = f.read()

    # Files to add with their groups
    files_to_add = [
        ('Models/JournalEntry.swift', 'Models', 'JournalEntry.swift'),
        ('Services/AudioRecordingService.swift', 'Services', 'AudioRecordingService.swift'),
        ('Views/Journal/AudioHealthJournalView.swift', 'Views/Journal', 'AudioHealthJournalView.swift'),
        ('Views/Journal/JournalEntryRecordingView.swift', 'Views/Journal', 'JournalEntryRecordingView.swift'),
        ('Views/Journal/JournalEntryDetailView.swift', 'Views/Journal', 'JournalEntryDetailView.swift'),
    ]

    print("=" * 60)
    print("  Audio Health Journal - File Addition")
    print("=" * 60)

    # Check files exist
    print("\nChecking files exist...")
    for filepath, group, filename in files_to_add:
        if not os.path.exists(filepath):
            print(f"  ❌ {filepath} - NOT FOUND")
            sys.exit(1)
        else:
            print(f"  ✅ {filepath}")

    print(f"\n✅ All {len(files_to_add)} files exist\n")

    # Generate UUIDs for all files
    file_uuids = {}
    for filepath, group, filename in files_to_add:
        file_uuids[filepath] = {
            'build_file_uuid': generate_uuid(),
            'file_ref_uuid': generate_uuid()
        }

    print("Generated UUIDs for all files\n")

    # Find group UUIDs from project file
    group_uuids = {}

    # Find Models group UUID
    models_match = re.search(r'([A-F0-9]{24}) /\* Models \*/ = \{', project_content)
    if models_match:
        group_uuids['Models'] = models_match.group(1)

    # Find Services group UUID
    services_match = re.search(r'([A-F0-9]{24}) /\* Services \*/ = \{', project_content)
    if services_match:
        group_uuids['Services'] = services_match.group(1)

    # Find Views group UUID
    views_match = re.search(r'([A-F0-9]{24}) /\* Views \*/ = \{', project_content)
    if views_match:
        group_uuids['Views'] = views_match.group(1)

    # Find or create Journal group under Views
    journal_match = re.search(r'([A-F0-9]{24}) /\* Journal \*/ = \{', project_content)
    if journal_match:
        group_uuids['Views/Journal'] = journal_match.group(1)
    else:
        # Create new Journal group
        journal_uuid = generate_uuid()
        group_uuids['Views/Journal'] = journal_uuid

        # Add Journal group to Views group
        views_uuid = group_uuids['Views']
        views_group_pattern = f'({views_uuid} /\\* Views \\*/ = {{[^}}]*children = \\([^)]*)'
        views_group_match = re.search(views_group_pattern, project_content, re.DOTALL)
        if views_group_match:
            insert_pos = views_group_match.end()
            journal_ref = f'\n\t\t\t\t{journal_uuid} /* Journal */,'
            project_content = project_content[:insert_pos] + journal_ref + project_content[insert_pos:]

        # Add Journal group definition
        journal_group_def = f'''
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
\t\t{journal_uuid} /* Journal */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t);
\t\t\tpath = Journal;
\t\t\tsourceTree = "<group>";
\t\t}};
'''
        # Find the right place to insert
        group_section = re.search(r'(/\* Begin PBXGroup section \*/)', project_content)
        if group_section:
            insert_pos = group_section.end()
            project_content = project_content[:insert_pos] + f'\n\t\t{journal_uuid} /* Journal */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t);\n\t\t\tpath = Journal;\n\t\t\tsourceTree = "<group>";\n\t\t}};' + project_content[insert_pos:]

    # Add PBXBuildFile entries
    build_file_section = re.search(r'/\* Begin PBXBuildFile section \*/', project_content)
    if build_file_section:
        insert_pos = build_file_section.end()
        build_file_entries = []
        for filepath, group, filename in files_to_add:
            uuids = file_uuids[filepath]
            build_file_entry = f'\n\t\t{uuids["build_file_uuid"]} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {uuids["file_ref_uuid"]} /* {filename} */; }};'
            build_file_entries.append(build_file_entry)
        project_content = project_content[:insert_pos] + ''.join(build_file_entries) + project_content[insert_pos:]
        print(f"✅ Added {len(build_file_entries)} PBXBuildFile entries")

    # Add PBXFileReference entries
    file_ref_section = re.search(r'/\* Begin PBXFileReference section \*/', project_content)
    if file_ref_section:
        insert_pos = file_ref_section.end()
        file_ref_entries = []
        for filepath, group, filename in files_to_add:
            uuids = file_uuids[filepath]
            file_ref_entry = f'\n\t\t{uuids["file_ref_uuid"]} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = "<group>"; }};'
            file_ref_entries.append(file_ref_entry)
        project_content = project_content[:insert_pos] + ''.join(file_ref_entries) + project_content[insert_pos:]
        print(f"✅ Added {len(file_ref_entries)} PBXFileReference entries")

    # Add files to Sources build phase
    sources_build_phase = re.search(r'([A-F0-9]{24}) /\* Sources \*/ = \{[^}]*files = \([^)]*', project_content, re.DOTALL)
    if sources_build_phase:
        insert_pos = sources_build_phase.end()
        source_entries = []
        for filepath, group, filename in files_to_add:
            uuids = file_uuids[filepath]
            source_entry = f'\n\t\t\t\t{uuids["build_file_uuid"]} /* {filename} in Sources */,'
            source_entries.append(source_entry)
        project_content = project_content[:insert_pos] + ''.join(source_entries) + project_content[insert_pos:]
        print(f"✅ Added {len(source_entries)} files to Sources build phase")

    # Add files to their respective groups
    for filepath, group, filename in files_to_add:
        if group in group_uuids:
            group_uuid = group_uuids[group]
            # Find the group's children array
            group_pattern = f'({group_uuid} /\\* {group.split("/")[-1]} \\*/ = {{[^}}]*children = \\([^)]*)'
            group_match = re.search(group_pattern, project_content, re.DOTALL)
            if group_match:
                insert_pos = group_match.end()
                file_ref_uuid = file_uuids[filepath]['file_ref_uuid']
                file_entry = f'\n\t\t\t\t{file_ref_uuid} /* {filename} */,'
                project_content = project_content[:insert_pos] + file_entry + project_content[insert_pos:]

    print(f"✅ Added files to their respective groups")

    # Backup original file
    backup_file = project_file + '.backup'
    with open(backup_file, 'w') as f:
        f.write(project_content)

    # Read original again and write modified version
    with open(project_file, 'r') as f:
        original = f.read()

    with open(project_file, 'w') as f:
        f.write(project_content)

    print(f"✅ Backup created: {backup_file}")
    print(f"✅ Updated: {project_file}")

    print("\n" + "=" * 60)
    print("✅ SUCCESS: All journal files added to Xcode project!")
    print("=" * 60)
    print("\nNext steps:")
    print("1. Build the project to verify")

if __name__ == '__main__':
    add_journal_files()
