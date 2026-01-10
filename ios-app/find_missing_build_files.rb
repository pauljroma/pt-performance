#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first

# Get all Swift file references
swift_files = project.files.select { |f| f.path&.end_with?('.swift') }

# Check which ones are NOT in the build phase
missing = []

swift_files.each do |file_ref|
  in_build = target.source_build_phase.files.any? { |bf| bf.file_ref == file_ref }

  unless in_build
    missing << file_ref.path
  end
end

if missing.empty?
  puts "All Swift files are in the build phase!"
else
  puts "Files missing from build phase:"
  puts "=" * 70
  missing.sort.each do |path|
    puts "  #{path}"
  end
  puts "=" * 70
  puts "Total: #{missing.count} files"
end
