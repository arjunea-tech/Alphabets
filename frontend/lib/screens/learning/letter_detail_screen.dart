import 'package:flutter/material.dart';
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
  }

  @override
  void dispose() {
    _audioService.stopAll();
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
              fontSize: 28,
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
                    _EnglishSlateKids(letter: letter.letter, height: 115),
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
                const SizedBox(height: 18),

                // Giant Collectible Letter Card
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 380),
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
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
                            height: 200,
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
                        const SizedBox(height: 16),

                        // Large Tamil Letter (Tappable to hear letter sound)
                        BouncyButton(
                          onPressed: _playAudio,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              letter.letter,
                              style: AppTextStyles.tamilLetterLarge.copyWith(
                                fontSize: 84,
                                color: color,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),

                        // Example Word with target letter highlighted - Tappable to hear WORD sound
                        if (letter.word.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          BouncyButton(
                            onPressed: () {},
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
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
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),


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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                const SizedBox(height: 18),

                // Previous / Next Buttons
                Row(
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
                ),
                const SizedBox(height: 20),
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
