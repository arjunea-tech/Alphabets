import '../models/word_puzzle_game_model.dart';

/// Centralized database of Tamil word creation puzzles.
/// Every word is split into its authentic linguistic Tamil components.
const List<WordPuzzleModel> wordPuzzleDatabase = [
  // =============================================================
  // LEVEL 1: 2–3 Components (Beginner words)
  // =============================================================
  WordPuzzleModel(
    id: 'word_l1_1',
    word: 'மரம்',
    components: ['ம', 'ர', 'ம்'],
    distractorPool: ['க', 'ப', 'த', 'ச', 'ல', 'வ', 'ந', 'ட', 'அ', 'ய', 'ழ', 'உ', 'ண்', 'ஆ', 'இ'],
    difficultyLevel: 1,
    meaning: 'பசுமையான மரம்',
  ),
  WordPuzzleModel(
    id: 'word_l1_2',
    word: 'மலர்',
    components: ['ம', 'ல', 'ர்'],
    distractorPool: ['ப', 'க', 'ர', 'ச', 'வ', 'த', 'ந', 'அ', 'ய', 'ழ', 'ட', 'உ', 'ண்', 'இ', 'ஒ'],
    difficultyLevel: 1,
    meaning: 'அழகான மலர்',
  ),
  WordPuzzleModel(
    id: 'word_l1_3',
    word: 'கண்',
    components: ['க', 'ண்'],
    distractorPool: ['ம', 'ப', 'ர', 'ல', 'ச', 'த', 'வ', 'ந', 'அ', 'ய', 'ட', 'ழ', 'உ', 'ம்', 'ர்'],
    difficultyLevel: 1,
    meaning: 'பார்க்கும் கண்',
  ),
  WordPuzzleModel(
    id: 'word_l1_4',
    word: 'படம்',
    components: ['ப', 'ட', 'ம்'],
    distractorPool: ['க', 'ம', 'ர', 'ல', 'ச', 'த', 'வ', 'ந', 'அ', 'ய', 'ழ', 'உ', 'ண்', 'ர்', 'ஆ'],
    difficultyLevel: 1,
    meaning: 'வண்ணப் படம்',
  ),
  WordPuzzleModel(
    id: 'word_l1_5',
    word: 'நாய்',
    components: ['ந', 'ா', 'ய்'],
    distractorPool: ['ப', 'ம', 'க', 'ர', 'ல', 'ச', 'த', 'வ', 'அ', 'ய', 'ழ', 'ட', 'உ', 'ம்', 'ண்'],
    difficultyLevel: 1,
    meaning: 'வீட்டுக் காவல் நாய்',
  ),
  WordPuzzleModel(
    id: 'word_l1_6',
    word: 'மீன்',
    components: ['ம', 'ீ', 'ன்'],
    distractorPool: ['ப', 'க', 'ர', 'ல', 'ச', 'த', 'வ', 'ந', 'அ', 'ய', 'ழ', 'ட', 'ா', 'ம்', 'ர்'],
    difficultyLevel: 1,
    meaning: 'நீந்தும் மீன்',
  ),

  // =============================================================
  // LEVEL 2: 3–4 Components (Intermediate words)
  // =============================================================
  WordPuzzleModel(
    id: 'word_l2_1',
    word: 'அம்மா',
    components: ['அ', 'ம்', 'ம', 'ா'],
    distractorPool: ['ப', 'க', 'ர', 'ல', 'ச', 'த', 'வ', 'ந', 'ய', 'ழ', 'ட', 'உ', 'ண்', 'ர்', 'ஆ', 'இ', 'ீ'],
    difficultyLevel: 2,
    meaning: 'அன்பான அம்மா',
  ),
  WordPuzzleModel(
    id: 'word_l2_2',
    word: 'அப்பா',
    components: ['அ', 'ப்', 'ப', 'ா'],
    distractorPool: ['ம', 'க', 'ர', 'ல', 'ச', 'த', 'வ', 'ந', 'ய', 'ழ', 'ட', 'உ', 'ம்', 'ண்', 'ர்', 'இ', 'ீ'],
    difficultyLevel: 2,
    meaning: 'பாசமான அப்பா',
  ),
  WordPuzzleModel(
    id: 'word_l2_3',
    word: 'மாமா',
    components: ['ம', 'ா', 'ம', 'ா'],
    distractorPool: ['ப', 'க', 'ர', 'ல', 'ச', 'த', 'வ', 'ந', 'அ', 'ய', 'ழ', 'ட', 'உ', 'ம்', 'ண்', 'ர்', 'ப்'],
    difficultyLevel: 2,
    meaning: 'அன்பு மாமா',
  ),
  WordPuzzleModel(
    id: 'word_l2_4',
    word: 'வீடு',
    components: ['வ', 'ீ', 'ட', 'ு'],
    distractorPool: ['ம', 'ப', 'க', 'ர', 'ல', 'ச', 'த', 'ந', 'அ', 'ய', 'ழ', 'ா', 'ம்', 'ண்', 'ர்', 'ப்', 'உ'],
    difficultyLevel: 2,
    meaning: 'நம் வீடு',
  ),
  WordPuzzleModel(
    id: 'word_l2_5',
    word: 'பந்து',
    components: ['ப', 'ந்', 'த', 'ு'],
    distractorPool: ['ம', 'க', 'ர', 'ல', 'ச', 'வ', 'ந', 'அ', 'ய', 'ழ', 'ட', 'ா', 'ம்', 'ண்', 'ர்', 'ீ', 'உ'],
    difficultyLevel: 2,
    meaning: 'விளையாடும் பந்து',
  ),
  WordPuzzleModel(
    id: 'word_l2_6',
    word: 'காடை',
    components: ['க', 'ா', 'ட', 'ை'],
    distractorPool: ['ம', 'ப', 'ர', 'ல', 'ச', 'த', 'வ', 'ந', 'அ', 'ய', 'ழ', 'ு', 'ம்', 'ண்', 'ர்', 'ப்', 'ீ'],
    difficultyLevel: 2,
    meaning: 'பறக்கும் காடை',
  ),

  // =============================================================
  // LEVEL 3: 4–5 Components (Advanced words)
  // =============================================================
  WordPuzzleModel(
    id: 'word_l3_1',
    word: 'யானை',
    components: ['ய', 'ா', 'ன', 'ை'],
    distractorPool: ['ம', 'ப', 'க', 'ல', 'ந', 'ச', 'ர', 'த', 'வ', 'அ', 'ட', 'ழ', 'உ', 'ம்', 'ண்', 'ர்', 'ப்', 'ீ', 'ு', 'ஆ'],
    difficultyLevel: 3,
    meaning: 'பெரிய யானை',
  ),
  WordPuzzleModel(
    id: 'word_l3_2',
    word: 'பூனை',
    components: ['ப', 'ூ', 'ன', 'ை'],
    distractorPool: ['ம', 'க', 'ர', 'ல', 'ச', 'த', 'வ', 'ந', 'அ', 'ய', 'ழ', 'ட', 'ா', 'ு', 'ம்', 'ண்', 'ர்', 'ப்', 'ீ', 'உ'],
    difficultyLevel: 3,
    meaning: 'செல்லப் பூனை',
  ),
  WordPuzzleModel(
    id: 'word_l3_3',
    word: 'மாடு',
    components: ['ம', 'ா', 'ட', 'ு'],
    distractorPool: ['ப', 'க', 'ர', 'ல', 'ச', 'த', 'வ', 'ந', 'அ', 'ய', 'ழ', 'ை', 'ூ', 'ம்', 'ண்', 'ர்', 'ப்', 'ீ', 'உ', 'ஆ'],
    difficultyLevel: 3,
    meaning: 'நாட்டு மாடு',
  ),
  WordPuzzleModel(
    id: 'word_l3_4',
    word: 'பள்ளி',
    components: ['ப', 'ள்', 'ள', 'ி'],
    distractorPool: ['ம', 'க', 'ர', 'ல', 'ச', 'த', 'வ', 'ந', 'அ', 'ய', 'ழ', 'ட', 'ா', 'ை', 'ம்', 'ண்', 'ர்', 'ப்', 'ூ', 'ு'],
    difficultyLevel: 3,
    meaning: 'கல்வி கற்கும் பள்ளி',
  ),
  WordPuzzleModel(
    id: 'word_l3_5',
    word: 'வண்டு',
    components: ['வ', 'ண்', 'ட', 'ு'],
    distractorPool: ['ம', 'ப', 'க', 'ர', 'ல', 'ச', 'த', 'ந', 'அ', 'ய', 'ழ', 'ா', 'ை', 'ம்', 'ர்', 'ப்', 'ீ', 'ூ', 'ள்', 'ள'],
    difficultyLevel: 3,
    meaning: 'ரீங்கார வண்டு',
  ),
  WordPuzzleModel(
    id: 'word_l3_6',
    word: 'பட்டம்',
    components: ['ப', 'ட்', 'ட', 'ம்'],
    distractorPool: ['ம', 'க', 'ர', 'ல', 'ச', 'த', 'வ', 'ந', 'அ', 'ய', 'ழ', 'ா', 'ை', 'ண்', 'ர்', 'ப்', 'ீ', 'ு', 'ூ', 'ள்'],
    difficultyLevel: 3,
    meaning: 'வானில் பறக்கும் பட்டம்',
  ),

  // =============================================================
  // LEVEL 4: 5+ Components (Master words & Long sequences)
  // =============================================================
  WordPuzzleModel(
    id: 'word_l4_1',
    word: 'பாப்பா',
    components: ['ப', 'ா', 'ப்', 'ப', 'ா'],
    distractorPool: ['ம', 'க', 'ர', 'ல', 'ச', 'த', 'வ', 'ந', 'அ', 'ய', 'ழ', 'ட', 'ை', 'ீ', 'ம்', 'ண்', 'ர்', 'ூ', 'ு', 'ள்', 'ள', 'ஆ'],
    difficultyLevel: 4,
    meaning: 'மழலைப் பாப்பா',
  ),
  WordPuzzleModel(
    id: 'word_l4_2',
    word: 'தாமரை',
    components: ['த', 'ா', 'ம', 'ர', 'ை'],
    distractorPool: ['ப', 'க', 'ல', 'ச', 'வ', 'ந', 'அ', 'ய', 'ழ', 'ட', 'ீ', 'ு', 'ூ', 'ம்', 'ண்', 'ர்', 'ப்', 'ள்', 'ள', 'ட்', 'ஆ', 'இ'],
    difficultyLevel: 4,
    meaning: 'தேசிய மலர் தாமரை',
  ),
  WordPuzzleModel(
    id: 'word_l4_3',
    word: 'கிளி',
    components: ['க', 'ி', 'ள', 'ி'],
    distractorPool: ['ம', 'ப', 'ர', 'ல', 'ச', 'த', 'வ', 'ந', 'அ', 'ய', 'ழ', 'ட', 'ா', 'ை', 'ூ', 'ம்', 'ண்', 'ர்', 'ப்', 'ு', 'ள்', 'ட்'],
    difficultyLevel: 4,
    meaning: 'பேசும் பச்சைக்கிளி',
  ),
  WordPuzzleModel(
    id: 'word_l4_4',
    word: 'கப்பல்',
    components: ['க', 'ப்', 'ப', 'ல்'],
    distractorPool: ['ம', 'ர', 'ல', 'ச', 'த', 'வ', 'ந', 'அ', 'ய', 'ழ', 'ட', 'ா', 'ை', 'ீ', 'ு', 'ம்', 'ண்', 'ர்', 'ூ', 'ள்', 'ள', 'ட்'],
    difficultyLevel: 4,
    meaning: 'கடலில் செல்லும் கப்பல்',
  ),
  WordPuzzleModel(
    id: 'word_l4_5',
    word: 'ஆலமரம்',
    components: ['ஆ', 'ல', 'ம', 'ர', 'ம்'],
    distractorPool: ['ப', 'க', 'ச', 'த', 'வ', 'ந', 'அ', 'ய', 'ழ', 'ட', 'ா', 'ை', 'ீ', 'ு', 'ண்', 'ர்', 'ப்', 'ூ', 'ள்', 'ள', 'ட்', 'இ'],
    difficultyLevel: 4,
    meaning: 'பெரிய ஆலமரம்',
  ),
  WordPuzzleModel(
    id: 'word_l4_6',
    word: 'புத்தகம்',
    components: ['ப', 'ு', 'த்', 'த', 'க', 'ம்'],
    distractorPool: ['ம', 'ர', 'ல', 'ச', 'வ', 'ந', 'அ', 'ய', 'ழ', 'ட', 'ா', 'ை', 'ீ', 'ூ', 'ண்', 'ர்', 'ப்', 'ள்', 'ள', 'ட்', 'ஆ', 'இ'],
    difficultyLevel: 4,
    meaning: 'அறிவு தரும் புத்தகம்',
  ),
];
