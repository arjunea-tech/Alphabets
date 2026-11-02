import 'dart:convert';

/// Model representing the child's learning profile
class UserProfile {
  final String id;
  final String name;
  final int age;
  final String avatarAsset;
  final int totalStars;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.avatarAsset,
    required this.totalStars,
    required this.createdAt,
  });

  factory UserProfile.defaultProfile() {
    return UserProfile(
      id: 'default_child',
      name: 'Kid',
      age: 5,
      avatarAsset: 'assets/images/welcome.png',
      totalStars: 25,
      createdAt: DateTime.now(),
    );
  }

  UserProfile copyWith({
    String? name,
    int? age,
    String? avatarAsset,
    int? totalStars,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      age: age ?? this.age,
      avatarAsset: avatarAsset ?? this.avatarAsset,
      totalStars: totalStars ?? this.totalStars,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
        'avatarAsset': avatarAsset,
        'totalStars': totalStars,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String? ?? 'child',
        name: json['name'] as String? ?? 'Kid',
        age: json['age'] as int? ?? 5,
        avatarAsset: json['avatarAsset'] as String? ?? 'assets/images/welcome.png',
        totalStars: json['totalStars'] as int? ?? 0,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  String toJsonString() => jsonEncode(toJson());

  factory UserProfile.fromJsonString(String jsonString) {
    if (jsonString.isEmpty) return UserProfile.defaultProfile();
    try {
      return UserProfile.fromJson(jsonDecode(jsonString));
    } catch (_) {
      return UserProfile.defaultProfile();
    }
  }
}
