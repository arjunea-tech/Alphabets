import 'package:shared_preferences/shared_preferences.dart';
import '../models/writing_practice_model.dart';
import '../models/user_profile_model.dart';

/// Abstract repository defining contracts for saving and retrieving writing practices.
/// This allows future drop-in replacement with a REST API / Node.js / MySQL backend.
abstract class WritingPracticeRepository {
  Future<void> savePractice(WritingPractice practice);
  Future<List<WritingPractice>> getPracticeHistory();
  Future<List<WritingPractice>> getPracticesForLetter(String letter);
  Future<int> getAttemptCountForLetter(String letter);
  Future<void> deletePractice(String id);
  Future<void> clearHistory();

  Future<UserProfile> getUserProfile();
  Future<void> saveUserProfile(UserProfile profile);
  Future<int> getPracticedLettersCount();
  Future<int> getTotalPracticesCount();
}

/// Concrete local storage implementation using SharedPreferences and JSON.
class LocalWritingPracticeRepository implements WritingPracticeRepository {
  static const String _keyPractices = 'agaram_writing_practices';
  static const String _keyProfile = 'agaram_user_profile';

  // Singleton instance
  static final LocalWritingPracticeRepository _instance =
      LocalWritingPracticeRepository._internal();
  factory LocalWritingPracticeRepository() => _instance;
  LocalWritingPracticeRepository._internal();

  @override
  Future<void> savePractice(WritingPractice practice) async {
    final prefs = await SharedPreferences.getInstance();
    final currentList = await getPracticeHistory();

    // Prepend new practice (newest first)
    final updatedList = [practice, ...currentList];

    // Persist up to 200 recent writing attempts locally
    final trimmedList = updatedList.take(200).toList();
    final jsonStr = WritingPractice.listToJson(trimmedList);
    await prefs.setString(_keyPractices, jsonStr);
  }

  @override
  Future<List<WritingPractice>> getPracticeHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyPractices) ?? '';
    return WritingPractice.listFromJson(jsonStr);
  }

  @override
  Future<List<WritingPractice>> getPracticesForLetter(String letter) async {
    final history = await getPracticeHistory();
    return history.where((p) => p.letter == letter).toList();
  }

  @override
  Future<int> getAttemptCountForLetter(String letter) async {
    final practices = await getPracticesForLetter(letter);
    return practices.length;
  }

  @override
  Future<void> deletePractice(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final currentList = await getPracticeHistory();
    final updatedList = currentList.where((p) => p.id != id).toList();
    await prefs.setString(_keyPractices, WritingPractice.listToJson(updatedList));
  }

  @override
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPractices);
  }

  @override
  Future<UserProfile> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyProfile) ?? '';
    if (jsonStr.isEmpty) {
      return UserProfile.defaultProfile();
    }
    return UserProfile.fromJsonString(jsonStr);
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfile, profile.toJsonString());
  }

  @override
  Future<int> getPracticedLettersCount() async {
    final history = await getPracticeHistory();
    final uniqueLetters = history.map((p) => p.letter).toSet();
    return uniqueLetters.length;
  }

  @override
  Future<int> getTotalPracticesCount() async {
    final history = await getPracticeHistory();
    return history.length;
  }
}
