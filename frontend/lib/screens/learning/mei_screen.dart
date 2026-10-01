import 'package:flutter/material.dart';
import '../../data/mei_data.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/kid_app_bar.dart';
import '../../widgets/kid_scaffold_background.dart';
import '../../widgets/letter_card.dart';
import 'letter_detail_screen.dart';

class MeiScreen extends StatelessWidget {
  final ProgressService progressService;

  const MeiScreen({super.key, required this.progressService});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: progressService,
      builder: (context, _) {
        return Scaffold(
          appBar: KidAppBar(
            title: 'மெய் எழுத்துகள் (18)',
            starCount: progressService.stars,
          ),
          body: KidScaffoldBackground(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 600 ? 5 : 3;

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.88,
                    ),
                    itemCount: meiLettersList.length,
                    itemBuilder: (context, index) {
                      final item = meiLettersList[index];
                      final isDone = progressService.isLetterCompleted(item.id);

                      return LetterCard(
                        letter: item,
                        accentColor: AppColors.meiColor,
                        isCompleted: isDone,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LetterDetailScreen(
                                letterList: meiLettersList,
                                initialIndex: index,
                                accentColor: AppColors.meiColor,
                                progressService: progressService,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
