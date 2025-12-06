#!/usr/bin/env ruby
require 'fileutils'
require 'xcodeproj'

project_path = 'PTPerformance.xcodeproj'

# Remove old project if exists
FileUtils.rm_rf(project_path) if File.exist?(project_path)

# Create new project
project = Xcodeproj::Project.new(project_path)

# Create app target
target = project.new_target(:application, 'PTPerformance', :ios, '17.0')

# Set bundle identifier
target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.ptperformance.app'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2' # iPhone and iPad
end

# Find all Swift files
swift_files = Dir.glob('**/*.swift').reject { |f| f.include?('build/') || f.include?('create_project') }

puts "📝 Found #{swift_files.count} Swift files"

# Add all Swift files to project
swift_files.sort.each do |file|
  file_ref = project.main_group.new_reference(file)
  target.add_file_references([file_ref])
  puts "   + #{file}"
end

# Save project
project.save

puts ""
puts "✅ Created PTPerformance.xcodeproj with #{swift_files.count} files!"
