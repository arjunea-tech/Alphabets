import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class LetterNavigator extends StatelessWidget {
  final String currentLetter;
  final int currentIndex;
  final int totalCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const LetterNavigator({
    super.key,
    required this.currentLetter,
    required this.currentIndex,
    required this.totalCount,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final hasPrev = currentIndex > 0;
    final hasNext = currentIndex < totalCount - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD166), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous button
          _buildNavButton(
            icon: Icons.arrow_back_rounded,
            enabled: hasPrev,
            onTap: onPrevious,
            tooltip: 'Previous letter',
          ),
          const SizedBox(width: 14),

          // Central badge
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentLetter,
                style: AppTextStyles.tamilLetterLarge.copyWith(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${currentIndex + 1} / $totalCount',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6C757D),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Next button
          _buildNavButton(
            icon: Icons.arrow_forward_rounded,
            enabled: hasNext,
            onTap: onNext,
            tooltip: 'Next letter',
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback? onTap,
    required String tooltip,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: enabled ? AppColors.secondary : const Color(0xFFE9ECEF),
            shape: BoxShape.circle,
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Icon(
              icon,
              color: enabled ? Colors.white : const Color(0xFFADB5BD),
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
