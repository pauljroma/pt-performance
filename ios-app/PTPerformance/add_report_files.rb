#!/usr/bin/env ruby
# Add PDF Report Generation files to Xcode project

require 'xcodeproj'

project_path = 'PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get main target
target = project.targets.find { |t| t.name == 'PTPerformance' }

# Files to add with their relative paths
files_to_add = [
  'Models/ReportTemplate.swift',
  'Utils/PDFGenerator.swift',
  'Services/ReportGenerationService.swift',
  'Views/Reports/ReportBuilderView.swift',
  'Views/Reports/ReportPreviewView.swift'
]

# Find or create groups
def find_or_create_group(project, path_components, parent_group = nil)
  parent = parent_group || project.main_group

  path_components.each do |component|
    group = parent.children.find { |g| g.respond_to?(:name) && g.name == component }
    if group.nil?
      group = parent.new_group(component)
      puts "Created group: #{component}"
    end
    parent = group
  end

  parent
end

added_count = 0

files_to_add.each do |relative_path|
  full_path = File.expand_path(relative_path)

  unless File.exist?(full_path)
    puts "SKIP: File not found: #{relative_path}"
    next
  end

  # Check if already in project
  existing = project.files.find { |f| f.path&.end_with?(File.basename(relative_path)) }
  if existing
    puts "SKIP: Already in project: #{relative_path}"
    next
  end

  # Get directory components
  dir_components = File.dirname(relative_path).split('/')

  # Find or create group
  group = find_or_create_group(project, dir_components)

  # Add file reference
  file_ref = group.new_file(full_path)

  # Add to target's compile sources
  target.source_build_phase.add_file_reference(file_ref)

  puts "ADDED: #{relative_path}"
  added_count += 1
end

# Save project
project.save

puts "\n✅ Added #{added_count} files to Xcode project"
