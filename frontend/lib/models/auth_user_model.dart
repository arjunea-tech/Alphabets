class AuthUserModel {
  final String id;
  final String name;
  final String email;
  final String avatarAsset;
  final int totalStars;
  final String? token;

  const AuthUserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarAsset = 'assets/images/welcome.png',
    this.totalStars = 0,
    this.token,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    return AuthUserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['child_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      avatarAsset: json['avatarAsset']?.toString() ??
          json['avatar_asset']?.toString() ??
          'assets/images/welcome.png',
      totalStars: json['totalStars'] as int? ?? json['total_stars'] as int? ?? 0,
      token: token ?? json['token']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarAsset': avatarAsset,
      'totalStars': totalStars,
      'token': token,
    };
  }

  AuthUserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarAsset,
    int? totalStars,
    String? token,
  }) {
    return AuthUserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarAsset: avatarAsset ?? this.avatarAsset,
      totalStars: totalStars ?? this.totalStars,
      token: token ?? this.token,
    );
  }
}
