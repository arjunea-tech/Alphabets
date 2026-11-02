import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class KidScaffoldBackground extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;

  const KidScaffoldBackground({
    super.key,
    required this.child,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.background,
      ),
      child: Stack(
        children: [
          // Soft decorative background bubbles and Tamil letter glyphs
          Positioned(
            top: -40,
            right: -30,
            child: _buildBubble(140, const Color(0xFFFFD166).withValues(alpha: 0.15)),
          ),
          Positioned(
            top: 180,
            left: -50,
            child: _buildBubble(160, const Color(0xFF4CC9F0).withValues(alpha: 0.12)),
          ),
          Positioned(
            bottom: 120,
            right: -40,
            child: _buildBubble(180, const Color(0xFFFF6B6B).withValues(alpha: 0.10)),
          ),
          Positioned(
            bottom: -60,
            left: -30,
            child: _buildBubble(150, const Color(0xFF06D6A0).withValues(alpha: 0.12)),
          ),

          // Faint decorative Tamil letters floating in background
          Positioned(
            top: 70,
            left: 24,
            child: _buildFaintLetter('A'),
          ),
          Positioned(
            top: 280,
            right: 20,
            child: _buildFaintLetter('B'),
          ),
          Positioned(
            bottom: 220,
            left: 30,
            child: _buildFaintLetter('C'),
          ),
          Positioned(
            bottom: 60,
            right: 36,
            child: _buildFaintLetter('D'),
          ),

          // Main child content
          child,
        ],
      ),
    );
  }

  Widget _buildBubble(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildFaintLetter(String text) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.08,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: Color(0xFF2B2D42),
          ),
        ),
      ),
    );
  }
}
