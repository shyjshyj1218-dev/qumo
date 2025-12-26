class QuizRoom {
  final String id;
  final String difficulty;
  final String status;
  final DateTime createdAt;

  QuizRoom({
    required this.id,
    required this.difficulty,
    required this.status,
    required this.createdAt,
  });

  factory QuizRoom.fromSupabase(Map<String, dynamic> data) {
    return QuizRoom(
      id: data['id']?.toString() ?? '',
      difficulty: data['difficulty'] ?? 'beginner',
      status: data['status'] ?? 'waiting',
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'difficulty': difficulty,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
