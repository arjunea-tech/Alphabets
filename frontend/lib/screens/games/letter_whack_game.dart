import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/game_content.dart';
import '../../services/progress_service.dart';
import 'mini_game_kit.dart';

/// Letter Whack-a-Mole: moles pop out of 9 holes holding letters. Tap the mole
/// with the target letter; tapping a wrong mole costs a heart.
class LetterWhackGame extends StatefulWidget {
  final ProgressService progressService;
  final GameContent content;

  const LetterWhackGame({
    super.key,
    required this.progressService,
    required this.content,
  });

  @override
  State<LetterWhackGame> createState() => _LetterWhackGameState();
}

class _Hole {
  String? letter;
  double timeLeft = 0;
  bool hit = false;
  bool wrongTap = false;

  bool get isUp => letter != null && timeLeft > 0;

  void clear() {
    letter = null;
    timeLeft = 0;
    hit = false;
    wrongTap = false;
  }
}

class _LetterWhackGameState extends State<LetterWhackGame> {
  static const Color _color = Color(0xFF65A30D);
  static const int _maxHearts = 5;

  final math.Random _rng = math.Random();
  final List<_Hole> _holes = List.generate(9, (_) => _Hole());
  late List<MiniRound> _rounds;
  Timer? _timer;

  int _roundIndex = 0;
  int _hearts = _maxHearts;
  int _spawnsSinceTarget = 0;
  double _spawnTimer = 0.5;
  String _state = 'playing'; // playing | won | lost
  bool _showQ = false; // question popup visible (game paused)
  String? _feedback;
  bool _feedbackGood = true;
  Timer? _feedbackTimer;

  double get _speed => widget.content.speedFactor;
  MiniRound get _round => _rounds[_roundIndex.clamp(0, _rounds.length - 1)];

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _feedbackTimer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    _rounds = buildMiniRounds(widget.content, _rng);
    for (final h in _holes) {
      h.clear();
    }
    setState(() {
      _roundIndex = 0;
      _hearts = _maxHearts;
      _spawnsSinceTarget = 0;
      _spawnTimer = 0.5;
      _showQ = _rounds.isNotEmpty;
      _state = _rounds.isEmpty ? 'won' : 'playing';
    });
    _timer = Timer.periodic(
      const Duration(milliseconds: 50),
      (_) => _tick(0.05),
    );
  }

  void _tick(double dt) {
    if (_state != 'playing' || _showQ || !mounted) return;
    for (final h in _holes) {
      if (h.letter == null) continue;
      h.timeLeft -= dt;
      if (h.timeLeft <= 0) h.clear();
    }

    _spawnTimer -= dt;
    final maxUp = _speed >= 1.5 ? 3 : 2;
    final upCount = _holes.where((h) => h.isUp).length;
    if (_spawnTimer <= 0 && upCount < maxUp) {
      _spawnMole();
      _spawnTimer = (0.8 + _rng.nextDouble() * 0.6) / _speed;
    }
    setState(() {});
  }

  void _spawnMole() {
    final empty = [
      for (var i = 0; i < _holes.length; i++)
        if (!_holes[i].isUp) i,
    ];
    if (empty.isEmpty) return;
    final hole = _holes[empty[_rng.nextInt(empty.length)]];
    final target = _round.target;
    final targetShowing = _holes.any(
      (h) => h.isUp && !h.hit && h.letter == target,
    );

    String letter;
    if (!targetShowing &&
        (_spawnsSinceTarget >= 2 || _rng.nextDouble() < 0.5)) {
      letter = target;
      _spawnsSinceTarget = 0;
    } else {
      final wrong = _round.wrong;
      letter = wrong[_rng.nextInt(wrong.length)];
      _spawnsSinceTarget++;
    }
    hole
      ..clear()
      ..letter = letter
      ..timeLeft = (2.4 + _rng.nextDouble() * 0.8) / _speed;
  }

  void _showFeedback(String text, bool good) {
    _feedbackTimer?.cancel();
    setState(() {
      _feedback = text;
      _feedbackGood = good;
    });
    _feedbackTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _feedback = null);
    });
  }

  void _onTapHole(_Hole hole) {
    if (_state != 'playing' || !hole.isUp || hole.hit || hole.wrongTap) return;

    if (hole.letter == _round.target) {
      HapticFeedback.lightImpact();
      hole.hit = true;
      hole.timeLeft = 0.45;
      _showFeedback(
        ['Bonk! ⭐', 'Great! 🎉', 'Super! 🌟'][_rng.nextInt(3)],
        true,
      );
      _nextRound();
    } else {
      HapticFeedback.heavyImpact();
      hole.wrongTap = true;
      hole.timeLeft = 0.45;
      _hearts--;
      _showFeedback('Oops! Find ${_round.target}', false);
      if (_hearts <= 0) {
        _timer?.cancel();
        setState(() => _state = 'lost');
      }
    }
  }

  void _nextRound() {
    if (_roundIndex + 1 >= _rounds.length) {
      _timer?.cancel();
      rewardMiniGameWin(widget.progressService, widget.content);
      setState(() {
        _roundIndex = _rounds.length;
        _state = 'won';
      });
      return;
    }
    setState(() {
      _roundIndex++;
      if (promptFor(widget.content, _round.level) !=
          promptFor(widget.content, _rounds[_roundIndex - 1].level)) {
        _showQ = true;
      }
      // Moles that are not the one just hit duck down for the new letter.
      for (final h in _holes) {
        if (!h.hit) h.clear();
      }
      _spawnsSinceTarget = 2;
      _spawnTimer = 0.4;
    });
  }

  @override
  Widget build(BuildContext context) {
    return QuestionPopupHost(
      show: _showQ && _state == 'playing' && _rounds.isNotEmpty,
      question: _rounds.isEmpty ? '' : promptFor(widget.content, _round.level),
      target: _rounds.isEmpty ? null : _round.target,
      label: 'QUESTION ${_roundIndex + 1}/${_rounds.length}',
      hint: 'Bonk the mole with the right letter!',
      emoji: '🔨',
      onStart: () => setState(() => _showQ = false),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF7DD3FC), Color(0xFFBEF264), Color(0xFF65A30D)],
              stops: [0.0, 0.35, 1.0],
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
                      hearts: _hearts,
                      color: _color,
                    ),
                    if (_rounds.isNotEmpty)
                      MiniTargetBanner(
                        label: 'Bonk the mole with ${_round.target}!',
                        target: _round.target,
                        prompt: promptFor(widget.content, _round.level),
                        color: _color,
                      ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: GridView.count(
                              crossAxisCount: 3,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 0.92,
                              children: [for (final h in _holes) _buildHole(h)],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 150,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: MiniFeedbackBubble(
                      text: _feedback,
                      good: _feedbackGood,
                    ),
                  ),
                ),
                if (_state != 'playing')
                  Positioned.fill(
                    child: MiniGameEndOverlay(
                      won: _state == 'won',
                      message: _state == 'won'
                          ? 'You bonked every letter mole!'
                          : 'The moles got away this time.',
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

  Widget _buildHole(_Hole hole) {
    final up = hole.isUp;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _onTapHole(hole),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;
          final holeH = h * 0.26;
          final moleH = h * 0.78;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Dark hole
              Positioned(
                left: w * 0.06,
                right: w * 0.06,
                bottom: 0,
                height: holeH,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF3F2A14),
                    borderRadius: BorderRadius.all(Radius.elliptical(w, holeH)),
                    border: Border.all(
                      color: const Color(0xFF854D0E),
                      width: 4,
                    ),
                  ),
                ),
              ),
              // Mole rising out of the hole (clipped at the hole's middle)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: holeH * 0.5,
                child: ClipRect(
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 170),
                        curve: Curves.easeOutBack,
                        left: w * 0.14,
                        right: w * 0.14,
                        height: moleH,
                        bottom: up ? -moleH * 0.05 : -moleH,
                        child: _buildMole(hole),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMole(_Hole hole) {
    final signColor = hole.hit
        ? const Color(0xFF22C55E)
        : hole.wrongTap
        ? const Color(0xFFEF4444)
        : Colors.white;
    final textColor = (hole.hit || hole.wrongTap)
        ? Colors.white
        : const Color(0xFF1E293B);
    return Column(
      children: [
        // Letter sign held above the head
        Flexible(
          flex: 5,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: signColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF92400E), width: 3),
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                hole.letter ?? '',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
        // Mole body
        Flexible(
          flex: 6,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFA16207),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(60),
                bottom: Radius.circular(10),
              ),
            ),
            alignment: Alignment.center,
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  hole.hit ? '😵' : (hole.wrongTap ? '😜' : '🐹'),
                  style: const TextStyle(fontSize: 34),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
