import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tamil/screens/games/letter_matching_game.dart';
import 'package:tamil/services/progress_service.dart';

const _flipAndLevelEnd = Duration(milliseconds: 700);

Finder _card(String label) => find.byKey(ValueKey('match_card_$label'));

List<String> _lettersOnBoard() {
  final alphabet = List.generate(26, (i) => String.fromCharCode(65 + i));
  return alphabet.where((l) => _card(l).evaluate().isNotEmpty).toList();
}

Future<void> _matchAllPairs(WidgetTester tester) async {
  for (final letter in _lettersOnBoard()) {
    await tester.tap(_card(letter));
    await tester.pump();
    await tester.tap(_card(letter.toLowerCase()));
    await tester.pump();
  }
  await tester.pump(_flipAndLevelEnd);
  await tester.pump(_flipAndLevelEnd);
}

Future<ProgressService> _pumpGame(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);

  final progressService = ProgressService();
  await tester.pumpWidget(
    MaterialApp(home: LetterMatchingGame(progressService: progressService)),
  );
  await tester.pump();
  return progressService;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('a wrong pair flips back and earns no match', (tester) async {
    await _pumpGame(tester);

    final letters = _lettersOnBoard();
    await tester.tap(_card(letters[0]));
    await tester.pump();
    await tester.tap(_card(letters[1].toLowerCase()));
    await tester.pump();
    expect(find.text('Moves: 1'), findsOneWidget);

    // The board stays locked until the mismatched cards have flipped back.
    await tester.tap(_card(letters[2]));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Moves: 1'), findsOneWidget);
    await tester.pump(_flipAndLevelEnd);
    expect(find.textContaining('complete'), findsNothing);
  });

  testWidgets('every level is playable and winning awards stars once', (tester) async {
    final progressService = await _pumpGame(tester);
    final startingStars = progressService.stars;

    for (var level = 0; level < letterMatchingLevelPairs.length; level++) {
      expect(_lettersOnBoard(), hasLength(letterMatchingLevelPairs[level]));
      await _matchAllPairs(tester);

      if (level < letterMatchingLevelPairs.length - 1) {
        expect(find.text('Level ${level + 1} complete!'), findsOneWidget);
        await tester.tap(find.text('Next Level'));
        await tester.pump();
      }
    }

    expect(find.text('You matched them all!'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(progressService.stars, startingStars + letterMatchingStarsReward);
    expect(progressService.progress.gamesPlayed, 1);
  });
}
