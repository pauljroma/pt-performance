#!/usr/bin/env ruby
require 'xcodeproj'

puts "Removing problematic Build 72A files from build (keeping models)"
puts "=" * 70

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first

files_to_remove_from_build = [
  'LoggingService.swift',
  'HelpSearchView.swift'
]

removed_count = 0

files_to_remove_from_build.each do |filename|
  # Find all file references with this name
  file_refs = project.files.select { |f| f.path == filename || f.display_name == filename }

  file_refs.each do |file_ref|
    # Remove from build phase only (keep file reference)
    target.source_build_phase.files.each do |build_file|
      if build_file.file_ref == file_ref
        target.source_build_phase.files.delete(build_file)
        puts "✓ Removed from build: #{filename}"
        removed_count += 1
      end
    end
  end
end

if removed_count > 0
  project.save
  puts "\n✅ Removed #{removed_count} files from build phase"
  puts "Note: Files still exist on disk and in project, just not compiled"
else
  puts "\n⊘ No files were removed"
end

puts "=" * 70
