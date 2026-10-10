import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamil/data/writing_data.dart';
import 'package:tamil/models/handwriting_ml_model.dart';
import 'package:tamil/services/stroke_preprocessor.dart';
import 'package:tamil/services/tamil_handwriting_recognition_service.dart';
import 'package:tamil/widgets/writing_canvas.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tamil Real ML Handwriting Recognition Engine Tests', () {
    const canvasSize = Size(350, 350);

    test('1. StrokePreprocessor converts strokes to normalized [32, 32, 1] tensor', () {
      const preprocessor = StrokePreprocessor(targetDimension: 32);

      final mockStrokes = [
        [
          const Offset(100, 100),
          const Offset(120, 110),
          const Offset(140, 130),
          const Offset(160, 160),
        ],
        [
          const Offset(140, 130),
          const Offset(220, 130),
        ],
      ];

      final Float32List tensor = preprocessor.preprocessToImageTensor(mockStrokes, canvasSize);

      expect(tensor.length, 32 * 32);
      expect(tensor.any((val) => val > 0.0), isTrue);
      for (final val in tensor) {
        expect(val, inInclusiveRange(0.0, 1.0));
      }
    });

    test('2. TamilHandwritingRecognitionService: verifies "அ", "ஆ", "இ", "ஊ", "ஔ" and rejection rules', () async {
      final service = TamilHandwritingRecognitionService.instance;
      await service.initialize();

      expect(
        service.status == MLModelStatus.loaded || service.status == MLModelStatus.modelFileRequired,
        isTrue,
      );

      // 1. Realistic handwritten 'அ' strokes
      final mockStrokesA = [
        [
          const Offset(160, 70),
          const Offset(140, 90),
          const Offset(160, 110),
          const Offset(180, 90),
          const Offset(160, 70),
          const Offset(195, 70),
          const Offset(210, 95),
          const Offset(210, 135),
        ],
        [
          const Offset(210, 135),
          const Offset(180, 175),
          const Offset(130, 215),
          const Offset(90, 240),
          const Offset(70, 260),
          const Offset(95, 275),
          const Offset(135, 260),
          const Offset(175, 200),
          const Offset(250, 200),
        ],
        [
          const Offset(250, 70),
          const Offset(250, 200),
          const Offset(250, 280),
        ],
      ];

      final resultA = await service.recognizeStrokes(
        expectedLetter: 'அ',
        userStrokes: mockStrokesA,
        canvasSize: canvasSize,
      );

      expect(resultA.recognizedCharacter, 'அ');
      expect(resultA.isMatch, isTrue);

      // 2. Realistic handwritten 'ஆ' strokes (with bottom-right loop)
      final mockStrokesAa = [
        [
          const Offset(160, 70),
          const Offset(140, 90),
          const Offset(160, 110),
          const Offset(180, 90),
          const Offset(160, 70),
          const Offset(195, 70),
          const Offset(210, 95),
          const Offset(210, 135),
        ],
        [
          const Offset(210, 135),
          const Offset(180, 175),
          const Offset(130, 215),
          const Offset(90, 240),
          const Offset(70, 260),
          const Offset(95, 275),
          const Offset(135, 260),
          const Offset(175, 200),
          const Offset(250, 200),
        ],
        [
          const Offset(250, 70),
          const Offset(250, 200),
          const Offset(250, 260),
          const Offset(280, 290),
          const Offset(300, 275),
          const Offset(285, 255),
          const Offset(250, 260),
        ],
      ];

      final resultAa = await service.recognizeStrokes(
        expectedLetter: 'ஆ',
        userStrokes: mockStrokesAa,
        canvasSize: canvasSize,
      );
      expect(resultAa.recognizedCharacter, 'ஆ');
      expect(resultAa.isMatch, isTrue);

      // 3. Realistic handwritten 'இ' strokes
      // 3a. Authentic handwritten 'இ' with full enclosing arch dome (as in user screenshot)
      final mockStrokesIAuthentic = [
        [
          const Offset(150, 130),
          const Offset(130, 110),
          const Offset(140, 80),
          const Offset(180, 80),
          const Offset(220, 100),
          const Offset(210, 140),
          const Offset(160, 175),
          const Offset(110, 210),
          const Offset(85, 255),
          const Offset(120, 290),
          const Offset(190, 290),
          const Offset(250, 265),
        ],
        [
          const Offset(85, 255),
          const Offset(65, 160),
          const Offset(105, 65),
          const Offset(210, 50),
          const Offset(300, 90),
          const Offset(315, 195),
          const Offset(310, 280),
        ],
      ];

      final resultIAuthentic = await service.recognizeStrokes(
        expectedLetter: 'இ',
        userStrokes: mockStrokesIAuthentic,
        canvasSize: canvasSize,
      );
      expect(resultIAuthentic.recognizedCharacter, 'இ');
      expect(resultIAuthentic.isMatch, isTrue, reason: "Authentic 'இ' with enclosing arch must match with success");

      // 3b. Standard cursive print 'இ' strokes
      final mockStrokesI = [
        [
          const Offset(140, 80),
          const Offset(120, 70),
          const Offset(110, 90),
          const Offset(130, 110),
          const Offset(160, 100),
          const Offset(200, 90),
          const Offset(230, 110),
          const Offset(240, 140),
        ],
        [
          const Offset(240, 140),
          const Offset(220, 170),
          const Offset(170, 180),
          const Offset(130, 200),
          const Offset(110, 230),
          const Offset(130, 260),
          const Offset(170, 260),
          const Offset(220, 250),
          const Offset(250, 260),
        ],
      ];

      final resultI = await service.recognizeStrokes(
        expectedLetter: 'இ',
        userStrokes: mockStrokesI,
        canvasSize: canvasSize,
      );
      expect(resultI.recognizedCharacter, 'இ');
      expect(resultI.isMatch, isTrue);

      // 4. Critical user scenario: Drawing 'இ' while practicing 'ஆ' -> MUST BE REJECTED
      final resultIVsAa = await service.recognizeStrokes(
        expectedLetter: 'ஆ',
        userStrokes: mockStrokesI,
        canvasSize: canvasSize,
      );
      expect(resultIVsAa.isMatch, isFalse, reason: "Drawing 'இ' when expecting 'ஆ' must be rejected");

      // 5. Critical user scenario: Drawing 'ஆ' while practicing 'அ' -> MUST BE REJECTED
      final resultAaVsA = await service.recognizeStrokes(
        expectedLetter: 'அ',
        userStrokes: mockStrokesAa,
        canvasSize: canvasSize,
      );
      expect(resultAaVsA.isMatch, isFalse, reason: "Drawing 'ஆ' when expecting 'அ' must be rejected");
      expect(resultAaVsA.errorMessage, contains('ஆ'));

      // 5b. Continuous single stroke 'ஆ' (as drawn in user screenshot) while practicing 'அ' -> MUST BE REJECTED
      final mockSingleStrokeAa = [
        [
          const Offset(150, 80),
          const Offset(130, 70),
          const Offset(115, 90),
          const Offset(135, 110),
          const Offset(165, 100),
          const Offset(200, 90),
          const Offset(215, 115),
          const Offset(215, 150),
          const Offset(190, 185),
          const Offset(140, 220),
          const Offset(90, 250),
          const Offset(65, 270),
          const Offset(90, 290),
          const Offset(135, 275),
          const Offset(180, 210),
          const Offset(250, 210),
          const Offset(250, 80),
          const Offset(250, 260),
          const Offset(275, 295),
          const Offset(295, 275),
          const Offset(275, 255),
          const Offset(250, 260),
        ]
      ];

      final resultSingleAaVsA = await service.recognizeStrokes(
        expectedLetter: 'அ',
        userStrokes: mockSingleStrokeAa,
        canvasSize: canvasSize,
      );
      expect(resultSingleAaVsA.isMatch, isFalse, reason: "Drawing single-stroke 'ஆ' when practicing 'அ' must be rejected");
      expect(resultSingleAaVsA.errorMessage, contains('ஆ'));

      // 6. Realistic handwritten 'ஊ' strokes (உ + ள)
      final mockStrokesOo = [
        [
          const Offset(90, 140),
          const Offset(75, 125),
          const Offset(60, 140),
          const Offset(75, 155),
          const Offset(95, 145),
          const Offset(130, 115),
          const Offset(160, 115),
          const Offset(170, 145),
          const Offset(170, 175),
        ],
        [
          const Offset(170, 175),
          const Offset(150, 215),
          const Offset(110, 245),
          const Offset(85, 275),
          const Offset(210, 275),
        ],
        [
          const Offset(210, 110),
          const Offset(195, 100),
          const Offset(190, 110),
          const Offset(200, 120),
          const Offset(220, 115),
          const Offset(240, 100),
          const Offset(250, 120),
          const Offset(250, 170),
          const Offset(225, 200),
          const Offset(265, 200),
        ],
      ];

      final resultOo = await service.recognizeStrokes(
        expectedLetter: 'ஊ',
        userStrokes: mockStrokesOo,
        canvasSize: canvasSize,
      );
      expect(resultOo.recognizedCharacter, 'ஊ');
      expect(resultOo.isMatch, isTrue, reason: "Drawing 'ஊ' correctly must match");

      // 6b. Drawing 'ஊ' when practicing 'உ' -> MUST BE REJECTED
      final resultOoVsU = await service.recognizeStrokes(
        expectedLetter: 'உ',
        userStrokes: mockStrokesOo,
        canvasSize: canvasSize,
      );
      expect(resultOoVsU.isMatch, isFalse, reason: "Drawing 'ஊ' when expecting 'உ' must be rejected");
      expect(resultOoVsU.errorMessage, contains('ஊ'));

      // 7. Realistic handwritten 'ஔ' strokes (ஒ + ள)
      final mockStrokesAu = [
        [
          const Offset(80, 110),
          const Offset(65, 95),
          const Offset(55, 110),
          const Offset(70, 125),
          const Offset(85, 120),
          const Offset(115, 95),
          const Offset(140, 110),
          const Offset(130, 150),
        ],
        [
          const Offset(130, 150),
          const Offset(95, 170),
          const Offset(105, 210),
          const Offset(135, 220),
          const Offset(165, 205),
          const Offset(165, 170),
          const Offset(190, 170),
          const Offset(190, 230),
        ],
        [
          const Offset(220, 120),
          const Offset(205, 110),
          const Offset(200, 120),
          const Offset(210, 130),
          const Offset(230, 125),
          const Offset(250, 110),
          const Offset(260, 130),
          const Offset(260, 180),
          const Offset(230, 210),
          const Offset(270, 210),
        ],
      ];

      final resultAu = await service.recognizeStrokes(
        expectedLetter: 'ஔ',
        userStrokes: mockStrokesAu,
        canvasSize: canvasSize,
      );
      expect(resultAu.recognizedCharacter, 'ஔ');
      expect(resultAu.isMatch, isTrue, reason: "Drawing 'ஔ' correctly must match");

      // 7b. Drawing 'ஔ' when practicing 'ஒ' -> MUST BE REJECTED
      final resultAuVsO = await service.recognizeStrokes(
        expectedLetter: 'ஒ',
        userStrokes: mockStrokesAu,
        canvasSize: canvasSize,
      );
      expect(resultAuVsO.isMatch, isFalse, reason: "Drawing 'ஔ' when expecting 'ஒ' must be rejected");

      // 7c. Realistic handwritten 'ஈ' strokes with dots -> MUST MATCH and NOT be rejected
      final mockStrokesEe = [
        [
          const Offset(100, 75),
          const Offset(100, 160),
          const Offset(100, 245),
        ],
        [
          const Offset(75, 75),
          const Offset(150, 75),
          const Offset(220, 75),
          const Offset(220, 160),
          const Offset(220, 245),
        ],
        [
          const Offset(160, 160),
        ],
        [
          const Offset(265, 160),
        ],
      ];

      final resultEe = await service.recognizeStrokes(
        expectedLetter: 'ஈ',
        userStrokes: mockStrokesEe,
        canvasSize: canvasSize,
      );
      expect(resultEe.recognizedCharacter, 'ஈ');
      expect(resultEe.isMatch, isTrue, reason: "Drawing 'ஈ' correctly with dots must match and not be rejected");

      // 8. Random scribble & zig-zag strokes must be rejected
      final mockScribble = [
        for (double y = 50; y <= 300; y += 30)
          [
            Offset(50, y),
            Offset(300, y + 10),
            Offset(50, y + 20),
          ]
      ];

      final scribbleResult = await service.recognizeStrokes(
        expectedLetter: 'அ',
        userStrokes: mockScribble,
        canvasSize: canvasSize,
      );
      expect(scribbleResult.isMatch, isFalse, reason: "Scribble must be rejected");

      // 8b. Single stroke zig-zag (M-shape / lightning scribble as drawn in user screenshot)
      final mockUserZigzagScribble = [
        [
          const Offset(100, 100),
          const Offset(80, 160),
          const Offset(65, 230),
          const Offset(130, 190),
          const Offset(190, 150),
          const Offset(180, 210),
          const Offset(220, 200),
          const Offset(230, 270),
        ]
      ];

      final zigzagResult = await service.recognizeStrokes(
        expectedLetter: 'அ',
        userStrokes: mockUserZigzagScribble,
        canvasSize: canvasSize,
      );
      expect(zigzagResult.isMatch, isFalse, reason: "Zigzag scribble must be rejected as 'அ'");

      // 9. Realistic handwritten 'ஃ' (3 distinct dot clusters)
      final mockStrokesAyutham = [
        [const Offset(175, 105), const Offset(176, 106)], // top dot
        [const Offset(120, 225), const Offset(121, 226)], // bottom-left dot
        [const Offset(230, 225), const Offset(231, 226)], // bottom-right dot
      ];

      final resultAyutham = await service.recognizeStrokes(
        expectedLetter: 'ஃ',
        userStrokes: mockStrokesAyutham,
        canvasSize: canvasSize,
      );
      expect(resultAyutham.recognizedCharacter, 'ஃ');
      expect(resultAyutham.isMatch, isTrue, reason: "Drawing 'ஃ' with 3 dots must match");

      // 10. Mei Consonant validation (Body + Top Dot)
      final mockStrokesIkWithDot = [
        [const Offset(110, 110), const Offset(110, 260)], // left stem
        [const Offset(110, 110), const Offset(240, 110), const Offset(240, 260)], // top bar + right stem
        [const Offset(175, 180), const Offset(240, 180), const Offset(265, 260)], // cross + hook
        [const Offset(175, 65), const Offset(176, 66)], // pulli (top dot)
      ];

      final resultIkWithDot = await service.recognizeStrokes(
        expectedLetter: 'க்',
        userStrokes: mockStrokesIkWithDot,
        canvasSize: canvasSize,
      );
      expect(resultIkWithDot.isMatch, isTrue, reason: "Drawing 'க்' with top pulli must match");

      // 10b. Mei consonant without dot -> MUST BE REJECTED
      final mockStrokesIkWithoutDot = [
        [const Offset(110, 110), const Offset(110, 260)],
        [const Offset(110, 110), const Offset(240, 110), const Offset(240, 260)],
        [const Offset(175, 180), const Offset(240, 180), const Offset(265, 260)],
      ];

      final resultIkWithoutDot = await service.recognizeStrokes(
        expectedLetter: 'க்',
        userStrokes: mockStrokesIkWithoutDot,
        canvasSize: canvasSize,
      );
      expect(resultIkWithoutDot.isMatch, isFalse, reason: "Drawing 'க்' without pulli must be rejected");
      expect(resultIkWithoutDot.errorMessage, contains('புள்ளி'));
    });

    test('3. WritingData contains all 12 Uyir, 18 Mei, and 1 Ayutham guides (31 total)', () {
      expect(WritingData.uyirGuides.length, 12);
      expect(WritingData.meiGuides.length, 18);
      expect(WritingData.ayuthamGuides.length, 1);
      final meiLetters = WritingData.meiGuides.map((g) => g.letter).toList();
      const expected18 = [
        'க்', 'ங்', 'ச்', 'ஞ்', 'ட்', 'ண்',
        'த்', 'ந்', 'ப்', 'ம்', 'ய்', 'ர்',
        'ல்', 'வ்', 'ழ்', 'ள்', 'ற்', 'ன்',
      ];
      expect(meiLetters, expected18);
      expect(WritingData.ayuthamGuides.first.letter, 'ஃ');
    });

    testWidgets('4. WritingCanvas renders Unicode letter in Learn mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 350,
              height: 350,
              child: WritingCanvas(
                letter: 'அ',
                mode: WritingCanvasMode.learn,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(WritingCanvas), findsOneWidget);
    });
  });
}
