import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/colors.dart';
import '../../models/match_user.dart';
import '../../providers/matching_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/mission_provider.dart';
import '../../services/mission_service.dart';

class MatchResultScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> result;
  final MatchUser opponent;
  final int playerCorrectCount;
  final int opponentCorrectCount;

  const MatchResultScreen({
    super.key,
    required this.result,
    required this.opponent,
    required this.playerCorrectCount,
    required this.opponentCorrectCount,
  });

  @override
  ConsumerState<MatchResultScreen> createState() => _MatchResultScreenState();
}

class _MatchResultScreenState extends ConsumerState<MatchResultScreen> {
  bool _missionUpdated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMission();
    });
  }

  Future<void> _updateMission() async {
    if (_missionUpdated) return;
    
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final missionService = ref.read(missionServiceProvider);
    await missionService.updateMatchCount(currentUser.id);

    setState(() {
      _missionUpdated = true;
    });

    // 미션 진행도 새로고침
    ref.invalidate(userMissionProgressProvider(currentUser.id));
    ref.invalidate(userProfileProvider);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final userProfile = ref.watch(userProfileProvider);
    final winnerId = widget.result['winner_id'];
    final isWin = winnerId == currentUser?.id;
    final isDraw = winnerId == null;
    final player1RatingChange = widget.result['player1_rating_change'] ?? 0;
    final player2RatingChange = widget.result['player2_rating_change'] ?? 0;
    
    // 현재 사용자가 player1인지 확인 (match_id나 다른 정보로 판단)
    // 일단 winner_id로 판단하거나, 정답 수로 판단
    final isPlayer1 = widget.result['player1_id'] == currentUser?.id;
    final ratingChange = isPlayer1 ? player1RatingChange : player2RatingChange;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 결과 헤더
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isWin
                    ? AppColors.difficultyBeginner
                    : isDraw
                        ? AppColors.textSecondary
                        : AppColors.difficultyExpert,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    isWin
                        ? Icons.emoji_events
                        : isDraw
                            ? Icons.handshake
                            : Icons.sentiment_dissatisfied,
                    size: 80,
                    color: AppColors.textWhite,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isWin ? '승리!' : isDraw ? '무승부' : '패배',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textWhite,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // 점수 비교
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildPlayerCard(
                      name: userProfile.value?.nickname ?? '나',
                      correctCount: widget.playerCorrectCount,
                      ratingChange: ratingChange,
                      isWin: isWin && !isDraw,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPlayerCard(
                      name: widget.opponent.nickname,
                      correctCount: widget.opponentCorrectCount,
                      ratingChange: isPlayer1 ? player2RatingChange : player1RatingChange,
                      isWin: !isWin && !isDraw && winnerId == widget.opponent.id,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // 레이팅 변화
            if (ratingChange != 0)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundWhite,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      ratingChange > 0 ? Icons.trending_up : Icons.trending_down,
                      color: ratingChange > 0
                          ? AppColors.difficultyBeginner
                          : AppColors.difficultyExpert,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '레이팅 ${ratingChange > 0 ? '+' : ''}$ratingChange',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ratingChange > 0
                            ? AppColors.difficultyBeginner
                            : AppColors.difficultyExpert,
                      ),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            // 버튼
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(matchingStatusProvider.notifier).state = 'idle';
                        context.go('/home');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textWhite,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '홈으로',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(matchingStatusProvider.notifier).state = 'idle';
                        context.go('/home');
                        // 다시 매칭 시작 (홈 화면에서 처리)
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.primary, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '다시하기',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard({
    required String name,
    required int correctCount,
    required int ratingChange,
    required bool isWin,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: isWin
            ? Border.all(color: AppColors.difficultyBeginner, width: 2)
            : null,
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary,
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            '$correctCount개 정답',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

