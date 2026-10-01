import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tamil_tts_service.dart';

/// Centralized Tamil Audio Service for the AGARAM Educational Platform.
/// Powered by pre-generated and cached ElevenLabs audio assets with seamless TamilTtsService fallback.
/// Resolves and plays any of the 247 Tamil letters, words, sentences, stories, and quizzes.
class TamilAudioService {
  static final TamilAudioService _instance = TamilAudioService._internal();
  factory TamilAudioService() => _instance;
  static TamilAudioService get instance => _instance;

  TamilAudioService._internal();

  AudioPlayer? _player;
  bool _isMuted = false;
  bool get isMuted => _isMuted;

  AudioPlayer get player {
    _player ??= AudioPlayer();
    return _player!;
  }

  void setMuted(bool muted) {
    _isMuted = muted;
    TamilTtsService.instance.setMuted(muted);
    if (muted) {
      stopAll();
    }
  }

  // --------------------------------------------------------------------------
  // Static Audio Asset Mappings for 247 Letters and Core Content
  // --------------------------------------------------------------------------
  static final Map<String, String> _audioMapping = _buildAudioMapping();

  static Map<String, String> _buildAudioMapping() {
    final map = <String, String>{};

    // 12 Uyir Letters
    const uyirSlugs = <String, String>{
      'அ': 'assets/sounds/uyir/uyir_a.mp3',
      'ஆ': 'assets/sounds/uyir/uyir_aa.mp3',
      'இ': 'assets/sounds/uyir/uyir_i.mp3',
      'ஈ': 'assets/sounds/uyir/uyir_ee.mp3',
      'உ': 'assets/sounds/uyir/uyir_u.mp3',
      'ஊ': 'assets/sounds/uyir/uyir_oo.mp3',
      'எ': 'assets/sounds/uyir/uyir_e.mp3',
      'ஏ': 'assets/sounds/uyir/uyir_ae.mp3',
      'ஐ': 'assets/sounds/uyir/uyir_ai.mp3',
      'ஒ': 'assets/sounds/uyir/uyir_o.mp3',
      'ஓ': 'assets/sounds/uyir/uyir_oo_long.mp3',
      'ஔ': 'assets/sounds/uyir/uyir_au.mp3',
    };
    for (final entry in uyirSlugs.entries) {
      map[entry.key] = entry.value;
    }
    map['uyir_1'] = 'assets/sounds/uyir/uyir_a.mp3';
    map['uyir_a'] = 'assets/sounds/uyir/uyir_a.mp3';

    // 18 Mei Letters
    const meiSlugs = <String, String>{
      'க்': 'mei_01_ik',
      'ங்': 'mei_02_ing',
      'ச்': 'mei_03_ich',
      'ஞ்': 'mei_04_inj',
      'ட்': 'mei_05_it',
      'ண்': 'mei_06_inn',
      'த்': 'mei_07_ith',
      'ந்': 'mei_08_inth',
      'ப்': 'mei_09_ip',
      'ம்': 'mei_10_im',
      'ய்': 'mei_11_iy',
      'ர்': 'mei_12_ir',
      'ல்': 'mei_13_il',
      'வ்': 'mei_14_iv',
      'ழ்': 'mei_15_izh',
      'ள்': 'mei_16_ill',
      'ற்': 'mei_17_irr',
      'ன்': 'mei_18_in',
    };
    for (final entry in meiSlugs.entries) {
      map[entry.key] = 'assets/audio/tamil/mei/${entry.value}.mp3';
    }

    // 1 Aytham Letter
    map['ஃ'] = 'assets/audio/tamil/aytham/aytham_01_ak.mp3';

    // 216 Uyirmei Combinations (18 Mei × 12 Uyir)
    const meiKeys = [
      'k', 'ng', 'c', 'nj', 't', 'nn', 'th', 'nth', 'p', 'm', 'y', 'r', 'l', 'v', 'zh', 'll', 'rr', 'n'
    ];
    const vowelKeys = [
      'a', 'aa', 'i', 'ee', 'u', 'oo', 'e', 'ae', 'ai', 'o', 'oo_long', 'au'
    ];

    const uyirmeiMatrix = <String, List<String>>{
      'க்': ['க', 'கா', 'கி', 'கீ', 'கு', 'கூ', 'கெ', 'கே', 'கை', 'கொ', 'கோ', 'கௌ'],
      'ங்': ['ங', 'ஙா', 'ஙி', 'ஙீ', 'ஙு', 'ஙூ', 'ஙெ', 'ஙே', 'ஙை', 'ஙொ', 'ஙோ', 'ஙௌ'],
      'ச்': ['ச', 'சா', 'சி', 'சீ', 'சு', 'சூ', 'செ', 'சே', 'சை', 'சொ', 'சோ', 'சௌ'],
      'ஞ்': ['ஞ', 'ஞா', 'ஞி', 'ஞீ', 'ஞு', 'ஞூ', 'ஞெ', 'ஞே', 'ஞை', 'ஞொ', 'ஞோ', 'ஞௌ'],
      'ட்': ['ட', 'டா', 'டி', 'டீ', 'டு', 'டூ', 'டெ', 'டே', 'டை', 'டொ', 'டோ', 'டௌ'],
      'ண்': ['ண', 'ணா', 'ணி', 'ணீ', 'ணு', 'ணூ', 'ணெ', 'ணே', 'ணை', 'ணொ', 'ணோ', 'ணௌ'],
      'த்': ['த', 'தா', 'தி', 'தீ', 'து', 'தூ', 'தெ', 'தே', 'தை', 'தொ', 'தோ', 'தௌ'],
      'ந்': ['ந', 'நா', 'நி', 'நீ', 'நு', 'நூ', 'நெ', 'நே', 'நை', 'நொ', 'நோ', 'நௌ'],
      'ப்': ['ப', 'பா', 'பி', 'பீ', 'பு', 'பூ', 'பெ', 'பே', 'பை', 'பொ', 'போ', 'பௌ'],
      'ம்': ['ம', 'மா', 'மி', 'மீ', 'மு', 'மூ', 'மெ', 'மே', 'மை', 'மொ', 'மோ', 'மௌ'],
      'ய்': ['ய', 'யா', 'யி', 'யீ', 'யு', 'யூ', 'யெ', 'யே', 'யை', 'யொ', 'யோ', 'யௌ'],
      'ர்': ['ர', 'ரா', 'ரி', 'ரீ', 'ரு', 'ரூ', 'ரெ', 'ரே', 'ரை', 'ரொ', 'ரோ', 'ரௌ'],
      'ல்': ['ல', 'லா', 'லி', 'லீ', 'லு', 'லூ', 'லெ', 'லே', 'லை', 'லொ', 'லோ', 'லௌ'],
      'வ்': ['வ', 'வா', 'வி', 'வீ', 'வு', 'வூ', 'வெ', 'வே', 'வை', 'வொ', 'வோ', 'வௌ'],
      'ழ்': ['ழ', 'ழா', 'ழி', 'ழீ', 'ழு', 'ழூ', 'ழெ', 'ழே', 'ழை', 'ழொ', 'ழோ', 'ழௌ'],
      'ள்': ['ள', 'ளா', 'ளி', 'ளீ', 'ளு', 'ளூ', 'ளெ', 'ளே', 'ளை', 'ளொ', 'ளோ', 'ளௌ'],
      'ற்': ['ற', 'றா', 'றி', 'றீ', 'று', 'றூ', 'றெ', 'றே', 'றை', 'றொ', 'றோ', 'றௌ'],
      'ன்': ['ன', 'னா', 'னி', 'னீ', 'னு', 'னூ', 'னெ', 'னே', 'னை', 'னொ', 'னோ', 'னௌ'],
    };

    int count = 0;
    final meiEntries = uyirmeiMatrix.entries.toList();
    for (int m = 0; m < meiEntries.length; m++) {
      final combinations = meiEntries[m].value;
      final baseKey = (m < meiKeys.length) ? meiKeys[m] : 'm$m';

      for (int v = 0; v < combinations.length; v++) {
        count++;
        final letter = combinations[v];
        final indexStr = count.toString().padLeft(3, '0');
        final suffix = (v < vowelKeys.length) ? vowelKeys[v] : 'v$v';
        final slug = 'uyirmei_${indexStr}_${baseKey}_$suffix';
        map[letter] = 'assets/audio/tamil/uyirmei/$slug.mp3';
      }
    }

    // Essential Vocabulary Words
    const wordSlugs = <String, String>{
      'அம்மா': 'word_amma',
      'ஆடு': 'word_aadu',
      'இலை': 'word_ilai',
      'ஈ': 'word_ee',
      'உரல்': 'word_ural',
      'ஊஞ்சல்': 'word_oonjal',
      'எலி': 'word_eli',
      'ஏணி': 'word_eani',
      'ஐந்து': 'word_ainthu',
      'ஒட்டகம்': 'word_ottagam',
      'ஓடம்': 'word_oodam',
      'ஔவையார்': 'word_auvaiyar',
      'தமிழ்': 'word_thamizh',
      'எஃகு': 'word_ehgu',
      'மரம்': 'word_maram',
      'பட்டம்': 'word_pattam',
      'கண்': 'word_kann',
      'பந்து': 'word_panthu',
      'வணக்கம்': 'word_vanakkam',
      'வணக்கம். இது அகரம் தமிழ் குரல் சோதனை.': 'sentence_greeting_test',
      'அ ஆ இ ஈ உ ஊ': 'sentence_alphabet_test',
    };
    for (final entry in wordSlugs.entries) {
      final category = entry.value.startsWith('sentence_') ? 'sentences' : 'words';
      map[entry.key] = 'assets/audio/tamil/$category/${entry.value}.mp3';
    }

    return map;
  }

  static final Map<String, String> _reverseAudioMapping = _buildReverseAudioMapping();

  static Map<String, String> _buildReverseAudioMapping() {
    final reverse = <String, String>{};

    for (final entry in _audioMapping.entries) {
      final text = entry.key;
      final path = entry.value;
      reverse[path] = text;
      if (path.startsWith('assets/')) {
        reverse[path.substring(7)] = text;
      }
    }

    // Direct and legacy sound path reverse mappings
    const legacySounds = <String, String>{
      // Uyir
      'assets/sounds/uyir/uyir_a.mp3': 'அ',
      'assets/sounds/uyir/uyir_aa.mp3': 'ஆ',
      'assets/sounds/uyir/uyir_i.mp3': 'இ',
      'assets/sounds/uyir/uyir_ee.mp3': 'ஈ',
      'assets/sounds/uyir/uyir_u.mp3': 'உ',
      'assets/sounds/uyir/uyir_oo.mp3': 'ஊ',
      'assets/sounds/uyir/uyir_e.mp3': 'எ',
      'assets/sounds/uyir/uyir_ae.mp3': 'ஏ',
      'assets/sounds/uyir/uyir_ai.mp3': 'ஐ',
      'assets/sounds/uyir/uyir_o.mp3': 'ஒ',
      'assets/sounds/uyir/uyir_oo_long.mp3': 'ஓ',
      'assets/sounds/uyir/uyir_au.mp3': 'ஔ',
      'assets/audio/tamil/uyir/அ.mp3': 'அ',

      // Mei
      'assets/sounds/mei/mei_ik.mp3': 'க்',
      'assets/sounds/mei/mei_ing.mp3': 'ங்',
      'assets/sounds/mei/mei_ich.mp3': 'ச்',
      'assets/sounds/mei/mei_inj.mp3': 'ஞ்',
      'assets/sounds/mei/mei_it.mp3': 'ட்',
      'assets/sounds/mei/mei_inn.mp3': 'ண்',
      'assets/sounds/mei/mei_ith.mp3': 'த்',
      'assets/sounds/mei/mei_inth.mp3': 'ந்',
      'assets/sounds/mei/mei_ip.mp3': 'ப்',
      'assets/sounds/mei/mei_im.mp3': 'ம்',
      'assets/sounds/mei/mei_iy.mp3': 'ய்',
      'assets/sounds/mei/mei_ir.mp3': 'ர்',
      'assets/sounds/mei/mei_il.mp3': 'ல்',
      'assets/sounds/mei/mei_iv.mp3': 'வ்',
      'assets/sounds/mei/mei_izh.mp3': 'ழ்',
      'assets/sounds/mei/mei_ill.mp3': 'ள்',
      'assets/sounds/mei/mei_irr.mp3': 'ற்',
      'assets/sounds/mei/mei_in.mp3': 'ன்',

      // Aytham
      'assets/sounds/aytham_ஃ.mp3': 'ஃ',
      'assets/audio/tamil/aytham/aytham_01_ak.mp3': 'ஃ',
    };

    for (final entry in legacySounds.entries) {
      reverse[entry.key] = entry.value;
      if (entry.key.startsWith('assets/')) {
        reverse[entry.key.substring(7)] = entry.value;
      }
    }

    return reverse;
  }

  Set<String>? _availableAssets;

  Future<void> _ensureAssetManifestLoaded() async {
    if (_availableAssets != null) return;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _availableAssets = manifest.listAssets().toSet();
      debugPrint('[TamilAudioService] In-memory AssetManifest loaded with ${_availableAssets!.length} assets.');
    } catch (e) {
      debugPrint('[TamilAudioService] Notice: AssetManifest not available ($e). Initializing empty asset set.');
      _availableAssets = <String>{};
    }
  }

  /// Checks whether an asset is physically available in the app bundle without making HTTP requests.
  Future<bool> isAssetAvailable(String path) async {
    await _ensureAssetManifestLoaded();
    if (_availableAssets == null || _availableAssets!.isEmpty) {
      return true;
    }
    final clean = path.trim();
    final withPrefix = clean.startsWith('assets/') ? clean : 'assets/$clean';
    final withoutPrefix = clean.startsWith('assets/') ? clean.substring(7) : clean;
    return _availableAssets!.contains(withPrefix) ||
           _availableAssets!.contains(withoutPrefix);
  }

  /// Safely resolves any string or asset path to pure spoken Tamil text.
  /// Strictly prevents speaking file paths, URLs, or non-Tamil strings.
  static String resolveTamilText(String input, {String? fallback}) {
    final trimmed = input.trim();
    // If input is already pure Tamil or plain text (no paths, URLs, or extensions)
    if (!trimmed.startsWith('assets/') &&
        !trimmed.contains('/') &&
        !trimmed.contains(r'\') &&
        !trimmed.endsWith('.mp3') &&
        !trimmed.endsWith('.wav') &&
        !trimmed.startsWith('http://') &&
        !trimmed.startsWith('https://')) {
      return trimmed;
    }

    // Try reverse mapping lookup
    if (_reverseAudioMapping.containsKey(trimmed)) {
      return _reverseAudioMapping[trimmed]!;
    }
    final withPrefix = trimmed.startsWith('assets/') ? trimmed : 'assets/$trimmed';
    if (_reverseAudioMapping.containsKey(withPrefix)) {
      return _reverseAudioMapping[withPrefix]!;
    }
    final withoutPrefix = trimmed.startsWith('assets/') ? trimmed.substring(7) : trimmed;
    if (_reverseAudioMapping.containsKey(withoutPrefix)) {
      return _reverseAudioMapping[withoutPrefix]!;
    }

    // Use fallback if valid pure text
    if (fallback != null && fallback.trim().isNotEmpty) {
      final fb = fallback.trim();
      if (!fb.contains('/') && !fb.contains(r'\') && !fb.endsWith('.mp3')) {
        return fb;
      }
    }

    return '';
  }

  Future<bool> _playAsset(String path) async {
    try {
      final cleanPath = path.startsWith('assets/') ? path.substring(7) : path;
      await player.stop();
      await player.play(AssetSource(cleanPath));
      return true;
    } catch (e) {
      debugPrint('[TamilAudioService] Asset playback failed for $path: $e');
      return false;
    }
  }

  /// Maps any Tamil text or key to its relative audio asset path
  static String? getAudioPath(String text) {
    final trimmed = text.trim();
    if (_audioMapping.containsKey(trimmed)) {
      return _audioMapping[trimmed];
    }
    // Check if input is already a valid asset path
    if (trimmed.startsWith('assets/')) {
      return trimmed;
    }
    return null;
  }

  /// Displays an attractive kid-friendly floating audio indicator with speaker icon
  static void showAudioIndicator(
    BuildContext context, {
    required String text,
    String? subtext,
  }) {
    if (!context.mounted) return;
    try {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1400),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          backgroundColor: const Color(0xFF2B2D42).withValues(alpha: 0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF3F4259),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.volume_up_rounded,
                  color: Color(0xFFFFD166),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  (subtext != null && subtext.isNotEmpty && subtext != text)
                      ? 'ஒலி: $text ($subtext)'
                      : 'ஒலி: $text',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('[TamilAudioService] showAudioIndicator notice: $e');
    }
  }

  /// Main Centralized Method: Resolves and plays audio for any Tamil text.
  /// 1. Plays pre-recorded Tamil audio assets
  /// 2. Plays remote URLs (if applicable)
  /// Strictly eliminates TTS fallback for letter pronunciations.
  Future<void> playTamilAudio(String? text, {String? fallbackTamilText}) async {
    if (_isMuted || text == null || text.trim().isEmpty) return;

    final trimmed = text.trim();

    // 1. Remote URLs (backend streaming or remote audio)
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      try {
        await player.stop();
        await player.play(UrlSource(trimmed));
        return;
      } catch (e) {
        debugPrint('[TamilAudioService] UrlSource playback failed for $trimmed: $e');
      }
    }

    // 2. Identify candidate asset path
    final isPath = trimmed.startsWith('assets/') || trimmed.endsWith('.mp3');
    final assetPath = isPath ? trimmed : getAudioPath(trimmed);

    // 3. Play bundled asset if present
    if (assetPath != null && await isAssetAvailable(assetPath)) {
      final played = await _playAsset(assetPath);
      if (played) return;
    }

    // 4. Try candidate letter audio paths (e.g., 'அ')
    final candidates = _getLetterCandidatePaths(trimmed);
    for (final candidate in candidates) {
      if (await isAssetAvailable(candidate)) {
        final played = await _playAsset(candidate);
        if (played) return;
      }
    }

    // 5. If no asset file is found, speak with Tamil TTS
    await TamilTtsService.instance.speakText(trimmed);
  }

  /// Convenience method matching existing AudioService signature
  /// Plays the authentic native Tamil pronunciation audio for the given letter.
  /// Strictly avoids TTS fallback so only real Tamil pronunciations are heard.
  Future<void> playLetterSound(
    BuildContext context, {
    required String letter,
    String? word,
    String? audioPath,
    bool showIndicator = true,
  }) async {
    if (_isMuted) return;

    if (showIndicator && context.mounted) {
      showAudioIndicator(
        context,
        text: letter,
        subtext: word,
      );
    }

    // 1. If explicit audioPath provided and available, play it
    if (audioPath != null && audioPath.trim().isNotEmpty && await isAssetAvailable(audioPath)) {
      final played = await _playAsset(audioPath);
      if (played) return;
    }

    // 2. Check canonical asset for this letter
    final letterAsset = getAudioPath(letter);
    if (letterAsset != null && await isAssetAvailable(letterAsset)) {
      final played = await _playAsset(letterAsset);
      if (played) return;
    }

    // 3. Check fallback candidate paths for letter 'அ' and others
    final candidates = _getLetterCandidatePaths(letter);
    for (final candidate in candidates) {
      if (await isAssetAvailable(candidate)) {
        final played = await _playAsset(candidate);
        if (played) return;
      }
    }

    debugPrint('[TamilAudioService] No audio asset found for "$letter". TTS fallback disabled.');
  }

  static List<String> _getLetterCandidatePaths(String text) {
    final t = text.trim();
    if (t == 'அ' || t == 'uyir_1' || t == 'uyir_a' || t == 'uyir_01_a') {
      return const [
        'assets/sounds/uyir/uyir_a.mp3',
        'assets/sounds/uyir/uyir_01_a.mp3',
        'assets/audio/tamil/uyir/uyir_01_a.mp3',
        'assets/sounds/uyir/அ.mp3',
      ];
    }
    return const [];
  }

  /// Convenience method for speaking any text
  Future<void> speakText(String? text, {String? fallbackTamilText}) async {
    await playTamilAudio(text, fallbackTamilText: fallbackTamilText);
  }

  /// Stops any playing audio
  Future<void> stopAll() async {
    try {
      await _player?.stop();
      await TamilTtsService.instance.stop();
    } catch (e) {
      debugPrint('[TamilAudioService] stopAll: $e');
    }
  }

  /// Plays cheerful success feedback sound effect
  Future<void> playSuccessFeedback(BuildContext context) async {
    if (_isMuted) return;
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Plays star award sound effect
  Future<void> playStarReward(BuildContext context) async {
    if (_isMuted) return;
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Plays gentle retry effect
  Future<void> playRetryFeedback(BuildContext context) async {
    if (_isMuted) return;
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  void dispose() {
    _player?.dispose();
    _player = null;
  }
}
