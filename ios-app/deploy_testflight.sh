#!/bin/bash
set -e

echo "🚀 PTPerformance - TestFlight Deployment"
echo "=========================================="

cd /Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance

# Step 1: Add Swift files to Xcode project
echo "📝 Adding Swift files to Xcode project..."

cat > add_files.rb << 'RUBY'
#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Models
models_group = project.main_group.find_subpath('Models', true)
models_files = ['Protocol.swift', 'WorkloadFlag.swift']
models_files.each do |file|
  next if models_group.files.any? { |f| f.path == file }
  file_ref = models_group.new_reference(file)
  target.add_file_references([file_ref])
end

# Components
components_group = project.main_group.find_subpath('Components', true)
components_files = ['ProtocolSelector.swift', 'StrengthTargetsCard.swift', 'WorkloadFlagBanner.swift']
components_files.each do |file|
  next if components_group.files.any? { |f| f.path == file }
  file_ref = components_group.new_reference(file)
  target.add_file_references([file_ref])
end

# Views
views_group = project.main_group.find_subpath('Views', true)
views_files = ['ProgramBuilderView.swift', 'ProgramEditorView.swift']
views_files.each do |file|
  next if views_group.files.any? { |f| f.path == file }
  file_ref = views_group.new_reference(file)
  target.add_file_references([file_ref])
end

# ViewModels
viewmodels_group = project.main_group.find_subpath('ViewModels', true)
viewmodels_files = ['ProgramBuilderViewModel.swift', 'ProgramEditorViewModel.swift', 'PatientListViewModel.swift']
viewmodels_files.each do |file|
  next if viewmodels_group.files.any? { |f| f.path == file }
  file_ref = viewmodels_group.new_reference(file)
  target.add_file_references([file_ref])
end

# Root files
root_files = ['TherapistDashboardView.swift']
root_files.each do |file|
  next if project.main_group.files.any? { |f| f.path == file }
  file_ref = project.main_group.new_reference(file)
  target.add_file_references([file_ref])
end

project.save
puts "✅ Xcode project updated"
RUBY

# Check if xcodeproj gem is installed
if ! gem list xcodeproj -i > /dev/null 2>&1; then
  echo "Installing xcodeproj gem..."
  gem install xcodeproj
fi

ruby add_files.rb
rm add_files.rb

# Step 2: Create export options
echo "📄 Creating export options..."

cat > exportOptions.plist << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
</dict>
</plist>
PLIST

# Step 3: Check prerequisites
echo ""
echo "🔍 Checking prerequisites..."

# Find scheme name
SCHEME=$(xcodebuild -list -project PTPerformance.xcodeproj | grep -A 1 "Schemes:" | tail -1 | xargs)
echo "   Scheme: $SCHEME"

# Get team ID
TEAM_ID=$(security find-identity -v -p codesigning | grep "Apple Development" | head -1 | grep -o '([A-Z0-9]\{10\})' | tr -d '()')
if [ -z "$TEAM_ID" ]; then
    echo "⚠️  No code signing identity found. You may need to sign in to Xcode with your Apple ID."
    echo "   Run: xcodebuild -showBuildSettings | grep DEVELOPMENT_TEAM"
    exit 1
fi
echo "   Team ID: $TEAM_ID"

# Update exportOptions with real team ID
sed -i '' "s/YOUR_TEAM_ID/$TEAM_ID/g" exportOptions.plist

# Step 4: Clean and build
echo ""
echo "🧹 Cleaning build folder..."
rm -rf build/
mkdir -p build/

echo "🔨 Building archive..."
xcodebuild clean archive \
  -project PTPerformance.xcodeproj \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath build/PTPerformance.xcarchive \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  | xcpretty || xcodebuild clean archive \
    -project PTPerformance.xcodeproj \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath build/PTPerformance.xcarchive

echo "✅ Archive created: build/PTPerformance.xcarchive"

# Step 5: Export IPA
echo ""
echo "📦 Exporting IPA..."
xcodebuild -exportArchive \
  -archivePath build/PTPerformance.xcarchive \
  -exportPath build/ \
  -exportOptionsPlist exportOptions.plist \
  | xcpretty || xcodebuild -exportArchive \
    -archivePath build/PTPerformance.xcarchive \
    -exportPath build/ \
    -exportOptionsPlist exportOptions.plist

echo "✅ IPA created: build/PTPerformance.ipa"

# Step 6: Upload to TestFlight
echo ""
echo "🚀 Uploading to TestFlight..."
echo ""
echo "You have two options:"
echo ""
echo "Option 1: Using xcrun altool (requires app-specific password)"
echo "----------------------------------------"
echo "xcrun altool --upload-app \\"
echo "  --type ios \\"
echo "  --file build/PTPerformance.ipa \\"
echo "  --username your-apple-id@email.com \\"
echo "  --password your-app-specific-password"
echo ""
echo "Option 2: Using Transporter app"
echo "----------------------------------------"
echo "1. Open Transporter app"
echo "2. Drag build/PTPerformance.ipa into it"
echo "3. Click 'Deliver'"
echo ""
echo "Option 3: Using xcrun (if you have Xcode Cloud)"
echo "----------------------------------------"
echo "xcrun notarytool submit build/PTPerformance.ipa \\"
echo "  --apple-id your-apple-id@email.com \\"
echo "  --team-id $TEAM_ID \\"
echo "  --password your-app-specific-password"
echo ""
echo "=========================================="
echo "✅ Build complete!"
echo "📱 IPA ready at: build/PTPerformance.ipa"
echo ""

ls -lh build/PTPerformance.ipa 2>/dev/null || echo "⚠️  IPA not found - check build logs above"
