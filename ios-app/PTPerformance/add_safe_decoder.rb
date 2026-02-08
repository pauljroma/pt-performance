require 'xcodeproj'

project_path = 'PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the Utils group
utils_group = nil
project.main_group.groups.each do |group|
  if group.name == 'Utils'
    utils_group = group
    break
  end
end

if utils_group.nil?
  puts "Utils group not found"
  exit 1
end

# Check if file already exists in project
file_exists = utils_group.files.any? { |f| f.path == 'SafeDecoder.swift' }
if file_exists
  puts "SafeDecoder.swift already in project"
else
  # Add the file
  file_ref = utils_group.new_reference('SafeDecoder.swift')
  
  # Add to target
  main_target = project.targets.find { |t| t.name == 'PTPerformance' }
  main_target.source_build_phase.add_file_reference(file_ref)
  
  project.save
  puts "SafeDecoder.swift added to project"
end
