import 'dart:ui';

enum RacingGameMode {
  uyir('உயிர் எழுத்துகள்'),
  words('தமிழ் சொற்கள்'),
  mei('மெய் எழுத்துகள்');

  final String title;
  const RacingGameMode(this.title);
}

class RacingTarget {
  final String id;
  final String text; // Target character or word (e.g., 'அ' or 'மீன்')
  final String clue; // Helpful clue or example (e.g., 'அம்மா' or 'துள்ளும் மீன்')
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
