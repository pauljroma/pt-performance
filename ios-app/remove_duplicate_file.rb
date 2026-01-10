#!/usr/bin/env ruby
require 'xcodeproj'

project_path = '/Users/expo/Code/expo/ios-app/PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'PTPerformance' }

# Find the old ProgramEditorView.swift in Views group
views_group = project.main_group['Views']
if views_group
  old_file = views_group.files.find { |f| f.path == 'ProgramEditorView.swift' }

  if old_file
    # Remove from target
    target.source_build_phase.files.each do |build_file|
      if build_file.file_ref == old_file
        target.source_build_phase.files.delete(build_file)
        puts "✅ Removed ProgramEditorView.swift from build phase"
      end
    end

    # Remove file reference
    old_file.remove_from_project
    puts "✅ Removed ProgramEditorView.swift from Xcode project"
  else
    puts "⚠️ File not found in Xcode project"
  end
else
  puts "❌ Views group not found"
end

project.save
puts "✅ Project saved"
