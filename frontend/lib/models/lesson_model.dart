import 'package:flutter/material.dart';

class LessonCategoryModel {
  final String id;
  final String title;
  final String subtitle;
  final String countText;
  final String buttonText;
  final String iconEmoji;
  final List<Color> gradientColors;
  final String routeName;

  const LessonCategoryModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.countText,
    required this.buttonText,
    required this.iconEmoji,
    required this.gradientColors,
    required this.routeName,
  });
}
