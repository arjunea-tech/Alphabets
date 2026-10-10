/**
 * Languages Controller
 */
const LanguageModel = require('../models/languageModel');
const { successResponse } = require('../utils/apiResponse');

class LanguageController {
  static async getAll(req, res, next) {
    try {
      const onlyActive = req.query.all !== 'true';
      const languages = await LanguageModel.getAll({ onlyActive });
      return successResponse(res, 'Languages fetched successfully', languages);
    } catch (error) {
      next(error);
    }
  }

  static async getByCode(req, res, next) {
    try {
      const language = await LanguageModel.getByCode(req.params.code);
      if (!language) {
        return errorResponse(res, 'Language not found', null, 404);
      }
      return successResponse(res, 'Language fetched successfully', language);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = LanguageController;
