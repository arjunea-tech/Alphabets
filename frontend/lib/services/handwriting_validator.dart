import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/letter_stroke_model.dart';
import 'writing_engine.dart';

/// Comprehensive multi-factor validator for handwriting evaluation in Practice Mode
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
        title: 'எழுதிப் பாருங்கள்!',
        message: 'விரலால் எழுத்தின் முழு வடிவத்தையும் எழுதி சரிபார்க்கவும்.',
        emoji: '',
        badgeColor: Color(0xFFFF9F1C),
      );
    }

    final int totalUserPoints = userStrokes.fold(0, (sum, s) => sum + s.length);
    if (totalUserPoints < 6) {
      return const HandwritingEvaluationResult(
        score: 15,
        coverage: 0.1,
        precision: 0.1,
        stars: 0,
        isPass: false,
        title: 'முழுமையாக எழுதவில்லை!',
        message: 'எழுத்தின் அனைத்துக் கோடுகளையும் விரலால் எழுதிப் பார்க்கவும்.',
        emoji: '',
        badgeColor: Color(0xFFFF5964),
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
        title: 'மிகச் சரி! அற்புதம்!',
        message: '"${targetLetter.letter}" எழுத்தை அழகாக எழுதிவிட்டீர்கள்!',
        emoji: '',
        badgeColor: const Color(0xFF10B981),
      );
    }

    // 2. Factor 1: Starting Point Accuracy (Did strokes start near expected start points?)
    double startPointScore = 0.0;
    if (userStrokes.isNotEmpty && targetLetter.strokes.isNotEmpty) {
      int matchedStartCount = 0;
      for (int i = 0; i < math.min(userStrokes.length, targetLetter.strokes.length); i++) {
        final expectedStart = Offset(
          targetLetter.strokes[i].startPoint.dx * canvasSize.width,
          targetLetter.strokes[i].startPoint.dy * canvasSize.height,
        );
        final userStart = userStrokes[i].first;
        final startTolerance = targetLetter.strokes[i].tolerance * canvasSize.width * 1.6;
        if ((userStart - expectedStart).distance <= startTolerance) {
          matchedStartCount++;
        }
      }
      startPointScore = matchedStartCount / targetLetter.strokes.length;
    }

    // 3. Factor 2: Directionality Check
    double directionScore = 0.0;
    if (userStrokes.isNotEmpty && targetLetter.strokes.isNotEmpty) {
      int correctDirectionCount = 0;
      for (int i = 0; i < math.min(userStrokes.length, targetLetter.strokes.length); i++) {
        final userStroke = userStrokes[i];
        if (userStroke.length >= 2) {
          final targetStroke = targetLetter.strokes[i];
          final expectedStart = Offset(
            targetStroke.startPoint.dx * canvasSize.width,
            targetStroke.startPoint.dy * canvasSize.height,
          );
          final expectedEnd = Offset(
            targetStroke.effectiveEndPoint.dx * canvasSize.width,
            targetStroke.effectiveEndPoint.dy * canvasSize.height,
          );
          final expectedVec = expectedEnd - expectedStart;
          final userVec = userStroke.last - userStroke.first;

          if (expectedVec.distance > 10 && userVec.distance > 10) {
            final dot = (expectedVec.dx * userVec.dx + expectedVec.dy * userVec.dy) /
                (expectedVec.distance * userVec.distance);
            if (dot >= -0.2) {
              correctDirectionCount++;
            }
          } else {
            correctDirectionCount++;
          }
        } else {
          correctDirectionCount++;
        }
      }
      directionScore = correctDirectionCount / targetLetter.strokes.length;
    }

    // 4. Factor 3: Target Waypoint Coverage (How much of the template was covered)
    final double targetHitRadius = math.max(canvasSize.width * 0.08, 28.0);
    final List<bool> coveredTarget = List<bool>.filled(allTargetDensePoints.length, false);
    int validUserPoints = 0;

    for (final stroke in userStrokes) {
      for (final pt in stroke) {
        double minDist = double.infinity;
        for (int i = 0; i < allTargetDensePoints.length; i++) {
          final dist = (pt - allTargetDensePoints[i]).distance;
          if (dist < minDist) minDist = dist;
          if (dist <= targetHitRadius) {
            coveredTarget[i] = true;
          }
        }
        if (minDist <= targetHitRadius * 1.6) {
          validUserPoints++;
        }
      }
    }

    final double coverage = coveredTarget.where((c) => c).length / allTargetDensePoints.length;

    // 5. Factor 4: Precision (User points on-target vs random scribbles)
    final double precision = totalUserPoints > 0 ? (validUserPoints / totalUserPoints) : 0.0;

    // 6. Factor 5: Structural letter verification rules
    bool structuralPass = true;
    final rule = targetLetter.validationRule;

    if (rule.requireRightVerticalStem) {
      // Must have vertical line on right side
      bool hasRightStem = false;
      for (final stroke in userStrokes) {
        for (final pt in stroke) {
          final nx = pt.dx / canvasSize.width;
          final ny = pt.dy / canvasSize.height;
          if (nx >= 0.58 && nx <= 0.82 && ny >= 0.22 && ny <= 0.78) {
            hasRightStem = true;
            break;
          }
        }
      }
      if (!hasRightStem) structuralPass = false;
    }

    if (rule.requireTopLeftLoop) {
      // Must have curve/loop in top-left region
      bool hasLoop = false;
      for (final stroke in userStrokes) {
        for (final pt in stroke) {
          final nx = pt.dx / canvasSize.width;
          final ny = pt.dy / canvasSize.height;
          if (nx >= 0.20 && nx <= 0.50 && ny >= 0.22 && ny <= 0.50) {
            hasLoop = true;
            break;
          }
        }
      }
      if (!hasLoop) structuralPass = false;
    }

    if (rule.requireBottomWave) {
      bool hasBottomWave = false;
      bool hasTallStem = false;
      for (final stroke in userStrokes) {
        for (final pt in stroke) {
          final nx = pt.dx / canvasSize.width;
          final ny = pt.dy / canvasSize.height;
          if (nx >= 0.35 && nx <= 0.78 && ny >= 0.60 && ny <= 0.85) hasBottomWave = true;
          if (nx >= 0.70 && ny >= 0.20 && ny <= 0.40) hasTallStem = true;
        }
      }
      if (!hasBottomWave || hasTallStem) structuralPass = false;
    }

    // 7. Calculate overall weighted score
    final double compositeScore = (coverage * 0.45) +
        (precision * 0.25) +
        (startPointScore * 0.15) +
        (directionScore * 0.15);

    final double scaledScore = (compositeScore * 100.0).clamp(0.0, 100.0);

    // Pass threshold: require minimum coverage, precision, and structural correctness
    final bool isPass = structuralPass &&
        coverage >= (rule.minCoverage * 0.85) &&
        precision >= (rule.minPrecision * 0.80) &&
        scaledScore >= 52.0;

    if (!isPass) {
      final double failScore = scaledScore.clamp(15.0, 49.0);
      return HandwritingEvaluationResult(
        score: failScore,
        coverage: coverage,
        precision: precision,
        stars: 0,
        isPass: false,
        title: 'தவறாக உள்ளது!',
        message: 'இது "${targetLetter.letter}" எழுத்தின் சரியான வடிவம் அல்ல. கவனமாக மீண்டும் எழுதிப் பார்க்கவும்!',
        emoji: '',
        badgeColor: const Color(0xFFFF5964),
      );
    }

    final double finalPassScore = math.max(scaledScore, 65.0);
    final int stars = finalPassScore >= 85 ? 3 : (finalPassScore >= 72 ? 2 : 1);

    String successTitle = 'மிகச் சரி! அற்புதம்!';
    String successMsg = '"${targetLetter.letter}" எழுத்தை மிகச் சரியாக எழுதிவிட்டீர்கள்!';

    if (stars == 2) {
      successTitle = 'நன்று! சிறப்பு!';
      successMsg = '"${targetLetter.letter}" எழுத்தை நன்றாக எழுதியுள்ளீர்கள்!';
    } else if (stars == 1) {
      successTitle = 'வெற்றி! பரவாயில்லை!';
      successMsg = 'சரியாக எழுதியுள்ளீர்கள், மேலும் பயிற்சி செய்து 3 நட்சத்திரங்கள் பெறுங்கள்!';
    }

    return HandwritingEvaluationResult(
      score: finalPassScore,
      coverage: coverage,
      precision: precision,
      stars: stars,
      isPass: true,
      title: successTitle,
      message: successMsg,
      emoji: '',
      badgeColor: const Color(0xFF10B981),
    );
  }
}
