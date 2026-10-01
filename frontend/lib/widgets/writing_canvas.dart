import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/handwriting_ml_model.dart';
import '../models/writing_practice_model.dart';
import '../services/tamil_handwriting_recognition_service.dart';

enum WritingCanvasMode {
  learn, // ✏️ கற்றுக்கொள்: Tracing over faint Unicode letter guide + ML recognition
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

class WritingCanvasState extends State<WritingCanvas> {
  Size _canvasSize = Size.zero;

  // Captured handwriting strokes
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  // ML Recognition status
  bool _isRecognizing = false;
  bool get isRecognizing => _isRecognizing;

  @override
  void initState() {
    super.initState();
    TamilHandwritingRecognitionService.instance.initialize().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant WritingCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.letter != widget.letter || oldWidget.mode != widget.mode) {
      clearCanvas();
    }
  }

  void clearCanvas() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
    });
    widget.onStrokeUpdated?.call(0);
    widget.onStrokesChanged?.call([]);
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

  // Smooth, lag-free Pointer Events (Listener eliminates gesture arena delays and starting dots)
  void _onPointerDown(Offset localPos) {
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
    // Filter out duplicate sub-pixel jitter
    if ((dx * dx + dy * dy) >= 1.0) {
      setState(() {
        _currentStroke.add(localPos);
      });
    }
  }

  void _onPointerUp(Offset localPos) {
    if (_currentStroke.isEmpty) return;

    setState(() {
      // If single tap dot (e.g. for pulli or ayutham), add a micro-offset point for solid dot rendering
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
    final isLearn = widget.mode == WritingCanvasMode.learn;

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
            final double letterFontSize = math.min(_canvasSize.width, _canvasSize.height) * 0.65;

            return Stack(
              alignment: Alignment.center,
              children: [
                // 1. Correct Tamil Unicode Font Rendering Guide (Shown only in Learn Mode)
                if (isLearn)
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        widget.letter,
                        style: TextStyle(
                          fontFamily: 'Catamaran',
                          fontSize: letterFontSize,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF3A86FF).withValues(alpha: 0.16),
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),

                // 2. User Drawn Handwriting Strokes with smooth bezier curves
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

                // 3. Ultra-responsive Pointer Listener for instantaneous, smooth drawing
                Positioned.fill(
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (e) => _onPointerDown(e.localPosition),
                    onPointerMove: (e) => _onPointerMove(e.localPosition),
                    onPointerUp: (e) => _onPointerUp(e.localPosition),
                    onPointerCancel: (_) => _onPointerCancel(),
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
                          color: const Color(0xFFCBD5E1).withValues(alpha: 0.4),
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: CustomPaint(
                painter: _SavedStrokesPainter(
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

class _SavedStrokesPainter extends CustomPainter {
  final List<List<WritingPoint>> strokes;
  final Color strokeColor;
  final double strokeWidth;

  _SavedStrokesPainter({
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
        final pt = stroke.first;
        canvas.drawCircle(
          Offset(pt.x * size.width, pt.y * size.height),
          strokeWidth / 2,
          Paint()
            ..color = strokeColor
            ..style = PaintingStyle.fill,
        );
        continue;
      }

      final path = Path();
      path.moveTo(stroke.first.x * size.width, stroke.first.y * size.height);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].x * size.width, stroke[i].y * size.height);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SavedStrokesPainter oldDelegate) => true;
}
