import 'dart:math';
import 'package:flutter/material.dart';
import 'letter_model.dart';

/// Game modes for the Letter Fishing Game
enum FishingGameMode {
  uyir('Vowels', 'Catch the vowels A, E, I, O, U with your hook!'),
  mei('Consonants', 'Catch consonants B to Z with your hook!');

  final String title;
  final String description;
  const FishingGameMode(this.title, this.description);
}

/// Dynamic swimming fish entity
class SwimmingFish {
  final int id;
  final LetterModel letterModel;
  final bool isTarget;
  
  // Position & Velocity
  double x; // 0.0 (left) to 1.0 (right)
  double y; // 0.12 (top ocean) to 0.82 (seabed)
  double speed; // screen width fraction per second
  int direction; // 1 = swimming right, -1 = swimming left
  
  // Natural Swimming Oscillation
  double yWobbleFreq;
  double yWobbleAmp;
  double wobblePhase;
  double tailWagPhase;
  
  // Appearance
  final List<Color> bodyGradient;
  final Color finColor;
  final Color accentColor;
  final double size; // Base fish length in logical pixels
  
  // Interaction States
  bool isCaught;
  double catchProgress; // 0.0 to 1.0 (pull up on hook)
  bool isWrongShaking;
  double wrongShakeProgress; // 0.0 to 1.0

  SwimmingFish({
    required this.id,
    required this.letterModel,
    required this.isTarget,
    required this.x,
    required this.y,
    required this.speed,
    required this.direction,
    required this.yWobbleFreq,
    required this.yWobbleAmp,
    required this.wobblePhase,
    required this.bodyGradient,
    required this.finColor,
    required this.accentColor,
    this.size = 115.0,
    this.tailWagPhase = 0.0,
    this.isCaught = false,
    this.catchProgress = 0.0,
    this.isWrongShaking = false,
    this.wrongShakeProgress = 0.0,
  });

  String get letter => letterModel.letter;
  String get word => letterModel.word;
  String? get audioPath => letterModel.audioPath;
}

/// Floating bubble in underwater scene
class UnderwaterBubble {
  double x;
  double y;
  double radius;
  double speedY;
  double wobbleSpeed;
  double wobblePhase;
  double opacity;

  UnderwaterBubble({
    required this.x,
    required this.y,
    required this.radius,
    required this.speedY,
    required this.wobbleSpeed,
    required this.wobblePhase,
    required this.opacity,
  });
}

/// Splash & Sparkle Particles for celebration
class FishingParticle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double size;
  double life;
  double maxLife;
  bool isStar;
  String? text;

  FishingParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.life,
    required this.maxLife,
    this.isStar = false,
    this.text,
  });

  double get progress => (1.0 - (life / maxLife)).clamp(0.0, 1.0);
}

/// Color presets for colorful cartoon fish
class FishColorPalette {
  static const List<List<Color>> bodyGradients = [
    [Color(0xFFFF7043), Color(0xFFFF5722), Color(0xFFE64A19)], // Clownfish Orange
    [Color(0xFF29B6F6), Color(0xFF0288D1), Color(0xFF01579B)], // Aqua Blue Tang
    [Color(0xFFEC407A), Color(0xFFD81B60), Color(0xFF880E4F)], // Coral Pink
    [Color(0xFFFFEE58), Color(0xFFFDD835), Color(0xFFF57F17)], // Golden Yellow
    [Color(0xFFAB47BC), Color(0xFF7B1FA2), Color(0xFF4A148C)], // Royal Purple
    [Color(0xFF26A69A), Color(0xFF00897B), Color(0xFF004D40)], // Emerald Turquoise
  ];

  static const List<Color> finColors = [
    Color(0xFFFFD54F),
    Color(0xFF80D8FF),
    Color(0xFFFF80AB),
    Color(0xFFFF8A65),
    Color(0xFFEA80FC),
    Color(0xFFA7FFEB),
  ];

  static const List<Color> accentColors = [
    Color(0xFFFFB74D),
    Color(0xFF4FC3F7),
    Color(0xFFF06292),
    Color(0xFFFFF176),
    Color(0xFFBA68C8),
    Color(0xFF4DB6AC),
  ];

  static (List<Color>, Color, Color) getRandomColors(Random rng) {
    final idx = rng.nextInt(bodyGradients.length);
    return (
      bodyGradients[idx],
      finColors[idx],
      accentColors[idx],
    );
  }
}
