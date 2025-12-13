#!/bin/bash
# Upload existing IPA to TestFlight using App Store Connect API

export APP_STORE_CONNECT_API_KEY_ID="NKWNDTD3DJ"
export APP_STORE_CONNECT_API_ISSUER_ID="69a6de9d-2840-47e3-e053-5b8c7c11a4d1"
export APP_STORE_CONNECT_API_KEY_CONTENT="$(cat ~/.appstoreconnect/private_keys/AuthKey_NKWNDTD3DJ.p8 | base64)"

bundle exec fastlane run upload_to_testflight \
  ipa:"PTPerformance.ipa" \
  api_key_path:"~/.appstoreconnect/private_keys/AuthKey_NKWNDTD3DJ.p8" \
  skip_waiting_for_build_processing:true
