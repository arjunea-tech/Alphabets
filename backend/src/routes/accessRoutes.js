/**
 * Content Access Routes (/api/v1/users/access)
 *
 * Stores on the user's account that they unlocked the content (scratch code from
 * the book, or in-app payment), so they are never asked again after logging in,
 * on any device.
 *
 *   GET  /users/access                      → { has_access, method, granted_at }
 *   POST /users/access { method, code? }    → unlock for the signed-in user
 *
 * SAMPLE MODE: while ACCESS_SAMPLE_MODE is true every code / payment is accepted.
 */
const express = require('express');
const { pool } = require('../config/db');
const { verifyToken } = require('../middleware/authMiddleware');
const { successResponse, errorResponse } = require('../utils/apiResponse');

// TODO(server): set to false once scratch codes and payment are verified below.
const ACCESS_SAMPLE_MODE = true;
const METHODS = ['scratch_code', 'payment'];

const router = express.Router();
router.use(verifyToken);

async function readAccess(userId) {
  const [rows] = await pool.query(
    'SELECT has_content_access, access_method, access_granted_at FROM users WHERE id = ?',
    [userId]
  );
  if (!rows.length) return null;
  const row = rows[0];
  return {
    has_access: Boolean(row.has_content_access),
    method: row.access_method || null,
    granted_at: row.access_granted_at || null,
  };
}

router.get('/', async (req, res, next) => {
  try {
    const access = await readAccess(req.user.id);
    if (!access) return errorResponse(res, 'User not found', null, 404);
    return successResponse(res, 'Access status fetched', access);
  } catch (err) {
    return next(err);
  }
});

router.post('/', async (req, res, next) => {
  try {
    const method = String(req.body?.method || '');
    if (!METHODS.includes(method)) {
      return errorResponse(res, `method must be one of: ${METHODS.join(', ')}`, null, 400);
    }

    const current = await readAccess(req.user.id);
    if (!current) return errorResponse(res, 'User not found', null, 404);
    if (current.has_access) return successResponse(res, 'Already unlocked', current);

    if (!ACCESS_SAMPLE_MODE) {
      // TODO(server): scratch_code → check req.body.code exists and is unused, mark it used.
      // TODO(server): payment → verify the gateway payment id / signature.
      return errorResponse(res, 'Unlocking is not available yet', null, 501);
    }

    await pool.query(
      `UPDATE users
       SET has_content_access = TRUE, access_method = ?, access_granted_at = CURRENT_TIMESTAMP
       WHERE id = ?`,
      [method, req.user.id]
    );
    return successResponse(res, 'Content unlocked', await readAccess(req.user.id));
  } catch (err) {
    return next(err);
  }
});

module.exports = router;
