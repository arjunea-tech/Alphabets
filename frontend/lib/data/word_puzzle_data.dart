import '../models/word_puzzle_game_model.dart';

/// Centralized database of English alphabet word spelling puzzles.
/// Every word is split into its uppercase letter components.
const List<WordPuzzleModel> wordPuzzleDatabase = [
  // =============================================================
  // LEVEL 1: 3-Letter Words (Beginner)
  // =============================================================
  WordPuzzleModel(
    id: 'word_l1_1',
    word: 'CAT',
    components: ['C', 'A', 'T'],
    distractorPool: ['B', 'D', 'O', 'G', 'M', 'R', 'S', 'P'],
    difficultyLevel: 1,
    meaning: 'A cute furry pet cat',
  ),
  WordPuzzleModel(
    id: 'word_l1_2',
    word: 'DOG',
    components: ['D', 'O', 'G'],
    distractorPool: ['C', 'A', 'T', 'F', 'H', 'N', 'P', 'B'],
    difficultyLevel: 1,
    meaning: 'A loyal pet dog',
  ),
  WordPuzzleModel(
    id: 'word_l1_3',
    word: 'SUN',
    components: ['S', 'U', 'N'],
    distractorPool: ['M', 'O', 'R', 'T', 'A', 'E', 'L', 'D'],
    difficultyLevel: 1,
    meaning: 'The bright warm sun in the sky',
  ),
  WordPuzzleModel(
    id: 'word_l1_4',
    word: 'HAT',
    components: ['H', 'A', 'T'],
    distractorPool: ['C', 'P', 'B', 'O', 'X', 'Y', 'E', 'R'],
    difficultyLevel: 1,
    meaning: 'A cool hat worn on head',
  ),
  WordPuzzleModel(
    id: 'word_l1_5',
    word: 'CAR',
    components: ['C', 'A', 'R'],
    distractorPool: ['B', 'U', 'S', 'V', 'A', 'N', 'E', 'T'],
    difficultyLevel: 1,
    meaning: 'A speedy colorful car',
  ),
  WordPuzzleModel(
    id: 'word_l1_6',
    word: 'FOX',
    components: ['F', 'O', 'X'],
    distractorPool: ['B', 'O', 'X', 'T', 'A', 'R', 'S', 'M'],
    difficultyLevel: 1,
    meaning: 'A clever wild fox',
  ),

  // =============================================================
  // LEVEL 2: 4-Letter Words (Intermediate)
  // =============================================================
  WordPuzzleModel(
    id: 'word_l2_1',
    word: 'BALL',
    components: ['B', 'A', 'L', 'L'],
    distractorPool: ['C', 'D', 'O', 'L', 'P', 'T', 'S', 'K'],
    difficultyLevel: 2,
    meaning: 'A bouncy ball for playing games',
  ),
  WordPuzzleModel(
    id: 'word_l2_2',
    word: 'FISH',
    components: ['F', 'I', 'S', 'H'],
    distractorPool: ['B', 'O', 'A', 'T', 'W', 'L', 'K', 'E'],
    difficultyLevel: 2,
    meaning: 'A friendly fish swimming in the sea',
  ),
  WordPuzzleModel(
    id: 'word_l2_3',
    word: 'BIRD',
    components: ['B', 'I', 'R', 'D'],
    distractorPool: ['S', 'O', 'N', 'G', 'F', 'L', 'Y', 'P'],
    difficultyLevel: 2,
    meaning: 'A cheerful bird flying high',
  ),
  WordPuzzleModel(
    id: 'word_l2_4',
    word: 'STAR',
    components: ['S', 'T', 'A', 'R'],
    distractorPool: ['M', 'O', 'O', 'N', 'S', 'K', 'Y', 'B'],
    difficultyLevel: 2,
    meaning: 'A shining star in the night sky',
  ),
  WordPuzzleModel(
    id: 'word_l2_5',
    word: 'LION',
    components: ['L', 'I', 'O', 'N'],
    distractorPool: ['K', 'I', 'N', 'G', 'R', 'A', 'R', 'E'],
    difficultyLevel: 2,
    meaning: 'The brave king of the jungle',
  ),
  WordPuzzleModel(
    id: 'word_l2_6',
    word: 'TREE',
    components: ['T', 'R', 'E', 'E'],
    distractorPool: ['L', 'E', 'A', 'F', 'W', 'O', 'O', 'D'],
    difficultyLevel: 2,
    meaning: 'A tall green shady tree',
  ),

  // =============================================================
  // LEVEL 3: 5-Letter Words (Advanced)
  // =============================================================
  WordPuzzleModel(
    id: 'word_l3_1',
    word: 'APPLE',
    components: ['A', 'P', 'P', 'L', 'E'],
    distractorPool: ['F', 'R', 'U', 'I', 'T', 'S', 'W', 'E'],
    difficultyLevel: 3,
    meaning: 'A sweet and juicy red apple',
  ),
  WordPuzzleModel(
    id: 'word_l3_2',
    word: 'ZEBRA',
    components: ['Z', 'E', 'B', 'R', 'A'],
    distractorPool: ['H', 'O', 'R', 'S', 'E', 'S', 'T', 'R'],
    difficultyLevel: 3,
    meaning: 'A striped wild zebra',
  ),
  WordPuzzleModel(
    id: 'word_l3_3',
    word: 'TIGER',
    components: ['T', 'I', 'G', 'E', 'R'],
    distractorPool: ['F', 'A', 'S', 'T', 'W', 'I', 'L', 'D'],
    difficultyLevel: 3,
    meaning: 'A magnificent striped tiger',
  ),
  WordPuzzleModel(
    id: 'word_l3_4',
    word: 'TRAIN',
    components: ['T', 'R', 'A', 'I', 'N'],
    distractorPool: ['T', 'R', 'A', 'C', 'K', 'S', 'L', 'O'],
    difficultyLevel: 3,
    meaning: 'A long train riding along the tracks',
  ),
];
