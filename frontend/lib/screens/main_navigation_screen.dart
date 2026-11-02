import 'package:flutter/material.dart';
import '../services/progress_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bouncy_button.dart';
import 'games/games_screen.dart';
import 'home/home_screen.dart';
import 'learning/learning_screen.dart';
import 'quiz/quiz_screen.dart';
import 'videos/videos_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final ProgressService progressService;

  const MainNavigationScreen({super.key, required this.progressService});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        progressService: widget.progressService,
        onTabSelect: _onTabSelected,
      ),
      LearningScreen(progressService: widget.progressService),
      GamesScreen(progressService: widget.progressService),
      VideosScreen(progressService: widget.progressService),
      QuizScreen(progressService: widget.progressService),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: _buildCustomNavBar(),
    );
  }

  Widget _buildCustomNavBar() {
    final items = const [
      _NavItem(icon: Icons.home_rounded, label: 'Home', color: AppColors.primary),
      _NavItem(icon: Icons.menu_book_rounded, label: 'Learn', color: AppColors.secondary),
      _NavItem(icon: Icons.sports_esports_rounded, label: 'Games', color: AppColors.candyPurple),
      _NavItem(icon: Icons.play_circle_filled_rounded, label: 'Videos', color: AppColors.playfulPink),
      _NavItem(icon: Icons.quiz_rounded, label: 'Quiz', color: AppColors.meiColor),
    ];

    return SafeArea(
      child: Container(
        height: 70,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFFFFE5B4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(items.length, (index) {
            final isSelected = _selectedIndex == index;
            final item = items[index];

            return BouncyButton(
              onPressed: () => _onTabSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? 14 : 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? item.color.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      color: isSelected ? item.color : AppColors.textMuted,
                      size: isSelected ? 26 : 24,
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 6),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: item.color,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final Color color;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.color,
  });
}
