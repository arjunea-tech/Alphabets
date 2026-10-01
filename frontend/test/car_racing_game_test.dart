import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tamil/models/car_racing_game_model.dart';
import 'package:tamil/screens/games/car_racing_game.dart';
import 'package:tamil/services/progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('CarRacingGame controls, lane steering, and 10-round progression test', (WidgetTester tester) async {
    final progressService = ProgressService();

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;

    await tester.pumpWidget(
      MaterialApp(
        home: CarRacingGame(
          progressService: progressService,
          mode: RacingGameMode.uyir,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    // Verify Title and initial HUD
    expect(find.text('உயிர் எழுத்து கார் பந்தயம்'), findsOneWidget);
    expect(find.text('0'), findsOneWidget); // Score is 0
    expect(find.text('1/10'), findsOneWidget);
    expect(find.text('ஒலியைக் கேட்டு காரை ஓட்டுங்கள்! 🚗'), findsOneWidget);

    final gameState = tester.state(find.byType(CarRacingGame)) as CarRacingGameState;

    // 1. Verify Lane Steering Controls
    expect(gameState.currentLane, equals(1)); // Initial center lane
    gameState.moveCarLeft();
    expect(gameState.currentLane, equals(0)); // Steered left
    gameState.moveCarLeft();
    expect(gameState.currentLane, equals(0)); // Boundary check (cannot go below 0)

    gameState.moveCarRight();
    expect(gameState.currentLane, equals(1)); // Center
    gameState.moveCarRight();
    expect(gameState.currentLane, equals(2)); // Steered right
    gameState.moveCarRight();
    expect(gameState.currentLane, equals(2)); // Boundary check (cannot go above 2)

    // 2. Target and Wave Validation
    final initialTarget = gameState.currentTarget.text;
    expect(initialTarget.isNotEmpty, isTrue);

    final waveTexts = gameState.roadItems.map((i) => i.text).toList();
    expect(waveTexts.contains(initialTarget), isTrue,
        reason: 'Target word must be guaranteed to appear on the road');
    expect(waveTexts.toSet().length, equals(waveTexts.length),
        reason: 'Items on road must be distinct without duplicates');

    // 3. Test Wrong Item Collection (Game must NOT freeze, target must stay active)
    final wrongItem = gameState.roadItems.firstWhere((i) => !i.isTarget);
    gameState.handleWrongCollection(wrongItem);
    await tester.pump(const Duration(milliseconds: 100));

    expect(gameState.score, equals(0));
    expect(gameState.currentTarget.text, equals(initialTarget));
    expect(gameState.isGameCompleted, isFalse);

    // 4. Simulate 10 Consecutive Rounds
    for (int round = 0; round < 10; round++) {
      final currentTargetText = gameState.currentTarget.text;
      final targetObj = gameState.roadItems.firstWhere((i) => i.isTarget);

      expect(targetObj.text, equals(currentTargetText));

      final preScore = gameState.score;
      gameState.handleCorrectCollection(targetObj, 200.0, 500.0);

      // Score increases by 10
      expect(gameState.score, equals(preScore + 10));

      // Pump through round transition delay
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 100));

      if (round < 9) {
        // Next round started automatically
        final nextTargetText = gameState.currentTarget.text;
        expect(nextTargetText.isNotEmpty, isTrue);

        final nextWaveTexts = gameState.roadItems.map((i) => i.text).toList();
        expect(nextWaveTexts.contains(nextTargetText), isTrue,
            reason: 'Target must appear on road in round ${round + 2}');
      }
    }

    // 5. Celebration Result Screen Verification
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(gameState.isGameCompleted, isTrue);
    expect(find.text('பந்தயம் முடிந்தது! 🎉'), findsOneWidget);
    expect(find.text('மீண்டும் விளையாடு 🚀'), findsOneWidget);
    expect(find.text('விளையாட்டுகளுக்கு செல்'), findsOneWidget);
    expect(gameState.score, equals(100)); // 10 rounds * 10 = 100
  });

  testWidgets('CarRacingGame Letter Mode (உயிர் எழுத்துகள்) test', (WidgetTester tester) async {
    final progressService = ProgressService();

    await tester.pumpWidget(
      MaterialApp(
        home: CarRacingGame(
          progressService: progressService,
          mode: RacingGameMode.uyir,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    final gameState = tester.state(find.byType(CarRacingGame)) as CarRacingGameState;
    expect(gameState.currentTarget.isWord, isFalse);
    expect(gameState.currentTarget.text.length, equals(1)); // Single letter
  });
}
