import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'bouncy_button.dart';

class CustomAudioButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool isSecondary;

  const CustomAudioButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color,
    this.isSecondary = false,
  });

  @override
  State<CustomAudioButton> createState() => _CustomAudioButtonState();
}

class _CustomAudioButtonState extends State<CustomAudioButton> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _waveController.forward(from: 0.0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.color ?? AppColors.secondary;

    return BouncyButton(
      onPressed: _handleTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.isSecondary ? Colors.white : activeColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: activeColor,
            width: 2.2,
          ),
          boxShadow: [
            BoxShadow(
              color: activeColor.withValues(alpha: widget.isSecondary ? 0.15 : 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.volume_up_rounded,
                color: widget.isSecondary ? activeColor : Colors.white,
                size: 22,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: AppTextStyles.buttonText.copyWith(
                  color: widget.isSecondary ? activeColor : Colors.white,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
