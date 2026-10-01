/**
 * Letters and Letter Groups Controller
 */
const LetterModel = require('../models/letterModel');
const { successResponse, errorResponse } = require('../utils/apiResponse');

class LetterController {
  static async getAll(req, res, next) {
    try {
      const { type, groupId, meiBase } = req.query;
      const onlyActive = req.query.all !== 'true';

      const letters = await LetterModel.getAll({
        type,
        groupId,
        meiBase,
        onlyActive,
      });

      return successResponse(res, 'Letters fetched successfully', letters);
    } catch (error) {
      next(error);
    }
  }

  static async getById(req, res, next) {
    try {
      const letter = await LetterModel.getById(req.params.id);
      if (!letter) {
        return errorResponse(res, 'Letter not found', null, 404);
      }
      return successResponse(res, 'Letter fetched successfully', letter);
    } catch (error) {
      next(error);
    }
  }

  static async create(req, res, next) {
    try {
      const letter = await LetterModel.create(req.body);
      return successResponse(res, 'Letter created successfully', letter, 201);
    } catch (error) {
      next(error);
    }
  }

  static async update(req, res, next) {
    try {
      const letter = await LetterModel.update(req.params.id, req.body);
      if (!letter) {
        return errorResponse(res, 'Letter not found', null, 404);
      }
      return successResponse(res, 'Letter updated successfully', letter);
    } catch (error) {
      next(error);
    }
  }

  static async delete(req, res, next) {
    try {
      const deleted = await LetterModel.delete(req.params.id);
      if (!deleted) {
        return errorResponse(res, 'Letter not found', null, 404);
      }
      return successResponse(res, 'Letter deleted successfully');
    } catch (error) {
      next(error);
    }
  }

  // --- Groups ---
  static async getGroups(req, res, next) {
    try {
      const { letterType } = req.query;
      const groups = await LetterModel.getGroups({ letterType });
      return successResponse(res, 'Letter groups fetched successfully', groups);
    } catch (error) {
      next(error);
    }
  }

  static async createGroup(req, res, next) {
    try {
      const group = await LetterModel.createGroup(req.body);
      return successResponse(res, 'Letter group created successfully', group, 201);
    } catch (error) {
      next(error);
    }
  }

  // --- Letter Video Management ---
  static async uploadVideo(req, res, next) {
    try {
      const { id } = req.params;
      const letter = await LetterModel.getById(id);
      if (!letter) {
        return errorResponse(res, 'Letter not found', null, 404);
      }
      if (!req.file) {
        return errorResponse(res, 'No video file provided', null, 400);
      }

      const relativePath = `uploads/videos/${req.file.filename}`;
      const updated = await LetterModel.update(id, { video_url: relativePath });

      return successResponse(res, 'Video uploaded and attached to letter successfully', {
        letter: updated,
        videoUrl: `/${relativePath}`,
        path: relativePath,
        filename: req.file.filename,
      }, 200);
    } catch (error) {
      next(error);
    }
  }

  static async deleteVideo(req, res, next) {
    try {
      const { id } = req.params;
      const letter = await LetterModel.getById(id);
      if (!letter) {
        return errorResponse(res, 'Letter not found', null, 404);
      }

      const updated = await LetterModel.update(id, { video_url: null });
      return successResponse(res, 'Video removed from letter successfully', updated);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = LetterController;


