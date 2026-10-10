import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart' show Offset, Size;
import '../models/handwriting_ml_model.dart';
import 'stroke_preprocessor.dart';

/// Zone box definition in normalized [0.0, 1.0] coordinates
class ZoneConstraint {
  final double xMin;
  final double yMin;
  final double xMax;
  final double yMax;
  final int minPts;
  final String name;

  const ZoneConstraint({
    required this.xMin,
    required this.yMin,
    required this.xMax,
    required this.yMax,
    this.minPts = 3,
    required this.name,
  });

  bool contains(Point2D pt) {
    return pt.x >= xMin && pt.x <= xMax && pt.y >= yMin && pt.y <= yMax;
  }
}

class Point2D {
  final double x;
  final double y;
  const Point2D(this.x, this.y);

  double distanceTo(Point2D other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }
}

class LetterSkeleton {
  final List<List<Point2D>> strokes;
  final List<ZoneConstraint> requiredZones;
  final List<ZoneConstraint> forbiddenZones;

  const LetterSkeleton({
    required this.strokes,
    this.requiredZones = const [],
    this.forbiddenZones = const [],
  });
}

/// Production Structural Vector Path & Zone Handwriting Verification Engine
class TamilHandwritingRecognitionService {
  static final TamilHandwritingRecognitionService _instance =
      TamilHandwritingRecognitionService._internal();

  factory TamilHandwritingRecognitionService() => _instance;
  static TamilHandwritingRecognitionService get instance => _instance;

  TamilHandwritingRecognitionService._internal();

  static const int inputDimension = 32;

  /// Ordered 31 class labels matching Tamil Alphabet
  static const List<String> defaultSupportedClasses = [
    'அ', 'ஆ', 'இ', 'ஈ', 'உ', 'ஊ', 'எ', 'ஏ', 'ஐ', 'ஒ', 'ஓ', 'ஔ',
    'க்', 'ங்', 'ச்', 'ஞ்', 'ட்', 'ண்', 'த்', 'ந்', 'ப்', 'ம்',
    'ய்', 'ர்', 'ல்', 'வ்', 'ழ்', 'ள்', 'ற்', 'ன்',
    'ஃ',
  ];

  final List<String> _labels = List.from(defaultSupportedClasses);
  List<String> get supportedClasses => List.unmodifiable(_labels);

  final StrokePreprocessor _preprocessor = const StrokePreprocessor(targetDimension: inputDimension);
  StrokePreprocessor get preprocessor => _preprocessor;

  MLModelStatus _status = MLModelStatus.loaded;
  MLModelStatus get status => _status;

  String? _lastErrorMessage;
  String? get lastErrorMessage => _lastErrorMessage;

  bool _initialized = true;
  bool get isModelAvailable => _initialized;

  Future<void> initialize() async {
    _initialized = true;
    _status = MLModelStatus.loaded;
  }

  /// Returns the primary reference skeleton for the letter (used for route rendering & demo animation)
  static LetterSkeleton? getPrimarySkeleton(String letter) {
    final list = _skeletons[letter];
    if (list != null && list.isNotEmpty) return list.first;
    return null;
  }

  /// Returns all reference skeletons for the letter
  static List<LetterSkeleton>? getAllSkeletons(String letter) {
    return _skeletons[letter];
  }

  // Pre-compiled 31 Letter Skeletons & Geometric Constraints (supports multi-variant styles)
  static final Map<String, List<LetterSkeleton>> _skeletons = {
    'அ': const [
      // Standard 3-stroke 'அ'
      LetterSkeleton(
        strokes: [
          [Point2D(0.42, 0.22), Point2D(0.36, 0.20), Point2D(0.32, 0.26), Point2D(0.38, 0.32), Point2D(0.48, 0.28), Point2D(0.58, 0.25), Point2D(0.62, 0.35), Point2D(0.58, 0.46)],
          [Point2D(0.58, 0.46), Point2D(0.45, 0.55), Point2D(0.32, 0.65), Point2D(0.24, 0.76), Point2D(0.32, 0.82), Point2D(0.48, 0.80), Point2D(0.70, 0.78)],
          [Point2D(0.45, 0.55), Point2D(0.70, 0.55)],
          [Point2D(0.70, 0.20), Point2D(0.70, 0.80)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.28, yMin: 0.15, xMax: 0.68, yMax: 0.45, minPts: 3, name: 'அ_top_loop'),
          ZoneConstraint(xMin: 0.16, yMin: 0.50, xMax: 0.58, yMax: 0.88, minPts: 3, name: 'அ_bottom_loop'),
          ZoneConstraint(xMin: 0.58, yMin: 0.20, xMax: 0.82, yMax: 0.82, minPts: 3, name: 'அ_right_stem'),
        ],
        forbiddenZones: [
          ZoneConstraint(xMin: 0.78, yMin: 0.70, xMax: 1.00, yMax: 1.00, minPts: 4, name: 'ஆ_tail'),
        ],
      ),
      // Single-stroke cursive 'அ'
      LetterSkeleton(
        strokes: [
          [Point2D(0.42, 0.22), Point2D(0.36, 0.20), Point2D(0.32, 0.26), Point2D(0.38, 0.32), Point2D(0.48, 0.28), Point2D(0.58, 0.25), Point2D(0.62, 0.35), Point2D(0.58, 0.46), Point2D(0.45, 0.55), Point2D(0.32, 0.65), Point2D(0.24, 0.76), Point2D(0.32, 0.82), Point2D(0.48, 0.80), Point2D(0.70, 0.55), Point2D(0.70, 0.20), Point2D(0.70, 0.80)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.28, yMin: 0.15, xMax: 0.68, yMax: 0.45, minPts: 3, name: 'அ_top_loop'),
          ZoneConstraint(xMin: 0.16, yMin: 0.50, xMax: 0.58, yMax: 0.88, minPts: 3, name: 'அ_bottom_loop'),
          ZoneConstraint(xMin: 0.58, yMin: 0.20, xMax: 0.82, yMax: 0.82, minPts: 3, name: 'அ_right_stem'),
        ],
        forbiddenZones: [
          ZoneConstraint(xMin: 0.78, yMin: 0.70, xMax: 1.00, yMax: 1.00, minPts: 4, name: 'ஆ_tail'),
        ],
      ),
    ],
    'ஆ': const [
      // Standard 4-stroke 'ஆ'
      LetterSkeleton(
        strokes: [
          [Point2D(0.42, 0.22), Point2D(0.36, 0.20), Point2D(0.32, 0.26), Point2D(0.38, 0.32), Point2D(0.48, 0.28), Point2D(0.58, 0.25), Point2D(0.62, 0.35), Point2D(0.58, 0.46)],
          [Point2D(0.58, 0.46), Point2D(0.45, 0.55), Point2D(0.32, 0.65), Point2D(0.24, 0.76), Point2D(0.32, 0.82), Point2D(0.48, 0.80), Point2D(0.70, 0.78)],
          [Point2D(0.45, 0.55), Point2D(0.70, 0.55)],
          [Point2D(0.70, 0.20), Point2D(0.70, 0.74), Point2D(0.80, 0.82), Point2D(0.85, 0.78), Point2D(0.81, 0.72), Point2D(0.70, 0.74)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.28, yMin: 0.15, xMax: 0.68, yMax: 0.45, minPts: 3, name: 'ஆ_top_loop'),
          ZoneConstraint(xMin: 0.16, yMin: 0.50, xMax: 0.58, yMax: 0.88, minPts: 3, name: 'ஆ_bottom_loop'),
          ZoneConstraint(xMin: 0.58, yMin: 0.20, xMax: 0.82, yMax: 0.74, minPts: 3, name: 'ஆ_right_stem'),
          ZoneConstraint(xMin: 0.65, yMin: 0.65, xMax: 0.95, yMax: 0.92, minPts: 3, name: 'ஆ_tail'),
        ],
      ),
      // Single-stroke cursive 'ஆ'
      LetterSkeleton(
        strokes: [
          [Point2D(0.42, 0.22), Point2D(0.36, 0.20), Point2D(0.32, 0.26), Point2D(0.38, 0.32), Point2D(0.48, 0.28), Point2D(0.58, 0.25), Point2D(0.62, 0.35), Point2D(0.58, 0.46), Point2D(0.45, 0.55), Point2D(0.32, 0.65), Point2D(0.24, 0.76), Point2D(0.32, 0.82), Point2D(0.48, 0.80), Point2D(0.70, 0.55), Point2D(0.70, 0.20), Point2D(0.70, 0.74), Point2D(0.80, 0.82), Point2D(0.85, 0.78), Point2D(0.81, 0.72), Point2D(0.70, 0.74)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.28, yMin: 0.15, xMax: 0.68, yMax: 0.45, minPts: 3, name: 'ஆ_top_loop'),
          ZoneConstraint(xMin: 0.16, yMin: 0.50, xMax: 0.58, yMax: 0.88, minPts: 3, name: 'ஆ_bottom_loop'),
          ZoneConstraint(xMin: 0.58, yMin: 0.20, xMax: 0.82, yMax: 0.74, minPts: 3, name: 'ஆ_right_stem'),
          ZoneConstraint(xMin: 0.65, yMin: 0.65, xMax: 0.95, yMax: 0.92, minPts: 3, name: 'ஆ_tail'),
        ],
      ),
    ],
    'இ': const [
      // Standard enclosing-arch handwritten 'இ' (as in school notebooks and user drawings)
      LetterSkeleton(
        strokes: [
          [Point2D(0.42, 0.38), Point2D(0.36, 0.30), Point2D(0.40, 0.22), Point2D(0.52, 0.22), Point2D(0.62, 0.28), Point2D(0.60, 0.40), Point2D(0.45, 0.50), Point2D(0.32, 0.60), Point2D(0.24, 0.72), Point2D(0.35, 0.82), Point2D(0.55, 0.82), Point2D(0.72, 0.75)],
          [Point2D(0.24, 0.72), Point2D(0.18, 0.45), Point2D(0.30, 0.18), Point2D(0.60, 0.14), Point2D(0.85, 0.25), Point2D(0.90, 0.55), Point2D(0.88, 0.80)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.20, yMin: 0.10, xMax: 0.72, yMax: 0.52, minPts: 3, name: 'இ_top_loop'),
          ZoneConstraint(xMin: 0.18, yMin: 0.50, xMax: 0.85, yMax: 0.90, minPts: 3, name: 'இ_bottom_wave'),
        ],
      ),
      // Single continuous cursive 'இ'
      LetterSkeleton(
        strokes: [
          [Point2D(0.42, 0.38), Point2D(0.36, 0.30), Point2D(0.40, 0.22), Point2D(0.52, 0.22), Point2D(0.62, 0.28), Point2D(0.60, 0.40), Point2D(0.45, 0.50), Point2D(0.32, 0.60), Point2D(0.24, 0.72), Point2D(0.35, 0.82), Point2D(0.55, 0.82), Point2D(0.72, 0.75), Point2D(0.80, 0.60), Point2D(0.75, 0.30), Point2D(0.60, 0.14), Point2D(0.30, 0.18), Point2D(0.18, 0.45), Point2D(0.24, 0.72)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.20, yMin: 0.10, xMax: 0.72, yMax: 0.52, minPts: 3, name: 'இ_top_loop'),
          ZoneConstraint(xMin: 0.18, yMin: 0.50, xMax: 0.85, yMax: 0.90, minPts: 3, name: 'இ_bottom_wave'),
        ],
      ),
      // Simplified print 'இ'
      LetterSkeleton(
        strokes: [
          [Point2D(0.40, 0.22), Point2D(0.34, 0.20), Point2D(0.31, 0.25), Point2D(0.37, 0.31), Point2D(0.45, 0.28), Point2D(0.57, 0.25), Point2D(0.65, 0.31), Point2D(0.68, 0.40)],
          [Point2D(0.68, 0.40), Point2D(0.62, 0.48), Point2D(0.48, 0.51), Point2D(0.37, 0.57), Point2D(0.31, 0.65), Point2D(0.37, 0.74), Point2D(0.48, 0.74), Point2D(0.62, 0.71), Point2D(0.71, 0.74)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.20, yMin: 0.12, xMax: 0.70, yMax: 0.50, minPts: 3, name: 'இ_top_loop'),
          ZoneConstraint(xMin: 0.20, yMin: 0.50, xMax: 0.80, yMax: 0.88, minPts: 3, name: 'இ_bottom_wave'),
        ],
      ),
    ],
    'ஈ': const [
      LetterSkeleton(
        strokes: [
          [Point2D(0.30, 0.22), Point2D(0.30, 0.78)],
          [Point2D(0.24, 0.22), Point2D(0.70, 0.22), Point2D(0.70, 0.78)],
          [Point2D(0.50, 0.51)],
          [Point2D(0.83, 0.51)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.18, yMin: 0.20, xMax: 0.42, yMax: 0.80, minPts: 2, name: 'ஈ_left_stem'),
          ZoneConstraint(xMin: 0.58, yMin: 0.20, xMax: 0.84, yMax: 0.80, minPts: 2, name: 'ஈ_right_stem'),
        ],
      ),
      LetterSkeleton(
        strokes: [
          [Point2D(0.30, 0.22), Point2D(0.30, 0.78)],
          [Point2D(0.24, 0.22), Point2D(0.70, 0.22)],
          [Point2D(0.70, 0.22), Point2D(0.70, 0.78)],
          [Point2D(0.50, 0.51)],
          [Point2D(0.83, 0.51)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.18, yMin: 0.20, xMax: 0.42, yMax: 0.80, minPts: 2, name: 'ஈ_left_stem'),
          ZoneConstraint(xMin: 0.58, yMin: 0.20, xMax: 0.84, yMax: 0.80, minPts: 2, name: 'ஈ_right_stem'),
        ],
      ),
    ],
    'உ': const [
      LetterSkeleton(
        strokes: [
          [Point2D(0.31, 0.34), Point2D(0.25, 0.30), Point2D(0.21, 0.34), Point2D(0.25, 0.38), Point2D(0.31, 0.35), Point2D(0.41, 0.25), Point2D(0.51, 0.25), Point2D(0.55, 0.35), Point2D(0.55, 0.45)],
          [Point2D(0.55, 0.45), Point2D(0.48, 0.60), Point2D(0.35, 0.71), Point2D(0.28, 0.78), Point2D(0.74, 0.78)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.18, yMin: 0.20, xMax: 0.58, yMax: 0.48, minPts: 3, name: 'உ_top_loop'),
          ZoneConstraint(xMin: 0.25, yMin: 0.65, xMax: 0.85, yMax: 0.88, minPts: 3, name: 'உ_base'),
        ],
        forbiddenZones: [
          ZoneConstraint(xMin: 0.65, yMin: 0.15, xMax: 0.92, yMax: 0.50, minPts: 5, name: 'top_la'),
        ],
      ),
    ],
    'ஊ': const [
      LetterSkeleton(
        strokes: [
          [Point2D(0.25, 0.40), Point2D(0.21, 0.35), Point2D(0.17, 0.40), Point2D(0.21, 0.44), Point2D(0.25, 0.41), Point2D(0.35, 0.32), Point2D(0.45, 0.32), Point2D(0.48, 0.41), Point2D(0.48, 0.50)],
          [Point2D(0.48, 0.50), Point2D(0.42, 0.62), Point2D(0.30, 0.71), Point2D(0.24, 0.78), Point2D(0.60, 0.78)],
          [Point2D(0.62, 0.34), Point2D(0.58, 0.31), Point2D(0.57, 0.34), Point2D(0.60, 0.37), Point2D(0.65, 0.35), Point2D(0.71, 0.31), Point2D(0.74, 0.37), Point2D(0.74, 0.51), Point2D(0.65, 0.60), Point2D(0.77, 0.60)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.58, yMin: 0.15, xMax: 0.92, yMax: 0.52, minPts: 3, name: 'top_la'),
          ZoneConstraint(xMin: 0.15, yMin: 0.55, xMax: 0.65, yMax: 0.88, minPts: 3, name: 'u_base'),
        ],
      ),
    ],
    'எ': const [
      LetterSkeleton(
        strokes: [
          [Point2D(0.34, 0.51), Point2D(0.28, 0.47), Point2D(0.25, 0.51), Point2D(0.30, 0.55), Point2D(0.34, 0.52), Point2D(0.37, 0.31), Point2D(0.65, 0.31)],
          [Point2D(0.65, 0.31), Point2D(0.65, 0.78)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.18, yMin: 0.35, xMax: 0.48, yMax: 0.65, minPts: 2, name: 'எ_loop'),
          ZoneConstraint(xMin: 0.28, yMin: 0.22, xMax: 0.75, yMax: 0.40, minPts: 2, name: 'எ_top_bar'),
          ZoneConstraint(xMin: 0.55, yMin: 0.28, xMax: 0.78, yMax: 0.85, minPts: 3, name: 'எ_right_stem'),
        ],
        forbiddenZones: [
          ZoneConstraint(xMin: 0.12, yMin: 0.65, xMax: 0.35, yMax: 0.88, minPts: 4, name: 'slant_tail'),
        ],
      ),
    ],
    'ஏ': const [
      LetterSkeleton(
        strokes: [
          [Point2D(0.34, 0.51), Point2D(0.28, 0.47), Point2D(0.25, 0.51), Point2D(0.30, 0.55), Point2D(0.34, 0.52), Point2D(0.37, 0.31), Point2D(0.65, 0.31)],
          [Point2D(0.65, 0.31), Point2D(0.65, 0.78)],
          [Point2D(0.34, 0.52), Point2D(0.18, 0.80)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.12, yMin: 0.62, xMax: 0.38, yMax: 0.88, minPts: 2, name: 'slant_tail'),
          ZoneConstraint(xMin: 0.55, yMin: 0.28, xMax: 0.78, yMax: 0.85, minPts: 3, name: 'ஏ_right_stem'),
        ],
      ),
    ],
    'ஐ': const [
      LetterSkeleton(
        strokes: [
          [Point2D(0.28, 0.31), Point2D(0.24, 0.28), Point2D(0.22, 0.32), Point2D(0.27, 0.35), Point2D(0.22, 0.40), Point2D(0.27, 0.42)],
          [Point2D(0.27, 0.42), Point2D(0.40, 0.28), Point2D(0.51, 0.28), Point2D(0.60, 0.37), Point2D(0.48, 0.62), Point2D(0.62, 0.62), Point2D(0.68, 0.51)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.15, yMin: 0.18, xMax: 0.48, yMax: 0.55, minPts: 3, name: 'ஐ_double_loop'),
          ZoneConstraint(xMin: 0.35, yMin: 0.45, xMax: 0.82, yMax: 0.82, minPts: 3, name: 'ஐ_base'),
        ],
      ),
    ],
    'ஒ': const [
      LetterSkeleton(
        strokes: [
          [Point2D(0.34, 0.31), Point2D(0.28, 0.27), Point2D(0.25, 0.31), Point2D(0.30, 0.35), Point2D(0.35, 0.34), Point2D(0.45, 0.27), Point2D(0.54, 0.31), Point2D(0.51, 0.45)],
          [Point2D(0.51, 0.45), Point2D(0.37, 0.51), Point2D(0.40, 0.65), Point2D(0.51, 0.68), Point2D(0.62, 0.62), Point2D(0.62, 0.51), Point2D(0.71, 0.51), Point2D(0.71, 0.71)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.18, yMin: 0.18, xMax: 0.58, yMax: 0.48, minPts: 3, name: 'ஒ_top_loop'),
          ZoneConstraint(xMin: 0.28, yMin: 0.42, xMax: 0.78, yMax: 0.80, minPts: 3, name: 'ஒ_body'),
        ],
        forbiddenZones: [
          ZoneConstraint(xMin: 0.72, yMin: 0.65, xMax: 0.95, yMax: 0.95, minPts: 4, name: 'o_tail'),
        ],
      ),
    ],
    'ஓ': const [
      LetterSkeleton(
        strokes: [
          [Point2D(0.34, 0.31), Point2D(0.28, 0.27), Point2D(0.25, 0.31), Point2D(0.30, 0.35), Point2D(0.35, 0.34), Point2D(0.45, 0.27), Point2D(0.54, 0.31), Point2D(0.51, 0.45)],
          [Point2D(0.51, 0.45), Point2D(0.37, 0.51), Point2D(0.40, 0.65), Point2D(0.51, 0.68), Point2D(0.62, 0.62)],
          [Point2D(0.62, 0.62), Point2D(0.65, 0.68), Point2D(0.74, 0.68), Point2D(0.74, 0.78), Point2D(0.65, 0.78), Point2D(0.62, 0.65)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.18, yMin: 0.18, xMax: 0.58, yMax: 0.48, minPts: 3, name: 'ஓ_top_loop'),
          ZoneConstraint(xMin: 0.58, yMin: 0.60, xMax: 0.90, yMax: 0.90, minPts: 3, name: 'ஓ_tail'),
        ],
      ),
    ],
    'ஔ': const [
      LetterSkeleton(
        strokes: [
          [Point2D(0.22, 0.31), Point2D(0.18, 0.27), Point2D(0.15, 0.31), Point2D(0.20, 0.35), Point2D(0.24, 0.34), Point2D(0.32, 0.27), Point2D(0.40, 0.31), Point2D(0.37, 0.42)],
          [Point2D(0.37, 0.42), Point2D(0.27, 0.48), Point2D(0.30, 0.60), Point2D(0.38, 0.62), Point2D(0.47, 0.58), Point2D(0.47, 0.48), Point2D(0.54, 0.48), Point2D(0.54, 0.65)],
          [Point2D(0.62, 0.37), Point2D(0.58, 0.34), Point2D(0.57, 0.37), Point2D(0.60, 0.40), Point2D(0.65, 0.38), Point2D(0.71, 0.34), Point2D(0.74, 0.40), Point2D(0.74, 0.54), Point2D(0.65, 0.62), Point2D(0.77, 0.62)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.52, yMin: 0.22, xMax: 0.88, yMax: 0.75, minPts: 3, name: 'right_la'),
          ZoneConstraint(xMin: 0.10, yMin: 0.22, xMax: 0.52, yMax: 0.75, minPts: 3, name: 'left_o'),
        ],
      ),
    ],
    'க்': const [
      LetterSkeleton(
        strokes: [
          [Point2D(0.31, 0.31), Point2D(0.31, 0.75)],
          [Point2D(0.31, 0.31), Point2D(0.68, 0.31), Point2D(0.68, 0.75)],
          [Point2D(0.50, 0.52), Point2D(0.68, 0.52), Point2D(0.75, 0.75)],
          [Point2D(0.50, 0.18)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.25, yMin: 0.30, xMax: 0.75, yMax: 0.80, minPts: 4, name: 'body'),
        ],
      ),
    ],
    'ங்': const [
      LetterSkeleton(
        strokes: [
          [Point2D(0.31, 0.31), Point2D(0.31, 0.75)],
          [Point2D(0.31, 0.31), Point2D(0.68, 0.31), Point2D(0.68, 0.54), Point2D(0.50, 0.54), Point2D(0.50, 0.75), Point2D(0.71, 0.75)],
          [Point2D(0.50, 0.18)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.25, yMin: 0.30, xMax: 0.75, yMax: 0.80, minPts: 4, name: 'body'),
        ],
      ),
    ],
    'ச்': const [
      LetterSkeleton(
        strokes: [
          [Point2D(0.31, 0.31), Point2D(0.31, 0.75)],
          [Point2D(0.31, 0.31), Point2D(0.68, 0.31), Point2D(0.68, 0.75)],
          [Point2D(0.50, 0.52), Point2D(0.74, 0.52)],
          [Point2D(0.50, 0.18)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.25, yMin: 0.30, xMax: 0.75, yMax: 0.80, minPts: 4, name: 'body'),
        ],
      ),
    ],
    'ஞ்': const [
      LetterSkeleton(
        strokes: [
          [Point2D(0.31, 0.31), Point2D(0.31, 0.75)],
          [Point2D(0.31, 0.31), Point2D(0.68, 0.31), Point2D(0.68, 0.54), Point2D(0.50, 0.54), Point2D(0.50, 0.75)],
          [Point2D(0.50, 0.62), Point2D(0.74, 0.62), Point2D(0.74, 0.75)],
          [Point2D(0.50, 0.18)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.25, yMin: 0.30, xMax: 0.75, yMax: 0.80, minPts: 4, name: 'body'),
        ],
      ),
    ],
    'ட்': const [
      LetterSkeleton(
        strokes: [
          [Point2D(0.34, 0.31), Point2D(0.34, 0.75), Point2D(0.71, 0.75)],
          [Point2D(0.52, 0.18)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.25, yMin: 0.30, xMax: 0.75, yMax: 0.80, minPts: 4, name: 'body'),
        ],
      ),
    ],
    'ண்': const [
      LetterSkeleton(
        strokes: [
          [Point2D(0.25, 0.40), Point2D(0.21, 0.37), Point2D(0.20, 0.41), Point2D(0.24, 0.44), Point2D(0.30, 0.41), Point2D(0.35, 0.37), Point2D(0.34, 0.44), Point2D(0.38, 0.41), Point2D(0.44, 0.37), Point2D(0.42, 0.44), Point2D(0.48, 0.41), Point2D(0.54, 0.37), Point2D(0.57, 0.42), Point2D(0.57, 0.75)],
          [Point2D(0.41, 0.18)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.20, yMin: 0.30, xMax: 0.65, yMax: 0.80, minPts: 4, name: 'body'),
        ],
      ),
    ],
    'த்': const [
      LetterSkeleton(
        strokes: [
          [Point2D(0.31, 0.31), Point2D(0.31, 0.75)],
          [Point2D(0.31, 0.31), Point2D(0.68, 0.31), Point2D(0.68, 0.57), Point2D(0.48, 0.57), Point2D(0.48, 0.75), Point2D(0.68, 0.75), Point2D(0.74, 0.82)],
          [Point2D(0.50, 0.18)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.25, yMin: 0.30, xMax: 0.75, yMax: 0.80, minPts: 4, name: 'body'),
        ],
      ),
    ],
    'ந்': const [
      LetterSkeleton(
        strokes: [
          [Point2D(0.31, 0.31), Point2D(0.31, 0.75)],
          [Point2D(0.31, 0.31), Point2D(0.68, 0.31), Point2D(0.68, 0.57), Point2D(0.48, 0.57), Point2D(0.48, 0.75), Point2D(0.71, 0.75)],
          [Point2D(0.50, 0.18)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.25, yMin: 0.30, xMax: 0.75, yMax: 0.80, minPts: 4, name: 'body'),
        ],
      ),
    ],
    'ப்': const [
      LetterSkeleton(
        strokes: [
          [Point2D(0.31, 0.31), Point2D(0.31, 0.75), Point2D(0.68, 0.75), Point2D(0.68, 0.31)],
          [Point2D(0.50, 0.18)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.25, yMin: 0.30, xMax: 0.75, yMax: 0.80, minPts: 4, name: 'body'),
        ],
      ),
    ],
    'ம்': const [
      LetterSkeleton(
        strokes: [
          [Point2D(0.31, 0.31), Point2D(0.31, 0.75), Point2D(0.68, 0.75), Point2D(0.68, 0.54), Point2D(0.31, 0.54)],
          [Point2D(0.50, 0.18)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.25, yMin: 0.30, xMax: 0.75, yMax: 0.80, minPts: 4, name: 'body'),
        ],
      ),
    ],
    'ய்': const [
      LetterSkeleton(
        strokes: [
          [Point2D(0.31, 0.31), Point2D(0.31, 0.52), Point2D(0.42, 0.52), Point2D(0.42, 0.31), Point2D(0.42, 0.75), Point2D(0.68, 0.75), Point2D(0.68, 0.31)],
          [Point2D(0.50, 0.18)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.25, yMin: 0.30, xMax: 0.75, yMax: 0.80, minPts: 4, name: 'body'),
        ],
      ),
    ],
    'ர்': const [
      LetterSkeleton(
        strokes: [
          [Point2D(0.34, 0.31), Point2D(0.34, 0.75)],
          [Point2D(0.34, 0.31), Point2D(0.62, 0.31), Point2D(0.62, 0.52), Point2D(0.34, 0.52)],
          [Point2D(0.48, 0.18)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.25, yMin: 0.30, xMax: 0.70, yMax: 0.80, minPts: 3, name: 'body'),
        ],
      ),
    ],
    'ல்': const [
      LetterSkeleton(
        strokes: [
          [Point2D(0.31, 0.50), Point2D(0.25, 0.45), Point2D(0.22, 0.50), Point2D(0.27, 0.54), Point2D(0.32, 0.51), Point2D(0.41, 0.40), Point2D(0.51, 0.40), Point2D(0.60, 0.48), Point2D(0.54, 0.75)],
          [Point2D(0.42, 0.18)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.20, yMin: 0.35, xMax: 0.65, yMax: 0.80, minPts: 4, name: 'body'),
        ],
      ),
    ],
    'வ்': const [
      LetterSkeleton(
        strokes: [
          [Point2D(0.31, 0.50), Point2D(0.25, 0.45), Point2D(0.22, 0.50), Point2D(0.27, 0.54), Point2D(0.32, 0.51), Point2D(0.41, 0.40), Point2D(0.65, 0.40), Point2D(0.65, 0.75)],
          [Point2D(0.48, 0.18)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.20, yMin: 0.35, xMax: 0.70, yMax: 0.80, minPts: 4, name: 'body'),
        ],
      ),
    ],
    'ழ்': const [
      LetterSkeleton(
        strokes: [
          [Point2D(0.31, 0.31), Point2D(0.31, 0.75)],
          [Point2D(0.31, 0.31), Point2D(0.65, 0.31), Point2D(0.65, 0.57), Point2D(0.45, 0.57), Point2D(0.45, 0.68), Point2D(0.68, 0.68), Point2D(0.68, 0.82)],
          [Point2D(0.48, 0.18)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.25, yMin: 0.30, xMax: 0.75, yMax: 0.85, minPts: 4, name: 'body'),
        ],
      ),
    ],
    'ள்': const [
      LetterSkeleton(
        strokes: [
          [Point2D(0.31, 0.50), Point2D(0.25, 0.45), Point2D(0.22, 0.50), Point2D(0.27, 0.54), Point2D(0.32, 0.51), Point2D(0.41, 0.40), Point2D(0.51, 0.40), Point2D(0.57, 0.45), Point2D(0.57, 0.62), Point2D(0.48, 0.75), Point2D(0.68, 0.75)],
          [Point2D(0.45, 0.18)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.20, yMin: 0.35, xMax: 0.75, yMax: 0.80, minPts: 4, name: 'body'),
        ],
      ),
    ],
    'ற்': const [
      LetterSkeleton(
        strokes: [
          [Point2D(0.34, 0.75), Point2D(0.48, 0.31), Point2D(0.62, 0.75)],
          [Point2D(0.48, 0.18)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.25, yMin: 0.30, xMax: 0.70, yMax: 0.80, minPts: 3, name: 'body'),
        ],
      ),
    ],
    'ன்': const [
      LetterSkeleton(
        strokes: [
          [Point2D(0.28, 0.42), Point2D(0.24, 0.40), Point2D(0.22, 0.44), Point2D(0.27, 0.47), Point2D(0.32, 0.44), Point2D(0.40, 0.38), Point2D(0.38, 0.47), Point2D(0.44, 0.44), Point2D(0.51, 0.38), Point2D(0.54, 0.44), Point2D(0.54, 0.75)],
          [Point2D(0.41, 0.18)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.20, yMin: 0.35, xMax: 0.65, yMax: 0.80, minPts: 4, name: 'body'),
        ],
      ),
    ],
    'ஃ': const [
      LetterSkeleton(
        strokes: [
          [Point2D(0.50, 0.31)],
          [Point2D(0.35, 0.65)],
          [Point2D(0.65, 0.65)],
        ],
        requiredZones: [
          ZoneConstraint(xMin: 0.40, yMin: 0.20, xMax: 0.60, yMax: 0.42, minPts: 1, name: 'top_dot'),
          ZoneConstraint(xMin: 0.25, yMin: 0.52, xMax: 0.45, yMax: 0.78, minPts: 1, name: 'left_dot'),
          ZoneConstraint(xMin: 0.55, yMin: 0.52, xMax: 0.75, yMax: 0.78, minPts: 1, name: 'right_dot'),
        ],
      ),
    ],
  };

  static List<Point2D> _densify(List<Point2D> stroke, {double step = 0.015}) {
    final List<Point2D> pts = [];
    if (stroke.isEmpty) return pts;
    if (stroke.length == 1) return [stroke[0]];

    for (int i = 0; i < stroke.length - 1; i++) {
      final p1 = stroke[i];
      final p2 = stroke[i + 1];
      final dist = p1.distanceTo(p2);
      final steps = math.max((dist / step).ceil(), 1);
      for (int s = 0; s < steps; s++) {
        final t = s / steps.toDouble();
        pts.add(Point2D(p1.x + (p2.x - p1.x) * t, p1.y + (p2.y - p1.y) * t));
      }
    }
    pts.add(stroke.last);
    return pts;
  }

  /// Detects whether user drawn strokes represent a random zig-zag or scribble
  static bool _isScribblePattern(List<List<Point2D>> rawStrokes, double totalLen, double bboxDiag) {
    if (rawStrokes.isEmpty) return false;

    // Check for extreme length with tiny bounding box (coloring over same tiny spot)
    if (bboxDiag < 0.12 && totalLen > 2.2) {
      return true;
    }

    for (final stroke in rawStrokes) {
      if (stroke.length < 5) continue;

      int sharpTurns = 0;
      double? prevAngle;

      for (int i = 0; i < stroke.length - 1; i++) {
        final p1 = stroke[i];
        final p2 = stroke[i + 1];
        final dx = p2.x - p1.x;
        final dy = p2.y - p1.y;
        final segLen = math.sqrt(dx * dx + dy * dy);
        if (segLen < 0.03) continue; // Skip sub-pixel jitter

        final angle = math.atan2(dy, dx);
        if (prevAngle != null) {
          double angleDiff = (angle - prevAngle).abs();
          if (angleDiff > math.pi) angleDiff = 2 * math.pi - angleDiff;
          // Sharp acute zig-zag reversal (> 110 degrees / 1.92 rad)
          if (angleDiff > 1.92) {
            sharpTurns++;
          }
        }
        prevAngle = angle;
      }

      // If a single stroke has 3 or more sharp acute reversals across long segments
      if (sharpTurns >= 3) {
        return true;
      }
    }

    return false;
  }

  /// Dedicated Geometric Feature Detectors
  static bool _detectAaTail(List<Point2D> normPts) {
    if (normPts.isEmpty) return false;

    // Look at points strictly in the bottom-right quadrant: nx >= 0.70 and ny >= 0.70
    final brPts = normPts.where((p) => p.x >= 0.70 && p.y >= 0.70).toList();
    if (brPts.length < 5) return false;

    double minBrX = brPts.fold(double.infinity, (m, p) => math.min(m, p.x));
    double maxBrX = brPts.fold(-double.infinity, (m, p) => math.max(m, p.x));
    double minBrY = brPts.fold(double.infinity, (m, p) => math.min(m, p.y));
    double maxBrY = brPts.fold(-double.infinity, (m, p) => math.max(m, p.y));
    final double brW = maxBrX - minBrX;
    final double brH = maxBrY - minBrY;

    // Check for loop curvature turnaround in bottom right
    bool hasTurnaround = false;
    for (int i = 0; i < brPts.length - 2; i++) {
      final p1 = brPts[i];
      final p2 = brPts[i + 1];
      final p3 = brPts[i + 2];
      if ((p2.x - p1.x > 0.015 && p3.x - p2.x < -0.015) || (p2.y - p1.y > 0.015 && p3.y - p2.y < -0.015)) {
        hasTurnaround = true;
        break;
      }
    }

    return (brW >= 0.12 && hasTurnaround) || (brW >= 0.15 && brH >= 0.15);
  }

  static bool _detectOoLa(List<Point2D> normPts) {
    final trPts = normPts.where((p) => p.x >= 0.52 && p.y <= 0.55).toList();
    if (trPts.length < 5) return false;

    double minTrX = trPts.fold(double.infinity, (m, p) => math.min(m, p.x));
    double maxTrX = trPts.fold(-double.infinity, (m, p) => math.max(m, p.x));
    double minTrY = trPts.fold(double.infinity, (m, p) => math.min(m, p.y));
    double maxTrY = trPts.fold(-double.infinity, (m, p) => math.max(m, p.y));

    return trPts.length >= 6 && (maxTrX - minTrX) >= 0.12 && (maxTrY - minTrY) >= 0.12;
  }

  static bool _detectEaTail(List<Point2D> normPts) {
    final blPts = normPts.where((p) => p.x <= 0.35 && p.y >= 0.65).toList();
    if (blPts.length < 4) return false;

    double minBlX = blPts.fold(double.infinity, (m, p) => math.min(m, p.x));
    double maxBlY = blPts.fold(-double.infinity, (m, p) => math.max(m, p.y));

    return minBlX <= 0.20 && maxBlY >= 0.78 && blPts.length >= 4;
  }

  static bool _detectOhTail(List<Point2D> normPts) {
    final brPts = normPts.where((p) => p.x >= 0.55 && p.y >= 0.62).toList();
    if (brPts.length < 5) return false;

    double minBrX = brPts.fold(double.infinity, (m, p) => math.min(m, p.x));
    double maxBrX = brPts.fold(-double.infinity, (m, p) => math.max(m, p.x));
    double minBrY = brPts.fold(double.infinity, (m, p) => math.min(m, p.y));
    double maxBrY = brPts.fold(-double.infinity, (m, p) => math.max(m, p.y));

    return (maxBrX - minBrX) >= 0.14 && (maxBrY - minBrY) >= 0.14 && brPts.length >= 5;
  }

  static bool _detectAuLa(List<Point2D> normPts) {
    final rPts = normPts.where((p) => p.x >= 0.52 && p.y >= 0.18 && p.y <= 0.85).toList();
    if (rPts.length < 6) return false;

    double minRX = rPts.fold(double.infinity, (m, p) => math.min(m, p.x));
    double maxRX = rPts.fold(-double.infinity, (m, p) => math.max(m, p.x));
    double minRY = rPts.fold(double.infinity, (m, p) => math.min(m, p.y));
    double maxRY = rPts.fold(-double.infinity, (m, p) => math.max(m, p.y));

    return (maxRX - minRX) >= 0.18 && (maxRY - minRY) >= 0.22;
  }

  static bool _detectTopPulli(List<List<Point2D>> rawNormStrokes, List<Point2D> normPts) {
    if (rawNormStrokes.length < 2) return false;

    // Check if any separate short stroke is positioned in the top pulli zone
    for (final stroke in rawNormStrokes) {
      if (stroke.isEmpty) continue;

      double strokeLen = 0.0;
      for (int i = 0; i < stroke.length - 1; i++) {
        strokeLen += stroke[i].distanceTo(stroke[i + 1]);
      }

      double sMinX = stroke.fold(double.infinity, (m, p) => math.min(m, p.x));
      double sMaxX = stroke.fold(-double.infinity, (m, p) => math.max(m, p.x));
      double sMinY = stroke.fold(double.infinity, (m, p) => math.min(m, p.y));
      double sMaxY = stroke.fold(-double.infinity, (m, p) => math.max(m, p.y));
      double sW = sMaxX - sMinX;
      double sH = sMaxY - sMinY;

      final bool isShortDot = (stroke.length <= 3 || strokeLen <= 0.08) && (sW <= 0.12 && sH <= 0.12);
      if (isShortDot && sMinY <= 0.30) {
        return true;
      }
    }
    return false;
  }

  static ({bool isAyutham, String? error}) _validateAyutham(List<List<Point2D>> rawNormStrokes) {
    if (rawNormStrokes.length != 3) {
      return (isAyutham: false, error: "'ஃ' (ஆய்த எழுத்து) சரியாக மூன்று தனித்தனி புள்ளிகளாக இருக்க வேண்டும்.");
    }
    for (final stroke in rawNormStrokes) {
      double strokeLen = 0.0;
      for (int i = 0; i < stroke.length - 1; i++) {
        strokeLen += stroke[i].distanceTo(stroke[i + 1]);
      }
      if (strokeLen > 0.22) {
        return (isAyutham: false, error: "'ஃ' எழுத்து புள்ளிகளாக மட்டுமே இருக்க வேண்டும், நீண்ட கோடுகள் கூடாது.");
      }
    }
    return (isAyutham: true, error: null);
  }

  /// Evaluates user touch strokes using Structural Vector Path & Strict Letter Conditions
  Future<HandwritingRecognitionResult> recognizeStrokes({
    required String expectedLetter,
    required List<List<Offset>> userStrokes,
    required Size canvasSize,
  }) async {
    final stopwatch = Stopwatch()..start();
    final int totalPoints = userStrokes.fold(0, (sum, s) => sum + s.length);
    final int strokeCount = userStrokes.length;

    final double width = canvasSize.width > 0 ? canvasSize.width : 350.0;
    final double height = canvasSize.height > 0 ? canvasSize.height : 350.0;

    // 1. Minimum Input Verification
    final int minInputPoints = expectedLetter == 'ஃ' ? 3 : 4;
    if (userStrokes.isEmpty || totalPoints < minInputPoints) {
      stopwatch.stop();
      return HandwritingRecognitionResult(
        expectedCharacter: expectedLetter,
        strokeCount: strokeCount,
        totalPointCount: totalPoints,
        modelStatus: MLModelStatus.loaded,
        confidence: 0.0,
        isMatchExplicit: false,
        errorMessage: 'போதிய எழுத்து வரிகள் வரையப்படவில்லை.',
        inferenceTime: stopwatch.elapsed,
      );
    }

    // Convert and normalize user strokes to [0.0, 1.0] relative to canvas
    final List<Point2D> userPts = [];
    final List<List<Point2D>> rawNormStrokes = [];
    double totalStrokeLen = 0.0;

    for (final s in userStrokes) {
      final normS = s.map((pt) => Point2D(pt.dx / width, pt.dy / height)).toList();
      rawNormStrokes.add(normS);
      final densified = _densify(normS, step: 0.015);
      userPts.addAll(densified);

      for (int i = 0; i < normS.length - 1; i++) {
        totalStrokeLen += normS[i].distanceTo(normS[i + 1]);
      }
    }

    final int minRequiredPoints = expectedLetter == 'ஃ' ? 3 : 10;
    final double minLength = expectedLetter == 'ஃ' ? 0.001 : 0.15;

    if (userPts.length < minRequiredPoints || totalStrokeLen < minLength) {
      stopwatch.stop();
      return HandwritingRecognitionResult(
        expectedCharacter: expectedLetter,
        strokeCount: strokeCount,
        totalPointCount: totalPoints,
        modelStatus: MLModelStatus.loaded,
        confidence: 0.0,
        isMatchExplicit: false,
        errorMessage: 'எழுத்தை முழுமையாக எழுதிப் பாருங்கள்.',
        inferenceTime: stopwatch.elapsed,
      );
    }

    // 2. Anti-Scribble Barrier
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;
    for (final p in userPts) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }
    final double boxW = maxX - minX;
    final double boxH = maxY - minY;
    final double bboxDiag = math.sqrt(boxW * boxW + boxH * boxH);

    if (_isScribblePattern(rawNormStrokes, totalStrokeLen, bboxDiag)) {
      stopwatch.stop();
      return HandwritingRecognitionResult(
        expectedCharacter: expectedLetter,
        strokeCount: strokeCount,
        totalPointCount: totalPoints,
        modelStatus: MLModelStatus.loaded,
        confidence: 0.0,
        isMatchExplicit: false,
        errorMessage: 'கிறுக்கல்கள் இல்லாமல் எழுத்தை மட்டும் தெளிவாக எழுதவும்.',
        inferenceTime: stopwatch.elapsed,
      );
    }

    // 3. Normalized Space Points [0, 1] relative to user drawing bounding box
    final List<Point2D> bboxNormPts = userPts.map((p) {
      final nx = boxW > 0.05 ? (p.x - minX) / boxW : p.x;
      final ny = boxH > 0.05 ? (p.y - minY) / boxH : p.y;
      return Point2D(nx, ny);
    }).toList();

    // 4. Feature Extraction
    final bool hasAaTail = _detectAaTail(bboxNormPts);
    final bool hasOoLa = _detectOoLa(bboxNormPts);
    final bool hasEaTail = _detectEaTail(bboxNormPts);
    final bool hasOhTail = _detectOhTail(bboxNormPts);
    final bool hasAuLa = _detectAuLa(bboxNormPts);
    final bool hasTopPulli = _detectTopPulli(rawNormStrokes, bboxNormPts);

    const uyirSet = {'அ', 'ஆ', 'இ', 'ஈ', 'உ', 'ஊ', 'எ', 'ஏ', 'ஐ', 'ஒ', 'ஓ', 'ஔ'};
    const meiSet = {
      'க்', 'ங்', 'ச்', 'ஞ்', 'ட்', 'ண்', 'த்', 'ந்', 'ப்', 'ம்',
      'ய்', 'ர்', 'ல்', 'வ்', 'ழ்', 'ள்', 'ற்', 'ன்',
    };

    // 5. Letter-Specific Strict Condition Invariants
    bool invariantPassed = true;
    String? rejectionReason;

    if (expectedLetter == 'ஃ') {
      final ayuthamCheck = _validateAyutham(rawNormStrokes);
      if (!ayuthamCheck.isAyutham) {
        invariantPassed = false;
        rejectionReason = ayuthamCheck.error;
      }
    } else if (uyirSet.contains(expectedLetter) && expectedLetter != 'ஈ' && hasTopPulli) {
      invariantPassed = false;
      rejectionReason = "உயிர் எழுத்துக்கு மேலே புள்ளி வைக்கக் கூடாது.";
    } else if (meiSet.contains(expectedLetter) && !hasTopPulli) {
      invariantPassed = false;
      rejectionReason = "மெய்யெழுத்துக்கு மேலே புள்ளி வைக்க வேண்டும்.";
    } else if (expectedLetter == 'அ' && hasAaTail) {
      invariantPassed = false;
      rejectionReason = "நீங்கள் எழுதியது 'ஆ'. 'அ' எழுத்தில் கீழ் சுழி இருக்கக் கூடாது.";
    } else if (expectedLetter == 'ஆ' && !hasAaTail) {
      invariantPassed = false;
      rejectionReason = "'ஆ' எழுத்தின் கீழ் சுழியை அழகாகச் சேர்த்து எழுதவும்.";
    } else if (expectedLetter == 'உ' && hasOoLa) {
      invariantPassed = false;
      rejectionReason = "நீங்கள் எழுதியது 'ஊ'. 'உ' எழுத்தில் மேல் 'ள' இருக்கக் கூடாது.";
    } else if (expectedLetter == 'ஊ' && !hasOoLa) {
      invariantPassed = false;
      rejectionReason = "'ஊ' எழுத்தின் மேலே 'ள' சேர்த்து எழுதவும்.";
    } else if (expectedLetter == 'எ' && hasEaTail) {
      invariantPassed = false;
      rejectionReason = "நீங்கள் எழுதியது 'ஏ'. 'எ' எழுத்தில் சாய்வுக்கோடு இருக்கக் கூடாது.";
    } else if (expectedLetter == 'ஏ' && !hasEaTail) {
      invariantPassed = false;
      rejectionReason = "'ஏ' எழுத்தின் இடது கீழ் சாய்வுக்கோட்டைச் சேர்த்து எழுதவும்.";
    } else if (expectedLetter == 'ஒ' && (hasOhTail || hasAuLa)) {
      invariantPassed = false;
      rejectionReason = "'ஒ' எழுத்தை மட்டும் தெளிவாக எழுதவும்.";
    } else if (expectedLetter == 'ஓ' && !hasOhTail) {
      invariantPassed = false;
      rejectionReason = "'ஓ' எழுத்தின் கீழ் சுழியைச் சேர்த்து எழுதவும்.";
    } else if (expectedLetter == 'ஔ' && !hasAuLa) {
      invariantPassed = false;
      rejectionReason = "'ஔ' எழுத்தின் பக்கத்தில் 'ள' சேர்த்து எழுதவும்.";
    }

    // 6. Multi-Class Competitive Discrimination & Evaluation Across All 31 Classes
    const double corridor = 0.125;

    final Map<String, ({double score, double coverage, double precision, bool passedZones})> allScores = {};

    for (final entry in _skeletons.entries) {
      final char = entry.key;
      final skeletonList = entry.value;

      double charBestScore = 0.0;
      double charBestCov = 0.0;
      double charBestPrec = 0.0;
      bool charPassedZones = false;

      for (final skel in skeletonList) {
        final List<Point2D> refPts = [];
        for (final s in skel.strokes) {
          refPts.addAll(_densify(s, step: 0.015));
        }
        if (refPts.isEmpty) continue;

        // Precision
        int validUserPts = 0;
        for (final up in userPts) {
          double minD = double.infinity;
          for (final rp in refPts) {
            final d = up.distanceTo(rp);
            if (d < minD) minD = d;
          }
          if (minD <= corridor) validUserPts++;
        }
        final double precision = userPts.isNotEmpty ? (validUserPts / userPts.length.toDouble()) : 0.0;

        // Coverage
        int coveredRef = 0;
        for (final rp in refPts) {
          double minD = double.infinity;
          for (final up in userPts) {
            final d = rp.distanceTo(up);
            if (d < minD) minD = d;
          }
          if (minD <= corridor) coveredRef++;
        }
        final double coverage = refPts.isNotEmpty ? (coveredRef / refPts.length.toDouble()) : 0.0;

        // Required Zones
        bool reqPassed = true;
        for (final zone in skel.requiredZones) {
          int ptsInZone = 0;
          for (final p in userPts) {
            if (zone.contains(p)) ptsInZone++;
          }
          if (ptsInZone < zone.minPts) {
            reqPassed = false;
            break;
          }
        }

        // Forbidden Zones
        bool forbPassed = true;
        for (final zone in skel.forbiddenZones) {
          int ptsInZone = 0;
          for (final p in userPts) {
            if (zone.contains(p)) ptsInZone++;
          }
          if (ptsInZone >= zone.minPts) {
            forbPassed = false;
            break;
          }
        }

        final bool zonesOk = reqPassed && forbPassed;
        final double rawScore = (0.50 * coverage + 0.50 * precision);
        final double score = zonesOk ? rawScore : rawScore * 0.40;

        if (score > charBestScore) {
          charBestScore = score;
          charBestCov = coverage;
          charBestPrec = precision;
          charPassedZones = zonesOk;
        }
      }

      allScores[char] = (
        score: charBestScore,
        coverage: charBestCov,
        precision: charBestPrec,
        passedZones: charPassedZones,
      );
    }

    final sortedCandidates = allScores.entries.toList()
      ..sort((a, b) => b.value.score.compareTo(a.value.score));

    final top1 = sortedCandidates.isNotEmpty ? sortedCandidates.first : null;
    final String top1Char = top1?.key ?? expectedLetter;
    final double top1Score = top1?.value.score ?? 0.0;
    final expEval = allScores[expectedLetter];

    // 7. Final Match Decision
    final bool isWinner = (top1Char == expectedLetter || (expEval != null && expEval.score >= top1Score - 0.03));
    final bool isMatch = isWinner &&
        invariantPassed &&
        expEval != null &&
        expEval.passedZones &&
        expEval.coverage >= 0.42 &&
        expEval.precision >= 0.42 &&
        expEval.score >= 0.45;

    final double finalConfidence = isMatch ? math.max(expEval.score, 0.88).clamp(0.0, 1.0) : 0.0;

    stopwatch.stop();

    String finalErrorMessage;
    if (isMatch) {
      finalErrorMessage = '';
    } else if (rejectionReason != null) {
      finalErrorMessage = rejectionReason;
    } else if (!isWinner && top1Char != expectedLetter && top1Score >= 0.48) {
      finalErrorMessage = "நீங்கள் எழுதியது '$top1Char'. '$expectedLetter' எழுத்தை கவனமாக எழுதிப் பாருங்கள்.";
    } else {
      finalErrorMessage = 'எழுத்தை மீண்டும் ஒருமுறை கவனமாக எழுதிப் பாருங்கள்.';
    }

    return HandwritingRecognitionResult(
      expectedCharacter: expectedLetter,
      recognizedCharacter: isMatch ? expectedLetter : (top1Score >= 0.48 ? top1Char : null),
      confidence: finalConfidence,
      topCandidates: isMatch
          ? [CharacterConfidence(character: expectedLetter, confidence: finalConfidence)]
          : (top1 != null && top1Score >= 0.40
              ? [CharacterConfidence(character: top1Char, confidence: top1Score.clamp(0.0, 1.0))]
              : []),
      strokeCount: strokeCount,
      totalPointCount: totalPoints,
      modelStatus: MLModelStatus.loaded,
      isMatchExplicit: isMatch,
      errorMessage: isMatch ? null : finalErrorMessage,
      inferenceTime: stopwatch.elapsed,
    );
  }
}
