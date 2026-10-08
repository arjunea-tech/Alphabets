import 'package:flutter/material.dart';
import '../../data/writing_data.dart';
import '../../models/handwriting_ml_model.dart';
import '../../models/writing_practice_model.dart';
import '../../services/audio_service.dart';
import '../../services/progress_service.dart';
import '../../services/writing_practice_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/audio_button.dart';
import '../../widgets/kid_scaffold_background.dart';
import '../../widgets/letter_navigator.dart';
import '../../widgets/star_counter.dart';
import '../../widgets/writing_canvas.dart';
import 'writing_history_screen.dart';

class WritingPracticeScreen extends StatefulWidget {
  final ProgressService progressService;
  final String? initialLetter;

  const WritingPracticeScreen({
    super.key,
    required this.progressService,
    this.initialLetter,
  });

  @override
  State<WritingPracticeScreen> createState() => _WritingPracticeScreenState();
}

class _WritingPracticeScreenState extends State<WritingPracticeScreen> {
  final GlobalKey<WritingCanvasState> _canvasKey = GlobalKey<WritingCanvasState>();
  final WritingPracticeRepository _repo = LocalWritingPracticeRepository();

  int _selectedCategoryIndex = 0; // 0: Uyir, 1: Mei
  int _letterIndex = 0;
  WritingCanvasMode _activeMode = WritingCanvasMode.learn; // learn, practice
  Color _activeColor = const Color(0xFF3A86FF);
  final Set<String> _awardedLetters = {};

  final List<Color> _brushColors = const [
    Color(0xFF3A86FF), // Royal Blue
    Color(0xFFFF006E), // Vibrant Magenta
    Color(0xFF8338EC), // Purple
    Color(0xFFFB5607), // Orange
    Color(0xFF06D6A0), // Green
  ];

  List<WritingLetterGuide> get _currentList {
    if (_selectedCategoryIndex == 1) return WritingData.meiGuides;
    if (_selectedCategoryIndex == 2) return WritingData.ayuthamGuides;
    return WritingData.uyirGuides;
  }

  WritingLetterGuide get _currentGuide => _currentList[_letterIndex];

  String get _currentCategoryCode {
    if (_selectedCategoryIndex == 1) return 'mei';
    if (_selectedCategoryIndex == 2) return 'ayutham';
    return 'uyir';
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialLetter != null) {
      final idx = WritingData.uyirGuides.indexWhere((g) => g.letter == widget.initialLetter);
      if (idx >= 0) {
        _selectedCategoryIndex = 0;
        _letterIndex = idx;
      } else {
        final meiIdx = WritingData.meiGuides.indexWhere((g) => g.letter == widget.initialLetter);
        if (meiIdx >= 0) {
          _selectedCategoryIndex = 1;
          _letterIndex = meiIdx;
        } else {
          final ayuthaIdx = WritingData.ayuthamGuides.indexWhere((g) => g.letter == widget.initialLetter);
          if (ayuthaIdx >= 0) {
            _selectedCategoryIndex = 2;
            _letterIndex = ayuthaIdx;
          }
        }
      }
    }
  }

  /// Automatically saves the current writing practice if meaningful strokes exist.
  Future<void> _autoSaveCurrentPractice({bool completed = true}) async {
    final canvasState = _canvasKey.currentState;
    if (canvasState == null) return;

    final strokes = canvasState.getNormalizedStrokes();
    final totalPoints = canvasState.totalPointsDrawn;

    // Only save if meaningful strokes were drawn (at least 4 points)
    if (strokes.isEmpty || totalPoints < 4) return;

    final letter = _currentGuide.letter;
    final pastCount = await _repo.getAttemptCountForLetter(letter);

    final practice = WritingPractice(
      id: '${letter}_${DateTime.now().millisecondsSinceEpoch}',
      letter: letter,
      category: _currentCategoryCode,
      strokes: strokes,
      createdAt: DateTime.now(),
      attemptNumber: pastCount + 1,
      completed: completed,
    );

    await _repo.savePractice(practice);
  }

  Future<void> _switchCategory(int index) async {
    if (_selectedCategoryIndex == index) return;
    await _autoSaveCurrentPractice(completed: false);
    setState(() {
      _selectedCategoryIndex = index;
      _letterIndex = 0;
    });
    _canvasKey.currentState?.clearCanvas();
  }

  Future<void> _goToPrevious() async {
    if (_letterIndex > 0) {
      await _autoSaveCurrentPractice(completed: false);
      setState(() => _letterIndex--);
      _canvasKey.currentState?.clearCanvas();
    }
  }

  Future<void> _goToNext() async {
    if (_letterIndex < _currentList.length - 1) {
      await _autoSaveCurrentPractice(completed: false);
      setState(() => _letterIndex++);
      _canvasKey.currentState?.clearCanvas();
    }
  }

  /// Handles "சரிபார் / முடித்தேன்" using the AI Model recognition
  Future<void> _handleFinishWriting() async {
    final canvasState = _canvasKey.currentState;
    final hasDrawn = canvasState?.hasContent ?? false;

    if (!hasDrawn || (canvasState?.totalPointsDrawn ?? 0) < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFFF9F1C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: const Text(
            'விரலால் எழுதிப் பாருங்கள்!',
            style: TextStyle(
              fontFamily: 'Catamaran',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      );
      return;
    }

    // Evaluate writing accuracy using the Real ML Recognition Pipeline
    final mlResult = await canvasState!.evaluateWithML();

    if (mlResult.isMatch) {
      // Auto-save this successful practice
      await _autoSaveCurrentPractice(completed: true);

      final currentLetter = _currentGuide.letter;
      final starsToAdd = mlResult.stars > 0 ? mlResult.stars : 1;

      if (!_awardedLetters.contains(currentLetter)) {
        _awardedLetters.add(currentLetter);
        widget.progressService.addStars(starsToAdd);
        widget.progressService.markLetterCompleted(currentLetter);
      }

      if (!mounted) return;
      await AudioService.instance.playSuccessFeedback(context);

      if (!mounted) return;
      _showAccuracyResultDialog(mlResult, isSuccess: true);
    } else {
      // Encouraging retry / feedback modal
      if (!mounted) return;
      await AudioService.instance.playRetryFeedback(context);

      if (!mounted) return;
      _showAccuracyResultDialog(mlResult, isSuccess: false);
    }
  }

  /// Displays interactive feedback dialog
  void _showAccuracyResultDialog(HandwritingRecognitionResult result, {required bool isSuccess}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final String badgeText = isSuccess ? 'சரியானது' : 'முயற்சி செய்க';

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isSuccess ? const Color(0xFF10B981) : const Color(0xFFFFB703),
                width: 3.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isSuccess ? const Color(0xFF10B981) : const Color(0xFFFFB703))
                      .withValues(alpha: 0.22),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Letter with Status Chip
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isSuccess
                              ? [const Color(0xFF10B981), const Color(0xFF059669)]
                              : [const Color(0xFFFF9F1C), const Color(0xFFFF6B6B)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        _currentGuide.letter,
                        style: const TextStyle(
                          fontFamily: 'Catamaran',
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: result.badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: result.badgeColor, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSuccess ? Icons.check_circle_rounded : Icons.edit_note_rounded,
                            color: result.badgeColor,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            badgeText,
                            style: TextStyle(
                              fontFamily: 'Catamaran',
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: result.badgeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Star rating row if success
                if (isSuccess && result.stars > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (idx) {
                        final filled = idx < result.stars;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Icon(
                            Icons.star_rounded,
                            color: filled ? const Color(0xFFFFC107) : const Color(0xFFE2E8F0),
                            size: 42,
                          ),
                        );
                      }),
                    ),
                  ),

                // Title
                Text(
                  result.feedbackTitle,
                  style: const TextStyle(
                    fontFamily: 'Catamaran',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),

                // Subtitle / Feedback message
                Text(
                  result.feedbackMessage,
                  style: const TextStyle(
                    fontFamily: 'Catamaran',
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Action Buttons
                if (isSuccess) ...[
                  // Primary Next Button
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2EC4B6), Color(0xFF0F9F90)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2EC4B6).withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          if (_letterIndex < _currentList.length - 1) {
                            _goToNext();
                          } else {
                            _canvasKey.currentState?.clearCanvas();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                        label: const Text(
                          'அடுத்த எழுத்து',
                          style: TextStyle(
                            fontFamily: 'Catamaran',
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Secondary Retry Button
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _canvasKey.currentState?.clearCanvas();
                    },
                    icon: const Icon(Icons.replay_rounded, color: Color(0xFF3A86FF), size: 18),
                    label: const Text(
                      'மீண்டும் இதே எழுத்தை எழுத',
                      style: TextStyle(
                        fontFamily: 'Catamaran',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3A86FF),
                      ),
                    ),
                  ),
                ] else ...[
                  // Try Again Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _canvasKey.currentState?.clearCanvas();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9F1C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      icon: const Icon(Icons.replay_rounded, size: 20),
                      label: const Text(
                        'மீண்டும் எழுதவும்',
                        style: TextStyle(
                          fontFamily: 'Catamaran',
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Switch to Learn mode button
                  if (_activeMode != WritingCanvasMode.learn)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() => _activeMode = WritingCanvasMode.learn);
                        _canvasKey.currentState?.clearCanvas();
                      },
                      icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF3A86FF), size: 18),
                      label: const Text(
                        'கற்றுக்கொள் முறைக்கு மாறுக',
                        style: TextStyle(
                          fontFamily: 'Catamaran',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3A86FF),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Show bottom sheet with past handwriting attempts for the current letter
  void _showPreviousAttempts() async {
    final letter = _currentGuide.letter;
    final practices = await _repo.getPracticesForLetter(letter);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9F1C), Color(0xFFFF6B6B)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      letter,
                      style: const TextStyle(
                        fontFamily: 'Catamaran',
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'முந்தைய பயிற்சிகள்',
                      style: TextStyle(
                        fontFamily: 'Catamaran',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: practices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/writing.png',
                              width: 100,
                              height: 100,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.history_edu_rounded,
                                size: 60,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'இந்த எழுத்திற்கு முந்தைய பயிற்சிகள் இல்லை',
                              style: TextStyle(
                                fontFamily: 'Catamaran',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'எழுதி முடித்ததும் இங்கு தானாகச் சேமிக்கப்படும்!',
                              style: TextStyle(
                                fontFamily: 'Catamaran',
                                fontSize: 13,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: practices.length,
                        itemBuilder: (context, idx) {
                          final p = practices[idx];
                          final timeStr =
                              '${p.createdAt.day}/${p.createdAt.month}/${p.createdAt.year} ${p.createdAt.hour}:${p.createdAt.minute.toString().padLeft(2, '0')}';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 70,
                                  height: 70,
                                  child: SavedHandwritingPreview(
                                    strokes: p.strokes,
                                    ghostLetter: letter,
                                    strokeColor: const Color(0xFF3A86FF),
                                    strokeWidth: 3.5,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'பயிற்சி முறை #${p.attemptNumber}',
                                        style: const TextStyle(
                                          fontFamily: 'Catamaran',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        timeStr,
                                        style: const TextStyle(
                                          fontFamily: 'Catamaran',
                                          fontSize: 13,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF10B981),
                                  size: 22,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final guide = _currentGuide;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _autoSaveCurrentPractice(completed: false);
        }
      },
      child: Scaffold(
        body: KidScaffoldBackground(
          child: SafeArea(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  children: [
                    // Top Action Header
                    _buildTopHeader(context),

                    // Category Switcher Pill Tabs: [உயிர் (12)] & [மெய் (18)]
                    _buildCategorySwitcher(),

                    // Writing Area and Controls
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Column(
                          children: [
                            // Letter Navigator Bar (< அ >)
                            LetterNavigator(
                              currentLetter: guide.letter,
                              currentIndex: _letterIndex,
                              totalCount: _currentList.length,
                              onPrevious: _goToPrevious,
                              onNext: _goToNext,
                            ),
                            const SizedBox(height: 8),

                            // Mode Selector Bar: [ கற்றுக்கொள் ] | [ சுய பயிற்சி ]
                            _buildModeSelector(),
                            const SizedBox(height: 8),

                            // Mascot & Instruction Banner
                            _buildInstructionBanner(guide),
                            const SizedBox(height: 10),

                            // Writing Canvas (Learn & Practice)
                            AspectRatio(
                              aspectRatio: 1.05,
                              child: WritingCanvas(
                                key: _canvasKey,
                                letter: guide.letter,
                                mode: _activeMode,
                                strokeColor: _activeColor,
                                strokeWidth: 20.0,
                                onStrokeUpdated: (_) {},
                                onLetterCompleted: () {
                                  _handleFinishWriting();
                                },
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Crayon Color Palette
                            _buildColorPalette(),
                            const SizedBox(height: 12),

                            // Bottom Control Buttons: [ மீண்டும் எழுது ] & [ சரிபார் (Check) ]
                            _buildBottomControls(),
                            const SizedBox(height: 10),

                            // Previous attempts button
                            _buildPreviousAttemptsButton(),
                            const SizedBox(height: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: [
          // Back button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                _autoSaveCurrentPractice(completed: false);
                Navigator.of(context).pop();
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFD166), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Title
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: 6),
                  Text(
                    'எழுதிப் பழகு',
                    style: AppTextStyles.screenTitle.copyWith(fontSize: 22),
                  ),
                ],
              ),
            ),
          ),

          // Audio Pronunciation Button
          AudioButton(
            letter: _currentGuide.letter,
            word: _currentGuide.sampleWord,
            size: 40,
            color: const Color(0xFFFF9F1C),
          ),
          const SizedBox(width: 8),

          // History Screen Link Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                _autoSaveCurrentPractice(completed: false);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WritingHistoryScreen(
                      initialLetter: _currentGuide.letter,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF3A86FF), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.history_edu_rounded,
                  color: Color(0xFF3A86FF),
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Star Counter
          ListenableBuilder(
            listenable: widget.progressService,
            builder: (context, _) => StarCounter(count: widget.progressService.stars),
          ),
        ],
      ),
    );
  }

  /// 3-Category Switcher: [உயிர் (12)], [மெய் (18)] & [ஆய்தம் (1)]
  Widget _buildCategorySwitcher() {
    final categories = ['உயிர் (12)', 'மெய் (18)', 'ஆய்தம் (1)'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFFD166), width: 2),
        ),
        child: Row(
          children: List.generate(categories.length, (idx) {
            final isSelected = _selectedCategoryIndex == idx;
            return Expanded(
              child: GestureDetector(
                onTap: () => _switchCategory(idx),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFFFF9F1C), Color(0xFFFF6B6B)],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      categories[idx],
                      style: TextStyle(
                        fontFamily: 'Catamaran',
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  /// 2-Mode Selector: [ கற்றுக்கொள் ] | [ சுய பயிற்சி ]
  Widget _buildModeSelector() {
    final modes = [
      {'mode': WritingCanvasMode.learn, 'title': 'கற்றுக்கொள்', 'icon': Icons.edit_rounded, 'color': const Color(0xFF3A86FF)},
      {'mode': WritingCanvasMode.practice, 'title': 'சுய பயிற்சி', 'icon': Icons.track_changes_rounded, 'color': const Color(0xFF2EC4B6)},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2F6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
      ),
      child: Row(
        children: modes.map((m) {
          final modeVal = m['mode'] as WritingCanvasMode;
          final isSelected = _activeMode == modeVal;
          final activeColor = m['color'] as Color;
          final iconData = m['icon'] as IconData;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (_activeMode != modeVal) {
                  setState(() => _activeMode = modeVal);
                  _canvasKey.currentState?.clearCanvas();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected ? activeColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      iconData,
                      size: 15,
                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        m['title'] as String,
                        style: TextStyle(
                          fontFamily: 'Catamaran',
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.white : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInstructionBanner(WritingLetterGuide guide) {
    String bannerTitle;
    String bannerSub;
    Color bannerBg;
    Color bannerBorder;
    Color titleColor;

    if (_activeMode == WritingCanvasMode.learn) {
      bannerTitle = 'கற்றுக்கொள்: ①, ②, ③ வரிசைப்படி அம்புக்குறி வழியே எழுதுங்கள்!';
      bannerSub = 'எழுதும் முறையைக் காண "எழுதும் முறை ▶" பட்டனை அழுத்தவும்.';
      bannerBg = const Color(0xFFE0F2FE);
      bannerBorder = const Color(0xFF7DD3FC);
      titleColor = const Color(0xFF0369A1);
    } else {
      bannerTitle = 'சுய பயிற்சி: நீங்களே எழுதி சரிபாருங்கள்!';
      bannerSub = 'சரியாக எழுதினால் மட்டுமே வெற்றி கிடைக்கும். தவறாக எழுதினால் திருத்தலாம்.';
      bannerBg = const Color(0xFFFFF3CD);
      bannerBorder = const Color(0xFFFFE082);
      titleColor = const Color(0xFF5A3E00);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bannerBorder, width: 2),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/writing.png',
            width: 44,
            height: 44,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.edit_rounded, size: 30, color: Color(0xFF3A86FF)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bannerTitle,
                  style: TextStyle(
                    fontFamily: 'Catamaran',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: titleColor,
                  ),
                ),
                Text(
                  bannerSub,
                  style: TextStyle(
                    fontFamily: 'Catamaran',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: titleColor.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPalette() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'வண்ணங்கள்: ',
            style: TextStyle(
              fontFamily: 'Catamaran',
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF475569),
            ),
          ),
          ..._brushColors.map((c) {
            final isSelected = _activeColor == c;
            return GestureDetector(
              onTap: () => setState(() => _activeColor = c),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: c.withValues(alpha: isSelected ? 0.6 : 0.25),
                      blurRadius: isSelected ? 8 : 4,
                    ),
                  ],
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Row(
      children: [
        // Clear / Reset Button: "மீண்டும் எழுது"
        Expanded(
          flex: 4,
          child: ElevatedButton.icon(
            onPressed: () => _canvasKey.currentState?.clearCanvas(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF8F9FA),
              foregroundColor: const Color(0xFF495057),
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: const BorderSide(color: Color(0xFFCED4DA), width: 2),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'மீண்டும் எழுது',
                style: TextStyle(
                  fontFamily: 'Catamaran',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Check & Submit Button: "சரிபார் (Check) ⭐"
        Expanded(
          flex: 6,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: _activeMode == WritingCanvasMode.practice
                    ? [const Color(0xFF2EC4B6), const Color(0xFF0F9F90)]
                    : [const Color(0xFF3A86FF), const Color(0xFF0056D2)],
              ),
              boxShadow: [
                BoxShadow(
                  color: (_activeMode == WritingCanvasMode.practice
                          ? const Color(0xFF2EC4B6)
                          : const Color(0xFF3A86FF))
                      .withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _handleFinishWriting,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _activeMode == WritingCanvasMode.practice
                      ? 'சரிபார் (Check)'
                      : 'சரிபார் / முடித்தேன்',
                  style: const TextStyle(
                    fontFamily: 'Catamaran',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviousAttemptsButton() {
    return TextButton.icon(
      onPressed: _showPreviousAttempts,
      icon: const Icon(Icons.visibility_rounded, color: Color(0xFF3A86FF), size: 18),
      label: Text(
        '${_currentGuide.letter} – முந்தைய பயிற்சிகள்',
        style: const TextStyle(
          fontFamily: 'Catamaran',
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF3A86FF),
        ),
      ),
    );
  }
}
