import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/avatar_model.dart';
import '../models/user_profile_model.dart';
import '../models/user_progress_model.dart';
import 'audio_service.dart';
import 'tamil_transliteration_service.dart';
import 'writing_practice_repository.dart';

class ProgressService extends ChangeNotifier {
  static const String _storageKey = 'agaram_user_progress';
  UserProgressModel _progress = const UserProgressModel();
  bool _isInitialized = false;
  int _childAge = 5;

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
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString(_storageKey);
      if (savedData != null) {
        final decoded = jsonDecode(savedData) as Map<String, dynamic>;
        _progress = UserProgressModel.fromJson(decoded);
      }

      // Sync with user profile repository if exists
      final userProfile = await LocalWritingPracticeRepository().getUserProfile();
      if (userProfile.name.isNotEmpty && userProfile.name != 'குழந்தை') {
        _progress = _progress.copyWith(
          childName: userProfile.name,
          avatarIndex: AppAvatar.getIndex(userProfile.avatarAsset),
        );
        _childAge = userProfile.age;
      } else if (_progress.childName.isNotEmpty && _progress.childName != 'குட்டி') {
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
    // Automatically transliterate English input to beautiful Tamil script
    final tamilName = TamilTransliterationService.toTamil(name.trim().isNotEmpty ? name.trim() : 'குட்டி');
    if (age != null) {
      _childAge = age;
    }

    _progress = _progress.copyWith(
      childName: tamilName,
      avatarIndex: avatarIndex,
    );
    notifyListeners();
    await _saveProgress();

    // Persist to user profile repository
    await LocalWritingPracticeRepository().saveUserProfile(
      UserProfile(
        id: 'child',
        name: tamilName,
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
    _progress = const UserProgressModel(stars: 10, childName: 'குட்டி', avatarIndex: 0);
    _childAge = 5;
    notifyListeners();
    await _saveProgress();
    await LocalWritingPracticeRepository().saveUserProfile(
      UserProfile(
        id: 'child',
        name: 'குட்டி',
        age: 5,
        avatarAsset: AppAvatar.getAssetPath(0),
        totalStars: 10,
        createdAt: DateTime.now(),
      ),
    );
  }
}
