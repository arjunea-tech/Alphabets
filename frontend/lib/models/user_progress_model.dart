class UserProgressModel {
  final int stars;
  final List<String> completedLetterIds;
  final int completedStories;
  final int quizHighScore;
  final int gamesPlayed;
  final String childName;
  final int avatarIndex;
  final bool soundEnabled;

  const UserProgressModel({
    this.stars = 15,
    this.completedLetterIds = const [],
    this.completedStories = 0,
    this.quizHighScore = 0,
    this.gamesPlayed = 0,
    this.childName = 'Kid',
    this.avatarIndex = 0,
    this.soundEnabled = true,
  });

  UserProgressModel copyWith({
    int? stars,
    List<String>? completedLetterIds,
    int? completedStories,
    int? quizHighScore,
    int? gamesPlayed,
    String? childName,
    int? avatarIndex,
    bool? soundEnabled,
  }) {
    return UserProgressModel(
      stars: stars ?? this.stars,
      completedLetterIds: completedLetterIds ?? this.completedLetterIds,
      completedStories: completedStories ?? this.completedStories,
      quizHighScore: quizHighScore ?? this.quizHighScore,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      childName: childName ?? this.childName,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'stars': stars,
        'completedLetterIds': completedLetterIds,
        'completedStories': completedStories,
        'quizHighScore': quizHighScore,
        'gamesPlayed': gamesPlayed,
        'childName': childName,
        'avatarIndex': avatarIndex,
        'soundEnabled': soundEnabled,
      };

  factory UserProgressModel.fromJson(Map<String, dynamic> json) {
    return UserProgressModel(
      stars: json['stars'] as int? ?? 15,
      completedLetterIds: (json['completedLetterIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      completedStories: json['completedStories'] as int? ?? 0,
      quizHighScore: json['quizHighScore'] as int? ?? 0,
      gamesPlayed: json['gamesPlayed'] as int? ?? 0,
      childName: json['childName'] as String? ?? 'Kid',
      avatarIndex: json['avatarIndex'] as int? ?? 0,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
    );
  }
}
