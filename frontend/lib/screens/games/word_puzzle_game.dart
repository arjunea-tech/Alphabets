import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/word_puzzle_data.dart';
import '../../models/letter_candy_game_model.dart';
import '../../models/word_puzzle_game_model.dart';
import '../../services/audio_service.dart';
import '../../services/progress_service.dart';

class WordPuzzleGame extends StatefulWidget {
  final ProgressService? progressService;
  final int initialLevel;

  const WordPuzzleGame({
    super.key,
    this.progressService,
    this.initialLevel = 1,
  });

  @override
  State<WordPuzzleGame> createState() => _WordPuzzleGameState();
}

class _WordPuzzleGameState extends State<WordPuzzleGame>
    with TickerProviderStateMixin {
  // Game states: 'playing', 'word_complete', 'level_complete'
  String _gameState = 'playing';

  late int _currentLevel;
  late List<WordPuzzleModel> _levelPuzzles;
  int _puzzleIndex = 0;
  WordPuzzleModel get _currentPuzzle => _levelPuzzles[_puzzleIndex];

  // Grid board
  int _gridRows = 5;
  int _gridCols = 5;
  List<WordPuzzleTile> _boardTiles = [];
  int _currentStep = 0; // Index into _currentPuzzle.components

  // Hints
  int _hintsRemaining = 3;
  int? _hintedTileId;

  // Stats
  int _score = 0;
  int _wordsCompletedInLevel = 0;
  bool _isSoundMuted = false;

  // Animation Controllers
  late AnimationController _shakeController;
  int? _shakingTileId;

  late AnimationController _celebrationController;
  final List<WordPuzzleSparkle> _sparkles = [];
  final Random _random = Random();

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _currentLevel = widget.initialLevel.clamp(1, 4);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _shakingTileId = null;
          });
          _shakeController.reset();
        }
      });

    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addListener(_updateSparkles);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _loadLevel(_currentLevel);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _celebrationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _loadLevel(int level) {
    _currentLevel = level;
    _levelPuzzles = wordPuzzleDatabase
        .where((p) => p.difficultyLevel == level)
        .toList();
    if (_levelPuzzles.isEmpty) {
      _levelPuzzles = wordPuzzleDatabase;
    }
    _puzzleIndex = 0;
    _wordsCompletedInLevel = 0;
    _hintsRemaining = 3;
    _loadPuzzle();
  }

  void _loadPuzzle() {
    _currentStep = 0;
    _hintedTileId = null;
    _gameState = 'playing';

    // Grid size scales with difficulty
    switch (_currentLevel) {
      case 1:
        _gridRows = 4;
        _gridCols = 5; // 20 tiles
        break;
      case 2:
        _gridRows = 4;
        _gridCols = 6; // 24 tiles
        break;
      case 3:
        _gridRows = 5;
        _gridCols = 5; // 25 tiles
        break;
      case 4:
      default:
        _gridRows = 5;
        _gridCols = 6; // 30 tiles
        break;
    }

    final totalCells = _gridRows * _gridCols;
    final puzzle = _currentPuzzle;
    final components = puzzle.components;

    // Pick random unique slot indexes for the correct components
    final allCellIndices = List.generate(totalCells, (i) => i)..shuffle(_random);
    final componentIndices = allCellIndices.take(components.length).toList();

    // Fill distractors
    final distractorPool = List<String>.from(puzzle.distractorPool)..shuffle(_random);
    int distractorIdx = 0;

    _boardTiles = List.generate(totalCells, (index) {
      final row = index ~/ _gridCols;
      final col = index % _gridCols;

      final compIdx = componentIndices.indexOf(index);
      final String letter;
      if (compIdx != -1) {
        letter = components[compIdx];
      } else {
        if (distractorIdx < distractorPool.length) {
          letter = distractorPool[distractorIdx++];
        } else {
          letter = distractorPool[_random.nextInt(distractorPool.length)];
        }
      }

      return WordPuzzleTile(
        id: index,
        component: letter,
        row: row,
        col: col,
        isMatched: false,
      );
    });

    setState(() {});
  }

  // Handle tile tap
  void _onTileTap(WordPuzzleTile tile) {
    if (_gameState != 'playing' || tile.isMatched) return;

    final targetComponent = _currentPuzzle.components[_currentStep];

    if (tile.component == targetComponent) {
      // CORRECT SELECTION
      setState(() {
        tile.isMatched = true;
        _hintedTileId = null;
        _currentStep++;
      });

      if (!_isSoundMuted) {
        AudioService.instance.playTamilAudio(tile.component);
      }

      // Check if full word is completed
      if (_currentStep >= _currentPuzzle.components.length) {
        _onWordCompleted();
      }
    } else {
      // WRONG SELECTION - GENTLE SHAKE FEEDBACK
      setState(() {
        _shakingTileId = tile.id;
      });
      _shakeController.forward(from: 0.0);

      if (!_isSoundMuted) {
        AudioService.instance.playRetryFeedback(context);
      }
    }
  }

  // Handle word completion
  Future<void> _onWordCompleted() async {
    setState(() {
      _gameState = 'word_complete';
      _score += 100;
      _wordsCompletedInLevel++;
    });

    if (!_isSoundMuted) {
      AudioService.instance.playSuccessFeedback(context);
      AudioService.instance.playTamilAudio(_currentPuzzle.word);
    }

    widget.progressService?.recordGameCompleted(1);

    _spawnCelebrationSparkles();
    _celebrationController.forward(from: 0.0);

    await Future.delayed(const Duration(milliseconds: 1800));

    if (!mounted) return;

    if (_puzzleIndex + 1 < _levelPuzzles.length) {
      // Next word in current level
      setState(() {
        _puzzleIndex++;
        _loadPuzzle();
      });
    } else {
      // Completed all words in current level!
      _onLevelCompleted();
    }
  }

  void _onLevelCompleted() {
    setState(() {
      _gameState = 'level_complete';
    });

    if (!_isSoundMuted) {
      AudioService.instance.playStarReward(context);
    }
  }

  void _useHint() {
    if (_hintsRemaining <= 0 || _gameState != 'playing') return;

    final targetComponent = _currentPuzzle.components[_currentStep];
    final matchingTile = _boardTiles.firstWhere(
      (t) => !t.isMatched && t.component == targetComponent,
      orElse: () => _boardTiles.first,
    );

    setState(() {
      _hintsRemaining--;
      _hintedTileId = matchingTile.id;
    });

    if (!_isSoundMuted) {
      AudioService.instance.playTamilAudio(targetComponent);
    }
  }

  void _spawnCelebrationSparkles() {
    _sparkles.clear();
    final colors = [
      Colors.amber,
      Colors.pinkAccent,
      Colors.cyanAccent,
      Colors.lightGreenAccent,
      Colors.purpleAccent,
      Colors.orangeAccent,
      Colors.white,
    ];

    for (int i = 0; i < 40; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 80 + _random.nextDouble() * 220;
      _sparkles.add(
        WordPuzzleSparkle(
          x: 0,
          y: 0,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - 60,
          color: colors[_random.nextInt(colors.length)],
          size: 6 + _random.nextDouble() * 10,
          life: 1.0,
          maxLife: 1.0,
        ),
      );
    }
  }

  void _updateSparkles() {
    final dt = 0.016;
    for (final s in _sparkles) {
      s.x += s.vx * dt;
      s.y += s.vy * dt;
      s.vy += 260 * dt; // gravity
      s.life -= dt;
    }
    _sparkles.removeWhere((s) => s.life <= 0);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13072E),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // Background Ambient Glowing Gradients
                Positioned(
                  top: -80,
                  right: -60,
                  width: 240,
                  height: 240,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFF4081).withOpacity(0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -60,
                  left: -60,
                  width: 240,
                  height: 240,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF00E5FF).withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Main Game Content Column
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      children: [
                        _buildTopAppBar(),
                        _buildTargetWordCard(),
                        _buildWordBuildingArea(),
                        const SizedBox(height: 6),
                        Expanded(
                          child: _buildCandyGridBoard(constraints),
                        ),
                      ],
                    ),
                  ),
                ),

                // Celebration Overlay Particles
                if (_gameState == 'word_complete')
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _SparklePainter(sparkles: _sparkles),
                      ),
                    ),
                  ),

                // Level Complete Modal
                if (_gameState == 'level_complete')
                  _buildLevelCompleteDialog(),
              ],
            );
          },
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TOP APP BAR & HUD
  // -------------------------------------------------------------
  Widget _buildTopAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topCenter,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Back button
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),

            // Title & Level selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amberAccent.withOpacity(0.6), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars_rounded, color: Colors.amberAccent, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'நிலை $_currentLevel (${_puzzleIndex + 1}/${_levelPuzzles.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Right controls: Hint & Sound
              Row(
                children: [
                  // Hint Button
                  GestureDetector(
                    onTap: _useHint,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: _hintsRemaining > 0 ? Colors.amber.withOpacity(0.2) : Colors.white10,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _hintsRemaining > 0 ? Colors.amberAccent : Colors.white24,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb_rounded, color: Colors.amberAccent, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$_hintsRemaining',
                            style: const TextStyle(
                              color: Colors.amberAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Sound Toggle
                  IconButton(
                    icon: Icon(
                      _isSoundMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () {
                      setState(() {
                        _isSoundMuted = !_isSoundMuted;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
  }

  // -------------------------------------------------------------
  // TARGET WORD CARD
  // -------------------------------------------------------------
  Widget _buildTargetWordCard() {
    final puzzle = _currentPuzzle;
    final isDone = _gameState == 'word_complete';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDone
              ? [const Color(0xFF00E676), const Color(0xFF00897B)]
              : [const Color(0xFF311B92), const Color(0xFF1A0E3D)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDone ? Colors.greenAccent : const Color(0xFFFF80AB).withOpacity(0.5),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDone ? Colors.greenAccent : const Color(0xFFFF4081)).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Target Word Label & Display
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'சொல்லை உருவாக்கு!',
                        style: TextStyle(
                          color: Color(0xFFFFD54F),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'மதிப்பெண்: $_score',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  puzzle.word,
                  style: GoogleFonts.catamaran(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                    shadows: const [
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Audio pronounce button
          GestureDetector(
            onTap: () {
              if (!_isSoundMuted) {
                AudioService.instance.playTamilAudio(puzzle.word);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFFFF4081), Color(0xFFC2185B)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF4081).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.volume_up_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // WORD BUILDING AREA / SLOTS
  // -------------------------------------------------------------
  Widget _buildWordBuildingArea() {
    final components = _currentPuzzle.components;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0E38).withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'சொல் கட்டமைப்பு:',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$_currentStep / ${components.length} முடிந்தது',
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Horizontal Slots
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(components.length, (idx) {
                final isFilled = idx < _currentStep;
                final isCurrent = idx == _currentStep && _gameState == 'playing';
                final componentLetter = isFilled ? components[idx] : '';
                final style = isFilled
                    ? CandyColorPalette.getStyleForLetter(componentLetter)
                    : null;

                return AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final pulseScale = isCurrent
                        ? 1.0 + (_pulseController.value * 0.08)
                        : 1.0;
                    return Transform.scale(
                      scale: pulseScale,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      gradient: isFilled
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: style!.gradientColors,
                            )
                          : null,
                      color: isFilled ? null : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isFilled
                            ? style!.borderColor
                            : (isCurrent
                                ? Colors.amberAccent
                                : Colors.white24),
                        width: isCurrent ? 2.5 : 1.5,
                      ),
                      boxShadow: isFilled
                          ? [
                              BoxShadow(
                                color: style!.shadowColor.withOpacity(0.6),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : (isCurrent
                              ? [
                                  BoxShadow(
                                    color: Colors.amberAccent.withOpacity(0.4),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null),
                    ),
                    child: Center(
                      child: isFilled
                          ? Text(
                              componentLetter,
                              style: GoogleFonts.catamaran(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: style!.textColor,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 3,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                            )
                          : (isCurrent
                              ? const Icon(
                                  Icons.arrow_downward_rounded,
                                  color: Colors.amberAccent,
                                  size: 18,
                                )
                              : Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.white24,
                                    shape: BoxShape.circle,
                                  ),
                                )),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // LARGE CANDY CRUSH-STYLE LETTER GRID BOARD
  // -------------------------------------------------------------
  Widget _buildCandyGridBoard(BoxConstraints constraints) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 2, 14, 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0624),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF9C27B0).withOpacity(0.5), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C27B0).withOpacity(0.25),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, boardConstraints) {
          final availableWidth = boardConstraints.maxWidth;
          final availableHeight = boardConstraints.maxHeight;

          final tileWidth = (availableWidth - (_gridCols - 1) * 6) / _gridCols;
          final tileHeight = (availableHeight - (_gridRows - 1) * 6) / _gridRows;
          final tileSize = min(tileWidth, tileHeight).clamp(38.0, 68.0);

          return Center(
            child: SizedBox(
              width: _gridCols * (tileSize + 6) - 6,
              height: _gridRows * (tileSize + 6) - 6,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _boardTiles.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _gridCols,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, index) {
                  final tile = _boardTiles[index];
                  return _buildCandyTile(tile, tileSize);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCandyTile(WordPuzzleTile tile, double size) {
    final style = CandyColorPalette.getStyleForLetter(tile.component);
    final isShaking = _shakingTileId == tile.id;
    final isHinted = _hintedTileId == tile.id;

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        double shakeOffset = 0.0;
        if (isShaking) {
          shakeOffset = sin(_shakeController.value * pi * 8) * 6.0;
        }
        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () => _onTileTap(tile),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: tile.isMatched ? 0.28 : 1.0,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 180),
            scale: tile.isMatched ? 0.88 : (isHinted ? 1.08 : 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.4),
                  radius: 0.9,
                  colors: style.gradientColors,
                ),
                borderRadius: BorderRadius.circular(size * 0.26),
                border: Border.all(
                  color: isHinted
                      ? Colors.amberAccent
                      : (isShaking ? Colors.redAccent : style.borderColor),
                  width: isHinted || isShaking ? 3.0 : 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isHinted
                        ? Colors.amberAccent.withOpacity(0.7)
                        : style.shadowColor.withOpacity(0.55),
                    blurRadius: isHinted ? 10 : 4,
                    offset: const Offset(0, 2.5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Top Gloss Reflection Highlight
                  Positioned(
                    top: 2,
                    left: 3,
                    right: 3,
                    height: size * 0.24,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.65),
                            Colors.white.withOpacity(0.0),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(size * 0.18),
                      ),
                    ),
                  ),

                  // Hint indicator badge
                  if (isHinted)
                    const Positioned(
                      top: 2,
                      right: 2,
                      child: Icon(
                        Icons.lightbulb_rounded,
                        color: Colors.amberAccent,
                        size: 14,
                      ),
                    ),

                  // Tamil Letter Text
                  Center(
                    child: Text(
                      tile.component,
                      style: GoogleFonts.catamaran(
                        fontSize: (size * 0.44).clamp(16.0, 26.0),
                        fontWeight: FontWeight.w900,
                        color: style.textColor,
                        shadows: const [
                          Shadow(
                            color: Color(0xCC000000),
                            offset: Offset(1.5, 1.5),
                            blurRadius: 4,
                          ),
                          Shadow(
                            color: Color(0x66000000),
                            offset: Offset(-1.0, -1.0),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Checked icon if matched
                  if (tile.isMatched)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(size * 0.26),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 20,
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

  // -------------------------------------------------------------
  // LEVEL COMPLETE MODAL
  // -------------------------------------------------------------
  Widget _buildLevelCompleteDialog() {
    return Container(
      color: Colors.black.withOpacity(0.75),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF311B92), Color(0xFF1A0E3D)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.amberAccent, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.amberAccent.withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'நிலை முடிந்தது!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'அருமையாக அனைத்து ($_wordsCompletedInLevel) சொற்களையும் அமைத்தாய்!\nமதிப்பெண்: $_score',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFFD54F),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Star badges
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_rounded, size: 44, color: Colors.amberAccent),
                  Icon(Icons.star_rounded, size: 54, color: Colors.amberAccent),
                  Icon(Icons.star_rounded, size: 44, color: Colors.amberAccent),
                ],
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  if (_currentLevel < 4)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _loadLevel(_currentLevel + 1);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E676),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'அடுத்த நிலை ➡️',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  if (_currentLevel < 4) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _loadLevel(_currentLevel);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4081),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'மீண்டும் ஆடு 🔄',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
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

/// Custom painter for fireworks sparkle celebration
class _SparklePainter extends CustomPainter {
  final List<WordPuzzleSparkle> sparkles;

  _SparklePainter({required this.sparkles});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.35);

    for (final s in sparkles) {
      final paint = Paint()
        ..color = s.color.withOpacity(s.life.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(center.dx + s.x, center.dy + s.y),
        s.size * s.life,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) => true;
}
