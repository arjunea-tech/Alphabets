import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tamil/models/game_content.dart';
import 'package:tamil/models/game_item_model.dart';
import 'package:tamil/models/user_progress_model.dart';
import 'package:tamil/services/progress_service.dart';

GameItem _game() => GameItem.fromJson({
      'id': 'g1',
      'game_type': 'balloon',
      'title': 'Balloon Pop',
      'prompt': 'Pop!',
      'levels': [
        {'title': 'Vowels', 'targets': ['A', 'E']},
        {'title': 'B-D', 'targets': ['B', 'C', 'D'], 'difficulty': 'easy'},
        {'title': 'Words', 'targets': ['CAT']},
      ],
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('difficulty defaults by position, explicit value wins', () {
    final levels = _game().playableLevels;
    expect(levels.map((l) => l.difficulty), ['easy', 'easy', 'hard']);
    expect(levels[2].speedFactor, 1.6);
  });

  test('every game gets at least 3 levels', () {
    GameItem one(List<String> targets) => GameItem.fromJson({
          'id': 'x',
          'game_type': 'fishing',
          'title': 'Fishing',
          'prompt': 'p',
          'levels': [
            {'title': 'Vowels', 'targets': targets},
          ],
        });
    final split = one(['A', 'E', 'I', 'O', 'U']).playableLevels;
    expect(split.map((l) => l.targets.join()), ['AEI', 'OU', 'AEIOU']);
    expect(split.map((l) => l.difficulty), ['easy', 'medium', 'hard']);
    expect(split.first.title, 'Vowels — Part 1');

    expect(one(['A']).playableLevels.map((l) => l.targets.join()), ['A', 'A', 'A']);

    final two = GameItem.fromJson({
      'id': 'y',
      'game_type': 'basket',
      'title': 'Basket',
      'prompt': 'p',
      'levels': [
        {'targets': ['A', 'B']},
        {'targets': ['b', 'C']},
      ],
    }).playableLevels;
    expect(two.length, 3);
    expect(two.last.targets, ['A', 'B', 'C']);
    expect(two.last.difficulty, 'hard');

    // Old games with only `options` also get 3 levels.
    final old = GameItem.fromJson({
      'id': 'z',
      'game_type': 'balloon',
      'title': 'Old',
      'prompt': 'p',
      'options': ['A', 'B', 'C', 'D'],
    }).playableLevels;
    expect(old.map((l) => l.targets.join()), ['AB', 'CD', 'ABCD']);

    // 3+ levels are left alone.
    expect(_game().playableLevels.map((l) => l.title), ['Vowels', 'B-D', 'Words']);
  });

  test('a picked level always asks exactly 5 questions', () {
    final rng = Random(1);
    final level = GameContent.forLevel(game: _game(), adminLetters: const [], index: 0); // targets A, E
    final rounds = level.roundsFrom(['A', 'E'], rng);
    expect(rounds.length, GameContent.questionsPerLevel);
    expect(rounds.toSet(), {'A', 'E'});
    expect(level.roundsFrom('ABCDEFGHIJ'.split(''), rng).length, 5);
    expect(level.hasNextLevel, isTrue);
    expect(GameContent.forLevel(game: _game(), adminLetters: const [], index: 2).hasNextLevel, isFalse);

    // Whole game (no level picked): every target once, capped at 10.
    final whole = GameContent(game: _game(), adminLetters: const []);
    expect(whole.roundsFrom(['A', 'B', 'C'], rng).length, 3);
    expect(whole.roundsFrom('ABCDEFGHIJKLMN'.split(''), rng).length, 10);
    expect(whole.hasNextLevel, isFalse);
  });

  test('GameContent.forLevel plays only that level', () {
    final c = GameContent.forLevel(game: _game(), adminLetters: const [], index: 2);
    expect(c.levels.single.title, 'Words');
    expect(c.allTargets, ['CAT']);
    expect(c.speedFactor, 1.6);
    expect(GameContent(game: _game(), adminLetters: const []).speedFactor, 1.0);
  });

  test('levels unlock one by one, only on a win, and survive a reload', () async {
    SharedPreferences.setMockInitialValues({});
    final p = ProgressService();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(p.isGameLevelUnlocked('g1', 0), isTrue);
    expect(p.isGameLevelUnlocked('g1', 1), isFalse);

    // Exiting / losing must not unlock anything.
    p.startGameLevel('g1', 0);
    p.recordGameCompleted(1);
    expect(p.isGameLevelUnlocked('g1', 1), isFalse);

    p.completeActiveGameLevel();
    expect(p.isGameLevelUnlocked('g1', 1), isTrue);
    expect(p.isGameLevelUnlocked('g1', 2), isFalse);

    // Replaying an earlier level never re-locks later ones.
    p.startGameLevel('g1', 1);
    p.completeActiveGameLevel();
    p.startGameLevel('g1', 0);
    p.completeActiveGameLevel();
    expect(p.completedGameLevels('g1'), 2);

    final saved = UserProgressModel.fromJson(UserProgressModel(gameLevelsCompleted: {'g1': 2}).toJson());
    expect(saved.gameLevelsCompleted['g1'], 2);
  });
}
