import 'dart:ui';
import 'package:flutter/material.dart';
import '../data/tamil_stroke_data.dart';
import '../models/letter_stroke_model.dart';
import 'writing_engine.dart';

export '../models/letter_stroke_model.dart';

/// Adapter preserving backwards compatibility for LetterStrokeEvaluator
class LetterWritingStep {
  final int stepNumber;
  final String title;
  final String instruction;
  final List<Offset> points;

  const LetterWritingStep({
    required this.stepNumber,
    required this.title,
    required this.instruction,
    required this.points,
  });
}

class LetterStrokeEvaluator {
  static List<LetterWritingStep> getStepsForLetter(String letter) {
    final tLetter = TamilStrokeDataRepository.getLetter(letter);
    return tLetter.strokes.map((s) {
      return LetterWritingStep(
        stepNumber: s.strokeNumber,
        title: s.title,
        instruction: s.instruction,
        points: s.pathPoints,
      );
    }).toList();
  }

  static Path generateSmoothSplinePath(List<Offset> pts, Size size) {
    return WritingEngine.generateSmoothSplinePath(pts, size);
  }

  static HandwritingEvaluationResult evaluate({
    required String letter,
    required List<List<Offset>> strokes,
    required Size canvasSize,
    double hitRadius = 30.0,
  }) {
    final tLetter = TamilStrokeDataRepository.getLetter(letter);
    return WritingEngine.evaluatePractice(
      targetLetter: tLetter,
      userStrokes: strokes,
      canvasSize: canvasSize,
    );
  }

  static bool isPointNearStroke({
    required Offset point,
    required String letter,
    required Size canvasSize,
    double tolerance = 44.0,
  }) {
    final tLetter = TamilStrokeDataRepository.getLetter(letter);
    for (final s in tLetter.strokes) {
      if (WritingEngine.isPointInsideStrokeBoundary(
        point: point,
        stroke: s,
        size: canvasSize,
      )) {
        return true;
      }
    }
    return false;
  }
}
