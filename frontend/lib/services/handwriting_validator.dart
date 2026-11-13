import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/letter_stroke_model.dart';
import 'writing_engine.dart';

export '../models/letter_stroke_model.dart' show HandwritingEvaluationResult;

/// Comprehensive multi-factor validator for handwriting evaluation (pass: more than [passPercent]% of the letter traced)
class HandwritingValidator {
  /// A trace must score MORE than this (%) to pass and move to the next letter.
  static const int passPercent = 85;

  /// Each individual stroke of the letter must be at least this much traced.
  static const double minStrokeCoverage = 0.70;

  static HandwritingEvaluationResult evaluate({
    required TamilWritingLetter targetLetter,
    required List<List<Offset>> userStrokes,
    required Size canvasSize,
  }) {
    // 0. Empty check
    if (userStrokes.isEmpty || userStrokes.every((s) => s.isEmpty)) {
      return const HandwritingEvaluationResult(
        score: 0,
        coverage: 0,
        precision: 0,
        stars: 0,
        isPass: false,
        title: 'Try Tracing!',
        message: 'Trace inside the letter outlines with your finger to check.',
        emoji: '✏️',
        badgeColor: Color(0xFFFF9F1C),
      );
    }

    final int totalUserPoints = userStrokes.fold(0, (sum, s) => sum + s.length);
    if (totalUserPoints < 8) {
      return HandwritingEvaluationResult(
        score: 0,
        coverage: 0.1,
        precision: 0.1,
        stars: 0,
        isPass: false,
        title: 'Incomplete Trace! (10% / 85%)',
        message: 'Please trace the full shape of letter "${targetLetter.letter}". More than 85% is needed to pass!',
        emoji: '✏️',
        badgeColor: const Color(0xFFFF5964),
      );
    }

    // 1. Gather all dense sample points from target strokes
    final List<List<Offset>> targetDenseStrokes = [];
    final List<Offset> allTargetDensePoints = [];

    for (final stroke in targetLetter.strokes) {
      final densePts = WritingEngine.sampleDensePoints(stroke, canvasSize);
      targetDenseStrokes.add(densePts);
      allTargetDensePoints.addAll(densePts);
    }

    if (allTargetDensePoints.isEmpty) {
      return HandwritingEvaluationResult(
        score: 90,
        coverage: 0.9,
        precision: 0.9,
        stars: 3,
        isPass: true,
        title: 'Awesome! Perfect!',
        message: 'You traced letter "${targetLetter.letter}" beautifully!',
        emoji: '🌟',
        badgeColor: const Color(0xFF10B981),
      );
    }

    // 2. Strict Hit Radius matching the actual letter canal track (~20px)
    final double targetHitRadius = math.max(canvasSize.width * 0.055, 20.0);
    int validUserPoints = 0;

    // Flatten user points
    final List<Offset> allUserPoints = [];
    for (final s in userStrokes) {
      allUserPoints.addAll(s);
    }

    // Assign every finger point to the ONE target stroke it is closest to, and
    // measure precision (must be near the letter path, not scribbled outside).
    // Without this, tracing A's two diagonals also "covered" both ends of the
    // short crossbar (they lie within the hit radius of the diagonals), so a
    // letter with a missing stroke could still pass.
    final List<List<Offset>> userPointsByStroke =
        List.generate(targetDenseStrokes.length, (_) => <Offset>[]);
    for (final up in allUserPoints) {
      double minDist = double.infinity;
      int nearestStroke = -1;
      for (int s = 0; s < targetDenseStrokes.length; s++) {
        for (final tp in targetDenseStrokes[s]) {
          final d = (up - tp).distance;
          if (d < minDist) {
            minDist = d;
            nearestStroke = s;
          }
        }
      }
      if (minDist <= targetHitRadius * 1.35) {
        validUserPoints++;
        userPointsByStroke[nearestStroke].add(up);
      }
    }

    // Per-stroke coverage: a stroke's points are covered only by finger points
    // that belong to that stroke.
    final List<double> strokeCoverages = [];
    for (int s = 0; s < targetDenseStrokes.length; s++) {
      final strokePts = targetDenseStrokes[s];
      if (strokePts.isEmpty) continue;
      final owned = userPointsByStroke[s];
      int coveredCount = 0;
      for (final tp in strokePts) {
        for (final up in owned) {
          if ((tp - up).distance <= targetHitRadius) {
            coveredCount++;
            break;
          }
        }
      }
      strokeCoverages.add(coveredCount / strokePts.length);
    }

    // Overall coverage: average of the strokes, each stroke weighted equally, so
    // skipping a short stroke (A's crossbar, E's middle bar) costs as much as
    // skipping a long one.
    final double coverage = strokeCoverages.isEmpty
        ? 0.0
        : strokeCoverages.reduce((a, b) => a + b) / strokeCoverages.length;

    // Precision: fraction of user points that stayed inside the letter canal
    final double precision = allUserPoints.isNotEmpty ? (validUserPoints / allUserPoints.length) : 0.0;

    // Every individual stroke must be mostly traced — no skipped lines.
    final bool allStrokesAttempted = strokeCoverages.every((c) => c >= minStrokeCoverage);

    // Score = how much of the letter was actually traced (coverage).
    // Staying inside the track earns no bonus; scribbling outside only lowers
    // the score (full marks while >= 80% of the finger points are on the track).
    final int coveragePercent = (coverage * 100).round();
    final double precisionFactor = (precision / 0.80).clamp(0.0, 1.0);
    final int finalScore = (coverage * 100.0 * precisionFactor).clamp(0.0, 100.0).round();
    final bool isPass = finalScore > passPercent && allStrokesAttempted;

    if (!isPass) {
      String failReason;
      if (!allStrokesAttempted) {
        failReason = 'Some parts of letter "${targetLetter.letter}" were missed! Trace along all the lines to fill it.';
      } else if (coveragePercent <= passPercent) {
        failReason = 'Filled $coveragePercent%. More than $passPercent% is needed to pass!';
      } else {
        failReason = 'Stay inside the letter track without drawing outside!';
      }

      return HandwritingEvaluationResult(
        score: finalScore.clamp(0, passPercent).toDouble(),
        coverage: coverage,
        precision: precision,
        stars: 0,
        isPass: false,
        title: 'Needs More Practice! ($finalScore% / $passPercent%)',
        message: failReason,
        emoji: '🔄',
        badgeColor: const Color(0xFFFF9F1C),
      );
    }

    final int stars = finalScore >= 95 ? 3 : 2;

    return HandwritingEvaluationResult(
      score: finalScore.toDouble(),
      coverage: coverage,
      precision: precision,
      stars: stars,
      isPass: true,
      title: finalScore >= 95 ? 'Awesome! Perfect! ($finalScore%)' : 'Well Done! ($finalScore%)',
      message: 'You traced letter "${targetLetter.letter}" with $finalScore% accuracy!',
      emoji: '🌟',
      badgeColor: const Color(0xFF10B981),
    );
  }
}
