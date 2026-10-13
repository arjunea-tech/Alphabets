import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/letter_stroke_model.dart';
import 'handwriting_validator.dart';
import 'writing_boundary_validator.dart';

/// Comprehensive Writing Engine for Tamil Handwriting Learning
class WritingEngine {
  /// Fraction of the canvas' shorter side used by the letter guide square.
  static const double guideScale = 0.76;

  /// The square on the canvas that stroke data and glyph outlines are normalized to.
  /// Every normalized -> canvas mapping must go through this so the letter,
  /// start/end markers and hit-testing all line up.
  static Rect guideRect(Size size) {
    final side = math.min(size.width, size.height) * guideScale;
    return Rect.fromLTWH((size.width - side) / 2, (size.height - side) / 2, side, side);
  }

  /// Maps a normalized (0..1) guide point to canvas pixels.
  static Offset toCanvas(Offset p, Size size) {
    final r = guideRect(size);
    return Offset(r.left + p.dx * r.width, r.top + p.dy * r.height);
  }

  /// Converts a normalized length (e.g. stroke tolerance) to canvas pixels.
  static double toCanvasLength(double v, Size size) => v * guideRect(size).width;

  /// Converts normalized waypoints into a continuous high-density smooth Catmull-Rom cubic Bezier path
  static Path generateSmoothSplinePath(List<Offset> pts, Size size) {
    final path = Path();
    if (pts.isEmpty || size.width <= 0 || size.height <= 0) return path;

    final realPts = pts.map((p) => toCanvas(p, size)).toList();
    if (realPts.length == 1) {
      path.addOval(Rect.fromCircle(center: realPts[0], radius: 3));
      return path;
    }
    if (realPts.length == 2) {
      path.moveTo(realPts[0].dx, realPts[0].dy);
      path.lineTo(realPts[1].dx, realPts[1].dy);
      return path;
    }

    path.moveTo(realPts[0].dx, realPts[0].dy);
    for (int i = 0; i < realPts.length - 1; i++) {
      final p0 = i > 0 ? realPts[i - 1] : realPts[i];
      final p1 = realPts[i];
      final p2 = realPts[i + 1];
      final p3 = i < realPts.length - 2 ? realPts[i + 2] : p2;

      final cp1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 5.5,
        p1.dy + (p2.dy - p0.dy) / 5.5,
      );
      final cp2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 5.5,
        p2.dy - (p3.dy - p1.dy) / 5.5,
      );
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }
    return path;
  }

  /// Dense sampled points along a stroke path for distance and boundary collision checks
  static List<Offset> sampleDensePoints(LetterStrokeData stroke, Size size, {double step = 6.0}) {
    if (stroke.pathPoints.isEmpty || size.width <= 0 || size.height <= 0) return [];
    if (stroke.pathPoints.length == 1) {
      return [toCanvas(stroke.pathPoints[0], size)];
    }

    final path = generateSmoothSplinePath(stroke.pathPoints, size);
    final List<Offset> result = [];
    for (final metric in path.computeMetrics()) {
      final len = metric.length;
      final count = math.max((len / step).ceil(), 2);
      for (int i = 0; i <= count; i++) {
        final dist = (i / count) * len;
        final tangent = metric.getTangentForOffset(dist);
        if (tangent != null) {
          result.add(tangent.position);
        }
      }
    }
    return result;
  }

  /// Checks if a touch point is within the allowed stroke boundary (Mode 2: Learn)
  static bool isPointInsideStrokeBoundary({
    required Offset point,
    required LetterStrokeData stroke,
    required Size size,
    double toleranceMultiplier = 1.0,
  }) {
    return WritingBoundaryValidator.isPointInsideStrokeBoundary(
      point: point,
      stroke: stroke,
      size: size,
      toleranceMultiplier: toleranceMultiplier,
    );
  }

  /// Evaluates progress (0.0 to 1.0) along a single stroke
  static double evaluateSingleStrokeProgress({
    required List<Offset> userPoints,
    required LetterStrokeData stroke,
    required Size size,
  }) {
    return WritingBoundaryValidator.evaluateSingleStrokeProgress(
      userPoints: userPoints,
      stroke: stroke,
      size: size,
    );
  }

  /// Mode 3 (Practice): Comprehensive Multi-Factor Handwriting Evaluation
  static HandwritingEvaluationResult evaluatePractice({
    required TamilWritingLetter targetLetter,
    required List<List<Offset>> userStrokes,
    required Size canvasSize,
  }) {
    return HandwritingValidator.evaluate(
      targetLetter: targetLetter,
      userStrokes: userStrokes,
      canvasSize: canvasSize,
    );
  }
}
