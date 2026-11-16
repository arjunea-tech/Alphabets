import 'dart:math';

import 'game_item_model.dart';
import 'letter_model.dart';

/// Everything a game screen needs to play, built from what the admin added.
///
/// Game screens contain no hardcoded content: missions, target letters/words
/// and distractors all come from [game]'s levels. [adminLetters] (the letters
/// managed in the admin panel) is used only to attach images/audio/words to
/// single-letter targets.
class GameContent {
  final GameItem game;
  final List<GameLevel> levels;
  final List<LetterModel> adminLetters;

  /// Index of the level being played when the child picked one level from the
  /// level-select screen; null when the game plays all levels together.
  final int? levelIndex;

  GameContent({required this.game, required this.adminLetters})
      : levels = game.playableLevels,
        levelIndex = null;

  /// Content for just one level ([index] into [GameItem.playableLevels]).
  GameContent.forLevel({required this.game, required this.adminLetters, required int index})
      : levels = [game.playableLevels[index]],
        levelIndex = index;

  /// Speed multiplier from the level's difficulty (1.0 easy, 1.3 medium,
  /// 1.6 hard). 1.0 when several levels are played together.
  double get speedFactor => levelIndex == null ? 1.0 : levels.first.speedFactor;

  /// Every picked level asks this many questions (rounds / gates / pops /
  /// correct cuts) before it is complete — the same in every game.
  static const int questionsPerLevel = 5;

  /// True while playing one level picked from the level-select screen.
  bool get isLevelMode => levelIndex != null;

  /// A picked level that has another level after it.
  bool get hasNextLevel => levelIndex != null && levelIndex! + 1 < game.playableLevels.length;

  /// Rounds for a game that asks one target per round. In level mode this is
  /// exactly [questionsPerLevel] rounds: the targets shuffled, repeated when
  /// there are fewer than 5 (e.g. a level with only O and U → O U U O U).
  /// Outside level mode the targets are shuffled and capped at [maxRounds].
  List<T> roundsFrom<T>(List<T> targets, Random rng, {int maxRounds = 10}) {
    if (targets.isEmpty) return [];
    if (!isLevelMode) {
      final all = List<T>.from(targets)..shuffle(rng);
      return all.length > maxRounds ? all.sublist(0, maxRounds) : all;
    }
    final rounds = <T>[];
    while (rounds.length < questionsPerLevel) {
      rounds.addAll(List<T>.from(targets)..shuffle(rng));
    }
    return rounds.sublist(0, questionsPerLevel);
  }

  bool get isEmpty => levels.isEmpty;

  GameLevel levelAt(int index) => levels[index.clamp(0, levels.length - 1)];

  /// Every target across all levels, in order, without duplicates.
  List<String> get allTargets {
    final seen = <String>{};
    return [
      for (final l in levels)
        for (final t in l.targets)
          if (seen.add(t.toUpperCase())) t,
    ];
  }

  /// Every distractor across all levels, without duplicates or overlap with targets.
  List<String> get allDistractors {
    final targets = allTargets.map((t) => t.toUpperCase()).toSet();
    final seen = <String>{};
    return [
      for (final l in levels)
        for (final d in l.distractors)
          if (!targets.contains(d.toUpperCase()) && seen.add(d.toUpperCase())) d,
    ];
  }

  /// Resolves a target string to the admin's letter record (for image/audio),
  /// or wraps it as a plain letter/word model when the admin has no such letter.
  LetterModel letterFor(String text) {
    final key = text.trim().toUpperCase();
    for (final l in adminLetters) {
      if (l.letter.trim().toUpperCase() == key) return l;
    }
    return LetterModel(
      id: 'game_${game.id}_$key',
      letter: text.trim(),
      type: LetterType.english,
      word: '',
      meaning: '',
      phonetic: '',
      iconEmoji: '⭐',
    );
  }

  /// Wrong answers for [level]: the admin's distractors, or — when none were
  /// entered — other admin content (other levels, then admin letters) that is
  /// not one of this level's targets.
  List<String> distractorsFor(GameLevel level) {
    if (level.distractors.isNotEmpty) return level.distractors;
    final targetKeys = level.targets.map((t) => t.toUpperCase()).toSet();
    final seen = <String>{};
    final pool = [
      ...allDistractors,
      ...allTargets,
      ...adminLetters.map((l) => l.letter),
    ];
    return [
      for (final p in pool)
        if (!targetKeys.contains(p.toUpperCase()) && seen.add(p.toUpperCase())) p,
    ];
  }

  List<LetterModel> lettersFor(Iterable<String> texts) => texts.map(letterFor).toList();

  List<LetterModel> get targetLetters => lettersFor(allTargets);

  List<LetterModel> get distractorLetters => lettersFor(allDistractors);

  /// Targets plus every level's wrong answers — the pool games draw "other"
  /// items from when they need several wrong choices next to the target.
  List<LetterModel> get mixPoolLetters {
    final seen = <String>{};
    final texts = [
      ...allTargets,
      for (final l in levels) ...distractorsFor(l),
    ].where((t) => seen.add(t.toUpperCase()));
    return lettersFor(texts);
  }
}
