#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
main_target = project.targets.find { |t| t.name == 'PTPerformance' }
puts "Main Target: #{main_target.name}"

# Create or find test target
test_target = project.targets.find { |t| t.name == 'PTPerformanceTests' }

if test_target.nil?
    puts "Creating new test target..."
    test_target = project.new_target(:unit_test_bundle, 'PTPerformanceTests', :ios)
    test_target.add_dependency(main_target)
end

puts "Test Target: #{test_target.name}"

# Find or create Tests group
tests_group = project.main_group['Tests'] || project.main_group.new_group('Tests')

# Find or create subgroups
unit_group = tests_group['Unit'] || tests_group.new_group('Unit')
integration_group = tests_group['Integration'] || tests_group.new_group('Integration')
ui_group = tests_group['UI'] || tests_group.new_group('UI')

# Add unit test files
unit_test_files = [
    'Tests/Unit/TodaySessionViewModelTests.swift',
    'Tests/Unit/PatientListViewModelTests.swift',
    'Tests/Unit/ConfigTests.swift'
]

unit_test_files.each do |file_path|
    filename = File.basename(file_path)
    puts "Adding unit test: #{filename}"

    file_ref = unit_group.new_file(file_path)
    test_target.source_build_phase.add_file_reference(file_ref)
end

# Add integration test files
integration_test_files = [
    'Tests/Integration/SupabaseIntegrationTests.swift'
]

integration_test_files.each do |file_path|
    filename = File.basename(file_path)
    puts "Adding integration test: #{filename}"

    file_ref = integration_group.new_file(file_path)
    test_target.source_build_phase.add_file_reference(file_ref)
end

# Add UI test files
ui_test_files = [
    'Tests/UI/PatientFlowUITests.swift'
]

# Create or find UI test target
ui_test_target = project.targets.find { |t| t.name == 'PTPerformanceUITests' }

if ui_test_target.nil?
    puts "Creating new UI test target..."
    ui_test_target = project.new_target(:ui_test_bundle, 'PTPerformanceUITests', :ios)
    ui_test_target.add_dependency(main_target)
end

ui_test_files.each do |file_path|
    filename = File.basename(file_path)
    puts "Adding UI test: #{filename}"

    file_ref = ui_group.new_file(file_path)
    ui_test_target.source_build_phase.add_file_reference(file_ref)
end

# Save the project
project.save

puts ""
puts "✅ All test files added to Xcode project"
puts ""
puts "Test Targets:"
puts "  - #{test_target.name} (Unit + Integration)"
puts "  - #{ui_test_target.name} (UI Tests)"
puts ""
puts "Next steps:"
puts "  1. Run ./run_qc_tests.sh to execute all tests"
puts "  2. Fix any failing tests"
puts "  3. Only deploy when all tests pass"
