/**
 * File Upload Middleware using Multer
 * Handles organized uploads for images, audio, and video assets.
 */
const path = require('path');
const fs = require('fs');
const multer = require('multer');
const config = require('../config/env');

const UPLOAD_ROOT = path.join(__dirname, '../../uploads');

// Ensure upload subdirectories exist
['images', 'audio', 'videos'].forEach((dir) => {
  const fullPath = path.join(UPLOAD_ROOT, dir);
  if (!fs.existsSync(fullPath)) {
    fs.mkdirSync(fullPath, { recursive: true });
  }
});

// Destination resolver based on field or route type
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    let subDir = 'images';
    if (file.mimetype.startsWith('audio/') || file.fieldname === 'audio') {
      subDir = 'audio';
    } else if (file.mimetype.startsWith('video/') || file.fieldname === 'video') {
      subDir = 'videos';
    }
    cb(null, path.join(UPLOAD_ROOT, subDir));
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    const cleanBase = path
      .basename(file.originalname, ext)
      .replace(/[^a-zA-Z0-9_-]/g, '_')
      .toLowerCase();
    const uniqueSuffix = `${Date.now()}_${Math.round(Math.random() * 1e6)}`;
    cb(null, `${cleanBase}_${uniqueSuffix}${ext}`);
  },
});

// File filter supporting common images, audio, and video formats
const fileFilter = (req, file, cb) => {
  const allowedMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/svg+xml',
    'image/gif',
    'image/jpg',
    'image/pjpeg',
    'image/x-png',
    'audio/mpeg',
    'audio/mp3',
    'audio/wav',
    'audio/aac',
    'audio/m4a',
    'audio/ogg',
    'video/mp4',
    'video/webm',
    'video/quicktime',
  ];

  const ext = path.extname(file.originalname).toLowerCase();
  const allowedExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.svg',
    '.gif',
    '.mp3',
    '.wav',
    '.aac',
    '.m4a',
    '.ogg',
    '.mp4',
    '.webm',
    '.mov',
  ];

  if (allowedMimeTypes.includes(file.mimetype) || allowedExtensions.includes(ext)) {
    cb(null, true);
  } else {
    cb(new Error(`Unsupported file type: ${file.mimetype || ext}. Allowed formats: JPG, PNG, WEBP, SVG, MP3, WAV, AAC, MP4.`), false);
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: config.uploads.maxSizeMB * 1024 * 1024,
  },
});

module.exports = upload;
