import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/kid_scaffold_background.dart';
import '../../widgets/mascot_widget.dart';

class QuizResultScreen extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final int starsEarned;
  final VoidCallback onRetry;
  final VoidCallback onHome;

  const QuizResultScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.starsEarned,
    required this.onRetry,
    required this.onHome,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final percentage = (widget.score / widget.totalQuestions);
      if (percentage >= 0.5) {
        AudioService.instance.playSuccessFeedback(context);
        // Great celebration
      } else {
        AudioService.instance.playRetryFeedback(context);
        // Good effort
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final score = widget.score;
    final totalQuestions = widget.totalQuestions;
    final starsEarned = widget.starsEarned;
    final percentage = (score / totalQuestions);
    final isAwesome = percentage >= 0.75;

    return Scaffold(
      body: KidScaffoldBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Celebrating AGARAM Mascot
                    MascotWidget(
                      pose: isAwesome ? MascotPose.game : MascotPose.welcome,
                      size: MascotSize.medium,
                      customHeight: 150,
                      showGlow: true,
                      speechText: isAwesome ? 'Awesome! Great job!' : 'Good effort! Keep practicing!',
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      isAwesome ? 'Congratulations!' : 'Good effort! Try again!',
                      style: AppTextStyles.brandTitle.copyWith(
                        color: AppColors.primaryDark,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your Score',
                      style: AppTextStyles.cardSubtitle.copyWith(
                        fontSize: 15,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Big Score Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.primary, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text(
                        '$score / $totalQuestions',
                        style: AppTextStyles.tamilLetterLarge.copyWith(
                          fontSize: 44,
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stars rating row (Vector Icons)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        starsEarned.clamp(1, 5),
                        (index) => const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.star_rounded, color: AppColors.starGold, size: 36),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '+$starsEarned Stars Earned!',
                      style: AppTextStyles.bodyTextBold.copyWith(
                        color: AppColors.textDark,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Retry Button
                    BouncyButton(
                      onPressed: widget.onRetry,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: AppColors.orangeGradient),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.replay_rounded, color: Colors.white, size: 22),
                            const SizedBox(width: 8),
                            Text('Play Again', style: AppTextStyles.buttonText),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Home Button
                    BouncyButton(
                      onPressed: widget.onHome,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.borderLight, width: 2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.home_rounded, color: AppColors.textDark, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Back to Home',
                              style: AppTextStyles.buttonText.copyWith(color: AppColors.textDark),
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
          ),
        ),
      ),
    );
  }
}
