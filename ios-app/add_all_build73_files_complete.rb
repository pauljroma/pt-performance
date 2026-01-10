#!/usr/bin/env ruby
require 'xcodeproj'

puts "BUILD 73 - Adding All Missing Files to Xcode Project"
puts "=" * 70

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first
main_group = project.main_group['PTPerformance'] || project.main_group.new_group('PTPerformance')

# Get or create groups
models_group = main_group['Models'] || main_group.new_group('Models')
models_group.path = 'Models'

services_group = main_group['Services'] || main_group.new_group('Services')
services_group.path = 'Services'

viewmodels_group = main_group['ViewModels'] || main_group.new_group('ViewModels')
viewmodels_group.path = 'ViewModels'

views_group = main_group['Views'] || main_group.new_group('Views')
views_group.path = 'Views'

# Create Articles subgroup under Views
articles_group = views_group['Articles'] || views_group.new_group('Articles')
articles_group.path = 'Articles'

# Create Onboarding subgroup under Views
onboarding_group = views_group['Onboarding'] || views_group.new_group('Onboarding')
onboarding_group.path = 'Onboarding'

# Define all files to add with their groups
files_to_add = [
  # Root level
  { group: main_group, file: 'SentryConfig.swift', path: 'PTPerformance/SentryConfig.swift' },

  # Models
  { group: models_group, file: 'ContentItem.swift', path: 'PTPerformance/Models/ContentItem.swift' },

  # Services
  { group: services_group, file: 'OnboardingCoordinator.swift', path: 'PTPerformance/Services/OnboardingCoordinator.swift' },
  { group: services_group, file: 'SupabaseManager.swift', path: 'PTPerformance/Services/SupabaseManager.swift' },

  # ViewModels
  { group: viewmodels_group, file: 'ArticlesViewModel.swift', path: 'PTPerformance/ViewModels/ArticlesViewModel.swift' },

  # Views - Articles
  { group: articles_group, file: 'ArticleBrowseView.swift', path: 'PTPerformance/Views/Articles/ArticleBrowseView.swift' },
  { group: articles_group, file: 'ArticleDetailView.swift', path: 'PTPerformance/Views/Articles/ArticleDetailView.swift' },

  # Views - Onboarding
  { group: onboarding_group, file: 'OnboardingView.swift', path: 'PTPerformance/Views/Onboarding/OnboardingView.swift' },
  { group: onboarding_group, file: 'OnboardingPage.swift', path: 'PTPerformance/Views/Onboarding/OnboardingPage.swift' },
]

added_count = 0
skipped_count = 0
error_count = 0

files_to_add.each do |file_info|
  file_name = file_info[:file]
  full_path = file_info[:path]

  # Check if file exists on disk
  unless File.exist?(full_path)
    puts "✗ File not found on disk: #{full_path}"
    error_count += 1
    next
  end

  # Check if file reference already exists
  existing_ref = project.files.find { |f| f.path == file_name || f.real_path.to_s.end_with?(file_name) }

  if existing_ref
    # Check if it's in the build phase
    in_build = target.source_build_phase.files.any? { |bf| bf.file_ref == existing_ref }

    if in_build
      puts "⊘ Already in project and build: #{file_name}"
      skipped_count += 1
    else
      # Add to build phase
      target.source_build_phase.add_file_reference(existing_ref)
      puts "✓ Added to build phase: #{file_name}"
      added_count += 1
    end
  else
    # Create new file reference
    begin
      file_ref = file_info[:group].new_file(file_name)

      # Add to build phase
      target.source_build_phase.add_file_reference(file_ref)

      puts "✓ Added new file: #{file_name}"
      added_count += 1
    rescue => e
      puts "✗ Error adding #{file_name}: #{e.message}"
      error_count += 1
    end
  end
end

# Save the project
if added_count > 0
  puts "\nSaving project..."
  project.save
end

puts "=" * 70
puts "BUILD 73 File Integration Complete"
puts "=" * 70
puts "Files added: #{added_count}"
puts "Files skipped: #{skipped_count}"
puts "Errors: #{error_count}"
puts "=" * 70

if error_count == 0
  puts "\n✅ All files successfully integrated!"
  exit 0
else
  puts "\n⚠️  Some errors occurred. Please review above."
  exit 1
end
