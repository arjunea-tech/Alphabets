import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Reusable Text-To-Speech service configured for Tamil pronunciation (`ta-IN`).
/// Designed for kid-friendly, clear, and non-robotic pacing.
class TamilTtsService {
  static final TamilTtsService _instance = TamilTtsService._internal();
  factory TamilTtsService() => _instance;
  static TamilTtsService get instance => _instance;

  TamilTtsService._internal();

  FlutterTts? _tts;
  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _isMuted = false;
  String _activeLanguage = 'ta-IN';
  bool _tamilSupportedOnDevice = false;
  String? _detectedEngine;
  List<String> _availableLanguages = [];
  String? _lastSpokenText;
  String? _lastError;

  bool get isSpeaking => _isSpeaking;
  bool get isMuted => _isMuted;
  String get activeLanguage => _activeLanguage;
  bool get isTamilSupported => _tamilSupportedOnDevice;
  String? get detectedEngine => _detectedEngine;
  List<String> get availableLanguages => _availableLanguages;
  String? get lastSpokenText => _lastSpokenText;
  String? get lastError => _lastError;

  /// Initializes the TTS engine with Tamil language, optimal speed, and pitch.
  Future<void> init() async {
    if (_isInitialized && _tts != null) return;

    try {
      debugPrint('[TTS] ==================== INITIALIZING TTS ====================');
      _tts = FlutterTts();

      // Setup event handlers with debug logs
      _tts!.setStartHandler(() {
        _isSpeaking = true;
        debugPrint('[TTS] >>> TTS SPEAK STARTED: "$_lastSpokenText"');
      });

      _tts!.setCompletionHandler(() {
        _isSpeaking = false;
        debugPrint('[TTS] <<< TTS SPEAK COMPLETED: "$_lastSpokenText"');
      });

      _tts!.setCancelHandler(() {
        _isSpeaking = false;
        debugPrint('[TTS] --- TTS SPEAK CANCELLED');
      });

      _tts!.setErrorHandler((msg) {
        _isSpeaking = false;
        _lastError = msg.toString();
        debugPrint('[TTS] !!! TTS SPEAK ERROR: $msg');
      });

      // Platform specific audio session configuration
      if (!kIsWeb) {
        if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
          try {
            await _tts!.setSharedInstance(true);
            await _tts!.setIosAudioCategory(
              IosTextToSpeechAudioCategory.ambientSolo,
              [
                IosTextToSpeechAudioCategoryOptions.allowBluetooth,
                IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
                IosTextToSpeechAudioCategoryOptions.mixWithOthers,
              ],
            );
          } catch (e) {
            debugPrint('[TTS] iOS audio session configuration notice: $e');
          }
        } else if (defaultTargetPlatform == TargetPlatform.android) {
          // On Android, check and prefer Google TTS engine for best Tamil pronunciation
          try {
            final dynamic engines = await _tts!.getEngines;
            debugPrint('[TTS] Android available engines: $engines');
            if (engines is List) {
              if (engines.contains('com.google.android.tts')) {
                _detectedEngine = 'com.google.android.tts';
                await _tts!.setEngine('com.google.android.tts');
                debugPrint('[TTS] Selected Google Speech Services: com.google.android.tts');
              } else if (engines.isNotEmpty) {
                _detectedEngine = engines.first.toString();
                debugPrint('[TTS] Using default device engine: $_detectedEngine');
              }
            }
          } catch (e) {
            debugPrint('[TTS] Engine check note: $e');
          }
        }
      }

      // Query available languages on device
      try {
        final dynamic langs = await _tts!.getLanguages;
        if (langs is List) {
          _availableLanguages = langs.map((e) => e.toString()).toList();
          debugPrint('[TTS] Device has ${_availableLanguages.length} available languages.');
          // Check for any Tamil locale variants
          final tamilVariants = _availableLanguages
              .where((l) => l.toLowerCase().startsWith('ta'))
              .toList();
          debugPrint('[TTS] Tamil language variants found on device: $tamilVariants');
        }
      } catch (e) {
        debugPrint('[TTS] Query languages note: $e');
      }

      // Check ta-IN availability
      bool taInFound = false;
      try {
        final dynamic taInCheck = await _tts!.isLanguageAvailable('ta-IN');
        taInFound = _isLanguageSupportedResult(taInCheck);
      } catch (_) {}

      bool taGenericFound = false;
      try {
        final dynamic taCheck = await _tts!.isLanguageAvailable('ta');
        taGenericFound = _isLanguageSupportedResult(taCheck);
      } catch (_) {}

      bool taUnderscoreFound = false;
      try {
        final dynamic taUnderCheck = await _tts!.isLanguageAvailable('ta_IN');
        taUnderscoreFound = _isLanguageSupportedResult(taUnderCheck);
      } catch (_) {}

      // If available in list or reported by isLanguageAvailable
      final inList = _availableLanguages.any((l) =>
          l == 'ta-IN' || l == 'ta_IN' || l == 'ta' || l.toLowerCase().startsWith('ta'));

      _tamilSupportedOnDevice = taInFound || taGenericFound || taUnderscoreFound || inList;

      if (taInFound) {
        _activeLanguage = 'ta-IN';
      } else if (taUnderscoreFound) {
        _activeLanguage = 'ta_IN';
      } else if (taGenericFound) {
        _activeLanguage = 'ta';
      } else {
        _activeLanguage = 'ta-IN'; // Default attempt
      }

      // Query available voices and explicitly select Tamil voice if present
      try {
        final dynamic voices = await _tts!.getVoices;
        if (voices is List && voices.isNotEmpty) {
          debugPrint('[TTS] Device has ${voices.length} voices available.');
          for (final v in voices) {
            if (v is Map) {
              final name = (v['name'] ?? '').toString();
              final locale = (v['locale'] ?? '').toString();
              if (locale.toLowerCase().startsWith('ta') || name.toLowerCase().contains('tamil')) {
                debugPrint('[TTS] 🎯 Selecting Tamil voice: "$name" ($locale)');
                await _tts!.setVoice({"name": name, "locale": locale});
                _tamilSupportedOnDevice = true;
                _activeLanguage = locale;
                break;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[TTS] Voice scan note: $e');
      }

      final langRes = await _tts!.setLanguage(_activeLanguage);
      debugPrint('[TTS] TTS LANGUAGE SET TO: $_activeLanguage (result: $langRes, supported: $_tamilSupportedOnDevice)');

      if (!_tamilSupportedOnDevice) {
        debugPrint('[TTS] ⚠️ WARNING: Tamil ("ta-IN") voice is not yet installed on this OS/device.');
        debugPrint('[TTS] 📌 Windows: Settings -> Time & Language -> Speech -> Add Voices -> Tamil (India)');
        debugPrint('[TTS] 📌 Android: Settings -> System -> Languages -> Text-to-speech -> Google Speech Services -> Install Tamil');
        debugPrint('[TTS] 📌 Chrome/Web: Settings -> Languages -> Add Tamil');
      }

      // Kid-friendly speech rate (0.45 - 0.50 gives clear syllable distinction)
      await _tts!.setSpeechRate(0.46);
      debugPrint('[TTS] TTS SPEECH RATE: 0.46');

      // Warm pitch
      await _tts!.setPitch(1.05);
      debugPrint('[TTS] TTS PITCH: 1.05');

      // Full media volume
      await _tts!.setVolume(1.0);
      debugPrint('[TTS] TTS VOLUME: 1.0');

      _isInitialized = true;
      debugPrint('[TTS] ==================== TTS INIT SUCCESS ====================');
    } catch (e) {
      _lastError = e.toString();
      debugPrint('[TTS] ==================== TTS INIT FAILED: $e ====================');
      _isInitialized = true;
    }
  }

  static bool _isLanguageSupportedResult(dynamic res) {
    if (res == true) return true;
    if (res is num && res >= 0) return true; // Android returns 0 (LANG_AVAILABLE) or 1 (LANG_COUNTRY_AVAILABLE)
    return false;
  }

  /// Speaks the given Tamil text.
  /// Automatically stops any ongoing speech before starting new speech.
  /// Handles null, empty, or whitespace safely.
  Future<void> speakText(String? text) async {
    if (_isMuted) {
      debugPrint('[TTS] Speech skipped because audio is muted.');
      return;
    }

    if (text == null) {
      debugPrint('[TTS] Speech skipped: text is null.');
      return;
    }

    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      debugPrint('[TTS] Speech skipped: text is empty.');
      return;
    }

    // Safety guard: TTS is for human speech, never speak file paths, URLs, or file identifiers
    if (cleanText.startsWith('assets/') ||
        cleanText.contains('/') ||
        cleanText.contains(r'\') ||
        cleanText.endsWith('.mp3') ||
        cleanText.endsWith('.wav') ||
        cleanText.startsWith('http://') ||
        cleanText.startsWith('https://')) {
      debugPrint('[TTS] ⚠️ Speech skipped: "$cleanText" is a file path or URL, not spoken Tamil text.');
      return;
    }

    if (!_isInitialized || _tts == null) {
      await init();
    }

    _lastSpokenText = cleanText;
    debugPrint('[TTS] >>> TTS SPEAK TEXT REQUEST: "$cleanText"');

    try {
      // If currently speaking, stop first so speech doesn't overlap
      if (_isSpeaking) {
        await _tts?.stop();
        _isSpeaking = false;
        // Tiny yield so native engine flushes cleanly
        await Future<void>.delayed(const Duration(milliseconds: 30));
      }

      _isSpeaking = true;
      await _tts?.setVolume(1.0);
      final dynamic result = await _tts?.speak(cleanText);
      debugPrint('[TTS] TTS speak() native call returned: $result');
    } catch (e) {
      _isSpeaking = false;
      _lastError = e.toString();
      debugPrint('[TTS] !!! TTS speak() threw exception: $e');
    }
  }

  /// Convenience static speak method so any widget or screen can call:
  /// `await TamilTtsService.speak("அ");`
  static Future<void> speak(String? text) async {
    await _instance.speakText(text);
  }

  /// Stops ongoing speech.
  Future<void> stop() async {
    try {
      _isSpeaking = false;
      await _tts?.stop();
      debugPrint('[TTS] TTS stopped.');
    } catch (e) {
      debugPrint('[TTS] TTS stop error: $e');
    }
  }

  /// Static stop convenience
  static Future<void> stopSpeech() async {
    await _instance.stop();
  }

  /// Pauses ongoing speech if supported.
  Future<void> pause() async {
    try {
      await _tts?.pause();
      _isSpeaking = false;
    } catch (e) {
      debugPrint('[TTS] TTS pause error: $e');
    }
  }

  /// Controls mute state for TTS.
  void setMuted(bool muted) {
    _isMuted = muted;
    debugPrint('[TTS] TTS mute set to: $muted');
    if (muted) {
      stop();
    }
  }

  /// Cleanup resources
  void dispose() {
    stop();
    _isSpeaking = false;
  }
}
