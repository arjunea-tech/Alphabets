import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/game_content.dart';
import '../../services/progress_service.dart';
import 'mini_game_kit.dart';

/// Space Letter Shooter: letter asteroids drift down. Drag the rocket left and
/// right and tap to fire. Hit the target letter; hitting a wrong asteroid
/// costs a heart. Missed asteroids just float away.
class SpaceLetterGame extends StatefulWidget {
  final ProgressService progressService;
  final GameContent content;

  const SpaceLetterGame({super.key, required this.progressService, required this.content});

  @override
  State<SpaceLetterGame> createState() => _SpaceLetterGameState();
}

class _Asteroid {
  final int id;
  final String letter;
  final double radius;
  final double vy;
  final Color color;
  double x;
  double y;

  _Asteroid({
    required this.id,
    required this.letter,
    required this.radius,
    required this.vy,
    required this.color,
    required this.x,
    required this.y,
  });
}

class _Laser {
  double x;
  double y;
  _Laser(this.x, this.y);
}

class _Blast {
  final double x;
  final double y;
  final bool good;
  double life = 0.6;
  _Blast(this.x, this.y, this.good);
}

class _SpaceLetterGameState extends State<SpaceLetterGame> {
  static const Color _color = Color(0xFF6366F1);
  static const int _maxHearts = 5;
  static const double _shipSize = 64;
  static const List<Color> _rockColors = [
    Color(0xFFF472B6),
    Color(0xFF60A5FA),
    Color(0xFFFBBF24),
    Color(0xFF34D399),
    Color(0xFFA78BFA),
    Color(0xFFFB923C),
  ];

  final math.Random _rng = math.Random();
  late final List<Offset> _stars = List.generate(
    60,
    (_) => Offset(_rng.nextDouble(), _rng.nextDouble()),
  );

  late List<MiniRound> _rounds;
  final List<_Asteroid> _rocks = [];
  final List<_Laser> _lasers = [];
  final List<_Blast> _blasts = [];
  Timer? _timer;
  Size _arena = Size.zero;

  int _idCounter = 0;
  int _roundIndex = 0;
  int _hearts = _maxHearts;
  int _spawnsSinceTarget = 0;
  double _spawnTimer = 0.3;
  double _fireCooldown = 0;
  double _shipX = 0.5; // 0..1 across the arena
  double _starScroll = 0;
  String _state = 'playing';
  String? _feedback;
  bool _feedbackGood = true;
  Timer? _feedbackTimer;

  double get _speed => widget.content.speedFactor;
  MiniRound get _round => _rounds[_roundIndex.clamp(0, _rounds.length - 1)];
  double get _shipY => _arena.height - _shipSize - 20;

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
    _rocks.clear();
    _lasers.clear();
    _blasts.clear();
    setState(() {
      _roundIndex = 0;
      _hearts = _maxHearts;
      _spawnsSinceTarget = 0;
      _spawnTimer = 0.3;
      _shipX = 0.5;
      _state = _rounds.isEmpty ? 'won' : 'playing';
    });
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick(0.016));
  }

  void _tick(double dt) {
    if (_state != 'playing' || !mounted || _arena == Size.zero) return;
    final w = _arena.width;
    final h = _arena.height;
    _starScroll = (_starScroll + dt * 0.04) % 1.0;
    _fireCooldown -= dt;

    // Spawn
    _spawnTimer -= dt;
    if (_spawnTimer <= 0 && _rocks.length < 5) {
      _spawnRock(w);
      _spawnTimer = (1.1 + _rng.nextDouble() * 0.7) / _speed;
    }

    // Move asteroids; drop the ones that left the screen
    for (final r in _rocks) {
      r.y += r.vy * dt;
    }
    _rocks.removeWhere((r) => r.y - r.radius > h);

    // Move lasers and check hits
    for (final l in _lasers) {
      l.y -= 620 * dt;
    }
    _lasers.removeWhere((l) => l.y < -20);

    for (var li = _lasers.length - 1; li >= 0; li--) {
      final l = _lasers[li];
      _Asteroid? hit;
      for (final r in _rocks) {
        final dx = r.x - l.x;
        final dy = r.y - l.y;
        if (dx * dx + dy * dy <= (r.radius + 6) * (r.radius + 6)) {
          hit = r;
          break;
        }
      }
      if (hit != null) {
        _lasers.removeAt(li);
        _rocks.remove(hit);
        _onRockHit(hit);
        if (_state != 'playing') return;
      }
    }

    for (final b in _blasts) {
      b.life -= dt;
    }
    _blasts.removeWhere((b) => b.life <= 0);
    setState(() {});
  }

  void _spawnRock(double w) {
    final target = _round.target;
    final targetShowing = _rocks.any((r) => r.letter == target);
    String letter;
    if (!targetShowing && (_spawnsSinceTarget >= 2 || _rng.nextDouble() < 0.45)) {
      letter = target;
      _spawnsSinceTarget = 0;
    } else {
      final wrong = _round.wrong;
      letter = wrong[_rng.nextInt(wrong.length)];
      _spawnsSinceTarget++;
    }
    final radius = 30.0 + _rng.nextDouble() * 6;
    _rocks.add(_Asteroid(
      id: _idCounter++,
      letter: letter,
      radius: radius,
      vy: (42 + _rng.nextDouble() * 22) * _speed,
      color: _rockColors[_rng.nextInt(_rockColors.length)],
      x: radius + _rng.nextDouble() * (w - radius * 2),
      y: -radius,
    ));
  }

  void _onRockHit(_Asteroid rock) {
    if (rock.letter == _round.target) {
      HapticFeedback.lightImpact();
      _blasts.add(_Blast(rock.x, rock.y, true));
      _showFeedback(['Zap! ⭐', 'Great shot! 🚀', 'Super! 🌟'][_rng.nextInt(3)], true);
      if (_roundIndex + 1 >= _rounds.length) {
        _timer?.cancel();
        rewardMiniGameWin(widget.progressService, widget.content);
        setState(() {
          _roundIndex = _rounds.length;
          _state = 'won';
        });
        return;
      }
      _roundIndex++;
      // Clear the sky so the new target is easy to spot.
      for (final r in _rocks) {
        _blasts.add(_Blast(r.x, r.y, true));
      }
      _rocks.clear();
      _spawnsSinceTarget = 2;
      _spawnTimer = 0.6;
    } else {
      HapticFeedback.heavyImpact();
      _blasts.add(_Blast(rock.x, rock.y, false));
      _hearts--;
      _showFeedback('Oops! Shoot ${_round.target}', false);
      if (_hearts <= 0) {
        _timer?.cancel();
        setState(() => _state = 'lost');
      }
    }
  }

  void _showFeedback(String text, bool good) {
    _feedbackTimer?.cancel();
    _feedback = text;
    _feedbackGood = good;
    _feedbackTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _feedback = null);
    });
  }

  void _moveShip(double localX) {
    if (_arena.width <= 0) return;
    setState(() => _shipX = (localX / _arena.width).clamp(0.06, 0.94));
  }

  void _fire() {
    if (_state != 'playing' || _fireCooldown > 0 || _lasers.length >= 4) return;
    _fireCooldown = 0.22;
    _lasers.add(_Laser(_shipX * _arena.width, _shipY));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1033),
      body: SafeArea(
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
                    label: 'Shoot the ${_round.target} asteroid!',
                    target: _round.target,
                    prompt: promptFor(widget.content, _round.level),
                    color: _color,
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      _arena = Size(c.maxWidth, c.maxHeight);
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (d) {
                          _moveShip(d.localPosition.dx);
                          _fire();
                        },
                        onHorizontalDragUpdate: (d) => _moveShip(d.localPosition.dx),
                        child: ClipRect(child: _buildArena()),
                      );
                    },
                  ),
                ),
              ],
            ),
            Positioned(
              top: 150,
              left: 0,
              right: 0,
              child: Center(child: MiniFeedbackBubble(text: _feedback, good: _feedbackGood)),
            ),
            if (_state != 'playing')
              Positioned.fill(
                child: MiniGameEndOverlay(
                  won: _state == 'won',
                  message: _state == 'won' ? 'You cleared the letter galaxy!' : 'Too many wrong asteroids.',
                  content: widget.content,
                  onReplay: _start,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildArena() {
    final w = _arena.width;
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _StarFieldPainter(_stars, _starScroll)),
        ),
        for (final r in _rocks)
          Positioned(
            key: ValueKey(r.id),
            left: r.x - r.radius,
            top: r.y - r.radius,
            width: r.radius * 2,
            height: r.radius * 2,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.4),
                  colors: [Colors.white.withValues(alpha: 0.9), r.color, Color.lerp(r.color, Colors.black, 0.45)!],
                  stops: const [0.0, 0.45, 1.0],
                ),
                boxShadow: [BoxShadow(color: r.color.withValues(alpha: 0.6), blurRadius: 12)],
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(6),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  r.letter,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                  ),
                ),
              ),
            ),
          ),
        for (final l in _lasers)
          Positioned(
            left: l.x - 3,
            top: l.y - 18,
            width: 6,
            height: 22,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF67E8F9),
                borderRadius: BorderRadius.circular(3),
                boxShadow: const [BoxShadow(color: Color(0xFF22D3EE), blurRadius: 8)],
              ),
            ),
          ),
        for (final b in _blasts)
          Positioned(
            left: b.x - 30,
            top: b.y - 30 - (0.6 - b.life) * 40,
            width: 60,
            height: 60,
            child: Opacity(
              opacity: (b.life / 0.6).clamp(0.0, 1.0),
              child: Center(
                child: Text(b.good ? '💥' : '❌', style: const TextStyle(fontSize: 38)),
              ),
            ),
          ),
        // Rocket
        Positioned(
          left: _shipX * w - _shipSize / 2,
          top: _shipY,
          width: _shipSize,
          height: _shipSize,
          child: Transform.rotate(
            angle: -math.pi / 4, // the 🚀 emoji points up-right; turn it straight up
            child: const FittedBox(child: Text('🚀')),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 4,
          child: Text(
            'Drag to move • Tap to fire',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  final List<Offset> stars;
  final double scroll;

  _StarFieldPainter(this.stars, this.scroll);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (var i = 0; i < stars.length; i++) {
      final s = stars[i];
      final y = ((s.dy + scroll * (1 + (i % 3) * 0.5)) % 1.0) * size.height;
      paint.color = Colors.white.withValues(alpha: 0.35 + (i % 4) * 0.15);
      canvas.drawCircle(Offset(s.dx * size.width, y), 1.0 + (i % 3) * 0.6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter old) => old.scroll != scroll;
}
