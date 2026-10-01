import 'package:flutter/material.dart';

/// Status of the Tamil Handwriting ML Recognition Engine
enum MLModelStatus {
  notLoaded,
  loading,
  loaded,
  modelFileRequired,
  inferenceError,
}

/// A candidate letter prediction with confidence from the ML model
class CharacterConfidence {
  final String character;
  final double confidence; // 0.0 to 1.0

  const CharacterConfidence({
    required this.character,
    required this.confidence,
  });

  @override
  String toString() => '$character: ${(confidence * 100).toStringAsFixed(1)}%';
}

/// Result returned by the Tamil Handwriting ML Recognition Pipeline
class HandwritingRecognitionResult {
  final String expectedCharacter;
  final String? recognizedCharacter;
  final double? confidence; // 0.0 to 1.0, null if model not loaded
  final List<CharacterConfidence> topCandidates;
  final int strokeCount;
  final int totalPointCount;
  final MLModelStatus modelStatus;
  final String? errorMessage;
  final Duration inferenceTime;
  final bool? isMatchExplicit;

  const HandwritingRecognitionResult({
    required this.expectedCharacter,
    this.recognizedCharacter,
    this.confidence,
    this.topCandidates = const [],
    required this.strokeCount,
    required this.totalPointCount,
    required this.modelStatus,
    this.errorMessage,
    this.inferenceTime = Duration.zero,
    this.isMatchExplicit,
  });

  bool get isModelReady => modelStatus == MLModelStatus.loaded;

  bool get isMatch {
    if (isMatchExplicit != null) return isMatchExplicit!;
    return isModelReady &&
        recognizedCharacter != null &&
        recognizedCharacter == expectedCharacter &&
        (confidence ?? 0.0) >= 0.45;
  }

  int get stars {
    if (!isMatch) return 0;
    final conf = confidence ?? 0.0;
    if (conf >= 0.70) return 3;
    if (conf >= 0.50) return 2;
    return 1;
  }

  String get feedbackTitle {
    if (modelStatus == MLModelStatus.modelFileRequired) {
      return 'மாதிரி தயார்நிலை';
    }
    if (modelStatus == MLModelStatus.inferenceError) {
      return 'மீண்டும் முயற்சி செய்க';
    }
    if (isMatch) {
      return 'சரியாக எழுதினீர்கள்!';
    }
    return 'மீண்டும் முயற்சி செய்க!';
  }

  String get feedbackMessage {
    if (modelStatus == MLModelStatus.modelFileRequired) {
      return 'கையெழுத்துப் பயிற்சி தயார் நிலையில் உள்ளது.';
    }
    if (modelStatus == MLModelStatus.inferenceError) {
      return errorMessage ?? 'மீண்டும் ஒருமுறை எழுதிப் பாருங்கள்.';
    }
    if (isMatch) {
      return 'மிகச் சிறப்பாக எழுதியுள்ளீர்கள்!';
    }
    return 'எழுத்தை மீண்டும் ஒருமுறை கவனமாக எழுதிப் பாருங்கள்.';
  }

  Color get badgeColor {
    if (isMatch) return const Color(0xFF10B981);
    return const Color(0xFFFF9F1C);
  }
}
