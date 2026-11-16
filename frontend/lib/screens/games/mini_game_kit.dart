import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/game_content.dart';
import '../../models/game_item_model.dart';
import '../../services/progress_service.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/next_level_button.dart';

/// Shared pieces for the Whack-a-Mole, Space Shooter and Letter Train games:
/// round building from admin levels, the top HUD and the win / game-over screen.

/// One question: find [target]; [wrong] are the choices to avoid.
class MiniRound {
  final GameLevel level;
  final String target;
  final List<String> wrong;

  const MiniRound({required this.level, required this.target, required this.wrong});
}

/// Rounds for a "find the target" game. A picked level gives exactly
/// [GameContent.questionsPerLevel] rounds; playing all levels together gives
/// up to [roundsPerLevel] rounds per level.
List<MiniRound> buildMiniRounds(GameContent content, math.Random rng, {int roundsPerLevel = 3}) {
  final rounds = <MiniRound>[];
  for (final level in content.levels) {
    final wrongPool = wrongChoicesFor(content, level);
    for (final target in content.roundsFrom(level.targets, rng, maxRounds: roundsPerLevel)) {
      rounds.add(MiniRound(
        level: level,
        target: target,
        wrong: wrongPool.where((w) => w.toUpperCase() != target.toUpperCase()).toList(),
      ));
    }
  }
  return rounds;
}

/// Wrong answers for [level], never empty: admin distractors, then other
/// admin content, then plain A–Z as a last resort.
List<String> wrongChoicesFor(GameContent content, GameLevel level) {
  final list = content.distractorsFor(level);
  if (list.isNotEmpty) return list;
  final targets = level.targets.map((t) => t.toUpperCase()).toSet();
  return [
    for (final c in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split(''))
      if (!targets.contains(c)) c,
  ];
}

/// Text shown above the game for the current level.
String promptFor(GameContent content, GameLevel level) =>
    level.prompt.trim().isNotEmpty ? level.prompt.trim() : content.game.prompt;

/// Saves a win: unlocks the next level and adds the game's stars.
void rewardMiniGameWin(ProgressService progress, GameContent content) {
  progress.completeActiveGameLevel();
  progress.recordGameCompleted(content.game.starsReward);
}

/// Top bar: back button, title, hearts (optional) and round progress.
class MiniGameHud extends StatelessWidget {
  final String title;
  final int done;
  final int total;
  final int? hearts;
  final Color color;

  const MiniGameHud({
    super.key,
    required this.title,
    required this.done,
    required this.total,
    required this.color,
    this.hearts,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: Row(
        children: [
          BouncyButton(
            onPressed: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)],
              ),
              child: Icon(Icons.arrow_back_rounded, color: color),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : done / total,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.35),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD166)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (hearts != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 18),
                  const SizedBox(width: 4),
                  Text('$hearts', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                ],
              ),
            ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$done / $total',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Big "find this" banner with the current target.
class MiniTargetBanner extends StatelessWidget {
  final String label;
  final String target;
  final String prompt;
  final Color color;

  const MiniTargetBanner({
    super.key,
    required this.label,
    required this.target,
    required this.prompt,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2.5),
      ),
      child: Row(
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 56),
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
            alignment: Alignment.center,
            child: Text(
              target,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
                Text(
                  prompt,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen win / game-over card with Next Level, Play Again and Back.
class MiniGameEndOverlay extends StatelessWidget {
  final bool won;
  final String message;
  final GameContent content;
  final VoidCallback onReplay;

  const MiniGameEndOverlay({
    super.key,
    required this.won,
    required this.message,
    required this.content,
    required this.onReplay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF2),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(won ? '🏆' : '💔', style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 8),
            Text(
              won ? 'You did it!' : 'Try again!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: won ? const Color(0xFF15803D) : const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
            ),
            if (won) ...[
              const SizedBox(height: 10),
              Text(
                '+${content.game.starsReward} ⭐',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFD97706)),
              ),
            ],
            const SizedBox(height: 20),
            if (won) NextLevelButton(content: content),
            Row(
              children: [
                Expanded(
                  child: _button(
                    label: 'Play Again',
                    icon: Icons.replay_rounded,
                    color: const Color(0xFF3B82F6),
                    onTap: onReplay,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _button(
                    label: 'Back',
                    icon: Icons.home_rounded,
                    color: const Color(0xFFF59E0B),
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _button({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return BouncyButton(
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Short "Great!" / "Oops!" toast shown over the play area.
class MiniFeedbackBubble extends StatelessWidget {
  final String? text;
  final bool good;

  const MiniFeedbackBubble({super.key, required this.text, required this.good});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: text == null ? 0 : 1,
        duration: const Duration(milliseconds: 180),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: good ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8)],
          ),
          child: Text(
            text ?? '',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}
