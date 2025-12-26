import '../models/league.dart';
import '../models/user.dart';
import 'supabase_service.dart';
import 'dart:math' as math;

class LeagueService {
  final supabase = SupabaseService.client;

  // 현재 주의 월요일 6시 구하기
  DateTime getCurrentWeekMonday() {
    final now = DateTime.now();
    final daysFromMonday = now.weekday - 1; // 월요일이 1이므로
    final mondayDate = DateTime(now.year, now.month, now.day - daysFromMonday);
    // 월요일 6시로 설정
    return DateTime(mondayDate.year, mondayDate.month, mondayDate.day, 6, 0);
  }

  // 현재 주의 일요일 22시 구하기
  DateTime getCurrentWeekSunday() {
    final monday = getCurrentWeekMonday();
    final sundayDate = monday.add(const Duration(days: 6));
    // 일요일 22시로 설정
    return DateTime(sundayDate.year, sundayDate.month, sundayDate.day, 22, 0);
  }

  // 현재 시간이 리그 기간 내에 있는지 확인
  bool isLeagueActive(DateTime weekStart, DateTime weekEnd) {
    final now = DateTime.now();
    return now.isAfter(weekStart) && now.isBefore(weekEnd);
  }

  // 현재 활성 리그인지 확인 (월요일 6시 ~ 일요일 22시)
  bool isCurrentLeagueActive() {
    final weekStart = getCurrentWeekMonday();
    final weekEnd = getCurrentWeekSunday();
    return isLeagueActive(weekStart, weekEnd);
  }

  // 사용자의 현재 리그 가져오기 또는 생성
  Future<LeagueModel> getOrCreateCurrentLeague(String userId) async {
    final user = await getUser(userId);
    var currentTier = user.currentLeagueTier ?? 'bronze';
    
    // 사용자의 리그 티어가 없으면 브론즈로 설정
    if (user.currentLeagueTier == null) {
      await supabase
          .from('users')
          .update({'current_league_tier': 'bronze'})
          .eq('id', userId);
      currentTier = 'bronze';
    }
    
    final weekStart = getCurrentWeekMonday();
    final weekEnd = getCurrentWeekSunday();

    // 현재 주의 리그가 있는지 확인
    final existingLeague = await supabase
        .from('leagues')
        .select()
        .eq('tier', currentTier)
        .eq('week_start_date', weekStart.toIso8601String().split('T')[0])
        .maybeSingle();

    if (existingLeague != null) {
      return LeagueModel.fromSupabase(existingLeague as Map<String, dynamic>);
    }

    // 리그가 없으면 생성
    final newLeague = await supabase
        .from('leagues')
        .insert({
          'tier': currentTier,
          'week_start_date': weekStart.toIso8601String().split('T')[0],
          'week_end_date': weekEnd.toIso8601String().split('T')[0],
        })
        .select()
        .single();

    return LeagueModel.fromSupabase(newLeague as Map<String, dynamic>);
  }

  // 사용자를 리그에 등록
  Future<void> registerUserToLeague(String userId, String leagueId, int currentRating) async {
    // 이미 등록되어 있는지 확인
    final existing = await supabase
        .from('league_rankings')
        .select()
        .eq('user_id', userId)
        .eq('league_id', leagueId)
        .maybeSingle();

    if (existing == null) {
      // 등록
      await supabase.from('league_rankings').insert({
        'user_id': userId,
        'league_id': leagueId,
        'rating_at_start': currentRating,
        'league_score': 0,
      });

      // 사용자의 현재 리그 정보 업데이트
      await supabase
          .from('users')
          .update({
            'current_league_id': leagueId,
          })
          .eq('id', userId);
    }
  }

  // 사용자 정보 가져오기
  Future<UserModel> getUser(String userId) async {
    final response = await supabase
        .from('users')
        .select()
        .eq('id', userId)
        .single();

    return UserModel.fromSupabase(response as Map<String, dynamic>);
  }

  // 리그 랭킹 가져오기 (리그 점수 순)
  Future<List<Map<String, dynamic>>> getLeagueRankings(String leagueId) async {
    final response = await supabase
        .from('league_rankings')
        .select('''
          *,
          users!league_rankings_user_id_fkey (
            id,
            email,
            nickname,
            coins,
            tickets,
            rating,
            profile_image,
            created_at,
            updated_at,
            current_league_tier,
            current_league_id
          )
        ''')
        .eq('league_id', leagueId)
        .order('league_score', ascending: false);

    if (response == null) return [];

    return (response as List).cast<Map<String, dynamic>>();
  }

  // 리그 갱신 (월요일 6시 이후 실행)
  Future<void> updateLeague() async {
    final now = DateTime.now();
    final lastWeekMonday = getCurrentWeekMonday().subtract(const Duration(days: 7));
    final lastWeekSunday = DateTime(
      lastWeekMonday.year,
      lastWeekMonday.month,
      lastWeekMonday.day + 6,
      22,
      0,
    );

    // 일요일 22시가 지났는지 확인 (월요일 6시 이후에만 실행)
    if (now.isBefore(lastWeekSunday)) {
      return; // 아직 리그가 종료되지 않음
    }

    // 지난 주 리그들 가져오기
    final lastWeekLeagues = await supabase
        .from('leagues')
        .select()
        .eq('week_start_date', lastWeekMonday.toIso8601String().split('T')[0]);

    if (lastWeekLeagues == null || (lastWeekLeagues as List).isEmpty) {
      return; // 지난 주 리그가 없으면 종료
    }

    for (var leagueData in lastWeekLeagues as List) {
      final league = LeagueModel.fromSupabase(leagueData as Map<String, dynamic>);
      await _processLeagueUpdate(league);
    }
  }

  // 개별 리그 갱신 처리
  Future<void> _processLeagueUpdate(LeagueModel league) async {
    // 리그 랭킹 가져오기
    final rankings = await supabase
        .from('league_rankings')
        .select('''
          *,
          users!league_rankings_user_id_fkey (
            id,
            rating
          )
        ''')
        .eq('league_id', league.id);

    if (rankings == null || (rankings as List).isEmpty) {
      return;
    }

    final rankingsList = (rankings as List).cast<Map<String, dynamic>>();

    // 각 사용자의 최종 레이팅으로 리그 점수 계산 및 업데이트
    for (var rankingData in rankingsList) {
      final userId = rankingData['user_id'] as String;
      final ratingAtStart = rankingData['rating_at_start'] as int;
      final userData = rankingData['users'] as Map<String, dynamic>?;
      final ratingAtEnd = userData?['rating'] as int? ?? ratingAtStart;

      final leagueScore = ratingAtEnd - ratingAtStart;

      await supabase
          .from('league_rankings')
          .update({
            'rating_at_end': ratingAtEnd,
            'league_score': leagueScore,
          })
          .eq('id', rankingData['id']);
    }

    // 리그 점수 순으로 정렬하여 순위 계산
    final updatedRankings = await supabase
        .from('league_rankings')
        .select()
        .eq('league_id', league.id)
        .order('league_score', ascending: false);

    if (updatedRankings == null) return;

    final sortedRankings = (updatedRankings as List).cast<Map<String, dynamic>>();
    final totalPlayers = sortedRankings.length;
    final top10Percent = math.max(1, (totalPlayers * 0.1).ceil());
    final bottom10Percent = math.max(1, (totalPlayers * 0.1).ceil());

    // 순위 업데이트 및 승급/강등 처리
    for (int i = 0; i < sortedRankings.length; i++) {
      final rankingData = sortedRankings[i];
      final rank = i + 1;
      final isTop10 = rank <= top10Percent;
      final isBottom10 = rank > (totalPlayers - bottom10Percent);

      String? newTier = league.tier;
      bool promoted = false;
      bool demoted = false;

      if (isTop10) {
        // 상위 10% 승급
        final nextTier = LeagueTier.getNextTier(league.tier);
        if (nextTier != null) {
          newTier = nextTier;
          promoted = true;
        }
      } else if (isBottom10) {
        // 하위 10% 강등
        final prevTier = LeagueTier.getPreviousTier(league.tier);
        if (prevTier != null) {
          newTier = prevTier;
          demoted = true;
        }
      }

      // 순위 및 승급/강등 정보 업데이트
      await supabase
          .from('league_rankings')
          .update({
            'rank': rank,
            'promoted': promoted,
            'demoted': demoted,
          })
          .eq('id', rankingData['id']);

      // 사용자의 리그 티어 업데이트
      if (promoted || demoted) {
        await supabase
            .from('users')
            .update({
              'current_league_tier': newTier,
            })
            .eq('id', rankingData['user_id']);
      }
    }
  }

  // 사용자의 현재 리그 랭킹 가져오기
  Future<List<Map<String, dynamic>>> getUserLeagueRankings(String userId) async {
    final user = await getUser(userId);
    final leagueId = user.currentLeagueId;

    if (leagueId == null) {
      // 리그에 등록되지 않았으면 등록
      final league = await getOrCreateCurrentLeague(userId);
      await registerUserToLeague(userId, league.id, user.rating);
      return getLeagueRankings(league.id);
    }

    return getLeagueRankings(leagueId);
  }

  // 새 사용자를 브론즈 리그에 등록
  Future<void> initializeUserLeague(String userId) async {
    final user = await getUser(userId);
    
    // 이미 리그가 설정되어 있으면 스킵
    if (user.currentLeagueTier != null && user.currentLeagueTier != 'bronze') {
      return;
    }

    // 브론즈 리그 가져오기 또는 생성
    final league = await getOrCreateCurrentLeague(userId);
    
    // 사용자 등록
    await registerUserToLeague(userId, league.id, user.rating);

    // 사용자 티어를 브론즈로 설정
    await supabase
        .from('users')
        .update({
          'current_league_tier': 'bronze',
          'current_league_id': league.id,
        })
        .eq('id', userId);
  }
}
