/**
 * Educational Videos Controller
 */
const VideoModel = require('../models/videoModel');
const { successResponse, errorResponse } = require('../utils/apiResponse');

class VideoController {
  static async getAll(req, res, next) {
    try {
      const { category } = req.query;
      const onlyPublished = req.query.all !== 'true';

      const videos = await VideoModel.getAll({ category, onlyPublished });
      return successResponse(res, 'Videos fetched successfully', videos);
    } catch (error) {
      next(error);
    }
  }

  static async getById(req, res, next) {
    try {
      const video = await VideoModel.getById(req.params.id);
      if (!video) {
        return errorResponse(res, 'Video not found', null, 404);
      }
      return successResponse(res, 'Video fetched successfully', video);
    } catch (error) {
      next(error);
    }
  }

  static async create(req, res, next) {
    try {
      const video = await VideoModel.create(req.body);
      return successResponse(res, 'Video created successfully', video, 201);
    } catch (error) {
      next(error);
    }
  }

  static async update(req, res, next) {
    try {
      const video = await VideoModel.update(req.params.id, req.body);
      if (!video) {
        return errorResponse(res, 'Video not found', null, 404);
      }
      return successResponse(res, 'Video updated successfully', video);
    } catch (error) {
      next(error);
    }
  }

  static async delete(req, res, next) {
    try {
      const deleted = await VideoModel.delete(req.params.id);
      if (!deleted) {
        return errorResponse(res, 'Video not found', null, 404);
      }
      return successResponse(res, 'Video deleted successfully');
    } catch (error) {
      next(error);
    }
  }
}

module.exports = VideoController;
