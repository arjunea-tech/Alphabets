import 'cloudinary_media.dart';

class ApiConfig {
  /// Live backend. Every build (debug, profile and release) uses it by default,
  /// so an APK works on any network, including mobile data.
  // TEMP: pointing at the local backend for testing.
  // Change back to 'https://alphabets-api.macvelsoftware.com/api/v1' before building an APK.
  static const String productionBaseUrl = 'http://localhost:5000/api/v1';

  // Runtime override, e.g. set from a settings screen.
  static String? customServerUrl;
  static String? _discoveredBaseUrl;

  /// To test against a backend running on your PC instead of the live server:
  ///   Phone on the same Wi-Fi: flutter run --dart-define=API_BASE_URL=http://192.168.1.46:5000/api/v1
  ///   Android emulator:        flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api/v1
  ///   Web / desktop:           flutter run --dart-define=API_BASE_URL=http://localhost:5000/api/v1
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Backend URLs to try, in order.
  static List<String> get candidateBaseUrls => [baseUrl];

  static String get baseUrl {
    if (customServerUrl != null && customServerUrl!.trim().isNotEmpty) {
      return customServerUrl!.trim();
    }
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (_discoveredBaseUrl != null && _discoveredBaseUrl!.isNotEmpty) {
      return _discoveredBaseUrl!;
    }
    return productionBaseUrl;
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
