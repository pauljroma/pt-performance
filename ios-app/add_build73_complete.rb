#!/usr/bin/env ruby
require 'xcodeproj'

puts "BUILD 73 - Complete Integration (72A + 72B)"
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

data_group = main_group['Data'] || main_group.new_group('Data')
data_group.path = 'Data'

tests_group = main_group['Tests'] || main_group.new_group('Tests')
tests_group.path = 'Tests'

# Create subgroups
articles_group = views_group['Articles'] || views_group.new_group('Articles')
articles_group.path = 'Articles'

onboarding_group = views_group['Onboarding'] || views_group.new_group('Onboarding')
onboarding_group.path = 'Onboarding'

help_group = views_group['Help'] || views_group.new_group('Help')
help_group.path = 'Help'

logging_group = views_group['Logging'] || views_group.new_group('Logging')
logging_group.path = 'Logging'

unit_tests_group = tests_group['Unit'] || tests_group.new_group('Unit')
unit_tests_group.path = 'Unit'

# Define all Build 73 files (72A + 72B)
files_to_add = [
  # Root level - Build 72B
  { group: main_group, file: 'SentryConfig.swift', path: 'PTPerformance/SentryConfig.swift' },

  # Models - Build 72A (already exist, ensure in build)
  { group: models_group, file: 'Session.swift', path: 'PTPerformance/Models/Session.swift' },
  { group: models_group, file: 'Block.swift', path: 'PTPerformance/Models/Block.swift' },
  { group: models_group, file: 'BlockItem.swift', path: 'PTPerformance/Models/BlockItem.swift' },
  { group: models_group, file: 'LogEvent.swift', path: 'PTPerformance/Models/LogEvent.swift' },
  { group: models_group, file: 'QuickMetrics.swift', path: 'PTPerformance/Models/QuickMetrics.swift' },
  { group: models_group, file: 'HelpArticle.swift', path: 'PTPerformance/Models/HelpArticle.swift' },

  # Models - Build 72B
  { group: models_group, file: 'ContentItem.swift', path: 'PTPerformance/Models/ContentItem.swift' },

  # Services - Build 72A
  { group: services_group, file: 'BlockLibraryManager.swift', path: 'PTPerformance/Services/BlockLibraryManager.swift' },
  { group: services_group, file: 'HelpDataManager.swift', path: 'PTPerformance/Services/HelpDataManager.swift' },
  { group: services_group, file: 'LoggingService.swift', path: 'PTPerformance/Services/LoggingService.swift' },

  # Services - Build 72B
  { group: services_group, file: 'OnboardingCoordinator.swift', path: 'PTPerformance/Services/OnboardingCoordinator.swift' },
  { group: services_group, file: 'SupabaseManager.swift', path: 'PTPerformance/Services/SupabaseManager.swift' },

  # ViewModels - Build 72B
  { group: viewmodels_group, file: 'ArticlesViewModel.swift', path: 'PTPerformance/ViewModels/ArticlesViewModel.swift' },

  # Views/Articles - Build 72B
  { group: articles_group, file: 'ArticleBrowseView.swift', path: 'PTPerformance/Views/Articles/ArticleBrowseView.swift' },
  { group: articles_group, file: 'ArticleDetailView.swift', path: 'PTPerformance/Views/Articles/ArticleDetailView.swift' },

  # Views/Onboarding - Build 72B
  { group: onboarding_group, file: 'OnboardingView.swift', path: 'PTPerformance/Views/Onboarding/OnboardingView.swift' },
  { group: onboarding_group, file: 'OnboardingPage.swift', path: 'PTPerformance/Views/Onboarding/OnboardingPage.swift' },

  # Views/Help - Build 72A (already exist, ensure in build)
  { group: help_group, file: 'HelpSearchView.swift', path: 'PTPerformance/Views/Help/HelpSearchView.swift' },
  { group: help_group, file: 'HelpArticleView.swift', path: 'PTPerformance/Views/Help/HelpArticleView.swift' },

  # Views/Logging - Build 72A (NEW)
  { group: logging_group, file: 'BlockCard.swift', path: 'PTPerformance/Views/Logging/BlockCard.swift' },
  { group: logging_group, file: 'BlockHeader.swift', path: 'PTPerformance/Views/Logging/BlockHeader.swift' },
  { group: logging_group, file: 'BlockItemRow.swift', path: 'PTPerformance/Views/Logging/BlockItemRow.swift' },
  { group: logging_group, file: 'QuickMetricsSummary.swift', path: 'PTPerformance/Views/Logging/QuickMetricsSummary.swift' },
]

# JSON data files (resources, not compiled)
resource_files = [
  { group: data_group, file: 'help_articles.json', path: 'PTPerformance/Data/help_articles.json' },
  { group: data_group, file: 'baseball_blocks.json', path: 'PTPerformance/Data/baseball_blocks.json' },
  { group: data_group, file: 'rtp_blocks.json', path: 'PTPerformance/Data/rtp_blocks.json' },
]

added_count = 0
skipped_count = 0
error_count = 0

puts "\nAdding Swift source files to build phase..."
puts "-" * 70

files_to_add.each do |file_info|
  file_name = file_info[:file]
  full_path = file_info[:path]

  # Check if file exists on disk
  unless File.exist?(full_path)
    puts "✗ File not found on disk: #{full_path}"
    error_count += 1
    next
  end

  # Check if file reference already exists in the group
  existing_ref = file_info[:group].files.find { |f| f.path == file_name }

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

puts "\nAdding JSON resource files to resource phase..."
puts "-" * 70

resource_files.each do |file_info|
  file_name = file_info[:file]
  full_path = file_info[:path]

  # Check if file exists on disk
  unless File.exist?(full_path)
    puts "✗ File not found on disk: #{full_path}"
    error_count += 1
    next
  end

  # Check if file reference already exists in the group
  existing_ref = file_info[:group].files.find { |f| f.path == file_name }

  if existing_ref
    # Check if it's in the resources build phase
    in_build = target.resources_build_phase.files.any? { |bf| bf.file_ref == existing_ref }

    if in_build
      puts "⊘ Already in resources: #{file_name}"
      skipped_count += 1
    else
      # Add to resources build phase
      target.resources_build_phase.add_file_reference(existing_ref)
      puts "✓ Added to resources: #{file_name}"
      added_count += 1
    end
  else
    # Create new file reference
    begin
      file_ref = file_info[:group].new_file(file_name)

      # Add to resources build phase
      target.resources_build_phase.add_file_reference(file_ref)

      puts "✓ Added new resource: #{file_name}"
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
puts "BUILD 73 Complete Integration (72A + 72B)"
puts "=" * 70
puts "Files added: #{added_count}"
puts "Files skipped: #{skipped_count}"
puts "Errors: #{error_count}"
puts "=" * 70

if error_count == 0
  puts "\n✅ All Build 73 files successfully integrated!"
  puts "\nBuild 72A files: 13 (models, views, services, data)"
  puts "Build 72B files: 9 (articles, onboarding, sentry)"
  puts "Total: 22 files + 3 JSON resources"
  exit 0
else
  puts "\n⚠️  Some errors occurred. Please review above."
  exit 1
end
