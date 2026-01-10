#!/usr/bin/env ruby
require 'xcodeproj'

puts "Removing incompatible Build 72A Logging view files from Xcode project"
puts "=" * 70

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first

files_to_remove = [
  'BlockCard.swift',
  'BlockHeader.swift',
  'BlockItemRow.swift',
  'QuickMetricsSummary.swift'
]

removed_count = 0

files_to_remove.each do |filename|
  # Find the file reference
  file_ref = project.files.find { |f| f.path == filename || f.display_name == filename }

  if file_ref
    # Remove from build phase
    target.source_build_phase.files.each do |build_file|
      if build_file.file_ref == file_ref
        target.source_build_phase.files.delete(build_file)
      end
    end

    # Remove file reference
    file_ref.remove_from_project

    puts "✓ Removed: #{filename}"
    removed_count += 1
  else
    puts "⊘ Not found: #{filename}"
  end
end

if removed_count > 0
  project.save
  puts "\n✅ Removed #{removed_count} file references from Xcode project"
else
  puts "\n⊘ No files were removed"
end

puts "=" * 70
