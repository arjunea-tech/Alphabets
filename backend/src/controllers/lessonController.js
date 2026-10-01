/**
 * Lesson Categories Controller
 */
const LessonModel = require('../models/lessonModel');
const { successResponse, errorResponse } = require('../utils/apiResponse');

class LessonController {
  static async getAll(req, res, next) {
    try {
      const onlyActive = req.query.all !== 'true';
      const lessons = await LessonModel.getAll({ onlyActive });
      return successResponse(res, 'Lessons fetched successfully', lessons);
    } catch (error) {
      next(error);
    }
  }

  static async getById(req, res, next) {
    try {
      const lesson = await LessonModel.getById(req.params.id);
      if (!lesson) {
        return errorResponse(res, 'Lesson not found', null, 404);
      }
      return successResponse(res, 'Lesson fetched successfully', lesson);
    } catch (error) {
      next(error);
    }
  }

  static async create(req, res, next) {
    try {
      const lesson = await LessonModel.create(req.body);
      return successResponse(res, 'Lesson created successfully', lesson, 201);
    } catch (error) {
      next(error);
    }
  }

  static async update(req, res, next) {
    try {
      const lesson = await LessonModel.update(req.params.id, req.body);
      if (!lesson) {
        return errorResponse(res, 'Lesson not found', null, 404);
      }
      return successResponse(res, 'Lesson updated successfully', lesson);
    } catch (error) {
      next(error);
    }
  }

  static async delete(req, res, next) {
    try {
      const deleted = await LessonModel.delete(req.params.id);
      if (!deleted) {
        return errorResponse(res, 'Lesson not found', null, 404);
      }
      return successResponse(res, 'Lesson deleted successfully');
    } catch (error) {
      next(error);
    }
  }
}

module.exports = LessonController;
