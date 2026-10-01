import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'star_counter.dart';

class KidAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final int? starCount;
  final VoidCallback? onBackTap;
  final bool showBack;
  final List<Widget>? actions;

  const KidAppBar({
    super.key,
    required this.title,
    this.starCount,
    this.onBackTap,
    this.showBack = true,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(66);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            if (showBack && Navigator.canPop(context))
              GestureDetector(
                onTap: onBackTap ?? () => Navigator.of(context).pop(),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: AppColors.borderLight, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textDark,
                    size: 24,
                  ),
                ),
              )
            else
              const SizedBox(width: 42),
            const SizedBox(width: 8),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  title,
                  style: AppTextStyles.screenTitle.copyWith(
                    fontSize: 20,
                  ),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (actions != null)
              ...actions!
            else if (starCount != null)
              StarCounter(count: starCount!)
            else
              const SizedBox(width: 42),
          ],
        ),
      ),
    );
  }
}
