import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'cloudinary_media.dart';

class ApiConfig {
  // Custom server IP override if testing on a physical phone on the same Wi-Fi network
  static String? customServerUrl;
  static String? _discoveredBaseUrl;

  /// Candidate backend URLs for seamless connectivity across physical devices, emulators, and web
  static List<String> get candidateBaseUrls {
    if (customServerUrl != null && customServerUrl!.trim().isNotEmpty) {
      return [customServerUrl!.trim()];
    }
    if (_discoveredBaseUrl != null && _discoveredBaseUrl!.isNotEmpty) {
      return [_discoveredBaseUrl!];
    }
    if (kIsWeb) {
      return ['http://localhost:5000/api/v1'];
    }
    if (Platform.isAndroid) {
      return [
        'http://192.168.1.49:5000/api/v1', // Wi-Fi LAN IP (Physical Android devices)
        'http://localhost:5000/api/v1',     // USB adb reverse (tcp:5000 -> tcp:5000)
        'http://10.0.2.2:5000/api/v1',     // Android Emulator loopback
      ];
    }
    return ['http://localhost:5000/api/v1'];
  }

  static String get baseUrl {
    if (customServerUrl != null && customServerUrl!.trim().isNotEmpty) {
      return customServerUrl!.trim();
    }
    if (_discoveredBaseUrl != null && _discoveredBaseUrl!.isNotEmpty) {
      return _discoveredBaseUrl!;
    }
    if (kIsWeb) {
      return 'http://localhost:5000/api/v1';
    }
    if (Platform.isAndroid) {
      // Default to Wi-Fi IP which connects on physical Android devices
      return 'http://192.168.1.49:5000/api/v1';
    }
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

