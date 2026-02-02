#!/usr/bin/env ruby
# ACP-827: Add Apple Health Deep Sync files to Xcode project

require 'xcodeproj'

project_path = 'PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'PTPerformance' }

# Files to add
files_to_add = [
  { path: 'Models/HealthSyncConfig.swift', group: 'Models' },
  { path: 'Services/HealthSyncManager.swift', group: 'Services' },
  { path: 'Views/Settings/HealthSyncSettingsView.swift', group: 'Views/Settings' },
  { path: 'Views/HealthKit/HealthSyncStatusView.swift', group: 'Views/HealthKit' }
]

files_to_add.each do |file_info|
  file_path = file_info[:path]
  group_path = file_info[:group]

  # Check if file exists
  unless File.exist?(file_path)
    puts "⚠️  File not found: #{file_path}"
    next
  end

  # Find or create the group
  group = project.main_group
  group_path.split('/').each do |part|
    child = group.children.find { |c| c.display_name == part }
    if child
      group = child
    else
      group = group.new_group(part, part)
    end
  end

  # Check if file already exists in project
  existing = group.files.find { |f| f.path == File.basename(file_path) }
  if existing
    puts "✓ Already in project: #{file_path}"
    next
  end

  # Add file reference
  file_ref = group.new_reference(File.basename(file_path))
  file_ref.last_known_file_type = 'sourcecode.swift'

  # Add to target
  target.source_build_phase.add_file_reference(file_ref)

  puts "✅ Added: #{file_path}"
end

project.save
puts "\n✅ Project saved successfully"
