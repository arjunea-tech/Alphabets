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

  /// 'easy', 'medium' or 'hard' (set per level in the admin panel). Controls
  /// how fast the game plays — see [speedFactor].
  final String difficulty;

  const GameLevel({
    required this.title,
    required this.prompt,
    required this.targets,
    this.distractors = const [],
    this.difficulty = 'easy',
  });

  /// Speed multiplier for falling / flying / moving items in a game.
  double get speedFactor {
    switch (difficulty) {
      case 'hard':
        return 1.6;
      case 'medium':
        return 1.3;
      default:
        return 1.0;
    }
  }

  /// [index] is the level's position, used as the default difficulty for
  /// levels saved before difficulty existed (1st easy, 2nd medium, 3rd+ hard).
  factory GameLevel.fromJson(Map<String, dynamic> json, [int index = 0]) {
    const known = ['easy', 'medium', 'hard'];
    final raw = json['difficulty']?.toString().trim().toLowerCase() ?? '';
    return GameLevel(
      title: json['title']?.toString() ?? '',
      prompt: json['prompt']?.toString() ?? '',
      targets: _toStringList(json['targets']),
      distractors: _toStringList(json['distractors']),
      difficulty: known.contains(raw) ? raw : known[index.clamp(0, known.length - 1)],
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
    if (withTargets.isNotEmpty) return ensureMinLevels(withTargets, title);
    if (options.isNotEmpty) {
      return ensureMinLevels([GameLevel(title: title, prompt: prompt, targets: options)], title);
    }
    return const [];
  }

  /// Every game offers at least this many levels (easy → medium → hard).
  static const int minLevels = 3;

  /// Tops [levels] up to [minLevels] — same rule as the backend
  /// (backend/src/models/gameModel.js ensureMinLevels), so the app still shows
  /// 3 levels when talking to a server that doesn't do it yet:
  ///   1 level  → Part 1 (first half of its targets, easy), Part 2 (second
  ///              half, medium), All (every target, hard). Fewer than 2
  ///              targets → the same targets three times, only faster.
  ///   2 levels → kept, plus a 3rd "All Together" level (hard).
  static List<GameLevel> ensureMinLevels(List<GameLevel> levels, String gameTitle) {
    if (levels.isEmpty || levels.length >= minLevels) return levels;
    const difficulties = ['easy', 'medium', 'hard'];

    if (levels.length == 1) {
      final base = levels.first;
      final name = base.title.isNotEmpty ? base.title : (gameTitle.isNotEmpty ? gameTitle : 'Level');
      final t = base.targets;
      final half = (t.length / 2).ceil();
      final parts = t.length >= 2 ? [t.sublist(0, half), t.sublist(half), t] : [t, t, t];
      const suffixes = ['Part 1', 'Part 2', 'All'];
      return [
        for (var i = 0; i < 3; i++)
          GameLevel(
            title: '$name — ${suffixes[i]}',
            prompt: base.prompt,
            targets: parts[i],
            distractors: base.distractors,
            difficulty: difficulties[i],
          ),
      ];
    }

    List<String> dedupe(Iterable<String> items) {
      final seen = <String>{};
      return [for (final v in items) if (seen.add(v.toUpperCase())) v];
    }

    return [
      ...levels,
      GameLevel(
        title: 'All Together',
        prompt: levels.first.prompt,
        targets: dedupe([...levels[0].targets, ...levels[1].targets]),
        distractors: dedupe([...levels[0].distractors, ...levels[1].distractors]),
        difficulty: 'hard',
      ),
    ];
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
      final maps = decodedLevels.whereType<Map>().toList();
      parsedLevels = [
        for (var i = 0; i < maps.length; i++) GameLevel.fromJson(Map<String, dynamic>.from(maps[i]), i),
      ];
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
