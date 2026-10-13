import 'dart:math' as math;
import 'dart:ui';
import '../models/letter_stroke_model.dart';
import 'writing_engine.dart';

/// Why a traced stroke was accepted or rejected in Learn mode.
enum StrokeAttemptStatus {
  correct,
  tooShort,
  wrongStart,
  wrongDirection,
  offPath,
  incomplete,
  missedDot,
  skippedCheckpoints,
}

class StrokeAttemptResult {
  final StrokeAttemptStatus status;
  final double coverage; // 0..1 of the target stroke traced
  final double precision; // 0..1 of the child's points that stayed on the track

  const StrokeAttemptResult(this.status, {this.coverage = 0, this.precision = 0});

  bool get isCorrect => status == StrokeAttemptStatus.correct;

  /// Short Tamil hint shown/spoken to the child.
  String get hint {
    switch (status) {
      case StrokeAttemptStatus.correct:
        return 'அருமை!';
      case StrokeAttemptStatus.tooShort:
        return 'விரலை எடுக்காமல் கோடு முழுவதும் எழுதவும்';
      case StrokeAttemptStatus.wrongStart:
        return 'பச்சை வட்டத்திலிருந்து தொடங்கவும்';
      case StrokeAttemptStatus.wrongDirection:
        return 'திசை தவறு! பச்சையில் தொடங்கி சிவப்பில் முடிக்கவும்';
      case StrokeAttemptStatus.offPath:
        return 'எழுத்தின் கோட்டின் மேலேயே எழுதவும்';
      case StrokeAttemptStatus.incomplete:
        return 'சிவப்பு புள்ளி வரை முழுமையாக எழுதவும்';
      case StrokeAttemptStatus.missedDot:
        return 'பச்சை வட்டத்தின் மேல் புள்ளி வைக்கவும்';
      case StrokeAttemptStatus.skippedCheckpoints:
        return 'எல்லா நட்சத்திரங்களையும் தொட்டு முழுமையாக எழுதவும் ⭐';
    }
  }
}

/// Service responsible for validating touch boundaries, corridors, and tracing tolerances
class WritingBoundaryValidator {
  // Learn-mode acceptance thresholds (child-friendly multipliers of stroke tolerance).
  static const double _startEndRadius = 1.8;
  static const double _onPathRadius = 2.0;
  static const double _coverageRadius = 1.6;
  static const double _minCoverage = 0.65;
  static const double _minPrecision = 0.45;

  /// Returns sequential normalized checkpoint ratios along a stroke (e.g. [0.06, 0.19, 0.42, 0.65, 0.85])
  static List<double> getCheckpointRatios(LetterStrokeData stroke) {
    if (stroke.isDot || stroke.pathPoints.length < 3) return const [];
    if (stroke.directionHint == 'loop_cw') {
      if (stroke.pathPoints.length > 120) {
        return const [0.03, 0.12, 0.28, 0.46, 0.65, 0.85];
      }
      return const [0.06, 0.19, 0.42, 0.65, 0.85];
    }
    if (stroke.pathPoints.length >= 16) {
      return const [0.12, 0.35, 0.60, 0.82];
    }
    if (stroke.pathPoints.length >= 8) {
      return const [0.20, 0.40, 0.60, 0.80];
    }
    return const [0.25, 0.50, 0.75];
  }

  /// Returns canvas positions of the star checkpoints along the stroke
  static List<Offset> getCheckpointPositions(LetterStrokeData stroke, Size size) {
    if (stroke.isDot || stroke.pathPoints.length < 3 || size.width <= 0 || size.height <= 0) return const [];
    final dense = WritingEngine.sampleDensePoints(stroke, size);
    if (dense.length < 4) return const [];
    final ratios = getCheckpointRatios(stroke);
    final pts = <Offset>[];
    for (final r in ratios) {
      final idx = ((dense.length - 1) * r).round().clamp(0, dense.length - 1);
      pts.add(dense[idx]);
    }
    return pts;
  }

  /// Returns how many checkpoints (in forward sequence) have been reached so far by userPoints
  static int getCollectedCheckpointsCount({
    required List<Offset> userPoints,
    required LetterStrokeData stroke,
    required Size size,
  }) {
    if (userPoints.isEmpty) return 0;
    final checkpoints = getCheckpointPositions(stroke, size);
    if (checkpoints.isEmpty) return 0;

    final tol = tolerancePx(stroke, size);
    final hitRadius = tol * 1.6;
    int count = 0;
    int searchStart = 0;

    for (final cp in checkpoints) {
      int hitIdx = -1;
      for (int u = searchStart; u < userPoints.length; u++) {
        if ((userPoints[u] - cp).distance <= hitRadius) {
          hitIdx = u;
          break;
        }
      }
      if (hitIdx != -1) {
        count++;
        searchStart = hitIdx + 1;
      } else {
        break; // strictly sequential forward collection!
      }
    }
    return count;
  }

  /// Stroke tolerance in canvas pixels (never smaller than a child's fingertip).
  static double tolerancePx(LetterStrokeData stroke, Size size) {
    return math.max(WritingEngine.toCanvasLength(stroke.tolerance, size), 22.0);
  }
  static double _tolerancePx(LetterStrokeData stroke, Size size) => tolerancePx(stroke, size);

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

    final pixelRadius = _tolerancePx(stroke, size) * toleranceMultiplier;

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

    final hitRadius = _tolerancePx(stroke, size) * 1.35;
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

  /// Learn mode: checks one traced stroke against the expected stroke -
  /// start point, direction, staying on the track, and reaching the end point.
  static StrokeAttemptResult checkStrokeAttempt({
    required List<Offset> userPoints,
    required LetterStrokeData stroke,
    required Size size,
  }) {
    if (userPoints.isEmpty || size.width <= 0 || size.height <= 0) {
      return const StrokeAttemptResult(StrokeAttemptStatus.tooShort);
    }

    final tol = _tolerancePx(stroke, size);
    final start = WritingEngine.toCanvas(stroke.startPoint, size);
    final end = WritingEngine.toCanvas(stroke.effectiveEndPoint, size);

    // Dots (pulli): a tap or a tiny scribble on the dot.
    if (stroke.isDot) {
      final centroid = userPoints.reduce((a, b) => a + b) / userPoints.length.toDouble();
      final ok = (userPoints.first - start).distance <= tol * _startEndRadius ||
          (centroid - start).distance <= tol * _startEndRadius;
      return StrokeAttemptResult(
        ok ? StrokeAttemptStatus.correct : StrokeAttemptStatus.missedDot,
        coverage: ok ? 1 : 0,
        precision: ok ? 1 : 0,
      );
    }

    final dense = WritingEngine.sampleDensePoints(stroke, size);
    if (dense.length < 2) return const StrokeAttemptResult(StrokeAttemptStatus.correct, coverage: 1, precision: 1);

    double drawn = 0, target = 0;
    for (int i = 0; i < userPoints.length - 1; i++) {
      drawn += (userPoints[i + 1] - userPoints[i]).distance;
    }
    for (int i = 0; i < dense.length - 1; i++) {
      target += (dense[i + 1] - dense[i]).distance;
    }
    if (userPoints.length < 3 || drawn < math.min(tol, target * 0.5)) {
      return const StrokeAttemptResult(StrokeAttemptStatus.tooShort);
    }

    // Nearest target sample for every user point.
    final nearestIdx = List<int>.filled(userPoints.length, 0);
    final nearestDist = List<double>.filled(userPoints.length, double.infinity);
    final covered = List<bool>.filled(dense.length, false);
    for (int u = 0; u < userPoints.length; u++) {
      final p = userPoints[u];
      for (int i = 0; i < dense.length; i++) {
        final d = (p - dense[i]).distance;
        if (d < nearestDist[u]) {
          nearestDist[u] = d;
          nearestIdx[u] = i;
        }
        if (d <= tol * _coverageRadius) covered[i] = true;
      }
    }
    final coverage = covered.where((c) => c).length / dense.length;
    final onPath = nearestDist.where((d) => d <= tol * _onPathRadius).length;
    final precision = onPath / userPoints.length;

    final maxStartDist = target > 0 ? math.min(tol * _startEndRadius, target * 0.25) : tol * _startEndRadius;
    final maxEndDist = target > 0 ? math.min(tol * _startEndRadius, target * 0.45) : tol * _startEndRadius;
    final startsAtStart = (userPoints.first - start).distance <= maxStartDist;
    final startsAtEnd = (userPoints.first - end).distance <= maxEndDist;
    final endsAtEnd = (userPoints.last - end).distance <= maxEndDist;

    // Direction: does the child move forward along the path (start -> end)?
    // Sample ~24 points; ignore large index jumps (closed loops wrap around).
    int forward = 0, backward = 0;
    final step = math.max(1, userPoints.length ~/ 24);
    final wrap = dense.length ~/ 2;
    for (int u = step; u < userPoints.length; u += step) {
      final delta = nearestIdx[u] - nearestIdx[u - step];
      if (delta.abs() >= wrap || delta == 0) continue;
      if (delta > 0) {
        forward++;
      } else {
        backward++;
      }
    }
    final reversed = backward >= 3 && backward > forward * 1.5;

    // Sequential star checkpoints verification: child must visit checkpoints in forward sequence!
    final checkpoints = getCheckpointPositions(stroke, size);
    bool checkpointsOk = true;
    if (checkpoints.isNotEmpty) {
      final hitRadius = tol * 1.85;
      int searchStart = 0;
      for (final cp in checkpoints) {
        int hitIdx = -1;
        for (int u = searchStart; u < userPoints.length; u++) {
          if ((userPoints[u] - cp).distance <= hitRadius) {
            hitIdx = u;
            break;
          }
        }
        if (hitIdx == -1) {
          checkpointsOk = false;
          break;
        }
        searchStart = hitIdx + 1;
      }

      // Segment-by-segment coverage: verify that the child traced along each curved segment
      // rather than shortcutting straight across between checkpoints.
      if (checkpointsOk) {
        final ratios = getCheckpointRatios(stroke);
        final segIndices = [
          0,
          ...ratios.map((r) => ((dense.length - 1) * r).round().clamp(0, dense.length - 1)),
          dense.length - 1,
        ];
        for (int s = 0; s < segIndices.length - 1; s++) {
          final segStart = segIndices[s];
          final segEnd = segIndices[s + 1];
          if (segEnd > segStart) {
            int segCovered = 0;
            for (int k = segStart; k <= segEnd; k++) {
              if (covered[k]) segCovered++;
            }
            final segCoverage = segCovered / (segEnd - segStart + 1);
            if (segCoverage < 0.40) {
              checkpointsOk = false;
              break;
            }
          }
        }
      }
    }

    StrokeAttemptStatus status;
    if (!startsAtStart) {
      status = (startsAtEnd || reversed) ? StrokeAttemptStatus.wrongDirection : StrokeAttemptStatus.wrongStart;
    } else if (reversed) {
      status = StrokeAttemptStatus.wrongDirection;
    } else if (coverage < _minCoverage || !endsAtEnd) {
      status = StrokeAttemptStatus.incomplete;
    } else if (!checkpointsOk) {
      status = StrokeAttemptStatus.skippedCheckpoints;
    } else if (precision < _minPrecision) {
      status = StrokeAttemptStatus.offPath;
    } else {
      status = StrokeAttemptStatus.correct;
    }
    return StrokeAttemptResult(status, coverage: coverage, precision: precision);
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
