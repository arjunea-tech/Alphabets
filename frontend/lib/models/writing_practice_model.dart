import 'dart:convert';

/// Represents a single point in a stroke with normalized coordinates (0.0 to 1.0)
/// so it can be rendered accurately at any size/resolution.
class WritingPoint {
  final double x;
  final double y;
  final bool isEndOfStroke;

  const WritingPoint({
    required this.x,
    required this.y,
    this.isEndOfStroke = false,
  });

  Map<String, dynamic> toJson() => {
        'x': double.parse(x.toStringAsFixed(4)),
        'y': double.parse(y.toStringAsFixed(4)),
        'e': isEndOfStroke ? 1 : 0,
      };

  factory WritingPoint.fromJson(Map<String, dynamic> json) => WritingPoint(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        isEndOfStroke: (json['e'] ?? 0) == 1,
      );
}

/// Model storing a child's complete writing practice attempt
class WritingPractice {
  final String id;
  final String letter;
  final String category; // 'uyir', 'mei', 'uyirmei'
  final List<List<WritingPoint>> strokes;
  final DateTime createdAt;
  final int attemptNumber;
  final bool completed;

  const WritingPractice({
    required this.id,
    required this.letter,
    required this.category,
    required this.strokes,
    required this.createdAt,
    required this.attemptNumber,
    this.completed = true,
  });

  int get totalPointsCount =>
      strokes.fold(0, (sum, stroke) => sum + stroke.length);

  Map<String, dynamic> toJson() => {
        'id': id,
        'letter': letter,
        'category': category,
        'strokes': strokes
            .map((stroke) => stroke.map((p) => p.toJson()).toList())
            .toList(),
        'createdAt': createdAt.toIso8601String(),
        'attemptNumber': attemptNumber,
        'completed': completed,
      };

  factory WritingPractice.fromJson(Map<String, dynamic> json) {
    var rawStrokes = json['strokes'] as List<dynamic>? ?? [];
    List<List<WritingPoint>> parsedStrokes = rawStrokes.map((s) {
      return (s as List<dynamic>)
          .map((p) => WritingPoint.fromJson(p as Map<String, dynamic>))
          .toList();
    }).toList();

    return WritingPractice(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      letter: json['letter'] as String? ?? '',
      category: json['category'] as String? ?? 'uyir',
      strokes: parsedStrokes,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      attemptNumber: json['attemptNumber'] as int? ?? 1,
      completed: json['completed'] as bool? ?? true,
    );
  }

  static String listToJson(List<WritingPractice> list) =>
      jsonEncode(list.map((item) => item.toJson()).toList());

  static List<WritingPractice> listFromJson(String jsonString) {
    if (jsonString.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded
          .map((e) => WritingPractice.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
