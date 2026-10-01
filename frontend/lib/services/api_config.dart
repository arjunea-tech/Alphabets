import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Custom server IP override if testing on a physical phone on the same Wi-Fi network
  static String? customServerUrl;

  static String get baseUrl {
    if (customServerUrl != null && customServerUrl!.isNotEmpty) {
      return customServerUrl!;
    }

    if (kIsWeb) {
      return 'http://localhost:5000/api/v1';
    }

    // Android Emulator routes 10.0.2.2 to host machine's localhost
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api/v1';
    }

    // Windows, macOS, Linux desktop testing
    return 'http://localhost:5000/api/v1';
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
    if (clean.startsWith('uploads/') || clean.startsWith('/uploads/')) {
      final sub = clean.startsWith('/') ? clean.substring(1) : clean;
      return '$serverRoot/$sub';
    }
    return clean;
  }
}
