/**
 * App Settings Routes
 *
 * Public:  GET /api/v1/settings/pricing        → price the app shows on the unlock popup
 * Admin:   GET /api/v1/admin/settings/pricing  → same, for the admin panel
 *          PUT /api/v1/admin/settings/pricing  { price_inr } → change the price
 */
const express = require('express');
const { pool } = require('../config/db');
const { verifyToken, requireRole } = require('../middleware/authMiddleware');
const { successResponse, errorResponse } = require('../utils/apiResponse');

const PRICE_KEY = 'content_price_inr';
const DEFAULT_PRICE_INR = 199;

async function getSetting(key) {
  const [rows] = await pool.query('SELECT setting_value FROM app_settings WHERE setting_key = ?', [key]);
  return rows.length ? rows[0].setting_value : null;
}

async function setSetting(key, value) {
  const [result] = await pool.query(
    'UPDATE app_settings SET setting_value = ?, updated_at = CURRENT_TIMESTAMP WHERE setting_key = ?',
    [value, key]
  );
  if (!result.affectedRows) {
    await pool.query('INSERT INTO app_settings (setting_key, setting_value) VALUES (?, ?)', [key, value]);
  }
}

async function readPricing() {
  const raw = await getSetting(PRICE_KEY);
  const price = raw === null ? DEFAULT_PRICE_INR : Number(raw);
  return { price_inr: Number.isFinite(price) ? price : DEFAULT_PRICE_INR, currency: 'INR' };
}

async function sendPricing(req, res, next) {
  try {
    return successResponse(res, 'Pricing fetched', await readPricing());
  } catch (err) {
    return next(err);
  }
}

// Public router (mounted at /settings)
const publicRouter = express.Router();
publicRouter.get('/pricing', sendPricing);

// Admin router (mounted at /admin/settings)
const adminRouter = express.Router();
adminRouter.use(verifyToken, requireRole('super_admin', 'content_admin'));
adminRouter.get('/pricing', sendPricing);
adminRouter.put('/pricing', async (req, res, next) => {
  try {
    const price = Number(req.body?.price_inr);
    if (!Number.isInteger(price) || price < 0 || price > 100000) {
      return errorResponse(res, 'Price must be a whole number between 0 and 100000', null, 400);
    }
    await setSetting(PRICE_KEY, String(price));
    return successResponse(res, 'Price updated', await readPricing());
  } catch (err) {
    return next(err);
  }
});

module.exports = { publicRouter, adminRouter };
