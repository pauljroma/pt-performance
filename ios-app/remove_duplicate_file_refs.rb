#!/usr/bin/env ruby
require 'xcodeproj'

puts "Removing Duplicate File References"
puts "=" * 70

# Open the Xcode project
project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first
puts "Target: #{target.name}"

# Track files by their path
files_by_path = {}
duplicates_removed = 0

# First, collect all file references
puts "\nScanning for duplicate file references..."
project.files.each do |file_ref|
  next unless file_ref.path

  key = file_ref.path

  if files_by_path[key]
    files_by_path[key] << file_ref
  else
    files_by_path[key] = [file_ref]
  end
end

# Find and remove duplicates
files_by_path.each do |path, refs|
  if refs.count > 1
    puts "\nFound #{refs.count} references for: #{path}"

    # Keep the first one, remove the rest
    refs[1..-1].each do |duplicate_ref|
      puts "  Removing duplicate reference: #{duplicate_ref.uuid}"

      # Remove from build phase if present
      target.source_build_phase.files.each do |build_file|
        if build_file.file_ref == duplicate_ref
          target.source_build_phase.files.delete(build_file)
        end
      end

      # Remove the file reference
      duplicate_ref.remove_from_project
      duplicates_removed += 1
    end
  end
end

# Save the project
puts "\n\nSaving project..."
project.save

puts "=" * 70
puts "✅ Duplicate File References Removed!"
puts "=" * 70
puts "Total duplicates removed: #{duplicates_removed}"
puts "=" * 70
