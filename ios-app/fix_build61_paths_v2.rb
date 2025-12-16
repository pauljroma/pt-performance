#!/usr/bin/env ruby
require 'xcodeproj'

# Open the Xcode project
project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

puts "Fixing Build 61 file paths (v2) in Xcode project..."

# Remove ALL references to our files
file_names = ['HelpArticle.swift', 'ContextualHelpButton.swift', 'HelpView.swift',
              'HelpCategoryView.swift', 'HelpArticleView.swift', 'HelpContent.json']

# Remove from build phases
target.source_build_phase.files.to_a.each do |build_file|
  if build_file.file_ref && file_names.any? { |fn| build_file.file_ref.path.to_s.include?(fn) }
    puts "Removing from sources: #{build_file.file_ref.path}"
    target.source_build_phase.files.delete(build_file)
  end
end

target.resources_build_phase.files.to_a.each do |build_file|
  if build_file.file_ref && file_names.any? { |fn| build_file.file_ref.path.to_s.include?(fn) }
    puts "Removing from resources: #{build_file.file_ref.path}"
    target.resources_build_phase.files.delete(build_file)
  end
end

# Remove from project tree
project.main_group.recursive_children.to_a.each do |item|
  if item.is_a?(Xcodeproj::Project::Object::PBXFileReference)
    if file_names.any? { |fn| item.path.to_s.include?(fn) }
      puts "Removing file reference: #{item.path}"
      item.remove_from_project
    end
  end
end

# Get or create groups
main_group = project.main_group
models_group = main_group['Models'] || main_group.new_group('Models', 'Models')
views_group = main_group['Views'] || main_group.new_group('Views', 'Views')
utils_group = main_group['Utils'] || main_group.new_group('Utils', 'Utils')
resources_group = main_group['Resources'] || main_group.new_group('Resources', 'Resources')
help_group = views_group['Help'] || views_group.new_group('Help', 'Views/Help')

# Add files with correct paths
files_to_add = [
  {
    file_name: 'HelpArticle.swift',
    path: 'Models/HelpArticle.swift',
    group: models_group
  },
  {
    file_name: 'ContextualHelpButton.swift',
    path: 'Utils/ContextualHelpButton.swift',
    group: utils_group
  },
  {
    file_name: 'HelpView.swift',
    path: 'Views/Help/HelpView.swift',
    group: help_group
  },
  {
    file_name: 'HelpCategoryView.swift',
    path: 'Views/Help/HelpCategoryView.swift',
    group: help_group
  },
  {
    file_name: 'HelpArticleView.swift',
    path: 'Views/Help/HelpArticleView.swift',
    group: help_group
  },
  {
    file_name: 'HelpContent.json',
    path: 'Resources/HelpContent.json',
    group: resources_group,
    is_resource: true
  }
]

files_to_add.each do |file_info|
  # Create file reference
  file_ref = file_info[:group].new_reference(file_info[:path])
  file_ref.source_tree = 'SOURCE_ROOT'

  if file_info[:is_resource]
    # Add to resources
    target.add_resources([file_ref])
    puts "✅ Added to resources: #{file_info[:file_name]}"
  else
    # Add to sources
    target.add_file_references([file_ref])
    puts "✅ Added to sources: #{file_info[:file_name]}"
  end
end

# Save the project
project.save

puts "\n🎉 Successfully fixed all file references!"
puts "Build 61: Help System file paths corrected (v2)."
