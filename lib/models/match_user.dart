class MatchUser {
  final String id;
  final String nickname;
  final String? profileImage;
  final int rating;

  MatchUser({
    required this.id,
    required this.nickname,
    this.profileImage,
    this.rating = 1000,
  });

  factory MatchUser.fromJson(Map<String, dynamic> json) {
    return MatchUser(
      id: json['id'] ?? '',
      nickname: json['nickname'] ?? '',
      profileImage: json['profile_image'],
      rating: json['rating'] ?? 1000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'profile_image': profileImage,
      'rating': rating,
    };
  }
}

