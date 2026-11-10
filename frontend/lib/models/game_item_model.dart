import 'dart:convert';

/// One playable level / mission of a game, managed from the admin panel.
///
/// `targets` are the letters/words the child must pick (pop, slice, catch,
/// spell...). `distractors` are wrong answers mixed in by games that need them.
class GameLevel {
  final String title;
  final String prompt;
  final List<String> targets;
  final List<String> distractors;

  const GameLevel({
    required this.title,
    required this.prompt,
    required this.targets,
    this.distractors = const [],
  });

  factory GameLevel.fromJson(Map<String, dynamic> json) {
    return GameLevel(
      title: json['title']?.toString() ?? '',
      prompt: json['prompt']?.toString() ?? '',
      targets: _toStringList(json['targets']),
      distractors: _toStringList(json['distractors']),
    );
  }
}

List<String> _toStringList(dynamic raw) {
  if (raw is String) {
    try {
      raw = jsonDecode(raw);
    } catch (_) {
      return raw.toString().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
  }
  if (raw is List) {
    return raw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
  }
  return const [];
}

/// Educational Game Catalog Item (fetched dynamically from backend admin)
class GameItem {
  final String id;
  final String gameType;
  final String title;
  final String prompt;
  final String? clue;
  final String? clueImage;
  final int correctIndex;
  final List<String> options;
  final List<GameLevel> levels;
  final String successPraise;
  final int starsReward;
  final int displayOrder;
  final bool isActive;

  const GameItem({
    required this.id,
    required this.gameType,
    required this.title,
    required this.prompt,
    this.clue,
    this.clueImage,
    this.correctIndex = 0,
    this.options = const [],
    this.levels = const [],
    this.successPraise = 'Awesome! ⭐',
    this.starsReward = 5,
    this.displayOrder = 0,
    this.isActive = true,
  });

  /// Levels to play. Older records that only have `options` become a single level.
  List<GameLevel> get playableLevels {
    final withTargets = levels.where((l) => l.targets.isNotEmpty).toList();
    if (withTargets.isNotEmpty) return withTargets;
    if (options.isNotEmpty) {
      return [GameLevel(title: title, prompt: prompt, targets: options)];
    }
    return const [];
  }

  bool get hasContent => playableLevels.isNotEmpty;

  factory GameItem.fromJson(Map<String, dynamic> json) {
    final rawLevels = json['levels'] ?? json['levels_json'];
    List<GameLevel> parsedLevels = [];
    dynamic decodedLevels = rawLevels;
    if (rawLevels is String) {
      try {
        decodedLevels = jsonDecode(rawLevels);
      } catch (_) {
        decodedLevels = null;
      }
    }
    if (decodedLevels is List) {
      parsedLevels = decodedLevels
          .whereType<Map>()
          .map((e) => GameLevel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return GameItem(
      id: json['id']?.toString() ?? '',
      gameType: json['game_type']?.toString() ?? json['gameType']?.toString() ?? 'runner',
      title: json['title']?.toString() ?? '',
      prompt: json['prompt']?.toString() ?? '',
      clue: json['clue']?.toString(),
      clueImage: json['clue_image']?.toString() ?? json['clueImage']?.toString(),
      correctIndex: json['correct_index'] is int
          ? json['correct_index']
          : int.tryParse(json['correct_index']?.toString() ?? '0') ?? 0,
      options: _toStringList(json['options'] ?? json['options_json']),
      levels: parsedLevels,
      successPraise: json['success_praise']?.toString() ?? 'Awesome! ⭐',
      starsReward: json['stars_reward'] is int
          ? json['stars_reward']
          : int.tryParse(json['stars_reward']?.toString() ?? '5') ?? 5,
      displayOrder: json['display_order'] is int
          ? json['display_order']
          : int.tryParse(json['display_order']?.toString() ?? '0') ?? 0,
      isActive: json['is_active'] == true || json['is_active'] == 1 || json['is_active'] == '1',
    );
  }
}
