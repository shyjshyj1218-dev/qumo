import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../../config/colors.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../../services/league_service.dart';
import '../../widgets/profile/radar_chart_widget.dart';
import '../../models/league.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _friendsCount = 0;
  int _followingCount = 0;
  int? _leagueRank;
  int _tournamentWins = 0;
  int _tournamentParticipations = 0;
  Map<String, double> _stats = {};
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadFriendsCount();
    _loadUserStatistics();
  }

  Future<void> _loadFriendsCount() async {
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      final supabase = SupabaseService.client;
      
      // 친구 수 조회 (accepted 상태만)
      final friendsResponse = await supabase
          .from('friends')
          .select('id')
          .eq('user_id', currentUser.id)
          .eq('status', 'accepted');

      // 팔로잉 수 조회 (내가 친구 요청을 보낸 경우)
      final followingResponse = await supabase
          .from('friends')
          .select('id')
          .eq('user_id', currentUser.id)
          .eq('status', 'pending');

      setState(() {
        _friendsCount = friendsResponse != null && friendsResponse is List
            ? (friendsResponse as List).length
            : 0;
        _followingCount = followingResponse != null && followingResponse is List
            ? (followingResponse as List).length
            : 0;
      });
    } catch (e) {
      // 오류 무시 (친구 테이블이 없을 수 있음)
      setState(() {
        _friendsCount = 0;
        _followingCount = 0;
      });
    }
  }

  Future<void> _loadUserStatistics() async {
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      final supabase = SupabaseService.client;
      final leagueService = LeagueService();

      // 리그 순위 가져오기
      try {
        final leagueRankings = await leagueService.getUserLeagueRankings(currentUser.id);
        if (leagueRankings.isNotEmpty) {
          final userRanking = leagueRankings.firstWhere(
            (ranking) {
              final userId = ranking['user_id'] ?? ranking['users']?['id'];
              return userId == currentUser.id;
            },
            orElse: () => {},
          );
          if (userRanking.isNotEmpty && userRanking['rank'] != null) {
            setState(() {
              _leagueRank = userRanking['rank'] as int;
            });
          }
        }
      } catch (e) {
        // 리그 랭킹이 없을 수 있음
      }

      // 토너먼트 통계 가져오기
      try {
        // 토너먼트 참여 횟수
        final participations = await supabase
            .from('matches')
            .select('id')
            .or('player1_id.eq.${currentUser.id},player2_id.eq.${currentUser.id}')
            .eq('mode', 'tournament');

        // 토너먼트 우승 횟수
        final wins = await supabase
            .from('matches')
            .select('id')
            .eq('winner_id', currentUser.id)
            .eq('mode', 'tournament');

        setState(() {
          _tournamentParticipations = participations != null && participations is List
              ? (participations as List).length
              : 0;
          _tournamentWins = wins != null && wins is List
              ? (wins as List).length
              : 0;
        });
      } catch (e) {
        // 토너먼트 데이터가 없을 수 있음
        setState(() {
          _tournamentParticipations = 0;
          _tournamentWins = 0;
        });
      }

      // 카테고리별 정답률 계산 (match_answers 테이블 사용)
      try {
        // 8개 분야 정의
        final categories = ['생활', '문화', '스포츠', 'IT', '역사', '지리', '과학', '사회'];
        final categoryStats = <String, int>{}; // 카테고리별 총 문제 수
        final categoryCorrect = <String, int>{}; // 카테고리별 정답 수
        
        // 초기화
        for (var category in categories) {
          categoryStats[category] = 0;
          categoryCorrect[category] = 0;
        }

        // match_answers 테이블에서 사용자의 모든 답변 기록 가져오기
        final matchAnswers = await supabase
            .from('match_answers')
            .select('question_id, is_correct')
            .eq('user_id', currentUser.id);

        if (matchAnswers != null && matchAnswers is List && matchAnswers.isNotEmpty) {
          // 모든 question_id 수집
          final questionIds = matchAnswers
              .map((answer) => answer['question_id'] as int?)
              .where((id) => id != null)
              .cast<int>()
              .toSet()
              .toList();

          // 문제별 카테고리 정보 가져오기 (병렬 처리)
          final questionFutures = questionIds.map((questionId) async {
            try {
              final questionData = await supabase
                  .from('quiz_questions')
                  .select('id, category')
                  .eq('id', questionId)
                  .maybeSingle();
              return questionData;
            } catch (e) {
              return null;
            }
          });

          final questionsData = await Future.wait(questionFutures);
          final questionCategoryMap = <int, String?>{};
          
          for (var questionData in questionsData) {
            if (questionData != null) {
              final questionId = questionData['id'] as int?;
              final category = questionData['category'] as String?;
              if (questionId != null) {
                questionCategoryMap[questionId] = category;
              }
            }
          }

          // match_answers 데이터 처리
          for (var answerData in matchAnswers) {
            final questionId = answerData['question_id'] as int?;
            final isCorrect = answerData['is_correct'] as bool? ?? false;
            final category = questionId != null ? questionCategoryMap[questionId] : null;
            
            if (category != null) {
              // 카테고리 이름 정규화 (예: "상식 생활" -> "생활", "생활" -> "생활")
              String normalizedCategory = category;
              for (var cat in categories) {
                if (category.contains(cat) || category == cat) {
                  normalizedCategory = cat;
                  break;
                }
              }
              
              // 카테고리별 통계 업데이트
              if (categoryStats.containsKey(normalizedCategory)) {
                categoryStats[normalizedCategory] = 
                    (categoryStats[normalizedCategory] ?? 0) + 1;
                
                if (isCorrect) {
                  categoryCorrect[normalizedCategory] = 
                      (categoryCorrect[normalizedCategory] ?? 0) + 1;
                }
              }
            }
          }

          // 카테고리별 정답률 계산 (0-100 스케일)
          final categoryAccuracy = <String, double>{};
          for (var category in categories) {
            final total = categoryStats[category] ?? 0;
            final correct = categoryCorrect[category] ?? 0;
            final accuracy = total > 0 ? (correct / total * 100) : 0.0;
            categoryAccuracy[category] = accuracy.clamp(0.0, 100.0);
          }

          setState(() {
            _stats = categoryAccuracy;
            _isLoadingStats = false;
          });
        } else {
          // match_answers 데이터가 없으면 기본값 (기존 matches 테이블로 폴백)
          try {
            final allMatches = await supabase
                .from('matches')
                .select()
                .or('player1_id.eq.${currentUser.id},player2_id.eq.${currentUser.id}')
                .eq('status', 'finished');

            if (allMatches != null && allMatches is List && allMatches.isNotEmpty) {
              // 기존 로직으로 근사치 계산 (match_answers가 없을 때만)
              // ... (기존 코드 유지)
            } else {
              final defaultStats = <String, double>{};
              for (var category in categories) {
                defaultStats[category] = 0.0;
              }
              setState(() {
                _stats = defaultStats;
                _isLoadingStats = false;
              });
            }
          } catch (e) {
            final defaultStats = <String, double>{};
            for (var category in categories) {
              defaultStats[category] = 0.0;
            }
            setState(() {
              _stats = defaultStats;
              _isLoadingStats = false;
            });
          }
        }
      } catch (e) {
        // 오류 발생 시 기본값
        final categories = ['생활', '문화', '스포츠', 'IT', '역사', '지리', '과학', '사회'];
        final defaultStats = <String, double>{};
        for (var category in categories) {
          defaultStats[category] = 0.0;
        }
        setState(() {
          _stats = defaultStats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: userProfile.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('사용자 정보를 불러올 수 없습니다'));
          }

          return SafeArea(
            child: Column(
              children: [
                // 상단 헤더 (뒤로가기, 설정 버튼)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 뒤로가기 버튼
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundWhite,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
                          onPressed: () => context.pop(),
                        ),
                      ),
                      // 설정 버튼
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundWhite,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.settings, color: AppColors.textPrimary),
                          onPressed: () {
                            context.push('/settings');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // 프로필 이미지
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.primary,
                  backgroundImage: user.profileImage != null
                      ? NetworkImage(user.profileImage!)
                      : null,
                  child: user.profileImage == null
                      ? Text(
                          user.nickname.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 48,
                            color: AppColors.textWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 20),
                // 프로필 정보
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 이름
                        Text(
                          user.nickname,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // 이메일
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // 정보 카드 그리드 (2x2)
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.star,
                                iconColor: AppColors.coinBg,
                                value: '${user.coins}',
                                label: 'Balance',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.emoji_events,
                                iconColor: AppColors.coinBg,
                                value: '${user.rating}',
                                label: 'Rating',
                                badge: 'Record',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.emoji_events,
                                iconColor: Color(0xFFFFE5E5),
                                value: _leagueRank != null 
                                    ? '#$_leagueRank' 
                                    : (user.currentLeagueTier != null 
                                        ? _getTierName(user.currentLeagueTier!) 
                                        : '-'),
                                label: _leagueRank != null 
                                    ? '리그 순위' 
                                    : '현재 리그',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.confirmation_number,
                                iconColor: AppColors.coinBg,
                                value: '${user.tickets}',
                                label: 'Tickets',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.tour,
                                iconColor: Color(0xFFFFD700),
                                value: '$_tournamentWins',
                                label: '토너먼트 우승',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.group,
                                iconColor: Color(0xFF4CAF50),
                                value: '$_tournamentParticipations',
                                label: '토너먼트 참여',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // 능력치 레이다 차트
                        if (_isLoadingStats)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_stats.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundWhite,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.borderGray,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '능력치',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Center(
                                  child: RadarChartWidget(
                                    stats: _stats,
                                    size: 280, // 8각형이므로 조금 더 크게
                                    fillColor: AppColors.primary,
                                    strokeColor: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('오류: $error')),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    String? badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderGray,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: AppColors.textPrimary),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.coin,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textWhite,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
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
}

