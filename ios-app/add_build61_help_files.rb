#!/usr/bin/env ruby
require 'xcodeproj'

# Open the Xcode project
project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Get the main group
main_group = project.main_group

# Find or create groups
models_group = main_group['Models'] || main_group.new_group('Models')
views_group = main_group['Views'] || main_group.new_group('Views')
utils_group = main_group['Utils'] || main_group.new_group('Utils')
resources_group = main_group['Resources'] || main_group.new_group('Resources')

# Create Help subgroup under Views
help_group = views_group['Help'] || views_group.new_group('Help')

puts "Adding Build 61 Help System files to Xcode project..."

# Files to add (relative to Views, Models, Utils, Resources groups)
files_to_add = [
  {
    path: 'Models/HelpArticle.swift',
    group: models_group,
    target: true
  },
  {
    path: 'Utils/ContextualHelpButton.swift',
    group: utils_group,
    target: true
  },
  {
    path: 'Views/Help/HelpView.swift',
    group: help_group,
    target: true
  },
  {
    path: 'Views/Help/HelpCategoryView.swift',
    group: help_group,
    target: true
  },
  {
    path: 'Views/Help/HelpArticleView.swift',
    group: help_group,
    target: true
  },
  {
    path: 'Resources/HelpContent.json',
    group: resources_group,
    target: false  # JSON file should not be in compile phase
  }
]

added_count = 0

files_to_add.each do |file_info|
  file_path = file_info[:path]
  group = file_info[:group]

  # Check if file already exists in project
  existing = group.files.find { |f| f.path == File.basename(file_path) }

  if existing
    puts "⚠️  File already exists in project: #{file_path}"
    next
  end

  # Check if file exists on disk
  unless File.exist?(file_path)
    puts "❌ File not found on disk: #{file_path}"
    next
  end

  # Add file reference
  file_ref = group.new_file(file_path)

  # Add to target if specified
  if file_info[:target]
    target.add_file_references([file_ref])
  end

  puts "✅ Added: #{file_path}"
  added_count += 1
end

# Save the project
project.save

puts "\n🎉 Successfully added #{added_count} files to the Xcode project!"
puts "Build 61: Help System integration complete."
