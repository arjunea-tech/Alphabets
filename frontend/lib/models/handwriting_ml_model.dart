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
        (confidence ?? 0.0) >= 0.70;
  }

  int get stars {
    if (!isMatch) return 0;
    final conf = confidence ?? 0.0;
    if (conf >= 0.85) return 3;
    if (conf >= 0.70) return 2;
    return 1;
  }

  String get feedbackTitle {
    if (modelStatus == MLModelStatus.modelFileRequired) {
      return 'Model Ready';
    }
    if (modelStatus == MLModelStatus.inferenceError) {
      return 'Try Again';
    }
    final pct = ((confidence ?? 0.0) * 100).round();
    if (isMatch) {
      return 'Correctly Written! ($pct%)';
    }
    return 'Needs Practice ($pct% / 70%)';
  }

  String get feedbackMessage {
    if (modelStatus == MLModelStatus.modelFileRequired) {
      return 'Handwriting practice is ready.';
    }
    if (modelStatus == MLModelStatus.inferenceError) {
      return errorMessage ?? 'Please try writing again.';
    }
    if (errorMessage != null && errorMessage!.isNotEmpty) {
      return errorMessage!;
    }
    if (isMatch) {
      return 'Excellent handwriting! You filled the letter properly!';
    }
    return 'Trace carefully inside the outlines to fill at least 80% of the letter.';
  }

  Color get badgeColor {
    if (isMatch) return const Color(0xFF10B981);
    return const Color(0xFFFF9F1C);
  }
}
