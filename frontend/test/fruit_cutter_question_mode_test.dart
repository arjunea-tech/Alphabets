import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tamil/models/game_content.dart';
import 'package:tamil/models/game_item_model.dart';
import 'package:tamil/screens/games/fruit_cutter_game.dart';
import 'package:tamil/services/progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Word Ninja level shows the question, target letters and 0/5 progress', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    const game = GameItem(
      id: 'ninja1',
      gameType: 'ninja',
      title: 'Word Ninja',
      prompt: 'Slice!',
      levels: [
        GameLevel(title: 'VOWEL LETTERS', prompt: 'Slice only VOWEL letters!', targets: ['A', 'E', 'I', 'O', 'U']),
        GameLevel(title: 'A to G', prompt: 'Slice A to G', targets: ['A', 'B', 'C']),
        GameLevel(title: 'Words', prompt: 'Slice animals', targets: ['CAT']),
      ],
    );
    final content = GameContent.forLevel(game: game, adminLetters: const [], index: 0);

    await tester.pumpWidget(MaterialApp(
      home: FruitCutterGame(progressService: ProgressService(), content: content),
    ));
    // The question popup shows first; close it to start the game.
    expect(find.text("Let's Play! 🚀"), findsOneWidget);
    await tester.tap(find.text("Let's Play! 🚀"));
    await tester.pump();
    // Let fruits spawn and fly for a few seconds.
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 33));
    }

    expect(find.text('Slice only VOWEL letters!'), findsOneWidget);
    for (final v in ['A', 'E', 'I', 'O', 'U']) {
      expect(find.text(v), findsWidgets);
    }
    expect(find.text('Level 1 · 0/5'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Leave the game so its ticker stops.
    await tester.pumpWidget(const SizedBox());
  });
}
