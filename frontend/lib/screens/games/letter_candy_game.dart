import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/uyir_data.dart';
import '../../data/mei_data.dart';
import '../../data/uyirmei_data.dart';
import '../../models/letter_candy_game_model.dart';
import '../../models/letter_model.dart';
import '../../services/audio_service.dart';
import '../../services/progress_service.dart';

class TamilLetterCandyGame extends StatefulWidget {
  final ProgressService? progressService;
  final int initialLevel;

  const TamilLetterCandyGame({
    super.key,
    this.progressService,
    this.initialLevel = 1,
  });

  @override
  State<TamilLetterCandyGame> createState() => _TamilLetterCandyGameState();
}

class _TamilLetterCandyGameState extends State<TamilLetterCandyGame>
    with TickerProviderStateMixin {
  // Grid size
  static const int kGridRows = 7;
  static const int kGridCols = 7;

  // Game States: 'start', 'playing', 'level_complete', 'game_over'
  String _gameState = 'start';

  late int _currentLevelIndex;
  late List<CandyGameLevel> _levels;
  CandyGameLevel get _currentLevel => _levels[_currentLevelIndex];

  // 2D Board Grid
  late List<List<CandyTile?>> _board;
  int _tileIdCounter = 0;

  // Selected tile for tap-to-swap
  CandyTile? _selectedTile;

  // Drag interaction tracking
  int? _dragRow;
  int? _dragCol;
  Offset _dragDelta = Offset.zero;

  // Game stats
  int _score = 0;
  int _highScore = 0;
  int _movesLeft = 20;
  int _secondsLeft = 60;
  Timer? _gameTimer;
  int _starsEarned = 0;
  int _matchesCount = 0;
  int _maxComboCount = 0;
  int _currentComboMultiplier = 1;

  // State flags to prevent multiple interactions while resolving matches
  bool _isProcessing = false;
  bool _isSoundMuted = false;

  // Combo text animation overlay
  String? _comboText;
  late AnimationController _comboAnimController;
  late Animation<double> _comboScaleAnim;
  late Animation<double> _comboOpacityAnim;

  // Gentle feedback overlay
  String? _encouragementText;
  Timer? _encouragementTimer;

  // Particles system
  final List<CandySparkleParticle> _particles = [];
  late AnimationController _particleController;
  final Random _random = Random();

  // Floating background candies for start screen & game background
  late AnimationController _bgFloatController;

  @override
  void initState() {
    super.initState();
    _currentLevelIndex = (widget.initialLevel - 1).clamp(0, 4);
    _buildLevels();

    // Setup animations
    _comboAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _comboScaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 1.25).chain(CurveTween(curve: Curves.easeOutBack)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15).chain(CurveTween(curve: Curves.easeIn)), weight: 40),
    ]).animate(_comboAnimController);

    _comboOpacityAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_comboAnimController);

    _comboAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _comboText = null;
          });
        }
      }
    });

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateParticles);
    _particleController.repeat();

    _bgFloatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _initBoard();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _encouragementTimer?.cancel();
    _comboAnimController.dispose();
    _particleController.dispose();
    _bgFloatController.dispose();
    super.dispose();
  }

  void _buildLevels() {
    // Level 1: Uyir Letters (Short & Long vowels)
    final uyirPool = uyirLettersList.take(6).toList(); // அ, ஆ, இ, ஈ, உ, ஊ

    // Level 2: Mei Letters
    final meiPool = meiLettersList.take(6).toList(); // க், ங், ச், ஞ், ட், ண்

    // Level 3: Uyirmei Letters (Ka series)
    final kaRow = uyirmeiLettersMap['க்'] ?? [];
    final uyirmeiPool = (kaRow.isNotEmpty ? kaRow.take(6).toList() : uyirPool);

    // Level 4: Mixed (Uyir + Mei)
    final mixedPool = [
      uyirLettersList[0], // அ
      uyirLettersList[1], // ஆ
      meiLettersList[0],  // க்
      meiLettersList[4],  // ட்
      uyirLettersList[4], // உ
      meiLettersList[11], // ம்
    ];

    // Level 5: Speed Challenge (60s countdown)
    final speedPool = [
      uyirLettersList[0], // அ
      uyirLettersList[1], // ஆ
      uyirLettersList[2], // இ
      meiLettersList[0],  // க்
      meiLettersList[11], // ம்
      if (kaRow.isNotEmpty) kaRow[0] else uyirLettersList[4],
    ];

    _levels = [
      CandyGameLevel(
        levelNumber: 1,
        title: 'உயிர் எழுத்துகள்',
        subtitle: 'முதல் படி',
        description: 'உயிர் எழுத்து மிட்டாய்களை 3 ஒன்றாக இணைக்கவும்!',
        letterPool: uyirPool,
        targetScore: 800,
        maxMoves: 22,
      ),
      CandyGameLevel(
        levelNumber: 2,
        title: 'மெய் எழுத்துகள்',
        subtitle: 'புள்ளி எழுத்துகள்',
        description: 'மெய் எழுத்துகளை இணைத்து சுவையான மிட்டாய் வெடிப்புகளை உருவாக்குங்கள்!',
        letterPool: meiPool,
        targetScore: 1200,
        maxMoves: 20,
      ),
      CandyGameLevel(
        levelNumber: 3,
        title: 'உயிர்மெய் எழுத்துகள்',
        subtitle: 'இனிமையான சேர்க்கை',
        description: 'உயிர்மெய் எழுத்து மிட்டாய்களை இணைத்து அதிக புள்ளிகள் பெறுங்கள்!',
        letterPool: uyirmeiPool,
        targetScore: 1600,
        maxMoves: 20,
      ),
      CandyGameLevel(
        levelNumber: 4,
        title: 'கலவை எழுத்துகள்',
        subtitle: 'மகா மிட்டாய் சவால்',
        description: 'உயிர் மற்றும் மெய் எழுத்துகளின் வண்ணமயமான சேர்க்கை!',
        letterPool: mixedPool,
        targetScore: 2000,
        maxMoves: 20,
      ),
      CandyGameLevel(
        levelNumber: 5,
        title: 'வேக சவால் (60 நொடி)',
        subtitle: 'மின்னல் வேகம்',
        description: 'நேரம் முடிவதற்குள் 2500 புள்ளிகளைப் பெற்று வெற்றி பெறுங்கள்!',
        letterPool: speedPool,
        targetScore: 2500,
        maxMoves: 99,
        timeLimitSeconds: 60,
      ),
    ];
  }

  // Generate random candy tile from current level pool
  CandyTile _generateRandomTile(int r, int c, {int? id}) {
    final pool = _currentLevel.letterPool;
    final letterModel = pool[_random.nextInt(pool.length)];
    final style = CandyColorPalette.getStyleForLetter(letterModel.letter);

    return CandyTile(
      id: id ?? ++_tileIdCounter,
      letterModel: letterModel,
      row: r,
      col: c,
      gradientColors: style.gradientColors,
      borderColor: style.borderColor,
      shadowColor: style.shadowColor,
      textColor: style.textColor,
    );
  }

  // Initialize board without pre-existing 3-in-a-row matches
  void _initBoard() {
    _board = List.generate(
      kGridRows,
      (r) => List.generate(kGridCols, (c) => null),
    );

    for (int r = 0; r < kGridRows; r++) {
      for (int c = 0; c < kGridCols; c++) {
        CandyTile tile;
        do {
          tile = _generateRandomTile(r, c);
          _board[r][c] = tile;
        } while (_createsMatchAt(r, c));
      }
    }
  }

  bool _createsMatchAt(int r, int c) {
    final letter = _board[r][c]?.letter;
    if (letter == null) return false;

    // Check horizontal match with previous 2
    if (c >= 2 &&
        _board[r][c - 1]?.letter == letter &&
        _board[r][c - 2]?.letter == letter) {
      return true;
    }

    // Check vertical match with previous 2
    if (r >= 2 &&
        _board[r - 1][c]?.letter == letter &&
        _board[r - 2][c]?.letter == letter) {
      return true;
    }

    return false;
  }

  void _startGame() {
    _initBoard();
    setState(() {
      _gameState = 'playing';
      _score = 0;
      _matchesCount = 0;
      _maxComboCount = 0;
      _movesLeft = _currentLevel.maxMoves;
      _secondsLeft = _currentLevel.timeLimitSeconds ?? 60;
      _isProcessing = false;
      _selectedTile = null;
      _comboText = null;
      _encouragementText = null;
    });

    _gameTimer?.cancel();
    if (_currentLevel.isTimed) {
      _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        if (_gameState != 'playing') {
          timer.cancel();
          return;
        }
        setState(() {
          if (_secondsLeft > 0) {
            _secondsLeft--;
            if (_secondsLeft == 0) {
              _onTimeOrMovesExhausted();
            }
          }
        });
      });
    }
  }

  // -------------------------------------------------------------
  // MATCH-3 GAME ENGINE
  // -------------------------------------------------------------

  // Handle tile tap selection
  void _onTileTap(int r, int c) {
    if (_isProcessing || _gameState != 'playing') return;

    final tapped = _board[r][c];
    if (tapped == null) return;

    if (_selectedTile == null) {
      setState(() {
        _selectedTile = tapped;
        tapped.isSelected = true;
      });
    } else {
      final prev = _selectedTile!;
      final dr = (prev.row - r).abs();
      final dc = (prev.col - c).abs();

      // Adjacent check (manhattan distance = 1)
      if ((dr == 1 && dc == 0) || (dr == 0 && dc == 1)) {
        setState(() {
          prev.isSelected = false;
          _selectedTile = null;
        });
        _attemptSwap(prev.row, prev.col, r, c);
      } else {
        // Switch selection
        setState(() {
          prev.isSelected = false;
          tapped.isSelected = true;
          _selectedTile = tapped;
        });
      }
    }
  }

  // Handle swipe gestures
  void _onPanStart(DragStartDetails details, int r, int c) {
    if (_isProcessing || _gameState != 'playing') return;
    _dragRow = r;
    _dragCol = c;
    _dragDelta = Offset.zero;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isProcessing || _dragRow == null || _dragCol == null) return;
    _dragDelta += details.delta;
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isProcessing || _dragRow == null || _dragCol == null) {
      _dragRow = null;
      _dragCol = null;
      return;
    }

    const minSwipeDist = 18.0;
    final r = _dragRow!;
    final c = _dragCol!;
    _dragRow = null;
    _dragCol = null;

    if (_dragDelta.distance < minSwipeDist) return;

    int targetR = r;
    int targetC = c;

    if (_dragDelta.dx.abs() > _dragDelta.dy.abs()) {
      // Horizontal swipe
      targetC += _dragDelta.dx > 0 ? 1 : -1;
    } else {
      // Vertical swipe
      targetR += _dragDelta.dy > 0 ? 1 : -1;
    }

    if (targetR >= 0 && targetR < kGridRows && targetC >= 0 && targetC < kGridCols) {
      if (_selectedTile != null) {
        _selectedTile!.isSelected = false;
        _selectedTile = null;
      }
      _attemptSwap(r, c, targetR, targetC);
    }
  }

  // Attempt swapping two tiles
  Future<void> _attemptSwap(int r1, int c1, int r2, int c2) async {
    _isProcessing = true;

    final t1 = _board[r1][c1];
    final t2 = _board[r2][c2];
    if (t1 == null || t2 == null) {
      _isProcessing = false;
      return;
    }

    // Perform swap in data
    _board[r1][c1] = t2;
    _board[r2][c2] = t1;
    t1.row = r2;
    t1.col = c2;
    t2.row = r1;
    t2.col = c1;

    setState(() {});

    // Check if swap produces any match
    final matches = _findAllMatches();

    if (matches.isEmpty) {
      // Gentle invalid swap feedback
      _showEncouragement('மீண்டும் முயற்சி செய்! 😊');
      await Future.delayed(const Duration(milliseconds: 260));

      // Swap back
      if (mounted) {
        setState(() {
          _board[r1][c1] = t1;
          _board[r2][c2] = t2;
          t1.row = r1;
          t1.col = c1;
          t2.row = r2;
          t2.col = c2;
        });
      }
      _isProcessing = false;
      return;
    }

    // Valid swap -> Decrement moves if not timed
    if (!_currentLevel.isTimed) {
      setState(() {
        _movesLeft--;
      });
    }

    _currentComboMultiplier = 1;
    await _resolveBoardCascades();

    // Check win/lose conditions
    _checkGameCondition();

    _isProcessing = false;
  }

  // Identify all contiguous 3+ lines (horizontal & vertical)
  Set<Point<int>> _findAllMatches() {
    final Set<Point<int>> matchedPoints = {};

    // Horizontal check
    for (int r = 0; r < kGridRows; r++) {
      int matchLen = 1;
      for (int c = 0; c < kGridCols; c++) {
        final current = _board[r][c];
        final next = (c < kGridCols - 1) ? _board[r][c + 1] : null;

        if (current != null && next != null && current.letter == next.letter) {
          matchLen++;
        } else {
          if (matchLen >= 3) {
            for (int k = c - matchLen + 1; k <= c; k++) {
              matchedPoints.add(Point(r, k));
            }
          }
          matchLen = 1;
        }
      }
    }

    // Vertical check
    for (int c = 0; c < kGridCols; c++) {
      int matchLen = 1;
      for (int r = 0; r < kGridRows; r++) {
        final current = _board[r][c];
        final next = (r < kGridRows - 1) ? _board[r + 1][c] : null;

        if (current != null && next != null && current.letter == next.letter) {
          matchLen++;
        } else {
          if (matchLen >= 3) {
            for (int k = r - matchLen + 1; k <= r; k++) {
              matchedPoints.add(Point(k, c));
            }
          }
          matchLen = 1;
        }
      }
    }

    return matchedPoints;
  }

  // Resolve matching, special candy creation, collapsing, and cascading
  Future<void> _resolveBoardCascades() async {
    while (true) {
      final matches = _findAllMatches();
      if (matches.isEmpty) break;

      _matchesCount++;

      // Trigger Tamil pronunciation audio for the first matched letter
      final firstPoint = matches.first;
      final matchedTile = _board[firstPoint.x][firstPoint.y];
      if (matchedTile != null) {
        _playLetterAudio(matchedTile);
      }

      // Detect special candy formations
      Point<int>? specialSpawnPoint;
      CandySpecialType specialTypeToSpawn = CandySpecialType.none;
      LetterModel? specialLetterModel;

      if (matches.length == 4) {
        specialTypeToSpawn = _random.nextBool() ? CandySpecialType.rowBlast : CandySpecialType.colBlast;
        specialSpawnPoint = matches.first;
        specialLetterModel = _board[specialSpawnPoint.x][specialSpawnPoint.y]?.letterModel;
      } else if (matches.length >= 5) {
        specialTypeToSpawn = CandySpecialType.bomb;
        specialSpawnPoint = matches.first;
        specialLetterModel = _board[specialSpawnPoint.x][specialSpawnPoint.y]?.letterModel;
      }

      // Expand matches if any matched tile was already a special powerup
      final Set<Point<int>> totalEliminated = Set.from(matches);
      for (final pt in matches) {
        final t = _board[pt.x][pt.y];
        if (t != null) {
          if (t.specialType == CandySpecialType.rowBlast) {
            for (int c = 0; c < kGridCols; c++) {
              totalEliminated.add(Point(pt.x, c));
            }
          } else if (t.specialType == CandySpecialType.colBlast) {
            for (int r = 0; r < kGridRows; r++) {
              totalEliminated.add(Point(r, pt.y));
            }
          } else if (t.specialType == CandySpecialType.bomb) {
            for (int dr = -1; dr <= 1; dr++) {
              for (int dc = -1; dc <= 1; dc++) {
                final nr = pt.x + dr;
                final nc = pt.y + dc;
                if (nr >= 0 && nr < kGridRows && nc >= 0 && nc < kGridCols) {
                  totalEliminated.add(Point(nr, nc));
                }
              }
            }
          }
        }
      }

      // Emit particle explosion for all eliminated tiles
      for (final pt in totalEliminated) {
        final t = _board[pt.x][pt.y];
        if (t != null) {
          _emitCandyPopParticles(pt.x, pt.y, t.gradientColors.first);
        }
      }

      // Calculate score
      final basePoints = totalEliminated.length * 30;
      final comboBonus = (_currentComboMultiplier - 1) * 50;
      final addedScore = (basePoints + comboBonus) * _currentComboMultiplier;

      setState(() {
        _score += addedScore;
        if (_score > _highScore) _highScore = _score;
      });

      // Show combo celebration banners
      if (_currentComboMultiplier == 2) {
        _triggerComboBanner('✨ அருமை!');
      } else if (_currentComboMultiplier == 3) {
        _triggerComboBanner('🔥 சூப்பர் காம்போ!');
      } else if (_currentComboMultiplier >= 4) {
        _triggerComboBanner('🔥🔥 மெகா காம்போ!');
      }

      if (_currentComboMultiplier > _maxComboCount) {
        _maxComboCount = _currentComboMultiplier;
      }

      // Animate popping scale down
      for (final pt in totalEliminated) {
        if (_board[pt.x][pt.y] != null) {
          _board[pt.x][pt.y]!.isMatched = true;
          _board[pt.x][pt.y]!.scale = 0.0;
        }
      }
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 220));

      // Remove eliminated tiles from board
      for (final pt in totalEliminated) {
        _board[pt.x][pt.y] = null;
      }

      // Spawn special candy if earned
      if (specialSpawnPoint != null && specialLetterModel != null && specialTypeToSpawn != CandySpecialType.none) {
        final style = CandyColorPalette.getStyleForLetter(specialLetterModel.letter);
        _board[specialSpawnPoint.x][specialSpawnPoint.y] = CandyTile(
          id: ++_tileIdCounter,
          letterModel: specialLetterModel,
          row: specialSpawnPoint.x,
          col: specialSpawnPoint.y,
          specialType: specialTypeToSpawn,
          gradientColors: style.gradientColors,
          borderColor: style.borderColor,
          shadowColor: style.shadowColor,
          textColor: style.textColor,
        );
      }

      // Gravity: Drop tiles down
      for (int c = 0; c < kGridCols; c++) {
        int emptyRow = kGridRows - 1;
        for (int r = kGridRows - 1; r >= 0; r--) {
          if (_board[r][c] != null) {
            if (r != emptyRow) {
              final movingTile = _board[r][c]!;
              _board[emptyRow][c] = movingTile;
              _board[r][c] = null;
              movingTile.row = emptyRow;
              movingTile.col = c;
            }
            emptyRow--;
          }
        }

        // Fill remaining top empty spaces with new tiles
        for (int r = emptyRow; r >= 0; r--) {
          _board[r][c] = _generateRandomTile(r, c);
        }
      }

      setState(() {});
      await Future.delayed(const Duration(milliseconds: 250));

      _currentComboMultiplier++;
    }
  }

  void _triggerComboBanner(String text) {
    setState(() {
      _comboText = text;
    });
    _comboAnimController.forward(from: 0.0);
  }

  void _showEncouragement(String msg) {
    _encouragementTimer?.cancel();
    setState(() {
      _encouragementText = msg;
    });
    _encouragementTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _encouragementText = null;
        });
      }
    });
  }

  // Play native Tamil audio for letter
  void _playLetterAudio(CandyTile tile) {
    if (_isSoundMuted) return;
    try {
      AudioService.instance.playLetterSound(
        context,
        letter: tile.letter,
        word: tile.word,
        audioPath: tile.audioPath,
        showIndicator: false,
      );

      // Also record letter learning progress
      widget.progressService?.markLetterCompleted(tile.letter);
    } catch (_) {
      // Fail gracefully if audio asset is missing
    }
  }

  // Check victory / game over
  void _checkGameCondition() {
    if (_score >= _currentLevel.targetScore) {
      _onLevelComplete();
    } else if (!_currentLevel.isTimed && _movesLeft <= 0) {
      _onTimeOrMovesExhausted();
    }
  }

  void _onLevelComplete() {
    _gameTimer?.cancel();
    // Calculate star rating (1 to 3 stars based on score vs target)
    if (_score >= _currentLevel.targetScore * 1.5) {
      _starsEarned = 3;
    } else if (_score >= _currentLevel.targetScore * 1.2) {
      _starsEarned = 2;
    } else {
      _starsEarned = 1;
    }

    try {
      widget.progressService?.recordGameCompleted(_starsEarned);
    } catch (_) {}

    setState(() {
      _gameState = 'level_complete';
    });
  }

  void _onTimeOrMovesExhausted() {
    _gameTimer?.cancel();
    if (_score >= _currentLevel.targetScore) {
      _onLevelComplete();
    } else {
      setState(() {
        _gameState = 'game_over';
      });
    }
  }

  void _nextLevel() {
    if (_currentLevelIndex < _levels.length - 1) {
      _currentLevelIndex++;
    }
    _startGame();
  }

  // -------------------------------------------------------------
  // PARTICLE SYSTEM
  // -------------------------------------------------------------
  void _emitCandyPopParticles(int r, int c, Color baseColor) {
    final double originX = 40.0 + c * 44.0;
    final double originY = 160.0 + r * 44.0;

    for (int i = 0; i < 14; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 1.5 + _random.nextDouble() * 4.0;
      _particles.add(
        CandySparkleParticle(
          x: originX,
          y: originY,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          color: i.isEven ? baseColor : Colors.amberAccent,
          size: 4.0 + _random.nextDouble() * 6.0,
          life: 0.0,
          maxLife: 0.6 + _random.nextDouble() * 0.4,
          isStar: i % 3 == 0,
        ),
      );
    }
  }

  void _updateParticles() {
    if (_particles.isEmpty) return;
    const dt = 0.016;
    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.life += dt;
      p.x += p.vx;
      p.y += p.vy;
      p.vy += 0.08; // subtle gravity

      if (p.life >= p.maxLife) {
        _particles.removeAt(i);
      }
    }
    if (mounted && _particles.isNotEmpty) {
      setState(() {});
    }
  }

  // -------------------------------------------------------------
  // BUILD UI
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1035), // Deep magical candy purple
      body: SafeArea(
        child: Stack(
          children: [
            // Background Animated Soft Candy Clouds & Sparkles
            Positioned.fill(
              child: _buildCandyBackground(),
            ),

            // Particle overlay painter
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: CandyParticlePainter(particles: _particles),
                ),
              ),
            ),

            // Main Active View
            if (_gameState == 'start')
              _buildStartScreen()
            else if (_gameState == 'playing')
              _buildPlayingScreen()
            else if (_gameState == 'level_complete')
              _buildLevelCompleteScreen()
            else if (_gameState == 'game_over')
              _buildGameOverScreen(),

            // Combo Notification Overlay
            if (_comboText != null)
              Center(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _comboAnimController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _comboScaleAnim.value,
                        child: Opacity(
                          opacity: _comboOpacityAnim.value.clamp(0.0, 1.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF1744), Color(0xFFFF9100), Color(0xFFFFD600)],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.6),
                                  blurRadius: 18,
                                  spreadRadius: 4,
                                ),
                              ],
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: Text(
                              _comboText!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  Shadow(
                                    color: Colors.black45,
                                    offset: Offset(2, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Gentle Encouragement Overlay
            if (_encouragementText != null)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white38),
                    ),
                    child: Text(
                      _encouragementText!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // START SCREEN
  // -------------------------------------------------------------
  Widget _buildStartScreen() {
    return Column(
      children: [
        // Top App Bar Navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isSoundMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      color: Colors.white,
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

        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Animated Mascot / Candy Illustration
                AnimatedBuilder(
                  animation: _bgFloatController,
                  builder: (context, child) {
                    final offsetY = sin(_bgFloatController.value * 2 * pi) * 8.0;
                    return Transform.translate(
                      offset: Offset(0, offsetY),
                      child: child,
                    );
                  },
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFFFF4081), Color(0xFF7B1FA2)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF4081).withOpacity(0.5),
                          blurRadius: 28,
                          spreadRadius: 6,
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: const Center(
                      child: Text(
                        '🍬',
                        style: TextStyle(fontSize: 72),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Title
                const Text(
                  'தமிழ் எழுத்து மிட்டாய்',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Color(0xFFE040FB),
                        blurRadius: 14,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  '“3 அல்லது அதற்கு மேற்பட்ட ஒரே எழுத்துகளை இணைத்து வெல்லுங்கள்!”',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFFFD54F),
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 24),

                // Level Selector Carousel
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.layers_rounded, color: Colors.amberAccent, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'நிலையைத் தேர்ந்தெடுக்கவும்:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _levels.length,
                          itemBuilder: (context, idx) {
                            final lvl = _levels[idx];
                            final isSelected = idx == _currentLevelIndex;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _currentLevelIndex = idx;
                                });
                              },
                              child: Container(
                                width: 130,
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isSelected
                                        ? [const Color(0xFFFF4081), const Color(0xFFFF9100)]
                                        : [Colors.white.withOpacity(0.12), Colors.white.withOpacity(0.05)],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? Colors.white : Colors.white24,
                                    width: isSelected ? 2.5 : 1.0,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFFFF4081).withOpacity(0.4),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'நிலை ${lvl.levelNumber}',
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.amberAccent,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      lvl.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      '🎯 ${lvl.targetScore}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Play Button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: const Color(0xFF00E676).withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: const BorderSide(color: Colors.white, width: 2.5),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'விளையாடலாம் 🎮',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // PLAYING SCREEN & HUD
  // -------------------------------------------------------------
  Widget _buildPlayingScreen() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            // Top HUD Status Bar
            _buildGameHUD(),

            // Encouraging Level Goal Tag
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _currentLevel.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    _currentLevel.isTimed
                        ? '⏳ வினாடி: $_secondsLeft'
                        : '🔄 நகர்வுகள்: $_movesLeft',
                    style: TextStyle(
                      color: (_currentLevel.isTimed && _secondsLeft <= 10) || (!_currentLevel.isTimed && _movesLeft <= 5)
                          ? Colors.redAccent
                          : Colors.amberAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),

            // Match-3 Candy Grid Container
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: _buildMatch3Grid(constraints),
                ),
              ),
            ),

            // Bottom Audio & Control Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Pause / Exit button
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _gameState = 'start';
                      });
                    },
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 18),
                    label: const Text(
                      'வெளியேறு',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),

                  // Restart level
                  TextButton.icon(
                    onPressed: _startGame,
                    icon: const Icon(Icons.refresh_rounded, color: Colors.amberAccent, size: 18),
                    label: const Text(
                      'மீண்டும்',
                      style: TextStyle(color: Colors.amberAccent, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Top Game HUD Cards
  Widget _buildGameHUD() {
    final progress = (_score / _currentLevel.targetScore).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2D184E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purpleAccent.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Current Score
                _buildHUDCard(
                  icon: Icons.star_rounded,
                  iconColor: Colors.amber,
                  label: 'மதிப்பெண்',
                  value: '$_score',
                ),
                const SizedBox(width: 24),

                // Level Target Score
                _buildHUDCard(
                  icon: Icons.track_changes_rounded,
                  iconColor: Colors.cyanAccent,
                  label: 'இலக்கு',
                  value: '${_currentLevel.targetScore}',
                ),
                const SizedBox(width: 24),

                // Moves or Timer
                _buildHUDCard(
                  icon: _currentLevel.isTimed ? Icons.timer_rounded : Icons.favorite_rounded,
                  iconColor: Colors.pinkAccent,
                  label: _currentLevel.isTimed ? 'நேரம்' : 'நகர்வு',
                  value: _currentLevel.isTimed ? '${_secondsLeft}s' : '$_movesLeft',
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Target Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHUDCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // MATCH-3 GRID WIDGET
  // -------------------------------------------------------------
  Widget _buildMatch3Grid(BoxConstraints constraints) {
    // Calculate optimum square cell size to fit safely without overflow
    final maxGridWidth = constraints.maxWidth - 24;
    final maxGridHeight = constraints.maxHeight - 140;
    final boardSize = min(maxGridWidth, maxGridHeight).clamp(260.0, 420.0);
    final cellSize = (boardSize / kGridCols);

    return Container(
      width: boardSize,
      height: boardSize,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF140A26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF9C27B0).withOpacity(0.6), width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C27B0).withOpacity(0.3),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background grid checkerboard cells
          for (int r = 0; r < kGridRows; r++)
            for (int c = 0; c < kGridCols; c++)
              Positioned(
                left: c * (cellSize - 12 / kGridCols),
                top: r * (cellSize - 12 / kGridRows),
                width: cellSize - 12 / kGridCols,
                height: cellSize - 12 / kGridRows,
                child: Container(
                  margin: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    color: (r + c).isEven
                        ? Colors.white.withOpacity(0.04)
                        : Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

          // Interactive Candy Tiles
          for (int r = 0; r < kGridRows; r++)
            for (int c = 0; c < kGridCols; c++)
              if (_board[r][c] != null)
                _buildCandyTileWidget(
                  _board[r][c]!,
                  r,
                  c,
                  cellSize - 12 / kGridCols,
                ),
        ],
      ),
    );
  }

  Widget _buildCandyTileWidget(
    CandyTile tile,
    int r,
    int c,
    double tileSize,
  ) {
    return Positioned(
      left: c * tileSize,
      top: r * tileSize,
      width: tileSize,
      height: tileSize,
      child: GestureDetector(
        onTap: () => _onTileTap(r, c),
        onPanStart: (d) => _onPanStart(d, r, c),
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: AnimatedScale(
          scale: tile.isMatched ? 0.0 : (tile.isSelected ? 1.14 : 1.0),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          child: Container(
            margin: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.4),
                radius: 0.9,
                colors: tile.gradientColors,
              ),
              borderRadius: BorderRadius.circular(tileSize * 0.28),
              border: Border.all(
                color: tile.isSelected ? Colors.white : tile.borderColor,
                width: tile.isSelected ? 3.0 : 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: tile.isSelected
                      ? Colors.white.withOpacity(0.7)
                      : tile.shadowColor.withOpacity(0.55),
                  blurRadius: tile.isSelected ? 10 : 4,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Top Gloss Reflection Highlight
                Positioned(
                  top: 3,
                  left: 4,
                  right: 4,
                  height: tileSize * 0.26,
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
                      borderRadius: BorderRadius.circular(tileSize * 0.2),
                    ),
                  ),
                ),

                // Special Candy Icon Indicator
                if (tile.specialType != CandySpecialType.none)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        tile.specialType == CandySpecialType.bomb
                            ? Icons.star_rounded
                            : (tile.specialType == CandySpecialType.rowBlast
                                ? Icons.swap_horiz_rounded
                                : Icons.swap_vert_rounded),
                        size: 10,
                        color: Colors.black,
                      ),
                    ),
                  ),

                // Tamil Letter Text
                Center(
                  child: Text(
                    tile.letter,
                    style: GoogleFonts.catamaran(
                      fontSize: (tileSize * 0.46).clamp(16.0, 26.0),
                      fontWeight: FontWeight.w900,
                      color: tile.textColor,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // LEVEL COMPLETE DIALOG
  // -------------------------------------------------------------
  Widget _buildLevelCompleteScreen() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF2B1449),
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
              '🎉 நிலை முடிந்தது! 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'அருமையாக விளையாடினாய்!',
              style: TextStyle(
                color: Color(0xFFFFD54F),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),

            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (idx) {
                final earned = idx < _starsEarned;
                return Icon(
                  Icons.star_rounded,
                  size: 48,
                  color: earned ? Colors.amberAccent : Colors.white24,
                );
              }),
            ),

            const SizedBox(height: 16),

            // Stats
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildStatRow('🏆 இறுதி மதிப்பெண்', '$_score'),
                  const SizedBox(height: 6),
                  _buildStatRow('🍬 இணைப்புகள்', '$_matchesCount'),
                  const SizedBox(height: 6),
                  _buildStatRow('🔥 சிறந்த காம்போ', 'x$_maxComboCount'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _startGame,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'மீண்டும் 🔄',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _nextLevel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'அடுத்த நிலை ➜',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // GAME OVER DIALOG
  // -------------------------------------------------------------
  Widget _buildGameOverScreen() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF2B1449),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.pinkAccent, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.pinkAccent.withOpacity(0.35),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'விளையாட்டு முடிந்தது',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'சிறப்பாக முயற்சித்தாய்! மீண்டும் ஒருமுறை விளையாடு!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFFF80AB),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),

            Text(
              'மதிப்பெண்: $_score / ${_currentLevel.targetScore}',
              style: const TextStyle(
                color: Colors.amberAccent,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _gameState = 'start';
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('வெளியேறு'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4081),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'மீண்டும் விளையாடு 🔄',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // ANIMATED CANDY BACKGROUND
  // -------------------------------------------------------------
  Widget _buildCandyBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF230D3E),
            Color(0xFF140824),
          ],
        ),
      ),
      child: AnimatedBuilder(
        animation: _bgFloatController,
        builder: (context, child) {
          final t = _bgFloatController.value;
          return CustomPaint(
            painter: CandyBgPainter(animationValue: t),
          );
        },
      ),
    );
  }
}

/// Particle painter for pop explosions
class CandyParticlePainter extends CustomPainter {
  final List<CandySparkleParticle> particles;

  CandyParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final alpha = (1.0 - p.progress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withOpacity(alpha)
        ..style = PaintingStyle.fill;

      if (p.isStar) {
        final path = Path();
        final s = p.size;
        path.moveTo(p.x, p.y - s);
        path.lineTo(p.x + s * 0.3, p.y - s * 0.3);
        path.lineTo(p.x + s, p.y);
        path.lineTo(p.x + s * 0.3, p.y + s * 0.3);
        path.lineTo(p.x, p.y + s);
        path.lineTo(p.x - s * 0.3, p.y + s * 0.3);
        path.lineTo(p.x - s, p.y);
        path.lineTo(p.x - s * 0.3, p.y - s * 0.3);
        path.close();
        canvas.drawPath(path, paint);
      } else {
        canvas.drawCircle(Offset(p.x, p.y), p.size * (1.0 - p.progress * 0.5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CandyParticlePainter oldDelegate) => true;
}

/// Floating subtle background sparkles and bubbles
class CandyBgPainter extends CustomPainter {
  final double animationValue;

  CandyBgPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw floating bubbles
    final bubblePositions = [
      Offset(size.width * 0.15, size.height * 0.25 + sin(animationValue * 2 * pi) * 12),
      Offset(size.width * 0.85, size.height * 0.18 + cos(animationValue * 2 * pi) * 10),
      Offset(size.width * 0.22, size.height * 0.75 + sin(animationValue * 2 * pi + 1) * 14),
      Offset(size.width * 0.78, size.height * 0.82 + cos(animationValue * 2 * pi + 2) * 12),
    ];

    for (int i = 0; i < bubblePositions.length; i++) {
      final pos = bubblePositions[i];
      paint.color = (i.isEven ? const Color(0xFFFF4081) : const Color(0xFF00E676)).withOpacity(0.07);
      canvas.drawCircle(pos, 28 + (i * 4).toDouble(), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CandyBgPainter oldDelegate) => true;
}
