#!/usr/bin/env ruby
# Add Program Library files to Xcode project

require 'xcodeproj'

project_path = '/Users/expo/pt-performance/ios-app/PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == 'PTPerformance' }
raise "Target 'PTPerformance' not found" unless target

# Find or create groups
def find_or_create_group(project, path)
  components = path.split('/')
  current_group = project.main_group

  components.each do |component|
    found = current_group.children.find { |c| c.respond_to?(:name) && c.name == component }
    if found
      current_group = found
    else
      current_group = current_group.new_group(component)
    end
  end

  current_group
end

# Files to add
files_to_add = [
  { path: 'Models/ProgramLibrary.swift', group: 'PTPerformance/Models' },
  { path: 'Models/ProgramEnrollment.swift', group: 'PTPerformance/Models' },
  { path: 'Services/ProgramLibraryService.swift', group: 'PTPerformance/Services' },
  { path: 'ViewModels/ProgramLibraryBrowserViewModel.swift', group: 'PTPerformance/ViewModels' },
  { path: 'Views/Programs/ProgramLibraryBrowserView.swift', group: 'PTPerformance/Views/Programs' },
  { path: 'Views/Programs/ProgramDetailSheet.swift', group: 'PTPerformance/Views/Programs' }
]

base_path = '/Users/expo/pt-performance/ios-app/PTPerformance'

files_to_add.each do |file_info|
  full_path = File.join(base_path, file_info[:path])

  unless File.exist?(full_path)
    puts "⚠️  File not found: #{full_path}"
    next
  end

  # Check if filename already in project (simpler check)
  filename = File.basename(file_info[:path])
  existing = project.main_group.recursive_children.find { |c|
    c.respond_to?(:path) && c.path && c.path.end_with?(filename)
  }
  if existing
    puts "✓ Already in project: #{file_info[:path]}"
    next
  end

  # Find or create the group
  group = find_or_create_group(project, file_info[:group])

  # Add file reference
  file_ref = group.new_file(full_path)

  # Add to target's compile sources
  target.source_build_phase.add_file_reference(file_ref)

  puts "✅ Added: #{file_info[:path]}"
end

project.save
puts "\n✅ Project saved successfully"
