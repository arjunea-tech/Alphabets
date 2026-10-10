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
    'ta': LanguageInfo(
      code: 'ta',
      name: 'Tamil',
      nativeName: 'தமிழ்',
      flagEmoji: '🇮🇳',
      brandTitle: 'அகரம்',
      greeting: 'வணக்கம்',
      vowelsTitle: 'உயிர் எழுத்துகள்',
      consonantsTitle: 'மெய் எழுத்துகள்',
    ),
    'te': LanguageInfo(
      code: 'te',
      name: 'Telugu',
      nativeName: 'తెలుగు',
      flagEmoji: '🇮🇳',
      brandTitle: 'అక్షరం',
      greeting: 'నమస్కారం',
      vowelsTitle: 'అచ్చులు (Achulu)',
      consonantsTitle: 'హల్లులు (Hallulu)',
    ),
    'en': LanguageInfo(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      flagEmoji: '🇬🇧',
      brandTitle: 'AGARAM',
      greeting: 'Hello',
      vowelsTitle: 'Vowels (A, E, I, O, U)',
      consonantsTitle: 'Consonants',
    ),
  };

  String _currentLanguageCode = 'ta';
  bool _isInitialized = false;
  bool _hasSelectedLanguage = false;

  String get currentLanguageCode => _currentLanguageCode;
  bool get hasSelectedLanguage => _hasSelectedLanguage;
  bool get isInitialized => _isInitialized;

  LanguageInfo get currentLanguage =>
      supportedLanguages[_currentLanguageCode] ?? supportedLanguages['ta']!;

  String get brandTitle => currentLanguage.brandTitle;
  String get greeting => currentLanguage.greeting;
  String get vowelsTitle => currentLanguage.vowelsTitle;
  String get consonantsTitle => currentLanguage.consonantsTitle;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefKey);
      if (savedCode != null && supportedLanguages.containsKey(savedCode)) {
        _currentLanguageCode = savedCode;
        _hasSelectedLanguage = true;
      } else {
        _hasSelectedLanguage = false;
        _currentLanguageCode = 'ta';
      }
    } catch (_) {
      _currentLanguageCode = 'ta';
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> setLanguage(String code) async {
    if (!supportedLanguages.containsKey(code)) return;
    _currentLanguageCode = code;
    _hasSelectedLanguage = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, code);
    } catch (_) {}
  }
}
