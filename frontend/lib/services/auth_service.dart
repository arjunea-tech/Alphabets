import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_user_model.dart';
import 'api_config.dart';

class AuthService extends ChangeNotifier {
  static const String _keyToken = 'agaram_auth_token';
  static const String _keyUser = 'agaram_auth_user';

  AuthUserModel? _currentUser;
  String? _token;
  bool _isLoading = false;

  AuthUserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get isLoading => _isLoading;

  AuthService() {
    loadSession();
  }

  /// Load session from SharedPreferences
  Future<bool> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_keyToken);
      final userJsonStr = prefs.getString(_keyUser);

      if (userJsonStr != null && userJsonStr.isNotEmpty) {
        final Map<String, dynamic> userMap = jsonDecode(userJsonStr);
        _currentUser = AuthUserModel.fromJson(userMap, token: _token);
      }

      notifyListeners();
      return isAuthenticated;
    } catch (e) {
      debugPrint('Error loading auth session: $e');
      return false;
    }
  }

  /// Register a new user
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    final candidates = ApiConfig.candidateBaseUrls;
    http.Response? response;
    String? lastError;

    for (final base in candidates) {
      try {
        final url = Uri.parse('$base/users/register');
        final res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name.trim(),
            'email': email.trim().toLowerCase(),
            'password': password,
          }),
        ).timeout(const Duration(seconds: 12));

        ApiConfig.setWorkingBaseUrl(base);
        response = res;
        break;
      } catch (e) {
        lastError = _describeConnectionError(base, e);
        continue;
      }
    }

    if (response == null) {
      _isLoading = false;
      notifyListeners();
      return AuthResult.failure(
        'Could not connect to server. Please check internet connection.'
        '${lastError != null ? '\n($lastError)' : ''}',
      );
    }

    try {
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = responseData['data'] as Map<String, dynamic>;
        final token = data['token']?.toString() ?? '';
        final userMap = data['user'] as Map<String, dynamic>;
        final user = AuthUserModel.fromJson(userMap, token: token);

        await _persistSession(token, user);
        _isLoading = false;
        notifyListeners();

        return AuthResult.success(user, 'Registration successful!');
      } else if (response.statusCode == 409) {
        _isLoading = false;
        notifyListeners();
        return AuthResult.failure(
          'This email is already registered.',
        );
      } else {
        _isLoading = false;
        notifyListeners();
        final msg = responseData['message']?.toString() ?? 'Failed to register';
        return AuthResult.failure(_translateError(msg));
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return AuthResult.failure('Temporary service error. Please try again.');
    }
  }

  /// Login with email and password
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    final candidates = ApiConfig.candidateBaseUrls;
    http.Response? response;
    String? lastError;

    for (final base in candidates) {
      try {
        final url = Uri.parse('$base/users/login');
        final res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email.trim().toLowerCase(),
            'password': password,
          }),
        ).timeout(const Duration(seconds: 12));

        ApiConfig.setWorkingBaseUrl(base);
        response = res;
        break;
      } catch (e) {
        lastError = _describeConnectionError(base, e);
        continue;
      }
    }

    if (response == null) {
      _isLoading = false;
      notifyListeners();
      return AuthResult.failure(
        'Could not connect to server. Please check internet connection.'
        '${lastError != null ? '\n($lastError)' : ''}',
      );
    }

    try {
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final data = responseData['data'] as Map<String, dynamic>;
        final token = data['token']?.toString() ?? '';
        final userMap = data['user'] as Map<String, dynamic>;
        final user = AuthUserModel.fromJson(userMap, token: token);

        await _persistSession(token, user);
        _isLoading = false;
        notifyListeners();

        return AuthResult.success(user, 'Login successful!');
      } else if (response.statusCode == 401) {
        _isLoading = false;
        notifyListeners();
        return AuthResult.failure('Invalid email or password.');
      } else {
        _isLoading = false;
        notifyListeners();
        final msg = responseData['message']?.toString() ?? 'Login failed';
        return AuthResult.failure(_translateError(msg));
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return AuthResult.failure('Temporary service error. Please try again.');
    }
  }

  /// Logout and clear storage
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUser);
    } catch (e) {
      debugPrint('Error clearing auth session: $e');
    } finally {
      _token = null;
      _currentUser = null;
      notifyListeners();
    }
  }

  Future<void> _persistSession(String token, AuthUserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
    _token = token;
    _currentUser = user;
  }

  /// Short, human-readable reason a request never got a response, shown under
  /// the generic message so connection problems can be diagnosed from a screenshot.
  String _describeConnectionError(String base, Object e) {
    final host = Uri.tryParse(base)?.host ?? base;
    String reason;
    if (e is TimeoutException) {
      reason = 'timed out';
    } else if (e is HandshakeException || e is TlsException) {
      reason = 'secure connection (SSL) failed: ${e.toString().split('\n').first}';
    } else if (e is SocketException) {
      final socketError = e;
      reason = 'network error: ${socketError.osError?.message ?? socketError.message}';
    } else if (e is http.ClientException) {
      reason = 'client error: ${e.message}';
    } else {
      reason = '${e.runtimeType}: $e';
    }
    final text = '$host – $reason';
    return text.length > 160 ? '${text.substring(0, 160)}…' : text;
  }

  String _translateError(String raw) {
    if (raw.contains('already registered')) {
      return 'This email is already registered.';
    }
    if (raw.contains('Invalid credentials')) {
      return 'Invalid email or password.';
    }
    if (raw.contains('Email') && raw.contains('required')) {
      return 'Email is required.';
    }
    if (raw.contains('Password') && raw.contains('required')) {
      return 'Password is required.';
    }
    if (raw.contains('at least 6 characters')) {
      return 'Password must be at least 6 characters.';
    }
    return raw;
  }
}

class AuthResult {
  final bool isSuccess;
  final AuthUserModel? user;
  final String message;

  const AuthResult._({
    required this.isSuccess,
    this.user,
    required this.message,
  });

  factory AuthResult.success(AuthUserModel user, [String message = '']) {
    return AuthResult._(isSuccess: true, user: user, message: message);
  }

  factory AuthResult.failure(String errorMessage) {
    return AuthResult._(isSuccess: false, message: errorMessage);
  }
}
