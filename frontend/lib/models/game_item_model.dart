import 'dart:convert';

/// Educational Game Catalog Item (fetched dynamically from backend superadmin)
class GameItem {
  final String id;
  final String gameType;
  final String title;
  final String prompt;
  final String? clue;
  final String? clueImage;
  final int correctIndex;
  final List<String> options;
  final String successPraise;
  final int starsReward;
  final int displayOrder;
  final bool isActive;

  const GameItem({
    required this.id,
    required this.gameType,
    required this.title,
    required this.prompt,
    this.clue,
    this.clueImage,
    this.correctIndex = 0,
    this.options = const [],
    this.successPraise = 'Awesome! ⭐',
    this.starsReward = 5,
    this.displayOrder = 0,
    this.isActive = true,
  });

  factory GameItem.fromJson(Map<String, dynamic> json) {
    List<String> parsedOptions = [];
    final rawOpts = json['options'] ?? json['options_json'];
    if (rawOpts is List) {
      parsedOptions = rawOpts.map((e) => e.toString()).toList();
    } else if (rawOpts is String) {
      try {
        final decoded = jsonDecode(rawOpts);
        if (decoded is List) {
          parsedOptions = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    return GameItem(
      id: json['id']?.toString() ?? '',
      gameType: json['game_type']?.toString() ?? json['gameType']?.toString() ?? 'runner',
      title: json['title']?.toString() ?? '',
      prompt: json['prompt']?.toString() ?? '',
      clue: json['clue']?.toString(),
      clueImage: json['clue_image']?.toString() ?? json['clueImage']?.toString(),
      correctIndex: json['correct_index'] is int
          ? json['correct_index']
          : int.tryParse(json['correct_index']?.toString() ?? '0') ?? 0,
      options: parsedOptions,
      successPraise: json['success_praise']?.toString() ?? 'Awesome! ⭐',
      starsReward: json['stars_reward'] is int
          ? json['stars_reward']
          : int.tryParse(json['stars_reward']?.toString() ?? '5') ?? 5,
      displayOrder: json['display_order'] is int
          ? json['display_order']
          : int.tryParse(json['display_order']?.toString() ?? '0') ?? 0,
      isActive: json['is_active'] == true || json['is_active'] == 1 || json['is_active'] == '1',
    );
  }
}

