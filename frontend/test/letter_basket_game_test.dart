import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tamil/models/letter_basket_game_model.dart';
import 'package:tamil/screens/games/letter_basket_game.dart';
import 'package:tamil/services/progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('LetterBasketGame initialization and round progression test (10 rounds)', (WidgetTester tester) async {
    final progressService = ProgressService();

    // Pump the Letter Basket Game inside a fixed phone screen resolution
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;

    await tester.pumpWidget(
      MaterialApp(
        home: LetterBasketGame(
          progressService: progressService,
          mode: BasketGameMode.uyir,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    // Verify Title and initial HUD
    expect(find.text('எழுத்துக் கூடை'), findsOneWidget);
    expect(find.text('0'), findsOneWidget); // Initial score is 0

    // Get the state of the game
    final gameState = tester.state(find.byType(LetterBasketGame)) as dynamic;

    final initialTarget = gameState.currentTarget.letter as String;
    expect(initialTarget.isNotEmpty, isTrue);

    // Verify that falling letters wave contains the target letter and distinct letters
    final initialLetters = (gameState.fallingLetters as List<dynamic>)
        .map((l) => l.letter as String)
        .toList();

    expect(initialLetters.contains(initialTarget), isTrue,
        reason: 'Target letter must appear among falling letters');

    // Verify all letters in the wave are unique
    expect(initialLetters.toSet().length, equals(initialLetters.length),
        reason: 'All letters in the wave must be distinct');

    // Test wrong letter catch: should not freeze the game, target remains same
    final wrongLetter = gameState.fallingLetters
        .firstWhere((l) => !(l.isTarget as bool));

    gameState.handleWrongCatch(wrongLetter, 200.0, 500.0);
    await tester.pump(const Duration(milliseconds: 100));

    expect(gameState.score, equals(0));
    expect(gameState.currentTarget.letter, equals(initialTarget));
    expect(gameState.isGameOver, isFalse);

    // Simulate 10 consecutive rounds catching the correct target letter
    for (int round = 0; round < 10; round++) {
      final currentTargetLetter = gameState.currentTarget.letter as String;
      final targetObj = gameState.fallingLetters.firstWhere((l) => l.isTarget as bool);

      // Verify the target object is valid
      expect(targetObj.letter, equals(currentTargetLetter));

      // Catch the correct target
      final preScore = gameState.score as int;
      gameState.handleCorrectCatch(targetObj, 200.0, 500.0);

      // Verify score incremented by 10 once
      expect(gameState.score, equals(preScore + 10));

      // Pump through the 650ms round transition
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 100));

      if (round < 9) {
        // Next round should have started automatically
        final nextTargetLetter = gameState.currentTarget.letter as String;
        expect(nextTargetLetter.isNotEmpty, isTrue);

        final nextWaveLetters = (gameState.fallingLetters as List<dynamic>)
            .map((l) => l.letter as String)
            .toList();

        // Target must appear in next wave
        expect(nextWaveLetters.contains(nextTargetLetter), isTrue,
            reason: 'Target must appear in wave for round ${round + 2}');

        // Letters in next wave must be unique
        expect(nextWaveLetters.toSet().length, equals(nextWaveLetters.length),
            reason: 'All letters in wave for round ${round + 2} must be distinct');
      }
    }

    // After 10 rounds, game must be completed
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(gameState.isGameCompleted, isTrue);
    expect(find.text('வாழ்த்துகள்! 🎉'), findsOneWidget);
    expect(find.text('மீண்டும் விளையாடு 🚀'), findsOneWidget);
    expect(gameState.score, equals(100)); // 10 rounds * 10 points = 100
  });
}
