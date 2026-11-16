import 'package:flutter/material.dart';
import '../models/game_content.dart';
import 'bouncy_button.dart';

/// Result a game pops with when the child taps "Next Level"; the games screen
/// then opens the following level straight away.
const String nextLevelResult = 'next_level';

/// Big green "Next Level ▶" button for a game's win screen. Shows nothing when
/// the game isn't playing a picked level or the level is the last one, so it
/// can be dropped into any victory screen unconditionally.
class NextLevelButton extends StatelessWidget {
  final GameContent? content;

  /// Stretch to the available width (for column layouts).
  final bool expand;

  const NextLevelButton({super.key, required this.content, this.expand = true});

  @override
  Widget build(BuildContext context) {
    final c = content;
    if (c == null || !c.hasNextLevel) return const SizedBox.shrink();
    final next = c.levelIndex! + 2;

    final button = BouncyButton(
      onPressed: () => Navigator.pop(context, nextLevelResult),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF15803D)]),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF16A34A).withValues(alpha: 0.45),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Next: Level $next',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}
