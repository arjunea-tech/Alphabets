import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tamil/data/story_data.dart';
import 'package:tamil/models/story_model.dart';
import 'package:tamil/screens/reading/reading_screen.dart';
import 'package:tamil/services/progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Reading Story Models and Data Tests', () {
    test('hareAndTortoiseStory structure and 6 simplified pages verification', () {
      expect(hareAndTortoiseStory.id, 'story_tortoise_rabbit');
      expect(hareAndTortoiseStory.title, 'முயலும் ஆமையும்');
      expect(hareAndTortoiseStory.pages.length, 6);

      // Verify Page 1 has exactly 3 interactive words, and Pages 2-6 are clean plain text
      for (int i = 0; i < hareAndTortoiseStory.pages.length; i++) {
        final page = hareAndTortoiseStory.pages[i];
        expect(page.text.isNotEmpty, isTrue);
        expect(page.text.length < 100, isTrue); // Very short Tamil sentence
        expect(page.characterName.isNotEmpty, isTrue);
        if (i == 0) {
          expect(page.interactiveWords.length, 3);
        } else {
          expect(page.interactiveWords.isEmpty, isTrue);
        }
      }

      // Page 1 specific verification
      final page1 = hareAndTortoiseStory.pages[0];
      expect(page1.text, 'ஒரு காட்டில் முயலும் ஆமையும் வாழ்ந்தன.');
      expect(page1.characterName, 'காடு');
      final labels1 = page1.interactiveWords.map((w) => w.displayLabel).toList();
      expect(labels1.contains('காடு'), isTrue);
      expect(labels1.contains('முயல்'), isTrue);
      expect(labels1.contains('ஆமை'), isTrue);

      // Page 2 specific verification
      final page2 = hareAndTortoiseStory.pages[1];
      expect(page2.text, contains('முயல் வேகமாக ஓடும்.'));
      expect(page2.text, contains('ஆமை மெதுவாக நடக்கும்.'));

      // Page 6 moral page
      final page6 = hareAndTortoiseStory.pages[5];
      expect(page6.text, contains('விடாமுயற்சி வெற்றி தரும்!'));
      expect(page6.interactiveWords.isEmpty, isTrue);
    });

    test('StoryModel and StoryPageModel JSON serialization and deserialization', () {
      final json = hareAndTortoiseStory.toJson();
      final restored = StoryModel.fromJson(json);

      expect(restored.id, hareAndTortoiseStory.id);
      expect(restored.title, hareAndTortoiseStory.title);
      expect(restored.pages.length, 6);
      expect(restored.pages.first.interactiveWords.length, 3);
      expect(restored.pages.first.interactiveWords.first.displayLabel, 'காடு');
    });

    test('StoryInteractiveWord JSON parsing with various key styles', () {
      final word1 = StoryInteractiveWord.fromJson({
        'word': 'காடு',
        'display_label': 'காடு',
        'image_path': 'assets/images/story_forest.jpg',
        'emoji': '🌲',
        'meaning': 'Forest',
      });
      expect(word1.displayLabel, 'காடு');
      expect(word1.imagePath, 'assets/images/story_forest.jpg');
      expect(word1.emoji, '🌲');
    });
  });

  group('ReadingScreen Widget and Navigation Tests', () {
    testWidgets('ReadingScreen renders Page 1, interactive words, and navigation controls', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final progressService = ProgressService();

      await tester.pumpWidget(
        MaterialApp(
          home: ReadingScreen(progressService: progressService),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Verify title & mascot header
      expect(find.text('முயலும் ஆமையும்'), findsWidgets);
      expect(find.text('முயலும் ஆமையும் கதையை வாசிப்போம்!'), findsOneWidget);

      // Verify Page 1 indicator & character tag
      expect(find.text('பக்கம் 1 / 6'), findsOneWidget);
      expect(find.text('காடு'), findsWidgets);

      // Verify Page 1 words
      expect(find.text('ஒரு'), findsOneWidget);
      expect(find.text('காட்டில்'), findsOneWidget);
      expect(find.text('முயலும்'), findsOneWidget);
      expect(find.text('ஆமையும்'), findsOneWidget);

      // Next button exists
      expect(find.text('அடுத்தது'), findsOneWidget);
      // Previous button should not be shown on page 1
      expect(find.text('முந்தையது'), findsNothing);
    });

    testWidgets('Tapping interactive word "காடு" / "காட்டில்" opens image modal and closes smoothly', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final progressService = ProgressService();

      await tester.pumpWidget(
        MaterialApp(
          home: ReadingScreen(progressService: progressService),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Tap the interactive word 'காட்டில்'
      await tester.tap(find.text('காட்டில்'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Dialog is open
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('அழகான காடு (Forest)'), findsOneWidget);
      expect(find.text('ஒலிப்பைக் கேட்க'), findsOneWidget);
      expect(find.text('கதைக்குத் திரும்பு'), findsOneWidget);

      // Tap close button
      await tester.tap(find.text('கதைக்குத் திரும்பு'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Dialog is closed
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('Tapping "முயல்" and "ஆமை" interactive items opens corresponding modal', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final progressService = ProgressService();

      await tester.pumpWidget(
        MaterialApp(
          home: ReadingScreen(progressService: progressService),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Tap 'முயலும்'
      await tester.tap(find.text('முயலும்'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('சுட்டி முயல் (Rabbit)'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('கதைக்குத் திரும்பு'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(Dialog), findsNothing);

      // Tap 'ஆமையும்'
      await tester.tap(find.text('ஆமையும்'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('அன்பான ஆமை (Tortoise)'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('கதைக்குத் திரும்பு'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('Full story navigation across all 6 pages and completion celebration', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final progressService = ProgressService();

      await tester.pumpWidget(
        MaterialApp(
          home: ReadingScreen(progressService: progressService),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Page 1 -> Page 2
      expect(find.text('பக்கம் 1 / 6'), findsOneWidget);
      await tester.ensureVisible(find.text('அடுத்தது'));
      await tester.tap(find.text('அடுத்தது'));
      await tester.pump(const Duration(milliseconds: 400));

      // Page 2
      expect(find.text('பக்கம் 2 / 6'), findsOneWidget);
      expect(find.text('முந்தையது'), findsOneWidget);

      // Page 2 -> Page 3
      await tester.ensureVisible(find.text('அடுத்தது'));
      await tester.tap(find.text('அடுத்தது'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('பக்கம் 3 / 6'), findsOneWidget);

      // Page 3 -> Page 4
      await tester.ensureVisible(find.text('அடுத்தது'));
      await tester.tap(find.text('அடுத்தது'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('பக்கம் 4 / 6'), findsOneWidget);

      // Page 4 -> Page 5
      await tester.ensureVisible(find.text('அடுத்தது'));
      await tester.tap(find.text('அடுத்தது'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('பக்கம் 5 / 6'), findsOneWidget);

      // Page 5 -> Page 6
      await tester.ensureVisible(find.text('அடுத்தது'));
      await tester.tap(find.text('அடுத்தது'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('பக்கம் 6 / 6'), findsOneWidget);

      // On last page, button is "முடித்தேன்"
      expect(find.text('முடித்தேன்'), findsOneWidget);

      // Tap Finish button
      await tester.ensureVisible(find.text('முடித்தேன்'));
      await tester.tap(find.text('முடித்தேன்'));
      await tester.pump(const Duration(milliseconds: 400));

      // Celebration Dialog appears with moral and 5 stars reward
      expect(find.text('கதை முடிந்தது!'), findsOneWidget);
      expect(find.text('முகப்புக்குச் செல்'), findsOneWidget);
      expect(progressService.stars, greaterThanOrEqualTo(5));
    });
  });
}
