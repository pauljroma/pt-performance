#!/usr/bin/env ruby
require 'xcodeproj'

# Open the Xcode project
project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

puts "Fixing Build 61 file paths in Xcode project..."

# Remove old incorrect references
files_to_remove = [
  'PTPerformance/Models/HelpArticle.swift',
  'PTPerformance/Utils/ContextualHelpButton.swift',
  'PTPerformance/Views/Help/HelpView.swift',
  'PTPerformance/Views/Help/HelpCategoryView.swift',
  'PTPerformance/Views/Help/HelpArticleView.swift',
  'PTPerformance/Resources/HelpContent.json'
]

files_to_remove.each do |file_path|
  file_name = File.basename(file_path)
  target.source_build_phase.files.each do |build_file|
    if build_file.file_ref && build_file.file_ref.path && build_file.file_ref.path.include?(file_name)
      puts "Removing old reference: #{build_file.file_ref.path}"
      target.source_build_phase.files.delete(build_file)
    end
  end

  # Also remove from resources if present
  target.resources_build_phase.files.each do |build_file|
    if build_file.file_ref && build_file.file_ref.path && build_file.file_ref.path.include?(file_name)
      puts "Removing old resource reference: #{build_file.file_ref.path}"
      target.resources_build_phase.files.delete(build_file)
    end
  end
end

# Remove from groups
project.main_group.recursive_children.each do |item|
  if item.is_a?(Xcodeproj::Project::Object::PBXFileReference)
    files_to_remove.each do |file_path|
      file_name = File.basename(file_path)
      if item.path == file_path || item.path == file_name
        puts "Removing file reference from group: #{item.path}"
        item.remove_from_project
      end
    end
  end
end

# Now add files with correct paths
main_group = project.main_group

models_group = main_group['Models'] || main_group.new_group('Models')
views_group = main_group['Views'] || main_group.new_group('Views')
utils_group = main_group['Utils'] || main_group.new_group('Utils')
resources_group = main_group['Resources'] || main_group.new_group('Resources')
help_group = views_group['Help'] || views_group.new_group('Help')

files_to_add = [
  {
    path: 'Models/HelpArticle.swift',
    group: models_group,
    add_to_target: true
  },
  {
    path: 'Utils/ContextualHelpButton.swift',
    group: utils_group,
    add_to_target: true
  },
  {
    path: 'Views/Help/HelpView.swift',
    group: help_group,
    add_to_target: true
  },
  {
    path: 'Views/Help/HelpCategoryView.swift',
    group: help_group,
    add_to_target: true
  },
  {
    path: 'Views/Help/HelpArticleView.swift',
    group: help_group,
    add_to_target: true
  },
  {
    path: 'Resources/HelpContent.json',
    group: resources_group,
    add_to_target: false,  # Will add to resources phase instead
    is_resource: true
  }
]

added_count = 0

files_to_add.each do |file_info|
  file_path = file_info[:path]
  group = file_info[:group]

  # Check if already exists
  file_name = File.basename(file_path)
  existing = group.files.find { |f| f.path == file_name }

  if existing
    puts "File already in group: #{file_name}"
    next
  end

  # Add file reference
  file_ref = group.new_reference(file_name)
  file_ref.source_tree = '<group>'

  if file_info[:add_to_target]
    target.add_file_references([file_ref])
    puts "✅ Added to sources: #{file_name}"
  elsif file_info[:is_resource]
    target.add_resources([file_ref])
    puts "✅ Added to resources: #{file_name}"
  end

  added_count += 1
end

# Save the project
project.save

puts "\n🎉 Successfully fixed #{added_count} file references!"
puts "Build 61: Help System file paths corrected."
