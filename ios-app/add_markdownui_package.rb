#!/usr/bin/env ruby
require 'xcodeproj'

puts "Adding MarkdownUI Package to PTPerformance"
puts "=" * 70

# Open the Xcode project
project_path = 'PTPerformance/PTPerformance.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first
puts "Target: #{target.name}"

# Create package reference for MarkdownUI
package_url = "https://github.com/gonzalezreal/swift-markdown-ui"
package_name = "swift-markdown-ui"

# Check if package already exists
existing_package = project.root_object.package_references.find do |pkg|
  pkg.repositoryURL == package_url
end

if existing_package
  puts "⊘ MarkdownUI package already exists in project"
else
  puts "Adding MarkdownUI package reference..."

  # Add package reference to project
  package_ref = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
  package_ref.repositoryURL = package_url
  package_ref.requirement = {
    'kind' => 'upToNextMajorVersion',
    'minimumVersion' => '2.0.0'
  }

  project.root_object.package_references << package_ref

  # Add package product dependency to target
  package_product = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  package_product.package = package_ref
  package_product.product_name = 'MarkdownUI'

  target.package_product_dependencies << package_product

  puts "✓ MarkdownUI package reference added"
  puts "✓ MarkdownUI product dependency added to target"
end

# Save the project
puts "\nSaving project..."
project.save

puts "=" * 70
puts "✅ MarkdownUI Package Successfully Added!"
puts "=" * 70
puts "Package: #{package_url}"
puts "Product: MarkdownUI"
puts "Target: #{target.name}"
puts ""
puts "Next: Run 'xcodebuild -resolvePackageDependencies' to fetch the package"
puts "=" * 70
