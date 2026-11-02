import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageInfo {
  final String code;
  final String name;
  final String nativeName;
  final String flagEmoji;
  final String brandTitle;
  final String greeting;
  final String vowelsTitle;
  final String consonantsTitle;

  const LanguageInfo({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flagEmoji,
    required this.brandTitle,
    required this.greeting,
    required this.vowelsTitle,
    required this.consonantsTitle,
  });
}

class LanguageService extends ChangeNotifier {
  static final LanguageService instance = LanguageService._internal();
  factory LanguageService() => instance;
  LanguageService._internal();

  static const String _prefKey = 'selected_language_code';

  static const Map<String, LanguageInfo> supportedLanguages = {
    'en': LanguageInfo(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      flagEmoji: '🇬🇧',
      brandTitle: 'ALPHABETS',
      greeting: 'Hello',
      vowelsTitle: 'Vowels (A, E, I, O, U)',
      consonantsTitle: 'Consonants (21 Letters)',
    ),
  };

  // Strictly English
  String _currentLanguageCode = 'en';
  bool _isInitialized = false;
  bool _hasSelectedLanguage = true;

  String get currentLanguageCode => 'en';
  bool get hasSelectedLanguage => true;
  bool get isInitialized => _isInitialized;

  LanguageInfo get currentLanguage => supportedLanguages['en']!;

  String get brandTitle => 'ALPHABETS';
  String get greeting => 'Hello';
  String get vowelsTitle => 'Vowels (A, E, I, O, U)';
  String get consonantsTitle => 'Consonants (21 Letters)';

  Future<void> init() async {
    _currentLanguageCode = 'en';
    _isInitialized = true;
    _hasSelectedLanguage = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, 'en');
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    _currentLanguageCode = 'en';
    _hasSelectedLanguage = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, 'en');
    } catch (_) {}
  }
}
