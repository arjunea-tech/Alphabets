import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/tamil_stroke_data.dart';
import '../../data/writing_data.dart';
import '../../data/tamil_letter_outlines.dart';
import '../../models/handwriting_ml_model.dart';
import '../../models/letter_stroke_model.dart';
import '../../models/writing_practice_model.dart';
import '../../services/audio_service.dart';
import '../../services/language_service.dart';
import '../../services/progress_service.dart';
import '../../services/handwriting_validator.dart';
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

  int _selectedCategoryIndex = 0; // 0: Uyir / Achulu, 1: Mei / Hallulu
  int _letterIndex = 0;
  final WritingCanvasMode _activeMode = WritingCanvasMode.learn; // learn
  final Color _activeColor = const Color(0xFF3A86FF);
  bool _isCanvasDrawing = false;
  final Set<String> _awardedLetters = {};
  HandwritingEvaluationResult? _lastEvaluation;
  bool _isAutoAdvancing = false;

  /// When a finished attempt scores 85% or less, the canvas is wiped after the
  /// child stops writing for [_retryDelay] so they write the letter again.
  static const Duration _retryDelay = Duration(seconds: 2);
  Timer? _retryTimer;
  int _strokesDrawn = 0;



  List<WritingLetterGuide> get _currentList {
    if (_selectedCategoryIndex == 1) return WritingData.smallLetterGuides;
    if (_selectedCategoryIndex == 2) return WritingData.uyirGuides;
    if (_selectedCategoryIndex == 3) return WritingData.meiGuides;
    return WritingData.allGuides;
  }

  WritingLetterGuide get _currentGuide => _currentList[_letterIndex];

  String get _currentCategoryCode {
    if (_selectedCategoryIndex == 1) return 'small';
    if (_selectedCategoryIndex == 2) return 'vowels';
    if (_selectedCategoryIndex == 3) return 'consonants';
    return 'capital';


  }

  @override
  void initState() {
    super.initState();
    if (widget.initialLetter != null) {
      final target = widget.initialLetter!;
      final smallIdx = WritingData.smallLetterGuides.indexWhere((g) => g.letter == target);
      if (smallIdx >= 0) {
        _selectedCategoryIndex = 1;
        _letterIndex = smallIdx;
      } else {
        final allIdx = WritingData.allGuides.indexWhere((g) => g.letter.toUpperCase() == target.toUpperCase());
        if (allIdx >= 0) {
          _selectedCategoryIndex = 0;
          _letterIndex = allIdx;
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
      _lastEvaluation = null;
      _isAutoAdvancing = false;
    });
    TamilLetterOutlines.clearCache();
    _canvasKey.currentState?.clearCanvas();
  }

  Future<void> _goToPrevious() async {
    if (_letterIndex > 0) {
      await _autoSaveCurrentPractice(completed: false);
      setState(() {
        _letterIndex--;
        _lastEvaluation = null;
        _isAutoAdvancing = false;
      });
      _canvasKey.currentState?.clearCanvas();
    }
  }

  Future<void> _goToNext() async {
    if (_letterIndex < _currentList.length - 1) {
      await _autoSaveCurrentPractice(completed: false);
      setState(() {
        _letterIndex++;
        _lastEvaluation = null;
        _isAutoAdvancing = false;
      });
      _canvasKey.currentState?.clearCanvas();
    }
  }

  /// Real-time stroke evaluation: If accuracy is above HandwritingValidator.passPercent (85%), automatically advances to next letter!
  void _onEvaluationChanged(HandwritingEvaluationResult eval) {
    // Any new evaluation (new stroke, Clear, letter change) restarts the wait.
    _retryTimer?.cancel();
    if (_isAutoAdvancing) return;

    setState(() {
      _lastEvaluation = eval;
    });

    if (eval.isPass && eval.score > HandwritingValidator.passPercent) {
      _isAutoAdvancing = true;
      _triggerSuccessAndAutoAdvance(eval);
      return;
    }

    // Failed attempt: once the child has drawn at least as many strokes as the
    // letter has (so a multi-stroke letter like A isn't wiped halfway) and then
    // stops writing, clear the canvas so they write it again.
    final expectedStrokes = TamilStrokeDataRepository.getLetter(_currentGuide.letter).strokes.length;
    if (eval.score > 0 && _strokesDrawn >= expectedStrokes) {
      _retryTimer = Timer(_retryDelay, _autoRetry);
    }
  }

  void _autoRetry() {
    if (!mounted || _isAutoAdvancing || _isCanvasDrawing) return;
    final scorePct = _lastEvaluation?.score.round() ?? 0;
    _canvasKey.currentState?.clearCanvas();
    setState(() => _lastEvaluation = null);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFFFF9F1C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Text(
            '$scorePct% — need above ${HandwritingValidator.passPercent}%. Write "${_currentGuide.letter}" again! ✏️',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      );
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> _triggerSuccessAndAutoAdvance(HandwritingEvaluationResult eval) async {
    final currentLetter = _currentGuide.letter;
    final starsToAdd = eval.stars > 0 ? eval.stars : 2;

    if (!_awardedLetters.contains(currentLetter)) {
      _awardedLetters.add(currentLetter);
      widget.progressService.addStars(starsToAdd);
      widget.progressService.markLetterCompleted(currentLetter);
    }

    await _autoSaveCurrentPractice(completed: true);

    // Friendly 1000ms delay to let the kid admire their completed letter and score
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    if (_letterIndex < _currentList.length - 1) {
      await _goToNext();
      if (mounted) {
        setState(() {
          _lastEvaluation = null;
          _isAutoAdvancing = false;
        });
      }
    } else {
      // Completed all letters in list!
      if (mounted) {
        setState(() {
          _isAutoAdvancing = false;
        });
        _showAccuracyResultDialog(
          HandwritingRecognitionResult(
            expectedCharacter: currentLetter,
            recognizedCharacter: currentLetter,
            confidence: eval.score / 100.0,
            strokeCount: eval.stars,
            totalPointCount: 100,
            modelStatus: MLModelStatus.loaded,
            isMatchExplicit: true,
          ),
          isSuccess: true,
        );
      }
    }
  }

  /// Handles handwriting check strictly using the 85% pass mark and precision evaluation
  Future<void> _handleFinishWriting() async {
    final canvasState = _canvasKey.currentState;
    final hasDrawn = canvasState?.hasContent ?? false;

    if (!hasDrawn || (canvasState?.totalPointsDrawn ?? 0) < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFFF9F1C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: const Text(
            'Trace the letter inside the outlines first!',
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

    // Rigorously evaluate strokes against the 85% pass mark
    final HandwritingRecognitionResult mlResult = await canvasState!.evaluateWithML();

    if (mlResult.isMatch) {
      // Auto-save this successful practice
      await _autoSaveCurrentPractice(completed: true);

      final currentLetter = _currentGuide.letter;
      final starsToAdd = mlResult.stars > 0 ? mlResult.stars : 2;

      if (!_awardedLetters.contains(currentLetter)) {
        _awardedLetters.add(currentLetter);
        widget.progressService.addStars(starsToAdd);
        widget.progressService.markLetterCompleted(currentLetter);
      }

      if (!mounted) return;
      _showAccuracyResultDialog(mlResult, isSuccess: true);
    } else {
      // Encouraging retry / feedback modal
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
        final String badgeText = isSuccess ? 'Correct!' : 'Try Again';

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
                          'Next Letter',
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
                      'Rewrite this letter',
                      style: TextStyle(
                        fontFamily: 'Catamaran',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3A86FF),
                      ),
                    ),
                  ),
                ] else ...[
                  // Try Again / Rewrite Button
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
                        'Retry & Rewrite ✏️',
                        style: TextStyle(
                          fontFamily: 'Catamaran',
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Watch Guide Button
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _canvasKey.currentState?.clearCanvas();
                      _canvasKey.currentState?.playFullGuideDemo();
                    },
                    icon: const Icon(Icons.play_circle_filled_rounded, color: Color(0xFF3A86FF), size: 20),
                    label: const Text(
                      'Watch Guide Animation ▶',
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

                    // Category Switcher Pill Tabs: [ (12)] & [ (18)]
                    _buildCategorySwitcher(),

                    // Writing Area and Controls
                    Expanded(
                      child: SingleChildScrollView(
                        physics: _isCanvasDrawing
                            ? const NeverScrollableScrollPhysics()
                            : const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Column(
                          children: [
                            // Letter Navigator Bar (<  >)
                            LetterNavigator(
                              currentLetter: guide.letter,
                              currentIndex: _letterIndex,
                              totalCount: _currentList.length,
                              onPrevious: _goToPrevious,
                              onNext: _goToNext,
                            ),
                            const SizedBox(height: 8),

                            // Mode Header: [  ]
                            _buildModeSelector(),
                            const SizedBox(height: 12),

                            // Writing Canvas (Learn Mode)
                            AspectRatio(
                              aspectRatio: 1.05,
                              child: WritingCanvas(
                                key: _canvasKey,
                                letter: guide.letter,
                                mode: _activeMode,
                                strokeColor: _activeColor,
                                strokeWidth: 20.0,
                                onStrokeUpdated: (count) => _strokesDrawn = count,
                                onLetterCompleted: () {},
                                onEvaluationChanged: _onEvaluationChanged,
                                onDrawingStateChanged: (drawing) {
                                  // Child started writing again — don't wipe it.
                                  if (drawing) _retryTimer?.cancel();
                                  if (_isCanvasDrawing != drawing && mounted) {
                                    setState(() => _isCanvasDrawing = drawing);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Bottom Control Buttons: [   ] & [  /  ]
                            _buildBottomControls(),
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
                    'Writing Practice',
                    style: AppTextStyles.screenTitle.copyWith(fontSize: 22),
                  ),
                ],
              ),
            ),
          ),


        ],
      ),
    );
  }

  /// Category Switcher (Horizontally scrollable with individual pill chips)
  Widget _buildCategorySwitcher() {
    const categories = ['Capital (A-Z)', 'Small (a-z)', 'Vowels (5)', 'Consonants (21)'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, idx) {
            final isSelected = _selectedCategoryIndex == idx;
            return GestureDetector(
              onTap: () => _switchCategory(idx),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFFFF9F1C), Color(0xFFFF6B6B)],
                        )
                      : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : const Color(0xFFFFD166),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? const Color(0xFFFF9F1C).withValues(alpha: 0.35)
                          : Colors.black.withValues(alpha: 0.04),
                      blurRadius: isSelected ? 6 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    categories[idx],
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'Catamaran',
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Mode Header: [  ]
  Widget _buildModeSelector() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 22),
        decoration: BoxDecoration(
          color: const Color(0xFF3A86FF),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3A86FF).withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text(
              'Learn',
              style: TextStyle(
                fontFamily: 'Catamaran',
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildBottomControls() {
    final eval = _lastEvaluation;
    final int scorePct = eval != null ? eval.score.round() : 0;
    final bool hasDrawn = eval != null && scorePct > 0;
    final bool isPassed = eval != null && eval.isPass && scorePct > HandwritingValidator.passPercent;

    String statusText;
    if (_isAutoAdvancing) {
      statusText = '🎉 $scorePct% - Moving to Next Letter... 🚀';
    } else if (isPassed) {
      statusText = '⭐ $scorePct% - Great Job!';
    } else if (hasDrawn) {
      statusText = '$scorePct% Correct (Need above ${HandwritingValidator.passPercent}%) ✏️';
    } else {
      statusText = 'Trace inside outlines with your finger ✍️';
    }

    return Row(
      children: [
        // Clear / Reset Button
        ElevatedButton.icon(
          onPressed: () {
            _canvasKey.currentState?.clearCanvas();
            setState(() {
              _lastEvaluation = null;
              _isAutoAdvancing = false;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF8F9FA),
            foregroundColor: const Color(0xFF495057),
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: Color(0xFFCED4DA), width: 2),
            ),
            elevation: 0,
          ),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text(
            'Clear',
            style: TextStyle(
              fontFamily: 'Catamaran',
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Live Accuracy Percentage Card (Replaces old Submit button)
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: isPassed
                    ? [const Color(0xFF10B981), const Color(0xFF059669)]
                    : (hasDrawn
                        ? [const Color(0xFFFF9F1C), const Color(0xFFF77F00)]
                        : [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)]),
              ),
              boxShadow: [
                if (hasDrawn)
                  BoxShadow(
                    color: (isPassed ? const Color(0xFF10B981) : const Color(0xFFFF9F1C))
                        .withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPassed
                      ? Icons.check_circle_rounded
                      : (hasDrawn ? Icons.draw_rounded : Icons.touch_app_rounded),
                  color: hasDrawn ? Colors.white : const Color(0xFF64748B),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontFamily: 'Catamaran',
                      color: hasDrawn ? Colors.white : const Color(0xFF475569),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
