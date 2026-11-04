import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/letter_stroke_model.dart';
import 'writing_engine.dart';

/// Comprehensive multi-factor validator for handwriting evaluation (Strict 80% Requirement)
class HandwritingValidator {
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
        score: 10,
        coverage: 0.1,
        precision: 0.1,
        stars: 0,
        isPass: false,
        title: 'Incomplete Trace! (10% / 70%)',
        message: 'Please trace the full shape of letter "${targetLetter.letter}". At least 70% is needed to pass!',
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
    final List<bool> coveredTarget = List<bool>.filled(allTargetDensePoints.length, false);
    int validUserPoints = 0;

    // Flatten user points
    final List<Offset> allUserPoints = [];
    for (final s in userStrokes) {
      allUserPoints.addAll(s);
    }

    // Check each target point against user touch points
    for (int i = 0; i < allTargetDensePoints.length; i++) {
      final tp = allTargetDensePoints[i];
      for (final up in allUserPoints) {
        if ((tp - up).distance <= targetHitRadius) {
          coveredTarget[i] = true;
          break;
        }
      }
    }

    // Check user points precision (must be near letter path, not scribbled outside)
    for (final up in allUserPoints) {
      double minDist = double.infinity;
      for (final tp in allTargetDensePoints) {
        final d = (up - tp).distance;
        if (d < minDist) minDist = d;
      }
      if (minDist <= targetHitRadius * 1.35) {
        validUserPoints++;
      }
    }

    // Overall Coverage: fraction of target template covered by user finger
    final double coverage = coveredTarget.where((c) => c).length / allTargetDensePoints.length;

    // Precision: fraction of user points that stayed inside the letter canal
    final double precision = allUserPoints.isNotEmpty ? (validUserPoints / allUserPoints.length) : 0.0;

    // Per-stroke coverage check (user must not completely skip any stroke)
    bool allStrokesAttempted = true;
    int offsetIndex = 0;
    for (final strokePts in targetDenseStrokes) {
      if (strokePts.isEmpty) continue;
      int coveredCount = 0;
      for (int i = 0; i < strokePts.length; i++) {
        if (coveredTarget[offsetIndex + i]) coveredCount++;
      }
      final strokeCov = coveredCount / strokePts.length;
      if (strokeCov < 0.40) {
        allStrokesAttempted = false; // At least 40% of every individual stroke must be drawn!
      }
      offsetIndex += strokePts.length;
    }

    // Strict 70% Rule requested by user:
    // 1. Overall coverage >= 0.70 (70%)
    // 2. Precision >= 0.50 (must stay reasonably inside track)
    // 3. All strokes attempted (no completely missing lines)
    final int coveragePercent = (coverage * 100).round();
    final double scaledScore = (coverage * 80.0 + precision * 20.0).clamp(0.0, 100.0);
    final int finalScore = scaledScore.round();
    final bool isPass = coverage >= 0.70 && precision >= 0.50 && allStrokesAttempted;

    if (!isPass) {
      String failReason;
      if (!allStrokesAttempted) {
        failReason = 'Some parts of letter "${targetLetter.letter}" were missed! Trace along all the lines to fill it.';
      } else if (coveragePercent < 70) {
        failReason = 'Filled $coveragePercent%. At least 70% coverage is needed to pass!';
      } else {
        failReason = 'Stay inside the letter track without drawing outside!';
      }

      return HandwritingEvaluationResult(
        score: finalScore.clamp(5, 69).toDouble(),
        coverage: coverage,
        precision: precision,
        stars: 0,
        isPass: false,
        title: 'Needs More Practice! ($coveragePercent% / 70%)',
        message: failReason,
        emoji: '🔄',
        badgeColor: const Color(0xFFFF9F1C),
      );
    }

    final int stars = finalScore >= 85 ? 3 : 2;

    return HandwritingEvaluationResult(
      score: finalScore.toDouble(),
      coverage: coverage,
      precision: precision,
      stars: stars,
      isPass: true,
      title: finalScore >= 85 ? 'Awesome! Perfect! ($finalScore%)' : 'Well Done! ($finalScore%)',
      message: 'You traced letter "${targetLetter.letter}" with $finalScore% accuracy!',
      emoji: '🌟',
      badgeColor: const Color(0xFF10B981),
    );
  }
}
