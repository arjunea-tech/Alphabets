import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/letter_stroke_model.dart';
import 'handwriting_validator.dart';
import 'writing_boundary_validator.dart';

/// Comprehensive Writing Engine for Tamil Handwriting Learning
class WritingEngine {
  /// Converts normalized waypoints into a continuous high-density smooth Catmull-Rom cubic Bezier path
  static Path generateSmoothSplinePath(List<Offset> pts, Size size) {
    final path = Path();
    if (pts.isEmpty || size.width <= 0 || size.height <= 0) return path;

    final realPts = pts.map((p) => Offset(p.dx * size.width, p.dy * size.height)).toList();
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
      return [Offset(stroke.pathPoints[0].dx * size.width, stroke.pathPoints[0].dy * size.height)];
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
