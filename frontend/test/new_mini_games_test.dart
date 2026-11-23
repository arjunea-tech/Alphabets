import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tamil/models/game_content.dart';
import 'package:tamil/models/game_item_model.dart';
import 'package:tamil/services/progress_service.dart';
import 'package:tamil/screens/games/letter_whack_game.dart';
import 'package:tamil/screens/games/space_letter_game.dart';
import 'package:tamil/screens/games/letter_train_game.dart';
import 'package:tamil/widgets/bouncy_button.dart';

GameContent _content(String type, {int? level}) {
  final game = GameItem.fromJson({
    'id': 'g_$type',
    'game_type': type,
    'title': type,
    'prompt': 'Play!',
    'levels': [
      {'title': 'One', 'targets': ['A', 'B', 'C', 'D', 'E'], 'distractors': ['X', 'Y']},
      {'title': 'Two', 'targets': ['M'], 'distractors': []},
      {'title': 'Three', 'targets': ['CAT', 'DOG']},
    ],
  });
  return level == null
      ? GameContent(game: game, adminLetters: const [])
      : GameContent.forLevel(game: game, adminLetters: const [], index: level);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final level in [null, 0, 1, 2]) {
    testWidgets('whack/space/train build and tick (level $level)', (tester) async {
      tester.view.physicalSize = const Size(1800, 2560);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final p = ProgressService();
      for (final w in <Widget>[
        LetterWhackGame(progressService: p, content: _content('whack', level: level)),
        SpaceLetterGame(progressService: p, content: _content('space', level: level)),
        LetterTrainGame(progressService: p, content: _content('train', level: level)),
      ]) {
        await tester.pumpWidget(MaterialApp(home: w));
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.tapAt(const Offset(180, 600));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
    });
  }

  testWidgets('train can be won by picking answers', (tester) async {
    tester.view.physicalSize = const Size(1800, 2560);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final p = ProgressService();
    final content = _content('train', level: 0);
    await tester.pumpWidget(MaterialApp(home: LetterTrainGame(progressService: p, content: content)));
    await tester.tap(find.text("Let's Play! 🚀")); // close the question popup
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    for (var round = 0; round < GameContent.questionsPerLevel; round++) {
      // Tap every answer button (skip the back button); the right one moves the train on.
      final buttons = find.byType(BouncyButton).evaluate().skip(1).length;
      for (var i = 1; i <= buttons; i++) {
        await tester.tap(find.byType(BouncyButton).at(i), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(seconds: 3));
    }
    expect(find.text('You did it!'), findsOneWidget);
  });
}
