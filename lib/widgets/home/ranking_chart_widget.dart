import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../config/colors.dart';
import '../../models/user.dart';
import '../../models/league.dart';
import '../../utils/constants.dart';
import '../../services/supabase_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/league_provider.dart';

class RankingChartWidget extends ConsumerStatefulWidget {
  const RankingChartWidget({super.key});

  @override
  ConsumerState<RankingChartWidget> createState() => _RankingChartWidgetState();
}

class _RankingChartWidgetState extends ConsumerState<RankingChartWidget> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return const Expanded(
        child: Center(
          child: Text(
            '로그인이 필요합니다',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
    }

    // 사용자의 리그 랭킹 가져오기
    final leagueRankingsAsync = ref.watch(userLeagueRankingsProvider(currentUser.id));
    final currentLeagueAsync = ref.watch(currentLeagueProvider(currentUser.id));

    return Expanded(
      child: Column(
        children: [
          // 리그 정보 표시
          currentLeagueAsync.when(
            data: (league) {
              if (league == null) {
                return const SizedBox.shrink();
              }
              return _buildLeagueInfo(league);
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // 랭킹 헤더
          _buildRankingHeader(),
          // 랭킹 리스트
          Expanded(
            child: leagueRankingsAsync.when(
              data: (rankings) {
                if (rankings.isEmpty) {
                  return const Center(
                    child: Text(
                      '랭킹 데이터가 없습니다',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: rankings.length,
                  itemBuilder: (context, index) {
                    final rankingData = rankings[index];
                    final userData = rankingData['users'] as Map<String, dynamic>?;
                    if (userData == null) return const SizedBox.shrink();

                    final user = UserModel.fromSupabase(userData);
                    final rank = rankingData['rank'] as int? ?? (index + 1);
                    final leagueScore = rankingData['league_score'] as int? ?? 0;
                    return _buildRankingCard(user, rank, leagueScore);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
              error: (error, stack) => Center(
                child: Text(
                  '오류: $error',
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeagueInfo(LeagueModel league) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.center,
      child: _buildTierIcon(league.tier),
    );
  }

  Widget _buildTierIcon(String tier) {
    // 티어별 SVG 파일 경로
    final tierIconPath = 'assets/images/league/${tier}.svg';
    
    return SizedBox(
      width: 80,
      height: 80,
      child: SvgPicture.asset(
        tierIconPath,
        fit: BoxFit.contain,
        // 에러 발생 시(파일 없거나 형식 오류) 보여줄 위젯
        errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(tier),
        placeholderBuilder: (context) => _buildDefaultIcon(tier),
      ),
    );
  }

  Widget _buildDefaultIcon(String tier) {
    return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.backgroundWhite,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.emoji_events,
            size: 40,
            color: _getTierColor(tier),
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'sapphire':
        return const Color(0xFF0F52BA);
      case 'ruby':
        return const Color(0xFFE0115F);
      case 'diamond':
        return const Color(0xFFB9F2FF);
      case 'crystal':
        return const Color(0xFFA7D8DE);
      default:
        return AppColors.primary;
    }
  }

  String _getTierName(String tier) {
    switch (tier) {
      case 'bronze':
        return '브론즈';
      case 'silver':
        return '실버';
      case 'gold':
        return '골드';
      case 'sapphire':
        return '사이파어';
      case 'ruby':
        return '루비';
      case 'diamond':
        return '다이아';
      case 'crystal':
        return '크리스탈';
      default:
        return '브론즈';
    }
  }


  Widget _buildRankingHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              'POS.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'PLAYER',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Row(
            children: [
              Text(
                '리그 점수',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.sort,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankingCard(UserModel user, int rank, int leagueScore) {
    final isFirst = rank == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.rankingCard,
        borderRadius: BorderRadius.circular(12),
        border: isFirst
            ? Border.all(
                color: AppColors.primary,
                width: 2,
              )
            : null,
      ),
      child: Row(
        children: [
          // 순위
          SizedBox(
            width: 50,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isFirst
                    ? AppColors.primary
                    : AppColors.textPrimary,
              ),
            ),
          ),
          // 플레이어 정보
          Expanded(
            child: Row(
              children: [
                // 아바타
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary,
                      backgroundImage: user.profileImage != null
                          ? NetworkImage(user.profileImage!)
                          : null,
                      child: user.profileImage == null
                          ? Text(
                              user.nickname.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    // 팀 배지 (아바타 왼쪽 하단)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.difficultyBeginner,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.rankingCard,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.star,
                          size: 10,
                          color: AppColors.textWhite,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // 이름 및 팀
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.nickname,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 리그 점수 (레이팅 증가량)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                leagueScore >= 0 ? '+$leagueScore' : '$leagueScore',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: leagueScore >= 0 
                      ? AppColors.primary 
                      : AppColors.difficultyExpert,
                ),
              ),
              Text(
                '${user.rating}',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}

