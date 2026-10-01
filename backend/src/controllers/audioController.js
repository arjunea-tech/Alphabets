/**
 * Centralized Audio Controller
 * Handles dynamic Tamil audio generation, verification, and manifest retrieval
 */
const path = require('path');
const fs = require('fs');
const elevenLabsService = require('../services/elevenLabsService');
const { successResponse, errorResponse } = require('../utils/apiResponse');
const logger = require('../utils/logger');

const PROJECT_ROOT = path.resolve(__dirname, '../../../');
const AUDIO_BASE_DIR = fs.existsSync(path.join(PROJECT_ROOT, 'frontend/assets/audio/tamil'))
  ? path.join(PROJECT_ROOT, 'frontend/assets/audio/tamil')
  : path.join(PROJECT_ROOT, 'assets/audio/tamil');
const MANIFEST_FILE = path.join(AUDIO_BASE_DIR, 'audio_manifest.json');

class AudioController {
  /**
   * Synthesize audio for given Tamil text (or retrieve cached audio)
   * POST /api/v1/audio/synthesize
   * Body: { text: "அம்மா", category: "words", filename: "word_amma" }
   */
  static async synthesize(req, res, next) {
    try {
      const { text, category = 'words', filename, force = false } = req.body;

      if (!text || !text.trim()) {
        return errorResponse(res, 'Tamil text is required for audio generation', null, 400);
      }

      const trimmedText = text.trim();
      const validCategory = ['uyir', 'mei', 'aytham', 'uyirmei', 'words', 'sentences', 'stories', 'lessons'].includes(category)
        ? category
        : 'words';

      // Generate stable English slug if filename not provided
      let slug = filename;
      if (!slug) {
        // Create deterministic slug using text length and char codes
        const codeSum = Array.from(trimmedText).reduce((acc, ch) => acc + ch.charCodeAt(0), 0);
        slug = `${validCategory}_${trimmedText.length}_${codeSum}`;
      }
      // Ensure safe ASCII filename
      slug = slug.replace(/[^a-zA-Z0-9_-]/g, '_');

      const relativeAssetPath = `assets/audio/tamil/${validCategory}/${slug}.mp3`;
      const fullFilePath = path.join(AUDIO_BASE_DIR, validCategory, `${slug}.mp3`);

      // Synthesize to file (skips if file exists and force is false)
      const result = await elevenLabsService.synthesizeToFile(trimmedText, fullFilePath, { forceRegenerate: force });

      // Update manifest
      try {
        let manifest = { generatedAt: new Date().toISOString(), totalEntries: 0, audio: {} };
        if (fs.existsSync(MANIFEST_FILE)) {
          manifest = JSON.parse(fs.readFileSync(MANIFEST_FILE, 'utf8'));
          manifest.audio = manifest.audio || {};
        }
        manifest.audio[trimmedText] = relativeAssetPath;
        manifest.totalEntries = Object.keys(manifest.audio).length;
        manifest.lastUpdated = new Date().toISOString();
        fs.writeFileSync(MANIFEST_FILE, JSON.stringify(manifest, null, 2), 'utf8');
      } catch (manifestErr) {
        logger.warn('Failed to update audio manifest:', manifestErr.message);
      }

      // Public URL accessible via Express static /assets/audio/tamil/...
      const publicUrl = `/${relativeAssetPath}`;

      return successResponse(res, result.cached ? 'Audio retrieved from cache' : 'Audio generated successfully', {
        text: trimmedText,
        audioPath: relativeAssetPath,
        url: publicUrl,
        sizeBytes: result.sizeBytes,
        cached: result.cached,
      });
    } catch (error) {
      logger.error('Audio synthesis failed:', error.message);
      next(error);
    }
  }

  /**
   * Retrieve current audio manifest
   * GET /api/v1/audio/manifest
   */
  static async getManifest(req, res) {
    try {
      if (fs.existsSync(MANIFEST_FILE)) {
        const manifest = JSON.parse(fs.readFileSync(MANIFEST_FILE, 'utf8'));
        return successResponse(res, 'Audio manifest fetched successfully', manifest);
      }
      return successResponse(res, 'Audio manifest is empty', { totalEntries: 0, audio: {} });
    } catch (error) {
      return errorResponse(res, 'Failed to read audio manifest', null, 500);
    }
  }
}

module.exports = AudioController;
