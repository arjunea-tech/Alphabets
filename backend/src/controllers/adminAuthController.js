/**
 * Admin Authentication Controller
 */
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const AdminModel = require('../models/adminModel');
const config = require('../config/env');
const { successResponse, errorResponse } = require('../utils/apiResponse');

class AdminAuthController {
  /**
   * Admin Login
   */
  static async login(req, res, next) {
    try {
      const { username, password } = req.body;

      if (!username || !password) {
        return errorResponse(res, 'Username and password are required', null, 400);
      }

      const admin = await AdminModel.findByUsernameOrEmail(username);
      if (!admin || !admin.is_active) {
        return errorResponse(res, 'Invalid credentials or inactive account', null, 401);
      }

      const isMatch = await bcrypt.compare(password, admin.password_hash);
      if (!isMatch) {
        return errorResponse(res, 'Invalid credentials', null, 401);
      }

      const token = jwt.sign(
        {
          id: admin.id,
          username: admin.username,
          email: admin.email,
          role: admin.role,
        },
        config.jwt.secret,
        { expiresIn: config.jwt.expiresIn }
      );

      const fullName = admin.full_name || admin.fullName || admin.username || 'Admin';

      return successResponse(res, 'Admin logged in successfully', {
        token,
        admin: {
          id: admin.id,
          username: admin.username,
          email: admin.email,
          fullName: fullName,
          full_name: fullName,
          role: admin.role,
          is_active: admin.is_active,
          created_at: admin.created_at,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get Current Admin Profile
   */
  static async me(req, res, next) {
    try {
      const admin = await AdminModel.findById(req.user.id);
      if (!admin) {
        return errorResponse(res, 'Admin not found', null, 404);
      }
      const fullName = admin.full_name || admin.fullName || admin.username || 'Admin';
      return successResponse(res, 'Admin profile fetched successfully', {
        id: admin.id,
        username: admin.username,
        email: admin.email,
        fullName: fullName,
        full_name: fullName,
        role: admin.role,
        is_active: admin.is_active,
        created_at: admin.created_at,
        updated_at: admin.updated_at,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Change Password
   */
  static async changePassword(req, res, next) {
    try {
      const { currentPassword, newPassword } = req.body;
      const admin = await AdminModel.findByUsername(req.user.username);

      if (!admin) {
        return errorResponse(res, 'Admin not found', null, 404);
      }

      const isMatch = await bcrypt.compare(currentPassword, admin.password_hash);
      if (!isMatch) {
        return errorResponse(res, 'Current password does not match', null, 400);
      }

      const salt = await bcrypt.genSalt(10);
      const newHash = await bcrypt.hash(newPassword, salt);
      await AdminModel.updatePassword(admin.id, newHash);

      return successResponse(res, 'Password changed successfully');
    } catch (error) {
      next(error);
    }
  }

  /**
   * Create New Admin (Super Admin only)
   */
  static async createAdmin(req, res, next) {
    try {
      const { username, email, password, role, fullName } = req.body;

      const existingUser = await AdminModel.findByUsername(username);
      if (existingUser) {
        return errorResponse(res, 'Username already exists', null, 409);
      }

      const existingEmail = await AdminModel.findByEmail(email);
      if (existingEmail) {
        return errorResponse(res, 'Email already exists', null, 409);
      }

      const salt = await bcrypt.genSalt(10);
      const passwordHash = await bcrypt.hash(password, salt);

      const adminId = await AdminModel.create({
        username,
        email,
        passwordHash,
        role: role || 'content_admin',
        fullName,
      });

      const newAdmin = await AdminModel.findById(adminId);
      const fullNameResult = newAdmin.full_name || newAdmin.fullName || newAdmin.username || fullName;
      return successResponse(res, 'Admin created successfully', {
        id: newAdmin.id,
        username: newAdmin.username,
        email: newAdmin.email,
        fullName: fullNameResult,
        full_name: fullNameResult,
        role: newAdmin.role,
        is_active: newAdmin.is_active,
        created_at: newAdmin.created_at,
      }, 201);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = AdminAuthController;
