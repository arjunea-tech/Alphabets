/**
 * Reading Stories Controller
 */
const StoryModel = require('../models/storyModel');
const { successResponse, errorResponse } = require('../utils/apiResponse');

class StoryController {
  static async getAll(req, res, next) {
    try {
      const onlyPublished = req.query.all !== 'true';
      const stories = await StoryModel.getAll({ onlyPublished });
      return successResponse(res, 'Stories fetched successfully', stories);
    } catch (error) {
      next(error);
    }
  }

  static async getById(req, res, next) {
    try {
      const story = await StoryModel.getById(req.params.id);
      if (!story) {
        return errorResponse(res, 'Story not found', null, 404);
      }
      return successResponse(res, 'Story fetched successfully', story);
    } catch (error) {
      next(error);
    }
  }

  static async create(req, res, next) {
    try {
      const { pages, ...storyData } = req.body;
      const story = await StoryModel.create(storyData);

      if (pages && Array.isArray(pages)) {
        for (const page of pages) {
          await StoryModel.addPage(story.id, page);
        }
      }

      const fullStory = await StoryModel.getById(story.id);
      return successResponse(res, 'Story created successfully', fullStory, 201);
    } catch (error) {
      next(error);
    }
  }

  static async update(req, res, next) {
    try {
      const story = await StoryModel.update(req.params.id, req.body);
      if (!story) {
        return errorResponse(res, 'Story not found', null, 404);
      }
      return successResponse(res, 'Story updated successfully', story);
    } catch (error) {
      next(error);
    }
  }

  static async delete(req, res, next) {
    try {
      const deleted = await StoryModel.delete(req.params.id);
      if (!deleted) {
        return errorResponse(res, 'Story not found', null, 404);
      }
      return successResponse(res, 'Story deleted successfully');
    } catch (error) {
      next(error);
    }
  }

  // --- Story Pages ---
  static async addPage(req, res, next) {
    try {
      const pageId = await StoryModel.addPage(req.params.id, req.body);
      const updatedStory = await StoryModel.getById(req.params.id);
      return successResponse(res, 'Story page added successfully', { pageId, story: updatedStory }, 201);
    } catch (error) {
      next(error);
    }
  }

  static async updatePage(req, res, next) {
    try {
      await StoryModel.updatePage(req.params.pageId, req.body);
      return successResponse(res, 'Story page updated successfully');
    } catch (error) {
      next(error);
    }
  }

  static async deletePage(req, res, next) {
    try {
      const deleted = await StoryModel.deletePage(req.params.pageId);
      if (!deleted) {
        return errorResponse(res, 'Story page not found', null, 404);
      }
      return successResponse(res, 'Story page deleted successfully');
    } catch (error) {
      next(error);
    }
  }
}

module.exports = StoryController;
