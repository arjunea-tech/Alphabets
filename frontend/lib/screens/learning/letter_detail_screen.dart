import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/letter_model.dart';
import '../../models/video_model.dart';
import '../../services/api_config.dart';
import '../../services/audio_service.dart';
import '../../services/cloudinary_media.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/custom_audio_button.dart';
import '../../widgets/kid_app_bar.dart';
import '../../widgets/kid_scaffold_background.dart';
import '../../widgets/mascot_widget.dart';
import '../../widgets/letter_media_image.dart';
import '../videos/video_player_screen.dart';
import '../writing/writing_practice_screen.dart';

class LetterDetailScreen extends StatefulWidget {
  final List<LetterModel> letterList;
  final int initialIndex;
  final Color accentColor;
  final ProgressService progressService;

  const LetterDetailScreen({
    super.key,
    required this.letterList,
    required this.initialIndex,
    required this.accentColor,
    required this.progressService,
  });

  @override
  State<LetterDetailScreen> createState() => _LetterDetailScreenState();
}

class _LetterDetailScreenState extends State<LetterDetailScreen> with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  final AudioService _audioService = AudioService();
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _recordingPlayer = AudioPlayer();
  bool _speaking = false;

  LetterModel get _currentLetter => widget.letterList[_currentIndex];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    _animController.forward();
    _markCompleted();
    _initTts();
  }

  Future<void> _initTts() async {
    _recordingPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      final playing = state == PlayerState.playing;
      if (playing != _speaking) setState(() => _speaking = playing);
    });
    _tts.setStartHandler(() { if (mounted) setState(() => _speaking = true); });
    _tts.setCompletionHandler(() { if (mounted) setState(() => _speaking = false); });
    _tts.setCancelHandler(() { if (mounted) setState(() => _speaking = false); });
    _tts.setErrorHandler((_) { if (mounted) setState(() => _speaking = false); });
    try {
      // Indian English accent so kids understand it clearly.
      await _tts.setLanguage('en-IN');
      await _pickIndianVoice();
      // Higher pitch + female voice = cheerful, kid-like voice.
      await _tts.setSpeechRate(0.4);
      await _tts.setPitch(1.6);
      await _tts.setVolume(1.0);
    } catch (_) {}
  }

  /// Chooses an Indian English (en-IN) voice if the device/browser has one,
  /// preferring Google / female voices which sound clearest.
  Future<void> _pickIndianVoice() async {
    try {
      final voices = await _tts.getVoices;
      if (voices is! List) return;
      final indian = voices
          .whereType<Map>()
          .where((v) {
            final locale = (v['locale'] ?? '').toString().toLowerCase().replaceAll('_', '-');
            final name = (v['name'] ?? '').toString().toLowerCase();
            return locale == 'en-in' || name.contains('india');
          })
          .toList();
      if (indian.isEmpty) return;
      int score(Map v) {
        final name = (v['name'] ?? '').toString().toLowerCase();
        var s = 0;
        // Female voices sound closest to a child once the pitch is raised.
        if (name.contains('female') || name.contains('heera') || name.contains('neerja') ||
            name.contains('en-in-x-ahp') || name.contains('en-in-x-cxx')) {
          s += 3;
        }
        if (name.contains('google')) s += 1;
        if (name.contains('male') && !name.contains('female')) s -= 2;
        return s;
      }
      indian.sort((a, b) => score(b).compareTo(score(a)));
      final best = indian.first;
      await _tts.setVoice({
        'name': best['name'].toString(),
        'locale': best['locale'].toString(),
      });
    } catch (_) {}
  }

  /// Speaks "A for Apple", "B for Ball", ... for the current letter.
  ///
  /// If a real recording (e.g. a child saying "A for Apple") was uploaded for
  /// this letter in the admin panel ("Audio Pronunciation"), that is played.
  /// Otherwise it falls back to the kid-style Indian English TTS voice.
  Future<void> _speakLetterWord() async {
    final letter = _currentLetter;
    await _stopAllSpeech();

    final url = ApiConfig.resolveMediaUrl(letter.audioPath);
    if (url != null) {
      try {
        final Source source = url.startsWith('http')
            ? UrlSource(url)
            : AssetSource(url.replaceFirst('assets/', ''));
        await _recordingPlayer.play(source, volume: 1.0);
        return;
      } catch (e) {
        debugPrint('[LetterDetail] Recording failed, using TTS: $e');
      }
    }

    final text = letter.word.isNotEmpty ? '${letter.letter}... for... ${letter.word}' : letter.letter;
    try {
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> _stopAllSpeech() async {
    try {
      await _tts.stop();
    } catch (_) {}
    try {
      await _recordingPlayer.stop();
    } catch (_) {}
  }

  void _stopTts() {
    _stopAllSpeech();
    _speaking = false;
  }

  @override
  void dispose() {
    _audioService.stopAll();
    _tts.stop();
    _recordingPlayer.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _markCompleted() {
    widget.progressService.markLetterCompleted(_currentLetter.id);
  }

  /// Download the previous/next letters' pictures in the background so tapping
  /// Next/Previous shows the image instantly instead of waiting for the network.
  void _precacheNeighbours() {
    for (final i in [_currentIndex + 1, _currentIndex + 2, _currentIndex - 1]) {
      if (i < 0 || i >= widget.letterList.length) continue;
      final url = ApiConfig.resolveMediaUrl(widget.letterList[i].imagePath);
      if (url == null) continue;
      final ImageProvider provider =
          url.startsWith('http') ? NetworkImage(url) : AssetImage(url);
      precacheImage(provider, context, onError: (_, _) {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheNeighbours();
  }

  void _playAudio() { return; }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      _audioService.stopAll();
      _stopTts();
      setState(() {
        _currentIndex--;
      });
      _animController.forward(from: 0.0);
      _markCompleted();
      _precacheNeighbours();
    }
  }

  void _goToNext() {
    if (_currentIndex < widget.letterList.length - 1) {
      _audioService.stopAll();
      _stopTts();
      setState(() {
        _currentIndex++;
      });
      _animController.forward(from: 0.0);
      _markCompleted();
      _precacheNeighbours();
    }
  }

  Widget _buildHighlightedWord(String word, String targetLetter, Color highlightColor) {
    if (word.isEmpty) return const SizedBox.shrink();

    final spans = <TextSpan>[];
    final index = word.indexOf(targetLetter);

    if (index != -1) {
      // Leading part of the word
      if (index > 0) {
        spans.add(
          TextSpan(
            text: word.substring(0, index),
            style: AppTextStyles.wordLarge.copyWith(
              color: AppColors.textDark,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }
      // Target letter highlighted in vibrant color!
      spans.add(
        TextSpan(
          text: targetLetter,
          style: AppTextStyles.wordLarge.copyWith(
            color: highlightColor,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      );
      // Trailing part of the word
      final remaining = word.substring(index + targetLetter.length);
      if (remaining.isNotEmpty) {
        spans.add(
          TextSpan(
            text: remaining,
            style: AppTextStyles.wordLarge.copyWith(
              color: AppColors.textDark,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }
    } else {
      // Fallback
      spans.add(
        TextSpan(
          text: word,
          style: AppTextStyles.wordLarge.copyWith(
            color: AppColors.textDark,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildPrevNextBar(bool hasPrev, bool hasNext, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (hasPrev)
          Flexible(
            child: BouncyButton(
              onPressed: _goToPrevious,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.borderLight, width: 2),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text('Previous', style: AppTextStyles.bodyTextBold.copyWith(fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          const SizedBox(width: 48),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: Text(
            '${_currentIndex + 1} / ${widget.letterList.length}',
            style: AppTextStyles.bodyTextBold.copyWith(
              color: AppColors.textMuted,
              fontSize: 15,
            ),
          ),
        ),
        if (hasNext)
          Flexible(
            child: BouncyButton(
              onPressed: _goToNext,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.85)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Next',
                        style: AppTextStyles.bodyTextBold.copyWith(color: Colors.white, fontSize: 15),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          const SizedBox(width: 48),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final letter = _currentLetter;
    final color = widget.accentColor;
    final hasPrev = _currentIndex > 0;
    final hasNext = _currentIndex < widget.letterList.length - 1;

    return Scaffold(
      appBar: KidAppBar(
        title: letter.letter,
        starCount: widget.progressService.stars,
      ),
      body: KidScaffoldBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Mascot Companion — kids holding slates that show the
                // current English letter (instead of the Tamil "அ" in the GIF).
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _EnglishSlateKids(letter: letter.letter, height: 92),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          'Let\'s pronounce and practice letter "${letter.letter}"!',
                          style: AppTextStyles.cardTitle.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Giant Collectible Letter Card
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 380),
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(color: color.withValues(alpha: 0.4), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.22),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Illustration Image or Emoji Icon (Tappable to hear letter sound)
                        BouncyButton(
                          onPressed: _playAudio,
                          // Full card width (minus the card's padding) so the
                          // picture is big and easy to see.
                          child: Container(
                            width: double.infinity,
                            height: 165,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            decoration: BoxDecoration(
                              color: letter.imagePath != null ? Colors.white : color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: color.withValues(alpha: 0.35),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(21),
                              child: LetterMediaImage(
                                imagePath: letter.imagePath,
                                iconEmoji: letter.iconEmoji,
                                fit: BoxFit.contain,
                                emojiSize: 96,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Large Tamil Letter (Tappable to hear letter sound)
                        BouncyButton(
                          onPressed: _playAudio,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              letter.letter,
                              style: AppTextStyles.tamilLetterLarge.copyWith(
                                fontSize: 64,
                                color: color,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),

                        // Example Word with target letter highlighted - Tappable to hear WORD sound
                        if (letter.word.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          BouncyButton(
                            onPressed: _speakLetterWord,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(18, 4, 6, 4),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.35),
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildHighlightedWord(letter.word, letter.letter, color),
                                  const SizedBox(width: 10),
                                  // Mic button — tap to hear "A for Apple"
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _speaking ? color : Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: color, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.mic_rounded,
                                      size: 20,
                                      color: _speaking ? Colors.white : color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),


                // Direct Writing Practice Shortcut
                BouncyButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WritingPracticeScreen(
                          progressService: widget.progressService,
                          initialLetter: letter.letter,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF006E), Color(0xFFFF70A6)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF006E).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Practice Writing',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Teaching Video Button (if video_url is present from Admin Panel)
                if (letter.videoUrl != null && letter.videoUrl!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  BouncyButton(
                    onPressed: () {
                      final isMei = letter.type == LetterType.mei;
                      final videoItem = VideoItem(
                        id: 'letter_video_${letter.id}',
                        title: '${letter.letter} - ${letter.word} Video',
                        description: 'Special video lesson for letter ${letter.letter}',
                        category: isMei ? 'Consonants' : 'Vowels',
                        duration: '1:30',
                        thumbnailEmoji: '',
                        videoUrl: letter.videoUrl!,
                      );
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => VideoPlayerScreen(
                            video: videoItem,
                            progressService: widget.progressService,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7B1FA2), Color(0xFFAB47BC)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7B1FA2).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Watch Video Lesson',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // Previous / Next — right under the buttons above, not stuck to the
                // screen bottom (that left a big empty gap on tall phones).
                _buildPrevNextBar(hasPrev, hasNext, color),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The "writing" kids holding up their slates, with the current English
/// [letter] chalked on both slates.
///
/// writing.gif has the Tamil letter "அ" drawn into every frame, and the slates
/// move while the kids write, so a text overlay can't follow them. Instead we
/// use one still frame of the GIF where both slates face the viewer (frame 60,
/// served by Cloudinary as a PNG) and paint the letter over the slate centres.
class _EnglishSlateKids extends StatefulWidget {
  final String letter;
  final double height;

  const _EnglishSlateKids({required this.letter, required this.height});

  // Source frame is 246 x 243 px. Slate interiors (inside the hands), as
  // fractions of the frame: left = girl, right = boy.
  static const double _frameAspect = 246 / 243;
  static const List<Rect> _slates = [
    Rect.fromLTWH(32 / 246, 101 / 243, 44 / 246, 37 / 243),
    Rect.fromLTWH(163 / 246, 101 / 243, 46 / 246, 37 / 243),
  ];

  static String? get _frameUrl {
    final gif = CloudinaryMedia.getUrl('assets/gifs/writing.gif');
    if (gif == null || !gif.contains('/upload/')) return null;
    return gif.replaceFirst('/upload/', '/upload/pg_60/').replaceFirst(RegExp(r'\.gif$'), '.png');
  }

  @override
  State<_EnglishSlateKids> createState() => _EnglishSlateKidsState();
}

class _EnglishSlateKidsState extends State<_EnglishSlateKids> with SingleTickerProviderStateMixin {
  late final AnimationController _bounce =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final url = _EnglishSlateKids._frameUrl;
    final fallback = MascotWidget(
      pose: MascotPose.welcome,
      size: MascotSize.small,
      customHeight: widget.height,
      showGlow: true,
    );
    if (url == null) return fallback;

    final h = widget.height;
    final w = h * _EnglishSlateKids._frameAspect;

    return AnimatedBuilder(
      animation: _bounce,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -6 * Curves.easeInOut.transform(_bounce.value)),
        child: child,
      ),
      child: SizedBox(
        width: w,
        height: h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Soft glow, like the other mascots
            Container(
              width: h * 0.9,
              height: h * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFD166).withValues(alpha: 0.45),
                    const Color(0xFFFFD166).withValues(alpha: 0.0),
                  ],
                  radius: 0.7,
                ),
              ),
            ),
            Positioned.fill(
              child: Image.network(
                url,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stackTrace) => fallback,
                frameBuilder: (context, child, frame, wasSync) {
                  // Only draw the chalk letters once the picture has loaded.
                  if (frame == null && !wasSync) return const SizedBox.shrink();
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      child,
                      for (final r in _EnglishSlateKids._slates)
                        Positioned(
                          left: r.left * w,
                          top: r.top * h,
                          width: r.width * w,
                          height: r.height * h,
                          child: Container(
                            color: const Color(0xFF23262B), // slate black
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(1.5),
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: Text(
                                widget.letter,
                                style: const TextStyle(
                                  color: Color(0xFFF8F8F2), // chalk white
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
