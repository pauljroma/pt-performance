#!/usr/bin/env ruby
require 'xcodeproj'

project_path = '/Users/expo/Code/expo/ios-app/PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'PTPerformance' }

removed_count = 0

# Search all file references for the old path
project.files.each do |file_ref|
  if file_ref.path =~ /ProgramEditorView\.swift$/ && file_ref.real_path.to_s.include?('Views/ProgramEditorView.swift')
    puts "Found old file reference: #{file_ref.real_path}"

    # Remove from build phase
    target.source_build_phase.files.each do |build_file|
      if build_file.file_ref == file_ref
        target.source_build_phase.files.delete(build_file)
        puts "  ✅ Removed from build phase"
      end
    end

    # Remove file reference
    file_ref.remove_from_project
    puts "  ✅ Removed file reference"
    removed_count += 1
  end
end

if removed_count == 0
  puts "⚠️  No old ProgramEditorView.swift references found"
else
  puts "\n✅ Removed #{removed_count} reference(s)"
end

project.save
puts "✅ Project saved"
