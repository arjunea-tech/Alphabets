/**
 * Child User Profile & Session Controller
 */
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
let OAuth2Client;
try {
  ({ OAuth2Client } = require('google-auth-library'));
} catch (e) {
  OAuth2Client = null;
}
const UserModel = require('../models/userModel');
const config = require('../config/env');
const { successResponse, errorResponse } = require('../utils/apiResponse');

// Accepts GOOGLE_CLIENT_IDS (comma-separated: web, android, ios) or a single GOOGLE_CLIENT_ID.
const googleClientIds = (process.env.GOOGLE_CLIENT_IDS || process.env.GOOGLE_CLIENT_ID || '')
  .split(',')
  .map((id) => id.trim())
  .filter(Boolean);
const googleClient = OAuth2Client ? new OAuth2Client() : null;

/** Verifies a Google ID token (Android/iOS) and returns the profile. Throws if invalid. */
async function verifyGoogleIdToken(idToken) {
  const ticket = await googleClient.verifyIdToken({ idToken, audience: googleClientIds });
  const p = ticket.getPayload() || {};
  return {
    email: p.email,
    emailVerified: p.email_verified === true,
    name: p.name,
    picture: p.picture,
  };
}

/**
 * Verifies a Google OAuth access token (Web sign-in returns no ID token).
 * Checks the token was issued to one of OUR client IDs, then reads the profile.
 */
async function verifyGoogleAccessToken(accessToken) {
  const infoRes = await fetch(
    `https://oauth2.googleapis.com/tokeninfo?access_token=${encodeURIComponent(accessToken)}`
  );
  if (!infoRes.ok) throw new Error(`tokeninfo HTTP ${infoRes.status}`);
  const info = await infoRes.json();
  const audience = info.aud || info.azp;
  if (!googleClientIds.includes(audience)) {
    throw new Error('access token was issued to a different client');
  }

  const userRes = await fetch('https://openidconnect.googleapis.com/v1/userinfo', {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!userRes.ok) throw new Error(`userinfo HTTP ${userRes.status}`);
  const u = await userRes.json();
  if (u.sub !== info.sub) throw new Error('token subject mismatch');
  return {
    email: u.email,
    emailVerified: u.email_verified === true,
    name: u.name,
    picture: u.picture,
  };
}

class UserAuthController {
  /**
   * Register a new user with Name, Email, Password
   */
  static async register(req, res, next) {
    try {
      const { name, childName, email, password, age, avatarAsset } = req.body;
      const fullName = (name || childName || '').trim();

      if (!fullName) {
        return errorResponse(res, 'உங்கள் பெயரை உள்ளிடவும் (Name is required)', null, 400);
      }

      if (!email || !email.includes('@')) {
        return errorResponse(res, 'சரியான மின்னஞ்சல் முகவரியை உள்ளிடவும் (Valid email is required)', null, 400);
      }

      if (!password || password.length < 6) {
        return errorResponse(res, 'கடவுச்சொல் குறைந்தது 6 எழுத்துகள் இருக்க வேண்டும் (Password must be at least 6 characters)', null, 400);
      }

      // Check if email already registered
      const existingUser = await UserModel.findByEmail(email);
      if (existingUser) {
        return errorResponse(res, 'இந்த மின்னஞ்சல் ஏற்கனவே பதிவு செய்யப்பட்டுள்ளது. (Email already registered)', null, 409);
      }

      // Hash password
      const salt = await bcrypt.genSalt(10);
      const passwordHash = await bcrypt.hash(password, salt);

      // Unique user ID
      const userId = `user_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;

      const user = await UserModel.create({
        id: userId,
        name: fullName,
        email: email.trim().toLowerCase(),
        passwordHash,
        age: age || 5,
        avatarAsset: avatarAsset || 'assets/images/welcome.png',
      });

      // Generate JWT
      const token = jwt.sign(
        {
          id: user.id,
          email: user.email,
          name: user.child_name,
          role: 'user',
        },
        config.jwt.secret,
        { expiresIn: config.jwt.expiresIn || '30d' }
      );

      return successResponse(
        res,
        'பதிவு வெற்றிகரமாக முடிந்தது! (Registration successful)',
        {
          token,
          user: {
            id: user.id,
            name: user.child_name,
            child_name: user.child_name,
            email: user.email,
            age: user.age,
            avatarAsset: user.avatar_asset,
            avatar_asset: user.avatar_asset,
            totalStars: user.total_stars,
            total_stars: user.total_stars,
            createdAt: user.created_at,
          },
        },
        201
      );
    } catch (error) {
      next(error);
    }
  }

  /**
   * Login with Email and Password
   */
  static async login(req, res, next) {
    try {
      const { email, username, identifier, password } = req.body;
      const credential = (email || username || identifier || req.body.name || '').trim();

      if (!credential || !password) {
        return errorResponse(res, 'மின்னஞ்சல் அல்லது பயனர் பெயர் மற்றும் கடவுச்சொல் தேவை (Username/Email and password are required)', null, 400);
      }

      const user = await UserModel.findByEmail(credential);
      if (!user || !user.is_active) {
        return errorResponse(res, 'மின்னஞ்சல் அல்லது கடவுச்சொல் தவறாக உள்ளது. (Invalid email or password)', null, 401);
      }

      if (!user.password_hash) {
        return errorResponse(res, 'மின்னஞ்சல் அல்லது கடவுச்சொல் தவறாக உள்ளது. (Invalid credentials)', null, 401);
      }

      const isMatch = await bcrypt.compare(password, user.password_hash);
      if (!isMatch) {
        return errorResponse(res, 'மின்னஞ்சல் அல்லது கடவுச்சொல் தவறாக உள்ளது. (Invalid email or password)', null, 401);
      }

      // Generate JWT
      const token = jwt.sign(
        {
          id: user.id,
          email: user.email,
          name: user.child_name,
          role: 'user',
        },
        config.jwt.secret,
        { expiresIn: config.jwt.expiresIn || '30d' }
      );

      return successResponse(res, 'உள்நுழைவு வெற்றிகரமாக முடிந்தது! (Login successful)', {
        token,
        user: {
          id: user.id,
          name: user.child_name,
          child_name: user.child_name,
          email: user.email,
          age: user.age,
          avatarAsset: user.avatar_asset,
          avatar_asset: user.avatar_asset,
          totalStars: user.total_stars,
          total_stars: user.total_stars,
          createdAt: user.created_at,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Google Sign-In / Registration
   */
  static async googleLogin(req, res, next) {
    try {
      const { idToken, accessToken, email, name, photoUrl } = req.body;

      let userEmail = (email || '').trim().toLowerCase();
      let userName = (name || '').trim();
      let userAvatar = photoUrl || 'assets/images/welcome.png';
      const safeAvatar = (userAvatar && userAvatar.length <= 250) ? userAvatar : 'assets/images/welcome.png';

      // 1. If Google client IDs are configured, verify the token
      if (googleClient && googleClientIds.length > 0 && (idToken || accessToken)) {
        try {
          const profile = idToken
            ? await verifyGoogleIdToken(idToken)
            : await verifyGoogleAccessToken(accessToken);
          if (profile && profile.email) {
            userEmail = profile.email.toLowerCase();
            userName = (profile.name || userName).trim();
            userAvatar = profile.picture || safeAvatar;
          }
        } catch (tokenErr) {
          console.warn('Google token verification failed (fallback to profile):', tokenErr.message);
        }
      }

      if (!userEmail) {
        return errorResponse(res, 'Google email not received', null, 400);
      }

      // 2. Check if user already exists
      let user = await UserModel.findByEmail(userEmail);
      if (!user) {
        const userId = `user_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
        user = await UserModel.create({
          id: userId,
          name: userName || 'Arjun',
          email: userEmail,
          passwordHash: null,
          age: 5,
          avatarAsset: safeAvatar,
        });
      }

      // 3. Generate JWT
      const token = jwt.sign(
        {
          id: user.id,
          email: user.email,
          name: user.child_name,
          role: 'user',
        },
        config.jwt.secret,
        { expiresIn: config.jwt.expiresIn || '30d' }
      );

      return successResponse(
        res,
        'Google Sign-In successful!',
        {
          token,
          user: {
            id: user.id,
            name: user.child_name,
            child_name: user.child_name,
            email: user.email,
            age: user.age,
            avatarAsset: user.avatar_asset,
            avatar_asset: user.avatar_asset,
            totalStars: user.total_stars,
            total_stars: user.total_stars,
            createdAt: user.created_at,
          },
        }
      );
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get Current Authenticated User Profile
   */
  static async me(req, res, next) {
    try {
      const user = await UserModel.findById(req.user.id);
      if (!user) {
        return errorResponse(res, 'பயனர் விவரம் கிடைக்கவில்லை (User not found)', null, 404);
      }

      return successResponse(res, 'Profile fetched successfully', {
        id: user.id,
        name: user.child_name,
        child_name: user.child_name,
        email: user.email,
        age: user.age,
        avatarAsset: user.avatar_asset,
        avatar_asset: user.avatar_asset,
        totalStars: user.total_stars,
        total_stars: user.total_stars,
        createdAt: user.created_at,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Legacy Register or Initialize Child Profile (Guest session support)
   */
  static async registerOrInit(req, res, next) {
    try {
      // If password and email are provided, delegate to real register
      if (req.body.password && req.body.email) {
        return UserAuthController.register(req, res, next);
      }

      const { id, childName, age, avatarAsset } = req.body;
      const userId = id || `child_${Date.now()}`;

      const user = await UserModel.createOrUpdate({
        id: userId,
        childName,
        age,
        avatarAsset,
      });

      return successResponse(res, 'Child profile saved successfully', user, 201);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Fetch Profile by ID
   */
  static async getProfile(req, res, next) {
    try {
      const { id } = req.params;
      const user = await UserModel.findById(id);

      if (!user) {
        return errorResponse(res, 'Child profile not found', null, 404);
      }

      return successResponse(res, 'Profile fetched successfully', user);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update Child Profile
   */
  static async updateProfile(req, res, next) {
    try {
      const { id } = req.params;
      const { childName, age, avatarAsset } = req.body;

      const user = await UserModel.updateProfile(id, {
        childName,
        age,
        avatarAsset,
      });

      if (!user) {
        return errorResponse(res, 'Child profile not found', null, 404);
      }

      return successResponse(res, 'Profile updated successfully', user);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = UserAuthController;
