#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first
puts "Target: #{target.name}"

# Get the main group
main_group = project.main_group

# Add Assets.xcassets if not already present
assets_ref = main_group.files.find { |f| f.path == 'Assets.xcassets' }
unless assets_ref
  assets_ref = main_group.new_reference('Assets.xcassets')
  assets_ref.last_known_file_type = 'folder.assetcatalog'

  # Add to target resources
  target.resources_build_phase.add_file_reference(assets_ref)
  puts "Added Assets.xcassets to project"
end

# Add LaunchScreen.storyboard if not already present
launch_ref = main_group.files.find { |f| f.path == 'LaunchScreen.storyboard' }
unless launch_ref
  launch_ref = main_group.new_reference('LaunchScreen.storyboard')
  launch_ref.last_known_file_type = 'file.storyboard'

  # Add to target resources
  target.resources_build_phase.add_file_reference(launch_ref)
  puts "Added LaunchScreen.storyboard to project"
end

# Update build settings
target.build_configurations.each do |config|
  # Set the asset catalog app icon set name
  config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'

  # Set Info.plist file path
  config.build_settings['INFOPLIST_FILE'] = 'Info.plist'

  puts "Updated #{config.name} configuration"
end

# Save the project
project.save
puts "\nProject saved successfully!"
puts "\nNext steps:"
puts "1. Run: ./run_local_build.sh"
puts "2. The build should now pass Apple's validation!"
