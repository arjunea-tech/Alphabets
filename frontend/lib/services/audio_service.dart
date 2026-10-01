import 'package:flutter/material.dart';
import 'tamil_audio_service.dart';
import 'tamil_tts_service.dart';

/// Legacy AudioService adapter that delegates all audio operations
/// to the single centralized TamilAudioService.
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  static AudioService get instance => _instance;

  AudioService._internal();

  bool get isMuted => TamilAudioService.instance.isMuted;

  void setMuted(bool muted) {
    TamilAudioService.instance.setMuted(muted);
    TamilTtsService.instance.setMuted(muted);
  }

  /// Maps letter or sound key to audio asset path
  static String getAudioPathForLetter(String letter) {
    return TamilAudioService.getAudioPath(letter) ?? 'assets/audio/tamil/uyirmei/$letter.mp3';
  }

  /// Main Centralized Audio API
  Future<void> playTamilAudio(String text) async {
    await TamilAudioService.instance.playTamilAudio(text);
  }

  /// Plays pronunciation for a Tamil letter or word.
  Future<void> playLetterSound(
    BuildContext context, {
    required String letter,
    String? word,
    String? audioPath,
    bool showIndicator = true,
  }) async {
    await TamilAudioService.instance.playLetterSound(
      context,
      letter: letter,
      word: word,
      audioPath: audioPath,
      showIndicator: showIndicator,
    );
  }

  /// Displays floating audio indicator with speaker icon
  void showFriendlyAudioIndicator(
    BuildContext context,
    String text, [
    String? subtext,
  ]) {
    TamilAudioService.showAudioIndicator(
      context,
      text: text,
      subtext: subtext,
    );
  }

  /// Speaks any Tamil text (letter, word, sentence, story, quiz question).
  Future<void> speakText(String? text, {String? fallbackTamilText}) async {
    await TamilAudioService.instance.playTamilAudio(text, fallbackTamilText: fallbackTamilText);
  }

  /// Stops all audio playback.
  Future<void> stopAll() async {
    await TamilAudioService.instance.stopAll();
  }

  /// Plays cheerful sound effect for rewards or right answers.
  Future<void> playSuccessFeedback(BuildContext context) async {
    await TamilAudioService.instance.playSuccessFeedback(context);
  }

  /// Plays star award sound
  Future<void> playStarReward(BuildContext context) async {
    await TamilAudioService.instance.playStarReward(context);
  }

  /// Plays gentle retry effect.
  Future<void> playRetryFeedback(BuildContext context) async {
    await TamilAudioService.instance.playRetryFeedback(context);
  }

  void dispose() {
    TamilAudioService.instance.dispose();
  }
}
