import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../data/uyir_data.dart';
import '../../data/mei_data.dart';
import '../../models/letter_model.dart';
import '../../models/letter_fishing_game_model.dart';
import '../../services/audio_service.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/mascot_widget.dart';

enum HookState {
  inactive,       // No hook in water. Fish swim freely.
  hookMovingDown, // Hook casting down to the tapped fish.
  hookMovingUp,   // Hook reeling the caught fish up to the boat.
}

class LetterFishingGame extends StatefulWidget {
  final ProgressService progressService;
  final FishingGameMode mode;

  const LetterFishingGame({
    super.key,
    required this.progressService,
    this.mode = FishingGameMode.uyir,
  });

  @override
  State<LetterFishingGame> createState() => _LetterFishingGameState();
}

class _LetterFishingGameState extends State<LetterFishingGame>
    with TickerProviderStateMixin {
  // Services
  final AudioService _audioService = AudioService.instance;
  final Random _rng = Random();

  // Game Engine 60fps Ticker
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  // Game Flow State
  bool _isPlaying = false;
  bool _isGameOver = false;
  bool _isRoundTransitioning = false;
  bool _isMuted = false;

  // Level & Round Data
  late List<LetterModel> _letterPool;
  late List<LetterModel> _roundQueue;
  int _currentRoundIndex = 0;
  int _score = 0;
  int _caughtCount = 0;
  int _starsEarned = 0;

  // Entities
  final List<SwimmingFish> _activeFish = [];
  final List<UnderwaterBubble> _bubbles = [];
  final List<FishingParticle> _particles = [];
  int _nextFishId = 0;

  // --------------------------------------------------------------------------
  // HOOK LIFECYCLE & STATE MACHINE (INACTIVE BY DEFAULT)
  // --------------------------------------------------------------------------
  HookState _hookState = HookState.inactive;
  SwimmingFish? _selectedFish;
  double _hookProgress = 0.0; // 0.0 (at boat) to 1.0 (at fish)
  double _pullUpProgress = 0.0; // 0.0 (at fish) to 1.0 (at boat)

  double _hookX = 0.50;
  double _hookY = 0.08;

  // Feedback Overlays
  String? _toastMessage;
  Color _toastColor = AppColors.mintGreen;
  double _toastOpacity = 0.0;

  // Celebration Banner Animation
  late AnimationController _celebrationController;
  late Animation<double> _celebrationScale;

  // Target Banner Pulse Animation
  late AnimationController _targetPulseController;
  late Animation<double> _targetPulseAnim;

  // Seaweed Sway Phase
  double _seaweedPhase = 0.0;

  LetterModel get _currentTarget => _roundQueue[_currentRoundIndex];

  @override
  void initState() {
    super.initState();
    _isMuted = _audioService.isMuted;

    _initAnimations();
    _setupGameData();
    _initBubbles();

    // Start ticker for smooth 60fps underwater animations
    _ticker = createTicker(_onTick)..start();
  }

  void _initAnimations() {
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _celebrationScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(_celebrationController);

    _targetPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _targetPulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _targetPulseController, curve: Curves.easeInOut),
    );
  }

  void _initBubbles() {
    _bubbles.clear();
    for (int i = 0; i < 22; i++) {
      _bubbles.add(
        UnderwaterBubble(
          x: _rng.nextDouble(),
          y: _rng.nextDouble(),
          radius: _rng.nextDouble() * 12 + 4,
          speedY: _rng.nextDouble() * 0.10 + 0.04,
          wobbleSpeed: _rng.nextDouble() * 3.0 + 1.5,
          wobblePhase: _rng.nextDouble() * 2 * pi,
          opacity: _rng.nextDouble() * 0.45 + 0.25,
        ),
      );
    }
  }

  void _setupGameData() {
    if (widget.mode == FishingGameMode.mei) {
      _letterPool = List<LetterModel>.from(meiLettersList);
    } else {
      _letterPool = List<LetterModel>.from(uyirLettersList);
    }

    _roundQueue = List<LetterModel>.from(_letterPool);
    _currentRoundIndex = 0;
    _score = 0;
    _caughtCount = 0;
    _starsEarned = 0;
    _isGameOver = false;
    _isRoundTransitioning = false;
    _hookState = HookState.inactive;
    _selectedFish = null;
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _isGameOver = false;
      _score = 0;
      _caughtCount = 0;
      _currentRoundIndex = 0;
      _setupGameData();
    });

    _spawnFishForCurrentRound();
    _playTargetSound();
  }

  void _spawnFishForCurrentRound() {
    _activeFish.clear();
    _hookState = HookState.inactive;
    _selectedFish = null;
    _isRoundTransitioning = false;

    final target = _currentTarget;

    // Pick 3 distinct distractors from letterPool
    final distractorCandidates = _letterPool.where((l) => l.id != target.id).toList()..shuffle(_rng);
    final distractors = distractorCandidates.take(3).toList();

    final roundLetters = <LetterModel>[target, ...distractors]..shuffle(_rng);

    // Spread fish across distinct vertical lanes
    final verticalLanes = [0.26, 0.42, 0.58, 0.74];
    verticalLanes.shuffle(_rng);

    for (int i = 0; i < roundLetters.length; i++) {
      final letter = roundLetters[i];
      final isTarget = letter.id == target.id;
      final direction = _rng.nextBool() ? 1 : -1;
      final startX = direction == 1 ? (_rng.nextDouble() * 0.20 + 0.02) : (0.75 + _rng.nextDouble() * 0.20);
      final laneY = verticalLanes[i % verticalLanes.length] + (_rng.nextDouble() * 0.04 - 0.02);

      final (bodyGrad, finCol, accentCol) = FishColorPalette.getRandomColors(_rng);

      _activeFish.add(
        SwimmingFish(
          id: _nextFishId++,
          letterModel: letter,
          isTarget: isTarget,
          x: startX,
          y: laneY.clamp(0.22, 0.78),
          speed: _rng.nextDouble() * 0.06 + 0.09, // Smooth, gentle swimming speed
          direction: direction,
          yWobbleFreq: _rng.nextDouble() * 1.5 + 1.8,
          yWobbleAmp: _rng.nextDouble() * 8 + 6,
          wobblePhase: _rng.nextDouble() * 2 * pi,
          bodyGradient: bodyGrad,
          finColor: finCol,
          accentColor: accentCol,
          size: 116.0,
        ),
      );
    }
  }

  // --------------------------------------------------------------------------
  // USER TAPS A FISH → ACTIVATE HOOK SPECIFICALLY FOR THAT FISH
  // --------------------------------------------------------------------------
  void _onFishTapped(SwimmingFish fish) {
    // Ignore tap if game is not active or hook is already in action
    if (!_isPlaying || _isGameOver || _isRoundTransitioning || _hookState != HookState.inactive) {
      return;
    }

    if (fish.isCaught) return;

    setState(() {
      _selectedFish = fish;
      _hookState = HookState.hookMovingDown;
      _hookProgress = 0.0;
      _pullUpProgress = 0.0;
      _hookX = 0.50;
      _hookY = 0.08;
    });
  }

  // --------------------------------------------------------------------------
  // 60 FPS GAME LOOP
  // --------------------------------------------------------------------------
  void _onTick(Duration elapsed) {
    if (!mounted) return;

    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }

    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    if (dt <= 0 || dt > 0.1) return;

    setState(() {
      _seaweedPhase += dt * 1.8;

      // 1. Update Bubbles
      for (final b in _bubbles) {
        b.y -= b.speedY * dt;
        b.wobblePhase += b.wobbleSpeed * dt;
        if (b.y < -0.05) {
          b.y = 1.05;
          b.x = _rng.nextDouble();
        }
      }

      // 2. Update Swimming Fish & Hook Movement
      _updateFishAndHookPhysics(dt);

      // 3. Update Celebration / Splash Particles
      for (int i = _particles.length - 1; i >= 0; i--) {
        final p = _particles[i];
        p.life -= dt;
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.vy += 90.0 * dt; // Gravity
        if (p.life <= 0) {
          _particles.removeAt(i);
        }
      }

      // 4. Toast Fade
      if (_toastOpacity > 0.0) {
        _toastOpacity = (_toastOpacity - dt * 0.7).clamp(0.0, 1.0);
      }
    });
  }

  void _updateFishAndHookPhysics(double dt) {
    // -------------------------------------------------------------
    // HOOK MOVEMENT TOWARD SELECTED FISH
    // -------------------------------------------------------------
    if (_hookState == HookState.hookMovingDown) {
      if (_selectedFish == null || !_activeFish.contains(_selectedFish)) {
        _resetHookToIdle();
        return;
      }

      // Fast, responsive line cast (~0.35s to reach fish)
      _hookProgress = (_hookProgress + dt * 2.8).clamp(0.0, 1.0);

      // Hook targets the selected fish directly
      _hookX = 0.50 + (_selectedFish!.x - 0.50) * _hookProgress;
      _hookY = 0.08 + (_selectedFish!.y - 0.08) * _hookProgress;

      // When hook arrives at selected fish -> attach and start reeling up!
      if (_hookProgress >= 1.0) {
        _hookState = HookState.hookMovingUp;
        _selectedFish!.isCaught = true;
        _pullUpProgress = 0.0;
      }
    } else if (_hookState == HookState.hookMovingUp) {
      if (_selectedFish == null) {
        _resetHookToIdle();
        return;
      }

      // Reeling hook & fish upward to the boat surface (~0.5s)
      _pullUpProgress = (_pullUpProgress + dt * 2.0).clamp(0.0, 1.0);

      final startX = _selectedFish!.x;
      final startY = _selectedFish!.y;
      _hookX = startX + (0.50 - startX) * _pullUpProgress;
      _hookY = startY + (0.08 - startY) * _pullUpProgress;

      // Fish position remains attached to the hook exactly
      _selectedFish!.x = _hookX;
      _selectedFish!.y = _hookY + 0.04;

      // When fish reaches the top boat surface -> evaluate catch
      if (_pullUpProgress >= 1.0) {
        _onFishReachedSurface();
      }
    }

    // -------------------------------------------------------------
    // SWIMMING FISH LOGIC (Uncaught fish swim freely)
    // -------------------------------------------------------------
    for (final fish in _activeFish) {
      fish.tailWagPhase += dt * 8.0;
      fish.wobblePhase += fish.yWobbleFreq * dt;

      // Only uncaught fish swim independently
      if (!fish.isCaught) {
        fish.x += fish.direction * fish.speed * dt;

        // Screen wrap-around with new randomized depth
        if (fish.direction == 1 && fish.x > 1.15) {
          fish.x = -0.15;
          fish.y = (_rng.nextDouble() * 0.52 + 0.24);
        } else if (fish.direction == -1 && fish.x < -0.15) {
          fish.x = 1.15;
          fish.y = (_rng.nextDouble() * 0.52 + 0.24);
        }
      }
    }
  }

  // --------------------------------------------------------------------------
  // FISH REACHED SURFACE → EVALUATE TARGET MATCH & CLEAN RESET
  // --------------------------------------------------------------------------
  void _onFishReachedSurface() {
    final fish = _selectedFish;
    if (fish == null) {
      _resetHookToIdle();
      return;
    }

    final media = MediaQuery.of(context).size;
    final surfaceX = media.width * 0.50;
    final surfaceY = media.height * 0.10;

    if (fish.isTarget) {
      // -------------------------------------------------------------
      // CORRECT TARGET FISH CAUGHT! 🎯🎣
      // -------------------------------------------------------------
      _score += 10;
      _caughtCount++;
      _isRoundTransitioning = true;

      // Celebration splash particles
      _spawnCelebrationParticles(surfaceX, surfaceY);
      _celebrationController.forward(from: 0.0);

      // Play authentic native Tamil letter pronunciation
      _audioService.playLetterSound(
        context,
        letter: fish.letter,
        word: fish.word,
        audioPath: fish.audioPath,
        showIndicator: false,
      );
      _audioService.playSuccessFeedback(context);

      // Mark letter learning progress
      widget.progressService.markLetterCompleted(fish.letterModel.id);
      _showToast('அருமை! +10', const Color(0xFFFFD54F));

      // Remove caught fish from active pool
      _activeFish.removeWhere((f) => f.id == fish.id);

      // Reset hook completely
      _resetHookToIdle();

      // Advance to next letter after brief celebratory pause
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        _advanceRound();
      });
    } else {
      // -------------------------------------------------------------
      // WRONG FISH CAUGHT (Friendly Feedback & Release) 😊
      // -------------------------------------------------------------
      _spawnWrongRipples(surfaceX, surfaceY);
      _audioService.playRetryFeedback(context);
      _showToast('இது இல்லை! மீண்டும் முயற்சி செய் 😊', const Color(0xFFFF8A65));

      // Release fish back to natural swimming at middle water
      fish.isCaught = false;
      fish.y = (_rng.nextDouble() * 0.40 + 0.35);

      // Reset hook completely so player can tap another fish
      _resetHookToIdle();
    }
  }

  void _resetHookToIdle() {
    _hookState = HookState.inactive;
    _selectedFish = null;
    _hookProgress = 0.0;
    _pullUpProgress = 0.0;
    _hookX = 0.50;
    _hookY = 0.08;
  }

  void _advanceRound() {
    if (_currentRoundIndex + 1 < _roundQueue.length) {
      setState(() {
        _currentRoundIndex++;
        _isRoundTransitioning = false;
      });
      _spawnFishForCurrentRound();
      _playTargetSound();
    } else {
      // -------------------------------------------------------------
      // LEVEL COMPLETED! 🎉
      // -------------------------------------------------------------
      const earnedStars = 3;
      widget.progressService.recordGameCompleted(earnedStars);

      setState(() {
        _isGameOver = true;
        _isPlaying = false;
        _starsEarned = earnedStars;
      });

      _audioService.playStarReward(context);
    }
  }

  void _playTargetSound() {
    if (!_isMuted && _isPlaying && !_isGameOver) {
      _audioService.playLetterSound(
        context,
        letter: _currentTarget.letter,
        word: _currentTarget.word,
        audioPath: _currentTarget.audioPath,
        showIndicator: false,
      );
    }
  }

  void _showToast(String message, Color color) {
    setState(() {
      _toastMessage = message;
      _toastColor = color;
      _toastOpacity = 1.0;
    });
  }

  void _spawnCelebrationParticles(double x, double y) {
    const starCount = 28;
    for (int i = 0; i < starCount; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = _rng.nextDouble() * 220 + 80;
      final colors = [
        const Color(0xFFFFD700),
        const Color(0xFFFF4081),
        const Color(0xFF00E5FF),
        const Color(0xFF76FF03),
        const Color(0xFFFFAB00),
        Colors.white,
      ];
      _particles.add(
        FishingParticle(
          x: x,
          y: y,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - 50,
          color: colors[_rng.nextInt(colors.length)],
          size: _rng.nextDouble() * 12 + 8,
          life: 0.85,
          maxLife: 0.85,
          isStar: _rng.nextBool(),
        ),
      );
    }
  }

  void _spawnWrongRipples(double x, double y) {
    for (int i = 0; i < 10; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = _rng.nextDouble() * 70 + 30;
      _particles.add(
        FishingParticle(
          x: x,
          y: y,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          color: const Color(0xFFFF8A65).withValues(alpha: 0.7),
          size: _rng.nextDouble() * 8 + 5,
          life: 0.5,
          maxLife: 0.5,
        ),
      );
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _celebrationController.dispose();
    _targetPulseController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // BUILD UI
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0077B6),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenSize = Size(constraints.maxWidth, constraints.maxHeight);

          return Stack(
            children: [
              // 1. Realistic Underwater Environment Canvas
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _UnderwaterWorldPainter(
                      bubbles: _bubbles,
                      seaweedPhase: _seaweedPhase,
                    ),
                  ),
                ),
              ),

              // 2. Active Swimming Fish & Hook Layer
              if (_isPlaying && !_isGameOver)
                Positioned.fill(
                  child: Stack(
                    children: [
                      // A. Fishing Line & Hook (Drawn ONLY when hook is active!)
                      if (_hookState != HookState.inactive)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _FishingRodAndHookPainter(
                                boatX: screenSize.width * 0.50,
                                boatY: MediaQuery.of(context).padding.top + 34,
                                hookX: _hookX * screenSize.width,
                                hookY: _hookY * screenSize.height,
                              ),
                            ),
                          ),
                        ),

                      // B. Tappable Swimming Fish Entities
                      ..._activeFish.map((fish) {
                        final fishY = fish.isCaught
                            ? (fish.y * screenSize.height)
                            : (fish.y * screenSize.height + sin(fish.wobblePhase) * fish.yWobbleAmp);
                        final fishX = fish.x * screenSize.width;

                        return Positioned(
                          left: fishX - (fish.size * 0.50),
                          top: fishY - (fish.size * 0.36),
                          child: IgnorePointer(
                            ignoring: fish.isCaught || _hookState != HookState.inactive,
                            child: _CartoonFishWidget(
                              fish: fish,
                              onTap: () => _onFishTapped(fish),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

              // 3. Floating Sparkle Particles Layer
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ParticlesPainter(particles: _particles),
                  ),
                ),
              ),

              // 4. Fisherman Boat at Water Surface
              Positioned(
                top: MediaQuery.of(context).padding.top + 6,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: _FishermanBoatWidget(isPlaying: _isPlaying),
                  ),
                ),
              ),

              // 5. In-Game HUD Header (Scores, Round Progress, Speaker, Back)
              if (_isPlaying && !_isGameOver)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 6,
                  left: 16,
                  right: 16,
                  child: _buildGameHeader(context),
                ),

              // 6. Prominent Target Banner: 🎯 "அ எழுத்தைப் பிடி!"
              if (_isPlaying && !_isGameOver)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 76,
                  left: 16,
                  right: 16,
                  child: Center(
                    child: ScaleTransition(
                      scale: _targetPulseAnim,
                      child: _buildTargetBanner(),
                    ),
                  ),
                ),

              // 7. Dynamic Celebration / Feedback Toast
              if (_toastOpacity > 0.0 && _toastMessage != null)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 160,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: ScaleTransition(
                        scale: _celebrationScale,
                        child: Opacity(
                          opacity: _toastOpacity,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                            decoration: BoxDecoration(
                              color: _toastColor,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              _toastMessage!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1A237E),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // 8. Start Game Welcome Screen
              if (!_isPlaying && !_isGameOver)
                _buildStartScreen(context),

              // 9. Level Completed / Victory Screen
              if (_isGameOver)
                _buildVictoryScreen(context),
            ],
          );
        },
      ),
    );
  }

  // --------------------------------------------------------------------------
  // UI WIDGETS
  // --------------------------------------------------------------------------

  Widget _buildGameHeader(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.topCenter,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Exit / Back Button
          BouncyButton(
            onPressed: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.90),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF0D47A1),
                size: 24,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Round Counter Capsule
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE0F7FA), Colors.white],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF4DD0E1), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎣 ', style: TextStyle(fontSize: 16)),
                Text(
                  '${_currentRoundIndex + 1} / ${_roundQueue.length}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF006064),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Score Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF9C4), Color(0xFFFFE082)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFFB300), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFF9F1C), size: 18),
                const SizedBox(width: 2),
                Text(
                  '$_score',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFE65100),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Speaker Button
          BouncyButton(
            onPressed: _playTargetSound,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.90),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.volume_up_rounded,
                color: Color(0xFFFF8F00),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetBanner() {
    final target = _currentTarget;

    return BouncyButton(
      onPressed: _playTargetSound,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF9C4), Colors.white, Color(0xFFFFF59D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFFFB300), width: 3.0),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB300).withValues(alpha: 0.40),
                blurRadius: 18,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🎯 ',
                style: TextStyle(fontSize: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE082),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFF8F00), width: 2),
                ),
                child: Text(
                  target.letter,
                  style: AppTextStyles.tamilLetterMedium.copyWith(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFD84315),
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'எழுத்தைத் தொடு!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFBF360C),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF8F00),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartScreen(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.40),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE1F5FE), Colors.white, Color(0xFFB3E5FC)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: const Color(0xFF29B6F6), width: 3.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Game Mascot / Illustration
                  const MascotWidget(
                    pose: MascotPose.game,
                    size: MascotSize.medium,
                    customHeight: 100,
                    showGlow: true,
                  ),
                  const SizedBox(height: 12),

                  // Title
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🎣 ', style: TextStyle(fontSize: 26)),
                        Text(
                          'எழுத்து மீன்பிடி',
                          style: AppTextStyles.screenTitle.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF01579B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F7FA),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF80DEEA), width: 1.5),
                      ),
                      child: const Text(
                        'மீனைத் தொட்டு தூண்டிலால் பிடிப்போம்!',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00695C),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Level Badge
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFFFB74D), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9800),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'நிலை 1',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.mode.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFE65100),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.mode.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF5D4037),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Preview Letters (அ, ஆ, இ, ஈ...)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: ['அ', 'ஆ', 'இ', 'ஈ', 'உ', 'ஊ'].map((l) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFFB74D)),
                              ),
                              child: Text(
                                l,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE65100),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Play Button
                  BouncyButton(
                    onPressed: _startGame,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E676), Color(0xFF00C853)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00C853).withValues(alpha: 0.40),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'விளையாடலாம் 🎮',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Back Button
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18, color: Color(0xFF0277BD)),
                    label: const Text(
                      'திரும்பிச் செல்',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0277BD),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVictoryScreen(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 30),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFFDE7), Colors.white, Color(0xFFFFF9C4)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: const Color(0xFFFFD54F), width: 3.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 26,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 50)),
                  const SizedBox(height: 6),
                  Text(
                    'அருமை!',
                    style: AppTextStyles.screenTitle.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFE65100),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'அனைத்து எழுத்துகளையும் பிடித்துவிட்டீர்கள்!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Star Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.star_rounded,
                          color: index < _starsEarned ? const Color(0xFFFFC107) : const Color(0xFFE0E0E0),
                          size: 42,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 18),

                  // Stats Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFFFE082), width: 2),
                    ),
                    child: Column(
                      children: [
                        _buildStatRow('மொத்த புள்ளிகள்', '$_score'),
                        const Divider(height: 16),
                        _buildStatRow('பிடித்த எழுத்துகள்', '$_caughtCount / ${_roundQueue.length}'),
                        const Divider(height: 16),
                        _buildStatRow('பெற்ற நட்சத்திரங்கள்', '+$_starsEarned'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Play Again Button
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
                            color: const Color(0xFF00C853).withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'மீண்டும் விளையாடு 🔄',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Back to Arena Button
                  BouncyButton(
                    onPressed: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECEFF1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFCFD8DC)),
                      ),
                      child: const Center(
                        child: Text(
                          'விளையாட்டு அரங்கம் 🏠',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF37474F),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5D4037),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Color(0xFFE65100),
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------------------
// FISHING ROD & HOOK CUSTOM PAINTER (Drawn only during active catch)
// ----------------------------------------------------------------------------

class _FishingRodAndHookPainter extends CustomPainter {
  final double boatX;
  final double boatY;
  final double hookX;
  final double hookY;

  _FishingRodAndHookPainter({
    required this.boatX,
    required this.boatY,
    required this.hookX,
    required this.hookY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Fishing Rod Tip
    final rodTip = Offset(boatX + 32, boatY + 14);

    // 2. Fishing Line (Glowing Transparent Nylon Line)
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.90)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final linePath = Path();
    linePath.moveTo(rodTip.dx, rodTip.dy);
    final controlX = (rodTip.dx + hookX) * 0.5;
    final controlY = (rodTip.dy + hookY) * 0.5;
    linePath.quadraticBezierTo(controlX, controlY, hookX, hookY - 14);
    canvas.drawPath(linePath, linePaint);

    // 3. Bobber
    final bobberPos = Offset(controlX, controlY);
    canvas.drawCircle(bobberPos, 5.0, Paint()..color = const Color(0xFFFF1744));
    canvas.drawCircle(bobberPos, 3.0, Paint()..color = Colors.white);

    // 4. Metallic Golden Fish Hook 🪝
    final hookPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final hookPath = Path();
    hookPath.moveTo(hookX, hookY - 14);
    hookPath.lineTo(hookX, hookY);
    hookPath.quadraticBezierTo(hookX, hookY + 14, hookX + 10, hookY + 14);
    hookPath.quadraticBezierTo(hookX + 18, hookY + 14, hookX + 18, hookY + 4);
    canvas.drawPath(hookPath, hookPaint);

    // Eyelet
    canvas.drawCircle(
      Offset(hookX, hookY - 14),
      2.5,
      Paint()..color = const Color(0xFFFFB300),
    );
  }

  @override
  bool shouldRepaint(covariant _FishingRodAndHookPainter oldDelegate) {
    return oldDelegate.hookX != hookX || oldDelegate.hookY != hookY;
  }
}

// ----------------------------------------------------------------------------
// TAPPABLE CARTOON FISH WIDGET
// ----------------------------------------------------------------------------

class _CartoonFishWidget extends StatelessWidget {
  final SwimmingFish fish;
  final VoidCallback onTap;

  const _CartoonFishWidget({
    required this.fish,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scale = fish.isCaught ? 1.12 : 1.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Transform.scale(
        scale: scale,
        child: SizedBox(
          width: fish.size,
          height: fish.size * 0.72,
          child: CustomPaint(
            painter: _FishVectorPainter(
              direction: fish.direction,
              bodyGradient: fish.bodyGradient,
              finColor: fish.finColor,
              accentColor: fish.accentColor,
              tailWagPhase: fish.tailWagPhase,
              letter: fish.letter,
              isCaught: fish.isCaught,
            ),
          ),
        ),
      ),
    );
  }
}

class _FishVectorPainter extends CustomPainter {
  final int direction;
  final List<Color> bodyGradient;
  final Color finColor;
  final Color accentColor;
  final double tailWagPhase;
  final String letter;
  final bool isCaught;

  _FishVectorPainter({
    required this.direction,
    required this.bodyGradient,
    required this.finColor,
    required this.accentColor,
    required this.tailWagPhase,
    required this.letter,
    required this.isCaught,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // Flip horizontally if swimming to the left
    if (direction == -1) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }

    final w = size.width;
    final h = size.height;
    final centerX = w * 0.52;
    final centerY = h * 0.50;

    // 1. Animated Waving Tail Fin
    final tailWag = isCaught ? 0.0 : sin(tailWagPhase) * 6.0;
    final tailPath = Path();
    tailPath.moveTo(w * 0.22, centerY);
    tailPath.quadraticBezierTo(
      w * 0.08,
      centerY - h * 0.35 + tailWag,
      0,
      centerY - h * 0.42 + tailWag,
    );
    tailPath.quadraticBezierTo(
      w * 0.10,
      centerY,
      0,
      centerY + h * 0.42 + tailWag,
    );
    tailPath.quadraticBezierTo(
      w * 0.08,
      centerY + h * 0.35 + tailWag,
      w * 0.22,
      centerY,
    );
    tailPath.close();

    final finPaint = Paint()
      ..color = finColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(tailPath, finPaint);

    final finBorder = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(tailPath, finBorder);

    // 2. Dorsal Fin (Top)
    final dorsalPath = Path();
    dorsalPath.moveTo(w * 0.38, h * 0.18);
    dorsalPath.quadraticBezierTo(w * 0.48, 0, w * 0.62, h * 0.14);
    dorsalPath.close();
    canvas.drawPath(dorsalPath, finPaint);

    // 3. Pectoral Fin (Bottom)
    final bottomFin = Path();
    bottomFin.moveTo(w * 0.42, h * 0.82);
    bottomFin.quadraticBezierTo(w * 0.52, h * 0.98, w * 0.60, h * 0.84);
    bottomFin.close();
    canvas.drawPath(bottomFin, finPaint);

    // 4. Main Fish Body
    final bodyPath = Path();
    bodyPath.moveTo(w * 0.96, centerY); // Snout
    bodyPath.quadraticBezierTo(w * 0.70, h * 0.05, w * 0.22, centerY); // Top curve
    bodyPath.quadraticBezierTo(w * 0.70, h * 0.95, w * 0.96, centerY); // Bottom curve
    bodyPath.close();

    final bodyPaint = Paint()
      ..shader = LinearGradient(
        colors: bodyGradient,
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(bodyPath, bodyPaint);

    // Body Outline
    final bodyOutline = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(bodyPath, bodyOutline);

    // Decorative Striped Scale Pattern
    final stripePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.44, centerY), width: 34, height: h * 0.72),
      -pi / 2,
      pi,
      false,
      stripePaint,
    );

    // 5. Cute Cartoon Eye
    final eyeCenter = Offset(w * 0.82, centerY - h * 0.14);
    final eyeRadius = h * 0.16;

    // White Sclera
    canvas.drawCircle(eyeCenter, eyeRadius, Paint()..color = Colors.white);
    // Dark Pupil
    canvas.drawCircle(eyeCenter + const Offset(1.5, 0), eyeRadius * 0.62, Paint()..color = const Color(0xFF1A237E));
    // Catchlight Glint
    canvas.drawCircle(eyeCenter + const Offset(-1.5, -2), eyeRadius * 0.28, Paint()..color = Colors.white);

    // 6. Friendly Smile
    final smilePath = Path();
    smilePath.moveTo(w * 0.93, centerY + h * 0.12);
    smilePath.quadraticBezierTo(w * 0.88, centerY + h * 0.22, w * 0.82, centerY + h * 0.14);
    canvas.drawPath(
      smilePath,
      Paint()
        ..color = const Color(0xFFB71C1C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    // 7. High-Contrast Center White Badge for Tamil Letter
    final badgeCenter = Offset(centerX - w * 0.04, centerY);
    final badgeRadius = h * 0.38;

    // Badge Shadow & Glow
    canvas.drawCircle(
      badgeCenter,
      badgeRadius + 3,
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );
    // Badge Background
    canvas.drawCircle(
      badgeCenter,
      badgeRadius,
      Paint()..color = Colors.white,
    );
    // Badge Border
    canvas.drawCircle(
      badgeCenter,
      badgeRadius,
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    // 8. Draw Bold Tamil Letter Text
    canvas.save();
    if (direction == -1) {
      canvas.translate(badgeCenter.dx, badgeCenter.dy);
      canvas.scale(-1, 1);
      canvas.translate(-badgeCenter.dx, -badgeCenter.dy);
    }

    final textSpan = TextSpan(
      text: letter,
      style: TextStyle(
        fontSize: letter.length > 2 ? 22 : 28,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF0D47A1),
        fontFamily: 'Catamaran',
        height: 1.0,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        badgeCenter.dx - (textPainter.width / 2),
        badgeCenter.dy - (textPainter.height / 2),
      ),
    );
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FishVectorPainter oldDelegate) {
    return oldDelegate.tailWagPhase != tailWagPhase ||
        oldDelegate.letter != letter ||
        oldDelegate.isCaught != isCaught;
  }
}

// ----------------------------------------------------------------------------
// UNDERWATER WORLD & SEAFLOOR PAINTER
// ----------------------------------------------------------------------------

class _UnderwaterWorldPainter extends CustomPainter {
  final List<UnderwaterBubble> bubbles;
  final double seaweedPhase;

  _UnderwaterWorldPainter({
    required this.bubbles,
    required this.seaweedPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Deep Ocean Vertical Gradient
    final oceanShader = const LinearGradient(
      colors: [
        Color(0xFF00B4D8), // Light surface cyan
        Color(0xFF0077B6), // Vibrant mid-water
        Color(0xFF023E8A), // Deep aquatic blue
        Color(0xFF03045E), // Bottom sapphire
      ],
      stops: [0.0, 0.35, 0.75, 1.0],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..shader = oceanShader);

    // 2. Caustic Light Beams (Sunlight penetrating water)
    for (int i = 0; i < 4; i++) {
      final startX = w * (0.15 + i * 0.25);
      final rayPath = Path();
      rayPath.moveTo(startX, 0);
      rayPath.lineTo(startX + 60, 0);
      rayPath.lineTo(startX + 140, h * 0.65);
      rayPath.lineTo(startX + 30, h * 0.65);
      rayPath.close();

      canvas.drawPath(
        rayPath,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.12),
              Colors.white.withValues(alpha: 0.0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(0, 0, w, h * 0.65)),
      );
    }

    // 3. Sandy Ocean Floor with Gentle Dunes
    final floorPath = Path();
    floorPath.moveTo(0, h * 0.88);
    floorPath.quadraticBezierTo(w * 0.25, h * 0.85, w * 0.50, h * 0.89);
    floorPath.quadraticBezierTo(w * 0.75, h * 0.93, w, h * 0.87);
    floorPath.lineTo(w, h);
    floorPath.lineTo(0, h);
    floorPath.close();

    final sandShader = const LinearGradient(
      colors: [Color(0xFFFFD54F), Color(0xFFFFB300), Color(0xFFFFA000)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, h * 0.85, w, h * 0.15));
    canvas.drawPath(floorPath, Paint()..shader = sandShader);

    // 4. Swaying Seaweed Stalks (Kelp)
    _drawSwayingSeaweed(canvas, w * 0.08, h * 0.90, h * 0.32, 0.0, const Color(0xFF2E7D32));
    _drawSwayingSeaweed(canvas, w * 0.14, h * 0.92, h * 0.26, 0.8, const Color(0xFF43A047));
    _drawSwayingSeaweed(canvas, w * 0.86, h * 0.91, h * 0.35, 1.4, const Color(0xFF1B5E20));
    _drawSwayingSeaweed(canvas, w * 0.92, h * 0.89, h * 0.28, 2.2, const Color(0xFF388E3C));

    // 5. Starfish on Sandy Seabed
    _drawStarfish(canvas, Offset(w * 0.32, h * 0.92), 16, const Color(0xFFFF5722));
    _drawStarfish(canvas, Offset(w * 0.68, h * 0.94), 13, const Color(0xFFE91E63));

    // 6. Translucent Rising Bubbles
    for (final b in bubbles) {
      final bubbleX = b.x * w + sin(b.wobblePhase) * 6;
      final bubbleY = b.y * h;

      final bubblePaint = Paint()
        ..color = Colors.white.withValues(alpha: b.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(bubbleX, bubbleY), b.radius, bubblePaint);

      final bubbleBorder = Paint()
        ..color = Colors.white.withValues(alpha: b.opacity + 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(Offset(bubbleX, bubbleY), b.radius, bubbleBorder);

      // Bubble highlight glint
      canvas.drawCircle(
        Offset(bubbleX - b.radius * 0.35, bubbleY - b.radius * 0.35),
        b.radius * 0.25,
        Paint()..color = Colors.white.withValues(alpha: b.opacity + 0.3),
      );
    }
  }

  void _drawSwayingSeaweed(Canvas canvas, double rootX, double rootY, double height, double offset, Color color) {
    final sway = sin(seaweedPhase + offset) * 16.0;
    final path = Path();
    path.moveTo(rootX - 8, rootY);
    path.quadraticBezierTo(rootX + sway * 0.4, rootY - height * 0.5, rootX + sway, rootY - height);
    path.quadraticBezierTo(rootX + sway * 0.5 + 8, rootY - height * 0.5, rootX + 8, rootY);
    path.close();

    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.85));
  }

  void _drawStarfish(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    const points = 5;
    final innerRadius = radius * 0.45;
    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : innerRadius;
      final angle = (i * pi / points) - (pi / 2);
      final x = center.dx + cos(angle) * r;
      final y = center.dy + sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _UnderwaterWorldPainter oldDelegate) => true;
}

// ----------------------------------------------------------------------------
// FISHERMAN BOAT WIDGET
// ----------------------------------------------------------------------------

class _FishermanBoatWidget extends StatelessWidget {
  final bool isPlaying;

  const _FishermanBoatWidget({required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF0288D1), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('⛵ ', style: TextStyle(fontSize: 18)),
          Text(
            'மீன்பிடி படகு',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Color(0xFF01579B),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// PARTICLES PAINTER
// ----------------------------------------------------------------------------

class _ParticlesPainter extends CustomPainter {
  final List<FishingParticle> particles;

  _ParticlesPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final alpha = (p.life / p.maxLife).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      if (p.isStar) {
        _drawStar(canvas, Offset(p.x, p.y), p.size * alpha, paint);
      } else {
        canvas.drawCircle(Offset(p.x, p.y), p.size * alpha, paint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const points = 5;
    final inner = radius * 0.45;
    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : inner;
      final angle = (i * pi / points) - (pi / 2);
      final x = center.dx + cos(angle) * r;
      final y = center.dy + sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) {
    return particles.isNotEmpty;
  }
}
