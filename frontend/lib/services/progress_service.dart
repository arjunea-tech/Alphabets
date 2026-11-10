import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/avatar_model.dart';
import '../models/user_profile_model.dart';
import '../models/user_progress_model.dart';
import 'audio_service.dart';
import 'writing_practice_repository.dart';

class ProgressService extends ChangeNotifier {
  static const String _storageKey = 'agaram_user_progress';
  UserProgressModel _progress = const UserProgressModel();
  bool _isInitialized = false;
  int _childAge = 5;
  late final Future<void> _initialization;

  UserProgressModel get progress => _progress;
  bool get isInitialized => _isInitialized;

  int get stars => _progress.stars;
  int get completedLettersCount => _progress.completedLetterIds.length;
  int get completedStoriesCount => _progress.completedStories;
  int get quizHighScore => _progress.quizHighScore;
  String get childName => _progress.childName;
  int get avatarIndex => _progress.avatarIndex;
  String get avatarAsset => AppAvatar.getAssetPath(_progress.avatarIndex);
  int get childAge => _childAge;
  bool get soundEnabled => _progress.soundEnabled;

  ProgressService() {
    _initialization = _loadProgress();
  }

  /// Converts any Tamil-script or stored name to clean English name for the kid
  static String toEnglishName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == 'Kid' || trimmed == 'Little Learner') {
      return 'Arjun';
    }

    // Specific user match: ஆர்ஜனய் or அர்ஜுன் -> Arjun
    if (trimmed == 'ஆர்ஜனய்' || trimmed == 'அர்ஜுன்' || trimmed.toLowerCase() == 'arjun') {
      return 'Arjun';
    }

    // High-frequency Tamil names reverse lookup
    const Map<String, String> reverseTamilNames = {
      'ஆர்ஜனய்': 'Arjun',
      'அர்ஜுன்': 'Arjun',
      'செல்வா': 'Selva',
      'செல்வன்': 'Selvan',
      'செல்வி': 'Selvi',
      'செல்வம்': 'Selvam',
      'செல்வராஜ்': 'Selvaraj',
      'கவின்': 'Kavin',
      'காவ்யா': 'Kavya',
      'கவி': 'Kavi',
      'கவிதா': 'Kavitha',
      'கார்த்திக்': 'Karthik',
      'கார்த்திகா': 'Karthika',
      'மித்ரன்': 'Mithran',
      'மித்ரா': 'Mithra',
      'குமார்': 'Kumar',
      'குமரன்': 'Kumaran',
      'பிரியா': 'Priya',
      'அன்பு': 'Anbu',
      'ராம்': 'Ram',
      'ராமன்': 'Raman',
      'ராகுல்': 'Rahul',
      'தருண்': 'Tarun',
      'சஞ்சய்': 'Sanjay',
      'சூர்யா': 'Surya',
      'விக்னேஷ்': 'Vignesh',
      'விக்ரம்': 'Vikram',
      'திவ்யா': 'Divya',
      'தீபா': 'Deepa',
      'தீபக்': 'Deepak',
      'வருண்': 'Varun',
      'அருண்': 'Arun',
      'அரவிந்த்': 'Aravind',
      'நிலா': 'Nila',
      'கயல்': 'Kayal',
      'மணி': 'Mani',
      'முருகன்': 'Murugan',
      'பாலா': 'Bala',
      'பாரத்': 'Bharat',
      'பாரதி': 'Bharathi',
      'சரண்': 'Charan',
      'தனுஷ்': 'Dhanush',
      'தினேஷ்': 'Dinesh',
      'கணேஷ்': 'Ganesh',
      'காயத்ரி': 'Gayathri',
      'கீதா': 'Geetha',
      'கோகுல்': 'Gokul',
      'ஹரி': 'Hari',
      'ஹரிஷ்': 'Harish',
      'ஜனனி': 'Janani',
      'ஜீவா': 'Jeeva',
      'கண்ணன்': 'Kannan',
      'கிருஷ்ணா': 'Krishna',
      'லட்சுமி': 'Lakshmi',
      'மாதவ்': 'Madhav',
      'மகேஷ்': 'Mahesh',
      'மனோஜ்': 'Manoj',
      'மோகன்': 'Mohan',
      'நவீன்': 'Naveen',
      'பூஜா': 'Pooja',
      'பிரவீன்': 'Praveen',
      'ராஜா': 'Raja',
      'ராஜேஷ்': 'Rajesh',
      'சினேகா': 'Sneha',
      'சுஜாதா': 'Sujatha',
      'விஜய்': 'Vijay',
      'வினோத்': 'Vinoth',
      'யுவன்': 'Yuvan',
    };

    if (reverseTamilNames.containsKey(trimmed)) {
      return reverseTamilNames[trimmed]!;
    }

    // If it contains Tamil script, systematically transliterate to English phonetics
    if (trimmed.contains(RegExp(r'[\u0B80-\u0BFF]'))) {
      final buffer = StringBuffer();
      for (int i = 0; i < trimmed.length; i++) {
        final c = trimmed[i];
        switch (c) {
          case 'அ': buffer.write('A'); break;
          case 'ஆ': buffer.write('Aa'); break;
          case 'இ': buffer.write('I'); break;
          case 'ஈ': buffer.write('Ee'); break;
          case 'உ': buffer.write('U'); break;
          case 'ஊ': buffer.write('Oo'); break;
          case 'எ': buffer.write('E'); break;
          case 'ஏ': buffer.write('Ae'); break;
          case 'ஐ': buffer.write('Ai'); break;
          case 'ஒ': buffer.write('O'); break;
          case 'ஓ': buffer.write('Oo'); break;
          case 'ஔ': buffer.write('Au'); break;
          case 'க': buffer.write('k'); break;
          case 'ங': buffer.write('ng'); break;
          case 'ச': buffer.write('s'); break;
          case 'ஞ': buffer.write('nj'); break;
          case 'ட': buffer.write('t'); break;
          case 'ண': buffer.write('n'); break;
          case 'த': buffer.write('th'); break;
          case 'ந': buffer.write('n'); break;
          case 'ப': buffer.write('p'); break;
          case 'ம': buffer.write('m'); break;
          case 'ய': buffer.write('y'); break;
          case 'ர': buffer.write('r'); break;
          case 'ல': buffer.write('l'); break;
          case 'வ': buffer.write('v'); break;
          case 'ழ': buffer.write('zh'); break;
          case 'ள': buffer.write('l'); break;
          case 'ற': buffer.write('r'); break;
          case 'ன': buffer.write('n'); break;
          case 'ஜ': buffer.write('j'); break;
          case 'ஷ': buffer.write('sh'); break;
          case 'ஸ': buffer.write('s'); break;
          case 'ஹ': buffer.write('h'); break;
          case '\u0BBE': buffer.write('a'); break;
          case '\u0BBF': buffer.write('i'); break;
          case '\u0BC0': buffer.write('ee'); break;
          case '\u0BC1': buffer.write('u'); break;
          case '\u0BC2': buffer.write('oo'); break;
          case '\u0BC6': buffer.write('e'); break;
          case '\u0BC7': buffer.write('e'); break;
          case '\u0BC8': buffer.write('ai'); break;
          case '\u0BCA': buffer.write('o'); break;
          case '\u0BCB': buffer.write('o'); break;
          case '\u0BCD': break;
          default: break;
        }
      }
      final res = buffer.toString().trim();
      if (res.isNotEmpty) {
        return res[0].toUpperCase() + (res.length > 1 ? res.substring(1) : '');
      }
      return 'Arjun';
    }

    return trimmed[0].toUpperCase() + (trimmed.length > 1 ? trimmed.substring(1) : '');
  }

  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString(_storageKey);
      if (savedData != null) {
        final decoded = jsonDecode(savedData) as Map<String, dynamic>;
        _progress = UserProgressModel.fromJson(decoded);
      }

      // Convert any legacy Tamil script name to English
      final convertedProgressName = toEnglishName(_progress.childName);
      if (convertedProgressName != _progress.childName) {
        _progress = _progress.copyWith(childName: convertedProgressName);
        await _saveProgress();
      }

      // Sync with user profile repository if exists
      final userProfile = await LocalWritingPracticeRepository().getUserProfile();
      final convertedProfileName = toEnglishName(userProfile.name);
      if (convertedProfileName.isNotEmpty && convertedProfileName != 'Kid') {
        _progress = _progress.copyWith(
          childName: convertedProfileName,
          avatarIndex: AppAvatar.getIndex(userProfile.avatarAsset),
        );
        _childAge = userProfile.age;

        // Persist English name back to repo if it was in Tamil
        if (convertedProfileName != userProfile.name) {
          await LocalWritingPracticeRepository().saveUserProfile(
            userProfile.copyWith(name: convertedProfileName),
          );
        }
      } else if (_progress.childName.isNotEmpty && _progress.childName != 'Kid') {
        // Save back to repository
        await LocalWritingPracticeRepository().saveUserProfile(
          UserProfile(
            id: 'child',
            name: _progress.childName,
            age: _childAge,
            avatarAsset: AppAvatar.getAssetPath(_progress.avatarIndex),
            totalStars: _progress.stars,
            createdAt: DateTime.now(),
          ),
        );
      }

      AudioService.instance.setMuted(!_progress.soundEnabled);
    } catch (e) {
      debugPrint('Error loading user progress: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_progress.toJson()));
    } catch (e) {
      debugPrint('Error saving user progress: $e');
    }
  }

  void addStars(int count) {
    _progress = _progress.copyWith(stars: _progress.stars + count);
    notifyListeners();
    _saveProgress();
  }

  void markLetterCompleted(String letterId) {
    if (!_progress.completedLetterIds.contains(letterId)) {
      final updatedList = List<String>.from(_progress.completedLetterIds)..add(letterId);
      _progress = _progress.copyWith(
        completedLetterIds: updatedList,
        stars: _progress.stars + 2, // 2 stars bonus for learning a letter!
      );
      notifyListeners();
      _saveProgress();
    }
  }

  bool isLetterCompleted(String letterId) {
    return _progress.completedLetterIds.contains(letterId);
  }

  void completeStory() {
    _progress = _progress.copyWith(
      completedStories: _progress.completedStories + 1,
      stars: _progress.stars + 5, // 5 stars reward for reading story!
    );
    notifyListeners();
    _saveProgress();
  }

  void recordQuizScore(int score, int starsEarned) {
    final newHigh = score > _progress.quizHighScore ? score : _progress.quizHighScore;
    _progress = _progress.copyWith(
      quizHighScore: newHigh,
      stars: _progress.stars + starsEarned,
    );
    notifyListeners();
    _saveProgress();
  }

  void recordGameCompleted(int starsEarned) {
    _progress = _progress.copyWith(
      gamesPlayed: _progress.gamesPlayed + 1,
      stars: _progress.stars + starsEarned,
    );
    notifyListeners();
    _saveProgress();
  }

  Future<void> updateProfile({
    required String name,
    required int avatarIndex,
    int? age,
  }) async {
    await _initialization;

    final cleanEnglishName = toEnglishName(name.isNotEmpty ? name : 'Arjun');
    if (age != null) {
      _childAge = age;
    }

    _progress = _progress.copyWith(
      childName: cleanEnglishName,
      avatarIndex: avatarIndex,
    );
    notifyListeners();
    await _saveProgress();

    // Persist to user profile repository
    await LocalWritingPracticeRepository().saveUserProfile(
      UserProfile(
        id: 'child',
        name: cleanEnglishName,
        age: _childAge,
        avatarAsset: AppAvatar.getAssetPath(avatarIndex),
        totalStars: _progress.stars,
        createdAt: DateTime.now(),
      ),
    );
  }

  void toggleSound(bool enabled) {
    _progress = _progress.copyWith(soundEnabled: enabled);
    AudioService.instance.setMuted(!enabled);
    notifyListeners();
    _saveProgress();
  }

  Future<void> resetProgress() async {
    _progress = const UserProgressModel(stars: 10, childName: 'Arjun', avatarIndex: 0);
    _childAge = 5;
    notifyListeners();
    await _saveProgress();
    await LocalWritingPracticeRepository().saveUserProfile(
      UserProfile(
        id: 'child',
        name: 'Arjun',
        age: 5,
        avatarAsset: AppAvatar.getAssetPath(0),
        totalStars: 10,
        createdAt: DateTime.now(),
      ),
    );
  }
}
