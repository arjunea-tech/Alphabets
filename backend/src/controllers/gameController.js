/**
 * Educational Games Controller
 */
const GameModel = require('../models/gameModel');
const { successResponse, errorResponse } = require('../utils/apiResponse');

class GameController {
  static async getAll(req, res, next) {
    try {
      const { gameType } = req.query;
      const onlyActive = req.query.all !== 'true';

      const games = await GameModel.getAll({ gameType, onlyActive });
      return successResponse(res, 'Games fetched successfully', games);
    } catch (error) {
      next(error);
    }
  }

  static async getById(req, res, next) {
    try {
      const game = await GameModel.getById(req.params.id);
      if (!game) {
        return errorResponse(res, 'Game not found', null, 404);
      }
      return successResponse(res, 'Game fetched successfully', game);
    } catch (error) {
      next(error);
    }
  }

  static async create(req, res, next) {
    try {
      const game = await GameModel.create(req.body);
      return successResponse(res, 'Game created successfully', game, 201);
    } catch (error) {
      next(error);
    }
  }

  static async update(req, res, next) {
    try {
      const game = await GameModel.update(req.params.id, req.body);
      if (!game) {
        return errorResponse(res, 'Game not found', null, 404);
      }
      return successResponse(res, 'Game updated successfully', game);
    } catch (error) {
      next(error);
    }
  }

  static async delete(req, res, next) {
    try {
      const deleted = await GameModel.delete(req.params.id);
      if (!deleted) {
        return errorResponse(res, 'Game not found', null, 404);
      }
      return successResponse(res, 'Game deleted successfully');
    } catch (error) {
      next(error);
    }
  }
}

module.exports = GameController;
