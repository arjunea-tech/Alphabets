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

class AythamScreen extends StatefulWidget {
  final ProgressService progressService;

  const AythamScreen({super.key, required this.progressService});

  @override
  State<AythamScreen> createState() => _AythamScreenState();
}

class _AythamScreenState extends State<AythamScreen> {
  // Bundled letters (same ids/images as the server) render instantly;
  // admin data replaces them as soon as the request returns.
  List<LetterModel> _letters = englishLettersList;

  @override
  void initState() {
    super.initState();
    _loadAllLetters();
  }

  Future<void> _loadAllLetters() async {
    try {
      final letters = await DataService.instance.getAllAlphabets();
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
            title: 'All Alphabets (A to Z)',
            starCount: widget.progressService.stars,
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
                    itemCount: _letters.length,
                    itemBuilder: (context, index) {
                      final item = _letters[index];
                      final isDone = widget.progressService.isLetterCompleted(item.id);
                      final accent = item.type == LetterType.vowel ? AppColors.uyirColor : AppColors.meiColor;

                      return LetterCard(
                        letter: item,
                        accentColor: accent,
                        isCompleted: isDone,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LetterDetailScreen(
                                letterList: _letters,
                                initialIndex: index,
                                accentColor: accent,
                                progressService: widget.progressService,
                              ),
                            ),
                          ).then((_) {
                            _loadAllLetters();
                          });
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
