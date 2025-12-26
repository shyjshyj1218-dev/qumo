class Mission {
  final String id;
  final String title;
  final String description;
  final int rewardCoins;
  final int rewardTickets;
  final String missionType; // daily, weekly, achievement
  final int targetValue; // 목표 값
  final String resetType; // daily, weekly, never
  final DateTime createdAt;

  Mission({
    required this.id,
    required this.title,
    required this.description,
    this.rewardCoins = 0,
    this.rewardTickets = 0,
    this.missionType = 'daily',
    this.targetValue = 1,
    this.resetType = 'daily',
    required this.createdAt,
  });

  factory Mission.fromSupabase(Map<String, dynamic> data) {
    return Mission(
      id: data['id']?.toString() ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      rewardCoins: data['reward_coins'] ?? 0,
      rewardTickets: data['reward_tickets'] ?? 0,
      missionType: data['mission_type'] ?? 'daily',
      targetValue: data['target_value'] ?? 1,
      resetType: data['reset_type'] ?? 'daily',
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'reward_coins': rewardCoins,
      'reward_tickets': rewardTickets,
      'mission_type': missionType,
      'target_value': targetValue,
      'reset_type': resetType,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
