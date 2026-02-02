import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class CategoryStatsService {
  final supabase = SupabaseService.client;

  // 사용자 카테고리별 능력치 조회 (8각형 레이더 그래프용)
  Future<Map<String, double>?> getUserCategoryStats(String userId) async {
    try {
      final response = await supabase
          .from('user_category_stats')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // 첫 게임 전이면 기본값 반환
        return {
          '생활': 0.0,
          '사회': 0.0,
          '과학': 0.0,
          '지리': 0.0,
          '역사': 0.0,
          'IT': 0.0,
          '스포츠': 0.0,
          '문화': 0.0,
        };
      }

      // 정규화된 값 계산 (EMA를 0~100으로 변환)
      const maxScore = 40.0; // 10문제 * 최상급(4점)
      final categories = ['생활', '사회', '과학', '지리', '역사', 'IT', '스포츠', '문화'];
      final stats = <String, double>{};

      for (final category in categories) {
        final emaValue = (response[category] as num?)?.toDouble() ?? 0.0;
        // EMA 값을 0~100으로 정규화
        final normalized = (emaValue / maxScore * 100).clamp(0.0, 100.0);
        stats[category] = normalized;
      }

      return stats;
    } catch (e) {
      debugPrint('❌ 능력치 조회 실패: $e');
      return null;
    }
  }

  // 게임 플레이 횟수 조회
  Future<int?> getGamesPlayed(String userId) async {
    try {
      final response = await supabase
          .from('user_category_stats')
          .select('games_played')
          .eq('user_id', userId)
          .maybeSingle();

      return (response?['games_played'] as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint('❌ 게임 횟수 조회 실패: $e');
      return 0;
    }
  }
}

