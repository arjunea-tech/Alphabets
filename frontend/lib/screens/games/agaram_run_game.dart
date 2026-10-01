import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/uyir_data.dart';
import '../../models/agaram_run_game_model.dart';
import '../../models/letter_model.dart';
import '../../services/audio_service.dart';
import '../../services/progress_service.dart';
import '../../widgets/bouncy_button.dart';

enum MovementDirection {
  idle,
  left,
  right,
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
  // Services
  final AudioService _audioService = AudioService.instance;
  final Random _rng = Random();

  // Game Engine 60fps Ticker
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  // Game Flow States: 'start', 'playing', 'paused', 'victory', 'game_over'
  String _gameState = 'start';
  bool _isMuted = false;

  // Level & World State
  late int _currentLevelIndex;
  late List<AgaramRunLevel> _levels;
  AgaramRunLevel get _currentLevel => _levels[_currentLevelIndex];

  // Active Level Entities
  late List<PlatformTile> _platforms;
  late List<CollectibleItem> _collectibles;
  late List<ObstacleItem> _obstacles;

  // Target Educational Letter Prompt
  int _currentTargetLetterIdx = 0;
  LetterModel get _currentTargetLetter =>
      _currentLevel.targetLetters[_currentTargetLetterIdx % _currentLevel.targetLetters.length];

  // Player Physics State
  double _playerX = 60.0;
  double _playerY = 220.0;
  double _playerVx = 0.0;
  double _playerVy = 0.0;
  bool _isGrounded = false;
  double _coyoteTimer = 0.0;
  int _facingDirection = 1; // 1 = right, -1 = left
  double _runLegPhase = 0.0;
  double _invulnerableTimer = 0.0; // Flash when taking damage

  // Player Stats
  int _score = 0;
  int _starsCollected = 0;
  int _lettersCollected = 0;
  int _lives = 3;

  // Camera Horizontal Scroll
  double _cameraX = 0.0;

  // Movement Direction State (One-tap continuous movement)
  MovementDirection _moveDirection = MovementDirection.idle;

  // Particle System
  final List<AgaramRunParticle> _particles = [];

  // Feedback Toast
  String? _toastMessage;
  Color _toastColor = const Color(0xFFFFD54F);
  double _toastOpacity = 0.0;

  // Animations
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _isMuted = _audioService.isMuted;
    _currentLevelIndex = (widget.initialLevel - 1).clamp(0, 3);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _buildLevels();
    _loadLevelData();

    // Start 60 FPS physics ticker
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // LEVEL DEFINITIONS
  // --------------------------------------------------------------------------
  void _buildLevels() {
    // Level 1: Uyir Letters (Short & Long vowels)
    final uyirLetters = uyirLettersList;

    // Build Level 1 World Layout (Length: 3200 logical pixels)
    final level1Platforms = <PlatformTile>[
      // Start Landing
      PlatformTile(id: 1, x: 0, y: 320, width: 420, height: 120, type: PlatformType.ground),
      
      // First floating stepping stones
      PlatformTile(id: 2, x: 480, y: 260, width: 140, height: 32, type: PlatformType.floating),
      PlatformTile(id: 3, x: 680, y: 210, width: 130, height: 32, type: PlatformType.floating),
      
      // Ground segment 2
      PlatformTile(id: 4, x: 860, y: 320, width: 500, height: 120, type: PlatformType.ground),
      
      // Moving platform over chasm
      PlatformTile(
        id: 5,
        x: 1420,
        y: 240,
        width: 140,
        height: 28,
        type: PlatformType.moving,
        minX: 1400,
        maxX: 1680,
        speedX: 70,
      ),

      // Ground segment 3
      PlatformTile(id: 6, x: 1750, y: 320, width: 550, height: 120, type: PlatformType.ground),
      
      // High floating path with bonus stars
      PlatformTile(id: 7, x: 2050, y: 190, width: 150, height: 30, type: PlatformType.floating),
      PlatformTile(id: 8, x: 2260, y: 150, width: 150, height: 30, type: PlatformType.floating),

      // Final stretch to the Agaram Goal Finish Arch
      PlatformTile(id: 9, x: 2450, y: 320, width: 750, height: 120, type: PlatformType.ground),
    ];

    // Collectibles (Target Uyir Letters + Bonus Stars)
    final level1Collectibles = <CollectibleItem>[
      // Uyir Letter 1: அ (Spaced for early collection)
      CollectibleItem(id: 1, x: 200, y: 260, type: CollectibleType.targetLetter, letterModel: uyirLetters[0]),
      // Star (Clear space before first jump at x=420)
      CollectibleItem(id: 2, x: 290, y: 240, type: CollectibleType.bonusStar),

      // Target: ஆ on floating platform 2 & Target: இ on platform 3
      CollectibleItem(id: 3, x: 540, y: 200, type: CollectibleType.targetLetter, letterModel: uyirLetters[1]),
      CollectibleItem(id: 4, x: 745, y: 150, type: CollectibleType.targetLetter, letterModel: uyirLetters[2]), // இ

      // Ground segment 2: Letter ஈ placed with generous approach
      CollectibleItem(id: 5, x: 1080, y: 245, type: CollectibleType.targetLetter, letterModel: uyirLetters[3]),
      // Star in air arc
      CollectibleItem(id: 6, x: 1150, y: 220, type: CollectibleType.bonusStar),

      // Moving ledge letter: உ
      CollectibleItem(id: 7, x: 1540, y: 175, type: CollectibleType.targetLetter, letterModel: uyirLetters[4]),

      // Letters: ஊ, எ, ஏ, ஐ
      CollectibleItem(id: 8, x: 1860, y: 260, type: CollectibleType.targetLetter, letterModel: uyirLetters[5]),
      CollectibleItem(id: 9, x: 2125, y: 125, type: CollectibleType.targetLetter, letterModel: uyirLetters[6]),
      CollectibleItem(id: 10, x: 2335, y: 85, type: CollectibleType.targetLetter, letterModel: uyirLetters[7]),
      
      // Final Stretch Letters: ஒ, ஓ, ஔ
      CollectibleItem(id: 11, x: 2580, y: 260, type: CollectibleType.targetLetter, letterModel: uyirLetters[8]),
      CollectibleItem(id: 12, x: 2800, y: 260, type: CollectibleType.targetLetter, letterModel: uyirLetters[9]),
      CollectibleItem(id: 13, x: 2980, y: 260, type: CollectibleType.targetLetter, letterModel: uyirLetters[10]),
    ];

    // Obstacles (Spaced naturally with clear approach & landing areas)
    final level1Obstacles = <ObstacleItem>[
      // Rock spaced well after platform 4 landing
      ObstacleItem(id: 1, x: 990, y: 288, width: 30, height: 32, type: ObstacleType.rock),
      // Wooden log spaced with runway before chasm
      ObstacleItem(id: 2, x: 1220, y: 285, width: 32, height: 35, type: ObstacleType.woodenLog),
      ObstacleItem(id: 3, x: 1960, y: 288, width: 30, height: 32, type: ObstacleType.rock),
      ObstacleItem(
        id: 4,
        x: 2700,
        y: 286,
        width: 34,
        height: 34,
        type: ObstacleType.snailEnemy,
        patrolRange: 60,
      ),
    ];

    _levels = [
      AgaramRunLevel(
        levelNumber: 1,
        title: 'உயிர் எழுத்துகள்',
        subtitle: 'கிராமத்து ஓட்டம்',
        description: 'ஓடி விளையாடி 12 உயிர் எழுத்துகளையும் சேகரித்து அகரம் இலக்கை அடையுங்கள்!',
        targetLetters: uyirLetters.take(12).toList(),
        worldWidth: 3200,
        platforms: level1Platforms,
        collectibles: level1Collectibles,
        obstacles: level1Obstacles,
        goalX: 3060,
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

    _playTargetLetterPronunciation();
  }

  // --------------------------------------------------------------------------
  // GAME LOOP (60 FPS PHYSICS TICK)
  // --------------------------------------------------------------------------
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
      _updatePhysics(dt);
      _updateParticles(dt);

      // Toast timer fade
      if (_toastOpacity > 0.0) {
        _toastOpacity = (_toastOpacity - dt * 0.8).clamp(0.0, 1.0);
      }
    });
  }

  void _updatePhysics(double dt) {
    // 1. Update Moving Platforms
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

    // 2. Update Patrol Obstacles
    for (final obs in _obstacles) {
      if (obs.type == ObstacleType.snailEnemy && obs.patrolRange > 0) {
        obs.x += obs.patrolDir * 35.0 * dt;
        if (obs.x > obs.startX + obs.patrolRange) {
          obs.x = obs.startX + obs.patrolRange;
          obs.patrolDir = -1;
        } else if (obs.x < obs.startX - obs.patrolRange) {
          obs.x = obs.startX - obs.patrolRange;
          obs.patrolDir = 1;
        }
      }
    }

    // 3. Horizontal Movement Physics (One-tap continuous movement)
    const moveSpeed = 210.0;

    if (_moveDirection == MovementDirection.right) {
      _playerVx = moveSpeed;
      _facingDirection = 1;
      _runLegPhase += dt * 14.0;
    } else if (_moveDirection == MovementDirection.left) {
      _playerVx = -moveSpeed;
      _facingDirection = -1;
      _runLegPhase += dt * 14.0;
    } else {
      _playerVx = 0.0;
      _runLegPhase = 0.0;
    }

    // 4. Gravity & Vertical Physics
    const gravity = 1100.0;
    const maxFallSpeed = 650.0;

    _playerVy = (_playerVy + gravity * dt).clamp(-650.0, maxFallSpeed);

    // Apply movement delta
    _playerX += _playerVx * dt;
    _playerY += _playerVy * dt;

    // 5. Platform AABB Collision Detection
    const playerWidth = 32.0;
    const playerHeight = 44.0;
    final playerFeet = _playerY + playerHeight;
    final prevFeet = playerFeet - (_playerVy * dt);
    final playerLeft = _playerX;
    final playerRight = _playerX + playerWidth;

    bool foundGround = false;

    for (final p in _platforms) {
      // Horizontal overlap check with a small side margin
      final overlapsX = (playerRight - 4.0) > p.x && (playerLeft + 4.0) < (p.x + p.width);

      if (overlapsX) {
        // Landing check: falling/stationary and feet crossing top surface
        if (_playerVy >= 0) {
          final isLanding = prevFeet <= p.y + 14.0 && playerFeet >= p.y - 2.0 && playerFeet <= p.y + p.height + 16.0;
          if (isLanding) {
            _playerY = p.y - playerHeight;
            _playerVy = 0.0;
            foundGround = true;

            // Stand and ride on moving platform
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

    // 6. Chasm Pit Fall Check
    if (_playerY > 440) {
      _takeDamage(isPitFall: true);
    }

    // 7. Clamp world bounds
    _playerX = _playerX.clamp(0.0, _currentLevel.worldWidth);

    // 8. Camera Smooth Tracking
    final targetCamX = (_playerX - 120.0).clamp(0.0, _currentLevel.worldWidth - 360.0);
    _cameraX += (targetCamX - _cameraX) * min(1.0, dt * 6.0);

    // 9. Invulnerability Timer Tick
    if (_invulnerableTimer > 0) {
      _invulnerableTimer = max(0.0, _invulnerableTimer - dt);
    }

    // 10. Check Collectible Collisions
    _checkCollectibleCollisions();

    // 11. Check Obstacle Collisions
    _checkObstacleCollisions();

    // 12. Check Goal Finish Line
    if (_playerX >= _currentLevel.goalX) {
      _onLevelCompleted();
    }
  }

  // --------------------------------------------------------------------------
  // INTERACTIVE GAME MECHANICS (COLLECTIBLES, OBSTACLES, AUDIO)
  // --------------------------------------------------------------------------
  void _checkCollectibleCollisions() {
    final playerBox = Rect.fromLTWH(_playerX, _playerY, 32, 44);

    for (final item in _collectibles) {
      if (item.isCollected) continue;

      if (playerBox.overlaps(item.rect)) {
        item.isCollected = true;

        if (item.type == CollectibleType.bonusStar) {
          // Bonus star collected!
          _score += 5;
          _starsCollected++;
          _showToast('நட்சத்திரம்! +5', Colors.amberAccent);
          _emitSparkles(item.x, item.y, Colors.amberAccent);
        } else if (item.type == CollectibleType.targetLetter) {
          final letter = item.letter;
          final target = _currentTargetLetter.letter;

          if (letter == target) {
            // Correct Target Letter Collected!
            _score += 10;
            _lettersCollected++;
            _showToast('அருமை! "$letter" +10', const Color(0xFF00E676));
            _emitSparkles(item.x, item.y, const Color(0xFF00E676), isLetterBurst: true);

            // Play authentic native Tamil letter pronunciation
            _audioService.playLetterSound(
              context,
              letter: item.letter,
              word: item.word,
              audioPath: item.audioPath,
              showIndicator: false,
            );

            // Record letter learning progress
            widget.progressService?.markLetterCompleted(item.letterModel!.id);

            // Advance target letter
            _currentTargetLetterIdx++;
          } else {
            // Wrong Letter Touched (Friendly gentle feedback)
            _showToast('இது "$letter" - இலக்கு: "$target" 😊', const Color(0xFFFF8A65));
            _audioService.playRetryFeedback(context);
            _emitSparkles(item.x, item.y, const Color(0xFFFF8A65));
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
    _invulnerableTimer = 1.6; // 1.6 seconds blink invulnerability

    if (isPitFall) {
      // Respawn back onto the nearest safe ground platform behind player
      final safePlat = _platforms.firstWhere(
        (p) => p.x <= _playerX && p.type == PlatformType.ground,
        orElse: () => _platforms.first,
      );
      _playerX = safePlat.x + 30;
      _playerY = safePlat.y - 50;
      _playerVx = 0.0;
      _playerVy = 0.0;
    } else {
      // Small knockback
      _playerVx = -_facingDirection * 150.0;
      _playerVy = -240.0;
    }

    _showToast('கவனம்! ❤️ -1', Colors.pinkAccent);
    _audioService.playRetryFeedback(context);

    if (_lives <= 0) {
      _onGameOver();
    }
  }

  void _triggerJump() {
    if ((_isGrounded || _coyoteTimer > 0) && _gameState == 'playing') {
      setState(() {
        _playerVy = -500.0;
        _isGrounded = false;
        _coyoteTimer = 0.0;
        _emitJumpDust(_playerX + 16, _playerY + 44);
      });
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

    widget.progressService?.recordGameCompleted(3);
    _audioService.playStarReward(context);
  }

  void _onGameOver() {
    setState(() {
      _gameState = 'game_over';
      _resetMovementState();
    });
  }

  void _playTargetLetterPronunciation() {
    if (!_isMuted && _gameState == 'playing') {
      _audioService.playLetterSound(
        context,
        letter: _currentTargetLetter.letter,
        word: _currentTargetLetter.word,
        audioPath: _currentTargetLetter.audioPath,
        showIndicator: false,
      );
    }
  }

  void _showToast(String msg, Color color) {
    setState(() {
      _toastMessage = msg;
      _toastColor = color;
      _toastOpacity = 1.0;
    });
  }

  // -------------------------------------------------------------
  // PARTICLE SYSTEM
  // -------------------------------------------------------------
  void _emitJumpDust(double x, double y) {
    for (int i = 0; i < 6; i++) {
      _particles.add(
        AgaramRunParticle(
          x: x,
          y: y,
          vx: (_rng.nextDouble() - 0.5) * 60,
          vy: -_rng.nextDouble() * 30,
          color: Colors.white70,
          size: 4.0 + _rng.nextDouble() * 3,
          life: 0.35,
          maxLife: 0.35,
        ),
      );
    }
  }

  void _emitSparkles(double x, double y, Color color, {bool isLetterBurst = false}) {
    final count = isLetterBurst ? 18 : 8;
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 60.0 + _rng.nextDouble() * 120.0;
      _particles.add(
        AgaramRunParticle(
          x: x,
          y: y,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          color: color,
          size: 6.0 + _rng.nextDouble() * 6,
          life: 0.6,
          maxLife: 0.6,
          isStar: i.isEven,
        ),
      );
    }
  }

  void _updateParticles(double dt) {
    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.life -= dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      if (p.life <= 0) {
        _particles.removeAt(i);
      }
    }
  }

  // --------------------------------------------------------------------------
  // BUILD UI
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF81D4FA),
      body: SafeArea(
        child: Stack(
          children: [
            // 1. 2D Parallax World & Game Canvas
            Positioned.fill(
              child: CustomPaint(
                painter: _AgaramWorldPainter(
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
                ),
              ),
            ),

            // 2. In-Game HUD Header (Score, Target Letter, Lives, Level, Pause)
            if (_gameState == 'playing')
              Positioned(
                top: 8,
                left: 14,
                right: 14,
                child: _buildHUDHeader(),
              ),

            // 3. Touch Controls (Large Left, Right, Jump buttons)
            if (_gameState == 'playing')
              Positioned(
                bottom: 12,
                left: 16,
                right: 16,
                child: _buildTouchControls(),
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
                          color: _toastColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
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
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // 5. Start Screen Overlay
            if (_gameState == 'start')
              _buildStartScreen(),

            // 6. Pause Menu Overlay
            if (_gameState == 'paused')
              _buildPauseScreen(),

            // 7. Victory Screen Overlay
            if (_gameState == 'victory')
              _buildVictoryScreen(),

            // 8. Game Over Screen Overlay
            if (_gameState == 'game_over')
              _buildGameOverScreen(),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // IN-GAME HUD
  // --------------------------------------------------------------------------
  Widget _buildHUDHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Exit / Back
        BouncyButton(
          onPressed: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1B5E20), size: 22),
          ),
        ),

        // Target Letter Prompt Capsule: 🎯 "அ எழுத்தை கண்டுபிடி!"
        ScaleTransition(
          scale: _pulseAnim,
          child: GestureDetector(
            onTap: _playTargetLetterPronunciation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF9C4), Colors.white],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFFB300), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎯 ', style: TextStyle(fontSize: 16)),
                  Text(
                    _currentTargetLetter.letter,
                    style: GoogleFonts.catamaran(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFD84315),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'எழுத்தை சேகரி!',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFBF360C),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.volume_up_rounded, color: Color(0xFFFF8F00), size: 16),
                ],
              ),
            ),
          ),
        ),

        // Lives & Score Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF81C784), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lives
              Row(
                children: List.generate(3, (idx) {
                  return Icon(
                    idx < _lives ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: Colors.pinkAccent,
                    size: 16,
                  );
                }),
              ),
              const Icon(Icons.star_rounded, color: Color(0xFFFF9F1C), size: 16),
              const SizedBox(width: 2),
              // Score
              Text(
                '$_score',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFE65100),
                ),
              ),
            ],
          ),
        ),

        // Pause Button
        BouncyButton(
          onPressed: () {
            setState(() {
              _gameState = 'paused';
              _resetMovementState();
            });
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pause_rounded, color: Color(0xFF1B5E20), size: 22),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // TOUCH CONTROLS (LARGE COMFORTABLE MOBILE BUTTONS)
  // --------------------------------------------------------------------------
  Widget _buildTouchControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left & Right D-Pad Controls (One-Tap Direction Switch)
        Row(
          children: [
            // Left Button (◀)
            _buildControlButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () {
                setState(() {
                  _moveDirection = MovementDirection.left;
                });
              },
            ),
            const SizedBox(width: 14),
            // Right Button (▶)
            _buildControlButton(
              icon: Icons.arrow_forward_ios_rounded,
              onTap: () {
                setState(() {
                  _moveDirection = MovementDirection.right;
                });
              },
            ),
          ],
        ),

        // Jump Button (⬆)
        _buildJumpButton(),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.88),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF4CAF50), width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, color: const Color(0xFF2E7D32), size: 32),
        ),
      ),
    );
  }

  Widget _buildJumpButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _triggerJump(),
      onTap: _triggerJump,
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9100), Color(0xFFFF6D00)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6D00).withOpacity(0.45),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 32),
              Text(
                'குதி ⬆',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // START & MODAL SCREENS
  // --------------------------------------------------------------------------
  Widget _buildStartScreen() {
    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8F5E9), Colors.white, Color(0xFFC8E6C9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFF4CAF50), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Game Artwork / Mascot
                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF81C784),
                  ),
                  child: const Center(
                    child: Text('🏃‍♂️', style: TextStyle(fontSize: 52)),
                  ),
                ),
                const SizedBox(height: 12),

                // Title
                const Text(
                  'அகரம் ஓட்டம்',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 6),

                // Subtitle
                const Text(
                  '“ஓடி விளையாடி தமிழ் எழுத்துகளை கற்போம்!”',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Play Button
                BouncyButton(
                  onPressed: _startGame,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E676), Color(0xFF00C853)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00C853).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'விளையாடலாம் ▶',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // How to play button
                TextButton.icon(
                  onPressed: _showHowToPlayDialog,
                  icon: const Icon(Icons.help_outline_rounded, color: Color(0xFF2E7D32), size: 18),
                  label: const Text(
                    'எப்படி விளையாடுவது? 📖',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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

  void _showHowToPlayDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFF1F8E9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Text('📖 ', style: TextStyle(fontSize: 22)),
            Text(
              'எப்படி விளையாடுவது?',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B5E20),
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHowToPlayItem('◀ ▶', 'இடது, வலது ஓடப் பயன்படுத்தவும்'),
            _buildHowToPlayItem('⬆', 'குதித்து மேலே செல்ல அழுத்தவும்'),
            _buildHowToPlayItem('🎯', 'கேட்கப்படும் சரியான தமிழ் எழுத்தை சேகரிக்கவும்'),
            _buildHowToPlayItem('⚠️', 'தடைகளை குதித்து தவிர்க்கவும்'),
            _buildHowToPlayItem('🏁', 'அகரம் முடிவு இலக்கை அடைந்து வெல்லுங்கள்!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('புரிந்தது 👍', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToPlayItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$icon  ', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Color(0xFF33691E), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPauseScreen() {
    return Container(
      color: Colors.black.withOpacity(0.55),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'விளையாட்டு இடைநிறுத்தப்பட்டது',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => setState(() => _gameState = 'playing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('தொடரவும் ▶', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _startGame,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('மீண்டும் தொடங்கு 🔄'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('வெளியேறு 🏠'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVictoryScreen() {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDE7),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFFFD54F), width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 48)),
              const Text(
                'வாழ்த்துகள்!',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFFE65100)),
              ),
              const Text(
                'நீங்கள் முதல் நிலையை முடித்துவிட்டீர்கள்!',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
              ),
              const SizedBox(height: 16),
              Text('இறுதி மதிப்பெண்: $_score', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              Text('சேகரித்த எழுத்துகள்: $_lettersCollected', style: const TextStyle(fontSize: 14)),
              Text('சேகரித்த நட்சத்திரங்கள்: $_starsCollected', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('மீண்டும் விளையாடு', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('முகப்பு'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverScreen() {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.pinkAccent, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('❤️', style: TextStyle(fontSize: 48)),
              const Text(
                'மீண்டும் முயற்சி செய்யலாம்!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.pinkAccent),
              ),
              const SizedBox(height: 8),
              Text('மதிப்பெண்: $_score', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4081),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('மீண்டும் விளையாடு 🔄', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('வெளியேறு 🏠'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// 2D PARALLAX WORLD & ENTITIES PAINTER
// ----------------------------------------------------------------------------

class _AgaramWorldPainter extends CustomPainter {
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

  _AgaramWorldPainter({
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
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Sky Gradient
    final skyShader = const LinearGradient(
      colors: [Color(0xFF81D4FA), Color(0xFFB3E5FC), Color(0xFFE1F5FE)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..shader = skyShader);

    // 2. Parallax Distant Hills (Layer 1: 0.15 scroll speed)
    _drawDistantHills(canvas, size, cameraX * 0.15);

    // 3. Parallax Village Trees & Huts (Layer 2: 0.4 scroll speed)
    _drawVillageScenery(canvas, size, cameraX * 0.4);

    // Transform Canvas for World Foreground (Layer 3: 1.0 full scroll speed)
    canvas.save();
    canvas.translate(-cameraX, 0);

    // 4. Platforms
    for (final p in platforms) {
      _drawPlatform(canvas, p);
    }

    // 5. Goal Finish Arch 🏁 "அகரம் முடிவு"
    _drawGoalArch(canvas, goalX);

    // 6. Obstacles
    for (final obs in obstacles) {
      _drawObstacle(canvas, obs);
    }

    // 7. Collectibles (Target Tamil Letters & Stars)
    for (final item in collectibles) {
      if (!item.isCollected) {
        _drawCollectible(canvas, item);
      }
    }

    // 8. Player Character (Tamil Cartoon Kid)
    _drawPlayer(canvas);

    // 9. Particles
    for (final p in particles) {
      final alpha = (p.life / p.maxLife).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withOpacity(alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x, p.y), p.size * alpha, paint);
    }

    canvas.restore();
  }

  void _drawDistantHills(Canvas canvas, Size size, double offset) {
    final hillPaint = Paint()..color = const Color(0xFFC8E6C9);
    final path = Path();
    path.moveTo(0, size.height);
    for (double x = 0; x <= size.width + 120; x += 100) {
      final worldPos = x + (offset % 200);
      final hillY = size.height * 0.55 + sin(worldPos * 0.02) * 28.0;
      path.lineTo(x, hillY);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, hillPaint);
  }

  void _drawVillageScenery(Canvas canvas, Size size, double offset) {
    final treePaint = Paint()..color = const Color(0xFFA5D6A7);
    for (double x = -60; x <= size.width + 100; x += 140) {
      final posX = x - (offset % 140);
      // Draw simple tree top
      canvas.drawCircle(Offset(posX, size.height * 0.62), 24, treePaint);
    }
  }

  void _drawPlatform(Canvas canvas, PlatformTile p) {
    final rect = p.rect;

    if (p.type == PlatformType.ground) {
      // Ground with grass top
      final groundPaint = Paint()..color = const Color(0xFF795548);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), groundPaint);

      // Lush green top trim
      final grassPaint = Paint()..color = const Color(0xFF4CAF50);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(p.x, p.y, p.width, 16), const Radius.circular(6)),
        grassPaint,
      );
    } else {
      // Floating / Moving Wooden Ledge
      final woodPaint = Paint()..color = p.type == PlatformType.moving ? const Color(0xFFFFB74D) : const Color(0xFF8D6E63);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), woodPaint);

      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), borderPaint);
    }
  }

  void _drawGoalArch(Canvas canvas, double gx) {
    // Two decorative stone pillars
    final pillarPaint = Paint()..color = const Color(0xFFFFF176);
    canvas.drawRect(Rect.fromLTWH(gx, 180, 16, 140), pillarPaint);
    canvas.drawRect(Rect.fromLTWH(gx + 90, 180, 16, 140), pillarPaint);

    // Arch header
    final archPaint = Paint()..color = const Color(0xFFFFB300);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(gx - 8, 160, 122, 28), const Radius.circular(10)),
      archPaint,
    );

    // Finish Text 🏁
    final textSpan = TextSpan(
      text: 'அகரம் முடிவு 🏁',
      style: GoogleFonts.catamaran(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: const Color(0xFFD84315),
      ),
    );
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    textPainter.paint(canvas, Offset(gx + 53 - (textPainter.width / 2), 166));
  }

  void _drawObstacle(Canvas canvas, ObstacleItem obs) {
    if (obs.type == ObstacleType.rock) {
      final rockPaint = Paint()..color = const Color(0xFF78909C);
      canvas.drawOval(obs.rect, rockPaint);
    } else if (obs.type == ObstacleType.woodenLog) {
      final logPaint = Paint()..color = const Color(0xFF6D4C41);
      canvas.drawRRect(RRect.fromRectAndRadius(obs.rect, const Radius.circular(6)), logPaint);
    } else if (obs.type == ObstacleType.snailEnemy) {
      // Cute little snail
      final shellPaint = Paint()..color = const Color(0xFFFF7043);
      canvas.drawCircle(Offset(obs.x + 18, obs.y + 16), 14, shellPaint);
      final bodyPaint = Paint()..color = const Color(0xFFFFD54F);
      canvas.drawOval(Rect.fromLTWH(obs.x + 2, obs.y + 20, 32, 14), bodyPaint);
    }
  }

  void _drawCollectible(Canvas canvas, CollectibleItem item) {
    final cx = item.x;
    final cy = item.y;

    if (item.type == CollectibleType.bonusStar) {
      // Draw 5-point star
      final starPaint = Paint()..color = Colors.amber;
      canvas.drawCircle(Offset(cx, cy), 16, starPaint);
      canvas.drawCircle(Offset(cx, cy), 16, Paint()..color = Colors.white.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 2);

      final textSpan = const TextSpan(text: '⭐', style: TextStyle(fontSize: 18));
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(cx - (tp.width / 2), cy - (tp.height / 2)));
    } else {
      // Tamil Target Letter Token Bubble
      final tokenPaint = Paint()..color = const Color(0xFFFF4081);
      canvas.drawCircle(Offset(cx, cy), 20, tokenPaint);

      final tokenBorder = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(Offset(cx, cy), 20, tokenBorder);

      final textSpan = TextSpan(
        text: item.letter,
        style: GoogleFonts.catamaran(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(cx - (tp.width / 2), cy - (tp.height / 2)));
    }
  }

  void _drawPlayer(Canvas canvas) {
    if (isInvulnerable && (DateTime.now().millisecond % 200 < 100)) {
      return; // Damage flashing effect
    }

    final px = playerX + 16;
    final py = playerY + 22;

    canvas.save();
    canvas.translate(px, py);
    if (facingDirection == -1) {
      canvas.scale(-1, 1);
    }

    // 1. Cartoon Kid Body (T-shirt)
    final shirtPaint = Paint()..color = const Color(0xFFFF5722);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-10, -4, 20, 18), const Radius.circular(6)),
      shirtPaint,
    );

    // 2. Head & Face
    final facePaint = Paint()..color = const Color(0xFFFFCC80);
    canvas.drawCircle(const Offset(0, -14), 11, facePaint);

    // 3. Hair
    final hairPaint = Paint()..color = const Color(0xFF3E2723);
    canvas.drawArc(
      const Rect.fromLTWH(-11, -25, 22, 18),
      pi,
      pi,
      true,
      hairPaint,
    );

    // 4. Eyes & Smile
    canvas.drawCircle(const Offset(4, -14), 2, Paint()..color = const Color(0xFF1B5E20));
    canvas.drawArc(
      const Rect.fromLTWH(0, -12, 6, 6),
      0,
      pi,
      false,
      Paint()..color = Colors.red..style = PaintingStyle.stroke..strokeWidth = 1.2,
    );

    // 5. Animated Running Legs
    final legSwing = isGrounded ? sin(runLegPhase) * 6.0 : 4.0;
    final legPaint = Paint()
      ..color = const Color(0xFF1976D2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // Left leg
    canvas.drawLine(const Offset(-4, 14), Offset(-4 - legSwing, 22), legPaint);
    // Right leg
    canvas.drawLine(const Offset(4, 14), Offset(4 + legSwing, 22), legPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AgaramWorldPainter oldDelegate) => true;
}
