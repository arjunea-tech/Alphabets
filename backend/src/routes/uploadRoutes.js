/**
 * File Upload Routes (Protected)
 */
const express = require('express');
const upload = require('../middleware/uploadMiddleware');
const { verifyToken, requireRole } = require('../middleware/authMiddleware');
const { successResponse, errorResponse } = require('../utils/apiResponse');

const router = express.Router();

router.use(verifyToken, requireRole('super_admin', 'content_admin'));

// Upload Image
router.post('/image', upload.single('image'), (req, res) => {
  if (!req.file) {
    return errorResponse(res, 'No image file uploaded', null, 400);
  }
  const relativePath = `uploads/images/${req.file.filename}`;
  return successResponse(res, 'Image uploaded successfully', {
    filename: req.file.filename,
    path: relativePath,
    url: `/${relativePath}`,
    mimetype: req.file.mimetype,
    size: req.file.size,
  }, 201);
});

// Upload Audio
router.post('/audio', upload.single('audio'), (req, res) => {
  if (!req.file) {
    return errorResponse(res, 'No audio file uploaded', null, 400);
  }
  const relativePath = `uploads/audio/${req.file.filename}`;
  return successResponse(res, 'Audio uploaded successfully', {
    filename: req.file.filename,
    path: relativePath,
    url: `/${relativePath}`,
    mimetype: req.file.mimetype,
    size: req.file.size,
  }, 201);
});

// Upload Video
router.post('/video', upload.single('video'), (req, res) => {
  if (!req.file) {
    return errorResponse(res, 'No video file uploaded', null, 400);
  }
  const relativePath = `uploads/videos/${req.file.filename}`;
  return successResponse(res, 'Video uploaded successfully', {
    filename: req.file.filename,
    path: relativePath,
    url: `/${relativePath}`,
    mimetype: req.file.mimetype,
    size: req.file.size,
  }, 201);
});

module.exports = router;
