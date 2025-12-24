#!/usr/bin/env ruby
require 'xcodeproj'

puts "BUILD_72A - Adding all files to Xcode project..."
puts "=" * 60

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
views_group = main_group['Views'] || main_group.new_group('Views')
help_views_group = views_group['Help'] || views_group.new_group('Help')
logging_views_group = views_group['Logging'] || views_group.new_group('Logging')
services_group = main_group['Services'] || main_group.new_group('Services')
data_group = main_group['Data'] || main_group.new_group('Data')
tests_group = project.main_group['Tests'] || project.main_group.new_group('Tests')
unit_tests_group = tests_group['Unit'] || tests_group.new_group('Unit')

# Set group paths
models_group.path = 'Models'
views_group.path = 'Views'
help_views_group.path = 'Help'
logging_views_group.path = 'Logging'
services_group.path = 'Services'
data_group.path = 'Data'
tests_group.path = 'Tests'
unit_tests_group.path = 'Unit'

# Define all files to add
files_to_add = [
  # Models (Agent 5 + Agent 4)
  { group: models_group, file: 'Models/Session.swift', compile: true },
  { group: models_group, file: 'Models/Block.swift', compile: true },
  { group: models_group, file: 'Models/BlockItem.swift', compile: true },
  { group: models_group, file: 'Models/QuickMetrics.swift', compile: true },
  { group: models_group, file: 'Models/LogEvent.swift', compile: true },
  { group: models_group, file: 'Models/HelpArticle.swift', compile: true },

  # Views - Help (Agent 4)
  { group: help_views_group, file: 'Views/Help/HelpSearchView.swift', compile: true },
  { group: help_views_group, file: 'Views/Help/HelpArticleView.swift', compile: true },

  # Views - Logging (Agent 7)
  { group: logging_views_group, file: 'Views/Logging/BlockCard.swift', compile: true },
  { group: logging_views_group, file: 'Views/Logging/BlockHeader.swift', compile: true },
  { group: logging_views_group, file: 'Views/Logging/BlockItemRow.swift', compile: true },
  { group: logging_views_group, file: 'Views/Logging/QuickMetricsSummary.swift', compile: true },

  # Services (Agent 4 + Agent 6 + Agent 8)
  { group: services_group, file: 'Services/HelpDataManager.swift', compile: true },
  { group: services_group, file: 'Services/BlockLibraryManager.swift', compile: true },
  { group: services_group, file: 'Services/LoggingService.swift', compile: true },

  # Data (Agent 4 + Agent 6) - JSON files as resources
  { group: data_group, file: 'Data/help_articles.json', compile: false, resource: true },
  { group: data_group, file: 'Data/baseball_blocks.json', compile: false, resource: true },
  { group: data_group, file: 'Data/rtp_blocks.json', compile: false, resource: true },

  # Tests (Agent 8)
  { group: unit_tests_group, file: 'Tests/Unit/LoggingServiceTests.swift', compile: true, test: true },
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
        if file_info[:resource]
          target.resources_build_phase.add_file_reference(file_ref)
          puts "✓ Added #{file_path} (resource)"
        elsif file_info[:test]
          # Find test target
          test_target = project.targets.find { |t| t.name.include?('Test') }
          if test_target
            test_target.source_build_phase.add_file_reference(file_ref)
            puts "✓ Added #{file_path} (test)"
          else
            target.source_build_phase.add_file_reference(file_ref)
            puts "✓ Added #{file_path} (source)"
          end
        elsif file_info[:compile]
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

puts "=" * 60
puts "BUILD_72A Integration Complete!"
puts "=" * 60
puts "Files added: #{added_count}"
puts "Files skipped: #{skipped_count}"
puts "Errors: #{error_count}"
puts ""
puts "Summary by Agent:"
puts "  Agent 4 (Help System): 5 files"
puts "  Agent 5 (Data Models): 5 files"
puts "  Agent 6 (Block Libraries): 3 files"
puts "  Agent 7 (Adaptive UI): 4 files"
puts "  Agent 8 (Logging Service): 2 files"
puts "=" * 60

if error_count == 0
  puts "\n✅ All BUILD_72A files successfully added to Xcode project!"
  exit 0
else
  puts "\n⚠️  Some files could not be added. Please review errors above."
  exit 1
end
