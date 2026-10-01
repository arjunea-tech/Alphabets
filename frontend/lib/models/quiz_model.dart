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
}
