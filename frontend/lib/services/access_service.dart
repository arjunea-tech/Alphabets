import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

/// SAMPLE MODE
/// -----------
/// While this is `true`, every scratch code is accepted and payment is only
/// simulated, so everyone gets in. When the server is ready, set it to `false`
/// and fill in the two TODOs below (verify code / verify payment on the server).
const bool kAccessSampleMode = true;

/// How the user unlocked the content.
enum AccessMethod { scratchCode, payment }

class AccessResult {
  final bool isSuccess;
  final String message;

  const AccessResult._(this.isSuccess, this.message);
  const AccessResult.success(String message) : this._(true, message);
  const AccessResult.failure(String message) : this._(false, message);
}

/// Keeps track of whether the signed-in user has unlocked the full content,
/// either with the scratch code printed in the book or by paying in the app.
class AccessService {
  AccessService._();
  static final AccessService instance = AccessService._();

  /// Used until the server price has loaded once (admin edits it in Settings).
  static const int defaultPriceInr = 199;

  static const String _keyPrefix = 'agaram_access_';
  static const String _keyPrice = 'agaram_content_price_inr';

  /// Price set by the admin. Falls back to the last price seen, then the default.
  Future<int> fetchPriceInr() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/settings/pricing'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = (jsonDecode(res.body) as Map<String, dynamic>)['data'];
        final price = (data is Map ? data['price_inr'] : null) as num?;
        if (price != null) {
          await prefs.setInt(_keyPrice, price.toInt());
          return price.toInt();
        }
      }
    } catch (e) {
      debugPrint('AccessService: could not load price: $e');
    }
    return prefs.getInt(_keyPrice) ?? defaultPriceInr;
  }
  static const String _keyAuthUser = 'agaram_auth_user'; // same keys AuthService uses
  static const String _keyAuthToken = 'agaram_auth_token';

  /// Id of the user saved by AuthService, or 'guest' if none.
  Future<String> currentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyAuthUser);
      if (raw != null && raw.isNotEmpty) {
        final id = (jsonDecode(raw) as Map<String, dynamic>)['id']?.toString();
        if (id != null && id.isNotEmpty) return id;
      }
    } catch (e) {
      debugPrint('AccessService: could not read user id: $e');
    }
    return 'guest';
  }

  /// True when this user already unlocked the content — on this phone, or on
  /// their account on the server (paid once → never asked again, any device).
  Future<bool> hasAccess() async {
    final userId = await currentUserId();
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool('$_keyPrefix$userId') ?? false) {
      // Unlocked while the server was unreachable → tell the server now.
      final pending = prefs.getString('$_keyPrefix${userId}_pending');
      if (pending != null) {
        final method = AccessMethod.values.firstWhere(
          (m) => m.name == pending,
          orElse: () => AccessMethod.payment,
        );
        if (await _postUnlock(method) == null) {
          await prefs.remove('$_keyPrefix${userId}_pending');
        }
      }
      return true;
    }

    // Not unlocked on this phone: ask the server (e.g. new phone / reinstall).
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/users/access'), headers: await _authHeaders())
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = (jsonDecode(res.body) as Map<String, dynamic>)['data'];
        if (data is Map && data['has_access'] == true) {
          await prefs.setBool('$_keyPrefix$userId', true);
          return true;
        }
      }
    } catch (e) {
      debugPrint('AccessService: could not check access on server: $e');
    }
    return false;
  }

  /// Redeem the scratch code from the book.
  Future<AccessResult> redeemScratchCode(String code) async {
    final cleaned = code.trim().toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
    if (cleaned.isEmpty) {
      return const AccessResult.failure('Please enter the scratch code.');
    }
    return _unlock(AccessMethod.scratchCode, code: cleaned,
        successMessage: 'Code accepted! Enjoy learning 🎉');
  }

  /// Buy the content inside the app.
  Future<AccessResult> purchase() async {
    // TODO(server): open the payment gateway (Razorpay / Play Billing etc.) here
    // and send its payment id to the server along with the unlock request.
    return _unlock(AccessMethod.payment,
        successMessage: 'Payment successful! Enjoy learning 🎉');
  }

  Future<AccessResult> _unlock(
    AccessMethod method, {
    String? code,
    required String successMessage,
  }) async {
    final error = await _postUnlock(method, code: code);
    final userId = await currentUserId();
    final prefs = await SharedPreferences.getInstance();

    if (error != null) {
      if (!kAccessSampleMode) return AccessResult.failure(error);
      // Sample mode: let them in anyway and sync with the server later.
      await prefs.setString('$_keyPrefix${userId}_pending', method.name);
    }
    await prefs.setBool('$_keyPrefix$userId', true);
    await prefs.setString('$_keyPrefix${userId}_method', method.name);
    return AccessResult.success(successMessage);
  }

  /// Saves the unlock on the user's account. Returns null on success, else an error message.
  Future<String?> _postUnlock(AccessMethod method, {String? code}) async {
    try {
      final res = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/users/access'),
            headers: {...await _authHeaders(), 'Content-Type': 'application/json'},
            body: jsonEncode({
              'method': method == AccessMethod.scratchCode ? 'scratch_code' : 'payment',
              if (code != null) 'code': code,
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return null;
      if (res.statusCode == 404 && kAccessSampleMode) return null;
      final msg = (jsonDecode(res.body) as Map<String, dynamic>)['message']?.toString();
      return msg ?? 'Could not unlock (error ${res.statusCode})';
    } catch (e) {
      debugPrint('AccessService: unlock request failed: $e');
      return 'Could not reach the server. Please check your internet connection.';
    }
  }

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyAuthToken);
    return {if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token'};
  }
}
