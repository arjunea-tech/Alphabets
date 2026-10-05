/**
 * Cloudinary v2 SDK Configuration
 */
const cloudinary = require('cloudinary').v2;
const config = require('./env');
const logger = require('../utils/logger');

cloudinary.config({
  cloud_name: config.cloudinary.cloudName,
  api_key: config.cloudinary.apiKey,
  api_secret: config.cloudinary.apiSecret,
  secure: true,
});

logger.info(`☁️ Cloudinary configured for cloud: ${config.cloudinary.cloudName}`);

module.exports = cloudinary;
