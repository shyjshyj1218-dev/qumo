import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/colors.dart';
import '../../models/mission.dart';
import '../../providers/mission_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/mission_service.dart';

class MissionScreen extends ConsumerStatefulWidget {
  const MissionScreen({super.key});

  @override
  ConsumerState<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends ConsumerState<MissionScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final missionsAsync = ref.watch(missionsProvider);

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('미션'),
          backgroundColor: AppColors.background,
        ),
        body: const Center(
          child: Text('로그인이 필요합니다'),
        ),
      );
    }

    final progressAsync = ref.watch(userMissionProgressProvider(currentUser.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('미션'),
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: missionsAsync.when(
        data: (missions) {
          if (missions.isEmpty) {
            return const Center(child: Text('미션이 없습니다'));
          }

          // 일일 미션만 필터링
          final dailyMissions = missions.where((m) => m.missionType == 'daily').toList();

          return progressAsync.when(
            data: (progress) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
                itemCount: dailyMissions.length,
            itemBuilder: (context, index) {
                  final mission = dailyMissions[index];
                  final missionProgress = progress[mission.id];
                  return _buildMissionCard(mission, missionProgress, currentUser.id);
            },
          );
        },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('오류: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('오류: $error')),
      ),
    );
  }

  Widget _buildMissionCard(Mission mission, UserMissionProgress? progress, String userId) {
    final isCompleted = progress?.isCompleted ?? false;
    final currentProgress = progress?.progress ?? 0;
    final targetValue = mission.targetValue;
    final progressPercent = targetValue > 0 ? (currentProgress / targetValue).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        border: isCompleted
            ? Border.all(color: AppColors.primary, width: 2)
            : Border.all(color: AppColors.borderGray, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
            mission.title,
                  style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? AppColors.primary
                        : AppColors.textPrimary,
            ),
                ),
              ),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '완료',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textWhite,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            mission.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          // 진행도 표시
          if (targetValue > 1)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '진행도: $currentProgress / $targetValue',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${(progressPercent * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressPercent,
                    backgroundColor: AppColors.borderGray,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted ? AppColors.primary : AppColors.coin,
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (mission.rewardCoins > 0) ...[
                _buildRewardBadge(
                  icon: Icons.monetization_on,
                  value: '${mission.rewardCoins}',
                  color: AppColors.coin,
                ),
                const SizedBox(width: 8),
              ],
              if (mission.rewardTickets > 0)
                _buildRewardBadge(
                  icon: Icons.confirmation_number,
                  value: '${mission.rewardTickets}',
                  color: AppColors.ticket,
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isCompleted
                  ? null
                  : () async {
                      final missionService = ref.read(missionServiceProvider);
                      
                      // 출석체크 미션인 경우
                      if (mission.title.contains('출석')) {
                        final success = await missionService.completeAttendanceMission(userId);
                        if (success && mounted) {
                          ref.invalidate(userMissionProgressProvider(userId));
                          ref.invalidate(userProfileProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('출석체크 완료! 보상이 지급되었습니다.'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('이미 출석체크를 완료했습니다.'),
                              backgroundColor: AppColors.difficultyExpert,
                            ),
                          );
                        }
                      } else {
                        // 다른 미션은 수동 완료 불가 (자동 완료)
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('이 미션은 자동으로 완료됩니다.'),
                              backgroundColor: AppColors.difficultyExpert,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompleted
                    ? AppColors.borderGray
                    : AppColors.primary,
                foregroundColor: AppColors.textWhite,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                isCompleted ? '완료됨' : mission.title.contains('출석') ? '출석체크' : '진행 중',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardBadge({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
