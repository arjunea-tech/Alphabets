import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamil/data/tamil_letter_outlines.dart';
import 'package:tamil/data/tamil_stroke_data.dart';
import 'package:tamil/data/writing_data.dart';
import 'package:tamil/models/letter_stroke_model.dart';
import 'package:tamil/services/writing_boundary_validator.dart';
import 'package:tamil/services/writing_engine.dart';

void main() {
  const size = Size(360, 420);

  List<Offset> trace(LetterStrokeData s) => WritingEngine.sampleDensePoints(s, size);

  void testLetter(String letter, int expectedStrokes) {
    final letterData = TamilStrokeDataRepository.getLetter(letter);
    expect(letterData.strokes.length, expectedStrokes,
        reason: '$letter should have $expectedStrokes strokes');

    final outline = TamilLetterOutlines.pathFor(letter, WritingEngine.guideRect(size));
    expect(outline, isNotNull, reason: 'missing outline for $letter');

    for (final s in letterData.strokes) {
      for (final p in [s.startPoint, s.effectiveEndPoint]) {
        final canvasPt = WritingEngine.toCanvas(p, size);
        final inOutline = outline!.contains(canvasPt);
        expect(inOutline, isTrue,
            reason: '$letter stroke ${s.strokeNumber} ($p -> $canvasPt) is outside outline');
      }

      final forwardAttempt = WritingBoundaryValidator.checkStrokeAttempt(
        userPoints: trace(s),
        stroke: s,
        size: size,
      );
      expect(forwardAttempt.status, StrokeAttemptStatus.correct,
          reason: '$letter stroke ${s.strokeNumber} forward trace failed');

      if (!s.isDot && (s.startPoint - s.effectiveEndPoint).distance > 0.15) {
        final reversedAttempt = WritingBoundaryValidator.checkStrokeAttempt(
          userPoints: trace(s).reversed.toList(),
          stroke: s,
          size: size,
        );
        expect(reversedAttempt.isCorrect, isFalse,
            reason: '$letter stroke ${s.strokeNumber} reversed trace was accepted');
      }
    }
  }

  test('validate TamilStrokeDataRepository for ண் (9), ன் (6), ழ் (5)', () {
    testLetter('ண்', 9);
    testLetter('ன்', 6);
    testLetter('ழ்', 5);
  });

  test('validate WritingData meiGuides for ண் (9), ன் (6), ழ் (5)', () {
    final expected = {
      'ண்': 9,
      'ன்': 6,
      'ழ்': 5,
    };
    for (final entry in expected.entries) {
      final guide = WritingData.meiGuides.firstWhere((g) => g.letter == entry.key);
      expect(guide.strokeCount, entry.value);
      expect(guide.strokeHints.length, entry.value);
      expect(guide.startingPoints.length, entry.value);
    }
  });
}
