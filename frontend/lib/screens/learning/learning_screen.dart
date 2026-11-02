import 'package:flutter/material.dart';
import '../../services/language_service.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/kid_app_bar.dart';
import '../../widgets/kid_scaffold_background.dart';
import '../../widgets/mascot_widget.dart';
import 'aytham_screen.dart';
import 'mei_screen.dart';
import '../reading/reading_screen.dart';
import 'uyir_screen.dart';

class LearningScreen extends StatelessWidget {
  final ProgressService progressService;

  const LearningScreen({super.key, required this.progressService});

  void _navigateToCategory(BuildContext context, String routeName) {
    Widget target;
    switch (routeName) {
      case '/aytham':
        target = AythamScreen(progressService: progressService);
        break;
      case '/uyir':
        target = UyirScreen(progressService: progressService);
        break;
      case '/mei':
        target = MeiScreen(progressService: progressService);
        break;
      case '/reading':
        target = ReadingScreen(progressService: progressService);
        break;
      default:
        target = AythamScreen(progressService: progressService);
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) => target));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: progressService,
      builder: (context, _) {
        final completedCount = progressService.completedLettersCount;

        return Scaffold(
          appBar: KidAppBar(
            title: 'Learn Alphabets',
            starCount: progressService.stars,
            showBack: false,
          ),
          body: KidScaffoldBackground(
            child: SafeArea(
              bottom: false,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
                    children: [
                      // Top Hero Mascot Card (learn.png - child reading book)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFF81C784), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.mintGreen.withValues(alpha: 0.2),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.school_rounded, color: Color(0xFF2E7D32), size: 14),
                                        SizedBox(width: 4),
                                        Text(
                                          'Alphabet Academy',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2E7D32),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Learn 26 English Alphabets!',
                                    style: AppTextStyles.cardTitle.copyWith(
                                      fontSize: 18,
                                      color: const Color(0xFF1B5E20),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Completed letters: $completedCount / 26',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF388E3C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const MascotWidget(
                              pose: MascotPose.learn,
                              size: MascotSize.small,
                              customHeight: 110,
                              showGlow: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 1. All 26 Alphabets (A - Z)
                      _buildCategoryCard(
                        context,
                        title: 'All Alphabets (A to Z)',
                        subtitle: 'Explore the complete 26 English alphabet letters',
                        badge: '26 Letters',
                        letterBadge: 'A-Z',
                        progressFraction: (completedCount / 26).clamp(0.0, 1.0),
                        gradient: AppColors.purpleGradient,
                        onTap: () => _navigateToCategory(context, '/aytham'),
                      ),
                      const SizedBox(height: 16),

                      // 2. Vowels Category (5 Vowels)
                      _buildCategoryCard(
                        context,
                        title: 'Vowels (A, E, I, O, U)',
                        subtitle: 'Master the 5 essential English vowel sounds',
                        badge: '5 Vowels',
                        letterBadge: 'A',
                        progressFraction: (completedCount / 5).clamp(0.0, 1.0),
                        gradient: AppColors.pinkGradient,
                        onTap: () => _navigateToCategory(context, '/uyir'),
                      ),
                      const SizedBox(height: 16),

                      // 3. Consonants Category (21 Consonants)
                      _buildCategoryCard(
                        context,
                        title: 'Consonants (21 Letters)',
                        subtitle: 'Practice 21 English consonants from B to Z',
                        badge: '21 Consonants',
                        letterBadge: 'B',
                        progressFraction: (completedCount / 21).clamp(0.0, 1.0),
                        gradient: AppColors.blueGradient,
                        onTap: () => _navigateToCategory(context, '/mei'),
                      ),
                      const SizedBox(height: 16),

                      // 4. Stories / Reading
                      _buildCategoryCard(
                        context,
                        title: 'Reading Stories',
                        subtitle: 'The Hare and The Tortoise & fable stories',
                        badge: 'Storybooks',
                        icon: Icons.auto_stories_rounded,
                        progressFraction: progressService.completedStoriesCount > 0 ? 1.0 : 0.0,
                        gradient: AppColors.orangeGradient,
                        onTap: () => _navigateToCategory(context, '/reading'),
                      ),
                      const SizedBox(height: 20),
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

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String badge,
    String? letterBadge,
    IconData? icon,
    required double progressFraction,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return BouncyButton(
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: gradient.first.withValues(alpha: 0.35), width: 2.2),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Icon / Letter box
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.first.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: letterBadge != null
                      ? Text(
                          letterBadge,
                          style: TextStyle(
                            fontSize: letterBadge.length > 2 ? 18 : 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        )
                      : Icon(icon ?? Icons.star_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),

                // Title, Subtitle & Badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.cardTitle.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: AppTextStyles.cardSubtitle.copyWith(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: gradient.first.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: gradient.first,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 18),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progressFraction,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF0F0F2),
                      valueColor: AlwaysStoppedAnimation<Color>(gradient.first),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(progressFraction * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: gradient.first,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
