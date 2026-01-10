#!/usr/bin/env ruby
require 'xcodeproj'

puts "BUILD 72B - Adding Article Browsing UI Files"
puts "=" * 70

# Open the Xcode project
project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first
puts "Target: #{target.name}"

# Get or create the PTPerformance group (main group)
main_group = project.main_group['PTPerformance'] || project.main_group.new_group('PTPerformance')

# Create or get groups
models_group = main_group['Models'] || main_group.new_group('Models')
viewmodels_group = main_group['ViewModels'] || main_group.new_group('ViewModels')
services_group = main_group['Services'] || main_group.new_group('Services')
views_group = main_group['Views'] || main_group.new_group('Views')
articles_views_group = views_group['Articles'] || views_group.new_group('Articles')

# Set group paths
models_group.path = 'Models'
viewmodels_group.path = 'ViewModels'
services_group.path = 'Services'
views_group.path = 'Views'
articles_views_group.path = 'Articles'

# Define all files to add
files_to_add = [
  # Models
  { group: models_group, file: 'Models/ContentItem.swift', compile: true },

  # ViewModels
  { group: viewmodels_group, file: 'ViewModels/ArticlesViewModel.swift', compile: true },

  # Services
  { group: services_group, file: 'Services/SupabaseManager.swift', compile: true },

  # Views - Articles
  { group: articles_views_group, file: 'Views/Articles/ArticleBrowseView.swift', compile: true },
  { group: articles_views_group, file: 'Views/Articles/ArticleDetailView.swift', compile: true },
]

added_count = 0
skipped_count = 0
error_count = 0

files_to_add.each do |file_info|
  file_path = file_info[:file]
  full_path = "PTPerformance/#{file_path}"

  if File.exist?(full_path)
    begin
      # Check if file already exists in project
      existing_ref = file_info[:group].files.find { |f| f.path == File.basename(file_path) }

      if existing_ref
        puts "⊘ Skipped #{file_path} (already in project)"
        skipped_count += 1
      else
        # Add file reference
        file_ref = file_info[:group].new_file(file_path)

        # Add to appropriate build phase
        if file_info[:compile]
          target.source_build_phase.add_file_reference(file_ref)
          puts "✓ Added #{file_path} (source)"
        end

        added_count += 1
      end
    rescue => e
      puts "✗ Error adding #{file_path}: #{e.message}"
      error_count += 1
    end
  else
    puts "✗ File not found: #{full_path}"
    error_count += 1
  end
end

# Save the project
puts "\nSaving project..."
project.save

puts "=" * 70
puts "BUILD 72B Article Files Integration Complete!"
puts "=" * 70
puts "Files added: #{added_count}"
puts "Files skipped: #{skipped_count}"
puts "Errors: #{error_count}"
puts ""
puts "New Files:"
puts "  • Models/ContentItem.swift"
puts "  • ViewModels/ArticlesViewModel.swift"
puts "  • Services/SupabaseManager.swift"
puts "  • Views/Articles/ArticleBrowseView.swift"
puts "  • Views/Articles/ArticleDetailView.swift"
puts "=" * 70

if error_count == 0
  puts "\n✅ All article browsing files successfully added to Xcode project!"
  puts "\n⚠️  NEXT STEP: Add MarkdownUI package dependency in Xcode"
  puts "   File → Add Package Dependencies"
  puts "   URL: https://github.com/gonzalezreal/swift-markdown-ui"
  exit 0
else
  puts "\n⚠️  Some files could not be added. Please review errors above."
  exit 1
end
