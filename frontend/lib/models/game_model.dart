class GameQuestion {
  final String id;
  final String prompt;
  final String clue;
  final String? clueImage;
  final List<String> options;
  final int correctIndex;
  final String successPraise;

  const GameQuestion({
    required this.id,
    required this.prompt,
    required this.clue,
    this.clueImage,
    required this.options,
    required this.correctIndex,
    this.successPraise = 'சூப்பர்!',
  });
}
