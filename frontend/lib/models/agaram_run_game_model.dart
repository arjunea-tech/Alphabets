import 'package:flutter/material.dart';
import 'letter_model.dart';

/// Types of platforms in the game world
enum PlatformType {
  ground,       // Solid grass/earth ground
  floating,     // Floating wooden or stone ledge
  moving,       // Horizontally or vertically moving platform
  woodenCrate,  // Stepping block
}

/// Types of collectible items
enum CollectibleType {
  targetLetter, // Tamil educational letter (e.g., 'அ')
  bonusStar,    // Collectible bonus star for extra points
}

/// Types of obstacles/hazards
enum ObstacleType {
  rock,         // Boulder on the ground
  woodenLog,    // Wooden hurdle
  snailEnemy,   // Cute bouncy snail creature
  hazardGap,    // Bottomless pit
}

/// Represents a platform in the 2D side-scroller world
class PlatformTile {
  final int id;
  double x;
  double y;
  double width;
  double height;
  final PlatformType type;
  
  // Moving platform parameters
  double minX;
  double maxX;
  double speedX;
  int moveDirection; // 1 or -1

  // Appearance
  final Color primaryColor;
  final Color accentColor;

  PlatformTile({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.type = PlatformType.ground,
    this.minX = 0,
    this.maxX = 0,
    this.speedX = 0,
    this.moveDirection = 1,
    this.primaryColor = const Color(0xFF4CAF50),
    this.accentColor = const Color(0xFF81C784),
  });

  Rect get rect => Rect.fromLTWH(x, y, width, height);
}

/// Represents a collectible Tamil letter or star
class CollectibleItem {
  final int id;
  final double x;
  final double y;
  final CollectibleType type;
  final LetterModel? letterModel; // Non-null if type == targetLetter
  bool isCollected;
  double floatPhase; // Idle floating bobbing animation

  CollectibleItem({
    required this.id,
    required this.x,
    required this.y,
    required this.type,
    this.letterModel,
    this.isCollected = false,
    this.floatPhase = 0.0,
  });

  String get letter => letterModel?.letter ?? '⭐';
  String? get audioPath => letterModel?.audioPath;
  String? get word => letterModel?.word;

  Rect get rect => Rect.fromCenter(center: Offset(x, y), width: 44, height: 44);
}

/// Represents an obstacle on the terrain
class ObstacleItem {
  final int id;
  double x;
  double y;
  double width;
  double height;
  final ObstacleType type;
  double patrolRange;
  double startX;
  int patrolDir;
  double animPhase;

  ObstacleItem({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.type,
    this.patrolRange = 0.0,
    double? startX,
    this.patrolDir = 1,
    this.animPhase = 0.0,
  }) : startX = startX ?? x;

  Rect get rect => Rect.fromLTWH(x, y, width, height);
}

/// Particle for jump dust, letter collection burst, or star sparkles
class AgaramRunParticle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double size;
  double life;
  double maxLife;
  bool isStar;

  AgaramRunParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.life,
    required this.maxLife,
    this.isStar = false,
  });

  double get progress => (1.0 - (life / maxLife)).clamp(0.0, 1.0);
}

/// Level specification model
class AgaramRunLevel {
  final int levelNumber;
  final String title;
  final String subtitle;
  final String description;
  final List<LetterModel> targetLetters;
  final double worldWidth;
  final List<PlatformTile> platforms;
  final List<CollectibleItem> collectibles;
  final List<ObstacleItem> obstacles;
  final double goalX;

  const AgaramRunLevel({
    required this.levelNumber,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.targetLetters,
    required this.worldWidth,
    required this.platforms,
    required this.collectibles,
    required this.obstacles,
    required this.goalX,
  });
}
