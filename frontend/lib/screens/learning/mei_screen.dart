import 'package:flutter/material.dart';
import '../../data/english_letters_data.dart';
import '../../models/letter_model.dart';
import '../../services/data_service.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/kid_app_bar.dart';
import '../../widgets/kid_scaffold_background.dart';
import '../../widgets/letter_card.dart';
import 'letter_detail_screen.dart';

class MeiScreen extends StatefulWidget {
  final ProgressService progressService;

  const MeiScreen({super.key, required this.progressService});

  @override
  State<MeiScreen> createState() => _MeiScreenState();
}

class _MeiScreenState extends State<MeiScreen> {
  List<LetterModel> _letters = englishConsonantsList;

  @override
  void initState() {
    super.initState();
    _loadConsonants();
  }

  Future<void> _loadConsonants() async {
    try {
      DataService.instance.invalidateCache();
      final letters = await DataService.instance.getMeiLetters();
      if (mounted && letters.isNotEmpty) {
        setState(() {
          _letters = letters;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.progressService,
      builder: (context, _) {
        return Scaffold(
          appBar: KidAppBar(
            title: 'Consonants (21 Letters)',
            starCount: widget.progressService.stars,
          ),
          body: KidScaffoldBackground(
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadConsonants,
                color: AppColors.meiColor,
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
                      itemCount: _letters.length,
                      itemBuilder: (context, index) {
                        final item = _letters[index];
                        final isDone = widget.progressService.isLetterCompleted(item.id);

                        return LetterCard(
                          letter: item,
                          accentColor: AppColors.meiColor,
                          isCompleted: isDone,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LetterDetailScreen(
                                  letterList: _letters,
                                  initialIndex: index,
                                  accentColor: AppColors.meiColor,
                                  progressService: widget.progressService,
                                ),
                              ),
                            ).then((_) {
                              _loadConsonants();
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
