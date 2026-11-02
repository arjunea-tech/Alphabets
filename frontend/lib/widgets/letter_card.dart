import 'package:flutter/material.dart';
import '../models/letter_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'audio_button.dart';
import 'bouncy_button.dart';
import 'letter_media_image.dart';

class LetterCard extends StatelessWidget {
  final LetterModel letter;
  final VoidCallback onTap;
  final Color? accentColor;
  final bool isCompleted;

  const LetterCard({
    super.key,
    required this.letter,
    required this.onTap,
    this.accentColor,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;

    return BouncyButton(
      onPressed: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: color.withValues(alpha: 0.35),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Top indicator circle accent
            Positioned(
              top: -15,
              right: -15,
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Completed star badge
            if (isCompleted)
              const Positioned(
                top: 8,
                left: 8,
                child: Icon(Icons.star_rounded, color: AppColors.starGold, size: 18),
              ),

            // Audio Speaker Button on Top Right (Does not navigate away)
            Positioned(
              top: 6,
              right: 6,
              child: AudioButton(
                letter: letter.letter,
                word: letter.word,
                audioPath: letter.audioPath,
                size: 32,
                color: color.withValues(alpha: 0.15),
                iconColor: color,
              ),
            ),

            // Main Card Content: [ Image ] on top, and underneath ONLY the Tamil Letter [  ]
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Illustration / Image
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: LetterMediaImage(
                          imagePath: letter.imagePath,
                          iconEmoji: letter.iconEmoji,
                          fit: BoxFit.contain,
                          emojiSize: 36,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // 2. ONLY the Tamil letter underneath the image (NO Tanglish/English)
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          letter.letter,
                          style: AppTextStyles.tamilLetterLarge.copyWith(
                            color: color,
                            fontSize: letter.letter.length > 2 ? 26 : 38,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
