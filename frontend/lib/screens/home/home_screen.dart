import 'package:flutter/material.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/gentle_bob.dart';
import '../../widgets/kid_scaffold_background.dart';
import '../../widgets/mascot_widget.dart';
import '../../widgets/star_counter.dart';
import '../settings/settings_screen.dart';
import '../writing/writing_practice_screen.dart';

class HomeScreen extends StatelessWidget {
  final ProgressService progressService;
  final Function(int) onTabSelect;

  const HomeScreen({
    super.key,
    required this.progressService,
    required this.onTabSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: progressService,
      builder: (context, _) {
        final childName = ProgressService.toEnglishName(progressService.childName);
        final stars = progressService.stars;
        final completedLetters = progressService.completedLettersCount;
        final quizScore = progressService.quizHighScore;

        return Scaffold(
          body: KidScaffoldBackground(
            child: SafeArea(
              bottom: false,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Clean Kid-Friendly Header: Child Profile Pill & Star Counter & Settings
                        _buildTopHeader(context, childName, stars),
                        const SizedBox(height: 16),

                        // Hero Welcome Banner with Cheerful Mascot & Start Button
                        _buildMascotHeroCard(context, childName),
                        const SizedBox(height: 24),

                        // Section Header: Learning Worlds
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9F1C).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: Color(0xFFFF9F1C),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Learning Worlds',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E293B),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap any world below to start learning & playing! ✨',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Destination 1: Learn Alphabets (A - Z)
                        _buildKidWorldCard(
                          title: 'Learn Alphabets',
                          subtitle: 'Explore all 26 letters A to Z with fun phonics!',
                          buttonLabel: "LET'S LEARN",
                          imageAsset: 'assets/images/learn.png',
                          gradient: const [Color(0xFFFF8A00), Color(0xFFFF5252)],
                          accentColor: const Color(0xFFE65100),
                          onTap: () => onTabSelect(1),
                        ),

                        // Destination 2: Play & Learn (Fun Mini Games)
                        _buildKidWorldCard(
                          title: 'Play & Learn',
                          subtitle: 'Exciting racing, balloon popping & word ninja!',
                          buttonLabel: 'PLAY GAMES',
                          imageAsset: 'assets/images/game.png',
                          gradient: const [Color(0xFF8338EC), Color(0xFF3A86FF)],
                          accentColor: const Color(0xFF6A00F4),
                          onTap: () => onTabSelect(2),
                        ),

                        // Destination 3: Writing Practice (Letter Tracing)
                        _buildKidWorldCard(
                          title: 'Writing Practice',
                          subtitle: 'Trace letters A to Z with magic finger guide!',
                          buttonLabel: 'START WRITING',
                          imageAsset: 'assets/images/writing.png',
                          gradient: const [Color(0xFFFF006E), Color(0xFFFF5252)],
                          accentColor: const Color(0xFFD90429),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => WritingPracticeScreen(
                                  progressService: progressService,
                                ),
                              ),
                            );
                          },
                        ),

                        // Destination 4: Educational Videos (Songs & Rhymes)
                        _buildKidWorldCard(
                          title: 'Educational Videos',
                          subtitle: 'Watch and sing along with ABC phonics songs!',
                          buttonLabel: 'WATCH VIDEOS',
                          imageAsset: 'assets/images/video.png',
                          gradient: const [Color(0xFF00B4D8), Color(0xFF06D6A0)],
                          accentColor: const Color(0xFF00897B),
                          onTap: () => onTabSelect(3),
                        ),

                        // Destination 5: Alphabet Quizzes (Star Challenges)
                        _buildKidWorldCard(
                          title: 'Alphabet Quizzes',
                          subtitle: 'Show how smart you are and collect golden stars!',
                          buttonLabel: 'START QUIZ',
                          imageAsset: 'assets/images/quiz.png',
                          gradient: const [Color(0xFF4361EE), Color(0xFF7209B7)],
                          accentColor: const Color(0xFF3F51B5),
                          onTap: () => onTabSelect(4),
                        ),

                        const SizedBox(height: 10),

                        // Super Star Progress Arcade Section
                        _buildProgressSection(childName, completedLetters, stars, quizScore),
                        const SizedBox(height: 24),
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

  /// Clean kid-friendly top bar without the circled orange pill and language tag
  Widget _buildTopHeader(BuildContext context, String childName, int stars) {
    return Row(
      children: [
        // Kid Profile Pill Button (tapping opens Settings, which holds the profile)
        BouncyButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SettingsScreen(progressService: progressService),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFF9F1C), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF9F1C).withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: const Color(0xFFFFF3CD),
                  backgroundImage: AssetImage(progressService.avatarAsset),
                ),
                const SizedBox(width: 8),
                Text(
                  'Hi, $childName! ⭐',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),

        // Star Counter
        StarCounter(count: stars),
        const SizedBox(width: 8),

        // Settings Button
        BouncyButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SettingsScreen(progressService: progressService),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderLight, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.settings_rounded, color: AppColors.textDark, size: 20),
          ),
        ),
      ],
    );
  }

  /// Bubbly Hero Card with Mascot and English Greeting
  Widget _buildMascotHeroCard(BuildContext context, String childName) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFF8E7),
            Color(0xFFFFE8B2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFFFD166), width: 2.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9F1C).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background floating playful bubble accents
          Positioned(
            right: 80,
            top: 10,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 8,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD166).withValues(alpha: 0.35),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 126, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Speech Pill in English
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('👋', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 5),
                      Text(
                        'Hello $childName!',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Let's Learn & Play ABC!",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2D1500),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '26 Letters • Fun Games • Songs! 🎈',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7A4400),
                  ),
                ),
                const SizedBox(height: 12),

                // Playful Start Button
                BouncyButton(
                  onPressed: () => onTabSelect(1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9F1C), Color(0xFFFF5252)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF5252).withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 4),
                        Text(
                          'START LEARNING',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Mascot Character
          const Positioned(
            right: 8,
            bottom: -6,
            child: MascotWidget(
              pose: MascotPose.welcome,
              size: MascotSize.medium,
              customHeight: 145,
              showGlow: true,
              animate: true,
            ),
          ),
        ],
      ),
    );
  }

  /// Big, vibrant, kid-friendly destination card
  Widget _buildKidWorldCard({
    required String title,
    required String subtitle,
    required String buttonLabel,
    required String imageAsset,
    required List<Color> gradient,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return BouncyButton(
      onPressed: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 2.5),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.15),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Stack(
            children: [
              // Subtle corner gradient glow
              Positioned(
                right: -25,
                top: -25,
                width: 130,
                height: 130,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        gradient[0].withValues(alpha: 0.18),
                        gradient[1].withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Big Visual Icon on Playful Pedestal
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            gradient[0].withValues(alpha: 0.12),
                            gradient[1].withValues(alpha: 0.24),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: gradient[0].withValues(alpha: 0.35),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: gradient[0].withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      // Light looping motion so the character feels alive (like a GIF)
                      child: GentleBob(
                        // Different start point per card so they don't all move together
                        phase: (imageAsset.hashCode % 100) / 100,
                        child: Image.asset(
                          imageAsset,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.stars_rounded,
                            size: 38,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Card Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 2),

                          // Subtitle
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),

                          // Kid Action Button
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: gradient),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: gradient[0].withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  buttonLabel,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 13,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Gamified Super Star Progress Arcade Section
  Widget _buildProgressSection(String childName, int lettersCount, int stars, int quizScore) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFFFD166), width: 2.6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD166).withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.military_tech_rounded, color: Color(0xFFFF9F1C), size: 24),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Super Star Progress",
                    style: TextStyle(
                      fontSize: 17.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    "Keep learning to earn more stars!",
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildProgressPod(
                  label: 'Letters Done',
                  value: '$lettersCount / 26',
                  icon: Icons.auto_stories_rounded,
                  color: const Color(0xFFFF6B6B),
                  bgColor: const Color(0xFFFFEEEE),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildProgressPod(
                  label: 'Total Stars',
                  value: '$stars',
                  icon: Icons.star_rounded,
                  color: const Color(0xFFFFB703),
                  bgColor: const Color(0xFFFFF8E7),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildProgressPod(
                  label: 'Best Quiz',
                  value: '$quizScore%',
                  icon: Icons.emoji_events_rounded,
                  color: const Color(0xFF8338EC),
                  bgColor: const Color(0xFFF3E8FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFE5B4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    "Awesome job, $childName! You are a superstar! 🚀",
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB45309),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressPod({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
