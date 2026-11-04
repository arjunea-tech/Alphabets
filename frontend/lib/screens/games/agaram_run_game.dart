import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../data/english_letters_data.dart';
import '../../models/agaram_run_game_model.dart';
import '../../models/letter_model.dart';
import '../../services/progress_service.dart';
import '../../widgets/bouncy_button.dart';

enum MovementDirection {
  idle,
  left,
  right,
}

class FloatingScoreText {
  double x;
  double y;
  final String text;
  final Color color;
  double life;
  final double maxLife;

  FloatingScoreText({
    required this.x,
    required this.y,
    required this.text,
    required this.color,
    this.life = 0.8,
    this.maxLife = 0.8,
  });
}

class AgaramRunGame extends StatefulWidget {
  final ProgressService? progressService;
  final int initialLevel;

  const AgaramRunGame({
    super.key,
    this.progressService,
    this.initialLevel = 1,
  });

  @override
  State<AgaramRunGame> createState() => _AgaramRunGameState();
}

class _AgaramRunGameState extends State<AgaramRunGame>
    with TickerProviderStateMixin {
  final Random _rng = Random();

  // 60 FPS Physics Ticker
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  // Game States: 'start', 'playing', 'paused', 'victory', 'game_over'
  String _gameState = 'start';

  // Level & World State
  late int _currentLevelIndex;
  late List<AgaramRunLevel> _levels;
  AgaramRunLevel get _currentLevel => _levels[_currentLevelIndex];

  late List<PlatformTile> _platforms;
  late List<CollectibleItem> _collectibles;
  late List<ObstacleItem> _obstacles;

  // Target Educational Letter Prompt
  int _currentTargetLetterIdx = 0;
  LetterModel get _currentTargetLetter {
    if (_currentLevel.targetLetters.isEmpty) {
      return englishLettersList.first;
    }
    return _currentLevel.targetLetters[_currentTargetLetterIdx % _currentLevel.targetLetters.length];
  }

  // Player Physics & Animation
  double _playerX = 60.0;
  double _playerY = 220.0;
  double _playerVx = 0.0;
  double _playerVy = 0.0;
  bool _isGrounded = false;
  double _coyoteTimer = 0.0;
  int _facingDirection = 1; // 1 = right, -1 = left
  double _runLegPhase = 0.0;
  double _invulnerableTimer = 0.0;
  double _animTime = 0.0;

  // Stats
  int _score = 0;
  int _starsCollected = 0;
  int _lettersCollected = 0;
  int _lives = 3;

  // Camera Horizontal Scroll
  double _cameraX = 0.0;

  // Controls
  MovementDirection _moveDirection = MovementDirection.idle;

  // Modern Particle System & Floating Texts
  final List<AgaramRunParticle> _particles = [];
  final List<FloatingScoreText> _floatingScores = [];

  // Feedback Toast
  String? _toastMessage;
  Color _toastColor = const Color(0xFF10B981);
  double _toastOpacity = 0.0;

  // HUD Pulse Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _currentLevelIndex = (widget.initialLevel - 1).clamp(0, 3);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _buildLevels();
    _loadLevelData();

    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _buildLevels() {
    final letters = englishLettersList;

    // Modern 3300px World with Variety of Floating Platforms
    final level1Platforms = <PlatformTile>[
      // Start Platform
      PlatformTile(id: 1, x: 0, y: 320, width: 440, height: 140, type: PlatformType.ground),

      // Stepping stones
      PlatformTile(id: 2, x: 500, y: 260, width: 140, height: 36, type: PlatformType.floating),
      PlatformTile(id: 3, x: 700, y: 210, width: 140, height: 36, type: PlatformType.floating),

      // Mid ground platform 2
      PlatformTile(id: 4, x: 890, y: 320, width: 500, height: 140, type: PlatformType.ground),

      // Futuristic moving hover platform over gap
      PlatformTile(
        id: 5,
        x: 1450,
        y: 230,
        width: 150,
        height: 32,
        type: PlatformType.moving,
        minX: 1430,
        maxX: 1720,
        speedX: 85,
      ),

      // Ground platform 3
      PlatformTile(id: 6, x: 1780, y: 320, width: 560, height: 140, type: PlatformType.ground),

      // Elevated floating route
      PlatformTile(id: 7, x: 2100, y: 195, width: 150, height: 34, type: PlatformType.floating),
      PlatformTile(id: 8, x: 2320, y: 155, width: 150, height: 34, type: PlatformType.floating),

      // Finish Ground Runway
      PlatformTile(id: 9, x: 2520, y: 320, width: 800, height: 140, type: PlatformType.ground),
    ];

    // Collectibles (Target Letters + Bonus Stars)
    final level1Collectibles = <CollectibleItem>[
      CollectibleItem(id: 1, x: 220, y: 250, type: CollectibleType.targetLetter, letterModel: letters[0]), // A
      CollectibleItem(id: 2, x: 340, y: 230, type: CollectibleType.bonusStar),

      CollectibleItem(id: 3, x: 570, y: 195, type: CollectibleType.targetLetter, letterModel: letters[1]), // B
      CollectibleItem(id: 4, x: 770, y: 145, type: CollectibleType.targetLetter, letterModel: letters[2]), // C

      CollectibleItem(id: 5, x: 1050, y: 245, type: CollectibleType.targetLetter, letterModel: letters[3]), // D
      CollectibleItem(id: 6, x: 1200, y: 215, type: CollectibleType.bonusStar),

      CollectibleItem(id: 7, x: 1580, y: 165, type: CollectibleType.targetLetter, letterModel: letters[4]), // E
      CollectibleItem(id: 8, x: 1920, y: 245, type: CollectibleType.targetLetter, letterModel: letters[5]), // F

      CollectibleItem(id: 9, x: 2175, y: 130, type: CollectibleType.targetLetter, letterModel: letters[6]), // G
      CollectibleItem(id: 10, x: 2395, y: 90, type: CollectibleType.targetLetter, letterModel: letters[7]), // H

      CollectibleItem(id: 11, x: 2650, y: 245, type: CollectibleType.targetLetter, letterModel: letters[8]), // I
      CollectibleItem(id: 12, x: 2850, y: 245, type: CollectibleType.targetLetter, letterModel: letters[9]), // J
      CollectibleItem(id: 13, x: 3020, y: 245, type: CollectibleType.targetLetter, letterModel: letters[10]), // K
    ];

    // Modern Obstacles
    final level1Obstacles = <ObstacleItem>[
      ObstacleItem(id: 1, x: 1000, y: 286, width: 34, height: 34, type: ObstacleType.rock),
      ObstacleItem(id: 2, x: 1250, y: 282, width: 36, height: 38, type: ObstacleType.woodenLog),
      ObstacleItem(id: 3, x: 1980, y: 286, width: 34, height: 34, type: ObstacleType.rock),
      ObstacleItem(
        id: 4,
        x: 2750,
        y: 284,
        width: 36,
        height: 36,
        type: ObstacleType.snailEnemy,
        patrolRange: 75,
      ),
    ];

    _levels = [
      AgaramRunLevel(
        levelNumber: 1,
        title: 'Alphabet Runner',
        subtitle: 'Sunny Meadow Run',
        description: 'Dash, jump, and collect English letters to cross the Finish Line!',
        targetLetters: letters.take(11).toList(),
        worldWidth: 3300,
        platforms: level1Platforms,
        collectibles: level1Collectibles,
        obstacles: level1Obstacles,
        goalX: 3120,
      ),
    ];
  }

  void _loadLevelData() {
    _platforms = _currentLevel.platforms.map((p) => PlatformTile(
      id: p.id,
      x: p.x,
      y: p.y,
      width: p.width,
      height: p.height,
      type: p.type,
      minX: p.minX,
      maxX: p.maxX,
      speedX: p.speedX,
      moveDirection: p.moveDirection,
      primaryColor: p.primaryColor,
      accentColor: p.accentColor,
    )).toList();

    _collectibles = _currentLevel.collectibles.map((c) => CollectibleItem(
      id: c.id,
      x: c.x,
      y: c.y,
      type: c.type,
      letterModel: c.letterModel,
      isCollected: false,
    )).toList();

    _obstacles = _currentLevel.obstacles.map((o) => ObstacleItem(
      id: o.id,
      x: o.x,
      y: o.y,
      width: o.width,
      height: o.height,
      type: o.type,
      patrolRange: o.patrolRange,
      startX: o.startX,
    )).toList();

    _playerX = 60.0;
    _playerY = 220.0;
    _playerVx = 0.0;
    _playerVy = 0.0;
    _isGrounded = false;
    _facingDirection = 1;
    _invulnerableTimer = 0.0;
    _cameraX = 0.0;
    _currentTargetLetterIdx = 0;
    _particles.clear();
    _floatingScores.clear();
  }

  void _startGame() {
    _loadLevelData();
    _resetMovementState();
    setState(() {
      _gameState = 'playing';
      _score = 0;
      _starsCollected = 0;
      _lettersCollected = 0;
      _lives = 3;
      _toastOpacity = 0.0;
    });
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;

    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }

    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    if (dt <= 0 || dt > 0.1 || _gameState != 'playing') return;

    setState(() {
      _animTime += dt;
      _updatePhysics(dt);
      _updateParticles(dt);
      _updateFloatingScores(dt);

      if (_toastOpacity > 0.0) {
        _toastOpacity = (_toastOpacity - dt * 0.9).clamp(0.0, 1.0);
      }
    });
  }

  void _updatePhysics(double dt) {
    // 1. Moving platforms
    for (final p in _platforms) {
      if (p.type == PlatformType.moving) {
        p.x += p.moveDirection * p.speedX * dt;
        if (p.x > p.maxX) {
          p.x = p.maxX;
          p.moveDirection = -1;
        } else if (p.x < p.minX) {
          p.x = p.minX;
          p.moveDirection = 1;
        }
      }
    }

    // 2. Patrol obstacles
    for (final obs in _obstacles) {
      if (obs.type == ObstacleType.snailEnemy && obs.patrolRange > 0) {
        obs.x += obs.patrolDir * 40.0 * dt;
        if (obs.x > obs.startX + obs.patrolRange) {
          obs.x = obs.startX + obs.patrolRange;
          obs.patrolDir = -1;
        } else if (obs.x < obs.startX - obs.patrolRange) {
          obs.x = obs.startX - obs.patrolRange;
          obs.patrolDir = 1;
        }
      }
    }

    // 3. Horizontal movement
    const moveSpeed = 230.0;

    if (_moveDirection == MovementDirection.right) {
      _playerVx = moveSpeed;
      _facingDirection = 1;
      _runLegPhase += dt * 16.0;
      _emitRunningDust();
    } else if (_moveDirection == MovementDirection.left) {
      _playerVx = -moveSpeed;
      _facingDirection = -1;
      _runLegPhase += dt * 16.0;
      _emitRunningDust();
    } else {
      _playerVx = 0.0;
      _runLegPhase = 0.0;
    }

    // 4. Gravity & Jump Physics
    const gravity = 1180.0;
    const maxFallSpeed = 680.0;

    _playerVy = (_playerVy + gravity * dt).clamp(-680.0, maxFallSpeed);

    _playerX += _playerVx * dt;
    _playerY += _playerVy * dt;

    // 5. Collisions with platforms
    const playerWidth = 32.0;
    const playerHeight = 44.0;
    final playerFeet = _playerY + playerHeight;
    final prevFeet = playerFeet - (_playerVy * dt);
    final playerLeft = _playerX;
    final playerRight = _playerX + playerWidth;

    bool foundGround = false;

    for (final p in _platforms) {
      final overlapsX = (playerRight - 4.0) > p.x && (playerLeft + 4.0) < (p.x + p.width);

      if (overlapsX) {
        if (_playerVy >= 0) {
          final isLanding = prevFeet <= p.y + 16.0 && playerFeet >= p.y - 4.0 && playerFeet <= p.y + p.height + 16.0;
          if (isLanding) {
            _playerY = p.y - playerHeight;
            _playerVy = 0.0;
            foundGround = true;

            if (p.type == PlatformType.moving) {
              _playerX += p.moveDirection * p.speedX * dt;
            }
            break;
          }
        }
      }
    }

    _isGrounded = foundGround;
    if (_isGrounded) {
      _coyoteTimer = 0.12;
    } else if (_coyoteTimer > 0) {
      _coyoteTimer = max(0.0, _coyoteTimer - dt);
    }

    // 6. Pitfall Check
    if (_playerY > 440) {
      _takeDamage(isPitFall: true);
    }

    // 7. Invulnerability Blink Timer
    if (_invulnerableTimer > 0) {
      _invulnerableTimer = max(0.0, _invulnerableTimer - dt);
    }

    // 8. Smooth Camera Follow
    const cameraLead = 140.0;
    final targetCameraX = max(0.0, (_playerX - cameraLead));
    _cameraX += (targetCameraX - _cameraX) * min(1.0, dt * 6.0);

    // 9. Collectibles Check
    _checkCollectibleCollisions();

    // 10. Obstacle Check
    _checkObstacleCollisions();

    // 11. Goal Finish Arch Check
    if (_playerX >= _currentLevel.goalX) {
      _onLevelCompleted();
    }
  }

  void _emitRunningDust() {
    if (!_isGrounded) return;
    if (_rng.nextDouble() < 0.28) {
      _particles.add(AgaramRunParticle(
        x: _playerX + (_facingDirection == 1 ? 4 : 28),
        y: _playerY + 42,
        vx: -_facingDirection * (30.0 + _rng.nextDouble() * 40.0),
        vy: -15.0 - _rng.nextDouble() * 25.0,
        color: Colors.white70,
        size: 2.5 + _rng.nextDouble() * 2.0,
        life: 0.35,
        maxLife: 0.35,
      ));
    }
  }

  void _checkCollectibleCollisions() {
    final playerBox = Rect.fromLTWH(_playerX, _playerY, 32, 44);

    for (final item in _collectibles) {
      if (item.isCollected) continue;

      if (playerBox.overlaps(item.rect)) {
        item.isCollected = true;

        if (item.type == CollectibleType.bonusStar) {
          _score += 5;
          _starsCollected++;
          _showToast('Star! +5 ⭐', const Color(0xFFFBBF24));
          _emitSparkles(item.x, item.y, const Color(0xFFFBBF24));
          _floatingScores.add(FloatingScoreText(x: item.x, y: item.y - 10, text: '+5 ⭐', color: const Color(0xFFFBBF24)));
          try { HapticFeedback.lightImpact(); } catch (_) {}
        } else if (item.type == CollectibleType.targetLetter) {
          final letter = item.letter;
          final target = _currentTargetLetter.letter;

          if (letter == target) {
            // Correct Target Letter!
            _score += 15;
            _lettersCollected++;
            _showToast('Great! "$letter" +15 ⭐', const Color(0xFF10B981));
            _emitSparkles(item.x, item.y, const Color(0xFF10B981), isLetterBurst: true);
            _floatingScores.add(FloatingScoreText(x: item.x, y: item.y - 15, text: '+15 "$letter"', color: const Color(0xFF10B981)));

            widget.progressService?.markLetterCompleted(item.letterModel!.id);
            _currentTargetLetterIdx++;
            try { HapticFeedback.mediumImpact(); } catch (_) {}
          } else {
            // Friendly gently reminder, no speech
            _showToast('This is "$letter" - Look for "$target"!', const Color(0xFFF97316));
            _emitSparkles(item.x, item.y, const Color(0xFFF97316));
            try { HapticFeedback.selectionClick(); } catch (_) {}
          }
        }
      }
    }
  }

  void _checkObstacleCollisions() {
    if (_invulnerableTimer > 0) return;

    final playerBox = Rect.fromLTWH(_playerX, _playerY, 32, 44);

    for (final obs in _obstacles) {
      if (playerBox.overlaps(obs.rect)) {
        _takeDamage();
        break;
      }
    }
  }

  void _takeDamage({bool isPitFall = false}) {
    if (_lives <= 0) return;

    _lives--;
    _invulnerableTimer = 1.6;

    if (isPitFall) {
      final safePlat = _platforms.firstWhere(
        (p) => p.x <= _playerX && p.type == PlatformType.ground,
        orElse: () => _platforms.first,
      );
      _playerX = safePlat.x + 30;
      _playerY = safePlat.y - 50;
      _playerVx = 0.0;
      _playerVy = 0.0;
    }

    _showToast('Watch out! ❤️ -1', const Color(0xFFEF4444));
    try { HapticFeedback.heavyImpact(); } catch (_) {}

    if (_lives <= 0) {
      _onGameOver();
    }
  }

  void _triggerJump() {
    if (_isGrounded || _coyoteTimer > 0) {
      _playerVy = -480.0;
      _isGrounded = false;
      _coyoteTimer = 0.0;
      try { HapticFeedback.mediumImpact(); } catch (_) {}
      _emitJumpDust(_playerX + 16, _playerY + 44);
    }
  }

  void _resetMovementState() {
    _moveDirection = MovementDirection.idle;
    _playerVx = 0.0;
    _playerVy = 0.0;
    _runLegPhase = 0.0;
    _coyoteTimer = 0.0;
  }

  void _onLevelCompleted() {
    setState(() {
      _gameState = 'victory';
      _resetMovementState();
    });

    widget.progressService?.addStars(15);
    widget.progressService?.recordGameCompleted(3);
    try { HapticFeedback.heavyImpact(); } catch (_) {}
  }

  void _onGameOver() {
    setState(() {
      _gameState = 'game_over';
      _resetMovementState();
    });
  }

  void _showToast(String msg, Color color) {
    setState(() {
      _toastMessage = msg;
      _toastColor = color;
      _toastOpacity = 1.0;
    });
  }

  void _emitJumpDust(double x, double y) {
    for (int i = 0; i < 9; i++) {
      final angle = (pi / 6) + _rng.nextDouble() * (2 * pi / 3);
      final speed = 35.0 + _rng.nextDouble() * 65.0;
      _particles.add(AgaramRunParticle(
        x: x,
        y: y,
        vx: cos(angle) * speed * (_rng.nextBool() ? 1 : -1),
        vy: -(sin(angle) * speed).abs(),
        color: Colors.white70,
        size: 3.0 + _rng.nextDouble() * 2.5,
        life: 0.35,
        maxLife: 0.35,
      ));
    }
  }

  void _emitSparkles(double x, double y, Color color, {bool isLetterBurst = false}) {
    final count = isLetterBurst ? 24 : 12;
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 60.0 + _rng.nextDouble() * 140.0;
      _particles.add(AgaramRunParticle(
        x: x,
        y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        color: i % 2 == 0 ? color : Colors.white,
        size: 2.8 + _rng.nextDouble() * 3.5,
        life: 0.55,
        maxLife: 0.55,
        isStar: _rng.nextBool(),
      ));
    }
  }

  void _updateParticles(double dt) {
    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 180.0 * dt; // gentle gravity
      p.life -= dt;
      if (p.life <= 0) {
        _particles.removeAt(i);
      }
    }
  }

  void _updateFloatingScores(double dt) {
    for (int i = _floatingScores.length - 1; i >= 0; i--) {
      final f = _floatingScores[i];
      f.y -= 40 * dt;
      f.life -= dt;
      if (f.life <= 0) {
        _floatingScores.removeAt(i);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0284C7),
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Modern 2D Parallax World & Game Canvas
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapDown: (details) {
                  // Tap on right half of screen triggers jump
                  final screenW = MediaQuery.of(context).size.width;
                  if (details.localPosition.dx > screenW * 0.55 && _gameState == 'playing') {
                    _triggerJump();
                  }
                },
                child: CustomPaint(
                  painter: _ModernRunnerWorldPainter(
                    cameraX: _cameraX,
                    worldWidth: _currentLevel.worldWidth,
                    platforms: _platforms,
                    collectibles: _collectibles,
                    obstacles: _obstacles,
                    goalX: _currentLevel.goalX,
                    playerX: _playerX,
                    playerY: _playerY,
                    facingDirection: _facingDirection,
                    isGrounded: _isGrounded,
                    runLegPhase: _runLegPhase,
                    isInvulnerable: _invulnerableTimer > 0,
                    particles: _particles,
                    floatingScores: _floatingScores,
                    targetLetter: _currentTargetLetter.letter,
                    animTime: _animTime,
                  ),
                ),
              ),
            ),

            // 2. Modern Glassmorphic In-Game HUD Header (NO MIC / SPEAKER ICON)
            if (_gameState == 'playing')
              Positioned(
                top: 8,
                left: 12,
                right: 12,
                child: _buildModernHUDHeader(),
              ),

            // 3. Ergonomic Touch Controls
            if (_gameState == 'playing')
              Positioned(
                bottom: 12,
                left: 16,
                right: 16,
                child: _buildModernTouchControls(),
              ),

            // 4. Floating Feedback Toast
            if (_toastOpacity > 0.0 && _toastMessage != null)
              Positioned(
                top: 76,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: Opacity(
                      opacity: _toastOpacity,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: _toastColor.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          _toastMessage!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Overlays
            if (_gameState == 'start') _buildStartScreen(),
            if (_gameState == 'paused') _buildPauseScreen(),
            if (_gameState == 'victory') _buildVictoryScreen(),
            if (_gameState == 'game_over') _buildGameOverScreen(),
          ],
        ),
      ),
    );
  }

  // Modern Glassmorphic HUD Header
  Widget _buildModernHUDHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.75),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            ),
          ),

          // Glowing Target Letter Pill (NO MIC / SPEAKER ICON)
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'TARGET: ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white70,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    _currentTargetLetter.letter,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Hearts & Score
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 3 Hearts
              Row(
                children: List.generate(3, (idx) {
                  return Icon(
                    idx < _lives ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: idx < _lives ? const Color(0xFFEF4444) : Colors.white24,
                    size: 18,
                  );
                }),
              ),
              const SizedBox(width: 8),

              // Score Stars
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 16),
                    const SizedBox(width: 3),
                    Text(
                      '$_score',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              // Pause Button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _gameState = 'paused';
                    _resetMovementState();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.pause_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Modern Ergonomic Touch Controls
  Widget _buildModernTouchControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left & Right D-Pad Controls
        Row(
          children: [
            _buildModernControlButton(
              icon: Icons.arrow_back_ios_new_rounded,
              isActive: _moveDirection == MovementDirection.left,
              onTap: () {
                setState(() {
                  _moveDirection = MovementDirection.left;
                });
              },
            ),
            const SizedBox(width: 14),
            _buildModernControlButton(
              icon: Icons.arrow_forward_ios_rounded,
              isActive: _moveDirection == MovementDirection.right,
              onTap: () {
                setState(() {
                  _moveDirection = MovementDirection.right;
                });
              },
            ),
          ],
        ),

        // Modern Jump Button
        _buildModernJumpButton(),
      ],
    );
  }

  Widget _buildModernControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF38BDF8).withOpacity(0.4) : Colors.black.withOpacity(0.45),
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? const Color(0xFF38BDF8) : Colors.white.withOpacity(0.35),
            width: 2.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildModernJumpButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _triggerJump(),
      onTap: _triggerJump,
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF97316), Color(0xFFEA580C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEA580C).withOpacity(0.55),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 30),
              Text(
                'JUMP',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Modern Start Screen
  Widget _buildStartScreen() {
    return Container(
      color: Colors.black.withOpacity(0.65),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFF38BDF8), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mascot / Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF38BDF8), Color(0xFF0284C7)]),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                  child: const Center(
                    child: Icon(Icons.directions_run_rounded, color: Colors.white, size: 48),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'ALPHABET RUNNER',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Collect the target letters and dash to the finish line!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 24),

                // Controls Tutorial
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(children: [
                        Icon(Icons.touch_app_rounded, color: Color(0xFF38BDF8), size: 18),
                        SizedBox(width: 6),
                        Text('◀ ▶ Move', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      ]),
                      Row(children: [
                        Icon(Icons.arrow_upward_rounded, color: Color(0xFFF97316), size: 18),
                        SizedBox(width: 6),
                        Text('▲ Jump', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                BouncyButton(
                  onPressed: _startGame,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text(
                        'START RUNNING 🏃',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Modern Pause Screen
  Widget _buildPauseScreen() {
    return Container(
      color: Colors.black.withOpacity(0.65),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('GAME PAUSED', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 20),
              BouncyButton(
                onPressed: () => setState(() => _gameState = 'playing'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF38BDF8), Color(0xFF0284C7)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('Resume', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              BouncyButton(
                onPressed: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('Exit Game', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Modern Victory Screen
  Widget _buildVictoryScreen() {
    return Container(
      color: Colors.black.withOpacity(0.78),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFFBBF24), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events_rounded, color: Color(0xFFFBBF24), size: 68),
              const SizedBox(height: 12),
              const Text(
                'RUN COMPLETE! 🎉',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'You reached the goal line and collected your letters!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(children: [
                      const Text('LETTERS', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('$_lettersCollected', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                    ]),
                    Column(children: [
                      const Text('SCORE', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('$_score pts', style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 18, fontWeight: FontWeight.w900)),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BouncyButton(
                    onPressed: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text('Back to Games', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  BouncyButton(
                    onPressed: _startGame,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
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

  // Modern Game Over Screen
  Widget _buildGameOverScreen() {
    return Container(
      color: Colors.black.withOpacity(0.78),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFEF4444), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.heart_broken_rounded, color: Color(0xFFEF4444), size: 64),
              const SizedBox(height: 12),
              const Text('OUT OF LIVES', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('Jump over obstacles and pits to keep running!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BouncyButton(
                    onPressed: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text('Back to Games', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  BouncyButton(
                    onPressed: _startGame,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
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

// --------------------------------------------------------------------------
// MODERN WORLD PAINTER
// --------------------------------------------------------------------------
class _ModernRunnerWorldPainter extends CustomPainter {
  final double cameraX;
  final double worldWidth;
  final List<PlatformTile> platforms;
  final List<CollectibleItem> collectibles;
  final List<ObstacleItem> obstacles;
  final double goalX;
  final double playerX;
  final double playerY;
  final int facingDirection;
  final bool isGrounded;
  final double runLegPhase;
  final bool isInvulnerable;
  final List<AgaramRunParticle> particles;
  final List<FloatingScoreText> floatingScores;
  final String targetLetter;
  final double animTime;

  _ModernRunnerWorldPainter({
    required this.cameraX,
    required this.worldWidth,
    required this.platforms,
    required this.collectibles,
    required this.obstacles,
    required this.goalX,
    required this.playerX,
    required this.playerY,
    required this.facingDirection,
    required this.isGrounded,
    required this.runLegPhase,
    required this.isInvulnerable,
    required this.particles,
    required this.floatingScores,
    required this.targetLetter,
    required this.animTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Dynamic Modern Sky Gradient
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0284C7), Color(0xFF38BDF8), Color(0xFFBAE6FD)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    // 2. Glowing Sun with Corona
    final sunOffset = Offset(w * 0.8 - (cameraX * 0.05) % (w * 0.4), h * 0.22);
    final coronaPaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFFFEF08A).withOpacity(0.85), const Color(0xFFFDE047).withOpacity(0.0)],
      ).createShader(Rect.fromCircle(center: sunOffset, radius: 55));
    canvas.drawCircle(sunOffset, 55, coronaPaint);
    canvas.drawCircle(sunOffset, 22, Paint()..color = const Color(0xFFFEF08A));

    // 3. Parallax Floating Clouds
    _drawParallaxClouds(canvas, size, cameraX * 0.12);

    // 4. Parallax Mountain Range (Layer 1: 0.22 scroll)
    _drawParallaxMountains(canvas, size, cameraX * 0.22);

    // 5. Parallax Lush Cartoon Hills (Layer 2: 0.48 scroll)
    _drawParallaxHills(canvas, size, cameraX * 0.48);

    // World Foreground (1.0 full camera translation)
    canvas.save();
    canvas.translate(-cameraX, 0);

    // 6. Modern Island Platforms
    for (final p in platforms) {
      _drawModernPlatform(canvas, p);
    }

    // 7. Grand Victory Portal
    _drawGoalPortal(canvas, goalX);

    // 8. Modern Obstacles
    for (final obs in obstacles) {
      _drawModernObstacle(canvas, obs);
    }

    // 9. Modern Glassmorphic Collectibles
    for (final item in collectibles) {
      if (!item.isCollected) {
        _drawModernCollectible(canvas, item);
      }
    }

    // 10. Modern Runner Character
    _drawModernPlayer(canvas);

    // 11. Particles
    for (final p in particles) {
      final alpha = (p.life / p.maxLife).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withOpacity(alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x, p.y), p.size * alpha, paint);
    }

    // 12. Floating Score Numbers
    for (final f in floatingScores) {
      final alpha = (f.life / f.maxLife).clamp(0.0, 1.0);
      final textSpan = TextSpan(
        text: f.text,
        style: TextStyle(
          color: f.color.withOpacity(alpha),
          fontSize: 16,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(color: Colors.black.withOpacity(0.6 * alpha), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(f.x - (tp.width / 2), f.y));
    }

    canvas.restore();
  }

  void _drawParallaxClouds(Canvas canvas, Size size, double offset) {
    final cloudPaint = Paint()..color = Colors.white.withOpacity(0.72);
    final cloudShadowPaint = Paint()..color = const Color(0xFFBAE6FD).withOpacity(0.5);

    for (double x = -100; x <= size.width + 200; x += 180) {
      final posX = (x - (offset % 600));
      final posY = 40.0 + sin((x + offset) * 0.01) * 15.0;

      // Soft shadow
      canvas.drawCircle(Offset(posX, posY + 5), 26, cloudShadowPaint);
      canvas.drawCircle(Offset(posX + 24, posY + 3), 20, cloudShadowPaint);

      // Cloud puffs
      canvas.drawCircle(Offset(posX, posY), 26, cloudPaint);
      canvas.drawCircle(Offset(posX + 22, posY - 2), 20, cloudPaint);
      canvas.drawCircle(Offset(posX - 20, posY + 4), 18, cloudPaint);
    }
  }

  void _drawParallaxMountains(Canvas canvas, Size size, double offset) {
    final mountainPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF60A5FA), Color(0xFF93C5FD)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, size.height * 0.45, size.width, size.height * 0.55));

    final path = Path();
    path.moveTo(0, size.height);
    for (double x = 0; x <= size.width + 120; x += 90) {
      final worldPos = x + (offset % 400);
      final mY = size.height * 0.52 + sin(worldPos * 0.015) * 36.0;
      path.lineTo(x, mY);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, mountainPaint);
  }

  void _drawParallaxHills(Canvas canvas, Size size, double offset) {
    final hillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF34D399), Color(0xFF059669)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, size.height * 0.60, size.width, size.height * 0.40));

    final path = Path();
    path.moveTo(0, size.height);
    for (double x = 0; x <= size.width + 120; x += 70) {
      final worldPos = x + (offset % 300);
      final hY = size.height * 0.64 + sin(worldPos * 0.02) * 22.0;
      path.lineTo(x, hY);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, hillPaint);
  }

  void _drawModernPlatform(Canvas canvas, PlatformTile p) {
    final rect = p.rect;

    // Platform Drop Shadow for depth
    final shadowRect = Rect.fromLTWH(p.x + 4, p.y + 10, p.width - 8, p.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(shadowRect, const Radius.circular(16)),
      Paint()..color = Colors.black.withOpacity(0.22)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    if (p.type == PlatformType.ground) {
      // Rounded 3D Earth Island
      final bodyPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF5D4037), Color(0xFF3E2723)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(14)), bodyPaint);

      // Lush Glossy Emerald Grass Cap
      final grassRect = Rect.fromLTWH(p.x, p.y, p.width, 22);
      final grassPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF34D399), Color(0xFF059669)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(grassRect);
      canvas.drawRRect(RRect.fromRectAndRadius(grassRect, const Radius.circular(12)), grassPaint);

      // Glossy Top Highlight Strip
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(p.x + 4, p.y + 2, p.width - 8, 4), const Radius.circular(4)),
        Paint()..color = Colors.white.withOpacity(0.45),
      );
    } else {
      // Floating / Moving Island
      final isMoving = p.type == PlatformType.moving;
      final ledgeColor1 = isMoving ? const Color(0xFF0EA5E9) : const Color(0xFFD97706);
      final ledgeColor2 = isMoving ? const Color(0xFF0369A1) : const Color(0xFFB45309);

      final ledgePaint = Paint()
        ..shader = LinearGradient(
          colors: [ledgeColor1, ledgeColor2],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(14)), ledgePaint);

      // Neon Top Strip
      final topStripRect = Rect.fromLTWH(p.x, p.y, p.width, 10);
      canvas.drawRRect(
        RRect.fromRectAndRadius(topStripRect, const Radius.circular(10)),
        Paint()..color = isMoving ? const Color(0xFF7DD3FC) : const Color(0xFFFDE68A),
      );

      // Futuristic Thruster Energy Glow for moving platform
      if (isMoving) {
        final thrusterGlow = Paint()
          ..color = const Color(0xFF38BDF8).withOpacity(0.65)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(Offset(p.x + p.width * 0.25, p.y + p.height + 4), 6, thrusterGlow);
        canvas.drawCircle(Offset(p.x + p.width * 0.75, p.y + p.height + 4), 6, thrusterGlow);
      }
    }
  }

  void _drawGoalPortal(Canvas canvas, double gx) {
    // Futuristic Checkered Neon Victory Portal
    final p1 = Rect.fromLTWH(gx, 150, 18, 170);
    final p2 = Rect.fromLTWH(gx + 100, 150, 18, 170);

    final pillarPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(p1);

    canvas.drawRRect(RRect.fromRectAndRadius(p1, const Radius.circular(8)), pillarPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(p2, const Radius.circular(8)), pillarPaint);

    // Rainbow Portal Banner
    final bannerRect = Rect.fromLTWH(gx - 8, 130, 134, 32);
    final bannerPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFEC4899), Color(0xFF8B5CF6), Color(0xFF3B82F6)],
      ).createShader(bannerRect);
    canvas.drawRRect(RRect.fromRectAndRadius(bannerRect, const Radius.circular(12)), bannerPaint);

    // Finish Text
    const textSpan = TextSpan(
      text: 'FINISH 🏁',
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.8),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(gx + 59 - (tp.width / 2), 137));
  }

  void _drawModernObstacle(Canvas canvas, ObstacleItem obs) {
    if (obs.type == ObstacleType.rock) {
      // Faceted 3D Crystal Boulder
      final r = obs.rect;
      final crystalPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF94A3B8), Color(0xFF475569)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(r);
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(10)), crystalPaint);

      // Facet Highlight
      canvas.drawCircle(Offset(obs.x + 10, obs.y + 10), 5, Paint()..color = Colors.white.withOpacity(0.55));
    } else if (obs.type == ObstacleType.woodenLog) {
      final logPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFB45309), Color(0xFF78350F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(obs.rect);
      canvas.drawRRect(RRect.fromRectAndRadius(obs.rect, const Radius.circular(8)), logPaint);
    } else if (obs.type == ObstacleType.snailEnemy) {
      // Cute Modern Robotic/Cartoon Snail
      final shellCenter = Offset(obs.x + 18, obs.y + 16);
      final shellPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFC2410C)],
        ).createShader(Rect.fromCircle(center: shellCenter, radius: 14));
      canvas.drawCircle(shellCenter, 14, shellPaint);

      // Body & Eye
      canvas.drawOval(Rect.fromLTWH(obs.x + 2, obs.y + 20, 32, 14), Paint()..color = const Color(0xFFFBBF24));
      canvas.drawCircle(Offset(obs.x + (obs.patrolDir == 1 ? 30 : 6), obs.y + 16), 3, Paint()..color = Colors.black87);
    }
  }

  void _drawModernCollectible(Canvas canvas, CollectibleItem item) {
    // Gentle floating bobbing
    final floatY = item.y + sin(animTime * 3.5 + item.id) * 5.0;
    final center = Offset(item.x, floatY);

    if (item.type == CollectibleType.bonusStar) {
      // 3D Faceted Golden Star
      final starGlow = Paint()
        ..color = const Color(0xFFFBBF24).withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(center, 18, starGlow);

      final starPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFEF08A), Color(0xFFF59E0B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromCircle(center: center, radius: 18));
      canvas.drawCircle(center, 18, starPaint);

      const textSpan = TextSpan(text: '⭐', style: TextStyle(fontSize: 20));
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(center.dx - (tp.width / 2), center.dy - (tp.height / 2)));
    } else {
      final isTarget = item.letter == targetLetter;

      // Outer Pulsing Halo if target letter
      if (isTarget) {
        final pulseHalo = Paint()
          ..color = const Color(0xFF10B981).withOpacity(0.65)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
        canvas.drawCircle(center, 26, pulseHalo);

        // Rotating sparkle ring
        canvas.drawCircle(
          center,
          24,
          Paint()
            ..color = const Color(0xFF6EE7B7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );
      }

      // 3D Glassmorphic Letter Orb
      final orbPaint = Paint()
        ..shader = LinearGradient(
          colors: isTarget
              ? [const Color(0xFF10B981), const Color(0xFF047857)]
              : [const Color(0xFF38BDF8), const Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromCircle(center: center, radius: 21));
      canvas.drawCircle(center, 21, orbPaint);

      // Glass specular highlight
      canvas.drawCircle(
        Offset(center.dx - 6, center.dy - 6),
        7,
        Paint()..color = Colors.white.withOpacity(0.48),
      );

      // Crisp High-Contrast Letter
      final textSpan = TextSpan(
        text: item.letter,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          shadows: [
            Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(center.dx - (tp.width / 2), center.dy - (tp.height / 2)));
    }
  }

  void _drawModernPlayer(Canvas canvas) {
    if (isInvulnerable && (DateTime.now().millisecond % 200 < 100)) {
      return; // Damage flash
    }

    final px = playerX + 16;
    final py = playerY + 22;

    canvas.save();
    canvas.translate(px, py);
    if (facingDirection == -1) {
      canvas.scale(-1, 1);
    }

    // Invulnerability Protective Shield Bubble
    if (isInvulnerable) {
      final shieldPaint = Paint()
        ..color = const Color(0xFFFBBF24).withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset.zero, 28, shieldPaint);
      canvas.drawCircle(
        Offset.zero,
        28,
        Paint()..color = const Color(0xFFFBBF24)..style = PaintingStyle.stroke..strokeWidth = 2,
      );
    }

    // 1. Sporty Runner Hoodie / Body
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(const Rect.fromLTWH(-14, -6, 28, 26));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-14, -6, 28, 26), const Radius.circular(10)), bodyPaint);

    // White athletic stripe
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-3, -4, 6, 22), const Radius.circular(3)), Paint()..color = Colors.white70);

    // 2. Cartoon Face (Cute round head)
    final headPaint = Paint()..color = const Color(0xFFFFCC80);
    canvas.drawCircle(const Offset(0, -14), 14, headPaint);

    // Blushing cheeks
    canvas.drawCircle(const Offset(6, -11), 3.5, Paint()..color = Colors.pinkAccent.withOpacity(0.5));

    // Big Sparkly Cartoon Eyes
    canvas.drawCircle(const Offset(4, -14), 3, Paint()..color = const Color(0xFF0F172A));
    canvas.drawCircle(const Offset(5, -15), 1, Paint()..color = Colors.white);

    // Happy Smile
    canvas.drawArc(
      const Rect.fromLTWH(1, -12, 6, 6),
      0,
      pi,
      false,
      Paint()..color = const Color(0xFFDC2626)..style = PaintingStyle.stroke..strokeWidth = 1.4,
    );

    // 3. Cool Sporty Backwards Runner Cap
    final capPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
      ).createShader(const Rect.fromLTWH(-13, -26, 26, 16));
    canvas.drawArc(
      const Rect.fromLTWH(-13, -27, 26, 18),
      pi,
      pi,
      true,
      capPaint,
    );

    // Cap Visor sticking backwards
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-18, -19, 10, 4), const Radius.circular(2)),
      Paint()..color = const Color(0xFF991B1B),
    );

    // 4. Animated Athletic Running Legs with Sneakers
    final legSwing = isGrounded ? sin(runLegPhase) * 8.0 : 5.0;
    final legPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    // Left leg
    canvas.drawLine(const Offset(-5, 16), Offset(-5 - legSwing, 26), legPaint);
    // Right leg
    canvas.drawLine(const Offset(5, 16), Offset(5 + legSwing, 26), legPaint);

    // Red & White Sneakers
    final shoePaint = Paint()..color = const Color(0xFFEF4444);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-9 - legSwing, 24, 10, 5), const Radius.circular(2)), shoePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(1 + legSwing, 24, 10, 5), const Radius.circular(2)), shoePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ModernRunnerWorldPainter oldDelegate) => true;
}
