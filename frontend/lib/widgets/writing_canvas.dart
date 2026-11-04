import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../data/tamil_letter_outlines.dart';
import '../data/tamil_stroke_data.dart';
import '../models/handwriting_ml_model.dart';
import '../models/letter_stroke_model.dart';
import '../models/writing_practice_model.dart';
import '../services/audio_service.dart';
import '../services/handwriting_validator.dart';
import '../services/tamil_handwriting_recognition_service.dart';
import '../services/writing_boundary_validator.dart';
import '../services/writing_engine.dart';

enum WritingCanvasMode {
  learn, //  ✏️ : Step-by-step guided tracing + audio announcement + one-time demo + ML recognition
  practice, //  🎯 : Independent writing + real ML recognition
}

class WritingCanvas extends StatefulWidget {
  final String letter;
  final WritingCanvasMode mode;
  final Color strokeColor;
  final double strokeWidth;
  final Function(int strokeCount)? onStrokeUpdated;
  final Function(List<List<WritingPoint>> normalizedStrokes)? onStrokesChanged;
  final VoidCallback? onLetterCompleted;
  final ValueChanged<bool>? onDrawingStateChanged;
  final ValueChanged<HandwritingEvaluationResult>? onEvaluationChanged;

  const WritingCanvas({
    super.key,
    required this.letter,
    this.mode = WritingCanvasMode.learn,
    this.strokeColor = const Color(0xFF3A86FF),
    this.strokeWidth = 18.0,
    this.onStrokeUpdated,
    this.onStrokesChanged,
    this.onLetterCompleted,
    this.onDrawingStateChanged,
    this.onEvaluationChanged,
  });

  @override
  WritingCanvasState createState() => WritingCanvasState();
}

class WritingCanvasState extends State<WritingCanvas> with TickerProviderStateMixin {
  Size _canvasSize = Size.zero;

  // Captured handwriting strokes
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  // Active step index for progressive step-by-step guidance
  int _activeStepIndex = 0;
  int get activeStepIndex {
    try {
      final dynamic idx = _activeStepIndex;
      if (idx is int) return idx;
    } catch (_) {}
    return 0;
  }

  // ML Recognition status
  bool _isRecognizing = false;
  bool get isRecognizing => _isRecognizing;

  // Route & Demo Animation
  AnimationController? _pulseController;
  AnimationController? _demoController;
  bool _isDemoActive = false;
  bool get isDemoActive => _isDemoActive;
  bool _isFullDemo = false;
  Timer? _stepTransitionTimer;

  // Learn-mode feedback for a wrongly traced stroke
  int _failedAttempts = 0;
  int _lastCollectedCheckpoints = 0;
  String? _hintText;
  Timer? _hintTimer;

  void _initControllers() {
    _pulseController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    if (_demoController == null) {
      _demoController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 3200),
      );

      _demoController!.addListener(() {
        if (mounted && _isDemoActive) setState(() {});
      });

      _demoController!.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (mounted) {
            setState(() {
              _isDemoActive = false;
            });
          }
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WritingEngine.activeLetter = widget.letter;
    _activeStepIndex = 0;
    _initControllers();
    TamilHandwritingRecognitionService.instance.initialize().then((_) {
      if (mounted) setState(() {});
    });

    // Auto-introduce Step 1 on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.mode == WritingCanvasMode.learn) {
        playCurrentStepDemo();
      }
    });
  }

  @override
  void didUpdateWidget(covariant WritingCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    WritingEngine.activeLetter = widget.letter;
    if (oldWidget.letter != widget.letter || oldWidget.mode != widget.mode) {
      _activeStepIndex = 0;
      clearCanvas();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _stepTransitionTimer?.cancel();
    _pulseController?.dispose();
    _demoController?.dispose();
    super.dispose();
  }

  /// Sets the active step, speaks it, and plays the demo one time
  void setStep(int stepIndex, {bool playDemo = true}) {
    final letterData = TamilStrokeDataRepository.getLetter(widget.letter);
    if (stepIndex < 0 || stepIndex >= letterData.strokes.length) return;
    setState(() {
      _activeStepIndex = stepIndex;
      _failedAttempts = 0;
    });
    if (playDemo) {
      playCurrentStepDemo();
    }
  }

  /// Plays a continuous animated demo showing the full letter smoothly in one go!
  void playFullGuideDemo() {
    _initControllers();
    if (_isDemoActive) {
      _stopDemo();
      return;
    }

    final letterData = TamilStrokeDataRepository.getLetter(widget.letter);
    if (letterData.strokes.isEmpty) return;

    setState(() {
      _isDemoActive = true;
      _hintText = null;
    });

    // Pronounce letter name
    try {
      AudioService.instance.playTamilAudio(widget.letter);
    } catch (_) {}

    final durationMs = 2800 + (letterData.strokes.length * 600);
    _demoController?.duration = Duration(milliseconds: durationMs);
    _demoController?.forward(from: 0.0);
  }

  /// Speaks the step instruction and plays the path demo
  void playCurrentStepDemo() {
    playFullGuideDemo();
  }

  void _stopDemo() {
    if (_isDemoActive) {
      setState(() {
        _isDemoActive = false;
        _demoController?.stop();
      });
    }
  }

  void clearCanvas() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
      _activeStepIndex = 0;
      _isDemoActive = false;
      _demoController?.stop();
      _failedAttempts = 0;
      _hintText = null;
    });
    widget.onStrokeUpdated?.call(0);
    widget.onStrokesChanged?.call([]);
    widget.onEvaluationChanged?.call(const HandwritingEvaluationResult(
      score: 0,
      coverage: 0,
      precision: 0,
      stars: 0,
      isPass: false,
      title: 'Try Tracing!',
      message: 'Trace inside the letter outlines with your finger to check.',
      emoji: '✏️',
      badgeColor: Color(0xFFFF9F1C),
    ));
    if (widget.mode == WritingCanvasMode.learn) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) playCurrentStepDemo();
      });
    }
  }

  int get totalPointsDrawn {
    int total = _strokes.fold(0, (acc, stroke) => acc + stroke.length);
    return total + _currentStroke.length;
  }

  int get strokeCount => _strokes.length + (_currentStroke.isNotEmpty ? 1 : 0);

  bool get hasContent => totalPointsDrawn > 0;

  List<List<WritingPoint>> getNormalizedStrokes() {
    if (_canvasSize.width <= 0 || _canvasSize.height <= 0) return [];

    return _strokes.map((stroke) {
      return stroke.asMap().entries.map((entry) {
        final idx = entry.key;
        final pt = entry.value;
        return WritingPoint(
          x: (pt.dx / _canvasSize.width).clamp(0.0, 1.0),
          y: (pt.dy / _canvasSize.height).clamp(0.0, 1.0),
          isEndOfStroke: idx == stroke.length - 1,
        );
      }).toList();
    }).toList();
  }

  /// Evaluates the drawn strokes using the Real ML Recognition Pipeline or English Stroke Validator
  Future<HandwritingRecognitionResult> evaluateWithML() async {
    final allStrokes = List<List<Offset>>.from(_strokes);
    if (_currentStroke.isNotEmpty) {
      allStrokes.add(List.from(_currentStroke));
    }

    setState(() => _isRecognizing = true);

    HandwritingRecognitionResult result;
    if (TamilHandwritingRecognitionService.defaultSupportedClasses.contains(widget.letter)) {
      result = await TamilHandwritingRecognitionService.instance.recognizeStrokes(
        expectedLetter: widget.letter,
        userStrokes: allStrokes,
        canvasSize: _canvasSize,
      );
    } else {
      // English Alphabet Letter Verification via HandwritingValidator
      final letterData = TamilStrokeDataRepository.getLetter(widget.letter);
      final eval = HandwritingValidator.evaluate(
        targetLetter: letterData,
        userStrokes: allStrokes,
        canvasSize: _canvasSize,
      );

      final totalPts = allStrokes.fold(0, (sum, s) => sum + s.length);
      final isMatch = eval.isPass;
      final conf = (eval.score / 100.0).clamp(0.0, 1.0);

      result = HandwritingRecognitionResult(
        expectedCharacter: widget.letter,
        recognizedCharacter: isMatch ? widget.letter : null,
        confidence: conf,
        strokeCount: allStrokes.length,
        totalPointCount: totalPts,
        modelStatus: MLModelStatus.loaded,
        isMatchExplicit: isMatch,
        errorMessage: isMatch ? null : eval.message,
      );
    }

    if (mounted) {
      setState(() {
        _isRecognizing = false;
      });
    }

    return result;
  }

  /// Checks if touch point is on or near the CURRENT ACTIVE STEP's corridor,
  /// and strictly NOT closer to future steps (e.g. step 2 vertical bar or step 3 curl while on step 1)!
  bool _isPointNearActiveStroke(Offset localPos) {
    if (_canvasSize.width <= 0 || _canvasSize.height <= 0) return true;
    final letterData = TamilStrokeDataRepository.getLetter(widget.letter);
    if (letterData.strokes.isEmpty) return true;

    final curStep = activeStepIndex.clamp(0, letterData.strokes.length - 1);
    final activeStroke = letterData.strokes[curStep];
    final activeDense = WritingEngine.sampleDensePoints(activeStroke, _canvasSize);
    if (activeDense.isEmpty) return true;

    // 1. Calculate minimum distance to active stroke centerline
    double minActiveDist = double.infinity;
    for (final pt in activeDense) {
      final d = (localPos - pt).distance;
      if (d < minActiveDist) minActiveDist = d;
    }

    // Max allowed touch radius from active stroke centerline (~24-28px, matches canal half-width with finger margin)
    final double maxAllowedDist = math.max(WritingEngine.guideRect(_canvasSize).width * 0.07, 24.0);
    if (minActiveDist > maxAllowedDist) {
      return false; // Point is too far from active stroke!
    }

    // 2. Anti-Skip: Check if point is closer to any FUTURE step than to the active step!
    // Prevents drawing on Step 2 or Step 3 while Step 1 is in progress.
    for (int f = curStep + 1; f < letterData.strokes.length; f++) {
      final futureStroke = letterData.strokes[f];
      final futureDense = WritingEngine.sampleDensePoints(futureStroke, _canvasSize);
      for (final fPt in futureDense) {
        final fDist = (localPos - fPt).distance;
        if (fDist < minActiveDist) {
          return false; // Point belongs to a future step, NOT active step!
        }
      }
    }

    return true;
  }

  // Smooth, lag-free Pointer Events
  void _onPointerDown(Offset localPos) {
    if (_isDemoActive) {
      _stopDemo();
    }
    widget.onDrawingStateChanged?.call(true);
    setState(() {
      _currentStroke = [localPos];
    });
  }

  void _onPointerMove(Offset localPos) {
    if (_currentStroke.isEmpty) {
      widget.onDrawingStateChanged?.call(true);
      setState(() {
        _currentStroke = [localPos];
      });
      return;
    }

    final last = _currentStroke.last;
    final dx = localPos.dx - last.dx;
    final dy = localPos.dy - last.dy;
    if ((dx * dx + dy * dy) >= 1.0) {
      setState(() {
        _currentStroke.add(localPos);
      });
    }
  }

  void _onPointerUp(Offset localPos) {
    widget.onDrawingStateChanged?.call(false);
    if (_currentStroke.isEmpty) return;

    setState(() {
      if (_currentStroke.length == 1) {
        _currentStroke.add(localPos.translate(0.5, 0.5));
      } else {
        _currentStroke.add(localPos);
      }
      _strokes.add(List.from(_currentStroke));
      _currentStroke.clear();
    });

    widget.onStrokeUpdated?.call(_strokes.length);
    widget.onStrokesChanged?.call(getNormalizedStrokes());

    // Instant real-time evaluation after each stroke
    if (_strokes.isNotEmpty && _canvasSize.width > 0 && _canvasSize.height > 0) {
      final allStrokes = List<List<Offset>>.from(_strokes);
      final letterData = TamilStrokeDataRepository.getLetter(widget.letter);
      final eval = HandwritingValidator.evaluate(
        targetLetter: letterData,
        userStrokes: allStrokes,
        canvasSize: _canvasSize,
      );
      widget.onEvaluationChanged?.call(eval);
    }
  }

  void _onPointerCancel() {
    widget.onDrawingStateChanged?.call(false);
    if (_currentStroke.isNotEmpty) {
      setState(() {
        _strokes.add(List.from(_currentStroke));
        _currentStroke.clear();
      });
      widget.onStrokeUpdated?.call(_strokes.length);
      widget.onStrokesChanged?.call(getNormalizedStrokes());
    }
  }

  @override
  Widget build(BuildContext context) {
    _initControllers();
    WritingEngine.activeLetter = widget.letter;
    final curStep = activeStepIndex;
    _activeStepIndex = curStep;
    final isLearn = widget.mode == WritingCanvasMode.learn;
    final letterData = TamilStrokeDataRepository.getLetter(widget.letter);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isLearn ? const Color(0xFF3A86FF) : const Color(0xFFFFD166),
          width: 4.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isLearn ? const Color(0xFF3A86FF) : const Color(0xFFFFD166))
                .withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: LayoutBuilder(
          builder: (context, constraints) {
            _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

            return Stack(
              alignment: Alignment.center,
              children: [
                // 0. Letter guide. Drawn from the same glyph outline the stroke paths were
                //    traced on, in the same guide square, so the start/end markers and
                //    paths always sit on the letter. Falls back to the font if no outline.
                if (TamilLetterOutlines.has(widget.letter))
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _LetterOutlinePainter(letter: widget.letter, isLearn: isLearn),
                      ),
                    ),
                  )
                else if (isLearn)
                  Positioned.fill(
                    child: Center(
                      child: IgnorePointer(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 0a. Outer Track Boundary (Soft Educational Blue Border)
                            Text(
                              widget.letter,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Catamaran',
                                fontSize: math.min(constraints.maxWidth, constraints.maxHeight) * 0.65,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 26.0
                                  ..strokeCap = StrokeCap.round
                                  ..strokeJoin = StrokeJoin.round
                                  ..color = const Color(0xFF93C5FD).withValues(alpha: 0.90),
                              ),
                            ),

                            // 0b. Hollow Tracing Channel (Smooth light canal where child traces)
                            Text(
                              widget.letter,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Catamaran',
                                fontSize: math.min(constraints.maxWidth, constraints.maxHeight) * 0.65,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 16.0
                                  ..strokeCap = StrokeCap.round
                                  ..strokeJoin = StrokeJoin.round
                                  ..color = const Color(0xFFF0F7FF),
                              ),
                            ),

                            // 0c. Soft inner letter core (shows authentic glyph shape clearly)
                            Text(
                              widget.letter,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Catamaran',
                                fontSize: math.min(constraints.maxWidth, constraints.maxHeight) * 0.65,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                                color: const Color(0xFF3A86FF).withValues(alpha: 0.14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Positioned.fill(
                    child: Center(
                      child: IgnorePointer(
                        child: Text(
                          widget.letter,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Catamaran',
                            fontSize: math.min(constraints.maxWidth, constraints.maxHeight) * 0.65,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFFFB703).withValues(alpha: 0.12),
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),

                // 1. Progressive Guided Path (Renders ACTIVE STEP ONLY; past steps faint, future steps hidden!)
                if (isLearn && _pulseController != null && _demoController != null)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_pulseController!, _demoController!]),
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _LetterPathGuidePainter(
                            letterData: letterData,
                            activeStepIndex: curStep,
                            pulseValue: _pulseController!.value,
                            demoProgress: _demoController!.value,
                            isDemoActive: _isDemoActive,
                            currentStroke: _currentStroke,
                          ),
                        );
                      },
                    ),
                  ),

                // 2. User Drawn Handwriting Strokes
                Positioned.fill(
                  child: CustomPaint(
                    painter: _HandwritingStrokesPainter(
                      letter: widget.letter,
                      strokes: _strokes,
                      currentStroke: _currentStroke,
                      strokeColor: widget.strokeColor,
                      strokeWidth: widget.strokeWidth,
                      clipBoundary: isLearn
                          ? TamilLetterOutlines.pathFor(widget.letter, WritingEngine.guideRect(_canvasSize, widget.letter))
                          : null,
                    ),
                  ),
                ),

                // 3. Pointer Listener for smooth drawing wrapped in EagerGestureRecognizer
                // to prevent parent SingleChildScrollView from intercepting writing gestures!
                Positioned.fill(
                  child: RawGestureDetector(
                    gestures: {
                      EagerGestureRecognizer: GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                        (EagerGestureRecognizer instance) {},
                      ),
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (e) => _onPointerDown(e.localPosition),
                      onPointerMove: (e) => _onPointerMove(e.localPosition),
                      onPointerUp: (e) => _onPointerUp(e.localPosition),
                      onPointerCancel: (_) => _onPointerCancel(),
                    ),
                  ),
                ),

                // 4. Top Guide Button (Learn Mode)
                if (isLearn && letterData.strokes.isNotEmpty)
                  Positioned(
                    top: 10,
                    right: 12,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: playFullGuideDemo,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            gradient: _isDemoActive
                                ? const LinearGradient(colors: [Color(0xFFFF9F1C), Color(0xFFFF5400)])
                                : null,
                            color: _isDemoActive ? null : Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isDemoActive ? const Color(0xFFFF5400) : const Color(0xFF3A86FF),
                              width: 1.6,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3A86FF).withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isDemoActive ? Icons.pause_circle_filled_rounded : Icons.play_arrow_rounded,
                                size: 18,
                                color: _isDemoActive ? Colors.white : const Color(0xFF3A86FF),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _isDemoActive ? 'Showing Guide...' : 'Guide ▶',
                                style: TextStyle(
                                  fontFamily: 'Catamaran',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: _isDemoActive ? Colors.white : const Color(0xFF3A86FF),
                                ),
                              ),
                            ],
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
    );
  }
}

/// Paints the letter outline as a hollow tracing track (Learn) or a soft watermark (Practice).
class _LetterOutlinePainter extends CustomPainter {
  final String letter;
  final bool isLearn;

  _LetterOutlinePainter({required this.letter, required this.isLearn});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final path = TamilLetterOutlines.pathFor(letter, WritingEngine.guideRect(size, letter));
    if (path == null) return;

    if (!isLearn) {
      canvas.drawPath(path, Paint()..color = const Color(0xFFFFB703).withValues(alpha: 0.14));
      return;
    }

    // 1. Soft clean groove/canal background
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFF1F5F9)
        ..style = PaintingStyle.fill,
    );
    // 2. Gentle welcoming inner canal tint
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF3A86FF).withValues(alpha: 0.08)
        ..style = PaintingStyle.fill,
    );
    // 3. Crisp canal border track
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF93C5FD),
    );
  }

  @override
  bool shouldRepaint(covariant _LetterOutlinePainter oldDelegate) =>
      oldDelegate.letter != letter || oldDelegate.isLearn != isLearn;
}

/// CustomPainter for rendering step-by-step progressive Tamil letter guidance
class _LetterPathGuidePainter extends CustomPainter {
  final TamilWritingLetter letterData;
  final int activeStepIndex;
  final double pulseValue;
  final double demoProgress;
  final bool isDemoActive;
  final List<Offset> currentStroke;

  _LetterPathGuidePainter({
    required this.letterData,
    required this.activeStepIndex,
    required this.pulseValue,
    required this.demoProgress,
    required this.isDemoActive,
    required this.currentStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (letterData.strokes.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }

    final double drawSize = WritingEngine.guideRect(size, letterData.letter).width;
    Offset toCanvas(Offset p) => WritingEngine.toCanvas(p, size, letterData.letter);
    final double trackFillWidth = drawSize * 0.055;

    // 1. Draw COMPLETE letter guide path for ALL strokes (Shows FULL letter guide!)
    for (final stroke in letterData.strokes) {
      if (!stroke.isDot && stroke.pathPoints.length > 1) {
        final dense = WritingEngine.sampleDensePoints(stroke, size);
        _drawDottedPath(canvas, dense, trackFillWidth, alpha: 0.70);
      } else if (stroke.isDot) {
        final c = toCanvas(stroke.startPoint);
        canvas.drawCircle(
          c,
          trackFillWidth * 0.5,
          Paint()
            ..color = const Color(0xFF3A86FF).withValues(alpha: 0.70)
            ..style = PaintingStyle.fill,
        );
      }
    }

    // 2. Draw a clean, gentle start indicator dot (NO numbered step circle badge!)
    if (letterData.strokes.isNotEmpty) {
      final firstStroke = letterData.strokes.first;
      final startPos = toCanvas(firstStroke.startPoint);
      _drawGentleStartIndicator(canvas, startPos, pulseValue);

      // Inviting direction arrow at the beginning
      if (!isDemoActive && currentStroke.isEmpty && firstStroke.pathPoints.length > 3) {
        final p0 = toCanvas(firstStroke.pathPoints[0]);
        final p1 = toCanvas(firstStroke.pathPoints[3]);
        _drawInitialDirectionArrow(canvas, p0, p1, pulseValue);
      }
    }

    // 3. FULL LETTER Animated Demo Motion across ALL strokes continuously
    if (isDemoActive) {
      _drawFullLetterDemoMotion(canvas, letterData.strokes, toCanvas, trackFillWidth, demoProgress);
    }
  }

  void _drawDottedPath(Canvas canvas, List<Offset> points, double trackFillWidth, {double alpha = 0.65}) {
    if (points.isEmpty) return;

    final dotPaint = Paint()
      ..color = const Color(0xFF3A86FF).withValues(alpha: alpha)
      ..style = PaintingStyle.fill;

    final double dotRadius = (trackFillWidth * 0.22).clamp(2.5, 4.5);
    final double spacing = dotRadius * 3.2;

    double accumulated = spacing;
    for (int i = 0; i < points.length; i++) {
      if (i > 0) {
        accumulated += (points[i] - points[i - 1]).distance;
      }
      if (accumulated >= spacing) {
        canvas.drawCircle(points[i], dotRadius, dotPaint);
        accumulated = 0.0;
      }
    }
  }

  void _drawGentleStartIndicator(Canvas canvas, Offset center, double pulse) {
    final double radius = 9.0 + (pulse * 1.8);

    // Soft pulsing halo
    final haloPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.35 * (1.0 - pulse))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius + 6.0 * pulse, haloPaint);

    // Green dot
    final dotPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, dotPaint);

    // Crisp white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, borderPaint);
  }

  void _drawInitialDirectionArrow(Canvas canvas, Offset p0, Offset p1, double pulse) {
    final v = p1 - p0;
    final dist = v.distance;
    if (dist <= 0) return;
    final dir = v / dist;
    final normal = Offset(-dir.dy, dir.dx);

    final bounce = (pulse * 4.5);
    final tip = p0 + dir * (24.0 + bounce);
    final base = tip - dir * 10.0;

    final arrowPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base.dx + normal.dx * 6.0, base.dy + normal.dy * 6.0)
      ..lineTo(base.dx - normal.dx * 6.0, base.dy - normal.dy * 6.0)
      ..close();

    final arrowPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.fill;
    canvas.drawPath(arrowPath, arrowPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawPath(arrowPath, borderPaint);
  }

  void _drawFullLetterDemoMotion(
    Canvas canvas,
    List<LetterStrokeData> strokes,
    Offset Function(Offset) toCanvas,
    double trackFillWidth,
    double progress,
  ) {
    if (strokes.isEmpty) return;

    double totalLetterLen = 0.0;
    final List<double> strokeLens = [];
    final List<List<Offset>> allCanvasPts = [];

    for (final stroke in strokes) {
      final canvasPts = stroke.pathPoints.map(toCanvas).toList();
      allCanvasPts.add(canvasPts);
      if (stroke.isDot) {
        strokeLens.add(10.0);
        totalLetterLen += 10.0;
      } else {
        double sLen = 0.0;
        for (int i = 0; i < canvasPts.length - 1; i++) {
          sLen += (canvasPts[i + 1] - canvasPts[i]).distance;
        }
        strokeLens.add(sLen);
        totalLetterLen += sLen;
      }
    }

    if (totalLetterLen <= 0) return;

    final double targetDist = progress.clamp(0.0, 1.0) * totalLetterLen;
    double accumulatedDist = 0.0;

    final trailPaint = Paint()
      ..color = const Color(0xFFFFB703)
      ..strokeWidth = trackFillWidth * 0.76
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    Offset? activeTip;

    for (int sIdx = 0; sIdx < strokes.length; sIdx++) {
      final stroke = strokes[sIdx];
      final canvasPts = allCanvasPts[sIdx];
      final sLen = strokeLens[sIdx];

      if (stroke.isDot) {
        if (targetDist >= accumulatedDist) {
          final c = toCanvas(stroke.startPoint);
          canvas.drawCircle(c, trackFillWidth * 0.5, Paint()..color = const Color(0xFFFFB703)..style = PaintingStyle.fill);
          activeTip = c;
        }
        accumulatedDist += sLen;
        continue;
      }

      if (canvasPts.length < 2) {
        accumulatedDist += sLen;
        continue;
      }

      if (accumulatedDist + sLen <= targetDist) {
        final fullPath = Path()..moveTo(canvasPts.first.dx, canvasPts.first.dy);
        for (int i = 1; i < canvasPts.length; i++) {
          fullPath.lineTo(canvasPts[i].dx, canvasPts[i].dy);
        }
        canvas.drawPath(fullPath, trailPaint);
        activeTip = canvasPts.last;
        accumulatedDist += sLen;
      } else if (targetDist > accumulatedDist) {
        final strokeTargetDist = targetDist - accumulatedDist;
        double segAccum = 0.0;
        final partialPath = Path()..moveTo(canvasPts.first.dx, canvasPts.first.dy);
        Offset currentPos = canvasPts.first;

        for (int i = 0; i < canvasPts.length - 1; i++) {
          final p0 = canvasPts[i];
          final p1 = canvasPts[i + 1];
          final segLen = (p1 - p0).distance;

          if (segAccum + segLen <= strokeTargetDist) {
            partialPath.lineTo(p1.dx, p1.dy);
            segAccum += segLen;
            currentPos = p1;
          } else {
            final remain = strokeTargetDist - segAccum;
            final ratio = (remain / (segLen > 0 ? segLen : 1.0)).clamp(0.0, 1.0);
            currentPos = Offset(
              p0.dx + (p1.dx - p0.dx) * ratio,
              p0.dy + (p1.dy - p0.dy) * ratio,
            );
            partialPath.lineTo(currentPos.dx, currentPos.dy);
            break;
          }
        }

        canvas.drawPath(partialPath, trailPaint);
        activeTip = currentPos;
        break;
      } else {
        break;
      }
    }

    // Draw glowing stylus / pointer tip
    if (activeTip != null) {
      canvas.drawCircle(
        activeTip,
        14.0,
        Paint()
          ..color = const Color(0xFFFFB703).withValues(alpha: 0.40)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        activeTip,
        7.0,
        Paint()
          ..color = const Color(0xFFFFF3B0)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        activeTip,
        3.5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LetterPathGuidePainter oldDelegate) => true;
}

/// Vibrant Rainbow Stroke Painter with optional letter boundary clipping mask
class _HandwritingStrokesPainter extends CustomPainter {
  final String letter;
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final Color strokeColor;
  final double strokeWidth;
  final Path? clipBoundary;

  _HandwritingStrokesPainter({
    required this.letter,
    required this.strokes,
    required this.currentStroke,
    required this.strokeColor,
    required this.strokeWidth,
    this.clipBoundary,
  });

  // Kid-friendly cheerful rainbow palette
  static const List<Color> _rainbowColors = [
    Color(0xFFFF1361), // Vibrant Neon Pink
    Color(0xFFFF5400), // Electric Orange
    Color(0xFFFFD166), // Sunshine Yellow
    Color(0xFF06D6A0), // Emerald Green
    Color(0xFF00C49F), // Fresh Turquoise
    Color(0xFF118AB2), // Bright Ocean Blue
    Color(0xFF7209B7), // Royal Purple
    Color(0xFFF72585), // Magenta Rose
  ];

  static Color _getRainbowColor(double progress) {
    final double t = progress.clamp(0.0, 1.0);
    final double scaled = t * (_rainbowColors.length - 1);
    final int idx = scaled.floor();
    final double remainder = scaled - idx;
    if (idx >= _rainbowColors.length - 1) return _rainbowColors.last;
    return Color.lerp(_rainbowColors[idx], _rainbowColors[idx + 1], remainder)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final double guideWidth = WritingEngine.guideRect(size, letter).width;
    final bool isSmall = letter.length == 1 &&
        letter.toLowerCase() == letter &&
        letter.toUpperCase() != letter;

    // Exact canal-matching stroke width:
    // Small letters have narrower tracks (~15-20px on mobile screens),
    // while capital letters have wider tracks (~20-25px).
    // Using guideWidth * 0.072 for small and guideWidth * 0.088 for capital ensures
    // the stroke fills neatly inside the canal without spilling or flooding nearby strokes!
    final double effectiveWidth = isSmall
        ? (guideWidth * 0.072).clamp(15.0, 20.0)
        : (guideWidth * 0.088).clamp(20.0, 26.0);

    canvas.save();
    if (clipBoundary != null) {
      // Clean mask: strokes cannot spill outside the letter canal!
      canvas.clipPath(clipBoundary!);
    }

    // Paint completed strokes
    for (int s = 0; s < strokes.length; s++) {
      _drawRainbowStroke(canvas, strokes[s], effectiveWidth);
    }

    // Paint active stroke
    if (currentStroke.isNotEmpty) {
      _drawRainbowStroke(canvas, currentStroke, effectiveWidth);
    }

    canvas.restore();

    // Redraw crisp canal border on top of the rainbow fill for a clean sticker/coloring-book finish!
    if (clipBoundary != null) {
      canvas.drawPath(
        clipBoundary!,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF93C5FD),
      );
    }
  }

  void _drawRainbowStroke(Canvas canvas, List<Offset> stroke, double width) {
    if (stroke.isEmpty) return;

    if (stroke.length == 1) {
      final color = _getRainbowColor(0.2);
      canvas.drawCircle(
        stroke.first,
        width * 0.5,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
      return;
    }

    final int n = stroke.length;
    for (int i = 0; i < n - 1; i++) {
      final double progress = (i / (n - 1));
      final color = _getRainbowColor(progress);
      final p0 = stroke[i];
      final p1 = stroke[i + 1];

      // Clean canal-bounded rainbow stroke
      canvas.drawLine(
        p0,
        p1,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HandwritingStrokesPainter oldDelegate) => true;
}

/// Standalone preview widget that renders previously saved strokes
class SavedHandwritingPreview extends StatelessWidget {
  final List<List<WritingPoint>> strokes;
  final String? ghostLetter;
  final Color strokeColor;
  final double strokeWidth;
  final Color backgroundColor;

  const SavedHandwritingPreview({
    super.key,
    required this.strokes,
    this.ghostLetter,
    this.strokeColor = const Color(0xFF3A86FF),
    this.strokeWidth = 4.0,
    this.backgroundColor = const Color(0xFFF8F9FA),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            if (ghostLetter != null && ghostLetter!.isNotEmpty)
              Positioned.fill(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        ghostLetter!,
                        style: TextStyle(
                          fontFamily: 'Catamaran',
                          fontSize: 120,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF3A86FF).withValues(alpha: 0.12),
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: CustomPaint(
                painter: _SavedPreviewPainter(
                  strokes: strokes,
                  strokeColor: strokeColor,
                  strokeWidth: strokeWidth,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedPreviewPainter extends CustomPainter {
  final List<List<WritingPoint>> strokes;
  final Color strokeColor;
  final double strokeWidth;

  _SavedPreviewPainter({
    required this.strokes,
    required this.strokeColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(
          Offset(stroke.first.x * size.width, stroke.first.y * size.height),
          strokeWidth / 2,
          Paint()
            ..color = strokeColor
            ..style = PaintingStyle.fill,
        );
        continue;
      }

      final path = Path()
        ..moveTo(stroke.first.x * size.width, stroke.first.y * size.height);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].x * size.width, stroke[i].y * size.height);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SavedPreviewPainter oldDelegate) => true;
}
