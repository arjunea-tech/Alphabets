import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/game_content.dart';
import '../../services/progress_service.dart';
import '../../widgets/bouncy_button.dart';

/// Interactive Balloon item floating in the sky
class _BalloonItem {
  final int id;
  final String text;
  final bool isTarget;
  final Color color;
  final double radius;
  double x;
  double y;
  double vy; // upward speed in px/sec (slowed down for kids)
  double wobbleAngle;
  double wobbleSpeed;
  bool popped = false;

  _BalloonItem({
    required this.id,
    required this.text,
    required this.isTarget,
    required this.color,
    required this.radius,
    required this.x,
    required this.y,
    required this.vy,
    required this.wobbleAngle,
    required this.wobbleSpeed,
  });
}

/// Dynamic Confetti Blast Particle
class _ConfettiParticle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double width;
  double height;
  double angle;
  double vRot;
  double life;
  double maxLife;
  bool isStar;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.width,
    required this.height,
    required this.angle,
    required this.vRot,
    required this.life,
    required this.maxLife,
    this.isStar = false,
  });
}

/// Expanding shockwave ring on pop blast
class _BlastShockwave {
  double x;
  double y;
  double currentRadius;
  double maxRadius;
  Color color;
  double life;
  double maxLife;

  _BlastShockwave({
    required this.x,
    required this.y,
    required this.currentRadius,
    required this.maxRadius,
    required this.color,
    required this.life,
    required this.maxLife,
  });
}

/// Floating score / encouragement feedback
class _FloatingText {
  final String text;
  final Color color;
  double x;
  double y;
  double vy;
  double life;
  double maxLife;
  double scale;

  _FloatingText({
    required this.text,
    required this.color,
    required this.x,
    required this.y,
    required this.vy,
    required this.life,
    required this.maxLife,
    this.scale = 1.0,
  });
}

/// Mission Data Model
class _BalloonMission {
  final String badge;
  final String title;
  final String prompt;
  final List<String> targets;
  final List<String> distractors;

  _BalloonMission({
    required this.badge,
    required this.title,
    required this.prompt,
    required this.targets,
    required this.distractors,
  });
}

class BalloonPopGame extends StatefulWidget {
  final ProgressService progressService;
  final GameContent content;

  const BalloonPopGame({super.key, required this.progressService, required this.content});

  @override
  State<BalloonPopGame> createState() => _BalloonPopGameState();
}

class _BalloonPopGameState extends State<BalloonPopGame> with SingleTickerProviderStateMixin {
  final math.Random _random = math.Random();
  Timer? _gameTimer;

  int _score = 0;
  int _lives = 5;
  int _currentMissionIndex = 0;
  int _missionPops = 0;
  final int _popsPerMission = 4;
  String _gameState = 'playing'; // 'playing', 'victory', 'gameover'
  bool _soundEnabled = true;

  double _spawnTimer = 0.2;
  int _idCounter = 0;
  Size _arenaSize = const Size(360, 600);

  final List<_BalloonItem> _balloons = [];
  final List<_ConfettiParticle> _confetti = [];
  final List<_BlastShockwave> _shockwaves = [];
  final List<_FloatingText> _floatingTexts = [];
  final Set<String> _poppedTargetsThisMission = {};

  static final List<Color> _balloonPalette = [
    const Color(0xFFEF4444), // Ruby Red
    const Color(0xFF3B82F6), // Royal Sky Blue
    const Color(0xFF10B981), // Emerald Green
    const Color(0xFFF59E0B), // Warm Amber
    const Color(0xFF8B5CF6), // Bright Purple
    const Color(0xFFEC4899), // Hot Pink
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFFF97316), // Vivid Orange
  ];

  /// Missions come from the levels the admin configured for this game.
  late final List<_BalloonMission> _missions;

  @override
  void initState() {
    super.initState();
    final content = widget.content;
    final levels = content.levels;
    _missions = [
      for (var i = 0; i < levels.length; i++)
        _BalloonMission(
          badge: 'MISSION ${i + 1}/${levels.length}'
              '${levels[i].title.isNotEmpty ? ': ${levels[i].title.toUpperCase()}' : ''}',
          title: levels[i].title.isNotEmpty ? levels[i].title : content.game.title,
          prompt: levels[i].prompt.isNotEmpty ? levels[i].prompt : content.game.prompt,
          targets: levels[i].targets,
          distractors: content.distractorsFor(levels[i]),
        ),
    ];
    _startNewGame();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  void _startNewGame() {
    _gameTimer?.cancel();
    _gameTimer = null;
    setState(() {
      _score = 0;
      _lives = 5;
      _currentMissionIndex = 0;
      _missionPops = 0;
      _gameState = 'playing';
      _balloons.clear();
      _confetti.clear();
      _shockwaves.clear();
      _floatingTexts.clear();
      _poppedTargetsThisMission.clear();
      _spawnTimer = 0.2;
    });

    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick(0.016));
  }

  void _triggerVictory() {
    _gameTimer?.cancel();
    _gameTimer = null;
    widget.progressService.addStars(widget.content.game.starsReward);
    if (mounted) {
      setState(() {
        _gameState = 'victory';
      });
    }
  }

  void _triggerGameOver() {
    _gameTimer?.cancel();
    _gameTimer = null;
    if (mounted) {
      setState(() {
        _gameState = 'gameover';
      });
    }
  }

  void _tick(double dt) {
    if (_gameState != 'playing') return;

    final w = _arenaSize.width > 0 ? _arenaSize.width : 360.0;
    final h = _arenaSize.height > 0 ? _arenaSize.height : 600.0;

    // 1. Spawning Balloons Gently
    _spawnTimer -= dt;
    if (_spawnTimer <= 0 && _balloons.where((b) => !b.popped).length < 6) {
      // Slower spawn pace: kids have ample time
      _spawnTimer = 0.85 + _random.nextDouble() * 0.45;
      _spawnSingleBalloon(w, h);
    }

    // 2. Update Balloons (Gentle upward floating, calm speed)
    for (int i = _balloons.length - 1; i >= 0; i--) {
      final b = _balloons[i];
      if (b.popped) {
        _balloons.removeAt(i);
        continue;
      }

      b.y -= b.vy * dt;
      b.wobbleAngle += b.wobbleSpeed * dt;
      b.x += math.sin(b.wobbleAngle) * 0.9;
      // Clamp within screen margins
      b.x = b.x.clamp(b.radius + 12.0, w - b.radius - 12.0);

      // Floated off top of screen
      if (b.y < -b.radius * 2.2) {
        if (b.isTarget) {
          // Missed a target letter! Gentle warning
          _floatingTexts.add(_FloatingText(
            text: 'Missed ${b.text}! 👀',
            color: const Color(0xFFFBBF24),
            x: b.x,
            y: 80,
            vy: -40,
            life: 1.1,
            maxLife: 1.1,
          ));
        }
        _balloons.removeAt(i);
      }
    }

    // 3. Update Confetti Particles (radial burst, rotation, gravity)
    for (int i = _confetti.length - 1; i >= 0; i--) {
      final c = _confetti[i];
      c.x += c.vx * dt;
      c.y += c.vy * dt;
      c.vy += 260.0 * dt; // gravity
      c.vx *= 0.985; // air drag
      c.angle += c.vRot * dt;
      c.life -= dt;
      if (c.life <= 0) {
        _confetti.removeAt(i);
      }
    }

    // 4. Update Blast Shockwaves
    for (int i = _shockwaves.length - 1; i >= 0; i--) {
      final s = _shockwaves[i];
      s.life -= dt;
      final progress = 1.0 - (s.life / s.maxLife).clamp(0.0, 1.0);
      s.currentRadius = s.maxRadius * (0.2 + progress * 0.8);
      if (s.life <= 0) {
        _shockwaves.removeAt(i);
      }
    }

    // 5. Update Floating Feedback Texts
    for (int i = _floatingTexts.length - 1; i >= 0; i--) {
      final t = _floatingTexts[i];
      t.y += t.vy * dt;
      t.life -= dt;
      if (t.life <= 0) {
        _floatingTexts.removeAt(i);
      }
    }

    if (mounted) setState(() {});
  }

  void _spawnSingleBalloon(double w, double h, {double? initialY}) {
    final mission = _missions[_currentMissionIndex];
    final bool isTarget = mission.distractors.isEmpty || _random.nextDouble() < 0.65;
    final String text = isTarget
        ? mission.targets[_random.nextInt(mission.targets.length)]
        : mission.distractors[_random.nextInt(mission.distractors.length)];

    final color = _balloonPalette[_random.nextInt(_balloonPalette.length)];
    final double radius = 38.0 + _random.nextDouble() * 8.0; // 38..46

    // Slower upward speed: 52..82 px/sec (calm, kid-friendly)
    final double vy = 52.0 + _random.nextDouble() * 30.0;
    final double x = radius + 20.0 + _random.nextDouble() * (w - (radius * 2 + 40.0));
    final double y = initialY ?? (h + radius + 15.0);

    _balloons.add(_BalloonItem(
      id: ++_idCounter,
      text: text,
      isTarget: isTarget,
      color: color,
      radius: radius,
      x: x,
      y: y,
      vy: vy,
      wobbleAngle: _random.nextDouble() * math.pi * 2,
      wobbleSpeed: 1.5 + _random.nextDouble() * 1.5,
    ));
  }

  void _onPopTouch(Offset touch) {
    if (_gameState != 'playing') return;

    for (int i = _balloons.length - 1; i >= 0; i--) {
      final b = _balloons[i];
      if (b.popped) continue;

      final dist = (touch - Offset(b.x, b.y)).distance;
      // Generous hitbox (+16 px) so kids can tap easily
      if (dist <= b.radius + 16.0) {
        _popBalloon(b);
        break;
      }
    }
  }

  void _popBalloon(_BalloonItem b) {
    b.popped = true;

    // Haptic pop feedback
    HapticFeedback.lightImpact();

    // 💥 1. Shockwave Blast Ring
    _shockwaves.add(_BlastShockwave(
      x: b.x,
      y: b.y,
      currentRadius: 10,
      maxRadius: b.radius * 2.2,
      color: b.color,
      life: 0.35,
      maxLife: 0.35,
    ));

    // 💥 2. Rich Confetti Explosion Particles (36+ particles)
    _createConfettiBlast(b.x, b.y, b.color, 36);

    if (b.isTarget) {
      // CORRECT TARGET HIT!
      _score += 100;
      _missionPops++;
      _poppedTargetsThisMission.add(b.text.toUpperCase());
      widget.progressService.addStars(1);

      // Cheerful Floating Text
      final cheers = ['+100 ⭐', 'POP! 🎉', 'SUPER! ✨', 'GREAT! 🌟', 'AWESOME! 💫'];
      _floatingTexts.add(_FloatingText(
        text: cheers[_random.nextInt(cheers.length)],
        color: const Color(0xFFFFD166),
        x: b.x,
        y: b.y - 10,
        vy: -75,
        life: 0.95,
        maxLife: 0.95,
        scale: 1.25,
      ));

      if (_missionPops >= _popsPerMission) {
        _advanceToNextMission();
      }
    } else {
      // WRONG DISTRACTOR BALLOON HIT!
      _lives--;
      HapticFeedback.heavyImpact();

      _floatingTexts.add(_FloatingText(
        text: 'Oops! -1 ❤️',
        color: const Color(0xFFEF4444),
        x: b.x,
        y: b.y - 10,
        vy: -60,
        life: 1.0,
        maxLife: 1.0,
        scale: 1.15,
      ));

      if (_lives <= 0) {
        _triggerGameOver();
      }
    }
  }

  void _createConfettiBlast(double x, double y, Color color, int count) {
    for (int i = 0; i < count; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = 80.0 + _random.nextDouble() * 220.0;
      final isSparkle = _random.nextDouble() < 0.35;
      final Color pColor = _random.nextBool()
          ? color
          : (_random.nextBool() ? const Color(0xFFFFD166) : const Color(0xFF38BDF8));

      _confetti.add(_ConfettiParticle(
        x: x,
        y: y,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed - 65.0, // slight upward explosion lift
        color: pColor,
        width: isSparkle ? 4.0 : 6.0 + _random.nextDouble() * 4.0,
        height: isSparkle ? 4.0 : 8.0 + _random.nextDouble() * 5.0,
        angle: _random.nextDouble() * math.pi * 2,
        vRot: (_random.nextDouble() - 0.5) * 14.0,
        life: 0.55 + _random.nextDouble() * 0.45,
        maxLife: 1.0,
        isStar: isSparkle,
      ));
    }
  }

  void _advanceToNextMission() {
    if (_currentMissionIndex < _missions.length - 1) {
      setState(() {
        _currentMissionIndex++;
        _missionPops = 0;
        _poppedTargetsThisMission.clear();
        _balloons.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.stars_rounded, color: Color(0xFFFFD166)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '🎉 Mission Complete! Moving to ${_missions[_currentMissionIndex].title}!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF059669),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      _triggerVictory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeMissionIdx = _currentMissionIndex.clamp(0, _missions.length - 1);
    final currentMission = _missions[safeMissionIdx];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            _arenaSize = Size(constraints.maxWidth, constraints.maxHeight);

            return Stack(
              children: [
                // 1. Background Cover Art with Atmospheric Vignette
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/games/balloon_pop_cover.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
                        ),
                      ),
                    ),
                  ),
                ),

                // Dark atmospheric gradient overlay for readability
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.65),
                          Colors.black.withValues(alpha: 0.25),
                          Colors.black.withValues(alpha: 0.70),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. Interactive Sky Canvas for Balloons, Blast Rings, Confetti & Scores
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanDown: (details) => _onPopTouch(details.localPosition),
                    onPanUpdate: (details) => _onPopTouch(details.localPosition),
                    child: CustomPaint(
                      painter: _BalloonGamePainter(
                        balloons: _balloons,
                        confetti: _confetti,
                        shockwaves: _shockwaves,
                        floatingTexts: _floatingTexts,
                      ),
                    ),
                  ),
                ),

                // 3. Top Header Bar & HIGH-CONTRAST HIGHLIGHTED MISSION BANNER
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      // Navigation & HUD Header
                      _buildTopHeader(),

                      // ⭐ HIGH-CONTRAST VIBRANT QUESTION BANNER (Highlight Qs!)
                      _buildHighlightedQuestionBanner(currentMission),
                    ],
                  ),
                ),

                // 4. Overlays: Victory / Game Over
                if (_gameState == 'victory') _buildVictoryOverlay(),
                if (_gameState == 'gameover') _buildGameOverOverlay(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          // Back Button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 6),

          // Title
          const Expanded(
            child: Text(
              'Balloon Word Pop',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
                shadows: [
                  Shadow(color: Colors.black, blurRadius: 6),
                ],
              ),
            ),
          ),

          // Score Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD166), width: 1.2),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFFD166), size: 18),
                const SizedBox(width: 4),
                Text(
                  '$_score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Lives (Hearts)
          Row(
            children: List.generate(5, (i) {
              return Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Icon(
                  Icons.favorite_rounded,
                  size: 17,
                  color: i < _lives ? const Color(0xFFEF4444) : Colors.white24,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Highlighted Question Banner with High-Contrast Glowing Borders & Live Chips
  Widget _buildHighlightedQuestionBanner(_BalloonMission mission) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        // High contrast deep indigo/slate background with neon border
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF38BDF8), // Glowing Neon Cyan
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.45),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.70),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mission Top Pill Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF7DD3FC), width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flash_on_rounded, color: Color(0xFFFFE066), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      mission.badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),

          // Main Question Prompt (High-Contrast Large Text)
          Text(
            mission.prompt,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFFDE047), // Radiant Sun Yellow for instant readability
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
              height: 1.2,
              shadows: [
                Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Live Target Letter Chips (Shows kids exactly which letters/words to look for!)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: mission.targets.map((target) {
              final isPopped = _poppedTargetsThisMission.contains(target.toUpperCase());
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPopped
                      ? const Color(0xFF10B981).withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isPopped ? const Color(0xFF34D399) : const Color(0xFF38BDF8),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPopped) ...[
                      const Icon(Icons.check_rounded, color: Color(0xFF34D399), size: 12),
                      const SizedBox(width: 2),
                    ],
                    Text(
                      target,
                      style: TextStyle(
                        color: isPopped ? const Color(0xFF6EE7B7) : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 7),

          // Progress Dots / Count
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Progress: $_missionPops / $_popsPerMission Popped',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              ...List.generate(_popsPerMission, (i) {
                final isDone = i < _missionPops;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    isDone ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isDone ? const Color(0xFFFFD166) : Colors.white24,
                    size: 15,
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVictoryOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars_rounded, color: Color(0xFFFFD166), size: 76),
              const SizedBox(height: 12),
              const Text(
                '🏆 VICTORY! 🏆',
                style: TextStyle(color: Color(0xFFFFD166), fontSize: 26, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'All Balloon Missions Cleared!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFD166)),
                ),
                child: Text(
                  'Final Score: $_score Stars ⭐',
                  style: const TextStyle(color: Color(0xFFFFD166), fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BouncyButton(
                    onPressed: _startNewGame,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.replay_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text('Play Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  BouncyButton(
                    onPressed: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text('Back to Arena', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
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
      color: Colors.black.withValues(alpha: 0.88),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.heart_broken_rounded, color: Color(0xFFEF4444), size: 72),
              const SizedBox(height: 12),
              const Text(
                'Out of Lives! 🎈',
                style: TextStyle(color: Color(0xFFEF4444), fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Watch out for distractor balloons and keep popping target letters!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Exit', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 12),
                  BouncyButton(
                    onPressed: _startNewGame,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.replay_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text('Try Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                        ],
                      ),
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

/// Custom Canvas Painter for Balloons, Strings, Blast Rings, Confetti & Floating Texts
class _BalloonGamePainter extends CustomPainter {
  final List<_BalloonItem> balloons;
  final List<_ConfettiParticle> confetti;
  final List<_BlastShockwave> shockwaves;
  final List<_FloatingText> floatingTexts;

  _BalloonGamePainter({
    required this.balloons,
    required this.confetti,
    required this.shockwaves,
    required this.floatingTexts,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 💥 1. Shockwave Rings (Expanding Blast Rings)
    for (final s in shockwaves) {
      final alpha = (s.life / s.maxLife).clamp(0.0, 1.0);
      final ringPaint = Paint()
        ..color = s.color.withValues(alpha: alpha * 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5 * alpha;
      canvas.drawCircle(Offset(s.x, s.y), s.currentRadius, ringPaint);

      // Inner white flash
      final flashPaint = Paint()
        ..color = Colors.white.withValues(alpha: alpha * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(s.x, s.y), s.currentRadius * 0.75, flashPaint);
    }

    // 🎈 2. Floating Balloons with Wavy Strings & Glossy Shading
    for (final b in balloons) {
      if (b.popped) continue;

      canvas.save();
      canvas.translate(b.x, b.y);

      // Wavy String Dangling Down
      final stringPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.65)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke;
      final stringPath = Path()
        ..moveTo(0, b.radius * 1.08)
        ..quadraticBezierTo(
          math.sin(b.wobbleAngle) * 9.0,
          b.radius * 1.55,
          -math.sin(b.wobbleAngle) * 4.0,
          b.radius * 2.15,
        );
      canvas.drawPath(stringPath, stringPaint);

      // Balloon Knot
      final knotPaint = Paint()
        ..color = b.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(0, b.radius * 1.08), 3.5, knotPaint);

      // Soft Dark Drop Shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, 5), width: b.radius * 2.15, height: b.radius * 2.55),
        shadowPaint,
      );

      // Balloon Body (Radial Gradient Shading for 3D Volume)
      final bodyRect = Rect.fromCenter(center: Offset.zero, width: b.radius * 2.15, height: b.radius * 2.55);
      final bodyPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.40),
          radius: 0.9,
          colors: [
            Color.lerp(b.color, Colors.white, 0.35)!,
            b.color,
            Color.lerp(b.color, Colors.black, 0.25)!,
          ],
          stops: const [0.0, 0.65, 1.0],
        ).createShader(bodyRect);
      canvas.drawOval(bodyRect, bodyPaint);

      // Gloss Specular Highlight (Upper Left Curved Glint)
      final glossPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.48)
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(-b.radius * 0.42, -b.radius * 0.48),
          width: b.radius * 0.48,
          height: b.radius * 0.72,
        ),
        glossPaint,
      );

      // Balloon Text (Clear, Bold, High-Contrast)
      final textSpan = TextSpan(
        text: b.text,
        style: TextStyle(
          color: Colors.white,
          fontSize: b.text.length > 3 ? 14 : 24,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.3,
          shadows: const [
            Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(1, 1.5)),
          ],
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));

      canvas.restore();
    }

    // 🎊 3. Confetti Blast Particles (Spinning ribbons, rectangles & stars)
    for (final c in confetti) {
      final alpha = (c.life / c.maxLife).clamp(0.0, 1.0);
      final cPaint = Paint()
        ..color = c.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(c.x, c.y);
      canvas.rotate(c.angle);

      if (c.isStar) {
        // Star Sparkle
        canvas.drawCircle(Offset.zero, c.width, cPaint);
      } else {
        // Confetti Ribbon / Rectangle
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: c.width, height: c.height),
          cPaint,
        );
      }

      canvas.restore();
    }

    // ⭐ 4. Floating Feedback Score & Cheer Texts
    for (final t in floatingTexts) {
      final alpha = (t.life / t.maxLife).clamp(0.0, 1.0);
      final textSpan = TextSpan(
        text: t.text,
        style: TextStyle(
          color: t.color.withValues(alpha: alpha),
          fontSize: 16 * t.scale,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(color: Colors.black.withValues(alpha: alpha * 0.8), blurRadius: 6),
          ],
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(t.x - tp.width / 2, t.y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _BalloonGamePainter oldDelegate) => true;
}
