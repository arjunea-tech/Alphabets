import 'package:flutter/material.dart';
import 'letter_model.dart';

/// Candy tile power-up types
enum CandySpecialType {
  none,
  rowBlast, // Clears entire row
  colBlast, // Clears entire column
  bomb,     // 3x3 blast or color burst
}

/// Represents an individual candy piece on the board
class CandyTile {
  final int id;
  LetterModel letterModel;
  int row;
  int col;
  CandySpecialType specialType;
  
  // Animation & Rendering state
  bool isSelected;
  bool isMatched;
  double scale;
  double opacity;
  double offsetX; // Drag/swipe pixel offset
  double offsetY; // Drag/swipe pixel offset
  double fallOffset; // Falling distance from above in rows

  // Visual appearance
  final List<Color> gradientColors;
  final Color borderColor;
  final Color shadowColor;
  final Color textColor;

  CandyTile({
    required this.id,
    required this.letterModel,
    required this.row,
    required this.col,
    this.specialType = CandySpecialType.none,
    this.isSelected = false,
    this.isMatched = false,
    this.scale = 1.0,
    this.opacity = 1.0,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.fallOffset = 0.0,
    required this.gradientColors,
    required this.borderColor,
    required this.shadowColor,
    this.textColor = Colors.white,
  });

  String get letter => letterModel.letter;
  String get word => letterModel.word;
  String? get audioPath => letterModel.audioPath;

  CandyTile copyWith({
    int? id,
    LetterModel? letterModel,
    int? row,
    int? col,
    CandySpecialType? specialType,
    bool? isSelected,
    bool? isMatched,
    double? scale,
    double? opacity,
    double? offsetX,
    double? offsetY,
    double? fallOffset,
    List<Color>? gradientColors,
    Color? borderColor,
    Color? shadowColor,
    Color? textColor,
  }) {
    return CandyTile(
      id: id ?? this.id,
      letterModel: letterModel ?? this.letterModel,
      row: row ?? this.row,
      col: col ?? this.col,
      specialType: specialType ?? this.specialType,
      isSelected: isSelected ?? this.isSelected,
      isMatched: isMatched ?? this.isMatched,
      scale: scale ?? this.scale,
      opacity: opacity ?? this.opacity,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      fallOffset: fallOffset ?? this.fallOffset,
      gradientColors: gradientColors ?? this.gradientColors,
      borderColor: borderColor ?? this.borderColor,
      shadowColor: shadowColor ?? this.shadowColor,
      textColor: textColor ?? this.textColor,
    );
  }
}

/// Particle for candy pop explosion
class CandySparkleParticle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double size;
  double life;
  double maxLife;
  bool isStar;
  bool isCandyPiece;

  CandySparkleParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.life,
    required this.maxLife,
    this.isStar = false,
    this.isCandyPiece = false,
  });

  double get progress => (1.0 - (life / maxLife)).clamp(0.0, 1.0);
}

/// Level specification model
class CandyGameLevel {
  final int levelNumber;
  final String title;
  final String subtitle;
  final String description;
  final List<LetterModel> letterPool;
  final int targetScore;
  final int maxMoves;
  final int? timeLimitSeconds; // null for move-based levels

  const CandyGameLevel({
    required this.levelNumber,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.letterPool,
    required this.targetScore,
    this.maxMoves = 22,
    this.timeLimitSeconds,
  });

  bool get isTimed => timeLimitSeconds != null && timeLimitSeconds! > 0;
}

/// Visual theme and styling specification for an individual candy letter tile
class CandyLetterStyle {
  final Color primaryColor;
  final List<Color> gradientColors;
  final Color borderColor;
  final Color shadowColor;
  final Color textColor;

  const CandyLetterStyle({
    required this.primaryColor,
    required this.gradientColors,
    required this.borderColor,
    required this.shadowColor,
    this.textColor = Colors.white,
  });
}

/// Centralized, dedicated color system for Tamil candy tiles.
/// Rule: ONE LETTER = ONE UNIQUE DEDICATED COLOR.
class CandyColorPalette {
  /// Centralized map of Tamil Letter -> Dedicated Primary Color
  static const Map<String, Color> letterColors = {
    'A': Color(0xFFFF1744),
    'B': Color(0xFFFF6D00),
    'C': Color(0xFFFFB300),
    'D': Color(0xFF00E676),
    'E': Color(0xFF00B0FF),
    'F': Color(0xFFAA00FF),
    'G': Color(0xFFFF4081),
    'H': Color(0xFF00897B),
    'I': Color(0xFF8D4B1E),
    'J': Color(0xFF3D5AFE),
    'K': Color(0xFF1B5E20),
    'L': Color(0xFF6A0080),
    'M': Color(0xFF00C853),
    'N': Color(0xFF0091EA),
    'O': Color(0xFFFF1493),
    'P': Color(0xFF7B1FA2),
    'Q': Color(0xFFFFD600),
    'R': Color(0xFFE53935),
    'S': Color(0xFFFF5722),
    'T': Color(0xFF00E5FF),
    'U': Color(0xFF76FF03),
    'V': Color(0xFFF50057),
    'W': Color(0xFF2962FF),
    'X': Color(0xFFBA68C8),
    'Y': Color(0xFF2979FF),
    'Z': Color(0xFFD50000),
  };

  /// Detailed styling tokens for each letter (Gradient, Border, Shadow, Text)
  static const Map<String, CandyLetterStyle> letterStyles = {
    'A': CandyLetterStyle(
      primaryColor: Color(0xFFFF1744),
      gradientColors: [Color(0xFFFF1744), Color(0xFFFF6D00)],
      borderColor: Colors.white,
      shadowColor: Color(0x33000000),
    ),
    'B': CandyLetterStyle(
      primaryColor: Color(0xFFFF6D00),
      gradientColors: [Color(0xFFFF6D00), Color(0xFFFFB300)],
      borderColor: Colors.white,
      shadowColor: Color(0x33000000),
    ),
    'C': CandyLetterStyle(
      primaryColor: Color(0xFFFFB300),
      gradientColors: [Color(0xFFFFB300), Color(0xFF00E676)],
      borderColor: Colors.white,
      shadowColor: Color(0x33000000),
    ),
    'D': CandyLetterStyle(
      primaryColor: Color(0xFF00E676),
      gradientColors: [Color(0xFF00E676), Color(0xFF00B0FF)],
      borderColor: Colors.white,
      shadowColor: Color(0x33000000),
    ),
    'E': CandyLetterStyle(
      primaryColor: Color(0xFF00B0FF),
      gradientColors: [Color(0xFF00B0FF), Color(0xFFAA00FF)],
      borderColor: Colors.white,
      shadowColor: Color(0x33000000),
    ),
    'F': CandyLetterStyle(
      primaryColor: Color(0xFFAA00FF),
      gradientColors: [Color(0xFFAA00FF), Color(0xFFFF4081)],
      borderColor: Colors.white,
      shadowColor: Color(0x33000000),
    ),
    'G': CandyLetterStyle(
      primaryColor: Color(0xFFFF4081),
      gradientColors: [Color(0xFFFF4081), Color(0xFF00897B)],
      borderColor: Colors.white,
      shadowColor: Color(0x33000000),
    ),
    'H': CandyLetterStyle(
      primaryColor: Color(0xFF00897B),
      gradientColors: [Color(0xFF00897B), Color(0xFF8D4B1E)],
      borderColor: Colors.white,
      shadowColor: Color(0x33000000),
    ),
    'I': CandyLetterStyle(
      primaryColor: Color(0xFF8D4B1E),
      gradientColors: [Color(0xFF8D4B1E), Color(0xFF3D5AFE)],
      borderColor: Colors.white,
      shadowColor: Color(0x33000000),
    ),
    'J': CandyLetterStyle(
      primaryColor: Color(0xFF3D5AFE),
      gradientColors: [Color(0xFF3D5AFE), Color(0xFF1B5E20)],
      borderColor: Colors.white,
      shadowColor: Color(0x33000000),
    ),
    'K': CandyLetterStyle(
      primaryColor: Color(0xFF1B5E20),
      gradientColors: [Color(0xFF1B5E20), Color(0xFF6A0080)],
      borderColor: Colors.white,
      shadowColor: Color(0x33000000),
    ),
    'L': CandyLetterStyle(
      primaryColor: Color(0xFF6A0080),
      gradientColors: [Color(0xFF6A0080), Color(0xFF00C853)],
      borderColor: Colors.white,
      shadowColor: Color(0x33000000),
    ),
    'M': CandyLetterStyle(
      primaryColor: Color(0xFF00C853),
      gradientColors: [Color(0xFF00C853), Color(0xFF0091EA)],
      borderColor: Colors.white,
      shadowColor: Color(0x33000000),
    ),
    'N': CandyLetterStyle(
      primaryColor: Color(0xFF0091EA),
      gradientColors: [Color(0xFF0091EA), Color(0xFFFF1493)],
      borderColor: Colors.white,
      shadowColor: Color(0x33000000),
    ),
    'O': CandyLetterStyle(
      primaryColor: Color(0xFFFF1493),
      gradientColors: [Color(0xFFFF1493), Color(0xFF7B1FA2)],
      borderColor: Colors.white,
      shadowColor: Color(0x33000000),
    ),
    'P': CandyLetterStyle(
      primaryColor: Color(0xFF7B1FA2),
      gradientColors: [Color(0xFF7B1FA2), Color(0xFFFFD600)],
      borderColor: Colors.white,
      shadowColor: Color(0x33000000),
    ),
    'Q': CandyLetterStyle(
      primaryColor: Color(0xFFFFD600),
      gradientColors: [Color(0xFFFFD600), Color(0xFFE53935)],
      borderColor: Colors.white,
      shadowColor: Color(0x33000000),
    ),
    'R': CandyLetterStyle(
      primaryColor: Color(0xFFE53935),
      gradientColors: [Color(0xFFE53935), Color(0xFFFF5722)],
      borderColor: Colors.white,
      shadowColor: Color(0x33000000),
    ),
    'S': CandyLetterStyle(
      primaryColor: Color(0xFFFF5722),
      gradientColors: [Color(0xFFFF5722), Color(0xFF00E5FF)],
      borderColor: Colors.white,
      shadowColor: Color(0x33000000),
    ),
    'T': CandyLetterStyle(
      primaryColor: Color(0xFF00E5FF),
      gradientColors: [Color(0xFF00E5FF), Color(0xFF76FF03)],
      borderColor: Colors.white,
      shadowColor: Color(0x33000000),
    ),
    'U': CandyLetterStyle(
      primaryColor: Color(0xFF76FF03),
      gradientColors: [Color(0xFF76FF03), Color(0xFFF50057)],
      borderColor: Colors.white,
      shadowColor: Color(0x33000000),
    ),
    'V': CandyLetterStyle(
      primaryColor: Color(0xFFF50057),
      gradientColors: [Color(0xFFF50057), Color(0xFF2962FF)],
      borderColor: Colors.white,
      shadowColor: Color(0x33000000),
    ),
    'W': CandyLetterStyle(
      primaryColor: Color(0xFF2962FF),
      gradientColors: [Color(0xFF2962FF), Color(0xFFBA68C8)],
      borderColor: Colors.white,
      shadowColor: Color(0x33000000),
    ),
    'X': CandyLetterStyle(
      primaryColor: Color(0xFFBA68C8),
      gradientColors: [Color(0xFFBA68C8), Color(0xFF2979FF)],
      borderColor: Colors.white,
      shadowColor: Color(0x33000000),
    ),
    'Y': CandyLetterStyle(
      primaryColor: Color(0xFF2979FF),
      gradientColors: [Color(0xFF2979FF), Color(0xFFD50000)],
      borderColor: Colors.white,
      shadowColor: Color(0x33000000),
    ),
    'Z': CandyLetterStyle(
      primaryColor: Color(0xFFD50000),
      gradientColors: [Color(0xFFD50000), Color(0xFFFF1744)],
      borderColor: Colors.white,
      shadowColor: Color(0x33000000),
    ),
  };

  /// Fallback curated candy styles palette for any future dynamic Tamil letters.
  static const List<CandyLetterStyle> dynamicPalette = [
    CandyLetterStyle(
      primaryColor: Color(0xFFFF1744),
      gradientColors: [Color(0xFFFF5252), Color(0xFFFF1744), Color(0xFFD50000)],
      borderColor: Color(0xFFFF8A80),
      shadowColor: Color(0xFF8A0000),
    ),
    CandyLetterStyle(
      primaryColor: Color(0xFFFF6D00),
      gradientColors: [Color(0xFFFF9100), Color(0xFFFF6D00), Color(0xFFE65100)],
      borderColor: Color(0xFFFFD180),
      shadowColor: Color(0xFFBF360C),
    ),
    CandyLetterStyle(
      primaryColor: Color(0xFFFFB300),
      gradientColors: [Color(0xFFFFD54F), Color(0xFFFFB300), Color(0xFFFF8F00)],
      borderColor: Color(0xFFFFF9C4),
      shadowColor: Color(0xFFE65100),
    ),
    CandyLetterStyle(
      primaryColor: Color(0xFF00E676),
      gradientColors: [Color(0xFF69F0AE), Color(0xFF00E676), Color(0xFF00C853)],
      borderColor: Color(0xFFB9F6CA),
      shadowColor: Color(0xFF1B5E20),
    ),
    CandyLetterStyle(
      primaryColor: Color(0xFF00B0FF),
      gradientColors: [Color(0xFF40C4FF), Color(0xFF00B0FF), Color(0xFF01579B)],
      borderColor: Color(0xFF80D8FF),
      shadowColor: Color(0xFF0D47A1),
    ),
    CandyLetterStyle(
      primaryColor: Color(0xFFAA00FF),
      gradientColors: [Color(0xFFE040FB), Color(0xFFAA00FF), Color(0xFF7B1FA2)],
      borderColor: Color(0xFFEA80FC),
      shadowColor: Color(0xFF4A148C),
    ),
    CandyLetterStyle(
      primaryColor: Color(0xFFFF4081),
      gradientColors: [Color(0xFFFF80AB), Color(0xFFFF4081), Color(0xFFC2185B)],
      borderColor: Color(0xFFFFC1E3),
      shadowColor: Color(0xFF880E4F),
    ),
    CandyLetterStyle(
      primaryColor: Color(0xFF00897B),
      gradientColors: [Color(0xFF26A69A), Color(0xFF00897B), Color(0xFF004D40)],
      borderColor: Color(0xFF80CBC4),
      shadowColor: Color(0xFF00251A),
    ),
    CandyLetterStyle(
      primaryColor: Color(0xFF8D4B1E),
      gradientColors: [Color(0xFFB76E3E), Color(0xFF8D4B1E), Color(0xFF5E2B08)],
      borderColor: Color(0xFFD7CCC8),
      shadowColor: Color(0xFF3E1B05),
    ),
    CandyLetterStyle(
      primaryColor: Color(0xFF3D5AFE),
      gradientColors: [Color(0xFF8C9EFF), Color(0xFF3D5AFE), Color(0xFF1A237E)],
      borderColor: Color(0xFFC5CAE9),
      shadowColor: Color(0xFF0D1B5E),
    ),
    CandyLetterStyle(
      primaryColor: Color(0xFF00E5FF),
      gradientColors: [Color(0xFF84FFFF), Color(0xFF00E5FF), Color(0xFF0097A7)],
      borderColor: Color(0xFFE0F7FA),
      shadowColor: Color(0xFF006064),
    ),
    CandyLetterStyle(
      primaryColor: Color(0xFFFF5722),
      gradientColors: [Color(0xFFFF8A65), Color(0xFFFF5722), Color(0xFFBF360C)],
      borderColor: Color(0xFFFFCCBC),
      shadowColor: Color(0xFF8A1E00),
    ),
    CandyLetterStyle(
      primaryColor: Color(0xFF76FF03),
      gradientColors: [Color(0xFFB2FF59), Color(0xFF76FF03), Color(0xFF33691E)],
      borderColor: Color(0xFFDCEDC8),
      shadowColor: Color(0xFF1B5E20),
    ),
    CandyLetterStyle(
      primaryColor: Color(0xFFBA68C8),
      gradientColors: [Color(0xFFCE93D8), Color(0xFFBA68C8), Color(0xFF6A1B9A)],
      borderColor: Color(0xFFF3E5F5),
      shadowColor: Color(0xFF4A148C),
    ),
    CandyLetterStyle(
      primaryColor: Color(0xFF2979FF),
      gradientColors: [Color(0xFF82B1FF), Color(0xFF2979FF), Color(0xFF0D47A1)],
      borderColor: Color(0xFFBBDEFB),
      shadowColor: Color(0xFF002171),
    ),
    CandyLetterStyle(
      primaryColor: Color(0xFFD50000),
      gradientColors: [Color(0xFFFF5252), Color(0xFFD50000), Color(0xFF8A0000)],
      borderColor: Color(0xFFFF8A80),
      shadowColor: Color(0xFF560000),
    ),
    CandyLetterStyle(
      primaryColor: Color(0xFFF50057),
      gradientColors: [Color(0xFFFF4081), Color(0xFFF50057), Color(0xFF880E4F)],
      borderColor: Color(0xFFFF80AB),
      shadowColor: Color(0xFF560027),
    ),
    CandyLetterStyle(
      primaryColor: Color(0xFF00BFA5),
      gradientColors: [Color(0xFF1DE9B6), Color(0xFF00BFA5), Color(0xFF004D40)],
      borderColor: Color(0xFFA7FFEB),
      shadowColor: Color(0xFF00251A),
    ),
  ];

  /// Get the full visual style for a Tamil letter.
  /// Always returns the exact same style for the same letter.
  static CandyLetterStyle getStyleForLetter(String letter) {
    if (letterStyles.containsKey(letter)) {
      return letterStyles[letter]!;
    }
    // Stable deterministic fallback for any unseen Tamil letter
    final hash = letter.runes.fold<int>(0, (prev, rune) => (prev * 31 + rune) & 0x7FFFFFFF);
    final idx = hash % dynamicPalette.length;
    return dynamicPalette[idx];
  }

  /// Get gradient, border, and shadow tokens for tile rendering (backward-compatible record)
  static (List<Color>, Color, Color) getColorForLetter(String letter) {
    final style = getStyleForLetter(letter);
    return (style.gradientColors, style.borderColor, style.shadowColor);
  }

  /// Get dedicated primary color for a letter
  static Color getPrimaryColorForLetter(String letter) {
    if (letterColors.containsKey(letter)) {
      return letterColors[letter]!;
    }
    return getStyleForLetter(letter).primaryColor;
  }
}

