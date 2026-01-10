#!/usr/bin/env ruby
require 'xcodeproj'

puts "Fixing All Duplicate Path References in Xcode Project"
puts "=" * 70

# Open the Xcode project
project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first
puts "Target: #{target.name}"

# Find all files with duplicated paths
puts "\nSearching for files with duplicated paths..."
duplicated_files = []

target.source_build_phase.files.each do |build_file|
  next unless build_file.file_ref
  path = build_file.file_ref.path

  # Check for patterns like "Models/Models/", "Views/Views/", etc.
  if path && (
    path.include?('ViewModels/ViewModels') ||
    path.include?('Models/Models') ||
    path.include?('Services/Services') ||
    path.include?('Views/Views') ||
    path.include?('Views/Articles/Views/Articles') ||
    path.include?('Views/Readiness/Views/Readiness') ||
    path.include?('Views/Scheduling/Views/Scheduling')
  )
    puts "Found: #{path}"
    duplicated_files << build_file
  end
end

puts "\nTotal duplicated path files found: #{duplicated_files.count}"

# Remove all duplicated path files
if duplicated_files.empty?
  puts "No duplicated paths found!"
else
  puts "\nRemoving duplicated path references..."
  duplicated_files.each do |build_file|
    path = build_file.file_ref.path
    # Remove from build phase
    target.source_build_phase.files.delete(build_file)
    # Remove file reference
    build_file.file_ref.remove_from_project
    puts "✓ Removed: #{path}"
  end
end

# Save the project
puts "\nSaving project..."
project.save

puts "=" * 70
puts "✅ All Duplicate Paths Removed!"
puts "=" * 70
puts "Removed: #{duplicated_files.count} file references"
puts ""
puts "Next: Re-run the integration scripts to add files with correct paths"
puts "=" * 70
