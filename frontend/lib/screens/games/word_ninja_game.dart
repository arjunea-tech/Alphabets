import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/progress_service.dart';
import '../../widgets/bouncy_button.dart';
import 'package:flutter/services.dart';

class WordNinjaGame extends StatefulWidget {
  final ProgressService progressService;

  const WordNinjaGame({super.key, required this.progressService});

  @override
  State<WordNinjaGame> createState() => _WordNinjaGameState();
}

class _NinjaItem {
  final int id;
  final String text;
  final bool isTarget;
  final Color color;
  final String fruitType;
  final Color juiceColor;
  final double radius = 44;
  double x;
  double y;
  double vx;
  double vy;
  double angle;
  double vRot;
  bool sliced = false;

  _NinjaItem({
    required this.id,
    required this.text,
    required this.isTarget,
    required this.color,
    required this.fruitType,
    required this.juiceColor,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.angle,
    required this.vRot,
  });
}

class _SlicePiece {
  final String text;
  final Color color;
  final String fruitType;
  final bool isLeft;
  final Color juiceColor;
  final double radius;
  double x;
  double y;
  double vx;
  double vy;
  double angle;
  double vRot;
  double opacity = 1.0;

  _SlicePiece({
    required this.text,
    required this.color,
    required this.fruitType,
    required this.isLeft,
    required this.juiceColor,
    required this.radius,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.angle,
    required this.vRot,
  });
}

class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double radius;
  double life;
  double maxLife;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.radius,
    required this.life,
    required this.maxLife,
  });
}

class _FloatingFeedback {
  final String text;
  final Color color;
  double x;
  double y;
  double opacity = 1.0;

  _FloatingFeedback({
    required this.text,
    required this.color,
    required this.x,
    required this.y,
  });
}

class _NinjaChallenge {
  final String title;
  final String prompt;
  final List<String> targets;
  final List<String> distractors;

  _NinjaChallenge({
    required this.title,
    required this.prompt,
    required this.targets,
    required this.distractors,
  });
}

class _BladePoint {
  final Offset position;
  final DateTime time;

  _BladePoint(this.position) : time = DateTime.now();
}

class _WordNinjaGameState extends State<WordNinjaGame> {
  int _score = 100;
  int _lives = 5;
  int _streak = 0;
  int _currentChallengeIndex = 0;
  int _challengeSlices = 0;
  final int _slicesPerChallenge = 4;
  String _gameState = 'playing'; // 'playing', 'victory', 'gameover'
  bool _soundEnabled = true;

  Timer? _loopTimer;
  double _spawnTimer = 0.6;
  int _idCounter = 0;

  final List<_NinjaItem> _items = [];
  final List<_SlicePiece> _pieces = [];
  final List<_Particle> _particles = [];
  final List<_FloatingFeedback> _feedbacks = [];
  final List<_BladePoint> _bladeTrail = [];

  static final List<_NinjaChallenge> _challenges = [
    _NinjaChallenge(
      title: 'VOWEL LETTERS',
      prompt: 'Slice only VOWEL letters (A, E, I, O, U)!',
      targets: ['A', 'E', 'I', 'O', 'U'],
      distractors: ['B', 'C', 'D', 'F', 'G', 'H', 'J', 'K', 'M'],
    ),
    _NinjaChallenge(
      title: 'LETTERS A TO G',
      prompt: 'Slice only letters from A to G!',
      targets: ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
      distractors: ['P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'Z'],
    ),
    _NinjaChallenge(
      title: 'ANIMAL WORDS',
      prompt: 'Slice only ANIMAL Words!',
      targets: ['Lion', 'Cat', 'Dog', 'Bear', 'Fox', 'Duck'],
      distractors: ['Cup', 'Car', 'Pen', 'Hat', 'Sun', 'Box'],
    ),
    _NinjaChallenge(
      title: 'CONSONANT LETTERS',
      prompt: 'Slice only CONSONANT letters!',
      targets: ['B', 'D', 'M', 'N', 'P', 'R', 'S', 'T', 'W'],
      distractors: ['A', 'E', 'I', 'O', 'U'],
    ),
    _NinjaChallenge(
      title: 'FRUIT & FOOD WORDS',
      prompt: 'Slice only FOOD Words!',
      targets: ['Apple', 'Mango', 'Bread', 'Cake', 'Egg', 'Milk'],
      distractors: ['Moon', 'Star', 'Bell', 'Desk', 'Road', 'Rock'],
    ),
  ];

  static const List<Map<String, dynamic>> _fruitCatalog = [
    {
      'type': 'watermelon',
      'color': Color(0xFF15803D),
      'juice': Color(0xFFEF4444),
    },
    {
      'type': 'orange',
      'color': Color(0xFFEA580C),
      'juice': Color(0xFFF97316),
    },
    {
      'type': 'apple',
      'color': Color(0xFFDC2626),
      'juice': Color(0xFFFCA5A5),
    },
    {
      'type': 'strawberry',
      'color': Color(0xFFE11D48),
      'juice': Color(0xFFFB7185),
    },
    {
      'type': 'banana',
      'color': Color(0xFFFACC15),
      'juice': Color(0xFFFEF08A),
    },
    {
      'type': 'grapes',
      'color': Color(0xFF9333EA),
      'juice': Color(0xFFA855F7),
    },
  ];

  @override
  void initState() {
    super.initState();
    _startNinjaGame();
  }

  @override
  void dispose() {
    _loopTimer?.cancel();
    super.dispose();
  }

  void _startNinjaGame() {
    _loopTimer?.cancel();
    _loopTimer = null;
    setState(() {
      _score = 100;
      _lives = 5;
      _streak = 0;
      _currentChallengeIndex = 0;
      _challengeSlices = 0;
      _gameState = 'playing';
      _items.clear();
      _pieces.clear();
      _particles.clear();
      _feedbacks.clear();
      _bladeTrail.clear();
      _spawnTimer = 0.5;
    });

    // 60 FPS fixed delta loop (16ms per tick)
    _loopTimer = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick(0.016));
  }

  void _triggerVictory() {
    _loopTimer?.cancel();
    _loopTimer = null;
    widget.progressService.addStars(15);
    if (mounted) {
      setState(() {
        _gameState = 'victory';
      });
    }
  }

  void _triggerGameOver() {
    _loopTimer?.cancel();
    _loopTimer = null;
    if (mounted) {
      setState(() {
        _gameState = 'gameover';
      });
    }
  }

  void _playSound(bool isCorrect) {
    if (!_soundEnabled) return;
    try {
      if (isCorrect) {
        HapticFeedback.mediumImpact();
        SystemSound.play(SystemSoundType.click);
      } else {
        HapticFeedback.vibrate();
        SystemSound.play(SystemSoundType.alert);
      }
    } catch (_) {}
  }

  void _tick(double dt) {
    if (_gameState != 'playing') return;

    final random = Random();

    // 1. Slow, Gentle Spawning
    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      // Slower spawn interval: 1.4 to 2.0 seconds between launches
      _spawnTimer = 1.4 + random.nextDouble() * 0.6;
      _launchFruitBatch();
    }

    // 2. Update Whole Flying Fruits (GENTLE, SLOW KID-FRIENDLY PHYSICS)
    // Low gravity gives long hang time (~3.0 seconds in air)
    const double gravity = 320.0;
    for (int i = _items.length - 1; i >= 0; i--) {
      final item = _items[i];
      item.x += item.vx * dt;
      item.y += item.vy * dt;
      item.vy += gravity * dt;
      item.angle += item.vRot * dt;

      // Fallen below screen
      if (item.y > 640 && item.vy > 0) {
        if (item.isTarget && !item.sliced) {
          // Missed target fruit: gentle -1 life
          _streak = 0;
          _lives--;
          _playSound(false);
          _feedbacks.add(_FloatingFeedback(
            text: 'MISSED! -1 ❤️',
            color: const Color(0xFFEF4444),
            x: item.x.clamp(60.0, 300.0),
            y: 520,
          ));
          if (_lives <= 0) {
            _triggerGameOver();
            return;
          }
        }
        _items.removeAt(i);
      }
    }

    // 3. Update Sliced Halves
    for (int i = _pieces.length - 1; i >= 0; i--) {
      final p = _pieces[i];
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += (gravity * 1.2) * dt;
      p.angle += p.vRot * dt;
      p.opacity -= dt * 0.85;

      if (p.opacity <= 0 || p.y > 660) {
        _pieces.removeAt(i);
      }
    }

    // 4. Update Juice & Sparkle Particles
    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 340.0 * dt;
      p.life -= dt;
      if (p.life <= 0) {
        _particles.removeAt(i);
      }
    }

    // 5. Update Floating Text Feedbacks
    for (int i = _feedbacks.length - 1; i >= 0; i--) {
      final fb = _feedbacks[i];
      fb.y -= 45.0 * dt;
      fb.opacity -= dt * 1.2;
      if (fb.opacity <= 0) {
        _feedbacks.removeAt(i);
      }
    }

    // 6. Clean Old Blade Trail Points
    final now = DateTime.now();
    _bladeTrail.removeWhere((p) => now.difference(p.time).inMilliseconds > 260);

    if (mounted) setState(() {});
  }

  void _launchFruitBatch() {
    final random = Random();
    // Launch 1 or 2 fruits at a time so it's calm and not chaotic
    final count = random.nextDouble() < 0.65 ? 1 : 2;

    for (int i = 0; i < count; i++) {
      final currentCh = _challenges[_currentChallengeIndex];
      final isTarget = random.nextDouble() < 0.65;
      final text = isTarget
          ? currentCh.targets[random.nextInt(currentCh.targets.length)]
          : currentCh.distractors[random.nextInt(currentCh.distractors.length)];

      final fruit = _fruitCatalog[random.nextInt(_fruitCatalog.length)];

      // Launch position spread across bottom
      final startX = 60.0 + (i * 120.0) + random.nextDouble() * 80.0;
      final startY = 560.0 + random.nextDouble() * 30.0;

      // Gentle upward arc
      final targetMidX = 180.0 + (random.nextDouble() - 0.5) * 80.0;
      final vx = (targetMidX - startX) * 0.75 + (random.nextDouble() - 0.5) * 40.0;
      // Gentle vertical velocity: stays in air ~2.6-3.2 seconds
      final vy = -410.0 - random.nextDouble() * 50.0;

      _items.add(_NinjaItem(
        id: ++_idCounter,
        text: text,
        isTarget: isTarget,
        color: fruit['color'] as Color,
        fruitType: fruit['type'] as String,
        juiceColor: fruit['juice'] as Color,
        x: startX,
        y: startY,
        vx: vx,
        vy: vy,
        angle: (random.nextDouble() - 0.5) * 0.5,
        vRot: (random.nextDouble() - 0.5) * 2.2,
      ));
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_gameState != 'playing') return;

    final pos = details.localPosition;
    _bladeTrail.add(_BladePoint(pos));

    if (_bladeTrail.length >= 2) {
      final p0 = _bladeTrail[_bladeTrail.length - 2].position;
      final p1 = _bladeTrail.last.position;

      for (final item in _items) {
        if (item.sliced) continue;

        final itemPos = Offset(item.x, item.y);
        final dist = _distToSegment(itemPos, p0, p1);

        if (dist <= item.radius + 10) {
          _sliceItem(item, (p1 - p0).direction);
        }
      }
    }
  }

  void _sliceItem(_NinjaItem item, double cutAngle) {
    item.sliced = true;
    _playSound(item.isTarget);

    // Juice Splash Explosion
    _spawnJuiceSplash(item.x, item.y, item.juiceColor);

    // Split Fruit into 2 halves that fly apart
    final random = Random();
    final splitVx = 110.0 + random.nextDouble() * 50.0;

    _pieces.add(_SlicePiece(
      text: item.text,
      color: item.color,
      fruitType: item.fruitType,
      isLeft: true,
      juiceColor: item.juiceColor,
      radius: item.radius,
      x: item.x - 14,
      y: item.y,
      vx: -splitVx,
      vy: item.vy * 0.45 - 40,
      angle: item.angle - 0.3,
      vRot: -2.8,
    ));

    _pieces.add(_SlicePiece(
      text: item.text,
      color: item.color,
      fruitType: item.fruitType,
      isLeft: false,
      juiceColor: item.juiceColor,
      radius: item.radius,
      x: item.x + 14,
      y: item.y,
      vx: splitVx,
      vy: item.vy * 0.45 - 40,
      angle: item.angle + 0.3,
      vRot: 2.8,
    ));

    if (item.isTarget) {
      // CORRECT TARGET SLICED!
      _streak++;
      _challengeSlices++;
      final bonus = _streak >= 3 ? 150 : 100;
      _score += bonus;

      _feedbacks.add(_FloatingFeedback(
        text: _streak >= 3 ? 'COMBO! +$bonus' : '+$bonus',
        color: const Color(0xFFFBBF24),
        x: item.x,
        y: item.y - 20,
      ));

      if (_challengeSlices >= _slicesPerChallenge) {
        if (_currentChallengeIndex < _challenges.length - 1) {
          setState(() {
            _currentChallengeIndex++;
            _challengeSlices = 0;
            _items.clear();
            _feedbacks.add(_FloatingFeedback(
              text: 'CHALLENGE COMPLETED! ⭐',
              color: const Color(0xFF10B981),
              x: 180,
              y: 260,
            ));
          });
        } else {
          // Completed all 5 challenges!
          _triggerVictory();
        }
      }
    } else {
      // WRONG DISTRACTOR SLICED!
      _streak = 0;
      _lives--;
      _feedbacks.add(_FloatingFeedback(
        text: 'WRONG! -1 ❤️',
        color: const Color(0xFFEF4444),
        x: item.x,
        y: item.y - 20,
      ));

      if (_lives <= 0) {
        _triggerGameOver();
      }
    }
  }

  void _spawnJuiceSplash(double x, double y, Color juiceColor) {
    final random = Random();
    for (int i = 0; i < 22; i++) {
      final angle = random.nextDouble() * pi * 2;
      final speed = 60.0 + random.nextDouble() * 180.0;
      _particles.add(_Particle(
        x: x,
        y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        color: i % 3 == 0 ? Colors.white : juiceColor,
        radius: 2.5 + random.nextDouble() * 3.5,
        life: 0.50,
        maxLife: 0.50,
      ));
    }
  }

  double _distToSegment(Offset p, Offset v, Offset w) {
    final l2 = (v - w).distanceSquared;
    if (l2 == 0) return (p - v).distance;
    final t = (((p.dx - v.dx) * (w.dx - v.dx) + (p.dy - v.dy) * (w.dy - v.dy)) / l2).clamp(0.0, 1.0);
    final proj = Offset(v.dx + t * (w.dx - v.dx), v.dy + t * (w.dy - v.dy));
    return (p - proj).distance;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Top HUD
            _buildTopHud(),

            // High-Contrast Question Banner
            _buildObjectiveBanner(),

            // Slicing Arena
            Expanded(
              child: Stack(
                children: [
                  // 1. Scenic Ninja Dojo Background Art (Asset + Procedural Japanese Dojo Fallback)
                  Positioned.fill(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _DojoAtmospherePainter(),
                          ),
                        ),
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/games/word_ninja_cover.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.10),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.35),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Full Arena Gesture & Custom Painter
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanDown: (d) => _bladeTrail.add(_BladePoint(d.localPosition)),
                    onPanUpdate: _onPanUpdate,
                    child: CustomPaint(
                      painter: _NinjaArenaPainter(
                        items: _items,
                        pieces: _pieces,
                        particles: _particles,
                        feedbacks: _feedbacks,
                        bladeTrail: _bladeTrail,
                      ),
                      child: Container(),
                    ),
                  ),

                  // Bottom Guidance
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: const Text(
                          '⚔️ SWIPE ACROSS FLYING FRUITS TO SLICE',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Overlays
                  if (_gameState == 'victory') _buildVictoryOverlay(),
                  if (_gameState == 'gameover') _buildGameOverOverlay(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHud() {
    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            ),
          ),

          // Score & Streak
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 22),
              const SizedBox(width: 4),
              Text(
                '$_score',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
              ),
              if (_streak >= 2) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange, width: 1),
                  ),
                  child: Text(
                    '⚡${_streak}x',
                    style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),

          // Lives & Sound
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...List.generate(
                5,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Icon(
                    i < _lives ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: i < _lives ? const Color(0xFFEF4444) : Colors.white24,
                    size: 16,
                  ),
                ),
              ),
              
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildObjectiveBanner() {
    final safeChIdx = _currentChallengeIndex.clamp(0, _challenges.length - 1);
    final currentCh = _challenges[safeChIdx];
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF311042),
            const Color(0xFF1E1B4B),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFF59E0B),
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Challenge Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.content_cut_rounded, color: Color(0xFFF59E0B), size: 14),
                const SizedBox(width: 6),
                Text(
                  'CHALLENGE ${_currentChallengeIndex + 1}/5: ${currentCh.title}',
                  style: const TextStyle(
                    color: Color(0xFFF59E0B),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Big Bold Prompt
          Text(
            currentCh.prompt,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              height: 1.25,
              shadows: [
                Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Sliced Counter
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Sliced: ',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                '$_challengeSlices / $_slicesPerChallenge',
                style: const TextStyle(
                  color: Color(0xFF4ADE80),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVictoryOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 72),
              const SizedBox(height: 14),
              const Text(
                '🎉 MASTER NINJA!',
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'All fruit targets sliced with precision!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  'Final Score: $_score pts  (+15 ⭐)',
                  style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BouncyButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text('Back to Games', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  BouncyButton(
                    onPressed: _startNinjaGame,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text('Play Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.heart_broken_rounded, color: Color(0xFFEF4444), size: 72),
              const SizedBox(height: 14),
              const Text(
                'OUT OF LIVES!',
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Slice only target fruits and avoid distractors!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  'Score: $_score pts',
                  style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BouncyButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text('Back to Games', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  BouncyButton(
                    onPressed: _startNinjaGame,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text('Try Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- CANVAS PAINTER (FRUITS, SLICED HALVES, JUICE, BLADE TRAIL, WOODEN PLAQUE) ---
class _NinjaArenaPainter extends CustomPainter {
  final List<_NinjaItem> items;
  final List<_SlicePiece> pieces;
  final List<_Particle> particles;
  final List<_FloatingFeedback> feedbacks;
  final List<_BladePoint> bladeTrail;

  _NinjaArenaPainter({
    required this.items,
    required this.pieces,
    required this.particles,
    required this.feedbacks,
    required this.bladeTrail,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Juice Particles
    for (final p in particles) {
      final alpha = (p.life / p.maxLife).clamp(0.0, 1.0);
      final pPaint = Paint()..color = p.color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(p.x, p.y), p.radius * alpha, pPaint);
    }

    // 2. Whole Flying Fruits
    for (final item in items) {
      if (item.sliced) continue;

      canvas.save();
      canvas.translate(item.x, item.y);
      canvas.rotate(item.angle);

      // Draw Realistic Fruit Body
      _drawFruit(canvas, item.fruitType, item.radius);

      // Wooden Word Plaque
      _drawWordPlaque(canvas, item.text);

      canvas.restore();
    }

    // 3. Sliced Fruit Halves
    for (final piece in pieces) {
      canvas.save();
      canvas.translate(piece.x, piece.y);
      canvas.rotate(piece.angle);

      _drawSlicedFruitHalf(canvas, piece.fruitType, piece.radius, piece.isLeft, piece.opacity);
      _drawSlicedPlaque(canvas, piece.text, piece.isLeft, piece.opacity);

      canvas.restore();
    }

    // 4. Glowing Katana Blade Trail
    if (bladeTrail.length >= 2) {
      final now = DateTime.now();
      for (int i = 0; i < bladeTrail.length - 1; i++) {
        final p0 = bladeTrail[i].position;
        final p1 = bladeTrail[i + 1].position;
        final ageMs = now.difference(bladeTrail[i].time).inMilliseconds;
        final alpha = (1.0 - (ageMs / 260.0)).clamp(0.0, 1.0);

        // Outer Cyan Katana Glow
        canvas.drawLine(
          p0,
          p1,
          Paint()
            ..color = const Color(0xFF38BDF8).withValues(alpha: alpha * 0.75)
            ..strokeWidth = 10.0 * alpha
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke,
        );

        // Core White Blade Light
        canvas.drawLine(
          p0,
          p1,
          Paint()
            ..color = Colors.white.withValues(alpha: alpha)
            ..strokeWidth = 4.0 * alpha
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke,
        );
      }
    }

    // 5. Floating Score Feedbacks
    for (final fb in feedbacks) {
      final tp = TextPainter(
        text: TextSpan(
          text: fb.text,
          style: TextStyle(
            color: fb.color.withValues(alpha: fb.opacity.clamp(0.0, 1.0)),
            fontSize: 16,
            fontWeight: FontWeight.w900,
            shadows: const [
              Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(fb.x - tp.width / 2, fb.y - tp.height / 2));
    }
  }

  // --- DRAW REALISTIC PROCEDURAL FRUITS ---
  void _drawFruit(Canvas canvas, String fruitType, double r) {
    // Drop Shadow
    canvas.drawCircle(
      const Offset(0, 6),
      r,
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );

    switch (fruitType) {
      case 'watermelon':
        // Green Striped Watermelon
        final rindPaint = Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.25, -0.25),
            radius: 0.9,
            colors: const [Color(0xFF22C55E), Color(0xFF15803D), Color(0xFF14532D)],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
        canvas.drawCircle(Offset.zero, r, rindPaint);

        // Dark green jagged stripes
        final stripePaint = Paint()
          ..color = const Color(0xFF052E16).withValues(alpha: 0.65)
          ..strokeWidth = 4.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        for (double a = -pi * 0.6; a <= pi * 0.6; a += 0.5) {
          canvas.save();
          canvas.rotate(a);
          final sPath = Path()
            ..moveTo(0, -r * 0.85)
            ..quadraticBezierTo(7, -r * 0.4, -4, 0)
            ..quadraticBezierTo(8, r * 0.4, 0, r * 0.85);
          canvas.drawPath(sPath, stripePaint);
          canvas.restore();
        }
        break;

      case 'orange':
        // Vibrant Orange
        final orangePaint = Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.3),
            radius: 0.9,
            colors: const [Color(0xFFFDBA74), Color(0xFFF97316), Color(0xFFC2410C)],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
        canvas.drawCircle(Offset.zero, r, orangePaint);

        // Little green stem on top
        canvas.drawCircle(Offset(0, -r + 3), 4, Paint()..color = const Color(0xFF15803D));
        break;

      case 'apple':
        // Glossy Red Apple
        final applePaint = Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.3),
            radius: 0.9,
            colors: const [Color(0xFFF87171), Color(0xFFEF4444), Color(0xFF991B1B)],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
        canvas.drawCircle(Offset.zero, r, applePaint);

        // Brown stem & green leaf
        canvas.drawLine(
          Offset(0, -r + 4),
          Offset(4, -r - 10),
          Paint()
            ..color = const Color(0xFF78350F)
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
        final leafPath = Path()
          ..moveTo(2, -r - 5)
          ..quadraticBezierTo(14, -r - 12, 10, -r - 2)
          ..close();
        canvas.drawPath(leafPath, Paint()..color = const Color(0xFF22C55E));
        break;

      case 'strawberry':
        // Red Strawberry
        final berryPaint = Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.25, -0.25),
            radius: 0.9,
            colors: const [Color(0xFFFB7185), Color(0xFFE11D48), Color(0xFF9F1239)],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
        canvas.drawOval(Rect.fromCenter(center: const Offset(0, 3), width: r * 1.9, height: r * 2.1), berryPaint);

        // Yellow seeds
        final seedPaint = Paint()..color = const Color(0xFFFEF08A);
        for (double dx = -r * 0.5; dx <= r * 0.5; dx += 14) {
          for (double dy = -r * 0.4; dy <= r * 0.5; dy += 14) {
            canvas.drawCircle(Offset(dx, dy), 1.5, seedPaint);
          }
        }
        break;

      case 'kiwi':
        // Fuzzy Kiwi
        final kiwiPaint = Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.25, -0.25),
            radius: 0.9,
            colors: const [Color(0xFF92400E), Color(0xFF78350F), Color(0xFF451A03)],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
        canvas.drawCircle(Offset.zero, r, kiwiPaint);
        break;

      case 'grapes':
        // Cluster of juicy grapes
        final grapePaint = Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.25, -0.25),
            radius: 0.9,
            colors: const [Color(0xFFA855F7), Color(0xFF9333EA), Color(0xFF581C87)],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
        canvas.drawCircle(Offset(-r * 0.25, -r * 0.2), r * 0.45, grapePaint);
        canvas.drawCircle(Offset(r * 0.25, -r * 0.2), r * 0.45, grapePaint);
        canvas.drawCircle(Offset(0, r * 0.22), r * 0.48, grapePaint);
        // Little green stem
        canvas.drawCircle(Offset(0, -r * 0.65), 4, Paint()..color = const Color(0xFF22C55E));
        break;

      default:
        // Generic Tropical Fruit
        final genericPaint = Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.3),
            radius: 0.9,
            colors: const [Color(0xFFFDE047), Color(0xFFEAB308), Color(0xFFCA8A04)],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
        canvas.drawCircle(Offset.zero, r, genericPaint);
    }

    // Glossy light curve highlight
    final glossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.38)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r * 0.72),
      -pi * 0.75,
      pi * 0.35,
      false,
      glossPaint,
    );
  }

  // --- DRAW SLICED FRUIT HALF ---
  void _drawSlicedFruitHalf(Canvas canvas, String fruitType, double r, bool isLeft, double opacity) {
    final startAng = isLeft ? pi * 0.5 : -pi * 0.5;
    const sweepAng = pi;
    final a = opacity.clamp(0.0, 1.0);

    switch (fruitType) {
      case 'watermelon':
        // Green outer rind
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r), startAng, sweepAng, true, Paint()..color = const Color(0xFF15803D).withValues(alpha: a));
        // Light inner rind
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r * 0.88), startAng, sweepAng, true, Paint()..color = const Color(0xFFDCFCE7).withValues(alpha: a));
        // Red juicy flesh
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r * 0.80), startAng, sweepAng, true, Paint()..color = const Color(0xFFEF4444).withValues(alpha: a));
        // Black seeds
        final seedPaint = Paint()..color = Colors.black87.withValues(alpha: a);
        final sx = isLeft ? -r * 0.45 : r * 0.45;
        for (final sy in [-r * 0.35, 0.0, r * 0.35]) {
          canvas.drawOval(Rect.fromCenter(center: Offset(sx, sy), width: 5, height: 8), seedPaint);
        }
        break;

      case 'orange':
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r), startAng, sweepAng, true, Paint()..color = const Color(0xFFEA580C).withValues(alpha: a));
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r * 0.90), startAng, sweepAng, true, Paint()..color = const Color(0xFFFEF9C3).withValues(alpha: a));
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r * 0.82), startAng, sweepAng, true, Paint()..color = const Color(0xFFFB923C).withValues(alpha: a));
        break;

      case 'apple':
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r), startAng, sweepAng, true, Paint()..color = const Color(0xFFDC2626).withValues(alpha: a));
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r * 0.90), startAng, sweepAng, true, Paint()..color = const Color(0xFFFEF9C3).withValues(alpha: a));
        // Apple core seed
        canvas.drawOval(Rect.fromCenter(center: Offset(isLeft ? -r * 0.25 : r * 0.25, 0), width: 6, height: 10), Paint()..color = const Color(0xFF451A03).withValues(alpha: a));
        break;

      case 'strawberry':
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r), startAng, sweepAng, true, Paint()..color = const Color(0xFFE11D48).withValues(alpha: a));
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r * 0.85), startAng, sweepAng, true, Paint()..color = const Color(0xFFFFE4E6).withValues(alpha: a));
        break;

      case 'kiwi':
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r), startAng, sweepAng, true, Paint()..color = const Color(0xFF78350F).withValues(alpha: a));
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r * 0.88), startAng, sweepAng, true, Paint()..color = const Color(0xFF22C55E).withValues(alpha: a));
        canvas.drawOval(Rect.fromCenter(center: Offset(isLeft ? -r * 0.2 : r * 0.2, 0), width: r * 0.4, height: r * 0.6), Paint()..color = const Color(0xFFFEF9C3).withValues(alpha: a));
        break;

      case 'coconut':
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r), startAng, sweepAng, true, Paint()..color = const Color(0xFF451A03).withValues(alpha: a));
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r * 0.85), startAng, sweepAng, true, Paint()..color = const Color(0xFFF8FAFC).withValues(alpha: a));
        break;

      default:
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r), startAng, sweepAng, true, Paint()..color = const Color(0xFFCA8A04).withValues(alpha: a));
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r * 0.88), startAng, sweepAng, true, Paint()..color = const Color(0xFFFEF08A).withValues(alpha: a));
    }
  }

  // --- DRAW WOODEN WORD PLAQUE ---
  void _drawWordPlaque(Canvas canvas, String text) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15.0,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.3,
          shadows: [
            Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final bannerW = (tp.width + 26).clamp(65.0, 140.0);
    const bannerH = 26.0;
    final rect = Rect.fromCenter(center: Offset.zero, width: bannerW, height: bannerH);

    // Dark Oak Plaque
    final bgPaint = Paint()..color = const Color(0xFF1E140C).withValues(alpha: 0.94);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), bgPaint);

    // Gold Border
    final borderPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), borderPaint);

    // 4 Corner Brass Rivets
    final rivetPaint = Paint()..color = const Color(0xFFFBBF24);
    final rx = bannerW / 2 - 4.0;
    final ry = bannerH / 2 - 4.0;
    canvas.drawCircle(Offset(-rx, -ry), 1.8, rivetPaint);
    canvas.drawCircle(Offset(rx, -ry), 1.8, rivetPaint);
    canvas.drawCircle(Offset(-rx, ry), 1.8, rivetPaint);
    canvas.drawCircle(Offset(rx, ry), 1.8, rivetPaint);

    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
  }

  // --- DRAW SLICED PLAQUE HALF ---
  void _drawSlicedPlaque(Canvas canvas, String text, bool isLeft, double opacity) {
    const tagW = 34.0;
    const tagH = 22.0;
    final a = opacity.clamp(0.0, 1.0);
    final rect = Rect.fromLTWH(isLeft ? -tagW : 0, -tagH / 2, tagW, tagH);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()..color = const Color(0xFF1E140C).withValues(alpha: a),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()
        ..color = const Color(0xFFF59E0B).withValues(alpha: a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _NinjaArenaPainter oldDelegate) => true;
}

/// Scenic Procedural Ninja Dojo Background (renders if asset is delayed or fallback)
class _DojoAtmospherePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // 1. Deep Midnight Twilight Sky Gradient
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF111827)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    // 2. Glowing Giant Moon
    final moonCenter = Offset(size.width * 0.80, size.height * 0.18);
    final moonGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFDE68A).withValues(alpha: 0.35),
          const Color(0xFFFDE68A).withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: moonCenter, radius: 85));
    canvas.drawCircle(moonCenter, 85, moonGlow);

    final moonPaint = Paint()..color = const Color(0xFFFEF3C7);
    canvas.drawCircle(moonCenter, 42, moonPaint);

    // Moon craters
    final craterPaint = Paint()..color = const Color(0xFFFDE68A).withValues(alpha: 0.55);
    canvas.drawCircle(Offset(moonCenter.dx - 12, moonCenter.dy - 10), 9, craterPaint);
    canvas.drawCircle(Offset(moonCenter.dx + 10, moonCenter.dy + 8), 6, craterPaint);
    canvas.drawCircle(Offset(moonCenter.dx + 6, moonCenter.dy - 16), 5, craterPaint);

    // 3. Traditional Dojo Wooden Beam Ceiling (Top Arch)
    final beamPaint = Paint()..color = const Color(0xFF1A120B);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 18), beamPaint);

    final archPath = Path()
      ..moveTo(0, 18)
      ..lineTo(size.width, 18)
      ..lineTo(size.width - 25, 34)
      ..lineTo(25, 34)
      ..close();
    canvas.drawPath(archPath, Paint()..color = const Color(0xFF2E1C0C));

    // 4. Hanging Glowing Red/Gold Paper Lanterns
    _drawLantern(canvas, Offset(size.width * 0.16, 68));
    _drawLantern(canvas, Offset(size.width * 0.86, 68));

    // 5. Wooden Tatami Dojo Floor at Bottom
    final floorY = size.height - 48.0;
    final floorPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF3E2723), Color(0xFF1B0000)],
      ).createShader(Rect.fromLTWH(0, floorY, size.width, 48));
    canvas.drawRect(Rect.fromLTWH(0, floorY, size.width, 48), floorPaint);

    final floorBorder = Paint()
      ..color = const Color(0xFFD97706)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, floorY), Offset(size.width, floorY), floorBorder);

    // Bamboo Silhouettes on Left & Right
    final bambooPaint = Paint()..color = const Color(0xFF0F172A).withValues(alpha: 0.75);
    _drawBamboo(canvas, 18, floorY, bambooPaint);
    _drawBamboo(canvas, 32, floorY, bambooPaint);
    _drawBamboo(canvas, size.width - 28, floorY, bambooPaint);
  }

  void _drawLantern(Canvas canvas, Offset center) {
    // String
    canvas.drawLine(Offset(center.dx, 18), Offset(center.dx, center.dy - 22), Paint()..color = const Color(0xFFD97706)..strokeWidth = 1.5);

    // Lantern Glow
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFF59E0B).withValues(alpha: 0.35),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 45));
    canvas.drawCircle(center, 45, glow);

    // Lantern Body
    final lanternRect = Rect.fromCenter(center: center, width: 28, height: 38);
    final lanternPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
      ).createShader(lanternRect);
    canvas.drawRRect(RRect.fromRectAndRadius(lanternRect, const Radius.circular(8)), lanternPaint);

    // Gold Ribs & Caps
    final gold = Paint()..color = const Color(0xFFFBBF24)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    canvas.drawRRect(RRect.fromRectAndRadius(lanternRect, const Radius.circular(8)), gold);
    canvas.drawLine(Offset(center.dx - 12, center.dy), Offset(center.dx + 12, center.dy), gold);
  }

  void _drawBamboo(Canvas canvas, double x, double floorY, Paint paint) {
    paint.strokeWidth = 6.0;
    paint.style = PaintingStyle.stroke;
    canvas.drawLine(Offset(x, floorY), Offset(x, floorY - 140), paint);
    // Nodes
    paint.strokeWidth = 8.5;
    canvas.drawLine(Offset(x - 4, floorY - 35), Offset(x + 4, floorY - 35), paint);
    canvas.drawLine(Offset(x - 4, floorY - 75), Offset(x + 4, floorY - 75), paint);
    canvas.drawLine(Offset(x - 4, floorY - 115), Offset(x + 4, floorY - 115), paint);
  }

  @override
  bool shouldRepaint(covariant _DojoAtmospherePainter oldDelegate) => false;
}
