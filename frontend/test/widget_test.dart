import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamil/data/writing_data.dart';
import 'package:tamil/main.dart';
import 'package:tamil/models/letter_model.dart';
import 'package:tamil/models/writing_practice_model.dart';
import 'package:tamil/models/user_profile_model.dart';
import 'package:tamil/screens/settings/settings_screen.dart';
import 'package:tamil/services/progress_service.dart';
import 'package:tamil/screens/writing/writing_history_screen.dart';
import 'package:tamil/screens/writing/writing_practice_screen.dart';
import 'package:tamil/services/audio_service.dart';
import 'package:tamil/services/tamil_tts_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tamil/widgets/letter_card.dart';

import 'package:tamil/screens/main_navigation_screen.dart';
import 'package:tamil/screens/auth/login_screen.dart';
import 'package:tamil/services/auth_service.dart';

void main() {
  testWidgets('Agaram App smoke test and main navigation verification', (WidgetTester tester) async {
    final progressService = ProgressService();

    // Build Agaram app
    await tester.pumpWidget(AgaramApp(
      progressService: progressService,
      initialScreen: MainNavigationScreen(progressService: progressService),
    ));
    await tester.pump();

    // Verify app brand and exact navigation labels
    expect(find.text('அகரம்'), findsWidgets);
    expect(find.text('முகப்பு'), findsWidgets);
    expect(find.text('கற்றுக்கொள்வோம்'), findsWidgets);
    expect(find.text('விளையாடிக் கற்போம்'), findsWidgets);
    expect(find.text('காணொளிகள்'), findsWidgets);
    expect(find.text('வினாடி வினா'), findsWidgets);

    // Verify "எழுதிப் பழகு" card is present on the Home Page
    expect(find.text('எழுதிப் பழகு'), findsOneWidget);
  });

  testWidgets('LoginScreen and RegisterScreen pure Tamil UI test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final authService = AuthService();
    final progressService = ProgressService();

    await tester.pumpWidget(MaterialApp(
      home: LoginScreen(authService: authService, progressService: progressService),
    ));
    await tester.pump();

    expect(find.text('உள்நுழையவும்'), findsWidgets);
    expect(find.text('மின்னஞ்சல்'), findsOneWidget);
    expect(find.text('கடவுச்சொல்'), findsOneWidget);
    expect(find.textContaining('பதிவு செய்யவும்'), findsOneWidget);

    // Scroll and tap register link
    await tester.ensureVisible(find.textContaining('பதிவு செய்யவும்'));
    await tester.tap(find.textContaining('பதிவு செய்யவும்'));
    await tester.pumpAndSettle();

    expect(find.text('புதிய கணக்கு தொடங்குங்கள்'), findsOneWidget);
    expect(find.text('பெயர்'), findsOneWidget);
    expect(find.text('கடவுச்சொல்லை உறுதிப்படுத்தவும்'), findsOneWidget);
  });

  testWidgets('WritingPracticeScreen interactive controls and pure Tamil UI', (WidgetTester tester) async {
    final progressService = ProgressService();

    await tester.pumpWidget(
      MaterialApp(
        home: WritingPracticeScreen(
          progressService: progressService,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Verify WritingPracticeScreen loaded with pure Tamil labels
    expect(find.byType(WritingPracticeScreen), findsOneWidget);
    expect(find.text('உயிர் (12)'), findsOneWidget);
    expect(find.text('மெய் (18)'), findsOneWidget);
    expect(find.text('மீண்டும் எழுது'), findsOneWidget);
    expect(find.text('சரிபார் / முடித்தேன்'), findsOneWidget);
    expect(find.text('அ – முந்தைய பயிற்சிகள்'), findsOneWidget);

    // Ensure numeric directional guide badges '1', '2', '3' are NOT displayed
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsNothing);
  });

  testWidgets('LetterCard renders image and only Tamil letter without Tanglish', (WidgetTester tester) async {
    final letter = LetterModel(
      id: 'uyir_1',
      letter: 'அ',
      type: LetterType.uyir,
      word: 'அம்மா',
      meaning: 'Mother',
      phonetic: 'Amma',
      imagePath: 'assets/images/amma.jpg',
      iconEmoji: '👩‍👧',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LetterCard(
            letter: letter,
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    // Letter 'அ' is rendered
    expect(find.text('அ'), findsOneWidget);
    // English transliteration 'Amma' is NOT rendered on the card
    expect(find.text('Amma'), findsNothing);
  });

  testWidgets('Settings (profile) and WritingHistoryScreen load smoothly', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(progressService: ProgressService()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Learning Progress'), findsOneWidget);
    expect(find.text('Writing Practice Records'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: WritingHistoryScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('எழுத்துப் பயிற்சி பதிவுகள்'), findsOneWidget);
  });

  test('WritingPractice and UserProfile serialization models test', () {
    final point1 = WritingPoint(x: 0.25, y: 0.5);
    final practice = WritingPractice(
      id: 'test_1',
      letter: 'அ',
      category: 'uyir',
      strokes: [[point1]],
      createdAt: DateTime(2026, 9, 16, 16, 30),
      attemptNumber: 1,
    );

    final jsonStr = WritingPractice.listToJson([practice]);
    final restored = WritingPractice.listFromJson(jsonStr);
    expect(restored.length, 1);
    expect(restored.first.letter, 'அ');
    expect(restored.first.strokes.first.first.x, 0.25);

    final profile = UserProfile(
      id: 'child_1',
      name: 'கயல்',
      age: 6,
      avatarAsset: 'assets/images/welcome.png',
      totalStars: 42,
      createdAt: DateTime(2026, 9, 16),
    );
    final profileStr = profile.toJsonString();
    final restoredProfile = UserProfile.fromJsonString(profileStr);
    expect(restoredProfile.name, 'கயல்');
    expect(restoredProfile.age, 6);
    expect(restoredProfile.totalStars, 42);
  });

  test('WritingData and AudioService mappings consistency test', () {
    expect(WritingData.uyirGuides.length, 12);
    expect(WritingData.meiGuides.length, 18);
    expect(WritingData.uyirmeiSampleGuides.length, 4);

    final pathA = AudioService.getAudioPathForLetter('அ');
    expect(pathA, 'assets/sounds/uyir/uyir_a.mp3');

    final pathK = AudioService.getAudioPathForLetter('க்');
    expect(pathK, 'assets/audio/tamil/mei/mei_01_ik.mp3');
  });

  test('TamilTtsService singleton, safe null/empty handling and mute synchronization', () async {
    final tts1 = TamilTtsService.instance;
    final tts2 = TamilTtsService();
    expect(identical(tts1, tts2), isTrue);

    // Null and empty strings should handle safely without throwing
    await TamilTtsService.speak(null);
    await TamilTtsService.speak('');
    await TamilTtsService.speak('   ');

    // Mute controls
    tts1.setMuted(true);
    expect(tts1.isMuted, isTrue);
    await TamilTtsService.speak('அம்மா');
    expect(tts1.isSpeaking, isFalse);

    tts1.setMuted(false);
    expect(tts1.isMuted, isFalse);

    // AudioService speakText
    final audio = AudioService.instance;
    await audio.speakText('வணக்கம்');
    await audio.stopAll();

    // Mute synchronization between AudioService and TamilTtsService
    audio.setMuted(true);
    expect(audio.isMuted, isTrue);
    expect(TamilTtsService.instance.isMuted, isTrue);

    audio.setMuted(false);
    expect(audio.isMuted, isFalse);
    expect(TamilTtsService.instance.isMuted, isFalse);
  });
}
