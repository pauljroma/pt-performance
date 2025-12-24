require 'xcodeproj'

project_path = 'PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find main target
main_target = project.targets.find { |t| t.name == 'PTPerformance' }

# Find or create groups
models_group = project.main_group['Models'] || project.main_group.new_group('Models')
services_group = project.main_group['Services'] || project.main_group.new_group('Services')

# Add LogEvent.swift to Models group
log_event_ref = models_group.new_file('Models/LogEvent.swift')
main_target.source_build_phase.add_file_reference(log_event_ref)

# Add LoggingService.swift to Services group
logging_service_ref = services_group.new_file('Services/LoggingService.swift')
main_target.source_build_phase.add_file_reference(logging_service_ref)

# Save project
project.save

puts "✅ Added BUILD_72A Agent 8 files to Xcode project:"
puts "   - Models/LogEvent.swift"
puts "   - Services/LoggingService.swift"
