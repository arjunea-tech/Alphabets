import '../models/letter_model.dart';
import '../models/story_model.dart';
import '../models/game_model.dart';
import '../models/game_item_model.dart';
import '../models/video_model.dart';
import '../models/quiz_model.dart';

import '../data/english_letters_data.dart';
import '../data/story_data.dart';
import '../data/game_data.dart';
import '../data/video_data.dart';
import '../data/quiz_data.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

abstract class IDataRepository {
  Future<List<LetterModel>> getAllAlphabets();
  Future<List<LetterModel>> getUyirLetters(); // Vowels (A, E, I, O, U)
  Future<List<LetterModel>> getMeiLetters(); // Consonants (21 Letters)
  Future<LetterModel> getAythamLetter();
  Future<List<LetterModel>> getUyirmeiByGroup(String meiBase);
  Future<List<String>> getMeiGroupBases();
  Future<StoryModel> getFeaturedStory();
  Future<List<GameQuestion>> getGameQuestions();
  Future<List<VideoItem>> getVideoLessons();
  Future<List<GameItem>> getActiveGames();
  Future<List<QuizCategory>> getQuizCategories();
  Future<List<QuizQuestion>> getQuizQuestions(String categoryId);
}

class LocalDataRepository implements IDataRepository {
  @override
  Future<List<LetterModel>> getAllAlphabets() async {
    return englishLettersList;
  }

  @override
  Future<List<LetterModel>> getUyirLetters() async {
    return englishVowelsList;
  }

  @override
  Future<List<LetterModel>> getMeiLetters() async {
    return englishConsonantsList;
  }

  @override
  Future<LetterModel> getAythamLetter() async {
    return englishLettersList.first;
  }

  @override
  Future<List<LetterModel>> getUyirmeiByGroup(String meiBase) async {
    return [];
  }

  @override
  Future<List<String>> getMeiGroupBases() async {
    return [];
  }

  @override
  Future<StoryModel> getFeaturedStory() async {
    return hareAndTortoiseStory;
  }

  @override
  Future<List<GameQuestion>> getGameQuestions() async {
    return letterPuzzleQuestions;
  }

  @override
  Future<List<VideoItem>> getVideoLessons() async {
    return tamilVideoLessonsList;
  }

  @override
  Future<List<GameItem>> getActiveGames() async {
    return const [
      GameItem(
        id: 'game_candy_1',
        gameType: 'candy',
        title: 'Alphabet Candy Match',
        prompt: 'Match 3 colorful letter candies together!',
        clueImage: 'assets/images/games/candy_match_cover.png',
        displayOrder: 1,
        isActive: true,
      ),
      GameItem(
        id: 'game_runner_1',
        gameType: 'runner',
        title: 'Alphabet Runner',
        prompt: 'Run and collect letters along the jungle trail!',
        clueImage: 'assets/images/games/runner_cover.png',
        displayOrder: 2,
        isActive: true,
      ),
      GameItem(
        id: 'game_balloon_1',
        gameType: 'balloon',
        title: 'Balloon Word Pop',
        prompt: 'Pop the floating balloons with the target letters!',
        clueImage: 'assets/images/games/balloon_pop_cover.png',
        displayOrder: 3,
        isActive: true,
      ),
      GameItem(
        id: 'game_flappy_1',
        gameType: 'flappy',
        title: 'Flappy Word',
        prompt: 'Flap wings and fly through the correct cloud gates!',
        clueImage: 'assets/images/games/flappy_word_cover.png',
        displayOrder: 4,
        isActive: true,
      ),
      GameItem(
        id: 'game_ninja_1',
        gameType: 'ninja',
        title: 'Word Ninja',
        prompt: 'Slice the flying letter fruits with your katana sword!',
        clueImage: 'assets/images/games/word_ninja_cover.png',
        displayOrder: 5,
        isActive: true,
      ),
      GameItem(
        id: 'game_racing_1',
        gameType: 'racing',
        title: 'Car Racing (Vowels)',
        prompt: 'Steer your car and drive through the target letter!',
        clueImage: 'assets/images/games/car_racing_cover.png',
        displayOrder: 6,
        isActive: true,
      ),
      GameItem(
        id: 'game_fishing_1',
        gameType: 'fishing',
        title: 'Letter Fishing',
        prompt: 'Catch the swimming fish carrying the target letter!',
        clueImage: 'assets/images/games/fishing_cover.png',
        displayOrder: 7,
        isActive: true,
      ),
      GameItem(
        id: 'game_basket_1',
        gameType: 'basket',
        title: 'Letter Basket (Vowels)',
        prompt: 'Catch the falling vowel letters into your basket!',
        clueImage: 'assets/images/games/basket_vowels_cover.png',
        displayOrder: 8,
        isActive: true,
      ),
      GameItem(
        id: 'game_basket_2',
        gameType: 'basket',
        title: 'Letter Basket (Consonants)',
        prompt: 'Catch the falling consonant letters into your magical basket!',
        clueImage: 'assets/images/games/basket_consonants_cover.png',
        displayOrder: 9,
        isActive: true,
      ),
      GameItem(
        id: 'game_puzzle_1',
        gameType: 'puzzle',
        title: 'Word Puzzle',
        prompt: 'Select the missing starting letter to complete the word!',
        clueImage: 'assets/images/welcome.png',
        displayOrder: 10,
        isActive: true,
      ),
      GameItem(
        id: 'game_matching_1',
        gameType: 'matching',
        title: 'Letter Matching',
        prompt: 'Flip the cards and match each big letter with its small letter!',
        clueImage: 'assets/images/games/letter_matching_cover.png',
        displayOrder: 11,
        isActive: true,
      ),
    ];
  }

  @override
  Future<List<QuizCategory>> getQuizCategories() async {
    return tamilQuizCategories;
  }

  @override
  Future<List<QuizQuestion>> getQuizQuestions(String categoryId) async {
    return tamilQuizQuestionsMap[categoryId] ?? tamilQuizQuestionsMap['quiz_alphabets'] ?? [];
  }
}

class ApiDataRepository implements IDataRepository {
  final LocalDataRepository _fallback = LocalDataRepository();
  List<LetterModel>? _cachedAll;
  List<LetterModel>? _cachedVowels;
  List<LetterModel>? _cachedConsonants;
  List<VideoItem>? _cachedVideos;
  List<GameItem>? _cachedGames;

  LetterModel _enrichWithLocalAssets(LetterModel letter) {
    if (letter.imagePath == null ||
        letter.imagePath!.isEmpty ||
        letter.imagePath == 'assets/images/welcome.png') {
      final localMatch = englishLettersList.firstWhere(
        (l) => l.letter.toUpperCase() == letter.letter.toUpperCase(),
        orElse: () => letter,
      );

      if (localMatch != letter && localMatch.imagePath != null) {
        return LetterModel(
          id: letter.id,
          letter: letter.letter,
          type: letter.type,
          word: letter.word.isNotEmpty ? letter.word : localMatch.word,
          meaning: letter.meaning.isNotEmpty ? letter.meaning : localMatch.meaning,
          phonetic: letter.phonetic.isNotEmpty ? letter.phonetic : localMatch.phonetic,
          iconEmoji: letter.iconEmoji.isNotEmpty && letter.iconEmoji != '⭐'
              ? letter.iconEmoji
              : localMatch.iconEmoji,
          imagePath: localMatch.imagePath,
          audioPath: letter.audioPath ?? localMatch.audioPath,
          videoUrl: letter.videoUrl,
          explanation: letter.explanation ?? localMatch.explanation,
        );
      }
    }
    return letter;
  }

  @override
  Future<List<LetterModel>> getAllAlphabets() async {
    if (_cachedAll != null && _cachedAll!.isNotEmpty) {
      return _cachedAll!;
    }
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/letters?all=true');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] is List) {
          final List list = data['data'];
          final letters = list
              .map((item) => _enrichWithLocalAssets(LetterModel.fromJson(item as Map<String, dynamic>)))
              .toList();
          if (letters.isNotEmpty) {
            _cachedAll = letters;
            return letters;
          }
        }
      }
    } catch (_) {}
    return _fallback.getAllAlphabets();
  }

  @override
  Future<List<LetterModel>> getUyirLetters() async {
    if (_cachedVowels != null && _cachedVowels!.isNotEmpty) {
      return _cachedVowels!;
    }
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/letters?type=vowel&all=true');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] is List) {
          final List list = data['data'];
          final letters = list
              .map((item) => _enrichWithLocalAssets(LetterModel.fromJson(item as Map<String, dynamic>)))
              .toList();
          if (letters.isNotEmpty) {
            _cachedVowels = letters;
            return letters;
          }
        }
      }
    } catch (_) {}
    return _fallback.getUyirLetters();
  }

  @override
  Future<List<LetterModel>> getMeiLetters() async {
    if (_cachedConsonants != null && _cachedConsonants!.isNotEmpty) {
      return _cachedConsonants!;
    }
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/letters?type=consonant&all=true');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] is List) {
          final List list = data['data'];
          final letters = list
              .map((item) => _enrichWithLocalAssets(LetterModel.fromJson(item as Map<String, dynamic>)))
              .toList();
          if (letters.isNotEmpty) {
            _cachedConsonants = letters;
            return letters;
          }
        }
      }
    } catch (_) {}
    return _fallback.getMeiLetters();
  }

  @override
  Future<LetterModel> getAythamLetter() async {
    final all = await getAllAlphabets();
    return all.isNotEmpty ? all.first : englishLettersList.first;
  }

  @override
  Future<List<LetterModel>> getUyirmeiByGroup(String meiBase) async => [];

  @override
  Future<List<String>> getMeiGroupBases() async => [];

  @override
  Future<StoryModel> getFeaturedStory() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/stories');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] is List && (data['data'] as List).isNotEmpty) {
          final storyJson = (data['data'] as List).first as Map<String, dynamic>;
          // Fetch full story details with pages
          final storyId = storyJson['id'];
          final detailUri = Uri.parse('${ApiConfig.baseUrl}/stories/$storyId');
          final detailRes = await http.get(detailUri).timeout(const Duration(seconds: 4));
          if (detailRes.statusCode == 200) {
            final detailData = jsonDecode(detailRes.body);
            if (detailData['success'] == true && detailData['data'] != null) {
              return StoryModel.fromJson(detailData['data'] as Map<String, dynamic>);
            }
          }
        }
      }
    } catch (_) {}
    return _fallback.getFeaturedStory();
  }

  @override
  Future<List<GameQuestion>> getGameQuestions() => _fallback.getGameQuestions();

  void clearVideoCache() {
    _cachedVideos = null;
  }

  @override
  Future<List<VideoItem>> getVideoLessons() async {
    if (_cachedVideos != null && _cachedVideos!.isNotEmpty) {
      return _cachedVideos!;
    }
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/videos?all=true');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] is List) {
          final List list = data['data'];
          final videos = list.map((item) => VideoItem.fromJson(item as Map<String, dynamic>)).toList();
          if (videos.isNotEmpty) {
            _cachedVideos = videos;
            return videos;
          }
        }
      }
    } catch (_) {}
    return _fallback.getVideoLessons();
  }

  void clearGamesCache() {
    _cachedGames = null;
  }

  @override
  Future<List<GameItem>> getActiveGames() async {
    if (_cachedGames != null && _cachedGames!.isNotEmpty) {
      return _cachedGames!;
    }
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/games');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] is List) {
          final List list = data['data'];
          final games = list.map((item) => GameItem.fromJson(item as Map<String, dynamic>)).toList();
          if (games.isNotEmpty) {
            _cachedGames = games;
            return games;
          }
        }
      }
    } catch (_) {}
    return _fallback.getActiveGames();
  }

  @override
  Future<List<QuizCategory>> getQuizCategories() => _fallback.getQuizCategories();

  @override
  Future<List<QuizQuestion>> getQuizQuestions(String categoryId) => _fallback.getQuizQuestions(categoryId);

  void invalidateCache() {
    _cachedAll = null;
    _cachedVowels = null;
    _cachedConsonants = null;
    _cachedVideos = null;
    _cachedGames = null;
  }
}

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  static DataService get instance => _instance;
  DataService._internal();

  IDataRepository _repo = ApiDataRepository();

  void setRepository(IDataRepository customRepo) {
    _repo = customRepo;
  }

  Future<List<LetterModel>> getAllAlphabets() => _repo.getAllAlphabets();
  Future<List<LetterModel>> getUyirLetters() => _repo.getUyirLetters();
  Future<List<LetterModel>> getMeiLetters() => _repo.getMeiLetters();
  Future<LetterModel> getAythamLetter() => _repo.getAythamLetter();
  Future<List<LetterModel>> getUyirmeiByGroup(String meiBase) => _repo.getUyirmeiByGroup(meiBase);
  Future<List<String>> getMeiGroupBases() => _repo.getMeiGroupBases();
  Future<StoryModel> getFeaturedStory() => _repo.getFeaturedStory();
  Future<List<GameQuestion>> getGameQuestions() => _repo.getGameQuestions();
  Future<List<VideoItem>> getVideoLessons() => _repo.getVideoLessons();
  Future<List<GameItem>> getActiveGames() => _repo.getActiveGames();
  Future<List<QuizCategory>> getQuizCategories() => _repo.getQuizCategories();
  Future<List<QuizQuestion>> getQuizQuestions(String categoryId) => _repo.getQuizQuestions(categoryId);

  void clearVideoCache() {
    if (_repo is ApiDataRepository) {
      (_repo as ApiDataRepository).clearVideoCache();
    }
  }

  void clearGamesCache() {
    if (_repo is ApiDataRepository) {
      (_repo as ApiDataRepository).clearGamesCache();
    }
  }

  void invalidateCache() {
    if (_repo is ApiDataRepository) {
      (_repo as ApiDataRepository).invalidateCache();
    }
  }
}
