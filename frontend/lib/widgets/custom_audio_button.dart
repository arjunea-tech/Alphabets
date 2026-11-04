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
    return const SizedBox.shrink();
  }
}
