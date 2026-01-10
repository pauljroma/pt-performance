#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Get main group
main_group = project.main_group.find_subpath('PTPerformance', true)

# Find or create groups
models_group = main_group.find_subpath('Models', true)
services_group = main_group.find_subpath('Services', true)
viewmodels_group = main_group.find_subpath('ViewModels', true)
views_group = main_group.find_subpath('Views', true)
video_library_group = views_group.find_subpath('VideoLibrary', true)

puts "Adding Build 62 Video Library files to PTPerformance..."

# Add VideoCategory.swift to Models
file_ref = models_group.new_reference('PTPerformance/Models/VideoCategory.swift')
target.add_file_references([file_ref])
puts "✅ Added VideoCategory.swift to Models group"

# Add VideoDownloadManager.swift to Services
file_ref = services_group.new_reference('PTPerformance/Services/VideoDownloadManager.swift')
target.add_file_references([file_ref])
puts "✅ Added VideoDownloadManager.swift to Services group"

# Add VideoLibraryViewModel.swift to ViewModels
file_ref = viewmodels_group.new_reference('PTPerformance/ViewModels/VideoLibraryViewModel.swift')
target.add_file_references([file_ref])
puts "✅ Added VideoLibraryViewModel.swift to ViewModels group"

# Add VideoLibrary views
file_ref = video_library_group.new_reference('PTPerformance/Views/VideoLibrary/VideoLibraryView.swift')
target.add_file_references([file_ref])
puts "✅ Added VideoLibraryView.swift to Views/VideoLibrary group"

file_ref = video_library_group.new_reference('PTPerformance/Views/VideoLibrary/VideoCategoryGrid.swift')
target.add_file_references([file_ref])
puts "✅ Added VideoCategoryGrid.swift to Views/VideoLibrary group"

file_ref = video_library_group.new_reference('PTPerformance/Views/VideoLibrary/ExerciseVideoDetailView.swift')
target.add_file_references([file_ref])
puts "✅ Added ExerciseVideoDetailView.swift to Views/VideoLibrary group"

project.save

puts "\n✨ Build 62 Video Library files successfully added to Xcode project!"
puts "\nFiles added:"
puts "  Models: VideoCategory.swift"
puts "  Services: VideoDownloadManager.swift"
puts "  ViewModels: VideoLibraryViewModel.swift"
puts "  Views/VideoLibrary: VideoLibraryView.swift, VideoCategoryGrid.swift, ExerciseVideoDetailView.swift"
