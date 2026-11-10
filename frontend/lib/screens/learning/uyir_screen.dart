import 'package:flutter/material.dart';
import '../../models/letter_model.dart';
import '../../services/data_service.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/kid_app_bar.dart';
import '../../widgets/kid_scaffold_background.dart';
import '../../widgets/letter_card.dart';
import 'letter_detail_screen.dart';

class UyirScreen extends StatefulWidget {
  final ProgressService progressService;

  const UyirScreen({super.key, required this.progressService});

  @override
  State<UyirScreen> createState() => _UyirScreenState();
}

class _UyirScreenState extends State<UyirScreen> {
  List<LetterModel> _letters = const []; // admin letters only

  @override
  void initState() {
    super.initState();
    _loadVowels();
  }

  Future<void> _loadVowels() async {
    try {
      final letters = await DataService.instance.getUyirLetters();
      if (mounted && letters.isNotEmpty) {
        setState(() {
          _letters = letters;
        });
      }
    } catch (_) {
      // Server unreachable: nothing to show until it is back
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.progressService,
      builder: (context, _) {
        return Scaffold(
          appBar: KidAppBar(
            title: 'Vowels (A, E, I, O, U)',
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
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _letters.length,
                    itemBuilder: (context, index) {
                      final item = _letters[index];
                      final isDone = widget.progressService.isLetterCompleted(item.id);

                      return LetterCard(
                        letter: item,
                        accentColor: AppColors.uyirColor,
                        isCompleted: isDone,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LetterDetailScreen(
                                letterList: _letters,
                                initialIndex: index,
                                accentColor: AppColors.uyirColor,
                                progressService: widget.progressService,
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
