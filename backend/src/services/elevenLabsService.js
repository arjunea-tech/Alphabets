/**
 * Centralized ElevenLabs Tamil TTS Service for AGARAM
 * Communicates with official ElevenLabs JavaScript SDK
 * Converts Tamil text to MP3 with local file caching and safe error handling.
 */
const fs = require('fs');
const path = require('path');
const config = require('../config/env');
const logger = require('../utils/logger');

class ElevenLabsService {
  constructor() {
    this._client = null;
    this.voiceId = config.elevenlabs.voiceId;
    this.modelId = config.elevenlabs.modelId || 'eleven_multilingual_v2';
    this.outputFormat = config.elevenlabs.outputFormat || 'mp3_44100_128';
  }

  /**
   * Lazy-initialize the ElevenLabsClient to ensure environment variables are loaded
   * and errors are captured without exposing secrets.
   */
  getClient() {
    if (this._client) return this._client;

    const apiKey = config.elevenlabs.apiKey;
    if (!apiKey) {
      throw new Error('ELEVENLABS_API_KEY is not configured in backend/.env');
    }

    let ElevenLabsClient;
    try {
      const sdk = require('@elevenlabs/elevenlabs-js');
      ElevenLabsClient = sdk.ElevenLabsClient || sdk.default || sdk;
    } catch (err1) {
      try {
        const sdk = require('elevenlabs');
        ElevenLabsClient = sdk.ElevenLabsClient || sdk.default || sdk;
      } catch (err2) {
        throw new Error('Neither @elevenlabs/elevenlabs-js nor elevenlabs could be loaded.');
      }
    }

    this._client = new ElevenLabsClient({ apiKey });
    return this._client;
  }

  /**
   * Synthesize speech for Tamil text and save to destination path.
   * If the file already exists and is non-empty, skips synthesis.
   *
   * @param {string} text - Tamil text to pronounce
   * @param {string} destFilePath - Absolute or relative path to save MP3
   * @param {Object} options - Optional overrides (voiceId, forceRegenerate)
   * @returns {Promise<{ filePath: string, sizeBytes: number, cached: boolean }>}
   */
  async synthesizeToFile(text, destFilePath, options = {}) {
    if (!text || !text.trim()) {
      throw new Error('Text is required for ElevenLabs synthesis');
    }

    const trimmedText = text.trim();
    const resolvedPath = path.resolve(destFilePath);
    const force = options.forceRegenerate || false;

    // Check existing cache
    if (!force && fs.existsSync(resolvedPath)) {
      const stats = fs.statSync(resolvedPath);
      if (stats.size > 100) {
        return {
          filePath: resolvedPath,
          sizeBytes: stats.size,
          cached: true,
        };
      }
    }

    const client = this.getClient();
    const voiceId = options.voiceId || this.voiceId;
    if (!voiceId) {
      throw new Error('ELEVENLABS_VOICE_ID is not configured in backend/.env');
    }

    // Ensure target directory exists
    const dir = path.dirname(resolvedPath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }

    // Call ElevenLabs convert API
    // Official method: client.textToSpeech.convert(voiceId, { text, model_id, output_format })
    const audioStream = await client.textToSpeech.convert(voiceId, {
      text: trimmedText,
      model_id: options.modelId || this.modelId,
      output_format: options.outputFormat || this.outputFormat,
    });

    // Write stream chunks to file
    const chunks = [];
    if (audioStream[Symbol.asyncIterator]) {
      for await (const chunk of audioStream) {
        chunks.push(chunk);
      }
    } else if (Buffer.isBuffer(audioStream)) {
      chunks.push(audioStream);
    } else if (typeof audioStream.pipe === 'function') {
      await new Promise((resolve, reject) => {
        const writer = fs.createWriteStream(resolvedPath);
        audioStream.pipe(writer);
        writer.on('finish', resolve);
        writer.on('error', reject);
      });
      const stats = fs.statSync(resolvedPath);
      return {
        filePath: resolvedPath,
        sizeBytes: stats.size,
        cached: false,
      };
    }

    const buffer = Buffer.concat(chunks);
    fs.writeFileSync(resolvedPath, buffer);

    return {
      filePath: resolvedPath,
      sizeBytes: buffer.length,
      cached: false,
    };
  }
}

module.exports = new ElevenLabsService();
