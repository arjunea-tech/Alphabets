import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'cloudinary_media.dart';

class ApiConfig {
  // Custom server IP override if testing on a physical phone on the same Wi-Fi network
  static String? customServerUrl;
  static String? _discoveredBaseUrl;

  /// Override without editing code:
  ///   flutter run --dart-define=API_BASE_URL=http://192.168.1.46:5000/api/v1
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Your PC's Wi-Fi IP (run `ipconfig`). Phones on the same Wi-Fi reach the backend here.
  static const String _lanBaseUrl = 'http://192.168.1.46:5000/api/v1';

  /// Candidate backend URLs for seamless connectivity across physical devices, emulators, and web
  static List<String> get candidateBaseUrls {
    if (customServerUrl != null && customServerUrl!.trim().isNotEmpty) {
      return [customServerUrl!.trim()];
    }
    if (_envBaseUrl.isNotEmpty) return [_envBaseUrl];
    if (_discoveredBaseUrl != null && _discoveredBaseUrl!.isNotEmpty) {
      return [_discoveredBaseUrl!];
    }
    return [
      if (kIsWeb) 'http://localhost:5000/api/v1',
      if (!kIsWeb && Platform.isAndroid) _lanBaseUrl, // physical phone on same Wi-Fi
      if (!kIsWeb && Platform.isAndroid) 'http://10.0.2.2:5000/api/v1', // Android emulator
      'http://localhost:5000/api/v1',
    ];
  }

  static String get baseUrl {
    if (customServerUrl != null && customServerUrl!.trim().isNotEmpty) {
      return customServerUrl!.trim();
    }
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (_discoveredBaseUrl != null && _discoveredBaseUrl!.isNotEmpty) {
      return _discoveredBaseUrl!;
    }
    if (kIsWeb) return 'http://localhost:5000/api/v1';
    if (!kIsWeb && Platform.isAndroid) return _lanBaseUrl;
    return 'http://localhost:5000/api/v1';
  }

  static void setWorkingBaseUrl(String url) {
    _discoveredBaseUrl = url;
  }

  static String get serverRoot {
    return baseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
  }

  static String? resolveMediaUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    final clean = path.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }

    // Images bundled inside the app load instantly from the device —
    // never re-download them from Cloudinary.
    if (clean.startsWith('assets/')) {
      return clean;
    }

    // Check Cloudinary mapping first
    final cloudinaryUrl = CloudinaryMedia.getUrl(clean);
    if (cloudinaryUrl != null && (cloudinaryUrl.startsWith('http://') || cloudinaryUrl.startsWith('https://'))) {
      return cloudinaryUrl;
    }

    if (clean.startsWith('uploads/') || clean.startsWith('/uploads/')) {
      final sub = clean.startsWith('/') ? clean.substring(1) : clean;
      return '$serverRoot/$sub';
    }
    return clean;
  }
}
