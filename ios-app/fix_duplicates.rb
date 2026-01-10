#!/usr/bin/env ruby
require 'xcodeproj'

puts "BUILD 96 - Remove Duplicate File References"
puts "=" * 70

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

removed_count = 0

puts "\nRemoving duplicate BUILD 96 files from build phase..."
puts "-" * 70

# Files that have duplicates
duplicate_files = ['PatientProfileView.swift', 'PatientProfileViewModel.swift', 'ExportService.swift']

duplicate_files.each do |file_name|
  # Find all build file references for this file
  build_files = target.source_build_phase.files.select do |bf|
    bf.file_ref && bf.file_ref.path == file_name
  end

  if build_files.count > 1
    # Keep only the first one, remove the rest
    build_files[1..-1].each do |bf|
      target.source_build_phase.files.delete(bf)
      removed_count += 1
    end
    puts "✓ Removed #{build_files.count - 1} duplicate(s) of #{file_name}"
  elsif build_files.count == 1
    puts "⊘ #{file_name} - no duplicates found"
  else
    puts "⚠ #{file_name} - not found in build phase"
  end
end

# Save the project
if removed_count > 0
  puts "\nSaving project..."
  project.save
  puts "✓ Project saved successfully"
end

puts "=" * 70
puts "BUILD 96 - Duplicate Removal Complete"
puts "=" * 70
puts "Duplicates removed: #{removed_count}"
puts "=" * 70

if removed_count > 0
  puts "\n✅ Duplicates cleaned successfully!"
  exit 0
else
  puts "\n⊘ No duplicates found"
  exit 0
end
