import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/tamil_stroke_data.dart';
import '../models/handwriting_ml_model.dart';
import '../models/letter_stroke_model.dart';
import '../models/writing_practice_model.dart';
import '../services/audio_service.dart';
import '../services/tamil_handwriting_recognition_service.dart';

enum WritingCanvasMode {
  learn, // ✏️ கற்றுக்கொள்: Step-by-step guided tracing + audio announcement + one-time demo + ML recognition
  practice, // 🎯 பயிற்சி: Independent writing + real ML recognition
}

class WritingCanvas extends StatefulWidget {
  final String letter;
  final WritingCanvasMode mode;
  final Color strokeColor;
  final double strokeWidth;
  final Function(int strokeCount)? onStrokeUpdated;
  final Function(List<List<WritingPoint>> normalizedStrokes)? onStrokesChanged;
  final VoidCallback? onLetterCompleted;

  const WritingCanvas({
    super.key,
    required this.letter,
    this.mode = WritingCanvasMode.learn,
    this.strokeColor = const Color(0xFF3A86FF),
    this.strokeWidth = 18.0,
    this.onStrokeUpdated,
    this.onStrokesChanged,
    this.onLetterCompleted,
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

  void _initControllers() {
    _pulseController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    if (_demoController == null) {
      _demoController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2200),
      );

      _demoController!.addListener(() {
        if (mounted && _isDemoActive) setState(() {});
      });

      _demoController!.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // One-time demo completed! Stop cleanly and let the child draw!
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
    if (oldWidget.letter != widget.letter || oldWidget.mode != widget.mode) {
      _activeStepIndex = 0;
      clearCanvas();
    }
  }

  @override
  void dispose() {
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
    });
    if (playDemo) {
      playCurrentStepDemo();
    }
  }

  /// Speaks the step instruction and plays the path demo ONE TIME along the active stroke
  void playCurrentStepDemo() {
    _initControllers();
    final letterData = TamilStrokeDataRepository.getLetter(widget.letter);
    if (letterData.strokes.isEmpty) return;

    final curStep = activeStepIndex;
    final strokeIndex = curStep.clamp(0, letterData.strokes.length - 1);
    final stroke = letterData.strokes[strokeIndex];

    // 1. Speak step instruction (Audio Announcement)
    try {
      final cleanTitle = stroke.title.replaceAll(RegExp(r'[^\u0B80-\u0BFF0-9a-zA-Z\s:]'), '').trim();
      final cleanInstruction = stroke.instruction.replaceAll(RegExp(r'[^\u0B80-\u0BFF0-9a-zA-Z\s]'), '').trim();
      AudioService.instance.playTamilAudio('$cleanTitle. $cleanInstruction');
    } catch (_) {}

    // 2. Play animated demo ONE TIME along the stroke path
    if (mounted) {
      setState(() {
        _isDemoActive = true;
      });
    }
    _demoController?.duration = const Duration(milliseconds: 2200);
    _demoController?.forward(from: 0.0);
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
    });
    widget.onStrokeUpdated?.call(0);
    widget.onStrokesChanged?.call([]);
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

  /// Evaluates the drawn strokes using the Real ML Recognition Pipeline
  Future<HandwritingRecognitionResult> evaluateWithML() async {
    final allStrokes = List<List<Offset>>.from(_strokes);
    if (_currentStroke.isNotEmpty) {
      allStrokes.add(List.from(_currentStroke));
    }

    setState(() => _isRecognizing = true);

    final result = await TamilHandwritingRecognitionService.instance.recognizeStrokes(
      expectedLetter: widget.letter,
      userStrokes: allStrokes,
      canvasSize: _canvasSize,
    );

    if (mounted) {
      setState(() {
        _isRecognizing = false;
      });
    }

    return result;
  }

  // Smooth, lag-free Pointer Events
  void _onPointerDown(Offset localPos) {
    if (_isDemoActive) {
      _stopDemo();
    }
    setState(() {
      _currentStroke = [localPos];
    });
  }

  void _onPointerMove(Offset localPos) {
    if (_currentStroke.isEmpty) {
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
    if (_currentStroke.isEmpty) return;

    final letterData = TamilStrokeDataRepository.getLetter(widget.letter);

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

    // In Learn mode: Progressive step-by-step advancement
    if (widget.mode == WritingCanvasMode.learn && letterData.strokes.isNotEmpty) {
      final curStep = activeStepIndex;
      final lastStroke = _strokes.isNotEmpty ? _strokes.last : <Offset>[];
      double drawnDistance = 0.0;
      for (int i = 0; i < lastStroke.length - 1; i++) {
        drawnDistance += (lastStroke[i + 1] - lastStroke[i]).distance;
      }

      // Advance only if the child made an intentional drawing gesture
      if (lastStroke.length >= 3 && drawnDistance >= 12.0) {
        if (curStep < letterData.strokes.length - 1) {
          // Step finished! Give cheerful audio feedback and advance to next step
          try {
            AudioService.instance.playTamilAudio('அருமை!');
          } catch (_) {}

          Future.delayed(const Duration(milliseconds: 650), () {
            if (mounted) {
              setStep(curStep + 1, playDemo: true);
            }
          });
        } else {
          // Final step finished! All steps completed!
          try {
            AudioService.instance.playTamilAudio('அருமை! நீங்கள் ${widget.letter} எழுத்தை அழகாக எழுதி முடித்துவிட்டீர்கள்!');
          } catch (_) {}

          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              widget.onLetterCompleted?.call();
            }
          });
        }
      }
    }
  }

  void _onPointerCancel() {
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
                // 0. Authentic Font-Matched Hollow Tracing Guide (Learn Mode: 100% typography-accurate)
                if (isLearn)
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
                  // Practice Mode: Gentle watermark background
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
                          ),
                        );
                      },
                    ),
                  ),

                // 2. User Drawn Handwriting Strokes
                Positioned.fill(
                  child: CustomPaint(
                    painter: _HandwritingStrokesPainter(
                      strokes: _strokes,
                      currentStroke: _currentStroke,
                      strokeColor: widget.strokeColor,
                      strokeWidth: widget.strokeWidth,
                    ),
                  ),
                ),

                // 3. Pointer Listener for smooth drawing
                Positioned.fill(
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (e) => _onPointerDown(e.localPosition),
                    onPointerMove: (e) => _onPointerMove(e.localPosition),
                    onPointerUp: (e) => _onPointerUp(e.localPosition),
                    onPointerCancel: (_) => _onPointerCancel(),
                  ),
                ),

                // 4. Top Action & Step Pills Bar (Learn Mode)
                if (isLearn && letterData.strokes.isNotEmpty)
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Interactive Step Pills: [ ① படி 1 ] [ ② படி 2 ] [ ③ படி 3 ]
                        Flexible(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(letterData.strokes.length, (sIdx) {
                                final s = letterData.strokes[sIdx];
                                final isCur = sIdx == curStep;
                                final isDone = sIdx < curStep;
                                return GestureDetector(
                                  onTap: () => setStep(sIdx, playDemo: true),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isCur
                                          ? const Color(0xFFFF9F1C)
                                          : (isDone ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.9)),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isCur
                                            ? const Color(0xFFFF5400)
                                            : (isDone ? const Color(0xFF059669) : const Color(0xFFCBD5E1)),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        if (isCur)
                                          BoxShadow(
                                            color: const Color(0xFFFF9F1C).withValues(alpha: 0.35),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isDone)
                                          const Icon(Icons.check_circle_rounded, size: 14, color: Colors.white)
                                        else
                                          Icon(
                                            Icons.edit_note_rounded,
                                            size: 14,
                                            color: isCur ? Colors.white : const Color(0xFF475569),
                                          ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'படி ${s.strokeNumber}',
                                          style: TextStyle(
                                            fontFamily: 'Catamaran',
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: (isCur || isDone) ? Colors.white : const Color(0xFF475569),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),

                        // Demo Play Button: [ ▶ வழிகாட்டல் ]
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: playCurrentStepDemo,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
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
                                  const SizedBox(width: 4),
                                  Text(
                                    _isDemoActive ? 'காட்டுகிறது...' : 'வழிகாட்டல் ▶',
                                    style: TextStyle(
                                      fontFamily: 'Catamaran',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: _isDemoActive ? Colors.white : const Color(0xFF3A86FF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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

/// CustomPainter for rendering step-by-step progressive Tamil letter guidance
class _LetterPathGuidePainter extends CustomPainter {
  final TamilWritingLetter letterData;
  final int activeStepIndex;
  final double pulseValue;
  final double demoProgress;
  final bool isDemoActive;

  _LetterPathGuidePainter({
    required this.letterData,
    required this.activeStepIndex,
    required this.pulseValue,
    required this.demoProgress,
    required this.isDemoActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (letterData.strokes.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }

    // 1. Maintain 1:1 Aspect Ratio and Center on the Canvas (Alignd with font glyph)
    final double boxSide = math.min(size.width, size.height);
    final double drawSize = boxSide * 0.76;
    final double offsetX = (size.width - drawSize) / 2;
    final double offsetY = (size.height - drawSize) / 2;

    Offset toCanvas(Offset p) {
      return Offset(
        offsetX + p.dx * drawSize,
        offsetY + p.dy * drawSize,
      );
    }

    final double trackFillWidth = drawSize * 0.055;

    final int safeStep = letterData.strokes.isNotEmpty
        ? activeStepIndex.clamp(0, letterData.strokes.length - 1)
        : 0;

    // --- PHASE 1: Draw Start Badge ONLY at current active step start point ---
    if (safeStep >= 0 && safeStep < letterData.strokes.length) {
      final stroke = letterData.strokes[safeStep];
      final startPos = toCanvas(stroke.startPoint);
      _drawStepBadge(
        canvas,
        startPos,
        stroke.strokeNumber,
        pulseValue,
        isCurrent: true,
      );
    }

    // --- PHASE 2: Animated Demo Motion (for ACTIVE STEP ONLY when demo is triggered) ---
    if (isDemoActive && safeStep >= 0 && safeStep < letterData.strokes.length) {
      final stroke = letterData.strokes[safeStep];
      _drawSingleStrokeDemoMotion(canvas, stroke, toCanvas, trackFillWidth, demoProgress);
    }
  }

  void _drawStepBadge(Canvas canvas, Offset center, int stepNumber, double pulse, {required bool isCurrent}) {
    final double baseRadius = 14.5;
    final double radius = isCurrent ? baseRadius + (pulse * 2.2) : baseRadius;

    // Pulsing halo for current active step
    if (isCurrent) {
      final haloPaint = Paint()
        ..color = const Color(0xFFFF9F1C).withValues(alpha: 0.35 * (1.0 - pulse))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius + 8.0 * pulse, haloPaint);
    }

    // Drop shadow
    canvas.drawCircle(
      center.translate(0, 2),
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Badge circle
    final badgePaint = Paint()
      ..color = isCurrent ? const Color(0xFFFF9F1C) : const Color(0xFF3A86FF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, badgePaint);

    // White border
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, borderPaint);

    // Number text
    final textSpan = TextSpan(
      text: '$stepNumber',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w900,
        fontFamily: 'Catamaran',
        height: 1.0,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  void _drawSingleStrokeDemoMotion(
    Canvas canvas,
    LetterStrokeData stroke,
    Offset Function(Offset) toCanvas,
    double trackFillWidth,
    double progress,
  ) {
    final canvasPts = stroke.pathPoints.map(toCanvas).toList();
    if (canvasPts.isEmpty) return;

    if (stroke.isDot) {
      final c = toCanvas(stroke.startPoint);
      final r = trackFillWidth * (0.3 + 0.3 * progress);
      canvas.drawCircle(c, r, Paint()..color = const Color(0xFFFFB703)..style = PaintingStyle.fill);
      return;
    }

    if (canvasPts.length < 2) return;

    double totalLen = 0.0;
    final List<double> segmentLens = [];
    for (int i = 0; i < canvasPts.length - 1; i++) {
      final len = (canvasPts[i + 1] - canvasPts[i]).distance;
      segmentLens.add(len);
      totalLen += len;
    }

    if (totalLen <= 0) return;

    final targetDist = progress * totalLen;
    double accumulated = 0.0;
    Offset currentPos = canvasPts.first;

    final trailPaint = Paint()
      ..color = const Color(0xFFFFB703)
      ..strokeWidth = trackFillWidth * 0.72
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final trailPath = Path()..moveTo(canvasPts.first.dx, canvasPts.first.dy);

    for (int i = 0; i < canvasPts.length - 1; i++) {
      final p0 = canvasPts[i];
      final p1 = canvasPts[i + 1];
      final len = segmentLens[i];

      if (accumulated + len <= targetDist) {
        trailPath.lineTo(p1.dx, p1.dy);
        accumulated += len;
        currentPos = p1;
      } else {
        final remain = targetDist - accumulated;
        final ratio = (remain / (len > 0 ? len : 1.0)).clamp(0.0, 1.0);
        currentPos = Offset(
          p0.dx + (p1.dx - p0.dx) * ratio,
          p0.dy + (p1.dy - p0.dy) * ratio,
        );
        trailPath.lineTo(currentPos.dx, currentPos.dy);
        break;
      }
    }
    canvas.drawPath(trailPath, trailPaint);

    // Glowing Magic Pointer
    final pointerHalo = Paint()
      ..color = const Color(0xFFFF5400).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(currentPos, 16.0, pointerHalo);

    final pointerCore = Paint()
      ..color = const Color(0xFFFFBE0B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(currentPos, 9.0, pointerCore);

    final pointerBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(currentPos, 9.0, pointerBorder);

    // Hand icon
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.touch_app_rounded.codePoint),
        style: TextStyle(
          fontSize: 28,
          fontFamily: Icons.touch_app_rounded.fontFamily,
          package: Icons.touch_app_rounded.fontPackage,
          color: const Color(0xFFFF5400),
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(1, 2),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    iconPainter.paint(
      canvas,
      Offset(currentPos.dx + 4, currentPos.dy - 28),
    );
  }

  @override
  bool shouldRepaint(covariant _LetterPathGuidePainter oldDelegate) => true;
}

/// Smooth Painter for freehand user strokes using quadratic Bezier spline curves
class _HandwritingStrokesPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final Color strokeColor;
  final double strokeWidth;

  _HandwritingStrokesPainter({
    required this.strokes,
    required this.currentStroke,
    required this.strokeColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final glowPaint = Paint()
      ..color = strokeColor.withValues(alpha: 0.20)
      ..strokeWidth = strokeWidth + 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    for (final stroke in strokes) {
      _drawSmoothStroke(canvas, stroke, glowPaint);
      _drawSmoothStroke(canvas, stroke, paint);
    }
    if (currentStroke.isNotEmpty) {
      _drawSmoothStroke(canvas, currentStroke, glowPaint);
      _drawSmoothStroke(canvas, currentStroke, paint);
    }
  }

  void _drawSmoothStroke(Canvas canvas, List<Offset> stroke, Paint paint) {
    if (stroke.isEmpty) return;

    if (stroke.length == 1) {
      canvas.drawCircle(
        stroke.first,
        strokeWidth / 2,
        Paint()
          ..color = paint.color
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
      return;
    }

    if (stroke.length == 2) {
      canvas.drawLine(stroke.first, stroke.last, paint);
      return;
    }

    final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);

    for (int i = 1; i < stroke.length - 1; i++) {
      final p0 = stroke[i];
      final p1 = stroke[i + 1];
      final midX = (p0.dx + p1.dx) / 2.0;
      final midY = (p0.dy + p1.dy) / 2.0;
      path.quadraticBezierTo(p0.dx, p0.dy, midX, midY);
    }

    path.lineTo(stroke.last.dx, stroke.last.dy);
    canvas.drawPath(path, paint);
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
