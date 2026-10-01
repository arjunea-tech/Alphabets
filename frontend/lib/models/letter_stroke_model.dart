import 'dart:ui';

/// Type aliases for reusable architecture
typedef WritingStroke = LetterStrokeData;
typedef WritingLetterTemplate = TamilWritingLetter;

/// Represents a single directional stroke in a Tamil letter with full geometry data
class LetterStrokeData {
  final int strokeNumber;
  final String title;
  final String instruction;
  final Offset startPoint; // Normalized (0.0 to 1.0)
  final Offset? endPoint; // Normalized (0.0 to 1.0)
  final List<Offset> pathPoints; // Normalized waypoints along the stroke
  final double tolerance; // Normalized tolerance radius (default 0.12)
  final String directionHint; // 'loop_cw', 'loop_ccw', 'right', 'down', etc.
  final bool isDot; // For pulli (dots)

  const LetterStrokeData({
    required this.strokeNumber,
    required this.title,
    required this.instruction,
    required this.startPoint,
    this.endPoint,
    required this.pathPoints,
    this.tolerance = 0.12,
    this.directionHint = 'down',
    this.isDot = false,
  });

  Offset get effectiveEndPoint => endPoint ?? (pathPoints.isNotEmpty ? pathPoints.last : startPoint);

  Map<String, dynamic> toJson() => {
        'strokeNumber': strokeNumber,
        'title': title,
        'instruction': instruction,
        'startPoint': {'x': startPoint.dx, 'y': startPoint.dy},
        'endPoint': {'x': effectiveEndPoint.dx, 'y': effectiveEndPoint.dy},
        'pathPoints': pathPoints.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
        'tolerance': tolerance,
        'directionHint': directionHint,
        'isDot': isDot,
      };

  factory LetterStrokeData.fromJson(Map<String, dynamic> json) {
    final startJson = json['startPoint'] as Map<String, dynamic>;
    final endJson = json['endPoint'] as Map<String, dynamic>?;
    final rawPoints = json['pathPoints'] as List<dynamic>? ?? [];
    return LetterStrokeData(
      strokeNumber: json['strokeNumber'] as int? ?? 1,
      title: json['title'] as String? ?? '',
      instruction: json['instruction'] as String? ?? '',
      startPoint: Offset(
        (startJson['x'] as num).toDouble(),
        (startJson['y'] as num).toDouble(),
      ),
      endPoint: endJson != null
          ? Offset(
              (endJson['x'] as num).toDouble(),
              (endJson['y'] as num).toDouble(),
            )
          : null,
      pathPoints: rawPoints
          .map((p) => Offset(
                ((p as Map<String, dynamic>)['x'] as num).toDouble(),
                (p['y'] as num).toDouble(),
              ))
          .toList(),
      tolerance: (json['tolerance'] as num?)?.toDouble() ?? 0.12,
      directionHint: json['directionHint'] as String? ?? 'down',
      isDot: json['isDot'] as bool? ?? false,
    );
  }
}

/// Structural validation rules for letter correctness recognition
class LetterValidationRule {
  final bool requireRightVerticalStem;
  final bool requireTopLeftLoop;
  final bool requireBottomWave;
  final bool requireBaseBar;
  final bool requireDot;
  final double minCoverage;
  final double minPrecision;

  const LetterValidationRule({
    this.requireRightVerticalStem = false,
    this.requireTopLeftLoop = false,
    this.requireBottomWave = false,
    this.requireBaseBar = false,
    this.requireDot = false,
    this.minCoverage = 0.50,
    this.minPrecision = 0.45,
  });

  Map<String, dynamic> toJson() => {
        'requireRightVerticalStem': requireRightVerticalStem,
        'requireTopLeftLoop': requireTopLeftLoop,
        'requireBottomWave': requireBottomWave,
        'requireBaseBar': requireBaseBar,
        'requireDot': requireDot,
        'minCoverage': minCoverage,
        'minPrecision': minPrecision,
      };

  factory LetterValidationRule.fromJson(Map<String, dynamic> json) {
    return LetterValidationRule(
      requireRightVerticalStem: json['requireRightVerticalStem'] as bool? ?? false,
      requireTopLeftLoop: json['requireTopLeftLoop'] as bool? ?? false,
      requireBottomWave: json['requireBottomWave'] as bool? ?? false,
      requireBaseBar: json['requireBaseBar'] as bool? ?? false,
      requireDot: json['requireDot'] as bool? ?? false,
      minCoverage: (json['minCoverage'] as num?)?.toDouble() ?? 0.50,
      minPrecision: (json['minPrecision'] as num?)?.toDouble() ?? 0.45,
    );
  }
}

/// Complete stroke definition and vector representation for a Tamil letter
class TamilWritingLetter {
  final String letter;
  final String category; // 'uyir', 'mei', 'aytham', 'uyirmei'
  final String sampleWord;
  final String sampleEmoji;
  final List<LetterStrokeData> strokes;
  final LetterValidationRule validationRule;

  const TamilWritingLetter({
    required this.letter,
    required this.category,
    required this.sampleWord,
    required this.sampleEmoji,
    required this.strokes,
    this.validationRule = const LetterValidationRule(),
  });

  int get totalStrokes => strokes.length;

  Map<String, dynamic> toJson() => {
        'letter': letter,
        'category': category,
        'sampleWord': sampleWord,
        'sampleEmoji': sampleEmoji,
        'strokes': strokes.map((s) => s.toJson()).toList(),
        'validationRule': validationRule.toJson(),
      };

  factory TamilWritingLetter.fromJson(Map<String, dynamic> json) {
    final rawStrokes = json['strokes'] as List<dynamic>? ?? [];
    return TamilWritingLetter(
      letter: json['letter'] as String? ?? '',
      category: json['category'] as String? ?? 'uyir',
      sampleWord: json['sampleWord'] as String? ?? '',
      sampleEmoji: json['sampleEmoji'] as String? ?? '📝',
      strokes: rawStrokes
          .map((s) => LetterStrokeData.fromJson(s as Map<String, dynamic>))
          .toList(),
      validationRule: json['validationRule'] != null
          ? LetterValidationRule.fromJson(
              json['validationRule'] as Map<String, dynamic>)
          : const LetterValidationRule(),
    );
  }
}

/// Evaluation result model
class HandwritingEvaluationResult {
  final double score; // 0.0 to 100.0
  final double coverage; // 0.0 to 1.0
  final double precision; // 0.0 to 1.0
  final int stars; // 0 to 3
  final bool isPass;
  final String title;
  final String message;
  final String emoji;
  final Color badgeColor;

  const HandwritingEvaluationResult({
    required this.score,
    required this.coverage,
    required this.precision,
    required this.stars,
    required this.isPass,
    required this.title,
    required this.message,
    required this.emoji,
    required this.badgeColor,
  });
}
