/**
 * File & Media Upload Routes (Protected with JWT & Role Auth)
 * Supports both Option 2 (Direct Client-to-Cloudinary signed upload)
 * and Server-side uploads.
 */
const express = require('express');
const upload = require('../middleware/uploadMiddleware');
const { verifyToken, requireRole } = require('../middleware/authMiddleware');
const { successResponse, errorResponse } = require('../utils/apiResponse');
const { getUploadSignature, uploadBufferToCloudinary } = require('../services/cloudinaryService');
const config = require('../config/env');
const fs = require('fs');

const router = express.Router();

router.use(verifyToken, requireRole('super_admin', 'content_admin'));

// -----------------------------------------------------------------------------
// OPTION 2: Signed Parameters for Direct Browser Upload to Cloudinary
// -----------------------------------------------------------------------------
router.get(['/signature', '/cloudinary-signature'], (req, res) => {
  try {
    const { folder, resourceType } = req.query;
    const targetFolder = folder || config.cloudinary.folder || 'agaram_media';
    const targetResourceType = resourceType || 'auto';

    const signatureData = getUploadSignature(targetFolder, targetResourceType);
    return successResponse(res, 'Cloudinary upload signature generated successfully', signatureData);
  } catch (error) {
    return errorResponse(res, 'Failed to generate Cloudinary signature', error.message, 500);
  }
});

// -----------------------------------------------------------------------------
// Server-Side Upload Fallbacks
// -----------------------------------------------------------------------------

// Upload Image
router.post('/image', upload.single('image'), async (req, res) => {
  if (!req.file) {
    return errorResponse(res, 'No image file uploaded', null, 400);
  }

  try {
    if (config.cloudinary.apiKey && config.cloudinary.cloudName) {
      const fileBuffer = fs.readFileSync(req.file.path);
      const cldRes = await uploadBufferToCloudinary(fileBuffer, {
        folder: `${config.cloudinary.folder}/images`,
        resourceType: 'image',
      });

      // Cleanup local temp file
      try { fs.unlinkSync(req.file.path); } catch (_) {}

      return successResponse(res, 'Image uploaded to Cloudinary successfully', {
        filename: req.file.filename,
        path: cldRes.secure_url,
        url: cldRes.secure_url,
        publicId: cldRes.public_id,
        mimetype: req.file.mimetype,
        size: cldRes.bytes || req.file.size,
      }, 201);
    }

    const relativePath = `uploads/images/${req.file.filename}`;
    return successResponse(res, 'Image uploaded locally', {
      filename: req.file.filename,
      path: relativePath,
      url: `/${relativePath}`,
      mimetype: req.file.mimetype,
      size: req.file.size,
    }, 201);
  } catch (error) {
    return errorResponse(res, 'Image upload failed', error.message, 500);
  }
});

// Upload Audio
router.post('/audio', upload.single('audio'), async (req, res) => {
  if (!req.file) {
    return errorResponse(res, 'No audio file uploaded', null, 400);
  }

  try {
    if (config.cloudinary.apiKey && config.cloudinary.cloudName) {
      const fileBuffer = fs.readFileSync(req.file.path);
      const cldRes = await uploadBufferToCloudinary(fileBuffer, {
        folder: `${config.cloudinary.folder}/audio`,
        resourceType: 'video', // Cloudinary handles audio files under video resource_type
      });

      try { fs.unlinkSync(req.file.path); } catch (_) {}

      return successResponse(res, 'Audio uploaded to Cloudinary successfully', {
        filename: req.file.filename,
        path: cldRes.secure_url,
        url: cldRes.secure_url,
        publicId: cldRes.public_id,
        mimetype: req.file.mimetype,
        size: cldRes.bytes || req.file.size,
      }, 201);
    }

    const relativePath = `uploads/audio/${req.file.filename}`;
    return successResponse(res, 'Audio uploaded locally', {
      filename: req.file.filename,
      path: relativePath,
      url: `/${relativePath}`,
      mimetype: req.file.mimetype,
      size: req.file.size,
    }, 201);
  } catch (error) {
    return errorResponse(res, 'Audio upload failed', error.message, 500);
  }
});

// Upload Video
router.post('/video', upload.single('video'), async (req, res) => {
  if (!req.file) {
    return errorResponse(res, 'No video file uploaded', null, 400);
  }

  try {
    if (config.cloudinary.apiKey && config.cloudinary.cloudName) {
      const fileBuffer = fs.readFileSync(req.file.path);
      const cldRes = await uploadBufferToCloudinary(fileBuffer, {
        folder: `${config.cloudinary.folder}/videos`,
        resourceType: 'video',
      });

      try { fs.unlinkSync(req.file.path); } catch (_) {}

      return successResponse(res, 'Video uploaded to Cloudinary successfully', {
        filename: req.file.filename,
        path: cldRes.secure_url,
        url: cldRes.secure_url,
        publicId: cldRes.public_id,
        mimetype: req.file.mimetype,
        size: cldRes.bytes || req.file.size,
        duration: cldRes.duration,
      }, 201);
    }

    const relativePath = `uploads/videos/${req.file.filename}`;
    return successResponse(res, 'Video uploaded locally', {
      filename: req.file.filename,
      path: relativePath,
      url: `/${relativePath}`,
      mimetype: req.file.mimetype,
      size: req.file.size,
    }, 201);
  } catch (error) {
    return errorResponse(res, 'Video upload failed', error.message, 500);
  }
});

module.exports = router;
