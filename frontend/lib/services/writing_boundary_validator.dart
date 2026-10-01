import 'dart:ui';
import '../models/letter_stroke_model.dart';
import 'writing_engine.dart';

/// Service responsible for validating touch boundaries, corridors, and tracing tolerances
class WritingBoundaryValidator {
  /// Checks if a touch point is within the allowed stroke boundary/corridor
  static bool isPointInsideStrokeBoundary({
    required Offset point,
    required LetterStrokeData stroke,
    required Size size,
    double toleranceMultiplier = 1.0,
  }) {
    if (stroke.pathPoints.isEmpty || size.width <= 0 || size.height <= 0) return false;

    final densePts = WritingEngine.sampleDensePoints(stroke, size);
    if (densePts.isEmpty) return false;

    final pixelRadius = stroke.tolerance * size.width * toleranceMultiplier;

    for (final samplePt in densePts) {
      if ((point - samplePt).distance <= pixelRadius) {
        return true;
      }
    }
    return false;
  }

  /// Finds the closest point on the stroke to the given touch point and returns distance
  static double getMinDistanceToStroke({
    required Offset point,
    required LetterStrokeData stroke,
    required Size size,
  }) {
    if (stroke.pathPoints.isEmpty || size.width <= 0 || size.height <= 0) {
      return double.infinity;
    }

    final densePts = WritingEngine.sampleDensePoints(stroke, size);
    if (densePts.isEmpty) return double.infinity;

    double minDist = double.infinity;
    for (final samplePt in densePts) {
      final dist = (point - samplePt).distance;
      if (dist < minDist) {
        minDist = dist;
      }
    }
    return minDist;
  }

  /// Evaluates progress (0.0 to 1.0) along a single stroke path based on user points
  static double evaluateSingleStrokeProgress({
    required List<Offset> userPoints,
    required LetterStrokeData stroke,
    required Size size,
  }) {
    if (userPoints.isEmpty || stroke.pathPoints.isEmpty || size.width <= 0 || size.height <= 0) {
      return 0.0;
    }
    final densePts = WritingEngine.sampleDensePoints(stroke, size);
    if (densePts.isEmpty) return 0.0;

    final hitRadius = stroke.tolerance * size.width * 1.35;
    final covered = List<bool>.filled(densePts.length, false);

    for (final uPt in userPoints) {
      for (int i = 0; i < densePts.length; i++) {
        if ((uPt - densePts[i]).distance <= hitRadius) {
          covered[i] = true;
        }
      }
    }

    final coveredCount = covered.where((c) => c).length;
    return coveredCount / densePts.length;
  }

  /// Checks if point is within the broad bounding area for the whole letter
  static bool isPointInLetterWritingZone({
    required Offset point,
    required Size size,
    double margin = 0.05,
  }) {
    final nx = point.dx / size.width;
    final ny = point.dy / size.height;
    return nx >= margin && nx <= (1.0 - margin) && ny >= margin && ny <= (1.0 - margin);
  }
}
