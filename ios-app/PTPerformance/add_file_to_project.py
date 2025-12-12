#!/usr/bin/env python3
"""Add SessionSummaryView.swift to Xcode project"""
import re
import uuid

project_file = "PTPerformance.xcodeproj/project.pbxproj"

# Read project
with open(project_file, "r") as f:
    content = f.read()

# Generate UUIDs for the new file
file_ref_uuid = str(uuid.uuid4()).replace('-', '')[:24].upper()
build_file_uuid = str(uuid.uuid4()).replace('-', '')[:24].upper()

file_path = "Views/Patient/SessionSummaryView.swift"

# Check if file already exists in project
if file_path in content or "SessionSummaryView.swift" in content:
    print(f"✅ {file_path} already in project")
    exit(0)

# Add PBXFileReference
file_ref_section = re.search(r'/\* Begin PBXFileReference section \*/(.*?)/\* End PBXFileReference section \*/', content, re.DOTALL)
if file_ref_section:
    file_ref_entry = f'\t\t{file_ref_uuid} /* SessionSummaryView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SessionSummaryView.swift; sourceTree = "<group>"; }};\n'
    insert_pos = file_ref_section.end() - len('/* End PBXFileReference section */')
    content = content[:insert_pos] + file_ref_entry + content[insert_pos:]

# Add PBXBuildFile
build_file_section = re.search(r'/\* Begin PBXBuildFile section \*/(.*?)/\* End PBXBuildFile section \*/', content, re.DOTALL)
if build_file_section:
    build_file_entry = f'\t\t{build_file_uuid} /* SessionSummaryView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* SessionSummaryView.swift */; }};\n'
    insert_pos = build_file_section.end() - len('/* End PBXBuildFile section */')
    content = content[:insert_pos] + build_file_entry + content[insert_pos:]

# Add to PBXSourcesBuildPhase (find PTPerformance target's sources)
sources_section = re.search(r'(.*?isa = PBXSourcesBuildPhase;.*?files = \()(.*?)(\);)', content, re.DOTALL)
if sources_section:
    sources_entry = f'\t\t\t\t{build_file_uuid} /* SessionSummaryView.swift in Sources */,\n'
    insert_pos = sources_section.end(2)
    content = content[:insert_pos] + sources_entry + content[insert_pos:]

# Add to PBXGroup (Views/Patient group)
# Find or create Views/Patient group
patient_group = re.search(r'([A-F0-9]{24}) /\* Patient \*/ = \{.*?children = \((.*?)\);', content, re.DOTALL)
if patient_group:
    # Add to existing Patient group
    children_entry = f'\t\t\t\t{file_ref_uuid} /* SessionSummaryView.swift */,\n'
    insert_pos = patient_group.end(2) - 1  # Before the closing paren
    content = content[:insert_pos] + children_entry + content[insert_pos:]
else:
    print("⚠️  Warning: Patient group not found, adding to Views group instead")
    views_group = re.search(r'([A-F0-9]{24}) /\* Views \*/ = \{.*?children = \((.*?)\);', content, re.DOTALL)
    if views_group:
        children_entry = f'\t\t\t\t{file_ref_uuid} /* SessionSummaryView.swift */,\n'
        insert_pos = views_group.end(2) - 1
        content = content[:insert_pos] + children_entry + content[insert_pos:]

# Write back
with open(project_file, "w") as f:
    f.write(content)

print(f"✅ Added {file_path} to Xcode project")
print(f"   File Ref: {file_ref_uuid}")
print(f"   Build File: {build_file_uuid}")
