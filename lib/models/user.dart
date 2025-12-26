class UserModel {
  final String id;
  final String email;
  final String nickname;
  final int coins;
  final int tickets;
  final int rating;
  final String? profileImage;
  final String? currentLeagueTier;
  final String? currentLeagueId;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.nickname,
    this.coins = 0,
    this.tickets = 0,
    this.rating = 1000,
    this.profileImage,
    this.currentLeagueTier,
    this.currentLeagueId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromSupabase(Map<String, dynamic> data) {
    return UserModel(
      id: data['id'] ?? '',
      email: data['email'] ?? '',
      nickname: data['nickname'] ?? '',
      coins: data['coins'] ?? 0,
      tickets: data['tickets'] ?? 0,
      rating: data['rating'] ?? 1000,
      profileImage: data['profile_image'],
      currentLeagueTier: data['current_league_tier'] ?? 'bronze',
      currentLeagueId: data['current_league_id'],
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'email': email,
      'nickname': nickname,
      'coins': coins,
      'tickets': tickets,
      'rating': rating,
      'profile_image': profileImage,
      'current_league_tier': currentLeagueTier ?? 'bronze',
      'current_league_id': currentLeagueId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? nickname,
    int? coins,
    int? tickets,
    int? rating,
    String? profileImage,
    String? currentLeagueTier,
    String? currentLeagueId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      coins: coins ?? this.coins,
      tickets: tickets ?? this.tickets,
      rating: rating ?? this.rating,
      profileImage: profileImage ?? this.profileImage,
      currentLeagueTier: currentLeagueTier ?? this.currentLeagueTier,
      currentLeagueId: currentLeagueId ?? this.currentLeagueId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
