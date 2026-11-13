import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamil/data/tamil_stroke_data.dart';
import 'package:tamil/services/handwriting_validator.dart';
import 'package:tamil/services/writing_engine.dart';
import 'package:tamil/data/english_stroke_data.dart';
import 'package:tamil/data/english_small_stroke_data.dart';

/// Simulates a child tracing exactly along the given strokes of [letter].
List<List<Offset>> _trace(String letter, Size size, {List<int>? only, double fraction = 1.0}) {
  final data = TamilStrokeDataRepository.getLetter(letter);
  final strokes = <List<Offset>>[];
  for (int i = 0; i < data.strokes.length; i++) {
    if (only != null && !only.contains(i)) continue;
    final pts = WritingEngine.sampleDensePoints(data.strokes[i], size, step: 3.0);
    strokes.add(pts.sublist(0, (pts.length * fraction).round().clamp(1, pts.length)));
  }
  return strokes;
}

void main() {
  const size = Size(320, 300);
  _allLettersPassWhenFullyTraced();

  test('A traced fully passes above 85%', () {
    final r = HandwritingValidator.evaluate(
      targetLetter: TamilStrokeDataRepository.getLetter('A'),
      userStrokes: _trace('A', size),
      canvasSize: size,
    );
    expect(r.isPass, isTrue);
    expect(r.score, greaterThan(HandwritingValidator.passPercent));
  });

  test('A with only the two diagonals (no crossbar) does NOT pass', () {
    final data = TamilStrokeDataRepository.getLetter('A');
    expect(data.strokes.length, 3);
    final r = HandwritingValidator.evaluate(
      targetLetter: data,
      userStrokes: _trace('A', size, only: [0, 1]),
      canvasSize: size,
    );
    expect(r.isPass, isFalse);
    expect(r.score, lessThanOrEqualTo(HandwritingValidator.passPercent));
  });

  test('C traced halfway shows about half, not a passing score', () {
    final r = HandwritingValidator.evaluate(
      targetLetter: TamilStrokeDataRepository.getLetter('C'),
      userStrokes: _trace('C', size, fraction: 0.5),
      canvasSize: size,
    );
    expect(r.isPass, isFalse);
    expect(r.score, lessThan(70));
  });
}

void _allLettersPassWhenFullyTraced() {
  const size = Size(320, 300);
  final letters = <String, dynamic>{
    ...EnglishStrokeData.letters,
    ...EnglishSmallLettersStrokeData.letters,
  };
  for (final entry in letters.entries) {
    test('"${entry.key}" traced fully passes', () {
      final r = HandwritingValidator.evaluate(
        targetLetter: entry.value,
        userStrokes: _trace(entry.key, size),
        canvasSize: size,
      );
      expect(r.isPass, isTrue, reason: '${entry.key}: score ${r.score}, ${r.message}');
    });
  }
}
