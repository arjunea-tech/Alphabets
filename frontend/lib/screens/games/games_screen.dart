import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/car_racing_game_model.dart';
import '../../models/letter_basket_game_model.dart';
import '../../models/letter_fishing_game_model.dart';
import '../../models/game_item_model.dart';
import '../../services/progress_service.dart';
import '../../services/data_service.dart';
import '../../services/api_config.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/kid_scaffold_background.dart';
import '../../widgets/animated_game_card_art.dart';
import 'agaram_run_game.dart';
import 'car_racing_game.dart';
import 'letter_basket_game.dart';
import 'letter_candy_game.dart';
import 'letter_fishing_game.dart';
import 'word_puzzle_game.dart';
import 'balloon_pop_game.dart';
import 'flappy_word_game.dart';
import 'word_ninja_game.dart';

class GamesScreen extends StatefulWidget {
  final ProgressService progressService;

  const GamesScreen({super.key, required this.progressService});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> with SingleTickerProviderStateMixin {
  int _selectedCategoryIndex = 0; // 0: All, 1: New, 2: Vowels, 3: Consonants
  late final AnimationController _floatAnimationController;

  final List<String> _categories = const ['All', 'New', 'Vowels', 'Consonants'];
  List<GameItem> _games = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _floatAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
    _loadGames();
  }

  Future<void> _loadGames() async {
    try {
      final games = await DataService.instance.getActiveGames();
      if (mounted) {
        setState(() {
          _games = games.where((g) => g.isActive).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _floatAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.progressService,
      builder: (context, _) {
        final stars = widget.progressService.stars;
        final gamesPlayed = widget.progressService.progress.gamesPlayed;

        return Scaffold(
          backgroundColor: const Color(0xFFFAF8F5),
          body: KidScaffoldBackground(
            child: SafeArea(
              bottom: false,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: RefreshIndicator(
                    onRefresh: () async {
                      DataService.instance.clearGamesCache();
                      await _loadGames();
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      children: [
                        // 1. Top Profile & Game Stats Header Bar
                        _buildTopHeader(gamesPlayed, stars),
                        const SizedBox(height: 16),

                        // 2. Category Filter Pills Row (All, New, Vowels, Consonants)
                        _buildCategoryFilters(),
                        const SizedBox(height: 18),

                        // 3. Dynamic Grid of Games Configured & Enabled in Superadmin
                        if (_isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else
                          _buildGamesGrid(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Top Profile & Game Stats Header
  Widget _buildTopHeader(int gamesPlayed, int stars) {
    return Row(
      children: [
        // Kid Avatar Image
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFFD166), width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/welcome.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFFFFF3CD),
                child: const Icon(Icons.face_rounded, color: Color(0xFFFF9F1C), size: 30),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Title and Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Games Arena',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Play & Learn 26 Alphabets',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey.shade600,
                ),
              ),
            ],
          ),
        ),

        // Games Played Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE9FE),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDDD6FE)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sports_esports_rounded, size: 16, color: Color(0xFF7C3AED)),
              const SizedBox(width: 5),
              Text(
                '$gamesPlayed',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF5B21B6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Star Count Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, size: 16, color: Color(0xFFD97706)),
              const SizedBox(width: 4),
              Text(
                '$stars',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF92400E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Category Filter Pills Row (All, New, Vowels, Consonants)
  Widget _buildCategoryFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(_categories.length, (index) {
          final isSelected = _selectedCategoryIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: BouncyButton(
              onPressed: () {
                setState(() => _selectedCategoryIndex = index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1E1E2D) : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF1E1E2D) : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? Colors.black.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.03),
                      blurRadius: isSelected ? 8 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _categories[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// 2-Column Responsive Grid of Active Educational Games
  Widget _buildGamesGrid(BuildContext context) {
    final filteredGames = _games.where((g) {
      if (_selectedCategoryIndex == 0) return true; // All
      if (_selectedCategoryIndex == 1) {
        // New Games
        return g.gameType == 'balloon' ||
            g.gameType == 'flappy' ||
            g.gameType == 'ninja' ||
            g.gameType == 'runner' ||
            g.gameType == 'candy';
      }
      if (_selectedCategoryIndex == 2) {
        // Vowels
        final title = g.title.toLowerCase();
        final prompt = g.prompt.toLowerCase();
        return title.contains('vowel') ||
            prompt.contains('vowel') ||
            g.gameType == 'racing' ||
            g.gameType == 'balloon' ||
            g.gameType == 'flappy';
      }
      if (_selectedCategoryIndex == 3) {
        // Consonants
        final title = g.title.toLowerCase();
        final prompt = g.prompt.toLowerCase();
        return title.contains('consonant') ||
            prompt.contains('consonant') ||
            g.gameType == 'ninja' ||
            g.gameType == 'candy' ||
            g.gameType == 'runner' ||
            g.id == 'game_basket_2';
      }
      return true;
    }).toList();

    if (filteredGames.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.sports_esports_outlined, size: 54, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No active games in this category',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 14,
          children: filteredGames.asMap().entries.map((entry) {
            final idx = entry.key;
            final game = entry.value;

            return AnimatedBuilder(
              animation: _floatAnimationController,
              builder: (context, _) {
                final double phase = idx * 1.05;
                final double floatY = math.sin((_floatAnimationController.value * 2 * math.pi) + phase) * 3.5;
                final double scale = 1.0 + math.cos((_floatAnimationController.value * 2 * math.pi) + phase) * 0.012;

                return Transform.translate(
                  offset: Offset(0, floatY),
                  child: Transform.scale(
                    scale: scale,
                    child: SizedBox(
                      width: itemWidth,
                      height: 155,
                      child: _buildGameCardFor(context, game, _floatAnimationController.value),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildGameCardFor(BuildContext context, GameItem game, double animTime) {
    if (game.gameType == 'runner') {
      return _buildHeroRunnerGameCard(
        context,
        title: game.title,
        coverAsset: _resolveCoverAsset(game),
        animTime: animTime,
        onTap: () => _launchGame(context, game),
      );
    }

    return _buildStandardGameCard(
      context,
      title: game.title,
      coverAsset: _resolveCoverAsset(game),
      badgeIcon: _badgeIconFor(game.gameType),
      gameType: game.gameType,
      animTime: animTime,
      onTap: () => _launchGame(context, game),
    );
  }

  String _resolveCoverAsset(GameItem game) {
    // welcome.png is the seeded placeholder, not a real cover, so skip it and
    // use the per-game cover below. Covers set from the admin panel still win.
    final clueImage = game.clueImage?.trim() ?? '';
    if (clueImage.isNotEmpty && !clueImage.endsWith('/welcome.png')) {
      return clueImage;
    }

    switch (game.gameType) {
      case 'balloon':
        return 'assets/images/games/balloon_pop_cover.png';
      case 'flappy':
        return 'assets/images/games/flappy_word_cover.png';
      case 'ninja':
        return 'assets/images/games/word_ninja_cover.png';
      case 'candy':
        return 'assets/images/games/candy_match_cover.png';
      case 'runner':
        return 'assets/images/games/runner_cover.png';
      case 'racing':
        return 'assets/images/games/car_racing_cover.png';
      case 'fishing':
        return 'assets/images/games/fishing_cover.png';
      case 'basket':
        if (game.title.toLowerCase().contains('consonant') || game.id.contains('2')) {
          return 'assets/images/games/basket_consonants_cover.png';
        }
        return 'assets/images/games/basket_vowels_cover.png';
      case 'puzzle':
      default:
        return 'assets/images/welcome.png';
    }
  }

  IconData _badgeIconFor(String gameType) {
    switch (gameType) {
      case 'balloon':
        return Icons.bubble_chart_rounded;
      case 'flappy':
        return Icons.flight_rounded;
      case 'ninja':
        return Icons.sports_kabaddi_rounded;
      case 'candy':
        return Icons.grid_view_rounded;
      case 'runner':
        return Icons.directions_run_rounded;
      case 'racing':
        return Icons.directions_car_filled_rounded;
      case 'fishing':
        return Icons.waves_rounded;
      case 'basket':
        return Icons.shopping_basket_rounded;
      case 'puzzle':
      default:
        return Icons.extension_rounded;
    }
  }

  void _launchGame(BuildContext context, GameItem game) {
    Widget targetScreen;

    switch (game.gameType) {
      case 'balloon':
        targetScreen = BalloonPopGame(progressService: widget.progressService);
        break;
      case 'flappy':
        targetScreen = FlappyWordGame(progressService: widget.progressService);
        break;
      case 'ninja':
        targetScreen = WordNinjaGame(progressService: widget.progressService);
        break;
      case 'runner':
        targetScreen = AgaramRunGame(progressService: widget.progressService);
        break;
      case 'candy':
        targetScreen = TamilLetterCandyGame(progressService: widget.progressService);
        break;
      case 'racing':
        targetScreen = CarRacingGame(
          progressService: widget.progressService,
          mode: RacingGameMode.uyir,
        );
        break;
      case 'fishing':
        targetScreen = LetterFishingGame(
          progressService: widget.progressService,
          mode: FishingGameMode.uyir,
        );
        break;
      case 'basket':
        final isMei = game.title.toLowerCase().contains('consonant') || game.id.contains('2');
        targetScreen = LetterBasketGame(
          progressService: widget.progressService,
          mode: isMei ? BasketGameMode.mei : BasketGameMode.uyir,
        );
        break;
      case 'puzzle':
      default:
        targetScreen = WordPuzzleGame(progressService: widget.progressService);
        break;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetScreen),
    );
  }

  /// Standard Cover-Image Game Card
  Widget _buildStandardGameCard(
    BuildContext context, {
    required String title,
    required String coverAsset,
    required IconData badgeIcon,
    required String gameType,
    required double animTime,
    required VoidCallback onTap,
  }) {
    return BouncyButton(
      onPressed: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Background Cover Image
              _buildCoverImage(coverAsset, badgeIcon),

              // 2. Animated Living Action Canvas (Moving car, flappy bird, slicing ninja, balloons, etc.)
              AnimatedGameCardArt(
                gameType: gameType,
                time: animTime,
              ),

              // 3. Bottom Dark Scrim Gradient for Crisp Title Readability
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.20),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                      stops: const [0.40, 0.68, 1.0],
                    ),
                  ),
                ),
              ),

              // Top-Left Circular Translucent Badge Icon
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.50),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.2),
                  ),
                  child: Icon(badgeIcon, color: Colors.white, size: 18),
                ),
              ),

              // Bottom Title Pill / Text
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                      shadows: [
                        Shadow(color: Colors.black, blurRadius: 4),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Featured Hero Runner Game Card (Jungle Runner with Play Now Pill)
  Widget _buildHeroRunnerGameCard(
    BuildContext context, {
    required String title,
    required String coverAsset,
    required double animTime,
    required VoidCallback onTap,
  }) {
    return BouncyButton(
      onPressed: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Background Cover Image
              _buildCoverImage(coverAsset, Icons.directions_run_rounded),

              // 2. Animated Runner Action Canvas
              AnimatedGameCardArt(
                gameType: 'runner',
                time: animTime,
              ),

              // 3. Soft Gradient Overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.15),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.70),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),

              // Top Title Badge Pill
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.directions_run_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Center / Bottom Play Now Pill Button
              Positioned(
                bottom: 12,
                left: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded, color: Color(0xFF16A34A), size: 18),
                      SizedBox(width: 4),
                      Text(
                        'Play Now',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImage(String coverAsset, IconData fallbackIcon) {
    if (coverAsset.startsWith('http://') || coverAsset.startsWith('https://')) {
      return Image.network(
        coverAsset,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackCover(fallbackIcon),
      );
    }

    final resolvedUrl = ApiConfig.resolveMediaUrl(coverAsset);
    if (resolvedUrl != null && (resolvedUrl.startsWith('http://') || resolvedUrl.startsWith('https://'))) {
      return Image.network(
        resolvedUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          coverAsset,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackCover(fallbackIcon),
        ),
      );
    }

    return Image.asset(
      coverAsset,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildFallbackCover(fallbackIcon),
    );
  }

  Widget _buildFallbackCover(IconData icon) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8338EC), Color(0xFF3A86FF)],
        ),
      ),
      child: Center(
        child: Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 48),
      ),
    );
  }
}
