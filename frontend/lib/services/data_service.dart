import '../models/letter_model.dart';
import '../models/story_model.dart';
import '../models/game_model.dart';
import '../models/game_item_model.dart';
import '../models/video_model.dart';
import '../models/quiz_model.dart';

import '../data/english_letters_data.dart';
import '../data/game_data.dart';

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
    throw Exception('Stories are admin-managed only');
  }

  @override
  Future<List<GameQuestion>> getGameQuestions() async {
    return letterPuzzleQuestions;
  }

  @override
  Future<List<VideoItem>> getVideoLessons() async {
    return const []; // Videos are admin-managed only
  }

  @override
  Future<List<GameItem>> getActiveGames() async {
    // Games are admin-managed only; there is no offline game catalog.
    return const [];
  }

  @override
  Future<List<QuizCategory>> getQuizCategories() async {
    return const []; // Quizzes are admin-managed only
  }

  @override
  Future<List<QuizQuestion>> getQuizQuestions(String categoryId) async {
    return const []; // Quizzes are admin-managed only
  }
}

class ApiDataRepository implements IDataRepository {
  final LocalDataRepository _fallback = LocalDataRepository();

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

  // ---------------------------------------------------------------------------
  // Fast cache: once something has loaded, screens get it instantly. When it is
  // older than [_freshFor] it is still returned instantly while a fresh copy is
  // fetched in the background, so admin changes show up on the next visit.
  // Identical requests that are already running are shared, not repeated.
  // ---------------------------------------------------------------------------
  static const Duration _freshFor = Duration(seconds: 30);
  static const Duration _timeout = Duration(seconds: 8);
  final Map<String, _CacheEntry> _cache = {};
  final Map<String, Future<dynamic>> _inFlight = {};

  Future<T> _cached<T>(String key, Future<T> Function() load) async {
    final entry = _cache[key];
    if (entry != null) {
      if (DateTime.now().difference(entry.storedAt) > _freshFor) {
        _refresh<T>(key, load).catchError((_) => entry.value as T); // background, errors ignored
      }
      return entry.value as T;
    }
    return _refresh<T>(key, load);
  }

  Future<T> _refresh<T>(String key, Future<T> Function() load) {
    final running = _inFlight[key];
    if (running != null) return running.then((v) => v as T);
    final future = load().then((value) {
      final isEmptyList = value is List && value.isEmpty;
      if (!isEmptyList) _cache[key] = _CacheEntry(value, DateTime.now());
      return value;
    }).whenComplete(() {
      // Block body on purpose: `remove` returns this same future, and if the
      // callback returned it, whenComplete would wait on itself forever.
      _inFlight.remove(key);
    });
    _inFlight[key] = future;
    return future;
  }

  void _forget(String prefix) => _cache.removeWhere((k, _) => k.startsWith(prefix));

  Future<dynamic> _getData(String path) async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}$path')).timeout(_timeout);
    if (res.statusCode != 200) throw Exception('Request failed (${res.statusCode}): $path');
    final body = jsonDecode(res.body);
    if (body['success'] != true) throw Exception('Unexpected response: $path');
    return body['data'];
  }

  Future<List<LetterModel>> _letters(String key, String path) async {
    try {
      return await _cached(key, () async {
        final data = await _getData(path);
        return (data as List)
            .map((item) => _enrichWithLocalAssets(LetterModel.fromJson(item as Map<String, dynamic>)))
            .toList();
      });
    } catch (_) {
      return const []; // Letters are admin-managed only
    }
  }

  @override
  Future<List<LetterModel>> getAllAlphabets() => _letters('letters:all', '/letters?all=true');

  @override
  Future<List<LetterModel>> getUyirLetters() => _letters('letters:vowel', '/letters?type=vowel&all=true');

  @override
  Future<List<LetterModel>> getMeiLetters() => _letters('letters:consonant', '/letters?type=consonant&all=true');

  @override
  Future<LetterModel> getAythamLetter() async {
    final all = await getAllAlphabets();
    return all.isNotEmpty ? all.first : englishLettersList.first;
  }

  @override
  Future<List<LetterModel>> getUyirmeiByGroup(String meiBase) async => [];

  @override
  Future<List<String>> getMeiGroupBases() async => [];

  /// The first admin story with its pages. Throws when none can be loaded.
  @override
  Future<StoryModel> getFeaturedStory() => _cached('story:featured', () async {
        final list = await _getData('/stories') as List;
        if (list.isEmpty) throw Exception('No story available from server');
        final storyId = (list.first as Map<String, dynamic>)['id'];
        final detail = await _getData('/stories/$storyId');
        return StoryModel.fromJson(detail as Map<String, dynamic>);
      });

  @override
  Future<List<GameQuestion>> getGameQuestions() => _fallback.getGameQuestions();

  void clearVideoCache() => _forget('videos');

  @override
  Future<List<VideoItem>> getVideoLessons() async {
    try {
      return await _cached('videos', () async {
        final data = await _getData('/videos?all=true') as List;
        return data.map((item) => VideoItem.fromJson(item as Map<String, dynamic>)).toList();
      });
    } catch (_) {
      return const []; // Videos are admin-managed only
    }
  }

  void clearGamesCache() => _forget('games');

  /// Admin-managed games. Throws when the server can't be reached and nothing is cached.
  @override
  Future<List<GameItem>> getActiveGames() => _cached('games', () async {
        final data = await _getData('/games') as List;
        return data.map((item) => GameItem.fromJson(item as Map<String, dynamic>)).toList();
      });

  /// Admin-managed quizzes. Throws when the server can't be reached and nothing is cached.
  @override
  Future<List<QuizCategory>> getQuizCategories() => _cached('quizzes', () async {
        final data = await _getData('/quizzes') as List;
        return data
            .map((item) => QuizCategory.fromJson(item as Map<String, dynamic>))
            .where((q) => q.questionCount > 0)
            .toList();
      });

  /// Questions (with answers) for one admin quiz. Throws when the server can't be reached.
  @override
  Future<List<QuizQuestion>> getQuizQuestions(String categoryId) => _cached('quiz:$categoryId', () async {
        final data = await _getData('/quizzes/$categoryId/play') as Map<String, dynamic>;
        final questions = (data['questions'] as List?) ?? const [];
        return questions
            .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>, categoryId))
            .where((q) => q.options.length >= 2)
            .toList();
      });

  /// Loads everything in the background (after the first screen is shown) so
  /// tapping into Letters, Games, Quiz, Stories or Videos opens instantly.
  Future<void> prefetchAll() async {
    Future<void> quietly(Future<dynamic> Function() f) async {
      try {
        await f();
      } catch (_) {}
    }

    await Future.wait([
      quietly(getAllAlphabets),
      quietly(getUyirLetters),
      quietly(getMeiLetters),
      quietly(getActiveGames),
      quietly(getVideoLessons),
      quietly(getFeaturedStory),
      quietly(() async {
        final quizzes = await getQuizCategories();
        await Future.wait(quizzes.map((q) => quietly(() => getQuizQuestions(q.id))));
      }),
    ]);
  }

  void invalidateCache() => _cache.clear();
}

class _CacheEntry {
  final dynamic value;
  final DateTime storedAt;
  _CacheEntry(this.value, this.storedAt);
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

  /// Warm every screen's data in the background so navigation is instant.
  Future<void> prefetchAll() async {
    final repo = _repo;
    if (repo is ApiDataRepository) await repo.prefetchAll();
  }

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
