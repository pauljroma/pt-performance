#!/usr/bin/env ruby
require 'xcodeproj'

project_path = '/Users/expo/pt-performance/ios-app/PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'PTPerformance' }
raise "Target 'PTPerformance' not found" unless target

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

files_to_add = [
  { path: 'ViewModels/EnrolledProgramsViewModel.swift', group: 'PTPerformance/ViewModels' },
  { path: 'Views/Programs/EnrolledProgramsSection.swift', group: 'PTPerformance/Views/Programs' }
]

base_path = '/Users/expo/pt-performance/ios-app/PTPerformance'

files_to_add.each do |file_info|
  full_path = File.join(base_path, file_info[:path])
  unless File.exist?(full_path)
    puts "⚠️  File not found: #{full_path}"
    next
  end
  filename = File.basename(file_info[:path])
  existing = project.main_group.recursive_children.find { |c|
    c.respond_to?(:path) && c.path && c.path.end_with?(filename)
  }
  if existing
    puts "✓ Already in project: #{file_info[:path]}"
    next
  end
  group = find_or_create_group(project, file_info[:group])
  file_ref = group.new_file(full_path)
  target.source_build_phase.add_file_reference(file_ref)
  puts "✅ Added: #{file_info[:path]}"
end

project.save
puts "\n✅ Project saved"
