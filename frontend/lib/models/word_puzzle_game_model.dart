import 'package:flutter/material.dart';

/// Represents a single tile on the Candy Crush-style letter board
class WordPuzzleTile {
  final int id;
  final String component;
  final int row;
  final int col;
  bool isMatched;
  bool isWrongShake;
  bool isHinted;

  WordPuzzleTile({
    required this.id,
    required this.component,
    required this.row,
    required this.col,
    this.isMatched = false,
    this.isWrongShake = false,
    this.isHinted = false,
  });

  WordPuzzleTile copyWith({
    int? id,
    String? component,
    int? row,
    int? col,
    bool? isMatched,
    bool? isWrongShake,
    bool? isHinted,
  }) {
    return WordPuzzleTile(
      id: id ?? this.id,
      component: component ?? this.component,
      row: row ?? this.row,
      col: col ?? this.col,
      isMatched: isMatched ?? this.isMatched,
      isWrongShake: isWrongShake ?? this.isWrongShake,
      isHinted: isHinted ?? this.isHinted,
    );
  }
}

/// Structured Tamil word puzzle definition
class WordPuzzleModel {
  final String id;
  final String word; // e.g. 'யானை'
  final List<String> components; // e.g. ['ய', 'ா', 'ன', 'ை']
  final List<String> distractorPool;
  final int difficultyLevel; // 1, 2, 3, 4
  final String? meaning;
  final String? audioPath;

  const WordPuzzleModel({
    required this.id,
    required this.word,
    required this.components,
    required this.distractorPool,
    required this.difficultyLevel,
    this.meaning,
    this.audioPath,
  });
}

/// Particle for celebration bursts
class WordPuzzleSparkle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double size;
  double life;
  double maxLife;

  WordPuzzleSparkle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.life,
    required this.maxLife,
  });

  double get progress => (1.0 - (life / maxLife)).clamp(0.0, 1.0);
}
