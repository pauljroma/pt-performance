#!/usr/bin/env ruby
require 'xcodeproj'

puts "Adding All Missing Files to Build Phase"
puts "=" * 70

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first

# List of files we know are missing
missing_files = [
  'SentryConfig.swift',
  'Services/OnboardingCoordinator.swift',
  'Views/Articles/ArticleBrowseView.swift',
  'Views/Articles/ArticleDetailView.swift',
  'Views/Onboarding/OnboardingView.swift',
  'Views/Onboarding/OnboardingPage.swift',
  'ViewModels/ArticlesViewModel.swift',
  'Services/SupabaseManager.swift',
  'Models/ContentItem.swift',
  'Models/ReadinessBand.swift'
]

added = 0
skipped = 0

missing_files.each do |file_path|
  # Find the file reference
  file_ref = project.files.find { |f| f.path == file_path }

  if file_ref.nil?
    puts "⚠️  File not found in project: #{file_path}"
    next
  end

  # Check if already in build phase
  already_in_build = target.source_build_phase.files.any? { |bf| bf.file_ref == file_ref }

  if already_in_build
    puts "⊘ Already in build: #{file_path}"
    skipped += 1
  else
    target.source_build_phase.add_file_reference(file_ref)
    puts "✓ Added: #{file_path}"
    added += 1
  end
end

if added > 0
  project.save
end

puts "\n" + "=" * 70
puts "Added: #{added} files"
puts "Skipped: #{skipped} files"
puts "=" * 70
