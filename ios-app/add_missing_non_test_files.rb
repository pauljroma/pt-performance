#!/usr/bin/env ruby
require 'xcodeproj'

puts "Adding Missing Non-Test Files to Build Phase"
puts "=" * 70

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first

# Get all Swift file references
swift_files = project.files.select { |f| f.path&.end_with?('.swift') }

# Find missing files (excluding Tests)
missing = []

swift_files.each do |file_ref|
  next if file_ref.path.nil?
  next if file_ref.path.start_with?('Tests/') # Skip test files for main target

  in_build = target.source_build_phase.files.any? { |bf| bf.file_ref == file_ref }

  unless in_build
    missing << file_ref
  end
end

if missing.empty?
  puts "All non-test Swift files are already in the build phase!"
else
  puts "Adding #{missing.count} files to build phase..."

  added = 0
  missing.each do |file_ref|
    target.source_build_phase.add_file_reference(file_ref)
    puts "  ✓ #{file_ref.path}"
    added += 1
  end

  project.save
  puts "\n" + "=" * 70
  puts "✅ Added #{added} files to build phase!"
  puts "=" * 70
end
