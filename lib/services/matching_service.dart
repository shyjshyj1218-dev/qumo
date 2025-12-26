import '../models/match.dart';
import '../utils/constants.dart';
import 'supabase_service.dart';

class MatchingService {
  final supabase = SupabaseService.client;

  Future<void> saveMatchResult(Match match) async {
    await supabase
        .from(AppConstants.matchesCollection)
        .upsert(match.toSupabase());
  }

  Future<Match?> getMatchById(String matchId) async {
    final response = await supabase
        .from(AppConstants.matchesCollection)
        .select()
        .eq('id', matchId)
        .single();

    if (response == null) {
      return null;
    }

    return Match.fromSupabase(response as Map<String, dynamic>);
  }

  Future<void> updateMatchProgress({
    required String matchId,
    required String playerId,
    required int progress,
    required int correctCount,
  }) async {
    final isPlayer1 = await _isPlayer1(matchId, playerId);
    final fieldPrefix = isPlayer1 ? 'player1' : 'player2';

    await supabase
        .from(AppConstants.matchesCollection)
        .update({
      '${fieldPrefix}_progress': progress,
      '${fieldPrefix}_correct_count': correctCount,
    }).eq('id', matchId);
  }

  Future<void> finishMatch({
    required String matchId,
    required String playerId,
    required int correctCount,
    required int totalQuestions,
  }) async {
    final match = await getMatchById(matchId);
    if (match == null) return;

    final isPlayer1 = match.player1Id == playerId;
    final fieldPrefix = isPlayer1 ? 'player1' : 'player2';

    final updates = {
      '${fieldPrefix}_finish_time': DateTime.now().toIso8601String(),
      '${fieldPrefix}_correct_count': correctCount,
      '${fieldPrefix}_progress': totalQuestions,
    };

    await supabase
        .from(AppConstants.matchesCollection)
        .update(updates)
        .eq('id', matchId);

    // 두 플레이어 모두 완료했는지 확인
    final updatedMatch = await getMatchById(matchId);
    if (updatedMatch != null &&
        updatedMatch.player1FinishTime != null &&
        updatedMatch.player2FinishTime != null) {
      await _calculateMatchResult(matchId, updatedMatch);
    }
  }

  Future<bool> _isPlayer1(String matchId, String playerId) async {
    final match = await getMatchById(matchId);
    return match?.player1Id == playerId;
  }

  // 문제별 정답 기록 저장
  Future<void> saveMatchAnswer({
    required String matchId,
    required String userId,
    required String questionId,
    required bool isCorrect,
  }) async {
    try {
      // question_id를 bigint로 변환 (quiz_questions의 id가 bigserial이므로)
      final questionIdInt = int.tryParse(questionId);
      if (questionIdInt == null) return;

      await supabase.from('match_answers').insert({
        'match_id': matchId,
        'user_id': userId,
        'question_id': questionIdInt,
        'is_correct': isCorrect,
        'answered_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // UNIQUE 제약 조건 위반 시 무시 (이미 저장된 경우)
      if (e.toString().contains('duplicate') || e.toString().contains('unique')) {
        return;
      }
      // 다른 오류는 로그만 남기고 계속 진행
      print('match_answers 저장 오류: $e');
    }
  }

  Future<void> _calculateMatchResult(String matchId, Match match) async {
    String? result;
    String? winnerId;

    if (match.player1CorrectCount > match.player2CorrectCount) {
      result = AppConstants.resultWin;
      winnerId = match.player1Id;
    } else if (match.player2CorrectCount > match.player1CorrectCount) {
      result = AppConstants.resultLose;
      winnerId = match.player2Id;
    } else {
      // 같은 정답 수인 경우 시간으로 판단
      if (match.player1FinishTime != null && match.player2FinishTime != null) {
        if (match.player1FinishTime!.isBefore(match.player2FinishTime!)) {
          result = AppConstants.resultWin;
          winnerId = match.player1Id;
        } else if (match.player2FinishTime!.isBefore(match.player1FinishTime!)) {
          result = AppConstants.resultLose;
          winnerId = match.player2Id;
        } else {
          result = AppConstants.resultDraw;
        }
      } else {
        result = AppConstants.resultDraw;
      }
    }

    await supabase.from(AppConstants.matchesCollection).update({
      'result': result,
      'winner_id': winnerId,
      'finished_at': DateTime.now().toIso8601String(),
      'status': AppConstants.matchStatusFinished,
    }).eq('id', matchId);
  }
}
