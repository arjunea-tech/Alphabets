import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamil/data/tamil_letter_outlines.dart';
import 'package:tamil/data/tamil_stroke_data.dart';
import 'package:tamil/models/letter_stroke_model.dart';
import 'package:tamil/services/writing_boundary_validator.dart';
import 'package:tamil/services/writing_engine.dart';
import 'package:tamil/widgets/writing_canvas.dart';

void main() {
  const size = Size(360, 420); // non-square on purpose: guide square must still line up
  final letters = TamilStrokeDataRepository.getAllVerifiedLetters();

  /// Canvas points along a stroke, as a child tracing it exactly would produce.
  List<Offset> trace(LetterStrokeData s) => WritingEngine.sampleDensePoints(s, size);

  test('every guide letter has an outline and every start/end point lies inside it', () {
    expect(letters.length, 35);
    for (final l in letters) {
      final outline = TamilLetterOutlines.pathFor(l, WritingEngine.guideRect(size));
      expect(outline, isNotNull, reason: 'missing outline for $l');
      for (final s in TamilStrokeDataRepository.getLetter(l).strokes) {
        for (final p in [s.startPoint, s.effectiveEndPoint]) {
          expect(outline!.contains(WritingEngine.toCanvas(p, size)), isTrue,
              reason: '$l stroke ${s.strokeNumber}: $p is outside the letter');
        }
      }
    }
  });

  test('tracing each stroke correctly is accepted', () {
    for (final l in letters) {
      for (final s in TamilStrokeDataRepository.getLetter(l).strokes) {
        final r = WritingBoundaryValidator.checkStrokeAttempt(userPoints: trace(s), stroke: s, size: size);
        expect(r.status, StrokeAttemptStatus.correct, reason: '$l stroke ${s.strokeNumber}');
      }
    }
  });

  test('tracing an open stroke backwards is rejected', () {
    for (final l in letters) {
      for (final s in TamilStrokeDataRepository.getLetter(l).strokes) {
        if (s.isDot || (s.startPoint - s.effectiveEndPoint).distance < 0.15) continue;
        final r = WritingBoundaryValidator.checkStrokeAttempt(
            userPoints: trace(s).reversed.toList(), stroke: s, size: size);
        expect(r.isCorrect, isFalse, reason: '$l stroke ${s.strokeNumber} reversed');
      }
    }
  });

  test('stopping halfway, starting elsewhere, or tracing the wrong stroke is rejected', () {
    final ka = TamilStrokeDataRepository.getLetter('க்').strokes;
    final first = trace(ka[0]);

    final half = WritingBoundaryValidator.checkStrokeAttempt(
        userPoints: first.sublist(0, first.length ~/ 2), stroke: ka[0], size: size);
    expect(half.status, StrokeAttemptStatus.incomplete);

    final late = WritingBoundaryValidator.checkStrokeAttempt(
        userPoints: first.sublist(first.length ~/ 3), stroke: ka[0], size: size);
    expect(late.status, StrokeAttemptStatus.wrongStart);

    final other = WritingBoundaryValidator.checkStrokeAttempt(userPoints: trace(ka[2]), stroke: ka[0], size: size);
    expect(other.isCorrect, isFalse);

    final pulli = ka.last;
    expect(pulli.isDot, isTrue);
    final tap = WritingEngine.toCanvas(pulli.startPoint, size);
    expect(
      WritingBoundaryValidator.checkStrokeAttempt(userPoints: [tap, tap + const Offset(0.5, 0.5)], stroke: pulli, size: size)
          .isCorrect,
      isTrue,
    );
    final miss = WritingEngine.toCanvas(const Offset(0.5, 0.9), size);
    expect(
      WritingBoundaryValidator.checkStrokeAttempt(userPoints: [miss, miss], stroke: pulli, size: size).status,
      StrokeAttemptStatus.missedDot,
    );
  });

  test('pulli (dot) is always the last stroke of a mei letter', () {
    for (final l in letters.where((l) => l.endsWith('்'))) {
      final strokes = TamilStrokeDataRepository.getLetter(l).strokes;
      expect(strokes.last.isDot, isTrue, reason: l);
      expect(strokes.where((s) => s.isDot).length, 1, reason: l);
    }
  });

  test('jumping from start to end while skipping star checkpoints is rejected', () {
    final aa = TamilStrokeDataRepository.getLetter('ஆ').strokes[0];
    final startPt = WritingEngine.toCanvas(aa.startPoint, size);
    final endPt = WritingEngine.toCanvas(aa.effectiveEndPoint, size);

    // Simulate touching start, then directly jumping to end without visiting star checkpoints
    final shortcutAttempt = [
      startPt,
      startPt + const Offset(1, 1),
      startPt + const Offset(2, 2),
      endPt - const Offset(2, 2),
      endPt - const Offset(1, 1),
      endPt,
    ];

    final result = WritingBoundaryValidator.checkStrokeAttempt(
      userPoints: shortcutAttempt,
      stroke: aa,
      size: size,
    );
    expect(result.isCorrect, isFalse, reason: 'Shortcutting directly to end must be rejected');
    expect(
      result.status == StrokeAttemptStatus.skippedCheckpoints ||
          result.status == StrokeAttemptStatus.incomplete,
      isTrue,
    );
  });

  testWidgets('WritingCanvas in Learn mode strictly blocks drawing on future steps', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: WritingCanvas(
              letter: 'ஆ',
              mode: WritingCanvasMode.learn,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    final state = tester.state<WritingCanvasState>(find.byType(WritingCanvas));
    expect(state.activeStepIndex, 0);

    final letterData = TamilStrokeDataRepository.getLetter('ஆ');
    // Step 2 is the vertical stem: starts at Offset(0.705, 0.262)
    final step2Point = WritingEngine.toCanvas(letterData.strokes[1].startPoint, const Size(400, 400));
    // Step 3 is the loop curl: starts at Offset(0.710, 0.560)
    final step3Point = WritingEngine.toCanvas(letterData.strokes[2].pathPoints[10], const Size(400, 400));

    // Tap on Step 2 while on Step 1
    final gesture = await tester.startGesture(step2Point);
    await tester.pump();
    expect(state.strokeCount, 0, reason: 'Touching Step 2 during Step 1 must be blocked');

    // Drag inside Step 2
    await gesture.moveTo(step2Point + const Offset(0, 30));
    await tester.pump();
    expect(state.strokeCount, 0, reason: 'Dragging on Step 2 during Step 1 must be blocked');
    await gesture.up();
    await tester.pump();
    expect(state.strokeCount, 0, reason: 'Step 2 must not have any registered strokes');

    // Tap on Step 3 while on Step 1
    final gesture3 = await tester.startGesture(step3Point);
    await tester.pump();
    expect(state.strokeCount, 0, reason: 'Touching Step 3 during Step 1 must be blocked');
    await gesture3.moveTo(step3Point + const Offset(10, 10));
    await tester.pump();
    expect(state.strokeCount, 0, reason: 'Dragging on Step 3 during Step 1 must be blocked');
    await gesture3.up();
    await tester.pump();
    expect(state.strokeCount, 0, reason: 'Step 3 must not have any registered strokes');
  });
}
