class QuizQuestion {
  final String id;
  final String categoryId;
  final String question;
  final String? visualHint;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    required this.id,
    required this.categoryId,
    required this.question,
    this.visualHint,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  /// Parses a question from the backend `/quizzes/:id/play` response.
  factory QuizQuestion.fromJson(Map<String, dynamic> json, String quizId) {
    final rawOptions = (json['options'] as List?) ?? const [];
    final options = <String>[];
    var correctIndex = 0;
    for (var i = 0; i < rawOptions.length; i++) {
      final opt = rawOptions[i];
      if (opt is Map) {
        options.add((opt['optionText'] ?? opt['option_text'] ?? '').toString());
        final correct = opt['isCorrect'] ?? opt['is_correct'];
        if (correct == true || correct == 1 || correct == '1') correctIndex = i;
      } else {
        options.add(opt.toString());
      }
    }
    final hint = (json['visualHint'] ?? json['visual_hint'])?.toString();
    return QuizQuestion(
      id: json['id']?.toString() ?? '',
      categoryId: quizId,
      question: (json['question'] ?? json['question_text'] ?? '').toString(),
      visualHint: (hint == null || hint.isEmpty) ? null : hint,
      options: options,
      correctIndex: correctIndex,
      explanation: (json['explanation'] ?? '').toString(),
    );
  }
}

class QuizCategory {
  final String id;
  final String title;
  final String subtitle;
  final String iconEmoji;
  final int questionCount;

  const QuizCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.iconEmoji,
    required this.questionCount,
  });

  /// Parses a quiz from the backend `/quizzes` list response.
  factory QuizCategory.fromJson(Map<String, dynamic> json) {
    final count = json['actual_question_count'] ?? json['question_count'] ?? 0;
    return QuizCategory(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      iconEmoji: json['icon_emoji']?.toString() ?? '❓',
      questionCount: count is int ? count : int.tryParse(count.toString()) ?? 0,
    );
  }
}
