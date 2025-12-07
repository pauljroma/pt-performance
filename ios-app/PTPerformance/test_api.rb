require 'spaceship'

api_key = Spaceship::ConnectAPI::Key.create(
  key_id: ENV["APP_STORE_CONNECT_API_KEY_ID"],
  issuer_id: ENV["APP_STORE_CONNECT_API_ISSUER_ID"],
  key: ENV["APP_STORE_CONNECT_API_KEY_CONTENT"]
)

Spaceship::ConnectAPI.token = api_key.text

begin
  # Try to fetch certificates
  certs = Spaceship::ConnectAPI::Certificate.all
  puts "✅ API key authentication successful!"
  puts "Found #{certs.count} certificates"
rescue => e
  puts "❌ API key authentication failed:"
  puts e.message
  puts e.class
end
