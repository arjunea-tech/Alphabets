import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/game_content.dart';
import '../../services/progress_service.dart';
import '../../widgets/bouncy_button.dart';
import 'package:flutter/services.dart';

class FlappyWordGame extends StatefulWidget {
  final ProgressService progressService;
  final GameContent content;

  const FlappyWordGame({super.key, required this.progressService, required this.content});

  @override
  State<FlappyWordGame> createState() => _FlappyWordGameState();
}

class _CloudGateWave {
  final String question;
  final String topText;
  final bool topCorrect;
  final String bottomText;
  final bool bottomCorrect;

  _CloudGateWave({
    required this.question,
    required this.topText,
    required this.topCorrect,
    required this.bottomText,
    required this.bottomCorrect,
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

class _BgCloud {
  double x;
  double y;
  double size;
  double speed;

  _BgCloud({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
  });
}

class _FlappyWordGameState extends State<FlappyWordGame> {
  int _score = 100;
  int _lives = 5;
  int _currentWaveIndex = 0;
  String _gameState = 'playing'; // 'playing', 'victory', 'gameover'
  bool _soundEnabled = true;

  // Bird Physics (Smooth, buoyant, kid-friendly)
  final double _birdX = 85.0;
  double _birdY = 230.0;
  double _birdVy = 0.0;
  double _birdAngle = 0.0;
  double _wingAngle = 0.0;
  double _animTimer = 0.0;
  // Gentle floaty gravity and buoyant flap impulse
  final double _gravity = 280.0;
  final double _flapStrength = -240.0;

  // Cloud Gate (Slow, calm, accessible horizontal speed)
  double _gateX = 420.0;
  final double _gateSpeed = 85.0; // Slow, giving kids 4-5 seconds per gate
  bool _gatePassed = false;
  bool _isAdvancingGate = false;
  double _gateTimer = 0.0;
  String? _feedbackText;
  Color? _feedbackColor;

  Timer? _loopTimer;
  final List<_Particle> _particles = [];
  final List<_BgCloud> _bgClouds = [];

  /// One cloud gate per admin level: a random target is the correct gate,
  /// a random distractor the wrong one, placed top/bottom at random.
  late final List<_CloudGateWave> _defaultWaves;

  @override
  void initState() {
    super.initState();
    final content = widget.content;
    final rng = Random();
    _defaultWaves = [
      for (final level in content.levels)
        () {
          final correct = level.targets[rng.nextInt(level.targets.length)];
          final wrongPool = content.distractorsFor(level);
          final wrong = wrongPool.isEmpty ? '?' : wrongPool[rng.nextInt(wrongPool.length)];
          final correctOnTop = rng.nextBool();
          return _CloudGateWave(
            question: level.prompt.isNotEmpty ? level.prompt : content.game.prompt,
            topText: correctOnTop ? correct : wrong,
            topCorrect: correctOnTop,
            bottomText: correctOnTop ? wrong : correct,
            bottomCorrect: !correctOnTop,
          );
        }(),
    ];
    _initBgClouds();
    _startFlappyGame();
  }

  @override
  void dispose() {
    _loopTimer?.cancel();
    super.dispose();
  }

  void _initBgClouds() {
    final random = Random();
    _bgClouds.clear();
    for (int i = 0; i < 5; i++) {
      _bgClouds.add(_BgCloud(
        x: random.nextDouble() * 360,
        y: 40 + random.nextDouble() * 200,
        size: 26 + random.nextDouble() * 20,
        speed: 15 + random.nextDouble() * 20,
      ));
    }
  }

  void _startFlappyGame() {
    _loopTimer?.cancel();
    _loopTimer = null;
    setState(() {
      _score = 100;
      _lives = 5;
      _currentWaveIndex = 0;
      _gameState = 'playing';
      _birdY = 220.0;
      _birdVy = 0.0;
      _birdAngle = 0.0;
      _wingAngle = 0.0;
      _animTimer = 0.0;
      _gateX = 390.0;
      _gatePassed = false;
      _isAdvancingGate = false;
      _feedbackText = null;
      _particles.clear();
    });

    // 60 FPS fixed delta loop (16ms)
    _loopTimer = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick(0.016));
  }

  void _triggerVictory() {
    _loopTimer?.cancel();
    _loopTimer = null;
    try { widget.progressService.addStars(widget.content.game.starsReward); } catch (_) {}
    if (mounted) {
      setState(() {
        _gameState = 'victory';
        _feedbackText = null;
        _isAdvancingGate = false;
      });
    }
  }

  void _triggerGameOver() {
    _loopTimer?.cancel();
    _loopTimer = null;
    if (mounted) {
      setState(() {
        _gameState = 'gameover';
        _feedbackText = null;
        _isAdvancingGate = false;
      });
    }
  }

  void _flap() {
    if (_gameState != 'playing') return;

    if (_soundEnabled) {
      try {
        HapticFeedback.lightImpact();
        SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }

    setState(() {
      // Immediate buoyant lift
      _birdVy = _flapStrength;
      _birdAngle = -0.38;
      _wingAngle = -0.8;
      _addFeathers();
    });
  }

  void _addFeathers() {
    final random = Random();
    for (int i = 0; i < 5; i++) {
      _particles.add(_Particle(
        x: _birdX - 12,
        y: _birdY + (random.nextDouble() - 0.5) * 10,
        vx: -35 - random.nextDouble() * 30,
        vy: 15 + random.nextDouble() * 35,
        color: i % 2 == 0 ? const Color(0xFFFEF08A) : Colors.white70,
        radius: 2.5 + random.nextDouble() * 1.8,
        life: 0.40,
        maxLife: 0.40,
      ));
    }
  }

  void _addBurst(double x, double y, Color color) {
    final random = Random();
    for (int i = 0; i < 24; i++) {
      final angle = random.nextDouble() * pi * 2;
      final speed = 35.0 + random.nextDouble() * 140.0;
      _particles.add(_Particle(
        x: x,
        y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        color: color,
        radius: 2.5 + random.nextDouble() * 3.0,
        life: 0.50,
        maxLife: 0.50,
      ));
    }
  }

  void _tick(double dt) {
    if (_gameState != 'playing') return;

    _animTimer += dt;

    // 1. Bird Physics: Gentle, smooth, responsive
    _birdVy += _gravity * dt;
    _birdY += _birdVy * dt;
    _birdAngle = (_birdAngle + 1.1 * dt).clamp(-0.40, 0.60);

    // Dynamic wing flap speed: flaps faster when rising
    final flapSpeed = _birdVy < 0 ? 24.0 : 10.0;
    _wingAngle = sin(_animTimer * flapSpeed) * 0.65;

    // 🌟 Rainbow jetstream trail behind bird
    const rainbowColors = [
      Color(0xFFEF4444),
      Color(0xFFF97316),
      Color(0xFFFBBF24),
      Color(0xFF10B981),
      Color(0xFF38BDF8),
      Color(0xFFA855F7),
    ];
    final colorIdx = (_animTimer * 12).floor() % rainbowColors.length;
    _particles.add(_Particle(
      x: _birdX - 16,
      y: _birdY + sin(_animTimer * 6) * 3,
      vx: -60 - Random().nextDouble() * 20,
      vy: (Random().nextDouble() - 0.5) * 15,
      color: rainbowColors[colorIdx],
      radius: 2.4 + Random().nextDouble() * 1.5,
      life: 0.38,
      maxLife: 0.38,
    ));

    // Floor and Ceiling bounds
    // Instead of instant death, bounce gently off grass floor!
    if (_birdY > 430) {
      _birdY = 430;
      _birdVy = -160.0; // Soft trampoline bounce!
      _birdAngle = -0.25;
      _lives--;
      _feedbackText = 'BOUNCED OFF GROUND! -1 ❤️';
      _feedbackColor = const Color(0xFFEF4444);
      if (_soundEnabled) {
        try {
          HapticFeedback.vibrate();
          SystemSound.play(SystemSoundType.alert);
        } catch (_) {}
      }
      if (_lives <= 0) {
        _triggerGameOver();
        return;
      }
    } else if (_birdY < 25) {
      _birdY = 25;
      _birdVy = 20.0;
    }

    // 2. Background Clouds drift
    for (var c in _bgClouds) {
      c.x -= c.speed * dt;
      if (c.x < -60) c.x = 400;
    }

    // 3. Cloud Gate Movement (Slow, Relaxing Pace)
    _gateX -= _gateSpeed * dt;

    // Deterministic in-frame gate advancement
    if (_isAdvancingGate) {
      _gateTimer -= dt;
      if (_gateTimer <= 0) {
        _isAdvancingGate = false;
        _advanceGate();
      }
    }

    // Gate collision checking
    final safeWaveIdx = _currentWaveIndex.clamp(0, _defaultWaves.length - 1);
    final wave = _defaultWaves[safeWaveIdx];
    const topCloudY = 125.0;
    const bottomCloudY = 325.0;
    const cloudRadius = 55.0;

    if (!_gatePassed && !_isAdvancingGate && _gateX <= _birdX + 25 && _gateX >= _birdX - 45) {
      // Check collision with top cloud
      final distTop = (Offset(_birdX, _birdY) - Offset(_gateX, topCloudY)).distance;
      if (distTop <= cloudRadius + 22) {
        _gatePassed = true;
        _resolveChoice(wave.topCorrect, wave.topText, Offset(_gateX, topCloudY));
      }

      // Check collision with bottom cloud
      final distBottom = (Offset(_birdX, _birdY) - Offset(_gateX, bottomCloudY)).distance;
      if (!_gatePassed && distBottom <= cloudRadius + 22) {
        _gatePassed = true;
        _resolveChoice(wave.bottomCorrect, wave.bottomText, Offset(_gateX, bottomCloudY));
      }
    }

    // Passed gate without touching either cloud
    if (!_gatePassed && !_isAdvancingGate && _gateX < _birdX - 55) {
      _gatePassed = true;
      _lives--;
      _feedbackText = 'MISSED CLOUD GATE! -1 ❤️';
      _feedbackColor = const Color(0xFFEF4444);
      if (_soundEnabled) {
        try {
          HapticFeedback.vibrate();
          SystemSound.play(SystemSoundType.alert);
        } catch (_) {}
      }
      if (_lives <= 0) {
        _triggerGameOver();
        return;
      } else {
        _isAdvancingGate = true;
        _gateTimer = 0.65;
      }
    }

    // Recycle gate when off screen
    if (!_isAdvancingGate && _gateX < -150) {
      _advanceGate();
    }

    // 4. Update Particles
    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.life -= dt;
      if (p.life <= 0) {
        _particles.removeAt(i);
      }
    }

    if (mounted) setState(() {});
  }

  void _resolveChoice(bool isCorrect, String choiceWord, Offset hitPos) {
    if (_isAdvancingGate || _gameState != 'playing') return;

    if (isCorrect) {
      // CORRECT GATE!
      _score += 100;
      _feedbackText = 'GREAT FLYING! +100 ⭐';
      _feedbackColor = const Color(0xFF10B981);
      _addBurst(hitPos.dx, hitPos.dy, const Color(0xFF38BDF8));
      _addBurst(hitPos.dx, hitPos.dy, const Color(0xFFFBBF24));
      if (_soundEnabled) {
        try {
          HapticFeedback.mediumImpact();
          SystemSound.play(SystemSoundType.click);
        } catch (_) {}
      }
    } else {
      // WRONG GATE!
      _lives--;
      _feedbackText = 'WRONG CLOUD! -1 ❤️';
      _feedbackColor = const Color(0xFFEF4444);
      _addBurst(hitPos.dx, hitPos.dy, const Color(0xFFEF4444));
      if (_soundEnabled) {
        try {
          HapticFeedback.vibrate();
          SystemSound.play(SystemSoundType.alert);
        } catch (_) {}
      }
      if (_lives <= 0) {
        _triggerGameOver();
        return;
      }
    }

    _isAdvancingGate = true;
    _gateTimer = 0.70;
  }

  void _advanceGate() {
    if (!mounted) return;
    _isAdvancingGate = false;
    _gateTimer = 0.0;

    if (_currentWaveIndex < _defaultWaves.length - 1) {
      setState(() {
        _currentWaveIndex++;
        _gateX = 390.0;
        _gatePassed = false;
        _feedbackText = null;
        _isAdvancingGate = false;
      });
    } else {
      // Completed all 5 gates!
      _triggerVictory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeWaveIdx = _currentWaveIndex.clamp(0, _defaultWaves.length - 1);
    final wave = _defaultWaves[safeWaveIdx];

    return Scaffold(
      backgroundColor: const Color(0xFF0284C7),
      body: SafeArea(
        child: Column(
          children: [
            // Top HUD
            _buildTopHud(),

            // Glowing High-Contrast Question Banner
            _buildQuestionBanner(wave),

            // Flappy Flight Arena (Tap anywhere on screen to flap!)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) => _flap(),
                child: Stack(
                  children: [
                    // Sky, Clouds, Gates, Bird, Rainbow Canvas
                    CustomPaint(
                      painter: _FlappySkyPainter(
                        bgClouds: _bgClouds,
                        birdX: _birdX,
                        birdY: _birdY,
                        birdAngle: _birdAngle,
                        wingAngle: _wingAngle,
                        gateX: _gateX,
                        wave: wave,
                        particles: _particles,
                      ),
                      child: Container(),
                    ),

                    // Floating Alert / Feedback
                    if (_feedbackText != null)
                      Positioned(
                        top: 20,
                        left: 20,
                        right: 20,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              color: (_feedbackColor ?? Colors.amber).withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              _feedbackText!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Tap / Flap Button at Bottom
                    Positioned(
                      bottom: 12,
                      left: 24,
                      right: 24,
                      child: BouncyButton(
                        onPressed: _flap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.flight_takeoff_rounded, color: Colors.white, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'FLAP WINGS 🕊️  (Tap Anywhere To Fly)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Overlays
                    if (_gameState == 'victory') Positioned.fill(child: _buildVictoryOverlay()),
                    if (_gameState == 'gameover') Positioned.fill(child: _buildGameOverOverlay()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHud() {
    return Container(
      color: const Color(0xFF0F172A),
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

          // Score
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 22),
              const SizedBox(width: 4),
              Text(
                '$_score',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ],
          ),

          // Gate Number
          Text(
            'GATE ${(_currentWaveIndex.clamp(0, _defaultWaves.length - 1)) + 1}/${_defaultWaves.length}',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 0.6,
            ),
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

  Widget _buildQuestionBanner(_CloudGateWave wave) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0F172A),
            const Color(0xFF1E293B),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF38BDF8),
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Target Gate Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF38BDF8), width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flight_rounded, color: Color(0xFF38BDF8), size: 14),
                const SizedBox(width: 6),
                Text(
                  'TARGET: GATE ${(_currentWaveIndex.clamp(0, _defaultWaves.length - 1)) + 1}/${_defaultWaves.length}',
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Big Bold Question
          Text(
            wave.question,
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
        ],
      ),
    );
  }

  Widget _buildVictoryOverlay() {
    return Material(
      color: Colors.transparent,
      child: Container(
        color: Colors.black87,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events_rounded, color: Color(0xFFFBBF24), size: 72),
                const SizedBox(height: 14),
                const Text(
                  '🎉 SKYWAYS MASTER!',
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You navigated all 5 cloud gates successfully!',
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
                    style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 18, fontWeight: FontWeight.bold),
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
                      onPressed: _startFlappyGame,
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
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Material(
      color: Colors.transparent,
      child: Container(
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
                  'Keep tapping to flap wings and fly to the correct cloud!',
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
                    style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 18, fontWeight: FontWeight.bold),
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
                      onPressed: _startFlappyGame,
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
      ),
    );
  }
}

// --- CANVAS PAINTER (BIRD, ANIMATED WINGS, RAINBOW JETSTREAM, CLOUD GATES) ---
class _FlappySkyPainter extends CustomPainter {
  final List<_BgCloud> bgClouds;
  final double birdX;
  final double birdY;
  final double birdAngle;
  final double wingAngle;
  final double gateX;
  final _CloudGateWave wave;
  final List<_Particle> particles;

  _FlappySkyPainter({
    required this.bgClouds,
    required this.birdX,
    required this.birdY,
    required this.birdAngle,
    required this.wingAngle,
    required this.gateX,
    required this.wave,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Sky Gradient Background
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0284C7), Color(0xFF38BDF8), Color(0xFFBAE6FD)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    // 2. Background Floating Clouds
    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: 0.35);
    for (final c in bgClouds) {
      canvas.drawCircle(Offset(c.x, c.y), c.size, cloudPaint);
      canvas.drawCircle(Offset(c.x + c.size * 0.7, c.y + 4), c.size * 0.75, cloudPaint);
      canvas.drawCircle(Offset(c.x - c.size * 0.7, c.y + 4), c.size * 0.75, cloudPaint);
    }

    // 3. Rainbow Particles & Feathers
    for (final p in particles) {
      final a = (p.life / p.maxLife).clamp(0.0, 1.0);
      final pPaint = Paint()..color = p.color.withValues(alpha: a);
      canvas.drawCircle(Offset(p.x, p.y), p.radius * a, pPaint);
    }

    // 4. Moving Cloud Gate Pair (Top Cloud & Bottom Cloud)
    _drawCloudGate(canvas, gateX, 125.0, wave.topText);
    _drawCloudGate(canvas, gateX, 325.0, wave.bottomText);

    // 5. Animated Cute Flappy Bird
    canvas.save();
    canvas.translate(birdX, birdY);
    canvas.rotate(birdAngle);

    _drawCuteBird(canvas, wingAngle);

    canvas.restore();

    // 6. Grass Bounce Floor at Bottom
    final grassPaint = Paint()..color = const Color(0xFF16A34A);
    canvas.drawRect(Rect.fromLTWH(0, size.height - 35, size.width, 35), grassPaint);
    final grassBorder = Paint()
      ..color = const Color(0xFF4ADE80)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height - 35), Offset(size.width, size.height - 35), grassBorder);
  }

  void _drawCloudGate(Canvas canvas, double cx, double cy, String text) {
    const w = 150.0;
    const h = 75.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: w, height: h),
      const Radius.circular(24),
    );

    // Cloud Drop Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 6), width: w, height: h),
        const Radius.circular(24),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.15),
    );

    // Fluffy Puffs
    final puffPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx - 45, cy - 18), 26, puffPaint);
    canvas.drawCircle(Offset(cx, cy - 24), 30, puffPaint);
    canvas.drawCircle(Offset(cx + 45, cy - 18), 26, puffPaint);

    // Cloud Pill Base
    canvas.drawRRect(rrect, puffPaint);

    // Soft Blue Glow Border
    final borderPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(rrect, borderPaint);

    // Word Text Inside Cloud
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  void _drawCuteBird(Canvas canvas, double wingAngle) {
    // Bird Body (Bright Golden Yellow)
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.25, -0.25),
        radius: 0.85,
        colors: [Color(0xFFFEF08A), Color(0xFFFACC15), Color(0xFFEAB308)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: 24));
    canvas.drawCircle(Offset.zero, 24, bodyPaint);

    // Soft Rosy Cheeks
    canvas.drawCircle(const Offset(6, 6), 6, Paint()..color = const Color(0xFFFB7185).withValues(alpha: 0.5));

    // Big Cute Eye
    canvas.drawCircle(const Offset(8, -6), 7, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(10, -6), 4.2, Paint()..color = Colors.black87);
    canvas.drawCircle(const Offset(11, -8), 1.8, Paint()..color = Colors.white);

    // Orange Beak
    final beakPath = Path()
      ..moveTo(16, -2)
      ..lineTo(28, 2)
      ..lineTo(16, 7)
      ..close();
    canvas.drawPath(beakPath, Paint()..color = const Color(0xFFEA580C));

    // Animated Flapping Wing
    canvas.save();
    canvas.translate(-8, 2);
    canvas.rotate(wingAngle);

    final wingPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-18, -14, -14, 8)
      ..quadraticBezierTo(-6, 12, 0, 0)
      ..close();
    canvas.drawPath(
      wingPath,
      Paint()
        ..color = const Color(0xFFCA8A04)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      wingPath,
      Paint()
        ..color = const Color(0xFFFEF08A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FlappySkyPainter oldDelegate) => true;
}
