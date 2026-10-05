/**
 * Cloudinary Media Service
 * Handles signature generation for Option 2 (Direct Client Upload)
 * and server-side stream uploading/deletion.
 */
const cloudinary = require('../config/cloudinary');
const config = require('../config/env');
const logger = require('../utils/logger');

/**
 * Generate signed upload parameters for secure direct browser-to-Cloudinary upload.
 * @param {string} customFolder - Optional subfolder in Cloudinary
 * @param {string} resourceType - 'auto' | 'video' | 'image' | 'raw'
 * @returns {object} { timestamp, signature, apiKey, cloudName, folder }
 */
function getUploadSignature(customFolder = 'agaram_media', resourceType = 'auto') {
  const timestamp = Math.round(new Date().getTime() / 1000);
  const folder = customFolder || config.cloudinary.folder || 'agaram_media';

  // Parameters to sign must be sorted alphabetically
  const paramsToSign = {
    folder,
    timestamp,
  };

  const signature = cloudinary.utils.api_sign_request(
    paramsToSign,
    config.cloudinary.apiSecret
  );

  return {
    timestamp,
    signature,
    apiKey: config.cloudinary.apiKey,
    cloudName: config.cloudinary.cloudName,
    folder,
    uploadUrl: `https://api.cloudinary.com/v1_1/${config.cloudinary.cloudName}/${resourceType === 'video' ? 'video' : resourceType === 'image' ? 'image' : 'auto'}/upload`,
  };
}

/**
 * Server-side stream upload to Cloudinary (fallback)
 * @param {Buffer} fileBuffer
 * @param {object} options
 * @returns {Promise<object>}
 */
function uploadBufferToCloudinary(fileBuffer, options = {}) {
  return new Promise((resolve, reject) => {
    const uploadOptions = {
      folder: options.folder || config.cloudinary.folder || 'agaram_media',
      resource_type: options.resourceType || 'auto',
      ...options,
    };

    const stream = cloudinary.uploader.upload_stream(uploadOptions, (error, result) => {
      if (error) {
        logger.error('Cloudinary stream upload error:', error);
        return reject(error);
      }
      resolve(result);
    });

    stream.end(fileBuffer);
  });
}

/**
 * Delete a media file from Cloudinary by public ID
 * @param {string} publicId
 * @param {string} resourceType - 'image' | 'video' | 'raw'
 */
async function deleteFromCloudinary(publicId, resourceType = 'video') {
  try {
    const res = await cloudinary.uploader.destroy(publicId, { resource_type: resourceType });
    return res;
  } catch (error) {
    logger.error(`Failed to delete from Cloudinary (${publicId}):`, error);
    throw error;
  }
}

module.exports = {
  getUploadSignature,
  uploadBufferToCloudinary,
  deleteFromCloudinary,
};
