/**
 * Configuration Module
 * Loads and validates environment variables for the PT Agent Service
 */

import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load .env from agent-service directory
dotenv.config({ path: resolve(__dirname, '../.env') });

// Validate required environment variables
const required = ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY', 'LINEAR_API_KEY'];
const missing = required.filter(key => !process.env[key]);

if (missing.length > 0) {
  console.error(`❌ ERROR: Missing required environment variables: ${missing.join(', ')}`);
  console.error('Please ensure .env file exists in agent-service/ directory');
  process.exit(1);
}

export const config = {
  // Server
  port: process.env.PORT || 4000,
  nodeEnv: process.env.NODE_ENV || 'development',

  // Supabase
  supabase: {
    url: process.env.SUPABASE_URL,
    serviceKey: process.env.SUPABASE_SERVICE_ROLE_KEY,
    anonKey: process.env.SUPABASE_ANON_KEY,
  },

  // Linear
  linear: {
    apiKey: process.env.LINEAR_API_KEY,
    teamId: process.env.LINEAR_TEAM_ID,
  },

  // Logging
  logLevel: process.env.LOG_LEVEL || 'info',
};

console.log('✅ Configuration loaded successfully');
console.log(`📍 Environment: ${config.nodeEnv}`);
console.log(`🔌 Port: ${config.port}`);
