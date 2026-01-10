#!/usr/bin/env ruby
require 'xcodeproj'

project = Xcodeproj::Project.open('PTPerformance.xcodeproj')
target = project.targets.first

# BUILD 119 files with correct paths
files_to_add = [
  'Services/SessionManager.swift',
  'Services/SecurityMonitor.swift',
  'ViewModels/AccountDeletionViewModel.swift',
  'Views/Settings/AccountDeletionView.swift',
  'Views/Onboarding/PrivacyNoticeView.swift'
]

added = 0
fixed = 0

files_to_add.each do |rel_path|
  full_path = File.join(Dir.pwd, rel_path)

  unless File.exist?(full_path)
    puts "⚠️  File not found: #{rel_path}"
    next
  end

  # Determine group path
  group_path = case rel_path
               when /^Services\// then 'PTPerformance/Services'
               when /^ViewModels\// then 'PTPerformance/ViewModels'
               when /^Views\/Settings\// then 'PTPerformance/Views/Settings'
               when /^Views\/Onboarding\// then 'PTPerformance/Views/Onboarding'
               else 'PTPerformance'
               end

  group = project.main_group.find_subpath(group_path, true)
  basename = File.basename(full_path)

  # Find and remove any incorrect references
  to_remove = []
  project.main_group.recursive_children.each do |item|
    if item.is_a?(Xcodeproj::Project::Object::PBXFileReference) && item.path == basename
      # If it's not in the correct group, mark for removal
      if item.parent != group
        to_remove << item
      end
    end
  end

  to_remove.each do |item|
    puts "🔧 Removing incorrect reference: #{item.path}"
    target.source_build_phase.remove_file_reference(item)
    item.remove_from_project
    fixed += 1
  end

  # Check if correct reference exists
  existing = group.files.find { |f| f.path == basename }
  if existing
    puts "✅ Already correct: #{rel_path}"
    next
  end

  # Add correct reference
  file_ref = group.new_reference(full_path)
  target.add_file_references([file_ref])
  puts "✅ Added: #{rel_path}"
  added += 1
end

project.save
puts "\n✓ Project saved"
puts "  🔧 Fixed: #{fixed} incorrect references"
puts "  ✅ Added: #{added} new references"
