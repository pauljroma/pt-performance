#!/usr/bin/env ruby
# Upload IPA to TestFlight using App Store Connect API
# This tests the same authentication method that GitHub Actions will use

require 'fastlane'

# Set up API key from environment
api_key = Fastlane::Actions::AppStoreConnectApiKeyAction.run(
  key_id: ENV["APP_STORE_CONNECT_API_KEY_ID"],
  issuer_id: ENV["APP_STORE_CONNECT_API_ISSUER_ID"],
  key_content: ENV["APP_STORE_CONNECT_API_KEY_CONTENT"],
  is_key_content_base64: true
)

# Upload to TestFlight
Fastlane::Actions::UploadToTestflightAction.run(
  api_key: api_key,
  ipa: "PTPerformance.ipa",
  skip_waiting_for_build_processing: true,
  distribute_external: false
)

puts "\n✅ Upload complete!"
