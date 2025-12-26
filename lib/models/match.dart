class Match {
  final String id;
  final String player1Id;
  final String player2Id;
  final int player1Progress;
  final int player2Progress;
  final int player1CorrectCount;
  final int player2CorrectCount;
  final DateTime? player1FinishTime;
  final DateTime? player2FinishTime;
  final String? result;
  final String? winnerId;
  final DateTime createdAt;
  final DateTime? finishedAt;

  Match({
    required this.id,
    required this.player1Id,
    required this.player2Id,
    this.player1Progress = 0,
    this.player2Progress = 0,
    this.player1CorrectCount = 0,
    this.player2CorrectCount = 0,
    this.player1FinishTime,
    this.player2FinishTime,
    this.result,
    this.winnerId,
    required this.createdAt,
    this.finishedAt,
  });

  factory Match.fromSupabase(Map<String, dynamic> data) {
    return Match(
      id: data['id']?.toString() ?? '',
      player1Id: data['player1_id'] ?? '',
      player2Id: data['player2_id'] ?? '',
      player1Progress: data['player1_progress'] ?? 0,
      player2Progress: data['player2_progress'] ?? 0,
      player1CorrectCount: data['player1_correct_count'] ?? 0,
      player2CorrectCount: data['player2_correct_count'] ?? 0,
      player1FinishTime: data['player1_finish_time'] != null
          ? DateTime.parse(data['player1_finish_time'])
          : null,
      player2FinishTime: data['player2_finish_time'] != null
          ? DateTime.parse(data['player2_finish_time'])
          : null,
      result: data['result'],
      winnerId: data['winner_id'],
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
      finishedAt: data['finished_at'] != null
          ? DateTime.parse(data['finished_at'])
          : null,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'player1_id': player1Id,
      'player2_id': player2Id,
      'player1_progress': player1Progress,
      'player2_progress': player2Progress,
      'player1_correct_count': player1CorrectCount,
      'player2_correct_count': player2CorrectCount,
      'player1_finish_time': player1FinishTime?.toIso8601String(),
      'player2_finish_time': player2FinishTime?.toIso8601String(),
      'result': result,
      'winner_id': winnerId,
      'created_at': createdAt.toIso8601String(),
      'finished_at': finishedAt?.toIso8601String(),
    };
  }
}
