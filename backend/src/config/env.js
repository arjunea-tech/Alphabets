/**
 * Environment Configuration and Validation
 */
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const config = {
  env: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT, 10) || 5000,
  apiPrefix: process.env.API_PREFIX || '/api/v1',
  db: {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT, 10) || 3306,
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || 'root',
    name: process.env.DB_NAME || 'agaram_db',
    connectionLimit: parseInt(process.env.DB_CONNECTION_LIMIT, 10) || 10,
  },
  jwt: {
    secret: process.env.JWT_SECRET || 'agaram_super_secret_jwt_key_2026_educational_tamil_platform',
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  },
  uploads: {
    path: process.env.UPLOAD_PATH || 'uploads',
    maxSizeMB: parseInt(process.env.MAX_FILE_SIZE_MB, 10) || 50,
  },
  cors: {
    origin: process.env.CORS_ORIGIN || '*',
  },
  elevenlabs: {
    apiKey: process.env.ELEVENLABS_API_KEY || '',
    voiceId: process.env.ELEVENLABS_VOICE_ID || '',
    modelId: process.env.ELEVENLABS_MODEL_ID || 'eleven_multilingual_v2',
    outputFormat: process.env.ELEVENLABS_OUTPUT_FORMAT || 'mp3_44100_128',
  },
};

module.exports = config;
