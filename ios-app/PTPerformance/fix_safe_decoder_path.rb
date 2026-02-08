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

# Remove the bad reference and add correct one
utils_group.files.each do |f|
  if f.path == 'SafeDecoder.swift' && (f.real_path.to_s.include?('SafeDecoder.swift') == false || f.real_path.to_s.end_with?('PTPerformance/SafeDecoder.swift'))
    puts "Removing bad reference: #{f.path} -> #{f.real_path}"
    f.remove_from_project
  end
end

# Check if correct file already exists
file_exists = utils_group.files.any? { |f| f.path == 'Utils/SafeDecoder.swift' || (f.path == 'SafeDecoder.swift' && f.real_path.to_s.include?('Utils/SafeDecoder.swift')) }

if !file_exists
  # Add the file with correct path
  file_ref = utils_group.new_reference('Utils/SafeDecoder.swift')
  file_ref.set_source_tree('SOURCE_ROOT')
  
  # Add to target
  main_target = project.targets.find { |t| t.name == 'PTPerformance' }
  main_target.source_build_phase.add_file_reference(file_ref)
  
  project.save
  puts "SafeDecoder.swift added with correct path"
else
  puts "SafeDecoder.swift already has correct path"
  project.save
end
