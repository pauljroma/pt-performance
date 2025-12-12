#!/usr/bin/env python3
"""Properly add SessionSummaryView.swift to Xcode project"""
import re
import uuid

project_file = "PTPerformance.xcodeproj/project.pbxproj"

with open(project_file, "r") as f:
    content = f.read()

# Check if already added
if "SessionSummaryView.swift" in content:
    print("✅ SessionSummaryView.swift already in project")
    exit(0)

# Generate UUIDs
file_ref_uuid = "A1B2C3D4E5F6789012345678"
build_file_uuid = "9876543210FEDCBA98765432"

# 1. Add PBXFileReference
file_ref = f'\t\t{file_ref_uuid} /* SessionSummaryView.swift */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = SessionSummaryView.swift; sourceTree = "<group>"; }};\n'
content = re.sub(
    r'(/\* End PBXFileReference section \*/)',
    file_ref + r'\1',
    content
)

# 2. Add PBXBuildFile
build_file = f'\t\t{build_file_uuid} /* SessionSummaryView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* SessionSummaryView.swift */; }};\n'
content = re.sub(
    r'(/\* End PBXBuildFile section \*/)',
    build_file + r'\1',
    content
)

# 3. Add to PBXSourcesBuildPhase
# Find the Sources build phase and add our file
sources_match = re.search(
    r'(/\* Sources \*/ = \{[^}]*files = \(\s*)(.*?)(\s*\);)',
    content,
    re.DOTALL
)
if sources_match:
    sources_list = sources_match.group(2)
    new_sources = sources_list + f'\n\t\t\t\t{build_file_uuid} /* SessionSummaryView.swift in Sources */,'
    content = content[:sources_match.start(2)] + new_sources + content[sources_match.end(2):]

# 4. Add to Views/Patient group
# First, find or create the Patient group
patient_group_match = re.search(
    r'([A-F0-9]{24}) /\* Patient \*/ = \{\s*isa = PBXGroup;\s*children = \(\s*(.*?)\s*\);',
    content,
    re.DOTALL
)

if patient_group_match:
    # Add to existing Patient group
    children = patient_group_match.group(2)
    new_children = children + f'\n\t\t\t\t{file_ref_uuid} /* SessionSummaryView.swift */,'
    content = content[:patient_group_match.start(2)] + new_children + content[patient_group_match.end(2):]
else:
    # Find Views group and add file there
    print("⚠️  Patient group not found, searching for Views group...")
    views_match = re.search(
        r'([A-F0-9]{24}) /\* Views \*/ = \{\s*isa = PBXGroup;\s*children = \(\s*(.*?)\s*\);',
        content,
        re.DOTALL
    )
    if views_match:
        children = views_match.group(2)
        new_children = children + f'\n\t\t\t\t{file_ref_uuid} /* SessionSummaryView.swift */,'
        content = content[:views_match.start(2)] + new_children + content[views_match.end(2):]

with open(project_file, "w") as f:
    f.write(content)

print(f"✅ Added SessionSummaryView.swift to Xcode project")
print(f"   File Ref: {file_ref_uuid}")
print(f"   Build File: {build_file_uuid}")
