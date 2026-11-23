import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/game_content.dart';
import '../../models/game_item_model.dart';
import '../../services/progress_service.dart';
import '../../widgets/bouncy_button.dart';
import 'mini_game_kit.dart';

/// Letter Train: a train of letter wagons arrives with one wagon missing.
/// The child picks the letter that comes in that spot. The order comes from
/// the level's targets as the admin typed them (e.g. A, B, C, D, E).
class LetterTrainGame extends StatefulWidget {
  final ProgressService progressService;
  final GameContent content;

  const LetterTrainGame({
    super.key,
    required this.progressService,
    required this.content,
  });

  @override
  State<LetterTrainGame> createState() => _LetterTrainGameState();
}

class _TrainRound {
  final GameLevel level;
  final List<String> wagons;
  final int missing;
  final List<String> options;

  /// The word the train spells (word levels only).
  final String? word;

  const _TrainRound({
    required this.level,
    required this.wagons,
    required this.missing,
    required this.options,
    this.word,
  });

  String get answer => wagons[missing];
}

class _LetterTrainGameState extends State<LetterTrainGame> {
  static const Color _color = Color(0xFFDC2626);
  static const Duration _driveTime = Duration(milliseconds: 900);
  static const List<Color> _wagonColors = [
    Color(0xFF3B82F6),
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
    Color(0xFFA855F7),
    Color(0xFFEC4899),
  ];

  final math.Random _rng = math.Random();
  late List<_TrainRound> _rounds;
  int _roundIndex = 0;
  int _mistakes = 0;
  bool _filled = false;
  bool _busy = false;
  String? _wrongPick;
  double _trainX =
      0; // slide offset: -1.6 (off left) .. 0 (centre) .. 1.6 (off right)
  bool _animateTrain = true;
  String _state = 'playing';
  bool _showQ = false; // question popup visible (train waits)
  final List<Timer> _timers = [];

  _TrainRound get _round => _rounds[_roundIndex.clamp(0, _rounds.length - 1)];

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  void _later(Duration d, VoidCallback fn) {
    _timers.add(
      Timer(d, () {
        if (mounted) fn();
      }),
    );
  }

  void _start() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    _rounds = _buildRounds();
    setState(() {
      _roundIndex = 0;
      _mistakes = 0;
      _filled = false;
      _busy = false;
      _wrongPick = null;
      _showQ = _rounds.isNotEmpty;
      _state = _rounds.isEmpty ? 'won' : 'playing';
    });
    if (!_showQ) _driveIn();
  }

  /// A level whose targets are words (CAT, DOG…) spells one word per train.
  static bool _isWordLevel(GameLevel level) =>
      level.targets.any((t) => t.trim().characters.length > 1);

  /// Pictures for the simple words used in the seeded word levels.
  static const Map<String, String> _wordEmoji = {
    'CAT': '🐱',
    'DOG': '🐶',
    'SUN': '☀️',
    'BUS': '🚌',
    'CUP': '☕',
    'HAT': '🎩',
    'PEN': '🖊️',
    'BAT': '🦇',
    'COW': '🐮',
    'PIG': '🐷',
    'EGG': '🥚',
    'BED': '🛏️',
    'BALL': '⚽',
    'FISH': '🐟',
    'CAKE': '🎂',
    'DUCK': '🦆',
    'FROG': '🐸',
    'STAR': '⭐',
    'TREE': '🌳',
    'BOOK': '📖',
    'MOON': '🌙',
    'LION': '🦁',
    'BIRD': '🐦',
    'BEAR': '🐻',
    'APPLE': '🍎',
    'TRAIN': '🚂',
    'HOUSE': '🏠',
    'ZEBRA': '🦓',
    'TIGER': '🐯',
  };

  List<_TrainRound> _buildRounds() {
    final content = widget.content;
    final rounds = <_TrainRound>[];
    for (final level in content.levels) {
      if (_isWordLevel(level)) {
        rounds.addAll(_buildWordRounds(level));
        continue;
      }
      final seq = level.targets;
      if (seq.isEmpty) continue;
      final count = content.isLevelMode
          ? GameContent.questionsPerLevel
          : math.min(3, seq.length);
      int? lastAnswerIndex;
      for (var i = 0; i < count; i++) {
        final len = math.min(4, seq.length);
        final start = _rng.nextInt(seq.length - len + 1);
        var missing = _rng.nextInt(len);
        // Avoid asking the exact same letter twice in a row when possible.
        if (len > 1 && start + missing == lastAnswerIndex) {
          missing = (missing + 1) % len;
        }
        lastAnswerIndex = start + missing;
        final wagons = seq.sublist(start, start + len);
        rounds.add(
          _TrainRound(
            level: level,
            wagons: wagons,
            missing: missing,
            options: _optionsFor(level, wagons, wagons[missing]),
          ),
        );
      }
    }
    return rounds;
  }

  List<_TrainRound> _buildWordRounds(GameLevel level) {
    final words = level.targets
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final rounds = <_TrainRound>[];
    for (final word in widget.content.roundsFrom(words, _rng, maxRounds: 3)) {
      final wagons = word.characters.toList();
      final missing = _rng.nextInt(wagons.length);
      final answer = wagons[missing];
      // Single letters only: admin distractors, letters of the other words, then A–Z.
      final pool = [
        ...wrongChoicesFor(widget.content, level),
        for (final w in words) ...w.characters,
        ...'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split(''),
      ].where((c) => c.characters.length == 1).toList()..shuffle(_rng);
      final seen = <String>{answer.toUpperCase()};
      final options = <String>[answer];
      for (final p in pool) {
        if (options.length >= 4) break;
        if (seen.add(p.toUpperCase())) options.add(p);
      }
      rounds.add(
        _TrainRound(
          level: level,
          wagons: wagons,
          missing: missing,
          options: options..shuffle(_rng),
          word: word,
        ),
      );
    }
    return rounds;
  }

  List<String> _optionsFor(
    GameLevel level,
    List<String> wagons,
    String answer,
  ) {
    final seen = <String>{answer.toUpperCase()};
    final pool = [
      ...level.targets.where((t) => !wagons.contains(t)),
      ...wrongChoicesFor(widget.content, level),
      ...wagons,
    ]..shuffle(_rng);
    final options = <String>[answer];
    for (final p in pool) {
      if (options.length >= 4) break;
      if (seen.add(p.toUpperCase())) options.add(p);
    }
    return options..shuffle(_rng);
  }

  /// Train rolls in from the left.
  void _driveIn() {
    setState(() {
      _animateTrain = false;
      _trainX = -1.6;
    });
    _later(const Duration(milliseconds: 40), () {
      setState(() {
        _animateTrain = true;
        _trainX = 0;
      });
    });
  }

  void _onPick(String option) {
    if (_state != 'playing' || _showQ || _busy || _filled) return;
    if (option == _round.answer) {
      HapticFeedback.lightImpact();
      setState(() {
        _filled = true;
        _busy = true;
        _wrongPick = null;
      });
      // Pause on the full train, then chug away to the right.
      _later(const Duration(milliseconds: 700), () {
        setState(() => _trainX = 1.6);
        _later(_driveTime, _nextRound);
      });
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _mistakes++;
        _wrongPick = option;
      });
      _later(
        const Duration(milliseconds: 600),
        () => setState(() => _wrongPick = null),
      );
    }
  }

  void _nextRound() {
    if (_roundIndex + 1 >= _rounds.length) {
      rewardMiniGameWin(widget.progressService, widget.content);
      setState(() {
        _roundIndex = _rounds.length;
        _state = 'won';
      });
      return;
    }
    setState(() {
      _roundIndex++;
      _filled = false;
      _busy = false;
      if (promptFor(widget.content, _round.level) !=
          promptFor(widget.content, _rounds[_roundIndex - 1].level)) {
        _showQ = true;
      }
    });
    if (!_showQ) _driveIn();
  }

  @override
  Widget build(BuildContext context) {
    return QuestionPopupHost(
      show: _showQ && _state == 'playing' && _rounds.isNotEmpty,
      question: _rounds.isEmpty ? '' : promptFor(widget.content, _round.level),
      label: 'QUESTION ${_roundIndex + 1}/${_rounds.length}',
      hint: 'Pick the missing wagon for the train!',
      emoji: '🚂',
      onStart: () {
        setState(() => _showQ = false);
        _driveIn();
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF38BDF8), Color(0xFFBAE6FD), Color(0xFF86EFAC)],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    MiniGameHud(
                      title: widget.content.game.title,
                      done: _roundIndex.clamp(0, _rounds.length),
                      total: _rounds.length,
                      color: _color,
                    ),
                    if (_rounds.isNotEmpty)
                      MiniTargetBanner(
                        label: _round.word != null
                            ? 'Fill the word!'
                            : 'Which wagon is missing?',
                        target: _round.word != null
                            ? (_wordEmoji[_round.word!.toUpperCase()] ?? '🔤')
                            : '?',
                        prompt: promptFor(widget.content, _round.level),
                        color: _color,
                      ),
                    const Spacer(),
                    if (_rounds.isNotEmpty) _buildTrack(),
                    const Spacer(),
                    if (_rounds.isNotEmpty) _buildOptions(),
                    const SizedBox(height: 24),
                  ],
                ),
                if (_state != 'playing')
                  Positioned.fill(
                    child: MiniGameEndOverlay(
                      won: true,
                      message: _mistakes == 0
                          ? 'Perfect! Every train is full! 🚂'
                          : 'All trains are full! ($_mistakes oops)',
                      content: widget.content,
                      onReplay: _start,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrack() {
    final round = _round;
    return LayoutBuilder(
      builder: (context, c) {
        final count = round.wagons.length;
        final wagonW = ((c.maxWidth - 24 - count * 6) / (count + 1.4)).clamp(
          36.0,
          88.0,
        );
        return SizedBox(
          height: wagonW * 1.35 + 20,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Rails
              Positioned(
                left: 0,
                right: 0,
                bottom: 6,
                child: Container(height: 6, color: const Color(0xFF57534E)),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Row(
                  children: List.generate(
                    24,
                    (_) => Expanded(
                      child: Container(
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: AnimatedSlide(
                  offset: Offset(_trainX, 0),
                  duration: _animateTrain ? _driveTime : Duration.zero,
                  curve: _trainX > 0 ? Curves.easeIn : Curves.easeOutCubic,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (var i = 0; i < count; i++) ...[
                            _buildWagon(round, i, wagonW),
                            Container(
                              width: 6,
                              height: 4,
                              color: const Color(0xFF44403C),
                              margin: const EdgeInsets.only(bottom: 16),
                            ),
                          ],
                          // Engine at the front, facing right
                          SizedBox(
                            width: wagonW * 1.3,
                            height: wagonW * 1.2,
                            child: Transform.flip(
                              flipX: true,
                              child: const FittedBox(child: Text('🚂')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWagon(_TrainRound round, int i, double w) {
    final isGap = i == round.missing && !_filled;
    final color = _wagonColors[i % _wagonColors.length];
    final label = isGap ? '?' : round.wagons[i];
    return SizedBox(
      width: w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: w * 1.0,
            decoration: BoxDecoration(
              color: isGap ? Colors.white.withValues(alpha: 0.7) : color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isGap ? _color : Color.lerp(color, Colors.black, 0.3)!,
                width: isGap ? 3 : 2,
              ),
              boxShadow: (i == round.missing && _filled)
                  ? [
                      const BoxShadow(
                        color: Color(0xFFFFD166),
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: isGap ? _color : Colors.white,
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [_wheel(w), _wheel(w)],
          ),
        ],
      ),
    );
  }

  Widget _wheel(double w) => Container(
    width: w * 0.26,
    height: w * 0.26,
    decoration: BoxDecoration(
      color: const Color(0xFF1F2937),
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0xFF9CA3AF), width: 2),
    ),
  );

  Widget _buildOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final o in _round.options)
            BouncyButton(
              onPressed: () => _onPick(o),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                constraints: const BoxConstraints(minWidth: 72),
                height: 72,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _wrongPick == o
                      ? const Color(0xFFEF4444)
                      : (_filled && o == _round.answer
                            ? const Color(0xFF22C55E)
                            : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.15),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  o,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: (_wrongPick == o || (_filled && o == _round.answer))
                        ? Colors.white
                        : const Color(0xFF1E293B),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
