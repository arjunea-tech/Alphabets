import 'dart:ui';
import '../models/letter_model.dart';

enum BasketGameMode {
  uyir('English Alphabets (A - Z)'),
  mei('English Vowels (A, E, I, O, U)');

  final String title;
  const BasketGameMode(this.title);
}

class FallingLetter {
  final int id;
  final String letter;
  final String word;
  final bool isTarget;
  double x; // Fractional position (0.0 to 1.0)
  double y; // Y coordinate in logical pixels
  final double speed; // Pixels per second
  final double wobbleOffset;
  final Color bubbleColor;
  final Color borderColor;
  bool isCaught;
  bool isMissed;

  FallingLetter({
    required this.id,
    required this.letter,
    required this.word,
    required this.isTarget,
    required this.x,
    required this.y,
    required this.speed,
    required this.wobbleOffset,
    required this.bubbleColor,
    required this.borderColor,
    this.isCaught = false,
    this.isMissed = false,
  });
}

class BasketGameRound {
  final int roundNumber;
  final LetterModel targetLetter;
  final List<LetterModel> distractorLetters;

  const BasketGameRound({
    required this.roundNumber,
    required this.targetLetter,
    required this.distractorLetters,
  });
}
