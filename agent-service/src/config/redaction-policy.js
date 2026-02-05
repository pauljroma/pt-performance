export const PAYLOAD_REDACTION_POLICY = {
  sensitiveFields: [
    'password',
    'token',
    'apiKey',
    'api_key',
    'secret',
    'authorization',
    'access_token',
    'refresh_token'
  ],
  maxFieldLength: 1000,
  replacement: '[REDACTED]'
};
