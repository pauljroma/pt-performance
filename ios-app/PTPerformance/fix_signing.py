#!/usr/bin/env python3
import re

# Read project file
with open("PTPerformance.xcodeproj/project.pbxproj", "r") as f:
    content = f.read()

# Find all buildConfigurations and set ProvisioningStyle to Manual
# and disable automatic code signing
content = re.sub(
    r'(buildSettings = \{[^}]*?)(CODE_SIGN_STYLE = Automatic;)',
    r'\1CODE_SIGN_STYLE = Manual;',
    content,
    flags=re.DOTALL
)

# Add Manual signing if CODE_SIGN_STYLE doesn't exist
content = re.sub(
    r'(buildSettings = \{(?![^}]*CODE_SIGN_STYLE))',
    r'\1\n\t\t\t\tCODE_SIGN_STYLE = Manual;',
    content
)

# Remove ProvisioningStyle = Automatic
content = re.sub(
    r'ProvisioningStyle = Automatic;?\s*',
    '',
    content
)

# Write back
with open("PTPerformance.xcodeproj/project.pbxproj", "w") as f:
    f.write(content)

print("Fixed code signing settings")
