import 'dart:ui';

enum RacingGameMode {
  uyir('Vowels (A, E, I, O, U)'),
  words('Alphabet Words'),
  mei('Consonants (21 Letters)');

  final String title;
  const RacingGameMode(this.title);
}

class RacingTarget {
  final String id;
  final String text; //  Target character or word (e.g., '' or '')
  final String clue; //  Helpful clue or example (e.g., '' or ' ')
  final String? audioPath;
  final bool isWord;

  const RacingTarget({
    required this.id,
    required this.text,
    required this.clue,
    this.audioPath,
    this.isWord = false,
  });
}

class RacingRoadItem {
  final int id;
  final String text;
  final bool isTarget;
  final bool isObstacle; // e.g. traffic cone or puddle
  final bool isBonusStar; // e.g. floating star bonus
  int lane; // 0: Left, 1: Center, 2: Right
  double y; // Fractional vertical position (0.0 at top horizon to 1.0 at car position)
  bool isCollected;
  final Color bubbleColor;
  final Color borderColor;

  RacingRoadItem({
    required this.id,
    required this.text,
    required this.isTarget,
    this.isObstacle = false,
    this.isBonusStar = false,
    required this.lane,
    required this.y,
    this.isCollected = false,
    required this.bubbleColor,
    required this.borderColor,
  });
}
