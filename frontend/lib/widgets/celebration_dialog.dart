import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'bouncy_button.dart';
import 'mascot_widget.dart';

class CelebrationDialog extends StatefulWidget {
  final String title;
  final String message;
  final int starsEarned;
  final String buttonText;
  final VoidCallback onContinue;

  const CelebrationDialog({
    super.key,
    this.title = 'வாழ்த்துகள்!',
    this.message = 'மிக அருமையாக முடித்துவிட்டாய்!',
    this.starsEarned = 3,
    this.buttonText = 'தொடரலாம்',
    required this.onContinue,
  });

  static Future<void> show(
    BuildContext context, {
    String title = 'வாழ்த்துகள்!',
    String message = 'மிக அருமையாக முடித்துவிட்டாய்!',
    int starsEarned = 3,
    String buttonText = 'தொடரலாம்',
    required VoidCallback onContinue,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CelebrationDialog(
        title: title,
        message: message,
        starsEarned: starsEarned,
        buttonText: buttonText,
        onContinue: onContinue,
      ),
    );
  }

  @override
  State<CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<CelebrationDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: AppColors.starGold, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mascot celebrating with stars
                const MascotWidget(
                  pose: MascotPose.welcome,
                  size: MascotSize.small,
                  customHeight: 110,
                  showGlow: true,
                  animate: true,
                ),
                const SizedBox(height: 12),

                // Star Burst Row (Vector Icons)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.starsEarned.clamp(1, 5),
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Icon(
                        Icons.star_rounded,
                        color: AppColors.starGold,
                        size: index == 1 ? 38 : 30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.title,
                  style: AppTextStyles.screenTitle.copyWith(
                    color: AppColors.primaryDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.message,
                  style: AppTextStyles.bodyText.copyWith(
                    color: AppColors.textDark,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars_rounded, color: AppColors.primaryDark, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '+${widget.starsEarned} நட்சத்திரங்கள்!',
                        style: AppTextStyles.cardTitle.copyWith(
                          fontSize: 14,
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                BouncyButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onContinue();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.orangeGradient,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.buttonText,
                      style: AppTextStyles.buttonText,
                      textAlign: TextAlign.center,
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
}
