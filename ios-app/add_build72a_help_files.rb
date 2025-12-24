#!/usr/bin/env ruby
require 'xcodeproj'

# Open the Xcode project
project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Get or create the PTPerformance group (main group)
main_group = project.main_group['PTPerformance'] || project.main_group.new_group('PTPerformance')

# Create or get groups
models_group = main_group['Models'] || main_group.new_group('Models')
views_group = main_group['Views'] || main_group.new_group('Views')
help_views_group = views_group['Help'] || views_group.new_group('Help')
services_group = main_group['Services'] || main_group.new_group('Services')
data_group = main_group['Data'] || main_group.new_group('Data')

# Set group paths
models_group.path = 'Models'
views_group.path = 'Views'
help_views_group.path = 'Help'
services_group.path = 'Services'
data_group.path = 'Data'

puts "Adding files to Xcode project..."

# Add HelpArticle.swift to Models group
help_article_file = 'Models/HelpArticle.swift'
if File.exist?("PTPerformance/#{help_article_file}")
  file_ref = models_group.new_file(help_article_file)
  target.add_file_references([file_ref])
  puts "✓ Added HelpArticle.swift to Models"
else
  puts "✗ HelpArticle.swift not found at PTPerformance/#{help_article_file}"
end

# Add HelpSearchView.swift to Views/Help group
help_search_file = 'Views/Help/HelpSearchView.swift'
if File.exist?("PTPerformance/#{help_search_file}")
  file_ref = help_views_group.new_file(help_search_file)
  target.add_file_references([file_ref])
  puts "✓ Added HelpSearchView.swift to Views/Help"
else
  puts "✗ HelpSearchView.swift not found at PTPerformance/#{help_search_file}"
end

# Add HelpArticleView.swift to Views/Help group
help_article_view_file = 'Views/Help/HelpArticleView.swift'
if File.exist?("PTPerformance/#{help_article_view_file}")
  file_ref = help_views_group.new_file(help_article_view_file)
  target.add_file_references([file_ref])
  puts "✓ Added HelpArticleView.swift to Views/Help"
else
  puts "✗ HelpArticleView.swift not found at PTPerformance/#{help_article_view_file}"
end

# Add HelpDataManager.swift to Services group
help_manager_file = 'Services/HelpDataManager.swift'
if File.exist?("PTPerformance/#{help_manager_file}")
  file_ref = services_group.new_file(help_manager_file)
  target.add_file_references([file_ref])
  puts "✓ Added HelpDataManager.swift to Services"
else
  puts "✗ HelpDataManager.swift not found at PTPerformance/#{help_manager_file}"
end

# Add help_articles.json to Data group (as resource, not compiled)
help_json_file = 'Data/help_articles.json'
if File.exist?("PTPerformance/#{help_json_file}")
  file_ref = data_group.new_file(help_json_file)
  target.resources_build_phase.add_file_reference(file_ref)
  puts "✓ Added help_articles.json to Data (as resource)"
else
  puts "✗ help_articles.json not found at PTPerformance/#{help_json_file}"
end

# Save the project
project.save

puts "\n✅ Successfully added all BUILD_72A Help System files to Xcode project!"
puts "\nFiles added:"
puts "  - Models/HelpArticle.swift"
puts "  - Views/Help/HelpSearchView.swift"
puts "  - Views/Help/HelpArticleView.swift"
puts "  - Services/HelpDataManager.swift"
puts "  - Data/help_articles.json (resource)"
