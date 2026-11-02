import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/car_racing_game_model.dart';
import '../../models/letter_basket_game_model.dart';
import '../../models/letter_fishing_game_model.dart';
import '../../services/progress_service.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/kid_scaffold_background.dart';
import 'agaram_run_game.dart';
import 'car_racing_game.dart';
import 'letter_basket_game.dart';
import 'letter_candy_game.dart';
import 'letter_fishing_game.dart';

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

  @override
  void initState() {
    super.initState();
    _floatAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
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
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    children: [
                      // 1. Top Profile & Game Stats Header Bar
                      _buildTopHeader(gamesPlayed, stars),
                      const SizedBox(height: 16),

                      // 2. Category Filter Pills Row (All, New, Vowels, Consonants)
                      _buildCategoryFilters(),
                      const SizedBox(height: 18),

                      // 3. 2-Column Grid of Beautiful Game Cards with Rich Cover Art
                      _buildGamesGrid(context),
                    ],
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
              errorBuilder: (_, __, ___) => Container(
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
    // 0: All, 1: New, 2: Vowels, 3: Consonants
    final showCandy = _selectedCategoryIndex == 0 || _selectedCategoryIndex == 1 || _selectedCategoryIndex == 3;
    final showRunner = _selectedCategoryIndex == 0 || _selectedCategoryIndex == 1 || _selectedCategoryIndex == 3;
    final showRacing = _selectedCategoryIndex == 0 || _selectedCategoryIndex == 2;
    final showFishing = _selectedCategoryIndex == 0 || _selectedCategoryIndex == 2;
    final showBasketVowels = _selectedCategoryIndex == 0 || _selectedCategoryIndex == 2;
    final showBasketConsonants = _selectedCategoryIndex == 0 || _selectedCategoryIndex == 3;

    final cards = <Widget>[];

    // Card 1: Alphabet Candy Match
    if (showCandy) {
      cards.add(
        _buildStandardGameCard(
          context,
          title: 'Alphabet Candy',
          coverAsset: 'assets/images/games/candy_match_cover.png',
          badgeIcon: Icons.grid_view_rounded,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TamilLetterCandyGame(
                  progressService: widget.progressService,
                ),
              ),
            );
          },
        ),
      );
    }

    // Card 2: Alphabet Runner (Hero Card with runner boy & Play button)
    if (showRunner) {
      cards.add(
        _buildHeroRunnerGameCard(
          context,
          title: 'Alphabet Runner',
          coverAsset: 'assets/images/games/runner_cover.png',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AgaramRunGame(
                  progressService: widget.progressService,
                ),
              ),
            );
          },
        ),
      );
    }

    // Card 3: Alphabet Car Racing
    if (showRacing) {
      cards.add(
        _buildStandardGameCard(
          context,
          title: 'Car Racing (Vowels)',
          coverAsset: 'assets/images/games/car_racing_cover.png',
          badgeIcon: Icons.directions_car_filled_rounded,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CarRacingGame(
                  progressService: widget.progressService,
                  mode: RacingGameMode.uyir,
                ),
              ),
            );
          },
        ),
      );
    }

    // Card 4: Letter Fishing
    if (showFishing) {
      cards.add(
        _buildStandardGameCard(
          context,
          title: 'Letter Fishing',
          coverAsset: 'assets/images/games/fishing_cover.png',
          badgeIcon: Icons.waves_rounded,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LetterFishingGame(
                  progressService: widget.progressService,
                  mode: FishingGameMode.uyir,
                ),
              ),
            );
          },
        ),
      );
    }

    // Card 5: Letter Basket (Vowels)
    if (showBasketVowels) {
      cards.add(
        _buildStandardGameCard(
          context,
          title: 'Letter Basket (Vowels)',
          coverAsset: 'assets/images/games/basket_vowels_cover.png',
          badgeIcon: Icons.shopping_basket_rounded,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LetterBasketGame(
                  progressService: widget.progressService,
                  mode: BasketGameMode.uyir,
                ),
              ),
            );
          },
        ),
      );
    }

    // Card 6: Letter Basket (Consonants)
    if (showBasketConsonants) {
      cards.add(
        _buildStandardGameCard(
          context,
          title: 'Letter Basket (Consonants)',
          coverAsset: 'assets/images/games/basket_consonants_cover.png',
          badgeIcon: Icons.shopping_basket_rounded,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LetterBasketGame(
                  progressService: widget.progressService,
                  mode: BasketGameMode.mei,
                ),
              ),
            );
          },
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 14,
          children: cards.asMap().entries.map((entry) {
            final idx = entry.key;
            final card = entry.value;
            return AnimatedBuilder(
              animation: _floatAnimationController,
              builder: (context, _) {
                // Organic floating and breathing wave (like an animated GIF sticker!)
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
                      child: card,
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

  /// Standard Cover-Image Game Card
  Widget _buildStandardGameCard(
    BuildContext context, {
    required String title,
    required String coverAsset,
    required IconData badgeIcon,
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
              // Background Cover Image
              Image.asset(
                coverAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF8338EC), Color(0xFF3A86FF)],
                    ),
                  ),
                  child: Center(
                    child: Icon(badgeIcon, color: Colors.white.withValues(alpha: 0.6), size: 48),
                  ),
                ),
              ),

              // Bottom Dark Scrim Gradient for Crisp Title Readability
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.78),
                      ],
                      stops: const [0.45, 0.70, 1.0],
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
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.2),
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
                    color: Colors.black.withValues(alpha: 0.48),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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
              // Background Cover Image
              Image.asset(
                coverAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2EC4B6), Color(0xFF0F9F90)],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.directions_run_rounded, color: Colors.white, size: 48),
                  ),
                ),
              ),

              // Soft Gradient Overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.10),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.65),
                      ],
                      stops: const [0.0, 0.5, 1.0],
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
                    color: Colors.black.withValues(alpha: 0.50),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
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

}
