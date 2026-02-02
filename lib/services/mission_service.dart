import 'package:flutter/foundation.dart';
import '../models/mission.dart';
import 'supabase_service.dart';

class UserMissionProgress {
  final String missionId;
  final int progress;
  final int targetValue;
  final bool isCompleted;
  final DateTime? completedAt;

  UserMissionProgress({
    required this.missionId,
    this.progress = 0,
    this.targetValue = 1,
    this.isCompleted = false,
    this.completedAt,
  });
}

class MissionService {
  final supabase = SupabaseService.client;

  // 모든 미션 가져오기
  Future<List<Mission>> getAllMissions() async {
    final response = await supabase
        .from('missions')
        .select()
        .order('created_at', ascending: true);

    return (response as List)
        .map((data) => Mission.fromSupabase(data as Map<String, dynamic>))
        .toList();
  }

  // 사용자의 미션 진행도 가져오기
  Future<Map<String, UserMissionProgress>> getUserMissionProgress(String userId) async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    final response = await supabase
        .from('user_missions')
        .select()
        .eq('user_id', userId)
        .gte('created_at', todayStart.toIso8601String());

    final progressMap = <String, UserMissionProgress>{};

    for (var data in response as List) {
        final missionId = data['mission_id'] as String;
        progressMap[missionId] = UserMissionProgress(
          missionId: missionId,
          progress: data['progress'] ?? 0,
          targetValue: data['target_value'] ?? 1,
          isCompleted: data['is_completed'] ?? false,
          completedAt: data['completed_at'] != null
              ? DateTime.parse(data['completed_at'])
              : null,
        );
    }

    return progressMap;
  }

  // 출석체크 미션 완료
  Future<bool> completeAttendanceMission(String userId) async {
    try {
      // 출석체크 미션 찾기
      final attendanceMission = await supabase
          .from('missions')
          .select()
          .eq('mission_type', 'daily')
          .ilike('title', '%출석%')
          .maybeSingle();

      if (attendanceMission == null) return false; // maybeSingle() can return null

      final missionId = attendanceMission['id'] as String;
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      // 오늘 이미 완료했는지 확인
      final existing = await supabase
          .from('user_missions')
          .select()
          .eq('user_id', userId)
          .eq('mission_id', missionId)
          .gte('created_at', todayStart.toIso8601String())
          .eq('is_completed', true)
          .maybeSingle();

      if (existing != null) {
        return false; // 이미 완료함
      }

      // 미션 완료 기록
      await supabase.from('user_missions').insert({
        'user_id': userId,
        'mission_id': missionId,
        'progress': 1,
        'target_value': 1,
        'is_completed': true,
        'completed_at': DateTime.now().toIso8601String(),
      });

      // 보상 지급
      await _giveReward(
        userId,
        attendanceMission['reward_coins'] ?? 0,
        attendanceMission['reward_tickets'] ?? 0,
      );

      return true;
    } catch (e) {
      debugPrint('출석체크 미션 완료 오류: $e');
      return false;
    }
  }

  // 매칭 횟수 업데이트
  Future<void> updateMatchCount(String userId) async {
    try {
      // 매칭 미션 찾기
      final matchMissions = await supabase
          .from('missions')
          .select()
          .eq('mission_type', 'daily')
          .ilike('title', '%매칭%');

      if ((matchMissions as List).isEmpty) return;

      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      for (var missionData in matchMissions as List) {
        final missionId = missionData['id'] as String;
        final targetValue = missionData['target_value'] ?? 3;

        // 기존 진행도 가져오기
        final existing = await supabase
            .from('user_missions')
            .select()
            .eq('user_id', userId)
            .eq('mission_id', missionId)
            .gte('created_at', todayStart.toIso8601String())
            .maybeSingle();

        int currentProgress = 0;
        bool isCompleted = false;

        if (existing != null) {
          currentProgress = existing['progress'] ?? 0;
          isCompleted = existing['is_completed'] ?? false;
        }

        if (isCompleted) continue; // 이미 완료

        currentProgress += 1;
        final newIsCompleted = currentProgress >= targetValue;

        if (existing != null) {
          // 업데이트
          await supabase
              .from('user_missions')
              .update({
                'progress': currentProgress,
                'is_completed': newIsCompleted,
                'completed_at': newIsCompleted
                    ? DateTime.now().toIso8601String()
                    : null,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', existing['id']);
        } else {
          // 새로 생성
          await supabase.from('user_missions').insert({
            'user_id': userId,
            'mission_id': missionId,
            'progress': currentProgress,
            'target_value': targetValue,
            'is_completed': newIsCompleted,
            'completed_at': newIsCompleted
                ? DateTime.now().toIso8601String()
                : null,
          });
        }

        // 완료 시 보상 지급
        if (newIsCompleted && !isCompleted) {
          await _giveReward(
            userId,
            missionData['reward_coins'] ?? 0,
            missionData['reward_tickets'] ?? 0,
          );
        }
      }
    } catch (e) {
      debugPrint('매칭 횟수 업데이트 오류: $e');
    }
  }

  // 보상 지급
  Future<void> _giveReward(String userId, int coins, int tickets) async {
    if (coins == 0 && tickets == 0) return;

    // 현재 사용자 정보 가져오기
    final user = await supabase
        .from('users')
        .select('coins, tickets')
        .eq('id', userId)
        .single();

    final currentCoins = (user['coins'] ?? 0) as int;
    final currentTickets = (user['tickets'] ?? 0) as int;

    // 업데이트
    await supabase
        .from('users')
        .update({
          'coins': currentCoins + coins,
          'tickets': currentTickets + tickets,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  // 미션 완료 처리 (수동 완료)
  Future<bool> completeMission(String userId, String missionId) async {
    try {
      final mission = await supabase
          .from('missions')
          .select()
          .eq('id', missionId)
          .single();

      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      // 오늘 이미 완료했는지 확인
      final existing = await supabase
          .from('user_missions')
          .select()
          .eq('user_id', userId)
          .eq('mission_id', missionId)
          .gte('created_at', todayStart.toIso8601String())
          .eq('is_completed', true)
          .maybeSingle();

      if (existing != null) {
        return false; // 이미 완료함
      }

      // 미션 완료 기록
      await supabase.from('user_missions').insert({
        'user_id': userId,
        'mission_id': missionId,
        'progress': mission['target_value'] ?? 1,
        'target_value': mission['target_value'] ?? 1,
        'is_completed': true,
        'completed_at': DateTime.now().toIso8601String(),
      });

      // 보상 지급
      await _giveReward(
        userId,
        mission['reward_coins'] ?? 0,
        mission['reward_tickets'] ?? 0,
      );

      return true;
    } catch (e) {
      debugPrint('미션 완료 오류: $e');
      return false;
    }
  }
}
